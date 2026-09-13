using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Engine.Terrain;
using Sedulous.Heightfield;
using Sedulous.Render;
using Sedulous.Scene;
using Sedulous.Terrain.Resource;

namespace Sedulous.Engine.Terrain.Tests;

/// The GPU splat caches: the weight and index texture PAIR per painted raster, the palette
/// array and its tile scale buffer, and what a paint or a scale edit does to each.
class SplatTextureCacheTests
{
	/// The smallest VALID palette blob: `slices` slices of a four by four chain, whose three
	/// mips exercise the chain arithmetic.
	private static TerrainPaletteData MakePalette(uint32 slices)
	{
		let data = new TerrainPaletteData();
		data.SliceSize = 4;
		data.MipCount = 3;
		data.SliceCount = slices;

		let bytes = TerrainPaletteData.SliceBytes(4, 3) * (int)slices;
		data.Texels.Resize(bytes);
		for (int i < bytes)
			data.Texels[i] = 200;

		return data;
	}

	[Test]
	public static void ThePairCachesByUidAndVersionAndABumpRetiresIt()
	{
		let fixture = scope NullDeviceFixture();

		let retire = scope GpuRetireQueue();
		retire.Initialize(fixture.Device, 2);

		let cache = scope TerrainSplatTextureCache();
		cache.SetRetireQueue(retire);

		let weights = scope SplatWeights(8, 8);
		SplatBrush.Paint(weights, 0.5f, 0.5f, 0.5f, 0.5f, 3, 1.0f);

		let first = cache.GetOrCreate(fixture.Device, weights, weights.Version);
		Test.Assert(first.WeightView != null);
		Test.Assert(first.IndexView != null);
		Test.Assert(first.WeightView !== first.IndexView);
		Test.Assert(cache.Size == 1);

		// The same identity at the same version returns the SAME views, with no rebuild.
		let again = cache.GetOrCreate(fixture.Device, weights, weights.Version);
		Test.Assert(again.WeightView === first.WeightView);
		Test.Assert(again.IndexView === first.IndexView);
		Test.Assert(cache.Size == 1);
		Test.Assert(retire.PendingCount == 0);

		// A paint bumps the version: the entry rebuilds in place and BOTH old textures and
		// their views are retired, a submitted frame still sampling them.
		weights.BumpVersion();
		let second = cache.GetOrCreate(fixture.Device, weights, weights.Version);
		Test.Assert(second.WeightView != null);
		Test.Assert(second.WeightView !== first.WeightView);
		Test.Assert(second.IndexView !== first.IndexView);
		Test.Assert(cache.Size == 1);
		Test.Assert(retire.PendingCount == 4);

		cache.Clear(fixture.Device);
		retire.Flush();
	}

	[Test]
	public static void TwoDistinctRastersNeverAlias()
	{
		let fixture = scope NullDeviceFixture();
		let cache = scope TerrainSplatTextureCache();

		let a = scope SplatWeights(4, 4);
		let b = scope SplatWeights(4, 4);
		Test.Assert(a.Uid != b.Uid);

		let va = cache.GetOrCreate(fixture.Device, a, a.Version);
		let vb = cache.GetOrCreate(fixture.Device, b, b.Version);
		Test.Assert(va.WeightView != null);
		Test.Assert(vb.WeightView != null);
		Test.Assert(va.WeightView !== vb.WeightView);
		Test.Assert(va.IndexView !== vb.IndexView);
		Test.Assert(cache.Size == 2);

		cache.Clear(fixture.Device);
		Test.Assert(cache.Size == 0);
	}

	[Test]
	public static void AnEmptyRasterYieldsNoTextures()
	{
		let fixture = scope NullDeviceFixture();
		let cache = scope TerrainSplatTextureCache();

		let empty = scope SplatWeights();
		let views = cache.GetOrCreate(fixture.Device, empty, empty.Version);
		Test.Assert(views.WeightView == null);
		Test.Assert(views.IndexView == null);
		Test.Assert(cache.Size == 0);
	}

