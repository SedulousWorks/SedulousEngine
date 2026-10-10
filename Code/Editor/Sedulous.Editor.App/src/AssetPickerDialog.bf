using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// A modal, read-only mirror of the asset browser for resource-ref picking: the group tree
/// on the left, matching instances on the right, a filter across all groups. Deliberately not
/// the browser itself: no rename, no delete, no cook actions. Only instances whose type is in
/// the type list are shown (an empty list matches every type); favourites sort first with a
/// * prefix regardless of the selected group; double-click or Select confirms, Clear picks
/// none, Cancel and Escape dismiss. The result is delivered through OnPicked (Empty for
/// cleared) before the dialog closes.
class AssetPickerDialog : Dialog
{
	/// The pick result: an instance id, or Empty for Clear. Fired once, before close. Owned.
	public delegate void(Guid id) OnPicked ~ delete _;

	private class RowAdapter : ListAdapterBase
	{
		private AssetPickerDialog mOwner;

		public this(AssetPickerDialog owner) { mOwner = owner; }

		public override int32 ItemCount => (int32)mOwner.mRows.Count;

		public override View CreateView(int32 viewType)
		{
			let row = new FlexLayout();
			row.Direction = .Horizontal;
			row.Spacing = 6;
			row.Padding = .(4, 2);
			let iconView = new DrawableView();
			iconView.DesiredWidth.Value = 24.0f;
			iconView.DesiredHeight.Value = 24.0f;
			row.AddView(iconView);
			let label = new Label();
			label.FontSize.Value = 12.0f;
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			row.AddView(label, grow);
			return row;
		}

		public override void BindView(View view, int32 position)
		{
			let row = view as FlexLayout;
			if ((row == null) || (row.ChildCount < 2) || (position < 0) || (position >= mOwner.mRows.Count))
				return;
			let iconView = row.GetChildAt(0) as DrawableView;
			let label = row.GetChildAt(1) as Label;
			if ((iconView == null) || (label == null))
				return;
			let instance = mOwner.Resolve(mOwner.mRows[position]);
			if (instance == null)
				return;
			iconView.SetDrawable(mOwner.RetainedIconFor(instance));
			let favorite = mOwner.mContext.IsFavorite(instance.Id);
			let text = scope String();
			if (favorite)
				text.Append("* ");
			// The full path keeps same-named assets across groups distinguishable.
			instance.GetPath(text);
			text.Append("   -   ");
			text.Append(instance.TypeName);
			label.SetText(text);
			label.TextColor.Value = favorite ? Color(1.0f, 0.85f, 0.45f, 1.0f) : Color(0.85f, 0.85f, 0.85f, 1.0f);
		}
	}

	/// A tile: the thumbnail (or the type icon) centred over the name, which truncates.
	private class GridAdapter : ListAdapterBase
	{
		private AssetPickerDialog mOwner;

		public this(AssetPickerDialog owner) { mOwner = owner; }

		public override int32 ItemCount => (int32)mOwner.mRows.Count;

		public override View CreateView(int32 viewType)
		{
			let tile = new FlexLayout();
			tile.Direction = .Vertical;
			tile.Padding = .(4, 4);
			let iconRow = new FlexLayout();
			iconRow.Direction = .Horizontal;
			iconRow.JustifyContent = .Center;
			// Centred on the cross axis too, or the icon stretches to the row's height.
			iconRow.AlignItems = .Center;
			let iconView = new DrawableView();
			iconView.DesiredWidth.Value = 48.0f;
			iconView.DesiredHeight.Value = 48.0f;
			iconRow.AddView(iconView);
			let label = new Label();
			label.FontSize.Value = 12.0f;
			label.HAlign.Value = .Center;
			label.Ellipsis.Value = true;
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			grow.Width = SizeSpec.Match();
			tile.AddView(iconRow, grow);
			var nameStyle = LayoutStyle();
			nameStyle.Width = SizeSpec.Match();
			nameStyle.Height = SizeSpec.Fixed(Unit.Dp(18));
			tile.AddView(label, nameStyle);
			return tile;
		}

