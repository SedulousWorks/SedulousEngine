using System;
using Sedulous.Core;
using Sedulous.VG;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// CSS value parsers: turn declaration value strings into typed values (color / length / bool /
// thickness). Ported from eepp's css value parsing (common subset). Number parsing is a small
// local scanner. Colors: named, #hex (#rgb/#rrggbb/#rrggbbaa), rgb()/rgba(), hsl()/hsla() and
// color-mix().

/// A length's unit.
enum LengthUnit
{
	Px,
	Em,
	Rem,
	Vw,
	Vh,
	Percent,
	/// calc(): a sum of the units above, in Terms.
	Calc,
}

struct LengthValue : IEquatable<LengthValue>
{
	public float Value = 0.0f;
	public LengthUnit Unit = .Px;
	/// A calc()'s amount of each unit (Px to Percent): calc(100% - 2em + 4px) is 100 of Percent,
	/// -2 of Em and 4 of Px. Unused for a plain length.
	public float[cLengthUnitCount] Terms = default;

	public this() { }

	public this(float value, LengthUnit unit)
	{
		Value = value;
		Unit = unit;
	}

	/// Any length as its terms (a plain one: its value in its unit).
	public float[cLengthUnitCount] ToTerms()
	{
		float[cLengthUnitCount] terms = default;
		for (int i = 0; i < cLengthUnitCount; i++)
			terms[i] = (Unit == .Calc) ? Terms[i] : 0.0f;
		if (Unit != .Calc)
			terms[(int)Unit] = Value;
		return terms;
	}

	/// Its percentage part (a plain percentage's value; a calc()'s percent term).
	public float PercentPart => (Unit == .Calc) ? Terms[(int)LengthUnit.Percent] : ((Unit == .Percent) ? Value : 0.0f);

	public static LengthValue FromTerms(float[cLengthUnitCount] terms)
	{
		var v = LengthValue();
		v.Value = 1.0f; // never "a zero", which converts to any unit
		v.Unit = .Calc;
		for (int i = 0; i < cLengthUnitCount; i++)
			v.Terms[i] = terms[i];
		return v;
	}

	public bool Equals(LengthValue other) => this == other;

	[Commutable]
	public static bool operator==(LengthValue a, LengthValue o)
	{
		if (a.Unit != o.Unit)
			return false;
		if (a.Unit != .Calc)
			return a.Value == o.Value;
		for (int i = 0; i < cLengthUnitCount; i++)
			if (a.Terms[i] != o.Terms[i])
				return false;
		return true;
	}
}

/// Resolution context: root/element font sizes (for rem/em) and the viewport (for vw/vh).
struct LengthContext
{
	public float RootFontSize = 16.0f;
	public float ElementFontSize = 16.0f;
	public float ViewportWidth = 0.0f;
	public float ViewportHeight = 0.0f;

	public this() { }
}

/// The `border` shorthand's width and color (ParseBorder).
struct BorderShorthand
{
	public float Width = 1.0f;
	public Color LineColor = .(0.0f, 0.0f, 0.0f, 1.0f);

	public this() { }
}

/// What CSSValues.bf keeps out of the public surface: calc()'s grammar and the color functions'
/// pieces.
internal static class CSSValuesDetail
{
	/// calc()'s grammar over a linear sum of units: + and - between terms, * and / by a plain
	/// number, parentheses and nested calc(). Each value is its terms and whether it is a plain
	/// number (what * and / need on one side).
	public struct CalcValue
	{
		public float[cLengthUnitCount] Terms = default;
		public float Number = 0.0f;
		public bool IsNumber = false;

		public this() { }
	}

	public static String[cLengthUnitCount] sCalcUnits = .("px", "em", "rem", "vw", "vh", "%");

	public struct CalcParser
	{
		private StringView mText;
		private int mAt = 0;

		public this(StringView text)
		{
			mText = text;
		}

		public bool Parse(ref CalcValue outValue) mut
		{
			if (!Sum(ref outValue))
				return false;
			Skip();
			return mAt == mText.Length;
		}

