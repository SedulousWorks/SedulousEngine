using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// An immutable vector path consisting of commands and points.
/// Created via PathBuilder.ToPath().
public class Path
{
	private List<PathCommand> mCommands ~ delete _;
	private List<Vector2> mPoints ~ delete _;

	/// Create a path from pre-built command and point lists (takes ownership)
	public this(List<PathCommand> commands, List<Vector2> points)
	{
		mCommands = commands;
		mPoints = points;
	}

	/// The commands that define this path
	public Span<PathCommand> Commands => mCommands;

	/// The points referenced by commands
	public Span<Vector2> Points => mPoints;

	/// Number of commands
	public int CommandCount => mCommands.Count;

	/// Number of points
	public int PointCount => mPoints.Count;

	/// Create an iterator over this path's segments
	public PathIterator GetIterator()
	{
		return .(mCommands, mPoints);
	}

	/// Count of sub-paths (number of MoveTo commands)
	public int SubPathCount
	{
		get
		{
			int count = 0;
			for (let cmd in mCommands)
			{
				if (cmd == .MoveTo)
					count++;
			}
			return count;
		}
	}

	/// Calculate the axis-aligned bounding box of this path
	public RectangleF GetBounds()
	{
		if (mPoints.Count == 0)
			return default;

		var minX = mPoints[0].X;
		var minY = mPoints[0].Y;
		var maxX = minX;
		var maxY = minY;

		for (let p in mPoints)
		{
			if (p.X < minX) minX = p.X;
			if (p.Y < minY) minY = p.Y;
			if (p.X > maxX) maxX = p.X;
			if (p.Y > maxY) maxY = p.Y;
		}

		return .(minX, minY, maxX - minX, maxY - minY);
	}

	/// Test whether a point is inside this path using the given fill rule.
	/// Uses ray casting (even-odd) or winding number (non-zero).
	public bool Contains(Vector2 point, FillRule fillRule)
	{
		// Flatten to polyline segments and do ray cast
		var iter = GetIterator();
		PathSegment seg = ?;
		int windingNumber = 0;
		var penPos = Vector2.Zero;
		var subPathStart = Vector2.Zero;

		while (iter.GetNext(out seg))
		{
			switch (seg.Command)
			{
			case .MoveTo:
				penPos = seg.Points[0];
				subPathStart = penPos;
			case .LineTo:
				let endPt = seg.Points[0];
				windingNumber += RayCrossing(point, penPos, endPt);
				penPos = endPt;
			case .QuadTo:
				// Approximate with line segments
				let cp = seg.Points[0];
				let endPt = seg.Points[1];
				let steps = 8;
				var prev = penPos;
				for (int i = 1; i <= steps; i++)
				{
					let t = (float)i / steps;
					let next = CurveUtils.QuadraticPointAt(penPos, cp, endPt, t);
					windingNumber += RayCrossing(point, prev, next);
					prev = next;
				}
				penPos = endPt;
			case .CubicTo:
				let cp1 = seg.Points[0];
				let cp2 = seg.Points[1];
				let endPt = seg.Points[2];
				let steps = 16;
				var prev = penPos;
				for (int i = 1; i <= steps; i++)
				{
					let t = (float)i / steps;
					let next = CurveUtils.CubicPointAt(penPos, cp1, cp2, endPt, t);
					windingNumber += RayCrossing(point, prev, next);
					prev = next;
				}
				penPos = endPt;
			case .Close:
				windingNumber += RayCrossing(point, penPos, subPathStart);
				penPos = subPathStart;
			}
		}

		switch (fillRule)
		{
		case .EvenOdd:
			return (windingNumber & 1) != 0;
		case .NonZero:
			return windingNumber != 0;
		}
	}

	/// Get the total arc length of the path
	public float GetLength()
	{
		float totalLength = 0;
		var iter = GetIterator();
		PathSegment seg = ?;

		while (iter.GetNext(out seg))
		{
			switch (seg.Command)
			{
			case .MoveTo:
				// No length
			case .LineTo:
				totalLength += Vector2.Distance(seg.StartPoint, seg.Points[0]);
			case .QuadTo:
				totalLength += CurveUtils.QuadraticLength(seg.StartPoint, seg.Points[0], seg.Points[1]);
			case .CubicTo:
				totalLength += CurveUtils.CubicLength(seg.StartPoint, seg.Points[0], seg.Points[1], seg.Points[2]);
			case .Close:
				// Close segment has implicit line
			}
		}

		return totalLength;
	}

