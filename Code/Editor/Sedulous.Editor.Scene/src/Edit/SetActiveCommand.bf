using System;
using Sedulous.Core;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Toggles an entity's active flag; setting what is already set is dropped.
class SetActiveCommand : EditorCommand
{
	private SceneEditContext mCtx;
	private Guid mEntity;
	private bool mActive;
	private bool mOld = false;

	public this(SceneEditContext ctx, Guid entity, bool active)
	{
		mCtx = ctx;
		mEntity = entity;
		mActive = active;
	}

	public override bool Execute()
	{
		let e = mCtx.Resolve(mEntity);
		if (!e.IsAssigned)
			return false;
		mOld = mCtx.Scene.IsActive(e);
		if (mOld == mActive)
			return false;
		mCtx.Scene.SetActive(e, mActive);
		return true;
	}

	public override void Undo()
	{
		let e = mCtx.Resolve(mEntity);
		if (e.IsAssigned)
			mCtx.Scene.SetActive(e, mOld);
	}

	public override StringView TypeId => "set_active";
}
