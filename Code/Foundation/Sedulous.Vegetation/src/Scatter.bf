using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Heightfield;
using Sedulous.Terrain;
using Sedulous.Terrain.Resource;
using Sedulous.Vegetation.Resource;

namespace Sedulous.Vegetation;

/// One scattered chunk: the instances in fade order, and what the scatter had to do to fit.
class ScatterResult
{
	/// Terrain local, in fade order.
	public List<Float4x4> Transforms = new .() ~ delete _;
	/// The chunk's terrain box grown by the mesh extent.
	public AABB LocalBounds = AABB.Empty();
	/// Points tried, which is density times area, or fewer where the cap filled first.
	public uint32 CandidateCount = 0;
	/// The layer's density, or the cap over the area where the chunk filled.
	public float EffectiveDensity = 0.0f;
	/// True when the chunk holds MaxInstancesPerChunk with candidates still to come.
	public bool DensityClamped = false;

	public void Clear()
	{
		Transforms.Clear();
		LocalBounds = AABB.Empty();
		CandidateCount = 0;
		EffectiveDensity = 0.0f;
		DensityClamped = false;
	}
}

/// The deterministic per chunk scatter and the distance fade.
///
/// ScatterChunk is a PURE function of the seed, the chunk, the heightfield, the splat and the
/// layer: the same inputs give identical instances frame to frame and on any machine.
/// Candidates are uniform XZ points in the chunk's footprint, accepted by the placement
/// source through rejection sampling against its share, by the slope limit and by the height
/// window; each accepted point takes its Y from the heightfield, a random yaw, a uniform
/// scale, and optionally the surface normal frame.
///
/// The output ORDER is the fade order: the generator emits a uniformly random sequence, so
/// the first N entries are a uniform thinning of the whole set. A distance fade is therefore
/// a draw count PREFIX, never a re-upload, and an instance's rank never changes, so a chunk
/// thins instance by instance instead of popping as a whole.
///
/// Transforms are TERRAIN LOCAL, in the heightfield's frame with the footprint centred on the
/// origin; the terrain entity's world matrix places them.
static class Scatter
{
	/// The candidate ceiling per chunk: a bound on the WORK of one rebuild, density times
	/// area being something a layer can ask anything of, never a bound on the picture. What a
	/// chunk holds is the layer's MaxInstancesPerChunk, counted against PLACED instances, so a
	/// candidate the mask rejects costs nothing and a painted patch grows at full density.
	public const uint32 cMaxCandidatesPerChunk = 1 << 20;

	/// The seed of one layer and chunk pair: a hash over the OWNING entity's persistent id,
	/// the layer's index and the chunk index, never a pointer and never a frame counter. The
	/// renderer keys its persistent instance buffer on the same value.
	public static uint64 ChunkSeed(Guid ownerId, uint32 layerIndex, int32 chunkX, int32 chunkZ)
	{
		var ownerId;
		var layerIndex;
		var chunkX;
		var chunkZ;
		var h = HashBytes(&ownerId, sizeof(Guid));
		h = HashBytes(&layerIndex, sizeof(uint32), h);
		h = HashBytes(&chunkX, sizeof(int32), h);
		h = HashBytes(&chunkZ, sizeof(int32), h);
		return (h == 0) ? 1 : h; // nought is the no set key downstream
	}

	/// The density multiplier at a distance in metres: one inside FadeStart, a smooth fall to
	/// nought at FadeEnd, nought beyond. A degenerate window, FadeEnd at or before FadeStart,
	/// is a hard cut at FadeEnd.
	public static float DensityAtDistance(float distance, float fadeStart, float fadeEnd)
	{
		if (distance >= fadeEnd)
			return 0.0f;
		if ((distance <= fadeStart) || (fadeEnd <= fadeStart))
			return 1.0f;

		let t = (distance - fadeStart) / (fadeEnd - fadeStart); // nought to one across the fade
		let s = t * t * (3.0f - 2.0f * t); // smoothstep
		return 1.0f - s;
	}

	/// The draw count prefix of a set of `count` instances at a density multiplier.
	public static uint32 FadePrefix(uint32 count, float density)
	{
		if (density <= 0.0f)
			return 0;
		if (density >= 1.0f)
			return count;

		let n = (float)count * density;
		let prefix = (uint32)(n + 0.5f);
		return (prefix > count) ? count : prefix;
	}

