using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// The Assets panel: source-database backed, the typed database is the truth. Left, the
/// group tree; right, the breadcrumb and list/grid toggle over the filter over the selected
/// group's content, subgroups first (double-click descends, the breadcrumb climbs back), then
/// instances; a non-empty filter searches instances across all groups. Rows show the name,
/// coloured by cook state, with a trailing "Type [badge]" meta label. Double-click descends
/// into a group or opens the instance's page; inline rename everywhere by slow click, F2 or
/// the menu; right-click rows for Open, Rename, Duplicate, Cook, Rebuild, Delete (multi-select
/// aware) and the background for Create, New Group, Import, Cook All, Rebuild All. Delete
/// always confirms, closes any open page first through OnCloseInstancePage, and logs.
class AssetsView : ViewGroup
{
	/// One content-area row: a subgroup of the selected group, or an instance.
	private struct Row
	{
		/// The instance identity, safe across deletes.
		public Guid Id = .Empty;
		/// Non-null for a navigable subgroup row.
		public Group Group = null;
	}

	private class ListAdapter : ListAdapterBase
	{
		private AssetsView mOwner;
		public this(AssetsView owner) { mOwner = owner; }
		public override int32 ItemCount => (int32)mOwner.mRows.Count;

		public override View CreateView(int32 viewType)
		{
			let row = new AssetCell();
			row.Direction = .Horizontal;
			row.Spacing = 6;
			row.Padding = .(4, 3);
			let iconView = new DrawableView();
			iconView.DesiredWidth.Value = 16.0f;
			iconView.DesiredHeight.Value = 16.0f;
			row.AddView(iconView);
			let name = new AssetNameLabel();
			name.FontSize.Value = 13.0f;
			name.Configure(new (label, newName) => { mOwner.ApplyRename(label, newName); });
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			row.AddView(name, grow);
			let meta = new Label();
			meta.FontSize.Value = 13.0f;
			row.AddView(meta);
			return row;
		}

		public override void BindView(View view, int32 position)
		{
			let row = view as AssetCell;
			if ((row == null) || (row.ChildCount < 3))
				return;
			row.ShowExportBadge = mOwner.IsRowExportRoot(position);
			row.ShowFavoriteBadge = mOwner.IsRowFavorite(position);
			let iconView = row.GetChildAt(0) as DrawableView;
			let name = row.GetChildAt(1) as AssetNameLabel;
			let meta = row.GetChildAt(2) as Label;
			if ((iconView == null) || (name == null) || (meta == null))
				return;
			iconView.SetDrawable(Retained(mOwner.RowIcon(position)));
			let target = mOwner.RowAt(position);
			name.BindTarget(target.Id, target.Group);
			if (let instance = mOwner.InstanceAt(position))
				row.BindDragPayload(instance.Id, instance.TypeName, instance.Name);
			else
				row.ClearDragPayload();
			let text = scope String();
			var color = Color(0.85f, 0.85f, 0.85f, 1.0f);
			mOwner.RowName(position, text, ref color);
			name.SetText(text);
			name.TextColor.Value = color;
			let metaText = scope String();
			var metaColor = Color(0.55f, 0.58f, 0.65f, 1.0f);
			mOwner.RowMeta(position, metaText, ref metaColor);
			meta.SetText(metaText);
			meta.TextColor.Value = metaColor;
		}
	}

	/// The grid tiles: the same rows as the list, the name under the icon or thumbnail.
	private class GridAdapter : ListAdapterBase
	{
		private AssetsView mOwner;
		public this(AssetsView owner) { mOwner = owner; }
		public override int32 ItemCount => (int32)mOwner.mRows.Count;

		public override View CreateView(int32 viewType)
		{
			let tile = new AssetCell();
			tile.Direction = .Vertical;
			tile.Padding = .(4, 4);
			let iconRow = new FlexLayout();
			iconRow.Direction = .Horizontal;
			iconRow.JustifyContent = .Center;
			// The cross-axis default is Stretch: without Center the icon fills the row's
			// height and the glyph draws vertically stretched.
			iconRow.AlignItems = .Center;
			let iconView = new DrawableView();
			iconView.DesiredWidth.Value = 40.0f;
			iconView.DesiredHeight.Value = 40.0f;
			iconRow.AddView(iconView);
			let name = new AssetNameLabel();
			name.FontSize.Value = 12.0f;
			name.HAlign.Value = .Center;
			name.Ellipsis.Value = true; // long names truncate instead of overflowing the tile
			name.Configure(new (label, newName) => { mOwner.ApplyRename(label, newName); });
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			grow.Width = SizeSpec.Match();
			tile.AddView(iconRow, grow);
			var nameStyle = LayoutStyle();
			nameStyle.Width = SizeSpec.Match();
			nameStyle.Height = SizeSpec.Fixed(Unit.Dp(18));
			tile.AddView(name, nameStyle);
			return tile;
		}

