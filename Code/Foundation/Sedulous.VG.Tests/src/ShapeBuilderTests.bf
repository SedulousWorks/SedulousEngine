using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.VG.Tests;

/// The common shapes, and the clamping that keeps a rounded rectangle from folding through
/// itself.
class ShapeBuilderTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

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

	private static Path Build(delegate void(PathBuilder) build)
	{
		let builder = scope PathBuilder();
		build(builder);
		return builder.ToPath();
	}

	[Test]
	public static void ARoundedRectHasFourCornerArcs()
	{
		let path = Build(scope (b) =>
			ShapeBuilder.BuildRoundedRect(.(0, 0, 100, 50), .(10.0f), b));
		defer delete path;

		Test.Assert(CountOf(path, .CubicTo) == 4, "one per corner");
		Test.Assert(CountOf(path, .LineTo) == 4, "one per edge");
		Test.Assert(CountOf(path, .Close) == 1);
	}

	/// A zero radius corner is a plain corner: no arc is emitted for it at all.
	[Test]
	public static void ZeroRadiusCornersEmitNoArcs()
	{
		let square = Build(scope (b) =>
			ShapeBuilder.BuildRoundedRect(.(0, 0, 100, 50), .(0.0f), b));
		defer delete square;
		Test.Assert(CountOf(square, .CubicTo) == 0);

		let mixed = Build(scope (b) =>
			ShapeBuilder.BuildRoundedRect(.(0, 0, 100, 50), .(10, 0, 10, 0), b));
		defer delete mixed;
		Test.Assert(CountOf(mixed, .CubicTo) == 2, "only the rounded corners");
	}

	/// A radius larger than half the smaller side is CLAMPED. Two radii that together
	/// exceed a side would otherwise cross, folding the shape through itself.
	[Test]
	public static void AnOversizedRadiusIsClampedToTheShape()
	{
		let path = Build(scope (b) =>
			ShapeBuilder.BuildRoundedRect(.(0, 0, 100, 20), .(999.0f), b));
		defer delete path;

		let bounds = path.GetBounds();
		Test.Assert(Near(bounds.X, 0.0f) && Near(bounds.Y, 0.0f));
		Test.Assert(bounds.Width <= 100.01f, "no control point escapes the rectangle");
		Test.Assert(bounds.Height <= 20.01f);
		Test.Assert(CountOf(path, .CubicTo) == 4);
	}

	[Test]
	public static void ACircleIsFourCubics()
	{
		let path = Build(scope (b) => ShapeBuilder.BuildCircle(.(50, 50), 25, b));
		defer delete path;

		Test.Assert(CountOf(path, .MoveTo) == 1);
		Test.Assert(CountOf(path, .CubicTo) == 4, "one per quadrant");
		Test.Assert(CountOf(path, .Close) == 1);

		let bounds = path.GetBounds();
		Test.Assert(Near(bounds.Width, 50.0f) && Near(bounds.Height, 50.0f));
	}

	/// The circle actually passes through its quadrant points, which is what the control
	/// offset is chosen for.
	[Test]
	public static void ACirclePassesThroughItsQuadrants()
	{
		let path = Build(scope (b) => ShapeBuilder.BuildCircle(.(0, 0), 10, b));
		defer delete path;

		Test.Assert(path.Contains(.(0, 0), .NonZero), "the centre is inside");
		Test.Assert(path.Contains(.(9, 0), .NonZero));
		Test.Assert(!path.Contains(.(11, 0), .NonZero));
		// The corner of the bounding box is outside a circle, which a square would fail.
		Test.Assert(!path.Contains(.(9.5f, 9.5f), .NonZero));
	}

	[Test]
	public static void AnEllipseIsFourCubicsOfDifferentRadii()
	{
		let path = Build(scope (b) => ShapeBuilder.BuildEllipse(.(0, 0), 30, 10, b));
		defer delete path;

		Test.Assert(CountOf(path, .CubicTo) == 4);
		let bounds = path.GetBounds();
		Test.Assert(Near(bounds.Width, 60.0f));
		Test.Assert(Near(bounds.Height, 20.0f));
	}

	/// A polygon of N sides is one move and N minus one lines: the last edge is the Close.
	[Test]
	public static void APolygonClosesItsLastEdgeImplicitly()
	{
		let hexagon = Build(scope (b) => ShapeBuilder.BuildRegularPolygon(.(0, 0), 10, 6, b));
		defer delete hexagon;

		Test.Assert(CountOf(hexagon, .MoveTo) == 1);
		Test.Assert(CountOf(hexagon, .LineTo) == 5);
		Test.Assert(CountOf(hexagon, .Close) == 1);

		let triangle = Build(scope (b) => ShapeBuilder.BuildRegularPolygon(.(0, 0), 10, 3, b));
		defer delete triangle;
		Test.Assert(CountOf(triangle, .LineTo) == 2);
	}

	/// It starts at the TOP, so an even sided polygon rests on a flat side.
	[Test]
	public static void APolygonStartsAtTheTop()
	{
		let path = Build(scope (b) => ShapeBuilder.BuildRegularPolygon(.(0, 0), 10, 6, b));
		defer delete path;

		Test.Assert(Near(path.Points[0].X, 0.0f));
		Test.Assert(Near(path.Points[0].Y, -10.0f), "straight up from the centre");
	}

	/// Fewer than three sides is not a polygon, and emits nothing rather than a degenerate
	/// shape the tessellator would have to reject later.
	[Test]
	public static void ADegeneratePolygonEmitsNothing()
	{
		for (let sides in scope int32[](2, 1, 0, -1))
		{
			let path = Build(scope [&] (b) => ShapeBuilder.BuildRegularPolygon(.(0, 0), 10, sides, b));
			defer delete path;
			Test.Assert(path.CommandCount == 0);
		}
	}

	/// A star has twice as many vertices as points, alternating between the two radii.
	[Test]
	public static void AStarAlternatesItsTwoRadii()
	{
		let path = Build(scope (b) => ShapeBuilder.BuildStar(.(0, 0), 10, 4, 5, b));
		defer delete path;

		Test.Assert(CountOf(path, .MoveTo) == 1);
		Test.Assert(CountOf(path, .LineTo) == 9, "ten vertices, the last closed");

		// Even indices sit on the outer radius, odd ones on the inner.
		for (int i = 0; i < path.PointCount; i++)
		{
			let radius = Length(path.Points[i]);
			Test.Assert(Near(radius, ((i % 2) == 0) ? 10.0f : 4.0f));
		}
	}

	[Test]
	public static void ADegenerateStarEmitsNothing()
	{
		let path = Build(scope (b) => ShapeBuilder.BuildStar(.(0, 0), 10, 4, 2, b));
		defer delete path;
		Test.Assert(path.CommandCount == 0);
	}
}
