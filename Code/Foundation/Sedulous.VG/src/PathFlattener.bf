using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// Flattens a Path into polyline sub-paths by converting curves to line segments
public static class PathFlattener
{
	private const float DistTol = 0.01f;

	/// Flatten a path into a list of polyline sub-paths
	public static void Flatten(Path path, float tolerance, List<FlattenedSubPath> output)
	{
		var iter = path.GetIterator();
		PathSegment seg = ?;
		FlattenedSubPath current = null;

		while (iter.GetNext(out seg))
		{
			switch (seg.Command)
			{
			case .MoveTo:
				current = new FlattenedSubPath();
				output.Add(current);
				current.Points.Add(seg.Points[0]);

			case .LineTo:
				if (current != null)
					AddPoint(current.Points, seg.Points[0]);

			case .QuadTo:
				if (current != null)
				{
					let prevCount = current.Points.Count;
					CurveUtils.FlattenQuadratic(seg.StartPoint, seg.Points[0], seg.Points[1], tolerance, current.Points);
					// Deduplicate any points that landed on the previous point
					DeduplicateFrom(current.Points, prevCount);
				}

			case .CubicTo:
				if (current != null)
				{
					let prevCount = current.Points.Count;
					CurveUtils.FlattenCubic(seg.StartPoint, seg.Points[0], seg.Points[1], seg.Points[2], tolerance, current.Points);
					// Deduplicate any points that landed on the previous point
					DeduplicateFrom(current.Points, prevCount);
				}

			case .Close:
				if (current != null)
				{
					current.IsClosed = true;
					// Remove trailing points that are coincident with the first point
					// to avoid zero-length closing edges that produce degenerate normals
					if (current.Points.Count > 2)
					{
						let first = current.Points[0];
						while (current.Points.Count > 2 && PointsEqual(current.Points[current.Points.Count - 1], first))
							current.Points.RemoveAt(current.Points.Count - 1);
					}
				}
			}
		}
	}

	/// Add a point only if it's not coincident with the last point
	private static void AddPoint(List<Vector2> points, Vector2 p)
	{
		if (points.Count > 0 && PointsEqual(points[points.Count - 1], p))
			return;
		points.Add(p);
	}

	/// Remove any newly-added points that are coincident with their predecessor
	private static void DeduplicateFrom(List<Vector2> points, int startIdx)
	{
		var startIdx;
		if (startIdx <= 0)
			startIdx = 1;
		int i = startIdx;
		while (i < points.Count)
		{
			if (PointsEqual(points[i], points[i - 1]))
				points.RemoveAt(i);
			else
				i++;
		}
	}

	/// Check if two points are within distance tolerance
	private static bool PointsEqual(Vector2 a, Vector2 b)
	{
		let dx = b.X - a.X;
		let dy = b.Y - a.Y;
		return dx * dx + dy * dy < DistTol * DistTol;
	}
}
