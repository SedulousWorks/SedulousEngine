using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// Rich text as runs: styled spans of text and inline icons, and the small markup that writes them,
// the same from markup and from script:
//
//   Your mark wears [color=#d04060][b]a rose gown[/b][/color] [icon=Icons/rose.png] [link=hint]?[/link]
//
// Tags: [b] bold, [i] italic, [u] underline, [color=#rrggbb | #rrggbbaa | name | rgb()],
// [size=<px>], [font=<family>], [link=<id>] (a span the label reports when clicked),
// [outline=<width> [colour]], [shadow=<x> <y> [blur] [colour]], [glow=<radius> [colour]] (text
// effects, drawn under the span's glyphs; a width or radius of 0 turns one off), each closed by
// [/name] or [/] (the innermost); [icon=<image path>] stands alone. "[[" is a literal "[". A tag
// that is malformed or unknown, or a close that matches nothing, is kept as text and reported in
// the diagnostics, never dropped.
//
// Copied from foundation.ui's text runs, and the GUI's own from then on: its names follow the
// GUI's, and colours parse as the GUI's sheets parse them.
//
// A run owns its strings and is copied (a frame's style is the next run's start), so it is a class
// with a deep Set; a document owns its runs and its diagnostics.

/// The parts of TextEffects a run may set apart from each other.
enum TextEffectPart : uint8
{
	TextEffectOutline = 1,
	TextEffectShadow = 2,
	TextEffectGlow = 4,
}

/// One styled span of a rich text, or an inline icon. A style field left unset takes the label's
/// (its font family, size and text colour).
class TextRun
{
	public String Text = new .() ~ delete _;
	/// An image path: an inline icon sitting on the baseline (Text is empty).
	public String Icon = new .() ~ delete _;
	/// Null when unset.
	public String Family ~ delete _;
	public float? Size;
	public Color? TextColor;
	public bool Bold = false;
	public bool Italic = false;
	public bool Underline = false;
	/// A link id the label reports when the run is clicked; empty for none.
	public String Link = new .() ~ delete _;
	/// The effects the markup set, those parts named in EffectParts (TextEffectPart); the parts
	/// left out take the label's.
	public TextEffects Effects = .();
	public uint8 EffectParts = 0;

	public bool IsIcon => Icon.Length != 0;

	/// Whether it sets nothing of its own: it draws in the label's font and colour.
	public bool IsPlain => (Family == null) && !Size.HasValue && !TextColor.HasValue && !Bold && !Italic && !Underline &&
		(Link.Length == 0) && (EffectParts == 0) && !IsIcon;

	/// Sets the family.
	public void SetFamily(StringView family)
	{
		if (Family == null)
			Family = new .();
		Family.Set(family);
	}

	/// Unsets the family: the run takes the label's.
	public void ClearFamily()
	{
		DeleteAndNullify!(Family);
	}

	/// Makes this a copy of `other`.
	public void Set(TextRun other)
	{
		if (other === this)
			return;
		Text.Set(other.Text);
		Icon.Set(other.Icon);
		if (other.Family == null)
			ClearFamily();
		else
			SetFamily(other.Family);
		Size = other.Size;
		TextColor = other.TextColor;
		Bold = other.Bold;
		Italic = other.Italic;
		Underline = other.Underline;
		Link.Set(other.Link);
		Effects = other.Effects;
		EffectParts = other.EffectParts;
	}

	/// Same style (and link), so two runs may merge.
	public bool SameStyle(TextRun other)
	{
		let sameFamily = (Family == null) ? (other.Family == null) : ((other.Family != null) && (Family == other.Family));
		let sameSize = (Size.HasValue == other.Size.HasValue) && (!Size.HasValue || (Size.Value == other.Size.Value));
		let sameColor = (TextColor.HasValue == other.TextColor.HasValue) && (!TextColor.HasValue || (TextColor.Value == other.TextColor.Value));
		return !IsIcon && !other.IsIcon && sameFamily && sameSize && sameColor && (Bold == other.Bold) && (Italic == other.Italic) &&
			(Underline == other.Underline) && (Link == other.Link) && (EffectParts == other.EffectParts) && (Effects == other.Effects);
	}

