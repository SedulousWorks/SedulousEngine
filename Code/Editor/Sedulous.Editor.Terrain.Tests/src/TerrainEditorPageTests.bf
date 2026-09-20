using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Heightfield;
using Sedulous.Terrain.Resource;
using Sedulous.Terrain.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Terrain.Tests;

/// The terrain page's headless half: the stats column, the undo snapshot round trip over
/// every authored field, and the palette's structural verbs.
class TerrainEditorPageTests
{
	private static bool Has(List<String> lines, StringView needle)
	{
		for (let line in lines)
		{
			if (line == needle)
				return true;
		}
		return false;
	}

	[Test]
	public static void StatLinesReportGridChunksPaletteAndShadowsFromAResolvedProduct()
	{
		let grid = scope Heightfield(129, .(128.0f, 128.0f), 0.0f, 20.0f);
		let res = scope TerrainResource();
		res.Heightfield.SetDirect(grid);
		res.CastShadows = true;
		res.Palette.Add(TerrainLayer());
		res.Palette.Add(TerrainLayer());
		let lines = scope List<String>();
		defer { ClearAndDeleteItems!(lines); }
		TerrainStats.Lines(res, lines);
		Test.Assert(lines.Count >= 4);
		Test.Assert(Has(lines, "Grid: 129 x 129"));
		Test.Assert(Has(lines, "World: 128 x 128 m"));
		Test.Assert(Has(lines, "Chunks: 2 x 2 = 4")); // 129 is two chunks a side
		Test.Assert(Has(lines, "Palette layers: 2"));
		Test.Assert(Has(lines, "Cast shadows: yes"));
	}

	[Test]
	public static void StatLinesAreRobustWhenTheHeightfieldIsUnresolved()
	{
		let res = scope TerrainResource();
		res.CastShadows = false;
		let lines = scope List<String>();
		defer { ClearAndDeleteItems!(lines); }
		TerrainStats.Lines(res, lines);
		Test.Assert(Has(lines, "Heightfield: unresolved"));
		Test.Assert(Has(lines, "Cast shadows: no"));
	}

	/// Every authored field survives the blob: the references, the base maps, the parallel
	/// palette lists including the optional normal, ORM, height and mask ids, the tiling,
	/// the blend contrast and the shadow flag.
	[Test]
	public static void TheSnapshotRoundTripsEveryAuthoredField()
	{
		TerrainPipeline.RegisterAll();
		let a = scope TerrainAsset();
		a.HeightfieldId = .(11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 22);
		a.WeightsId = .(33, 0, 0, 0, 0, 0, 0, 0, 0, 0, 44);
		a.BaseAlbedoId = .(55, 0, 0, 0, 0, 0, 0, 0, 0, 0, 66);
		a.BaseNormalId = .(101, 0, 0, 0, 0, 0, 0, 0, 0, 0, 102);
		a.BaseOrmId = .(103, 0, 0, 0, 0, 0, 0, 0, 0, 0, 104);
		a.BaseHeightId = .(131, 0, 0, 0, 0, 0, 0, 0, 0, 0, 132);
		a.BaseTileScale = 24.0f;
		a.PaletteAlbedoIds.Add(.(77, 0, 0, 0, 0, 0, 0, 0, 0, 0, 88));
		a.PaletteAlbedoIds.Add(.Empty);
		a.PaletteTileScales.Add(16.0f);
		a.PaletteTileScales.Add(48.0f);
		a.PaletteNormalIds.Add(.(201, 0, 0, 0, 0, 0, 0, 0, 0, 0, 202));
		a.PaletteNormalIds.Add(.Empty);
		a.PaletteOrmIds.Add(.Empty);
		a.PaletteOrmIds.Add(.(203, 0, 0, 0, 0, 0, 0, 0, 0, 0, 204));
		a.PaletteHeightIds.Add(.(211, 0, 0, 0, 0, 0, 0, 0, 0, 0, 212));
		a.PaletteHeightIds.Add(.Empty);
		a.PaletteMaskIds.Add(.(221, 0, 0, 0, 0, 0, 0, 0, 0, 0, 222));
		a.PaletteMaskIds.Add(.Empty);
		a.PaletteTextureSize = 512;
		a.HeightBlendContrast = 0.4f;
		a.CastShadows = false;

		let blob = scope List<uint8>();
		TerrainAssetEdit.Snapshot(a, blob);
		Test.Assert(!blob.IsEmpty);

		let b = scope TerrainAsset();
		Test.Assert(TerrainAssetEdit.Apply(b, blob));
		Test.Assert(b.HeightfieldId == a.HeightfieldId);
		Test.Assert(b.WeightsId == a.WeightsId);
		Test.Assert(b.BaseAlbedoId == a.BaseAlbedoId);
		Test.Assert(b.BaseNormalId == a.BaseNormalId);
		Test.Assert(b.BaseOrmId == a.BaseOrmId);
		Test.Assert(b.BaseHeightId == a.BaseHeightId);
		Test.Assert(Math.Abs(b.BaseTileScale - 24.0f) < 1e-6f);
		Test.Assert(b.PaletteAlbedoIds.Count == 2);
		Test.Assert(b.PaletteAlbedoIds[0] == a.PaletteAlbedoIds[0]);
		Test.Assert(b.PaletteAlbedoIds[1].IsNil);
		Test.Assert(b.PaletteTileScales.Count == 2);
		Test.Assert(Math.Abs(b.PaletteTileScales[1] - 48.0f) < 1e-6f);
		Test.Assert(b.PaletteNormalIds.Count == 2);
		Test.Assert(b.PaletteNormalIds[0] == a.PaletteNormalIds[0]);
		Test.Assert(b.PaletteNormalIds[1].IsNil);
		Test.Assert(b.PaletteOrmIds.Count == 2);
		Test.Assert(b.PaletteOrmIds[0].IsNil);
		Test.Assert(b.PaletteOrmIds[1] == a.PaletteOrmIds[1]);
		Test.Assert(b.PaletteHeightIds.Count == 2);
		Test.Assert(b.PaletteHeightIds[0] == a.PaletteHeightIds[0]);
		Test.Assert(b.PaletteMaskIds.Count == 2);
		Test.Assert(b.PaletteMaskIds[0] == a.PaletteMaskIds[0]);
		Test.Assert(b.PaletteTextureSize == 512);
		Test.Assert(Math.Abs(b.HeightBlendContrast - 0.4f) < 1e-6f);
		Test.Assert(b.CastShadows == false);

		// Applying what already matches reports nothing to do.
		Test.Assert(!TerrainAssetEdit.Apply(b, blob));
	}

