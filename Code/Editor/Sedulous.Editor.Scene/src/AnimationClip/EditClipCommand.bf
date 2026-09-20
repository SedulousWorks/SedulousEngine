using System;
using System.Collections;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// One undo step of the clip page: the asset's binary snapshot before and after, coalesced
/// per key so a scrub is one step.
class EditClipCommand : EditorCommand
{
	/// Borrowed.
	private AnimationClipEditorPage mPage;
	private String mMergeKey = new .() ~ delete _;
	private List<uint8> mBefore = new .() ~ delete _;
	private List<uint8> mAfter = new .() ~ delete _;

	public this(AnimationClipEditorPage page, StringView mergeKey, Span<uint8> before, Span<uint8> after)
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
	public override StringView TypeId => "edit_animclip";

	public override bool MergeInto(EditorCommand previous)
	{
		let prev = previous as EditClipCommand;
		if ((prev == null) || (prev.mPage !== mPage) || (prev.mMergeKey != mMergeKey))
			return false;
		prev.mAfter.Clear();
		prev.mAfter.AddRange(mAfter);
		return true;
	}
}
