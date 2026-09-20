using System;
using Sedulous.UI;

namespace Sedulous.Editor.Scene;

/// An entity snapshot as a tree adapter: label rows, indented past the expander. The
/// snapshot and the tree are BORROWED. Subclasses override the row views.
class EntityTreeAdapter : ITreeAdapter
{
	protected EntityTreeSnapshot mSnapshot;
	protected TreeView mTree = null;

	public this(EntityTreeSnapshot snapshot)
	{
		mSnapshot = snapshot;
	}

	/// The tree whose inset the rows follow.
	public void SetTree(TreeView tree) => mTree = tree;

	public int32 RootCount => (int32)mSnapshot.Roots.Count;

	public int32 GetChildCount(int32 nodeId)
	{
		if (nodeId == -1)
			return RootCount;
		return mSnapshot.InRange(nodeId) ? (int32)mSnapshot.Nodes[nodeId].Children.Count : 0;
	}

	public int32 GetChildId(int32 parentId, int32 childIndex)
	{
		if (parentId == -1)
			return ((childIndex >= 0) && (childIndex < RootCount)) ? mSnapshot.Roots[childIndex] : -1;
		if (!mSnapshot.InRange(parentId))
			return -1;
		let kids = mSnapshot.Nodes[parentId].Children;
		return ((childIndex >= 0) && (childIndex < kids.Count)) ? kids[childIndex] : -1;
	}

	public int32 GetDepth(int32 nodeId) => mSnapshot.InRange(nodeId) ? mSnapshot.Nodes[nodeId].Depth : 0;
	public bool HasChildren(int32 nodeId) => GetChildCount(nodeId) > 0;

	public virtual View CreateView(int32 viewType)
	{
		let row = new FlexLayout();
		let label = new Label();
		label.FontSize.Value = 12.0f;
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		row.AddView(label, grow);
		return row;
	}

	public virtual void BindView(View view, int32 nodeId, int32 depth, bool isExpanded)
	{
		let row = view as FlexLayout;
		if ((row == null) || (row.ChildCount == 0) || !mSnapshot.InRange(nodeId))
			return;
		let label = row.GetChildAt(0) as Label;
		if (label == null)
			return;
		label.SetText(mSnapshot.Nodes[nodeId].Name);
		if (mTree != null)
			row.Padding = .(mTree.ContentInset(depth), 0, 0, 0);
	}

	public int32 GetItemViewType(int32 nodeId) => 0;
	public void SetObserver(ITreeAdapterObserver observer) {}
}
