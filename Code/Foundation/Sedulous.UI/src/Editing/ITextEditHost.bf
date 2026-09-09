using System;

namespace Sedulous.UI;

/// How TextEditingBehavior talks to the control hosting it.
///
/// The HOST owns the text, does the font work and fires the events; the behaviour owns the
/// editing logic. Splitting them this way is what lets one behaviour drive a single line box,
/// a password box and a multiline editor without knowing which it is in.
///
/// Injected and held by reference, so it never needs a capability query on the view.
interface ITextEditHost
{
	/// The current content.
	StringView Text { get; }

	/// The longest text allowed, in characters. Nought means unlimited.
	int32 MaxLength { get; }

	bool IsReadOnly { get; }
	bool IsMultiline { get; }

	/// The number of CHARACTERS, not bytes.
	int32 TextCharCount { get; }

	/// Replaces a range. The start and length are CHARACTER indices; the host converts to
	/// byte offsets itself, because only the host knows the encoding of its own buffer.
	void ReplaceText(int32 charStart, int32 charLength, StringView replacement);

	/// Tells the host the content changed, so it can fire events and re-shape.
	void OnTextModified();

	/// The character insertion index at local coordinates.
	int32 HitTestPosition(float localX, float localY);

	/// The same, in GLYPH space, with no padding or scroll applied. Line navigation uses this
	/// because it already knows where the line is and only wants the column.
	int32 HitTestGlyphPosition(float glyphX, float glyphY);

	/// The x pixel position of the cursor at a character index.
	float GetCursorXPosition(int32 charIndex);

	/// The y pixel position, at the top of the line, for a character index.
	float GetCursorYPosition(int32 charIndex);

	float LineHeight { get; }

	/// May be null when there is no clipboard to reach.
	IClipboard Clipboard { get; }

	/// The current time in seconds, used to decide when to coalesce undo entries.
	float CurrentTime { get; }
}
