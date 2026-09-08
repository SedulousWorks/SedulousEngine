using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.VG;

/// Reduces a path to polylines, one per subpath.
///
/// Everything downstream, filling and stroking alike, works on polylines. Doing the
/// reduction once here is what keeps the curve mathematics out of the tessellators.
static class PathFlattener
{
	/// How close two points must be to count as the same one.
	///
	/// A hundredth of a pixel: coincident points produce zero length edges, whose normal
	/// is a division by zero, and a stroke built on one gets a spike or a hole where the
	/// join should be.
	private const float cDistanceTolerance = 0.01f;

	/// THE CALLER OWNS the subpaths appended to `output`.
	public static void Flatten(Path path, float tolerance, List<FlattenedSubPath> output)
	{
		var iterator = path.GetIterator();
		FlattenedSubPath current = null;

		while (iterator.GetNext(let segment))
		{
			switch (segment.Command)
			{
			case .MoveTo:
				current = new FlattenedSubPath();
				output.Add(current);
				current.Points.Add(segment.Points[0]);

			case .LineTo:
				if (current != null)
					AddPoint(current.Points, segment.Points[0]);

			case .QuadTo:
				if (current != null)
				{
					let previousCount = current.Points.Count;
					CurveUtils.FlattenQuadratic(segment.StartPoint, segment.Points[0],
						segment.Points[1], tolerance, current.Points);
					DeduplicateFrom(current.Points, previousCount);
				}

			case .CubicTo:
				if (current != null)
				{
					let previousCount = current.Points.Count;
					CurveUtils.FlattenCubic(segment.StartPoint, segment.Points[0],
						segment.Points[1], segment.Points[2], tolerance, current.Points);
					DeduplicateFrom(current.Points, previousCount);
				}

			case .Close:
				if (current != null)
					CloseSubPath(current);
			}
		}
	}

	private static void CloseSubPath(FlattenedSubPath subPath)
	{
		subPath.IsClosed = true;

		// Trailing points sitting on the first one would make the closing edge zero
		// length, whose normal is undefined. Two points are kept regardless: below that
		// there is no subpath left to speak of.
		if (subPath.Points.Count <= 2)
			return;

		let first = subPath.Points[0];
		while ((subPath.Points.Count > 2)
			&& PointsEqual(subPath.Points[subPath.Points.Count - 1], first))
			subPath.Points.RemoveAt(subPath.Points.Count - 1);
	}

	/// Appends only if it is somewhere new.
	private static void AddPoint(List<Float2> points, Float2 point)
	{
		if (!points.IsEmpty && PointsEqual(points[points.Count - 1], point))
			return;
		points.Add(point);
	}

	/// Drops points coincident with their predecessor, from `startIndex` on.
	///
	/// Flattening emits the start of every accepted span, and a curve that begins where the
	/// previous segment ended therefore repeats that point. Comparing against the
	/// predecessor also catches a curve that folds back on itself.
	private static void DeduplicateFrom(List<Float2> points, int startIndex)
	{
		var index = Max(startIndex, 1);
		while (index < points.Count)
		{
			if (PointsEqual(points[index], points[index - 1]))
				points.RemoveAt(index);
			else
				index++;
		}
	}

	private static bool PointsEqual(Float2 a, Float2 b)
	{
		let dx = b.X - a.X;
		let dy = b.Y - a.Y;
		return ((dx * dx) + (dy * dy)) < (cDistanceTolerance * cDistanceTolerance);
	}
}
