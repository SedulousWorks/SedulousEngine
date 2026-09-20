using System;
using Sedulous.UI;

namespace Sedulous.Editor.Script;

/// The API browser's tree as label rows. The tree and the view are BORROWED.
class ScriptApiTreeAdapter : ITreeAdapter
{
	private ScriptApiTree mTree;
	private TreeView mView = null;

	public this(ScriptApiTree tree)
	{
		mTree = tree;
	}

	public void SetView(TreeView view) => mView = view;

	public int32 RootCount => (int32)mTree.Roots.Count;

	public int32 GetChildCount(int32 nodeId)
	{
		if (nodeId == -1)
			return RootCount;
		return mTree.InRange(nodeId) ? (int32)mTree.Nodes[nodeId].Children.Count : 0;
	}

	public int32 GetChildId(int32 parentId, int32 childIndex)
	{
		if (childIndex < 0)
			return -1;
		if (parentId == -1)
			return (childIndex < RootCount) ? mTree.Roots[childIndex] : -1;
		if (!mTree.InRange(parentId))
			return -1;
		let kids = mTree.Nodes[parentId].Children;
		return (childIndex < kids.Count) ? kids[childIndex] : -1;
	}

	public int32 GetDepth(int32 nodeId) => mTree.InRange(nodeId) ? mTree.Nodes[nodeId].Depth : 0;
	public bool HasChildren(int32 nodeId) => GetChildCount(nodeId) > 0;

	public View CreateView(int32 viewType)
	{
		let row = new FlexLayout();
		let label = new Label();
		label.FontSize.Value = 12.0f;
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		row.AddView(label, grow);
		return row;
	}

	public void BindView(View view, int32 nodeId, int32 depth, bool isExpanded)
	{
		let row = view as FlexLayout;
		if ((row == null) || (row.ChildCount == 0) || !mTree.InRange(nodeId))
			return;
		if (let label = row.GetChildAt(0) as Label)
			label.SetText(mTree.Nodes[nodeId].Label);
		if (mView != null)
			row.Padding = .(mView.ContentInset(depth), 0, 0, 0);
	}

	public int32 GetItemViewType(int32 nodeId) => 0;
	public void SetObserver(ITreeAdapterObserver observer) {}
}
