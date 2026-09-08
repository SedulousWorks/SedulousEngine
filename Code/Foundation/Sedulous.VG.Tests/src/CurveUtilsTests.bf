using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.VG.Tests;

/// Bezier evaluation, measurement, and flattening.
class CurveUtilsTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;
	private static bool NearPoint(Float2 a, Float2 b, float epsilon = 0.001f)
		=> Near(a.X, b.X, epsilon) && Near(a.Y, b.Y, epsilon);

	[Test]
	public static void ACurvePassesThroughItsEndpoints()
	{
		let p0 = Float2(0, 0);
		let p1 = Float2(1, 2);
		let p2 = Float2(3, 0);
		let p3 = Float2(4, 2);

		Test.Assert(NearPoint(CurveUtils.QuadraticPointAt(p0, p1, p2, 0.0f), p0));
		Test.Assert(NearPoint(CurveUtils.QuadraticPointAt(p0, p1, p2, 1.0f), p2));
		Test.Assert(NearPoint(CurveUtils.CubicPointAt(p0, p1, p2, p3, 0.0f), p0));
		Test.Assert(NearPoint(CurveUtils.CubicPointAt(p0, p1, p2, p3, 1.0f), p3));
	}

	/// A curve whose control points are collinear IS the line, which is the case the
	/// flattener has to recognise immediately.
	[Test]
	public static void ACollinearCurveIsItsChord()
	{
		let p0 = Float2(0, 0);
		let p3 = Float2(6, 0);

		Test.Assert(NearPoint(CurveUtils.QuadraticPointAt(p0, .(3, 0), p3, 0.5f), .(3, 0)));
		Test.Assert(NearPoint(CurveUtils.CubicPointAt(p0, .(2, 0), .(4, 0), p3, 0.5f), .(3, 0)));
	}

	[Test]
	public static void ATangentIsNormalisedAndPointsAlongTheCurve()
	{
		let tangent = CurveUtils.CubicTangentAt(.(0, 0), .(1, 0), .(2, 0), .(3, 0), 0.5f);
		Test.Assert(Near(Length(tangent), 1.0f), "normalised");
		Test.Assert(NearPoint(tangent, .(1, 0)));

		let vertical = CurveUtils.QuadraticTangentAt(.(0, 0), .(0, 1), .(0, 2), 0.5f);
		Test.Assert(NearPoint(vertical, .(0, 1)));
	}

	/// A degenerate curve has no direction, so it answers along positive X rather than a
	/// zero vector a caller would go on to divide by.
	[Test]
	public static void ADegenerateCurveHasAFallbackTangent()
	{
		let point = Float2(5, 5);
		Test.Assert(CurveUtils.QuadraticTangentAt(point, point, point, 0.5f) == Float2(1, 0));
		Test.Assert(CurveUtils.CubicTangentAt(point, point, point, point, 0.5f) == Float2(1, 0));
	}

	/// A straight curve's length is its chord, exactly. A bent one is longer than its
	/// chord and no longer than its control polygon, which brackets the approximation.
	[Test]
	public static void LengthIsTheChordWhenStraightAndBracketedWhenNot()
	{
		Test.Assert(Near(CurveUtils.CubicLength(.(0, 0), .(1, 0), .(2, 0), .(3, 0)), 3.0f));
		Test.Assert(Near(CurveUtils.QuadraticLength(.(0, 0), .(1, 0), .(2, 0)), 2.0f));

		let p0 = Float2(0, 0);
		let p1 = Float2(0, 4);
		let p2 = Float2(4, 4);
		let bent = CurveUtils.QuadraticLength(p0, p1, p2);
		Test.Assert(bent > Distance(p0, p2), "longer than the chord");
		Test.Assert(bent < (Distance(p0, p1) + Distance(p1, p2)), "shorter than the controls");
	}

	/// More steps can only get closer to the true length, never further.
	[Test]
	public static void MoreStepsMeasureAtLeastAsMuch()
	{
		let coarse = CurveUtils.CubicLength(.(0, 0), .(0, 10), .(10, 10), .(10, 0), 4);
		let fine = CurveUtils.CubicLength(.(0, 0), .(0, 10), .(10, 10), .(10, 0), 64);
		Test.Assert(fine >= coarse, "a polyline inscribed in a curve only grows");
	}

	// ---- flattening ----

	[Test]
	public static void FlatteningStartsAndEndsOnTheCurve()
	{
		let points = scope List<Float2>();
		CurveUtils.FlattenCubic(.(0, 0), .(0, 10), .(10, 10), .(10, 0), 0.25f, points);

		Test.Assert(points.Count >= 2);
		Test.Assert(NearPoint(points[0], .(0, 0)));
		Test.Assert(NearPoint(points[points.Count - 1], .(10, 0)), "the end is appended");
	}

	/// A tighter tolerance means more segments. That is the whole contract of adaptive
	/// flattening: the caller buys accuracy with vertices.
	[Test]
	public static void ATighterToleranceProducesMoreSegments()
	{
		let coarse = scope List<Float2>();
		CurveUtils.FlattenCubic(.(0, 0), .(0, 10), .(10, 10), .(10, 0), 2.0f, coarse);

		let fine = scope List<Float2>();
		CurveUtils.FlattenCubic(.(0, 0), .(0, 10), .(10, 10), .(10, 0), 0.05f, fine);

		Test.Assert(fine.Count > coarse.Count);
	}

	/// A curve that is already flat needs no subdivision at all.
	[Test]
	public static void AFlatCurveIsTwoPoints()
	{
		let points = scope List<Float2>();
		CurveUtils.FlattenQuadratic(.(0, 0), .(5, 0), .(10, 0), 0.25f, points);
		Test.Assert(points.Count == 2, "the start and the end, nothing between");
	}

	/// A cubic whose control points bulge OPPOSITE ways is not flat, even though the
	/// midpoint sits on the chord. Checking one control point would accept it.
	[Test]
	public static void AnSBendIsNotMistakenForFlat()
	{
		let points = scope List<Float2>();
		CurveUtils.FlattenCubic(.(0, 0), .(3, 5), .(7, -5), .(10, 0), 0.25f, points);
		Test.Assert(points.Count > 2, "both control points are measured against the chord");
	}

	/// A cusp never becomes flat, so the depth bound is what stops it. Without one this
	/// runs until the stack does.
	[Test]
	public static void ACuspTerminatesOnTheDepthBound()
	{
		let points = scope List<Float2>();
		CurveUtils.FlattenCubic(.(0, 0), .(10, 10), .(0, 10), .(10, 0), 0.0001f, points);
		Test.Assert(points.Count > 2);
		Test.Assert(points.Count < 200000, "bounded rather than subdividing forever");
	}

	// ---- arcs ----

	/// Each cubic is three points: two controls and an end.
	[Test]
	public static void AnArcConvertsToWholeCubics()
	{
		let points = scope List<Float2>();
		CurveUtils.ArcToCubics(.(0, 0), 10, 10, 0, false, true, .(10, 10), points);

		Test.Assert(!points.IsEmpty);
		Test.Assert((points.Count % 3) == 0, "whole cubics only");
		Test.Assert(NearPoint(points[points.Count - 1], .(10, 10), 0.01f), "ends where asked");
	}

	/// A large arc sweeps the long way round, so it needs more segments than the short one
	/// between the same endpoints.
	[Test]
	public static void TheLargeArcFlagTakesTheLongWayRound()
	{
		let small = scope List<Float2>();
		CurveUtils.ArcToCubics(.(0, 0), 10, 10, 0, false, true, .(10, 10), small);

		let large = scope List<Float2>();
		CurveUtils.ArcToCubics(.(0, 0), 10, 10, 0, true, true, .(10, 10), large);

		Test.Assert(large.Count > small.Count);
		Test.Assert(NearPoint(large[large.Count - 1], .(10, 10), 0.01f));
	}

	/// The sweep flag picks the other side, so the two curves bow opposite ways between
	/// the same endpoints.
	[Test]
	public static void TheSweepFlagPicksTheOtherSide()
	{
		let clockwise = scope List<Float2>();
		CurveUtils.ArcToCubics(.(0, 0), 10, 10, 0, false, true, .(10, 10), clockwise);

		let counter = scope List<Float2>();
		CurveUtils.ArcToCubics(.(0, 0), 10, 10, 0, false, false, .(10, 10), counter);

		Test.Assert(!NearPoint(clockwise[0], counter[0]), "bowed the other way");
	}

	/// An arc to where the pen already is has nothing to draw.
	[Test]
	public static void ADegenerateArcEmitsNothing()
	{
		let points = scope List<Float2>();
		CurveUtils.ArcToCubics(.(5, 5), 10, 10, 0, false, true, .(5, 5), points);
		Test.Assert(points.IsEmpty);
	}

	/// A zero radius is a straight LINE by the specification, not an error.
	[Test]
	public static void AZeroRadiusArcIsALine()
	{
		let points = scope List<Float2>();
		CurveUtils.ArcToCubics(.(0, 0), 0, 10, 0, false, true, .(10, 0), points);

		Test.Assert(points.Count == 3);
		Test.Assert(NearPoint(points[points.Count - 1], .(10, 0)));
	}

	/// Radii too small to span the endpoints are SCALED UP until they just reach, rather
	/// than the arc being refused.
	[Test]
	public static void TooSmallRadiiAreScaledUpToReach()
	{
		let points = scope List<Float2>();
		// A radius of one cannot span twenty units.
		CurveUtils.ArcToCubics(.(0, 0), 1, 1, 0, false, true, .(20, 0), points);

		Test.Assert(!points.IsEmpty);
		Test.Assert(NearPoint(points[points.Count - 1], .(20, 0), 0.01f),
			"it still lands on the endpoint");
	}
}
