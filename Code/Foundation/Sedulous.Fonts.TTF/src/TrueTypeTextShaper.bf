using System;
using System.Collections;
using Sedulous.Fonts;

namespace Sedulous.Fonts.TTF;

/// Basic text shaper for TrueType fonts
public class TrueTypeTextShaper : ITextShaper
{
	public Result<float> ShapeText(IFont font, StringView text, List<GlyphPosition> outPositions)
	{
		return ShapeText(font, text, 0, 0, outPositions);
	}

	public Result<float> ShapeText(IFont font, StringView text, float startX, float startY, List<GlyphPosition> outPositions)
	{
		outPositions.Clear();

		float x = startX;
		int32 prevCodepoint = 0;
		int32 index = 0;

		for (let c in text.DecodedChars)
		{
			let codepoint = (int32)c;
			let glyphInfo = font.GetGlyphInfo(codepoint);

			// Apply kerning
			if (prevCodepoint != 0)
				x += font.GetKerning(prevCodepoint, codepoint);

			GlyphPosition pos = .(index, codepoint, x, startY, glyphInfo.AdvanceWidth, glyphInfo);
			outPositions.Add(pos);

			x += glyphInfo.AdvanceWidth;
			prevCodepoint = codepoint;
			index++;
		}

		return .Ok(x - startX);
	}

	public Result<void> ShapeTextWrapped(IFont font, StringView text, float maxWidth, List<GlyphPosition> outPositions, out float totalHeight)
	{
		outPositions.Clear();
		totalHeight = 0;

		let lineHeight = font.Metrics.LineHeight;
		float x = 0;
		float y = 0;
		int32 prevCodepoint = 0;
		int32 index = 0;
		int32 lineStartIdx = 0;
		int32 lastSpaceIdx = -1;
		float xAtLastSpace = 0;

		for (let c in text.DecodedChars)
		{
			let codepoint = (int32)c;

			// Handle explicit newlines
			if (codepoint == (int32)'\n')
			{
				y += lineHeight;
				x = 0;
				prevCodepoint = 0;
				lineStartIdx = index + 1;
				lastSpaceIdx = -1;
				index++;
				continue;
			}

			// Skip carriage return
			if (codepoint == (int32)'\r')
			{
				index++;
				continue;
			}

			let glyphInfo = font.GetGlyphInfo(codepoint);

			// Apply kerning
			float kern = 0;
			if (prevCodepoint != 0)
				kern = font.GetKerning(prevCodepoint, codepoint);

			float newX = x + kern + glyphInfo.AdvanceWidth;

			// Track spaces for word wrapping
			if (codepoint == (int32)' ')
			{
				lastSpaceIdx = (int32)outPositions.Count;
				xAtLastSpace = x + kern;
			}

			// Check if we need to wrap
			if (newX > maxWidth && x > 0)
			{
				if (lastSpaceIdx >= lineStartIdx && lastSpaceIdx >= 0)
				{
					// Wrap at last space - reflow glyphs after the space
					y += lineHeight;
					float reflowX = 0;

					// Get the last character that was reflowed (for correct kerning)
					int32 lastReflowedCodepoint = 0;
					for (int32 i = lastSpaceIdx + 1; i < outPositions.Count; i++)
					{
						var pos = ref outPositions[i];
						pos.X = reflowX;
						pos.Y = y;
						reflowX += pos.Advance;
						lastReflowedCodepoint = pos.Codepoint;
					}

					// Recalculate kerning based on the last reflowed character
					if (lastReflowedCodepoint != 0)
						kern = font.GetKerning(lastReflowedCodepoint, codepoint);
					else
						kern = 0; // Nothing was reflowed, start fresh

					x = reflowX;
					lineStartIdx = lastSpaceIdx + 1;
				}
				else
				{
					// No space to break at - hard wrap
					y += lineHeight;
					x = 0;
					kern = 0;
					lineStartIdx = index;
				}
				lastSpaceIdx = -1;
			}

			// Add glyph position
			GlyphPosition pos = .(index, codepoint, x + kern, y, glyphInfo.AdvanceWidth, glyphInfo);
			outPositions.Add(pos);

			x = x + kern + glyphInfo.AdvanceWidth;
			prevCodepoint = codepoint;
			index++;
		}

		totalHeight = y + lineHeight;
		return .Ok;
	}

	// === UI Support Methods ===

