using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// Tessellates filled paths into triangle meshes
public static class FillTessellator
{
	/// Tessellate a filled path into vertices and indices
	public static void Tessellate(Path path, FillRule fillRule, Color color, bool antiAlias, List<VGVertex> vertices, List<uint32> indices, float tolerance = 0.25f)
	{
		// Flatten path to polylines
		let subPaths = scope List<FlattenedSubPath>();
		PathFlattener.Flatten(path, tolerance, subPaths);
		defer { for (let sp in subPaths) delete sp; }

		if (subPaths.Count == 0)
			return;

		for (let subPath in subPaths)
		{
			if (subPath.Points.Count < 3)
				continue;

			var pointCount = subPath.Points.Count;
			if (pointCount > 1 && Vector2.Distance(subPath.Points[0], subPath.Points[pointCount - 1]) < 0.0001f)
				pointCount--;

			if (pointCount < 3)
				continue;

			let points = Span<Vector2>(subPath.Points.Ptr, pointCount);

			if (antiAlias)
			{
				// With AA: inset the fill polygon by half the fringe width, then add fringe ring
				TessellateWithAA(points, fillRule, color, vertices, indices);
			}
			else
			{
				let baseIndex = (uint32)vertices.Count;
				for (int i = 0; i < pointCount; i++)
					vertices.Add(.Solid(points[i], color));
				Triangulator.Triangulate(points, fillRule, indices, baseIndex);
			}
		}
	}

	/// Tessellate a filled path with an IVGFill style
	public static void TessellateWithFill(Path path, FillRule fillRule, IVGFill fill, bool antiAlias, List<VGVertex> vertices, List<uint32> indices, float tolerance = 0.25f)
	{
		if (!fill.RequiresInterpolation)
		{
			Tessellate(path, fillRule, fill.BaseColor, antiAlias, vertices, indices, tolerance);
			return;
		}

		let bounds = path.GetBounds();

		let subPaths = scope List<FlattenedSubPath>();
		PathFlattener.Flatten(path, tolerance, subPaths);
		defer { for (let sp in subPaths) delete sp; }

		if (subPaths.Count == 0)
			return;

		for (let subPath in subPaths)
		{
			if (subPath.Points.Count < 3)
				continue;

			var pointCount = subPath.Points.Count;
			if (pointCount > 1 && Vector2.Distance(subPath.Points[0], subPath.Points[pointCount - 1]) < 0.0001f)
				pointCount--;

			if (pointCount < 3)
				continue;

			let points = Span<Vector2>(subPath.Points.Ptr, pointCount);

			if (antiAlias)
			{
				TessellateWithAAFill(points, fillRule, fill, bounds, vertices, indices);
			}
			else
			{
				let baseIndex = (uint32)vertices.Count;
				for (int i = 0; i < pointCount; i++)
					vertices.Add(.Solid(points[i], fill.GetColorAt(points[i], bounds)));
				Triangulator.Triangulate(points, fillRule, indices, baseIndex);
			}
		}
	}

