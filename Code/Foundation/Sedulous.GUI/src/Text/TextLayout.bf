using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// The inline formatter: lays a TextDocument's runs into lines. Text breaks after spaces and at line
// breaks, runs of different sizes share a baseline (each line as tall as its tallest run, or as the
// line height says), an icon sits on the baseline as tall as its run's text is big, and each line
// aligns on its own. What comes out is positioned glyphs per run, underlines, icon rectangles and
// link rectangles, in the layout's own coordinates; the widget draws them.
//
// A run that sets no font of its own draws in the style's font (the label's). One that sets a family,
// a size, bold or italic asks the font service; bold and italic take the family's "<family> Bold",
// "<family> Italic" or "<family> Bold Italic" face when one is loaded, and are synthesized when not
// (bold drawn twice a little apart, italic slanted), as browsers do. With no service, such a run
// draws in the style's font, its bold and italic synthesized. A character a run's face lacks takes
// the first of the style's fallback families that has it (the rest of a font-family list): a piece
// is measured in its faces' stretches, shaped with the whole list, and its glyphs come out as one
// run per face.
//
// Copied from foundation.ui's text layout, and the GUI's own from then on. The GUI adds what CSS's
// text properties need: a line height, letter spacing, a clamp on the line count and an ellipsis at
// a line's end, start or middle (text-overflow), and what editing needs: every glyph and line knows
// the bytes of the plain text it shows, so a caret finds its x and a point its offset. A font with
// no shaper still measures; its pieces come out as text to draw unshaped, each character placed by
// measuring (they take no ellipsis).
//
// A layout owns its lists (a glyph run its glyphs), and the style its family names; both are
// classes with a deep Set, as the middle ellipsis and a Text's cache copy them.

enum TextHAlign
{
	Left,
	Center,
	Right,
	/// The line's start: left, or right in a right-to-left paragraph.
	Start,
	/// The line's end.
	End,
}

enum TextVAlign
{
	Top,
	Middle,
	Bottom
}

/// CSS's white-space: whether spaces and line breaks collapse, and whether lines wrap.
enum TextWhiteSpace : uint8
{
	/// Collapse; wrap.
	Normal,
	/// Collapse; one line unless the text breaks it.
	NoWrap,
	/// Keep; break only where the text does.
	Pre,
	/// Keep; wrap.
	PreWrap,
}

/// CSS's text-overflow, with the GUI's start and middle ellipses (for paths).
enum TextOverflow : uint8
{
	Clip,
	/// "Long text that…"
	Ellipsis,
	/// "…the end of it"
	EllipsisStart,
	/// "/home/…/file.txt"
	EllipsisMiddle
}

/// What CSS chooses of a font past its family and size: the families a character the font lacks
/// falls back to, the weight and the style.
class FontSelection : IEquatable<FontSelection>
{
	/// The rest of a font-family list (comma separated), in order.
	public String FallbackFamilies = new .() ~ delete _;
	/// 100 to 900, CSS's font-weight.
	public uint16 Weight = 400;
	public bool Italic = false;

	/// Whether it chooses nothing past the family: no fallbacks, the normal weight, upright.
	public bool IsDefault => FallbackFamilies.IsEmpty && (Weight == 400) && !Italic;

	/// Makes this a copy of `other`.
	public void Set(FontSelection other)
	{
		if (other === this)
			return;
		FallbackFamilies.Set(other.FallbackFamilies);
		Weight = other.Weight;
		Italic = other.Italic;
	}

	public bool Equals(FontSelection other) => (FallbackFamilies == other.FallbackFamilies) && (Weight == other.Weight) && (Italic == other.Italic);
}

/// Which way a text's paragraphs run: one way, or (Auto) each as its first strong character reads,
/// one with none as `AutoRightToLeft` says (its node's way).
struct ParagraphDirection : IEquatable<ParagraphDirection>
{
	public TextDirection Direction = .LeftToRight;
	public bool AutoRightToLeft = false;

	public this() { }

	public this(TextDirection direction, bool autoRightToLeft)
	{
		Direction = direction;
		AutoRightToLeft = autoRightToLeft;
	}

	public bool Equals(ParagraphDirection other) => this == other;

	[Commutable]
	public static bool operator==(ParagraphDirection a, ParagraphDirection b) => (a.Direction == b.Direction) && (a.AutoRightToLeft == b.AutoRightToLeft);
}

/// What a run takes when its markup leaves a style unset, and how the lines go.
class TextLayoutStyle
{
	/// The label's font: plain runs draw in it. Borrowed.
	public CachedFont Font = null;
	/// Resolves a run's own family, size, bold and italic. Borrowed.
	public IFontService Fonts = null;
	/// The label's family as the service names it.
	public String Family = new .() ~ delete _;
	/// The label's fallback families, weight and style: a run takes its face from them.
	public FontSelection Selection = new .() ~ delete _;
	/// The label's size in pixels.
	public float Size = 16.0f;
	public Color TextColor = .White;
	public TextHAlign Align = .Left;
	public bool Wrap = true;
	/// The width lines wrap at, align in and end in an ellipsis past; 0: unbounded.
	public float MaxWidth = 0.0f;
	/// Each line's height in pixels; 0: its fonts' own.
	public float LineHeight = 0.0f;
	/// Added after every character, in pixels.
	public float LetterSpacing = 0.0f;
	/// overflow-wrap: a word wider than a line breaks between its graphemes.
	public bool BreakWords = false;
	/// The most lines kept (line-clamp); 0: all.
	public uint32 MaxLines = 0;
	public TextOverflow Overflow = .Clip;
	/// Each paragraph's base direction: its node's, or (Auto) its first strong character's.
	public TextDirection Direction = .LeftToRight;
	/// An Auto paragraph with no strong character runs right to left (its node does).
	public bool AutoRightToLeft = false;

	/// Makes this a copy of `other`.
	public void Set(TextLayoutStyle other)
	{
		if (other === this)
			return;
		Font = other.Font;
		Fonts = other.Fonts;
		Family.Set(other.Family);
		Selection.Set(other.Selection);
		Size = other.Size;
		TextColor = other.TextColor;
		Align = other.Align;
		Wrap = other.Wrap;
		MaxWidth = other.MaxWidth;
		LineHeight = other.LineHeight;
		LetterSpacing = other.LetterSpacing;
		BreakWords = other.BreakWords;
		MaxLines = other.MaxLines;
		Overflow = other.Overflow;
		Direction = other.Direction;
		AutoRightToLeft = other.AutoRightToLeft;
	}
}

/// A run's glyphs on one line: positions in layout coordinates, y on the baseline.
class LaidOutGlyphs
{
	/// Borrowed.
	public CachedFont Font = null;
	public List<GlyphPosition> Glyphs = new .() ~ delete _;
	/// Each glyph's bytes of the plain text, parallel to Glyphs (an ellipsis has none of its own:
	/// it covers what it stands for).
	public List<int> GlyphStart = new .() ~ delete _;
	public List<int> GlyphEnd = new .() ~ delete _;
	public Color TextColor = .White;
	public float Size = 0.0f;
	/// No bold face: draw twice, `Size / 24` apart.
	public bool SyntheticBold = false;
	/// No italic face: slant about the baseline.
	public bool SyntheticItalic = false;
	/// Its font has no shaper: draw TextStart..TextEnd at X as text (its glyphs only place carets).
	public bool Unshaped = false;
	public float Baseline = 0.0f;
	/// Where its first glyph starts.
	public float X = 0.0f;
	/// Its advance.
	public float Width = 0.0f;
	public int TextStart = 0;
	public int TextEnd = 0;
	public int Line = 0;
	/// Its run, or -1 for an ellipsis.
	public int32 Run = 0;

	/// Makes this a copy of `other`, its glyphs too.
	public void Set(LaidOutGlyphs other)
	{
		if (other === this)
			return;
		Font = other.Font;
		Glyphs.Clear();
		Glyphs.AddRange(other.Glyphs);
		GlyphStart.Clear();
		GlyphStart.AddRange(other.GlyphStart);
		GlyphEnd.Clear();
		GlyphEnd.AddRange(other.GlyphEnd);
		TextColor = other.TextColor;
		Size = other.Size;
		SyntheticBold = other.SyntheticBold;
		SyntheticItalic = other.SyntheticItalic;
		Unshaped = other.Unshaped;
		Baseline = other.Baseline;
		X = other.X;
		Width = other.Width;
		TextStart = other.TextStart;
		TextEnd = other.TextEnd;
		Line = other.Line;
		Run = other.Run;
	}
}

/// One laid-out line.
struct LaidOutLine
{
	public float Top = 0.0f;
	public float Height = 0.0f;
	public float Baseline = 0.0f;
	/// After alignment.
	public float Left = 0.0f;
	/// Without trailing spaces.
	public float Width = 0.0f;
	/// Its bytes of the plain text, its line break left out.
	public int Start = 0;
	public int End = 0;
	/// An ellipsis stands for some of its text.
	public bool Ellipsized = false;
	/// Its paragraph runs right to left: its start is on its right.
	public bool RightToLeft = false;

	public this() { }
}

/// A rectangle a part of the text covers, with its run (an icon's, an underline's, a link's).
struct LaidOutBox
{
	public Rectangle Rect = .();
	public int32 Run = 0;
	public int Line = 0;
	/// An underline's colour.
	public Color TextColor = .White;

	public this() { }
}

