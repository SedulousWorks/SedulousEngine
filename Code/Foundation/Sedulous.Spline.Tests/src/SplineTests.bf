using System;
using Sedulous.Core;
using Sedulous.Spline;

namespace Sedulous.Spline.Tests;

/// The authorable spline. The parts worth pinning down are the ones an author would
/// notice: that the curve passes through its points, that a closed loop actually closes,
/// and that distance queries are evenly spaced where raw parameter queries are not.
class SplineTests
{
	private static bool Near(float a, float b, float tolerance = 0.001f) => Abs(a - b) <= tolerance;
	private static bool Near(Float3 a, Float3 b, float tolerance = 0.001f)
		=> Sedulous.Core.Length(a - b) <= tolerance;

	private static SplineCurve Line()
	{
		let curve = new SplineCurve();
		curve.Points.Add(.(.(0, 0, 0)));
		curve.Points.Add(.(.(1, 0, 0)));
		curve.Points.Add(.(.(2, 0, 0)));
		curve.UpdateAutoHandles();
		return curve;
	}

	[Test]
	public static void SegmentCountFollowsOpenOrClosed()
	{
		let curve = scope SplineCurve();
		Test.Assert(curve.SegmentCount == 0, "no points, no segments");

		curve.Points.Add(.(.(0, 0, 0)));
		Test.Assert(curve.SegmentCount == 0, "one point is not a curve");

		curve.Points.Add(.(.(1, 0, 0)));
		Test.Assert(curve.SegmentCount == 1);
		Test.Assert(curve.MaxT == 1.0f);

		curve.Points.Add(.(.(2, 0, 0)));
		Test.Assert(curve.SegmentCount == 2, "open: one fewer than the points");

		curve.Closed = true;
		Test.Assert(curve.SegmentCount == 3, "closed adds the wrap segment");
	}

	/// The curve passes THROUGH its authored points. That is the property an author is
	/// relying on when they drop a point where they want the path to go.
	[Test]
	public static void TheCurvePassesThroughItsPoints()
	{
		let curve = scope SplineCurve();
		curve.Points.Add(.(.(0, 0, 0)));
		curve.Points.Add(.(.(1, 2, 0)));
		curve.Points.Add(.(.(3, 1, 1)));
		curve.UpdateAutoHandles();

		Test.Assert(Near(curve.Evaluate(0.0f), .(0, 0, 0)));
		Test.Assert(Near(curve.Evaluate(1.0f), .(1, 2, 0)), "the interior point is hit exactly");
		Test.Assert(Near(curve.Evaluate(2.0f), .(3, 1, 1)));
	}

	/// Auto handles follow the Catmull-Rom rule: a sixth of the chord between the
	/// neighbours. An open endpoint has only one neighbour, so its outward handle is the
	/// chord and the other side is zero.
	[Test]
	public static void AutoHandlesFollowTheNeighbourChord()
	{
		let curve = Line();
		defer delete curve;

		// The middle point's neighbours are 2 apart along X, so each handle is 1/3 of X.
		Test.Assert(Near(curve.Points[1].OutHandle, .(2.0f / 6.0f, 0, 0)));
		Test.Assert(Near(curve.Points[1].InHandle, .(-2.0f / 6.0f, 0, 0)), "the in handle points back");

		// The open ends have nothing on one side.
		Test.Assert(Near(curve.Points[0].InHandle, .(0, 0, 0)), "no previous neighbour");
		Test.Assert(Near(curve.Points[2].OutHandle, .(0, 0, 0)), "no next neighbour");
	}

	/// Only Auto points are recomputed. An authored handle survives an edit elsewhere,
	/// which is the whole reason the mode exists.
	[Test]
	public static void AuthoredHandlesSurviveAnUpdate()
	{
		let curve = scope SplineCurve();
		curve.Points.Add(.(.(0, 0, 0)));
		curve.Points.Add(.(.(1, 0, 0), .Broken));
		curve.Points.Add(.(.(2, 0, 0)));

		curve.Points[1].InHandle = .(0, 5, 0);
		curve.Points[1].OutHandle = .(0, -5, 0);
		curve.UpdateAutoHandles();

		Test.Assert(Near(curve.Points[1].InHandle, .(0, 5, 0)), "a Broken handle is left alone");
		Test.Assert(Near(curve.Points[1].OutHandle, .(0, -5, 0)));
		Test.Assert(!Near(curve.Points[0].OutHandle, .(0, 0, 0)), "and the Auto ones were resolved");
	}

