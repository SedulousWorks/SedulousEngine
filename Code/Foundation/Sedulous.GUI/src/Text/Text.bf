using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.VG;
using Sedulous.VG.SVG;
using Sedulous.Profiler; // ProfileScope: a frame's text, apart in the GUI's draw
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// Text: what a widget measures and draws its text with. It holds a string, or a rich text's runs
// from markup, and lays them out through TextLayout: shaped, wrapped as CSS's white-space says, its
// lines as tall as line-height says, letter-spaced, clamped to a line count and ended by an ellipsis
// where they overflow. The layout is cached for the last widths asked (a widget measures unbounded
// and draws at its width), and laid out again only when something it reads changes. It holds a
// borrowed CachedFont (the font service owns it), and a service for runs that set a font of their
// own, and draws through the DrawContext's VG.

/// A label's text with its access key marked (`&File`): what it shows (`File`, `&&` an
/// ampersand), the key (the marked character, lower case; 0 for none) and the bytes of the shown
/// text it underlines.
class Mnemonic
{
	public String Shown = new .() ~ delete _;
	public char32 Key = (char32)0;
	public int Start = 0;
	public int End = 0;
}

/// Type-ahead: what a list, a tree or an open menu matches as text is typed. The text typed within
/// a second of the last is one prefix; one character typed again cycles through the items starting
/// with it. Typed text, so it follows the keyboard layout and an IME.
class TypeAheadSearch
{
	private String mTyped = new .() ~ delete _;
	private float mTypedAt = -10.0f;

	/// Takes `typed` at `now` (seconds) and finds the item it matches among `count`, from
	/// `current` (-1: none), each item's text appended by `textOf`: the item, or -1 when none
	/// matches. A new prefix of one character starts past the current item, so typing it again
	/// moves on; a longer one may stay on the current item.
	public int32 Find(StringView typed, float now, int32 count, int32 current, delegate void(int32 item, String outText) textOf)
	{
		if ((typed.Length == 0) || (count <= 0))
			return -1;
		if (now - mTypedAt > 1.0f)
			mTyped.Clear();
		mTypedAt = now;
		mTyped.Append(typed);
		StringView prefix = mTyped;
		int firstEnd = 0;
		DecodeCodepoint(prefix, ref firstEnd);
		let first = prefix.Substring(0, firstEnd);
		bool repeated = prefix.Length > firstEnd;
		for (int at = firstEnd; (at < prefix.Length) && repeated; at += firstEnd)
			repeated = (prefix.Length - at >= firstEnd) && (prefix.Substring(at, firstEnd) == first);
		if (repeated)
			prefix = first;
		let start = ((prefix.Length == firstEnd) || (current < 0)) ? current + 1 : current;
		let text = scope String();
		for (int32 n = 0; n < count; ++n)
		{
			let item = ((start + n) % count + count) % count;
			text.Clear();
			textOf(item, text);
			if (StartsWithIgnoringCase(text, prefix))
				return item;
		}
		return -1;
	}
}