/// A document laid out.
class TextLayout
{
	public List<LaidOutLine> Lines = new .() ~ delete _;
	public List<LaidOutGlyphs> GlyphRuns = new .() ~ DeleteContainerAndItems!(_);
	public List<LaidOutBox> Icons = new .() ~ delete _;
	public List<LaidOutBox> Underlines = new .() ~ delete _;
	/// One per run per line it spans.
	public List<LaidOutBox> Links = new .() ~ delete _;
	/// The plain text the offsets index (a ligature's inner caret places).
	public String Text = new .() ~ delete _;
	/// The widest line.
	public float Width = 0.0f;
	/// Every line.
	public float Height = 0.0f;
	/// Lines past the clamp were left out.
	public bool Clamped = false;

	/// Empties it, as a layout of nothing before its first line.
	public void Clear()
	{
		Lines.Clear();
		ClearAndDeleteItems!(GlyphRuns);
		Icons.Clear();
		Underlines.Clear();
		Links.Clear();
		Text.Clear();
		Width = 0.0f;
		Height = 0.0f;
		Clamped = false;
	}

	/// Makes this a copy of `other`, its glyph runs copied too.
	public void Set(TextLayout other)
	{
		if (other === this)
			return;
		Clear();
		Lines.AddRange(other.Lines);
		for (let run in other.GlyphRuns)
		{
			let copy = new LaidOutGlyphs();
			copy.Set(run);
			GlyphRuns.Add(copy);
		}
		Icons.AddRange(other.Icons);
		Underlines.AddRange(other.Underlines);
		Links.AddRange(other.Links);
		Text.Set(other.Text);
		Width = other.Width;
		Height = other.Height;
		Clamped = other.Clamped;
	}

	/// The run of the link under a point, or -1.
	public int32 LinkAt(Float2 point)
	{
		for (let area in Links)
		{
			if ((point.X >= area.Rect.X) && (point.X < area.Rect.X + area.Rect.Width) && (point.Y >= area.Rect.Y) &&
				(point.Y < area.Rect.Y + area.Rect.Height))
				return area.Run;
		}
		return -1;
	}

	/// The line a caret at `offset` stands on (at a wrap, the line it starts).
	public int LineOf(int offset)
	{
		for (int i = 0; i < Lines.Count; i++)
			if ((offset < Lines[i].End) || ((offset == Lines[i].End) && ((i + 1 == Lines.Count) || (Lines[i + 1].Start > offset))))
				return i;
		return Lines.IsEmpty ? 0 : Lines.Count - 1;
	}

	/// Where a caret at `offset` stands across its line (`upstream`: after the text before it,
	/// where that is elsewhere, at a direction's boundary).
	public float CaretX(int offset, bool upstream = false) => Lines.IsEmpty ? 0.0f : CaretXOnLine(offset, LineOf(offset), upstream);

	/// Where a caret at `offset` stands across line `line` (a wrapped line's end: its own, not the
	/// next line's start). Downstream (the default) it is before the text after it; `upstream`,
	/// after the text before it: the two differ where the directions meet.
	public float CaretXOnLine(int offset, int line, bool upstream = false)
	{
		if (line >= Lines.Count)
			return 0.0f;
		if (upstream)
		{
			for (let run in GlyphRuns)
			{
				if ((run.Line != line) || (run.Run < 0))
					continue;
				for (int g = 0; g < run.Glyphs.Count; g++)
					if ((run.GlyphEnd[g] == offset) && (run.GlyphStart[g] < offset))
						return run.Glyphs[g].RightToLeft ? run.Glyphs[g].X : run.Glyphs[g].X + run.Glyphs[g].Advance;
			}
		}
		// The leading edge of the glyph the offset starts (a right-to-left glyph's is its right),
		// else the trailing edge of the one before it, else the line's start.
		let at = Lines[line];
		float x = at.RightToLeft ? at.Left + at.Width : at.Left;
		int before = 0;
		bool found = false;
		for (let run in GlyphRuns)
		{
			if ((run.Line != line) || (run.Run < 0))
				continue;
			for (int g = 0; g < run.Glyphs.Count; g++)
			{
				let glyph = run.Glyphs[g];
				let start = run.GlyphStart[g];
				let end = run.GlyphEnd[g];
				if ((offset >= start) && (offset < end))
				{
					// Inside a ligature: the share of its advance before the offset.
					let share = (end > start) ? ((float)(offset - start) / (float)(end - start)) : 0.0f;
					return glyph.RightToLeft ? glyph.X + glyph.Advance * (1.0f - share) : glyph.X + glyph.Advance * share;
				}
				if ((offset >= end) && (!found || (end >= before)))
				{
					x = glyph.RightToLeft ? glyph.X : glyph.X + glyph.Advance;
					before = end;
					found = true;
				}
			}
		}
		return x;
	}

	/// The offset a caret takes for a point: the line under its y (the first above, the last
	/// below), then the glyph edge nearest its x.
	public int OffsetAt(Float2 point) => OffsetAtImpl(point, null);

	/// As OffsetAt; `upstream` says the edge was the trailing one of the text before the offset.
	public int OffsetAt(Float2 point, out bool upstream)
	{
		bool up = false;
		let offset = OffsetAtImpl(point, &up);
		upstream = up;
		return offset;
	}

	/// The offset on line `line` nearest across to `x`.
	public int OffsetOnLine(int line, float x) => OffsetOnLineImpl(line, x, null);

	/// As OffsetOnLine; `upstream` as OffsetAt's.
	public int OffsetOnLine(int line, float x, out bool upstream)
	{
		bool up = false;
		let offset = OffsetOnLineImpl(line, x, &up);
		upstream = up;
		return offset;
	}

	private int OffsetAtImpl(Float2 point, bool* upstream)
	{
		if (upstream != null)
			*upstream = false;
		if (Lines.IsEmpty)
			return 0;
		int line = Lines.Count - 1;
		for (int i = 0; i < Lines.Count; i++)
		{
			if (point.Y < Lines[i].Top + Lines[i].Height)
			{
				line = i;
				break;
			}
		}
		return OffsetOnLineImpl(line, point.X, upstream);
	}

	private int OffsetOnLineImpl(int line, float x, bool* upstream)
	{
		if (upstream != null)
			*upstream = false;
		if (line >= Lines.Count)
			return 0;
		let at = Lines[line];
		bool trailing = false;
		int best = at.Start;
		int lastStart = at.Start; // the last glyph's start: a wrapped line's end
		float bestDistance = Math.Abs(x - (at.RightToLeft ? at.Left + at.Width : at.Left));
		for (let run in GlyphRuns)
		{
			if ((run.Line != line) || (run.Run < 0))
				continue;
			for (int g = 0; g < run.Glyphs.Count; g++)
			{
				let glyph = run.Glyphs[g];
				let left = Math.Abs(x - glyph.X);
				let right = Math.Abs(x - (glyph.X + glyph.Advance));
				// A right-to-left glyph's start is on its right.
				let leftOffset = glyph.RightToLeft ? run.GlyphEnd[g] : run.GlyphStart[g];
				let rightOffset = glyph.RightToLeft ? run.GlyphStart[g] : run.GlyphEnd[g];
				if (left < bestDistance)
				{
					bestDistance = left;
					best = leftOffset;
					trailing = glyph.RightToLeft; // a right-to-left glyph's left edge is its end
				}
				if (right < bestDistance)
				{
					bestDistance = right;
					best = rightOffset;
					trailing = !glyph.RightToLeft;
				}
				lastStart = Math.Max(lastStart, run.GlyphStart[g]);
			}
		}
		best = Math.Min(best, at.End);
		// Where a line wraps, its end is the next line's start: a caret there would stand on the
		// next line, so the end of a wrapped line is before its last space.
		if ((best == at.End) && (line + 1 < Lines.Count) && (Lines[line + 1].Start == best))
		{
			best = lastStart;
			trailing = false;
		}
		// Upstream only where it stands apart from downstream (a direction's boundary).
		if ((upstream != null) && trailing && (best > at.Start))
			*upstream = CaretXOnLine(best, line, true) != CaretXOnLine(best, line, false);
		return best;
	}

	/// A caret place across a line, for OffsetVisually.
	private struct Stop
	{
		public float X;
		public int Offset;
		public bool Upstream;

		public this(float x, int offset, bool upstream)
		{
			X = x;
			Offset = offset;
			Upstream = upstream;
		}
	}

	// A caret place on `line`, unless one already stands at its x.
	private void AddStop(List<Stop> stops, int line, int at, bool up)
	{
		let x = CaretXOnLine(at, line, up);
		for (let s in stops)
			if (Math.Abs(s.X - x) < 0.01f)
				return; // a place already reached
		stops.Add(.(x, at, up));
	}