	/// `inherited` (the label's effects) with the parts this run sets in their place.
	public TextEffects EffectsOver(TextEffects inherited)
	{
		var result = inherited;
		if ((EffectParts & (uint8)TextEffectPart.TextEffectOutline) != 0)
		{
			result.OutlineWidth = Effects.OutlineWidth;
			result.OutlineColor = Effects.OutlineColor;
		}
		if ((EffectParts & (uint8)TextEffectPart.TextEffectShadow) != 0)
		{
			result.ShadowOffset = Effects.ShadowOffset;
			result.ShadowBlur = Effects.ShadowBlur;
			result.ShadowColor = Effects.ShadowColor;
		}
		if ((EffectParts & (uint8)TextEffectPart.TextEffectGlow) != 0)
		{
			result.GlowRadius = Effects.GlowRadius;
			result.GlowColor = Effects.GlowColor;
		}
		return result;
	}
}

/// A markup problem: where, in bytes, and what. The offending text stays in the runs.
class TextMarkupDiagnostic
{
	public int Offset = 0;
	public String Message = new .() ~ delete _;
}

/// A rich text: its runs in order, and what parsing its markup reported.
class TextDocument
{
	public List<TextRun> Runs = new .() ~ DeleteContainerAndItems!(_);
	public List<TextMarkupDiagnostic> Diagnostics = new .() ~ DeleteContainerAndItems!(_);

	/// Empties it: no runs, no diagnostics.
	public void Clear()
	{
		ClearAndDeleteItems!(Runs);
		ClearAndDeleteItems!(Diagnostics);
	}

	/// One run of plain text (what a label without markup holds), in `outDocument` (cleared
	/// first), which it returns.
	public static TextDocument Plain(StringView text, TextDocument outDocument)
	{
		outDocument.Clear();
		if (text.Length != 0)
		{
			let run = new TextRun();
			run.Text.Set(text);
			outDocument.Runs.Add(run);
		}
		return outDocument;
	}

	/// The text with the markup taken out (an icon is U+FFFC, the object replacement character),
	/// appended to `outText`.
	public void PlainText(String outText)
	{
		for (let run in Runs)
		{
			if (run.IsIcon)
				outText.Append("\u{FFFC}");
			else
				outText.Append(run.Text);
		}
	}
}

/// Resolves a colour name in markup ([color=gold]) beyond what a sheet's colours parse, as a
/// palette would; null leaves only what ParseColor takes.
typealias TextMarkupColorResolver = delegate Color?(StringView name);

static
{
	/// Parse markup into runs, in `outDocument` (cleared first).
	public static void ParseTextMarkup(StringView markup, TextDocument outDocument)
	{
		ParseTextMarkup(markup, null, outDocument);
	}

	/// Parse markup into runs, colour names asked of `resolver` (borrowed; null for none) first, in
	/// `outDocument` (cleared first).
	public static void ParseTextMarkup(StringView markup, TextMarkupColorResolver resolver, TextDocument outDocument)
	{
		outDocument.Clear();
		let parser = scope TextRunsDetail.TextMarkupParser(markup, resolver, outDocument);
		parser.Parse();
	}
}

/// The parser TextRuns.bf keeps out of the public surface, and the number reading it shares
/// with the layout.
internal static class TextRunsDetail
{
	/// `s` without its leading and trailing spaces, tabs and line breaks.
	public static StringView Trimmed(StringView s)
	{
		int start = 0;
		int end = s.Length;
		while ((start < end) && ((s[start] == ' ') || (s[start] == '\t') || (s[start] == '\n') || (s[start] == '\r')))
			start++;
		while ((end > start) && ((s[end - 1] == ' ') || (s[end - 1] == '\t') || (s[end - 1] == '\n') || (s[end - 1] == '\r')))
			end--;
		return s.Substring(start, end - start);
	}

	/// A base-10 number: none unless the whole trimmed view is one.
	public static double? ParseFloat(StringView s)
	{
		let t = Trimmed(s);
		if (t.IsEmpty)
			return null;
		if (double.Parse(t) case .Ok(let value))
			return value;
		return null;
	}

	public class MarkupFrame
	{
		/// The tag that opened it (b, i, u, color, size, font, link, outline, shadow, glow).
		public String Tag = new .() ~ delete _;
		public TextRun Style = new .() ~ delete _;
	}