static
{
	/// A character in lower case, for the scripts type-ahead matches by case: Latin (ASCII, Latin-1
	/// and Latin Extended-A), Greek and Cyrillic; any other as it is.
	public static char32 SimpleLowerCase(char32 character)
	{
		let c = (uint32)character;
		if (((c >= (uint32)'A') && (c <= (uint32)'Z')) || ((c >= 0xC0) && (c <= 0xDE) && (c != 0xD7)) ||
			((c >= 0x391) && (c <= 0x3AB) && (c != 0x3A2)) || ((c >= 0x410) && (c <= 0x42F)))
			return (char32)(c + 0x20);
		if ((c >= 0x400) && (c <= 0x40F))
			return (char32)(c + 0x50);
		// Latin Extended-A pairs: upper case even, lower odd, but for a run where it is the other way.
		if (((c >= 0x100) && (c <= 0x137) && (c != 0x130) && ((c & 1) == 0)) || ((c >= 0x14A) && (c <= 0x177) && ((c & 1) == 0)))
			return (char32)(c + 1);
		if ((((c >= 0x139) && (c <= 0x148)) || ((c >= 0x179) && (c <= 0x17E))) && ((c & 1) == 1))
			return (char32)(c + 1);
		if (c == 0x178)
			return (char32)0xFF;
		return character;
	}

	/// Whether `text` starts with `prefix`, letters in either case alike (SimpleLowerCase): what
	/// type-ahead matches.
	public static bool StartsWithIgnoringCase(StringView text, StringView prefix)
	{
		int t = 0;
		int p = 0;
		while (p < prefix.Length)
		{
			if (t >= text.Length)
				return false;
			if (SimpleLowerCase((char32)DecodeCodepoint(text, ref t)) != SimpleLowerCase((char32)DecodeCodepoint(prefix, ref p)))
				return false;
		}
		return true;
	}

	/// `text`'s mnemonic, in `outMnemonic` (its shown text cleared first).
	public static void ParseMnemonic(StringView text, Mnemonic outMnemonic)
	{
		outMnemonic.Shown.Clear();
		outMnemonic.Key = (char32)0;
		outMnemonic.Start = 0;
		outMnemonic.End = 0;
		for (int i = 0; i < text.Length;)
		{
			if ((text[i] == '&') && (i + 1 < text.Length))
			{
				if (text[i + 1] == '&')
				{
					outMnemonic.Shown.Append('&');
					i += 2;
					continue;
				}
				if (outMnemonic.Key == (char32)0)
				{
					int next = i + 1;
					let c = DecodeCodepoint(text, ref next);
					outMnemonic.Key = ((c >= (uint32)'A') && (c <= (uint32)'Z')) ? (char32)(c - (uint32)'A' + (uint32)'a') : (char32)c;
					outMnemonic.Start = outMnemonic.Shown.Length;
					outMnemonic.Shown.Append(text.Substring(i + 1, next - i - 1));
					outMnemonic.End = outMnemonic.Shown.Length;
					i = next;
					continue;
				}
			}
			outMnemonic.Shown.Append(text[i]);
			i++;
		}
	}
}

class Text
{
	/// A layout laid out at one width.
	private class LayoutCache
	{
		public TextLayout Layout = new .() ~ delete _;
		public float Width = 0.0f;
		public bool Valid = false;
	}

	private String mString = new .() ~ delete _;
	private bool mRich = false;
	private CachedFont mFont = null; // borrowed (owned by the font service)
	private IFontService mFontService = null; // borrowed
	private FontSelection mSelection = new .() ~ delete _;
	private String mFamily = new .() ~ delete _; // as the sheet names it (empty: the font's own name)
	private IResourceProvider mResources = null; // borrowed
	private Color mColor = .White;
	private TextHAlign mHAlign = .Start;
	private ParagraphDirection mDirection = .();
	private int mUnderlineStart = 0; // a plain text's underlined bytes (a mnemonic)
	private int mUnderlineEnd = 0;
	private TextVAlign mVAlign = .Top;
	private TextWhiteSpace mWhiteSpace = .NoWrap;
	private float mLineHeight = 0.0f;
	private float mLetterSpacing = 0.0f;
	private bool mBreakWords = false;
	private uint32 mMaxLines = 0;
	private TextOverflow mOverflow = .Clip;

	private bool mSynced = false;
	private TextDocument mDocument = new .() ~ delete _;
	private String mPlain = new .() ~ delete _;
	private LayoutCache[2] mCache = .(new LayoutCache(), new LayoutCache());
	private int mNextSlot = 0;

	public this() { }

	/// `font` is borrowed.
	public this(StringView text, CachedFont font)
	{
		mString.Set(text);
		mFont = font;
	}

	/// `font` is borrowed.
	public this(StringView text, CachedFont font, Color color)
	{
		mString.Set(text);
		mFont = font;
		mColor = color;
	}

	public ~this()
	{
		delete mCache[0];
		delete mCache[1];
	}

	// === What it shows ===

	/// Plain text.
	public void SetString(StringView text)
	{
		if (!mRich && (text == mString))
			return;
		mString.Set(text);
		mRich = false;
		Dirty();
	}

