namespace Sedulous.VG.Tests;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.VG;

class CurveUtilsTests
{
	[Test]
	public static void FlattenQuadratic_StraightLine_FewPoints()
	{
		let output = scope List<Vector2>();
		// A "curve" that's actually a straight line (control point on the line)
		CurveUtils.FlattenQuadratic(.(0, 0), .(5, 0), .(10, 0), 0.25f, output);
		// Should produce very few points for a straight line
		Test.Assert(output.Count >= 2);
		Test.Assert(output.Count <= 4); // start + end + maybe a couple subdivisions
	}

	[Test]
	public static void FlattenCubic_CurvedLine_MultiplePoints()
	{
		let output = scope List<Vector2>();
		CurveUtils.FlattenCubic(.(0, 0), .(0, 10), .(10, 10), .(10, 0), 0.25f, output);
		// A curved line should produce many points
		Test.Assert(output.Count > 4);
	}

	[Test]
	public static void QuadraticPointAt_Endpoints()
	{
		let p0 = Vector2(0, 0);
		let p1 = Vector2(5, 10);
		let p2 = Vector2(10, 0);

		let start = CurveUtils.QuadraticPointAt(p0, p1, p2, 0.0f);
		let end = CurveUtils.QuadraticPointAt(p0, p1, p2, 1.0f);

		Test.Assert(Math.Abs(start.X - p0.X) < 0.001f);
		Test.Assert(Math.Abs(start.Y - p0.Y) < 0.001f);
		Test.Assert(Math.Abs(end.X - p2.X) < 0.001f);
		Test.Assert(Math.Abs(end.Y - p2.Y) < 0.001f);
	}

	[Test]
	public static void CubicPointAt_Endpoints()
	{
		let p0 = Vector2(0, 0);
		let p1 = Vector2(0, 10);
		let p2 = Vector2(10, 10);
		let p3 = Vector2(10, 0);

		let start = CurveUtils.CubicPointAt(p0, p1, p2, p3, 0.0f);
		let end = CurveUtils.CubicPointAt(p0, p1, p2, p3, 1.0f);

		Test.Assert(Math.Abs(start.X - p0.X) < 0.001f);
		Test.Assert(Math.Abs(start.Y - p0.Y) < 0.001f);
		Test.Assert(Math.Abs(end.X - p3.X) < 0.001f);
		Test.Assert(Math.Abs(end.Y - p3.Y) < 0.001f);
	}

	[Test]
	public static void ArcToCubics_QuarterCircle()
	{
		let controlPoints = scope List<Vector2>();
		CurveUtils.ArcToCubics(.(100, 0), 100, 100, 0, false, true, .(0, 100), controlPoints);

		// Should produce at least one cubic (3 points per cubic)
		Test.Assert(controlPoints.Count >= 3);
		Test.Assert(controlPoints.Count % 3 == 0);
	}

	[Test]
	public static void QuadraticLength_StraightLine()
	{
		// Straight line from (0,0) to (10,0) with midpoint on line
		let len = CurveUtils.QuadraticLength(.(0, 0), .(5, 0), .(10, 0));
		Test.Assert(Math.Abs(len - 10.0f) < 0.1f);
	}

	[Test]
	public static void CubicLength_StraightLine()
	{
		let len = CurveUtils.CubicLength(.(0, 0), .(3.33f, 0), .(6.66f, 0), .(10, 0));
		Test.Assert(Math.Abs(len - 10.0f) < 0.1f);
	}

	[Test]
	public static void QuadraticTangentAt_Endpoints()
	{
		let p0 = Vector2(0, 0);
		let p1 = Vector2(5, 0);
		let p2 = Vector2(10, 0);

		// For a straight horizontal line, tangent should be (1, 0)
		let tangent = CurveUtils.QuadraticTangentAt(p0, p1, p2, 0.5f);
		Test.Assert(Math.Abs(tangent.X - 1.0f) < 0.01f);
		Test.Assert(Math.Abs(tangent.Y) < 0.01f);
	}
}