		private void Skip() mut
		{
			while ((mAt < mText.Length) && ((mText[mAt] == ' ') || (mText[mAt] == '\t')))
				mAt++;
		}

		private bool Sum(ref CalcValue outValue) mut
		{
			if (!Product(ref outValue))
				return false;
			while (true)
			{
				Skip();
				if ((mAt >= mText.Length) || ((mText[mAt] != '+') && (mText[mAt] != '-')))
					return true;
				let minus = mText[mAt++] == '-';
				var rhs = CalcValue();
				if (!Product(ref rhs) || (rhs.IsNumber != outValue.IsNumber))
					return false; // a number and a length do not add
				let sign = minus ? -1.0f : 1.0f;
				outValue.Number += sign * rhs.Number;
				for (int i = 0; i < cLengthUnitCount; i++)
					outValue.Terms[i] += sign * rhs.Terms[i];
			}
		}

		private bool Product(ref CalcValue outValue) mut
		{
			if (!Factor(ref outValue))
				return false;
			while (true)
			{
				Skip();
				if ((mAt >= mText.Length) || ((mText[mAt] != '*') && (mText[mAt] != '/')))
					return true;
				let divide = mText[mAt++] == '/';
				var rhs = CalcValue();
				if (!Factor(ref rhs))
					return false;
				if (divide)
				{
					if (!rhs.IsNumber || (rhs.Number == 0.0f))
						return false;
					Scale(ref outValue, 1.0f / rhs.Number);
				}
				else if (rhs.IsNumber)
					Scale(ref outValue, rhs.Number);
				else if (outValue.IsNumber)
				{
					let by = outValue.Number;
					outValue = rhs;
					Scale(ref outValue, by);
				}
				else
					return false; // a length times a length
			}
		}

		private static void Scale(ref CalcValue v, float by)
		{
			v.Number *= by;
			for (int i = 0; i < cLengthUnitCount; i++)
				v.Terms[i] *= by;
		}

		private bool Factor(ref CalcValue outValue) mut
		{
			Skip();
			if ((mAt < mText.Length) && (mText[mAt] == '('))
				return Group(ref outValue);
			if (mText.Substring(mAt, Math.Min(5, mText.Length - mAt)) == "calc(")
			{
				mAt += 4;
				return Group(ref outValue);
			}
			var end = mAt;
			if ((end < mText.Length) && ((mText[end] == '+') || (mText[end] == '-')))
				end++;
			while ((end < mText.Length) && (ParseUtil.IsDigit(mText[end]) || (mText[end] == '.')))
				end++;
			let number = ParseLength(mText.Substring(mAt, end - mAt));
			if (!number.HasValue)
				return false;
			var unitEnd = end;
			while ((unitEnd < mText.Length) && (((mText[unitEnd] >= 'a') && (mText[unitEnd] <= 'z')) || (mText[unitEnd] == '%')))
				unitEnd++;
			let unit = mText.Substring(end, unitEnd - end);
			mAt = unitEnd;
			outValue = CalcValue();
			if (unit.Length == 0)
			{
				outValue.IsNumber = true;
				outValue.Number = number.Value;
				return true;
			}
			for (int i = 0; i < cLengthUnitCount; i++)
			{
				if (unit == sCalcUnits[i])
				{
					outValue.Terms[i] = number.Value;
					return true;
				}
			}
			return false;
		}

		private bool Group(ref CalcValue outValue) mut
		{
			mAt++; // '('
			if (!Sum(ref outValue))
				return false;
			Skip();
			if ((mAt >= mText.Length) || (mText[mAt] != ')'))
				return false;
			mAt++;
			return true;
		}
	}

