using System;
using System.Collections;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Audio;

/// One undo step of the sound cue page: the asset's binary snapshot before and after,
/// coalesced per key when the key is not empty.
class EditSoundCueCommand : EditorCommand
{
	/// Borrowed.
	private SoundCueEditorPage mPage;
	private String mMergeKey = new .() ~ delete _;
	private List<uint8> mBefore = new .() ~ delete _;
	private List<uint8> mAfter = new .() ~ delete _;

	public this(SoundCueEditorPage page, StringView mergeKey, Span<uint8> before, Span<uint8> after)
	{
		mPage = page;
		mMergeKey.Set(mergeKey);
		mBefore.AddRange(before);
		mAfter.AddRange(after);
	}

	public override bool Execute()
	{
		mPage.ApplyAssetBlob(mAfter);
		return true;
	}

	public override void Undo() => mPage.ApplyAssetBlob(mBefore);
	public override StringView TypeId => "edit_soundcue";

	public override bool MergeInto(EditorCommand previous)
	{
		let prev = previous as EditSoundCueCommand;
		if ((prev == null) || (prev.mPage !== mPage) || mMergeKey.IsEmpty || (prev.mMergeKey != mMergeKey))
			return false;
		prev.mAfter.Clear();
		prev.mAfter.AddRange(mAfter);
		return true;
	}
}
