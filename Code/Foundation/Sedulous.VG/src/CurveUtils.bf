using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.VG;

/// Bezier math: evaluating curves, measuring them, flattening them to polylines, and
/// turning an SVG arc into cubics.
static class CurveUtils
{
	/// How deep adaptive subdivision may go before it gives up and accepts the segment.
	///
	/// A bound rather than a tolerance alone, because a cusp or a degenerate control
	/// polygon never reaches flat: without it a pathological curve subdivides until the
	/// stack runs out.
	private const int cMaxFlattenDepth = 16;

	/// Below this a length is treated as zero. Squared distances compare against its
	/// square where that is what is being measured.
	private const float cEpsilon = 0.0001f;

	// ---- evaluation ----

	public static Float2 QuadraticPointAt(Float2 p0, Float2 p1, Float2 p2, float t)
	{
		let mt = 1.0f - t;
		return (p0 * (mt * mt)) + (p1 * (2.0f * mt * t)) + (p2 * (t * t));
	}

	public static Float2 CubicPointAt(Float2 p0, Float2 p1, Float2 p2, Float2 p3, float t)
	{
		let mt = 1.0f - t;
		let mt2 = mt * mt;
		let t2 = t * t;
		return (p0 * (mt2 * mt)) + (p1 * (3.0f * mt2 * t)) + (p2 * (3.0f * mt * t2))
			+ (p3 * (t2 * t));
	}

	/// The NORMALISED direction of travel. A degenerate curve has no direction, so it
	/// answers along positive X rather than a zero vector a caller would go on to divide by.
	public static Float2 QuadraticTangentAt(Float2 p0, Float2 p1, Float2 p2, float t)
	{
		let mt = 1.0f - t;
		let tangent = ((p1 - p0) * (2.0f * mt)) + ((p2 - p1) * (2.0f * t));
		return Normalised(tangent);
	}

	public static Float2 CubicTangentAt(Float2 p0, Float2 p1, Float2 p2, Float2 p3, float t)
	{
		let mt = 1.0f - t;
		let mt2 = mt * mt;
		let t2 = t * t;
		let tangent = ((p1 - p0) * (3.0f * mt2)) + ((p2 - p1) * (6.0f * mt * t))
			+ ((p3 - p2) * (3.0f * t2));
		return Normalised(tangent);
	}

	private static Float2 Normalised(Float2 v)
	{
		let length = Length(v);
		if (length > cEpsilon)
			return v / length;
		return .(1.0f, 0.0f);
	}

	// ---- length ----

	/// The arc length, approximated by walking a fixed number of steps.
	///
	/// Fixed rather than adaptive because this measures rather than draws: a dash pattern
	/// and a point-at-distance query want a stable answer for the same curve, and an
	/// adaptive one changes with the tolerance in effect.
	public static float QuadraticLength(Float2 p0, Float2 p1, Float2 p2, int32 steps = 16)
	{
		var length = 0.0f;
		var previous = p0;
		for (int32 i = 1; i <= steps; i++)
		{
			let next = QuadraticPointAt(p0, p1, p2, (float)i / (float)steps);
			length += Distance(previous, next);
			previous = next;
		}
		return length;
	}

	public static float CubicLength(Float2 p0, Float2 p1, Float2 p2, Float2 p3, int32 steps = 16)
	{
		var length = 0.0f;
		var previous = p0;
		for (int32 i = 1; i <= steps; i++)
		{
			let next = CubicPointAt(p0, p1, p2, p3, (float)i / (float)steps);
			length += Distance(previous, next);
			previous = next;
		}
		return length;
	}

	// ---- flattening ----

	/// Flattens to line segments, subdividing only where the curve is not yet flat enough.
	///
	/// The output receives every point EXCEPT the last, which is appended here: the
	/// recursion emits the start of each accepted span, so the far end would otherwise be
	/// missing.
	public static void FlattenQuadratic(Float2 p0, Float2 p1, Float2 p2, float tolerance,
		List<Float2> output)
	{
		FlattenQuadraticRecursive(p0, p1, p2, tolerance * tolerance, 0, output);
		output.Add(p2);
	}

	public static void FlattenCubic(Float2 p0, Float2 p1, Float2 p2, Float2 p3, float tolerance,
		List<Float2> output)
	{
		FlattenCubicRecursive(p0, p1, p2, p3, tolerance * tolerance, 0, output);
		output.Add(p3);
	}

