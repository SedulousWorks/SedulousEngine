using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.Fonts.TrueType;

/// Lays text out, and answers the questions an editable text control asks of a laid out
/// line.
///
/// Stateless: it holds nothing between calls and takes the font it is working with, so one
/// instance serves every font in the process.
class TrueTypeTextShaper : ITextShaper
{
	public override Result<float, FontLoadResult> ShapeText(IFont font, StringView text,
		List<GlyphPosition> outPositions)
		=> ShapeText(font, text, 0, 0, outPositions);

	/// Returns the advance WIDTH, not the end position: a caller measuring a run wants how
	/// wide it is, whatever it started from.
	public override Result<float, FontLoadResult> ShapeText(IFont font, StringView text,
		float startX, float startY, List<GlyphPosition> outPositions)
	{
		outPositions.Clear();
		if (font == null)
			return .Err(.Unknown);

		float x = startX;
		int32 previous = 0;
		int32 index = 0;
		int i = 0;
		while (i < text.Length)
		{
			let codepoint = (int32)DecodeCodepoint(text, ref i);
			let info = font.GetGlyphInfo(codepoint);
			if (previous != 0)
				x += font.GetKerning(previous, codepoint);

			var position = GlyphPosition();
			position.StringIndex = index;
			position.Codepoint = codepoint;
			position.X = x;
			position.Y = startY;
			position.Advance = info.AdvanceWidth;
			position.GlyphInfo = info;
			outPositions.Add(position);

			x += info.AdvanceWidth;
			previous = codepoint;
			index++;
		}
		return .Ok(x - startX);
	}

	/// Wraps to a width, reporting the height the result occupies.
	///
	/// Breaks at the last space where there is one, and REFLOWS what followed it onto the
	/// new line: the glyphs after a break were already placed, and moving them is what
	/// makes the break look like a word wrap rather than a mid word cut. Where there is no
	/// space to break at, it cuts, because a single long word still has to fit somewhere.
	public override Result<void, FontLoadResult> ShapeTextWrapped(IFont font, StringView text,
		float maxWidth, List<GlyphPosition> outPositions, out float outTotalHeight)
	{
		outPositions.Clear();
		outTotalHeight = 0;
		if (font == null)
			return .Err(.Unknown);

		let lineHeight = font.Metrics.LineHeight;
		float x = 0;
		float y = 0;
		int32 previous = 0;
		int32 index = 0;
		/// Where the current line starts, so a break candidate from an earlier line is not
		/// used for this one.
		int32 lineStart = 0;
		int32 lastSpace = -1;
		int i = 0;

		while (i < text.Length)
		{
			let codepoint = (int32)DecodeCodepoint(text, ref i);

			// An explicit newline ends the line wherever it is, and clears the break
			// candidate: a space on the previous line is not one for the next.
			if (codepoint == (int32)'\n')
			{
				y += lineHeight;
				x = 0;
				previous = 0;
				lineStart = index + 1;
				lastSpace = -1;
				index++;
				continue;
			}
			// A carriage return is consumed silently, so CRLF is one break and not two.
			if (codepoint == (int32)'\r')
			{
				index++;
				continue;
			}

			let info = font.GetGlyphInfo(codepoint);
			float kern = (previous != 0) ? font.GetKerning(previous, codepoint) : 0;
			let advancedTo = x + kern + info.AdvanceWidth;

			if (codepoint == (int32)' ')
				lastSpace = (int32)outPositions.Count;

			// `x > 0` guards the case where one glyph is wider than the whole line: it
			// would otherwise wrap forever, placing nothing.
			if ((advancedTo > maxWidth) && (x > 0))
			{
				if ((lastSpace >= lineStart) && (lastSpace >= 0))
				{
					y += lineHeight;
					float reflowX = 0;
					int32 lastReflowed = 0;
					for (int j = lastSpace + 1; j < outPositions.Count; j++)
					{
						var moved = outPositions[j];
						moved.X = reflowX;
						moved.Y = y;
						outPositions[j] = moved;
						reflowX += moved.Advance;
						lastReflowed = moved.Codepoint;
					}
					// Whenever the loop above ran, `lastReflowed` is the glyph that was
					// already `previous`, so this recomputes the same number. It matters
					// only when the reflowed run was EMPTY, which is a break falling right
					// after the space: there is then no preceding glyph on the new line and
					// the kerning against the space is dropped rather than carried over.
					kern = (lastReflowed != 0) ? font.GetKerning(lastReflowed, codepoint) : 0;
					x = reflowX;
					lineStart = lastSpace + 1;
				}
				else
				{
					// Nowhere to break: cut here.
					y += lineHeight;
					x = 0;
					kern = 0;
					lineStart = index;
				}
				lastSpace = -1;
			}

			var position = GlyphPosition();
			position.StringIndex = index;
			position.Codepoint = codepoint;
			position.X = x + kern;
			position.Y = y;
			position.Advance = info.AdvanceWidth;
			position.GlyphInfo = info;
			outPositions.Add(position);

			x += kern + info.AdvanceWidth;
			previous = codepoint;
			index++;
		}

		// The last line counts too, so the height is one more than the breaks taken.
		outTotalHeight = y + lineHeight;
		return .Ok;
	}

