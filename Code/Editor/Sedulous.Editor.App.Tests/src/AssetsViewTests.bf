using System;
using System.Collections;
using System.Diagnostics;
using System.Threading;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Settings;
using Sedulous.Pipeline.Core;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The asset types of the browser's project. AlwaysInclude, so their type data (the name the
/// registry resolves, the category, the display name) is there to be asked. The mesh has a
/// category and no display name; the sound a display name and no category.
[Category("Rendering"), AlwaysInclude]
class BrowserMesh
{
}

[DisplayName("Browser Sound"), AlwaysInclude]
class BrowserSound
{
}

/// A builder for BrowserMesh, so the cook service badges a mesh; never run.
class BrowserMeshBuilder : IAssetBuilder
{
	public Type AssetType => typeof(BrowserMesh);
	public Type ProductType => typeof(BrowserMesh);

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context) => .Err(.Unknown);
}

/// The Assets panel over its markup (Data/Editor/Assets.gml) and a scratch project: the group tree
/// and the breadcrumb following where it is; a group's subgroups then its assets, each by name,
/// what it is and its star; entering a group and opening an asset; the search over every group
/// saying where each match is, and the type filter, each with its state when nothing is left and
/// the way back; tiles or a list kept with the project; building again when the database's shape
/// moves; Reveal; a drag of the selection carrying its assets; and, under the editor's sheet, the
/// toolbar keeping its height and the type menu opening below its button. Then what Sedulous adds
/// so each behaviour has a test: the tree's click and Enter navigating, the breadcrumb's tooltip, a
/// guid typed whole, braced or bare selecting its asset, the clear button and the state's verb, the
/// type filter's menu and a type's display name, the toggles' checks, a type's glyph and tint, the
/// cook badges (a tile marks only stale or failed) and the cells drawn again when a cook lands,
/// another project's view starting at its top, and the filter's matching itself (AssetFilter).
static class AssetsViewTests
{
	/// The frame read from the repository's Data with the elements the editor's window registers
	/// (the breadcrumb is the toolkit's); its one reference is the caller's.
	private static Node LoadAssets()
	{
		let data = scope String();
		Test.Assert(EditorSplashTests.DataRoot(data));
		let text = scope String();
		Test.Assert(System.IO.File.ReadAllText(PathJoin(data, AssetsView.cMarkupPath, .. scope .()), text) case .Ok);
		RegisterGuiElements();
		RegisterToolkitElements();
		let elements = ElementSet.All();
		defer delete elements;
		let loader = scope MarkupLoader(elements);
		return loader.LoadFromString(text);
	}

	/// Content (Crate, Models (Town (Barrel, Bell)), Sounds) open in an editor context with a
	/// project editor store; the view in a root of a GUI of its own, 900 by 600, what it opened
	/// in Opened. With a cook, a cook service over no builders, or the mesh's (`cooksMeshes`).
	/// For the editor's sheet (`forSheet`), the toolbar and the group tree are left to it.
	private class Bed
	{
		public String Dir = new .() ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .();
		public Settings Store = new .();
		public EditorIcons Icons;
		public BuilderRegistry Builders = null;
		public EditorCookService Cook = null;
		public SceneRoot Root;
		public AssetsView View;
		public String MeshName = new .() ~ delete _;
		public String SoundName = new .() ~ delete _;
		// The project's.
		public Group Top;
		public Group Models;
		public Group Town;
		public Group Sounds;
		public Instance Crate;
		public Instance Barrel;
		public Instance Bell;
		public List<Guid> Opened = new .() ~ delete _;
		/// How often the store was asked to be saved.
		public int Saves = 0;
		/// The toolbar and the group tree are the sheet's to size.
		public bool ForSheet;
		/// The editor's sheet, once StyleAsTheEditor has styled the tree.
		public EditorSheet Sheet = null;

