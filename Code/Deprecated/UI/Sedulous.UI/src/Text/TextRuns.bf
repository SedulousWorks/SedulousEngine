using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.UI;

/// The parts of TextEffects a run may set apart from each other.
enum TextEffectPart : uint8
{
	Outline = 1,
	Shadow = 2,
	Glow = 4
}

/// One styled span of a rich text, or an inline icon.
///
/// A style field left unset (null) takes the control's: its font family, size and text colour.
class TextRun
{
	public String Text = new .() ~ delete _;
	/// An image path: an inline icon sitting on the baseline, its Text empty.
	public String Icon = new .() ~ delete _;
	public String Family ~ delete _;
	public float? Size;
	public Sedulous.Core.Color? Color;
	public bool Bold;
	public bool Italic;
	public bool Underline;
	/// A link id the control reports when the run is clicked; empty for none.
	public String Link = new .() ~ delete _;
	/// The effects the markup set, those parts named in EffectParts; the parts left out take
	/// the control's.
	public TextEffects Effects = .();
	public TextEffectPart EffectParts;

	public bool IsIcon => !Icon.IsEmpty;

	/// `inherited` (the control's effects) with the parts this run sets in their place.
	public TextEffects EffectsOver(TextEffects inherited)
	{
		var effects = inherited;
		if (EffectParts.HasFlag(.Outline))
		{
			effects.OutlineWidth = Effects.OutlineWidth;
			effects.OutlineColor = Effects.OutlineColor;
		}
		if (EffectParts.HasFlag(.Shadow))
		{
			effects.ShadowOffset = Effects.ShadowOffset;
			effects.ShadowBlur = Effects.ShadowBlur;
			effects.ShadowColor = Effects.ShadowColor;
		}
		if (EffectParts.HasFlag(.Glow))
		{
			effects.GlowRadius = Effects.GlowRadius;
			effects.GlowColor = Effects.GlowColor;
		}
		return effects;
	}

	/// Same style and link, so two runs may merge.
	public bool SameStyle(TextRun other)
	{
		return Icon.IsEmpty && other.Icon.IsEmpty && (StringView(Family) == StringView(other.Family))
			&& ((Family == null) == (other.Family == null)) && (Size == other.Size) && SameColor(Color, other.Color)
			&& (Bold == other.Bold) && (Italic == other.Italic) && (Underline == other.Underline)
			&& (Link == other.Link) && (EffectParts == other.EffectParts) && (Effects == other.Effects);
	}

	/// A copy of the style, with no text or icon.
	public TextRun CopyStyle()
	{
		let copy = new TextRun();
		if (Family != null)
			copy.Family = new .(Family);
		copy.Size = Size;
		copy.Color = Color;
		copy.Bold = Bold;
		copy.Italic = Italic;
		copy.Underline = Underline;
		copy.Link.Set(Link);
		copy.Effects = Effects;
		copy.EffectParts = EffectParts;
		return copy;
	}

	private static bool SameColor(Sedulous.Core.Color? a, Sedulous.Core.Color? b)
	{
		if (a.HasValue != b.HasValue)
			return false;
		if (!a.HasValue)
			return true;
		let x = a.Value;
		let y = b.Value;
		return (x.R == y.R) && (x.G == y.G) && (x.B == y.B) && (x.A == y.A);
	}
}

/// A markup problem: where, in bytes, and what. The offending text stays in the runs.
struct TextMarkupDiagnostic
{
	public int Offset;
	public StringView Message;

	public this(int offset, StringView message)
	{
		Offset = offset;
		Message = message;
	}
}

/// A rich text: its runs in order, and what parsing its markup reported.
class TextDocument
{
	public List<TextRun> Runs = new .() ~ DeleteContainerAndItems!(_);
	public List<TextMarkupDiagnostic> Diagnostics = new .() ~ delete _;

	/// The text with the markup taken out; an icon is U+FFFC, the object replacement character.
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

/// The small bracket markup rich text is written in, the same from markup and from script:
///
/// `Your mark wears [color=#d04060][b]a rose gown[/b][/color] [icon=Icons/rose.png] [link=hint]?[/link]`
///
/// Tags: [b] bold, [i] italic, [u] underline, [color=#rrggbb | #rrggbbaa | name], [size=<dp>],
/// [font=<family>], [link=<id>] (a span the control reports when clicked), [outline=<width>
/// [colour]], [shadow=<x> <y> [blur] [colour]], [glow=<radius> [colour]] (text effects, drawn under
/// the span's glyphs; a width or radius of 0 turns one off), each closed by [/name] or [/] (the
/// innermost); [icon=<image path>] stands alone. "[[" is a literal "[". A tag that is
/// malformed or unknown, or a close that matches nothing, is kept as text and reported in the
/// diagnostics, never dropped. Adjacent runs of one style merge.
static class TextMarkup
{
	/// Parses markup into runs; the caller owns the document. `resolver` resolves a colour name
	/// ([color=gold]) beyond the named CSS colours, as a palette would.
	public static TextDocument Parse(StringView markup, delegate Color?(StringView name) resolver = null)
	{
		let parser = scope TextMarkupParser(markup, resolver);
		return parser.Parse();
	}
}

/// One open tag: the name that opened it, and the style inside it.
class TextMarkupFrame
{
	public String Tag = new .() ~ delete _;
	public TextRun Style ~ delete _;
}

class TextMarkupParser
{
	private StringView mMarkup;
	private delegate Color?(StringView name) mResolver;
	private TextDocument mDocument = new .();
	private List<TextMarkupFrame> mStack = new .() ~ DeleteContainerAndItems!(_);
	private String mText = new .() ~ delete _;

	public this(StringView markup, delegate Color?(StringView name) resolver)
	{
		mMarkup = markup;
		mResolver = resolver;
	}

