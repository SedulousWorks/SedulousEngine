using System;
using System.Collections;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Heightfield;

/// One undo step of the heightfield page: the asset's binary snapshot before and after,
/// coalesced per key so a scrub is one step.
class EditHeightfieldCommand : EditorCommand
{
	/// Borrowed.
	private HeightfieldEditorPage mPage;
	private String mMergeKey = new .() ~ delete _;
	private List<uint8> mBefore = new .() ~ delete _;
	private List<uint8> mAfter = new .() ~ delete _;

	public this(HeightfieldEditorPage page, StringView mergeKey, Span<uint8> before, Span<uint8> after)
	{
		mPage = page;
		mMergeKey.Set(mergeKey);
		mBefore.AddRange(before);
		mAfter.AddRange(after);
	}

	public override bool Execute()
	{
		mPage.ApplyBlob(mAfter);
		return true;
	}

	public override void Undo() => mPage.ApplyBlob(mBefore);
	public override StringView TypeId => "edit_heightfield";

	public override bool MergeInto(EditorCommand previous)
	{
		let prev = previous as EditHeightfieldCommand;
		if ((prev == null) || (prev.mPage !== mPage) || (prev.mMergeKey != mMergeKey))
			return false;
		prev.mAfter.Clear();
		prev.mAfter.AddRange(mAfter);
		return true;
	}
}