	public class TextMarkupParser
	{
		private StringView mMarkup;
		private TextMarkupColorResolver mResolver; // borrowed
		private TextDocument mDocument; // borrowed: the caller's
		private List<MarkupFrame> mStack = new .() ~ DeleteContainerAndItems!(_);
		private String mText = new .() ~ delete _;

		public this(StringView markup, TextMarkupColorResolver resolver, TextDocument document)
		{
			mMarkup = markup;
			mResolver = resolver;
			mDocument = document;
		}

		public void Parse()
		{
			int i = 0;
			while (i < mMarkup.Length)
			{
				let c = mMarkup[i];
				if (c != '[')
				{
					mText.Append(c);
					i++;
					continue;
				}
				if ((i + 1 < mMarkup.Length) && (mMarkup[i + 1] == '['))
				{
					mText.Append('['); // "[[": a literal bracket
					i += 2;
					continue;
				}
				int close = i + 1;
				while ((close < mMarkup.Length) && (mMarkup[close] != ']') && (mMarkup[close] != '['))
					close++;
				if ((close >= mMarkup.Length) || (mMarkup[close] != ']'))
				{
					Diagnose(i, "an unclosed '[' (write \"[[\" for a literal bracket)");
					mText.Append(c);
					i++;
					continue;
				}
				let body = mMarkup.Substring(i + 1, close - i - 1);
				if (!Apply(body, i))
					mText.Append(mMarkup.Substring(i, close - i + 1)); // kept as text
				i = close + 1;
			}
			Flush();
		}

		// Apply one tag's body (between the brackets); false when it is not a tag we take.
		private bool Apply(StringView body, int at)
		{
			if ((body.Length != 0) && (body[0] == '/'))
				return Close(ParseUtil.Trim(body.Substring(1, body.Length - 1)), at);
			StringView name = body;
			StringView value = default;
			bool hasValue = false;
			for (int k = 0; k < body.Length; k++)
			{
				if (body[k] == '=')
				{
					name = body.Substring(0, k);
					value = ParseUtil.Trim(body.Substring(k + 1, body.Length - k - 1));
					hasValue = true;
					break;
				}
			}
			name = ParseUtil.Trim(name);
			let style = scope TextRun();
			Current(style);
			if ((name == "b") || (name == "i") || (name == "u"))
			{
				if (hasValue)
					return Reject(at, "[b], [i] and [u] take no value");
				if (name == "b")
					style.Bold = true;
				else if (name == "i")
					style.Italic = true;
				else
					style.Underline = true;
			}
			else if (name == "color")
			{
				let color = ParseMarkupColor(value);
				if (!color.HasValue)
					return Reject(at, "[color=] takes #rrggbb, #rrggbbaa or a colour name");
				style.TextColor = color;
			}
			else if (name == "size")
			{
				let size = ParseFloat(value);
				if (!size.HasValue || (size.Value <= 0.0))
					return Reject(at, "[size=] takes a positive number");
				style.Size = (float)size.Value;
			}
			else if (name == "font")
			{
				if (value.Length == 0)
					return Reject(at, "[font=] takes a family name");
				style.SetFamily(value);
			}
			else if (name == "link")
			{
				if (value.Length == 0)
					return Reject(at, "[link=] takes an id");
				style.Link.Set(value);
			}
			else if ((name == "outline") || (name == "shadow") || (name == "glow"))
			{
				if (!ApplyEffect(name, value, style))
				{
					return Reject(at, (name == "outline") ? "[outline=] takes a width and a colour" :
						(name == "shadow") ? "[shadow=] takes x and y offsets, a blur and a colour" :
						"[glow=] takes a radius and a colour");
				}
			}
			else if (name == "icon")
			{
				if (value.Length == 0)
					return Reject(at, "[icon=] takes an image path");
				Flush();
				let icon = new TextRun();
				Current(icon);
				icon.Icon.Set(value);
				mDocument.Runs.Add(icon);
				return true;
			}
			else
			{
				return Reject(at, "an unknown tag");
			}
			Flush();
			let frame = new MarkupFrame();
			frame.Tag.Set(name);
			frame.Style.Set(style);
			mStack.Add(frame);
			return true;
		}

