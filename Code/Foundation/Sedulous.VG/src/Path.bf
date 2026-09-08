using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.VG;

/// An immutable path: a command stream and the points those commands consume.
///
/// Built through a PathBuilder. Immutable because a path is CACHED against its
/// tessellation, and something that could change underneath the cache would serve
/// geometry for a shape that no longer exists.
class Path
{
	private List<PathCommand> mCommands = new .() ~ delete _;
	private List<Float2> mPoints = new .() ~ delete _;

	public this() {}

	/// COPIES what it is given, so a builder can go on being used afterwards.
	public this(Span<PathCommand> commands, Span<Float2> points)
	{
		mCommands.AddRange(commands);
		mPoints.AddRange(points);
	}

	public Span<PathCommand> Commands => mCommands;
	public Span<Float2> Points => mPoints;
	public int CommandCount => mCommands.Count;
	public int PointCount => mPoints.Count;

	public PathIterator GetIterator() => .(Commands, Points);

	/// How many subpaths, which is how many times the pen was moved without drawing.
	public int SubPathCount
	{
		get
		{
			var count = 0;
			for (let command in mCommands)
			{
				if (command == .MoveTo)
					count++;
			}
			return count;
		}
	}

	/// The axis aligned box around the path's CONTROL POINTS.
	///
	/// Not around the curve itself, which is always inside its control polygon: this is
	/// conservative, which is what a culling test and a cover quad both want, and it costs
	/// one pass rather than a flattening.
	public Rectangle GetBounds()
	{
		if (mPoints.IsEmpty)
			return .();

		var minX = mPoints[0].X;
		var minY = mPoints[0].Y;
		var maxX = minX;
		var maxY = minY;

		for (let point in mPoints)
		{
			minX = Min(minX, point.X);
			minY = Min(minY, point.Y);
			maxX = Max(maxX, point.X);
			maxY = Max(maxY, point.Y);
		}

		return .(minX, minY, maxX - minX, maxY - minY);
	}

	/// Whether a point is inside, under the given fill rule.
	///
	/// Curves are sampled rather than solved: a hit test is answered at interaction rates
	/// and a few steps are indistinguishable from exact at the scale a person clicks.
	public bool Contains(Float2 point, FillRule fillRule)
	{
		var iterator = GetIterator();
		int32 winding = 0;
		var pen = Float2.Zero;
		var subPathStart = Float2.Zero;

		while (iterator.GetNext(let segment))
		{
			switch (segment.Command)
			{
			case .MoveTo:
				pen = segment.Points[0];
				subPathStart = pen;

			case .LineTo:
				winding += RayCrossing(point, pen, segment.Points[0]);
				pen = segment.Points[0];

			case .QuadTo:
				winding += CurveCrossings(point, pen, segment, 8);
				pen = segment.Points[1];

			case .CubicTo:
				// More steps than a quadratic, because a cubic can turn twice.
				winding += CurveCrossings(point, pen, segment, 16);
				pen = segment.Points[2];

			case .Close:
				winding += RayCrossing(point, pen, subPathStart);
				pen = subPathStart;
			}
		}

		switch (fillRule)
		{
		case .EvenOdd: return (winding & 1) != 0;
		case .NonZero: return winding != 0;
		}
	}

	private static int32 CurveCrossings(Float2 point, Float2 pen, PathSegment segment, int32 steps)
	{
		int32 crossings = 0;
		var previous = pen;

		for (int32 i = 1; i <= steps; i++)
		{
			let t = (float)i / (float)steps;
			let next = (segment.Command == .QuadTo)
				? CurveUtils.QuadraticPointAt(pen, segment.Points[0], segment.Points[1], t)
				: CurveUtils.CubicPointAt(pen, segment.Points[0], segment.Points[1],
					segment.Points[2], t);

			crossings += RayCrossing(point, previous, next);
			previous = next;
		}
		return crossings;
	}

	/// The total arc length.
	///
	/// A Close contributes NOTHING, matching Raptor: its implicit line back to the subpath
	/// start is not counted, so a closed shape's length is the length of what was drawn.
	public float GetLength()
	{
		var total = 0.0f;
		var iterator = GetIterator();

		while (iterator.GetNext(let segment))
		{
			switch (segment.Command)
			{
			case .MoveTo, .Close:
			case .LineTo:
				total += Distance(segment.StartPoint, segment.Points[0]);
			case .QuadTo:
				total += CurveUtils.QuadraticLength(segment.StartPoint, segment.Points[0],
					segment.Points[1]);
			case .CubicTo:
				total += CurveUtils.CubicLength(segment.StartPoint, segment.Points[0],
					segment.Points[1], segment.Points[2]);
			}
		}
		return total;
	}

