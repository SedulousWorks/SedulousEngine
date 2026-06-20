using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// Tessellates stroked polylines into triangle meshes with joins and caps
public static class StrokeTessellator
{
	/// Tessellate a stroked polyline
	public static void Tessellate(Span<Vector2> points, bool closed, StrokeStyle style, Span<float> dashPattern,
		bool antiAlias, Color color, List<VGVertex> vertices, List<uint32> indices)
	{
		if (points.Length < 2)
			return;

		// Apply dashing if pattern is provided
		if (dashPattern.Length >= 2)
		{
			let dashSegments = scope List<List<Vector2>>();
			DashGenerator.GenerateDashes(points, closed, dashPattern, style.DashOffset, dashSegments);
			defer { for (let seg in dashSegments) delete seg; }

			for (let seg in dashSegments)
			{
				if (seg.Count >= 2)
					TessellateSegment(seg, false, style, antiAlias, color, vertices, indices);
			}
			return;
		}

		// No dashing - tessellate directly
		let pointList = scope List<Vector2>();
		for (let p in points)
			pointList.Add(p);
		TessellateSegment(pointList, closed, style, antiAlias, color, vertices, indices);
	}

	private static void TessellateSegment(List<Vector2> points, bool closed, StrokeStyle style,
		bool antiAlias, Color color, List<VGVertex> vertices, List<uint32> indices)
	{
		let n = points.Count;
		if (n < 2)
			return;

		let fringeWidth = antiAlias ? 0.75f : 0.0f;
		let halfWidth = style.Width * 0.5f;

		// Pre-compute edge directions, normals, and lengths
		let edgeCount = closed ? n : n - 1;
		Vector2[] edgeDirs = scope Vector2[edgeCount];
		Vector2[] edgeNormals = scope Vector2[edgeCount];
		float[] edgeLens = scope float[edgeCount];
		for (int i = 0; i < edgeCount; i++)
		{
			let p0 = points[i];
			let p1 = points[(i + 1) % n];
			var dir = p1 - p0;
			let len = dir.Length();
			edgeLens[i] = len;
			if (len > 0.0001f)
			{
				dir = dir / len;
				edgeDirs[i] = dir;
				edgeNormals[i] = .(-dir.Y, dir.X);
			}
			else
			{
				edgeDirs[i] = .(0, 0);
				edgeNormals[i] = .(0, 1);
			}
		}

		// Compute per-vertex miter-scaled normals and unit normals (for fringe)
		Vector2[] vertNormals = scope Vector2[n];   // miter-scaled
		Vector2[] unitNormals = scope Vector2[n];    // unit length (for fixed-width fringe)
		for (int i = 0; i < n; i++)
		{
			if (closed)
			{
				let prevEdge = (i + edgeCount - 1) % edgeCount;
				let nextEdge = i % edgeCount;
				let minLen = Math.Min(edgeLens[prevEdge], edgeLens[nextEdge]);
				ComputeJoinNormal(edgeNormals[prevEdge], edgeNormals[nextEdge], style, halfWidth, minLen,
					out vertNormals[i], out unitNormals[i]);
			}
			else if (i == 0)
			{
				vertNormals[i] = edgeNormals[0];
				unitNormals[i] = edgeNormals[0];
			}
			else if (i == n - 1)
			{
				vertNormals[i] = edgeNormals[edgeCount - 1];
				unitNormals[i] = edgeNormals[edgeCount - 1];
			}
			else
			{
				let minLen = Math.Min(edgeLens[i - 1], edgeLens[i]);
				ComputeJoinNormal(edgeNormals[i - 1], edgeNormals[i], style, halfWidth, minLen,
					out vertNormals[i], out unitNormals[i]);
			}
		}

		// Determine which vertices need bevel/round joins
		bool[] needsJoin = scope bool[n];
		if (style.Join != .Miter)
		{
			for (int i = 0; i < n; i++)
			{
				bool isJoinVertex = closed || (i > 0 && i < n - 1);
				if (!isJoinVertex) continue;

				let prevEdge = closed ? (i + edgeCount - 1) % edgeCount : i - 1;
				let nextEdge = closed ? i % edgeCount : i;
				if (prevEdge < 0 || nextEdge >= edgeCount) continue;

				let cross = edgeNormals[prevEdge].X * edgeNormals[nextEdge].Y -
					edgeNormals[prevEdge].Y * edgeNormals[nextEdge].X;
				// Only add join geometry at visible corners (not near-parallel edges)
				needsJoin[i] = Math.Abs(cross) >= 0.001f;
			}
		}

		if (antiAlias)
		{
			// With AA: create 4 vertex rings
			// Fringe uses unitNormals (fixed pixel width), body uses vertNormals (miter-scaled)
			let transColor = Color(color.R, color.G, color.B, 0);

			// Ring 0: outer fringe (left side, coverage=0)
			let outerLeftBase = (uint32)vertices.Count;
			for (int i = 0; i < n; i++)
			{
				let p = points[i];
				let bodyOffset = vertNormals[i] * halfWidth;
				let fringeOffset = unitNormals[i] * fringeWidth;
				vertices.Add(.Solid(p + bodyOffset + fringeOffset, transColor, 0.0f));
			}

			// Ring 1: stroke left edge (coverage=1)
			let strokeLeftBase = (uint32)vertices.Count;
			for (int i = 0; i < n; i++)
			{
				let p = points[i];
				let offset = vertNormals[i] * halfWidth;
				vertices.Add(.Solid(p + offset, color, 1.0f));
			}

			// Ring 2: stroke right edge (coverage=1)
			let strokeRightBase = (uint32)vertices.Count;
			for (int i = 0; i < n; i++)
			{
				let p = points[i];
				let offset = vertNormals[i] * halfWidth;
				vertices.Add(.Solid(p - offset, color, 1.0f));
			}

			// Ring 3: outer fringe (right side, coverage=0)
			let outerRightBase = (uint32)vertices.Count;
			for (int i = 0; i < n; i++)
			{
				let p = points[i];
				let bodyOffset = vertNormals[i] * halfWidth;
				let fringeOffset = unitNormals[i] * fringeWidth;
				vertices.Add(.Solid(p - bodyOffset - fringeOffset, transColor, 0.0f));
			}

			// Connect rings with quad strips
			let segCount = closed ? n : n - 1;
			for (int i = 0; i < segCount; i++)
			{
				let j = (i + 1) % n;
				let ui = (uint32)i;
				let uj = (uint32)j;

				// Left fringe: outerLeft -> strokeLeft
				indices.Add(outerLeftBase + ui); indices.Add(outerLeftBase + uj); indices.Add(strokeLeftBase + uj);
				indices.Add(outerLeftBase + ui); indices.Add(strokeLeftBase + uj); indices.Add(strokeLeftBase + ui);

				// Stroke body: strokeLeft -> strokeRight
				indices.Add(strokeLeftBase + ui); indices.Add(strokeLeftBase + uj); indices.Add(strokeRightBase + uj);
				indices.Add(strokeLeftBase + ui); indices.Add(strokeRightBase + uj); indices.Add(strokeRightBase + ui);

				// Right fringe: strokeRight -> outerRight
				indices.Add(strokeRightBase + ui); indices.Add(strokeRightBase + uj); indices.Add(outerRightBase + uj);
				indices.Add(strokeRightBase + ui); indices.Add(outerRightBase + uj); indices.Add(outerRightBase + ui);
			}
		}
		else
		{
			// Without AA: simple left/right quad strip
			let strokeBase = (uint32)vertices.Count;
			for (int i = 0; i < n; i++)
			{
				let p = points[i];
				let offset = vertNormals[i] * halfWidth;
				vertices.Add(.Solid(p + offset, color));
				vertices.Add(.Solid(p - offset, color));
			}

			let segCount = closed ? n : n - 1;
			for (int i = 0; i < segCount; i++)
			{
				let j = (i + 1) % n;
				let i0 = strokeBase + (uint32)(i * 2);
				let i1 = strokeBase + (uint32)(i * 2 + 1);
				let i2 = strokeBase + (uint32)(j * 2);
				let i3 = strokeBase + (uint32)(j * 2 + 1);

				indices.Add(i0); indices.Add(i2); indices.Add(i1);
				indices.Add(i1); indices.Add(i2); indices.Add(i3);
			}
		}

		// Add joins at vertices that need them
		for (int i = 0; i < n; i++)
		{
			if (!needsJoin[i]) continue;

			let prevEdge = closed ? (i + edgeCount - 1) % edgeCount : i - 1;
			let nextEdge = closed ? i % edgeCount : i;

			AddJoin(points[i], edgeNormals[prevEdge], edgeNormals[nextEdge], halfWidth, style.Join, color, vertices, indices);
		}

		// Add caps for open paths
		if (!closed && style.Cap != .Butt)
		{
			// Start cap
			{
				var dir = points[1] - points[0];
				let len = dir.Length();
				if (len > 0.0001f)
				{
					dir = dir / len;
					AddCap(points[0], -dir, edgeNormals[0], halfWidth, style.Cap, color, vertices, indices);
				}
			}
			// End cap
			{
				var dir = points[n - 1] - points[n - 2];
				let len = dir.Length();
				if (len > 0.0001f)
				{
					dir = dir / len;
					AddCap(points[n - 1], dir, edgeNormals[edgeCount - 1], halfWidth, style.Cap, color, vertices, indices);
				}
			}
		}
	}

