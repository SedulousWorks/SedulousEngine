using System;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.VG.SVG;

/// Parses a path's data attribute into a builder.
static class SVGPathParser
{
	public static Result<void, ErrorCode> Parse(StringView pathData, PathBuilder builder)
	{
		var pos = 0;
		var current = Float2.Zero;
		var subPathStart = Float2.Zero;
		// Where the previous curve's last control point was, which is what a smooth command
		// reflects to get its own first one.
		var lastControl = Float2.Zero;
		char8 lastCommand = 0;

		while (pos < pathData.Length)
		{
			SVGScan.SkipWhitespaceAndCommas(pathData, ref pos);
			if (pos >= pathData.Length)
				break;

			var command = pathData[pos];

			if (IsCommand(command))
			{
				pos++;
			}
			else if (SVGScan.IsDigitOrSign(command))
			{
				// A bare number REPEATS the previous command, which is how a polyline is
				// written as one L with many pairs.
				//
				// Except after a move, which repeats as a LINE: that is what makes
				// "M 0 0 10 0 10 10" a triangle rather than three separate moves.
				if (lastCommand == 'M')
					command = 'L';
				else if (lastCommand == 'm')
					command = 'l';
				else
					command = lastCommand;

				if (command == 0)
					return .Err(.InvalidArgument);
			}
			else
			{
				return .Err(.InvalidArgument);
			}

			// Lower case is RELATIVE to the current point; upper case is absolute.
			let relative = (command >= 'a') && (command <= 'z');
			let upper = relative ? (char8)(command - 32) : command;

			Try!(RunCommand(pathData, ref pos, builder, upper, relative, lastCommand,
				ref current, ref subPathStart, ref lastControl));

			lastCommand = command;
		}

		return .Ok;
	}

	private static Result<void, ErrorCode> RunCommand(StringView s, ref int pos,
		PathBuilder builder, char8 command, bool relative, char8 lastCommand, ref Float2 current,
		ref Float2 subPathStart, ref Float2 lastControl)
	{
		Float2 Absolute(Float2 point) => relative ? (current + point) : point;

		switch (command)
		{
		case 'M':
			let target = Absolute(Try!(Point(s, ref pos)));
			builder.MoveTo(target);
			current = target;
			subPathStart = target;

		case 'L':
			let target = Absolute(Try!(Point(s, ref pos)));
			builder.LineTo(target);
			current = target;

		case 'H':
			// Horizontal: the Y stays where it was, which is why it takes one number.
			let x = Try!(Number(s, ref pos));
			current = .(relative ? (current.X + x) : x, current.Y);
			builder.LineTo(current);

		case 'V':
			let y = Try!(Number(s, ref pos));
			current = .(current.X, relative ? (current.Y + y) : y);
			builder.LineTo(current);

		case 'C':
			let control1 = Absolute(Try!(Point(s, ref pos)));
			let control2 = Absolute(Try!(Point(s, ref pos)));
			let target = Absolute(Try!(Point(s, ref pos)));
			builder.CubicTo(control1, control2, target);
			lastControl = control2;
			current = target;

		case 'S':
			// Smooth cubic: the first control point is the previous one REFLECTED through
			// the current point, which is what makes the join tangent continuous. After
			// anything that was not a cubic there is nothing to reflect, so it sits on the
			// current point and the curve starts straight.
			let control2 = Absolute(Try!(Point(s, ref pos)));
			let target = Absolute(Try!(Point(s, ref pos)));
			let control1 = FollowsCubic(lastCommand) ? ((current * 2.0f) - lastControl) : current;
			builder.CubicTo(control1, control2, target);
			lastControl = control2;
			current = target;

		case 'Q':
			let control = Absolute(Try!(Point(s, ref pos)));
			let target = Absolute(Try!(Point(s, ref pos)));
			builder.QuadTo(control, target);
			lastControl = control;
			current = target;

		case 'T':
			// Smooth quadratic: the same reflection, of the one control point a quadratic
			// has.
			let target = Absolute(Try!(Point(s, ref pos)));
			let control = FollowsQuadratic(lastCommand) ? ((current * 2.0f) - lastControl) : current;
			builder.QuadTo(control, target);
			lastControl = control;
			current = target;

		case 'A':
			let rx = Try!(Number(s, ref pos));
			let ry = Try!(Number(s, ref pos));
			let rotation = Try!(Number(s, ref pos));
			// The two flags are SINGLE DIGITS with no separator required, which is why they
			// are scanned rather than parsed as numbers: "a1 1 0 0110 0" is legal.
			let largeArc = Try!(Flag(s, ref pos));
			let sweep = Try!(Flag(s, ref pos));
			let target = Absolute(Try!(Point(s, ref pos)));
			builder.ArcTo(rx, ry, rotation * Pi / 180.0f, largeArc, sweep, target);
			current = target;

		case 'Z':
			builder.Close();
			current = subPathStart;

		default:
			return .Err(.InvalidArgument);
		}

		return .Ok;
	}

	private static bool FollowsCubic(char8 command)
		=> (command == 'C') || (command == 'c') || (command == 'S') || (command == 's');

	private static bool FollowsQuadratic(char8 command)
		=> (command == 'Q') || (command == 'q') || (command == 'T') || (command == 't');

	private static bool IsCommand(char8 c)
	{
		switch (SVGScan.ToLower(c))
		{
		case 'm', 'l', 'h', 'v', 'c', 's', 'q', 't', 'a', 'z': return true;
		default: return false;
		}
	}

	private static Result<float, ErrorCode> Number(StringView s, ref int pos)
	{
		SVGScan.SkipWhitespaceAndCommas(s, ref pos);
		if (!SVGScan.ScanNumber(s, ref pos, let value))
			return .Err(.InvalidArgument);
		return value;
	}

	private static Result<Float2, ErrorCode> Point(StringView s, ref int pos)
	{
		let x = Try!(Number(s, ref pos));
		let y = Try!(Number(s, ref pos));
		return Float2(x, y);
	}

	/// One digit, zero or one. Not a number: the grammar allows flags to run together with
	/// what follows them.
	private static Result<bool, ErrorCode> Flag(StringView s, ref int pos)
	{
		SVGScan.SkipWhitespaceAndCommas(s, ref pos);
		if (pos >= s.Length)
			return .Err(.InvalidArgument);

		switch (s[pos])
		{
		case '0':
			pos++;
			return false;
		case '1':
			pos++;
			return true;
		default:
			return .Err(.InvalidArgument);
		}
	}
}