	/// A closed curve wraps: the parameter runs past the last point and back to the first.
	[Test]
	public static void AClosedCurveWrapsRatherThanClamping()
	{
		let curve = scope SplineCurve();
		curve.Points.Add(.(.(0, 0, 0)));
		curve.Points.Add(.(.(1, 0, 0)));
		curve.Points.Add(.(.(1, 1, 0)));
		curve.Closed = true;
		curve.UpdateAutoHandles();

		Test.Assert(Near(curve.Evaluate(3.0f), curve.Evaluate(0.0f)), "one full lap returns to the start");
		Test.Assert(Near(curve.Evaluate(4.0f), curve.Evaluate(1.0f)));
		Test.Assert(Near(curve.Evaluate(-1.0f), curve.Evaluate(2.0f)), "and it wraps backwards too");
	}

	/// An open curve clamps instead. Past the end is the end, not a wrap to the start,
	/// which would teleport whatever is following the path.
	[Test]
	public static void AnOpenCurveClampsAtItsEnds()
	{
		let curve = Line();
		defer delete curve;

		Test.Assert(Near(curve.Evaluate(-5.0f), .(0, 0, 0)));
		Test.Assert(Near(curve.Evaluate(99.0f), .(2, 0, 0)));
	}

	[Test]
	public static void TheTangentIsUnitLength()
	{
		let curve = scope SplineCurve();
		curve.Points.Add(.(.(0, 0, 0)));
		curve.Points.Add(.(.(1, 2, 0)));
		curve.Points.Add(.(.(3, 1, 1)));
		curve.UpdateAutoHandles();

		for (int i <= 20)
		{
			let t = curve.MaxT * (float)i / 20.0f;
			let tangent = curve.Tangent(t);
			Test.Assert(Near(LengthSquared(tangent), 1.0f), scope $"at t={t} the tangent was {LengthSquared(tangent)}");
		}
	}

	/// A knot whose handles are both zero has no derivative exactly at the point, but the
	/// curve either side of it still has a direction. Reporting no tangent there would
	/// make anything orienting along the path snap to identity for one frame.
	[Test]
	public static void AZeroHandleKnotStillHasADirection()
	{
		let curve = scope SplineCurve();
		curve.Points.Add(.(.(0, 0, 0), .Broken));
		curve.Points.Add(.(.(1, 0, 0), .Broken));
		// Handles left at zero, so the segment is a straight line with a degenerate
		// derivative at each end.

		let atStart = curve.Tangent(0.0f);
		Test.Assert(Near(LengthSquared(atStart), 1.0f), "nudged off the knot rather than giving up");
		Test.Assert(atStart.X > 0.9f, "and it points along the segment");
	}

	/// A curve with nothing to interpolate answers its single point rather than reading
	/// past the list.
	[Test]
	public static void ADegenerateCurveIsHarmless()
	{
		let empty = scope SplineCurve();
		Test.Assert(Near(empty.Evaluate(0.5f), .(0, 0, 0)));
		Test.Assert(Near(empty.Tangent(0.5f), .(0, 0, 0)));
		Test.Assert(empty.Length == 0.0f);
		Test.Assert(empty.DistanceToT(10.0f) == 0.0f);
		Test.Assert(Near(empty.ClosestPoint(.(5, 5, 5)).Position, .(0, 0, 0)));

		let single = scope SplineCurve();
		single.Points.Add(.(.(7, 8, 9)));
		single.RebuildArcLength();
		Test.Assert(Near(single.Evaluate(0.5f), .(7, 8, 9)));
		Test.Assert(Near(single.ClosestPoint(.(0, 0, 0)).Position, .(7, 8, 9)));
	}

	/// A straight line's arc length is its chord. Anything else means the table is being
	/// built over the wrong parameter range.
	[Test]
	public static void AStraightLineMeasuresItsChord()
	{
		let curve = Line();
		defer delete curve;

		Test.Assert(curve.Length == 0.0f, "nothing is measured until the table is built");
		curve.RebuildArcLength();
		Test.Assert(Near(curve.Length, 2.0f, 0.01f), scope $"got {curve.Length}");
	}

