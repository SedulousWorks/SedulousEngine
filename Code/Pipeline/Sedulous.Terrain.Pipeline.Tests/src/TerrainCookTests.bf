using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Heightfield;
using Sedulous.Heightfield.Resource;
using Sedulous.Resource;
using Sedulous.Terrain.Resource;

namespace Sedulous.Terrain.Pipeline.Tests;

/// The terrain cook: an authored terrain into a product that binds its shared grid and carries
/// every reference it was given.
class TerrainCookTests
{
	private static bool Near(float a, float b, float tolerance = 0.001f) => Abs(a - b) <= tolerance;

	/// Binds the cooked terrain, running the body with it.
	///
	/// A delegate rather than a return, because the terrain BORROWS from the manager and the
	/// database, and both have to outlive the reading.
	private static void Bind(TerrainFixture fixture, Guid terrainId,
		delegate void(TerrainResource terrain) body)
	{
		let manager = scope ResourceManager(fixture.Database, null);
		let heightfields = scope HeightfieldFactory();
		let terrains = scope TerrainFactory();
		manager.AddFactory(heightfields);
		manager.AddFactory(terrains);

		let bound = manager.Bind<TerrainResource>(terrainId);
		Test.Assert(bound.Get != null);
		body(bound.Get);
	}

	/// Every authored reference survives the cook, and the shared grid RESOLVES.
	///
	/// The ids matter as much as the binding: the editor walks back from a terrain to the
	/// heightfield asset through them rather than searching for it.
	[Test]
	public static void ATerrainCooksAndResolvesItsSharedHeightfield()
	{
		let fixture = scope TerrainFixture("scratch_terrain_cook");
		let heightfieldId = fixture.AddHeightfield();
		let product = fixture.AddTerrainProduct();
		let terrainId = product.Id;

		let weightsId = Guid(123, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);
		let baseAlbedoId = Guid(111, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2);
		let paletteAlbedoId = Guid(321, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3);
		{
			let asset = scope TerrainAsset();
			asset.HeightfieldId = heightfieldId;
			asset.WeightsId = weightsId;
			asset.BaseAlbedoId = baseAlbedoId;
			asset.BaseTileScale = 16.0f;
			asset.PaletteAlbedoIds.Add(paletteAlbedoId);
			asset.PaletteAlbedoIds.Add(.Empty);
			asset.PaletteTileScales.Add(4.0f);
			asset.PaletteTileScales.Add(8.0f);
			asset.PaletteTextureSize = 64; // a small array keeps the cook quick
			asset.CastShadows = false;
			fixture.Cook(asset, product);
		}

		Bind(fixture, terrainId, scope (terrain) =>
			{
				Test.Assert(!terrain.CastShadows);
				Test.Assert(terrain.PaletteCount == 2);
				Test.Assert(Near(terrain.Base.TileScale, 16.0f));
				Test.Assert(Near(terrain.Palette[0].TileScale, 4.0f));
				Test.Assert(Near(terrain.Palette[1].TileScale, 8.0f));

				Test.Assert(terrain.Heightfield.Get != null);
				Test.Assert(terrain.Heightfield.Get.Size == 65);

				// A non nil id BINDS even with no texture factory present: what the reference
				// resolves to on the GPU is the backend's business, not the cook's.
				Test.Assert(terrain.Weights.IsBound);
				Test.Assert(terrain.Base.Albedo.IsBound);
				Test.Assert(terrain.Palette[0].Albedo.IsBound);
				Test.Assert(!terrain.Palette[1].Albedo.IsBound); // a nil id stays unbound

				Test.Assert(terrain.Heightfield.Id == heightfieldId);
				Test.Assert(terrain.Weights.Id == weightsId);
				Test.Assert(terrain.Base.Albedo.Id == baseAlbedoId);
				Test.Assert(terrain.Palette[0].Albedo.Id == paletteAlbedoId);
			});
	}

