using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Runtime.Client;
using Sedulous.Graphics;
using Sedulous.Engine.Render;
using Sedulous.Engine.Terrain;
using Sedulous.Terrain.Resource;
using Sedulous.Terrain.Pipeline;
using Sedulous.Heightfield.Pipeline;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Preview;

namespace Sedulous.Editor.Terrain;

/// A terrain on the GUI from the preview pages' markup (Data/Editor/PreviewPage.xml; Raptor's
/// editor-gui spec, 5.4, layer 7). The cooked terrain on a preview lit by a sun (its self-shadowing
/// shown), beside its rows. The asset keeps its layers in parallel lists, so the rows are the page's
/// own, not its reflection's: under Terrain the heightfield and the splat weights it is painted with,
/// whether it casts shadows, how soft the height blend is and the size every layer's textures are
/// packed at; under Base layer what shows wherever no paint covers (its albedo, normal, ORM and height
/// maps and its tiling); under Paint layers a list, each layer a group of its maps (albedo, normal,
/// ORM, height, coverage mask) and its tiling. A layer's place in the list is its channel in the
/// splat weights, so the list adds and removes but does not reorder; a layer removed frees its weights
/// and moves those above it down. A terrain with no splat weights gets new ones from the bar's New
/// Splat Weights (the paint tool only edits weights that exist). What the cooked terrain is (its
/// grid, world size, chunks) are read-only rows.
///
/// Each edit is one undo step (the whole asset before and after: it is small). Save writes it and
/// asks for a cook, after which the preview follows the new product. Brushes never live here:
/// sculpting and painting are the scene view's tools.
class TerrainEditorPage : AssetObjectPage
{
	public const String cMarkupPath = "Editor/PreviewPage.xml";
	/// The sizes New Splat Weights offers, in its menu's order.
	public const int32[3] cSplatSizes = .(512, 1024, 2048);

	// A layer's maps: the row's name and what it says, and the list that keeps it (albedo, else a
	// PaletteMap's).
	private struct LayerMap
	{
		public String Path;
		public String Shown;
		public String About;
		public PaletteMap? Map; // null: the albedos

		public this(String path, String shown, String about, PaletteMap? map)
		{
			Path = path;
			Shown = shown;
			About = about;
			Map = map;
		}
	}

	private static readonly LayerMap[5] cLayerMaps = .(
		.("albedo", "Albedo", "Its colour", null),
		.("normal", "Normal", "Its normal map (none: flat)", .Normal),
		.("orm", "ORM", "Its occlusion, roughness and metalness (none: 1, 1, 0)", .Orm),
		.("height", "Height", "Its height map, which the height blend reads where layers meet (none: flat)", .Height),
		.("mask", "Coverage", "A mask of where it may show over what it is painted on (none: everywhere)", .Mask));

	// The base layer's maps.
	private static readonly (String path, String shown, String about)[4] cBaseMaps = .(
		("albedo", "Albedo", "Its colour (none: white)"),
		("normal", "Normal", "Its normal map (none: flat)"),
		("orm", "ORM", "Its occlusion, roughness and metalness (none: 1, 1, 0)"),
		("height", "Height", "Its height map, which the height blend reads (none: flat)"));

	/// The rows; the base's sections let go of them first (ClearSections).
	private Sedulous.GUI.PropertyBag mTerrainRows = null;
	private Sedulous.GUI.PropertyBag mBaseRows = null;
	private Sedulous.GUI.PropertyBag mLayerRows = null;
	private ToolMenuButton mSplat = null ~ _?.ReleaseRef();
	private PreviewPane mPane = null;
	private EntityHandle mEntity = .Invalid;
	/// The cooked terrain, retained; follows reloads.
	private Proxy<TerrainResource> mProduct = default;
	/// What the preview and the facts show.
	private TerrainResource mShownProduct = null;

	/// It takes `services`.
	public this(EditorContext context, AssetPageServices services, Instance instance)
		: base(context, services, instance, typeof(TerrainAsset), cMarkupPath)
	{
		// Its layers live in parallel lists no one edits by hand: the rows are the page's own. An
		// older terrain's shorter lists are squared by its first edit, not by opening it.
		HideAssetRows();
		if (Content != null)
		{
			mPane = new PreviewPane(Content, Services, "terrain.preview");
			mPane.OnFrame = new [=this] () => { FramePreview(); };
			BuildPreviewScene();
			AddSplatButton();
		}
		BuildRows();
		if (Context.Resources != null)
		{
			mProduct = Context.Resources.Bind<TerrainResource>(InstanceId);
			mProduct.Retain();
		}
		ShowRows();
		ShowFacts();
	}