	/// The arguments of a colour function, split at commas or, failing that, spaces (a `/` before
	/// an alpha read as a separator). Returns how many it found (at most 4).
	public static int ColorArguments(StringView inside, ref StringView[4] outParts)
	{
		bool comma = false;
		for (int i = 0; i < inside.Length; i++)
			comma = comma || (inside[i] == ',');
		int n = 0;
		int start = 0;
		for (int i = 0; (i <= inside.Length) && (n < 4); i++)
		{
			let split = (i == inside.Length) || (comma ? (inside[i] == ',') : ((inside[i] == ' ') || (inside[i] == '/')));
			if (!split)
				continue;
			let part = ParseUtil.Trim(inside.Substring(start, i - start));
			if (part.Length != 0)
				outParts[n++] = part;
			start = i + 1;
		}
		return n;
	}

	/// A number, or a percentage as its fraction of `full` (an alpha: of 1; a saturation: of 100).
	public static float? NumberOrPercent(StringView t, float full)
	{
		if ((t.Length > 1) && (t[t.Length - 1] == '%'))
		{
			let v = ParseLength(t.Substring(0, t.Length - 1));
			return v.HasValue ? (float?)(v.Value * full / 100.0f) : null;
		}
		return ParseLength(t);
	}

	private static float HslChannel(float n, float h, float s, float l)
	{
		var k = n + h / 30.0f;
		k = k - 12.0f * (float)(int32)(k / 12.0f);
		let amount = s * Math.Min(l, 1.0f - l);
		return l - amount * Math.Max(-1.0f, Math.Min(Math.Min(k - 3.0f, 9.0f - k), 1.0f));
	}

	/// hsl() to rgb (CSS Color 4's algorithm), hue in degrees, saturation and lightness 0 to 1.
	public static Color HslToRgb(float h, float s, float l, float a)
	{
		var h;
		h = h - 360.0f * (float)(int32)(h / 360.0f);
		if (h < 0.0f)
			h += 360.0f;
		return .(HslChannel(0.0f, h, s, l), HslChannel(8.0f, h, s, l), HslChannel(4.0f, h, s, l), a);
	}

	/// `name(...)` around the whole of `s`: true with what is between the parentheses.
	public static bool ColorFunction(StringView s, StringView name, out StringView inside)
	{
		inside = default;
		if ((s.Length <= name.Length + 1) || (s.Substring(0, name.Length) != name) || (s[name.Length] != '(') || (s[s.Length - 1] != ')'))
			return false;
		inside = s.Substring(name.Length + 1, s.Length - name.Length - 2);
		return true;
	}

	/// Up to four whitespace-separated parts of `s`, each read by `read`; the count, or -1 when
	/// one does not read or there are more than four.
	public static int ReadFour(StringView s, delegate float?(StringView part) read, ref float[4] parts)
	{
		int count = 0;
		int start = 0;
		for (int i = 0; i <= s.Length; i++)
		{
			let boundary = (i == s.Length) || ParseUtil.IsWhiteSpace(s[i]);
			if (boundary)
			{
				if (i > start)
				{
					if (count == 4)
						return -1; // too many
					let v = read(s.Substring(start, i - start));
					if (!v.HasValue)
						return -1;
					parts[count++] = v.Value;
				}
				start = i + 1;
			}
		}
		return count;
	}

	/// 1 to 4 values in CSS's side order (top, right, bottom, left) as a Thickness.
	public static Thickness SidesOf(float[4] parts, int count)
	{
		float top, right, bottom, left;
		if (count == 1)
		{
			top = right = bottom = left = parts[0];
		}
		else if (count == 2)
		{
			top = bottom = parts[0];
			right = left = parts[1];
		}
		else if (count == 3)
		{
			top = parts[0];
			right = left = parts[1];
			bottom = parts[2];
		}
		else
		{
			top = parts[0];
			right = parts[1];
			bottom = parts[2];
			left = parts[3];
		}
		return .(left, top, right, bottom);
	}
}

