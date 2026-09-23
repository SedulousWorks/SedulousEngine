using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Heightfield;
using Sedulous.Terrain;
using Sedulous.Terrain.Resource;
using Sedulous.Vegetation;
using Sedulous.Vegetation.Resource;

namespace Sedulous.Vegetation.Tests;

/// The scatter's contract: determinism per seed, density to count, the splat, slope and
/// height rules, normal alignment, the fade math, the chunk touch mapping and the cap.
class ScatterTests
{
	/// One chunk of 64 quads.
	private const int32 cGrid = 65;
	/// A metre per quad, so the chunk is 64 by 64 metres, which is 4096 square metres.
	private const float cWorld = 64.0f;

	private static bool Near(float a, float b, float epsilon = 0.01f) => Math.Abs(a - b) <= epsilon;

	/// A flat field at a height, the world Y range being nought to forty.
	private static Heightfield MakeFlat(float height)
	{
		let grid = new Heightfield(cGrid, .(cWorld, cWorld), 0.0f, 40.0f);
		let sample = grid.WorldYToSample(height);
		for (int32 z = 0; z < cGrid; z++)
			for (int32 x = 0; x < cGrid; x++)
				grid.SetSample(x, z, sample);
		return grid;
	}

	/// A plane rising with x: nought at the low edge, `rise` at the high one, a constant slope.
	private static Heightfield MakeRamp(float rise)
	{
		let grid = new Heightfield(cGrid, .(cWorld, cWorld), 0.0f, 40.0f);
		for (int32 z = 0; z < cGrid; z++)
		{
			for (int32 x = 0; x < cGrid; x++)
			{
				let t = (float)x / (float)(cGrid - 1);
				grid.SetSample(x, z, grid.WorldYToSample(t * rise));
			}
		}
		return grid;
	}

	/// The single chunk of a 65 sample grid.
	private static TerrainChunk ChunkOf(Heightfield grid)
	{
		let chunks = scope List<TerrainChunk>();
		TerrainChunks.BuildChunks(grid, chunks);
		Test.Assert(chunks.Count == 1);
		return chunks[0];
	}

	/// A splat raster with palette layer nought one hot on the left half, base on the right.
	private static SplatWeights MakeHalfSplat()
	{
		const int32 n = 32;
		let sw = new SplatWeights(n, n);
		let idx = sw.Indices;
		let wts = sw.Weights;
		for (int32 y = 0; y < n; y++)
		{
			for (int32 x = 0; x < n / 2; x++)
			{
				let at = sw.TexelOffset(x, y);
				idx[at + 0] = 0;
				wts[at + 0] = 255;
			}
		}
		sw.BumpVersion();
		return sw;
	}

	private static ScatterLayer Uniform(float density)
	{
		var layer = ScatterLayer();
		layer.Placement = .Uniform;
		layer.Density = density;
		layer.MaxSlopeDegrees = 90.0f;
		return layer;
	}

	private static bool SameTransforms(List<Float4x4> a, List<Float4x4> b)
	{
		if (a.Count != b.Count)
			return false;
		for (int i < a.Count)
		{
			if (Internal.MemCmp(&a[i], &b[i], sizeof(Float4x4)) != 0)
				return false;
		}
		return true;
	}

	private static Float3 Row(Float4x4 m, int r) => .(m.M[r][0], m.M[r][1], m.M[r][2]);

