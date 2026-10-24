using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// Typed CSS values: what a declaration becomes once parsed, so a sheet parses each declaration
// once and the cascade, the applier and transitions work on values, not text. Also the value
// grammars the box properties need: lists split at top-level commas and spaces, angles, box
// shadows, transform functions, gradients and their stops, and var() substitution anywhere in a
// value (nested, partial, with fallbacks).
//
// The parsers that make a list fill one the caller gives, adding to it, and add nothing when the
// value does not parse. The values that hold a list or text (GradientValue, BackgroundLayer) are
// classes, each owning what it holds, with a deep Set.

struct ShadowValue : IEquatable<ShadowValue>
{
	public LengthValue OffsetX = .();
	public LengthValue OffsetY = .();
	public LengthValue Blur = .();
	public LengthValue Spread = .();
	public Color ShadowColor = .(0.0f, 0.0f, 0.0f, 0.5f);
	public bool Inset = false;

	public this() { }

	public bool Equals(ShadowValue other) => this == other;

	[Commutable]
	public static bool operator==(ShadowValue a, ShadowValue o) =>
		(a.OffsetX == o.OffsetX) && (a.OffsetY == o.OffsetY) && (a.Blur == o.Blur) && (a.Spread == o.Spread) &&
		(a.ShadowColor == o.ShadowColor) && (a.Inset == o.Inset);
}

/// The filter functions the GUI draws (through VG's layers): a Gaussian blur so far. Others
/// (brightness, drop-shadow, ...) need a colour pass VG does not have yet, so a list naming one
/// does not parse.
enum FilterKind : uint8
{
	/// Amount: the Gaussian's standard deviation, a length.
	Blur,
}

struct FilterFunction : IEquatable<FilterFunction>
{
	public FilterKind Kind = .Blur;
	public LengthValue Amount = .();

	public this() { }

	public this(FilterKind kind, LengthValue amount)
	{
		Kind = kind;
		Amount = amount;
	}

	public bool Equals(FilterFunction other) => this == other;

	[Commutable]
	public static bool operator==(FilterFunction a, FilterFunction o) => (a.Kind == o.Kind) && (a.Amount == o.Amount);
}

enum TransformKind : uint8
{
	/// A, B: lengths (percentages of the element's own size).
	Translate,
	/// Angle.
	Rotate,
	/// ScaleX, ScaleY.
	Scale,
	/// Angle (x), AngleY.
	Skew,
	/// M: a, b, c, d, e, f.
	Matrix,
}

struct TransformFunction
{
	public TransformKind Kind = .Translate;
	public LengthValue A = .();
	public LengthValue B = .();
	public float Angle = 0.0f;
	public float AngleY = 0.0f;
	public float ScaleX = 1.0f;
	public float ScaleY = 1.0f;
	public float[6] M = .(1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f);

	public this() { }
}

struct TransformOriginValue
{
	public LengthValue X = .(50.0f, .Percent);
	public LengthValue Y = .(50.0f, .Percent);

	public this() { }

	public this(LengthValue x, LengthValue y)
	{
		X = x;
		Y = y;
	}
}

enum GradientKind : uint8
{
	Linear,
	Radial,
	Conic,
}

struct GradientStopValue
{
	public Color StopColor = .();
	/// A fraction of the gradient line; negative: spaced evenly (CSS).
	public float Position = -1.0f;

	public this() { }

	public this(Color stopColor, float position)
	{
		StopColor = stopColor;
		Position = position;
	}
}

/// A class, not a struct: it owns its stop list. Set copies another one deeply.
class GradientValue
{
	public GradientKind Kind = .Linear;
	/// Linear: the CSS angle (0 up, clockwise; 180deg is down). Conic: from.
	public float Angle = 3.14159265358979f;
	public bool Repeating = false;
	public List<GradientStopValue> Stops = new .() ~ delete _;

	public void Set(GradientValue other)
	{
		if (other === this)
			return;
		Kind = other.Kind;
		Angle = other.Angle;
		Repeating = other.Repeating;
		Stops.Clear();
		Stops.AddRange(other.Stops);
	}
}

enum BackgroundKind : uint8
{
	Color,
	Gradient,
	Image,
}