	/// Compute miter-scaled and unit normals for a join vertex.
	/// minEdgeLen is the shorter of the two adjacent edges (for inner bevel clamping).
	private static void ComputeJoinNormal(Vector2 prevNormal, Vector2 nextNormal,
		StrokeStyle style, float halfWidth, float minEdgeLen,
		out Vector2 miterNormal, out Vector2 unitNormal)
	{
		var avg = (prevNormal + nextNormal) * 0.5f;
		let len = avg.Length();
		if (len < 0.0001f)
		{
			miterNormal = prevNormal;
			unitNormal = prevNormal;
			return;
		}

		avg = avg / len;
		unitNormal = avg;

		let dot = prevNormal.X * avg.X + prevNormal.Y * avg.Y;
		if (dot > 0.0001f)
		{
			var miterLen = 1.0f / dot;

			// Clamp to prevent extreme miter spikes
			miterLen = Math.Min(miterLen, 600.0f);

			// Inner bevel: if miter extends beyond the shorter adjacent edge, clamp
			if (minEdgeLen > 0.0001f)
			{
				let limit = Math.Max(1.01f, minEdgeLen / halfWidth);
				if (miterLen > limit)
					miterLen = limit;
			}

			if (miterLen > style.MiterLimit && style.Join == .Miter)
			{
				miterNormal = avg;
				return;
			}

			miterNormal = avg * miterLen;
			return;
		}

		miterNormal = prevNormal;
		unitNormal = prevNormal;
	}

