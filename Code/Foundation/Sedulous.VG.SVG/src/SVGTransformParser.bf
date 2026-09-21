using System;
using Sedulous.Core;

namespace Sedulous.VG.SVG;

/// Parses a transform attribute into a matrix.
///
/// The functions COMPOSE left to right as written, which is what SVG specifies: each new
/// one pre multiplies, so the leftmost is applied last.
static class SVGTransformParser
{
	public static Result<Float4x4, ErrorCode> Parse(StringView transform)
	{
		var result = Float4x4.Identity();
		var pos = 0;

		while (pos < transform.Length)
		{
			SVGScan.SkipWhitespace(transform, ref pos);
			if (pos >= transform.Length)
				break;

			if (SVGScan.StartsWith(transform, pos, "translate"))
			{
				pos += 9;
				result = Try!(ParseTranslate(transform, ref pos)) * result;
			}
			else if (SVGScan.StartsWith(transform, pos, "scale"))
			{
				pos += 5;
				result = Try!(ParseScale(transform, ref pos)) * result;
			}
			else if (SVGScan.StartsWith(transform, pos, "rotate"))
			{
				pos += 6;
				// Rotation about a point is three factors rather than one, so it composes
				// itself onto the running result rather than returning a single matrix.
				result = Try!(ParseRotate(transform, ref pos, result));
			}
			else if (SVGScan.StartsWith(transform, pos, "skewX"))
			{
				pos += 5;
				result = Try!(ParseSkew(transform, ref pos, true)) * result;
			}
			else if (SVGScan.StartsWith(transform, pos, "skewY"))
			{
				pos += 5;
				result = Try!(ParseSkew(transform, ref pos, false)) * result;
			}
			else if (SVGScan.StartsWith(transform, pos, "matrix"))
			{
				pos += 6;
				result = Try!(ParseMatrix(transform, ref pos)) * result;
			}
			else
			{
				return .Err(.InvalidArgument);
			}

			SVGScan.SkipWhitespace(transform, ref pos);
		}

		return result;
	}

	private static Result<Float4x4, ErrorCode> ParseTranslate(StringView s, ref int pos)
	{
		Try!(OpenParen(s, ref pos));
		let tx = Try!(Number(s, ref pos));
		SVGScan.SkipComma(s, ref pos);

		// The second argument is OPTIONAL and defaults to zero, so translate(5) moves
		// along X only.
		var ty = 0.0f;
		if ((pos < s.Length) && SVGScan.IsDigitOrSign(s[pos]))
			ty = Try!(Number(s, ref pos));

		Try!(CloseParen(s, ref pos));
		return Float4x4.Translation(.(tx, ty, 0.0f));
	}

	private static Result<Float4x4, ErrorCode> ParseScale(StringView s, ref int pos)
	{
		Try!(OpenParen(s, ref pos));
		let sx = Try!(Number(s, ref pos));
		SVGScan.SkipComma(s, ref pos);

		// One argument scales UNIFORMLY, which is the difference from translate's default.
		var sy = sx;
		if ((pos < s.Length) && SVGScan.IsDigitOrSign(s[pos]))
			sy = Try!(Number(s, ref pos));

		Try!(CloseParen(s, ref pos));
		return Float4x4.Scale(.(sx, sy, 1.0f));
	}

	private static Result<Float4x4, ErrorCode> ParseRotate(StringView s, ref int pos,
		Float4x4 running)
	{
		Try!(OpenParen(s, ref pos));
		let degrees = Try!(Number(s, ref pos));
		let angle = degrees * Pi / 180.0f;
		SVGScan.SkipComma(s, ref pos);

		var cx = 0.0f;
		var cy = 0.0f;
		var aboutPoint = false;
		if ((pos < s.Length) && SVGScan.IsDigitOrSign(s[pos]))
		{
			cx = Try!(Number(s, ref pos));
			SVGScan.SkipComma(s, ref pos);
			cy = Try!(Number(s, ref pos));
			aboutPoint = true;
		}

		Try!(CloseParen(s, ref pos));

		if (!aboutPoint)
			return Float4x4.RotationZ(angle) * running;

		// Move the centre to the origin, rotate, and move it back.
		//
		// Composed as ONE factor and then pre multiplied, because these matrices are row
		// vector: in `a * b` the left one is applied FIRST, so writing the three steps as
		// three successive pre multiplications would run them backwards and the rotation
		// would not leave the point fixed.
		let toOrigin = Float4x4.Translation(.(-cx, -cy, 0.0f));
		let back = Float4x4.Translation(.(cx, cy, 0.0f));
		return (toOrigin * Float4x4.RotationZ(angle) * back) * running;
	}

	private static Result<Float4x4, ErrorCode> ParseSkew(StringView s, ref int pos, bool alongX)
	{
		Try!(OpenParen(s, ref pos));
		let degrees = Try!(Number(s, ref pos));
		Try!(CloseParen(s, ref pos));

		var skew = Float4x4.Identity();
		// A skew along X displaces X by Y, which in a row vector matrix is the entry that
		// carries Y into X.
		if (alongX)
			skew[1, 0] = Tan(degrees * Pi / 180.0f);
		else
			skew[0, 1] = Tan(degrees * Pi / 180.0f);
		return skew;
	}

	private static Result<Float4x4, ErrorCode> ParseMatrix(StringView s, ref int pos)
	{
		Try!(OpenParen(s, ref pos));

		float[6] values = .();
		for (int i = 0; i < 6; i++)
			values[i] = Try!(Number(s, ref pos));

		Try!(CloseParen(s, ref pos));

		// SVG's six values are the two by two linear part in column order, then the
		// translation. In a row vector matrix that is the top left block and the fourth row.
		var matrix = Float4x4.Identity();
		matrix[0, 0] = values[0];
		matrix[0, 1] = values[1];
		matrix[1, 0] = values[2];
		matrix[1, 1] = values[3];
		matrix[3, 0] = values[4];
		matrix[3, 1] = values[5];
		return matrix;
	}

	private static Result<void, ErrorCode> OpenParen(StringView s, ref int pos)
	{
		SVGScan.SkipWhitespace(s, ref pos);
		if ((pos >= s.Length) || (s[pos] != '('))
			return .Err(.InvalidArgument);
		pos++;
		SVGScan.SkipWhitespace(s, ref pos);
		return .Ok;
	}

	private static Result<void, ErrorCode> CloseParen(StringView s, ref int pos)
	{
		SVGScan.SkipWhitespace(s, ref pos);
		if ((pos >= s.Length) || (s[pos] != ')'))
			return .Err(.InvalidArgument);
		pos++;
		return .Ok;
	}

	private static Result<float, ErrorCode> Number(StringView s, ref int pos)
	{
		SVGScan.SkipComma(s, ref pos);
		if (!SVGScan.ScanNumber(s, ref pos, let value))
			return .Err(.InvalidArgument);
		return value;
	}
}