	public ~this()
	{
		PointPreviewAt(null);
		mProduct.Forget();
		DeleteAndNullify!(mPane);
		// The grid's sections let go of the rows before they go (the base's outlive these).
		ClearSections();
		DeleteAndNullify!(mTerrainRows);
		DeleteAndNullify!(mBaseRows);
		DeleteAndNullify!(mLayerRows);
	}

	/// The rows' sections: the terrain's, its base layer's, its paint layers'.
	public Sedulous.GUI.PropertyBag TerrainRows => mTerrainRows;
	public Sedulous.GUI.PropertyBag BaseRows => mBaseRows;
	public Sedulous.GUI.PropertyBag LayerRows => mLayerRows;

	// === For tests ===

	public TerrainAsset Asset => ObjectAs<TerrainAsset>();
	public ToolMenuButton SplatButton => mSplat;

	/// Writes `value` to row `path` of `rows` as the grid commits an edit (one undo step).
	public void EditRow(Sedulous.GUI.PropertyBag rows, StringView path, Sedulous.GUI.Variant value)
	{
		rows.SetValue(path, 0, value); // as the grid's commit leaves it
		Committed(rows, path, value);
	}

	/// A list edit of the paint layers as the grid makes one (an add, a remove).
	public void EditLayers(ListEdit edit)
	{
		let asset = Asset;
		if (asset == null)
			return;
		if (edit.Kind == .Insert)
		{
			// At the end, its maps unset: the next channel of the weights.
			EditWhole("edit_terrain", scope [&] (object) =>
				{
					let terrainAsset = (TerrainAsset)object;
					TerrainAssetEdit.Square(terrainAsset);
					TerrainAssetEdit.AddLayer(terrainAsset);
				});
		}
		else if ((edit.Kind == .Remove) && (edit.Index >= 0) && (edit.Index < asset.PaletteAlbedoIds.Count))
		{
			let index = edit.Index;
			// Its weights freed and those above it moved down, in the live weights and their files.
			RemapWeightsOnRemove((uint32)index);
			EditWhole("edit_terrain", scope [&] (object) =>
				{
					let terrainAsset = (TerrainAsset)object;
					TerrainAssetEdit.Square(terrainAsset);
					TerrainAssetEdit.RemoveLayer(terrainAsset, index);
				});
		}
		ShowRows(); // the list as the terrain holds it (a move, which the list does not offer, goes back)
	}