	/// The caret one stop across from (`offset`, `upstream`) on its line, left (`step` below 0) or
	/// right, in visual order: the line's caret places sorted by x, each once. Past the line's edge
	/// it goes on to the next line where the line reads that way and to the one before where it
	/// reads the other way. False when there is nowhere to go (the out values are then the start).
	public bool OffsetVisually(int offset, bool upstream, int32 step, out int outOffset, out bool outUpstream)
	{
		outOffset = offset;
		outUpstream = upstream;
		if (Lines.IsEmpty)
			return false;
		let line = LineOf(offset);
		let stops = scope List<Stop>();
		// Downstream first, so a place both reach keeps the plain caret.
		AddStop(stops, line, Lines[line].Start, false);
		bool[2] passes = .(false, true);
		for (let up in passes)
		{
			for (let run in GlyphRuns)
			{
				if ((run.Line != line) || (run.Run < 0))
					continue;
				for (int g = 0; g < run.Glyphs.Count; g++)
				{
					AddStop(stops, line, up ? run.GlyphEnd[g] : run.GlyphStart[g], up);
					// Inside a ligature (fi, lam-alef), a place between each of its graphemes.
					if (!up && (run.GlyphEnd[g] <= Text.Length))
					{
						for (int inner = NextGrapheme(Text, run.GlyphStart[g]); inner < run.GlyphEnd[g]; inner = NextGrapheme(Text, inner))
							AddStop(stops, line, inner, false);
					}
				}
			}
		}
		for (int i = 1; i < stops.Count; i++) // insertion sort: a line's stops are few
			for (int j = i; (j > 0) && (stops[j].X < stops[j - 1].X); j--)
				Swap!(stops[j], stops[j - 1]);
		let x = CaretXOnLine(offset, line, upstream);
		int at = 0;
		for (int i = 0; i < stops.Count; i++)
			if (Math.Abs(stops[i].X - x) < Math.Abs(stops[at].X - x))
				at = i;
		if ((step > 0) && (at + 1 < stops.Count))
		{
			outOffset = stops[at + 1].Offset;
			outUpstream = stops[at + 1].Upstream;
			return true;
		}
		if ((step < 0) && (at > 0))
		{
			outOffset = stops[at - 1].Offset;
			outUpstream = stops[at - 1].Upstream;
			return true;
		}
		let towardsEnd = (step > 0) != Lines[line].RightToLeft;
		if (towardsEnd && (line + 1 < Lines.Count))
		{
			outOffset = Lines[line + 1].Start;
			outUpstream = false;
			return true;
		}
		if (!towardsEnd && (line > 0))
		{
			outOffset = Lines[line - 1].End;
			outUpstream = true;
			return true;
		}
		return false;
	}

	/// The boxes across line `line` that bytes [start, end) of the text cover (one a stretch of
	/// glyphs side by side: a selection in mixed-direction text falls in pieces), left to right, as
	/// x ranges (X its left, Y its right), in `outRanges` (cleared first).
	public void RangeOnLine(int start, int end, int line, List<Float2> outRanges)
	{
		outRanges.Clear();
		if ((line >= Lines.Count) || (end <= start))
			return;
		for (let run in GlyphRuns)
		{
			if ((run.Line != line) || (run.Run < 0))
				continue;
			for (int g = 0; g < run.Glyphs.Count; g++)
			{
				let a = Math.Max(start, run.GlyphStart[g]);
				let b = Math.Min(end, run.GlyphEnd[g]);
				if (b <= a)
					continue;
				let glyph = run.Glyphs[g];
				let span = run.GlyphEnd[g] - run.GlyphStart[g];
				// A ligature's share (from its start's side).
				float from = (float)(a - run.GlyphStart[g]) / (float)span;
				float to = (float)(b - run.GlyphStart[g]) / (float)span;
				if (glyph.RightToLeft)
				{
					let f = 1.0f - to;
					to = 1.0f - from;
					from = f;
				}
				outRanges.Add(.(glyph.X + glyph.Advance * from, glyph.X + glyph.Advance * to));
			}
		}
		for (int i = 1; i < outRanges.Count; i++)
			for (int j = i; (j > 0) && (outRanges[j].X < outRanges[j - 1].X); j--)
				Swap!(outRanges[j], outRanges[j - 1]);
		int kept = 0;
		for (int i = 0; i < outRanges.Count; i++)
		{
			if ((kept > 0) && (outRanges[i].X <= outRanges[kept - 1].Y + 0.01f))
				outRanges[kept - 1].Y = Math.Max(outRanges[kept - 1].Y, outRanges[i].Y); // touching: one box
			else
				outRanges[kept++] = outRanges[i];
		}
		outRanges.RemoveRange(kept, outRanges.Count - kept);
	}
}

/// The font a run draws in, the faces it falls back to for what that one lacks (the rest of its
/// `font-family` list), and what of its style the face lacks (to synthesize).
struct ResolvedRunFont
{
	public const int cMaxFallbacks = 4;
	/// Borrowed, as its fallbacks are.
	public CachedFont Font = null;
	public CachedFont[cMaxFallbacks] Fallbacks = default;
	public uint8 FallbackCount = 0;
	public float Size = 16.0f;
	public bool SyntheticBold = false;
	public bool SyntheticItalic = false;

	public this() { }

	/// Face `i` of the list: 0 the run's font, then its fallbacks.
	public CachedFont Face(int i) => (i == 0) ? Font : Fallbacks[i - 1];

	public int FaceCount => (Font != null) ? 1 + FallbackCount : 0;

	/// The first face that has `codepoint` (the run's font when none has it, its missing glyph then
	/// drawn as that font draws one).
	public int FaceFor(int32 codepoint)
	{
		for (int i = 0; i < FaceCount; i++)
			if ((Face(i).Font != null) && Face(i).Font.HasGlyph(codepoint))
				return i;
		return 0;
	}
}