	/// Get the point at a given distance along the path
	public Vector2 GetPointAtDistance(float distance)
	{
		float remaining = distance;
		var iter = GetIterator();
		PathSegment seg = ?;

		while (iter.GetNext(out seg))
		{
			float segLen = 0;
			switch (seg.Command)
			{
			case .MoveTo:
				continue;
			case .LineTo:
				segLen = Vector2.Distance(seg.StartPoint, seg.Points[0]);
				if (remaining <= segLen)
				{
					let t = remaining / segLen;
					return Vector2.Lerp(seg.StartPoint, seg.Points[0], t);
				}
			case .QuadTo:
				segLen = CurveUtils.QuadraticLength(seg.StartPoint, seg.Points[0], seg.Points[1]);
				if (remaining <= segLen)
				{
					let t = remaining / segLen;
					return CurveUtils.QuadraticPointAt(seg.StartPoint, seg.Points[0], seg.Points[1], t);
				}
			case .CubicTo:
				segLen = CurveUtils.CubicLength(seg.StartPoint, seg.Points[0], seg.Points[1], seg.Points[2]);
				if (remaining <= segLen)
				{
					let t = remaining / segLen;
					return CurveUtils.CubicPointAt(seg.StartPoint, seg.Points[0], seg.Points[1], seg.Points[2], t);
				}
			case .Close:
				continue;
			}
			remaining -= segLen;
		}

		// Past end - return last point
		if (mPoints.Count > 0)
			return mPoints[mPoints.Count - 1];
		return .Zero;
	}

	/// Get the tangent direction at a given distance along the path
	public Vector2 GetTangentAtDistance(float distance)
	{
		float remaining = distance;
		var iter = GetIterator();
		PathSegment seg = ?;

		while (iter.GetNext(out seg))
		{
			float segLen = 0;
			switch (seg.Command)
			{
			case .MoveTo:
				continue;
			case .LineTo:
				segLen = Vector2.Distance(seg.StartPoint, seg.Points[0]);
				if (remaining <= segLen)
				{
					var tangent = seg.Points[0] - seg.StartPoint;
					let len = tangent.Length();
					if (len > 0.0001f)
						return tangent / len;
					return .(1, 0);
				}
			case .QuadTo:
				segLen = CurveUtils.QuadraticLength(seg.StartPoint, seg.Points[0], seg.Points[1]);
				if (remaining <= segLen)
				{
					let t = remaining / segLen;
					return CurveUtils.QuadraticTangentAt(seg.StartPoint, seg.Points[0], seg.Points[1], t);
				}
			case .CubicTo:
				segLen = CurveUtils.CubicLength(seg.StartPoint, seg.Points[0], seg.Points[1], seg.Points[2]);
				if (remaining <= segLen)
				{
					let t = remaining / segLen;
					return CurveUtils.CubicTangentAt(seg.StartPoint, seg.Points[0], seg.Points[1], seg.Points[2], t);
				}
			case .Close:
				continue;
			}
			remaining -= segLen;
		}

		return .(1, 0);
	}

	/// Ray crossing test for point-in-polygon. Returns +1 or -1 for crossing direction, 0 for no crossing.
	private static int RayCrossing(Vector2 point, Vector2 a, Vector2 b)
	{
		if (a.Y <= point.Y)
		{
			if (b.Y > point.Y)
			{
				// Upward crossing
				if (CrossProduct(b - a, point - a) > 0)
					return 1;
			}
		}
		else
		{
			if (b.Y <= point.Y)
			{
				// Downward crossing
				if (CrossProduct(b - a, point - a) < 0)
					return -1;
			}
		}
		return 0;
	}

	private static float CrossProduct(Vector2 a, Vector2 b)
	{
		return a.X * b.Y - a.Y * b.X;
	}
}
