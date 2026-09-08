using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.VG.Tests;

/// The path model: building one, walking it, and the queries over it.
class PathTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;
	private static bool NearPoint(Float2 a, Float2 b, float epsilon = 0.01f)
		=> Near(a.X, b.X, epsilon) && Near(a.Y, b.Y, epsilon);

	/// A closed square from (0,0) to (10,10).
	private static Path Square()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);
		builder.LineTo(10, 10);
		builder.LineTo(0, 10);
		builder.Close();
		return builder.ToPath();
	}

	[Test]
	public static void BoundsCoverEveryPoint()
	{
		let path = Square();
		defer delete path;

		let bounds = path.GetBounds();
		Test.Assert(bounds.X == 0.0f);
		Test.Assert(bounds.Y == 0.0f);
		Test.Assert(bounds.Width == 10.0f);
		Test.Assert(bounds.Height == 10.0f);
	}

	/// An empty path has empty bounds rather than an inverted or infinite box.
	[Test]
	public static void AnEmptyPathHasEmptyBounds()
	{
		let path = scope Path();
		let bounds = path.GetBounds();
		Test.Assert((bounds.Width == 0.0f) && (bounds.Height == 0.0f));
		Test.Assert(path.CommandCount == 0);
		Test.Assert(path.SubPathCount == 0);
	}

	/// The bounds cover the CONTROL points, so a curve's box is conservative rather than
	/// tight. That is what a cover quad and a culling test both want.
	[Test]
	public static void CurveBoundsAreConservative()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		// The curve never reaches y = 10; its control points do.
		builder.CubicTo(0, 10, 10, 10, 10, 0);
		let path = builder.ToPath();
		defer delete path;

		Test.Assert(path.GetBounds().Height == 10.0f, "the control polygon, not the curve");
	}

	[Test]
	public static void ContainsAnswersInsideAndOutside()
	{
		let path = Square();
		defer delete path;

		Test.Assert(path.Contains(.(5, 5), .NonZero));
		Test.Assert(path.Contains(.(5, 5), .EvenOdd));
		Test.Assert(!path.Contains(.(15, 5), .NonZero));
		Test.Assert(!path.Contains(.(-1, 5), .EvenOdd));
		Test.Assert(!path.Contains(.(5, 20), .NonZero));
	}

	/// The two rules disagree about a hole, which is the entire reason both exist. Two
	/// squares wound the SAME way: even odd cancels them, non zero does not.
	[Test]
	public static void TheFillRulesDisagreeAboutAnOverlap()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);
		builder.LineTo(10, 10);
		builder.LineTo(0, 10);
		builder.Close();
		builder.MoveTo(2, 2);
		builder.LineTo(8, 2);
		builder.LineTo(8, 8);
		builder.LineTo(2, 8);
		builder.Close();

		let path = builder.ToPath();
		defer delete path;

		Test.Assert(!path.Contains(.(5, 5), .EvenOdd), "two crossings cancel");
		Test.Assert(path.Contains(.(5, 5), .NonZero), "wound the same way, so it fills");
		// Between the two squares only the outer one contains the point, so both agree.
		Test.Assert(path.Contains(.(1, 5), .EvenOdd));
		Test.Assert(path.Contains(.(1, 5), .NonZero));
	}

	/// A point exactly on a horizontal ray through a vertex must be counted once, not
	/// twice or never. The asymmetric edge comparisons are what guarantee it.
	[Test]
	public static void APointLevelWithAVertexIsCountedOnce()
	{
		let path = Square();
		defer delete path;

		Test.Assert(path.Contains(.(5, 0.0f), .NonZero), "on the bottom edge's level");
		Test.Assert(!path.Contains(.(15, 0.0f), .NonZero), "and outside it horizontally");
	}

	[Test]
	public static void SubPathsAreCountedByTheirMoves()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(1, 1);
		builder.MoveTo(5, 5);
		builder.LineTo(6, 6);
		builder.MoveTo(9, 9);

		let path = builder.ToPath();
		defer delete path;
		Test.Assert(path.SubPathCount == 3);
	}

	[Test]
	public static void LengthAddsUpTheDrawnSegments()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);
		builder.LineTo(10, 5);
		let path = builder.ToPath();
		defer delete path;

		Test.Assert(Near(path.GetLength(), 15.0f));
	}

	/// A Close contributes NOTHING to the length, so a closed shape measures the segments
	/// that were drawn rather than the implicit return.
	[Test]
	public static void ACloseAddsNoLength()
	{
		let open = scope PathBuilder();
		open.MoveTo(0, 0);
		open.LineTo(10, 0);
		let openPath = open.ToPath();
		defer delete openPath;

		let closed = scope PathBuilder();
		closed.MoveTo(0, 0);
		closed.LineTo(10, 0);
		closed.Close();
		let closedPath = closed.ToPath();
		defer delete closedPath;

		Test.Assert(Near(openPath.GetLength(), closedPath.GetLength()));
	}

	[Test]
	public static void PointAtDistanceWalksTheSegments()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);
		builder.LineTo(10, 10);
		let path = builder.ToPath();
		defer delete path;

		Test.Assert(NearPoint(path.GetPointAtDistance(0.0f), .(0, 0)));
		Test.Assert(NearPoint(path.GetPointAtDistance(5.0f), .(5, 0)));
		Test.Assert(NearPoint(path.GetPointAtDistance(10.0f), .(10, 0)), "the seam");
		Test.Assert(NearPoint(path.GetPointAtDistance(15.0f), .(10, 5)), "onto the next segment");
	}

	/// Past the end it is the last point, which is what a caller stepping a dash pattern
	/// wants rather than a wrap or an error.
	[Test]
	public static void PastTheEndIsTheLastPoint()
	{
		let path = Square();
		defer delete path;
		Test.Assert(NearPoint(path.GetPointAtDistance(9999.0f), .(0, 10)));

		let empty = scope Path();
		Test.Assert(empty.GetPointAtDistance(1.0f) == Float2.Zero);
		Test.Assert(empty.GetTangentAtDistance(1.0f) == Float2(1, 0));
	}

	[Test]
	public static void TangentAtDistanceFollowsTheDirectionOfTravel()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);
		builder.LineTo(10, 10);
		let path = builder.ToPath();
		defer delete path;

		Test.Assert(NearPoint(path.GetTangentAtDistance(5.0f), .(1, 0)));
		Test.Assert(NearPoint(path.GetTangentAtDistance(15.0f), .(0, 1)));
	}

	// ---- iteration ----

	[Test]
	public static void IterationYieldsEachCommandWithItsPoints()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(1, 1);
		builder.LineTo(2, 2);
		builder.QuadTo(3, 3, 4, 4);
		builder.CubicTo(5, 5, 6, 6, 7, 7);
		builder.Close();

		let path = builder.ToPath();
		defer delete path;

		var iterator = path.GetIterator();
		let commands = scope List<PathCommand>();
		let counts = scope List<int>();
		let starts = scope List<Float2>();

		while (iterator.GetNext(let segment))
		{
			commands.Add(segment.Command);
			counts.Add(segment.Points.Length);
			starts.Add(segment.StartPoint);
		}

		Test.Assert(commands.Count == 5);
		Test.Assert(commands[0] == .MoveTo && counts[0] == 1);
		Test.Assert(commands[1] == .LineTo && counts[1] == 1);
		Test.Assert(commands[2] == .QuadTo && counts[2] == 2);
		Test.Assert(commands[3] == .CubicTo && counts[3] == 3);
		Test.Assert(commands[4] == .Close && counts[4] == 0, "a close carries no points");

		// The start point is where the pen was, which is what every curve needs as its
		// own first point.
		Test.Assert(NearPoint(starts[1], .(1, 1)));
		Test.Assert(NearPoint(starts[2], .(2, 2)));
		Test.Assert(NearPoint(starts[3], .(4, 4)), "the quad's endpoint, not its control");
	}

	/// After a Close the pen is back at the subpath's start, so what follows continues
	/// from there.
	[Test]
	public static void ACloseReturnsThePenToTheSubPathStart()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(5, 5);
		builder.LineTo(9, 5);
		builder.Close();
		builder.LineTo(9, 9);

		let path = builder.ToPath();
		defer delete path;

		var iterator = path.GetIterator();
		PathSegment last = .();
		while (iterator.GetNext(let segment))
			last = segment;

		Test.Assert(last.Command == .LineTo);
		Test.Assert(NearPoint(last.StartPoint, .(5, 5)), "back where the subpath began");
	}
}
