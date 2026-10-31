using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.UI;

/// What a run takes when its markup leaves a style unset, and how the lines go.
struct TextLayoutStyle
{
	public StringView Family;
	public float Size = 16.0f;
	public Color Color = .White;
	public TextAlignment Align = .Left;
	public bool Wrap = true;
	/// The width lines wrap at and align in, wrapped or not; 0 is unbounded.
	public float MaxWidth = 0.0f;

	public this() { Family = default; }
}

/// A run's glyphs on one line: positions in layout coordinates, y on the baseline.
class LaidOutGlyphs
{
	/// Borrowed from the font service.
	public CachedFont Font;
	public List<GlyphPosition> Glyphs = new .() ~ delete _;
	public Color Color = .White;
	public float Size;
	/// No bold face: draw twice, `Size / 24` apart.
	public bool SyntheticBold;
	/// No italic face: slant about the baseline.
	public bool SyntheticItalic;
	public float Baseline;
	public int32 Run;
}

/// One laid out line.
struct LaidOutLine
{
	public float Top;
	public float Height;
	public float Baseline;
	/// After alignment.
	public float Left;
	/// Without trailing spaces.
	public float Width;
}

/// A rectangle a part of the text covers, with its run: an icon's, an underline's, a link's.
struct LaidOutBox
{
	public Rectangle Rect;
	public int32 Run;
	/// An underline's colour.
	public Color Color;
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
	/// The widest line.
	public float Width;
	/// Every line.
	public float Height;

	/// The run of the link under a point, or -1.
	public int32 LinkAt(Float2 point)
	{
		for (let link in Links)
		{
			if ((point.X >= link.Rect.X) && (point.X < link.Rect.X + link.Rect.Width) && (point.Y >= link.Rect.Y)
				&& (point.Y < link.Rect.Y + link.Rect.Height))
				return link.Run;
		}
		return -1;
	}
}

/// The font a run draws in, and what of its style the face lacks, to synthesize.
struct ResolvedRunFont
{
	public CachedFont Font;
	public float Size = 16.0f;
	public bool SyntheticBold;
	public bool SyntheticItalic;

	public this() { Font = null; SyntheticBold = false; SyntheticItalic = false; }
}

/// The inline formatter: lays a TextDocument's runs into lines.
///
/// Text breaks after spaces and at line breaks, runs of different sizes share a baseline (each
/// line as tall as its tallest run), an icon sits on the baseline as tall as its run's text is
/// big, and each line aligns on its own. What comes out is positioned glyphs per run, underlines,
/// icon rectangles and link rectangles, in the layout's own coordinates; the control draws them.
///
/// Bold and italic take the family's "<family> Bold", "<family> Italic" or "<family> Bold Italic"
/// face when one is loaded, and are synthesized when not (bold drawn twice a little apart, italic
/// slanted), as browsers do.
static class TextLayouter
{
	/// The font a run draws in.
	public static ResolvedRunFont ResolveRunFont(TextRun run, TextLayoutStyle style, IFontService service)
	{
		var resolved = ResolvedRunFont();
		let family = (run.Family != null) ? StringView(run.Family) : style.Family;
		resolved.Size = run.Size.HasValue ? run.Size.Value : style.Size;
		let face = scope String(family);
		if (run.Bold || run.Italic)
		{
			let styled = scope String(family);
			styled.Append(run.Bold && run.Italic ? " Bold Italic" : (run.Bold ? " Bold" : " Italic"));
			let bold = scope String(family);
			bold.Append(" Bold");
			if (service.HasFamily(styled))
			{
				face.Set(styled);
			}
			else if (run.Bold && run.Italic && service.HasFamily(bold))
			{
				face.Set(bold);
				resolved.SyntheticItalic = true;
			}
			else
			{
				resolved.SyntheticBold = run.Bold;
				resolved.SyntheticItalic = run.Italic;
			}
		}
		resolved.Font = service.GetFont(face, resolved.Size);
		return resolved;
	}