static
{
	public static bool CollapsesSpaces(TextWhiteSpace w) => (w == .Normal) || (w == .NoWrap);

	public static bool Wraps(TextWhiteSpace w) => (w == .Normal) || (w == .PreWrap);

	/// Whether `font` draws every character of `text`: its atlas holds a glyph for each (a font
	/// with no atlas is taken at its word). Atlases are baked over a range of codepoints, so a
	/// widget's own marks (an ellipsis, a password's bullet) fall back to ones it has.
	public static bool FontDraws(CachedFont font, StringView text)
	{
		if ((font == null) || (font.Font == null))
			return false;
		if (font.Atlas == null)
			return true;
		for (int i = 0; i < text.Length;)
		{
			let glyph = font.Atlas.GlyphFor((int32)DecodeCodepoint(text, ref i));
			if ((glyph <= 0) || !font.Atlas.Contains(glyph))
				return false;
		}
		return true;
	}

	/// The ellipsis `font` draws: U+2026, or three full stops.
	public static StringView EllipsisFor(CachedFont font) => FontDraws(font, "\u{2026}") ? "\u{2026}" : "...";

	/// Calls `each` with every family of a CSS `font-family` list, in order: split at commas, the
	/// spaces and quotes around each taken off (`"Roboto", 'Noto Sans Arabic', sans-serif`).
	public static void ForEachFamily(StringView list, delegate void(StringView family) each)
	{
		int start = 0;
		while (start <= list.Length)
		{
			int end = start;
			while ((end < list.Length) && (list[end] != ','))
				end++;
			var family = TextRunsDetail.Trimmed(list.Substring(start, end - start));
			if ((family.Length >= 2) && ((family[0] == '"') || (family[0] == '\'')) && (family[family.Length - 1] == family[0]))
				family = TextRunsDetail.Trimmed(family.Substring(1, family.Length - 2));
			if (family.Length != 0)
				each(family);
			start = end + 1;
		}
	}

	/// The faces a run falls back to, at its size: for a run of its own family the label's family
	/// first, then the rest of the label's list; up to ResolvedRunFont.cMaxFallbacks, a face already
	/// chosen not added again. (They are the families' regular faces: a bold run's fallback glyphs
	/// are not bold.)
	public static void AddFallbacks(ref ResolvedRunFont result, TextLayoutStyle style, bool ownFamily)
	{
		if ((style.Fonts == null) || (result.Font == null))
			return;
		if (ownFamily && (style.Family.Length != 0))
			TextLayoutDetail.AddFallback(ref result, style, style.Family);
		let families = scope List<StringView>();
		ForEachFamily(style.Selection.FallbackFamilies, scope [&] (family) => families.Add(family));
		for (let family in families)
			TextLayoutDetail.AddFallback(ref result, style, family);
	}

	public static ResolvedRunFont ResolveRunFont(TextRun run, TextLayoutStyle style)
	{
		var result = ResolvedRunFont();
		result.Font = style.Font;
		result.Size = run.Size.HasValue ? run.Size.Value : style.Size;
		// A run's <b> is CSS's bolder, its <i> italic, over the label's own weight and style.
		let weight = run.Bold ? TextLayoutDetail.Bolder(style.Selection.Weight) : style.Selection.Weight;
		let italic = run.Italic || style.Selection.Italic;
		let ownFont = (run.Family != null) || run.Size.HasValue || (weight != 400) || italic;
		if (!ownFont)
		{
			AddFallbacks(ref result, style, false);
			return result;
		}
		if (style.Fonts == null)
		{
			// No service to ask: the label's font, its style synthesized.
			result.Size = style.Size;
			result.SyntheticBold = weight >= 600;
			result.SyntheticItalic = italic;
			return result;
		}
		let service = style.Fonts;
		StringView family = (run.Family != null) ? run.Family : style.Family;
		let face = scope TextLayoutDetail.FaceChoice();
		TextLayoutDetail.ChooseFace(service, family, weight, italic, face);
		result.SyntheticBold = face.SyntheticBold;
		result.SyntheticItalic = face.SyntheticItalic;
		let font = service.GetFont(face.Face, result.Size);
		if (font != null)
			result.Font = font;
		AddFallbacks(ref result, style, run.Family != null);
		return result;
	}

	/// Lay a document out, in `outLayout` (cleared first), which it returns.
	public static TextLayout LayOutText(TextDocument document, TextLayoutStyle style, TextLayout outLayout)
	{
		let layout = outLayout;
		layout.Clear();
		let spacing = style.LetterSpacing;
		let pieces = scope List<TextLayoutDetail.TextPiece>();
		int runStart = 0; // the run's first byte in the plain text
		for (int r = 0; r < document.Runs.Count; r++)
		{
			let run = document.Runs[r];
			let font = ResolveRunFont(run, style);
			if (run.IsIcon)
			{
				var piece = TextLayoutDetail.TextPiece();
				piece.Run = (int32)r;
				piece.Start = runStart;
				piece.Font = font;
				piece.Icon = true;
				TextLayoutDetail.MeasurePiece(ref piece, spacing);
				piece.Width = font.Size;
				piece.Ascent = Math.Max(piece.Ascent, font.Size);
				pieces.Add(piece);
				runStart += 3; // U+FFFC in the plain text
				continue;
			}
			StringView text = run.Text;
			int start = 0;
			int i = 0;
			while (i < text.Length)
			{
				if (text[i] == '\n')
				{
					TextLayoutDetail.EmitPiece(pieces, (int32)r, text, start, i, runStart, font, spacing);
					var lineBreak = TextLayoutDetail.TextPiece();
					lineBreak.Run = (int32)r;
					lineBreak.Start = runStart + i;
					lineBreak.Font = font;
					lineBreak.LineBreak = true;
					TextLayoutDetail.MeasurePiece(ref lineBreak, spacing);
					pieces.Add(lineBreak);
					start = ++i;
					continue;
				}
				if (text[i] == ' ')
				{
					while ((i < text.Length) && (text[i] == ' '))
						i++;
					TextLayoutDetail.EmitPiece(pieces, (int32)r, text, start, i, runStart, font, spacing); // a word takes the spaces after it
					start = i;
					continue;
				}
				i++;
			}
			TextLayoutDetail.EmitPiece(pieces, (int32)r, text, start, text.Length, runStart, font, spacing);
			runStart += text.Length;
		}

		let bidi = TextLayoutDetail.ResolveBidi(pieces, style.Direction, style.AutoRightToLeft, spacing);

		// The base font's metrics size an empty line.
		var empty = TextLayoutDetail.TextPiece();
		empty.Font = ResolveRunFont(scope TextRun(), style);
		TextLayoutDetail.MeasurePiece(ref empty, spacing);

		document.PlainText(layout.Text);
		let bounded = style.MaxWidth > 0.0f;
		var lines = TextLayoutDetail.LineBuilder();
		lines.Pieces = pieces;
		lines.Layout = layout;
		lines.Style = style;
		lines.Empty = empty;
		let lineFirstPiece = scope List<int>(); // each line's first piece (its last is before the next's first)
		lines.LineFirstPiece = lineFirstPiece;
		for (int p = 0; p < pieces.Count; p++)
		{
			if (pieces[p].LineBreak)
			{
				lines.FinishLine(p + 1);
				continue;
			}
			if (style.Wrap && bounded && (p > lines.LineStart) && (lines.X + pieces[p].Width - pieces[p].TrailingSpace > style.MaxWidth))
				lines.FinishLine(p);
			// overflow-wrap: a word wider than the whole line breaks where the line ends, between
			// graphemes (one at the least), the rest going on as a piece of its own.
			if (style.Wrap && style.BreakWords && bounded && !pieces[p].Icon && (p == lines.LineStart) &&
				(pieces[p].Width - pieces[p].TrailingSpace > style.MaxWidth))
			{
				let cut = TextLayoutDetail.FittingPrefix(pieces[p], style.MaxWidth, spacing);
				if (cut < pieces[p].Text.Length)
				{
					var rest = pieces[p];
					rest.Text = pieces[p].Text.Substring(cut, pieces[p].Text.Length - cut);
					rest.Start = pieces[p].Start + cut;
					rest.Width = 0.0f;
					rest.TrailingSpace = 0.0f;
					TextLayoutDetail.MeasurePiece(ref rest, spacing);
					var piece = ref pieces[p];
					piece.Text = piece.Text.Substring(0, cut);
					piece.Width = 0.0f;
					piece.TrailingSpace = 0.0f;
					TextLayoutDetail.MeasurePiece(ref piece, spacing);
					pieces.Insert(p + 1, rest);
				}
			}
			pieces[p].X = lines.X;
			lines.X += pieces[p].Width;
		}
		if ((lines.LineStart < pieces.Count) || layout.Lines.IsEmpty || (!pieces.IsEmpty && pieces.Back.LineBreak))
			lines.FinishLine(pieces.Count);

		// The clamp: the lines past it go.
		int keptLines = layout.Lines.Count;
		if ((style.MaxLines > 0) && (keptLines > (int)style.MaxLines))
		{
			keptLines = (int)style.MaxLines;
			layout.Lines.RemoveRange(keptLines, layout.Lines.Count - keptLines);
			layout.Clamped = true;
			layout.Height = layout.Lines.Back.Top + layout.Lines.Back.Height;
		}

		// Each line in visual order, its pieces placed again from its left.
		if (bidi)
		{
			let baseLevel = ((style.Direction == .RightToLeft) || ((style.Direction == .Auto) && style.AutoRightToLeft)) ? (uint8)1 : (uint8)0;
			for (int l = 0; l < keptLines; l++)
				TextLayoutDetail.OrderLine(pieces, lineFirstPiece[l], (l + 1 < lineFirstPiece.Count) ? lineFirstPiece[l + 1] : pieces.Count,
					baseLevel, ref layout.Lines[l]);
		}

		// Glyphs, icons, underlines and links, from each line's start.
		let offsets = scope List<int>();
		for (int p = 0; p < pieces.Count; p++)
		{
			let piece = pieces[p];
			if (piece.LineBreak || (piece.Line >= keptLines))
				continue;
			let at = layout.Lines[piece.Line];
			let run = document.Runs[piece.Run];
			let color = run.TextColor.HasValue ? run.TextColor.Value : style.TextColor;
			let visible = piece.Width - piece.TrailingSpace;
			if (piece.Icon)
			{
				var icon = LaidOutBox();
				icon.Rect = .(piece.X, at.Baseline - piece.Font.Size, piece.Font.Size, piece.Font.Size);
				icon.Run = piece.Run;
				icon.Line = piece.Line;
				layout.Icons.Add(icon);
			}
			else if (piece.Font.Font != null)
			{
				let glyphs = new LaidOutGlyphs();
				glyphs.Font = piece.Font.Font;
				glyphs.TextColor = color;
				glyphs.Size = piece.Font.Size;
				glyphs.SyntheticBold = piece.Font.SyntheticBold;
				glyphs.SyntheticItalic = piece.Font.SyntheticItalic;
				glyphs.Baseline = at.Baseline;
				glyphs.X = piece.X;
				glyphs.Width = piece.Width;
				glyphs.TextStart = piece.Start;
				glyphs.TextEnd = piece.Start + piece.Text.Length;
				glyphs.Line = piece.Line;
				glyphs.Run = piece.Run;
				// Shaped as it reads: one way, the level its piece is at.
				bool shaped = false;
				let shaper = piece.Font.Font.Shaper;
				if ((shaper != null) && (piece.Font.Font.Font != null))
				{
					if (!bidi && (piece.Font.FallbackCount == 0))
					{
						shaped = (shaper.ShapeText(piece.Font.Font.Font, piece.Text, piece.X, at.Baseline, glyphs.Glyphs) case .Ok);
					}
					else
					{
						// Its faces in order: a character takes the first that has it.
						IFont[1 + ResolvedRunFont.cMaxFallbacks] list = default;
						for (int f = 0; f < piece.Font.FaceCount; f++)
							list[f] = piece.Font.Face(f).Font;
						var request = ShapeRequest(piece.Text, .(&list[0], piece.Font.FaceCount));
						request.Direction = piece.Shaping;
						request.StartX = piece.X;
						request.StartY = at.Baseline;
						shaped = (shaper.Shape(request, glyphs.Glyphs) case .Ok);
					}
				}
				if (shaped)
				{
					// Each glyph's bytes from its cluster (a character index); letter spacing after
					// every character before it.
					TextLayoutDetail.CodepointOffsets(piece.Text, piece.Start, offsets);
					let count = offsets.Count - 1;
					for (int k = 0; k < glyphs.Glyphs.Count; k++)
					{
						var g = ref glyphs.Glyphs[k];
						let first = Math.Min((int)Math.Max(0, g.Cluster), count);
						let last = Math.Min((int)Math.Max(0, g.ClusterEnd), count);
						glyphs.GlyphStart.Add(offsets[first]);
						glyphs.GlyphEnd.Add(offsets[last]);
						g.X += spacing * (float)first;
						g.Advance += spacing * (float)(last - first);
					}
				}
				else
				{
					// No shaper: a position for each character from the widths of what comes before
					// it, so carets still find their places; drawn as text.
					glyphs.Glyphs.Clear();
					glyphs.Unshaped = true;
					TextLayoutDetail.CodepointOffsets(piece.Text, piece.Start, offsets);
					float before = 0.0f;
					for (int c = 0; c + 1 < offsets.Count; c++)
					{
						let end = offsets[c + 1] - piece.Start;
						let after = (piece.Font.Font.Font != null) ?
							(piece.Font.Font.Font.MeasureString(piece.Text.Substring(0, end)) + spacing * (float)(c + 1)) : before;
						var g = GlyphPosition();
						g.Cluster = (int32)c;
						g.X = piece.X + before;
						g.Y = at.Baseline;
						g.Advance = after - before;
						glyphs.Glyphs.Add(g);
						glyphs.GlyphStart.Add(offsets[c]);
						glyphs.GlyphEnd.Add(offsets[c + 1]);
						before = after;
					}
				}
				if ((piece.Font.FallbackCount == 0) || glyphs.Unshaped)
					layout.GlyphRuns.Add(glyphs);
				else
				{
					TextLayoutDetail.SplitByFace(layout, glyphs, piece.Font);
					delete glyphs;
				}
			}
			if (run.Underline && (visible > 0.0f) && (piece.Font.Font != null) && (piece.Font.Font.Font != null))
			{
				let decorations = piece.Font.Font.Font.Metrics.Decorations;
				var underline = LaidOutBox();
				// A word's underline runs on under the spaces after it unless it ends the line.
				// (Its spaces are on its left when it reads right to left.)
				let lastOnLine = (p + 1 >= pieces.Count) || pieces[p + 1].LineBreak || (pieces[p + 1].Line != piece.Line);
				let hang = (lastOnLine && ((piece.Level & 1) != 0)) ? piece.TrailingSpace : 0.0f;
				underline.Rect = .(piece.X + hang, at.Baseline + decorations.UnderlinePosition, lastOnLine ? visible : piece.Width,
					decorations.UnderlineThickness);
				underline.Run = piece.Run;
				underline.Line = piece.Line;
				underline.TextColor = color;
				layout.Underlines.Add(underline);
			}
			if (run.Link.Length != 0)
			{
				var link = LaidOutBox();
				link.Rect = .(piece.X, at.Top, piece.Width, at.Height);
				link.Run = piece.Run;
				link.Line = piece.Line;
				layout.Links.Add(link);
			}
		}

		// An ellipsis where a line passes the width (or ends a clamped paragraph), then alignment.
		for (int l = 0; l < layout.Lines.Count; l++)
		{
			let forced = layout.Clamped && (l + 1 == layout.Lines.Count) && (style.Overflow != .Clip);
			// A right-to-left line ends on its left: its end ellipsis is the visual start's.
			TextOverflow overflow = style.Overflow;
			if (layout.Lines[l].RightToLeft && (overflow == .Ellipsis))
				overflow = .EllipsisStart;
			else if (layout.Lines[l].RightToLeft && (overflow == .EllipsisStart))
				overflow = .Ellipsis;
			if (bounded && (style.Overflow != .Clip) && (forced || (layout.Lines[l].Width > style.MaxWidth + 0.01f)))
				TextLayoutDetail.Ellipsize(layout, l, style.MaxWidth, overflow, forced, layout.Lines[l].RightToLeft);
			var line = ref layout.Lines[l];
			// Start and end are the paragraph's.
			TextHAlign align = style.Align;
			if (align == .Start)
				align = line.RightToLeft ? .Right : .Left;
			else if (align == .End)
				align = line.RightToLeft ? .Left : .Right;
			if (bounded && (align == .Center))
				line.Left = (style.MaxWidth - line.Width) * 0.5f;
			else if (bounded && (align == .Right))
				line.Left = style.MaxWidth - line.Width;
			TextLayoutDetail.ShiftLine(layout, l, line.Left);
			layout.Width = Math.Max(layout.Width, line.Width);
		}
		return layout;
	}
}

