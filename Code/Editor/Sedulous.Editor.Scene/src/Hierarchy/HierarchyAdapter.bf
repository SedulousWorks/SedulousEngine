using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene.Resource;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.Editor.Scene;

/// The hierarchy snapshot as a reorderable tree: drag before a row reorders, drag onto a row
/// reparents, both refused where they would put an entity inside itself.
class HierarchyAdapter : EntityTreeAdapter, IReorderableTreeAdapter
{
	private SceneHierarchyView mOwner;

	public this(SceneHierarchyView owner, EntityTreeSnapshot snapshot) : base(snapshot)
	{
		mOwner = owner;
	}

	public override View CreateView(int32 viewType)
	{
		let row = new HierarchyRow();
		row.FontSize.Value = 12.0f; // the inspector's dense text
		let edit = mOwner.Edit;
		row.OnRenameCommitted.Add(new [=edit, =row](label, newName) =>
		{
			edit.RenameEntity(row.Entity, newName);
		});
		return row;
	}

	public override void BindView(View view, int32 nodeId, int32 depth, bool isExpanded)
	{
		if (!mSnapshot.InRange(nodeId))
			return;
		let row = view as HierarchyRow;
		if (row == null)
			return;
		let node = mSnapshot.Nodes[nodeId];
		let scene = mOwner.Edit.Scene;
		PrefabMemberInfo member = ?;
		let prefabMember = PrefabOverrides.FindMember(scene, node.Id, out member);
		let effectivelyActive = scene.IsEffectivelyActive(scene.FindEntity(node.Id));
		row.Bind(node.Id, node.Name, mOwner.Tree.ContentInset(depth), prefabMember, effectivelyActive);
	}

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
		let edit = mOwner.Edit;
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
		mOwner.Edit.MoveEntityBefore(from, before);
	}

	public bool CanDropInto(int32 fromPosition, int32 toPosition)
	{
		let from = mOwner.GuidAtFlat(fromPosition);
		let to = mOwner.GuidAtFlat(toPosition);
		if ((from == Guid()) || (to == Guid()) || (from == to))
			return false;
		return !mOwner.Edit.IsSelfOrAncestor(to, from); // a target under the source is a cycle
	}

	public void DropInto(int32 fromPosition, int32 toPosition)
	{
		let from = mOwner.GuidAtFlat(fromPosition);
		let to = mOwner.GuidAtFlat(toPosition);
		if ((from != Guid()) && (to != Guid()))
			mOwner.Edit.ReparentEntity(from, to);
	}
}
