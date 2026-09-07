namespace Sedulous.Fonts;

/// A selected range of text, half open as [Start, End).
///
/// NORMALISED on construction, so Start is never past End. A selection dragged backwards
/// carries its direction in the caller's anchor and caret, not here: this type answers
/// "what is selected", which is the same either way round, and normalising once means
/// every consumer is spared the comparison.
struct SelectionRange
{
	public int32 Start = 0;
	public int32 End = 0;

	public this() { Start = 0; End = 0; }

	public this(int32 start, int32 end)
	{
		Start = (start < end) ? start : end;
		End = (start < end) ? end : start;
	}

	public bool IsEmpty => Start == End;
	public int32 Length => End - Start;

	/// Half open, so the character AT End is not selected. That is what makes an empty
	/// selection at a caret contain nothing.
	public bool Contains(int32 index) => (index >= Start) && (index < End);

	/// From a drag: where it started and where the caret is now, in either order.
	public static SelectionRange FromAnchorActive(int32 anchor, int32 active) => .(anchor, active);
}
