using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Settings;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The asset types of the asset picker's project. AlwaysInclude, so their type data (the name the
/// registry resolves, the category) is there to be asked.
[Category("Rendering"), AlwaysInclude]
class PickMeshAsset
{
}

[AlwaysInclude]
class PickSoundAsset
{
}

/// The asset picker over its markup (Data/Editor/AssetPicker.gml) and a scratch project: the groups
/// a tree (Favourites and All first, then the project's, Content at the top); the current value's
/// group chosen and its row lit, the foot saying Esc keeps it; a group holding only what the slot
/// takes; a search over every group, each match saying where it lives; Favourites; tiles or a list
/// kept with the project for the next pick; Enter picking and closing; its close keeping the value. Then
/// what Sedulous adds so each behaviour has a test: a type taken by its short or full name, the
/// wildcard or none taking any; a row's type glyph and tint, without the browser's state columns; and
/// the state saying what is missing.
static class AssetPickerWindowTests
{
	/// Content (Crate, Models (Town (Barrel, Bell, Bucket)), Sounds) in an editor context with a
	/// project editor store; the picker over a root of a GUI of its own, 900 by 600.
	private class Bed
	{
		public String Dir = new .("scratch_asset_picker") ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .();
		public Settings Store = new .();
		public EditorIcons Icons;
		public SceneRoot Root;
		public AssetPickerWindow Picker;
		public String MeshName = new .() ~ delete _;
		public String SoundName = new .() ~ delete _;
		public Instance Crate;
		public Instance Barrel;
		public Instance Bell;
		public Instance Bucket;
		public List<Guid> Chosen = new .() ~ delete _;
		public int Saves = 0;
		/// The crate's thumbnail, once "generated" (a reference of ours).
		public Sedulous.GUI.Drawable Picture = null ~ _?.ReleaseRef();

		public this()
		{
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "Pick") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			typeof(PickMeshAsset).GetFullName(MeshName);
			typeof(PickSoundAsset).GetFullName(SoundName);
			let top = Project.SourceDb.RootGroup;
			Crate = top.CreateInstance("Crate", MeshName);
			let town = top.CreateGroup("Models").CreateGroup("Town");
			Barrel = town.CreateInstance("Barrel", MeshName);
			Bell = town.CreateInstance("Bell", SoundName);
			Bucket = town.CreateInstance("Bucket", MeshName);
			Test.Assert(top.CreateGroup("Sounds") != null);
			Test.Assert((Crate != null) && (Barrel != null) && (Bell != null) && (Bucket != null));
			Context.SetProject(Project);
			Context.ProjectEditorSettings = Store;
			let bed = this;
			Context.OnProjectEditorSettingsSaveRequested = new [=bed] () => { bed.Saves++; };
			// The mesh has an icon of its own; the sound takes the generic asset's.
			Icons = new EditorIcons(new (path) => (path == "Editor/Icons/Types/PickMeshAsset.svg") || (path == "Editor/Icons/Types/Asset.svg"));
			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(900.0f, 600.0f);
			let services = new AssetPickerServices();
			services.Context = Context;
			services.Icons = Icons;
			services.Picture = new [=bed] (id) => (id == bed.Crate.Id) ? bed.Picture : null;
			Picker = new AssetPickerWindow(services, PagesBed.LoadMarkup(AssetPickerWindow.cMarkupPath));
		}

