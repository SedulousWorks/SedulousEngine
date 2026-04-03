using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// Triangulates polygons using ear-clipping algorithm
public static class Triangulator
{
	/// Compute the signed area of a polygon.
	/// Positive = counter-clockwise, Negative = clockwise.
	public static float PolygonArea(Span<Vector2> contour)
	{
		float area = 0;
		let n = contour.Length;
		for (int i = 0; i < n; i++)
		{
			let j = (i + 1) % n;
			area += contour[i].X * contour[j].Y;
			area -= contour[j].X * contour[i].Y;
		}
		return area * 0.5f;
	}

	/// Check if point is inside triangle using barycentric coordinates
	public static bool PointInTriangle(Vector2 p, Vector2 a, Vector2 b, Vector2 c)
	{
		let d1 = Sign(p, a, b);
		let d2 = Sign(p, b, c);
		let d3 = Sign(p, c, a);

		let hasNeg = (d1 < 0) || (d2 < 0) || (d3 < 0);
		let hasPos = (d1 > 0) || (d2 > 0) || (d3 > 0);

		return !(hasNeg && hasPos);
	}

	/// Check if a triangle (p0, p1, p2) has a convex angle at p1 given a CCW winding
	public static bool IsConvex(Vector2 p0, Vector2 p1, Vector2 p2)
	{
		return Cross(p1 - p0, p2 - p0) > 0;
	}

	/// Triangulate a simple polygon using ear-clipping.
	/// Indices are appended to the output list using baseIndex as the vertex offset.
	public static void Triangulate(Span<Vector2> contour, FillRule fillRule, List<uint32> indices, uint32 baseIndex = 0)
	{
		let n = contour.Length;
		if (n < 3)
			return;

		// For convex polygons, use simple fan (fast path)
		if (IsConvexPolygon(contour))
		{
			// Determine winding — fan from vertex 0
			let area = PolygonArea(contour);
			if (area > 0)
			{
				// CCW
				for (int i = 1; i < n - 1; i++)
				{
					indices.Add(baseIndex);
					indices.Add(baseIndex + (uint32)i);
					indices.Add(baseIndex + (uint32)(i + 1));
				}
			}
			else
			{
				// CW — reverse winding
				for (int i = 1; i < n - 1; i++)
				{
					indices.Add(baseIndex);
					indices.Add(baseIndex + (uint32)(i + 1));
					indices.Add(baseIndex + (uint32)i);
				}
			}
			return;
		}

		// Ear-clipping for concave polygons
		// Build a mutable index list
		let idxList = scope List<int>(n);

		let area = PolygonArea(contour);
		if (area > 0)
		{
			// CCW — keep order
			for (int i = 0; i < n; i++)
				idxList.Add(i);
		}
		else
		{
			// CW — reverse to CCW
			for (int i = n - 1; i >= 0; i--)
				idxList.Add(i);
		}

		var failCount = 0;
		var i = 0;

		while (idxList.Count > 2)
		{
			if (failCount >= idxList.Count)
			{
				// Degenerate — fallback to fan triangulation for remaining vertices
				for (int k = 1; k < idxList.Count - 1; k++)
				{
					indices.Add(baseIndex + (uint32)idxList[0]);
					indices.Add(baseIndex + (uint32)idxList[k]);
					indices.Add(baseIndex + (uint32)idxList[k + 1]);
				}
				break;
			}

			let count = idxList.Count;
			let iPrev = (i + count - 1) % count;
			let iCurr = i % count;
			let iNext = (i + 1) % count;

			let vPrev = idxList[iPrev];
			let vCurr = idxList[iCurr];
			let vNext = idxList[iNext];

			let pPrev = contour[vPrev];
			let pCurr = contour[vCurr];
			let pNext = contour[vNext];

			// Check if this is an ear
			if (IsEarTip(pPrev, pCurr, pNext, contour, idxList, iCurr))
			{
				indices.Add(baseIndex + (uint32)vPrev);
				indices.Add(baseIndex + (uint32)vCurr);
				indices.Add(baseIndex + (uint32)vNext);

				idxList.RemoveAt(iCurr);
				failCount = 0;

				// Stay at same index (next vertex shifted into current position)
				if (i >= idxList.Count)
					i = 0;
			}
			else
			{
				i = (i + 1) % idxList.Count;
				failCount++;
			}
		}
	}