	/// A piece the lines are made of: a word with the spaces after it, an icon, or a break.
	private struct Piece
	{
		public int32 Run;
		public StringView Text;
		public ResolvedRunFont Font;
		public float Width;
		/// The width of the spaces it ends with.
		public float TrailingSpace;
		public float Ascent;
		/// Below the baseline, positive.
		public float Descent;
		public float Gap;
		public bool Icon;
		public bool LineBreak;
		/// Placed.
		public float X;
		/// The line it landed on.
		public int Line;
	}

	private static void Measure(ref Piece piece)
	{
		if ((piece.Font.Font == null) || (piece.Font.Font.Font == null))
			return;
		let font = piece.Font.Font.Font;
		let metrics = font.Metrics;
		piece.Ascent = metrics.Ascent;
		piece.Descent = Math.Abs(metrics.Descent);
		piece.Gap = metrics.LineGap;
		if (piece.Text.IsEmpty)
			return;
		piece.Width = font.MeasureString(piece.Text);
		var spaces = piece.Text.Length;
		while ((spaces > 0) && (piece.Text[spaces - 1] == ' '))
			spaces--;
		if (spaces < piece.Text.Length)
			piece.TrailingSpace = piece.Width - font.MeasureString(piece.Text.Substring(0, spaces));
	}