		public override void BindView(View view, int32 position)
		{
			let tile = view as FlexLayout;
			if ((tile == null) || (tile.ChildCount < 2) || (position < 0) || (position >= mOwner.mRows.Count))
				return;
			let iconRow = tile.GetChildAt(0) as FlexLayout;
			let label = tile.GetChildAt(1) as Label;
			if ((iconRow == null) || (iconRow.ChildCount < 1) || (label == null))
				return;
			let iconView = iconRow.GetChildAt(0) as DrawableView;
			let instance = mOwner.Resolve(mOwner.mRows[position]);
			if ((iconView == null) || (instance == null))
				return;
			iconView.SetDrawable(mOwner.RetainedIconFor(instance));
			// A tile has room for the name alone; its tooltip carries the path and type the
			// list row shows.
			let favorite = mOwner.mContext.IsFavorite(instance.Id);
			label.SetText(instance.Name);
			label.TextColor.Value = favorite ? Color(1.0f, 0.85f, 0.45f, 1.0f) : Color(0.85f, 0.85f, 0.85f, 1.0f);
			tile.TooltipText.Clear();
			instance.GetPath(tile.TooltipText);
			tile.TooltipText.Append("   -   ");
			tile.TooltipText.Append(instance.TypeName);
		}
	}

	/// Borrowed.
	private EditorContext mContext;
	private List<String> mTypeNames = new .() ~ DeleteContainerAndItems!(_);
	// Borrowed: the content owns them.
	private TreeView mTree;
	private ListView mList;
	private GridView mGrid;
	private ViewModeToggles mViewToggles;
	private EditText mFilterEdit;
	private GroupTreeAdapter mGroups = new .() ~ delete _;
	private RowAdapter mListAdapter ~ delete _;
	private GridAdapter mGridAdapter ~ delete _;
	private bool mGridMode = false;
	private List<Guid> mRows = new .() ~ delete _;
	private Group mSelectedGroup = null;
	private String mFilter = new .() ~ delete _;

