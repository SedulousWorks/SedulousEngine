using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// A component the picker offers: its authored name and category, its type, and what it does
/// for the entity (its type's Description; may be empty).
class ComponentChoice
{
	public String Label = new .() ~ delete _;
	public String Category = new .() ~ delete _;
	public Type Type;
	public String Description = new .() ~ delete _;
}

/// The inspector's Add Component: a picker like the asset and entity pickers rather than a menu
/// of category submenus. A search field at the top; below it the categories, open, each with its
/// components, narrowed as you type to the components whose name, or whose category's, holds the
/// text. The first match is selected, so typing a name and pressing Enter adds it; a double click
/// or Add adds the selected one. Under the list, the selected component's description. The
/// caller hands in the choices (grouped by category, then name) and hears the pick through
/// OnPicked, fired before the dialog closes.
class ComponentPickerDialog : Dialog
{
	/// The component picked. Fired once, before close. Owned.
	public delegate void(Type type) OnPicked ~ delete _;

	private static readonly Color cDimText = .(0.62f, 0.62f, 0.62f, 1.0f);

	/// A category heading (Choice < 0, its components below) or a component.
	private class Node
	{
		public int32 Choice = -1;
		public String Text = new .() ~ delete _;
		public List<int32> Children = new .() ~ delete _;
	}

	private class Adapter : ITreeAdapter
	{
		private ComponentPickerDialog mOwner;

		public this(ComponentPickerDialog owner)
		{
			mOwner = owner;
		}

		private bool InRange(int32 nodeId) => (nodeId >= 0) && (nodeId < mOwner.mNodes.Count);

		public int32 RootCount => (int32)mOwner.mRoots.Count;

		public int32 GetChildCount(int32 nodeId)
		{
			if (nodeId == -1)
				return RootCount;
			return InRange(nodeId) ? (int32)mOwner.mNodes[nodeId].Children.Count : 0;
		}

		public int32 GetChildId(int32 parentId, int32 childIndex)
		{
			if (parentId == -1)
				return ((childIndex >= 0) && (childIndex < RootCount)) ? mOwner.mRoots[childIndex] : -1;
			if (!InRange(parentId))
				return -1;
			let kids = mOwner.mNodes[parentId].Children;
			return ((childIndex >= 0) && (childIndex < kids.Count)) ? kids[childIndex] : -1;
		}

		public int32 GetDepth(int32 nodeId) => (InRange(nodeId) && (mOwner.mNodes[nodeId].Choice >= 0)) ? 1 : 0;
		public bool HasChildren(int32 nodeId) => GetChildCount(nodeId) > 0;

		public View CreateView(int32 viewType)
		{
			let row = new FlexLayout();
			let label = new Label();
			label.FontSize.Value = 12.0f;
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			grow.AlignSelf = .Center;
			row.AddView(label, grow);
			return row;
		}

		public void BindView(View view, int32 nodeId, int32 depth, bool isExpanded)
		{
			let row = view as FlexLayout;
			if ((row == null) || (row.ChildCount == 0) || !InRange(nodeId))
				return;
			let label = row.GetChildAt(0) as Label;
			let node = mOwner.mNodes[nodeId];
			label.SetText(node.Text);
			// Headings quieter than the components they hold.
			label.TextColor.Value = (node.Choice < 0) ? cDimText : (Color?)null;
			row.Padding = .(mOwner.mTree.ContentInset(depth), 0, 0, 0);
		}

		public int32 GetItemViewType(int32 nodeId) => 0;
		public void SetObserver(ITreeAdapterObserver observer) {}
	}

	private List<ComponentChoice> mChoices ~ DeleteContainerAndItems!(_);
	private Adapter mAdapter ~ delete _;
	private List<Node> mNodes = new .() ~ DeleteContainerAndItems!(_);
	private List<int32> mRoots = new .() ~ delete _;
	private int32 mSelected = -1;
	private String mFilter = new .() ~ delete _;
	// Borrowed from the content.
	private EditText mFilterEdit;
	private TreeView mTree;
	private Label mEmptyNote;
	private Label mDescription;