	private static void FlattenQuadraticRecursive(Float2 p0, Float2 p1, Float2 p2,
		float toleranceSquared, int depth, List<Float2> output)
	{
		if (depth > cMaxFlattenDepth)
		{
			output.Add(p0);
			return;
		}

		// Flat enough when the control point sits close to the midpoint of the chord.
		let mid = (p0 + p2) * 0.5f;
		let deviation = p1 - mid;
		if (((deviation.X * deviation.X) + (deviation.Y * deviation.Y)) <= toleranceSquared)
		{
			output.Add(p0);
			return;
		}

		// De Casteljau at the halfway parameter.
		let p01 = (p0 + p1) * 0.5f;
		let p12 = (p1 + p2) * 0.5f;
		let p012 = (p01 + p12) * 0.5f;

		FlattenQuadraticRecursive(p0, p01, p012, toleranceSquared, depth + 1, output);
		FlattenQuadraticRecursive(p012, p12, p2, toleranceSquared, depth + 1, output);
	}

	private static void FlattenCubicRecursive(Float2 p0, Float2 p1, Float2 p2, Float2 p3,
		float toleranceSquared, int depth, List<Float2> output)
	{
		if (depth > cMaxFlattenDepth)
		{
			output.Add(p0);
			return;
		}

		// Flat enough when BOTH control points sit close to the chord. Checking only one
		// accepts an S bend whose halves cancel.
		let first = PointToLineDistanceSquared(p1, p0, p3);
		let second = PointToLineDistanceSquared(p2, p0, p3);
		if ((first <= toleranceSquared) && (second <= toleranceSquared))
		{
			output.Add(p0);
			return;
		}

		let p01 = (p0 + p1) * 0.5f;
		let p12 = (p1 + p2) * 0.5f;
		let p23 = (p2 + p3) * 0.5f;
		let p012 = (p01 + p12) * 0.5f;
		let p123 = (p12 + p23) * 0.5f;
		let p0123 = (p012 + p123) * 0.5f;

		FlattenCubicRecursive(p0, p01, p012, p0123, toleranceSquared, depth + 1, output);
		FlattenCubicRecursive(p0123, p123, p23, p3, toleranceSquared, depth + 1, output);
	}

	/// The squared perpendicular distance from a point to the INFINITE line through two
	/// others. A degenerate line falls back to the distance to its start.
	private static float PointToLineDistanceSquared(Float2 point, Float2 lineStart, Float2 lineEnd)
	{
		let dx = lineEnd.X - lineStart.X;
		let dy = lineEnd.Y - lineStart.Y;
		let lengthSquared = (dx * dx) + (dy * dy);
		if (lengthSquared < cEpsilon)
			return DistanceSquared(point, lineStart);

		let cross = ((point.X - lineStart.X) * dy) - ((point.Y - lineStart.Y) * dx);
		return (cross * cross) / lengthSquared;
	}

	// ---- arcs ----

