using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.Fonts.TrueType;

/// The basic shaper: lays text out one glyph per character, with kerning and no
/// substitutions. The questions an editable text control asks of a laid out line come from
/// ClusterTextShaper, which every shaper shares.
///
/// Stateless: it holds nothing between calls and takes the font it is working with, so one
/// instance serves every font in the process.
class TrueTypeTextShaper : ClusterTextShaper
{
	/// One glyph per character: nothing beyond what the codepoints map to.
	public override void CollectReachableGlyphs(IFont font, Span<int32> codepoints, List<int32> outGlyphs)
	{
		outGlyphs.Clear();
	}

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
			position.Cluster = index;
			position.GlyphId = info.GlyphIndex;
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
						lastReflowed = moved.GlyphInfo.Codepoint;
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
			position.Cluster = index;
			position.GlyphId = info.GlyphIndex;
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

	/// Each font run shaped as ShapeText does (no script or language changes what it draws); a
	/// right-to-left run is laid out mirrored, with no joining: the basic shaper's limit.
	protected override Result<float, FontLoadResult> ShapeRun(ShapeRequest request, List<uint32> codepoints,
		List<int> byteOffsets, int start, int end, RunDirection direction, float x, float y,
		List<GlyphPosition> outPositions)
	{
		let sub = scope List<uint32>();
		let subBytes = scope List<int>();
		for (int i = start; i < end; i++)
		{
			sub.Add(codepoints[i]);
			subBytes.Add(byteOffsets[i]);
		}
		subBytes.Add(byteOffsets[end]);
		let runs = scope List<FontRun>();
		ItemizeByFont(request.Fonts, sub, subBytes, runs);

		let first = outPositions.Count;
		var x;
		let startX = x;
		let run = scope List<GlyphPosition>();
		for (let fontRun in runs)
		{
			let font = request.Fonts[fontRun.Font];
			if (font == null)
				continue;
			let text = request.Text.Substring(fontRun.ByteStart, fontRun.ByteEnd - fontRun.ByteStart);
			let advance = ShapeText(font, text, x, y, run);
			if (advance case .Err(let error))
				return .Err(error);
			for (var glyph in run)
			{
				glyph.Cluster += (int32)(start + fontRun.Start);
				glyph.Font = fontRun.Font;
				glyph.RightToLeft = direction == .RightToLeft;
				outPositions.Add(glyph);
			}
			x += advance.Value;
		}
		if (direction == .RightToLeft)
			MirrorLine(outPositions, first, startX, x - startX);
		return .Ok(x - startX);
	}
}