	/// A rich text's markup ([b], [color=], [link=] and the rest, TextRuns.bf).
	public void SetMarkup(StringView markup)
	{
		if (mRich && (markup == mString))
			return;
		mString.Set(markup);
		mRich = true;
		Dirty();
	}

	/// Underlines bytes [start, end) of a plain text (a mnemonic's letter); start == end: none.
	public void SetUnderline(int start, int end)
	{
		if ((start == mUnderlineStart) && (end == mUnderlineEnd))
			return;
		mUnderlineStart = start;
		mUnderlineEnd = end;
		Dirty();
	}

	/// What was set: the plain text, or the markup.
	public StringView GetString() => mString;

	public bool IsRich => mRich;
	public bool IsEmpty => mString.Length == 0;

	/// The runs it lays out (spaces collapsed where its white-space says).
	public TextDocument Document
	{
		get
		{
			Sync();
			return mDocument;
		}
	}

	/// The text it lays out, markup taken out and spaces collapsed: what the layout's offsets count.
	public StringView PlainText
	{
		get
		{
			Sync();
			return mPlain;
		}
	}

	// === How it looks ===

	/// Borrowed.
	public CachedFont Font
	{
		get => mFont;
		set
		{
			if (value === mFont)
				return;
			mFont = value;
			Dirty();
		}
	}

	/// What of the font CSS chose past its size: the family as the sheet names it (its faces are
	/// named after it, not after the font file's own name), the fallback families, the weight and
	/// the style; and the service that has those faces (a rich text's own faces come from it too).
	/// `service` is borrowed; `selection` is copied.
	public void SetFontSelection(IFontService service, StringView family, FontSelection selection)
	{
		if (!selection.IsDefault)
			FontService = service;
		if (selection.Equals(mSelection) && (family == mFamily))
			return;
		mSelection.Set(selection);
		mFamily.Set(family);
		Dirty();
	}

	/// A font that can draw (one is set and loaded).
	public bool HasFont => (mFont != null) && (mFont.Font != null);

	/// Resolves runs that set a family, a size, bold or italic of their own (null: they take its
	/// font). Borrowed.
	public IFontService FontService
	{
		get => mFontService;
		set
		{
			if (value === mFontService)
				return;
			mFontService = value;
			Dirty();
		}
	}

	/// Loads a rich text's inline icons (null: they keep their space, undrawn). Borrowed.
	public void SetResourceProvider(IResourceProvider resources) => mResources = resources;

	public Color Color
	{
		get => mColor;
		set
		{
			if (value == mColor)
				return;
			mColor = value;
			Dirty();
		}
	}

	public void SetAlignment(TextHAlign horizontal, TextVAlign vertical)
	{
		if ((horizontal == mHAlign) && (vertical == mVAlign))
			return;
		mHAlign = horizontal;
		mVAlign = vertical;
		Dirty();
	}

	public TextHAlign HAlign => mHAlign;
	public TextVAlign VAlign => mVAlign;

	/// Which way its paragraphs run: left to right, right to left, or (Auto) as each one's first
	/// strong character says.
	public ParagraphDirection Direction
	{
		get => mDirection;
		set
		{
			if (value == mDirection)
				return;
			mDirection = value;
			Dirty();
		}
	}

	/// CSS's white-space: whether spaces collapse and lines wrap. A Text starts as NoWrap (one line,
	/// spaces collapsed), a widget's usual text; a sheet's `white-space: normal` wraps it.
	public TextWhiteSpace WhiteSpace
	{
		get => mWhiteSpace;
		set
		{
			if (value == mWhiteSpace)
				return;
			mWhiteSpace = value;
			Dirty();
		}
	}

	public bool IsWrapping => Wraps(mWhiteSpace);

	/// Each line's height in pixels (0: the font's own).
	public void SetLineHeight(float pixels)
	{
		if (pixels == mLineHeight)
			return;
		mLineHeight = Math.Max(0.0f, pixels);
		Dirty();
	}

