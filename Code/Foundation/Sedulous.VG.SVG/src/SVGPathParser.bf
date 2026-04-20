using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.VG;

namespace Sedulous.VG.SVG;

/// Parses SVG path data strings into PathBuilder commands
public static class SVGPathParser
{
	/// Parse an SVG path data string (d attribute) into a PathBuilder
	public static Result<void> Parse(StringView pathData, PathBuilder builder)
	{
		var pos = 0;
		var currentX = 0.0f;
		var currentY = 0.0f;
		var subPathStartX = 0.0f;
		var subPathStartY = 0.0f;
		var lastControlX = 0.0f;
		var lastControlY = 0.0f;
		char8 lastCommand = (char8)0;

		while (pos < pathData.Length)
		{
			SkipWhitespaceAndCommas(pathData, ref pos);
			if (pos >= pathData.Length)
				break;

			var cmd = pathData[pos];
			bool isRelative = cmd >= 'a' && cmd <= 'z';

			if (IsCommand(cmd))
			{
				pos++;
			}
			else if (IsDigitOrSign(cmd))
			{
				// Implicit repeat of last command
				// After MoveTo, implicit repeats become LineTo
				if (lastCommand == 'M')
					cmd = 'L';
				else if (lastCommand == 'm')
					cmd = 'l';
				else
					cmd = lastCommand;
				isRelative = cmd >= 'a' && cmd <= 'z';
			}
			else
			{
				return .Err;
			}

			let cmdUpper = isRelative ? (char8)(cmd - 32) : cmd;

			switch (cmdUpper)
			{
			case 'M': // MoveTo
				let x = Try!(ParseFloat(pathData, ref pos));
				let y = Try!(ParseFloat(pathData, ref pos));
				let absX = isRelative ? currentX + x : x;
				let absY = isRelative ? currentY + y : y;
				builder.MoveTo(absX, absY);
				currentX = absX;
				currentY = absY;
				subPathStartX = absX;
				subPathStartY = absY;

			case 'L': // LineTo
				let x = Try!(ParseFloat(pathData, ref pos));
				let y = Try!(ParseFloat(pathData, ref pos));
				let absX = isRelative ? currentX + x : x;
				let absY = isRelative ? currentY + y : y;
				builder.LineTo(absX, absY);
				currentX = absX;
				currentY = absY;

			case 'H': // Horizontal LineTo
				let x = Try!(ParseFloat(pathData, ref pos));
				let absX = isRelative ? currentX + x : x;
				builder.LineTo(absX, currentY);
				currentX = absX;

			case 'V': // Vertical LineTo
				let y = Try!(ParseFloat(pathData, ref pos));
				let absY = isRelative ? currentY + y : y;
				builder.LineTo(currentX, absY);
				currentY = absY;

			case 'C': // Cubic Bezier
				let c1x = Try!(ParseFloat(pathData, ref pos));
				let c1y = Try!(ParseFloat(pathData, ref pos));
				let c2x = Try!(ParseFloat(pathData, ref pos));
				let c2y = Try!(ParseFloat(pathData, ref pos));
				let x = Try!(ParseFloat(pathData, ref pos));
				let y = Try!(ParseFloat(pathData, ref pos));
				let absC1x = isRelative ? currentX + c1x : c1x;
				let absC1y = isRelative ? currentY + c1y : c1y;
				let absC2x = isRelative ? currentX + c2x : c2x;
				let absC2y = isRelative ? currentY + c2y : c2y;
				let absX = isRelative ? currentX + x : x;
				let absY = isRelative ? currentY + y : y;
				builder.CubicTo(absC1x, absC1y, absC2x, absC2y, absX, absY);
				lastControlX = absC2x;
				lastControlY = absC2y;
				currentX = absX;
				currentY = absY;

			case 'S': // Smooth cubic Bezier
				let c2x = Try!(ParseFloat(pathData, ref pos));
				let c2y = Try!(ParseFloat(pathData, ref pos));
				let x = Try!(ParseFloat(pathData, ref pos));
				let y = Try!(ParseFloat(pathData, ref pos));
				// Reflect last control point
				var rc1x = currentX;
				var rc1y = currentY;
				if (lastCommand == 'C' || lastCommand == 'c' || lastCommand == 'S' || lastCommand == 's')
				{
					rc1x = 2 * currentX - lastControlX;
					rc1y = 2 * currentY - lastControlY;
				}
				let absC2x = isRelative ? currentX + c2x : c2x;
				let absC2y = isRelative ? currentY + c2y : c2y;
				let absX = isRelative ? currentX + x : x;
				let absY = isRelative ? currentY + y : y;
				builder.CubicTo(rc1x, rc1y, absC2x, absC2y, absX, absY);
				lastControlX = absC2x;
				lastControlY = absC2y;
				currentX = absX;
				currentY = absY;

			case 'Q': // Quadratic Bezier
				let cx = Try!(ParseFloat(pathData, ref pos));
				let cy = Try!(ParseFloat(pathData, ref pos));
				let x = Try!(ParseFloat(pathData, ref pos));
				let y = Try!(ParseFloat(pathData, ref pos));
				let absCx = isRelative ? currentX + cx : cx;
				let absCy = isRelative ? currentY + cy : cy;
				let absX = isRelative ? currentX + x : x;
				let absY = isRelative ? currentY + y : y;
				builder.QuadTo(absCx, absCy, absX, absY);
				lastControlX = absCx;
				lastControlY = absCy;
				currentX = absX;
				currentY = absY;

			case 'T': // Smooth quadratic Bezier
				let x = Try!(ParseFloat(pathData, ref pos));
				let y = Try!(ParseFloat(pathData, ref pos));
				// Reflect last control point
				var rcx = currentX;
				var rcy = currentY;
				if (lastCommand == 'Q' || lastCommand == 'q' || lastCommand == 'T' || lastCommand == 't')
				{
					rcx = 2 * currentX - lastControlX;
					rcy = 2 * currentY - lastControlY;
				}
				let absX = isRelative ? currentX + x : x;
				let absY = isRelative ? currentY + y : y;
				builder.QuadTo(rcx, rcy, absX, absY);
				lastControlX = rcx;
				lastControlY = rcy;
				currentX = absX;
				currentY = absY;

			case 'A': // Arc
				let rx = Try!(ParseFloat(pathData, ref pos));
				let ry = Try!(ParseFloat(pathData, ref pos));
				let xRotation = Try!(ParseFloat(pathData, ref pos)) * Math.PI_f / 180.0f;
				let largeArc = Try!(ParseFlag(pathData, ref pos));
				let sweep = Try!(ParseFlag(pathData, ref pos));
				let x = Try!(ParseFloat(pathData, ref pos));
				let y = Try!(ParseFloat(pathData, ref pos));
				let absX = isRelative ? currentX + x : x;
				let absY = isRelative ? currentY + y : y;
				builder.ArcTo(rx, ry, xRotation, largeArc, sweep, absX, absY);
				currentX = absX;
				currentY = absY;

			case 'Z': // Close
				builder.Close();
				currentX = subPathStartX;
				currentY = subPathStartY;

			default:
				return .Err;
			}

			lastCommand = cmd;
		}

		return .Ok;
	}