	/// A palette array is built ON DEMAND: one only exists when some layer authored that map.
	///
	/// Otherwise every terrain would carry four full arrays of defaults, which is most of a
	/// terrain's memory spent on maps nothing samples.
	[Test]
	public static void APaletteArrayIsOnlyBuiltWhenALayerUsesIt()
	{
		let fixture = scope TerrainFixture("scratch_terrain_normal");
		let heightfieldId = fixture.AddHeightfield();
		let product = fixture.AddTerrainProduct();
		let terrainId = product.Id;

		let baseNormalId = Guid(11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4);
		let paletteNormalId = Guid(55, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5);
		{
			let asset = scope TerrainAsset();
			asset.HeightfieldId = heightfieldId;
			asset.BaseAlbedoId = Guid(111, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2);
			asset.BaseNormalId = baseNormalId;
			asset.BaseOrmId = Guid(33, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6);
			asset.BaseTileScale = 16.0f;
			asset.PaletteTextureSize = 64;
			asset.PaletteAlbedoIds.Add(Guid(321, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3));
			asset.PaletteAlbedoIds.Add(.Empty);
			asset.PaletteNormalIds.Add(paletteNormalId); // layer nought has one
			asset.PaletteNormalIds.Add(.Empty);          // layer one does not
			asset.PaletteTileScales.Add(4.0f);
			asset.PaletteTileScales.Add(8.0f);
			fixture.Cook(asset, product);
		}

		Test.Assert(TerrainFixture.HasStream(product, TerrainPaletteData.NormalStream));
		// No layer authored an occlusion map, so no array was built for one.
		Test.Assert(!TerrainFixture.HasStream(product, TerrainPaletteData.OrmStream));

		// The layer with NO normal still gets a slice, and it is the flat one, so sampling the
		// array is uniform whatever a layer authored.
		let texels = scope List<uint8>();
		TerrainFixture.ReadPalette(product, TerrainPaletteData.NormalStream, texels,
			let sliceSize, let mipCount, let sliceCount);
		Test.Assert(sliceCount == 2);
		let secondSlice = TerrainPaletteData.SliceBytes(sliceSize, mipCount);
		Test.Assert(texels[secondSlice + 0] == 128);
		Test.Assert(texels[secondSlice + 1] == 128);
		Test.Assert(texels[secondSlice + 2] == 255);
		Test.Assert(texels[secondSlice + 3] == 255);

		Bind(fixture, terrainId, scope (terrain) =>
			{
				Test.Assert(terrain.Base.Normal.IsBound);
				Test.Assert(terrain.Base.Normal.Id == baseNormalId);
				Test.Assert(terrain.Base.Orm.IsBound);
				Test.Assert(terrain.Palette[0].Normal.IsBound);
				Test.Assert(terrain.Palette[0].Normal.Id == paletteNormalId);
				Test.Assert(!terrain.Palette[1].Normal.IsBound);
				Test.Assert(!terrain.Palette[0].Orm.IsBound); // none were authored

				Test.Assert(terrain.PaletteData.HasNormal);
				Test.Assert(!terrain.PaletteData.HasOrm);
			});
	}

	/// An albedo only terrain carries ONE array and nothing else.
	[Test]
	public static void AnAlbedoOnlyTerrainBuildsNoOtherArrays()
	{
		let fixture = scope TerrainFixture("scratch_terrain_albedo_only");
		let heightfieldId = fixture.AddHeightfield();
		let product = fixture.AddTerrainProduct();
		let terrainId = product.Id;

		{
			let asset = scope TerrainAsset();
			asset.HeightfieldId = heightfieldId;
			asset.BaseAlbedoId = Guid(111, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2);
			asset.PaletteTextureSize = 64;
			asset.PaletteAlbedoIds.Add(Guid(321, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3));
			asset.PaletteTileScales.Add(4.0f);
			fixture.Cook(asset, product);
		}

		Test.Assert(!TerrainFixture.HasStream(product, TerrainPaletteData.NormalStream));
		Test.Assert(!TerrainFixture.HasStream(product, TerrainPaletteData.OrmStream));

		Bind(fixture, terrainId, scope (terrain) =>
			{
				Test.Assert(terrain.PaletteData.IsValid);
				Test.Assert(!terrain.PaletteData.HasNormal);
				Test.Assert(!terrain.PaletteData.HasOrm);
				Test.Assert(!terrain.PaletteData.HasHeight);
				Test.Assert(!terrain.PaletteData.HasMask);
			});
	}

	/// Height maps drive the blend between layers, so the authored CONTRAST has to survive with
	/// them, and a layer without one gets the mid height that blends neutrally.
	[Test]
	public static void HeightMapsAndTheirContrastSurviveTheCook()
	{
		let fixture = scope TerrainFixture("scratch_terrain_height");
		let heightfieldId = fixture.AddHeightfield();
		let product = fixture.AddTerrainProduct();
		let terrainId = product.Id;

		let baseHeightId = Guid(77, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7);
		let paletteHeightId = Guid(55, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8);
		{
			let asset = scope TerrainAsset();
			asset.HeightfieldId = heightfieldId;
			asset.BaseAlbedoId = Guid(111, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2);
			asset.BaseHeightId = baseHeightId;
			asset.HeightBlendContrast = 0.4f;
			asset.BaseTileScale = 16.0f;
			asset.PaletteTextureSize = 64;
			asset.PaletteAlbedoIds.Add(Guid(321, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3));
			asset.PaletteAlbedoIds.Add(.Empty);
			asset.PaletteHeightIds.Add(paletteHeightId);
			asset.PaletteHeightIds.Add(.Empty);
			asset.PaletteTileScales.Add(4.0f);
			asset.PaletteTileScales.Add(8.0f);
			fixture.Cook(asset, product);
		}

		Test.Assert(TerrainFixture.HasStream(product, TerrainPaletteData.HeightStream));
		Test.Assert(!TerrainFixture.HasStream(product, TerrainPaletteData.NormalStream));

		let texels = scope List<uint8>();
		TerrainFixture.ReadPalette(product, TerrainPaletteData.HeightStream, texels,
			let sliceSize, let mipCount, let sliceCount);
		Test.Assert(sliceCount == 2);
		let secondSlice = TerrainPaletteData.SliceBytes(sliceSize, mipCount);
		for (int c < 3)
			Test.Assert(texels[secondSlice + c] == 128); // mid height, so neutral
		Test.Assert(texels[secondSlice + 3] == 255);

		Bind(fixture, terrainId, scope (terrain) =>
			{
				Test.Assert(terrain.Base.Height.IsBound);
				Test.Assert(terrain.Base.Height.Id == baseHeightId);
				Test.Assert(terrain.Palette[0].Height.IsBound);
				Test.Assert(terrain.Palette[0].Height.Id == paletteHeightId);
				Test.Assert(!terrain.Palette[1].Height.IsBound);
				Test.Assert(Near(terrain.HeightBlendContrast, 0.4f));
			});
	}