/// The face matching, measuring, bidi and ellipsis steps TextLayout.bf keeps out of the public
/// surface.
internal static class TextLayoutDetail
{
	/// The face a family draws a weight and style in, and what of them it must synthesize.
	public class FaceChoice
	{
		public String Face = new .() ~ delete _;
		public bool SyntheticBold = false;
		public bool SyntheticItalic = false;
	}

	/// A piece the lines are made of: a word with the spaces after it, an icon, or a break. Its
	/// text is borrowed from its run.
	public struct TextPiece
	{
		public int32 Run = 0;
		public StringView Text = default;
		/// Its bytes of the plain text.
		public int Start = 0;
		public ResolvedRunFont Font = .();
		public float Width = 0.0f;
		/// The width of the spaces it ends with.
		public float TrailingSpace = 0.0f;
		public float Ascent = 0.0f;
		/// Below the baseline, positive.
		public float Descent = 0.0f;
		public float Gap = 0.0f;
		public bool Icon = false;
		public bool LineBreak = false;
		/// Placed, from its line's start.
		public float X = 0.0f;
		/// The line it landed on.
		public int Line = 0;
		/// Its bidi embedding level: odd reads right to left.
		public uint8 Level = 0;
		/// Its paragraph's.
		public uint8 ParagraphLevel = 0;
		/// The direction it is shaped in.
		public TextDirection Shaping = .Auto;

		public this() { }
	}

	public static String[9] sWeightSuffixes = .(" Thin", " ExtraLight", " Light", "", " Medium", " SemiBold", " Bold", " ExtraBold", " Black");

	/// The name a family's face of a weight is loaded under: "Roboto Light", "Roboto", "Roboto
	/// Bold" (the weights' common names, as font files name them).
	public static StringView WeightSuffix(uint16 weight) => sWeightSuffixes[(Math.Clamp((int)weight, 100, 900) + 50) / 100 - 1];

	/// CSS's bolder and lighter, from the weight inherited.
	public static uint16 Bolder(uint16 weight) => (weight < 350) ? (uint16)400 : (weight < 550) ? (uint16)700 : (uint16)900;

	public static uint16 Lighter(uint16 weight) => (weight < 550) ? (uint16)100 : (weight < 750) ? (uint16)400 : (uint16)700;

	/// The weights CSS tries for `desired`, nearest first (the hundreds; CSS Fonts 4, 5.2): from
	/// 400 to 500 up to 500 then down then above 500; below 400 down then up; above 500 up then
	/// down.
	public static void WeightOrder(uint16 desired, ref uint16[9] outOrder)
	{
		let want = ((Math.Clamp((int)desired, 100, 900) + 50) / 100) * 100;
		int n = 0;
		if ((want >= 400) && (want <= 500))
		{
			for (int w = want; w <= 500; w += 100)
				outOrder[n++] = (uint16)w;
			for (int w = want - 100; w >= 100; w -= 100)
				outOrder[n++] = (uint16)w;
			for (int w = 600; w <= 900; w += 100)
				outOrder[n++] = (uint16)w;
		}
		else if (want < 400)
		{
			for (int w = want; w >= 100; w -= 100)
				outOrder[n++] = (uint16)w;
			for (int w = want + 100; w <= 900; w += 100)
				outOrder[n++] = (uint16)w;
		}
		else
		{
			for (int w = want; w <= 900; w += 100)
				outOrder[n++] = (uint16)w;
			for (int w = want - 100; w >= 100; w -= 100)
				outOrder[n++] = (uint16)w;
		}
	}

	/// CSS's matching over the faces the service has: the style first (an italic face of any weight
	/// before an upright one), then the nearest weight. Bold is synthesized where 600 or more was
	/// asked for and the face is lighter than 600, italic where no italic face is; with no face of
	/// the family at all, the family is asked for as it is.
	public static void ChooseFace(IFontService service, StringView family, uint16 weight, bool italic, FaceChoice outChoice)
	{
		uint16[9] order = default;
		WeightOrder(weight, ref order);
		bool[2] styles = .(true, false);
		let name = scope String();
		for (let slanted in styles)
		{
			if (slanted && !italic)
				continue;
			for (let w in order)
			{
				name.Set(family);
				name.Append(WeightSuffix(w));
				if (slanted)
					name.Append(" Italic");
				if (!service.HasFamily(name))
					continue;
				outChoice.Face.Set(name);
				outChoice.SyntheticBold = (weight >= 600) && (w < 600);
				outChoice.SyntheticItalic = italic && !slanted;
				return;
			}
		}
		outChoice.Face.Set(family);
		outChoice.SyntheticBold = weight >= 600;
		outChoice.SyntheticItalic = italic;
	}

	/// One fallback face of AddFallbacks: `family` at the run's size, unless the list is full, the
	/// service lacks it, or it is a face already chosen.
	public static void AddFallback(ref ResolvedRunFont result, TextLayoutStyle style, StringView family)
	{
		if ((result.FallbackCount >= ResolvedRunFont.cMaxFallbacks) || !style.Fonts.HasFamily(family))
			return;
		let face = style.Fonts.GetFont(family, result.Size);
		if ((face == null) || (face === result.Font))
			return;
		for (int i = 0; i < result.FallbackCount; i++)
			if (result.Fallbacks[i] === face)
				return;
		result.Fallbacks[result.FallbackCount++] = face;
	}

	public static int CodepointCount(StringView text)
	{
		int count = 0;
		for (int i = 0; i < text.Length; i++)
			if (((uint8)text[i] & 0xC0) != 0x80)
				count++;
		return count;
	}

	// A space, an ASCII digit or punctuation: it stays in the stretch's face where that has it.
	private static bool IsNeutral(int32 cp) =>
		(cp == (int32)' ') || (cp == (int32)'\t') || (cp == 0xA0) || ((cp >= 0x21) && (cp <= 0x40)) || ((cp >= 0x5B) && (cp <= 0x60)) ||
		((cp >= 0x7B) && (cp <= 0x7E));