		public this(StringView dir, bool withCook = false, bool cooksMeshes = false, bool forSheet = false)
		{
			Dir.Set(dir);
			ForSheet = forSheet;
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "Browse") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			typeof(BrowserMesh).GetFullName(MeshName);
			typeof(BrowserSound).GetFullName(SoundName);
			Top = Project.SourceDb.RootGroup;
			Crate = Top.CreateInstance("Crate", MeshName);
			Models = Top.CreateGroup("Models");
			Town = Models.CreateGroup("Town");
			Barrel = Town.CreateInstance("Barrel", MeshName);
			Bell = Town.CreateInstance("Bell", SoundName);
			Sounds = Top.CreateGroup("Sounds");
			Test.Assert((Crate != null) && (Barrel != null) && (Bell != null) && (Sounds != null));
			Context.SetProject(Project);
			Context.ProjectEditorSettings = Store;
			let bed = this;
			Context.OnProjectEditorSettingsSaveRequested = new [=bed] () => { bed.Saves++; };
			// The mesh has an icon of its own; the sound takes the generic asset's.
			Icons = new EditorIcons(new (path) => (path == "Editor/Icons/Types/BrowserMesh.svg") || (path == "Editor/Icons/Types/Asset.svg"));
			if (withCook)
			{
				Builders = new .();
				if (cooksMeshes)
					Builders.Register(new BrowserMeshBuilder());
				Cook = new .();
				Cook.Initialize(Project, Builders);
			}
			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(900.0f, 600.0f);
			View = MakeView();
			Root.AddChild(View.Content);
			Layout();
		}

