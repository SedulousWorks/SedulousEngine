using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Fonts;

/// Turns text into positioned glyphs, and answers the questions an editable text control
/// asks of a laid out line.
abstract class ITextShaper
{
	/// Shapes a request on one line: glyphs in drawing order from (StartX, StartY), each with
	/// its cluster, its glyph id and the font of the list it belongs to. Returns the advance.
	public abstract Result<float, FontLoadResult> Shape(ShapeRequest request, List<GlyphPosition> outPositions);

	/// Lays out from the origin. Returns the total advance width.
	public abstract Result<float, FontLoadResult> ShapeText(IFont font, StringView text,
		List<GlyphPosition> outPositions);

	public abstract Result<float, FontLoadResult> ShapeText(IFont font, StringView text,
		float startX, float startY, List<GlyphPosition> outPositions);

	/// Wraps to a width, reporting the height the result occupies rather than its width,
	/// because the width is now the constraint and the height is the unknown.
	public abstract Result<void, FontLoadResult> ShapeTextWrapped(IFont font, StringView text,
		float maxWidth, List<GlyphPosition> outPositions, out float outTotalHeight);

	public abstract HitTestResult HitTest(IFont font, Span<GlyphPosition> positions, float x, float y);

	public abstract HitTestResult HitTestWrapped(IFont font, Span<GlyphPosition> positions,
		float x, float y, float lineHeight);

	/// Where a caret sits for a character index, which is what draws it and what arrow keys
	/// move between.
	public abstract float GetCursorPosition(IFont font, Span<GlyphPosition> positions, int32 characterIndex);

	/// The rectangles to fill for a selection. Several, because a wrapped selection is one
	/// box per line and the middle lines run the full width.
	public abstract void GetSelectionRects(IFont font, Span<GlyphPosition> positions,
		SelectionRange selection, float lineHeight, List<FontRect> outRects);

	/// The glyphs shaping text of `codepoints` can produce beyond those the codepoints map to
	/// (ligatures, joined and contextual forms), as glyph indices: what a baker adds to an atlas
	/// so the shaped text draws. None for a shaper that maps one character to one glyph.
	public abstract void CollectReachableGlyphs(IFont font, Span<int32> codepoints, List<int32> outGlyphs);
}
