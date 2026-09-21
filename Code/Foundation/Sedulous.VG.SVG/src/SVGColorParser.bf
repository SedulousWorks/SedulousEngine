using System;
using Sedulous.Core;

namespace Sedulous.VG.SVG;

/// Parses an SVG colour string.
static class SVGColorParser
{
	/// The colour, as the float form vector graphics works in.
	public static Result<Color, ErrorCode> Parse(StringView colorString)
	{
		if (ParseBytes(colorString) case .Ok(let bytes))
			return .Ok(ToColor(bytes));
		return .Err(.InvalidArgument);
	}

	/// The packed byte form, which is what every syntax here naturally produces.
	private static Result<Color32, ErrorCode> ParseBytes(StringView colorString)
	{
		let s = SVGScan.Trim(colorString);
		if (s.IsEmpty)
			return .Err(.InvalidArgument);

		if (s[0] == '#')
			return ParseHex(s);

		if ((s.Length >= 5) && SVGScan.StartsWith(s, 0, "rgb("))
			return ParseRgb(s);

		return ParseNamed(s);
	}

	private static Result<Color32, ErrorCode> ParseHex(StringView s)
	{
		switch (s.Length)
		{
		case 7: // #rrggbb
			return Color32(Try!(HexByte(s, 1)), Try!(HexByte(s, 3)), Try!(HexByte(s, 5)));

		case 4: // #rgb
			// Each nibble is DOUBLED, so f becomes ff rather than f0: that is what makes
			// the short form's white actually white.
			let r = Try!(HexNibble(s, 1));
			let g = Try!(HexNibble(s, 2));
			let b = Try!(HexNibble(s, 3));
			return Color32((uint8)(r | (r << 4)), (uint8)(g | (g << 4)), (uint8)(b | (b << 4)));

		case 9: // #rrggbbaa
			return Color32(Try!(HexByte(s, 1)), Try!(HexByte(s, 3)), Try!(HexByte(s, 5)),
				Try!(HexByte(s, 7)));

		default:
			return .Err(.InvalidArgument);
		}
	}

	private static Result<Color32, ErrorCode> ParseRgb(StringView s)
	{
		var pos = 4;
		let r = Try!(ParseComponent(s, ref pos));
		SVGScan.SkipComma(s, ref pos);
		let g = Try!(ParseComponent(s, ref pos));
		SVGScan.SkipComma(s, ref pos);
		let b = Try!(ParseComponent(s, ref pos));

		return Color32(r, g, b);
	}

	private static Result<uint8, ErrorCode> ParseComponent(StringView s, ref int pos)
	{
		SVGScan.SkipWhitespace(s, ref pos);
		if (!SVGScan.ScanNumber(s, ref pos, let value))
			return .Err(.InvalidArgument);
		return (uint8)(int32)value;
	}

	/// The named colours SVG defines that anything here is likely to use.
	///
	/// A subset rather than the full list: the rest fail to parse, which an importer reports
	/// rather than guessing a colour for.
	private static Result<Color32, ErrorCode> ParseNamed(StringView name)
	{
		let named = scope (StringView Name, Color32 Value)[](
			("black", .(0, 0, 0)),
			("white", .(255, 255, 255)),
			("red", .(255, 0, 0)),
			// NOT full green: the SVG keyword is the dark one, and lime is the bright.
			("green", .(0, 128, 0)),
			("blue", .(0, 0, 255)),
			("yellow", .(255, 255, 0)),
			("cyan", .(0, 255, 255)),
			("aqua", .(0, 255, 255)),
			("magenta", .(255, 0, 255)),
			("fuchsia", .(255, 0, 255)),
			("gray", .(128, 128, 128)),
			("grey", .(128, 128, 128)),
			("silver", .(192, 192, 192)),
			("maroon", .(128, 0, 0)),
			("olive", .(128, 128, 0)),
			("lime", .(0, 255, 0)),
			("teal", .(0, 128, 128)),
			("navy", .(0, 0, 128)),
			("purple", .(128, 0, 128)),
			("orange", .(255, 165, 0)),
			("pink", .(255, 192, 203)),
			("brown", .(165, 42, 42)),
			("coral", .(255, 127, 80)),
			("gold", .(255, 215, 0)),
			("indigo", .(75, 0, 130)),
			("ivory", .(255, 255, 240)),
			("khaki", .(240, 230, 140)),
			("lavender", .(230, 230, 250)),
			// Both parse to a fully transparent colour, so a caller that wanted "no fill"
			// gets something that draws nothing rather than a failure.
			("none", .(0, 0, 0, 0)),
			("transparent", .(0, 0, 0, 0)));

		for (let entry in named)
		{
			if (SVGScan.EqualsIgnoreCase(name, entry.Name))
				return entry.Value;
		}
		return .Err(.InvalidArgument);
	}

	private static Result<uint8, ErrorCode> HexValue(char8 c)
	{
		if ((c >= '0') && (c <= '9'))
			return (uint8)(c - '0');
		if ((c >= 'a') && (c <= 'f'))
			return (uint8)(c - 'a' + 10);
		if ((c >= 'A') && (c <= 'F'))
			return (uint8)(c - 'A' + 10);
		return .Err(.InvalidArgument);
	}

	private static Result<uint8, ErrorCode> HexByte(StringView s, int offset)
	{
		if ((offset + 1) >= s.Length)
			return .Err(.InvalidArgument);
		let high = Try!(HexValue(s[offset]));
		let low = Try!(HexValue(s[offset + 1]));
		return (uint8)((high << 4) | low);
	}

	private static Result<uint8, ErrorCode> HexNibble(StringView s, int offset)
	{
		if (offset >= s.Length)
			return .Err(.InvalidArgument);
		return HexValue(s[offset]);
	}
}