/// A class, not a struct: it owns its gradient and its image path. Set copies another one
/// deeply.
class BackgroundLayer
{
	public BackgroundKind Kind = .Color;
	public Color LayerColor = .();
	public GradientValue Gradient = new .() ~ delete _;
	/// An image path (url()).
	public String Image = new .() ~ delete _;

	public void Set(BackgroundLayer other)
	{
		if (other === this)
			return;
		Kind = other.Kind;
		LayerColor = other.LayerColor;
		Gradient.Set(other.Gradient);
		Image.Set(other.Image);
	}
}

static
{
	// === Splitting ===

	/// The parts of `value` separated by `separator` at the top level (outside parentheses and
	/// quotes), trimmed, empty parts dropped, added to `outParts`. A space separator splits at
	/// any whitespace run.
	public static void SplitTopLevel(StringView value, char8 separator, List<StringView> outParts)
	{
		int32 depth = 0;
		char8 quote = (char8)0;
		int start = 0;
		for (int i = 0; i <= value.Length; i++)
		{
			let end = i == value.Length;
			let c = end ? (char8)0 : value[i];
			if (!end && (quote != (char8)0))
			{
				if (c == quote)
					quote = (char8)0;
				continue;
			}
			if (!end && ((c == '"') || (c == '\'')))
			{
				quote = c;
				continue;
			}
			if (!end && (c == '('))
			{
				depth++;
				continue;
			}
			if (!end && (c == ')'))
			{
				depth--;
				continue;
			}
			let isSeparator = (separator == ' ') ? ParseUtil.IsWhiteSpace(c) : (c == separator);
			if (end || ((depth == 0) && isSeparator))
			{
				let part = ParseUtil.Trim(value.Substring(start, i - start));
				if (part.Length != 0)
					outParts.Add(part);
				start = i + 1;
			}
		}
	}

	/// `name(arguments)`: true with the name and what is between the parentheses.
	public static bool SplitFunction(StringView value, out StringView name, out StringView arguments)
	{
		name = default;
		arguments = default;
		let v = ParseUtil.Trim(value);
		int open = 0;
		while ((open < v.Length) && (v[open] != '('))
			open++;
		if ((open == 0) || (open >= v.Length) || (v[v.Length - 1] != ')'))
			return false;
		name = ParseUtil.Trim(v.Substring(0, open));
		arguments = ParseUtil.Trim(v.Substring(open + 1, v.Length - open - 2));
		return true;
	}

	// === var() ===

	/// Substitutes every var(--name[, fallback]) in `value`, anywhere and nested, through
	/// `lookup` (true with a custom property's value appended to its string, false when it has
	/// none), whose result is itself substituted. `outText` is cleared and receives the result.
	/// False when a reference has no value and no fallback, or the references run deeper than a
	/// cycle could (the declaration is then invalid, as CSS has it).
	public static bool SubstituteVariables(StringView value, delegate bool(StringView name, String outValue) lookup, String outText,
		int32 depth = 0)
	{
		if (depth > 16)
			return false;
		outText.Clear();
		int i = 0;
		while (i < value.Length)
		{
			let atVar = (i + 4 <= value.Length) && (value.Substring(i, 4) == "var(") && ((i == 0) || !ParseUtil.IsIdentChar(value[i - 1]));
			if (!atVar)
			{
				outText.Append(value[i]);
				i++;
				continue;
			}
			// The reference's extent: its matching parenthesis, and its first top-level comma.
			int close = i + 4;
			int comma = 0;
			int32 nesting = 1;
			while ((close < value.Length) && (nesting > 0))
			{
				if (value[close] == '(')
					nesting++;
				else if (value[close] == ')')
					nesting--;
				else if ((value[close] == ',') && (nesting == 1) && (comma == 0))
					comma = close;
				if (nesting > 0)
					close++;
			}
			if (close >= value.Length)
				return false; // unbalanced
			let nameEnd = (comma != 0) ? comma : close;
			let name = ParseUtil.Trim(value.Substring(i + 4, nameEnd - i - 4));
			let resolved = scope String();
			let found = scope String();
			if (lookup(name, found))
			{
				if (!SubstituteVariables(found, lookup, resolved, depth + 1))
					return false;
			}
			else if (comma != 0)
			{
				if (!SubstituteVariables(ParseUtil.Trim(value.Substring(comma + 1, close - comma - 1)), lookup, resolved, depth + 1))
					return false;
			}
			else
			{
				return false;
			}
			outText.Append(resolved);
			i = close + 1;
		}
		return true;
	}

	// === Angles ===

	/// `90deg`, `1.5rad`, `0.25turn`, `100grad`, or a bare 0, in radians.
	public static float? ParseAngle(StringView value)
	{
		let v = ParseUtil.Trim(value);
		const float cPi = 3.14159265358979f;
		if (StyleValueDetail.EndsWithUnit(v, "deg"))
		{
			let n = ParseLength(v.Substring(0, v.Length - 3));
			if (n.HasValue)
				return n.Value * cPi / 180.0f;
		}
		if (StyleValueDetail.EndsWithUnit(v, "grad"))
		{
			let n = ParseLength(v.Substring(0, v.Length - 4));
			if (n.HasValue)
				return n.Value * cPi / 200.0f;
		}
		if (StyleValueDetail.EndsWithUnit(v, "rad"))
		{
			let n = ParseLength(v.Substring(0, v.Length - 3));
			if (n.HasValue)
				return n.Value;
		}
		if (StyleValueDetail.EndsWithUnit(v, "turn"))
		{
			let n = ParseLength(v.Substring(0, v.Length - 4));
			if (n.HasValue)
				return n.Value * 2.0f * cPi;
		}
		if (v == "0")
			return 0.0f;
		return null;
	}

	// === Box shadows ===

	/// `box-shadow`: `none`, or a comma list of `[inset] <x> <y> [blur [spread]] [color]` (the
	/// keyword and the colour in either place), added to `outShadows`. Nothing for none.
	public static bool ParseShadows(StringView value, List<ShadowValue> outShadows)
	{
		if (ParseUtil.Trim(value) == "none")
			return true;
		let shadows = scope List<ShadowValue>();
		let layers = scope List<StringView>();
		SplitTopLevel(value, ',', layers);
		for (let layer in layers)
		{
			var shadow = ShadowValue();
			LengthValue[4] lengths = .(.(), .(), .(), .());
			int count = 0;
			bool colored = false;
			let tokens = scope List<StringView>();
			SplitTopLevel(layer, ' ', tokens);
			for (let token in tokens)
			{
				if (token == "inset")
				{
					shadow.Inset = true;
					continue;
				}
				let length = ParseLengthValue(token);
				if (length.HasValue)
				{
					if (count == 4)
						return false;
					lengths[count++] = length.Value;
					continue;
				}
				let color = ParseColor(token);
				if (!color.HasValue || colored)
					return false;
				shadow.ShadowColor = color.Value;
				colored = true;
			}
			if (count < 2)
				return false;
			shadow.OffsetX = lengths[0];
			shadow.OffsetY = lengths[1];
			if (count > 2)
				shadow.Blur = lengths[2];
			if (count > 3)
				shadow.Spread = lengths[3];
			if (shadow.Blur.Value < 0.0f)
				return false;
			shadows.Add(shadow);
		}
		outShadows.AddRange(shadows);
		return true;
	}

	// === Filters ===

	/// `filter` and `backdrop-filter`: `none` (nothing added), or functions separated by spaces,
	/// added to `outFilters`: `blur(<length>)` (no length: 0; negative: invalid).
	public static bool ParseFilters(StringView value, List<FilterFunction> outFilters)
	{
		if (ParseUtil.Trim(value) == "none")
			return true;
		let tokens = scope List<StringView>();
		SplitTopLevel(value, ' ', tokens);
		if (tokens.IsEmpty)
			return false;
		let filters = scope List<FilterFunction>();
		for (let token in tokens)
		{
			if (!SplitFunction(token, let name, let arguments))
				return false;
			var f = FilterFunction();
			if (name == "blur")
			{
				f.Kind = .Blur;
				if (ParseUtil.Trim(arguments).Length != 0)
				{
					let amount = ParseLengthValue(arguments);
					if (!amount.HasValue || (amount.Value.Value < 0.0f) || (amount.Value.Unit == .Percent))
						return false;
					f.Amount = amount.Value;
				}
			}
			else
			{
				return false;
			}
			filters.Add(f);
		}
		outFilters.AddRange(filters);
		return true;
	}

	/// `text-outline: <width> [color]` and `text-glow: <radius> [color]` (either order), as a
	/// one-shadow list so they interpolate as shadows do: the outline's width rides as the
	/// spread, the glow's radius as the blur. `none`: nothing added.
	public static bool ParseTextEffectShadow(StringView value, bool outline, List<ShadowValue> outShadows)
	{
		if (ParseUtil.Trim(value) == "none")
			return true;
		var shadow = ShadowValue();
		shadow.ShadowColor = outline ? Color(0.0f, 0.0f, 0.0f, 1.0f) : Color(1.0f, 1.0f, 1.0f, 1.0f);
		bool sized = false;
		bool colored = false;
		let tokens = scope List<StringView>();
		SplitTopLevel(value, ' ', tokens);
		for (let token in tokens)
		{
			let length = ParseLengthValue(token);
			if (length.HasValue && !sized)
			{
				if (length.Value.Value < 0.0f)
					return false;
				if (outline)
					shadow.Spread = length.Value;
				else
					shadow.Blur = length.Value;
				sized = true;
				continue;
			}
			let color = ParseColor(token);
			if (!color.HasValue || colored)
				return false;
			shadow.ShadowColor = color.Value;
			colored = true;
		}
		if (!sized)
			return false;
		outShadows.Add(shadow);
		return true;
	}

	// === Transforms ===

	/// `transform`: `none`, or a space list of translate(x[, y]), translateX/Y, rotate(a),
	/// scale(s[, s]), scaleX/Y, skew(ax[, ay]), skewX/Y and matrix(a, b, c, d, e, f), applied
	/// left to right, added to `outFunctions`. Nothing for none.
	public static bool ParseTransforms(StringView value, List<TransformFunction> outFunctions)
	{
		if (ParseUtil.Trim(value) == "none")
			return true;
		let functions = scope List<TransformFunction>();
		let tokens = scope List<StringView>();
		SplitTopLevel(value, ' ', tokens);
		for (let token in tokens)
		{
			if (!SplitFunction(token, let name, let arguments))
				return false;
			let args = scope List<StringView>();
			SplitTopLevel(arguments, ',', args);
			var fn = TransformFunction();
			bool ok = false;
			if (name == "translate")
			{
				fn.Kind = .Translate;
				ok = StyleValueDetail.LengthArg(args, 0, ref fn.A) && ((args.Count == 1) || StyleValueDetail.LengthArg(args, 1, ref fn.B)) &&
					(args.Count <= 2);
			}
			else if (name == "translateX")
			{
				fn.Kind = .Translate;
				ok = (args.Count == 1) && StyleValueDetail.LengthArg(args, 0, ref fn.A);
			}
			else if (name == "translateY")
			{
				fn.Kind = .Translate;
				ok = (args.Count == 1) && StyleValueDetail.LengthArg(args, 0, ref fn.B);
			}
			else if (name == "rotate")
			{
				fn.Kind = .Rotate;
				ok = (args.Count == 1) && StyleValueDetail.AngleArg(args, 0, ref fn.Angle);
			}
			else if (name == "scale")
			{
				fn.Kind = .Scale;
				ok = StyleValueDetail.NumberArg(args, 0, ref fn.ScaleX) && (args.Count <= 2);
				fn.ScaleY = fn.ScaleX;
				ok = ok && ((args.Count == 1) || StyleValueDetail.NumberArg(args, 1, ref fn.ScaleY));
			}
			else if (name == "scaleX")
			{
				fn.Kind = .Scale;
				ok = (args.Count == 1) && StyleValueDetail.NumberArg(args, 0, ref fn.ScaleX);
			}
			else if (name == "scaleY")
			{
				fn.Kind = .Scale;
				ok = (args.Count == 1) && StyleValueDetail.NumberArg(args, 0, ref fn.ScaleY);
			}
			else if (name == "skew")
			{
				fn.Kind = .Skew;
				ok = StyleValueDetail.AngleArg(args, 0, ref fn.Angle) && (args.Count <= 2) &&
					((args.Count == 1) || StyleValueDetail.AngleArg(args, 1, ref fn.AngleY));
			}
			else if (name == "skewX")
			{
				fn.Kind = .Skew;
				ok = (args.Count == 1) && StyleValueDetail.AngleArg(args, 0, ref fn.Angle);
			}
			else if (name == "skewY")
			{
				fn.Kind = .Skew;
				ok = (args.Count == 1) && StyleValueDetail.AngleArg(args, 0, ref fn.AngleY);
			}
			else if (name == "matrix")
			{
				fn.Kind = .Matrix;
				ok = args.Count == 6;
				for (int k = 0; ok && (k < 6); k++)
					ok = StyleValueDetail.NumberArg(args, k, ref fn.M[k]);
			}
			if (!ok)
				return false;
			functions.Add(fn);
		}
		outFunctions.AddRange(functions);
		return true;
	}

	/// A translation's or an origin's length in the box's units: a percentage of `size`,
	/// anything else as written (pixels).
	public static float ResolveAgainst(LengthValue v, float size)
	{
		if (v.Unit == .Calc) // its pixels and percentage
			return v.Terms[(int)LengthUnit.Px] + v.Terms[(int)LengthUnit.Percent] * size / 100.0f;
		return (v.Unit == .Percent) ? v.Value * size / 100.0f : v.Value;
	}

	/// The matrix a transform list makes for a box of `size`: its functions applied left to
	/// right.
	public static Transform2D ComposeTransforms(List<TransformFunction> functions, Float2 size)
	{
		var m = Transform2D();
		for (let f in functions)
		{
			switch (f.Kind)
			{
			case .Translate:
				m.Translate(ResolveAgainst(f.A, size.X), ResolveAgainst(f.B, size.Y));
			case .Rotate:
				m.Rotate(f.Angle);
			case .Scale:
				m.Scale(f.ScaleX, f.ScaleY);
			case .Skew:
				m.Combine(Transform2D(1.0f, Math.Tan(f.AngleY), Math.Tan(f.Angle), 1.0f, 0.0f, 0.0f));
			case .Matrix:
				m.Combine(Transform2D(f.M[0], f.M[1], f.M[2], f.M[3], f.M[4], f.M[5]));
			}
		}
		return m;
	}

	/// `transform-origin`: one or two of a length, a percentage, or left / center / right
	/// (horizontal) and top / center / bottom (vertical); 50% 50% where unsaid.
	public static TransformOriginValue? ParseTransformOrigin(StringView value)
	{
		var x = LengthValue(50.0f, .Percent);
		var y = LengthValue(50.0f, .Percent);
		let tokens = scope List<StringView>();
		SplitTopLevel(value, ' ', tokens);
		if (tokens.IsEmpty || (tokens.Count > 2))
			return null;
		bool xSet = false;
		bool ySet = false;
		for (int k = 0; k < tokens.Count; k++)
		{
			let t = tokens[k];
			if ((t == "left") || (t == "right"))
			{
				x = LengthValue((t == "left") ? 0.0f : 100.0f, .Percent);
				xSet = true;
			}
			else if ((t == "top") || (t == "bottom"))
			{
				y = LengthValue((t == "top") ? 0.0f : 100.0f, .Percent);
				ySet = true;
			}
			else if (t == "center")
			{
			}
			else
			{
				let length = ParseLengthValue(t);
				if (!length.HasValue)
					return null;
				if ((k == 0) && !xSet)
				{
					x = length.Value;
					xSet = true;
				}
				else if (!ySet)
				{
					y = length.Value;
					ySet = true;
				}
				else
				{
					return null;
				}
			}
		}
		return TransformOriginValue(x, y);
	}

	// === Gradients ===

	/// The stops with every position settled, as CSS does: the first at 0 and the last at 1
	/// when unsaid, the ones between spaced evenly, and none before the one ahead of it. Added to
	/// `outStops`.
	public static void SettleStops(List<GradientStopValue> stops, List<GradientStopValue> outStops)
	{
		let settled = scope List<GradientStopValue>();
		settled.AddRange(stops);
		if (settled.IsEmpty)
			return;
		if (settled[0].Position < 0.0f)
			settled[0].Position = 0.0f;
		if ((settled.Count > 1) && (settled[settled.Count - 1].Position < 0.0f))
			settled[settled.Count - 1].Position = 1.0f;
		for (int i = 1; i < settled.Count; i++)
			if ((settled[i].Position >= 0.0f) && (settled[i].Position < settled[i - 1].Position))
				settled[i].Position = settled[i - 1].Position;
		for (int i = 1; i < settled.Count; i++)
		{
			if (settled[i].Position >= 0.0f)
				continue;
			int next = i;
			while (settled[next].Position < 0.0f)
				next++;
			let from = settled[i - 1].Position;
			let to = settled[next].Position;
			for (int k = i; k < next; k++)
				settled[k].Position = from + (to - from) * (float)(k - i + 1) / (float)(next - i + 1);
		}
		outStops.AddRange(settled);
	}

	/// linear-gradient([<angle> | to <side or corner>,] stops), radial-gradient([<shape or
	/// position>,] stops) and conic-gradient([from <angle>,] stops), and their repeating- forms;
	/// a stop is `<color> [<percentage>]`. `outGradient` takes the gradient (unchanged when it
	/// does not parse).
	public static bool ParseGradient(StringView value, GradientValue outGradient)
	{
		if (!SplitFunction(value, let name, let arguments))
			return false;
		let gradient = scope GradientValue();
		var kind = name;
		if ((kind.Length > 10) && (kind.Substring(0, 10) == "repeating-"))
		{
			gradient.Repeating = true;
			kind = kind.Substring(10, kind.Length - 10);
		}
		if (kind == "linear-gradient")
			gradient.Kind = .Linear;
		else if (kind == "radial-gradient")
			gradient.Kind = .Radial;
		else if (kind == "conic-gradient")
			gradient.Kind = .Conic;
		else
			return false;
		if (gradient.Kind == .Conic)
			gradient.Angle = 0.0f;

		let parts = scope List<StringView>();
		SplitTopLevel(arguments, ',', parts);
		int first = 0;
		if (!parts.IsEmpty)
		{
			let leadWords = scope List<StringView>();
			SplitTopLevel(parts[0], ' ', leadWords);
			if (!ParseColor(leadWords[0]).HasValue)
			{
				// A leading direction (linear), shape (radial, drawn as a circle) or start angle
				// (conic).
				let lead = parts[0];
				if (gradient.Kind == .Linear)
				{
					let a = ParseAngle(lead);
					if (a.HasValue)
					{
						gradient.Angle = a.Value;
					}
					else
					{
						let words = scope List<StringView>();
						SplitTopLevel(lead, ' ', words);
						if (words.IsEmpty || (words[0] != "to"))
							return false;
						float dx = 0.0f;
						float dy = 0.0f;
						for (int k = 1; k < words.Count; k++)
						{
							if (words[k] == "top")
								dy = -1.0f;
							else if (words[k] == "bottom")
								dy = 1.0f;
							else if (words[k] == "left")
								dx = -1.0f;
							else if (words[k] == "right")
								dx = 1.0f;
							else
								return false;
						}
						if ((dx == 0.0f) && (dy == 0.0f))
							return false;
						// The CSS angle: 0 points up, clockwise.
						gradient.Angle = Math.Atan2(dx, -dy);
					}
				}
				else if (gradient.Kind == .Conic)
				{
					let words = scope List<StringView>();
					SplitTopLevel(lead, ' ', words);
					if ((words.Count != 2) || (words[0] != "from"))
						return false;
					let a = ParseAngle(words[1]);
					if (!a.HasValue)
						return false;
					gradient.Angle = a.Value;
				}
				// A radial gradient's shape and position are read as a circle at the centre.
				first = 1;
			}
		}
		for (int k = first; k < parts.Count; k++)
		{
			let words = scope List<StringView>();
			SplitTopLevel(parts[k], ' ', words);
			if (words.IsEmpty || (words.Count > 2))
				return false;
			let color = ParseColor(words[0]);
			if (!color.HasValue)
				return false;
			var stop = GradientStopValue();
			stop.StopColor = color.Value;
			if (words.Count == 2)
			{
				let at = ParseLengthValue(words[1]);
				if (!at.HasValue || (at.Value.Unit != .Percent))
					return false;
				stop.Position = at.Value.Value / 100.0f;
			}
			gradient.Stops.Add(stop);
		}
		if (gradient.Stops.Count < 2)
			return false;
		outGradient.Set(gradient);
		return true;
	}

	// === Backgrounds ===

	/// `background` / `background-image`: `none`, or a comma list of layers, the first on top,
	/// each a colour (the bottom one only, in CSS), a gradient, or url(path). The layers are added
	/// to `outLayers`, which owns them; nothing for none.
	public static bool ParseBackgroundLayers(StringView value, List<BackgroundLayer> outLayers)
	{
		if (ParseUtil.Trim(value) == "none")
			return true;
		let layers = scope List<BackgroundLayer>();
		defer { ClearAndDeleteItems(layers); }
		let parts = scope List<StringView>();
		SplitTopLevel(value, ',', parts);
		for (let part in parts)
		{
			let layer = new BackgroundLayer();
			layers.Add(layer);
			let gradient = scope GradientValue();
			if (SplitFunction(part, let name, let arguments) && (name == "url"))
			{
				var path = arguments;
				if ((path.Length >= 2) && ((path[0] == '"') || (path[0] == '\'')) && (path[path.Length - 1] == path[0]))
					path = path.Substring(1, path.Length - 2);
				layer.Kind = .Image;
				layer.Image.Set(path);
			}
			else if (ParseGradient(part, gradient))
			{
				layer.Kind = .Gradient;
				layer.Gradient.Set(gradient);
			}
			else
			{
				let color = ParseColor(part);
				if (!color.HasValue)
					return false;
				layer.Kind = .Color;
				layer.LayerColor = color.Value;
			}
		}
		outLayers.AddRange(layers);
		layers.Clear(); // handed over
		return true;
	}

	// === Side and corner lists ===

	/// One to four values for top, right, bottom, left (CSS's side order and fill-in), parsed by
	/// `parse`, added to `outSides` (four of them).
	public static bool ParseSides<T>(StringView value, delegate T?(StringView token) parse, List<T> outSides) where T : struct
	{
		let tokens = scope List<StringView>();
		SplitTopLevel(value, ' ', tokens);
		if (tokens.IsEmpty || (tokens.Count > 4))
			return false;
		let parsed = scope List<T>();
		for (let token in tokens)
		{
			let v = parse(token);
			if (!v.HasValue)
				return false;
			parsed.Add(v.Value);
		}
		let n = parsed.Count;
		outSides.Add(parsed[0]); // top
		outSides.Add(parsed[(n > 1) ? 1 : 0]); // right
		outSides.Add(parsed[(n > 2) ? 2 : 0]); // bottom
		outSides.Add(parsed[(n > 3) ? 3 : ((n > 1) ? 1 : 0)]); // left
		return true;
	}
}

/// What StyleValue.bf keeps out of the public surface: the transform functions' argument
/// readers and the angle units' test.
internal static class StyleValueDetail
{
	/// `v` ends with `unit` and has something before it.
	public static bool EndsWithUnit(StringView v, StringView unit) =>
		(v.Length > unit.Length) && (v.Substring(v.Length - unit.Length, unit.Length) == unit);

	public static bool LengthArg(List<StringView> args, int k, ref LengthValue outValue)
	{
		if (k >= args.Count)
			return false;
		let v = ParseLengthValue(args[k]);
		if (!v.HasValue)
			return false;
		outValue = v.Value;
		return true;
	}

	public static bool NumberArg(List<StringView> args, int k, ref float outValue)
	{
		if (k >= args.Count)
			return false;
		let v = ParseLength(args[k]);
		if (!v.HasValue)
			return false;
		outValue = v.Value;
		return true;
	}

	public static bool AngleArg(List<StringView> args, int k, ref float outValue)
	{
		if (k >= args.Count)
			return false;
		let v = ParseAngle(args[k]);
		if (!v.HasValue)
			return false;
		outValue = v.Value;
		return true;
	}
}