	public HitTestResult HitTest(IFont font, Span<GlyphPosition> positions, float x, float y)
	{
		if (positions.Length == 0)
			return HitTestResult(0, false, false);

		// Check if click is before first character
		if (x < positions[0].X)
			return HitTestResult(0, false, false);

		// Linear search through positions
		for (int32 i = 0; i < positions.Length; i++)
		{
			let pos = positions[i];
			let charRight = pos.X + pos.Advance;

			if (x >= pos.X && x < charRight)
			{
				// Found the character - determine leading/trailing edge
				let midpoint = pos.X + pos.Advance * 0.5f;
				let trailing = x >= midpoint;
				return HitTestResult(i, trailing, true);
			}
		}

		// Click is after last character
		return HitTestResult((int32)(positions.Length - 1), true, false);
	}

	public HitTestResult HitTestWrapped(IFont font, Span<GlyphPosition> positions, float x, float y, float lineHeight)
	{
		if (positions.Length == 0)
			return HitTestResult(0, false, false);

		// Determine which line was clicked
		int32 targetLine = (int32)(y / lineHeight);
		if (targetLine < 0) targetLine = 0;

		// Find character range on target line
		int32 lineStart = -1;
		int32 lineEnd = -1;
		float currentLineY = positions[0].Y;
		int32 currentLine = 0;

		for (int32 i = 0; i < positions.Length; i++)
		{
			let pos = positions[i];

			// Detect line change (Y increased significantly)
			if (i > 0 && pos.Y > currentLineY + lineHeight * 0.5f)
			{
				currentLine++;
				currentLineY = pos.Y;
			}

			if (currentLine == targetLine)
			{
				if (lineStart < 0) lineStart = i;
				lineEnd = i;
			}
			else if (currentLine > targetLine)
			{
				break;
			}
		}

		// If no characters on target line, return end of text
		if (lineStart < 0)
			return HitTestResult((int32)(positions.Length - 1), true, false, targetLine);

		// Hit test within the line
		for (int32 i = lineStart; i <= lineEnd; i++)
		{
			let pos = positions[i];
			let charRight = pos.X + pos.Advance;

			if (x >= pos.X && x < charRight)
			{
				let midpoint = pos.X + pos.Advance * 0.5f;
				let trailing = x >= midpoint;
				return HitTestResult(i, trailing, true, targetLine);
			}
		}

		// Click before or after line content
		if (x < positions[lineStart].X)
			return HitTestResult(lineStart, false, false, targetLine);
		else
			return HitTestResult(lineEnd, true, false, targetLine);
	}

	public float GetCursorPosition(IFont font, Span<GlyphPosition> positions, int32 characterIndex)
	{
		if (positions.Length == 0)
			return 0;

		// Cursor before first character
		if (characterIndex <= 0)
			return positions[0].X;

		// Cursor after last character
		if (characterIndex >= positions.Length)
		{
			let lastPos = positions[positions.Length - 1];
			return lastPos.X + lastPos.Advance;
		}

		// Cursor before character at index
		return positions[characterIndex].X;
	}

	public void GetSelectionRects(IFont font, Span<GlyphPosition> positions, SelectionRange selection, float lineHeight, List<Rect> outRects)
	{
		outRects.Clear();

		if (positions.Length == 0 || selection.IsEmpty)
			return;

		int32 startIdx = Math.Max(0, selection.Start);
		int32 endIdx = Math.Min((int32)positions.Length, selection.End);

		if (startIdx >= endIdx)
			return;

		// For single-line text, use full lineHeight as rect height
		// Position at Y=0 relative to the text baseline position
		float rectHeight = lineHeight;

		// Track current line rectangle
		float currentLineY = positions[startIdx].Y;
		float rectStartX = positions[startIdx].X;
		float rectEndX = rectStartX;

		for (int32 i = startIdx; i < endIdx; i++)
		{
			let pos = positions[i];

			// Check for line break (Y changed significantly)
			if (Math.Abs(pos.Y - currentLineY) > lineHeight * 0.5f)
			{
				// Emit rectangle for completed line
				if (rectEndX > rectStartX)
				{
					// Y=0 means top of the line (text is drawn from baseline which is offset by ascent)
					let rect = Rect(rectStartX, currentLineY, rectEndX - rectStartX, rectHeight);
					outRects.Add(rect);
				}

				// Start new line rectangle
				currentLineY = pos.Y;
				rectStartX = pos.X;
			}

			rectEndX = pos.X + pos.Advance;
		}

		// Emit final rectangle
		if (rectEndX > rectStartX)
		{
			let rect = Rect(rectStartX, currentLineY, rectEndX - rectStartX, rectHeight);
			outRects.Add(rect);
		}
	}
}
