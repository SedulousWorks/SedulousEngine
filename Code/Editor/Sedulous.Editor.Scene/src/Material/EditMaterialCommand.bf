using System;
using System.Collections;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// One undo step of the material page: the source's binary snapshot before and after,
/// coalesced per row so a slider scrub is one step.
class EditMaterialCommand : EditorCommand
{
	/// Borrowed.
	private MaterialEditorPage mPage;
	private String mMergeKey = new .() ~ delete _;
	private List<uint8> mBefore = new .() ~ delete _;
	private List<uint8> mAfter = new .() ~ delete _;

	public this(MaterialEditorPage page, StringView mergeKey, Span<uint8> before, Span<uint8> after)
	{
		mPage = page;
		mMergeKey.Set(mergeKey);
		mBefore.AddRange(before);
		mAfter.AddRange(after);
	}

	public override bool Execute()
	{
		mPage.ApplySourceBlob(mAfter);
		return true;
	}

	public override void Undo() => mPage.ApplySourceBlob(mBefore);
	public override StringView TypeId => "edit_material";

	public override bool MergeInto(EditorCommand previous)
	{
		let prev = previous as EditMaterialCommand;
		if ((prev == null) || (prev.mPage !== mPage) || (prev.mMergeKey != mMergeKey))
			return false;
		prev.mAfter.Clear();
		prev.mAfter.AddRange(mAfter);
		return true;
	}
}
