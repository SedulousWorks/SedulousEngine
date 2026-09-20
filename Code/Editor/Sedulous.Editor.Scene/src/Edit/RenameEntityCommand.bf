using System;
using Sedulous.Core;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Renames an entity. Consecutive renames of the same entity merge, so typing in the
/// hierarchy's edit box is one undo step back to the ORIGINAL name.
class RenameEntityCommand : EditorCommand
{
	private SceneEditContext mCtx;
	private Guid mEntity;
	private String mNewName = new .() ~ delete _;
	private String mOldName = new .() ~ delete _;
	private bool mHasOld = false;

	public this(SceneEditContext ctx, Guid entity, StringView newName)
	{
		mCtx = ctx;
		mEntity = entity;
		mNewName.Set(newName);
	}

	public override bool Execute()
	{
		let e = mCtx.Resolve(mEntity);
		if (!e.IsAssigned)
			return false;
		if (!mHasOld)
		{
			mOldName.Set(mCtx.Scene.GetEntityName(e));
			mHasOld = true;
		}
		mCtx.Scene.SetEntityName(e, mNewName);
		return true;
	}

	public override void Undo()
	{
		let e = mCtx.Resolve(mEntity);
		if (e.IsAssigned)
			mCtx.Scene.SetEntityName(e, mOldName);
	}

	public override StringView TypeId => "rename_entity";

	public override bool MergeInto(EditorCommand previous)
	{
		let prev = (RenameEntityCommand)previous;
		if (prev.mEntity != mEntity)
			return false;
		prev.mNewName.Set(mNewName); // previous keeps its ORIGINAL old name
		return true;
	}
}
