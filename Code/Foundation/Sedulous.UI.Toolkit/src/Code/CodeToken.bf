namespace Sedulous.UI.Toolkit;

/// One coloured run inside a line.
///
/// Carries BOTH a byte range and a column, because the two are needed for different things: the
/// bytes to cut the text out of the line, the column to place it, since a monospaced glyph's x
/// is its column times the advance. Recomputing one from the other per token, per frame, would
/// be a UTF-8 walk for every token on screen.
struct CodeToken
{
	public uint32 ByteBegin = 0;
	public uint32 ByteEnd = 0;
	/// The codepoint column the run starts at.
	public int32 Column = 0;
	public CodeTokenKind Kind = .Default;

	public this() {}

	public this(uint32 byteBegin, uint32 byteEnd, int32 column, CodeTokenKind kind)
	{
		ByteBegin = byteBegin;
		ByteEnd = byteEnd;
		Column = column;
		Kind = kind;
	}
}