		public ~this()
		{
			// The sheet while what it styled is there, the view (its list and tree let go while
			// the root holds them), the cook before the project it reads, the context before the
			// store it borrows.
			DeleteAndNullify!(Sheet);
			DeleteAndNullify!(View);
			if (Cook != null)
			{
				Cook.Shutdown();
				delete Cook;
			}
			delete Builders;
			delete Icons;
			Context.ProjectEditorSettings = null;
			Context.SetProject(null);
			delete Context;
			delete Store;
			Root.ReleaseRef();
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// A view over the bed's services, built; the caller's. No sheet here: the group tree
		/// beside the content, each a size of its own (the editor's sheet sizes them), the toolbar
		/// and the tree left to the sheet in a bed made for it.
		public AssetsView MakeView()
		{
			let services = new AssetsViewServices();
			services.Context = Context;
			services.Cook = Cook;
			services.Icons = Icons;
			let bed = this;
			services.Open = new [=bed] (instance) => { bed.Opened.Add(instance.Id); };
			let view = new AssetsView(services, LoadAssets());
			Test.Assert((view.Content != null) && (view.List != null) && (view.Tree != null) && (view.Crumbs != null));
			view.Content.EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Px(900.0f);
					s.Height = LayoutLength.Px(600.0f);
				});
			if (!ForSheet)
			{
				// The toolbar a row of its own height, the body under it.
				view.Content.GetChildAt(0).EditLayoutStyle(scope (s) =>
					{
						s.Direction = .Row;
						s.Height = LayoutLength.Px(30.0f);
					});
				view.Tree.Parent.EditLayoutStyle(scope (s) => { s.Direction = .Row; });
				view.Tree.EditLayoutStyle(scope (s) =>
					{
						s.Width = LayoutLength.Px(200.0f);
						s.Height = LayoutLength.Px(300.0f);
					});
			}
			view.List.EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Px(600.0f);
					s.Height = LayoutLength.Px(300.0f);
				});
			view.Rebuild();
			return view;
		}

		public void Layout()
		{
			Root.UpdateLayout();
			Root.UpdateLayout();
		}

		/// The tree styled by the editor's own sheet (the default density's), as the window makes it,
		/// then laid out.
		public void StyleAsTheEditor()
		{
			Sheet = new .();
			Sheet.Apply(Root);
			Layout();
		}

		/// The rows shown, a group's marked /.
		public void Rows(String outText)
		{
			for (int i < View.RowCount)
			{
				if (!outText.IsEmpty)
					outText.Append(" ");
				if (View.RowGroup(i) != null)
					outText.Append("/");
				outText.Append(View.RowName(i));
			}
		}

		public bool RowsAre(StringView expected)
		{
			let text = Rows(.. scope .());
			if (text != expected)
				Console.WriteLine("  rows are '{}', expected '{}'", text, expected);
			return text == expected;
		}

		public int32 RowOf(StringView name)
		{
			for (int i < View.RowCount)
			{
				if (View.RowName(i) == name)
					return (int32)i;
			}
			return -1;
		}

		/// The cell a row is drawn by, once laid out; null when it is not realised.
		public AssetCell Cell(int32 row)
		{
			Layout();
			let holder = View.List.RowForItem(row);
			return (holder != null) ? (holder.Content as AssetCell) : null;
		}

		/// The middle of a realised row of `view`, where the pointer reaches it (asserted).
		public Float2 Middle(ItemView view, int32 item)
		{
			Layout();
			let row = view.RowForItem(item);
			Test.Assert(row != null, "realised");
			let bounds = row.ScreenBounds;
			Test.Assert((bounds.Width > 0.0f) && (bounds.Height > 0.0f), "laid out");
			let at = Float2(bounds.X + bounds.Width * 0.5f, bounds.Y + bounds.Height * 0.5f);
			var hit = Root.OverFind(at);
			while ((hit != null) && (hit != row))
				hit = hit.Parent;
			Test.Assert(hit == row, "the pointer reaches it");
			return at;
		}

		public void Click(Float2 at)
		{
			Root.EventDispatcher.InjectMouseMove(at);
			Root.EventDispatcher.InjectMouseDown(at, .Left);
			Root.EventDispatcher.InjectMouseUp(at, .Left);
		}

		/// The tree's item showing `text`; -1 with none.
		public int32 TreeItem(StringView text)
		{
			let shown = scope String();
			for (int32 item < (int32)View.Tree.GetItemCount())
			{
				shown.Clear();
				View.Tree.GetItemText(item, shown);
				if (shown == text)
					return item;
			}
			return -1;
		}

		/// The frame's part with this id, as a T; null when it has none.
		public T Part<T>(StringView id) where T : Node
		{
			return View.Content.FindElement(id) as T;
		}
	}

	/// Content at the top, its subgroups then its assets; entering a group (as Enter or a double
	/// click, by a row's activation and by Enter on the list) moves the breadcrumb and the tree; an
	/// asset opens; the breadcrumb climbs back; a click on a group in the tree goes there.
	[Test]
	public static void AGroupsSubgroupsThenItsAssetsEnteringAGroupMovesTheBreadcrumbAndTheTreeAnAssetOpens()
	{
		let bed = scope Bed("scratch_assets_view_browse");
		let view = bed.View;
		Test.Assert(view.CurrentGroup == bed.Top);
		Test.Assert(bed.RowsAre("/Models /Sounds Crate"));
		Test.Assert(view.Crumbs.ItemCount == 1);
		Test.Assert(view.Crumbs.ItemAt(0).Text == "Content");
		let tree = view.Tree;
		Test.Assert(tree.GetItemCount() == 4, "every group open: Content, Models, Town, Sounds");
		Test.Assert(bed.TreeItem("Content") == 0);
		Test.Assert(tree.SelectedItem == 0);

		view.OpenRow(bed.RowOf("Models")); // as Enter or a double click
		Test.Assert(view.CurrentGroup == bed.Models);
		Test.Assert(bed.RowsAre("/Town"));
		view.List.SelectedItem = bed.RowOf("Town");
		Test.Assert(view.List.HandleActivate(), "Enter on the list");
		Test.Assert(view.CurrentGroup == bed.Town);
		Test.Assert(bed.RowsAre("Barrel Bell"));
		Test.Assert(view.Crumbs.ItemCount == 3);
		Test.Assert(view.Crumbs.ItemAt(1).Text == "Models");
		Test.Assert(view.Crumbs.ItemAt(2).Text == "Town");
		Test.Assert(view.Crumbs.ItemAt(2).Tooltip == "Content/Models/Town");
		Test.Assert(tree.SelectedItem == bed.TreeItem("Town"));

		view.OpenRow(bed.RowOf("Barrel"));
		Test.Assert((bed.Opened.Count == 1) && (bed.Opened[0] == bed.Barrel.Id));
		view.List.SelectedItem = bed.RowOf("Bell");
		Test.Assert(view.List.HandleActivate());
		Test.Assert((bed.Opened.Count == 2) && (bed.Opened[1] == bed.Bell.Id));
		Test.Assert(view.CurrentGroup == bed.Town, "an asset opens; it is no group to enter");

		// The breadcrumb climbs back.
		Test.Assert(view.Crumbs.Navigate(0));
		Test.Assert(view.CurrentGroup == bed.Top);
		Test.Assert(tree.SelectedItem == 0);

		// A click on a group in the tree goes there.
		bed.Click(bed.Middle(tree, bed.TreeItem("Sounds")));
		Test.Assert(view.CurrentGroup == bed.Sounds);
		Test.Assert(view.Crumbs.ItemCount == 2);
	}

	/// The search looks in every group, by name in any case, a match saying where it is, by its
	/// type's display name where it has one; a guid's start finds its asset, a whole guid (braced or
	/// bare) selects it; nothing matching says so, and its verb, the clear button or entering a
	/// group clears the search.
	[Test]
	public static void ASearchLooksInEveryGroupSayingWhereEachMatchIsNothingMatchingSaysSoAndClears()
	{
		let bed = scope Bed("scratch_assets_view_search");
		let view = bed.View;
		let field = bed.Part<TextField>("assets-search");
		let clear = bed.Part<Sedulous.GUI.Button>("assets-clear-search");
		Test.Assert((field != null) && (clear != null));
		Test.Assert(!clear.Visible, "nothing to clear");
		view.SetTiles(false);
		// Searched from inside another group: the search is not that group's alone.
		view.Navigate(bed.Sounds);
		view.SetSearch("BAR");
		Test.Assert(bed.RowsAre("Barrel"));
		Test.Assert(field.Text == "BAR");
		Test.Assert(clear.Visible);
		var cell = bed.Cell(0);
		Test.Assert(cell != null);
		Test.Assert(cell.Kind == "BrowserMesh in Content/Models/Town");
		view.Navigate(bed.Top); // the rest from the top
		view.SetSearch("bell");
		cell = bed.Cell(0);
		Test.Assert(bed.RowsAre("Bell"));
		Test.Assert(cell.Kind == "Browser Sound in Content/Models/Town", "its type's display name");

		// A guid's start finds it, and leaves the choosing to the user; a whole one selects it.
		let guid = bed.Crate.Id.ToString(.. scope .());
		view.SetSearch(StringView(guid, 0, 8));
		Test.Assert(bed.RowsAre("Crate"));
		Test.Assert(view.List.SelectedItem == -1);
		let braced = scope $"{{{guid}}}";
		braced.ToUpper();
		view.SetSearch(braced);
		Test.Assert(bed.RowsAre("Crate"));
		Test.Assert(view.List.SelectedItem == 0, "a whole guid selects its asset");
		let bare = scope String(guid)..Replace("-", "");
		view.SetSearch(bare);
		Test.Assert(bed.RowsAre("Crate"));
		Test.Assert(view.List.SelectedItem == 0);

		view.SetSearch("crate4");
		Test.Assert(view.RowCount == 0);
		Test.Assert(view.ShowsState);
		Test.Assert(!view.List.Displayed);
		Test.Assert(view.StateTitle == "Nothing matches crate4");
		let verb = bed.Part<Sedulous.GUI.Button>("assets-state-verb");
		Test.Assert(verb.Displayed && (verb.Text == "Clear the search"));
		Test.Assert(verb.HandleActivate());
		Test.Assert(view.SearchText.IsEmpty && field.Text.IsEmpty);
		Test.Assert(!view.ShowsState);
		Test.Assert(view.List.Displayed);
		Test.Assert(bed.RowsAre("/Models /Sounds Crate"));

		// The clear button clears it, as does entering a group.
		view.SetSearch("Crate");
		Test.Assert(clear.HandleActivate());
		Test.Assert(view.SearchText.IsEmpty && field.Text.IsEmpty && !clear.Visible);
		Test.Assert(bed.RowsAre("/Models /Sounds Crate"));
		view.SetSearch("Barrel");
		view.Navigate(bed.Models);
		Test.Assert(view.SearchText.IsEmpty && field.Text.IsEmpty);
		Test.Assert(bed.RowsAre("/Town"));
	}

	/// The type filter keeps one type, by its full name or its short one; groups go while it does,
	/// its button checked and saying which; with none here it says so and shows every type again.
	/// Its menu lists the types the project has by what each is called, the kept one checked. An
	/// empty group says so.
	[Test]
	public static void TheTypeFilterKeepsOneTypeFromTheTypesTheProjectHasAnEmptyGroupSaysSo()
	{
		let bed = scope Bed("scratch_assets_view_types");
		let view = bed.View;
		let types = bed.Part<Sedulous.GUI.Button>("assets-types");
		Test.Assert(!types.HasClass("checked") && (types.Tooltip == "Filter by type"));
		view.OpenRow(bed.RowOf("Models"));
		view.OpenRow(bed.RowOf("Town"));
		view.SetTypeFilter(bed.SoundName);
		Test.Assert(bed.RowsAre("Bell"));
		Test.Assert(types.HasClass("checked"));
		Test.Assert(types.Tooltip == "Showing Browser Sound only");
		view.Navigate(bed.Top);
		Test.Assert(view.RowCount == 0, "no sounds, and no groups while filtering");
		Test.Assert(view.StateTitle == "No Browser Sound here");
		let verb = bed.Part<Sedulous.GUI.Button>("assets-state-verb");
		Test.Assert(verb.Displayed && (verb.Text == "Show every type"));
		Test.Assert(verb.HandleActivate());
		Test.Assert(view.TypeFilter.IsEmpty && !types.HasClass("checked"));
		Test.Assert(bed.RowsAre("/Models /Sounds Crate"));
		view.SetTypeFilter("BrowserMesh"); // its short name
		Test.Assert(bed.RowsAre("Crate"));
		view.SetTypeFilter("");
		Test.Assert(bed.RowsAre("/Models /Sounds Crate"));

		view.Navigate(bed.Sounds);
		Test.Assert(view.StateTitle == "Nothing in Content/Sounds yet");
		let text = bed.Part<Sedulous.GUI.Label>("assets-state-text");
		Test.Assert(text.Displayed && (text.Text == "Create an asset or import files into it."));
		Test.Assert(!verb.Displayed, "nothing to clear");
		view.Navigate(bed.Top);

		// The menu: every type, then each the project has, by what it is called.
		Test.Assert(types.HandleActivate());
		var menu = view.TypeMenu;
		Test.Assert(menu != null);
		Test.Assert(MenuRows.Is(menu, "Every type|-|Browser Sound|BrowserMesh"));
		Test.Assert(MenuRows.ItemNamed(menu, "Every type").Checked);
		Test.Assert(!MenuRows.ItemNamed(menu, "BrowserMesh").Checked);
		Test.Assert(MenuRows.ItemNamed(menu, "BrowserMesh").HandleActivate());
		Test.Assert(view.TypeFilter == bed.MeshName);
		Test.Assert(bed.RowsAre("Crate"));
		Test.Assert(types.HandleActivate());
		menu = view.TypeMenu;
		Test.Assert(menu != null);
		Test.Assert(MenuRows.ItemNamed(menu, "BrowserMesh").Checked);
		Test.Assert(!MenuRows.ItemNamed(menu, "Every type").Checked);
		Test.Assert(MenuRows.ItemNamed(menu, "Every type").HandleActivate());
		Test.Assert(view.TypeFilter.IsEmpty);
		Test.Assert(bed.RowsAre("/Models /Sounds Crate"));
	}

	/// Tiles until the project says otherwise; the toggles switch and show which, the choice kept
	/// with the project, a view opened later taking it. A cell shows its type's glyph in its
	/// category's tint (else the generic asset's), a group its folder and what it holds, a tile its
	/// name and what it is as its tooltip, and a favourite its star.
	[Test]
	public static void TilesOrAListKeptWithTheProjectAFavouriteStarred()
	{
		let bed = scope Bed("scratch_assets_view_tiles");
		let view = bed.View;
		let tiles = bed.Part<Sedulous.GUI.Button>("assets-tiles");
		let list = bed.Part<Sedulous.GUI.Button>("assets-list");
		Test.Assert(view.ShowsTiles, "tiles until the project says otherwise");
		Test.Assert(view.List.LayoutMode == .Grid);
		Test.Assert(tiles.HasClass("checked") && !list.HasClass("checked"));
		var crate = bed.Cell(bed.RowOf("Crate"));
		Test.Assert(crate.IsTile);
		Test.Assert(crate.Glyph == "Editor/Icons/Types/BrowserMesh.svg");
		Test.Assert(crate.GlyphClass == "cat-rendering", "its category's tint");
		Test.Assert(crate.Tooltip == "Crate (BrowserMesh)");
		let models = bed.Cell(bed.RowOf("Models"));
		Test.Assert(models.HasClass("group") && (models.Glyph == "Editor/Icons/folder.svg"));
		Test.Assert(models.Kind == "Group, 1 item");
		Test.Assert(bed.Cell(bed.RowOf("Sounds")).Kind == "Group, 0 items");

		Test.Assert(list.HandleActivate());
		Test.Assert(!view.ShowsTiles);
		Test.Assert(view.List.LayoutMode == .List);
		Test.Assert(view.List.HasClass("asset-list") && !view.List.HasClass("asset-tiles"));
		Test.Assert(!tiles.HasClass("checked") && list.HasClass("checked"));
		let saved = bed.Store.Find<EditorAssetBrowserSettings>();
		Test.Assert(saved != null);
		Test.Assert(!saved.GridMode);
		Test.Assert(bed.Saves == 1);
		Test.Assert(list.HandleActivate());
		Test.Assert(bed.Saves == 1, "already a list: nothing to keep");

		bed.Context.ToggleFavorite(bed.Crate.Id);
		view.Rebuild();
		crate = bed.Cell(bed.RowOf("Crate"));
		Test.Assert(crate != null);
		Test.Assert(!crate.IsTile);
		Test.Assert(crate.ShowsStar);
		Test.Assert(crate.Tooltip.IsEmpty, "a row says what it is itself");
		Test.Assert(crate.Kind == "BrowserMesh");
		Test.Assert(!bed.Cell(bed.RowOf("Models")).ShowsStar);
		view.Navigate(bed.Town);
		let bell = bed.Cell(bed.RowOf("Bell"));
		Test.Assert(bell.Glyph == "Editor/Icons/Types/Asset.svg", "the generic asset's");
		Test.Assert(bell.GlyphClass.IsEmpty, "no category: no tint");
		Test.Assert(!bell.ShowsStar);

		// A view opened later takes the project's choice, and keeps a change back.
		let again = bed.MakeView();
		defer delete again;
		Test.Assert(!again.ShowsTiles);
		Test.Assert(again.List.LayoutMode == .List);
		again.SetTiles(true);
		Test.Assert(saved.GridMode);
		Test.Assert(bed.Saves == 2);
	}

	/// A cell's cook badge: an asset a builder cooks, never cooked, is stale, on a tile and a row;
	/// one no builder cooks has none. A tile marks only what needs a look: a cooked one is a row's
	/// word alone, a failed one marked on both.
	[Test]
	public static void ACellsCookBadgeATileMarkingOnlyStaleOrFailed()
	{
		let bed = scope Bed("scratch_assets_view_badges", true, true);
		let view = bed.View;
		let crate = bed.Cell(bed.RowOf("Crate"));
		Test.Assert(crate.IsTile);
		Test.Assert((crate.Badge == "Stale") && (crate.BadgeClass == "warning") && crate.ShowsBadge);
		view.Navigate(bed.Town);
		let bell = bed.Cell(bed.RowOf("Bell"));
		Test.Assert(bell.Badge.IsEmpty && !bell.ShowsBadge, "no builder: no badge");
		view.SetTiles(false);
		let barrel = bed.Cell(bed.RowOf("Barrel"));
		Test.Assert(!barrel.IsTile && barrel.ShowsBadge && (barrel.Badge == "Stale"));

		let tile = new AssetCell(true);
		defer tile.ReleaseRef();
		let row = new AssetCell(false);
		defer row.ReleaseRef();
		var shown = AssetCell.Shown();
		shown.Glyph = "Editor/Icons/file.svg";
		shown.Name = "Crate";
		shown.Kind = "Mesh";
		shown.Badge = "Cooked";
		shown.BadgeClass = "success";
		tile.Show(shown);
		row.Show(shown);
		Test.Assert((tile.Badge == "Cooked") && !tile.ShowsBadge, "a tile leaves a cooked one unmarked");
		Test.Assert(row.ShowsBadge && (row.BadgeClass == "success"));
		shown.Badge = "Failed";
		shown.BadgeClass = "danger";
		tile.Show(shown);
		Test.Assert(tile.ShowsBadge && (tile.BadgeClass == "danger"));
		shown.Badge = "";
		shown.BadgeClass = "";
		row.Show(shown);
		Test.Assert(!row.ShowsBadge && row.BadgeClass.IsEmpty);
	}

	/// The cells are drawn again when a cook lands (the badges it moved), though the database's
	/// shape did not move: a star given since shows then.
	[Test]
	public static void ItDrawsItsCellsAgainWhenACookLands()
	{
		let bed = scope Bed("scratch_assets_view_cook", true);
		let view = bed.View;
		let crate = bed.RowOf("Crate");
		Test.Assert(!bed.Cell(crate).ShowsStar);
		bed.Context.ToggleFavorite(bed.Crate.Id); // nothing tells the view
		view.Refresh();
		Test.Assert(!bed.Cell(crate).ShowsStar, "nothing moved: nothing drawn again");

		let shape = bed.Project.SourceDb.Revision;
		bed.Cook.RequestCook(false);
		let watch = scope Stopwatch(true);
		while (((bed.Cook.Revision == 0) || !bed.Cook.IsIdle) && (watch.ElapsedMilliseconds < 60000))
		{
			bed.Cook.Update();
			Thread.Sleep(1);
		}
		Test.Assert(bed.Cook.Revision == 1);
		Test.Assert(bed.Project.SourceDb.Revision == shape, "the cook left the sources' shape");
		view.Refresh();
		Test.Assert(bed.Cell(crate).ShowsStar, "a cook landed: drawn again");
	}

	/// It builds again when the database's shape moves, however it moved (the tree too); Reveal
	/// shows an asset where it lives, the search and the type filter cleared; another project (or
	/// none) starts at its top.
	[Test]
	public static void ItBuildsAgainWhenTheDatabasesShapeMovesRevealShowsAnAssetWhereItLives()
	{
		let bed = scope Bed("scratch_assets_view_rebuild");
		let view = bed.View;
		Test.Assert(bed.Top.CreateInstance("Anvil", bed.MeshName) != null); // as an agent's write would
		Test.Assert(bed.Top.CreateGroup("Props") != null);
		view.Refresh();
		Test.Assert(bed.RowsAre("/Models /Props /Sounds Anvil Crate"));
		Test.Assert(bed.TreeItem("Props") >= 0);

		view.SetSearch("Crate");
		view.SetTypeFilter(bed.MeshName);
		Test.Assert(view.Reveal(bed.Barrel.Id));
		Test.Assert(view.CurrentGroup == bed.Town);
		Test.Assert(view.SearchText.IsEmpty && view.TypeFilter.IsEmpty);
		Test.Assert(!bed.Part<Sedulous.GUI.Button>("assets-types").HasClass("checked"));
		Test.Assert(view.List.SelectedItem >= 0);
		Test.Assert(view.RowName(view.List.SelectedItem) == "Barrel");
		let chosen = scope List<Instance>();
		view.SelectedAssets(chosen);
		Test.Assert((chosen.Count == 1) && (chosen[0] == bed.Barrel));
		Test.Assert(view.Tree.SelectedItem == bed.TreeItem("Town"));
		Test.Assert(!view.Reveal(Guid(9, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0)));
		Test.Assert(view.CurrentGroup == bed.Town, "an unknown guid moves nothing");

		// No project: it says so; the project again: at its top, the search gone.
		view.SetSearch("Bell");
		bed.Context.SetProject(null);
		view.Refresh();
		Test.Assert(view.RowCount == 0);
		Test.Assert(view.CurrentGroup == null);
		Test.Assert(view.StateTitle == "No project is open");
		Test.Assert(view.Tree.GetItemCount() == 0);
		bed.Context.SetProject(bed.Project);
		view.Refresh();
		Test.Assert(view.CurrentGroup == bed.Top);
		Test.Assert(view.SearchText.IsEmpty);
		Test.Assert(bed.RowsAre("/Models /Props /Sounds Anvil Crate"));
	}

	/// A drag of the selection carries its assets, in their order, labelled by how many; a group's
	/// row carries none.
	[Test]
	public static void ADragOfTheSelectionCarriesItsAssets()
	{
		let bed = scope Bed("scratch_assets_view_drag");
		let view = bed.View;
		view.SetTiles(false);
		view.OpenRow(bed.RowOf("Models"));
		view.OpenRow(bed.RowOf("Town"));
		view.List.SelectAll();
		let d = bed.Root.EventDispatcher;
		let carried = scope List<AssetDrag>();
		defer { ClearAndDeleteItems!(carried); }
		{
			let press = bed.Middle(view.List, 0);
			d.InjectMouseDown(press, .Left);
			d.InjectMouseMove(.(press.X + 12.0f, press.Y + 30.0f));
			d.InjectMouseMove(.(press.X + 40.0f, press.Y + 80.0f));
			Test.Assert(d.IsDragging);
			Test.Assert(AssetDrag.ReadAll(d.DragPayload, carried));
			Test.Assert(carried.Count == 2);
			Test.Assert((carried[0].Name == "Barrel") && (carried[0].Id == bed.Barrel.Id) && (carried[0].TypeName == bed.MeshName));
			Test.Assert((carried[1].Name == "Bell") && (carried[1].Id == bed.Bell.Id));
			Test.Assert(d.DragPayload.Label == "2 assets");
			d.InjectMouseUp(.(press.X + 40.0f, press.Y + 80.0f), .Left);
		}

		// At the top, all selected: the groups' rows carry nothing, the asset itself.
		view.Navigate(bed.Top);
		view.List.SelectAll();
		// A while after the first press, so this one at the same place is no double click (which
		// would enter the group under it).
		d.Tick(1.0f);
		{
			let press = bed.Middle(view.List, (int32)bed.RowOf("Models"));
			d.InjectMouseDown(press, .Left);
			d.InjectMouseMove(.(press.X + 12.0f, press.Y + 30.0f));
			d.InjectMouseMove(.(press.X + 40.0f, press.Y + 80.0f));
			Test.Assert(d.IsDragging);
			Test.Assert(AssetDrag.ReadAll(d.DragPayload, carried));
			Test.Assert((carried.Count == 1) && (carried[0].Id == bed.Crate.Id));
			Test.Assert(d.DragPayload.Label == "Crate");
			d.InjectMouseUp(.(press.X + 40.0f, press.Y + 80.0f), .Left);
		}
	}

	/// The filter finds a name by any part of it, or a guid whole or by its first digits.
	[Test]
	public static void TheFilterFindsANameOrAGuidWholeOrByItsStart()
	{
		let bed = scope Bed("scratch_assets_view_filter");
		let crate = bed.Crate;
		let guid = crate.Id.ToString(.. scope .());

		Test.Assert(AssetFilter.Matches(crate, ""));
		Test.Assert(AssetFilter.Matches(crate, "rat"), "a part of Crate, any case");
		Test.Assert(AssetFilter.Matches(crate, "CRATE"));
		Test.Assert(!AssetFilter.Matches(crate, "barrel"));

		// The guid whole, upper case, braced, without dashes, or its first digits.
		Test.Assert(AssetFilter.Matches(crate, guid));
		Test.Assert(AssetFilter.Matches(crate, scope String(guid)..ToUpper()));
		Test.Assert(AssetFilter.Matches(crate, scope $"{{{guid}}}"));
		let bare = scope String(guid)..Replace("-", "");
		Test.Assert(AssetFilter.Matches(crate, bare));
		Test.Assert(AssetFilter.Matches(crate, StringView(guid, 0, 6)));
		// Too short to read as a guid, or a different one.
		Test.Assert(!AssetFilter.Matches(crate, "zz"));
		let other = scope String(StringView(guid, 0, 35));
		other.Append((guid[35] == '0') ? "1" : "0");
		Test.Assert(!AssetFilter.Matches(crate, other));

		// AsGuid reads a whole guid only.
		Test.Assert(AssetFilter.AsGuid(bare, let parsed) && (parsed == crate.Id));
		Test.Assert(!AssetFilter.AsGuid(StringView(guid, 0, 6), ?));
		Test.Assert(!AssetFilter.AsGuid("Crate", ?));
	}

	/// Under the editor's sheet the toolbar keeps its height however full the body (a short panel:
	/// the body wants more room than it has, and a toolbar that shrank was squeezed to its search
	/// box); the type menu opens below its button, not at the window's corner (its point was the
	/// button's own where the menu takes one in the window's space).
	[Test]
	public static void UnderTheEditorsSheetTheToolbarKeepsItsHeightTheTypeMenuOpensBelowItsButton()
	{
		let bed = scope Bed("scratch_assets_view_sheet", false, false, true);
		let view = bed.View;
		bed.StyleAsTheEditor();
		// A short panel: the panel fills its window, so the window is made short, and the
		// toolbar must keep its height over a body that wants more room than there is.
		bed.Root.Size = .(900.0f, 120.0f);
		view.Content.EditLayoutStyle(scope (s) => { s.MinHeight = LayoutLength.Px(0.0f); });
		bed.Layout();
		Test.Assert(view.Content.Size.Y < 130.0f, scope $"the panel is {view.Content.Size.Y} high: not squeezed");
		let bar = view.Crumbs.Parent;
		Test.Assert(bar != null);
		// The default density's --bar, its search inside it with room above and below.
		Test.Assert(Math.Abs(bar.Size.Y - 34.0f) < 0.5f, scope $"the toolbar is {bar.Size.Y} high");

		let types = bed.Part<Sedulous.GUI.Button>("assets-types");
		Test.Assert(types != null);
		Test.Assert(types.HandleActivate());
		bed.Layout();
		let menu = view.TypeMenu;
		Test.Assert(menu != null);
		let button = types.ScreenBounds;
		let at = menu.ScreenBounds;
		Test.Assert(at.Y >= button.Y + button.Height - 1.0f, "below the button, not at the window's corner");
		Test.Assert(at.X >= button.X - at.Width);
	}
}