	[Test]
	public static void ASeedGivesIdenticalInstancesAnotherChunkOrLayerDiffers()
	{
		let grid = MakeFlat(5.0f);
		defer delete grid;
		let chunk = ChunkOf(grid);
		let layer = Uniform(0.25f);
		let ownerId = Guid(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);
		let seed = Scatter.ChunkSeed(ownerId, 0, 0, 0);

		let a = scope ScatterResult();
		let b = scope ScatterResult();
		Scatter.ScatterChunk(seed, chunk, grid, null, null, layer, AABB.Empty(), a);
		Scatter.ScatterChunk(seed, chunk, grid, null, null, layer, AABB.Empty(), b);
		Test.Assert(!a.Transforms.IsEmpty);
		Test.Assert(SameTransforms(a.Transforms, b.Transforms));

		// Every instance sits ON the surface, inside the chunk footprint.
		for (let m in a.Transforms)
		{
			Test.Assert(Near(m.M[3][1], 5.0f, 0.05f));
			Test.Assert(m.M[3][0] >= chunk.Bounds.Min.X);
			Test.Assert(m.M[3][0] <= chunk.Bounds.Max.X);
			Test.Assert(m.M[3][2] >= chunk.Bounds.Min.Z);
			Test.Assert(m.M[3][2] <= chunk.Bounds.Max.Z);
		}

		// The seed IS the identity: a neighbouring chunk, another slot on the same entity, or
		// another entity all scatter differently.
		Test.Assert(Scatter.ChunkSeed(ownerId, 0, 1, 0) != seed);
		Test.Assert(Scatter.ChunkSeed(ownerId, 0, 0, 1) != seed);
		Test.Assert(Scatter.ChunkSeed(ownerId, 1, 0, 0) != seed);
		Test.Assert(Scatter.ChunkSeed(Guid(9, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11), 0, 0, 0) != seed);
		let c = scope ScatterResult();
		Scatter.ScatterChunk(Scatter.ChunkSeed(ownerId, 0, 1, 0), chunk, grid, null, null, layer,
			AABB.Empty(), c);
		Test.Assert(!SameTransforms(a.Transforms, c.Transforms));
	}

	[Test]
	public static void DensityScalesTheCandidateCountAndTheCapStopsPlacingWhenFull()
	{
		let grid = MakeFlat(1.0f);
		defer delete grid;
		let chunk = ChunkOf(grid);

		let one = scope ScatterResult();
		Scatter.ScatterChunk(7, chunk, grid, null, null, Uniform(0.25f), AABB.Empty(), one);
		let two = scope ScatterResult();
		Scatter.ScatterChunk(7, chunk, grid, null, null, Uniform(0.5f), AABB.Empty(), two);
		Test.Assert(one.CandidateCount == 1024); // a quarter per square metre over 4096
		Test.Assert(two.CandidateCount == 2048);
		Test.Assert(one.Transforms.Count == 1024); // Uniform on a flat field keeps every one
		Test.Assert(two.Transforms.Count == 2048);
		Test.Assert(!one.DensityClamped);
		Test.Assert(Near(one.EffectiveDensity, 0.25f, 0.0001f));

		// Over budget: the loop stops once the chunk holds the cap, and the reported density
		// is what the chunk actually carries.
		var dense = Uniform(10.0f); // 40960 wanted
		dense.MaxInstancesPerChunk = 4096;
		let capped = scope ScatterResult();
		Scatter.ScatterChunk(7, chunk, grid, null, null, dense, AABB.Empty(), capped);
		Test.Assert(capped.CandidateCount == 4096); // every candidate placed, then it stopped
		Test.Assert(capped.DensityClamped);
		Test.Assert(Near(capped.EffectiveDensity, 1.0f, 0.0001f));
		Test.Assert(capped.Transforms.Count == 4096);

		// And what it kept is a PREFIX of the uncapped set: the candidate stream is stable, so
		// raising the cap only ever appends.
		var roomy = Uniform(10.0f);
		roomy.MaxInstancesPerChunk = 1 << 20;
		let full = scope ScatterResult();
		Scatter.ScatterChunk(7, chunk, grid, null, null, roomy, AABB.Empty(), full);
		Test.Assert(full.Transforms.Count > 4096);
		Test.Assert(Internal.MemCmp(full.Transforms.Ptr, capped.Transforms.Ptr,
			4096 * strideof(Float4x4)) == 0);

		// Nothing to do: no density, or an authored, Scattered, layer.
		let none = scope ScatterResult();
		Scatter.ScatterChunk(7, chunk, grid, null, null, Uniform(0.0f), AABB.Empty(), none);
		Test.Assert(none.Transforms.IsEmpty);
		// A layer whose cap is nought holds nothing however dense it is.
		var capped = Uniform(1.0f);
		capped.MaxInstancesPerChunk = 0;
		Scatter.ScatterChunk(7, chunk, grid, null, null, capped, AABB.Empty(), none);
		Test.Assert(none.Transforms.IsEmpty);
	}

