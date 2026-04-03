using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.VG.SVG;

/// Parses SVG transform attribute strings into Matrix values
public static class SVGTransformParser
{
	/// Parse an SVG transform string (e.g., "translate(10,20) rotate(45)")
	public static Result<Matrix> Parse(StringView transform)
	{
		var result = Matrix.Identity;
		var pos = 0;

		while (pos < transform.Length)
		{
			SkipWhitespace(transform, ref pos);
			if (pos >= transform.Length)
				break;

			if (StartsWith(transform, pos, "translate"))
			{
				pos += 9;
				Try!(SkipParen(transform, ref pos));
				let tx = Try!(ParseFloat(transform, ref pos));
				SkipComma(transform, ref pos);
				float ty = 0;
				if (pos < transform.Length && IsDigitOrSign(transform[pos]))
					ty = Try!(ParseFloat(transform, ref pos));
				Try!(SkipCloseParen(transform, ref pos));

				result = Matrix.CreateTranslation(tx, ty, 0) * result;
			}
			else if (StartsWith(transform, pos, "scale"))
			{
				pos += 5;
				Try!(SkipParen(transform, ref pos));
				let sx = Try!(ParseFloat(transform, ref pos));
				SkipComma(transform, ref pos);
				var sy = sx;
				if (pos < transform.Length && IsDigitOrSign(transform[pos]))
					sy = Try!(ParseFloat(transform, ref pos));
				Try!(SkipCloseParen(transform, ref pos));

				result = Matrix.CreateScale(sx, sy, 1) * result;
			}
			else if (StartsWith(transform, pos, "rotate"))
			{
				pos += 6;
				Try!(SkipParen(transform, ref pos));
				let angle = Try!(ParseFloat(transform, ref pos)) * Math.PI_f / 180.0f;
				SkipComma(transform, ref pos);

				float cx = 0, cy = 0;
				if (pos < transform.Length && IsDigitOrSign(transform[pos]))
				{
					cx = Try!(ParseFloat(transform, ref pos));
					SkipComma(transform, ref pos);
					cy = Try!(ParseFloat(transform, ref pos));
				}
				Try!(SkipCloseParen(transform, ref pos));

				if (cx != 0 || cy != 0)
				{
					result = Matrix.CreateTranslation(-cx, -cy, 0) * result;
					result = Matrix.CreateRotationZ(angle) * result;
					result = Matrix.CreateTranslation(cx, cy, 0) * result;
				}
				else
				{
					result = Matrix.CreateRotationZ(angle) * result;
				}
			}
			else if (StartsWith(transform, pos, "skewX"))
			{
				pos += 5;
				Try!(SkipParen(transform, ref pos));
				let angle = Try!(ParseFloat(transform, ref pos)) * Math.PI_f / 180.0f;
				Try!(SkipCloseParen(transform, ref pos));

				var skew = Matrix.Identity;
				skew.M21 = (float)Math.Tan(angle);
				result = skew * result;
			}
			else if (StartsWith(transform, pos, "skewY"))
			{
				pos += 5;
				Try!(SkipParen(transform, ref pos));
				let angle = Try!(ParseFloat(transform, ref pos)) * Math.PI_f / 180.0f;
				Try!(SkipCloseParen(transform, ref pos));

				var skew = Matrix.Identity;
				skew.M12 = (float)Math.Tan(angle);
				result = skew * result;
			}
			else if (StartsWith(transform, pos, "matrix"))
			{
				pos += 6;
				Try!(SkipParen(transform, ref pos));
				let a = Try!(ParseFloat(transform, ref pos));
				let b = Try!(ParseFloat(transform, ref pos));
				let c = Try!(ParseFloat(transform, ref pos));
				let d = Try!(ParseFloat(transform, ref pos));
				let e = Try!(ParseFloat(transform, ref pos));
				let f = Try!(ParseFloat(transform, ref pos));
				Try!(SkipCloseParen(transform, ref pos));

				// SVG matrix(a,b,c,d,e,f) maps to:
				// [a c e]   [M11 M21 M41]
				// [b d f] = [M12 M22 M42]
				// [0 0 1]   [ 0   0   1 ]
				var mat = Matrix.Identity;
				mat.M11 = a;
				mat.M12 = b;
				mat.M21 = c;
				mat.M22 = d;
				mat.M41 = e;
				mat.M42 = f;
				result = mat * result;
			}
			else
			{
				return .Err; // Unknown transform
			}

			SkipWhitespace(transform, ref pos);
		}

		return .Ok(result);
	}

	// --- Helpers ---

	private static bool StartsWith(StringView s, int pos, StringView prefix)
	{
		if (pos + prefix.Length > s.Length)
			return false;
		for (int i = 0; i < prefix.Length; i++)
		{
			if (s[pos + i] != prefix[i])
				return false;
		}
		return true;
	}

	private static void SkipWhitespace(StringView s, ref int pos)
	{
		while (pos < s.Length && (s[pos] == ' ' || s[pos] == '\t' || s[pos] == '\n' || s[pos] == '\r'))
			pos++;
	}

	private static void SkipComma(StringView s, ref int pos)
	{
		SkipWhitespace(s, ref pos);
		if (pos < s.Length && s[pos] == ',')
			pos++;
		SkipWhitespace(s, ref pos);
	}

	private static Result<void> SkipParen(StringView s, ref int pos)
	{
		SkipWhitespace(s, ref pos);
		if (pos >= s.Length || s[pos] != '(')
			return .Err;
		pos++;
		SkipWhitespace(s, ref pos);
		return .Ok;
	}

	private static Result<void> SkipCloseParen(StringView s, ref int pos)
	{
		SkipWhitespace(s, ref pos);
		if (pos >= s.Length || s[pos] != ')')
			return .Err;
		pos++;
		return .Ok;
	}

	private static bool IsDigitOrSign(char8 c)
	{
		return (c >= '0' && c <= '9') || c == '-' || c == '+' || c == '.';
	}

	private static Result<float> ParseFloat(StringView s, ref int pos)
	{
		SkipComma(s, ref pos);
		if (pos >= s.Length)
			return .Err;

		let start = pos;

		if (pos < s.Length && (s[pos] == '-' || s[pos] == '+'))
			pos++;
		while (pos < s.Length && s[pos] >= '0' && s[pos] <= '9')
			pos++;
		if (pos < s.Length && s[pos] == '.')
		{
			pos++;
			while (pos < s.Length && s[pos] >= '0' && s[pos] <= '9')
				pos++;
		}
		if (pos < s.Length && (s[pos] == 'e' || s[pos] == 'E'))
		{
			pos++;
			if (pos < s.Length && (s[pos] == '-' || s[pos] == '+'))
				pos++;
			while (pos < s.Length && s[pos] >= '0' && s[pos] <= '9')
				pos++;
		}

		if (pos == start)
			return .Err;

		let numStr = s.Substring(start, pos - start);
		if (float.Parse(numStr) case .Ok(let val))
			return .Ok(val);

		return .Err;
	}
}