	/// TAKES OWNERSHIP of `choices`, in the order to show them (by category, then name).
	public this(List<ComponentChoice> choices) : base("Add Component")
	{
		mChoices = choices;
		// A fixed size: the list narrows as you type, the dialog does not.
		MinWidth.Value = 380.0f;
		MaxWidth.Value = 380.0f;
		MinHeight.Value = 460.0f;
		MaxHeight.Value = 460.0f;

		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 6;

		mFilterEdit = new EditText();
		mFilterEdit.SetPlaceholder("Search components...");
		mFilterEdit.OnTextChanged.Add(new [=this](edit) =>
			{
				mFilter.Set(edit.Text);
				RebuildTree();
			});
		mFilterEdit.OnSubmit.Add(new [=this](edit) => { Pick(); }); // Enter adds the match
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		column.AddView(mFilterEdit, match);

		mAdapter = new Adapter(this);
		mTree = new TreeView();
		mTree.ItemHeight = 22.0f;
		mTree.SetAdapter(mAdapter);
		mTree.OnItemClick.Add(new [=this](info) =>
			{
				if ((info.NodeId < 0) || (info.NodeId >= mNodes.Count) || (mNodes[info.NodeId].Choice < 0))
					return; // a category heading
				mSelected = info.NodeId;
				ShowDescription();
				if (info.ClickCount >= 2)
					Pick();
			});
		var grow = LayoutStyle();
		grow.Width = SizeSpec.Match();
		grow.FlexGrow = 1.0f;
		column.AddView(mTree, grow);

		mEmptyNote = new Label("No component matches.");
		mEmptyNote.FontSize.Value = 11.0f;
		mEmptyNote.TextColor.Value = cDimText;
		column.AddView(mEmptyNote);
		// The selected component, said in a sentence under the list.
		mDescription = new Label();
		mDescription.FontSize.Value = 11.5f;
		mDescription.WordWrap.Value = true;
		mDescription.TextColor.Value = Color(0.75f, 0.75f, 0.75f, 1.0f);
		var twoLines = LayoutStyle();
		twoLines.Width = SizeSpec.Match();
		twoLines.Height = SizeSpec.Fixed(Unit.Dp(34.0f)); // two lines, steady as it changes
		column.AddView(mDescription, twoLines);
		SetContent(column);

		let add = AddButton("Add", .None);
		add.OnClick.Add(new [=this](b) => { Pick(); });
		AddButton("Cancel", .Cancel);

		RebuildTree();
	}

	public ~this()
	{
		// The tree outlives this body (the content holds it); it must not ask a deleted adapter.
		mTree.SetAdapter(null);
	}

	/// Adds the selected component; with none selected, nothing happens.
	public void Pick()
	{
		let type = SelectedType;
		if (type == null)
			return;
		if (OnPicked != null)
			OnPicked(type);
		Close(.OK);
	}

	/// For tests: the search field, the components shown, the description shown, and the one
	/// Add would add.
	public EditText FilterField => mFilterEdit;

	public int ShownComponentCount
	{
		get
		{
			var count = 0;
			for (let node in mNodes)
				count += (node.Choice >= 0) ? 1 : 0;
			return count;
		}
	}

	public StringView DescriptionText => mDescription.Text.Value;

	public Type SelectedType
	{
		get
		{
			if ((mSelected < 0) || (mSelected >= mNodes.Count))
				return null;
			let choice = mNodes[mSelected].Choice;
			return (choice >= 0) ? mChoices[choice].Type : null;
		}
	}

	private void RebuildTree()
	{
		ClearAndDeleteItems(mNodes);
		mRoots.Clear();
		mSelected = -1;
		// The choices arrive grouped by category: a heading opens each run of them that has a
		// component showing. A category's name finds all of it.
		int32 heading = -1;
		for (int i < mChoices.Count)
		{
			let choice = mChoices[i];
			if (!SearchFilter.TextContains(choice.Label, mFilter) && !SearchFilter.TextContains(choice.Category, mFilter))
				continue;
			if ((heading < 0) || (choice.Category != mNodes[heading].Text))
			{
				let node = new Node();
				node.Text.Set(choice.Category);
				heading = (int32)mNodes.Count;
				mNodes.Add(node);
				mRoots.Add(heading);
			}
			let item = new Node();
			item.Choice = (int32)i;
			item.Text.Set(choice.Label);
			let id = (int32)mNodes.Count;
			mNodes.Add(item);
			mNodes[heading].Children.Add(id);
			if (mSelected < 0)
				mSelected = id; // the first match: Enter adds it
		}
		mEmptyNote.Visibility = mNodes.IsEmpty ? .Visible : .Gone;
		if (let flat = mTree.FlatAdapter)
		{
			for (let root in mRoots)
				flat.Expand(root);
			flat.RebuildVisibleList();
			for (int32 pos < flat.ItemCount)
			{
				if (flat.GetNodeId(pos) == mSelected)
				{
					mTree.Selection.Select(pos);
					mTree.InternalListView.ScrollToPosition(pos);
					break;
				}
			}
		}
		ShowDescription();
	}

	private void ShowDescription()
	{
		let choice = ((mSelected >= 0) && (mSelected < mNodes.Count)) ? mNodes[mSelected].Choice : -1;
		mDescription.SetText((choice >= 0) ? StringView(mChoices[choice].Description) : "");
	}
}