	/// The cap counts PLACED instances rather than candidates, so a painted patch covering a
	/// slice of the chunk grows at the layer's own density.
	///
	/// The cap used to scale the density over the WHOLE chunk area before the mask was even
	/// consulted, so a small patch could never reach the density the layer asked for.
	[Test]
	public static void ACappedLayerStillGrowsAPaintedPatchAtItsFullDensity()
	{
		let grid = MakeFlat(1.0f);
		defer delete grid;
		let chunk = ChunkOf(grid);

		// A quarter of the footprint painted, which is 1024 of the chunk's 4096 square metres.
		let quarter = scope VegetationMask(32, 32, 1);
		for (int32 y = 0; y < 16; y++)
			for (int32 x = 0; x < 16; x++)
				quarter.SetDensity(0, x, y, 255);

		var patch = ScatterLayer();
		patch.Placement = .Mask;
		patch.MaskPlane = 0;
		patch.Density = 2.0f;
		patch.MaxSlopeDegrees = 90.0f;
		patch.MaxInstancesPerChunk = 4096;

		let grown = scope ScatterResult();
		Scatter.ScatterChunk(7, chunk, grid, null, quarter, patch, AABB.Empty(), grown);
		Test.Assert(grown.CandidateCount == 8192, "two per square metre over the whole chunk");
		Test.Assert(!grown.DensityClamped, "the patch never filled the cap");
		Test.Assert(Near(grown.EffectiveDensity, 2.0f, 0.0001f));
		// Two per square metre over the painted 1024, not the one per metre the old scaling
		// would have left.
		Test.Assert(grown.Transforms.Count > 1800);
		Test.Assert(grown.Transforms.Count < 2300);

		// A cap below that fills the patch to exactly the cap, and every one is inside it.
		patch.MaxInstancesPerChunk = 512;
		Scatter.ScatterChunk(7, chunk, grid, null, quarter, patch, AABB.Empty(), grown);
		Test.Assert(grown.Transforms.Count == 512);
		Test.Assert(grown.DensityClamped);
		Test.Assert(grown.CandidateCount < 8192, "it stopped before the stream ran out");
		for (let m in grown.Transforms)
		{
			Test.Assert(m.M[3][0] < 0.0f);
			Test.Assert(m.M[3][2] < 0.0f);
		}
	}

	[Test]
	public static void TheSplatRuleGrowsOnlyWhereTheShareClearsTheThreshold()
	{
		let grid = MakeFlat(2.0f);
		defer delete grid;
		let chunk = ChunkOf(grid);
		let splat = MakeHalfSplat();
		defer delete splat;

		var grass = ScatterLayer();
		grass.Placement = .Splat;
		grass.SplatLayer = 0;
		grass.SplatThreshold = 0.25f;
		grass.Density = 0.5f;
		grass.MaxSlopeDegrees = 90.0f;

		let painted = scope ScatterResult();
		Scatter.ScatterChunk(3, chunk, grid, splat, null, grass, AABB.Empty(), painted);
		Test.Assert(!painted.Transforms.IsEmpty);
		// Roughly half the candidates: the painted half at share one keeps every one of them.
		Test.Assert(painted.Transforms.Count > (int)painted.CandidateCount / 3);
		Test.Assert(painted.Transforms.Count < (int)painted.CandidateCount * 2 / 3);
		for (let m in painted.Transforms)
			Test.Assert(m.M[3][0] < 0.0f); // only on the painted half

		// The base layer is the complement.
		var baseLayer = grass;
		baseLayer.SplatLayer = ScatterLayer.cSplatBaseLayer;
		let unpainted = scope ScatterResult();
		Scatter.ScatterChunk(3, chunk, grid, splat, null, baseLayer, AABB.Empty(), unpainted);
		Test.Assert(!unpainted.Transforms.IsEmpty);
		for (let m in unpainted.Transforms)
			Test.Assert(m.M[3][0] > 0.0f);

		// A layer nobody painted, a threshold above every share, or no splat at all: nothing.
		var rocks = grass;
		rocks.SplatLayer = 3;
		let none = scope ScatterResult();
		Scatter.ScatterChunk(3, chunk, grid, splat, null, rocks, AABB.Empty(), none);
		Test.Assert(none.Transforms.IsEmpty);
		var strict = grass;
		strict.SplatThreshold = 1.5f;
		Scatter.ScatterChunk(3, chunk, grid, splat, null, strict, AABB.Empty(), none);
		Test.Assert(none.Transforms.IsEmpty);
		Scatter.ScatterChunk(3, chunk, grid, null, null, grass, AABB.Empty(), none);
		Test.Assert(none.Transforms.IsEmpty);

		// The share IS the sampled weight.
		Test.Assert(Near(Scatter.PlacementShareAt(grass, grid, splat, null, -16.0f, 0.0f), 1.0f, 0.001f));
		Test.Assert(Near(Scatter.PlacementShareAt(grass, grid, splat, null, 16.0f, 0.0f), 0.0f, 0.001f));
		Test.Assert(Near(Scatter.PlacementShareAt(baseLayer, grid, splat, null, 16.0f, 0.0f), 1.0f, 0.001f));
	}

