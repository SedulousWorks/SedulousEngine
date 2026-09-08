using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.VG.SVG;

namespace Sedulous.VG.SVG.Tests;

/// Parsing path data.
class SVGPathParserTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;
	private static bool NearPoint(Float2 a, Float2 b, float epsilon = 0.001f)
		=> Near(a.X, b.X, epsilon) && Near(a.Y, b.Y, epsilon);

	/// Parses into a path. THE CALLER OWNS what comes back.
	private static Path Parse(StringView data)
	{
		let builder = scope PathBuilder();
		Test.Assert(SVGPathParser.Parse(data, builder) case .Ok, scope $"'{data}' did not parse");
		return builder.ToPath();
	}

	private static int CountOf(Path path, PathCommand wanted)
	{
		var count = 0;
		for (let command in path.Commands)
		{
			if (command == wanted)
				count++;
		}
		return count;
	}

	[Test]
	public static void AbsoluteCommandsPlacePointsWhereTheySay()
	{
		let path = Parse("M 10 20 L 30 40");
		defer delete path;

		Test.Assert(path.CommandCount == 2);
		Test.Assert(NearPoint(path.Points[0], .(10, 20)));
		Test.Assert(NearPoint(path.Points[1], .(30, 40)));
	}

	/// A lower case command is RELATIVE to where the pen is.
	[Test]
	public static void RelativeCommandsAccumulate()
	{
		let path = Parse("m 10 20 l 5 5 l 5 5");
		defer delete path;

		Test.Assert(NearPoint(path.Points[0], .(10, 20)));
		Test.Assert(NearPoint(path.Points[1], .(15, 25)));
		Test.Assert(NearPoint(path.Points[2], .(20, 30)));
	}

	/// A bare number repeats the previous command, which is how a polyline is written with
	/// one letter.
	[Test]
	public static void ABareNumberRepeatsTheCommand()
	{
		let path = Parse("M 0 0 L 10 0 20 0 30 0");
		defer delete path;

		Test.Assert(CountOf(path, .LineTo) == 3);
		Test.Assert(NearPoint(path.Points[3], .(30, 0)));
	}

	/// Except after a MOVE, which repeats as a LINE. Without that, a triangle written as
	/// one M with three pairs would be three disconnected moves.
	[Test]
	public static void ARepeatAfterAMoveIsALine()
	{
		let path = Parse("M 0 0 10 0 10 10");
		defer delete path;

		Test.Assert(CountOf(path, .MoveTo) == 1);
		Test.Assert(CountOf(path, .LineTo) == 2);

		let relative = Parse("m 0 0 10 0 10 10");
		defer delete relative;
		Test.Assert(CountOf(relative, .MoveTo) == 1);
		Test.Assert(CountOf(relative, .LineTo) == 2);
		Test.Assert(NearPoint(relative.Points[2], .(20, 10)), "and it stays relative");
	}

	/// Horizontal and vertical each take ONE number and keep the other coordinate.
	[Test]
	public static void HorizontalAndVerticalKeepTheOtherAxis()
	{
		let path = Parse("M 10 20 H 50 V 60");
		defer delete path;

		Test.Assert(NearPoint(path.Points[1], .(50, 20)), "the Y stayed");
		Test.Assert(NearPoint(path.Points[2], .(50, 60)), "and then the X");

		let relative = Parse("M 10 20 h 5 v 5");
		defer delete relative;
		Test.Assert(NearPoint(relative.Points[1], .(15, 20)));
		Test.Assert(NearPoint(relative.Points[2], .(15, 25)));
	}

	[Test]
	public static void CurvesTakeTheirControlPoints()
	{
		let cubic = Parse("M 0 0 C 1 2 3 4 5 6");
		defer delete cubic;
		Test.Assert(CountOf(cubic, .CubicTo) == 1);
		Test.Assert(NearPoint(cubic.Points[1], .(1, 2)));
		Test.Assert(NearPoint(cubic.Points[2], .(3, 4)));
		Test.Assert(NearPoint(cubic.Points[3], .(5, 6)));

		let quadratic = Parse("M 0 0 Q 1 2 3 4");
		defer delete quadratic;
		Test.Assert(CountOf(quadratic, .QuadTo) == 1);
		Test.Assert(NearPoint(quadratic.Points[1], .(1, 2)));
		Test.Assert(NearPoint(quadratic.Points[2], .(3, 4)));
	}

	/// A smooth cubic REFLECTS the previous control point through the current point, which
	/// is what makes the join tangent continuous.
	[Test]
	public static void ASmoothCubicReflectsThePreviousControl()
	{
		let path = Parse("M 0 0 C 1 1 2 2 3 3 S 5 5 6 6");
		defer delete path;

		// The cubic ended at (3,3) with its last control at (2,2), so the reflection is
		// (4,4).
		Test.Assert(NearPoint(path.Points[4], .(4, 4)), "reflected through the endpoint");
		Test.Assert(NearPoint(path.Points[5], .(5, 5)));
	}

	/// After something that was NOT a cubic there is nothing to reflect, so the control
	/// sits on the current point and the curve starts straight.
	[Test]
	public static void ASmoothCubicAfterALineStartsStraight()
	{
		let path = Parse("M 0 0 L 3 3 S 5 5 6 6");
		defer delete path;
		Test.Assert(NearPoint(path.Points[2], .(3, 3)), "the current point, not a reflection");
	}

	[Test]
	public static void ASmoothQuadraticReflectsToo()
	{
		let path = Parse("M 0 0 Q 1 1 2 2 T 4 4");
		defer delete path;

		// The quadratic's control was (1,1) and it ended at (2,2), so the reflection is
		// (3,3).
		Test.Assert(NearPoint(path.Points[3], .(3, 3)));

		let afterLine = Parse("M 0 0 L 2 2 T 4 4");
		defer delete afterLine;
		Test.Assert(NearPoint(afterLine.Points[2], .(2, 2)), "nothing to reflect");
	}

	/// An arc becomes cubics, so nothing downstream needs an arc case.
	[Test]
	public static void AnArcBecomesCubics()
	{
		let path = Parse("M 0 0 A 10 10 0 0 1 10 10");
		defer delete path;

		Test.Assert(CountOf(path, .CubicTo) > 0);
		Test.Assert(NearPoint(path.Points[path.PointCount - 1], .(10, 10), 0.01f));
	}

	/// The arc flags are SINGLE DIGITS with no separator required, which is why they are
	/// scanned rather than parsed as numbers.
	[Test]
	public static void ArcFlagsNeedNoSeparator()
	{
		let spaced = Parse("M 0 0 A 10 10 0 0 1 10 10");
		defer delete spaced;

		// The two flags and the following coordinate run together.
		let packed = Parse("M 0 0 A 10 10 0 0110 10");
		defer delete packed;

		Test.Assert(packed.CommandCount == spaced.CommandCount);
		Test.Assert(NearPoint(packed.Points[packed.PointCount - 1], .(10, 10), 0.01f));
	}

	[Test]
	public static void CloseReturnsThePenToTheSubPathStart()
	{
		let path = Parse("M 10 10 L 20 10 L 20 20 Z L 30 30");
		defer delete path;

		Test.Assert(CountOf(path, .Close) == 1);

		var iterator = path.GetIterator();
		PathSegment last = .();
		while (iterator.GetNext(let segment))
			last = segment;

		Test.Assert(NearPoint(last.StartPoint, .(10, 10)), "back where the subpath began");
	}

	/// Separators are flexible: commas, spaces, newlines, or nothing at all between a sign
	/// and the previous number.
	[Test]
	public static void SeparatorsAreFlexible()
	{
		for (let data in scope StringView[](
			"M 0 0 L 10 20", "M0 0L10 20", "M 0,0 L 10,20", "M0,0L10,20",
			"M 0 0\nL 10 20", "M 0 0 L 10 20 ", "M0 0L10,20"))
		{
			let path = Parse(data);
			defer delete path;
			Test.Assert(NearPoint(path.Points[1], .(10, 20)), scope $"'{data}'");
		}
	}

	/// A negative number needs no separator before it: the sign ends the previous token.
	[Test]
	public static void ANegativeSignSeparatesNumbers()
	{
		let path = Parse("M0 0L-10-20");
		defer delete path;
		Test.Assert(NearPoint(path.Points[1], .(-10, -20)));
	}

	[Test]
	public static void FractionalAndExponentialNumbersParse()
	{
		let path = Parse("M 0.5 .25 L 1e2 -1.5e1");
		defer delete path;
		Test.Assert(NearPoint(path.Points[0], .(0.5f, 0.25f)));
		Test.Assert(NearPoint(path.Points[1], .(100, -15)));
	}

	[Test]
	public static void AnEmptyPathParsesToNothing()
	{
		let path = Parse("");
		defer delete path;
		Test.Assert(path.CommandCount == 0);

		let spaces = Parse("   \n\t ");
		defer delete spaces;
		Test.Assert(spaces.CommandCount == 0);
	}

	/// Malformed data FAILS rather than producing a partial shape, which would draw
	/// something the file never described.
	[Test]
	public static void MalformedDataFails()
	{
		for (let data in scope StringView[](
			"M", "M 10", "L 10 20 30", "X 10 20", "M 0 0 C 1 2 3",
			"M 0 0 A 10 10 0 5 1 10 10", "M 0 0 Q 1 2"))
		{
			let builder = scope PathBuilder();
			Test.Assert(SVGPathParser.Parse(data, builder) case .Err,
				scope $"'{data}' should not parse");
		}
	}

	/// A real path: several subpaths, mixed cases, and every command kind.
	[Test]
	public static void AMixedPathParsesEndToEnd()
	{
		let path = Parse("M10,10 h30 v30 h-30 z M60,10 c5,0 5,10 0,10 s-5,10 0,10 Z");
		defer delete path;

		Test.Assert(CountOf(path, .MoveTo) == 2);
		Test.Assert(CountOf(path, .Close) == 2);
		Test.Assert(CountOf(path, .LineTo) == 3);
		Test.Assert(CountOf(path, .CubicTo) == 2);
		Test.Assert(path.SubPathCount == 2);
	}
}