	/// The splat texel, nearest, under a terrain local XZ point: the splat raster spans the
	/// whole footprint, like the terrain shader's splat uv running nought to one across the
	/// grid.
	private static float SplatShare(SplatWeights splat, Heightfield heightfield,
		uint32 paletteIndex, float localX, float localZ)
	{
		if (splat.IsEmpty)
			return 0.0f;

		let size = heightfield.WorldSize;
		let u = Clamp(localX / Max(size.X, 1e-6f) + 0.5f, 0.0f, 1.0f);
		let v = Clamp(localZ / Max(size.Y, 1e-6f) + 0.5f, 0.0f, 1.0f);
		let sx = Clamp((int32)(u * (float)(splat.Width - 1) + 0.5f), 0, splat.Width - 1);
		let sy = Clamp((int32)(v * (float)(splat.Height - 1) + 0.5f), 0, splat.Height - 1);
		let w = (paletteIndex == ScatterLayer.cSplatBaseLayer)
			? splat.BaseWeight(sx, sy)
			: splat.WeightOfLayer(sx, sy, paletteIndex);
		return (float)w / 255.0f;
	}

	/// The mask plane's density, nought to one, under a terrain local XZ point: the nearest
	/// texel, on the same footprint mapping as the splat.
	private static float MaskShare(VegetationMask mask, Heightfield heightfield, uint32 plane,
		float localX, float localZ)
	{
		let size = heightfield.WorldSize;
		let u = localX / Max(size.X, 1e-6f) + 0.5f;
		let v = localZ / Max(size.Y, 1e-6f) + 0.5f;
		return mask.ShareAt(plane, u, v);
	}

	/// The placement source's share, nought to one, at a terrain local XZ point: one for
	/// Uniform and for Mask until the mask lands, the splat layer's painted weight for Splat
	/// and nought with no splat.
	public static float PlacementShareAt(ScatterLayer layer, Heightfield heightfield,
		SplatWeights splat, VegetationMask mask, float localX, float localZ)
	{
		// A CUT cell has no surface, so nothing grows there whatever the placement says.
		if (heightfield.HasHoles)
		{
			heightfield.CellOfLocal(localX, localZ, let cx, let cz);
			if (heightfield.CellHasHole(cx, cz))
				return 0.0f;
		}

		switch (layer.Placement)
		{
		case .Uniform:
			return 1.0f;
		case .Splat:
			return (splat != null)
				? SplatShare(splat, heightfield, layer.SplatLayer, localX, localZ)
				: 0.0f;
		case .Mask:
			return (mask != null)
				? MaskShare(mask, heightfield, layer.MaskPlane, localX, localZ)
				: 0.0f;
		case .SplatTimesMask:
			return ((splat != null) && (mask != null))
				? SplatShare(splat, heightfield, layer.SplatLayer, localX, localZ)
					* MaskShare(mask, heightfield, layer.MaskPlane, localX, localZ)
				: 0.0f;
		}
	}

	/// A right handed frame whose Y axis is `up`, in the row vector convention where the rows
	/// are the axes.
	private static Float4x4 FrameFromUp(Float3 up, float yaw)
	{
		// Yaw first, about the terrain local Y, then tilt the whole frame onto the normal.
		let c = Cos(yaw);
		let s = Sin(yaw);
		let flatX = Float3(c, 0.0f, -s);
		let flatZ = Float3(s, 0.0f, c);
		let n = Normalized(up);
		// Rotate the flat frame's X onto the plane perpendicular to n; Z completes it.
		var x = flatX - n * Dot(flatX, n);
		if (LengthSquared(x) < 1e-8f)
			x = flatZ - n * Dot(flatZ, n);
		x = Normalized(x);
		let z = Cross(x, n);
		return .(
			x.X, x.Y, x.Z, 0.0f,
			n.X, n.Y, n.Z, 0.0f,
			z.X, z.Y, z.Z, 0.0f,
			0.0f, 0.0f, 0.0f, 1.0f);
	}