	[Test]
	public static void TheSlopeLimitAndTheHeightWindowReject()
	{
		// A ramp rising 32 metres over 64: a slope of about 26.6 degrees everywhere.
		let ramp = MakeRamp(32.0f);
		defer delete ramp;
		let chunk = ChunkOf(ramp);

		var gentle = Uniform(0.25f);
		// The limit sits under the ramp's slope everywhere: the central difference halves at
		// the clamped x edges, about 13.3 degrees there, so ten keeps rejecting at the rim too.
		gentle.MaxSlopeDegrees = 10.0f;
		let none = scope ScatterResult();
		Scatter.ScatterChunk(11, chunk, ramp, null, null, gentle, AABB.Empty(), none);
		Test.Assert(none.Transforms.IsEmpty);

		var steep = Uniform(0.25f);
		steep.MaxSlopeDegrees = 35.0f; // allowed
		let all = scope ScatterResult();
		Scatter.ScatterChunk(11, chunk, ramp, null, null, steep, AABB.Empty(), all);
		Test.Assert(all.Transforms.Count == (int)all.CandidateCount);

		// The height window: only the band eight to sixteen metres up the ramp.
		var band = steep;
		band.HeightRange = .(8.0f, 16.0f);
		let banded = scope ScatterResult();
		Scatter.ScatterChunk(11, chunk, ramp, null, null, band, AABB.Empty(), banded);
		Test.Assert(!banded.Transforms.IsEmpty);
		Test.Assert(banded.Transforms.Count < all.Transforms.Count);
		for (let m in banded.Transforms)
		{
			Test.Assert(m.M[3][1] >= 8.0f - 0.05f);
			Test.Assert(m.M[3][1] <= 16.0f + 0.05f);
		}
	}

	[Test]
	public static void AlignToNormalTiltsEachInstanceAndTheScaleIsUniform()
	{
		let ramp = MakeRamp(32.0f);
		defer delete ramp;
		let chunk = ChunkOf(ramp);
		let expected = Normalized(Float3(-0.5f, 1.0f, 0.0f)); // the ramp's normal

		var flat = Uniform(0.05f);
		flat.ScaleRange = .(2.0f, 2.0f);
		let upright = scope ScatterResult();
		Scatter.ScatterChunk(5, chunk, ramp, null, null, flat, AABB.Empty(), upright);
		Test.Assert(!upright.Transforms.IsEmpty);
		for (let m in upright.Transforms)
		{
			let up = Row(m, 1);
			Test.Assert(Near(Length(up), 2.0f, 0.005f)); // the uniform scale
			Test.Assert(Near(Normalized(up).Y, 1.0f, 0.005f));
		}

		var aligned = flat;
		aligned.AlignToNormal = true;
		let tilted = scope ScatterResult();
		Scatter.ScatterChunk(5, chunk, ramp, null, null, aligned, AABB.Empty(), tilted);
		// The same candidates and the same keeps.
		Test.Assert(tilted.Transforms.Count == upright.Transforms.Count);
		for (let m in tilted.Transforms)
		{
			let up = Normalized(Row(m, 1));
			// Inside the rim the central difference is the true slope.
			if (Math.Abs(m.M[3][0]) < 31.0f)
				Test.Assert(Near(Dot(up, expected), 1.0f, 0.02f));

			// Still a right handed orthonormal frame at scale two.
			let x = Row(m, 0);
			let z = Row(m, 2);
			Test.Assert(Near(Length(x), 2.0f, 0.005f));
			Test.Assert(Near(Dot(Normalized(x), up), 0.0f, 0.02f));
			Test.Assert(Near(Dot(Normalized(z), up), 0.0f, 0.02f));
			Test.Assert(Near(Dot(Cross(Normalized(x), up), Normalized(z)), 1.0f, 0.02f));
		}
	}

