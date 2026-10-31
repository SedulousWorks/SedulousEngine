using System;

namespace Sedulous.UI;

/// One undo entry, capturing the WHOLE text rather than a delta.
///
/// Snapshots are simpler to get right than deltas, and a text control's contents are small
/// enough that the memory does not matter.
class UndoEntry
{
	public String Text = new .() ~ delete _;
	public int32 CursorPos = 0;
	public int32 AnchorPos = 0;

	public this() {}

	public this(StringView text, int32 cursorPos, int32 anchorPos)
	{
		Text.Set(text);
		CursorPos = cursorPos;
		AnchorPos = anchorPos;
	}
}
