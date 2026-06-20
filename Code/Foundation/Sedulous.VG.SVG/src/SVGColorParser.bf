using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.VG.SVG;

/// Parses SVG color strings into Color values
public static class SVGColorParser
{
	/// Parse an SVG color string (hex, named, or rgb())
	public static Result<Color> Parse(StringView colorStr)
	{
		var s = colorStr;
		// Trim whitespace
		while (s.Length > 0 && (s[0] == ' ' || s[0] == '\t'))
			s = s.Substring(1);
		while (s.Length > 0 && (s[s.Length - 1] == ' ' || s[s.Length - 1] == '\t'))
			s = s.Substring(0, s.Length - 1);

		if (s.IsEmpty)
			return .Err;

		// Hex color
		if (s[0] == '#')
		{
			if (s.Length == 7) // #rrggbb
			{
				let r = Try!(ParseHexByte(s, 1));
				let g = Try!(ParseHexByte(s, 3));
				let b = Try!(ParseHexByte(s, 5));
				return .Ok(Color((int32)r, (int32)g, (int32)b));
			}
			else if (s.Length == 4) // #rgb
			{
				let r = Try!(ParseHexNibble(s, 1));
				let g = Try!(ParseHexNibble(s, 2));
				let b = Try!(ParseHexNibble(s, 3));
				return .Ok(Color((int32)(r | (r << 4)), (int32)(g | (g << 4)), (int32)(b | (b << 4))));
			}
			else if (s.Length == 9) // #rrggbbaa
			{
				let r = Try!(ParseHexByte(s, 1));
				let g = Try!(ParseHexByte(s, 3));
				let b = Try!(ParseHexByte(s, 5));
				let a = Try!(ParseHexByte(s, 7));
				return .Ok(Color((int32)r, (int32)g, (int32)b, (int32)a));
			}
			return .Err;
		}

		// rgb() function
		if (s.Length >= 5 && s[0] == 'r' && s[1] == 'g' && s[2] == 'b' && s[3] == '(')
		{
			var pos = 4;
			let r = Try!(ParseInt(s, ref pos));
			SkipComma(s, ref pos);
			let g = Try!(ParseInt(s, ref pos));
			SkipComma(s, ref pos);
			let b = Try!(ParseInt(s, ref pos));
			return .Ok(Color(r, g, b));
		}

		// Named colors (basic SVG set)
		return ParseNamedColor(s);
	}

	private static Result<Color> ParseNamedColor(StringView name)
	{
		// Compare case-insensitively
		let lower = scope String(name);
		lower.ToLower();

		switch (lower)
		{
		case "black": return .Ok(Color(0, 0, 0));
		case "white": return .Ok(Color(255, 255, 255));
		case "red": return .Ok(Color(255, 0, 0));
		case "green": return .Ok(Color(0, 128, 0));
		case "blue": return .Ok(Color(0, 0, 255));
		case "yellow": return .Ok(Color(255, 255, 0));
		case "cyan", "aqua": return .Ok(Color(0, 255, 255));
		case "magenta", "fuchsia": return .Ok(Color(255, 0, 255));
		case "gray", "grey": return .Ok(Color(128, 128, 128));
		case "silver": return .Ok(Color(192, 192, 192));
		case "maroon": return .Ok(Color(128, 0, 0));
		case "olive": return .Ok(Color(128, 128, 0));
		case "lime": return .Ok(Color(0, 255, 0));
		case "teal": return .Ok(Color(0, 128, 128));
		case "navy": return .Ok(Color(0, 0, 128));
		case "purple": return .Ok(Color(128, 0, 128));
		case "orange": return .Ok(Color(255, 165, 0));
		case "pink": return .Ok(Color(255, 192, 203));
		case "brown": return .Ok(Color(165, 42, 42));
		case "coral": return .Ok(Color(255, 127, 80));
		case "gold": return .Ok(Color(255, 215, 0));
		case "indigo": return .Ok(Color(75, 0, 130));
		case "ivory": return .Ok(Color(255, 255, 240));
		case "khaki": return .Ok(Color(240, 230, 140));
		case "lavender": return .Ok(Color(230, 230, 250));
		case "none", "transparent": return .Ok(Color(0, 0, 0, 0));
		}

		return .Err;
	}

	private static Result<uint8> ParseHexByte(StringView s, int offset)
	{
		if (offset + 1 >= s.Length)
			return .Err;
		let high = Try!(HexVal(s[offset]));
		let low = Try!(HexVal(s[offset + 1]));
		return .Ok((uint8)(high << 4 | low));
	}

	private static Result<uint8> ParseHexNibble(StringView s, int offset)
	{
		if (offset >= s.Length)
			return .Err;
		return HexVal(s[offset]);
	}

	private static Result<uint8> HexVal(char8 c)
	{
		if (c >= '0' && c <= '9') return .Ok((uint8)(c - '0'));
		if (c >= 'a' && c <= 'f') return .Ok((uint8)(c - 'a' + 10));
		if (c >= 'A' && c <= 'F') return .Ok((uint8)(c - 'A' + 10));
		return .Err;
	}

	private static Result<int32> ParseInt(StringView s, ref int pos)
	{
		SkipWhitespace(s, ref pos);
		let start = pos;
		if (pos < s.Length && (s[pos] == '-' || s[pos] == '+'))
			pos++;
		while (pos < s.Length && s[pos] >= '0' && s[pos] <= '9')
			pos++;
		if (pos == start)
			return .Err;

		let numStr = s.Substring(start, pos - start);
		if (int32.Parse(numStr) case .Ok(let val))
			return .Ok(val);
		return .Err;
	}

	private static void SkipWhitespace(StringView s, ref int pos)
	{
		while (pos < s.Length && (s[pos] == ' ' || s[pos] == '\t'))
			pos++;
	}

	private static void SkipComma(StringView s, ref int pos)
	{
		SkipWhitespace(s, ref pos);
		if (pos < s.Length && s[pos] == ',')
			pos++;
		SkipWhitespace(s, ref pos);
	}
}