	[Test]
	public static void TheMeshExtentGrowsTheChunkBoundsByTheLargestScale()
	{
		let grid = MakeFlat(3.0f);
		defer delete grid;
		let chunk = ChunkOf(grid);
		var layer = Uniform(0.1f);
		layer.ScaleRange = .(1.0f, 3.0f);
		let blade = AABB.FromCenterExtents(.(0.0f, 0.5f, 0.0f), .(0.1f, 0.5f, 0.1f));

		let r = scope ScatterResult();
		Scatter.ScatterChunk(9, chunk, grid, null, null, layer, blade, r);
		Test.Assert(!r.Transforms.IsEmpty);
		// The reach is the extent length plus the centre length, times the largest scale.
		let grow = (Length(Float3(0.1f, 0.5f, 0.1f)) + 0.5f) * 3.0f;
		Test.Assert(Near(r.LocalBounds.Min.X, chunk.Bounds.Min.X - grow, 0.01f));
		Test.Assert(Near(r.LocalBounds.Max.Y, chunk.Bounds.Max.Y + grow, 0.01f));

		let bare = scope ScatterResult();
		Scatter.ScatterChunk(9, chunk, grid, null, null, layer, AABB.Empty(), bare);
		Test.Assert(Near(bare.LocalBounds.Min.X, chunk.Bounds.Min.X, 0.01f));
	}

	[Test]
	public static void TheFadeIsFullInsideZeroBeyondAndThePrefixIsACount()
	{
		Test.Assert(Scatter.DensityAtDistance(0.0f, 40.0f, 80.0f) == 1.0f);
		Test.Assert(Scatter.DensityAtDistance(40.0f, 40.0f, 80.0f) == 1.0f);
		Test.Assert(Scatter.DensityAtDistance(80.0f, 40.0f, 80.0f) == 0.0f);
		Test.Assert(Scatter.DensityAtDistance(500.0f, 40.0f, 80.0f) == 0.0f);
		Test.Assert(Near(Scatter.DensityAtDistance(60.0f, 40.0f, 80.0f), 0.5f, 0.001f));

		var previous = 1.0f;
		for (float d = 40.0f; d <= 80.0f; d += 1.0f)
		{
			let now = Scatter.DensityAtDistance(d, 40.0f, 80.0f);
			Test.Assert(now <= previous);
			previous = now;
		}

		// A degenerate window is a hard cut at the end.
		Test.Assert(Scatter.DensityAtDistance(79.0f, 80.0f, 80.0f) == 1.0f);
		Test.Assert(Scatter.DensityAtDistance(80.0f, 80.0f, 80.0f) == 0.0f);

		Test.Assert(Scatter.FadePrefix(1000, 1.0f) == 1000);
		Test.Assert(Scatter.FadePrefix(1000, 0.0f) == 0);
		Test.Assert(Scatter.FadePrefix(1000, 0.5f) == 500);
		Test.Assert(Scatter.FadePrefix(1000, 2.0f) == 1000);
		Test.Assert(Scatter.FadePrefix(3, 0.5f) == 2); // rounds
		Test.Assert(Scatter.FadePrefix(0, 0.5f) == 0);
	}

	[Test]
	public static void ChunksTouchedByMapsAGridRegionToTheChunksSharingItsSamples()
	{
		let touched = scope List<uint32>();
		var inside = HeightfieldRegion();
		inside.MinX = 10;
		inside.MaxX = 20;
		inside.MinZ = 70;
		inside.MaxZ = 80;
		Scatter.ChunksTouchedBy(inside, 4, touched); // a 257 sample grid: four by four chunks
		Test.Assert(touched.Count == 1);
		Test.Assert(touched[0] == 4); // chunk (0, 1)

		// A region ending ON the shared boundary sample touches both chunks.
		touched.Clear();
		var edge = HeightfieldRegion();
		edge.MinX = 60;
		edge.MaxX = 64;
		edge.MinZ = 5;
		edge.MaxZ = 6;
		Scatter.ChunksTouchedBy(edge, 4, touched);
		Test.Assert(touched.Count == 2);
		Test.Assert(touched[0] == 0);
		Test.Assert(touched[1] == 1);

		// A region starting on a boundary sample touches the chunk before it too.
		touched.Clear();
		var corner = HeightfieldRegion();
		corner.MinX = 64;
		corner.MaxX = 64;
		corner.MinZ = 64;
		corner.MaxZ = 64;
		Scatter.ChunksTouchedBy(corner, 4, touched);
		Test.Assert(touched.Count == 4);

		// It APPENDS uniquely: the same region again adds nothing, nor does an empty one.
		Scatter.ChunksTouchedBy(corner, 4, touched);
		Test.Assert(touched.Count == 4);
		Scatter.ChunksTouchedBy(HeightfieldRegion(), 4, touched);
		Test.Assert(touched.Count == 4);

		// Clamped to the grid.
		touched.Clear();
		var beyond = HeightfieldRegion();
		beyond.MinX = 250;
		beyond.MaxX = 400;
		beyond.MinZ = 0;
		beyond.MaxZ = 0;
		Scatter.ChunksTouchedBy(beyond, 4, touched);
		Test.Assert(touched.Count == 1);
		Test.Assert(touched[0] == 3);
	}