	/// Scatters one chunk. `meshLocalBounds` is the instanced mesh's own box, whose extent
	/// grows the chunk's bounds by the maximum scale; an empty box leaves the terrain bounds
	/// as they are.
	public static void ScatterChunk(uint64 seed, TerrainChunk chunk, Heightfield heightfield,
		SplatWeights splat, VegetationMask mask, ScatterLayer layer, AABB meshLocalBounds,
		ScatterResult outResult)
	{
		outResult.Clear();
		outResult.LocalBounds = chunk.Bounds;
		if (heightfield.IsEmpty || (layer.Density <= 0.0f) || (layer.MaxInstancesPerChunk == 0))
			return;

		let minX = chunk.Bounds.Min.X;
		let minZ = chunk.Bounds.Min.Z;
		let sizeX = chunk.Bounds.Max.X - minX;
		let sizeZ = chunk.Bounds.Max.Z - minZ;
		let area = sizeX * sizeZ;
		if (area <= 0.0f)
			return;

		// Candidates are the layer's OWN density times the chunk area, under a ceiling that
		// bounds the work rather than the picture. The cap bounds what the chunk HOLDS: the
		// loop stops once it is full, so a mask patch covering a slice of the chunk still
		// grows at the layer's density, a candidate outside the patch costing no cap at all,
		// and only a chunk that fills up is clamped.
		let wanted = Min(layer.Density * area, (float)cMaxCandidatesPerChunk);
		let candidates = (uint32)(wanted + 0.5f);
		let cap = layer.MaxInstancesPerChunk;
		outResult.CandidateCount = candidates;
		outResult.EffectiveDensity = layer.Density;
		if (candidates == 0)
			return;

		let scaleMin = Min(layer.ScaleRange.X, layer.ScaleRange.Y);
		let scaleMax = Max(layer.ScaleRange.X, layer.ScaleRange.Y);
		let minNormalY = Cos(Clamp(layer.MaxSlopeDegrees, 0.0f, 90.0f) * (Math.PI_f / 180.0f));
		let heightMin = Min(layer.HeightRange.X, layer.HeightRange.Y);
		let heightMax = Max(layer.HeightRange.X, layer.HeightRange.Y);

		var rng = Random(seed);
		outResult.Transforms.Reserve((int)Min(candidates, cap));
		for (uint32 i = 0; i < candidates; i++)
		{
			// Full: what holds is the cap, not the density.
			if ((uint32)outResult.Transforms.Count >= cap)
			{
				outResult.DensityClamped = true;
				outResult.EffectiveDensity = (float)cap / area;
				outResult.CandidateCount = i;
				break;
			}

			// Draw every random number a candidate CAN consume up front, so a rejection never
			// shifts the stream of the ones after it: the accepted set stays a stable prefix
			// thinning of the candidate set as the parameters move.
			let x = minX + rng.NextFloat() * sizeX;
			let z = minZ + rng.NextFloat() * sizeZ;
			let keep = rng.NextFloat();
			let yaw = rng.NextFloat() * (Math.PI_f * 2.0f);
			let scale = scaleMin + rng.NextFloat() * (scaleMax - scaleMin);

			let share = PlacementShareAt(layer, heightfield, splat, mask, x, z);
			// The threshold gates only the SPLAT modes: a mask's density IS the share.
			let thresholded = (layer.Placement == .Splat) || (layer.Placement == .SplatTimesMask);
			if ((share <= 0.0f) || (thresholded && (share < layer.SplatThreshold))
				|| (keep >= share))
				continue;

			let normal = heightfield.GetNormalAt(x, z);
			if (normal.Y < minNormalY)
				continue;

			let y = heightfield.GetHeightAt(x, z);
			if ((y < heightMin) || (y > heightMax))
				continue;

			let rotation = layer.AlignToNormal ? FrameFromUp(normal, yaw) : Float4x4.RotationY(yaw);
			outResult.Transforms.Add(
				Float4x4.Scale(.(scale, scale, scale)) * rotation
					* Float4x4.Translation(.(x, y, z)));
		}

		// The bounds are the chunk's terrain box grown by the mesh's extent at the largest
		// scale, a blade's tip or a rock's overhang, so the set's cull sphere covers every
		// instance.
		if (!outResult.Transforms.IsEmpty && (meshLocalBounds.Max.X >= meshLocalBounds.Min.X))
		{
			let reach = Length(meshLocalBounds.Extents()) + Length(meshLocalBounds.Center());
			let grow = reach * scaleMax;
			outResult.LocalBounds.Min = outResult.LocalBounds.Min - Float3(grow, grow, grow);
			outResult.LocalBounds.Max = outResult.LocalBounds.Max + Float3(grow, grow, grow);
		}
	}

