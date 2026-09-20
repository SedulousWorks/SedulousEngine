using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.Editor.Scene;

/// The particle tree's adapter over a snapshot: labelled rows, a system row renamable in
/// place, and modules draggable within their own folder. The page and the snapshot are
/// BORROWED.
class ParticleTreeAdapter : IReorderableTreeAdapter
{
	private ParticleEffectEditorPage mOwner;
	private ParticleTreeSnapshot mSnapshot;
	private TreeView mTree = null;

	public this(ParticleEffectEditorPage owner, ParticleTreeSnapshot snapshot)
	{
		mOwner = owner;
		mSnapshot = snapshot;
	}

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

	public View CreateView(int32 viewType)
	{
		let row = new ParticleTreeRow();
		row.FontSize.Value = 12.0f;
		row.Ellipsis.Value = true;
		let owner = mOwner;
		row.OnRenameCommitted.Add(new [=owner, =row](label, newName) =>
			{
				if (row.Kind == .System)
					owner.RenameSystem(row.SystemIndex, newName);
			});
		return row;
	}

	public void BindView(View view, int32 nodeId, int32 depth, bool isExpanded)
	{
		let row = view as ParticleTreeRow;
		if ((row == null) || !mSnapshot.InRange(nodeId))
			return;
		let node = mSnapshot.Nodes[nodeId];
		row.Bind(node.Label, (mTree != null) ? mTree.ContentInset(depth) : 0.0f, node.Kind, node.SystemIndex);
	}

	public int32 GetItemViewType(int32 nodeId) => 0;
	public void SetObserver(ITreeAdapterObserver observer) {}

	/// Only a module over another of the same kind in the same system.
	public bool CanMove(int32 fromPosition, int32 toPosition)
	{
		let flat = (mTree != null) ? mTree.FlatAdapter : null;
		if (flat == null)
			return false;
		let fromNode = flat.GetNodeId(fromPosition);
		let toNode = flat.GetNodeId(toPosition);
		if (!mSnapshot.InRange(fromNode) || !mSnapshot.InRange(toNode))
			return false;
		let a = mSnapshot.Nodes[fromNode];
		let b = mSnapshot.Nodes[toNode];
		return (a.Kind == b.Kind) && (a.SystemIndex == b.SystemIndex) && ((a.Kind == .Initializer) || (a.Kind == .Behavior));
	}

	public void MoveItem(int32 fromPosition, int32 toPosition)
	{
		let flat = (mTree != null) ? mTree.FlatAdapter : null;
		if (flat == null)
			return;
		let fromNode = flat.GetNodeId(fromPosition);
		let toNode = flat.GetNodeId(toPosition);
		if (!mSnapshot.InRange(fromNode) || !mSnapshot.InRange(toNode))
			return;
		let a = mSnapshot.Nodes[fromNode];
		let b = mSnapshot.Nodes[toNode];
		if ((a.Kind != b.Kind) || (a.SystemIndex != b.SystemIndex))
			return;
		mOwner.MoveModule(a.Kind, a.SystemIndex, a.ModuleIndex, b.ModuleIndex);
	}
}
