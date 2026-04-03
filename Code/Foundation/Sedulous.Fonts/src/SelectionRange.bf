using System;

namespace Sedulous.Fonts;

/// Represents a text selection range
public struct SelectionRange
{
	/// Start character index (inclusive)
	public int32 Start;
	/// End character index (exclusive)
	public int32 End;

	public this()
	{
		Start = 0;
		End = 0;
	}

	public this(int32 start, int32 end)
	{
		// Normalize so Start <= End
		Start = Math.Min(start, end);
		End = Math.Max(start, end);
	}

	/// Whether the selection is empty (no characters selected)
	public bool IsEmpty => Start == End;

	/// Number of characters in the selection
	public int32 Length => End - Start;

	/// Create from anchor and active cursor positions
	/// Handles reversed selection (when user drags backwards)
	public static SelectionRange FromAnchorActive(int32 anchor, int32 active)
	{
		return .(Math.Min(anchor, active), Math.Max(anchor, active));
	}

	/// Check if a character index is within this selection
	public bool Contains(int32 index)
	{
		return index >= Start && index < End;
	}
}
