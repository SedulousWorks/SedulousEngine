using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// Utility functions for Bezier curve math
public static class CurveUtils
{
	/// Evaluate a point on a quadratic Bezier curve at parameter t
	public static Vector2 QuadraticPointAt(Vector2 p0, Vector2 p1, Vector2 p2, float t)
	{
		let mt = 1.0f - t;
		return p0 * (mt * mt) + p1 * (2.0f * mt * t) + p2 * (t * t);
	}

	/// Evaluate a point on a cubic Bezier curve at parameter t
	public static Vector2 CubicPointAt(Vector2 p0, Vector2 p1, Vector2 p2, Vector2 p3, float t)
	{
		let mt = 1.0f - t;
		let mt2 = mt * mt;
		let t2 = t * t;
		return p0 * (mt2 * mt) + p1 * (3.0f * mt2 * t) + p2 * (3.0f * mt * t2) + p3 * (t2 * t);
	}

	/// Get the tangent (normalized direction) of a quadratic Bezier at parameter t
	public static Vector2 QuadraticTangentAt(Vector2 p0, Vector2 p1, Vector2 p2, float t)
	{
		let mt = 1.0f - t;
		var tangent = (p1 - p0) * (2.0f * mt) + (p2 - p1) * (2.0f * t);
		let len = tangent.Length();
		if (len > 0.0001f)
			return tangent / len;
		return .(1, 0);
	}

	/// Get the tangent (normalized direction) of a cubic Bezier at parameter t
	public static Vector2 CubicTangentAt(Vector2 p0, Vector2 p1, Vector2 p2, Vector2 p3, float t)
	{
		let mt = 1.0f - t;
		let mt2 = mt * mt;
		let t2 = t * t;
		var tangent = (p1 - p0) * (3.0f * mt2) + (p2 - p1) * (6.0f * mt * t) + (p3 - p2) * (3.0f * t2);
		let len = tangent.Length();
		if (len > 0.0001f)
			return tangent / len;
		return .(1, 0);
	}

	/// Approximate the arc length of a quadratic Bezier using subdivision
	public static float QuadraticLength(Vector2 p0, Vector2 p1, Vector2 p2, int steps = 16)
	{
		float length = 0;
		var prev = p0;
		for (int i = 1; i <= steps; i++)
		{
			let t = (float)i / steps;
			let next = QuadraticPointAt(p0, p1, p2, t);
			length += Vector2.Distance(prev, next);
			prev = next;
		}
		return length;
	}

	/// Approximate the arc length of a cubic Bezier using subdivision
	public static float CubicLength(Vector2 p0, Vector2 p1, Vector2 p2, Vector2 p3, int steps = 16)
	{
		float length = 0;
		var prev = p0;
		for (int i = 1; i <= steps; i++)
		{
			let t = (float)i / steps;
			let next = CubicPointAt(p0, p1, p2, p3, t);
			length += Vector2.Distance(prev, next);
			prev = next;
		}
		return length;
	}

	/// Flatten a quadratic Bezier into line segments using adaptive subdivision
	public static void FlattenQuadratic(Vector2 p0, Vector2 p1, Vector2 p2, float tolerance, List<Vector2> output)
	{
		FlattenQuadraticRecursive(p0, p1, p2, tolerance * tolerance, 0, output);
		output.Add(p2);
	}

	/// Flatten a cubic Bezier into line segments using adaptive subdivision
	public static void FlattenCubic(Vector2 p0, Vector2 p1, Vector2 p2, Vector2 p3, float tolerance, List<Vector2> output)
	{
		FlattenCubicRecursive(p0, p1, p2, p3, tolerance * tolerance, 0, output);
		output.Add(p3);
	}

