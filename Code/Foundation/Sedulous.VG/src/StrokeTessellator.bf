using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.VG;

/// Turns polylines into stroke geometry, with joins, caps, dashing and an antialiased
/// fringe.
static class StrokeTessellator
{
	/// The antialiased fringe width, in pixels, matching the fill tessellator's.
	public const float FringeWidth = 0.75f;

	private const float cEpsilon = 0.0001f;

	/// Below this, two edge normals are parallel enough that a join would be invisible.
	private const float cJoinEpsilon = 0.001f;

	/// How far a miter may extend before it is clamped regardless of the style's limit.
	///
	/// Six hundred half widths is far past anything anyone would want, and exists so a
	/// nearly doubled back edge cannot throw a vertex to infinity.
	private const float cMiterHardLimit = 600.0f;

	/// Strokes a polyline.
	///
	/// A dash pattern of fewer than two elements is IGNORED rather than applied: one
	/// element never alternates, so it would draw solid anyway, and skipping the dash
	/// machinery entirely is cheaper.
	public static void Tessellate(Span<Float2> points, bool closed, StrokeStyle style,
		Span<float> dashPattern, bool antiAlias, Color color, List<VGVertex> vertices,
		List<uint32> indices, float fringeWidth = FringeWidth)
	{
		if (points.Length < 2)
			return;

		if (dashPattern.Length >= 2)
		{
			let dashes = scope List<List<Float2>>();
			defer { ClearAndDeleteItems!(dashes); }
			DashGenerator.GenerateDashes(points, closed, dashPattern, style.DashOffset, dashes);

			// Every dash is its own OPEN polyline, so each gets its own caps: that is what
			// makes a round dashed line look like a row of capsules.
			for (let dash in dashes)
			{
				if (dash.Count >= 2)
					TessellateSegment(dash, false, style, antiAlias, color, vertices, indices,
						fringeWidth);
			}
			return;
		}

		TessellateSegment(points, closed, style, antiAlias, color, vertices, indices, fringeWidth);
	}