	public this(EditorContext context, Span<StringView> assetTypeNames) : base("Select asset")
	{
		mContext = context;
		for (let name in assetTypeNames)
			mTypeNames.Add(new String(name));
		MinWidth.Value = 520.0f;
		MinHeight.Value = 380.0f;
		MaxWidth.Value = 640.0f;
		MaxHeight.Value = 460.0f;

		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 6;

		mFilterEdit = new EditText();
		mFilterEdit.Placeholder.Value.Set("Filter all groups...");
		mFilterEdit.OnTextChanged.Add(new (edit) =>
			{
				mFilter.Set(edit.Text);
				RebuildList();
			});
		{
			// The filter, and the List and Grid toggles beside it.
			let header = new FlexLayout();
			header.Direction = .Horizontal;
			header.Spacing = 6;
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			grow.AlignSelf = .Center;
			header.AddView(mFilterEdit, grow);
			mViewToggles = new ViewModeToggles();
			mViewToggles.OnModeChanged = new (grid) => { SetGridMode(grid); };
			var center = LayoutStyle();
			center.AlignSelf = .Center;
			header.AddView(mViewToggles, center);
			var match = LayoutStyle();
			match.Width = SizeSpec.Match();
			column.AddView(header, match);
		}

		let split = new SplitView();
		split.SplitRatio = 0.32f;
		mTree = new TreeView();
		mTree.ItemHeight = 20.0f;
		mTree.OnItemClick.Add(new (info) =>
			{
				if (let group = mGroups.GroupAt(info.NodeId))
				{
					mSelectedGroup = group;
					RebuildList();
				}
			});
		mListAdapter = new RowAdapter(this);
		mList = new ListView();
		mList.ItemHeight.Value = 28.0f; // rows carry a 24px thumbnail, not a 14px glyph
		mList.SetAdapter(mListAdapter);
		mList.OnItemClicked.Add(new (position, clickCount, x, y) =>
			{
				if (clickCount >= 2)
					ConfirmAt(position);
			});
		mList.OnItemRightClicked.Add(new (position, x, y) => { ShowRowMenu(mList, position, x, y); });
		// The grid: the same rows as tiles, a larger thumbnail over the name.
		mGridAdapter = new GridAdapter(this);
		mGrid = new GridView();
		mGrid.CellWidth.Value = 96.0f;
		mGrid.CellHeight.Value = 84.0f;
		mGrid.Visibility = .Gone;
		mGrid.SetAdapter(mGridAdapter);
		mGrid.OnItemClicked.Add(new (position, clickCount, x, y) =>
			{
				if (clickCount >= 2)
					ConfirmAt(position);
			});
		mGrid.OnItemRightClicked.Add(new (position, x, y) => { ShowRowMenu(mGrid, position, x, y); });
		let results = new FlexLayout();
		results.Direction = .Vertical;
		{
			var fill = LayoutStyle();
			fill.Width = SizeSpec.Match();
			fill.FlexGrow = 1.0f;
			results.AddView(mList, fill);
			results.AddView(mGrid, fill);
		}
		split.SetPanes(mTree, results);
		var grow = LayoutStyle();
		grow.Width = SizeSpec.Match();
		grow.FlexGrow = 1.0f;
		column.AddView(split, grow);
		SetContent(column);

		let select = AddButton("Select", .None);
		select.OnClick.Add(new (b) => { ConfirmAt(SelectedPosition()); });
		let clear = AddButton("Clear", .None);
		clear.OnClick.Add(new (b) =>
			{
				if (OnPicked != null)
					OnPicked(.Empty);
				Close(.OK);
			});
		AddButton("Cancel", .Cancel);

		RebuildModel();
		ApplySavedViewMode();
	}

	public ~this()
	{
		mTree.SetAdapter(null);
		mList.SetAdapter(null);
		mGrid.SetAdapter(null);
	}

	/// The List and Grid toggles beside the filter.
	public ViewModeToggles ViewToggles => mViewToggles;
	public bool IsGridMode => mGridMode;
	/// The rows the dialog offers (instance ids), in the order both views show them.
	public Span<Guid> Rows => mRows;
	public ListView RowList => mList;
	public GridView RowGrid => mGrid;

	/// Shows the rows as a list or as a grid of tiles; `persist` remembers it for the project,
	/// apart from the browser's choice: a picker is often a narrower choice (one asset type),
	/// where tiles of thumbnails read differently.
	public void SetGridMode(bool grid, bool persist = true)
	{
		mGridMode = grid;
		mViewToggles.SetGridMode(grid);
		mList.Visibility = grid ? .Gone : .Visible;
		mGrid.Visibility = grid ? .Visible : .Gone;
		Invalidate();
		if (persist)
		{
			if (let store = mContext.ProjectEditorSettings)
			{
				store.Section<EditorAssetBrowserSettings>().PickerGridMode = grid;
				store.MarkChanged<EditorAssetBrowserSettings>();
				mContext.RequestProjectEditorSettingsSave();
			}
		}
	}

	/// The project's saved picker view, applied without saving it again.
	private void ApplySavedViewMode()
	{
		let store = mContext.ProjectEditorSettings;
		if (store == null)
			return; // no project store yet: the default, list
		if (let section = store.Find<EditorAssetBrowserSettings>())
			SetGridMode(section.PickerGridMode, false);
	}

	/// The selected row in whichever view shows, or -1.
	private int32 SelectedPosition() => mGridMode ? mGrid.Selection.FirstSelected() : mList.Selection.FirstSelected();