	/// What SetLineHeight set (0: the font's own).
	public float LineHeightSetting => mLineHeight;

	public float LetterSpacing
	{
		get => mLetterSpacing;
		set
		{
			if (value == mLetterSpacing)
				return;
			mLetterSpacing = value;
			Dirty();
		}
	}

	/// CSS's overflow-wrap: a word wider than its line breaks between its characters (break-word,
	/// anywhere) rather than running out of its box (normal).
	public bool BreakWords
	{
		get => mBreakWords;
		set
		{
			if (value == mBreakWords)
				return;
			mBreakWords = value;
			Dirty();
		}
	}

	public TextOverflow Overflow
	{
		get => mOverflow;
		set
		{
			if (value == mOverflow)
				return;
			mOverflow = value;
			Dirty();
		}
	}

	/// The most lines it shows (line-clamp); 0: all.
	public uint32 MaxLines
	{
		get => mMaxLines;
		set
		{
			if (value == mMaxLines)
				return;
			mMaxLines = value;
			Dirty();
		}
	}

	// === Measurement (0 with no font) ===

	/// Its width on one line, unbroken but where the text breaks.
	public float Width => HasFont ? LayoutAt(0.0f).Width : 0.0f;

	/// One line's height: the line height set, or the font's.
	public float LineHeight
	{
		get
		{
			if (!HasFont)
				return 0.0f;
			return (mLineHeight > 0.0f) ? mLineHeight : mFont.Font.Metrics.LineHeight;
		}
	}

	/// Its size unbounded (one line unless the text breaks it).
	public Float2 Measure()
	{
		if (!HasFont)
			return .(0.0f, 0.0f);
		let layout = LayoutAt(0.0f);
		return .(layout.Width, layout.Height);
	}

	/// Its size laid out in `maxWidth` (wrapped where its white-space wraps: at no width, a line a
	/// word, its min-content; at cUnbounded, unbroken); an empty text measures zero.
	public Float2 MeasureWrapped(float maxWidth)
	{
		if (!HasFont || IsEmpty)
			return .(0.0f, 0.0f);
		let bounded = IsWrapping && (maxWidth < 1.0e8f);
		let layout = LayoutAt(bounded ? Math.Max(maxWidth, 0.01f) : 0.0f);
		return .(layout.Width, layout.Height);
	}

	/// The layout it draws in `bounds` (laid out at their width). Borrowed: valid until the next
	/// change or layout at another width.
	public TextLayout LayoutFor(Rect bounds) => LayoutAt(BoundedWidth(bounds.Width));

	/// Where the layout's origin goes in `bounds` (its block aligned up and down).
	public Float2 Origin(Rect bounds)
	{
		let layout = LayoutFor(bounds);
		float top = bounds.Top;
		if (mVAlign == .Middle)
			top += (bounds.Height - layout.Height) * 0.5f;
		else if (mVAlign == .Bottom)
			top += bounds.Height - layout.Height;
		return .(bounds.Left, top);
	}

	/// Where Draw(ctx, bounds) puts the first line's baseline.
	public float FirstBaseline(Rect bounds)
	{
		if (!HasFont)
			return bounds.Top + bounds.Height;
		let layout = LayoutFor(bounds);
		let first = layout.Lines.IsEmpty ? mFont.Font.Metrics.Ascent : layout.Lines[0].Baseline;
		return Origin(bounds).Y + first;
	}

	/// The link id under `point` when drawn in `bounds` (empty: none).
	public StringView LinkAt(Rect bounds, Float2 point)
	{
		if (!mRich || !HasFont)
			return default;
		let origin = Origin(bounds);
		let run = LayoutFor(bounds).LinkAt(.(point.X - origin.X, point.Y - origin.Y));
		return (run >= 0) ? (StringView)mDocument.Runs[run].Link : default;
	}

	// === Drawing ===

	/// Draws at `position` (the top-left), unbounded.
	public void Draw(DrawContext ctx, Float2 position)
	{
		if (!HasFont || IsEmpty)
			return;
		DrawLayout(ctx, LayoutAt(0.0f), position);
	}