	/// Lays a document out; the caller owns the layout.
	public static TextLayout LayOut(TextDocument document, TextLayoutStyle style, IFontService service)
	{
		let pieces = scope List<Piece>();
		for (int r < document.Runs.Count)
		{
			let run = document.Runs[r];
			let font = ResolveRunFont(run, style, service);
			if (run.IsIcon)
			{
				var piece = Piece();
				piece.Run = (int32)r;
				piece.Font = font;
				piece.Icon = true;
				Measure(ref piece);
				piece.Width = font.Size;
				piece.Ascent = Math.Max(piece.Ascent, font.Size);
				pieces.Add(piece);
				continue;
			}
			let text = StringView(run.Text);
			var start = 0;
			var i = 0;
			void Emit(int end)
			{
				if (end <= start)
					return;
				var piece = Piece();
				piece.Run = (int32)r;
				piece.Text = text.Substring(start, end - start);
				piece.Font = font;
				Measure(ref piece);
				pieces.Add(piece);
			}
			while (i < text.Length)
			{
				if (text[i] == '\n')
				{
					Emit(i);
					var lineBreak = Piece();
					lineBreak.Run = (int32)r;
					lineBreak.Font = font;
					lineBreak.LineBreak = true;
					Measure(ref lineBreak);
					pieces.Add(lineBreak);
					start = ++i;
					continue;
				}
				if (text[i] == ' ')
				{
					while ((i < text.Length) && (text[i] == ' '))
						i++;
					// A word takes the spaces after it.
					Emit(i);
					start = i;
					continue;
				}
				i++;
			}
			Emit(text.Length);
		}

		// The base font's metrics size an empty line.
		let plain = scope TextRun();
		var empty = Piece();
		empty.Font = ResolveRunFont(plain, style, service);
		Measure(ref empty);

		let layout = new TextLayout();
		let bounded = style.MaxWidth > 0.0f;
		var lineStart = 0;
		var x = 0.0f;
		void FinishLine(int end)
		{
			var line = LaidOutLine();
			line.Top = layout.Height;
			float ascent = 0.0f;
			float descent = 0.0f;
			float gap = 0.0f;
			var any = false;
			for (int p = lineStart; p < end; p++)
			{
				ascent = Math.Max(ascent, pieces[p].Ascent);
				descent = Math.Max(descent, pieces[p].Descent);
				gap = Math.Max(gap, pieces[p].Gap);
				any = any || !pieces[p].LineBreak;
			}
			if (!any)
			{
				// A line with nothing on it is as tall as its break's font, or the base font's.
				let sized = (end > lineStart) ? pieces[lineStart] : empty;
				ascent = sized.Ascent;
				descent = sized.Descent;
				gap = sized.Gap;
			}
			line.Height = ascent + descent + gap;
			line.Baseline = line.Top + ascent;
			line.Width = x;
			for (int p = end; p > lineStart; p--)
			{
				if (pieces[p - 1].LineBreak)
					continue;
				line.Width -= pieces[p - 1].TrailingSpace;
				break;
			}
			if (bounded && (style.Align == .Center))
				line.Left = (style.MaxWidth - line.Width) * 0.5f;
			else if (bounded && (style.Align == .Right))
				line.Left = style.MaxWidth - line.Width;
			for (int p = lineStart; p < end; p++)
			{
				pieces[p].X += line.Left;
				pieces[p].Line = layout.Lines.Count;
			}
			layout.Lines.Add(line);
			layout.Height += line.Height;
			layout.Width = Math.Max(layout.Width, line.Width);
			lineStart = end;
			x = 0.0f;
		}
		for (int p < pieces.Count)
		{
			if (pieces[p].LineBreak)
			{
				FinishLine(p + 1);
				continue;
			}
			if (style.Wrap && bounded && (p > lineStart) && (x + pieces[p].Width - pieces[p].TrailingSpace > style.MaxWidth))
				FinishLine(p);
			pieces[p].X = x;
			x += pieces[p].Width;
		}
		if ((lineStart < pieces.Count) || layout.Lines.IsEmpty || (!pieces.IsEmpty && pieces.Back.LineBreak))
			FinishLine(pieces.Count);

		// Glyphs, icons, underlines and links.
		for (int p < pieces.Count)
		{
			let piece = pieces[p];
			if (piece.LineBreak)
				continue;
			let at = layout.Lines[piece.Line];
			let run = document.Runs[piece.Run];
			let color = run.Color.HasValue ? run.Color.Value : style.Color;
			let visible = piece.Width - piece.TrailingSpace;
			if (piece.Icon)
			{
				var icon = LaidOutBox();
				icon.Rect = .(piece.X, at.Baseline - piece.Font.Size, piece.Font.Size, piece.Font.Size);
				icon.Run = piece.Run;
				layout.Icons.Add(icon);
			}
			else if ((piece.Font.Font != null) && (piece.Font.Font.Shaper != null))
			{
				let glyphs = new LaidOutGlyphs();
				glyphs.Font = piece.Font.Font;
				glyphs.Color = color;
				glyphs.Size = piece.Font.Size;
				glyphs.SyntheticBold = piece.Font.SyntheticBold;
				glyphs.SyntheticItalic = piece.Font.SyntheticItalic;
				glyphs.Baseline = at.Baseline;
				glyphs.Run = piece.Run;
				if (piece.Font.Font.Shaper.ShapeText(piece.Font.Font.Font, piece.Text, piece.X, at.Baseline, glyphs.Glyphs) case .Ok)
					layout.GlyphRuns.Add(glyphs);
				else
					delete glyphs;
			}
			if (run.Underline && (visible > 0.0f) && (piece.Font.Font != null))
			{
				let decorations = piece.Font.Font.Font.Metrics.Decorations;
				// A word's underline runs on under the spaces after it unless it ends the line.
				let lastOnLine = (p + 1 >= pieces.Count) || pieces[p + 1].LineBreak || (pieces[p + 1].Line != piece.Line);
				var underline = LaidOutBox();
				underline.Rect = .(piece.X, at.Baseline + decorations.UnderlinePosition, lastOnLine ? visible : piece.Width,
					decorations.UnderlineThickness);
				underline.Run = piece.Run;
				underline.Color = color;
				layout.Underlines.Add(underline);
			}
			if (!run.Link.IsEmpty)
			{
				var link = LaidOutBox();
				link.Rect = .(piece.X, at.Top, piece.Width, at.Height);
				link.Run = piece.Run;
				layout.Links.Add(link);
			}
		}
		return layout;
	}
}
