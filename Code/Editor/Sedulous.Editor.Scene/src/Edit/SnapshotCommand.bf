using System;
using Sedulous.Core;
using Sedulous.Scene.Resource;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// A change no finer command describes (reverting a prefab instance, applying one to its prefab),
/// run as one step between two snapshots of the whole scene: Undo restores the one before, Redo the
/// one after, each in place (guids kept, so the selection and the pages' references hold).
///
/// The change runs once, on the first Execute, and is not kept. `undone` and `redone`, owned, run
/// after a restore to put back what lives outside the scene (the prefab asset).
class SnapshotCommand : EditorCommand
{
	private SceneEditContext mCtx;
	private String mTypeId = new .() ~ delete _;
	private delegate bool() mChange; // borrowed, for the first Execute only
	private delegate void() mUndone ~ delete _;
	private delegate void() mRedone ~ delete _;
	private SceneSnapshot mBefore ~ delete _;
	private SceneSnapshot mAfter ~ delete _;

	public this(SceneEditContext ctx, StringView typeId, delegate bool() change, delegate void() undone,
		delegate void() redone)
	{
		mCtx = ctx;
		mTypeId.Set(typeId);
		mChange = change;
		mUndone = undone;
		mRedone = redone;
	}

	public override bool Execute()
	{
		let scene = mCtx.Scene;
		if (mAfter != null) // redo
		{
			Restore(mAfter);
			if (mRedone != null)
				mRedone();
			return true;
		}
		if (mChange == null)
			return false;
		let change = mChange;
		mChange = null;
		mBefore = SceneSnapshot.Capture(scene);
		if ((mBefore == null) || !change())
			return false;
		mAfter = SceneSnapshot.Capture(scene);
		return mAfter != null;
	}

	public override void Undo()
	{
		Restore(mBefore);
		if (mUndone != null)
			mUndone();
	}

	public override StringView TypeId => mTypeId;

	private void Restore(SceneSnapshot snapshot)
	{
		snapshot.Restore(mCtx.Scene).IgnoreError();
		mCtx.ResolveRestoredResources();
	}
}