	/// Which character a point landed on, in a single line of text.
	public override HitTestResult HitTest(IFont font, Span<GlyphPosition> positions, float x, float y)
	{
		if (positions.IsEmpty)
			return .(0, false, false);

		// Before the first character: the caret goes at the start, and it is NOT inside.
		if (x < positions[0].X)
			return .(0, false, false);

		for (int i < positions.Length)
		{
			let position = positions[i];
			if ((x >= position.X) && (x < (position.X + position.Advance)))
			{
				// Past the middle means the caret belongs after this character, which is
				// what makes click to place feel like it went where you pointed.
				let midpoint = position.X + position.Advance * 0.5f;
				return .((int32)i, x >= midpoint, true);
			}
		}

		// Past the end: clamped to after the last character rather than reported as a miss
		// with no position.
		return .((int32)positions.Length - 1, true, false);
	}

	/// The same, over text that has been wrapped: the line is chosen first, then the
	/// character within it.
	public override HitTestResult HitTestWrapped(IFont font, Span<GlyphPosition> positions,
		float x, float y, float lineHeight)
	{
		if (positions.IsEmpty)
			return .(0, false, false);

		var targetLine = (lineHeight > 0) ? (int32)(y / lineHeight) : 0;
		if (targetLine < 0)
			targetLine = 0;

		int32 lineStart = -1;
		int32 lineEnd = -1;
		float currentLineY = positions[0].Y;
		int32 currentLine = 0;

		for (int i < positions.Length)
		{
			// HALF a line of tolerance: the positions carry the y they were laid out at,
			// and comparing against an exact multiple would miss on any rounding.
			if ((i > 0) && (positions[i].Y > (currentLineY + lineHeight * 0.5f)))
			{
				currentLine++;
				currentLineY = positions[i].Y;
			}

			if (currentLine == targetLine)
			{
				if (lineStart < 0)
					lineStart = (int32)i;
				lineEnd = (int32)i;
			}
			else if (currentLine > targetLine)
			{
				break;
			}
		}

		// A click below the last line lands on no line at all, and answers the very end.
		if (lineStart < 0)
			return .((int32)positions.Length - 1, true, false, targetLine);

		for (int32 i = lineStart; i <= lineEnd; i++)
		{
			let position = positions[i];
			if ((x >= position.X) && (x < (position.X + position.Advance)))
			{
				let midpoint = position.X + position.Advance * 0.5f;
				return .(i, x >= midpoint, true, targetLine);
			}
		}

		if (x < positions[lineStart].X)
			return .(lineStart, false, false, targetLine);
		return .(lineEnd, true, false, targetLine);
	}

	/// Where a caret sits for a character index.
	///
	/// An index PAST the end answers the far side of the last character, which is where the
	/// caret goes at the end of a line; clamping to the last character's left edge instead
	/// would put it one character back.
	public override float GetCursorPosition(IFont font, Span<GlyphPosition> positions,
		int32 characterIndex)
	{
		if (positions.IsEmpty)
			return 0;
		if (characterIndex <= 0)
			return positions[0].X;
		if (characterIndex >= (int32)positions.Length)
		{
			let last = positions[positions.Length - 1];
			return last.X + last.Advance;
		}
		return positions[characterIndex].X;
	}

	/// The rectangles to fill for a selection: one per line it spans.
	public override void GetSelectionRects(IFont font, Span<GlyphPosition> positions,
		SelectionRange selection, float lineHeight, List<FontRect> outRects)
	{
		outRects.Clear();
		if (positions.IsEmpty || selection.IsEmpty)
			return;

		// Clamped to what actually exists: a selection can outlive the text it was made
		// against, and indexing past the end would read rubbish.
		let start = (selection.Start > 0) ? selection.Start : 0;
		let end = (selection.End < (int32)positions.Length) ? selection.End : (int32)positions.Length;
		if (start >= end)
			return;

		float lineY = positions[start].Y;
		float rectStartX = positions[start].X;
		float rectEndX = rectStartX;

		for (int32 i = start; i < end; i++)
		{
			let position = positions[i];
			// A change of line closes the current rectangle and starts another.
			if (Abs(position.Y - lineY) > (lineHeight * 0.5f))
			{
				if (rectEndX > rectStartX)
					outRects.Add(.(rectStartX, lineY, rectEndX - rectStartX, lineHeight));
				lineY = position.Y;
				rectStartX = position.X;
			}
			rectEndX = position.X + position.Advance;
		}

		if (rectEndX > rectStartX)
			outRects.Add(.(rectStartX, lineY, rectEndX - rectStartX, lineHeight));
	}
}
