using System;
using Sedulous.Input;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Input;

/// One undo step of the input map page: a deep copy of the whole map before and after.
class InputMapEditCommand : EditorCommand
{
	/// Borrowed.
	private InputMapEditorPage mPage;
	private InputMap mBefore = new .() ~ delete _;
	private InputMap mAfter = new .() ~ delete _;

	/// Copies both maps.
	public this(InputMapEditorPage page, InputMap before, InputMap after)
	{
		mPage = page;
		before.CopyTo(mBefore);
		after.CopyTo(mAfter);
	}

	public override bool Execute()
	{
		mPage.ApplyMap(mAfter);
		return true;
	}

	public override void Undo() => mPage.ApplyMap(mBefore);
	public override StringView TypeId => "input-map-edit";
}
