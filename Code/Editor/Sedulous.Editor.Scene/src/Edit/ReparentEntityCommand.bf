using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Reparents an entity, keeping it where it is in the world. Undo restores the exact old
/// local transform and sibling slot rather than decomposing a world matrix back, so a
/// reparent-undo round trip drifts by nothing.
class ReparentEntityCommand : EditorCommand
{
	private SceneEditContext mCtx;
	private Guid mEntity;
	private Guid mNewParent;
	private Guid mOldParent = .();
	private Guid mOldNextSibling = .();
	private Transform mOldLocal = .();
	private bool mHasOld = false;

	public this(SceneEditContext ctx, Guid entity, Guid newParent)
	{
		mCtx = ctx;
		mEntity = entity;
		mNewParent = newParent;
	}

	public override bool Execute()
	{
		let scene = mCtx.Scene;
		let e = mCtx.Resolve(mEntity);
		if (!e.IsAssigned)
			return false;
		let parent = mCtx.Resolve(mNewParent);
		if ((mNewParent != Guid()) && !parent.IsAssigned)
			return false;
		if ((mNewParent != Guid()) && mCtx.IsSelfOrAncestor(mNewParent, mEntity))
			return false; // a cycle

		if (!mHasOld)
		{
			mOldParent = scene.GetEntityId(scene.GetParent(e));
			mOldNextSibling = scene.GetEntityId(scene.GetNextSibling(e));
			mOldLocal = scene.GetLocalTransform(e);
			mHasOld = true;
		}
		if (mOldParent == mNewParent)
			return false; // already there: no undo pollution
		scene.SetParent(e, parent, true);
		return true;
	}

	public override void Undo()
	{
		let e = mCtx.Resolve(mEntity);
		if (!e.IsAssigned)
			return;
		let scene = mCtx.Scene;
		scene.SetParent(e, mCtx.Resolve(mOldParent));
		let before = mCtx.Resolve(mOldNextSibling);
		if (before.IsAssigned)
			scene.MoveBefore(e, before);
		scene.SetLocalTransform(e, mOldLocal);
	}

	public override StringView TypeId => "reparent_entity";
}