	[Test]
	public static void TheScatterHashCoversTheScatterParametersNotTheDrawState()
	{
		let a = ScatterLayer();
		var b = a;
		Test.Assert(VegetationLayers.LayerScatterHash(a) == VegetationLayers.LayerScatterHash(b));
		b.Density = 3.0f;
		Test.Assert(VegetationLayers.LayerScatterHash(a) != VegetationLayers.LayerScatterHash(b));

		// The fade and the shadow flag are draw time, so they never regrow.
		b = a;
		b.FadeEnd = 200.0f;
		b.CastShadows = true;
		Test.Assert(VegetationLayers.LayerScatterHash(a) == VegetationLayers.LayerScatterHash(b));

		for (let p in scope VegetationPlacement[](.Uniform, .Mask))
		{
			b = a;
			b.Placement = p;
			Test.Assert(VegetationLayers.LayerScatterHash(a) != VegetationLayers.LayerScatterHash(b));
		}
	}

	/// A painted mask grows where it has density, and carves a splat layer when the two
	/// multiply. The splat threshold gates only the splat modes: a mask's density IS its
	/// share, so a faint paint thins rather than disappearing.
	[Test]
	public static void TheMaskPlacementGrowsWhereThePlaneHasDensity()
	{
		let grid = MakeFlat(1.0f);
		defer delete grid;
		let chunk = ChunkOf(grid);

		// Full density over the left half of the footprint, on plane one.
		let mask = scope VegetationMask(32, 32, 2);
		for (int32 y = 0; y < 32; y++)
			for (int32 x = 0; x < 16; x++)
				mask.SetDensity(1, x, y, 255);

		var layer = Uniform(0.25f);
		layer.Placement = .Mask;
		layer.MaskPlane = 1;

		let painted = scope ScatterResult();
		Scatter.ScatterChunk(5, chunk, grid, null, mask, layer, AABB.Empty(), painted);
		Test.Assert(!painted.Transforms.IsEmpty);
		for (let m in painted.Transforms)
			Test.Assert(m.M[3][0] < 0.0f, "only where the plane is painted");

		// An unpainted plane grows nothing, and neither does a missing mask.
		var other = layer;
		other.MaskPlane = 0;
		let none = scope ScatterResult();
		Scatter.ScatterChunk(5, chunk, grid, null, mask, other, AABB.Empty(), none);
		Test.Assert(none.Transforms.IsEmpty);
		Scatter.ScatterChunk(5, chunk, grid, null, null, layer, AABB.Empty(), none);
		Test.Assert(none.Transforms.IsEmpty);

		// A HALF density plane thins rather than disappearing: the threshold is a splat rule.
		let faint = scope VegetationMask(32, 32, 1);
		for (int32 y = 0; y < 32; y++)
			for (int32 x = 0; x < 32; x++)
				faint.SetDensity(0, x, y, 128);
		var half = Uniform(0.25f);
		half.Placement = .Mask;
		half.MaskPlane = 0;
		half.SplatThreshold = 0.9f; // ignored for a mask
		let thinned = scope ScatterResult();
		Scatter.ScatterChunk(5, chunk, grid, null, faint, half, AABB.Empty(), thinned);
		Test.Assert(!thinned.Transforms.IsEmpty, "a faint mask still grows");
		Test.Assert(thinned.Transforms.Count < (int)thinned.CandidateCount * 3 / 4);
		Test.Assert(thinned.Transforms.Count > (int)thinned.CandidateCount / 4);

		// SplatTimesMask is the PRODUCT: the painted splat half carved by the mask half.
		let splat = MakeHalfSplat();
		defer delete splat;
		var carved = Uniform(0.5f);
		carved.Placement = .SplatTimesMask;
		carved.SplatLayer = 0;
		carved.SplatThreshold = 0.25f;
		carved.MaskPlane = 0;
		// The mask covers the upper half of the footprint.
		let band = scope VegetationMask(32, 32, 1);
		for (int32 y = 0; y < 16; y++)
			for (int32 x = 0; x < 32; x++)
				band.SetDensity(0, x, y, 255);
		let product = scope ScatterResult();
		Scatter.ScatterChunk(5, chunk, grid, splat, band, carved, AABB.Empty(), product);
		Test.Assert(!product.Transforms.IsEmpty);
		for (let m in product.Transforms)
		{
			Test.Assert(m.M[3][0] < 0.0f, "inside the painted splat half");
			Test.Assert(m.M[3][2] < 0.0f, "and inside the masked band");
		}

		// Either side missing makes the product nothing.
		Scatter.ScatterChunk(5, chunk, grid, null, band, carved, AABB.Empty(), none);
		Test.Assert(none.Transforms.IsEmpty);
		Scatter.ScatterChunk(5, chunk, grid, splat, null, carved, AABB.Empty(), none);
		Test.Assert(none.Transforms.IsEmpty);
	}