	// ==================== The prop scatter brush ====================

	/// Where an instance may NOT go, asked of a candidate's terrain local position and its
	/// world radius. Null means nowhere is blocked.
	public typealias BlockedQuery = delegate bool(Float3 localPosition, float radius);

	/// What one stamp did: the points tried, the instances placed, and why the rest were not.
	public struct StampResult
	{
		/// Points tried.
		public uint32 Candidates = 0;
		/// Instances appended.
		public uint32 Placed = 0;
		public uint32 RejectedSpacing = 0;
		public uint32 RejectedBlocked = 0;
		/// The slope limit or the height window.
		public uint32 RejectedRules = 0;

		public this() {}
	}

	/// Whether a candidate at x, z sits within `reach` of an instance already there: the
	/// layer's existing ones, and the ones this stamp has placed so far.
	private static bool TooClose(Span<Float4x4> existing, List<Float4x4> placed, int firstNew,
		float x, float z, float reach)
	{
		let reachSquared = reach * reach;
		for (let m in existing)
		{
			let dx = m[3, 0] - x;
			let dz = m[3, 2] - z;
			if (((dx * dx) + (dz * dz)) < reachSquared)
				return true;
		}
		for (int i = firstNew; i < placed.Count; i++)
		{
			let m = placed[i];
			let dx = m[3, 0] - x;
			let dz = m[3, 2] - z;
			if (((dx * dx) + (dz * dz)) < reachSquared)
				return true;
		}
		return false;
	}

	/// One brush stamp of authored instances into a PROP layer.
	///
	/// `density` per square metre over the disc of `radius` at the terrain local centre,
	/// scaled by `amount` from nought to one. Each candidate takes a uniform point in the
	/// disc and the layer's own rules, the slope limit, the height window, the scale range
	/// and the alignment, exactly as the procedural scatter does, and then two rejections:
	/// the SPACING rule, no instance within `spacing` times the mesh's radius times its
	/// scale of one already there, and the `blocked` query, which the editor wires to the
	/// physics world so nothing lands inside an existing body.
	///
	/// DETERMINISTIC for a seed: a scripted stroke places the same instances every run.
	/// `existing` are the layer's current instances and `outInstances` receives the new ones,
	/// appended, with the spacing test seeing both.
	public static StampResult ScatterStamp(uint64 seed, Heightfield heightfield,
		ScatterLayer layer, AABB meshLocalBounds, float centreX, float centreZ, float radius,
		float density, float amount, float spacing, Span<Float4x4> existing,
		BlockedQuery blocked, List<Float4x4> outInstances)
	{
		var result = StampResult();
		if (heightfield.IsEmpty || (radius <= 0.0f) || (density <= 0.0f) || (amount <= 0.0f))
			return result;

		let area = Math.PI_f * radius * radius;
		let candidates = (uint32)((density * area * Clamp(amount, 0.0f, 1.0f)) + 0.5f);
		result.Candidates = candidates;
		if (candidates == 0)
			return result;

		let scaleMin = Min(layer.ScaleRange.X, layer.ScaleRange.Y);
		let scaleMax = Max(layer.ScaleRange.X, layer.ScaleRange.Y);
		let minNormalY = Cos(Clamp(layer.MaxSlopeDegrees, 0.0f, 90.0f) * (Math.PI_f / 180.0f));
		let heightMin = Min(layer.HeightRange.X, layer.HeightRange.Y);
		let heightMax = Max(layer.HeightRange.X, layer.HeightRange.Y);
		let hasBounds = meshLocalBounds.Max.X >= meshLocalBounds.Min.X;
		let meshRadius = hasBounds ? Length(meshLocalBounds.Extents()) : 0.5f;
		let firstNew = outInstances.Count;

		var rng = Random(seed);
		for (uint32 i = 0; i < candidates; i++)
		{
			// Every random number a candidate CAN consume is drawn up front, so a rejection
			// never shifts the stream of the ones after it.
			let angle = rng.NextFloat() * (Math.PI_f * 2.0f);
			// The square root is what makes the point uniform over the disc rather than
			// crowded at its centre.
			let r = radius * Sqrt(rng.NextFloat());
			let yaw = rng.NextFloat() * (Math.PI_f * 2.0f);
			let scale = scaleMin + rng.NextFloat() * (scaleMax - scaleMin);
			let x = centreX + Cos(angle) * r;
			let z = centreZ + Sin(angle) * r;

			// No prop stands over a cut cell.
			if (heightfield.HasHoles)
			{
				heightfield.CellOfLocal(x, z, let cx, let cz);
				if (heightfield.CellHasHole(cx, cz))
				{
					result.RejectedRules++;
					continue;
				}
			}

			let normal = heightfield.GetNormalAt(x, z);
			let y = heightfield.GetHeightAt(x, z);
			if ((normal.Y < minNormalY) || (y < heightMin) || (y > heightMax))
			{
				result.RejectedRules++;
				continue;
			}

			let reach = Max(spacing, 0.0f) * meshRadius * scale;
			if ((reach > 0.0f) && TooClose(existing, outInstances, firstNew, x, z, reach))
			{
				result.RejectedSpacing++;
				continue;
			}

			if ((blocked != null) && blocked(.(x, y, z), meshRadius * scale))
			{
				result.RejectedBlocked++;
				continue;
			}

			let rotation = layer.AlignToNormal ? FrameFromUp(normal, yaw) : Float4x4.RotationY(yaw);
			outInstances.Add(
				Float4x4.Scale(.(scale, scale, scale)) * rotation
					* Float4x4.Translation(.(x, y, z)));
			result.Placed++;
		}
		return result;
	}

