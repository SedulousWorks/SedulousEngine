using System;
using System.Collections;

namespace Sedulous.GUI;

// MediaQuery + MediaContext: `@media` condition evaluation. Ported from eepp's css/MediaQuery
// (common subset), then widened: a comma list of queries (any one matching), each optionally
// `not`, a media type (`all`, `screen`; `print` never) and feature tests joined by `and`: width,
// height and resolution (min-, max-, exact), orientation, and the host's preferences,
// prefers-color-scheme, prefers-contrast and prefers-reduced-motion, and `input` (pointer,
// keyboard or pad, the kind in use). A rule carries an (optional) MediaQuery; StyleSheet.Resolve
// skips rules whose query does not match the MediaContext; a query naming any other feature
// matches nothing. Deferred: aspect-ratio, range syntax (`width >= 600px`), `or` inside a query.
//
// A query owns its lists, so it is a class, with a deep Set.

/// How much contrast the user asks for (CSS's prefers-contrast).
enum ContrastPreference : uint8
{
	NoPreference,
	More,
	Less,
}

/// The environment a media query is evaluated against: the viewport, and what the host knows of
/// the user's preferences (its platform's dark mode, contrast and reduced-motion settings).
struct MediaContext : IEquatable<MediaContext>
{
	public float Width = 0.0f;
	public float Height = 0.0f;
	public float Dpi = 96.0f;
	/// prefers-color-scheme: dark (else light).
	public bool DarkScheme = true;
	public ContrastPreference Contrast = .NoPreference;
	/// prefers-reduced-motion: reduce.
	public bool ReducedMotion = false;
	/// `input`: what drives the GUI now.
	public InputKind Input = .Pointer;

	public this() { }

	public this(float width, float height, float dpi)
	{
		Width = width;
		Height = height;
		Dpi = dpi;
	}

	public bool Equals(MediaContext other) => this == other;

	[Commutable]
	public static bool operator==(MediaContext a, MediaContext b) =>
		(a.Width == b.Width) && (a.Height == b.Height) && (a.Dpi == b.Dpi) && (a.DarkScheme == b.DarkScheme) &&
		(a.Contrast == b.Contrast) && (a.ReducedMotion == b.ReducedMotion) && (a.Input == b.Input);
}

enum MediaFeatureType
{
	MinWidth,
	MaxWidth,
	MinHeight,
	MaxHeight,
	Width,
	Height,
	/// In dpi: 1dppx (1x) is 96dpi.
	MinResolution,
	MaxResolution,
	Resolution,
	/// orientation: portrait (height at least width).
	Portrait,
	Landscape,
	/// prefers-color-scheme.
	Dark,
	Light,
	/// prefers-contrast.
	ContrastMore,
	ContrastLess,
	/// prefers-contrast: no-preference.
	ContrastNone,
	/// (prefers-contrast): any preference.
	ContrastAny,
	/// prefers-reduced-motion: reduce.
	ReduceMotion,
	NoMotionPreference,
	/// input: pointer (the input kind in use, not a device's presence).
	InputPointer,
	InputKeyboard,
	InputPad,
}

struct MediaFeature
{
	public MediaFeatureType Type;
	public float Value = 0.0f;

	public this(MediaFeatureType type, float value)
	{
		Type = type;
		Value = value;
	}
}

/// A list of queries, any one of which matching matches; each a conjunction of feature tests,
/// perhaps negated. An empty list always matches; a query with a feature the GUI does not know
/// never does (CSS's "not all"), so a rule written for a feature it cannot test is not applied
/// everywhere.
class MediaQuery
{
	private class Query
	{
		public List<MediaFeature> Features = new .() ~ delete _;
		public bool Not = false;
		/// A feature it cannot test, or a type it is not (print): false, and `not` does not save it.
		public bool Never = false;
	}

	private List<Query> mQueries = new .() ~ DeleteContainerAndItems!(_);