	private static void AddJoin(Vector2 point, Vector2 prevNormal, Vector2 nextNormal, float halfWidth,
		VGLineJoin joinType, Color color, List<VGVertex> vertices, List<uint32> indices)
	{
		let cross = prevNormal.X * nextNormal.Y - prevNormal.Y * nextNormal.X;
		if (Math.Abs(cross) < 0.001f)
			return;

		if (joinType == .Bevel)
		{
			let baseIdx = (uint32)vertices.Count;
			vertices.Add(.Solid(point, color));

			if (cross > 0)
			{
				vertices.Add(.Solid(point + prevNormal * halfWidth, color));
				vertices.Add(.Solid(point + nextNormal * halfWidth, color));
			}
			else
			{
				vertices.Add(.Solid(point - prevNormal * halfWidth, color));
				vertices.Add(.Solid(point - nextNormal * halfWidth, color));
			}

			indices.Add(baseIdx);
			indices.Add(baseIdx + 1);
			indices.Add(baseIdx + 2);
		}
		else if (joinType == .Round)
		{
			let startAngle = Math.Atan2(prevNormal.Y, prevNormal.X);
			var endAngle = Math.Atan2(nextNormal.Y, nextNormal.X);

			if (cross > 0)
			{
				if (endAngle < startAngle) endAngle += Math.PI_f * 2.0f;
			}
			else
			{
				if (endAngle > startAngle) endAngle -= Math.PI_f * 2.0f;
			}

			let segments = Math.Max(3, (int32)(Math.Abs(endAngle - startAngle) * halfWidth * 0.5f));
			let angleStep = (float)(endAngle - startAngle) / segments;

			let baseIdx = (uint32)vertices.Count;
			vertices.Add(.Solid(point, color));

			for (int i = 0; i <= segments; i++)
			{
				let angle = (float)startAngle + angleStep * i;
				let x = point.X + Math.Cos(angle) * halfWidth;
				let y = point.Y + Math.Sin(angle) * halfWidth;
				vertices.Add(.Solid(x, y, color));
			}

			for (int i = 0; i < segments; i++)
			{
				indices.Add(baseIdx);
				indices.Add(baseIdx + (uint32)(i + 1));
				indices.Add(baseIdx + (uint32)(i + 2));
			}
		}
	}

	private static void AddCap(Vector2 point, Vector2 direction, Vector2 normal, float halfWidth,
		VGLineCap capType, Color color, List<VGVertex> vertices, List<uint32> indices)
	{
		if (capType == .Square)
		{
			let baseIdx = (uint32)vertices.Count;
			let p0 = point - normal * halfWidth;
			let p1 = point + normal * halfWidth;
			let p2 = point + direction * halfWidth + normal * halfWidth;
			let p3 = point + direction * halfWidth - normal * halfWidth;

			vertices.Add(.Solid(p0, color));
			vertices.Add(.Solid(p1, color));
			vertices.Add(.Solid(p2, color));
			vertices.Add(.Solid(p3, color));

			indices.Add(baseIdx + 0);
			indices.Add(baseIdx + 1);
			indices.Add(baseIdx + 2);
			indices.Add(baseIdx + 0);
			indices.Add(baseIdx + 2);
			indices.Add(baseIdx + 3);
		}
		else if (capType == .Round)
		{
			let segments = Math.Max(4, (int32)(halfWidth * 0.5f));
			let baseIdx = (uint32)vertices.Count;

			vertices.Add(.Solid(point, color));

			let startAngle = Math.Atan2(normal.Y, normal.X);
			let angleStep = Math.PI_f / segments;

			for (int i = 0; i <= segments; i++)
			{
				let angle = (float)startAngle + i * angleStep;
				let x = point.X + Math.Cos(angle) * halfWidth;
				let y = point.Y + Math.Sin(angle) * halfWidth;
				vertices.Add(.Solid(x, y, color));
			}

			for (int i = 0; i < segments; i++)
			{
				indices.Add(baseIdx);
				indices.Add(baseIdx + (uint32)(i + 1));
				indices.Add(baseIdx + (uint32)(i + 2));
			}
		}
	}
}