	private static void TessellateSegment(Span<Float2> points, bool closed, StrokeStyle style,
		bool antiAlias, Color color, List<VGVertex> vertices, List<uint32> indices, float aaFringe)
	{
		let n = points.Length;
		if (n < 2)
			return;

		let fringeWidth = antiAlias ? aaFringe : 0.0f;
		let halfWidth = style.Width * 0.5f;

		// A closed polyline has one more edge than an open one: the closing edge.
		let edgeCount = closed ? n : (n - 1);

		let edgeDirections = scope List<Float2>();
		let edgeNormals = scope List<Float2>();
		let edgeLengths = scope List<float>();
		edgeDirections.Resize(edgeCount);
		edgeNormals.Resize(edgeCount);
		edgeLengths.Resize(edgeCount);

		for (int i = 0; i < edgeCount; i++)
		{
			var direction = points[(i + 1) % n] - points[i];
			let length = Length(direction);
			edgeLengths[i] = length;

			if (length > cEpsilon)
			{
				direction = direction / length;
				edgeDirections[i] = direction;
				edgeNormals[i] = .(-direction.Y, direction.X);
			}
			else
			{
				// A zero length edge has no direction. Straight up is arbitrary but
				// finite, which is all the following code needs.
				edgeDirections[i] = .Zero;
				edgeNormals[i] = .(0.0f, 1.0f);
			}
		}

		// Two normals per vertex: one scaled for the miter, which places the stroke edge,
		// and one of unit length, which places the fringe outside it.
		let vertexNormals = scope List<Float2>();
		let unitNormals = scope List<Float2>();
		vertexNormals.Resize(n);
		unitNormals.Resize(n);

		for (int i = 0; i < n; i++)
		{
			if (closed)
			{
				let previousEdge = (i + edgeCount - 1) % edgeCount;
				let nextEdge = i % edgeCount;
				ComputeJoinNormal(edgeNormals[previousEdge], edgeNormals[nextEdge], style,
					halfWidth, Min(edgeLengths[previousEdge], edgeLengths[nextEdge]),
					out vertexNormals[i], out unitNormals[i]);
			}
			else if (i == 0)
			{
				// An endpoint has only one edge, so there is no join to compute.
				vertexNormals[0] = edgeNormals[0];
				unitNormals[0] = edgeNormals[0];
			}
			else if (i == (n - 1))
			{
				vertexNormals[i] = edgeNormals[edgeCount - 1];
				unitNormals[i] = edgeNormals[edgeCount - 1];
			}
			else
			{
				ComputeJoinNormal(edgeNormals[i - 1], edgeNormals[i], style, halfWidth,
					Min(edgeLengths[i - 1], edgeLengths[i]), out vertexNormals[i],
					out unitNormals[i]);
			}
		}

		// Which corners get extra geometry. A miter join needs none: the scaled normal
		// already carries the corner.
		let needsJoin = scope List<bool>();
		needsJoin.Resize(n);
		if (style.Join != .Miter)
		{
			for (int i = 0; i < n; i++)
			{
				let isJoinVertex = closed || ((i > 0) && (i < (n - 1)));
				if (!isJoinVertex)
					continue;

				let previousEdge = closed ? ((i + edgeCount - 1) % edgeCount) : (i - 1);
				let nextEdge = closed ? (i % edgeCount) : i;
				if ((previousEdge < 0) || (nextEdge >= edgeCount))
					continue;

				let cross = (edgeNormals[previousEdge].X * edgeNormals[nextEdge].Y)
					- (edgeNormals[previousEdge].Y * edgeNormals[nextEdge].X);
				// Near parallel edges have no visible corner to fill.
				needsJoin[i] = Abs(cross) >= cJoinEpsilon;
			}
		}

		if (antiAlias)
			EmitAntiAliased(points, closed, halfWidth, fringeWidth, color, vertexNormals,
				unitNormals, vertices, indices);
		else
			EmitPlain(points, closed, halfWidth, color, vertexNormals, vertices, indices);

		for (int i = 0; i < n; i++)
		{
			if (!needsJoin[i])
				continue;

			let previousEdge = closed ? ((i + edgeCount - 1) % edgeCount) : (i - 1);
			let nextEdge = closed ? (i % edgeCount) : i;
			AddJoin(points[i], edgeNormals[previousEdge], edgeNormals[nextEdge], halfWidth,
				style.Join, color, vertices, indices);
		}

		// Only an open path has ends to cap, and a butt cap is the absence of geometry.
		if (closed || (style.Cap == .Butt))
			return;

		{
			var direction = points[1] - points[0];
			let length = Length(direction);
			if (length > cEpsilon)
			{
				direction = direction / length;
				// NEGATED: the start cap extends backwards, away from the line.
				AddCap(points[0], -direction, edgeNormals[0], halfWidth, style.Cap, color,
					vertices, indices);
			}
		}
		{
			var direction = points[n - 1] - points[n - 2];
			let length = Length(direction);
			if (length > cEpsilon)
			{
				direction = direction / length;
				AddCap(points[n - 1], direction, edgeNormals[edgeCount - 1], halfWidth, style.Cap,
					color, vertices, indices);
			}
		}
	}

	/// Four rings: a transparent fringe, the two stroke edges, and a transparent fringe on
	/// the other side. Three quad strips between them.
	private static void EmitAntiAliased(Span<Float2> points, bool closed, float halfWidth,
		float fringeWidth, Color color, List<Float2> vertexNormals, List<Float2> unitNormals,
		List<VGVertex> vertices, List<uint32> indices)
	{
		let n = points.Length;
		let transparent = Color(color.R, color.G, color.B, 0.0f);

		let outerLeftBase = (uint32)vertices.Count;
		for (int i = 0; i < n; i++)
		{
			// The fringe rides on the UNIT normal, so it keeps its width even where the
			// miter has stretched the body outward.
			let offset = (vertexNormals[i] * halfWidth) + (unitNormals[i] * fringeWidth);
			vertices.Add(VGVertex.Solid(points[i] + offset, transparent, 0.0f));
		}

		let strokeLeftBase = (uint32)vertices.Count;
		for (int i = 0; i < n; i++)
			vertices.Add(VGVertex.Solid(points[i] + (vertexNormals[i] * halfWidth), color, 1.0f));

		let strokeRightBase = (uint32)vertices.Count;
		for (int i = 0; i < n; i++)
			vertices.Add(VGVertex.Solid(points[i] - (vertexNormals[i] * halfWidth), color, 1.0f));

		let outerRightBase = (uint32)vertices.Count;
		for (int i = 0; i < n; i++)
		{
			let offset = (vertexNormals[i] * halfWidth) + (unitNormals[i] * fringeWidth);
			vertices.Add(VGVertex.Solid(points[i] - offset, transparent, 0.0f));
		}

		let segmentCount = closed ? n : (n - 1);
		for (int i = 0; i < segmentCount; i++)
		{
			let a = (uint32)i;
			let b = (uint32)((i + 1) % n);

			AddQuad(indices, outerLeftBase + a, outerLeftBase + b, strokeLeftBase + b,
				strokeLeftBase + a);
			AddQuad(indices, strokeLeftBase + a, strokeLeftBase + b, strokeRightBase + b,
				strokeRightBase + a);
			AddQuad(indices, strokeRightBase + a, strokeRightBase + b, outerRightBase + b,
				outerRightBase + a);
		}
	}

