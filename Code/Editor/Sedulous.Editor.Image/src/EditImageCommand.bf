using System;
using System.Collections;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Image;

/// One undo step of the image page: the asset's binary snapshot before and after,
/// coalesced per key.
class EditImageCommand : EditorCommand
{
	/// Borrowed.
	private ImageEditorPage mPage;
	private String mMergeKey = new .() ~ delete _;
	private List<uint8> mBefore = new .() ~ delete _;
	private List<uint8> mAfter = new .() ~ delete _;

	public this(ImageEditorPage page, StringView mergeKey, Span<uint8> before, Span<uint8> after)
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
	public override StringView TypeId => "edit_image";

	public override bool MergeInto(EditorCommand previous)
	{
		let prev = previous as EditImageCommand;
		if ((prev == null) || (prev.mPage !== mPage) || (prev.mMergeKey != mMergeKey))
			return false;
		prev.mAfter.Clear();
		prev.mAfter.AddRange(mAfter);
		return true;
	}
}