static
{
	/// The units a calc() sums (all but Calc).
	public const int cLengthUnitCount = 6;

	/// Parse a decimal number (ignores a trailing unit like "px"/"%"). Empty if none.
	public static float? ParseLength(StringView value)
	{
		let s = ParseUtil.Trim(value);
		if (s.Length == 0)
			return null;
		int i = 0;
		float sign = 1.0f;
		if (s[i] == '+')
			i++;
		else if (s[i] == '-')
		{
			sign = -1.0f;
			i++;
		}

		double whole = 0.0;
		bool any = false;
		while ((i < s.Length) && ParseUtil.IsDigit(s[i]))
		{
			whole = whole * 10.0 + (double)((int32)s[i] - (int32)'0');
			i++;
			any = true;
		}
		double frac = 0.0;
		double scale = 1.0;
		if ((i < s.Length) && (s[i] == '.'))
		{
			i++;
			while ((i < s.Length) && ParseUtil.IsDigit(s[i]))
			{
				frac = frac * 10.0 + (double)((int32)s[i] - (int32)'0');
				scale *= 10.0;
				i++;
				any = true;
			}
		}
		if (!any)
			return null;
		return (float)((double)sign * (whole + frac / scale));
	}

	/// A calc() expression's length: `calc(100% - 2 * 8px)`. Empty when it does not parse or
	/// comes to a plain number (a length is wanted), save a zero.
	public static LengthValue? ParseCalcLength(StringView value)
	{
		let s = ParseUtil.Trim(value);
		if ((s.Length < 6) || (s.Substring(0, 5) != "calc(") || (s[s.Length - 1] != ')'))
			return null;
		var calc = CSSValuesDetail.CalcValue();
		var parser = CSSValuesDetail.CalcParser(s.Substring(4, s.Length - 4)); // "(...)": the group
		if (!parser.Parse(ref calc))
			return null;
		if (calc.IsNumber)
			return (calc.Number == 0.0f) ? (LengthValue?)LengthValue() : null;
		return LengthValue.FromTerms(calc.Terms);
	}

	/// Parse a number with an optional unit suffix: "12", "12px", "1.5rem", "2em", "50vw",
	/// "80vh", "50%", or a calc(). Unitless is treated as px. An unrecognized unit yields
	/// nothing.
	public static LengthValue? ParseLengthValue(StringView value)
	{
		let s = ParseUtil.Trim(value);
		if (s.Length == 0)
			return null;
		if ((s.Length > 5) && (s.Substring(0, 5) == "calc("))
			return ParseCalcLength(s);
		int i = 0;
		if ((s[i] == '+') || (s[i] == '-'))
			i++;
		while ((i < s.Length) && ParseUtil.IsDigit(s[i]))
			i++;
		if ((i < s.Length) && (s[i] == '.'))
		{
			i++;
			while ((i < s.Length) && ParseUtil.IsDigit(s[i]))
				i++;
		}

		let num = ParseLength(s.Substring(0, i));
		if (!num.HasValue)
			return null;

		let suffix = ParseUtil.Trim(s.Substring(i, s.Length - i));
		LengthUnit unit = .Px;
		if ((suffix.Length == 0) || (suffix == "px"))
			unit = .Px;
		else if (suffix == "rem")
			unit = .Rem;
		else if (suffix == "em")
			unit = .Em;
		else if (suffix == "vw")
			unit = .Vw;
		else if (suffix == "vh")
			unit = .Vh;
		else if (suffix == "%")
			unit = .Percent;
		else
			return null;
		return LengthValue(num.Value, unit);
	}

	/// Resolve a length to pixels. `percentBase` is the value 100% maps to (the caller supplies
	/// the relevant containing dimension); 0 if unknown.
	public static float ResolveLengthValue(LengthValue lv, LengthContext ctx, float percentBase = 0.0f)
	{
		switch (lv.Unit)
		{
		case .Px:
			return lv.Value;
		case .Em:
			return lv.Value * ctx.ElementFontSize;
		case .Rem:
			return lv.Value * ctx.RootFontSize;
		case .Vw:
			return lv.Value * ctx.ViewportWidth / 100.0f;
		case .Vh:
			return lv.Value * ctx.ViewportHeight / 100.0f;
		case .Percent:
			return lv.Value * percentBase / 100.0f;
		case .Calc:
			float sum = 0.0f;
			for (int i = 0; i < cLengthUnitCount; i++)
			{
				if (lv.Terms[i] != 0.0f)
				{
					var term = LengthValue();
					term.Value = lv.Terms[i];
					term.Unit = (LengthUnit)i;
					sum += ResolveLengthValue(term, ctx, percentBase);
				}
			}
			return sum;
		}
	}

	/// Parse and resolve a length string to pixels.
	public static float? ResolveLength(StringView value, LengthContext ctx, float percentBase = 0.0f)
	{
		let lv = ParseLengthValue(value);
		if (!lv.HasValue)
			return null;
		return ResolveLengthValue(lv.Value, ctx, percentBase);
	}

	public static bool? ParseBool(StringView value)
	{
		let s = ParseUtil.Trim(value);
		if ((s == "true") || (s == "1") || (s == "yes"))
			return true;
		if ((s == "false") || (s == "0") || (s == "no"))
			return false;
		return null;
	}

	public static Color? ParseColor(StringView value)
	{
		let s = ParseUtil.Trim(value);
		if (s.Length == 0)
			return null;
		StringView inside;
		// hsl() / hsla(): hue in degrees (deg or none), saturation and lightness as percentages,
		// alpha a number or a percentage.
		if (CSSValuesDetail.ColorFunction(s, "hsl", out inside) || CSSValuesDetail.ColorFunction(s, "hsla", out inside))
		{
			StringView[4] args = default;
			let n = CSSValuesDetail.ColorArguments(inside, ref args);
			if (n < 3)
				return null;
			var hue = args[0];
			if ((hue.Length > 3) && (hue.Substring(hue.Length - 3, 3) == "deg"))
				hue = hue.Substring(0, hue.Length - 3);
			let h = ParseLength(hue);
			let sat = CSSValuesDetail.NumberOrPercent(args[1], 100.0f);
			let light = CSSValuesDetail.NumberOrPercent(args[2], 100.0f);
			let alpha = (n > 3) ? CSSValuesDetail.NumberOrPercent(args[3], 1.0f) : (float?)1.0f;
			if (!h.HasValue || !sat.HasValue || !light.HasValue || !alpha.HasValue)
				return null;
			return CSSValuesDetail.HslToRgb(h.Value, Clamp(sat.Value / 100.0f, 0.0f, 1.0f), Clamp(light.Value / 100.0f, 0.0f, 1.0f),
				Clamp(alpha.Value, 0.0f, 1.0f));
		}
		// color-mix(in srgb, A [p%], B [q%]): premultiplied by alpha, the percentages made to sum
		// to 100 (one left out is the rest; a sum under 100 scales the alpha).
		if (CSSValuesDetail.ColorFunction(s, "color-mix", out inside))
		{
			StringView[3] parts = default;
			int n = 0;
			int start = 0;
			int depth = 0;
			for (int i = 0; (i <= inside.Length) && (n < 3); i++)
			{
				if ((i < inside.Length) && (inside[i] == '('))
					depth++;
				else if ((i < inside.Length) && (inside[i] == ')') && (depth > 0))
					depth--;
				else if ((i == inside.Length) || ((inside[i] == ',') && (depth == 0)))
				{
					parts[n++] = ParseUtil.Trim(inside.Substring(start, i - start));
					start = i + 1;
				}
			}
			if ((n != 3) || ((parts[0] != "in srgb") && (parts[0] != "in srgb-linear")))
				return null;
			Color[2] colors = default;
			float?[2] amounts = default;
			for (int k = 0; k < 2; k++)
			{
				var part = parts[k + 1];
				int space = part.Length;
				for (int i = part.Length - 1; i >= 0; i--)
				{
					if (part[i] == ' ')
					{
						space = i;
						break;
					}
				}
				if ((space < part.Length) && (part[part.Length - 1] == '%'))
				{
					amounts[k] = CSSValuesDetail.NumberOrPercent(part.Substring(space + 1, part.Length - space - 1), 100.0f);
					part = ParseUtil.Trim(part.Substring(0, space));
				}
				let c = ParseColor(part);
				if (!c.HasValue)
					return null;
				colors[k] = c.Value;
			}
			float p1 = amounts[0].HasValue ? amounts[0].Value : (amounts[1].HasValue ? 100.0f - amounts[1].Value : 50.0f);
			float p2 = amounts[1].HasValue ? amounts[1].Value : 100.0f - p1;
			let sum = p1 + p2;
			if (sum <= 0.0f)
				return null;
			let scaleAlpha = Math.Min(sum, 100.0f) / 100.0f;
			p1 /= sum;
			p2 /= sum;
			let a = colors[0].A * p1 + colors[1].A * p2;
			if (a <= 0.0f)
				return Color(0.0f, 0.0f, 0.0f, 0.0f);
			let c0 = colors[0];
			let c1 = colors[1];
			return Color((c0.R * c0.A * p1 + c1.R * c1.A * p2) / a, (c0.G * c0.A * p1 + c1.G * c1.A * p2) / a,
				(c0.B * c0.A * p1 + c1.B * c1.A * p2) / a, a * scaleAlpha);
		}

		// #hex
		if (s[0] == '#')
		{
			let hex = s.Substring(1, s.Length - 1);
			let len = hex.Length;
			float r = 0, g = 0, b = 0, a = 1.0f;
			if (len == 3)
			{
				let hr = ParseUtil.HexValue(hex[0]);
				let hg = ParseUtil.HexValue(hex[1]);
				let hb = ParseUtil.HexValue(hex[2]);
				if ((hr < 0) || (hg < 0) || (hb < 0))
					return null;
				r = (float)(hr * 17) / 255.0f;
				g = (float)(hg * 17) / 255.0f;
				b = (float)(hb * 17) / 255.0f;
			}
			else if ((len == 6) || (len == 8))
			{
				for (int k = 0; k < len; k++)
					if (ParseUtil.HexValue(hex[k]) < 0)
						return null;
				r = (float)(ParseUtil.HexValue(hex[0]) * 16 + ParseUtil.HexValue(hex[1])) / 255.0f;
				g = (float)(ParseUtil.HexValue(hex[2]) * 16 + ParseUtil.HexValue(hex[3])) / 255.0f;
				b = (float)(ParseUtil.HexValue(hex[4]) * 16 + ParseUtil.HexValue(hex[5])) / 255.0f;
				if (len == 8)
					a = (float)(ParseUtil.HexValue(hex[6]) * 16 + ParseUtil.HexValue(hex[7])) / 255.0f;
			}
			else
			{
				return null;
			}
			return Color(r, g, b, a);
		}

		// rgb() / rgba()
		let rgba = (s.Length > 5) && (s.Substring(0, 5) == "rgba(");
		let rgb = (s.Length > 4) && (s.Substring(0, 4) == "rgb(");
		if (rgb || rgba)
		{
			let open = rgba ? 5 : 4;
			var close = open;
			while ((close < s.Length) && (s[close] != ')'))
				close++;
			let args = s.Substring(open, close - open);
			float[4] comps = .(0, 0, 0, 1.0f);
			int ci = 0;
			int start = 0;
			for (int i = 0; (i <= args.Length) && (ci < 4); i++)
			{
				if ((i == args.Length) || (args[i] == ','))
				{
					let v = ParseLength(args.Substring(start, i - start));
					if (!v.HasValue)
						return null;
					comps[ci] = (ci < 3) ? (v.Value / 255.0f) : v.Value; // alpha is 0..1
					ci++;
					start = i + 1;
				}
			}
			return Color(comps[0], comps[1], comps[2], comps[3]);
		}

		// named
		return ParseNamedColor(s);
	}

	/// 1-4 whitespace-separated lengths in CSS shorthand order (top / right / bottom / left).
	public static Thickness? ParseThickness(StringView value)
	{
		float[4] parts = default;
		let count = CSSValuesDetail.ReadFour(ParseUtil.Trim(value), scope (part) => ParseLength(part), ref parts);
		if (count <= 0)
			return null;
		return CSSValuesDetail.SidesOf(parts, count);
	}

	/// border-radius: 1-4 lengths in CSS corner order (top-left, top-right, bottom-right,
	/// bottom-left; 1 = all, 2 = TL/BR + TR/BL, 3 = TL, TR/BL, BR).
	public static CornerRadii? ParseCornerRadii(StringView value)
	{
		float[4] parts = default;
		let count = CSSValuesDetail.ReadFour(ParseUtil.Trim(value), scope (part) => ParseLength(part), ref parts);
		if (count <= 0)
			return null;

		float tl, tr, br, bl;
		if (count == 1)
		{
			tl = tr = br = bl = parts[0];
		}
		else if (count == 2)
		{
			tl = br = parts[0];
			tr = bl = parts[1];
		}
		else if (count == 3)
		{
			tl = parts[0];
			tr = bl = parts[1];
			br = parts[2];
		}
		else
		{
			tl = parts[0];
			tr = parts[1];
			br = parts[2];
			bl = parts[3];
		}
		return CornerRadii(tl, tr, br, bl);
	}

	/// The `border` shorthand: any order of a width (a length), a style keyword (ignored - only
	/// solid is drawn), and a color. Missing width defaults to 1; missing color to black. A
	/// leading "none"/"0" yields width 0. Returns width + color.
	public static BorderShorthand? ParseBorder(StringView value)
	{
		var result = BorderShorthand();
		bool any = false;
		let s = ParseUtil.Trim(value);
		int start = 0;
		for (int i = 0; i <= s.Length; i++)
		{
			let boundary = (i == s.Length) || ParseUtil.IsWhiteSpace(s[i]);
			if (!boundary)
				continue;
			if (i > start)
			{
				let tok = s.Substring(start, i - start);
				if (tok == "none")
				{
					result.Width = 0.0f;
					any = true;
				}
				else if ((tok == "solid") || (tok == "dashed") || (tok == "dotted") || (tok == "hidden"))
				{
					any = true;
				}
				else
				{
					let c = ParseColor(tok);
					if (c.HasValue)
					{
						result.LineColor = c.Value;
						any = true;
					}
					else
					{
						let w = ParseLength(tok);
						if (w.HasValue)
						{
							result.Width = w.Value;
							any = true;
						}
					}
				}
			}
			start = i + 1;
		}
		if (!any)
			return null;
		return result;
	}

	/// Like ParseThickness, but each component is unit-resolved against `ctx` (no % support -
	/// padding/margin percentages are a follow-up needing the containing block).
	public static Thickness? ResolveThickness(StringView value, LengthContext ctx)
	{
		float[4] parts = default;
		let count = CSSValuesDetail.ReadFour(ParseUtil.Trim(value), scope (part) => ResolveLength(part, ctx), ref parts);
		if (count <= 0)
			return null;
		return CSSValuesDetail.SidesOf(parts, count);
	}

	/// A small named-color set.
	public static Color? ParseNamedColor(StringView s)
	{
		if (s == "white")
			return Color.White;
		if (s == "black")
			return Color.Black;
		if (s == "red")
			return Color.Red;
		if (s == "green")
			return Color.Green;
		if (s == "blue")
			return Color.Blue;
		if (s == "transparent")
			return Color.Transparent;
		if (s == "yellow")
			return Color(1.0f, 1.0f, 0.0f, 1.0f);
		if (s == "cyan")
			return Color(0.0f, 1.0f, 1.0f, 1.0f);
		if (s == "magenta")
			return Color(1.0f, 0.0f, 1.0f, 1.0f);
		if ((s == "gray") || (s == "grey"))
			return Color(0.5f, 0.5f, 0.5f, 1.0f);
		if (s == "orange")
			return Color(1.0f, 0.647f, 0.0f, 1.0f);
		return null;
	}
}