	/// Distance queries are evenly spaced where parameter queries are not. That is what
	/// the table is for: placing fence posts every two metres along a path.
	///
	/// Measured on a POLYLINE, with the handles held at zero, so the curve is exactly its
	/// chords and any error is the arc length machinery's own rather than the difference
	/// between a chord and the arc it subtends.
	[Test]
	public static void DistanceQueriesAreEvenlySpaced()
	{
		let curve = scope SplineCurve();
		// A short segment and a very long one, so parameter space and distance space
		// disagree loudly.
		curve.Points.Add(.(.(0, 0, 0), .Broken));
		curve.Points.Add(.(.(1, 0, 0), .Broken));
		curve.Points.Add(.(.(11, 0, 0), .Broken));
		curve.RebuildArcLength();

		Test.Assert(Near(curve.Length, 11.0f, 0.01f), scope $"the polyline is 11 long, got {curve.Length}");

		let step = curve.Length / 10.0f;
		var previous = curve.EvaluateAtDistance(0.0f);
		for (int i = 1; i <= 10; i++)
		{
			let position = curve.EvaluateAtDistance(step * (float)i);
			let travelled = Sedulous.Core.Length(position - previous);
			Test.Assert(Near(travelled, step, step * 0.05f),
				scope $"step {i} moved {travelled}, expected about {step}");
			previous = position;
		}

		// Parameter space, by contrast, is lumpy: half the PARAMETER is one unit along,
		// because it is the midpoint of a segment that covers a tenth of the curve.
		Test.Assert(Near(curve.Evaluate(1.0f), .(1, 0, 0)), "half the parameter is barely started");
		Test.Assert(Near(curve.EvaluateAtDistance(curve.Length * 0.5f), .(5.5f, 0, 0), 0.05f),
			"half the distance is genuinely halfway");
	}

	/// And on a genuinely curved path, where a chord understates the arc it subtends, the
	/// spacing is still even to within the resolution of the table.
	[Test]
	public static void DistanceQueriesAreEvenlySpacedOnACurve()
	{
		let curve = scope SplineCurve();
		curve.Points.Add(.(.(0, 0, 0)));
		curve.Points.Add(.(.(2, 1, 0)));
		curve.Points.Add(.(.(5, 1, 0)));
		curve.Points.Add(.(.(7, 0, 0)));
		curve.UpdateAutoHandles();
		curve.RebuildArcLength();

		let step = curve.Length / 12.0f;
		var previous = curve.EvaluateAtDistance(0.0f);
		for (int i = 1; i <= 12; i++)
		{
			let position = curve.EvaluateAtDistance(step * (float)i);
			let travelled = Sedulous.Core.Length(position - previous);
			Test.Assert(Near(travelled, step, step * 0.12f),
				scope $"step {i} moved {travelled}, expected about {step}");
			previous = position;
		}
	}

	[Test]
	public static void DistanceQueriesClampToTheEnds()
	{
		let curve = Line();
		defer delete curve;
		curve.RebuildArcLength();

		Test.Assert(Near(curve.EvaluateAtDistance(-10.0f), .(0, 0, 0)));
		Test.Assert(Near(curve.EvaluateAtDistance(curve.Length + 10.0f), .(2, 0, 0)));
	}

	/// The tangent at the very end of an OPEN curve belongs to the last segment, not to the
	/// wrap segment that does not exist. Unit length alone does not catch this: the wrong
	/// segment still yields a unit vector, just one pointing somewhere else entirely.
	[Test]
	public static void TheTangentAtTheEndBelongsToTheLastSegment()
	{
		let curve = Line();
		defer delete curve;

		let atEnd = curve.Tangent(curve.MaxT);
		Test.Assert(Near(LengthSquared(atEnd), 1.0f));
		Test.Assert(atEnd.X > 0.9f, scope $"expected to still run along +X, got {atEnd.X},{atEnd.Y},{atEnd.Z}");

		// And it agrees with the tangent just before the end, rather than jumping.
		let justBefore = curve.Tangent(curve.MaxT - 0.01f);
		Test.Assert(Near(atEnd, justBefore, 0.05f), "no discontinuity at the last point");
	}