	/// Converts an SVG endpoint arc into cubics, appended as groups of THREE points: the
	/// two control points and the end.
	///
	/// The endpoint parameterisation is what SVG stores and what a person authors; every
	/// renderer wants centre and angles. This is the conversion from the specification,
	/// including its two correction steps: radii too small to reach are scaled up rather
	/// than refused, and a degenerate radius becomes a line.
	public static void ArcToCubics(Float2 from, float rx, float ry, float xAxisRotation,
		bool largeArc, bool sweep, Float2 to, List<Float2> controlPoints)
	{
		// An arc to where it already is has no arc to draw.
		if (Distance(from, to) < cEpsilon)
			return;

		var radiusX = Abs(rx);
		var radiusY = Abs(ry);

		// A zero radius is a straight line by the specification, not an error.
		if ((radiusX < cEpsilon) || (radiusY < cEpsilon))
		{
			controlPoints.Add(from);
			controlPoints.Add(to);
			controlPoints.Add(to);
			return;
		}

		let sinPhi = Sin(xAxisRotation);
		let cosPhi = Cos(xAxisRotation);

		// Into the space where the ellipse is a unit circle.
		let dx = (from.X - to.X) * 0.5f;
		let dy = (from.Y - to.Y) * 0.5f;
		let x1p = (cosPhi * dx) + (sinPhi * dy);
		let y1p = (-sinPhi * dx) + (cosPhi * dy);

		let x1pSquared = x1p * x1p;
		let y1pSquared = y1p * y1p;

		// Radii too small to span the endpoints are SCALED UP until they just reach, which
		// is what the specification says to do rather than refusing the arc.
		let lambda = (x1pSquared / (radiusX * radiusX)) + (y1pSquared / (radiusY * radiusY));
		if (lambda > 1.0f)
		{
			let scale = Sqrt(lambda);
			radiusX *= scale;
			radiusY *= scale;
		}

		let rx2 = radiusX * radiusX;
		let ry2 = radiusY * radiusY;

		// Clamped at zero: the exact arithmetic cannot go negative, but rounding at the
		// scaled-radii boundary can, and a negative square root would be a NaN centre.
		var underRoot = ((rx2 * ry2) - (rx2 * y1pSquared) - (ry2 * x1pSquared))
			/ ((rx2 * y1pSquared) + (ry2 * x1pSquared));
		if (underRoot < 0.0f)
			underRoot = 0.0f;

		var coefficient = Sqrt(underRoot);
		// The two flags together pick which of the two possible centres is meant.
		if (largeArc == sweep)
			coefficient = -coefficient;

		let cxp = coefficient * radiusX * y1p / radiusY;
		let cyp = coefficient * -radiusY * x1p / radiusX;

		let mx = (from.X + to.X) * 0.5f;
		let my = (from.Y + to.Y) * 0.5f;
		let cx = (cosPhi * cxp) - (sinPhi * cyp) + mx;
		let cy = (sinPhi * cxp) + (cosPhi * cyp) + my;

		let startAngle = VectorAngle(1.0f, 0.0f, (x1p - cxp) / radiusX, (y1p - cyp) / radiusY);
		var deltaAngle = VectorAngle((x1p - cxp) / radiusX, (y1p - cyp) / radiusY,
			(-x1p - cxp) / radiusX, (-y1p - cyp) / radiusY);

		// The sweep flag says which way round, so a delta with the wrong sign takes the
		// long way instead.
		if (!sweep && (deltaAngle > 0.0f))
			deltaAngle -= TwoPi;
		else if (sweep && (deltaAngle < 0.0f))
			deltaAngle += TwoPi;

		// A cubic approximates a circular arc well up to about a quarter turn, so the sweep
		// is split into that many pieces.
		let segments = Max(1, (int32)((Abs(deltaAngle) / HalfPi) + 0.999f));
		let segmentAngle = deltaAngle / (float)segments;

		for (int32 i = 0; i < segments; i++)
		{
			ArcSegmentToCubic(cx, cy, radiusX, radiusY, xAxisRotation,
				startAngle + (segmentAngle * (float)i),
				startAngle + (segmentAngle * (float)(i + 1)), controlPoints);
		}
	}

	/// The SIGNED angle from one vector to another, which is what tells the arc conversion
	/// which way it is going.
	private static float VectorAngle(float ux, float uy, float vx, float vy)
	{
		let dot = (ux * vx) + (uy * vy);
		let cross = (ux * vy) - (uy * vx);
		return Atan2(cross, dot);
	}

	private static void ArcSegmentToCubic(float cx, float cy, float rx, float ry, float phi,
		float a1, float a2, List<Float2> controlPoints)
	{
		// The control point distance that makes a cubic match a circular arc of this sweep.
		let half = (a2 - a1) * 0.5f;
		let alpha = Sin(a2 - a1) * (Sqrt(4.0f + (3.0f * Tan(half) * Tan(half))) - 1.0f) / 3.0f;

		let sinPhi = Sin(phi);
		let cosPhi = Cos(phi);
		let cosA1 = Cos(a1);
		let sinA1 = Sin(a1);
		let cosA2 = Cos(a2);
		let sinA2 = Sin(a2);

		let x1 = (cosPhi * rx * cosA1) - (sinPhi * ry * sinA1) + cx;
		let y1 = (sinPhi * rx * cosA1) + (cosPhi * ry * sinA1) + cy;
		let x4 = (cosPhi * rx * cosA2) - (sinPhi * ry * sinA2) + cx;
		let y4 = (sinPhi * rx * cosA2) + (cosPhi * ry * sinA2) + cy;

		// The derivatives at each end, which the control points travel along.
		let dx1 = (-cosPhi * rx * sinA1) - (sinPhi * ry * cosA1);
		let dy1 = (-sinPhi * rx * sinA1) + (cosPhi * ry * cosA1);
		let dx2 = (-cosPhi * rx * sinA2) - (sinPhi * ry * cosA2);
		let dy2 = (-sinPhi * rx * sinA2) + (cosPhi * ry * cosA2);

		controlPoints.Add(.(x1 + (alpha * dx1), y1 + (alpha * dy1)));
		controlPoints.Add(.(x4 - (alpha * dx2), y4 - (alpha * dy2)));
		controlPoints.Add(.(x4, y4));
	}
}