		public override void BindView(View view, int32 position)
		{
			let tile = view as AssetCell;
			if ((tile == null) || (tile.ChildCount < 2))
				return;
			tile.ShowExportBadge = mOwner.IsRowExportRoot(position);
			tile.ShowFavoriteBadge = mOwner.IsRowFavorite(position);
			let iconRow = tile.GetChildAt(0) as FlexLayout;
			let name = tile.GetChildAt(1) as AssetNameLabel;
			if ((iconRow == null) || (iconRow.ChildCount < 1) || (name == null))
				return;
			let iconView = iconRow.GetChildAt(0) as DrawableView;
			if ((iconView == null) || (position < 0) || (position >= mOwner.mRows.Count))
				return;
			let row = mOwner.mRows[position];
			// The thumbnail wins; the type icon shows until one exists.
			Drawable drawable = null;
			if ((row.Group == null) && (mOwner.mContext.Thumbnails != null))
				drawable = mOwner.mContext.Thumbnails.Get(row.Id);
			if (drawable == null)
				drawable = mOwner.RowIcon(position);
			iconView.SetDrawable(Retained(drawable));
			name.BindTarget(row.Id, row.Group);
			if (let instance = mOwner.InstanceAt(position))
				tile.BindDragPayload(instance.Id, instance.TypeName, instance.Name);
			else
				tile.ClearDragPayload();
			// No meta label on a tile: the name colour carries the cook status (favourite and
			// export show as corner dots) and stays pure, it is the inline-rename edit text.
			let text = scope String();
			var color = Color(0.85f, 0.85f, 0.85f, 1.0f);
			mOwner.RowName(position, text, ref color);
			name.SetText(text);
			name.TextColor.Value = color;
		}
	}

	/// Open an instance's editor page; wired by the application. Owned.
	public delegate void(Instance instance) OnOpenInstance ~ delete _;
	/// Import... in the background menu: the app, which owns the shell, browses for a file
	/// and feeds it back through ImportFile. Owned.
	public delegate void() OnBrowseImport ~ delete _;
	/// Create an asset via a registry creator, into the group the menu was invoked for;
	/// wired by the application, which also opens it. Owned.
	public delegate void(AssetCreator creator, Group group) OnCreate ~ delete _;
	/// Close any open editor page for this instance before it is deleted; called from a
	/// mutation-queue action, so synchronous teardown is safe. Owned.
	public delegate void(Guid id) OnCloseInstancePage ~ delete _;

	/// Borrowed.
	private EditorContext mContext;
	/// Borrowed, app-owned.
	private EditorCookService mCook;
	/// Borrowed; null in headless hosts.
	private EditorJobService mJobs;
	// Borrowed: the tree owns them.
	private TreeView mTree;
	private ListView mList;
	private GridView mGrid;
	private EditText mFilterEdit;
	private BreadcrumbBar mBreadcrumb;
	private ToggleButton mListToggle;
	private ToggleButton mGridToggle;
	private AssetGroupTreeAdapter mTreeAdapter ~ delete _;
	private ListAdapter mListAdapter ~ delete _;
	private GridAdapter mGridAdapter ~ delete _;
	/// The content area: subgroups, then instances.
	private List<Row> mRows = new .() ~ delete _;
	/// Segment index to group.
	private List<Group> mBreadcrumbGroups = new .() ~ delete _;
	private Group mSelectedGroup = null;
	/// The chosen import destination, the Change... picker.
	private Group mImportTargetGroup = null;
	private String mFilter = new .() ~ delete _;
	private bool mGridMode = false;
	private uint64 mCookRevision = uint64.MaxValue;