	/// One quad strip: the two stroke edges and nothing else.
	private static void EmitPlain(Span<Float2> points, bool closed, float halfWidth, Color color,
		List<Float2> vertexNormals, List<VGVertex> vertices, List<uint32> indices)
	{
		let n = points.Length;
		let strokeBase = (uint32)vertices.Count;

		// Interleaved, two per point, which is why the index arithmetic below doubles.
		for (int i = 0; i < n; i++)
		{
			let offset = vertexNormals[i] * halfWidth;
			vertices.Add(VGVertex.Solid(points[i] + offset, color));
			vertices.Add(VGVertex.Solid(points[i] - offset, color));
		}

		let segmentCount = closed ? n : (n - 1);
		for (int i = 0; i < segmentCount; i++)
		{
			let j = (i + 1) % n;
			let i0 = strokeBase + (uint32)(i * 2);
			let i1 = strokeBase + (uint32)((i * 2) + 1);
			let i2 = strokeBase + (uint32)(j * 2);
			let i3 = strokeBase + (uint32)((j * 2) + 1);

			indices.Add(i0);
			indices.Add(i2);
			indices.Add(i1);
			indices.Add(i1);
			indices.Add(i2);
			indices.Add(i3);
		}
	}

	private static void AddQuad(List<uint32> indices, uint32 a, uint32 b, uint32 c, uint32 d)
	{
		indices.Add(a);
		indices.Add(b);
		indices.Add(c);
		indices.Add(a);
		indices.Add(c);
		indices.Add(d);
	}

	/// The two normals for a vertex where two edges meet.
	///
	/// `miterNormal` is scaled so the stroke edge lands on the corner's true outside;
	/// `unitNormal` stays unit length so the fringe outside it keeps its width.
	private static void ComputeJoinNormal(Float2 previousNormal, Float2 nextNormal,
		StrokeStyle style, float halfWidth, float minEdgeLength, out Float2 miterNormal,
		out Float2 unitNormal)
	{
		var average = (previousNormal + nextNormal) * 0.5f;
		let length = Length(average);

		// The edges double back exactly, so there is no outward direction between them.
		if (length < cEpsilon)
		{
			miterNormal = previousNormal;
			unitNormal = previousNormal;
			return;
		}

		average = average / length;
		unitNormal = average;

		let dot = (previousNormal.X * average.X) + (previousNormal.Y * average.Y);
		if (dot <= cEpsilon)
		{
			miterNormal = previousNormal;
			unitNormal = previousNormal;
			return;
		}

		// The miter length that puts the corner on the intersection of the two offset
		// edges. It grows without bound as the corner sharpens, hence the clamps.
		var miterLength = Min(1.0f / dot, cMiterHardLimit);

		// A miter longer than the SHORTER adjacent edge would reach past the far end of
		// it, crossing the geometry of the next segment.
		if (minEdgeLength > cEpsilon)
			miterLength = Min(miterLength, Max(1.01f, minEdgeLength / halfWidth));

		// Past the style's limit a miter join gives up and becomes a flat cut, which is
		// what the limit is for.
		if ((miterLength > style.MiterLimit) && (style.Join == .Miter))
		{
			miterNormal = average;
			return;
		}

		miterNormal = average * miterLength;
	}