		// [/name] closes back to the innermost frame of that name (inner ones with it); [/]
		// closes the innermost.
		private bool Close(StringView name, int at)
		{
			if (mStack.IsEmpty)
				return Reject(at, "a close with nothing open");
			int index = mStack.Count - 1;
			if (name.Length != 0)
			{
				while (mStack[index].Tag != name)
				{
					if (index == 0)
						return Reject(at, "a close that matches no open tag");
					index--;
				}
				if (index != mStack.Count - 1)
					Diagnose(at, "closes tags opened inside it");
			}
			Flush();
			while (mStack.Count > index)
				delete mStack.PopBack();
			return true;
		}

		private bool Reject(int at, StringView message)
		{
			Diagnose(at, message);
			return false;
		}

		private void Diagnose(int at, StringView message)
		{
			let diagnostic = new TextMarkupDiagnostic();
			diagnostic.Offset = at;
			diagnostic.Message.Set(message);
			mDocument.Diagnostics.Add(diagnostic);
		}

		// The style the text so far takes: the innermost frame's, or none.
		private void Current(TextRun outStyle)
		{
			if (mStack.IsEmpty)
				outStyle.Set(scope TextRun());
			else
				outStyle.Set(mStack.Back.Style);
		}

		// The text so far becomes a run in the current style (merged into the last when alike).
		private void Flush()
		{
			if (mText.Length == 0)
				return;
			let run = new TextRun();
			Current(run);
			if (!mDocument.Runs.IsEmpty && mDocument.Runs.Back.SameStyle(run))
			{
				mDocument.Runs.Back.Text.Append(mText);
				delete run;
			}
			else
			{
				run.Text.Set(mText);
				mDocument.Runs.Add(run);
			}
			mText.Clear();
		}

		// An effect tag's value: numbers then an optional colour, space separated
		// ([outline=2 #000], [shadow=2 2 3 black], [glow=6 yellow]).
		private bool ApplyEffect(StringView name, StringView value, TextRun style)
		{
			float[3] numbers = default;
			int count = 0;
			Color? color = null;
			int k = 0;
			while (k < value.Length)
			{
				while ((k < value.Length) && (value[k] == ' '))
					k++;
				int end = k;
				while ((end < value.Length) && (value[end] != ' '))
					end++;
				if (end == k)
					break;
				let token = value.Substring(k, end - k);
				k = end;
				if (color.HasValue)
					return false; // the colour comes last
				let number = ParseFloat(token);
				if (number.HasValue)
				{
					if (count == 3)
						return false;
					numbers[count++] = (float)number.Value;
					continue;
				}
				color = ParseMarkupColor(token);
				if (!color.HasValue)
					return false;
			}
			if (name == "outline")
			{
				if ((count != 1) || (numbers[0] < 0.0f))
					return false;
				style.Effects.OutlineWidth = numbers[0];
				style.Effects.OutlineColor = color.HasValue ? color.Value : Color(0.0f, 0.0f, 0.0f, 1.0f);
				style.EffectParts |= (uint8)TextEffectPart.TextEffectOutline;
			}
			else if (name == "shadow")
			{
				if ((count < 2) || ((count == 3) && (numbers[2] < 0.0f)))
					return false;
				style.Effects.ShadowOffset = Float2(numbers[0], numbers[1]);
				style.Effects.ShadowBlur = (count == 3) ? numbers[2] : 0.0f;
				style.Effects.ShadowColor = color.HasValue ? color.Value : Color(0.0f, 0.0f, 0.0f, 0.5f);
				style.EffectParts |= (uint8)TextEffectPart.TextEffectShadow;
			}
			else
			{
				if ((count != 1) || (numbers[0] < 0.0f))
					return false;
				style.Effects.GlowRadius = numbers[0];
				style.Effects.GlowColor = color.HasValue ? color.Value : Color(1.0f, 1.0f, 1.0f, 1.0f);
				style.EffectParts |= (uint8)TextEffectPart.TextEffectGlow;
			}
			return true;
		}

		// The resolver first for a bare name (a palette's "$gold" too), then what a sheet takes.
		private Color? ParseMarkupColor(StringView value)
		{
			if (value.Length == 0)
				return null;
			if ((value[0] != '#') && (mResolver != null))
			{
				let name = (value[0] == '$') ? value.Substring(1, value.Length - 1) : value;
				let named = mResolver(name);
				if (named.HasValue)
					return named;
			}
			return ParseColor(value);
		}
	}
}