	// --- Parsing helpers ---

	private static bool IsCommand(char8 c)
	{
		switch (c)
		{
		case 'M', 'm', 'L', 'l', 'H', 'h', 'V', 'v',
			 'C', 'c', 'S', 's', 'Q', 'q', 'T', 't',
			 'A', 'a', 'Z', 'z':
			return true;
		default:
			return false;
		}
	}

	private static bool IsDigitOrSign(char8 c)
	{
		return (c >= '0' && c <= '9') || c == '-' || c == '+' || c == '.';
	}

	private static void SkipWhitespaceAndCommas(StringView s, ref int pos)
	{
		while (pos < s.Length && (s[pos] == ' ' || s[pos] == '\t' || s[pos] == '\n' || s[pos] == '\r' || s[pos] == ','))
			pos++;
	}

	private static Result<float> ParseFloat(StringView s, ref int pos)
	{
		SkipWhitespaceAndCommas(s, ref pos);
		if (pos >= s.Length)
			return .Err;

		let start = pos;
		bool hasDot = false;

		// Sign
		if (pos < s.Length && (s[pos] == '-' || s[pos] == '+'))
			pos++;

		// Integer part
		while (pos < s.Length && s[pos] >= '0' && s[pos] <= '9')
			pos++;

		// Decimal point (only first one - a second dot starts a new number)
		if (pos < s.Length && s[pos] == '.')
		{
			hasDot = true;
			pos++;
			while (pos < s.Length && s[pos] >= '0' && s[pos] <= '9')
				pos++;
		}

		// Exponent
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

		// Handle leading dot (e.g., ".81" -> parse as 0.81)
		if (numStr.Length > 0 && numStr[0] == '.')
		{
			let withZero = scope String("0");
			withZero.Append(numStr);
			if (float.Parse(withZero) case .Ok(let val))
				return .Ok(val);
		}
		// Handle negative leading dot (e.g., "-.81")
		else if (numStr.Length > 1 && numStr[0] == '-' && numStr[1] == '.')
		{
			let withZero = scope String("-0");
			withZero.Append(numStr, 1, numStr.Length - 1);
			if (float.Parse(withZero) case .Ok(let val))
				return .Ok(val);
		}

		if (float.Parse(numStr) case .Ok(let val))
			return .Ok(val);

		return .Err;
	}

	private static Result<bool> ParseFlag(StringView s, ref int pos)
	{
		SkipWhitespaceAndCommas(s, ref pos);
		if (pos >= s.Length)
			return .Err;

		let c = s[pos];
		if (c == '0')
		{
			pos++;
			return .Ok(false);
		}
		else if (c == '1')
		{
			pos++;
			return .Ok(true);
		}

		return .Err;
	}
}