	public this()
	{
	}

	public this(StringView text)
	{
		Parse(text);
	}

	public void Set(MediaQuery other)
	{
		if (other === this)
			return;
		ClearAndDeleteItems!(mQueries);
		for (let q in other.mQueries)
		{
			let copy = new Query();
			copy.Features.AddRange(q.Features);
			copy.Not = q.Not;
			copy.Never = q.Never;
			mQueries.Add(copy);
		}
	}

	public bool IsEmpty => mQueries.IsEmpty;

	/// The feature tests of every query in the list.
	public int FeatureCount
	{
		get
		{
			int n = 0;
			for (let q in mQueries)
				n += q.Features.Count;
			return n;
		}
	}

	public bool Evaluate(MediaContext context)
	{
		if (mQueries.IsEmpty)
			return true;
		for (let q in mQueries)
		{
			if (EvaluateQuery(q, context))
				return true;
		}
		return false;
	}

	private static bool EvaluateQuery(Query q, MediaContext c)
	{
		if (q.Never)
			return false;
		bool all = true;
		for (let f in q.Features)
			all = all && EvaluateFeature(f, c);
		return all != q.Not;
	}

	private static bool EvaluateFeature(MediaFeature f, MediaContext c)
	{
		switch (f.Type)
		{
		case .MinWidth: return c.Width >= f.Value;
		case .MaxWidth: return c.Width <= f.Value;
		case .MinHeight: return c.Height >= f.Value;
		case .MaxHeight: return c.Height <= f.Value;
		case .Width: return c.Width == f.Value;
		case .Height: return c.Height == f.Value;
		case .MinResolution: return c.Dpi >= f.Value;
		case .MaxResolution: return c.Dpi <= f.Value;
		case .Resolution: return c.Dpi == f.Value;
		case .Portrait: return c.Height >= c.Width;
		case .Landscape: return c.Width > c.Height;
		case .Dark: return c.DarkScheme;
		case .Light: return !c.DarkScheme;
		case .ContrastMore: return c.Contrast == .More;
		case .ContrastLess: return c.Contrast == .Less;
		case .ContrastNone: return c.Contrast == .NoPreference;
		case .ContrastAny: return c.Contrast != .NoPreference;
		case .ReduceMotion: return c.ReducedMotion;
		case .NoMotionPreference: return !c.ReducedMotion;
		case .InputPointer: return c.Input == .Pointer;
		case .InputKeyboard: return c.Input == .Keyboard;
		case .InputPad: return c.Input == .Pad;
		}
	}

	private void Parse(StringView text)
	{
		// A comma list: each part a query (commas inside parentheses are the feature's own).
		int start = 0;
		int depth = 0;
		for (int i = 0; i <= text.Length; i++)
		{
			if ((i < text.Length) && (text[i] == '('))
				depth++;
			else if ((i < text.Length) && (text[i] == ')') && (depth > 0))
				depth--;
			else if ((i == text.Length) || ((text[i] == ',') && (depth == 0)))
			{
				let part = ParseUtil.Trim(text.Substring(start, i - start));
				if (part.Length != 0)
					mQueries.Add(ParseQuery(part));
				start = i + 1;
			}
		}
	}

	private static Query ParseQuery(StringView text)
	{
		let q = new Query();
		int i = 0;
		let n = text.Length;
		// Words before and between the groups: `not`, `only`, a media type, `and`.
		void Word(StringView w)
		{
			if (w == "not")
				q.Not = true;
			else if (w == "print")
				q.Never = true;
			else if ((w != "and") && (w != "only") && (w != "all") && (w != "screen"))
				q.Never = true; // a type or a keyword it does not know
		}
		while (i < n)
		{
			while ((i < n) && (text[i] == ' '))
				i++;
			if (i >= n)
				break;
			if (text[i] != '(')
			{
				let start = i;
				while ((i < n) && (text[i] != ' ') && (text[i] != '('))
					i++;
				Word(text.Substring(start, i - start));
				continue;
			}
			i++;
			let start = i;
			while ((i < n) && (text[i] != ')'))
				i++;
			if (!ParseFeature(text.Substring(start, i - start), q.Features))
				q.Never = true;
			if (i < n)
				i++; // skip ')'
		}
		return q;
	}

