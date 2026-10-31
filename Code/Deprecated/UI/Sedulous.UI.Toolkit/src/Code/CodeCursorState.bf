namespace Sedulous.UI.Toolkit;

/// Where the cursor and its anchor were, stored with an undo entry so undoing restores the
/// SELECTION as well as the text. Undoing a replacement that leaves the selection behind puts
/// the user somewhere they did not ask to be.
struct CodeCursorState
{
	public CodePosition Cursor = .();
	public CodePosition Anchor = .();

	public this() {}

	public this(CodePosition cursor, CodePosition anchor)
	{
		Cursor = cursor;
		Anchor = anchor;
	}
}