	// Calls `each(face, text)` for the stretches of `text` each face of `font` draws, as the shapers
	// split a font list: a character takes the first face that has it, a neutral one (a space, an
	// ASCII digit or punctuation) the stretch's face where that has it.
	public static void ForEachFaceStretch(ResolvedRunFont font, StringView text, delegate void(int face, StringView stretch) each)
	{
		if (font.FallbackCount == 0)
		{
			each(0, text);
			return;
		}
		int start = 0;
		int face = 0;
		for (int i = 0; i < text.Length;)
		{
			let at = i;
			let cp = (int32)DecodeCodepoint(text, ref i);
			let current = font.Face(face).Font;
			let next = ((at != 0) && IsNeutral(cp) && (current != null) && current.HasGlyph(cp)) ? face : font.FaceFor(cp);
			if (at == 0)
				face = next;
			else if (next != face)
			{
				each(face, text.Substring(start, at - start));
				start = at;
				face = next;
			}
		}
		if (start < text.Length)
			each(face, text.Substring(start, text.Length - start));
	}

	// The width `font` draws `text` in, its faces each measuring their own stretches; `used`
	// gathers the faces that drew any (a bit each).
	public static float MeasureInFaces(ResolvedRunFont font, StringView text, uint32* used = null)
	{
		float width = 0.0f;
		ForEachFaceStretch(font, text, scope [&] (face, stretch) =>
			{
				let f = font.Face(face).Font;
				if (f != null)
					width += f.MeasureString(stretch);
				if (used != null)
					*used |= (uint32)1 << face;
			});
		return width;
	}

	// `text` shaped with `font`'s faces as it will be drawn (ligatures, joined forms, kerning): its
	// advance, and in `trailing` that of the glyphs from character `trailingFrom` on; the faces that
	// drew any gathered in `used`. False with no shaper (the caller measures).
	public static bool MeasureShaped(ResolvedRunFont font, StringView text, int trailingFrom, out float advance, out float trailing,
		ref uint32 used)
	{
		advance = 0.0f;
		trailing = 0.0f;
		if (font.Font.Shaper == null)
			return false;
		IFont[1 + ResolvedRunFont.cMaxFallbacks] list = default;
		for (int f = 0; f < font.FaceCount; f++)
			list[f] = font.Face(f).Font;
		let request = ShapeRequest(text, .(&list[0], font.FaceCount));
		let glyphs = scope List<GlyphPosition>();
		if (font.Font.Shaper.Shape(request, glyphs) case .Err)
			return false;
		for (let g in glyphs)
		{
			advance += g.Advance;
			if ((int)Math.Max(0, g.Cluster) >= trailingFrom)
				trailing += g.Advance;
			used |= (uint32)1 << g.Font;
		}
		return true;
	}

	public static void MeasurePiece(ref TextPiece piece, float letterSpacing)
	{
		if ((piece.Font.Font == null) || (piece.Font.Font.Font == null))
			return;
		uint32 used = 1; // the run's own face sets the line's height even where a fallback draws it all
		int spaces = piece.Text.Length;
		while ((spaces > 0) && (piece.Text[spaces - 1] == ' '))
			spaces--;
		let kept = piece.Text.Substring(0, spaces);
		let characters = CodepointCount(piece.Text);
		let keptCharacters = CodepointCount(kept);
		if (piece.Text.Length != 0)
		{
			// Measured as it is shaped, so a line is as wide as what it draws; measured by its
			// characters' advances only where there is no shaper (it draws unshaped then).
			float advance = 0.0f;
			float trailing = 0.0f;
			if (!MeasureShaped(piece.Font, piece.Text, keptCharacters, out advance, out trailing, ref used))
			{
				advance = MeasureInFaces(piece.Font, piece.Text, &used);
				trailing = (spaces < piece.Text.Length) ? (advance - MeasureInFaces(piece.Font, kept)) : 0.0f;
			}
			piece.Width = advance + letterSpacing * (float)characters;
			piece.TrailingSpace = trailing + letterSpacing * (float)(characters - keptCharacters);
		}
		// Its line holds the tallest face it draws in.
		for (int f = 0; f < piece.Font.FaceCount; f++)
		{
			if (((used & ((uint32)1 << f)) != 0) && (piece.Font.Face(f).Font != null))
			{
				let metrics = piece.Font.Face(f).Font.Metrics;
				piece.Ascent = Math.Max(piece.Ascent, metrics.Ascent);
				piece.Descent = Math.Max(piece.Descent, Math.Abs(metrics.Descent));
				piece.Gap = Math.Max(piece.Gap, metrics.LineGap);
			}
		}
	}

	/// A word of run `run` (bytes [start, end) of its text), measured, onto `pieces`; nothing when
	/// it is empty.
	public static void EmitPiece(List<TextPiece> pieces, int32 run, StringView text, int start, int end, int runStart, ResolvedRunFont font,
		float spacing)
	{
		if (end <= start)
			return;
		var piece = TextPiece();
		piece.Run = run;
		piece.Text = text.Substring(start, end - start);
		piece.Start = runStart + start;
		piece.Font = font;
		MeasurePiece(ref piece, spacing);
		pieces.Add(piece);
	}

	// The bytes of `piece` from its start that fit in `width`: whole graphemes, one at the least (a
	// line holds something).
	public static int FittingPrefix(TextPiece piece, float width, float letterSpacing)
	{
		let text = piece.Text;
		int fits = NextGrapheme(text, 0);
		for (int at = fits; at < text.Length;)
		{
			let next = NextGrapheme(text, at);
			let head = text.Substring(0, next);
			float advance = 0.0f;
			float trailing = 0.0f;
			uint32 used = 0;
			if (!MeasureShaped(piece.Font, head, head.Length, out advance, out trailing, ref used))
				advance = MeasureInFaces(piece.Font, head);
			if (advance + letterSpacing * (float)CodepointCount(head) > width)
				break;
			fits = next;
			at = next;
		}
		return fits;
	}

	// The byte offset of each codepoint of `text` from `basis`, and the end (count + 1 entries), in
	// `outOffsets` (cleared first).
	public static void CodepointOffsets(StringView text, int basis, List<int> outOffsets)
	{
		outOffsets.Clear();
		for (int i = 0; i < text.Length; i++)
			if (((uint8)text[i] & 0xC0) != 0x80)
				outOffsets.Add(basis + i);
		outOffsets.Add(basis + text.Length);
	}

	// The first strongly directional character's way: 1 right to left (Hebrew, Arabic, Syriac,
	// Thaana, N'Ko and their presentation forms), 0 left to right (the letters of the scripts that
	// read so), -1 none (digits, spaces, punctuation and symbols only): an auto paragraph's
	// direction, by the rule of Unicode's P2 over the common scripts.
	public static int32 FirstStrongDirection(List<uint32> codepoints)
	{
		for (let cp in codepoints)
		{
			if (((cp >= 0x0590) && (cp <= 0x08FF)) || ((cp >= 0xFB1D) && (cp <= 0xFDFF)) || ((cp >= 0xFE70) && (cp <= 0xFEFF)))
				return 1;
			let letter = ((cp >= (uint32)'A') && (cp <= (uint32)'Z')) || ((cp >= (uint32)'a') && (cp <= (uint32)'z')) ||
				((cp >= 0xC0) && (cp <= 0x058F) && (cp != 0xD7) && (cp != 0xF7)) || ((cp >= 0x0900) && (cp < 0x2000)) ||
				((cp >= 0x3040) && (cp < 0xFB1D));
			if (letter)
				return 0;
		}
		return -1;
	}

	// Bidi: each paragraph's embedding levels from the installed resolver over its pieces'
	// characters (an icon as U+FFFC), and a piece crossing a level change split there, so each piece
	// reads one way. False when nothing reads right to left and the base direction is left to right
	// (the layout then runs as it always has, the pieces untouched). With no resolver installed, a
	// right-to-left paragraph keeps its pieces in order (only its start moves to the right) and each
	// is shaped as its script reads.
	public static bool ResolveBidi(List<TextPiece> pieces, TextDirection direction, bool autoRightToLeft, float letterSpacing)
	{
		let automatic = direction == .Auto;
		let baseLevel = ((direction == .RightToLeft) || (automatic && autoRightToLeft)) ? (uint8)1 : (uint8)0;
		bool rightToLeftText = false; // (a right-to-left base needs the path even for no text)
		for (let piece in pieces)
			for (int i = 0; (i < piece.Text.Length) && !rightToLeftText; i++)
				rightToLeftText = (uint8)piece.Text[i] >= 0xD6; // a lead byte of U+0590 or above
		if ((baseLevel == 0) && !rightToLeftText)
			return false;
		let resolver = BidiResolverFactory.Resolver;
		let result = scope List<TextPiece>();
		let codepoints = scope List<uint32>();
		let owner = scope List<int>(); // each character's piece
		let within = scope List<int>(); // its byte in that piece's text
		let levels = scope BidiLevels();
		bool any = baseLevel != 0;
		int first = 0;
		while (first < pieces.Count)
		{
			int last = first; // a paragraph runs to its break
			while ((last < pieces.Count) && !pieces[last].LineBreak)
				last++;
			codepoints.Clear();
			owner.Clear();
			within.Clear();
			for (int p = first; p < last; p++)
			{
				if (pieces[p].Icon)
				{
					codepoints.Add(0xFFFC);
					owner.Add(p);
					within.Add(0);
					continue;
				}
				let t = pieces[p].Text;
				for (int i = 0; i < t.Length;)
				{
					within.Add(i);
					codepoints.Add(DecodeCodepoint(t, ref i));
					owner.Add(p);
				}
			}
			// An auto paragraph runs as its first strong character reads, else as its node does; the
			// resolver is then told which (a resolver alone would make it left to right).
			uint8 paragraph = baseLevel;
			TextDirection paragraphDirection = direction;
			if (automatic)
			{
				let strong = FirstStrongDirection(codepoints);
				paragraph = (strong >= 0) ? (uint8)strong : baseLevel;
				paragraphDirection = (paragraph != 0) ? .RightToLeft : .LeftToRight;
			}
			levels.Levels.Clear();
			let resolved = (resolver != null) && !codepoints.IsEmpty;
			if (resolved)
			{
				resolver.Resolve(.(codepoints.Ptr, codepoints.Count), paragraphDirection, levels);
				paragraph = levels.ParagraphLevel;
			}
			while (levels.Levels.Count < codepoints.Count)
				levels.Levels.Add(resolved ? paragraph : (uint8)0);
			any = any || (paragraph != 0);
			int c = 0;
			for (int p = first; p < last; p++)
			{
				let piece = pieces[p];
				let begin = c;
				while ((c < owner.Count) && (owner[c] == p))
					c++;
				if (begin == c)
				{
					var part = piece;
					part.Level = paragraph;
					part.ParagraphLevel = paragraph;
					result.Add(part);
					continue;
				}
				int from = begin;
				for (int k = begin + 1; k <= c; k++)
				{
					if ((k < c) && (levels.Levels[k] == levels.Levels[from]))
						continue;
					var part = piece;
					part.Level = levels.Levels[from];
					part.ParagraphLevel = paragraph;
					part.Shaping = !resolved ? .Auto : (((part.Level & 1) != 0) ? .RightToLeft : .LeftToRight);
					if (!piece.Icon && ((from != begin) || (k != c)))
					{
						let a = within[from];
						let b = (k == c) ? piece.Text.Length : within[k];
						part.Text = piece.Text.Substring(a, b - a);
						part.Start = piece.Start + a;
						part.Width = 0.0f;
						part.TrailingSpace = 0.0f;
						MeasurePiece(ref part, letterSpacing);
					}
					any = any || (part.Level != 0);
					result.Add(part);
					from = k;
				}
			}
			if (last < pieces.Count)
			{
				var lineBreak = pieces[last];
				lineBreak.Level = paragraph;
				lineBreak.ParagraphLevel = paragraph;
				result.Add(lineBreak);
			}
			first = last + 1;
		}
		pieces.Clear();
		pieces.AddRange(result);
		return any;
	}