	/// One "(feature: value)" or "(feature)" group; false for one it cannot test.
	private static bool ParseFeature(StringView group, List<MediaFeature> outFeatures)
	{
		int colon = group.Length;
		for (int i = 0; i < group.Length; i++)
		{
			if (group[i] == ':')
			{
				colon = i;
				break;
			}
		}
		let name = ParseUtil.Trim(group.Substring(0, colon));
		let text = (colon < group.Length) ? ParseUtil.Trim(group.Substring(colon + 1, group.Length - colon - 1)) : StringView();
		bool Keyword(MediaFeatureType type)
		{
			outFeatures.Add(.(type, 0.0f));
			return true;
		}
		if (name == "orientation")
		{
			if (text == "portrait")
				return Keyword(.Portrait);
			if (text == "landscape")
				return Keyword(.Landscape);
			return false;
		}
		if (name == "prefers-color-scheme")
		{
			if (text == "dark")
				return Keyword(.Dark);
			if (text == "light")
				return Keyword(.Light);
			return false;
		}
		if (name == "prefers-contrast")
		{
			if (text.Length == 0)
				return Keyword(.ContrastAny);
			if (text == "more")
				return Keyword(.ContrastMore);
			if (text == "less")
				return Keyword(.ContrastLess);
			if (text == "no-preference")
				return Keyword(.ContrastNone);
			return false;
		}
		if (name == "input")
		{
			if (text == "pointer")
				return Keyword(.InputPointer);
			if (text == "keyboard")
				return Keyword(.InputKeyboard);
			if (text == "pad")
				return Keyword(.InputPad);
			return false;
		}
		if (name == "prefers-reduced-motion")
		{
			if ((text.Length == 0) || (text == "reduce"))
				return Keyword(.ReduceMotion);
			if (text == "no-preference")
				return Keyword(.NoMotionPreference);
			return false;
		}
		if (colon >= group.Length)
			return false; // another boolean feature: none is known

		let resolution = (name == "min-resolution") || (name == "max-resolution") || (name == "resolution");
		let value = resolution ? ParseResolution(text) : ParseLength(text);
		if (!value.HasValue)
			return false;

		MediaFeatureType type;
		if (name == "min-width")
			type = .MinWidth;
		else if (name == "max-width")
			type = .MaxWidth;
		else if (name == "min-height")
			type = .MinHeight;
		else if (name == "max-height")
			type = .MaxHeight;
		else if (name == "width")
			type = .Width;
		else if (name == "height")
			type = .Height;
		else if (name == "min-resolution")
			type = .MinResolution;
		else if (name == "max-resolution")
			type = .MaxResolution;
		else if (name == "resolution")
			type = .Resolution;
		else
			return false; // a feature it does not know

		outFeatures.Add(.(type, value.Value));
		return true;
	}

	/// `2dppx`, `2x` or `192dpi`, in dpi.
	private static float? ParseResolution(StringView text)
	{
		float? Number(int suffix) => ParseLength(text.Substring(0, text.Length - suffix));
		bool EndsWith(StringView unit) => (text.Length > unit.Length) && (text.Substring(text.Length - unit.Length, unit.Length) == unit);
		if (EndsWith("dppx"))
		{
			let n = Number(4);
			if (n.HasValue)
				return n.Value * 96.0f;
		}
		if (EndsWith("dpi"))
			return Number(3);
		if (EndsWith("x"))
		{
			let n = Number(1);
			if (n.HasValue)
				return n.Value * 96.0f;
		}
		return null;
	}
}
