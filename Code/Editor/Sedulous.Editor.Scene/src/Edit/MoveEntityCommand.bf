using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Sibling reordering: puts an entity immediately before `sibling`, under the sibling's
/// parent, or at the end of the root list when the sibling is nil. The world transform is
/// kept only when the parent actually changes; a pure reorder leaves the local alone. A move
/// that changes nothing is dropped, told by the scene's revision.
class MoveEntityCommand : EditorCommand
{
	private SceneEditContext mCtx;
	private Guid mEntity;
	private Guid mSibling;
	private Guid mOldParent = .();
	private Guid mOldNext = .();
	private Transform mOldLocal = .();
	private bool mHasOld = false;

	public this(SceneEditContext ctx, Guid entity, Guid sibling)
	{
		mCtx = ctx;
		mEntity = entity;
		mSibling = sibling;
	}

	public override bool Execute()
	{
		let scene = mCtx.Scene;
		let e = mCtx.Resolve(mEntity);
		if (!e.IsAssigned)
			return false;
		let sibling = mCtx.Resolve(mSibling);
		if ((mSibling != Guid()) && !sibling.IsAssigned)
			return false;
		if (mSibling == mEntity)
			return false;
		if (sibling.IsAssigned)
		{
			// The slot's parent inside the moving subtree would be a cycle.
			let parent = scene.GetParent(sibling);
			if (parent.IsAssigned && mCtx.IsSelfOrAncestor(scene.GetEntityId(parent), mEntity))
				return false;
		}

		if (!mHasOld)
		{
			mOldParent = scene.GetEntityId(scene.GetParent(e));
			mOldNext = scene.GetEntityId(scene.GetNextSibling(e));
			mOldLocal = scene.GetLocalTransform(e);
			mHasOld = true;
		}

		let newParent = sibling.IsAssigned ? scene.GetParent(sibling) : EntityHandle.Invalid;
		let parentChanges = scene.GetEntityId(newParent) != mOldParent;

		let before = scene.Revision;
		if (sibling.IsAssigned)
			scene.MoveBefore(e, sibling, parentChanges);
		else
			scene.SetParent(e, .Invalid, parentChanges);
		return scene.Revision != before;
	}

	public override void Undo()
	{
		let scene = mCtx.Scene;
		let e = mCtx.Resolve(mEntity);
		if (!e.IsAssigned)
			return;
		let oldNext = mCtx.Resolve(mOldNext);
		if (oldNext.IsAssigned)
			scene.MoveBefore(e, oldNext);
		else
			scene.SetParent(e, mCtx.Resolve(mOldParent)); // was last: append
		scene.SetLocalTransform(e, mOldLocal);
	}

	public override StringView TypeId => "move_entity";
}