	/// The point a given distance along the path. Past the end it is the last point, which
	/// is what a caller stepping a dash pattern wants rather than a wrap or an error.
	public Float2 GetPointAtDistance(float distance)
	{
		var remaining = distance;
		var iterator = GetIterator();

		while (iterator.GetNext(let segment))
		{
			var segmentLength = 0.0f;
			switch (segment.Command)
			{
			case .MoveTo, .Close:
				continue;

			case .LineTo:
				segmentLength = Distance(segment.StartPoint, segment.Points[0]);
				if (remaining <= segmentLength)
					return Lerp(segment.StartPoint, segment.Points[0], remaining / segmentLength);

			case .QuadTo:
				segmentLength = CurveUtils.QuadraticLength(segment.StartPoint, segment.Points[0],
					segment.Points[1]);
				if (remaining <= segmentLength)
				{
					// The parameter is the distance FRACTION, which is only the arc length
					// parameter for a curve of even speed. Close enough for a dash phase,
					// and exact for the line case above.
					return CurveUtils.QuadraticPointAt(segment.StartPoint, segment.Points[0],
						segment.Points[1], remaining / segmentLength);
				}

			case .CubicTo:
				segmentLength = CurveUtils.CubicLength(segment.StartPoint, segment.Points[0],
					segment.Points[1], segment.Points[2]);
				if (remaining <= segmentLength)
				{
					return CurveUtils.CubicPointAt(segment.StartPoint, segment.Points[0],
						segment.Points[1], segment.Points[2], remaining / segmentLength);
				}
			}
			remaining -= segmentLength;
		}

		if (!mPoints.IsEmpty)
			return mPoints[mPoints.Count - 1];
		return .Zero;
	}

	/// The direction of travel at a given distance. Past the end, or on a degenerate path,
	/// it is positive X rather than a zero vector a caller would divide by.
	public Float2 GetTangentAtDistance(float distance)
	{
		var remaining = distance;
		var iterator = GetIterator();

		while (iterator.GetNext(let segment))
		{
			var segmentLength = 0.0f;
			switch (segment.Command)
			{
			case .MoveTo, .Close:
				continue;

			case .LineTo:
				segmentLength = Distance(segment.StartPoint, segment.Points[0]);
				if (remaining <= segmentLength)
				{
					let tangent = segment.Points[0] - segment.StartPoint;
					let length = Length(tangent);
					return (length > 0.0001f) ? (tangent / length) : Float2(1.0f, 0.0f);
				}

			case .QuadTo:
				segmentLength = CurveUtils.QuadraticLength(segment.StartPoint, segment.Points[0],
					segment.Points[1]);
				if (remaining <= segmentLength)
				{
					return CurveUtils.QuadraticTangentAt(segment.StartPoint, segment.Points[0],
						segment.Points[1], remaining / segmentLength);
				}

			case .CubicTo:
				segmentLength = CurveUtils.CubicLength(segment.StartPoint, segment.Points[0],
					segment.Points[1], segment.Points[2]);
				if (remaining <= segmentLength)
				{
					return CurveUtils.CubicTangentAt(segment.StartPoint, segment.Points[0],
						segment.Points[1], segment.Points[2], remaining / segmentLength);
				}
			}
			remaining -= segmentLength;
		}

		return .(1.0f, 0.0f);
	}

	/// Whether a ray from the point crosses this edge, and which way: up counts once
	/// forward, down once back. Summing them over a closed contour gives the winding
	/// number, which both fill rules are then read off.
	private static int32 RayCrossing(Float2 point, Float2 a, Float2 b)
	{
		// The comparisons are deliberately asymmetric, one side inclusive and the other
		// not, so a vertex exactly on the ray is counted by exactly one of the two edges
		// meeting there rather than by both or neither.
		if (a.Y <= point.Y)
		{
			if ((b.Y > point.Y) && (CrossProduct(b - a, point - a) > 0.0f))
				return 1;
		}
		else if ((b.Y <= point.Y) && (CrossProduct(b - a, point - a) < 0.0f))
		{
			return -1;
		}
		return 0;
	}

	private static float CrossProduct(Float2 a, Float2 b) => (a.X * b.Y) - (a.Y * b.X);
}
