using System;

namespace Sedulous.UI.Toolkit;

/// A place in a buffer, zero based.
///
/// The column counts CODEPOINTS rather than bytes, because everything a user does is in
/// characters: arrow keys, selections, the column readout. Bytes appear only where the buffer
/// itself is touched, and the document converts at that boundary.
struct CodePosition
{
	public int32 Line = 0;
	public int32 Column = 0;

	public this() {}

	public this(int32 line, int32 column)
	{
		Line = line;
		Column = column;
	}

	[Commutable]
	public static bool operator==(CodePosition a, CodePosition b) =>
		(a.Line == b.Line) && (a.Column == b.Column);

	/// Document ORDER: earlier lines first, then earlier columns.
	public static bool operator<(CodePosition a, CodePosition b) =>
		(a.Line != b.Line) ? (a.Line < b.Line) : (a.Column < b.Column);

	public static bool operator<=(CodePosition a, CodePosition b) => !(b < a);
}