	// Places piece `p` at `x` and moves `x` past it: the line's last piece in logical order loses its
	// trailing spaces' width, which hang past its end (to its left when it reads right to left).
	private static void PlacePiece(List<TextPiece> pieces, int p, int lastLogical, ref float x)
	{
		var piece = ref pieces[p];
		float width = piece.Width;
		float hang = 0.0f;
		if (p == lastLogical)
		{
			width -= piece.TrailingSpace;
			if ((piece.Level & 1) != 0)
				hang = piece.TrailingSpace;
		}
		piece.X = x - hang;
		x += width;
	}

	// Places pieces [begin, finish) of one line in visual order (rule L1: its trailing spaces at the
	// paragraph's level; L2: the runs at each level reversed), each from where the one to its left
	// ends. The line's last piece in logical order loses its trailing spaces' width, which hang past
	// its end (to its left when it reads right to left).
	public static void OrderLine(List<TextPiece> pieces, int begin, int finish, uint8 baseLevel, ref LaidOutLine line)
	{
		let items = scope List<int>();
		for (int p = begin; p < finish; p++)
			if (!pieces[p].LineBreak)
				items.Add(p);
		let paragraph = (begin < finish) ? pieces[begin].ParagraphLevel : baseLevel; // an empty text: the base's
		line.RightToLeft = (paragraph & 1) != 0;
		if (items.IsEmpty)
			return;
		let levels = scope BidiLevels();
		levels.ParagraphLevel = paragraph;
		let marks = scope List<uint32>(); // no character is whitespace to ReorderLine: L1 is applied by piece here
		for (let p in items)
		{
			levels.Levels.Add(pieces[p].Level);
			marks.Add((uint32)'x');
		}
		for (int k = items.Count - 1; k >= 0; k--)
		{
			let piece = pieces[items[k]];
			if (piece.Icon || (piece.Text.Length == 0) || (piece.TrailingSpace < piece.Width - 0.001f))
				break;
			levels.Levels[k] = paragraph; // a piece of nothing but spaces at the line's end
		}
		let runs = scope List<BidiRun>();
		BidiReorder.ReorderLine(levels, .(marks.Ptr, marks.Count), 0, items.Count, runs);
		let lastLogical = items.Back;
		float x = 0.0f;
		for (let run in runs)
		{
			if (run.RightToLeft)
			{
				for (int k = run.End - 1; k >= run.Start; k--)
					PlacePiece(pieces, items[k], lastLogical, ref x);
			}
			else
			{
				for (int k = run.Start; k < run.End; k++)
					PlacePiece(pieces, items[k], lastLogical, ref x);
			}
		}
	}

	// A piece's glyphs from a list of faces, as runs of one face each (the face a run is drawn and
	// measured with), in order, onto the layout. `glyphs` stays the caller's.
	public static void SplitByFace(TextLayout layout, LaidOutGlyphs glyphs, ResolvedRunFont font)
	{
		int g = 0;
		while (g < glyphs.Glyphs.Count)
		{
			let face = glyphs.Glyphs[g].Font;
			let part = new LaidOutGlyphs();
			part.Font = (face < font.FaceCount) ? font.Face(face) : font.Font;
			part.TextColor = glyphs.TextColor;
			part.Size = glyphs.Size;
			part.SyntheticBold = glyphs.SyntheticBold;
			part.SyntheticItalic = glyphs.SyntheticItalic;
			part.Baseline = glyphs.Baseline;
			part.Line = glyphs.Line;
			part.Run = glyphs.Run;
			part.TextStart = glyphs.GlyphStart[g];
			part.TextEnd = glyphs.GlyphEnd[g];
			float left = glyphs.Glyphs[g].X;
			float right = left;
			for (; (g < glyphs.Glyphs.Count) && (glyphs.Glyphs[g].Font == face); g++)
			{
				let glyph = glyphs.Glyphs[g];
				part.Glyphs.Add(glyph);
				part.GlyphStart.Add(glyphs.GlyphStart[g]);
				part.GlyphEnd.Add(glyphs.GlyphEnd[g]);
				part.TextStart = Math.Min(part.TextStart, glyphs.GlyphStart[g]);
				part.TextEnd = Math.Max(part.TextEnd, glyphs.GlyphEnd[g]);
				left = Math.Min(left, glyph.X);
				right = Math.Max(right, glyph.X + glyph.Advance);
			}
			part.X = left;
			part.Width = right - left;
			layout.GlyphRuns.Add(part);
		}
	}

	// Shifts everything laid out on `line` across by `dx`.
	public static void ShiftLine(TextLayout layout, int line, float dx)
	{
		if (dx == 0.0f)
			return;
		for (let run in layout.GlyphRuns)
		{
			if (run.Line != line)
				continue;
			run.X += dx;
			for (int g = 0; g < run.Glyphs.Count; g++)
				run.Glyphs[g].X += dx;
		}
		ShiftBoxes(layout.Icons, line, dx);
		ShiftBoxes(layout.Underlines, line, dx);
		ShiftBoxes(layout.Links, line, dx);
	}

	private static void ShiftBoxes(List<LaidOutBox> boxes, int line, float dx)
	{
		for (int b = 0; b < boxes.Count; b++)
			if (boxes[b].Line == line)
				boxes[b].Rect.X += dx;
	}

	// What of `boxes` on `line` lies in [from, to) across; an icon (`whole`) is not cut in two, and
	// widens what stayed.
	private static void KeepBoxes(List<LaidOutBox> boxes, bool whole, int line, float from, float to, ref float right, ref float leftmost)
	{
		for (int b = boxes.Count - 1; b >= 0; b--)
		{
			var area = ref boxes[b];
			if (area.Line != line)
				continue;
			let left = Math.Max(area.Rect.X, from);
			let boxRight = Math.Min(area.Rect.X + area.Rect.Width, to);
			if ((boxRight <= left) || (whole && ((area.Rect.X < from - 0.01f) || (area.Rect.X + area.Rect.Width > to + 0.01f))))
			{
				boxes.RemoveAt(b);
				continue;
			}
			area.Rect.X = left;
			area.Rect.Width = boxRight - left;
			if (whole)
			{
				right = Math.Max(right, boxRight);
				leftmost = Math.Min(leftmost, left);
			}
		}
	}