	/// The wedge of geometry that fills the outside of a corner.
	private static void AddJoin(Float2 point, Float2 previousNormal, Float2 nextNormal,
		float halfWidth, VGLineJoin joinType, Color color, List<VGVertex> vertices,
		List<uint32> indices)
	{
		let cross = (previousNormal.X * nextNormal.Y) - (previousNormal.Y * nextNormal.X);
		if (Abs(cross) < cJoinEpsilon)
			return;

		// The SIGN says which side of the line the corner turns toward, and therefore which
		// side the wedge belongs on.
		let outward = (cross > 0.0f) ? 1.0f : -1.0f;

		if (joinType == .Bevel)
		{
			let baseIndex = (uint32)vertices.Count;
			vertices.Add(VGVertex.Solid(point, color));
			vertices.Add(VGVertex.Solid(point + (previousNormal * halfWidth * outward), color));
			vertices.Add(VGVertex.Solid(point + (nextNormal * halfWidth * outward), color));

			indices.Add(baseIndex);
			indices.Add(baseIndex + 1);
			indices.Add(baseIndex + 2);
			return;
		}

		if (joinType != .Round)
			return;

		let startAngle = Atan2(previousNormal.Y, previousNormal.X);
		var endAngle = Atan2(nextNormal.Y, nextNormal.X);

		// Swept the SHORT way round, in the direction the corner turns. Without this the
		// fan could take the long way and cover the wrong side entirely.
		if (cross > 0.0f)
		{
			if (endAngle < startAngle)
				endAngle += TwoPi;
		}
		else if (endAngle > startAngle)
		{
			endAngle -= TwoPi;
		}

		// Segment count scales with both the sweep and the radius, so a wide stroke's
		// corner is no coarser than a thin one's.
		let segments = Max(3, (int32)(Abs(endAngle - startAngle) * halfWidth * 0.5f));
		EmitFan(point, startAngle, (endAngle - startAngle) / (float)segments, segments, halfWidth,
			color, vertices, indices);
	}

	/// The geometry past the end of an open stroke.
	private static void AddCap(Float2 point, Float2 direction, Float2 normal, float halfWidth,
		VGLineCap capType, Color color, List<VGVertex> vertices, List<uint32> indices)
	{
		if (capType == .Square)
		{
			let baseIndex = (uint32)vertices.Count;
			let extent = direction * halfWidth;
			let side = normal * halfWidth;

			vertices.Add(VGVertex.Solid(point - side, color));
			vertices.Add(VGVertex.Solid(point + side, color));
			vertices.Add(VGVertex.Solid(point + extent + side, color));
			vertices.Add(VGVertex.Solid(point + extent - side, color));

			AddQuad(indices, baseIndex, baseIndex + 1, baseIndex + 2, baseIndex + 3);
			return;
		}

		if (capType != .Round)
			return;

		// A half turn from one side of the stroke to the other.
		let segments = Max(4, (int32)(halfWidth * 0.5f));
		EmitFan(point, Atan2(normal.Y, normal.X), Pi / (float)segments, segments, halfWidth, color,
			vertices, indices);
	}

	/// A triangle fan around a centre: the centre, then one vertex per step of the sweep.
	private static void EmitFan(Float2 center, float startAngle, float angleStep, int32 segments,
		float radius, Color color, List<VGVertex> vertices, List<uint32> indices)
	{
		let baseIndex = (uint32)vertices.Count;
		vertices.Add(VGVertex.Solid(center, color));

		// One MORE vertex than segments: a fan of n triangles needs n plus one rim points.
		for (int32 i = 0; i <= segments; i++)
		{
			let angle = startAngle + (angleStep * (float)i);
			vertices.Add(VGVertex.Solid(center.X + (Cos(angle) * radius),
				center.Y + (Sin(angle) * radius), color));
		}

		for (int32 i = 0; i < segments; i++)
		{
			indices.Add(baseIndex);
			indices.Add(baseIndex + (uint32)(i + 1));
			indices.Add(baseIndex + (uint32)(i + 2));
		}
	}
}