	/// Triangulate a polygon with holes.
	public static void TriangulateWithHoles(Span<Vector2> outer, List<Span<Vector2>> holes, FillRule fillRule, List<uint32> indices, List<Vector2> mergedVertices)
	{
		if (outer.Length < 3)
			return;

		if (holes == null || holes.Count == 0)
		{
			let baseIndex = (uint32)mergedVertices.Count;
			for (let p in outer)
				mergedVertices.Add(p);
			Triangulate(Span<Vector2>(mergedVertices.Ptr + baseIndex, outer.Length), fillRule, indices, baseIndex);
			return;
		}

		let merged = scope List<Vector2>();
		for (let p in outer)
			merged.Add(p);

		let sortedHoles = scope List<int>();
		for (int i = 0; i < holes.Count; i++)
			sortedHoles.Add(i);

		sortedHoles.Sort(scope (a, b) =>
			{
				float maxXA = float.MinValue;
				for (let p in holes[a])
					if (p.X > maxXA) maxXA = p.X;
				float maxXB = float.MinValue;
				for (let p in holes[b])
					if (p.X > maxXB) maxXB = p.X;
				return maxXB <=> maxXA;
			});

		for (let holeIdx in sortedHoles)
		{
			let hole = holes[holeIdx];
			MergeHole(merged, hole);
		}

		let baseIndex = (uint32)mergedVertices.Count;
		for (let p in merged)
			mergedVertices.Add(p);
		Triangulate(Span<Vector2>(mergedVertices.Ptr + baseIndex, merged.Count), fillRule, indices, baseIndex);
	}

	// --- Private helpers ---

	private static float Sign(Vector2 p1, Vector2 p2, Vector2 p3)
	{
		return (p1.X - p3.X) * (p2.Y - p3.Y) - (p2.X - p3.X) * (p1.Y - p3.Y);
	}

	private static float Cross(Vector2 a, Vector2 b)
	{
		return a.X * b.Y - a.Y * b.X;
	}

	private static bool IsConvexPolygon(Span<Vector2> contour)
	{
		let n = contour.Length;
		if (n < 3) return false;

		bool gotPositive = false;
		bool gotNegative = false;

		for (int i = 0; i < n; i++)
		{
			let p0 = contour[i];
			let p1 = contour[(i + 1) % n];
			let p2 = contour[(i + 2) % n];
			let cross = Cross(p1 - p0, p2 - p1);

			if (cross > 0.0001f) gotPositive = true;
			if (cross < -0.0001f) gotNegative = true;

			if (gotPositive && gotNegative)
				return false;
		}

		return true;
	}

	private static bool IsEarTip(Vector2 pPrev, Vector2 pCurr, Vector2 pNext, Span<Vector2> contour, List<int> idxList, int currIdx)
	{
		// Must be convex (CCW winding)
		if (Cross(pCurr - pPrev, pNext - pPrev) <= 0)
			return false;

		// Check that no other vertex in the remaining polygon falls inside this triangle
		for (int i = 0; i < idxList.Count; i++)
		{
			if (i == currIdx)
				continue;
			if (i == (currIdx + idxList.Count - 1) % idxList.Count)
				continue;
			if (i == (currIdx + 1) % idxList.Count)
				continue;

			let p = contour[idxList[i]];

			// Skip if the point is one of the triangle vertices (can happen with duplicate points)
			if ((p.X == pPrev.X && p.Y == pPrev.Y) || (p.X == pCurr.X && p.Y == pCurr.Y) || (p.X == pNext.X && p.Y == pNext.Y))
				continue;

			if (PointInTriangle(p, pPrev, pCurr, pNext))
				return false;
		}

		return true;
	}

	private static void MergeHole(List<Vector2> outer, Span<Vector2> hole)
	{
		if (hole.Length == 0)
			return;

		int rightmostIdx = 0;
		for (int i = 1; i < hole.Length; i++)
		{
			if (hole[i].X > hole[rightmostIdx].X)
				rightmostIdx = i;
		}

		let holePoint = hole[rightmostIdx];

		int bestOuterIdx = 0;
		float bestDist = float.MaxValue;

		for (int i = 0; i < outer.Count; i++)
		{
			let dist = Vector2.DistanceSquared(holePoint, outer[i]);
			if (dist < bestDist)
			{
				bestDist = dist;
				bestOuterIdx = i;
			}
		}

		let insertPos = bestOuterIdx + 1;
		let bridgePoint = outer[bestOuterIdx];

		let holeVerts = scope List<Vector2>();
		for (int i = 0; i <= hole.Length; i++)
		{
			holeVerts.Add(hole[(rightmostIdx + i) % hole.Length]);
		}
		holeVerts.Add(bridgePoint);

		outer.Insert(insertPos, holeVerts);
	}
}