	// Keeps only what of `line` lies in [from, to) across; what straddles an edge is cut (a glyph
	// goes whole, a box is narrowed). Returns the right edge of what stayed, and sets `left` (when
	// not null) to its left edge.
	public static float KeepSpan(TextLayout layout, int line, float from, float to, float* left = null)
	{
		float right = from;
		float leftmost = to;
		let glyphs = scope List<GlyphPosition>();
		let starts = scope List<int>();
		let ends = scope List<int>();
		for (let run in layout.GlyphRuns)
		{
			if ((run.Line != line) || run.Unshaped)
				continue;
			glyphs.Clear();
			starts.Clear();
			ends.Clear();
			for (int g = 0; g < run.Glyphs.Count; g++)
			{
				let glyph = run.Glyphs[g];
				if ((glyph.X < from - 0.01f) || (glyph.X + glyph.Advance > to + 0.01f))
					continue;
				glyphs.Add(glyph);
				starts.Add(run.GlyphStart[g]);
				ends.Add(run.GlyphEnd[g]);
				right = Math.Max(right, glyph.X + glyph.Advance);
				leftmost = Math.Min(leftmost, glyph.X);
			}
			if (!glyphs.IsEmpty)
			{
				// Its start and advance are its glyphs' that stayed.
				run.X = glyphs[0].X;
				run.Width = glyphs.Back.X + glyphs.Back.Advance - run.X;
			}
			run.Glyphs.Clear();
			run.Glyphs.AddRange(glyphs);
			run.GlyphStart.Clear();
			run.GlyphStart.AddRange(starts);
			run.GlyphEnd.Clear();
			run.GlyphEnd.AddRange(ends);
		}
		for (int r = layout.GlyphRuns.Count - 1; r >= 0; r--)
		{
			let run = layout.GlyphRuns[r];
			if ((run.Line == line) && !run.Unshaped && run.Glyphs.IsEmpty)
			{
				layout.GlyphRuns.RemoveAt(r);
				delete run;
			}
		}
		KeepBoxes(layout.Icons, true, line, from, to, ref right, ref leftmost);
		KeepBoxes(layout.Underlines, false, line, from, to, ref right, ref leftmost);
		KeepBoxes(layout.Links, false, line, from, to, ref right, ref leftmost);
		if (left != null)
			*left = leftmost;
		return right;
	}

	// An ellipsis on `line` at x in the style of `like`.
	public static void AddEllipsis(TextLayout layout, int line, float x, LaidOutGlyphs like, int offset)
	{
		let ellipsis = new LaidOutGlyphs();
		ellipsis.Font = like.Font;
		ellipsis.TextColor = like.TextColor;
		ellipsis.Size = like.Size;
		ellipsis.SyntheticBold = like.SyntheticBold;
		ellipsis.SyntheticItalic = like.SyntheticItalic;
		ellipsis.Baseline = layout.Lines[line].Baseline;
		ellipsis.X = x;
		ellipsis.Line = line;
		ellipsis.Run = -1;
		ellipsis.TextStart = offset;
		ellipsis.TextEnd = offset;
		if ((like.Font != null) && (like.Font.Shaper != null) && (like.Font.Font != null) &&
			(like.Font.Shaper.ShapeText(like.Font.Font, EllipsisFor(like.Font), x, ellipsis.Baseline, ellipsis.Glyphs) case .Ok))
		{
			for (let g in ellipsis.Glyphs)
			{
				ellipsis.Width += g.Advance;
				ellipsis.GlyphStart.Add(offset);
				ellipsis.GlyphEnd.Add(offset);
			}
			layout.GlyphRuns.Add(ellipsis);
		}
		else
			delete ellipsis;
	}

	public static float EllipsisWidth(LaidOutGlyphs like) =>
		((like.Font != null) && (like.Font.Font != null)) ? like.Font.Font.MeasureString(EllipsisFor(like.Font)) : 0.0f;

	// What of `tail`'s line `line` moves into `layout`, shifted across by `shift`: its shaped glyph
	// runs (taken from the tail, which keeps none of them) and its boxes.
	private static void MoveTail(TextLayout tail, TextLayout layout, int line, float shift)
	{
		for (int r = 0; r < tail.GlyphRuns.Count; r++)
		{
			let run = tail.GlyphRuns[r];
			if ((run.Line != line) || run.Unshaped)
				continue;
			run.X += shift;
			for (int g = 0; g < run.Glyphs.Count; g++)
				run.Glyphs[g].X += shift;
			layout.GlyphRuns.Add(run);
			tail.GlyphRuns[r] = null;
		}
		MoveTailBoxes(tail.Icons, layout.Icons, line, shift);
		MoveTailBoxes(tail.Underlines, layout.Underlines, line, shift);
		MoveTailBoxes(tail.Links, layout.Links, line, shift);
	}

	private static void MoveTailBoxes(List<LaidOutBox> from, List<LaidOutBox> to, int line, float shift)
	{
		for (var area in from)
		{
			if (area.Line != line)
				continue;
			area.Rect.X += shift;
			to.Add(area);
		}
	}

	// Ends `line` in an ellipsis where it passes `maxWidth` (always, when `forced`: the clamp cut the
	// lines after it), at its end, start or middle. The line is still unaligned (from 0).
	public static void Ellipsize(TextLayout layout, int line, float maxWidth, TextOverflow mode, bool forced, bool rightToLeft = false)
	{
		var mode;
		LaidOutGlyphs first = null;
		LaidOutGlyphs last = null;
		for (let run in layout.GlyphRuns)
		{
			if ((run.Line == line) && !run.Unshaped && !run.Glyphs.IsEmpty)
			{
				if (first == null)
					first = run;
				last = run;
			}
		}
		if (last == null)
			return; // nothing shaped to cut
		let firstStyle = scope LaidOutGlyphs(); // copies: the runs change below
		firstStyle.Set(first);
		let lastStyle = scope LaidOutGlyphs();
		lastStyle.Set(last);
		let width = layout.Lines[line].Width;
		if (forced)
			mode = rightToLeft ? .EllipsisStart : .Ellipsis; // a clamped paragraph ends at its end: its left in right to left
		let e = EllipsisWidth((mode == .EllipsisStart) ? firstStyle : lastStyle);
		let room = Math.Max(0.0f, maxWidth - e);
		if (mode == .Ellipsis)
		{
			let limit = (forced && (width + e <= maxWidth)) ? width : room;
			let right = KeepSpan(layout, line, 0.0f, limit);
			AddEllipsis(layout, line, right, lastStyle, layout.Lines[line].End);
			layout.Lines[line].Width = right + e;
		}
		else if (mode == .EllipsisStart)
		{
			// The tail from where its first whole glyph starts, moved up to the ellipsis.
			let cut = width - room;
			float kept = cut;
			KeepSpan(layout, line, cut, width + 1.0f, &kept);
			ShiftLine(layout, line, e - kept);
			AddEllipsis(layout, line, 0.0f, firstStyle, layout.Lines[line].Start);
			layout.Lines[line].Width = width - kept + e;
		}
		else
		{
			// A head and a tail of half the room each, the ellipsis between.
			let half = room * 0.5f;
			let tailFrom = width - half;
			// The tail moves next to the head: kept apart, then shifted.
			let tail = scope TextLayout();
			tail.Set(layout);
			let headRight = KeepSpan(layout, line, 0.0f, half);
			float tailLeft = tailFrom;
			KeepSpan(tail, line, tailFrom, width + 1.0f, &tailLeft);
			let shift = headRight + e - tailLeft;
			MoveTail(tail, layout, line, shift);
			AddEllipsis(layout, line, headRight, lastStyle, layout.Lines[line].Start);
			layout.Lines[line].Width = headRight + e + (width - tailLeft);
		}
		layout.Lines[line].Ellipsized = true;
	}

	/// The lines LayOutText makes as it walks its pieces: where the current line starts, how far
	/// across it has come, and where the next line's text starts. Its lists are borrowed.
	public struct LineBuilder
	{
		public List<TextPiece> Pieces = null;
		public TextLayout Layout = null;
		public TextLayoutStyle Style = null;
		/// Sizes a line with nothing on it and no break of its own.
		public TextPiece Empty = .();
		/// Each line's first piece.
		public List<int> LineFirstPiece = null;
		public int LineStart = 0;
		public float X = 0.0f;
		/// Where the next line's text starts.
		public int NextOffset = 0;

		public this() { }

		/// Ends the line at piece `end` (the pieces from LineStart before it are on it).
		public void FinishLine(int end) mut
		{
			LineFirstPiece.Add(LineStart);
			var line = LaidOutLine();
			line.Top = Layout.Height;
			float ascent = 0.0f;
			float descent = 0.0f;
			float gap = 0.0f;
			bool any = false;
			for (int p = LineStart; p < end; p++)
			{
				ascent = Math.Max(ascent, Pieces[p].Ascent);
				descent = Math.Max(descent, Pieces[p].Descent);
				gap = Math.Max(gap, Pieces[p].Gap);
				any = any || !Pieces[p].LineBreak;
			}
			if (!any)
			{
				// A line with nothing on it is as tall as its break's font, or the base font's.
				let sized = (end > LineStart) ? Pieces[LineStart] : Empty;
				ascent = sized.Ascent;
				descent = sized.Descent;
				gap = sized.Gap;
			}
			if (Style.LineHeight > 0.0f)
			{
				// CSS's half-leading: the line's extra height (or what it lacks) split above and below.
				line.Height = Style.LineHeight;
				line.Baseline = line.Top + (Style.LineHeight - (ascent + descent)) * 0.5f + ascent;
			}
			else
			{
				line.Height = ascent + descent + gap;
				line.Baseline = line.Top + ascent;
			}
			line.Width = X;
			for (int p = end; p > LineStart; p--)
			{
				if (Pieces[p - 1].LineBreak)
					continue;
				line.Width -= Pieces[p - 1].TrailingSpace;
				break;
			}
			line.Start = NextOffset;
			line.End = NextOffset;
			for (int p = LineStart; p < end; p++)
			{
				Pieces[p].Line = Layout.Lines.Count;
				if (Pieces[p].LineBreak)
				{
					line.End = Pieces[p].Start;
					NextOffset = Pieces[p].Start + 1;
				}
				else
				{
					line.End = Pieces[p].Start + (Pieces[p].Icon ? 3 : Pieces[p].Text.Length);
					NextOffset = line.End;
				}
			}
			Layout.Lines.Add(line);
			Layout.Height += line.Height;
			LineStart = end;
			X = 0.0f;
		}
	}
}
