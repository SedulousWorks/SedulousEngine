using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Heightfield;
using Sedulous.Resource;
using Sedulous.Terrain.Resource;

namespace Sedulous.Terrain.Resource.Tests;

/// The terrain as a cooked resource: what it references, and how the factory resolves it.
class TerrainResourceTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	/// The whole path: a cooked heightfield, a terrain referencing it, and a bind that
	/// resolves the two through ONE manager.
	[Test]
	public static void ATerrainResolvesItsSharedHeightfield()
	{
		let fixture = scope TerrainFixture("scratch_terrain_resource");

		let grid = scope Heightfield(65, .(64.0f, 64.0f), 0.0f, 10.0f);
		let heightfieldId = fixture.AuthorHeightfield("hf", grid);

		let source = scope TerrainSource();
		source.HeightfieldId = heightfieldId;
		source.BaseTileScale = 16.0f;
		source.CastShadows = false;
		// Unset albedos: there is no GPU factory here, and the terrain still has its shape.
		source.PaletteAlbedoIds.Add(Guid.Empty);
		source.PaletteAlbedoIds.Add(Guid.Empty);
		source.PaletteTileScales.Add(4.0f);
		source.PaletteTileScales.Add(8.0f);
		let terrainId = fixture.AuthorTerrain("terrain", source);

		let manager = fixture.CreateManager();
		defer delete manager;

		let bound = manager.Bind<TerrainResource>(terrainId);
		Test.Assert(bound.Get != null);

		let terrain = bound.Get;
		Test.Assert(!terrain.CastShadows);
		Test.Assert(terrain.PaletteCount == 2);
		Test.Assert(Near(terrain.Base.TileScale, 16.0f));
		Test.Assert(Near(terrain.Palette[0].TileScale, 4.0f));
		Test.Assert(Near(terrain.Palette[1].TileScale, 8.0f));

		// The grid resolved through the same manager, which is what makes it shared.
		Test.Assert(terrain.Heightfield.Get != null);
		Test.Assert(terrain.Heightfield.Get.Size == 65);
		Test.Assert(Near(terrain.Heightfield.Get.GetHeightAt(0.0f, 0.0f), 0.0f));
		Test.Assert(terrain.Heightfield.Id == heightfieldId,
			"and the reference kept its identity, so the terrain serializes back");
	}

	/// The splat weights resolve the same way, and their absence is pure base rather than a
	/// failure.
	[Test]
	public static void TheSplatWeightsResolveWhenThereAreSome()
	{
		let fixture = scope TerrainFixture("scratch_terrain_weights");

		let weights = scope SplatWeights(16, 16);
		SplatBrush.Paint(weights, 0.5f, 0.5f, 0.5f, 0.5f, 3, 1.0f);
		let weightsId = fixture.AuthorSplatWeights("weights", weights);

		let source = scope TerrainSource();
		source.WeightsId = weightsId;
		let terrainId = fixture.AuthorTerrain("terrain", source);

		let manager = fixture.CreateManager();
		defer delete manager;

		let terrain = manager.Bind<TerrainResource>(terrainId).Get;
		Test.Assert(terrain != null);
		Test.Assert(terrain.Weights.Get != null);
		Test.Assert(terrain.Weights.Get.Width == 16);
		Test.Assert(terrain.Weights.Get.WeightOfLayer(8, 8, 3) == weights.WeightOfLayer(8, 8, 3));
	}

	/// A terrain referencing NOTHING still builds: an unbound reference is the renderer's
	/// stand in, and a terrain that failed to build is a hole in the world.
	[Test]
	public static void ATerrainWithNoReferencesStillBuilds()
	{
		let fixture = scope TerrainFixture("scratch_terrain_bare");

		let source = scope TerrainSource();
		let terrainId = fixture.AuthorTerrain("bare", source);

		let manager = fixture.CreateManager();
		defer delete manager;

		let terrain = manager.Bind<TerrainResource>(terrainId).Get;
		Test.Assert(terrain != null);
		Test.Assert(terrain.Heightfield.Get == null);
		Test.Assert(terrain.Weights.Get == null);
		Test.Assert(terrain.PaletteCount == 0);
		Test.Assert(terrain.PaletteData == null);
		Test.Assert(terrain.CastShadows, "and the defaults survived");
		Test.Assert(Near(terrain.HeightBlendContrast, 0.25f));
	}

	/// A palette layer with FEWER tile scales than albedos falls back to one rather than
	/// reading past the end of the list.
	[Test]
	public static void AMissingTileScaleFallsBackToOne()
	{
		let fixture = scope TerrainFixture("scratch_terrain_scales");

		let source = scope TerrainSource();
		source.PaletteAlbedoIds.Add(Guid.Empty);
		source.PaletteAlbedoIds.Add(Guid.Empty);
		source.PaletteTileScales.Add(4.0f);
		let terrainId = fixture.AuthorTerrain("terrain", source);

		let manager = fixture.CreateManager();
		defer delete manager;

		let terrain = manager.Bind<TerrainResource>(terrainId).Get;
		Test.Assert(terrain != null);
		Test.Assert(terrain.PaletteCount == 2);
		Test.Assert(Near(terrain.Palette[0].TileScale, 4.0f));
		Test.Assert(Near(terrain.Palette[1].TileScale, 1.0f));
	}

	/// The cooked source round trips through the database, which is what the cook writes.
	[Test]
	public static void TheSourceRoundTripsThroughTheDatabase()
	{
		let fixture = scope TerrainFixture("scratch_terrain_roundtrip");

		let written = scope TerrainSource();
		written.HeightfieldId = Guid(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);
		written.WeightsId = Guid(2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
		written.BaseAlbedoId = Guid(3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13);
		written.BaseTileScale = 16.0f;
		written.HeightBlendContrast = 0.75f;
		written.CastShadows = false;
		written.PaletteAlbedoIds.Add(Guid(4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14));
		written.PaletteAlbedoIds.Add(Guid(5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15));
		written.PaletteTileScales.Add(4.0f);
		written.PaletteTileScales.Add(8.0f);

		let id = fixture.AuthorTerrain("roundtrip", written);
		let stored = fixture.Database.GetInstance(id).ReadObject();
		Test.Assert(stored != null);
		defer delete stored;

		let read = stored as TerrainSource;
		Test.Assert(read != null);
		Test.Assert(read.HeightfieldId == written.HeightfieldId);
		Test.Assert(read.WeightsId == written.WeightsId);
		Test.Assert(read.BaseAlbedoId == written.BaseAlbedoId);
		Test.Assert(Near(read.BaseTileScale, 16.0f));
		Test.Assert(Near(read.HeightBlendContrast, 0.75f));
		Test.Assert(!read.CastShadows);
		Test.Assert(read.PaletteAlbedoIds.Count == 2);
		Test.Assert(read.PaletteAlbedoIds[1] == written.PaletteAlbedoIds[1]);
		Test.Assert(Near(read.PaletteTileScales[0], 4.0f));
	}

	// ---- the palette sidecars ----

	private static void FillPalette(List<uint8> outTexels, int bytes, uint8 value)
	{
		outTexels.Clear();
		outTexels.Resize(bytes);
		for (int i < bytes)
			outTexels[i] = value;
	}

	[Test]
	public static void ThePaletteArrayIsReadFromItsSidecar()
	{
		let fixture = scope TerrainFixture("scratch_terrain_palette");

		let source = scope TerrainSource();
		source.PaletteAlbedoIds.Add(Guid.Empty);
		let terrainId = fixture.AuthorTerrain("terrain", source);

		// Two slices of a two by two albedo with two mips: 2x2 plus 1x1, four bytes a texel.
		let bytes = TerrainPaletteData.SliceBytes(2, 2) * 2;
		let texels = scope List<uint8>();
		FillPalette(texels, bytes, 7);
		fixture.WritePalette(terrainId, TerrainPaletteData.AlbedoStream, 2, 2, 2,
			.(texels.Ptr, texels.Count));

		let manager = fixture.CreateManager();
		defer delete manager;

		let terrain = manager.Bind<TerrainResource>(terrainId).Get;
		Test.Assert(terrain != null);
		Test.Assert(terrain.PaletteData != null);
		Test.Assert(terrain.PaletteData.IsValid);
		Test.Assert(terrain.PaletteData.SliceSize == 2);
		Test.Assert(terrain.PaletteData.MipCount == 2);
		Test.Assert(terrain.PaletteData.SliceCount == 2);
		Test.Assert(terrain.PaletteData.Texels.Count == bytes);
		Test.Assert(terrain.PaletteData.Texels[0] == 7);

		// The other maps were never cooked, so the renderer binds its stand ins.
		Test.Assert(!terrain.PaletteData.HasNormal);
		Test.Assert(!terrain.PaletteData.HasOrm);
		Test.Assert(!terrain.PaletteData.HasHeight);
		Test.Assert(!terrain.PaletteData.HasMask);
	}

	[Test]
	public static void TheSecondaryArraysAreReadWhenTheyWereCooked()
	{
		let fixture = scope TerrainFixture("scratch_terrain_palette_maps");

		let source = scope TerrainSource();
		source.PaletteAlbedoIds.Add(Guid.Empty);
		let terrainId = fixture.AuthorTerrain("terrain", source);

		let bytes = TerrainPaletteData.SliceBytes(2, 2);
		let texels = scope List<uint8>();
		FillPalette(texels, bytes, 1);
		fixture.WritePalette(terrainId, TerrainPaletteData.AlbedoStream, 2, 2, 1,
			.(texels.Ptr, texels.Count));
		FillPalette(texels, bytes, 2);
		fixture.WritePalette(terrainId, TerrainPaletteData.NormalStream, 2, 2, 1,
			.(texels.Ptr, texels.Count));
		FillPalette(texels, bytes, 3);
		fixture.WritePalette(terrainId, TerrainPaletteData.MaskStream, 2, 2, 1,
			.(texels.Ptr, texels.Count));

		let manager = fixture.CreateManager();
		defer delete manager;

		let palette = manager.Bind<TerrainResource>(terrainId).Get.PaletteData;
		Test.Assert(palette != null);
		Test.Assert(palette.HasNormal && (palette.NormalTexels[0] == 2));
		Test.Assert(palette.HasMask && (palette.MaskTexels[0] == 3));
		Test.Assert(!palette.HasOrm, "that one was never cooked");
	}

	/// A secondary array whose GEOMETRY does not match the albedo's is REFUSED: binding it
	/// beside the albedo would sample a different slice for the same layer, which is a stale
	/// or truncated cook rather than a usable one.
	[Test]
	public static void AMismatchedSecondaryArrayIsRefused()
	{
		let fixture = scope TerrainFixture("scratch_terrain_palette_mismatch");

		let source = scope TerrainSource();
		source.PaletteAlbedoIds.Add(Guid.Empty);
		let terrainId = fixture.AuthorTerrain("terrain", source);

		let texels = scope List<uint8>();
		FillPalette(texels, TerrainPaletteData.SliceBytes(2, 2), 1);
		fixture.WritePalette(terrainId, TerrainPaletteData.AlbedoStream, 2, 2, 1,
			.(texels.Ptr, texels.Count));

		// A different slice size, and the bytes to match it.
		FillPalette(texels, TerrainPaletteData.SliceBytes(4, 3), 2);
		fixture.WritePalette(terrainId, TerrainPaletteData.NormalStream, 4, 3, 1,
			.(texels.Ptr, texels.Count));

		let manager = fixture.CreateManager();
		defer delete manager;

		let palette = manager.Bind<TerrainResource>(terrainId).Get.PaletteData;
		Test.Assert(palette != null);
		Test.Assert(palette.IsValid);
		Test.Assert(!palette.HasNormal);
		Test.Assert(palette.NormalTexels.IsEmpty);
	}

	/// A palette whose texels do not match its own header is NOT valid, and says so rather
	/// than being uploaded as whatever length it happens to be.
	[Test]
	public static void ATruncatedPaletteIsNotValid()
	{
		let fixture = scope TerrainFixture("scratch_terrain_palette_short");

		let source = scope TerrainSource();
		let terrainId = fixture.AuthorTerrain("terrain", source);

		let texels = scope List<uint8>();
		FillPalette(texels, 16, 5);
		fixture.WritePalette(terrainId, TerrainPaletteData.AlbedoStream, 8, 4, 3,
			.(texels.Ptr, texels.Count));

		let manager = fixture.CreateManager();
		defer delete manager;

		let palette = manager.Bind<TerrainResource>(terrainId).Get.PaletteData;
		Test.Assert(palette != null);
		Test.Assert(!palette.IsValid);
	}

	/// The slice geometry: a full mip chain down to one by one, four bytes a texel.
	[Test]
	public static void SliceBytesCountTheWholeMipChain()
	{
		Test.Assert(TerrainPaletteData.SliceBytes(1, 1) == 4);
		Test.Assert(TerrainPaletteData.SliceBytes(2, 2) == (4 + 1) * 4);
		Test.Assert(TerrainPaletteData.SliceBytes(4, 3) == (16 + 4 + 1) * 4);
		Test.Assert(TerrainPaletteData.SliceBytes(4, 1) == 16 * 4, "only the mips asked for");
		Test.Assert(TerrainPaletteData.SliceBytes(0, 0) == 0);
	}
}