		public ~this()
		{
			// The picker closed while the root is there, the context before the store it borrows.
			DeleteAndNullify!(Picker);
			delete Icons;
			Context.ProjectEditorSettings = null;
			Context.SetProject(null);
			delete Context;
			delete Store;
			Root.ReleaseRef();
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// A slot of `types` (none given: the mesh, by its short name) holding `current`, opened.
		public void Open(Guid current, Span<String> types = default)
		{
			let request = new AssetPickRequest();
			if (types.IsEmpty)
				request.Types.Add(new String("PickMeshAsset"));
			for (let type in types)
				request.Types.Add(new String(type));
			request.Current = current;
			let bed = this;
			request.Chosen = new [=bed] (id) => { bed.Chosen.Add(id); };
			Test.Assert(Picker.Open(Root, request));
			Layout();
		}

		/// Twice: the popup is sized by what it holds, then what it holds is placed in it.
		public void Layout()
		{
			Root.UpdateLayout();
			Root.UpdateLayout();
		}

		public bool Press(Sedulous.GUI.KeyCode key) => Root.EventDispatcher.InjectKeyDown((uint32)key);

		/// The cell a row is drawn by, once laid out; null when it is not realised.
		public AssetCell Cell(int32 row)
		{
			Layout();
			let holder = Picker.List.RowForItem(row);
			return (holder != null) ? (holder.Content as AssetCell) : null;
		}

		/// The list a fixed 400 by 300, so it realises its rows without the sheet.
		public void SizeList()
		{
			Picker.List.EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Px(400.0f);
					s.Height = LayoutLength.Px(300.0f);
				});
			Layout();
		}
	}

	[Test]
	public static void TheGroupsATreeFavouritesAndAllFirstTheCurrentValuesGroupChosenItsRowLit()
	{
		let bed = scope Bed();
		bed.Open(bed.Barrel.Id);
		Test.Assert(bed.Picker.IsOpen);
		Test.Assert(bed.Picker.Groups(.. scope .()) == "Favourites | All PickMeshAssets | Content | Models | Town | Sounds");
		Test.Assert(bed.Picker.Rows(.. scope .()) == "Barrel | Bucket", "the sound is not one it takes");
		Test.Assert(bed.Picker.LitName == "Barrel");
		Test.Assert(bed.Picker.Where == "Town  ·  2 pickmeshassets");
		Test.Assert(bed.Picker.Hint == "Enter picks, Esc keeps Barrel");
		// In the window's middle, as every picker opens.
		let frame = bed.Picker.Content.ScreenBounds;
		Test.Assert(Math.Abs(frame.X + frame.Width * 0.5f - 450.0f) < 4.0f, scope $"the frame's middle at {frame.X + frame.Width * 0.5f}");
		Test.Assert(Math.Abs(frame.Y + frame.Height * 0.5f - 300.0f) < 3.0f, scope $"the frame's middle at {frame.Y + frame.Height * 0.5f}");
	}

	[Test]
	public static void AGroupHoldsWhatItHoldsAllEveryGroupsASearchEveryGroupsSayingWhereEachLives()
	{
		let bed = scope Bed();
		bed.Open(.Empty);
		Test.Assert(bed.Picker.Rows(.. scope .()) == "Crate | Barrel | Bucket", "nothing current: All");
		Test.Assert(bed.Picker.LitName == "Crate");
		Test.Assert(bed.Picker.Hint == "Enter picks, Esc closes");
		Test.Assert(bed.Picker.ChooseSource("Content"));
		Test.Assert(bed.Picker.Rows(.. scope .()) == "Crate");
		Test.Assert(bed.Picker.ChooseSource("Sounds"));
		Test.Assert(bed.Picker.Rows(.. scope .()).IsEmpty);
		Test.Assert(bed.Picker.StateText == "No pickmeshassets here.");
		Test.Assert(!bed.Picker.ChooseSource("Attic"), "no such group");
		bed.Picker.Search("bu");
		Test.Assert(bed.Picker.Rows(.. scope .()) == "Bucket");
		Test.Assert(bed.Picker.Where == "In every group  ·  1 pickmeshassets");
		bed.SizeList();
		let cell = bed.Cell(0);
		Test.Assert(cell != null);
		Test.Assert(cell.Kind == "PickMeshAsset in Content/Models/Town");
		Test.Assert(cell.Tooltip == "Content/Models/Town/Bucket (PickMeshAsset)", "hovered: the whole of where it lives");
		bed.Picker.Search("zz");
		Test.Assert(bed.Picker.StateText == "No pickmeshassets match \"zz\".");
		bed.Picker.Search("");
		Test.Assert(bed.Picker.Rows(.. scope .()).IsEmpty, "the chosen group again");
	}

	[Test]
	public static void FavouritesHoldsTheStarredAssetsItTakes()
	{
		let bed = scope Bed();
		bed.Context.ToggleFavorite(bed.Bucket.Id);
		bed.Context.ToggleFavorite(bed.Bell.Id); // not a type it takes
		bed.Open(.Empty);
		Test.Assert(bed.Picker.ChooseSource("Favourites"));
		Test.Assert(bed.Picker.Rows(.. scope .()) == "Bucket");
		bed.Context.ToggleFavorite(bed.Bucket.Id);
		Test.Assert(bed.Picker.ChooseSource("Favourites"));
		Test.Assert(bed.Picker.StateText == "No favourite pickmeshassets: star one in the Assets panel.");
	}

	[Test]
	public static void TilesOrAListKeptWithTheProjectForTheNextPick()
	{
		let bed = scope Bed();
		bed.Open(.Empty);
		Test.Assert(!bed.Picker.ShowsTiles, "a list until the project says otherwise");
		Test.Assert(bed.Picker.List.LayoutMode == .List);
		bed.Picker.SetTiles(true);
		Test.Assert(bed.Picker.List.LayoutMode == .Grid);
		Test.Assert(bed.Picker.List.HasClass("asset-tiles"));
		let saved = bed.Store.Find<EditorAssetBrowserSettings>();
		Test.Assert(saved != null);
		Test.Assert(saved.PickerGridMode);
		Test.Assert(!saved.GridMode, "the browser's own choice untouched");
		Test.Assert(bed.Saves == 1);
		bed.Picker.Close();
		bed.Open(.Empty);
		Test.Assert(bed.Picker.ShowsTiles);
	}

	[Test]
	public static void DownThenEnterPicksTheNextRowAndClosesNonePicksNothing()
	{
		let bed = scope Bed();
		bed.Open(bed.Barrel.Id);
		bed.Press(.Down);
		Test.Assert(bed.Picker.LitName == "Bucket");
		bed.Press(.Down); // the last: kept
		Test.Assert(bed.Picker.LitName == "Bucket");
		bed.Press(.Return);
		Test.Assert(bed.Chosen.Count == 1);
		Test.Assert(bed.Chosen[0] == bed.Bucket.Id);
		Test.Assert(!bed.Picker.IsOpen);

		bed.Open(bed.Barrel.Id);
		Test.Assert(bed.Picker.CloseButton != null);
		Test.Assert(bed.Picker.CloseButton.HandleActivate());
		Test.Assert(bed.Chosen.Count == 1); // nothing picked: the value stays
		Test.Assert(!bed.Picker.IsOpen);
	}

	[Test]
	public static void ATypeTakenByItsShortOrFullNameTheWildcardOrNoneTakingAny()
	{
		let bed = scope Bed();
		String[1] full = .(bed.MeshName);
		bed.Open(.Empty, full);
		Test.Assert(bed.Picker.Rows(.. scope .()) == "Crate | Barrel | Bucket");
		bed.Picker.Close();
		String[1] sounds = .("PickSoundAsset");
		bed.Open(.Empty, sounds);
		Test.Assert(bed.Picker.Rows(.. scope .()) == "Bell");
		bed.Picker.Close();
		String[2] wild = .("PickSoundAsset", AssetPickerSlot.cAnyAsset);
		bed.Open(.Empty, wild);
		Test.Assert(bed.Picker.Rows(.. scope .()) == "Crate | Barrel | Bell | Bucket", "the wildcard takes any");
		Test.Assert(bed.Picker.Groups(.. scope .()).StartsWith("Favourites | All Assets |"));

		String[1] meshes = .("PickMeshAsset");
		Test.Assert(AssetPickerWindow.Takes(bed.MeshName, meshes));
		Test.Assert(!AssetPickerWindow.Takes(bed.SoundName, meshes));
		Test.Assert(AssetPickerWindow.Takes(bed.SoundName, Span<String>()), "none named takes any");
	}

	[Test]
	public static void ARowsTypeGlyphAndTintWithoutTheBrowsersStateColumns()
	{
		let bed = scope Bed();
		String[1] wild = .(AssetPickerSlot.cAnyAsset);
		bed.Open(.Empty, wild);
		bed.SizeList();
		let crate = bed.Cell(0);
		Test.Assert(crate != null);
		Test.Assert(crate.Name == "Crate");
		Test.Assert(crate.Glyph == "Editor/Icons/Types/PickMeshAsset.svg");
		Test.Assert(crate.GlyphClass == "cat-rendering");
		Test.Assert(crate.Kind == "PickMeshAsset in Content", "All: where it lives");
		Test.Assert(!crate.AlwaysExportPart.Displayed, "a pick asks nothing of its export");
		Test.Assert(!crate.ShowsBadge);
		let bell = bed.Cell(2);
		Test.Assert(bell.Name == "Bell");
		Test.Assert(bell.Glyph == "Editor/Icons/Types/Asset.svg", "no icon of its own: the generic asset's");
		Test.Assert(bell.GlyphClass.IsEmpty, "no category: no tint");
	}

	/// A long where gives way, never the name, nor is it drawn over it: in the picker it is cut in
	/// the middle, the type and the asset's own folder kept. Each where starts in one column.
	[Test]
	public static void ALongWhereGivesWayNeverTheNameNorDrawnOverItEachWhereStartsInOneColumn()
	{
		let bed = scope Bed();
		var deep = bed.Project.SourceDb.RootGroup.GetGroup("Models");
		for (let name in StringView[?]("Mechanics", "Bridge_Modular_With_A_Long_Name", "Bridge_Modular_Pieces_Also_Long"))
			deep = deep.CreateGroup(name);
		Test.Assert(bed.Project.SourceDb.RootGroup.CreateInstance("Cube.051", bed.MeshName) != null);
		Test.Assert(deep.CreateInstance("Cube.051", bed.MeshName) != null);
		let sheet = scope EditorSheet(true); // goes first, while the tree it styled is there

		bed.Open(.Empty);
		bed.Picker.Search("Cube"); // every group's, each row saying where it lives
		Test.Assert(bed.Picker.Rows(.. scope .()) == "Cube.051 | Cube.051");
		sheet.Apply(bed.Root);
		let near = bed.Cell(0); // the rows made, then styled too
		let far = bed.Cell(1);
		Test.Assert((near != null) && (far != null));
		sheet.Apply(bed.Root);
		bed.Layout();
		Test.Assert(far.Kind.Length > near.Kind.Length, "the deep one's where is the long one");
		Test.Assert(far.KindLabel.TextOverflow == .EllipsisMiddle, "the picker's where is cut in the middle");

		let farName = far.NameLabel.ScreenBounds;
		let farKind = far.KindLabel.ScreenBounds;
		let farRow = far.ScreenBounds;
		Test.Assert(far.KindLabel.MeasureText().X > farKind.Width, "the where is cut: it did not fit");
		Test.Assert(farName.Width >= far.NameLabel.MeasureText().X - 0.5f, "the name keeps its room");
		Test.Assert(farKind.X >= farName.X + farName.Width - 0.5f, "the where after it, not over it");
		Test.Assert(farKind.X + farKind.Width <= farRow.X + farRow.Width + 0.5f);
		// A column: where each asset lives starts at one x, whatever its name or its path.
		Test.Assert(Math.Abs(near.KindLabel.ScreenBounds.X - farKind.X) < 0.5f);
		bed.Picker.Close();
	}

	[Test]
	public static void ARowsMenuPinsItAsAFavouriteOrUnpinsIt()
	{
		let bed = scope Bed();
		bed.Open(.Empty);
		Test.Assert(bed.Picker.ChooseSource("Favourites"));
		Test.Assert(bed.Picker.Rows(.. scope .()).IsEmpty);
		Test.Assert(bed.Picker.ChooseSource("All PickMeshAssets"));
		bed.Picker.ShowRowMenu(0, .(20.0f, 10.0f)); // Crate
		var menu = bed.Picker.RowMenu;
		Test.Assert(menu != null);
		let pin = MenuRows.ItemNamed(menu, "Pin as Favourite");
		Test.Assert(pin != null);
		Test.Assert(pin.HandleActivate());
		Test.Assert(bed.Context.IsFavorite(bed.Crate.Id));
		Test.Assert(bed.Picker.ChooseSource("Favourites"));
		Test.Assert(bed.Picker.Rows(.. scope .()) == "Crate");
		bed.Picker.ShowRowMenu(0, .(20.0f, 10.0f));
		menu = bed.Picker.RowMenu;
		Test.Assert(menu != null);
		let unpin = MenuRows.ItemNamed(menu, "Unpin Favourite");
		Test.Assert(unpin != null);
		Test.Assert(unpin.HandleActivate());
		Test.Assert(!bed.Context.IsFavorite(bed.Crate.Id));
		Test.Assert(bed.Picker.Rows(.. scope .()).IsEmpty); // it left the Favourites shown
	}

	[Test]
	public static void AWholeGuidOfAnAssetTheSlotDoesNotTakeSaysWhatItIs()
	{
		let bed = scope Bed();
		bed.Open(.Empty);
		bed.Picker.Search(bed.Bell.Id.ToString(.. scope .()));
		Test.Assert(bed.Picker.Rows(.. scope .()).IsEmpty);
		Test.Assert(bed.Picker.StateText == "'Bell' is a PickSoundAsset, which this slot does not take.", scope String(bed.Picker.StateText));
		bed.Picker.Search("nothing like it");
		Test.Assert(bed.Picker.StateText == "No pickmeshassets match \"nothing like it\".");
	}

	[Test]
	public static void ARowShowsTheAssetsThumbnailSmallInItsIconsPlaceAsATileDoes()
	{
		let bed = scope Bed();
		bed.Picture = SvgDrawable.FromText("<svg xmlns='http://www.w3.org/2000/svg' width='8' height='8'><rect width='8' height='8'/></svg>");
		bed.Open(.Empty);
		Test.Assert(bed.Picker.ChooseSource("All PickMeshAssets"));
		Test.Assert(!bed.Picker.ShowsTiles);
		bed.SizeList();
		let crate = bed.Cell(0);
		Test.Assert(crate != null);
		Test.Assert(crate.ShowsPicture);
		let barrel = bed.Cell(1);
		Test.Assert(barrel != null);
		Test.Assert(!barrel.ShowsPicture); // none yet: its glyph
	}
}