	/// Draws aligned within `bounds`.
	public void Draw(DrawContext ctx, Rect bounds)
	{
		if (!HasFont || IsEmpty)
			return;
		DrawLayout(ctx, LayoutFor(bounds), Origin(bounds));
	}

	/// Draws a layout at `origin` (a field draws its own, scrolled).
	public void DrawLayout(DrawContext ctx, TextLayout layout, Float2 origin)
	{
		var profiled = ProfileScope("GUI.Draw.Text"); // the glyphs into the batch
		defer profiled.Dispose();
		Sync();
		let g = ctx.VG;
		bool anyEffects = false;
		for (let run in mDocument.Runs)
			anyEffects = anyEffects || (run.EffectParts != 0);
		if (anyEffects)
		{
			// Every run's effects (its own over the node's) under every run's glyphs, so one run's
			// outline or shadow never covers its neighbour.
			let inherited = g.TextEffects;
			g.PushState();
			g.SetTextEffectsOnly(true);
			for (let run in layout.GlyphRuns)
			{
				let effects = (run.Run >= 0) ? mDocument.Runs[run.Run].EffectsOver(inherited) : inherited;
				if (!effects.Any)
					continue;
				g.SetTextEffects(effects);
				DrawRun(ctx, run, origin);
			}
			g.PopState();
			g.PushState();
			g.ClearTextEffects();
		}
		for (let run in layout.GlyphRuns)
			DrawRun(ctx, run, origin);
		if (anyEffects)
			g.PopState();
		for (let underline in layout.Underlines)
		{
			let r = underline.Rect;
			g.FillRect(.(r.X + origin.X, r.Y + origin.Y, r.Width, r.Height), underline.TextColor);
		}
		for (let icon in layout.Icons)
		{
			if (mResources == null)
				break;
			let run = mDocument.Runs[icon.Run];
			let r = Rectangle(icon.Rect.X + origin.X, icon.Rect.Y + origin.Y, icon.Rect.Width, icon.Rect.Height);
			if (IsSvgSource(run.Icon)) // drawn as paths, crisp at the line's size
			{
				let svg = mResources.Svg(run.Icon);
				if (svg != null)
					SVGRenderer.Render(g, svg, r);
			}
			else
			{
				let image = mResources.LoadImage(run.Icon);
				if (image != null)
					g.DrawImage(image, r);
			}
		}
	}

	private static float BoundedWidth(float width) => ((width > 0.0f) && (width < 1.0e8f)) ? width : 0.0f;

	private void Dirty()
	{
		mSynced = false;
		mCache[0].Valid = false;
		mCache[1].Valid = false;
	}

	// The runs from the string (parsed when rich), spaces collapsed where white-space says.
	private void Sync()
	{
		if (mSynced)
			return;
		mSynced = true;
		let document = mDocument;
		if (mRich)
			ParseTextMarkup(mString, document);
		else
			TextDocument.Plain(mString, document);
		// A plain text's underlined range (a mnemonic): its own run between the rest.
		if (!mRich && (mUnderlineStart < mUnderlineEnd) && (mUnderlineEnd <= mString.Length) && (document.Runs.Count == 1))
		{
			let middle = new TextRun();
			middle.Set(document.Runs[0]);
			let after = new TextRun();
			after.Set(document.Runs[0]);
			StringView all = mString;
			document.Runs[0].Text.Set(all.Substring(0, mUnderlineStart));
			middle.Text.Set(all.Substring(mUnderlineStart, mUnderlineEnd - mUnderlineStart));
			middle.Underline = true;
			after.Text.Set(all.Substring(mUnderlineEnd, all.Length - mUnderlineEnd));
			document.Runs.Add(middle);
			document.Runs.Add(after);
			for (int r = document.Runs.Count - 1; r >= 0; r--)
			{
				if (document.Runs[r].Text.Length == 0)
				{
					delete document.Runs[r];
					document.Runs.RemoveAt(r);
				}
			}
		}
		if (CollapsesSpaces(mWhiteSpace))
		{
			// Spaces, tabs and line breaks become one space; none at the start or the end.
			bool lastSpace = true;
			let collapsed = scope String();
			for (let run in document.Runs)
			{
				if (run.IsIcon)
				{
					lastSpace = false;
					continue;
				}
				collapsed.Clear();
				for (int i = 0; i < run.Text.Length; i++)
				{
					let c = run.Text[i];
					let space = (c == ' ') || (c == '\t') || (c == '\n') || (c == '\r');
					if (space && lastSpace)
						continue;
					collapsed.Append(space ? ' ' : c);
					lastSpace = space;
				}
				run.Text.Set(collapsed);
			}
			for (int r = document.Runs.Count - 1; r >= 0; r--)
			{
				let run = document.Runs[r];
				if (run.IsIcon)
					break;
				while ((run.Text.Length != 0) && (run.Text[run.Text.Length - 1] == ' '))
					run.Text.RemoveFromEnd(1);
				if (run.Text.Length != 0)
					break;
			}
			for (int r = document.Runs.Count - 1; r >= 0; r--)
			{
				if (!document.Runs[r].IsIcon && (document.Runs[r].Text.Length == 0))
				{
					delete document.Runs[r];
					document.Runs.RemoveAt(r);
				}
			}
		}
		mPlain.Clear();
		mDocument.PlainText(mPlain);
	}

