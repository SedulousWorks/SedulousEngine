using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.UI;

namespace Sedulous.Editor.App;

/// The content-database group hierarchy as a tree adapter: one root (shown as "Content"),
/// each group a node whose id is its index in a depth-first table, parent before children.
/// Shared by the asset picker, the group picker and the create dialog, which all show the
/// same left-hand tree. Rebuild from a root, set it on a TreeView, then ExpandAll.
class GroupTreeAdapter : ITreeAdapter
{
	private struct Node
	{
		public Group Group = null;
		public int32 Depth = 0;
		public List<int32> Children = null;
	}

	private List<Node> mNodes = new .() ~ { for (var n in _) delete n.Children; delete _; };
	/// Borrowed; the tree whose inset the rows follow.
	protected TreeView mTree = null;

	public int Count => mNodes.Count;

	/// The group at a node id, or null.
	public Group GroupAt(int32 nodeId) => InRange(nodeId) ? mNodes[nodeId].Group : null;

	/// Rebuilds the table from a root; null empties it.
	public void Rebuild(Group root)
	{
		for (var n in mNodes)
			delete n.Children;
		mNodes.Clear();
		if (root != null)
			AddGroupNode(root, 0);
	}

	/// Binds the tree the rows are shown in: the adapter is set on it, which reads RootCount
	/// against the now populated table, then every group with children is expanded so the
	/// whole hierarchy is visible.
	public void AttachExpanded(TreeView tree)
	{
		mTree = tree;
		tree.SetAdapter(this);
		if (let flat = tree.FlatAdapter)
		{
			for (int32 i < (int32)mNodes.Count)
			{
				if (!mNodes[i].Children.IsEmpty)
					flat.Expand(i);
			}
		}
	}

	public int32 RootCount => mNodes.IsEmpty ? 0 : 1;

	public int32 GetChildCount(int32 nodeId)
	{
		if (nodeId == -1)
			return RootCount;
		return InRange(nodeId) ? (int32)mNodes[nodeId].Children.Count : 0;
	}

	public int32 GetChildId(int32 parentId, int32 childIndex)
	{
		if (parentId == -1)
			return ((childIndex == 0) && !mNodes.IsEmpty) ? 0 : -1;
		if (!InRange(parentId))
			return -1;
		let kids = mNodes[parentId].Children;
		return ((childIndex >= 0) && (childIndex < kids.Count)) ? kids[childIndex] : -1;
	}

	public int32 GetDepth(int32 nodeId) => InRange(nodeId) ? mNodes[nodeId].Depth : 0;
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
		if ((row == null) || (row.ChildCount == 0) || !InRange(nodeId))
			return;
		let label = row.GetChildAt(0) as Label;
		if (label == null)
			return;
		let name = mNodes[nodeId].Group.Name;
		label.SetText(name.IsEmpty ? "Content" : name);
		// Left-padded past the expander column; ContentInset tracks the tree's indent width
		// so the padding can never drift from the chevron and overlap the text.
		if (mTree != null)
			row.Padding = .(mTree.ContentInset(depth), 0, 0, 0);
	}

	public int32 GetItemViewType(int32 nodeId) => 0;
	public void SetObserver(ITreeAdapterObserver observer) {}

	private bool InRange(int32 nodeId) => (nodeId >= 0) && (nodeId < mNodes.Count);

	private int32 AddGroupNode(Group group, int32 depth)
	{
		let id = (int32)mNodes.Count;
		var node = Node();
		node.Group = group;
		node.Depth = depth;
		node.Children = new List<int32>();
		mNodes.Add(node);
		for (let child in group.Groups)
		{
			let childId = AddGroupNode(child, depth + 1);
			mNodes[id].Children.Add(childId);
		}
		return id;
	}
}