	public this(EditorContext context, EditorCookService cook, EditorJobService jobs = null)
	{
		mContext = context;
		mCook = cook;
		mJobs = jobs;

		let split = new SplitView();
		split.SplitRatio = 0.3f;

		// Left: the group tree.
		mTreeAdapter = new AssetGroupTreeAdapter(this);
		mTree = new TreeView();
		mTree.ItemHeight = 22.0f;
		mTree.OnItemClick.Add(new (info) =>
			{
				if (let group = mTreeAdapter.GroupAt(info.NodeId))
					SelectGroup(group);
			});
		mTree.OnItemRightClick.Add(new (nodeId, x, y) =>
			{
				if (let group = mTreeAdapter.GroupAt(nodeId))
					SelectGroup(group);
				ShowBackgroundMenu(mTree, x, y);
			});
		mTree.OnItemKeyDown.Add(new (nodeId, e) =>
			{
				let group = mTreeAdapter.GroupAt(nodeId);
				if ((group == null) || (group.Parent == null))
					return; // the root: no rename or delete
				if (e.Key == .F2)
				{
					StartRenameGroupInTree(group);
					e.Handled = true;
				}
				else if (e.Key == .Delete)
				{
					ConfirmDeleteGroup(group);
					e.Handled = true;
				}
			});

		// Right: the breadcrumb and view toggle over the filter over the list or grid.
		let right = new FlexLayout();
		right.Direction = .Vertical;
		right.Padding = .(6, 4); // inset off the edge, like the group tree
		right.Spacing = 4;
		{
			let header = new FlexLayout();
			header.Direction = .Horizontal;
			header.Spacing = 4;
			mBreadcrumb = new BreadcrumbBar();
			mBreadcrumb.OnSegmentClicked.Add(new (bar, segment) => { NavigateToBreadcrumb(segment); });
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			grow.Height = SizeSpec.Match();
			header.AddView(mBreadcrumb, grow);
			mListToggle = new ToggleButton("List");
			mGridToggle = new ToggleButton("Grid");
			mListToggle.IsChecked.Value = true;
			mListToggle.OnClick.Add(new (b) => { SetGridMode(false); });
			mGridToggle.OnClick.Add(new (b) => { SetGridMode(true); });
			header.AddView(mListToggle);
			header.AddView(mGridToggle);
			var headerStyle = LayoutStyle();
			headerStyle.Width = SizeSpec.Match();
			headerStyle.Height = SizeSpec.Fixed(Unit.Dp(26));
			right.AddView(header, headerStyle);
		}
		mFilterEdit = new EditText();
		mFilterEdit.Placeholder.Value.Set("Filter all assets...");
		mFilterEdit.OnTextChanged.Add(new (edit) =>
			{
				mFilter.Set(edit.Text);
				RebuildList();
			});
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		right.AddView(mFilterEdit, match);

		mListAdapter = new ListAdapter(this);
		mGridAdapter = new GridAdapter(this);
		mList = new ListView();
		mList.ItemHeight.Value = 22.0f;
		mList.Selection.Mode = .Multiple;
		mList.SetAdapter(mListAdapter);
		mGrid = new GridView();
		mGrid.CellWidth.Value = 96.0f;
		mGrid.CellHeight.Value = 84.0f;
		mGrid.Selection.Mode = .Multiple;
		mGrid.Visibility = .Gone;
		mGrid.SetAdapter(mGridAdapter);
		mList.OnItemClicked.Add(new (position, clickCount, x, y) => { ActivateRow(position, clickCount); });
		mList.OnItemRightClicked.Add(new (position, x, y) => { ShowRowMenu(mList, mList.Selection, position, x, y); });
		mList.OnBackgroundRightClicked.Add(new (x, y) => { ShowBackgroundMenu(mList, x, y); });
		mGrid.OnItemClicked.Add(new (position, clickCount, x, y) => { ActivateRow(position, clickCount); });
		mGrid.OnItemRightClicked.Add(new (position, x, y) => { ShowRowMenu(mGrid, mGrid.Selection, position, x, y); });
		mGrid.OnBackgroundRightClicked.Add(new (x, y) => { ShowBackgroundMenu(mGrid, x, y); });
		mList.OnItemKeyDown.Add(new (position, e) => { OnRowKeyDown(mList.Selection, position, e); });
		mGrid.OnItemKeyDown.Add(new (position, e) => { OnRowKeyDown(mGrid.Selection, position, e); });
		var fill = LayoutStyle();
		fill.FlexGrow = 1.0f;
		fill.Width = SizeSpec.Match();
		right.AddView(mList, fill);
		right.AddView(mGrid, fill);

		split.SetPanes(mTree, right);
		AddView(split);
		Rebuild();
		ApplySavedViewMode(); // the last-used list or grid view for this project
	}

	public ~this()
	{
		mTree.SetAdapter(null);
		mList.SetAdapter(null);
		mGrid.SetAdapter(null);
	}

	/// Per frame: the badges refresh after a cook finishes; database shape changes call
	/// Rebuild.
	public void Refresh()
	{
		if (mCook.Revision != mCookRevision)
		{
			mCookRevision = mCook.Revision;
			RebuildList();
		}
	}