	/// Convert an SVG endpoint arc to cubic Bezier curves
	public static void ArcToCubics(Vector2 from, float rx, float ry, float xAxisRotation, bool largeArc, bool sweep, Vector2 to, List<Vector2> controlPoints)
	{
		// Handle degenerate cases
		if (Vector2.Distance(from, to) < 0.0001f)
			return;

		var rx, ry;
		rx = Math.Abs(rx);
		ry = Math.Abs(ry);
		if (rx < 0.0001f || ry < 0.0001f)
		{
			// Degenerate to line
			controlPoints.Add(from);
			controlPoints.Add(to);
			controlPoints.Add(to);
			return;
		}

		let sinPhi = Math.Sin(xAxisRotation);
		let cosPhi = Math.Cos(xAxisRotation);

		// Step 1: Compute (x1', y1') - transform to unit circle space
		let dx = (from.X - to.X) * 0.5f;
		let dy = (from.Y - to.Y) * 0.5f;
		let x1p = (float)(cosPhi * dx + sinPhi * dy);
		let y1p = (float)(-sinPhi * dx + cosPhi * dy);

		// Step 2: Compute (cx', cy') - center in transformed space
		let x1p2 = x1p * x1p;
		let y1p2 = y1p * y1p;
		let rx2 = rx * rx;
		let ry2 = ry * ry;

		// Scale radii if needed
		let lambda = x1p2 / rx2 + y1p2 / ry2;
		if (lambda > 1.0f)
		{
			let sqrtLambda = Math.Sqrt(lambda);
			rx *= sqrtLambda;
			ry *= sqrtLambda;
		}

		let rx2Updated = rx * rx;
		let ry2Updated = ry * ry;

		var sq = (rx2Updated * ry2Updated - rx2Updated * y1p2 - ry2Updated * x1p2) /
				 (rx2Updated * y1p2 + ry2Updated * x1p2);
		if (sq < 0) sq = 0;
		var coeff = Math.Sqrt(sq);
		if (largeArc == sweep)
			coeff = -coeff;

		let cxp = (float)(coeff * rx * y1p / ry);
		let cyp = (float)(coeff * -ry * x1p / rx);

		// Step 3: Compute (cx, cy) from (cx', cy')
		let mx = (from.X + to.X) * 0.5f;
		let my = (from.Y + to.Y) * 0.5f;
		let cx = (float)(cosPhi * cxp - sinPhi * cyp + mx);
		let cy = (float)(sinPhi * cxp + cosPhi * cyp + my);

		// Step 4: Compute angles
		let startAngle = VectorAngle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry);
		var deltaAngle = VectorAngle((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry);

		if (!sweep && deltaAngle > 0)
			deltaAngle -= Math.PI_f * 2.0f;
		else if (sweep && deltaAngle < 0)
			deltaAngle += Math.PI_f * 2.0f;

		// Step 5: Convert arc to cubic Bezier segments
		let segments = Math.Max(1, (int)(Math.Abs(deltaAngle) / (Math.PI_f * 0.5f) + 0.999f));
		let segAngle = deltaAngle / segments;

		for (int i = 0; i < segments; i++)
		{
			let a1 = startAngle + segAngle * i;
			let a2 = startAngle + segAngle * (i + 1);
			ArcSegmentToCubic(cx, cy, rx, ry, (float)xAxisRotation, a1, a2, controlPoints);
		}
	}

	// --- Private helpers ---

	private static void FlattenQuadraticRecursive(Vector2 p0, Vector2 p1, Vector2 p2, float toleranceSq, int depth, List<Vector2> output)
	{
		if (depth > 16)
		{
			output.Add(p0);
			return;
		}

		// Check flatness: distance from control point to line p0-p2
		let mid = (p0 + p2) * 0.5f;
		let deviation = p1 - mid;
		if (deviation.X * deviation.X + deviation.Y * deviation.Y <= toleranceSq)
		{
			output.Add(p0);
			return;
		}

		// Subdivide
		let p01 = (p0 + p1) * 0.5f;
		let p12 = (p1 + p2) * 0.5f;
		let p012 = (p01 + p12) * 0.5f;

		FlattenQuadraticRecursive(p0, p01, p012, toleranceSq, depth + 1, output);
		FlattenQuadraticRecursive(p012, p12, p2, toleranceSq, depth + 1, output);
	}