	/// Removes every instance whose terrain local XZ lies inside the disc, and answers how
	/// many went.
	public static uint32 EraseInstancesInDisc(List<Float4x4> instances, float centreX,
		float centreZ, float radius)
	{
		let radiusSquared = radius * radius;
		var removed = (uint32)0;
		var write = 0;
		for (int i = 0; i < instances.Count; i++)
		{
			let dx = instances[i][3, 0] - centreX;
			let dz = instances[i][3, 2] - centreZ;
			if (((dx * dx) + (dz * dz)) <= radiusSquared)
			{
				removed++;
				continue;
			}
			if (write != i)
				instances[write] = instances[i];
			write++;
		}
		instances.Count = write;
		return removed;
	}

	/// The chunk indices, row major as cz times the side plus cx, whose growth a sculpt or a
	/// paint over the region in sample grid coordinates can change. Chunks share edge samples,
	/// so a region on a boundary sample touches both neighbours. Appends unique indices,
	/// ascending.
	public static void ChunksTouchedBy(HeightfieldRegion region, int32 chunksPerSide,
		List<uint32> outChunkIndices)
	{
		if (region.IsEmpty || (chunksPerSide <= 0))
			return;

		let last = chunksPerSide - 1;
		// A boundary sample, gx at a multiple of the quad count, belongs to the previous
		// chunk's far edge AND to this chunk's near edge.
		let cx0 = Clamp((region.MinX - 1) / TerrainMesh.ChunkQuads, 0, last);
		let cx1 = Clamp(region.MaxX / TerrainMesh.ChunkQuads, 0, last);
		let cz0 = Clamp((region.MinZ - 1) / TerrainMesh.ChunkQuads, 0, last);
		let cz1 = Clamp(region.MaxZ / TerrainMesh.ChunkQuads, 0, last);
		for (int32 cz = cz0; cz <= cz1; cz++)
		{
			for (int32 cx = cx0; cx <= cx1; cx++)
			{
				let index = (uint32)(cz * chunksPerSide + cx);
				var seen = false;
				for (let existing in outChunkIndices)
				{
					if (existing == index)
					{
						seen = true;
						break;
					}
				}
				if (!seen)
					outChunkIndices.Add(index);
			}
		}
	}
}