	/// The brush stamp: a deterministic count inside the disc, and each rejection rule.
	[Test]
	public static void ASeededStampPlacesInsideTheDiscAndTheRulesReject()
	{
		let grid = MakeFlat(2.0f);
		defer delete grid;

		var rocks = Uniform(0.0f);
		rocks.ScaleRange = .(1.0f, 1.0f);
		rocks.MaxSlopeDegrees = 90.0f;
		let rock = AABB.FromCenterExtents(.(0, 0.5f, 0), .(0.5f, 0.5f, 0.5f));

		let a = scope List<Float4x4>();
		let placed = Scatter.ScatterStamp(99, grid, rocks, rock, 4.0f, -3.0f, 6.0f, 0.5f, 1.0f,
			0.0f, default, null, a);
		// Half a rock per square metre over a disc of six metres.
		Test.Assert(placed.Candidates == 57);
		// Flat, unspaced and unblocked: every candidate lands.
		Test.Assert(placed.Placed == 57);
		Test.Assert(a.Count == 57);
		for (let m in a)
		{
			let dx = m.M[3][0] - 4.0f;
			let dz = m.M[3][2] + 3.0f;
			Test.Assert(((dx * dx) + (dz * dz)) <= (36.0f + 0.001f), "inside the disc");
			Test.Assert(Near(m.M[3][1], 2.0f), "on the field");
		}

		// The same seed places the same instances and another seed does not; the amount scales
		// the count.
		let b = scope List<Float4x4>();
		Scatter.ScatterStamp(99, grid, rocks, rock, 4.0f, -3.0f, 6.0f, 0.5f, 1.0f, 0.0f, default,
			null, b);
		Test.Assert(SameTransforms(a, b));
		let c = scope List<Float4x4>();
		Scatter.ScatterStamp(100, grid, rocks, rock, 4.0f, -3.0f, 6.0f, 0.5f, 1.0f, 0.0f, default,
			null, c);
		Test.Assert(!SameTransforms(a, c));
		let half = scope List<Float4x4>();
		Test.Assert(Scatter.ScatterStamp(99, grid, rocks, rock, 4.0f, -3.0f, 6.0f, 0.5f, 0.5f,
			0.0f, default, null, half).Candidates == 28);

		// Spacing: a rock of about 0.87 metres of radius at a spacing of two keeps the props
		// some 1.7 metres apart, so far fewer land and none of them is within reach of one
		// that was already there.
		let spaced = scope List<Float4x4>();
		let spacedResult = Scatter.ScatterStamp(99, grid, rocks, rock, 4.0f, -3.0f, 6.0f, 2.0f,
			1.0f, 2.0f, a, null, spaced);
		Test.Assert(spacedResult.RejectedSpacing > 0);
		Test.Assert((spacedResult.Placed + spacedResult.RejectedSpacing) == spacedResult.Candidates);
		let reach = 2.0f * Length(rock.Extents());
		for (let m in spaced)
		{
			for (let e in a)
			{
				let dx = m.M[3][0] - e.M[3][0];
				let dz = m.M[3][2] - e.M[3][2];
				Test.Assert(((dx * dx) + (dz * dz)) >= ((reach * reach) - 0.001f), "kept apart");
			}
		}

		// The blocked query, which the editor wires to the physics world's overlap.
		let blocked = scope List<Float4x4>();
		let blockedResult = Scatter.ScatterStamp(99, grid, rocks, rock, 4.0f, -3.0f, 6.0f, 0.5f,
			1.0f, 0.0f, default, scope (position, radius) => position.X > 4.0f, blocked);
		Test.Assert(blockedResult.RejectedBlocked > 0);
		Test.Assert((blockedResult.Placed + blockedResult.RejectedBlocked) == blockedResult.Candidates);
		for (let m in blocked)
			Test.Assert(m.M[3][0] <= 4.0f, "nothing lands where the query says no");

		// The slope rule: a steep ramp under a tight limit places nothing.
		let ramp = MakeRamp(32.0f);
		defer delete ramp;
		var gentle = rocks;
		gentle.MaxSlopeDegrees = 10.0f;
		let none = scope List<Float4x4>();
		let noneResult = Scatter.ScatterStamp(5, ramp, gentle, rock, 0.0f, 0.0f, 6.0f, 0.5f,
			1.0f, 0.0f, default, null, none);
		Test.Assert(none.IsEmpty);
		Test.Assert(noneResult.RejectedRules == noneResult.Candidates);

		// The eraser takes what is inside the disc and leaves the rest in order.
		let field = scope List<Float4x4>();
		field.AddRange(a);
		let removed = Scatter.EraseInstancesInDisc(field, 4.0f, -3.0f, 3.0f);
		Test.Assert(removed > 0);
		Test.Assert((field.Count + (int)removed) == a.Count);
		for (let m in field)
		{
			let dx = m.M[3][0] - 4.0f;
			let dz = m.M[3][2] + 3.0f;
			Test.Assert(((dx * dx) + (dz * dz)) > 9.0f, "what is left is outside the disc");
		}
		Test.Assert(Scatter.EraseInstancesInDisc(field, 100.0f, 100.0f, 1.0f) == 0);

		// Degenerate inputs place nothing.
		Test.Assert(Scatter.ScatterStamp(1, grid, rocks, rock, 0, 0, 0.0f, 1.0f, 1.0f, 0.0f,
			default, null, none).Candidates == 0);
		Test.Assert(Scatter.ScatterStamp(1, grid, rocks, rock, 0, 0, 5.0f, 0.0f, 1.0f, 0.0f,
			default, null, none).Candidates == 0);
	}

