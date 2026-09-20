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
			// The thumbnail wins; the type icon shows until one exists. Get also schedules
			// a missing thumbnail, which appears on the next rebind: rows are passive
			// re-queriers, like the inspector's picker slots.
			Drawable drawable = null;
			if (mOwner.mContext.Thumbnails != null)
				drawable = mOwner.mContext.Thumbnails.Get(instance.Id);
			if (drawable == null)
				drawable = EditorIcons.ForAssetType(instance.TypeName);
			if (drawable != null)
				drawable.AddRef();
			iconView.SetDrawable(drawable);
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

	/// Borrowed.
	private EditorContext mContext;
	private List<String> mTypeNames = new .() ~ DeleteContainerAndItems!(_);
	// Borrowed: the content owns them.
	private TreeView mTree;
	private ListView mList;
	private EditText mFilterEdit;
	private GroupTreeAdapter mGroups = new .() ~ delete _;
	private RowAdapter mListAdapter ~ delete _;
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
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		column.AddView(mFilterEdit, match);

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
		mList.OnItemRightClicked.Add(new (position, x, y) => { ShowRowMenu(position, x, y); });
		split.SetPanes(mTree, mList);
		var grow = LayoutStyle();
		grow.Width = SizeSpec.Match();
		grow.FlexGrow = 1.0f;
		column.AddView(split, grow);
		SetContent(column);

		let select = AddButton("Select", .None);
		select.OnClick.Add(new (b) => { ConfirmAt(mList.Selection.FirstSelected()); });
		let clear = AddButton("Clear", .None);
		clear.OnClick.Add(new (b) =>
			{
				if (OnPicked != null)
					OnPicked(.Empty);
				Close(.OK);
			});
		AddButton("Cancel", .Cancel);

		RebuildModel();
	}

	public ~this()
	{
		mTree.SetAdapter(null);
		mList.SetAdapter(null);
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
		mList.NotifyDataChanged();
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

	private void ShowRowMenu(int32 position, float x, float y)
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
		let screenPos = mList.LocalToScreen(.(x, y));
		menu.Show(Context, screenPos.X, screenPos.Y);
		menu.ReleaseRef();
	}
}
