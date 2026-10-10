using System;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Pipeline.Core;
using Sedulous.Settings;
using Sedulous.UI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The Assets panel and the asset picker over a scratch project: the browser's group tree
/// indents each level by the tree's own inset; both views of assets switch between a list and a
/// grid through the same List and Grid icon toggles (a radio pair), and the picker keeps its
/// own choice per project.
static class AssetsViewTests
{
	/// A scratch project with one asset in the root group, open in an editor context that has
	/// a project editor settings store, where the view modes are remembered.
	private class Bench
	{
		public String Dir = new .() ~ delete _;
		public EditorProject Project ~ delete _;
		public EditorContext Context = new .() ~ delete _;
		public Settings Store = new .() ~ delete _;
		public BuilderRegistry Builders = new .() ~ delete _;
		public EditorCookService Cook = new .() ~ delete _;
		public Guid Asset;

		public this(StringView leaf)
		{
			Dir.Set(leaf);
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "Views") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			let instance = Project.SourceDb.RootGroup.CreateInstance("Crate", "Tests.Blob");
			Test.Assert(instance != null);
			Asset = instance.Id;
			Context.SetProject(Project);
			Context.ProjectEditorSettings = Store;
			Cook.Initialize(Project, Builders);
		}

		public ~this()
		{
			Cook.Shutdown();
			Context.ProjectEditorSettings = null;
			Context.SetProject(null);
			DeleteAndNullify!(Project);
			RemoveDirectoryRecursive(Dir);
		}
	}

	/// Two icon toggles with their words as tooltips, one always checked: checking the other
	/// switches and reports once, pressing the checked one leaves it checked, and the owner's
	/// SetGridMode moves the check without reporting back.
	[Test]
	public static void TheViewTogglesAreTwoIconsOneAlwaysChecked()
	{
		EditorIcons.Initialize();
		defer EditorIcons.Shutdown();
		let toggles = new ViewModeToggles();
		defer toggles.ReleaseRef();
		let list = toggles.ListToggle;
		let grid = toggles.GridToggle;
		Test.Assert(list.TooltipText == "List");
		Test.Assert(grid.TooltipText == "Grid");
		// Icons, not words: each toggle's content is a drawable view showing its icon.
		let listGlyph = list.Content as DrawableView;
		let gridGlyph = grid.Content as DrawableView;
		Test.Assert((listGlyph != null) && (gridGlyph != null));
		Test.Assert(listGlyph.Drawable == EditorIcons.ViewList);
		Test.Assert(gridGlyph.Drawable == EditorIcons.ViewGrid);

		var calls = 0;
		var last = false;
		toggles.OnModeChanged = new [&](grid) => { calls++; last = grid; };
		Test.Assert(list.IsChecked.Value && !grid.IsChecked.Value);

		grid.IsChecked.Value = true;
		Test.Assert(toggles.GridMode && !list.IsChecked.Value);
		Test.Assert((calls == 1) && last);

		grid.IsChecked.Value = false;
		Test.Assert(grid.IsChecked.Value, "the checked one stays checked");
		Test.Assert(toggles.GridMode && (calls == 1));

		toggles.SetGridMode(false);
		Test.Assert(list.IsChecked.Value && !grid.IsChecked.Value);
		Test.Assert(calls == 1, "SetGridMode does not report");
	}

	/// The browser's Grid toggle shows the grid and remembers it for the project, the
	/// browser's choice alone.
	[Test]
	public static void TheBrowsersGridToggleShowsTheGridAndRemembersIt()
	{
		let bench = scope Bench("scratch_assets_view_modes");
		let view = new AssetsView(bench.Context, bench.Cook);
		defer view.ReleaseRef();
		Test.Assert(!view.IsGridMode);
		view.ViewToggles.GridToggle.IsChecked.Value = true;
		Test.Assert(view.IsGridMode);
		let section = bench.Store.Find<EditorAssetBrowserSettings>();
		Test.Assert(section != null);
		Test.Assert(section.GridMode);
		Test.Assert(!section.PickerGridMode, "the picker's choice is its own");
	}

	/// The picker shows the same rows as a grid, picks from a tile, and keeps its mode per
	/// project, apart from the browser's.
	[Test]
	public static void ThePickersGridShowsTheSameRowsPicksAndIsRemembered()
	{
		let bench = scope Bench("scratch_asset_picker_grid");
		var picked = Guid.Empty;
		{
			let picker = new AssetPickerDialog(bench.Context, .());
			defer picker.ReleaseRef();
			Test.Assert(!picker.IsGridMode);
			Test.Assert((picker.RowList.Visibility == .Visible) && (picker.RowGrid.Visibility == .Gone));
			Test.Assert((picker.Rows.Length == 1) && (picker.Rows[0] == bench.Asset));

			picker.ViewToggles.GridToggle.IsChecked.Value = true;
			Test.Assert(picker.IsGridMode);
			Test.Assert((picker.RowList.Visibility == .Gone) && (picker.RowGrid.Visibility == .Visible));
			let section = bench.Store.Find<EditorAssetBrowserSettings>();
			Test.Assert(section != null);
			Test.Assert(section.PickerGridMode);
			Test.Assert(!section.GridMode, "the browser's choice is its own");

			// A double-click on a tile picks its asset, as on a list row.
			picker.OnPicked = new [&picked](id) => { picked = id; };
			picker.RowGrid.OnItemClicked(0, 2, 0.0f, 0.0f);
		}
		Test.Assert(picked == bench.Asset);

		// The next picker opens in the grid.
		let again = new AssetPickerDialog(bench.Context, .());
		defer again.ReleaseRef();
		Test.Assert(again.IsGridMode);
		Test.Assert(again.ViewToggles.GridToggle.IsChecked.Value);
	}

	/// Each folder's name is indented by the tree's own inset for its depth.
	///
	/// The rows set a literal (depth + 1) * 18 while the tree draws each chevron in its
	/// IndentWidth column (20), so a name fell 2 px further behind its chevron at every level
	/// and the gap before the chevrons shrank with depth.
	[Test]
	public static void EachFolderIsIndentedByTheTreesInsetForItsDepth()
	{
		let dir = "scratch_assets_view_tree";
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "Tree") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;

		// Content/A/B/C: a folder at every depth from nought to three.
		let root = project.SourceDb.RootGroup;
		let a = root.CreateGroup("A");
		let b = a.CreateGroup("B");
		let c = b.CreateGroup("C");

		let context = scope EditorContext();
		context.SetProject(project);
		let builders = scope BuilderRegistry();
		let cook = scope EditorCookService();
		cook.Initialize(project, builders);
		defer cook.Shutdown();

		let view = new AssetsView(context, cook);
		defer view.ReleaseRef();
		let tree = view.GroupTree;
		let adapter = tree.TreeAdapter as GroupTreeAdapter;
		Test.Assert(adapter != null);

		Group[4] groups = .(root, a, b, c);
		for (int32 depth < 4)
		{
			var nodeId = (int32)-1;
			for (int32 i < (int32)adapter.Count)
			{
				if (adapter.GroupAt(i) === groups[depth])
					nodeId = i;
			}
			Test.Assert(nodeId >= 0, "the folder is in the tree");
			Test.Assert(adapter.GetDepth(nodeId) == depth);

			let row = adapter.CreateView(0);
			defer row.ReleaseRef();
			adapter.BindView(row, nodeId, depth, true);
			let label = row as AssetNameLabel;
			Test.Assert(label != null);
			Test.Assert(label.TextOffsetX.Value == tree.ContentInset(depth),
				scope $"depth {depth}: text at {label.TextOffsetX.Value}, inset {tree.ContentInset(depth)}");
		}
	}

	/// The filter finds a name by any part of it, or a guid whole or by its first digits.
	[Test]
	public static void TheFilterFindsANameOrAGuidWholeOrByItsStart()
	{
		let bench = scope Bench("scratch_asset_filter");
		let crate = bench.Project.SourceDb.GetInstance(bench.Asset);
		Test.Assert(crate != null);
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

	/// A guid in the browser's filter finds its asset in any group, and a whole one selects it.
	[Test]
	public static void AGuidInTheBrowsersFilterFindsItsAssetAndSelectsIt()
	{
		let bench = scope Bench("scratch_assets_view_guid");
		// A second asset deep in a subgroup, the one to find.
		let props = bench.Project.SourceDb.RootGroup.CreateGroup("Props");
		let lamp = props.CreateInstance("Lamp", "Tests.Blob");
		Test.Assert(lamp != null);
		let text = lamp.Id.ToString(.. scope .());

		let view = new AssetsView(bench.Context, bench.Cook);
		defer view.ReleaseRef();
		view.SetFilter(text);
		let listed = scope System.Collections.List<Guid>();
		view.ListedAssets(listed);
		Test.Assert((listed.Count == 1) && (listed[0] == lamp.Id));
		Test.Assert(view.SelectedPosition == 0, "a whole guid selects its asset");

		// Its first digits find it too, without choosing it for the user.
		view.SetFilter(StringView(text, 0, 8));
		view.ListedAssets(listed);
		Test.Assert(listed.Contains(lamp.Id));
	}

	/// A guid in the picker's filter lists its asset when the slot takes it, and says why not
	/// otherwise.
	[Test]
	public static void AGuidInThePickerListsItsAssetOrSaysWhyNot()
	{
		let bench = scope Bench("scratch_asset_picker_guid");
		let crate = bench.Project.SourceDb.GetInstance(bench.Asset);
		let text = crate.Id.ToString(.. scope .());

		// A slot that takes the crate's type: listed and selected.
		{
			StringView[1] types = .(crate.TypeName);
			let picker = new AssetPickerDialog(bench.Context, types);
			defer picker.ReleaseRef();
			picker.SetFilter(text);
			Test.Assert((picker.Rows.Length == 1) && (picker.Rows[0] == crate.Id));
			Test.Assert(picker.RowList.Selection.FirstSelected() == 0);
			Test.Assert(picker.FilterHint.IsEmpty);
		}
		// A slot that takes something else: nothing listed, and the line under the filter says why.
		{
			StringView[1] types = .("MaterialAsset");
			let picker = new AssetPickerDialog(bench.Context, types);
			defer picker.ReleaseRef();
			picker.SetFilter(text);
			Test.Assert(picker.Rows.IsEmpty);
			Test.Assert(picker.FilterHint.Contains("Crate", true) && picker.FilterHint.Contains("does not take", true), scope String(picker.FilterHint));
			picker.SetFilter("");
			Test.Assert(picker.FilterHint.IsEmpty);
		}
	}
}
