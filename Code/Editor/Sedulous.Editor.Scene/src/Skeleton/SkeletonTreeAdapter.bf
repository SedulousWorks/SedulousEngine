using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Animation;

namespace Sedulous.Editor.Scene;

/// The bone tree's adapter: label rows named from the live skeleton, never reorderable. The
/// snapshot, the tree and the skeleton source are BORROWED.
class SkeletonTreeAdapter : IReorderableTreeAdapter
{
	private SkeletonTreeSnapshot mSnapshot;
	private TreeView mTree = null;
	/// The skeleton the rows name, refreshed by the page as the product reloads.
	private Skeleton mSkeleton = null;

	public this(SkeletonTreeSnapshot snapshot)
	{
		mSnapshot = snapshot;
	}

	public void SetTree(TreeView tree) => mTree = tree;
	public void SetSkeleton(Skeleton skeleton) => mSkeleton = skeleton;

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

	public View CreateView(int32 viewType)
	{
		let row = new FlexLayout();
		let label = new Label();
		label.FontSize.Value = 12.0f;
		label.Ellipsis.Value = true;
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		row.AddView(label, grow);
		return row;
	}

	public void BindView(View view, int32 nodeId, int32 depth, bool isExpanded)
	{
		let row = view as FlexLayout;
		if ((row == null) || (row.ChildCount == 0) || !mSnapshot.InRange(nodeId))
			return;
		let label = row.GetChildAt(0) as Label;
		if (label == null)
			return;
		let bone = (mSkeleton != null) ? mSkeleton.GetBone(mSnapshot.Nodes[nodeId].BoneIndex) : null;
		label.SetText((bone != null) ? bone.Name : "?");
		if (mTree != null)
			row.Padding = .(mTree.ContentInset(depth), 0, 0, 0);
	}

	public int32 GetItemViewType(int32 nodeId) => 0;
	public void SetObserver(ITreeAdapterObserver observer) {}
	public bool CanMove(int32 fromPosition, int32 toPosition) => false;
	public void MoveItem(int32 fromPosition, int32 toPosition) {}
}