	/// The parameter a distance maps to stays inside the curve, which callers reading
	/// DistanceToT directly depend on: they index segments with it.
	[Test]
	public static void DistanceToTStaysInsideTheCurve()
	{
		let curve = Line();
		defer delete curve;
		curve.RebuildArcLength();

		Test.Assert(curve.DistanceToT(-100.0f) >= 0.0f, "before the start clamps to the start");
		Test.Assert(curve.DistanceToT(-100.0f) <= curve.MaxT);

		let past = curve.DistanceToT(curve.Length * 10.0f);
		Test.Assert(past <= curve.MaxT, scope $"past the end gave t={past}, MaxT is {curve.MaxT}");
		Test.Assert(Near(past, curve.MaxT, 0.05f), "and it clamps to the far end, not somewhere arbitrary");

		// The ends map to the ends.
		Test.Assert(Near(curve.DistanceToT(0.0f), 0.0f, 0.01f));
		Test.Assert(Near(curve.DistanceToT(curve.Length), curve.MaxT, 0.05f));
	}

	[Test]
	public static void ClosestPointFindsTheNearestPositionOnTheCurve()
	{
		let curve = Line();
		defer delete curve;
		curve.RebuildArcLength();

		// Directly above the middle of the line.
		let sample = curve.ClosestPoint(.(1.0f, 5.0f, 0.0f));
		Test.Assert(Near(sample.Position, .(1, 0, 0), 0.02f), scope $"got {sample.Position.X},{sample.Position.Y},{sample.Position.Z}");
		Test.Assert(Near(sample.T, 1.0f, 0.05f), scope $"got t={sample.T}");

		// Past the end: the closest point is the end itself.
		let beyond = curve.ClosestPoint(.(50.0f, 0.0f, 0.0f));
		Test.Assert(Near(beyond.Position, .(2, 0, 0), 0.02f));

		// And a point already on the curve comes back as itself.
		let on = curve.ClosestPoint(.(0.5f, 0, 0));
		Test.Assert(Near(on.Position, .(0.5f, 0, 0), 0.02f));
	}

	/// The reported parameter and position agree with each other. A sample whose t does
	/// not evaluate back to its own position would send anything following the curve to a
	/// different place than it was told.
	[Test]
	public static void AClosestPointSampleIsSelfConsistent()
	{
		let curve = scope SplineCurve();
		curve.Points.Add(.(.(0, 0, 0)));
		curve.Points.Add(.(.(2, 3, 0)));
		curve.Points.Add(.(.(5, 0, 1)));
		curve.UpdateAutoHandles();
		curve.RebuildArcLength();

		for (let target in Float3[4](.(1, 1, 0), .(4, -2, 0), .(0, 5, 5), .(3, 0, 2)))
		{
			let sample = curve.ClosestPoint(target);
			Test.Assert(Near(sample.Position, curve.Evaluate(sample.T), 0.01f),
				"the sample's parameter evaluates back to its own position");
		}
	}

	/// Rebuilding after an edit picks up the change, rather than answering from the table
	/// the previous shape left behind.
	[Test]
	public static void RebuildingPicksUpAnEdit()
	{
		let curve = Line();
		defer delete curve;
		curve.RebuildArcLength();
		let before = curve.Length;

		curve.Points[2].Position = .(10, 0, 0);
		curve.UpdateAutoHandles();
		Test.Assert(curve.Length == before, "the stored table has not been told yet");

		curve.RebuildArcLength();
		Test.Assert(curve.Length > before + 5.0f, scope $"got {curve.Length} after the edit");
	}

	/// A TWO point auto curve has no second neighbour to bend toward, so it has to come out
	/// as the exact straight segment.
	///
	/// This is the degenerate case for auto handles: with one neighbour there is nothing to
	/// average, and a handle scaled from a chord that is not there either bows the line or
	/// collapses it to a point. The three point fixture above cannot catch that, because its
	/// middle knot always has two neighbours.
	[Test]
	public static void ATwoPointAutoCurveIsTheStraightSegment()
	{
		let curve = scope SplineCurve();
		curve.Points.Add(.(.(0, 0, 0)));
		curve.Points.Add(.(.(10, 0, 0)));
		curve.UpdateAutoHandles();
		curve.RebuildArcLength();

		Test.Assert(Near(curve.Evaluate(0.5f), .(5, 0, 0)), "the midpoint is the midpoint");
		Test.Assert(Near(curve.Tangent(0.5f), .(1, 0, 0)), "pointing straight down the line");
		Test.Assert(Near(curve.Length, 10.0f, 0.01f), scope $"got {curve.Length}");
		Test.Assert(Near(curve.EvaluateAtDistance(2.5f), .(2.5f, 0, 0), 0.01f),
			"distance along a straight segment is linear");
	}
}
