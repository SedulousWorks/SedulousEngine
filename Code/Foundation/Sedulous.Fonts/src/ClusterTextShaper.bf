using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Fonts;

/// The shaper UI helpers (hit testing, caret positions, selection rectangles) over
/// GlyphPosition clusters, shared by every shaper backend. Clusters count characters, so they
/// hold for any N to M mapping a shaper makes; a backend implements only the shaping.
abstract class ClusterTextShaper : ITextShaper
{
	/// One line: the text's paragraph levels from the installed bidi resolver (none: one run in
	/// the request's direction), its runs placed in visual order, each shaped by ShapeRun.
	public override Result<float, FontLoadResult> Shape(ShapeRequest request, List<GlyphPosition> outPositions)
	{
		outPositions.Clear();
		let codepoints = scope List<uint32>();
		let bytes = scope List<int>();
		DecodeWithOffsets(request.Text, codepoints, bytes);
		let levels = scope BidiLevels();
		let resolved = ResolveLevels(request.Direction, codepoints, 0, codepoints.Count, levels);
		return ShapeLine(request, codepoints, bytes, 0, codepoints.Count, resolved ? levels : null,
			request.StartX, request.StartY, outPositions);
	}

	/// How a run reads: from its script (Auto), or as bidi resolved it.
	protected enum RunDirection : uint8
	{
		Auto,
		LeftToRight,
		RightToLeft
	}

	/// Shapes characters [start, end) of the request's text as one run, appending its glyphs
	/// from (x, y) in drawing order (a right-to-left run's last character first), each glyph
	/// marked RightToLeft when it reads so. Returns the run's advance.
	protected abstract Result<float, FontLoadResult> ShapeRun(ShapeRequest request, List<uint32> codepoints,
		List<int> byteOffsets, int start, int end, RunDirection direction, float x, float y,
		List<GlyphPosition> outPositions);

	/// The levels of characters [start, end), one paragraph, from the installed resolver,
	/// indexed from `start`; false with none installed.
	protected static bool ResolveLevels(TextDirection baseDirection, List<uint32> codepoints, int start, int end,
		BidiLevels outLevels)
	{
		let resolver = BidiResolverFactory.Resolver;
		if ((resolver == null) || (end <= start))
			return false;
		resolver.Resolve(.(codepoints.Ptr + start, end - start), baseDirection, outLevels);
		return outLevels.Levels.Count == (end - start);
	}

	/// Characters [start, end) laid out on one line from (x, y): with levels (indexed from
	/// `levelBase`), in the visual order of their runs; without, as one run in the request's
	/// direction.
	protected Result<float, FontLoadResult> ShapeLine(ShapeRequest request, List<uint32> codepoints, List<int> bytes,
		int start, int end, BidiLevels levels, float x, float y, List<GlyphPosition> outPositions, int levelBase = 0)
	{
		if (levels == null)
		{
			RunDirection direction;
			switch (request.Direction)
			{
			case .LeftToRight: direction = .LeftToRight;
			case .RightToLeft: direction = .RightToLeft;
			case .Auto: direction = .Auto;
			}
			return ShapeRun(request, codepoints, bytes, start, end, direction, x, y, outPositions);
		}

		let runs = scope List<BidiRun>();
		Bidi.ReorderLine(levels, .(codepoints.Ptr + levelBase, codepoints.Count - levelBase),
			start - levelBase, end - levelBase, runs);
		var x;
		let startX = x;
		for (let run in runs)
		{
			let advance = ShapeRun(request, codepoints, bytes, levelBase + run.Start, levelBase + run.End,
				run.RightToLeft ? .RightToLeft : .LeftToRight, x, y, outPositions);
			if (advance case .Err(let error))
				return .Err(error);
			x += advance.Value;
		}
		return .Ok(x - startX);
	}

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
				return .OnCluster(position, TrailingHalf(position, x), true);
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
				return .OnCluster(position, TrailingHalf(position, x), true, targetLine);
			}
		}

		if (x < positions[lineStart].X)
			return .OnCluster(positions[lineStart], false, false, targetLine);
		return .OnCluster(positions[lineEnd], true, false, targetLine);
	}

	/// Where a caret sits before a character, whatever order the glyphs are drawn in: at the
	/// leading edge of its cluster (left, or right in a right-to-left run); inside a cluster, at
	/// the cluster's; on a character with no glyph (a line break) or past the end, at the
	/// trailing edge of the glyph logically before it.
	public override float GetCursorPosition(IFont font, Span<GlyphPosition> positions,
		int32 characterIndex)
	{
		if (positions.IsEmpty)
			return 0;
		int exact = -1;
		int inside = -1;
		int before = -1;
		int first = 0;
		for (int i < positions.Length)
		{
			let position = positions[i];
			if ((position.Cluster == characterIndex) && (exact < 0))
				exact = i;
			else if ((position.Cluster < characterIndex) && (characterIndex < position.ClusterEnd) && (inside < 0))
				inside = i;
			if ((position.ClusterEnd <= characterIndex)
				&& ((before < 0) || (position.ClusterEnd > positions[before].ClusterEnd)))
				before = i;
			if (position.Cluster < positions[first].Cluster)
				first = i;
		}
		if (exact >= 0)
			return LeadingEdge(positions[exact]);
		if (inside >= 0)
			return LeadingEdge(positions[inside]);
		if (before >= 0)
			return TrailingEdge(positions[before]);
		return LeadingEdge(positions[first]);
	}

	/// Where a glyph's cluster starts on screen: its left, or its right in a right-to-left run.
	public static float LeadingEdge(GlyphPosition glyph) => glyph.RightToLeft ? (glyph.X + glyph.Advance) : glyph.X;
	/// Where a glyph's cluster ends on screen.
	public static float TrailingEdge(GlyphPosition glyph) => glyph.RightToLeft ? glyph.X : (glyph.X + glyph.Advance);

	/// Whether `x` falls in the half of the glyph its cluster ends in.
	public static bool TrailingHalf(GlyphPosition glyph, float x)
	{
		let midpoint = glyph.X + glyph.Advance * 0.5f;
		return glyph.RightToLeft ? (x < midpoint) : (x >= midpoint);
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