	/// The document; the caller owns it.
	public TextDocument Parse()
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
				// "[[": a literal bracket.
				mText.Append('[');
				i += 2;
				continue;
			}
			var close = i + 1;
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
		let document = mDocument;
		mDocument = null;
		return document;
	}

	public ~this()
	{
		delete mDocument;
	}

	/// Applies one tag's body, between the brackets; false when it is not a tag this takes.
	private bool Apply(StringView body, int at)
	{
		if (!body.IsEmpty && (body[0] == '/'))
		{
			var name = body.Substring(1);
			name.Trim();
			return Close(name, at);
		}
		var name = body;
		var value = StringView();
		var hasValue = false;
		let equals = body.IndexOf('=');
		if (equals >= 0)
		{
			name = body.Substring(0, equals);
			value = body.Substring(equals + 1);
			value.Trim();
			hasValue = true;
		}
		name.Trim();

		let style = Current();
		switch (name)
		{
		case "b", "i", "u":
			if (hasValue)
			{
				delete style;
				return Reject(at, "[b], [i] and [u] take no value");
			}
			if (name == "b")
				style.Bold = true;
			else if (name == "i")
				style.Italic = true;
			else
				style.Underline = true;
		case "color":
			let color = ParseColor(value);
			if (!color.HasValue)
			{
				delete style;
				return Reject(at, "[color=] takes #rrggbb, #rrggbbaa or a colour name");
			}
			style.Color = color;
		case "size":
			if (!(float.Parse(value) case .Ok(let size)) || (size <= 0.0f))
			{
				delete style;
				return Reject(at, "[size=] takes a positive number");
			}
			style.Size = size;
		case "font":
			if (value.IsEmpty)
			{
				delete style;
				return Reject(at, "[font=] takes a family name");
			}
			delete style.Family;
			style.Family = new .(value);
		case "link":
			if (value.IsEmpty)
			{
				delete style;
				return Reject(at, "[link=] takes an id");
			}
			style.Link.Set(value);
		case "outline", "shadow", "glow":
			if (!ApplyEffect(name, value, style))
			{
				delete style;
				switch (name)
				{
				case "outline": return Reject(at, "[outline=] takes a width and a colour");
				case "shadow": return Reject(at, "[shadow=] takes x and y offsets, a blur and a colour");
				default: return Reject(at, "[glow=] takes a radius and a colour");
				}
			}
		case "icon":
			if (value.IsEmpty)
			{
				delete style;
				return Reject(at, "[icon=] takes an image path");
			}
			Flush();
			style.Icon.Set(value);
			mDocument.Runs.Add(style);
			return true;
		default:
			delete style;
			return Reject(at, "an unknown tag");
		}
		Flush();
		let frame = new TextMarkupFrame();
		frame.Tag.Set(name);
		frame.Style = style;
		mStack.Add(frame);
		return true;
	}

	/// [/name] closes back to the innermost frame of that name, inner ones with it; [/] closes
	/// the innermost.
	private bool Close(StringView name, int at)
	{
		if (mStack.IsEmpty)
			return Reject(at, "a close with nothing open");
		var index = mStack.Count - 1;
		if (!name.IsEmpty)
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
		mDocument.Diagnostics.Add(.(at, message));
	}

	/// A new run in the current style; the caller owns it.
	private TextRun Current() => mStack.IsEmpty ? new TextRun() : mStack.Back.Style.CopyStyle();

	/// The text so far becomes a run in the current style, merged into the last when alike.
	private void Flush()
	{
		if (mText.IsEmpty)
			return;
		let run = Current();
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

	/// An effect tag's value: numbers then an optional colour, space separated ([outline=2 #000],
	/// [shadow=2 2 3 black], [glow=6 yellow]).
	private bool ApplyEffect(StringView name, StringView value, TextRun style)
	{
		float[3] numbers = default;
		int count = 0;
		Color? color = null;
		for (let token in value.Split(' ', .RemoveEmptyEntries))
		{
			if (color.HasValue)
				return false; // the colour comes last
			if (float.Parse(token) case .Ok(let number))
			{
				if (count == 3)
					return false;
				numbers[count++] = number;
				continue;
			}
			color = ParseColor(token);
			if (!color.HasValue)
				return false;
		}

		switch (name)
		{
		case "outline":
			if ((count != 1) || (numbers[0] < 0.0f))
				return false;
			style.Effects.OutlineWidth = numbers[0];
			style.Effects.OutlineColor = color ?? .(0.0f, 0.0f, 0.0f, 1.0f);
			style.EffectParts |= .Outline;
		case "shadow":
			if ((count < 2) || ((count == 3) && (numbers[2] < 0.0f)))
				return false;
			style.Effects.ShadowOffset = .(numbers[0], numbers[1]);
			style.Effects.ShadowBlur = (count == 3) ? numbers[2] : 0.0f;
			style.Effects.ShadowColor = color ?? .(0.0f, 0.0f, 0.0f, 0.5f);
			style.EffectParts |= .Shadow;
		default:
			if ((count != 1) || (numbers[0] < 0.0f))
				return false;
			style.Effects.GlowRadius = numbers[0];
			style.Effects.GlowColor = color ?? .(1.0f, 1.0f, 1.0f, 1.0f);
			style.EffectParts |= .Glow;
		}
		return true;
	}

	private Color? ParseColor(StringView value)
	{
		if (value.IsEmpty)
			return null;
		if (value[0] == '#')
			return StyleValueParser.ParseHexColor(value);
		if (mResolver != null)
		{
			let name = (value[0] == '$') ? value.Substring(1) : value;
			let named = mResolver(name);
			if (named.HasValue)
				return named;
		}
		return StyleValueParser.ParseNamedColor(value);
	}
}
