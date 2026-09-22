using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Heightfield;
using Sedulous.Terrain;
using Sedulous.Terrain.Resource;
using Sedulous.Vegetation;

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
		Scatter.ScatterChunk(seed, chunk, grid, null, layer, AABB.Empty(), a);
		Scatter.ScatterChunk(seed, chunk, grid, null, layer, AABB.Empty(), b);
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
		Scatter.ScatterChunk(Scatter.ChunkSeed(ownerId, 0, 1, 0), chunk, grid, null, layer,
			AABB.Empty(), c);
		Test.Assert(!SameTransforms(a.Transforms, c.Transforms));
	}

	[Test]
	public static void DensityScalesTheCandidateCountAndTheCapScalesDensityDown()
	{
		let grid = MakeFlat(1.0f);
		defer delete grid;
		let chunk = ChunkOf(grid);

		let one = scope ScatterResult();
		Scatter.ScatterChunk(7, chunk, grid, null, Uniform(0.25f), AABB.Empty(), one);
		let two = scope ScatterResult();
		Scatter.ScatterChunk(7, chunk, grid, null, Uniform(0.5f), AABB.Empty(), two);
		Test.Assert(one.CandidateCount == 1024); // a quarter per square metre over 4096
		Test.Assert(two.CandidateCount == 2048);
		Test.Assert(one.Transforms.Count == 1024); // Uniform on a flat field keeps every one
		Test.Assert(two.Transforms.Count == 2048);
		Test.Assert(!one.DensityClamped);
		Test.Assert(Near(one.EffectiveDensity, 0.25f, 0.0001f));

		// Over budget: the cap wins and the density reports what was actually used.
		var dense = Uniform(10.0f); // 40960 wanted
		dense.MaxInstancesPerChunk = 4096;
		let capped = scope ScatterResult();
		Scatter.ScatterChunk(7, chunk, grid, null, dense, AABB.Empty(), capped);
		Test.Assert(capped.CandidateCount == 4096);
		Test.Assert(capped.DensityClamped);
		Test.Assert(Near(capped.EffectiveDensity, 1.0f, 0.0001f));
		Test.Assert(capped.Transforms.Count == 4096);

		// Nothing to do: no density, or an authored, Scattered, layer.
		let none = scope ScatterResult();
		Scatter.ScatterChunk(7, chunk, grid, null, Uniform(0.0f), AABB.Empty(), none);
		Test.Assert(none.Transforms.IsEmpty);
		var authored = Uniform(1.0f);
		authored.Placement = .Scattered;
		Scatter.ScatterChunk(7, chunk, grid, null, authored, AABB.Empty(), none);
		Test.Assert(none.Transforms.IsEmpty);
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
		Scatter.ScatterChunk(3, chunk, grid, splat, grass, AABB.Empty(), painted);
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
		Scatter.ScatterChunk(3, chunk, grid, splat, baseLayer, AABB.Empty(), unpainted);
		Test.Assert(!unpainted.Transforms.IsEmpty);
		for (let m in unpainted.Transforms)
			Test.Assert(m.M[3][0] > 0.0f);

		// A layer nobody painted, a threshold above every share, or no splat at all: nothing.
		var rocks = grass;
		rocks.SplatLayer = 3;
		let none = scope ScatterResult();
		Scatter.ScatterChunk(3, chunk, grid, splat, rocks, AABB.Empty(), none);
		Test.Assert(none.Transforms.IsEmpty);
		var strict = grass;
		strict.SplatThreshold = 1.5f;
		Scatter.ScatterChunk(3, chunk, grid, splat, strict, AABB.Empty(), none);
		Test.Assert(none.Transforms.IsEmpty);
		Scatter.ScatterChunk(3, chunk, grid, null, grass, AABB.Empty(), none);
		Test.Assert(none.Transforms.IsEmpty);

		// The share IS the sampled weight.
		Test.Assert(Near(Scatter.PlacementShareAt(grass, grid, splat, -16.0f, 0.0f), 1.0f, 0.001f));
		Test.Assert(Near(Scatter.PlacementShareAt(grass, grid, splat, 16.0f, 0.0f), 0.0f, 0.001f));
		Test.Assert(Near(Scatter.PlacementShareAt(baseLayer, grid, splat, 16.0f, 0.0f), 1.0f, 0.001f));
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
		Scatter.ScatterChunk(11, chunk, ramp, null, gentle, AABB.Empty(), none);
		Test.Assert(none.Transforms.IsEmpty);

		var steep = Uniform(0.25f);
		steep.MaxSlopeDegrees = 35.0f; // allowed
		let all = scope ScatterResult();
		Scatter.ScatterChunk(11, chunk, ramp, null, steep, AABB.Empty(), all);
		Test.Assert(all.Transforms.Count == (int)all.CandidateCount);

		// The height window: only the band eight to sixteen metres up the ramp.
		var band = steep;
		band.HeightRange = .(8.0f, 16.0f);
		let banded = scope ScatterResult();
		Scatter.ScatterChunk(11, chunk, ramp, null, band, AABB.Empty(), banded);
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
		Scatter.ScatterChunk(5, chunk, ramp, null, flat, AABB.Empty(), upright);
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
		Scatter.ScatterChunk(5, chunk, ramp, null, aligned, AABB.Empty(), tilted);
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
		Scatter.ScatterChunk(9, chunk, grid, null, layer, blade, r);
		Test.Assert(!r.Transforms.IsEmpty);
		// The reach is the extent length plus the centre length, times the largest scale.
		let grow = (Length(Float3(0.1f, 0.5f, 0.1f)) + 0.5f) * 3.0f;
		Test.Assert(Near(r.LocalBounds.Min.X, chunk.Bounds.Min.X - grow, 0.01f));
		Test.Assert(Near(r.LocalBounds.Max.Y, chunk.Bounds.Max.Y + grow, 0.01f));

		let bare = scope ScatterResult();
		Scatter.ScatterChunk(9, chunk, grid, null, layer, AABB.Empty(), bare);
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
}
