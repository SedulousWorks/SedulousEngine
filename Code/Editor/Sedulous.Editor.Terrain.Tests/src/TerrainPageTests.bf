using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Terrain.Resource;
using Sedulous.Terrain.Pipeline;
using Sedulous.Heightfield.Pipeline;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Terrain.Tests;

/// The terrain page over its markup (Data/Editor/PreviewPage.xml) and a scratch project, without a
/// host (no preview): its rows from the asset (the terrain's, the base layer's, the paint layers a
/// list of groups that adds and removes but does not reorder), each edit one undo step, a layer added
/// and removed with every list kept in line, new splat weights made beside the terrain, and a terrain
/// with no heightfield said so.
class TerrainPageTests
{
	static bool DataRoot(String outPath)
	{
		var dir = GetCurrentDirectory(.. scope .());
		for (int i < 8)
		{
			let data = PathJoin(dir, "Data", .. scope .());
			if (DirectoryExists(PathJoin(data, "Editor", .. scope .())))
			{
				outPath.Set(data);
				return true;
			}
			let parent = PathParent(dir, .. scope .());
			if (parent == dir)
				break;
			dir.Set(parent);
		}
		return false;
	}

	/// Markup under the data root: a node with one reference, the caller's.
	static Node LoadMarkup(StringView relative)
	{
		let data = scope String();
		Test.Assert(DataRoot(data));
		let text = scope String();
		Test.Assert(System.IO.File.ReadAllText(PathJoin(data, relative, .. scope .()), text) case .Ok);
		RegisterGuiElements();
		RegisterToolkitElements();
		let elements = ElementSet.All();
		defer delete elements;
		let loader = scope MarkupLoader(elements);
		return loader.LoadFromString(text);
	}

	static void Text(Guid id, String outText) => id.ToString(outText);

	static void Value(Sedulous.GUI.PropertyBag rows, StringView path, String outText)
	{
		var value = rows.GetValue(path, 0);
		outText.Append(value.AsString);
		value.Dispose();
	}

	/// A project with a terrain ("Hills": a heightfield, two layers, only the first with a normal map,
	/// as an older terrain keeps them) and one with nothing ("Bare").
	private class Bed
	{
		public String Dir = new .("scratch_terrain_page_project") ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .() ~ delete _;
		public Instance Hills;
		public Instance Bare;
		public readonly Guid Heights = .(0x7e, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);
		public readonly Guid Grass = .(0x7e, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2);
		public readonly Guid Rock = .(0x7e, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3);
		public readonly Guid GrassNormal = .(0x7e, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4);
		public readonly Guid Moss = .(0x7e, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5);

		public this()
		{
			TerrainPipeline.RegisterAll(); // the instances' types, written and read back
			HeightfieldPipeline.RegisterAll();
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			let typeName = typeof(TerrainAsset).GetFullName(.. scope .());
			Hills = Project.SourceDb.RootGroup.CreateInstance("Hills", typeName);
			Bare = Project.SourceDb.RootGroup.CreateInstance("Bare", typeName);
			Test.Assert((Hills != null) && (Bare != null));
			let terrain = scope TerrainAsset();
			Test.Assert(Bare.WriteObject(terrain) case .Ok);
			terrain.HeightfieldId = Heights;
			terrain.PaletteAlbedoIds.Add(Grass);
			terrain.PaletteAlbedoIds.Add(Rock);
			terrain.PaletteTileScales.Add(16.0f);
			terrain.PaletteTileScales.Add(48.0f);
			terrain.PaletteNormalIds.Add(GrassNormal); // ragged: rock has none, nor any ORM
			Test.Assert(Hills.WriteObject(terrain) case .Ok);
		}

		public ~this()
		{
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// The page over `instance`; the caller deletes it (before the bed).
		public TerrainEditorPage Open(Instance instance)
		{
			let services = new AssetPageServices();
			services.LoadMarkup = new (path) => LoadMarkup(path);
			return new TerrainEditorPage(Context, services, instance);
		}
	}

