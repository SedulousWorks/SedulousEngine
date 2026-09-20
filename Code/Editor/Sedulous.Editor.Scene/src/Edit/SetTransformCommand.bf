using System;
using Sedulous.Core;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Sets an entity's local transform. Consecutive sets on one entity merge, so a gizmo drag
/// is one undo step back to where the drag STARTED.
class SetTransformCommand : EditorCommand
{
	private SceneEditContext mCtx;
	private Guid mEntity;
	private Transform mNew;
	private Transform mOld = .();
	private bool mHasOld = false;

	public this(SceneEditContext ctx, Guid entity, Transform transform)
	{
		mCtx = ctx;
		mEntity = entity;
		mNew = transform;
	}

	public override bool Execute()
	{
		let e = mCtx.Resolve(mEntity);
		if (!e.IsAssigned)
			return false;
		if (!mHasOld)
		{
			mOld = mCtx.Scene.GetLocalTransform(e);
			mHasOld = true;
		}
		mCtx.Scene.SetLocalTransform(e, mNew);
		return true;
	}

	public override void Undo()
	{
		let e = mCtx.Resolve(mEntity);
		if (e.IsAssigned)
			mCtx.Scene.SetLocalTransform(e, mOld);
	}

	public override StringView TypeId => "set_transform";

	public override bool MergeInto(EditorCommand previous)
	{
		let prev = (SetTransformCommand)previous;
		if (prev.mEntity != mEntity)
			return false;
		prev.mNew = mNew; // previous keeps its ORIGINAL old transform
		return true;
	}
}