	private static void FlattenCubicRecursive(Vector2 p0, Vector2 p1, Vector2 p2, Vector2 p3, float toleranceSq, int depth, List<Vector2> output)
	{
		if (depth > 16)
		{
			output.Add(p0);
			return;
		}

		// Check flatness: max distance of control points from chord
		let d1 = PointToLineDistanceSq(p1, p0, p3);
		let d2 = PointToLineDistanceSq(p2, p0, p3);
		if (d1 <= toleranceSq && d2 <= toleranceSq)
		{
			output.Add(p0);
			return;
		}

		// De Casteljau subdivision at t=0.5
		let p01 = (p0 + p1) * 0.5f;
		let p12 = (p1 + p2) * 0.5f;
		let p23 = (p2 + p3) * 0.5f;
		let p012 = (p01 + p12) * 0.5f;
		let p123 = (p12 + p23) * 0.5f;
		let p0123 = (p012 + p123) * 0.5f;

		FlattenCubicRecursive(p0, p01, p012, p0123, toleranceSq, depth + 1, output);
		FlattenCubicRecursive(p0123, p123, p23, p3, toleranceSq, depth + 1, output);
	}

	private static float PointToLineDistanceSq(Vector2 point, Vector2 lineStart, Vector2 lineEnd)
	{
		let dx = lineEnd.X - lineStart.X;
		let dy = lineEnd.Y - lineStart.Y;
		let lenSq = dx * dx + dy * dy;
		if (lenSq < 0.0001f)
			return Vector2.DistanceSquared(point, lineStart);

		let cross = (point.X - lineStart.X) * dy - (point.Y - lineStart.Y) * dx;
		return (cross * cross) / lenSq;
	}

	private static float VectorAngle(float ux, float uy, float vx, float vy)
	{
		let dot = ux * vx + uy * vy;
		let cross = ux * vy - uy * vx;
		return (float)Math.Atan2(cross, dot);
	}

	private static void ArcSegmentToCubic(float cx, float cy, float rx, float ry, float phi, float a1, float a2, List<Vector2> controlPoints)
	{
		let alpha = (float)(Math.Sin(a2 - a1) * (Math.Sqrt(4.0 + 3.0 * Math.Tan((a2 - a1) * 0.5) * Math.Tan((a2 - a1) * 0.5)) - 1.0) / 3.0);

		let sinPhi = Math.Sin(phi);
		let cosPhi = Math.Cos(phi);

		let cosA1 = (float)Math.Cos(a1);
		let sinA1 = (float)Math.Sin(a1);
		let cosA2 = (float)Math.Cos(a2);
		let sinA2 = (float)Math.Sin(a2);

		// Start point
		let x1 = (float)(cosPhi * rx * cosA1 - sinPhi * ry * sinA1 + cx);
		let y1 = (float)(sinPhi * rx * cosA1 + cosPhi * ry * sinA1 + cy);

		// End point
		let x4 = (float)(cosPhi * rx * cosA2 - sinPhi * ry * sinA2 + cx);
		let y4 = (float)(sinPhi * rx * cosA2 + cosPhi * ry * sinA2 + cy);

		// Control point 1
		let dx1 = (float)(-cosPhi * rx * sinA1 - sinPhi * ry * cosA1);
		let dy1 = (float)(-sinPhi * rx * sinA1 + cosPhi * ry * cosA1);

		// Control point 2
		let dx2 = (float)(-cosPhi * rx * sinA2 - sinPhi * ry * cosA2);
		let dy2 = (float)(-sinPhi * rx * sinA2 + cosPhi * ry * cosA2);

		controlPoints.Add(.(x1 + alpha * dx1, y1 + alpha * dy1)); // CP1
		controlPoints.Add(.(x4 - alpha * dx2, y4 - alpha * dy2)); // CP2
		controlPoints.Add(.(x4, y4)); // End point
	}
}
