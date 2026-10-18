using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Fonts;

/// The shaper UI helpers (hit testing, caret positions, selection rectangles) over
/// GlyphPosition clusters, shared by every shaper backend. Clusters count characters, so they
/// hold for any N to M mapping a shaper makes; a backend implements only the shaping.
abstract class ClusterTextShaper : ITextShaper
{
	/// Characters [Start, End) shaped in one font of the request's list, and their UTF-8 bytes.
	protected struct FontRun
	{
		public int Start;
		public int End;
		public int ByteStart;
		public int ByteEnd;
		public uint8 Font;
	}

	/// The text's codepoints, and each one's byte offset, with one more: the text's length.
	protected static void DecodeWithOffsets(StringView text, List<uint32> outCodepoints, List<int> outByteOffsets)
	{
		outCodepoints.Clear();
		outByteOffsets.Clear();
		int index = 0;
		while (index < text.Length)
		{
			outByteOffsets.Add(index);
			outCodepoints.Add(DecodeCodepoint(text, ref index));
		}
		outByteOffsets.Add(text.Length);
	}

	/// A space, a tab, a no-break space, or ASCII digits and punctuation: a character that stays
	/// in the run around it when that run's font has it, so runs do not split at spaces.
	private static bool IsNeutral(uint32 codepoint)
		=> (codepoint == (uint32)' ') || (codepoint == (uint32)'\t') || (codepoint == 0xA0)
			|| ((codepoint >= 0x21) && (codepoint <= 0x40)) || ((codepoint >= 0x5B) && (codepoint <= 0x60))
			|| ((codepoint >= 0x7B) && (codepoint <= 0x7E));

	private static bool FontHas(Span<IFont> fonts, int font, uint32 codepoint)
		=> (fonts[font] != null) && fonts[font].HasGlyph((int32)codepoint);

	/// Runs by font: a character takes the first font of the list that has its glyph (the list is
	/// in order of preference); a neutral one stays in the current run's font when that has it,
	/// so runs do not split at spaces; one no font has stays in the current run.
	protected static void ItemizeByFont(Span<IFont> fonts, List<uint32> codepoints, List<int> byteOffsets,
		List<FontRun> outRuns)
	{
		outRuns.Clear();
		if (codepoints.IsEmpty || fonts.IsEmpty)
			return;

		var run = FontRun();
		for (int i < codepoints.Count)
		{
			int font = run.Font;
			if ((i == 0) || !IsNeutral(codepoints[i]) || !FontHas(fonts, font, codepoints[i]))
			{
				for (int candidate = 0; (candidate < fonts.Length) && (candidate < 256); candidate++)
				{
					if (FontHas(fonts, candidate, codepoints[i]))
					{
						font = candidate;
						break;
					}
				}
			}
			if (i == 0)
			{
				run.Font = (uint8)font;
			}
			else if (font != run.Font)
			{
				run.End = i;
				run.ByteEnd = byteOffsets[i];
				outRuns.Add(run);
				run = FontRun();
				run.Start = i;
				run.ByteStart = byteOffsets[i];
				run.Font = (uint8)font;
			}
		}
		run.End = codepoints.Count;
		run.ByteEnd = byteOffsets[codepoints.Count];
		outRuns.Add(run);
	}

	/// Lays glyphs laid out left to right from `startX` out right to left over the same width,
	/// in drawing order: a right-to-left request to a shaper that only goes left to right.
	protected static void MirrorLine(List<GlyphPosition> glyphs, int first, float startX, float width)
	{
		for (int i = first; i < glyphs.Count; i++)
		{
			var glyph = ref glyphs[i];
			glyph.X = startX + width - (glyph.X - startX) - glyph.Advance;
		}
		for (int a = first, b = glyphs.Count; (a + 1) < b; a++, b--)
			Swap!(glyphs[a], glyphs[b - 1]);
	}

	// All in characters through clusters (GlyphPosition.Cluster), so they hold for any shaper's
	// N to M mapping; under the basic shaper every cluster is one character and one glyph.

