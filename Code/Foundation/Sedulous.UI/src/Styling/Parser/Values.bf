namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Parses style value literals from .sss token text.
/// Shared between the .sss parser and .sml markup loader.
public static class StyleValueParser
{
	/// Parse a hex color string: #rrggbb or #rrggbbaa (with leading #).
	public static Result<Color> ParseHexColor(StringView text)
	{
		if (text.Length < 2 || text[0] != '#')
			return .Err;

		let hex = text.Substring(1);
		if (hex.Length == 6)
		{
			if (ParseHexByte(hex, 0) case .Ok(let r))
			if (ParseHexByte(hex, 2) case .Ok(let g))
			if (ParseHexByte(hex, 4) case .Ok(let b))
				return .Ok(Color(r, g, b, 255));
		}
		else if (hex.Length == 8)
		{
			if (ParseHexByte(hex, 0) case .Ok(let r))
			if (ParseHexByte(hex, 2) case .Ok(let g))
			if (ParseHexByte(hex, 4) case .Ok(let b))
			if (ParseHexByte(hex, 6) case .Ok(let a))
				return .Ok(Color(r, g, b, a));
		}
		return .Err;
	}

	/// Parse a named color.
	public static Result<Color> ParseNamedColor(StringView name)
	{
		if (name == "white")       return .Ok(Color(255, 255, 255, 255));
		if (name == "black")       return .Ok(Color(0, 0, 0, 255));
		if (name == "transparent") return .Ok(Color(0, 0, 0, 0));
		if (name == "red")         return .Ok(Color(255, 0, 0, 255));
		if (name == "green")       return .Ok(Color(0, 128, 0, 255));
		if (name == "blue")        return .Ok(Color(0, 0, 255, 255));
		if (name == "yellow")      return .Ok(Color(255, 255, 0, 255));
		if (name == "cyan")        return .Ok(Color(0, 255, 255, 255));
		if (name == "magenta")     return .Ok(Color(255, 0, 255, 255));
		if (name == "gray")        return .Ok(Color(128, 128, 128, 255));
		if (name == "grey")        return .Ok(Color(128, 128, 128, 255));
		return .Err;
	}

	/// Parse a thickness from 1, 2, or 4 float values.
	/// 1 value: all sides. 2 values: vertical, horizontal. 4 values: top, right, bottom, left.
	public static Thickness ParseThickness(float* values, int count)
	{
		if (count == 1)
			return .(values[0]);
		if (count == 2)
			return .(values[1], values[0], values[1], values[0]); // horiz, vert
		if (count == 4)
			return .(values[3], values[0], values[1], values[2]); // left=3, top=0, right=1, bottom=2
		return .();
	}

	/// Parse a unit value from a number token.
	/// Unitless = dp (default), "px" = Px, "dp" = Dp, "pt" = Pt.
	public static Unit ParseUnit(float value, StringView suffix)
	{
		if (suffix == "px") return .Px(value);
		if (suffix == "pt") return .Pt(value);
		return .Dp(value); // default: dp (includes "dp" and unitless)
	}

	// === Helpers ===

	private static Result<uint8> ParseHexByte(StringView hex, int offset)
	{
		if (offset + 2 > hex.Length) return .Err;
		int val = 0;
		for (int i = 0; i < 2; i++)
		{
			let ch = hex[offset + i];
			val <<= 4;
			if (ch >= '0' && ch <= '9') val |= ch - '0';
			else if (ch >= 'a' && ch <= 'f') val |= ch - 'a' + 10;
			else if (ch >= 'A' && ch <= 'F') val |= ch - 'A' + 10;
			else return .Err;
		}
		return .Ok((uint8)val);
	}
}