	[Test]
	public static void TheTerrainsRowsItsBaseLayersAndItsPaintLayersAListOfGroupsThatDoesNotReorder()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Hills);
		defer delete page;
		Test.Assert(!page.LoadFailed);
		Test.Assert(Value(page.TerrainRows, "heightfield", .. scope .()) == Text(bed.Heights, .. scope .()));
		Test.Assert(page.TerrainRows.FindInfo("heightfield").ReferenceType == typeof(Sedulous.Heightfield.Heightfield));
		Test.Assert(page.TerrainRows.FindInfo("weights").ReferenceType == typeof(SplatWeights));
		Test.Assert(page.TerrainRows.GetValue("castShadows", 0).AsBool);
		Test.Assert(page.BaseRows.FindInfo("albedo").ReferenceType == typeof(Sedulous.Texture.Resource.Texture));

		let list = page.LayerRows.FindInfo("layers");
		Test.Assert(list != null);
		Test.Assert(list.Kind == .List);
		Test.Assert((list.ListOps & PropertyListMove) == 0); // a layer's place is its weight channel
		Test.Assert((list.ListOps & PropertyListAdd) != 0);
		Test.Assert(page.LayerRows.ElementCount("layers", 0) == 2);
		let fields = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(fields); }
		page.LayerRows.GetProperties("layers.0", fields);
		Test.Assert(fields.Count == 6); // albedo, normal, ORM, height, coverage, tile
		Test.Assert(fields[0].ShownName == "Albedo");
		Test.Assert(fields[4].ShownName == "Coverage");
		Test.Assert(fields[5].Kind == .Float);
		let layers = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(layers); }
		page.LayerRows.GetProperties("layers", layers);
		Test.Assert(layers.Count == 2);
		Test.Assert(layers[0].ShownName == "Layer 1"); // its channel, as the paint tool numbers it
		Test.Assert(layers[1].Summary == "No albedo"); // the albedo's name when the project has it
		Test.Assert(Value(page.LayerRows, "layers.0.albedo", .. scope .()) == Text(bed.Grass, .. scope .()));
		Test.Assert(Value(page.LayerRows, "layers.0.normal", .. scope .()) == Text(bed.GrassNormal, .. scope .()));
		Test.Assert(Value(page.LayerRows, "layers.1.albedo", .. scope .()) == Text(bed.Rock, .. scope .()));
		Test.Assert(Value(page.LayerRows, "layers.1.normal", .. scope .()).IsEmpty); // past the short list: none
		Test.Assert(Math.Abs(page.LayerRows.GetValue("layers.1.tile", 0).AsFloat - 48.0) < 0.001);
		Test.Assert(page.Notice("heightfield", .. scope .()).IsEmpty);
		Test.Assert(page.Fact("Grid", .. scope .()) == "Not cooked yet: Save to cook it");

		// Opening it changes nothing; its first edit makes every layer list as long as the albedos.
		let asset = page.Asset;
		Test.Assert(asset != null);
		Test.Assert(asset.PaletteNormalIds.Count == 1);
		Test.Assert(!page.IsDirty);
		page.EditRow(page.LayerRows, "layers.0.tile", Sedulous.GUI.Variant(20.0));
		Test.Assert(page.Asset.PaletteNormalIds.Count == 2);
		Test.Assert(page.Asset.PaletteMaskIds.Count == 2);

		let empty = bed.Open(bed.Bare);
		defer delete empty;
		Test.Assert(!empty.Notice("heightfield", .. scope .()).IsEmpty);
		Test.Assert(empty.LayerRows.ElementCount("layers", 0) == 0);
	}

	[Test]
	public static void AMapPickedATilingAndASwitchEachOneUndoStep()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Hills);
		defer delete page;
		page.EditRow(page.LayerRows, "layers.1.normal", Sedulous.GUI.Variant(Text(bed.Moss, .. scope .())));
		page.EditRow(page.LayerRows, "layers.0.tile", Sedulous.GUI.Variant(24.0));
		page.EditRow(page.TerrainRows, "castShadows", Sedulous.GUI.Variant(false));
		page.EditRow(page.BaseRows, "albedo", Sedulous.GUI.Variant(Text(bed.Grass, .. scope .())));
		Test.Assert(page.Asset.PaletteNormalIds[1] == bed.Moss);
		Test.Assert(Math.Abs(page.Asset.PaletteTileScales[0] - 24.0f) < 0.001f);
		Test.Assert(!page.Asset.CastShadows);
		Test.Assert(page.Asset.BaseAlbedoId == bed.Grass);
		Test.Assert(page.IsDirty);

		page.Commands.Undo();
		Test.Assert(page.Asset.BaseAlbedoId.IsNil);
		page.Commands.Undo();
		Test.Assert(page.Asset.CastShadows);
		Test.Assert(page.TerrainRows.GetValue("castShadows", 0).AsBool); // the row follows its undo
		page.Commands.Undo();
		Test.Assert(Math.Abs(page.Asset.PaletteTileScales[0] - 16.0f) < 0.001f);
		page.Commands.Undo();
		Test.Assert(page.Asset.PaletteNormalIds.Count == 1); // as it was read: the short list back
		Test.Assert(Value(page.LayerRows, "layers.1.normal", .. scope .()).IsEmpty);
	}

	[Test]
	public static void ALayerAddedAtTheEndAndOneRemovedKeepEveryListInLineEachOneUndoStep()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Hills);
		defer delete page;

		Test.Assert(page.LayerRows.EditList("layers", scope ListEdit(.Insert, 2)));
		Test.Assert(page.Asset.PaletteAlbedoIds.Count == 3);
		Test.Assert(page.Asset.PaletteHeightIds.Count == 3);
		Test.Assert(page.Asset.PaletteTileScales.Count == 3);
		Test.Assert(page.LayerRows.ElementCount("layers", 0) == 3);

		// The first removed: those after it move down, their maps with them.
		Test.Assert(page.LayerRows.EditList("layers", scope ListEdit(.Remove, 0)));
		Test.Assert(page.Asset.PaletteAlbedoIds.Count == 2);
		Test.Assert(page.Asset.PaletteAlbedoIds[0] == bed.Rock);
		Test.Assert(page.Asset.PaletteNormalIds[0].IsNil); // grass's normal went with grass
		Test.Assert(Math.Abs(page.Asset.PaletteTileScales[0] - 48.0f) < 0.001f);
		Test.Assert(Value(page.LayerRows, "layers.0.albedo", .. scope .()) == Text(bed.Rock, .. scope .()));

		page.Commands.Undo(); // the removal
		Test.Assert(page.Asset.PaletteAlbedoIds.Count == 3);
		Test.Assert(page.Asset.PaletteAlbedoIds[0] == bed.Grass);
		Test.Assert(page.Asset.PaletteNormalIds[0] == bed.GrassNormal);
		page.Commands.Undo(); // the add
		Test.Assert(page.Asset.PaletteAlbedoIds.Count == 2);
		Test.Assert(page.LayerRows.ElementCount("layers", 0) == 2);
	}

	[Test]
	public static void NewSplatWeightsMakesThemBesideTheTerrainAndGivesThemToItOnce()
	{
		let bed = scope Bed();
		let page = bed.Open(bed.Hills);
		defer delete page;
		Test.Assert(page.SplatButton != null);
		Test.Assert(page.SplatButton.Enabled);
		Test.Assert(page.CreateSplatWeights(512));
		Test.Assert(!page.Asset.WeightsId.IsNil);
		let made = bed.Project.SourceDb.GetInstance(page.Asset.WeightsId);
		Test.Assert(made != null);
		Test.Assert(made.Name == "Hills_splat");
		Test.Assert(made.OwningGroup === bed.Hills.OwningGroup);
		let object = made.ReadObject();
		defer delete object;
		let splat = object as SplatmapAsset;
		Test.Assert(splat != null);
		Test.Assert(splat.Width == 512);
		Test.Assert(Value(page.TerrainRows, "weights", .. scope .()) == Text(page.Asset.WeightsId, .. scope .()));
		Test.Assert(!page.SplatButton.Enabled); // it has some now
		Test.Assert(!page.CreateSplatWeights(1024));

		page.Commands.Undo(); // the terrain lets them go; the asset made stays
		Test.Assert(page.Asset.WeightsId.IsNil);
		Test.Assert(page.SplatButton.Enabled);
	}
}