	/// Tessellate with connected AA fringe ring
	private static void TessellateWithAA(Span<Vector2> points, FillRule fillRule, Color color, List<VGVertex> vertices, List<uint32> indices)
	{
		let n = points.Length;
		let fringeWidth = 0.75f;

		// Determine winding to get correct outward normal direction
		let area = Triangulator.PolygonArea(points);
		let sign = (area > 0) ? 1.0f : -1.0f; // CCW = positive area

		// Compute per-vertex averaged outward normals
		Vector2[] normals = scope Vector2[n];
		for (int i = 0; i < n; i++)
		{
			let prev = (i + n - 1) % n;
			let next = (i + 1) % n;

			// Edge normals for the two edges meeting at this vertex
			var e0 = points[i] - points[prev];
			var e1 = points[next] - points[i];
			let len0 = e0.Length();
			let len1 = e1.Length();

			if (len0 > 0.0001f) e0 = e0 / len0;
			if (len1 > 0.0001f) e1 = e1 / len1;

			// Outward normals (perpendicular to edge, direction based on winding)
			let n0 = Vector2(e0.Y, -e0.X) * sign;
			let n1 = Vector2(e1.Y, -e1.X) * sign;

			// Average and normalize
			var avg = (n0 + n1) * 0.5f;
			let avgLen = avg.Length();
			if (avgLen > 0.0001f)
			{
				avg = avg / avgLen;
				// Scale to maintain consistent fringe width at corners (miter-like)
				// Clamp to prevent extreme normals at sharp concave angles
				let dot = n0.X * avg.X + n0.Y * avg.Y;
				if (dot > 0.1f)
				{
					let scale = Math.Min(1.0f / dot, 3.0f);
					avg = avg * scale;
				}
			}
			else
			{
				avg = n0;
			}

			normals[i] = avg;
		}

		// Create inner ring (inset by half fringe) and outer ring (offset by half fringe)
		let innerBaseIdx = (uint32)vertices.Count;

		// Inner ring vertices (full opacity, coverage = 1)
		Vector2[] innerPoints = scope Vector2[n];
		for (int i = 0; i < n; i++)
		{
			innerPoints[i] = points[i] - normals[i] * (fringeWidth * 0.5f);
			vertices.Add(.Solid(innerPoints[i], color, 1.0f));
		}

		// Triangulate the inner polygon
		Triangulator.Triangulate(Span<Vector2>(innerPoints.CArray(), n), fillRule, indices, innerBaseIdx);

		// Outer ring vertices (zero opacity, coverage = 0)
		let outerBaseIdx = (uint32)vertices.Count;
		let transColor = Color(color.R, color.G, color.B, 0);
		for (int i = 0; i < n; i++)
		{
			let outerPt = points[i] + normals[i] * (fringeWidth * 0.5f);
			vertices.Add(.Solid(outerPt, transColor, 0.0f));
		}

		// Connect inner and outer rings with a quad strip
		for (int i = 0; i < n; i++)
		{
			let j = (i + 1) % n;
			let i0 = innerBaseIdx + (uint32)i;
			let i1 = innerBaseIdx + (uint32)j;
			let o0 = outerBaseIdx + (uint32)i;
			let o1 = outerBaseIdx + (uint32)j;

			indices.Add(i0); indices.Add(i1); indices.Add(o1);
			indices.Add(i0); indices.Add(o1); indices.Add(o0);
		}
	}

	/// Tessellate with connected AA fringe ring using fill style
	private static void TessellateWithAAFill(Span<Vector2> points, FillRule fillRule, IVGFill fill, RectangleF bounds, List<VGVertex> vertices, List<uint32> indices)
	{
		let n = points.Length;
		let fringeWidth = 0.75f;

		let area = Triangulator.PolygonArea(points);
		let sign = (area > 0) ? 1.0f : -1.0f;

		Vector2[] normals = scope Vector2[n];
		for (int i = 0; i < n; i++)
		{
			let prev = (i + n - 1) % n;
			let next = (i + 1) % n;

			var e0 = points[i] - points[prev];
			var e1 = points[next] - points[i];
			let len0 = e0.Length();
			let len1 = e1.Length();

			if (len0 > 0.0001f) e0 = e0 / len0;
			if (len1 > 0.0001f) e1 = e1 / len1;

			let n0 = Vector2(e0.Y, -e0.X) * sign;
			let n1 = Vector2(e1.Y, -e1.X) * sign;

			var avg = (n0 + n1) * 0.5f;
			let avgLen = avg.Length();
			if (avgLen > 0.0001f)
			{
				avg = avg / avgLen;
				let dot = n0.X * avg.X + n0.Y * avg.Y;
				if (dot > 0.1f)
				{
					let scale = Math.Min(1.0f / dot, 3.0f);
					avg = avg * scale;
				}
			}
			else
			{
				avg = n0;
			}

			normals[i] = avg;
		}

		let innerBaseIdx = (uint32)vertices.Count;

		Vector2[] innerPoints = scope Vector2[n];
		for (int i = 0; i < n; i++)
		{
			innerPoints[i] = points[i] - normals[i] * (fringeWidth * 0.5f);
			let fillColor = fill.GetColorAt(points[i], bounds);
			vertices.Add(.Solid(innerPoints[i], fillColor, 1.0f));
		}

		Triangulator.Triangulate(Span<Vector2>(innerPoints.CArray(), n), fillRule, indices, innerBaseIdx);

		let outerBaseIdx = (uint32)vertices.Count;
		for (int i = 0; i < n; i++)
		{
			let outerPt = points[i] + normals[i] * (fringeWidth * 0.5f);
			let fillColor = fill.GetColorAt(points[i], bounds);
			vertices.Add(.Solid(outerPt, Color(fillColor.R, fillColor.G, fillColor.B, 0), 0.0f));
		}

		for (int i = 0; i < n; i++)
		{
			let j = (i + 1) % n;
			let i0 = innerBaseIdx + (uint32)i;
			let i1 = innerBaseIdx + (uint32)j;
			let o0 = outerBaseIdx + (uint32)i;
			let o1 = outerBaseIdx + (uint32)j;

			indices.Add(i0); indices.Add(i1); indices.Add(o1);
			indices.Add(i0); indices.Add(o1); indices.Add(o0);
		}
	}
}