	/// An asset that never populated its optional maps round trips empty lists and the
	/// default contrast; nothing is invented on the way through.
	[Test]
	public static void TheSnapshotKeepsNeverPopulatedMapsEmptyAndTheDefaultContrast()
	{
		TerrainPipeline.RegisterAll();
		let a = scope TerrainAsset();
		a.BaseAlbedoId = .(55, 0, 0, 0, 0, 0, 0, 0, 0, 0, 66);
		a.PaletteAlbedoIds.Add(.(77, 0, 0, 0, 0, 0, 0, 0, 0, 0, 88));
		a.PaletteTileScales.Add(16.0f);
		let blob = scope List<uint8>();
		TerrainAssetEdit.Snapshot(a, blob);
		let b = scope TerrainAsset();
		b.PaletteNormalIds.Add(.Empty); // stale state the restore must clear
		Test.Assert(TerrainAssetEdit.Apply(b, blob));
		Test.Assert(b.BaseNormalId.IsNil);
		Test.Assert(b.BaseOrmId.IsNil);
		Test.Assert(b.BaseHeightId.IsNil);
		Test.Assert(b.PaletteNormalIds.IsEmpty);
		Test.Assert(b.PaletteOrmIds.IsEmpty);
		Test.Assert(b.PaletteHeightIds.IsEmpty);
		Test.Assert(b.PaletteMaskIds.IsEmpty);
		Test.Assert(Math.Abs(b.HeightBlendContrast - 0.25f) < 1e-6f); // the default preserved
	}

	[Test]
	public static void AddAndRemoveLayerKeepTheParallelListsAligned()
	{
		let a = scope TerrainAsset();
		TerrainAssetEdit.AddLayer(a);
		TerrainAssetEdit.AddLayer(a);
		Test.Assert(a.PaletteAlbedoIds.Count == 2);
		Test.Assert(a.PaletteTileScales.Count == 2);
		Test.Assert(a.PaletteNormalIds.Count == 2);
		Test.Assert(a.PaletteOrmIds.Count == 2);
		Test.Assert(a.PaletteHeightIds.Count == 2);
		Test.Assert(a.PaletteMaskIds.Count == 2);
		Test.Assert(a.PaletteTileScales[1] == TerrainAssetEdit.cNewLayerTileScale);

		a.PaletteAlbedoIds[1] = .(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);
		Test.Assert(TerrainAssetEdit.RemoveLayer(a, 0));
		Test.Assert(a.PaletteAlbedoIds.Count == 1);
		Test.Assert(a.PaletteAlbedoIds[0] == Guid(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)); // the survivor shifted down
		Test.Assert(a.PaletteMaskIds.Count == 1);
		Test.Assert(!TerrainAssetEdit.RemoveLayer(a, 5)); // no such layer
		Test.Assert(!TerrainAssetEdit.RemoveLayer(a, -1));
	}

	/// An asset authored before a map kind existed has a short list; setting a map grows it
	/// to the albedo count rather than indexing past the end.
	[Test]
	public static void SettingAPaletteMapGrowsAShortListLazily()
	{
		let a = scope TerrainAsset();
		a.PaletteAlbedoIds.Add(.Empty);
		a.PaletteAlbedoIds.Add(.Empty);
		a.PaletteAlbedoIds.Add(.Empty);
		Test.Assert(a.PaletteHeightIds.IsEmpty);
		Test.Assert(TerrainAssetEdit.MapId(a, .Height, 2).IsNil);
		let id = Guid(9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9);
		Test.Assert(TerrainAssetEdit.SetPaletteMap(a, .Height, 2, id));
		Test.Assert(a.PaletteHeightIds.Count == 3);
		Test.Assert(a.PaletteHeightIds[0].IsNil);
		Test.Assert(a.PaletteHeightIds[2] == id);
		Test.Assert(TerrainAssetEdit.MapId(a, .Height, 2) == id);
		Test.Assert(TerrainAssetEdit.MapIds(a, .Normal) === a.PaletteNormalIds);
		Test.Assert(TerrainAssetEdit.MapIds(a, .Orm) === a.PaletteOrmIds);
		Test.Assert(TerrainAssetEdit.MapIds(a, .Mask) === a.PaletteMaskIds);
		Test.Assert(!TerrainAssetEdit.SetPaletteMap(a, .Mask, 3, id)); // past the palette
		Test.Assert(a.PaletteMaskIds.IsEmpty);
	}

	[Test]
	public static void TheFactoryReportsTheTerrainAssetPrimaryType()
	{
		let factory = scope TerrainEditorPageFactory(null, null);
		Test.Assert(factory.PrimaryType == typeof(TerrainAsset));
	}
}