	[Test]
	public static void ThePaletteKeysByDataAndTheScaleHash()
	{
		let fixture = scope NullDeviceFixture();

		let retire = scope GpuRetireQueue();
		retire.Initialize(fixture.Device, 2);

		let cache = scope TerrainPaletteTextureCache();
		cache.SetRetireQueue(retire);

		let data = MakePalette(3);
		defer delete data;

		let scales = scope List<float>();
		scales.Add(4.0f);
		scales.Add(8.0f);
		scales.Add(2.0f);

		let first = cache.GetOrCreate(fixture.Device, data, scales);
		Test.Assert(first.ArrayView != null);
		Test.Assert(first.TileScaleBuffer != null);
		Test.Assert(first.Generation == 1);
		Test.Assert(cache.Size == 1);

		// The same data and the same scales return the SAME objects.
		let same = cache.GetOrCreate(fixture.Device, data, scales);
		Test.Assert(same.ArrayView === first.ArrayView);
		Test.Assert(same.TileScaleBuffer === first.TileScaleBuffer);
		Test.Assert(same.Generation == first.Generation);
		Test.Assert(retire.PendingCount == 0);

		// A per layer scale edit, which re-cooks nothing and so keeps the same identity,
		// rebuilds with the old set retired and the generation BUMPED: the material bind
		// cache keys on it.
		scales[1] = 16.0f;
		let second = cache.GetOrCreate(fixture.Device, data, scales);
		Test.Assert(second.ArrayView != null);
		Test.Assert(second.Generation == 2);
		Test.Assert(cache.Size == 1);
		Test.Assert(retire.PendingCount == 3);

		// A re-cook IS a new palette, and so a second entry.
		let recooked = MakePalette(3);
		defer delete recooked;
		Test.Assert(recooked.Uid != data.Uid);

		let third = cache.GetOrCreate(fixture.Device, recooked, scales);
		Test.Assert(third.ArrayView != null);
		Test.Assert(third.ArrayView !== second.ArrayView);
		Test.Assert(cache.Size == 2);

		cache.Clear(fixture.Device);
		Test.Assert(cache.Size == 0);
		retire.Flush();
	}

	[Test]
	public static void InvalidPaletteDataYieldsNothing()
	{
		let fixture = scope NullDeviceFixture();
		let cache = scope TerrainPaletteTextureCache();

		// Zero sized, which is what an uncooked palette looks like.
		let bad = scope TerrainPaletteData();
		let gpu = cache.GetOrCreate(fixture.Device, bad, scope List<float>());
		Test.Assert(gpu.ArrayView == null);
		Test.Assert(gpu.TileScaleBuffer == null);
		Test.Assert(cache.Size == 0);
	}

	[Test]
	public static void AWeightsBearingTerrainDerivesBothOnExtract()
	{
		let fixture = scope NullDeviceFixture();

		let scene = scope Scene();
		TerrainScene.AddTerrainSceneManagers(scene);

		let manager = scene.GetSystem<TerrainComponentManager>();
		Test.Assert(manager != null);
		manager.SetRenderContext(fixture.Device, 7);

		let grid = scope Heightfield(65, .(64.0f, 64.0f), 0.0f, 10.0f);
		let weights = scope SplatWeights(32, 32);
		SplatBrush.Paint(weights, 0.5f, 0.5f, 0.4f, 0.4f, 0, 1.0f);

		let resource = scope TerrainResource();
		resource.Heightfield.SetDirect(grid);
		resource.Weights.SetDirect(weights);
		resource.Palette.Add(.());
		resource.PaletteData = MakePalette(1);

		let entity = scene.CreateEntity("terrain");
		manager.Add(entity).Terrain.SetDirect(resource);
		scene.Start();

		let snapshot = scope ExtractedScene();
		manager.ExtractRenderData(snapshot);
		Test.Assert(manager.SplatTextureCount == 1);
		Test.Assert(manager.PaletteTextureCount == 1);

		manager.ClearGpu();
		Test.Assert(manager.SplatTextureCount == 0);
		Test.Assert(manager.PaletteTextureCount == 0);
	}
}
