using System;
using Sedulous.Input;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Input;

/// One undo step of the input map page: a deep copy of the whole map before and after. A
/// field's edits carry the field as their merge key and fold into the edit before them on the
/// same field, so dragging a value is one step.
class InputMapEditCommand : EditorCommand
{
	/// Borrowed.
	private InputMapEditorPage mPage;
	private InputMap mBefore = new .() ~ delete _;
	private InputMap mAfter = new .() ~ delete _;
	/// Empty: never merges.
	private String mMergeKey = new .() ~ delete _;

	/// Copies both maps.
	public this(InputMapEditorPage page, InputMap before, InputMap after, StringView mergeKey = "")
	{
		mPage = page;
		before.CopyTo(mBefore);
		after.CopyTo(mAfter);
		mMergeKey.Set(mergeKey);
	}

	public override bool Execute()
	{
		mPage.ApplyMap(mAfter);
		return true;
	}

	public override void Undo() => mPage.ApplyMap(mBefore);
	public override StringView TypeId => "input-map-edit";

	public override bool MergeInto(EditorCommand previous)
	{
		let earlier = previous as InputMapEditCommand;
		if ((earlier == null) || mMergeKey.IsEmpty || (earlier.mMergeKey != mMergeKey))
			return false;
		mAfter.CopyTo(earlier.mAfter);
		return true;
	}
}
