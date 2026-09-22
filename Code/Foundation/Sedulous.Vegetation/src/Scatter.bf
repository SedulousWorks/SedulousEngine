using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Heightfield;
using Sedulous.Terrain;
using Sedulous.Terrain.Resource;

namespace Sedulous.Vegetation;

/// One scattered chunk: the instances in fade order, and what the scatter had to do to fit.
class ScatterResult
{
	/// Terrain local, in fade order.
	public List<Float4x4> Transforms = new .() ~ delete _;
	/// The chunk's terrain box grown by the mesh extent.
	public AABB LocalBounds = AABB.Empty();
	/// Points tried, which is density times area, capped.
	public uint32 CandidateCount = 0;
	/// The density actually used.
	public float EffectiveDensity = 0.0f;
	/// True when MaxInstancesPerChunk scaled the density down.
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

	/// The placement source's share, nought to one, at a terrain local XZ point: one for
	/// Uniform and for Mask until the mask lands, the splat layer's painted weight for Splat
	/// and nought with no splat, nought for Scattered.
	public static float PlacementShareAt(ScatterLayer layer, Heightfield heightfield,
		SplatWeights splat, float localX, float localZ)
	{
		switch (layer.Placement)
		{
		case .Uniform, .Mask: // the mask plane multiplies in here once it lands
			return 1.0f;
		case .Splat:
			return (splat != null)
				? SplatShare(splat, heightfield, layer.SplatLayer, localX, localZ)
				: 0.0f;
		case .Scattered:
			return 0.0f;
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
		SplatWeights splat, ScatterLayer layer, AABB meshLocalBounds, ScatterResult outResult)
	{
		outResult.Clear();
		outResult.LocalBounds = chunk.Bounds;
		if (heightfield.IsEmpty || (layer.Placement == .Scattered) || (layer.Density <= 0.0f)
			|| (layer.MaxInstancesPerChunk == 0))
			return;

		let minX = chunk.Bounds.Min.X;
		let minZ = chunk.Bounds.Min.Z;
		let sizeX = chunk.Bounds.Max.X - minX;
		let sizeZ = chunk.Bounds.Max.Z - minZ;
		let area = sizeX * sizeZ;
		if (area <= 0.0f)
			return;

		// The candidate budget is density times area, capped per chunk: a layer over budget
		// scales its density down, the memory bound per set being the cap and not the density.
		var density = layer.Density;
		var wanted = density * area;
		let cap = (float)layer.MaxInstancesPerChunk;
		if (wanted > cap)
		{
			density = cap / area;
			wanted = cap;
			outResult.DensityClamped = true;
		}
		let candidates = (uint32)(wanted + 0.5f);
		outResult.CandidateCount = candidates;
		outResult.EffectiveDensity = density;
		if (candidates == 0)
			return;

		let scaleMin = Min(layer.ScaleRange.X, layer.ScaleRange.Y);
		let scaleMax = Max(layer.ScaleRange.X, layer.ScaleRange.Y);
		let minNormalY = Cos(Clamp(layer.MaxSlopeDegrees, 0.0f, 90.0f) * (Math.PI_f / 180.0f));
		let heightMin = Min(layer.HeightRange.X, layer.HeightRange.Y);
		let heightMax = Max(layer.HeightRange.X, layer.HeightRange.Y);

		var rng = Random(seed);
		outResult.Transforms.Reserve((int)candidates);
		for (uint32 i = 0; i < candidates; i++)
		{
			// Draw every random number a candidate CAN consume up front, so a rejection never
			// shifts the stream of the ones after it: the accepted set stays a stable prefix
			// thinning of the candidate set as the parameters move.
			let x = minX + rng.NextFloat() * sizeX;
			let z = minZ + rng.NextFloat() * sizeZ;
			let keep = rng.NextFloat();
			let yaw = rng.NextFloat() * (Math.PI_f * 2.0f);
			let scale = scaleMin + rng.NextFloat() * (scaleMax - scaleMin);

			let share = PlacementShareAt(layer, heightfield, splat, x, z);
			if ((share <= 0.0f) || (share < layer.SplatThreshold) || (keep >= share))
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