	/// The full rebuild, group tree and list: project open and close, create, delete, import.
	public void Rebuild()
	{
		let root = (mContext.Project != null) ? mContext.Project.SourceDb.RootGroup : null;
		mTreeAdapter.Rebuild(root);
		// The selection is re-validated against the fresh snapshot; the group may be gone.
		bool selectionAlive = false;
		for (int32 i < (int32)mTreeAdapter.Count)
		{
			if (mTreeAdapter.GroupAt(i) === mSelectedGroup)
			{
				selectionAlive = true;
				break;
			}
		}
		if (!selectionAlive)
			mSelectedGroup = root;
		mTreeAdapter.AttachExpanded(mTree);
		RebuildList();
	}

	/// A thumbnail finished for the id: just that row or tile rebinds in place, no tree or
	/// list reconstruction, since a generation burst would otherwise flicker the whole
	/// browser. Rows outside the current folder or filter no-op.
	public void RefreshThumbnail(Guid id)
	{
		for (int i < mRows.Count)
		{
			if ((mRows[i].Group == null) && (mRows[i].Id == id))
			{
				// Both adapters share the row model; only the attached view holds active
				// item views, so the other notify is a no-op.
				mListAdapter.NotifyRangeChanged((int32)i, 1);
				mGridAdapter.NotifyRangeChanged((int32)i, 1);
				return;
			}
		}
	}

	/// Reveals an instance: navigates to its owning group, selects its row, scrolls it into
	/// view. Unknown guids no-op.
	public void Reveal(Guid id)
	{
		let instance = Resolve(id);
		if (instance == null)
			return;
		SelectGroup(instance.OwningGroup);
		for (int i < mRows.Count)
		{
			if ((mRows[i].Group == null) && (mRows[i].Id == id))
			{
				let position = (int32)i;
				if (mGridMode)
				{
					mGrid.Selection.Select(position);
					mGrid.ScrollToPosition(position);
				}
				else
				{
					mList.Selection.Select(position);
					mList.ScrollToPosition(position);
				}
				return;
			}
		}
	}

	/// Fills the available space.
	protected override void OnMeasure(BoxConstraints constraints)
	{
		for (int i < ChildCount)
			GetChildAt(i).Measure(constraints);
		MeasuredSize = .(constraints.MaxWidth, constraints.MaxHeight);
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		for (int i < ChildCount)
			GetChildAt(i).Layout(0, 0, width, height);
	}

	// ---- the model -------------------------------------------------------------------------

	private void SelectGroup(Group group)
	{
		mSelectedGroup = group;
		// Group navigation replaces the search scope: a stale filter reads as "my group is
		// empty", since the filter searches all groups.
		if (!mFilter.IsEmpty)
		{
			mFilter.Clear();
			mFilterEdit.SetText("");
		}
		RebuildList();
	}

	private void RebuildList()
	{
		mRows.Clear();
		if (mContext.Project != null)
		{
			if (mFilter.IsEmpty)
			{
				if (mSelectedGroup != null)
				{
					for (let child in mSelectedGroup.Groups)
					{
						var row = Row();
						row.Group = child;
						mRows.Add(row);
					}
					for (let instance in mSelectedGroup.Instances)
					{
						var row = Row();
						row.Id = instance.Id;
						mRows.Add(row);
					}
				}
			}
			else
			{
				CollectFiltered(mContext.Project.SourceDb.RootGroup);
			}
		}
		mList.Selection.ClearSelection();
		mGrid.Selection.ClearSelection();
		mList.NotifyDataChanged();
		mGridAdapter.NotifyDataSetChanged();
		UpdateBreadcrumb();
	}

	private void CollectFiltered(Group group)
	{
		if (group == null)
			return;
		for (let instance in group.Instances)
		{
			if (instance.Name.IndexOf(mFilter, true) >= 0)
			{
				var row = Row();
				row.Id = instance.Id;
				mRows.Add(row);
			}
		}
		for (let child in group.Groups)
			CollectFiltered(child);
	}

	private Row RowAt(int32 position) => ((position >= 0) && (position < mRows.Count)) ? mRows[position] : Row();

	private Instance InstanceAt(int32 position)
	{
		let row = RowAt(position);
		return ((row.Group == null) && row.Id.IsSet) ? Resolve(row.Id) : null;
	}

	/// Borrowed.
	private Drawable RowIcon(int32 position)
	{
		let row = RowAt(position);
		if (row.Group != null)
			return EditorIcons.Folder;
		let instance = row.Id.IsSet ? Resolve(row.Id) : null;
		return (instance != null) ? EditorIcons.ForAssetType(instance.TypeName) : null;
	}