	/// New splat weights of `size` texels a side, made beside the terrain and given to it (one undo
	/// step for the terrain; the new asset stays). False when it has some already.
	public bool CreateSplatWeights(int32 size)
	{
		// Made here, not by a stroke: the paint tool edits weights that exist, so no stroke ever makes
		// an asset and its undo stays the stroke's.
		let asset = Asset;
		if ((asset == null) || !asset.WeightsId.IsNil || (Context.Project == null))
			return false;
		// Beside the terrain, in its group.
		let self = Context.Project.SourceDb.GetInstance(InstanceId);
		let group = (self != null) ? self.OwningGroup : Context.Project.SourceDb.RootGroup;
		if (group == null)
			return false;
		// A free name: CreateInstance hands back whatever holds a taken one, and the starter written
		// below would overwrite it (weights an undo left, or another asset of that name).
		let name = group.UniqueInstanceName(scope String()..AppendF("{}_splat", Title), .. scope String());
		let made = group.CreateInstance(name, typeof(SplatmapAsset).GetFullName(.. scope .()));
		if (made == null)
		{
			Context.Notify(.Error, scope String()..AppendF("No splat weights made: '{}' could not be created.", name));
			return false;
		}
		let splat = scope SplatmapAsset();
		splat.Width = (size > 0) ? size : 1024;
		splat.Height = splat.Width;
		made.WriteObject(splat).IgnoreError(); // all zero: the base layer everywhere, as its cook makes it
		let id = made.Id;
		EditWhole("edit_terrain", scope [&] (object) => { ((TerrainAsset)object).WeightsId = id; });
		Context.RequestCook(false);
		Context.Notify(.Success, scope String()..AppendF("Made splat weights '{}'.", name));
		return true;
	}

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		base.OnUpdate(host, dt);
		if (mPane != null)
			mPane.Update(dt);
		// The cooked terrain came, or a cook replaced it: the preview, its framing and the facts follow.
		let product = mProduct.Get;
		if (product !== mShownProduct)
		{
			let first = mShownProduct == null;
			mShownProduct = product;
			PointPreviewAt(product);
			if (first)
				FramePreview();
			ShowFacts();
		}
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		if (mPane != null)
			mPane.Render(ref frame);
	}

	public override void OnClose()
	{
		if (mPane != null)
			mPane.Close();
	}

	protected override void OnObjectChanged()
	{
		ShowRows();
		PointPreviewAt(mProduct.Get);
	}

	// === The rows ===

	private static PropertyInfo AddReference(Sedulous.GUI.PropertyBag rows, StringView path, StringView shown, StringView about, Type type)
	{
		let info = rows.Add(path, .Reference, Sedulous.GUI.Variant(""));
		info.DisplayName.Set(shown);
		info.Description.Set(about);
		info.ReferenceType = type;
		return info;
	}

	private static void Tile(PropertyInfo info, StringView about)
	{
		info.DisplayName.Set("Tile");
		info.Description.Set(about);
		info.HasRange = true;
		info.Min = 0.1;
		info.Max = 8192.0;
		info.Step = 1.0;
	}

	private void BuildRows()
	{
		mTerrainRows = new Sedulous.GUI.PropertyBag();
		mBaseRows = new Sedulous.GUI.PropertyBag();
		mLayerRows = new Sedulous.GUI.PropertyBag();

		AddReference(mTerrainRows, "heightfield", "Heightfield", "The heights it is drawn from (shared with its collision and navigation)",
			typeof(Sedulous.Heightfield.Heightfield));
		AddReference(mTerrainRows, "weights", "Splat weights",
			"Where each paint layer shows, as the Paint Layers tool paints it (none: the base layer everywhere)", typeof(SplatWeights));
		let shadows = mTerrainRows.Add("castShadows", .Bool, Sedulous.GUI.Variant(true));
		shadows.DisplayName.Set("Casts shadows");
		let blend = mTerrainRows.Add("heightBlend", .Float, Sedulous.GUI.Variant(0.25));
		blend.DisplayName.Set("Height blend");
		blend.Description.Set("How wide the seam is where layers with height maps meet: smaller is crisper");
		blend.HasRange = true;
		blend.Min = 0.0;
		blend.Max = 1.0;
		blend.Step = 0.01;
		blend.Hint.Set("slider");
		let packed = mTerrainRows.Add("textureSize", .Integer, Sedulous.GUI.Variant((int64)1024));
		packed.DisplayName.Set("Layer texture size");
		packed.Description.Set("The size every paint layer's maps are packed at, in texels a side");
		packed.HasRange = true;
		packed.Min = 64.0;
		packed.Max = 4096.0;
		packed.Step = 64.0;

		for (let map in cBaseMaps)
			AddReference(mBaseRows, map.path, map.shown, map.about, typeof(Sedulous.Texture.Resource.Texture));
		Tile(mBaseRows.Add("tile", .Float, Sedulous.GUI.Variant(1.0)), "How many metres its textures repeat over");

		// The layers as every page's lists: the count with Add, each a group of its maps and its
		// tiling. A layer's place is its channel in the splat weights: added and removed, never moved.
		let list = mLayerRows.AddList("layers", .Group, .());
		list.DisplayName.Set("Paint layers");
		list.Description.Set("What the splat weights paint over the base layer, each in its own channel");
		list.ListOps = PropertyListAdd | PropertyListRemove;
		for (let map in cLayerMaps)
		{
			if (let field = mLayerRows.AddElementField("layers", map.Path, .Reference, Sedulous.GUI.Variant("")))
			{
				field.DisplayName.Set(map.Shown);
				field.Description.Set(map.About);
				field.ReferenceType = typeof(Sedulous.Texture.Resource.Texture);
			}
		}
		if (let tile = mLayerRows.AddElementField("layers", "tile", .Float, Sedulous.GUI.Variant((double)TerrainAssetEdit.cNewLayerTileScale)))
			Tile(tile, "How many metres its textures repeat over");

		for (let rows in Sedulous.GUI.PropertyBag[3](mTerrainRows, mBaseRows, mLayerRows))
		{
			rows.SetOnCommit(new [=this, =rows] (commit) =>
				{
					if (!commit.After.IsEmpty)
						Committed(rows, commit.Path, commit.After[0]);
				});
			rows.PropertiesChanged(); // Add told the grid before the rows' names were set
		}
		mLayerRows.SetOnListEdited(new [=this] (path, edit) => { EditLayers(edit); });
		// Each layer by its channel, numbered from 1 as the paint tool's keys are, and closed, by the
		// albedo it shows.
		mLayerRows.SetOnDescribe(new [=this] (path, info) => { DescribeLayer(path, info); });
		AddSection("terrain", "Terrain", mTerrainRows);
		AddSection("base", "Base layer", mBaseRows);
		AddSection("layers", "Paint layers", mLayerRows);
	}

	private void DescribeLayer(StringView path, PropertyInfo info)
	{
		if (ParentPropertyPath(path) != "layers")
			return;
		if (!(int.Parse(LastSegment(path)) case .Ok(let index)))
			return;
		info.DisplayName.Clear();
		info.DisplayName.AppendF("Layer {}", index + 1);
		var value = mLayerRows.GetValue(JoinPropertyPath(path, "albedo", .. scope .()), 0);
		let albedo = GuidOf(value.AsString);
		value.Dispose();
		let named = (!albedo.IsNil && (Context.Project != null)) ? Context.Project.SourceDb.GetInstance(albedo) : null;
		info.Summary.Set((named != null) ? (StringView)named.Name : "No albedo");
	}

	private void ShowRows()
	{
		let asset = Asset;
		if (asset == null)
			return;
		let text = scope String();
		mTerrainRows.SetValue("heightfield", 0, Sedulous.GUI.Variant(GuidText(asset.HeightfieldId, text..Clear())));
		mTerrainRows.SetValue("weights", 0, Sedulous.GUI.Variant(GuidText(asset.WeightsId, text..Clear())));
		mTerrainRows.SetValue("castShadows", 0, Sedulous.GUI.Variant(asset.CastShadows));
		mTerrainRows.SetValue("heightBlend", 0, Sedulous.GUI.Variant((double)asset.HeightBlendContrast));
		mTerrainRows.SetValue("textureSize", 0, Sedulous.GUI.Variant((int64)asset.PaletteTextureSize));
		mBaseRows.SetValue("albedo", 0, Sedulous.GUI.Variant(GuidText(asset.BaseAlbedoId, text..Clear())));
		mBaseRows.SetValue("normal", 0, Sedulous.GUI.Variant(GuidText(asset.BaseNormalId, text..Clear())));
		mBaseRows.SetValue("orm", 0, Sedulous.GUI.Variant(GuidText(asset.BaseOrmId, text..Clear())));
		mBaseRows.SetValue("height", 0, Sedulous.GUI.Variant(GuidText(asset.BaseHeightId, text..Clear())));
		mBaseRows.SetValue("tile", 0, Sedulous.GUI.Variant((double)asset.BaseTileScale));

		let layers = asset.PaletteAlbedoIds.Count;
		mLayerRows.ResizeList("layers", 0, layers);
		let path = scope String();
		for (int i < layers)
		{
			for (let map in cLayerMaps)
			{
				path.Clear();
				path.AppendF("layers.{}.{}", i, map.Path);
				mLayerRows.SetValue(path, 0, Sedulous.GUI.Variant(GuidText(LayerMapId(asset, map, i), text..Clear())));
			}
			path.Clear();
			path.AppendF("layers.{}.tile", i);
			let tile = (i < asset.PaletteTileScales.Count) ? asset.PaletteTileScales[i] : TerrainAssetEdit.cNewLayerTileScale;
			mLayerRows.SetValue(path, 0, Sedulous.GUI.Variant((double)tile));
		}
		SetNotice("heightfield", asset.HeightfieldId.IsNil ? "This terrain has no heightfield: pick one, or there is nothing to draw." : "");
		if (mSplat != null)
			mSplat.Enabled = asset.WeightsId.IsNil;
	}

	private void ShowFacts()
	{
		let product = mProduct.Get;
		if (product == null)
		{
			SetFact("Grid", "Not cooked yet: Save to cook it");
			return;
		}
		let facts = scope List<TerrainFact>();
		defer { ClearAndDeleteItems!(facts); }
		TerrainFact.Of(product, facts);
		for (let fact in facts)
			SetFact(fact.Name, fact.Value);
	}

	private void AddSplatButton()
	{
		// After the bar's own separator, as every page's own controls.
		let own = Find<Node>("page-own");
		let bar = (own != null) ? own.Parent : null;
		if ((bar == null) || LoadFailed)
			return;
		mSplat = new ToolMenuButton();
		mSplat.Id = "terrain-new-weights";
		mSplat.Text = "New Splat Weights";
		mSplat.Tooltip = "Make splat weights for this terrain to paint its layers on, at a size (texels a side)";
		for (let size in cSplatSizes)
			mSplat.Menu.AddItem(scope String()..AppendF("{} x {}", size, size), new [=this, =size] () => { CreateSplatWeights(size); });
		bar.AddChildAt(mSplat, bar.GetChildIndex(own) + 1);
	}

	private void Committed(Sedulous.GUI.PropertyBag rows, StringView path, Sedulous.GUI.Variant value)
	{
		if (Asset == null)
			return;
		if (rows === mTerrainRows)
		{
			if ((path == "heightfield") || (path == "weights"))
			{
				let id = GuidOf(value.AsString);
				let heightfield = path == "heightfield";
				EditWhole("edit_terrain", scope [&] (object) =>
					{
						if (heightfield)
							((TerrainAsset)object).HeightfieldId = id;
						else
							((TerrainAsset)object).WeightsId = id;
					});
			}
			else if (path == "castShadows")
			{
				let casts = value.AsBool;
				EditWhole("edit_terrain", scope [&] (object) => { ((TerrainAsset)object).CastShadows = casts; });
			}
			else if (path == "heightBlend")
			{
				let blend = (float)Math.Clamp(value.AsFloat, 0.0, 1.0);
				EditWhole("edit_terrain", scope [&] (object) => { ((TerrainAsset)object).HeightBlendContrast = blend; });
			}
			else if (path == "textureSize")
			{
				let size = (int32)Math.Clamp(value.AsInt, 64, 4096);
				EditWhole("edit_terrain", scope [&] (object) => { ((TerrainAsset)object).PaletteTextureSize = size; });
			}
			return;
		}
		if (rows === mBaseRows)
		{
			if (path == "tile")
			{
				let tile = (float)Math.Max(0.1, value.AsFloat);
				EditWhole("edit_terrain", scope [&] (object) => { ((TerrainAsset)object).BaseTileScale = tile; });
				return;
			}
			let id = GuidOf(value.AsString);
			let field = scope String(path);
			EditWhole("edit_terrain", scope [&] (object) =>
				{
					let terrainAsset = (TerrainAsset)object;
					if (field == "albedo")
						terrainAsset.BaseAlbedoId = id;
					else if (field == "normal")
						terrainAsset.BaseNormalId = id;
					else if (field == "orm")
						terrainAsset.BaseOrmId = id;
					else if (field == "height")
						terrainAsset.BaseHeightId = id;
				});
			return;
		}
		let layer = LayerOf(path);
		if ((layer < 0) || (layer >= Asset.PaletteAlbedoIds.Count))
			return;
		let field = LastSegment(path);
		if (field == "tile")
		{
			let tile = (float)Math.Max(0.1, value.AsFloat);
			EditWhole("edit_terrain", scope [&] (object) =>
				{
					let terrainAsset = (TerrainAsset)object;
					TerrainAssetEdit.Square(terrainAsset);
					terrainAsset.PaletteTileScales[layer] = tile;
				});
			return;
		}
		for (let map in cLayerMaps)
		{
			if (field != map.Path)
				continue;
			let id = GuidOf(value.AsString);
			let kind = map.Map;
			EditWhole("edit_terrain", scope [&] (object) =>
				{
					let terrainAsset = (TerrainAsset)object;
					TerrainAssetEdit.Square(terrainAsset);
					if (kind.HasValue)
						TerrainAssetEdit.MapIds(terrainAsset, kind.Value)[layer] = id;
					else
						terrainAsset.PaletteAlbedoIds[layer] = id;
				});
		}
	}

	private void RemapWeightsOnRemove(uint32 removed)
	{
		let product = mProduct.Get;
		let weights = (product != null) ? product.Weights.Get : null;
		if ((weights == null) || weights.IsEmpty || !SplatBrush.RemapOnPaletteRemove(weights, removed))
			return; // no live weights (not cooked yet): nothing names the layers by channel
		let id = product.Weights.Id;
		if (id.IsSet)
			Context.RegisterAssetEdit(id, TerrainPersist.ForSplat(weights, id)); // written with the next save, as a brush's strokes are
	}

	private static Guid LayerMapId(TerrainAsset asset, LayerMap map, int index)
	{
		if (map.Map.HasValue)
			return TerrainAssetEdit.MapId(asset, map.Map.Value, index);
		return (index < asset.PaletteAlbedoIds.Count) ? asset.PaletteAlbedoIds[index] : .Empty;
	}

	// The layer a path names ("layers.2.normal": 2), or -1.
	private static int LayerOf(StringView path)
	{
		let element = ParentPropertyPath(path);
		if (ParentPropertyPath(element) != "layers")
			return -1;
		if (int.Parse(LastSegment(element)) case .Ok(let index))
			return (index >= 0) ? index : -1;
		return -1;
	}

	private static StringView LastSegment(StringView path)
	{
		let dot = path.LastIndexOf('.');
		return (dot >= 0) ? path.Substring(dot + 1) : path;
	}

	/// The id as a row shows it, appended: empty for none.
	private static StringView GuidText(Guid id, String outText)
	{
		if (!id.IsNil)
			id.ToString(outText);
		return outText;
	}

	private static Guid GuidOf(StringView text)
	{
		var trimmed = text;
		trimmed.Trim();
		if (!trimmed.IsEmpty && (Guid.Parse(trimmed) case .Ok(let id)))
			return id;
		return .();
	}

	// === The preview ===

	private Sedulous.Scene.Scene PreviewScene => ((mPane != null) && (mPane.Viewport != null)) ? mPane.Viewport.Scene : null;

	private void BuildPreviewScene()
	{
		let scene = PreviewScene;
		if (scene == null)
			return;
		if (scene.GetSystem<TerrainComponentManager>() == null)
			TerrainScene.AddTerrainSceneManagers(scene);
		mEntity = scene.CreateEntity("PreviewTerrain");
		if (let terrains = scene.GetSystem<TerrainComponentManager>())
			terrains.Add(mEntity); // given its terrain once the product resolves
		let sun = scene.CreateEntity("Sun");
		var t = Transform();
		t.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), 0.5f) * Quaternion.FromAxisAngle(.(1, 0, 0), -0.9f);
		scene.SetLocalTransform(sun, t);
		if (let lights = scene.GetSystem<LightComponentManager>())
		{
			let light = lights.Add(sun);
			light.Type = .Directional;
			light.CastsShadows = true; // the terrain's own shadows show
		}
	}

	private void PointPreviewAt(TerrainResource product)
	{
		let scene = PreviewScene;
		let terrains = (scene != null) ? scene.GetSystem<TerrainComponentManager>() : null;
		let component = ((terrains != null) && mEntity.IsAssigned) ? terrains.Get(mEntity) : null;
		if (component == null)
			return;
		component.Terrain.SetId(.());
		component.Terrain.SetDirect(product); // the cooked product, or none while it is not cooked
		if (mPane != null)
		{
			if (product != null)
				mPane.Show();
			else
				mPane.ShowEmpty("", "");
		}
	}

	private void FramePreview()
	{
		if ((mPane == null) || (mPane.Viewport == null))
			return;
		let product = mProduct.Get;
		let grid = (product != null) ? product.Heightfield.Get : null;
		let world = (grid != null) ? grid.WorldSize : Float2(256.0f, 256.0f);
		let middle = (grid != null) ? 0.5f * (grid.MinY + grid.MaxY) : 0.0f;
		let size = Math.Max(world.X, world.Y);
		let preview = mPane.Viewport;
		// From above a corner, far enough that the whole of it is in view (the terrain is centred on
		// its origin), and its far side within the camera's reach.
		let away = Normalized(Float3(1.0f, 0.85f, 1.0f));
		let distance = size * 1.25f;
		preview.Camera.Position = Float3(0.0f, middle, 0.0f) + away * distance;
		preview.Camera.LookAt(.(0.0f, middle, 0.0f));
		preview.Camera.FarZ = Math.Max(preview.Camera.FarZ, distance + size);
	}
}
