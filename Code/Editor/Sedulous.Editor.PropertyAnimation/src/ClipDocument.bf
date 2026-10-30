using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.PropertyAnimation;
using Sedulous.PropertyAnimation.Resource;
using Sedulous.PropertyAnimation.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.PropertyAnimation;

/// A property animation clip open for editing (Raptor's editor-gui spec, 5.4, layer 9, part 1): the
/// clip asset read into a clip, its own history and unsaved mark. A clip is an asset of its own, not
/// the scene it animates in, so its edits are not the scene page's steps (the user's ruling: the old
/// panel's edits on the scene page's stack read as the scene's); the mark follows the history, so
/// undoing back to where it was saved clears it.
class ClipDocument
{
	// One step: the whole clip before and after.
	private class Step : EditorCommand
	{
		private ClipDocument mDocument;
		private String mTypeId = new .() ~ delete _;
		private PropertyAnimationClip mBefore ~ delete _;
		private PropertyAnimationClip mAfter ~ delete _;

		/// Takes both clips.
		public this(ClipDocument document, StringView typeId, PropertyAnimationClip before, PropertyAnimationClip after)
		{
			mDocument = document;
			mTypeId.Set(typeId);
			mBefore = before;
			mAfter = after;
		}

		public override bool Execute()
		{
			mDocument.Apply(mAfter);
			return true;
		}

		public override void Undo() => mDocument.Apply(mBefore);

		public override StringView TypeId => mTypeId;
	}

	/// A history the save is no longer on.
	private const int cNeverSaved = -2;

	private EditorContext mContext;
	private PropertyAnimationClip mClip = new .() ~ delete _;
	private Guid mId = .Empty;
	private String mName = new .() ~ delete _;
	private EditorCommandStack mCommands = new .() ~ delete _;
	/// The history's place when last saved (or loaded).
	private int mSavedAt = -1;
	/// A gesture's clip as it began; null while none is open.
	private PropertyAnimationClip mGestureBefore = null ~ delete _;

	/// Told after any change to the clip: an edit, a gesture's preview, an undo, a load.
	public delegate void() OnChanged ~ delete _;

	public this(EditorContext context)
	{
		mContext = context;
		// Told once the history has moved (a step, an undo, a redo), so the unsaved mark it shows is
		// the history's new place, not the one it is leaving.
		mCommands.OnChanged = new [=this] () => { Changed(); };
	}

	public bool HasClip => mId != .Empty;
	public Guid ClipId => mId;
	public StringView Name => mName;
	public bool IsDirty => HasClip && (mCommands.UndoIndex != mSavedAt);
	public PropertyAnimationClip Clip => mClip;
	public EditorCommandStack Commands => mCommands;
	public bool InGesture => mGestureBefore != null;

	/// Its length: the one authored, or its last key's time, whichever is later (at least a second).
	public float Length => Math.Max(Math.Max(mClip.Duration, mClip.ComputeDuration()), 1.0f);

	/// Reads the clip asset `clipId` (its history let go); false when there is no such clip.
	public bool Load(Guid clipId)
	{
		let instance = (mContext.Project != null) ? mContext.Project.SourceDb.GetInstance(clipId) : null;
		let object = (instance != null) ? instance.ReadObject() : null;
		defer delete object;
		let asset = object as PropertyAnimationClipAsset;
		if (asset == null)
			return false;
		CancelGesture();
		let read = scope PropertyAnimationClip();
		asset.Source.FillClip(read);
		read.CopyTo(mClip);
		mId = clipId;
		mName.Set(instance.Name);
		mCommands.Clear();
		mSavedAt = mCommands.UndoIndex;
		Changed();
		return true;
	}

	/// Writes the clip to its asset and asks for a cook; the clip is then saved.
	public Result<void, ErrorCode> Save()
	{
		let instance = (HasClip && (mContext.Project != null)) ? mContext.Project.SourceDb.GetInstance(mId) : null;
		if (instance == null)
			return .Err(.NotFound);
		let asset = scope PropertyAnimationClipAsset();
		PropertyAnimationClipSource.FromClip(mClip, asset.Source);
		if (instance.WriteObject(asset) case .Err(let error))
		{
			GlobalLog(.Warning, "Editor: writing the clip '{}' failed", mName);
			return .Err(error);
		}
		mSavedAt = mCommands.UndoIndex;
		mContext.RequestCook(false);
		Changed(); // the unsaved mark
		return .Ok;
	}

	/// No clip, its history let go.
	public void Close()
	{
		CancelGesture();
		let empty = scope PropertyAnimationClip();
		empty.CopyTo(mClip);
		mId = .Empty;
		mName.Clear();
		mCommands.Clear();
		mSavedAt = mCommands.UndoIndex;
		Changed();
	}

	/// An edit made at once: `mutate` changes the clip, one step (its length grown to its keys).
	public void Edit(StringView typeId, delegate void(PropertyAnimationClip clip) mutate)
	{
		if (!HasClip || InGesture)
			return;
		let before = mClip.Clone();
		mutate(mClip);
		Push(typeId, before);
	}

	/// A gesture: the clip edited live (GestureClip, then PreviewGesture to show it), one step when it
	/// commits; cancelled, the clip as it was.
	public void BeginGesture()
	{
		if (!HasClip)
			return;
		if (InGesture)
			CancelGesture();
		mGestureBefore = mClip.Clone();
	}

	public PropertyAnimationClip GestureClip => mClip;

	public void PreviewGesture() => Changed();

	public void CommitGesture(StringView typeId)
	{
		if (!InGesture)
			return;
		let before = mGestureBefore;
		mGestureBefore = null;
		Push(typeId, before);
	}

	public void CancelGesture()
	{
		if (!InGesture)
			return;
		mGestureBefore.CopyTo(mClip);
		DeleteAndNullify!(mGestureBefore);
		Changed();
	}

	// The clip as it is now after `before` (taken), one step.
	private void Push(StringView typeId, PropertyAnimationClip before)
	{
		// Its length never cuts a key off.
		mClip.Duration = Math.Max(mClip.Duration, mClip.ComputeDuration());
		// A step taken below the save leaves the save off the history: no place is saved now.
		if (mSavedAt > mCommands.UndoIndex)
			mSavedAt = cNeverSaved;
		mCommands.Execute(new Step(this, typeId, before, mClip.Clone()));
	}

	// The history tells, once it has moved.
	private void Apply(PropertyAnimationClip state)
	{
		state.CopyTo(mClip);
	}

	private void Changed()
	{
		if (OnChanged != null)
			OnChanged();
	}
}
