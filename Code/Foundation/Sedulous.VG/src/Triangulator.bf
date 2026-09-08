using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.VG;

/// Turns polygons into triangles by ear clipping, with holes bridged into the outer
/// contour first.
///
/// Ear clipping rather than something asymptotically better because the polygons here come
/// from FLATTENED paths: a few dozen to a few hundred points, where the constant factor
/// dominates and a simple algorithm with no allocation is faster in practice.
static class Triangulator
{
	/// Below this a cross product is treated as collinear rather than as a turn.
	private const float cCollinearEpsilon = 0.0001f;

	/// The SIGNED area: positive counter clockwise, negative clockwise.
	///
	/// The sign is what everything downstream reads. Ear clipping only works on one
	/// winding, and the triangle order that faces the viewer depends on it.
	public static float PolygonArea(Span<Float2> contour)
	{
		var area = 0.0f;
		let n = contour.Length;
		for (int i = 0; i < n; i++)
		{
			let j = (i + 1) % n;
			area += contour[i].X * contour[j].Y;
			area -= contour[j].X * contour[i].Y;
		}
		return area * 0.5f;
	}

	/// Whether a point is inside a triangle, boundary included.
	///
	/// Inclusive on purpose: a vertex lying exactly on an ear's edge still blocks the clip,
	/// because cutting it would leave that vertex stranded outside the remaining polygon.
	public static bool PointInTriangle(Float2 p, Float2 a, Float2 b, Float2 c)
	{
		let d1 = Sign(p, a, b);
		let d2 = Sign(p, b, c);
		let d3 = Sign(p, c, a);

		let hasNegative = (d1 < 0.0f) || (d2 < 0.0f) || (d3 < 0.0f);
		let hasPositive = (d1 > 0.0f) || (d2 > 0.0f) || (d3 > 0.0f);
		return !(hasNegative && hasPositive);
	}

	/// Whether the corner at the middle point turns left, which is convex for a counter
	/// clockwise contour.
	public static bool IsConvex(Float2 p0, Float2 p1, Float2 p2) => Cross(p1 - p0, p2 - p0) > 0.0f;

	/// Triangulates a simple polygon, appending indices offset by `baseIndex`.
	public static void Triangulate(Span<Float2> contour, FillRule fillRule, List<uint32> indices,
		uint32 baseIndex = 0)
	{
		let n = contour.Length;
		if (n < 3)
			return;

		// A convex polygon needs no ear search at all: every fan triangle is inside it.
		// Most shapes that reach here are convex, so this is the path that matters.
		if (IsConvexPolygon(contour))
		{
			FanTriangulate(n, PolygonArea(contour) > 0.0f, indices, baseIndex);
			return;
		}

		// Ear clipping works on ONE winding, so a clockwise contour is walked backwards
		// rather than being copied and reversed.
		let remaining = scope List<int>();
		if (PolygonArea(contour) > 0.0f)
		{
			for (int i = 0; i < n; i++)
				remaining.Add(i);
		}
		else
		{
			for (int i = n - 1; i >= 0; i--)
				remaining.Add(i);
		}

		var failures = 0;
		var cursor = 0;

		while (remaining.Count > 2)
		{
			let count = remaining.Count;

			// A full pass with no ear found means the polygon is not simple: it
			// self intersects, or its points are degenerate. A fan over what is left is
			// wrong in detail but bounded, and covers roughly the right area; refusing
			// would drop the shape entirely.
			if (failures >= count)
			{
				for (int k = 1; k < (count - 1); k++)
				{
					indices.Add(baseIndex + (uint32)remaining[0]);
					indices.Add(baseIndex + (uint32)remaining[k]);
					indices.Add(baseIndex + (uint32)remaining[k + 1]);
				}
				break;
			}

			let previousSlot = (cursor + count - 1) % count;
			let currentSlot = cursor % count;
			let nextSlot = (cursor + 1) % count;

			let previous = remaining[previousSlot];
			let current = remaining[currentSlot];
			let next = remaining[nextSlot];

			if (IsEarTip(contour[previous], contour[current], contour[next], contour, remaining,
				currentSlot))
			{
				indices.Add(baseIndex + (uint32)previous);
				indices.Add(baseIndex + (uint32)current);
				indices.Add(baseIndex + (uint32)next);

				remaining.RemoveAt(currentSlot);
				failures = 0;

				// The cursor STAYS put: the next vertex has shifted into this slot, and
				// re-testing here is what lets a run of ears clip consecutively.
				if (cursor >= remaining.Count)
					cursor = 0;
			}
			else
			{
				cursor = (cursor + 1) % remaining.Count;
				failures++;
			}
		}
	}

	/// Triangulates a polygon with holes, bridging each hole into the outer contour.
	///
	/// The merged vertices are appended to `mergedVertices`, because bridging INTRODUCES
	/// vertices: a bridge visits the same point twice, so the indices no longer refer to
	/// the caller's own points.
	public static void TriangulateWithHoles(Span<Float2> outer, Span<Span<Float2>> holes,
		FillRule fillRule, List<uint32> indices, List<Float2> mergedVertices)
	{
		if (outer.Length < 3)
			return;

		let baseIndex = (uint32)mergedVertices.Count;

		if (holes.IsEmpty)
		{
			mergedVertices.AddRange(outer);
			Triangulate(.(mergedVertices.Ptr + baseIndex, outer.Length), fillRule, indices,
				baseIndex);
			return;
		}

		let merged = scope List<Float2>();
		merged.AddRange(outer);

		// Bridged RIGHTMOST first. A bridge is a corridor cut through the polygon, and
		// cutting from the right means each later hole still sees an unbroken path to the
		// outside rather than having to cross a corridor already cut.
		let order = scope List<int>();
		for (int i = 0; i < holes.Length; i++)
			order.Add(i);

		for (int a = 1; a < order.Count; a++)
		{
			let key = order[a];
			let keyMaxX = MaxX(holes[key]);
			var b = a;
			while ((b > 0) && (MaxX(holes[order[b - 1]]) < keyMaxX))
			{
				order[b] = order[b - 1];
				b--;
			}
			order[b] = key;
		}

		for (let index in order)
			MergeHole(merged, holes[index]);

		mergedVertices.AddRange(merged);
		Triangulate(.(mergedVertices.Ptr + baseIndex, merged.Count), fillRule, indices, baseIndex);
	}

