using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.VG.Tests;

/// Reducing a path to polylines, and the deduplication that keeps degenerate edges out of
/// the tessellators.
class PathFlattenerTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	private static void Flatten(Path path, List<FlattenedSubPath> output, float tolerance = 0.25f)
		=> PathFlattener.Flatten(path, tolerance, output);

	[Test]
	public static void EachMoveStartsANewSubPath()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);
		builder.MoveTo(0, 10);
		builder.LineTo(10, 10);
		let path = builder.ToPath();
		defer delete path;

		let subPaths = scope List<FlattenedSubPath>();
		defer { ClearAndDeleteItems!(subPaths); }
		Flatten(path, subPaths);

		Test.Assert(subPaths.Count == 2);
		Test.Assert(subPaths[0].Points.Count == 2);
		Test.Assert(subPaths[1].Points.Count == 2);
		Test.Assert(!subPaths[0].IsClosed);
	}

	[Test]
	public static void AClosedPathIsMarkedClosed()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);
		builder.LineTo(10, 10);
		builder.Close();
		let path = builder.ToPath();
		defer delete path;

		let subPaths = scope List<FlattenedSubPath>();
		defer { ClearAndDeleteItems!(subPaths); }
		Flatten(path, subPaths);

		Test.Assert(subPaths.Count == 1);
		Test.Assert(subPaths[0].IsClosed);
		// The closing edge is implied rather than stored, so the first point is not
		// repeated at the end.
		Test.Assert(subPaths[0].Points.Count == 3);
	}

	/// A path that draws back to where it started AND closes must not keep the repeat: a
	/// zero length closing edge has no normal, and a stroke built on one gets a spike.
	[Test]
	public static void AnExplicitReturnToTheStartIsNotRepeated()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);
		builder.LineTo(10, 10);
		builder.LineTo(0, 0);
		builder.Close();
		let path = builder.ToPath();
		defer delete path;

		let subPaths = scope List<FlattenedSubPath>();
		defer { ClearAndDeleteItems!(subPaths); }
		Flatten(path, subPaths);

		Test.Assert(subPaths[0].Points.Count == 3, "the duplicate closing point is dropped");
	}

	/// Repeated identical points are dropped, whatever produced them.
	[Test]
	public static void CoincidentPointsAreDropped()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);
		builder.LineTo(10, 0);
		builder.LineTo(10, 0);
		builder.LineTo(10, 10);
		let path = builder.ToPath();
		defer delete path;

		let subPaths = scope List<FlattenedSubPath>();
		defer { ClearAndDeleteItems!(subPaths); }
		Flatten(path, subPaths);

		Test.Assert(subPaths[0].Points.Count == 3);
	}

	/// Flattening a curve appends the start of each span, so the point where the previous
	/// segment ended repeats. The deduplication is what removes it.
	[Test]
	public static void ACurveDoesNotRepeatTheSeamPoint()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);
		builder.CubicTo(15, 0, 20, 5, 20, 10);
		let path = builder.ToPath();
		defer delete path;

		let subPaths = scope List<FlattenedSubPath>();
		defer { ClearAndDeleteItems!(subPaths); }
		Flatten(path, subPaths);

		let points = subPaths[0].Points;
		for (int i = 1; i < points.Count; i++)
			Test.Assert(Distance(points[i], points[i - 1]) > 0.005f, "no zero length edge");
	}

	/// A tighter tolerance buys more points, which is the contract the tessellator passes
	/// through from its caller.
	[Test]
	public static void ATighterToleranceProducesMorePoints()
	{
		let builder = scope PathBuilder();
		ShapeBuilder.BuildCircle(.(0, 0), 100, builder);
		let path = builder.ToPath();
		defer delete path;

		let coarse = scope List<FlattenedSubPath>();
		defer { ClearAndDeleteItems!(coarse); }
		Flatten(path, coarse, 4.0f);

		let fine = scope List<FlattenedSubPath>();
		defer { ClearAndDeleteItems!(fine); }
		Flatten(path, fine, 0.05f);

		Test.Assert(fine[0].Points.Count > coarse[0].Points.Count);
	}

	/// A flattened circle stays on the circle: every point is at the radius, which is the
	/// end to end check that the shape, the curve math and the flattener all agree.
	[Test]
	public static void AFlattenedCircleStaysOnTheCircle()
	{
		let builder = scope PathBuilder();
		ShapeBuilder.BuildCircle(.(0, 0), 50, builder);
		let path = builder.ToPath();
		defer delete path;

		let subPaths = scope List<FlattenedSubPath>();
		defer { ClearAndDeleteItems!(subPaths); }
		Flatten(path, subPaths, 0.1f);

		Test.Assert(subPaths[0].IsClosed);
		for (let point in subPaths[0].Points)
			Test.Assert(Near(Length(point), 50.0f, 0.5f));
	}

	/// A path with no move at all flattens to nothing rather than faulting on a null
	/// subpath.
	[Test]
	public static void AnEmptyPathFlattensToNothing()
	{
		let path = scope Path();
		let subPaths = scope List<FlattenedSubPath>();
		defer { ClearAndDeleteItems!(subPaths); }
		Flatten(path, subPaths);
		Test.Assert(subPaths.IsEmpty);
	}
}
