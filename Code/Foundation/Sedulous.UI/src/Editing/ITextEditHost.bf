namespace Sedulous.UI;

using System;

/// Interface that TextEditingBehavior uses to interact with its host control.
/// The host owns the text, handles font/shaping, and fires events.
public interface ITextEditHost
{
	/// The current text content (read-only view).
	StringView Text { get; }

	/// The maximum allowed text length in characters (0 = unlimited).
	int32 MaxLength { get; }

	/// Whether the control is read-only.
	bool IsReadOnly { get; }

	/// Whether multiline editing is enabled.
	bool IsMultiline { get; }

	/// The number of characters in the text (not bytes).
	int32 TextCharCount { get; }

	/// Replace a range of characters. charStart and charLength are
	/// character indices, not byte offsets. The host converts internally.
	void ReplaceText(int32 charStart, int32 charLength, StringView replacement);

	/// Notify the host that text content has changed (fire events, re-shape).
	void OnTextModified();

	/// Hit-test: return the character insertion index at local coordinates
	/// (relative to the control's bounds, including padding).
	int32 HitTestPosition(float localX, float localY);

	/// Hit-test in glyph space (no padding/scroll adjustment).
	/// Used by TextEditingBehavior for Up/Down line navigation.
	int32 HitTestGlyphPosition(float glyphX, float glyphY);

	/// Get the X pixel position of the cursor at the given character index.
	float GetCursorXPosition(int32 charIndex);

	/// Get the Y pixel position (top of line) for the given character index.
	/// Used for Up/Down arrow navigation in multiline mode.
	float GetCursorYPosition(int32 charIndex);

	/// Get the line height in pixels.
	float LineHeight { get; }

	/// Get clipboard (may return null).
	IClipboard Clipboard { get; }

	/// Get current time in seconds (for undo coalescing).
	float CurrentTime { get; }
}