	private static void FanTriangulate(int n, bool counterClockwise, List<uint32> indices,
		uint32 baseIndex)
	{
		for (int i = 1; i < (n - 1); i++)
		{
			indices.Add(baseIndex);
			// A clockwise contour emits its triangles the other way round, so every
			// triangle this produces faces the same way whatever the input winding was.
			if (counterClockwise)
			{
				indices.Add(baseIndex + (uint32)i);
				indices.Add(baseIndex + (uint32)(i + 1));
			}
			else
			{
				indices.Add(baseIndex + (uint32)(i + 1));
				indices.Add(baseIndex + (uint32)i);
			}
		}
	}

	private static float Sign(Float2 p1, Float2 p2, Float2 p3)
		=> ((p1.X - p3.X) * (p2.Y - p3.Y)) - ((p2.X - p3.X) * (p1.Y - p3.Y));

	private static float Cross(Float2 a, Float2 b) => (a.X * b.Y) - (a.Y * b.X);

	private static float MaxX(Span<Float2> points)
	{
		var maximum = -FloatMax;
		for (let point in points)
			maximum = Max(maximum, point.X);
		return maximum;
	}

	/// Whether every corner turns the same way.
	///
	/// Collinear corners are IGNORED rather than counted either way: a flattened curve
	/// produces plenty of them, and treating one as a turn would send an otherwise convex
	/// shape down the ear clipping path for nothing.
	private static bool IsConvexPolygon(Span<Float2> contour)
	{
		let n = contour.Length;
		if (n < 3)
			return false;

		var gotPositive = false;
		var gotNegative = false;

		for (int i = 0; i < n; i++)
		{
			let p0 = contour[i];
			let p1 = contour[(i + 1) % n];
			let p2 = contour[(i + 2) % n];
			let cross = Cross(p1 - p0, p2 - p1);

			if (cross > cCollinearEpsilon)
				gotPositive = true;
			if (cross < -cCollinearEpsilon)
				gotNegative = true;
			if (gotPositive && gotNegative)
				return false;
		}
		return true;
	}

	/// Whether the corner at `currentSlot` can be cut off: convex, and with no other
	/// vertex of the polygon inside the triangle it would remove.
	private static bool IsEarTip(Float2 previous, Float2 current, Float2 next, Span<Float2> contour,
		List<int> remaining, int currentSlot)
	{
		// A reflex corner cuts away area OUTSIDE the polygon.
		if (Cross(current - previous, next - previous) <= 0.0f)
			return false;

		let count = remaining.Count;
		for (int i = 0; i < count; i++)
		{
			// The ear's own three corners are not obstacles to themselves.
			if ((i == currentSlot) || (i == ((currentSlot + count - 1) % count))
				|| (i == ((currentSlot + 1) % count)))
				continue;

			let point = contour[remaining[i]];

			// A DUPLICATE of one of the ear's corners would test as inside and block the
			// clip forever. Flattening can leave these behind, so they are skipped.
			if (((point.X == previous.X) && (point.Y == previous.Y))
				|| ((point.X == current.X) && (point.Y == current.Y))
				|| ((point.X == next.X) && (point.Y == next.Y)))
				continue;

			if (PointInTriangle(point, previous, current, next))
				return false;
		}
		return true;
	}

	/// Cuts a corridor from the outer contour to a hole, so the two become one contour that
	/// ear clipping can handle.
	private static void MergeHole(List<Float2> outer, Span<Float2> hole)
	{
		if (hole.IsEmpty)
			return;

		// The hole's RIGHTMOST point, which is the one with the clearest line out: to its
		// right there is only outer contour.
		var rightmost = 0;
		for (int i = 1; i < hole.Length; i++)
		{
			if (hole[i].X > hole[rightmost].X)
				rightmost = i;
		}

		let holePoint = hole[rightmost];

		// The nearest outer vertex, which keeps the corridor short and so less likely to
		// cross anything.
		var bestOuter = 0;
		var bestDistance = FloatMax;
		for (int i = 0; i < outer.Count; i++)
		{
			let distance = DistanceSquared(holePoint, outer[i]);
			if (distance >= bestDistance)
				continue;
			bestDistance = distance;
			bestOuter = i;
		}

		// The hole walked from its rightmost point all the way round and back to it, then
		// back along the corridor to the outer vertex. Both endpoints appear twice, which
		// is what makes the corridor zero width and invisible.
		let bridged = scope List<Float2>();
		for (int i = 0; i <= hole.Length; i++)
			bridged.Add(hole[(rightmost + i) % hole.Length]);
		bridged.Add(outer[bestOuter]);

		outer.Insert(bestOuter + 1, bridged);
	}
}
