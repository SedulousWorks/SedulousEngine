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
}