	/// A mask cuts a layer away, so a layer WITHOUT one has to default to fully opaque: a
	/// transparent default would erase every layer that authored no mask.
	[Test]
	public static void AMaskLessLayerDefaultsToOpaque()
	{
		let fixture = scope TerrainFixture("scratch_terrain_mask");
		let heightfieldId = fixture.AddHeightfield();
		let product = fixture.AddTerrainProduct();
		let terrainId = product.Id;

		let paletteMaskId = Guid(91, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9);
		{
			let asset = scope TerrainAsset();
			asset.HeightfieldId = heightfieldId;
			asset.BaseAlbedoId = Guid(111, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2);
			asset.PaletteTextureSize = 64;
			asset.PaletteAlbedoIds.Add(Guid(321, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3));
			asset.PaletteAlbedoIds.Add(.Empty);
			asset.PaletteMaskIds.Add(paletteMaskId);
			asset.PaletteMaskIds.Add(.Empty);
			asset.PaletteTileScales.Add(4.0f);
			asset.PaletteTileScales.Add(8.0f);
			fixture.Cook(asset, product);
		}

		Test.Assert(TerrainFixture.HasStream(product, TerrainPaletteData.MaskStream));
		Test.Assert(!TerrainFixture.HasStream(product, TerrainPaletteData.HeightStream));

		let texels = scope List<uint8>();
		TerrainFixture.ReadPalette(product, TerrainPaletteData.MaskStream, texels,
			let sliceSize, let mipCount, let sliceCount);
		Test.Assert(sliceCount == 2);
		let secondSlice = TerrainPaletteData.SliceBytes(sliceSize, mipCount);
		for (int c < 4)
			Test.Assert(texels[secondSlice + c] == 255); // fully opaque

		Bind(fixture, terrainId, scope (terrain) =>
			{
				Test.Assert(terrain.Palette[0].Mask.IsBound);
				Test.Assert(terrain.Palette[0].Mask.Id == paletteMaskId);
				Test.Assert(!terrain.Palette[1].Mask.IsBound);
				Test.Assert(terrain.PaletteData.HasMask);
			});
	}

	/// Re-cooking without a map DELETES the sidecar it used to write.
	///
	/// A left behind array would keep loading, so a map the author removed would go on being
	/// sampled with nothing on the page to say so.
	[Test]
	public static void ReCookingWithoutAMapDeletesItsStaleSidecar()
	{
		let fixture = scope TerrainFixture("scratch_terrain_stale");
		let heightfieldId = fixture.AddHeightfield();
		let product = fixture.AddTerrainProduct();
		let terrainId = product.Id;

		{
			let withMask = scope TerrainAsset();
			withMask.HeightfieldId = heightfieldId;
			withMask.BaseAlbedoId = Guid(111, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2);
			withMask.PaletteTextureSize = 64;
			withMask.PaletteAlbedoIds.Add(Guid(321, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3));
			withMask.PaletteMaskIds.Add(Guid(91, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9));
			withMask.PaletteTileScales.Add(4.0f);
			fixture.Cook(withMask, product);
		}
		Test.Assert(TerrainFixture.HasStream(product, TerrainPaletteData.MaskStream));

		{
			let withoutMask = scope TerrainAsset();
			withoutMask.HeightfieldId = heightfieldId;
			withoutMask.BaseAlbedoId = Guid(111, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2);
			withoutMask.PaletteTextureSize = 64;
			withoutMask.PaletteAlbedoIds.Add(Guid(321, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3));
			withoutMask.PaletteTileScales.Add(4.0f);
			fixture.Cook(withoutMask, product);
		}
		Test.Assert(!TerrainFixture.HasStream(product, TerrainPaletteData.MaskStream));

		Bind(fixture, terrainId, scope (terrain) =>
			{
				Test.Assert(terrain.PaletteData.IsValid); // the albedo array is still there
				Test.Assert(!terrain.PaletteData.HasMask);
			});
	}
}