	/// The thumbnail, or the type icon until one exists (the browser's pattern), with a
	/// reference taken for the view that will hold it. Get also SCHEDULES a missing thumbnail,
	/// which appears on the next rebind (scroll, filter, reopen): rows are passive re-queriers,
	/// like the inspector's picker slots.
	private Drawable RetainedIconFor(Instance instance)
	{
		Drawable drawable = null;
		if (mContext.Thumbnails != null)
			drawable = mContext.Thumbnails.Get(instance.Id);
		if (drawable == null)
			drawable = EditorIcons.ForAssetType(instance.TypeName);
		if (drawable != null)
			drawable.AddRef();
		return drawable;
	}

	// ---- the model -------------------------------------------------------------------------

	/// An empty filter matches every type: the generic asset page's untyped guid picker.
	private bool TypeMatches(Instance instance)
	{
		if (mTypeNames.IsEmpty)
			return true;
		for (let typeName in mTypeNames)
		{
			if (AssetTypeNames.Matches(instance.TypeName, typeName))
				return true;
		}
		return false;
	}

	private void RebuildModel()
	{
		let root = (mContext.Project != null) ? mContext.Project.SourceDb.RootGroup : null;
		mGroups.Rebuild(root);
		if (mSelectedGroup == null)
			mSelectedGroup = root;
		mGroups.AttachExpanded(mTree);
		RebuildList();
	}

	private void RebuildList()
	{
		mRows.Clear();
		if (mContext.Project != null)
		{
			// Favourites first (matching type, any group), then the scoped or filtered rest.
			for (let id in mContext.Favorites)
			{
				let instance = mContext.Project.SourceDb.GetInstance(id);
				if ((instance != null) && TypeMatches(instance) && MatchesFilter(instance.Name, mFilter))
					mRows.Add(id);
			}
			if (mFilter.IsEmpty)
			{
				if (mSelectedGroup != null)
					CollectGroup(mSelectedGroup, false);
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
	}

	private void CollectGroup(Group group, bool recurse)
	{
		for (let instance in group.Instances)
		{
			if (!TypeMatches(instance) || mContext.IsFavorite(instance.Id))
				continue;
			mRows.Add(instance.Id);
		}
		if (recurse)
		{
			for (let child in group.Groups)
				CollectGroup(child, true);
		}
	}

	private void CollectFiltered(Group group)
	{
		if (group == null)
			return;
		for (let instance in group.Instances)
		{
			if (!TypeMatches(instance) || mContext.IsFavorite(instance.Id))
				continue;
			if (MatchesFilter(instance.Name, mFilter))
				mRows.Add(instance.Id);
		}
		for (let child in group.Groups)
			CollectFiltered(child);
	}

	private static bool MatchesFilter(StringView name, StringView filter)
	{
		return filter.IsEmpty || (name.IndexOf(filter, true) >= 0);
	}

	private Instance Resolve(Guid id) => (mContext.Project != null) ? mContext.Project.SourceDb.GetInstance(id) : null;

	// ---- actions ---------------------------------------------------------------------------

	private void ConfirmAt(int32 position)
	{
		if ((position < 0) || (position >= mRows.Count))
			return;
		let id = mRows[position];
		if (OnPicked != null)
			OnPicked(id);
		Close(.OK);
	}

	/// `source` is the list or the grid the row was right-clicked in.
	private void ShowRowMenu(View source, int32 position, float x, float y)
	{
		if ((position < 0) || (position >= mRows.Count) || (Context == null))
			return;
		let id = mRows[position];
		let menu = new ContextMenu();
		menu.AddItem(mContext.IsFavorite(id) ? "Unpin favorite" : "Pin favorite", new [=id, =this]() =>
			{
				mContext.ToggleFavorite(id);
				RebuildList();
			});
		let screenPos = source.LocalToScreen(.(x, y));
		menu.Show(Context, screenPos.X, screenPos.Y);
		menu.ReleaseRef();
	}
}
