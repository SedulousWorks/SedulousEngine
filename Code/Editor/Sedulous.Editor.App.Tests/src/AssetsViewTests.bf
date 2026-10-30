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
/// moves; Reveal; a drag of the selection carrying its assets; assets dropped on a group's row or a
/// group in the tree moving into it, one already there or taken there refused, saying why; and,
/// under the editor's sheet, the toolbar keeping its height, the type menu opening below its
/// button, and a list row's kind on its name's baseline, ending where every other row's does; a
/// tile showing its type's glyph until its thumbnail is ready, then the thumbnail. Then
/// what Sedulous adds
/// so each behaviour has a test: the tree's click and Enter navigating, the breadcrumb's tooltip, a
/// guid typed whole, braced or bare selecting its asset, the clear button and the state's verb, the
/// type filter's menu and a type's display name, the toggles' checks, a type's glyph and tint, the
/// cook badges (a tile marks only stale or failed) and the cells drawn again when a cook lands,
/// another project's view starting at its top, and the filter's matching itself (AssetFilter). And
/// the verbs, AssetOperations': an asset's menu, a group's and the shown group's with New, each
/// item reaching what it names, opened by a right click on the list or the tree; Delete asking,
/// naming what goes, on the list or the tree, Cancel keeping it; and a row's or a tree group's
/// name edited in place, by the models and by F2 or the menu's Rename, a refused name saying why
/// and keeping the edit open, the rows of a database moved since never edited; and a drag of the
/// assets dropped by the pointer on a group's row, the tree and a breadcrumb segment, saying
/// "Move into ..." or why not.
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
		/// The verbs; borrowed by the view.
		public AssetOperations Ops;
		/// What New ran, by its creator's label, and the groups it ran into.
		public List<String> Created = new .() ~ DeleteContainerAndItems!(_);
		public List<Group> CreatedIn = new .() ~ delete _;
		/// The groups Import... asked files for.
		public List<Group> ImportInto = new .() ~ delete _;
		/// The notices said.
		public List<String> Said = new .() ~ DeleteContainerAndItems!(_);
		/// The GUI's clipboard, for the copies.
		public LauncherClipboard Clipboard = new .() ~ delete _;
		/// How often the store was asked to be saved.
		public int Saves = 0;
		/// The toolbar and the group tree are the sheet's to size.
		public bool ForSheet;
		/// The editor's sheet, once StyleAsTheEditor has styled the tree.
		public EditorSheet Sheet = null;
		/// The asset whose thumbnail is ready (none: empty), and what it shows (ours: one reference).
		public Guid Pictured = .Empty;
		public Sedulous.GUI.Drawable Picture = null ~ _?.ReleaseRef();

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
			Context.OnNotice = new [=bed] (kind, message) => { bed.Said.Add(new String(message)); };
			// New's creators: one with no category, one in a submenu.
			Context.Creators.Register(new AssetCreator("Material", "", typeof(BrowserMesh), new (at) => null));
			Context.Creators.Register(new AssetCreator("Cube", "Primitives", typeof(BrowserMesh), new (at) => null));
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
			let operations = new AssetOperationsServices();
			operations.Context = Context; // no later: at once
			operations.Cook = Cook;
			Ops = new AssetOperations(operations);
			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(900.0f, 600.0f);
			Root.EventDispatcher.Clipboard = Clipboard;
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
			delete Ops; // the view's, before the cook it reaches
			Root.EventDispatcher.Clipboard = null;
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
			services.Operations = Ops;
			services.Picture = new [=bed] (id) => (id == bed.Pictured) ? bed.Picture : null;
			services.Create = new [=bed] (creator, group) =>
				{
					bed.Created.Add(new String(creator.Label));
					bed.CreatedIn.Add(group);
				};
			services.Import = new [=bed] (group) => { bed.ImportInto.Add(group); };
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
		/// then laid out; its faces loaded too (`withFonts`) for a test that measures text.
		public void StyleAsTheEditor(bool withFonts = false)
		{
			Sheet = new .(withFonts);
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

		public StringView LastSaid => Said.IsEmpty ? "" : Said.Back;

		/// The open menu after `row`'s (-1: the shown group's) was asked for.
		public Sedulous.GUI.Menu MenuFor(int32 row)
		{
			View.ShowMenuFor(row);
			Layout();
			return View.OpenMenu;
		}

		/// Activates the item `text` of the menu `row` shows (asserted there).
		public void Choose(int32 row, StringView text)
		{
			let menu = MenuFor(row);
			Test.Assert(menu != null);
			let item = MenuRows.ItemNamed(menu, text);
			Test.Assert(item != null, scope $"{text} in the menu");
			Test.Assert(item.HandleActivate());
		}

		public void RightClick(Float2 at)
		{
			// A while after any press before, so this one is no double click.
			Root.EventDispatcher.Tick(1.0f);
			Root.EventDispatcher.InjectMouseMove(at);
			Root.EventDispatcher.InjectMouseDown(at, .Right);
			Root.EventDispatcher.InjectMouseUp(at, .Right);
		}

		public bool Press(KeyCode key) => Root.EventDispatcher.InjectKeyDown((uint32)key);

		/// The middle of `node`, where the pointer reaches it (asserted).
		public Float2 MiddleOf(Node node)
		{
			Layout();
			let bounds = node.ScreenBounds;
			Test.Assert((bounds.Width > 0.0f) && (bounds.Height > 0.0f), "laid out");
			let at = Float2(bounds.X + bounds.Width * 0.5f, bounds.Y + bounds.Height * 0.5f);
			var hit = Root.OverFind(at);
			while ((hit != null) && (hit != node))
				hit = hit.Parent;
			Test.Assert(hit == node, "the pointer reaches it");
			return at;
		}

		/// Drags the list's row `row` to `to` and lets go there, a while after any press before, so
		/// this one is no double click (the GUI's clock moves only by Tick). What the drag said over
		/// `to` is returned, its reason set into `outReason`.
		public DropEffect DragRowTo(int32 row, Float2 to, String outReason)
		{
			let d = Root.EventDispatcher;
			d.Tick(1.0f);
			let from = Middle(View.List, row);
			d.InjectMouseMove(from);
			d.InjectMouseDown(from, .Left);
			d.InjectMouseMove(.(from.X + 12.0f, from.Y));
			d.InjectMouseMove(to);
			d.InjectMouseMove(.(to.X + 1.0f, to.Y));
			Test.Assert(d.IsDragging);
			let effect = d.DropEffect;
			outReason.Set(d.DropReason);
			d.InjectMouseUp(.(to.X + 1.0f, to.Y), .Left);
			return effect;
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

	/// The search looks in the group shown and every group under it, by name in any case, a match
	/// saying where it is, by its type's display name where it has one, and is kept as the group
	/// changes; a guid's start finds its asset, a whole guid (braced or bare) selects it; nothing
	/// matching says so (naming the group when it is not the top), and its verb or the clear button
	/// clears the search; Reveal ends it.
	[Test]
	public static void ASearchLooksInTheGroupShownAndUnderItKeptAsTheGroupChangesNothingMatchingSaysSoAndClears()
	{
		let bed = scope Bed("scratch_assets_view_search");
		let view = bed.View;
		let field = bed.Part<TextField>("assets-search");
		let clear = bed.Part<Sedulous.GUI.Button>("assets-clear-search");
		Test.Assert((field != null) && (clear != null));
		Test.Assert(!clear.Visible, "nothing to clear");
		view.SetTiles(false);
		// Searched from a group: in it and under it.
		view.Navigate(bed.Models);
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

		// The clear button clears it.
		view.SetSearch("Crate");
		Test.Assert(clear.HandleActivate());
		Test.Assert(view.SearchText.IsEmpty && field.Text.IsEmpty && !clear.Visible);
		Test.Assert(bed.RowsAre("/Models /Sounds Crate"));

		// Another group chosen keeps the search, looking there and under it.
		view.SetSearch("e");
		Test.Assert(bed.RowsAre("Crate Barrel Bell"));
		view.Navigate(bed.Models);
		Test.Assert(view.SearchText == "e");
		Test.Assert(bed.RowsAre("Barrel Bell"));
		view.SetSearch("crate");
		Test.Assert(view.StateTitle == "Nothing matches crate in Content/Models");
		view.Navigate(bed.Top);
		Test.Assert(bed.RowsAre("Crate"));
		// Reveal shows an asset where it lives, so it ends the search.
		Test.Assert(view.Reveal(bed.Barrel.Id));
		Test.Assert(view.SearchText.IsEmpty && field.Text.IsEmpty);
		Test.Assert(view.CurrentGroup == bed.Town);
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
		Test.Assert(models.Kind.IsEmpty, "its folder says it is a group: no words for it");
		Test.Assert(models.Tooltip == "Models", "its tile named without an empty kind");
		Test.Assert(bed.Cell(bed.RowOf("Sounds")).Kind.IsEmpty);

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

	/// Files dropped on the editor go into the group the panel shows, else the top (no panel, or
	/// no group shown).
	[Test]
	public static void FilesDroppedGoIntoTheGroupThePanelShowsElseTheTop()
	{
		let bed = scope Bed("scratch_assets_view_drop");
		let view = bed.View;
		let sources = bed.Project.SourceDb;
		Test.Assert(ImportWindow.DropGroup(view, sources) == bed.Top);
		view.Navigate(bed.Town);
		Test.Assert(ImportWindow.DropGroup(view, sources) == bed.Town);
		Test.Assert(ImportWindow.DropGroup(null, sources) == bed.Top, "no panel: the top");
		bed.Context.SetProject(null);
		view.Refresh();
		Test.Assert(view.CurrentGroup == null);
		Test.Assert(ImportWindow.DropGroup(view, sources) == bed.Top, "none shown: the top");
		bed.Context.SetProject(bed.Project);
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

	/// Under the editor's sheet a list row's kind is on its name's baseline (a smaller text
	/// centred on its own sat higher) and ends where every other row's does: the name takes the
	/// room, the kind hugs its text at the end, and the badge and the star keep their columns on
	/// a row without them (a kind used to start wherever its name ended, and to run on into the
	/// star's room on a row with none). Two rows of names and kinds of different lengths, one
	/// starred and badged (a mesh a builder cooks, never cooked) and one with neither; the
	/// editor's faces loaded, as text with no font measures nothing.
	[Test]
	public static void UnderTheEditorsSheetAListRowsKindIsOnItsNamesBaselineAndEndsWhereEveryOtherRowsDoes()
	{
		let bed = scope Bed("scratch_assets_view_row_kind", true, true, true);
		let view = bed.View;
		// A fine device grid: every edge rounds to its pixel on its own, and a whole pixel would
		// hide the third of one between the baselines the row's centring left.
		bed.Root.DisplayScale = 16.0f;
		view.SetTiles(false);
		bed.Context.ToggleFavorite(bed.Barrel.Id); // one row starred, one not
		bed.Ops.ToggleAlwaysExport(bed.Barrel.Id); // and always exported, one not
		view.OpenRow(bed.RowOf("Models"));
		view.OpenRow(bed.RowOf("Town"));
		bed.StyleAsTheEditor(true);
		bed.Sheet.Apply(bed.Root); // the cells the first pass realised
		bed.Layout();
		let barrel = bed.Cell(bed.RowOf("Barrel"));
		let bell = bed.Cell(bed.RowOf("Bell"));
		Test.Assert((barrel != null) && (bell != null));
		Test.Assert(barrel.ShowsStar && barrel.ShowsBadge);
		Test.Assert(!bell.ShowsStar && !bell.ShowsBadge);
		Test.Assert(barrel.Kind != bell.Kind, "kinds of different widths");
		Test.Assert(barrel.NameLabel.GetTextLayout().HasFont && barrel.KindLabel.GetTextLayout().HasFont, "the sheet's faces");
		Test.Assert(barrel.NameLabel.Size.Y > barrel.KindLabel.Size.Y, "the kind smaller than its name");

		// In the root's own units, which the display scale maps to device pixels.
		float KindRight(AssetCell cell)
		{
			let kind = cell.KindLabel;
			return kind.ConvertToRootSpace(.(kind.Size.X, 0.0f)).X;
		}
		// Every row's Always Export and star in the same columns, each an icon's width (a class of
		// another dialog's once stretched the row's).
		for (int i < Math.Min(barrel.ChildCount, bell.ChildCount))
		{
			let a = barrel.GetChildAt(i).ScreenBounds;
			let b = bell.GetChildAt(i).ScreenBounds;
			Test.Assert(Math.Abs(a.X - b.X) < 0.1f);
			Test.Assert(Math.Abs(a.Width - b.Width) < 0.1f);
		}
		Test.Assert(Math.Abs(barrel.GetChildAt(barrel.ChildCount - 2).Size.X - 14.0f) < 0.1f); // Always Export
		Test.Assert(barrel.ShowsAlwaysExport);
		Test.Assert(!bell.ShowsAlwaysExport);
		// Lit, a favourite's star is gold (its token defined: an undefined one left it white), and
		// greyed when not.
		Sedulous.GUI.Image StarOf(AssetCell cell) => cell.GetChildAt(cell.ChildCount - 1) as Sedulous.GUI.Image;
		Test.Assert(StarOf(barrel) != null);
		let gold = StarOf(barrel).ImageColor;
		Test.Assert(gold.R > gold.B + 0.3f, "yellow: red and green well over blue");
		Test.Assert(gold.G > gold.B + 0.2f);
		Test.Assert(StarOf(bell).ImageColor.R < gold.R);
		let barrelRight = KindRight(barrel);
		let bellRight = KindRight(bell);
		Test.Assert(Math.Abs(barrelRight - bellRight) < 0.1f, scope $"the kinds end at {barrelRight} and {bellRight}: the badge's, the export's and the star's columns kept on the row without them");
		// Each kind as wide as its text, which so ends where the kind does, not where its name did.
		void HugsItsText(AssetCell cell)
		{
			let kind = cell.KindLabel;
			let room = kind.Size.X - kind.Chrome.TotalHorizontal;
			let text = kind.GetTextLayout().Width;
			Test.Assert(Math.Abs(room - text) < 0.1f, scope $"the kind '{cell.Kind}' has {room} for {text} of text: its text ends at the row's end");
		}
		HugsItsText(barrel);
		HugsItsText(bell);

		// On one baseline: the name's and the kind's text baselines at the same height.
		float BaselineOf(Sedulous.GUI.Label label) => label.ConvertToRootSpace(.(0.0f, label.Baseline)).Y;
		let nameLine = BaselineOf(barrel.NameLabel);
		let kindLine = BaselineOf(barrel.KindLabel);
		Test.Assert(Math.Abs(nameLine - kindLine) < 0.1f, scope $"the name's baseline at {nameLine}, the kind's at {kindLine}");
	}

	/// An asset's menu: what acts on it, then what acts on the selection holding it (else on it
	/// alone), each item reaching what it names (the copies on the clipboard, the guid hyphened; the
	/// star and the export flag shown after); a group's row's; the shown group's, with New from the
	/// creators by category into it, New Group (made, shown, in the tree, a folder) and Import...
	/// (files asked for into it), Content's cooking all and neither renamed, flagged nor deleted. A right click on a row, on the list's
	/// empty room or on the tree opens them.
	[Test]
	public static void AnAssetsMenuAGroupsAndTheShownGroupsWithNewEachItemReachingWhatItNames()
	{
		let bed = scope Bed("scratch_assets_view_menus");
		let view = bed.View;
		let list = view.List;
		let crate = bed.RowOf("Crate");
		list.SelectedItem = crate;
		var menu = bed.MenuFor(crate);
		Test.Assert(menu != null);
		Test.Assert(MenuRows.Is(menu, "Open|-|Rename|Duplicate|-|Copy GUID|Copy Path|Pin as Favourite|Always Export|-|Cook|Rebuild|-|Delete..."));
		Test.Assert(MenuRows.ItemNamed(menu, "Rename").Shortcut == "F2");
		Test.Assert(MenuRows.ItemNamed(menu, "Delete...").Shortcut == "Del");
		let always = MenuRows.ItemNamed(menu, "Always Export");
		Test.Assert(always.Checkable && !always.Checked);
		Test.Assert(MenuRows.ItemNamed(menu, "Open").HandleActivate());
		Test.Assert((bed.Opened.Count == 1) && (bed.Opened[0] == bed.Crate.Id));
		bed.Choose(crate, "Copy GUID");
		Test.Assert(bed.Clipboard.Held == bed.Crate.Id.ToString(.. scope .(), 'D'));
		Test.Assert(bed.LastSaid == "Copied GUID");
		bed.Choose(crate, "Copy Path");
		Test.Assert(bed.Clipboard.Held == "Crate");
		Test.Assert(bed.LastSaid == "Copied path");
		bed.Choose(crate, "Pin as Favourite");
		Test.Assert(bed.Context.IsFavorite(bed.Crate.Id));
		Test.Assert(bed.Cell(crate).ShowsStar, "its star at once");
		bed.Choose(crate, "Always Export");
		Test.Assert(bed.Project.ExportRoots.HasInstance(bed.Crate.Id));
		Test.Assert(bed.LastSaid == "Crate is always exported.");
		menu = bed.MenuFor(crate);
		Test.Assert(MenuRows.ItemNamed(menu, "Unpin Favourite") != null);
		Test.Assert(MenuRows.ItemNamed(menu, "Always Export").Checked);
		menu.Close();
		bed.Choose(crate, "Duplicate");
		Test.Assert(bed.LastSaid == "The duplicate failed (see the Console).", "the bed's assets are never written: nothing to copy");
		bed.Choose(crate, "Delete...");
		var confirm = view.OpenConfirm;
		Test.Assert((confirm != null) && confirm.Message.StartsWith("Delete Crate?"));
		Test.Assert(confirm.ButtonAt(0).HandleActivate()); // Cancel
		Test.Assert(bed.Project.SourceDb.GetInstance(bed.Crate.Id) != null);

		// The selection holding the row, else the row alone.
		view.Navigate(bed.Town);
		list.SelectAll();
		menu = bed.MenuFor(bed.RowOf("Barrel"));
		Test.Assert(MenuRows.Is(menu, "Open|-|Rename|Duplicate|-|Copy GUID|Copy Path|Pin as Favourite|Always Export|-|Cook 2 Assets|Rebuild 2 Assets|-|Delete 2 Assets..."));
		Test.Assert(MenuRows.ItemNamed(menu, "Delete 2 Assets...").HandleActivate());
		confirm = view.OpenConfirm;
		Test.Assert(confirm != null);
		Test.Assert(confirm.Title == "Delete 2 Assets");
		Test.Assert(confirm.Message == "Delete Barrel and Bell? Their source files and cooked products go, and their open pages close.");
		Test.Assert(confirm.ButtonAt(0).HandleActivate());
		list.SelectedItem = bed.RowOf("Bell");
		menu = bed.MenuFor(bed.RowOf("Barrel"));
		Test.Assert(MenuRows.ItemNamed(menu, "Cook") != null, "the selection does not hold it: it alone");
		Test.Assert(MenuRows.ItemNamed(menu, "Delete...") != null);
		menu.Close();

		// A group's row.
		view.Navigate(bed.Top);
		let models = bed.RowOf("Models");
		menu = bed.MenuFor(models);
		Test.Assert(MenuRows.Is(menu, "Open|-|Rename|Always Export Its Contents|-|Cook Group|Rebuild Group|-|Delete Group..."));
		Test.Assert(MenuRows.ItemNamed(menu, "Rename").Shortcut == "F2");
		Test.Assert(!MenuRows.ItemNamed(menu, "Always Export Its Contents").Checked);
		menu.Close();
		bed.Choose(models, "Always Export Its Contents");
		Test.Assert(bed.Project.ExportRoots.HasGroup("Models"));
		Test.Assert(bed.LastSaid == "Everything in Models is always exported.");
		menu = bed.MenuFor(models);
		Test.Assert(MenuRows.ItemNamed(menu, "Always Export Its Contents").Checked);
		menu.Close();
		bed.Choose(models, "Delete Group...");
		confirm = view.OpenConfirm;
		Test.Assert((confirm != null) && (confirm.Title == "Delete Group"));
		Test.Assert(confirm.ButtonAt(0).HandleActivate());
		bed.Choose(models, "Open");
		Test.Assert(view.CurrentGroup == bed.Models);

		// The group shown: Content's makes new things and cooks all.
		view.Navigate(bed.Top);
		menu = bed.MenuFor(-1);
		Test.Assert(MenuRows.Is(menu, "New>|New Group|Import...|-|Cook All|Rebuild All"), "Content: neither renamed, flagged nor deleted");
		let create = MenuRows.SubMenuNamed(menu, "New");
		Test.Assert(create != null);
		Test.Assert(MenuRows.Is(create, "Material|-|Primitives>"));
		let primitives = MenuRows.SubMenuNamed(create, "Primitives");
		Test.Assert((primitives != null) && MenuRows.Is(primitives, "Cube"));
		Test.Assert(MenuRows.ItemNamed(create, "Material").HandleActivate());
		Test.Assert((bed.Created.Count == 1) && (bed.Created[0] == "Material") && (bed.CreatedIn[0] == bed.Top));
		// Another's, into it.
		view.Navigate(bed.Town);
		menu = bed.MenuFor(-1);
		Test.Assert(MenuRows.Is(menu, "New>|New Group|Import...|-|Rename|Always Export Its Contents|-|Cook Group|Rebuild Group|-|Delete Group..."));
		Test.Assert(MenuRows.ItemNamed(MenuRows.SubMenuNamed(MenuRows.SubMenuNamed(menu, "New"), "Primitives"), "Cube").HandleActivate());
		Test.Assert((bed.Created.Count == 2) && (bed.Created[1] == "Cube") && (bed.CreatedIn[1] == bed.Town), "into the group shown");
		bed.Choose(-1, "Import...");
		Test.Assert((bed.ImportInto.Count == 1) && (bed.ImportInto[0] == bed.Town), "files asked for into the group shown");
		bed.Choose(-1, "New Group");
		let made = view.CurrentGroup;
		Test.Assert((made != null) && (made.Name == "Group") && (made.Parent == bed.Town), "made and shown");
		Test.Assert(bed.TreeItem("Group") >= 0, "in the tree");
		Test.Assert(view.Tree.SelectedItem == bed.TreeItem("Group"));
		Test.Assert(bed.Project.SourceDb.Mount.Exists("Models/Town/Group"), "a folder while empty");

		// A right click: on a row its menu, on the list's empty room and on the tree the shown group's.
		view.Navigate(bed.Top);
		bed.Root.MutationQueue.Drain(); // the menus and questions closed, out of the tree
		bed.Layout();
		bed.RightClick(bed.Middle(list, bed.RowOf("Crate")));
		menu = view.OpenMenu;
		Test.Assert((menu != null) && (MenuRows.ItemNamed(menu, "Duplicate") != null), "a row's");
		menu.Close();
		bed.Root.MutationQueue.Drain(); // the closed menu out of the tree
		bed.Layout();
		let room = list.ConvertToWorldSpace(.(list.Size.X - 8.0f, list.Size.Y - 8.0f));
		Test.Assert(list.ItemAt(room) < 0, "no row there");
		bed.RightClick(room);
		menu = view.OpenMenu;
		Test.Assert((menu != null) && MenuRows.Is(menu, "New>|New Group|Import...|-|Cook All|Rebuild All"), "the shown group's");
		menu.Close();
		bed.Root.MutationQueue.Drain();
		bed.RightClick(bed.Middle(view.Tree, 0)); // Content, the group shown
		menu = view.OpenMenu;
		Test.Assert((menu != null) && (MenuRows.ItemNamed(menu, "New Group") != null), "the tree's: the group shown");
		menu.Close();
	}

	/// Delete asks first, naming what goes and what follows: on the list the selected assets, else
	/// the selected group's row (what it holds counted); on the tree the group shown, Content
	/// never. Cancel keeps them; Delete deletes, what showed a deleted group moving to its parent.
	[Test]
	public static void DeleteAsksNamingWhatGoesCancelKeepsThemDeleteDeletes()
	{
		let bed = scope Bed("scratch_assets_view_delete");
		let view = bed.View;
		let list = view.List;
		list.SelectedItem = bed.RowOf("Crate");
		Test.Assert(list.FocusElement());
		bed.Press(.Delete);
		var confirm = view.OpenConfirm;
		Test.Assert(confirm != null);
		Test.Assert(confirm.Title == "Delete Asset");
		Test.Assert(confirm.Message == "Delete Crate? Its source file and cooked product go, and its open pages close.");
		Test.Assert(confirm.ButtonCount == 2);
		Test.Assert((confirm.ButtonAt(0).Text == "Cancel") && (confirm.ButtonAt(1).Text == "Delete"));
		Test.Assert(confirm.GetButtonRole(1) == .Destructive);
		Test.Assert(confirm.ButtonAt(0).HandleActivate()); // Cancel
		Test.Assert(view.OpenConfirm == null);
		let crate = bed.Crate.Id;
		Test.Assert(bed.Project.SourceDb.GetInstance(crate) != null, "kept");
		Test.Assert(list.FocusElement());
		bed.Press(.Delete);
		confirm = view.OpenConfirm;
		Test.Assert(confirm != null);
		Test.Assert(confirm.ButtonAt(1).HandleActivate()); // Delete
		Test.Assert(bed.Project.SourceDb.GetInstance(crate) == null);
		view.Refresh();
		Test.Assert(bed.RowsAre("/Models /Sounds"));

		// A group's row, what it holds all the way down counted.
		view.Navigate(bed.Town);
		list.SelectedItem = bed.RowOf("Bell");
		Test.Assert(list.FocusElement());
		bed.Press(.Delete);
		confirm = view.OpenConfirm;
		Test.Assert((confirm != null) && confirm.ButtonAt(1).HandleActivate());
		view.Navigate(bed.Top);
		list.SelectedItem = bed.RowOf("Models");
		Test.Assert(list.FocusElement());
		bed.Press(.Delete);
		confirm = view.OpenConfirm;
		Test.Assert(confirm != null);
		Test.Assert(confirm.Title == "Delete Group");
		Test.Assert(confirm.Message == "Delete the group Models and the asset in it? Its source file and cooked product go, and its open page closes.");
		Test.Assert(confirm.ButtonAt(0).HandleActivate());
		Test.Assert(bed.Town.CreateInstance("Keg", bed.MeshName) != null);
		view.Refresh();
		list.SelectedItem = bed.RowOf("Models");
		Test.Assert(list.FocusElement());
		bed.Press(.Delete);
		confirm = view.OpenConfirm;
		Test.Assert(confirm != null);
		Test.Assert(confirm.Message == "Delete the group Models and the 2 assets in it? Their source files and cooked products go, and their open pages close.");
		let barrel = bed.Barrel.Id;
		view.Navigate(bed.Town); // shown inside it: moved out before it goes
		Test.Assert(confirm.ButtonAt(1).HandleActivate());
		Test.Assert(bed.Top.GetGroup("Models") == null);
		Test.Assert(bed.Project.SourceDb.GetInstance(barrel) == null);
		Test.Assert(view.CurrentGroup == bed.Top);
		view.Refresh();
		Test.Assert(bed.RowsAre("/Sounds"));
		Test.Assert(bed.TreeItem("Models") < 0);

		// The tree: the group shown, an empty one said so; Content never.
		Test.Assert(view.Tree.FocusElement());
		bed.Press(.Delete);
		Test.Assert(view.OpenConfirm == null, "Content is not deleted");
		view.Navigate(bed.Sounds);
		Test.Assert(view.Tree.FocusElement());
		bed.Press(.Delete);
		confirm = view.OpenConfirm;
		Test.Assert(confirm != null);
		Test.Assert(confirm.Message == "Delete the empty group Sounds?");
		Test.Assert(confirm.ButtonAt(1).HandleActivate());
		Test.Assert(bed.Top.GetGroup("Sounds") == null);
		Test.Assert(view.CurrentGroup == bed.Top, "moved to its parent first");
	}

	/// A row's name edited in place renames its asset or its group, a tree node's its group,
	/// through the models; a refused name says why and keeps the edit open, as F2's edit shows; the
	/// menu's Rename edits once the menu has closed, a shown group's in the tree; Content's node is
	/// not edited, nor the rows or the tree of a database moved since, until they are built again.
	[Test]
	public static void ARowsNameAndATreeGroupsEditedInPlaceRenameThemARefusedNameSayingWhyAndKept()
	{
		let bed = scope Bed("scratch_assets_view_rename");
		let view = bed.View;
		let rows = view.List.Model;
		let crate = bed.RowOf("Crate");
		Test.Assert(rows.IsEditable(rows.Index(crate)));
		Test.Assert(rows.SetData(rows.Index(crate), Sedulous.GUI.Variant(StringView("Box"))));
		Test.Assert(bed.Crate.Name == "Box");
		Test.Assert(!rows.IsEditable(rows.Index(crate)), "the database moved: its rows are not edited till built again");
		view.Refresh();
		let boxRow = bed.RowOf("Box");
		Test.Assert(rows.IsEditable(rows.Index(boxRow)));
		Test.Assert(!rows.SetData(rows.Index(boxRow), Sedulous.GUI.Variant(StringView("a:b"))));
		Test.Assert(bed.LastSaid == "A name cannot hold :.");
		Test.Assert(bed.Crate.Name == "Box");
		// A group's row.
		Test.Assert(rows.SetData(rows.Index(bed.RowOf("Models")), Sedulous.GUI.Variant(StringView("Props"))));
		Test.Assert(bed.Models.Name == "Props");
		view.Refresh();
		Test.Assert(!rows.SetData(rows.Index(bed.RowOf("Props")), Sedulous.GUI.Variant(StringView("Sounds"))));
		Test.Assert(bed.LastSaid == "Sounds is already there.");

		// The tree's nodes.
		let tree = view.Tree;
		let groups = tree.Model;
		Test.Assert(!groups.IsEditable(tree.GetItemIndex(0)), "Content");
		let town = bed.TreeItem("Town");
		Test.Assert(town >= 0);
		Test.Assert(groups.IsEditable(tree.GetItemIndex(town)));
		Test.Assert(groups.SetData(tree.GetItemIndex(town), Sedulous.GUI.Variant(StringView("Village"))));
		Test.Assert(bed.Town.Name == "Village");
		Test.Assert(!groups.IsEditable(tree.GetItemIndex(town)), "the tree of the database as it was");
		view.Refresh();
		let village = bed.TreeItem("Village");
		Test.Assert(village >= 0);
		Test.Assert(!groups.SetData(tree.GetItemIndex(village), Sedulous.GUI.Variant(StringView("a*b"))));
		Test.Assert(bed.LastSaid == "A name cannot hold *.");
		Test.Assert(bed.Town.Name == "Village");

		// F2 on the list: a refused name keeps the edit open, marked.
		view.SetTiles(false);
		bed.Layout();
		let list = view.List;
		list.SelectedItem = bed.RowOf("Box");
		Test.Assert(list.FocusElement());
		bed.Press(.F2);
		Test.Assert(list.IsEditing);
		Test.Assert(list.Editor.Text == "Box");
		list.Editor.Text = "a/b";
		Test.Assert(!list.EndEdit(true));
		Test.Assert(list.IsEditing && list.Editor.HasClass("invalid"), "kept open, marked");
		Test.Assert(bed.LastSaid == "A name cannot hold /.");
		list.Editor.Text = "Anvil";
		Test.Assert(list.EndEdit(true));
		Test.Assert(!list.IsEditing);
		Test.Assert(bed.Crate.Name == "Anvil");
		view.Refresh();

		// F2 on the tree.
		tree.SelectedItem = bed.TreeItem("Village");
		Test.Assert(tree.FocusElement());
		bed.Press(.F2);
		Test.Assert(tree.IsEditing);
		tree.Editor.Text = "Hamlet";
		Test.Assert(tree.EndEdit(true));
		Test.Assert(bed.Town.Name == "Hamlet");
		view.Refresh();

		// The menu's Rename, once the menu has closed (its close gives the list the focus back).
		bed.Layout();
		bed.Choose(bed.RowOf("Anvil"), "Rename");
		Test.Assert(!list.IsEditing, "not while the menu closes");
		bed.Root.MutationQueue.Drain();
		Test.Assert(list.IsEditing);
		Test.Assert(list.Editor.Text == "Anvil");
		Test.Assert(list.EndEdit(false));
		Test.Assert(bed.Crate.Name == "Anvil");
		// The shown group's, in the tree.
		view.Navigate(bed.Town);
		bed.Choose(-1, "Rename");
		Test.Assert(!tree.IsEditing);
		bed.Root.MutationQueue.Drain();
		Test.Assert(tree.IsEditing);
		Test.Assert(tree.Editor.Text == "Hamlet");
		Test.Assert(tree.EndEdit(false));
	}

	/// Assets dropped on a group's row or a group in the tree move into it, the drop saying "Move
	/// into ..."; between rows is no move; one already there, or whose name is taken there, is
	/// refused, saying why.
	[Test]
	public static void AssetsDroppedOnAGroupsRowOrAGroupInTheTreeMoveIntoItOneAlreadyThereOrTakenThereIsRefused()
	{
		let bed = scope Bed("scratch_assets_view_drop");
		let view = bed.View;
		let rows = view.List.Model;
		let crate = scope DragPayload();
		AssetDrag.Payload(bed.Crate.Id, bed.MeshName, "Crate", crate);

		// Onto the Models row: moved.
		var drop = ModelDrop();
		drop.Payload = crate;
		drop.Index = rows.Index(bed.RowOf("Models"));
		drop.Place = .On;
		let why = scope String();
		Test.Assert(rows.CanDrop(drop, why) == .Move);
		Test.Assert(why == "Move into Models");
		drop.Place = .After; // between rows: not a move
		why.Clear();
		Test.Assert(rows.CanDrop(drop, why) == .None);
		Test.Assert(why.IsEmpty, "no reason: a place it does not take");
		drop.Index = rows.Index(bed.RowOf("Crate"));
		drop.Place = .On;
		Test.Assert(rows.CanDrop(drop, why) == .None, "an asset's row is no group");
		drop.Index = rows.Index(bed.RowOf("Models"));
		Test.Assert(rows.Drop(drop));
		Test.Assert(bed.Crate.OwningGroup === bed.Models);
		Test.Assert(bed.Crate.GetPath(.. scope .()) == "Models/Crate");
		view.Refresh();

		// Into Town through the tree; then back where it is: refused.
		let tree = view.Tree;
		let groups = tree.Model;
		Test.Assert((bed.TreeItem("Town") >= 0) && (bed.TreeItem("Models") >= 0));
		var onto = ModelDrop();
		onto.Payload = crate;
		onto.Index = tree.GetItemIndex(bed.TreeItem("Town"));
		onto.Place = .On;
		Test.Assert(groups.CanDrop(onto, why) == .Move);
		Test.Assert(why == "Move into Town");
		Test.Assert(groups.Drop(onto));
		Test.Assert(bed.Crate.OwningGroup === bed.Town);
		view.Refresh();
		onto.Index = tree.GetItemIndex(bed.TreeItem("Town"));
		Test.Assert(groups.CanDrop(onto, why) == .None);
		Test.Assert(why == "Already in Models/Town");
		Test.Assert(!groups.Drop(onto));
		// Text, which TreeModel's own drop would make a node of: the tree is the database's.
		let text = scope DragPayload();
		text.Type.Set("text");
		text.Label.Set("Loose");
		onto.Payload = text;
		Test.Assert(groups.CanDrop(onto, why) == .None);
		Test.Assert(!groups.Drop(onto));
		Test.Assert(tree.GetItemCount() == 4, "no node made");

		// A name taken where it would go: refused, saying so.
		Test.Assert(bed.Models.CreateInstance("Barrel", bed.MeshName) != null);
		view.Refresh();
		let barrel = scope DragPayload();
		AssetDrag.Payload(bed.Barrel.Id, bed.MeshName, "Barrel", barrel);
		onto.Payload = barrel;
		onto.Index = tree.GetItemIndex(bed.TreeItem("Models"));
		Test.Assert(groups.CanDrop(onto, why) == .None);
		Test.Assert(why == "Barrel is already in Models");
		Test.Assert(!groups.Drop(onto));
		Test.Assert(bed.Barrel.OwningGroup === bed.Town);
	}

	/// The pointer's drag of the browser's assets, over a group's row, a group in the tree or a
	/// breadcrumb segment, says "Move into ..." and moves them there when let go; over the group
	/// they are in it says so and moves nothing; the current segment takes none.
	[Test]
	public static void APointersDragOfAssetsOntoAGroupsRowTheTreeOrABreadcrumbSegmentMovesThem()
	{
		let bed = scope Bed("scratch_assets_view_drag_move");
		let view = bed.View;
		view.SetTiles(false);
		let reason = scope String();

		// Onto the Models row.
		Test.Assert(bed.DragRowTo(bed.RowOf("Crate"), bed.Middle(view.List, bed.RowOf("Models")), reason) == .Move);
		Test.Assert(reason == "Move into Models");
		Test.Assert(bed.Crate.OwningGroup === bed.Models);
		view.Refresh();

		// Onto Town in the tree.
		view.Navigate(bed.Models);
		Test.Assert(bed.RowsAre("/Town Crate"));
		Test.Assert(bed.DragRowTo(bed.RowOf("Crate"), bed.Middle(view.Tree, bed.TreeItem("Town")), reason) == .Move);
		Test.Assert(reason == "Move into Town");
		Test.Assert(bed.Crate.OwningGroup === bed.Town);
		view.Refresh();

		// Onto the group it is in: refused, saying so.
		view.Navigate(bed.Town);
		Test.Assert(bed.RowsAre("Barrel Bell Crate"));
		Test.Assert(bed.DragRowTo(bed.RowOf("Crate"), bed.Middle(view.Tree, bed.TreeItem("Town")), reason) == .None);
		Test.Assert(reason == "Already in Models/Town");
		Test.Assert(bed.Crate.OwningGroup === bed.Town);

		// Onto Content's breadcrumb segment: up to the top. The current segment takes none.
		Test.Assert(view.Crumbs.ItemCount == 3);
		// A segment sized as the editor's sheet would (no sheet, so no font, is loaded here); the
		// bar makes its segments again as the view moves, so each is sized as it is used.
		Node Segment(int index)
		{
			let segment = view.Crumbs.SegmentAt(index);
			segment.EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Px(80.0f);
					s.Height = LayoutLength.Px(20.0f);
				});
			return segment;
		}
		Test.Assert(bed.DragRowTo(bed.RowOf("Crate"), bed.MiddleOf(Segment(0)), reason) != .None);
		Test.Assert(bed.Crate.OwningGroup === bed.Top);
		view.Refresh();
		Test.Assert(bed.RowsAre("Barrel Bell"));
		Test.Assert(bed.DragRowTo(bed.RowOf("Bell"), bed.MiddleOf(Segment(2)), reason) == .None);
		Test.Assert(bed.Bell.OwningGroup === bed.Town);
	}

	/// A tile shows its type's glyph until its thumbnail is ready, then the thumbnail in its place:
	/// drawn again when the context says one is ready (as the thumbnail service tells it), not
	/// before. One with none keeps its glyph, a list row always does, and a tile whose thumbnail
	/// goes shows its glyph again. The view hears the context while it lives.
	[Test]
	public static void ATileShowsItsTypesGlyphUntilItsThumbnailIsReadyThenTheThumbnail()
	{
		let bed = scope Bed("scratch_assets_view_thumbnails");
		let view = bed.View;
		Test.Assert(view.ShowsTiles);
		Test.Assert(bed.Context.ThumbnailListenerCount == 1, "the view hears the thumbnails");
		var crate = bed.Cell(bed.RowOf("Crate"));
		Test.Assert(crate != null);
		Test.Assert(!crate.ShowsPicture && crate.ShowsGlyph, "none yet: its glyph");

		bed.Picture = SvgDrawable.FromText("<svg xmlns='http://www.w3.org/2000/svg' width='8' height='8'><rect width='8' height='8'/></svg>");
		Test.Assert(bed.Picture != null);
		bed.Pictured = bed.Crate.Id;
		crate = bed.Cell(bed.RowOf("Crate"));
		Test.Assert(!crate.ShowsPicture, "nothing told the view: nothing drawn again");
		bed.Context.NotifyThumbnailReady(bed.Crate.Id); // as the thumbnail service tells it
		crate = bed.Cell(bed.RowOf("Crate"));
		Test.Assert(crate != null);
		Test.Assert(crate.ShowsPicture && !crate.ShowsGlyph, "ready: the thumbnail in its glyph's place");
		Test.Assert(!bed.Cell(bed.RowOf("Models")).ShowsPicture, "a group: its folder");
		view.Navigate(bed.Town);
		let bell = bed.Cell(bed.RowOf("Bell"));
		Test.Assert(!bell.ShowsPicture && bell.ShowsGlyph, "no thumbnail: its glyph stays");

		// A list row keeps its glyph, a thumbnail or not.
		view.Navigate(bed.Top);
		view.SetTiles(false);
		crate = bed.Cell(bed.RowOf("Crate"));
		Test.Assert((crate != null) && !crate.IsTile);
		Test.Assert(!crate.ShowsPicture && crate.ShowsGlyph, "a row: its glyph");

		// A tile whose thumbnail goes shows its glyph again.
		let tile = new AssetCell(true);
		defer tile.ReleaseRef();
		var shown = AssetCell.Shown();
		shown.Glyph = "Editor/Icons/file.svg";
		shown.Name = "Crate";
		shown.Picture = bed.Picture;
		tile.Show(shown);
		Test.Assert(tile.ShowsPicture && !tile.ShowsGlyph);
		shown.Picture = null;
		tile.Show(shown);
		Test.Assert(!tile.ShowsPicture && tile.ShowsGlyph);

		// Another view hears too, and stops when it goes.
		let again = bed.MakeView();
		Test.Assert(bed.Context.ThumbnailListenerCount == 2);
		delete again;
		Test.Assert(bed.Context.ThumbnailListenerCount == 1);
		bed.Context.NotifyThumbnailReady(bed.Crate.Id); // nothing of it left to call into
	}

	/// A right click on a group in the tree opens its menu; a browser with no verbs opens none
	/// (Raptor's crash at the desk, 2026-10-25).
	[Test]
	public static void ARightClickOnATreeGroupOpensItsMenuABrowserWithNoVerbsOpensNone()
	{
		let bed = scope Bed("scratch_assets_view_tree_menu");
		let view = bed.View;
		bed.RightClick(bed.Middle(view.Tree, bed.TreeItem("Town")));
		let menu = view.OpenMenu;
		Test.Assert(menu != null, "the tree group's menu");
		Test.Assert(view.CurrentGroup == bed.Town, "the group clicked is the one shown");
		Test.Assert(MenuRows.ItemNamed(menu, "Delete Group...") != null);
		menu.Close();
		bed.Root.MutationQueue.Drain();

		// The same browser with no verbs: no menu, and no crash.
		let services = new AssetsViewServices();
		services.Context = bed.Context;
		services.Icons = bed.Icons;
		let plain = scope AssetsView(services, LoadAssets());
		bed.Root.RemoveChild(view.Content);
		plain.Content.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(900.0f);
				s.Height = LayoutLength.Px(600.0f);
			});
		plain.Content.GetChildAt(0).EditLayoutStyle(scope (s) =>
			{
				s.Direction = .Row;
				s.Height = LayoutLength.Px(30.0f);
			});
		plain.Tree.Parent.EditLayoutStyle(scope (s) => { s.Direction = .Row; });
		plain.Tree.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(200.0f);
				s.Height = LayoutLength.Px(300.0f);
			});
		bed.Root.AddChild(plain.Content);
		plain.Rebuild();
		bed.RightClick(bed.Middle(plain.Tree, 0));
		Test.Assert(plain.OpenMenu == null, "no verbs: no menu");
		bed.Root.RemoveChild(plain.Content); // before the plain view goes
		bed.Root.AddChild(view.Content);
	}

	/// An asset or a group always exported is marked: a tile's dot in its picture's corner (its
	/// tooltip saying what it means), a row's Always Export icon, lit when so and greyed when not, on every row; the
	/// menus' toggles draw the cell again at once.
	[Test]
	public static void AnAssetOrAGroupAlwaysExportedIsMarkedATilesCornerMarkARowsLitIconTheMenusToggleRedrawsIt()
	{
		let bed = scope Bed("scratch_assets_view_always_export");
		let view = bed.View;
		Test.Assert(view.ShowsTiles);
		var crate = bed.Cell(bed.RowOf("Crate"));
		Test.Assert(crate != null);
		Test.Assert(!crate.ShowsAlwaysExport);
		// A tile's mark: a dot in its picture, out of the layout till flagged, reached by the
		// pointer for its tooltip.
		let mark = crate.AlwaysExportPart;
		Test.Assert(mark.HasClass("export-mark") && (mark.Parent !== crate), "in the picture");
		Test.Assert(!mark.Displayed);
		Test.Assert(mark.Tooltip == "Always exported");
		Test.Assert(mark.HitTestVisible, "its tooltip");

		// Through the asset's menu, as a user does: the cell redraws with its mark, unasked.
		bed.Choose(bed.RowOf("Crate"), "Always Export");
		crate = bed.Cell(bed.RowOf("Crate"));
		Test.Assert(crate != null);
		Test.Assert(crate.ShowsAlwaysExport, "its mark at once");
		Test.Assert(crate.AlwaysExportPart.Displayed);

		// A group's contents, and the list's icon.
		bed.Ops.ToggleAlwaysExport(bed.Models);
		view.SetTiles(false);
		let models = bed.Cell(bed.RowOf("Models"));
		Test.Assert(models != null);
		Test.Assert(!models.IsTile);
		Test.Assert(models.ShowsAlwaysExport, "a group marked");
		let icon = models.AlwaysExportPart;
		Test.Assert(icon.HasClass("badge-icon") && icon.HasClass("always-export") && !icon.HasClass("export"), "an icon, not the export dialog's class");
		Test.Assert(icon.HasClass("on"), "lit");
		Test.Assert(icon.Tooltip == "Always exported");
		Test.Assert(icon.Parent === models, "a column of the row's own");
		crate = bed.Cell(bed.RowOf("Crate"));
		Test.Assert(crate != null);
		Test.Assert(crate.ShowsAlwaysExport);
		// A row not flagged shows the icon greyed, so every row's name stays in line.
		let sounds = bed.Cell(bed.RowOf("Sounds"));
		Test.Assert(sounds != null);
		Test.Assert(!sounds.ShowsAlwaysExport);
		Test.Assert(sounds.AlwaysExportPart.Displayed && sounds.AlwaysExportPart.Visible && !sounds.AlwaysExportPart.HasClass("on"), "shown, greyed");
		Test.Assert(sounds.AlwaysExportPart.Tooltip == "Exported when something it ships uses it");

		// Through the group's menu: its mark goes at once.
		bed.Choose(bed.RowOf("Models"), "Always Export Its Contents");
		Test.Assert(!bed.Project.ExportRoots.HasGroup("Models"));
		Test.Assert(!bed.Cell(bed.RowOf("Models")).ShowsAlwaysExport, "its mark gone at once");

		bed.Ops.ToggleAlwaysExport(bed.Crate.Id); // off again
		view.Rebuild();
		crate = bed.Cell(bed.RowOf("Crate"));
		Test.Assert(crate != null);
		Test.Assert(!crate.ShowsAlwaysExport);
		Test.Assert(crate.AlwaysExportPart.Displayed, "its column kept");
	}
}