	private TextLayout LayoutAt(float maxWidth)
	{
		Sync();
		for (let cache in mCache)
			if (cache.Valid && (cache.Width == maxWidth))
				return cache.Layout;
		let slot = mCache[mNextSlot];
		mNextSlot = (mNextSlot + 1) % 2;
		let style = scope TextLayoutStyle();
		style.Font = mFont;
		style.Fonts = mFontService;
		if (HasFont)
		{
			if (mFamily.Length != 0)
				style.Family.Set(mFamily);
			else
				mFont.Font.GetFamilyName(style.Family);
			style.Size = mFont.Font.PixelHeight;
		}
		style.Selection.Set(mSelection);
		style.TextColor = mColor;
		style.Align = mHAlign;
		style.Wrap = IsWrapping;
		style.MaxWidth = maxWidth;
		style.LineHeight = mLineHeight;
		style.LetterSpacing = mLetterSpacing;
		style.BreakWords = mBreakWords;
		style.MaxLines = mMaxLines;
		style.Overflow = mOverflow;
		style.Direction = mDirection.Direction;
		style.AutoRightToLeft = mDirection.AutoRightToLeft;
		LayOutText(mDocument, style, slot.Layout);
		slot.Width = maxWidth;
		slot.Valid = true;
		return slot.Layout;
	}

	// One run's glyphs, slanted when its italic is synthesized and twice when its bold is; a run its
	// font could not shape, as text.
	private void DrawRun(DrawContext ctx, LaidOutGlyphs run, Float2 origin)
	{
		let g = ctx.VG;
		if (run.Unshaped)
		{
			let text = StringView(mPlain).Substring(run.TextStart, run.TextEnd - run.TextStart);
			g.DrawText(text, run.Font, .(origin.X + run.X, origin.Y + run.Baseline), run.TextColor);
			return;
		}
		if (run.SyntheticItalic)
		{
			// Lean the glyphs about their baseline: x moves right by a fifth of the height above it.
			g.PushState();
			var lean = Float4x4.Identity();
			let baseline = origin.Y + run.Baseline;
			lean.M[1][0] = -0.2f;
			lean.M[3][0] = 0.2f * baseline;
			g.SetTransform(lean * g.GetTransform());
		}
		g.DrawPositionedGlyphs(run.Glyphs, run.Font, origin.X, origin.Y, run.TextColor);
		if (run.SyntheticBold && !g.TextEffectsOnly) // effects once, under both strokes
			g.DrawPositionedGlyphs(run.Glyphs, run.Font, origin.X + Math.Max(0.5f, run.Size / 24.0f), origin.Y, run.TextColor);
		if (run.SyntheticItalic)
			g.PopState();
	}
}