	/// A CUT cell has no surface, so nothing grows over it and no prop stands on it: the same
	/// rule the renderer's indices and the physics body follow.
	[Test]
	public static void NothingGrowsOverACutCell()
	{
		let grid = MakeFlat(2.0f);
		defer delete grid;
		let chunk = ChunkOf(grid);

		var grass = Uniform(2.0f);
		grass.MaxSlopeDegrees = 90.0f;

		let before = scope ScatterResult();
		Scatter.ScatterChunk(9, chunk, grid, null, null, grass, AABB.Empty(), before);
		Test.Assert(!before.Transforms.IsEmpty);

		// Cut the whole grid: the placement share is nought everywhere, so nothing is placed.
		for (int32 z = 0; z < cGrid; z++)
			for (int32 x = 0; x < cGrid; x++)
				grid.SetHole(x, z, true);

		let after = scope ScatterResult();
		Scatter.ScatterChunk(9, chunk, grid, null, null, grass, AABB.Empty(), after);
		Test.Assert(after.Transforms.IsEmpty, "a cut field grows nothing");
		Test.Assert(Scatter.PlacementShareAt(grass, grid, null, null, 0.0f, 0.0f) == 0.0f);

		// And the prop stamp rejects every candidate for the same reason, counting them as a
		// rules rejection rather than silently placing none.
		var rocks = grass;
		rocks.ScaleRange = .(1.0f, 1.0f);
		let props = scope List<Float4x4>();
		let stamp = Scatter.ScatterStamp(3, grid, rocks, AABB.Empty(), 0.0f, 0.0f, 6.0f, 0.5f,
			1.0f, 0.0f, default, null, props);
		Test.Assert(props.IsEmpty);
		Test.Assert(stamp.Candidates > 0);
		Test.Assert(stamp.RejectedRules == stamp.Candidates);
	}
}
