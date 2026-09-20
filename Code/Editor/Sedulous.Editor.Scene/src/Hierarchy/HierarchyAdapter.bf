using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene.Resource;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.Editor.Scene;

/// The hierarchy snapshot as a reorderable tree: drag before a row reorders, drag onto a row
/// reparents, both refused where they would put an entity inside itself.
class HierarchyAdapter : IReorderableTreeAdapter
{
	private SceneHierarchyView mOwner;

	public this(SceneHierarchyView owner)
	{
		mOwner = owner;
	}

	public int32 RootCount => (int32)mOwner.[Friend]mRoots.Count;

	public int32 GetChildCount(int32 nodeId)
	{
		if (nodeId == -1)
			return RootCount;
		return InRange(nodeId) ? (int32)mOwner.[Friend]mNodes[nodeId].Children.Count : 0;
	}

	public int32 GetChildId(int32 parentId, int32 childIndex)
	{
		if (parentId == -1)
			return ((childIndex >= 0) && (childIndex < RootCount)) ? mOwner.[Friend]mRoots[childIndex] : -1;
		if (!InRange(parentId))
			return -1;
		let kids = mOwner.[Friend]mNodes[parentId].Children;
		return ((childIndex >= 0) && (childIndex < kids.Count)) ? kids[childIndex] : -1;
	}

	public int32 GetDepth(int32 nodeId) => InRange(nodeId) ? mOwner.[Friend]mNodes[nodeId].Depth : 0;
	public bool HasChildren(int32 nodeId) => GetChildCount(nodeId) > 0;

	public View CreateView(int32 viewType)
	{
		let row = new HierarchyRow();
		row.FontSize.Value = 12.0f; // the inspector's dense text
		let edit = mOwner.[Friend]mEdit;
		row.OnRenameCommitted.Add(new [=edit, =row](label, newName) =>
		{
			edit.RenameEntity(row.Entity, newName);
		});
		return row;
	}

	public void BindView(View view, int32 nodeId, int32 depth, bool isExpanded)
	{
		if (!InRange(nodeId))
			return;
		let row = view as HierarchyRow;
		if (row == null)
			return;
		let node = mOwner.[Friend]mNodes[nodeId];
		let scene = mOwner.[Friend]mEdit.Scene;
		PrefabMemberInfo member = ?;
		let prefabMember = PrefabOverrides.FindMember(scene, node.Id, out member);
		let effectivelyActive = scene.IsEffectivelyActive(scene.FindEntity(node.Id));
		row.Bind(node.Id, node.Name, mOwner.Tree.ContentInset(depth), prefabMember, effectivelyActive);
	}

	public int32 GetItemViewType(int32 nodeId) => 0;
	public void SetObserver(ITreeAdapterObserver observer) {}

	public bool CanMove(int32 fromPosition, int32 toPosition)
	{
		let from = mOwner.GuidAtFlat(fromPosition);
		if (from == Guid())
			return false;
		if (toPosition >= mOwner.FlatCount)
			return true; // the end of the root list
		let before = mOwner.GuidAtFlat(toPosition);
		if ((before == Guid()) || (before == from))
			return false;
		let edit = mOwner.[Friend]mEdit;
		let parent = edit.Scene.GetParent(edit.Resolve(before));
		if (parent.IsAssigned && edit.IsSelfOrAncestor(edit.Scene.GetEntityId(parent), from))
			return false;
		return true;
	}

	public void MoveItem(int32 fromPosition, int32 toPosition)
	{
		let from = mOwner.GuidAtFlat(fromPosition);
		if (from == Guid())
			return;
		let before = (toPosition < mOwner.FlatCount) ? mOwner.GuidAtFlat(toPosition) : Guid();
		mOwner.[Friend]mEdit.MoveEntityBefore(from, before);
	}

	public bool CanDropInto(int32 fromPosition, int32 toPosition)
	{
		let from = mOwner.GuidAtFlat(fromPosition);
		let to = mOwner.GuidAtFlat(toPosition);
		if ((from == Guid()) || (to == Guid()) || (from == to))
			return false;
		return !mOwner.[Friend]mEdit.IsSelfOrAncestor(to, from); // a target under the source is a cycle
	}

	public void DropInto(int32 fromPosition, int32 toPosition)
	{
		let from = mOwner.GuidAtFlat(fromPosition);
		let to = mOwner.GuidAtFlat(toPosition);
		if ((from != Guid()) && (to != Guid()))
			mOwner.[Friend]mEdit.ReparentEntity(from, to);
	}

	private bool InRange(int32 nodeId) => (nodeId >= 0) && (nodeId < mOwner.[Friend]mNodes.Count);
}