	/// A shared drawable with a reference taken for the view that will consume it.
	private static Drawable Retained(Drawable drawable)
	{
		if (drawable != null)
			drawable.AddRef();
		return drawable;
	}

	/// The name text stays pure, doubling as the inline-rename edit text; the corner dots
	/// carry favourite and export, so the colour always carries the cook status.
	private void RowName(int32 position, String text, ref Color color)
	{
		let row = RowAt(position);
		if (row.Group != null)
		{
			text.Append(row.Group.Name);
			color = .(0.85f, 0.75f, 0.5f, 1.0f);
			return;
		}
		let instance = row.Id.IsSet ? Resolve(row.Id) : null;
		if (instance == null)
			return;
		text.Append(instance.Name);
		switch (mCook.BadgeFor(instance))
		{
		case .Cooked: color = .(0.6f, 0.9f, 0.6f, 1.0f);
		case .Missing: color = .(0.95f, 0.85f, 0.5f, 1.0f);
		case .Failed: color = .(1.0f, 0.45f, 0.45f, 1.0f);
		case .NoBuilder:
		}
	}

	/// The trailing meta label, list mode only: the type and cook badge, badge-coloured.
	private void RowMeta(int32 position, String text, ref Color color)
	{
		let row = RowAt(position);
		if (row.Group != null)
		{
			text.Append("Group");
			return;
		}
		let instance = row.Id.IsSet ? Resolve(row.Id) : null;
		if (instance == null)
			return;
		text.Append(instance.TypeName);
		switch (mCook.BadgeFor(instance))
		{
		case .Cooked:
			text.Append("  [cooked]");
			color = .(0.6f, 0.9f, 0.6f, 1.0f);
		case .Missing:
			text.Append("  [not cooked]");
			color = .(0.95f, 0.85f, 0.5f, 1.0f);
		case .Failed:
			text.Append("  [FAILED]");
			color = .(1.0f, 0.45f, 0.45f, 1.0f);
		case .NoBuilder:
		}
	}

	private Instance Resolve(Guid id) => (mContext.Project != null) ? mContext.Project.SourceDb.GetInstance(id) : null;

	// ---- navigation ------------------------------------------------------------------------

	private void ActivateRow(int32 position, int32 clickCount)
	{
		if (clickCount < 2)
			return;
		let row = RowAt(position);
		if (row.Group != null)
		{
			SelectGroup(row.Group);
			return;
		}
		if (let instance = row.Id.IsSet ? Resolve(row.Id) : null)
		{
			if (OnOpenInstance != null)
				OnOpenInstance(instance);
		}
	}

	/// Root to selected group as clickable segments ("Content / models / fox").
	private void UpdateBreadcrumb()
	{
		let chain = scope List<Group>();
		for (var g = mSelectedGroup; g != null; g = g.Parent)
			chain.Add(g);
		mBreadcrumbGroups.Clear();
		let segments = scope List<StringView>();
		for (int i = chain.Count; i > 0; i--)
		{
			let g = chain[i - 1];
			mBreadcrumbGroups.Add(g);
			segments.Add((g.Parent == null) ? "Content" : g.Name);
		}
		mBreadcrumb.SetSegments(segments);
	}

	private void NavigateToBreadcrumb(int32 segment)
	{
		if ((segment >= 0) && (segment < mBreadcrumbGroups.Count))
			SelectGroup(mBreadcrumbGroups[segment]);
	}

	/// `persist` writes the choice to the per-project editor settings; the initial apply from
	/// saved settings passes false so loading does not immediately re-save.
	private void SetGridMode(bool grid, bool persist = true)
	{
		mGridMode = grid;
		mListToggle.IsChecked.Value = !grid;
		mGridToggle.IsChecked.Value = grid;
		mList.Visibility = grid ? .Gone : .Visible;
		mGrid.Visibility = grid ? .Visible : .Gone;
		Invalidate();
		if (persist)
		{
			if (let store = mContext.ProjectEditorSettings)
			{
				store.Section<EditorAssetBrowserSettings>().GridMode = grid;
				store.MarkChanged<EditorAssetBrowserSettings>();
				mContext.RequestProjectEditorSettingsSave();
			}
		}
	}

	private void ApplySavedViewMode()
	{
		let store = mContext.ProjectEditorSettings;
		if (store == null)
			return; // no project store yet: the default, list
		if (let section = store.Find<EditorAssetBrowserSettings>())
			SetGridMode(section.GridMode, false);
	}
}