	/// Which cluster a point landed on, in a single line of text.
	public override HitTestResult HitTest(IFont font, Span<GlyphPosition> positions, float x, float y)
	{
		if (positions.IsEmpty)
			return .(0, false, false);

		// Before the first character: the caret goes at the start, and it is NOT inside.
		if (x < positions[0].X)
			return .OnCluster(positions[0], false, false);

		for (let position in positions)
		{
			if ((x >= position.X) && (x < (position.X + position.Advance)))
			{
				// Past the middle means the caret belongs after this cluster, which is what
				// makes click to place feel like it went where you pointed.
				let midpoint = position.X + position.Advance * 0.5f;
				return .OnCluster(position, x >= midpoint, true);
			}
		}

		// Past the end: clamped to after the last cluster rather than reported as a miss with
		// no position.
		return .OnCluster(positions[positions.Length - 1], true, false);
	}

	/// The same, over text that has been wrapped: the line is chosen first, then the cluster
	/// within it.
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
			return .OnCluster(positions[positions.Length - 1], true, false, targetLine);

		for (int32 i = lineStart; i <= lineEnd; i++)
		{
			let position = positions[i];
			if ((x >= position.X) && (x < (position.X + position.Advance)))
			{
				let midpoint = position.X + position.Advance * 0.5f;
				return .OnCluster(position, x >= midpoint, true, targetLine);
			}
		}

		if (x < positions[lineStart].X)
			return .OnCluster(positions[lineStart], false, false, targetLine);
		return .OnCluster(positions[lineEnd], true, false, targetLine);
	}

	/// Where a caret sits before a character: the start of its cluster's first glyph; inside a
	/// cluster, the cluster's start; on a character with no glyph (a line break), the end of the
	/// glyph before it; past the end, the end of the last glyph.
	public override float GetCursorPosition(IFont font, Span<GlyphPosition> positions,
		int32 characterIndex)
	{
		if (positions.IsEmpty)
			return 0;
		for (int i < positions.Length)
		{
			let position = positions[i];
			if (position.Cluster < characterIndex)
				continue;
			if ((position.Cluster == characterIndex) || (i == 0))
				return position.X;
			let previous = positions[i - 1];
			return (previous.ClusterEnd <= characterIndex) ? (previous.X + previous.Advance)
				: ClusterStartX(positions, i - 1);
		}
		let last = positions[positions.Length - 1];
		return (characterIndex < last.ClusterEnd) ? ClusterStartX(positions, positions.Length - 1)
			: (last.X + last.Advance);
	}

	/// The x of the first glyph of glyph `index`'s cluster: a mark shares its base's.
	public static float ClusterStartX(Span<GlyphPosition> positions, int index)
	{
		var index;
		while ((index > 0) && (positions[index - 1].Cluster == positions[index].Cluster))
			index--;
		return positions[index].X;
	}

	/// The rectangles to fill for a selection, one per line it spans, over the glyphs whose
	/// clusters fall in the character range.
	public override void GetSelectionRects(IFont font, Span<GlyphPosition> positions,
		SelectionRange selection, float lineHeight, List<FontRect> outRects)
	{
		outRects.Clear();
		if (positions.IsEmpty || selection.IsEmpty)
			return;

		let start = Math.Min(selection.Start, selection.End);
		let end = Math.Max(selection.Start, selection.End);
		var open = false;
		float lineY = 0;
		float rectStartX = 0;
		float rectEndX = 0;
		for (let position in positions)
		{
			if ((position.Cluster < start) || (position.Cluster >= end))
				continue;
			// A change of line closes the current rectangle and starts another.
			if (open && (Abs(position.Y - lineY) > (lineHeight * 0.5f)))
			{
				if (rectEndX > rectStartX)
					outRects.Add(.(rectStartX, lineY, rectEndX - rectStartX, lineHeight));
				open = false;
			}
			if (!open)
			{
				open = true;
				lineY = position.Y;
				rectStartX = position.X;
			}
			rectEndX = position.X + position.Advance;
		}
		if (open && (rectEndX > rectStartX))
			outRects.Add(.(rectStartX, lineY, rectEndX - rectStartX, lineHeight));
	}
}
