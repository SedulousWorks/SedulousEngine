using System;
using System.Collections;

namespace Sedulous.Fonts;

/// Text shaping and layout interface
public interface ITextShaper
{
	/// Shape text and output positioned glyphs
	/// Returns total width of shaped text
	Result<float> ShapeText(IFont font, StringView text, List<GlyphPosition> outPositions);

	/// Shape text with explicit starting position
	Result<float> ShapeText(IFont font, StringView text, float startX, float startY, List<GlyphPosition> outPositions);

	/// Shape multi-line text with word wrapping
	Result<void> ShapeTextWrapped(IFont font, StringView text, float maxWidth, List<GlyphPosition> outPositions, out float totalHeight);

	// === UI Support Methods ===

	/// Hit test: given a pixel position relative to text origin, find the character index
	/// For single-line text (Y is ignored)
	HitTestResult HitTest(IFont font, Span<GlyphPosition> positions, float x, float y);

	/// Hit test for wrapped/multi-line text
	/// Uses lineHeight to determine which line was clicked
	HitTestResult HitTestWrapped(IFont font, Span<GlyphPosition> positions, float x, float y, float lineHeight);

	/// Get the X position for a cursor at the given character index
	/// Index 0 returns position before first character
	/// Index N returns position after last character
	float GetCursorPosition(IFont font, Span<GlyphPosition> positions, int32 characterIndex);

	/// Get rectangles for rendering text selection highlight
	/// Returns one rectangle per line for multi-line selections
	void GetSelectionRects(IFont font, Span<GlyphPosition> positions, SelectionRange selection, float lineHeight, List<Rect> outRects);
}

/// Horizontal text alignment options
public enum TextAlignment
{
	Left,
	Center,
	Right
}

/// Vertical text alignment options
public enum VerticalAlignment
{
	Top,
	Middle,
	Bottom,
	Baseline
}
