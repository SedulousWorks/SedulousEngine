using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// Parses style value literals from token text.
///
/// Shared by the style sheet parser and the markup loader, so `width="50%"` in markup and
/// `width: 50%` in a sheet mean the same thing.
static class StyleValueParser
{
	/// A hex colour, either #rrggbb or #rrggbbaa, leading hash included.
	public static Color? ParseHexColor(StringView text)
	{
		if ((text.Length < 2) || (text[0] != '#'))
			return null;

		let hex = text.Substring(1);

		if (hex.Length == 6)
		{
			if (ParseHexByte(hex, 0) case .Ok(let r))
			{
				if (ParseHexByte(hex, 2) case .Ok(let g))
				{
					if (ParseHexByte(hex, 4) case .Ok(let b))
						return Color(r / 255.0f, g / 255.0f, b / 255.0f, 1.0f);
				}
			}
			return null;
		}

		if (hex.Length == 8)
		{
			if (ParseHexByte(hex, 0) case .Ok(let r))
			{
				if (ParseHexByte(hex, 2) case .Ok(let g))
				{
					if (ParseHexByte(hex, 4) case .Ok(let b))
					{
						if (ParseHexByte(hex, 6) case .Ok(let a))
							return Color(r / 255.0f, g / 255.0f, b / 255.0f, a / 255.0f);
					}
				}
			}
		}
		return null;
	}

	/// A named colour. The set is small and deliberate rather than the whole CSS list.
	public static Color? ParseNamedColor(StringView name)
	{
		switch (name)
		{
		case "white": return Color.White;
		case "black": return Color.Black;
		case "transparent": return Color.Transparent;
		case "red": return Color.Red;
		// CSS `green` is the DARK one, not full brightness.
		case "green": return Color(0.0f, 128.0f / 255.0f, 0.0f, 1.0f);
		case "blue": return Color.Blue;
		case "yellow": return Color(1.0f, 1.0f, 0.0f, 1.0f);
		case "cyan": return Color(0.0f, 1.0f, 1.0f, 1.0f);
		case "magenta": return Color(1.0f, 0.0f, 1.0f, 1.0f);
		case "gray", "grey": return Color(128.0f / 255.0f, 128.0f / 255.0f, 128.0f / 255.0f, 1.0f);
		default: return null;
		}
	}

	/// A thickness from one, two or four values, in the CSS orders: one is every side, two is
	/// vertical then horizontal, and four is top, right, bottom, left.
	public static Thickness ParseThickness(Span<float> values)
	{
		if (values.Length == 1)
			return .(values[0]);
		if (values.Length == 2)
			return .(values[1], values[0], values[1], values[0]);
		if (values.Length == 4)
			return .(values[3], values[0], values[1], values[2]);
		return .();
	}

	/// A unit from a number and its suffix. Unitless means dp, which is the logical layout
	/// unit and the right default.
	public static Unit ParseUnit(float value, StringView suffix)
	{
		switch (suffix)
		{
		case "px": return Unit.Px(value);
		case "pt": return Unit.Pt(value);
		case "em": return Unit.Em(value);
		case "%": return Unit.Percent(value);
		default: return Unit.Dp(value);
		}
	}

	/// A length from TEXT, which is what a markup attribute carries: `240`, `240px`, `16dp`,
	/// `12pt`, `50%`, `2em`, or a `calc(a + b)` over two such terms. Null on anything else.
	///
	/// Only ONE level of nesting: calc within calc is not supported.
	public static Unit? ParseLengthText(StringView text)
	{
		var t = text;
		t.Trim();

		if (t.StartsWith("calc(") && t.EndsWith(")"))
		{
			var inner = t.Substring(5, t.Length - 6);
			inner.Trim();

			// The operator is a plus or minus with a SPACE on each side, which is what
			// distinguishes it from the sign of a negative term.
			for (int i = 1; i + 1 < inner.Length; i++)
			{
				if (((inner[i] != '+') && (inner[i] != '-'))
					|| (inner[i - 1] != ' ') || (inner[i + 1] != ' '))
					continue;

				let left = ParseLengthText(inner.Substring(0, i));
				let right = ParseLengthText(inner.Substring(i + 1));
				if ((left == null) || (right == null))
					return null;

				return (inner[i] == '+') ? (left.Value + right.Value) : (left.Value - right.Value);
			}
			return null;
		}

		// Split the trailing unit off the number by walking back over the non numeric tail.
		var unitStart = t.Length;
		while (unitStart > 0)
		{
			let c = t[unitStart - 1];
			if (((c >= '0') && (c <= '9')) || (c == '.') || (c == '-'))
				break;
			unitStart--;
		}

		let number = t.Substring(0, unitStart);
		let suffix = t.Substring(unitStart);
		if (number.IsEmpty)
			return null;

		if (!(double.Parse(number) case .Ok(let value)))
			return null;

		// An unrecognised suffix is a REFUSAL rather than a silent fall back to dp: `20foo`
		// is a mistake worth surfacing, where the caller can still choose to ignore it.
		if (!suffix.IsEmpty && (suffix != "px") && (suffix != "dp") && (suffix != "pt")
			&& (suffix != "em") && (suffix != "%"))
			return null;

		return ParseUnit((float)value, suffix);
	}

	private static Result<uint8> ParseHexByte(StringView hex, int offset)
	{
		if (offset + 2 > hex.Length)
			return .Err;

		var value = 0;
		for (int i < 2)
		{
			let ch = hex[offset + i];
			value <<= 4;
			if ((ch >= '0') && (ch <= '9'))
				value |= (int)(ch - '0');
			else if ((ch >= 'a') && (ch <= 'f'))
				value |= (int)(ch - 'a') + 10;
			else if ((ch >= 'A') && (ch <= 'F'))
				value |= (int)(ch - 'A') + 10;
			else
				return .Err;
		}
		return .Ok((uint8)value);
	}
}
