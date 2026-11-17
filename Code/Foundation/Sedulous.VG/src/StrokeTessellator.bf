using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.VG;

/// Turns polylines into stroke geometry, with joins, caps, dashing and an antialiased
/// fringe.
static class StrokeTessellator
{
	/// The segments a round join or cap is drawn with, from the count its size asks for: at least
	/// `least`, at most 128 (a smooth arc at any size on screen). Unbounded, a stroke of a huge
	/// width (hostile SVG, a runaway value) asked for millions, and a non-finite size cast to an
	/// integer is undefined.
	public static int32 ArcSegments(float wanted, int32 least)
	{
		const float cMost = 128.0f;
		if (!(wanted < cMost)) // also NaN
			return (int32)cMost;
		return Math.Max(least, (int32)wanted);
	}

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

		// The fringe straddles the stroke's edge, so the stroke covers its own width: solid to half
		// a fringe inside the edge, nothing half a fringe outside it. The fringe keeps the colour's
		// alpha and fades by coverage alone (the shader multiplies the two; fading both squared the
		// ramp to a stepped edge). A stroke thinner than the fringe is solid nowhere: it is drawn as
		// wide as its fringe, at the alpha that covers its own width.
		let innerHalf = Max(halfWidth - (fringeWidth * 0.5f), 0.0f);
		let outerHalf = halfWidth + (fringeWidth * 0.5f);
		var strokeColor = color;
		if (antiAlias && ((halfWidth - (fringeWidth * 0.5f)) < 0.0f))
			strokeColor.A *= 2.0f * halfWidth / outerHalf;

		// Each side of a vertex is offset along its mitred normal, except the outer side of a round or
		// bevel join: there each segment ends square, along its own normal, and the join fills the
		// wedge between them. With one mitred vertex for both, the outer side ran out to the miter
		// point and the join was drawn under that spike, so a round or bevel corner showed as a mitre.
		let outerLeft = scope List<bool>(); // at a join: the left (+normal) side is the outside of the turn
		outerLeft.Resize(n);
		for (int i = 0; i < n; i++)
		{
			if (!needsJoin[i])
				continue;
			let previousEdge = closed ? ((i + edgeCount - 1) % edgeCount) : (i - 1);
			let nextEdge = closed ? (i % edgeCount) : i;
			let a = edgeNormals[previousEdge];
			let b = edgeNormals[nextEdge];
			// Turning left (the normals' cross product positive), the outside is the right.
			outerLeft[i] = ((a.X * b.Y) - (a.Y * b.X)) < 0.0f;
		}
		// The normal segment `edge` uses at vertex `v` on its left (`left`) or right side.
		Float2 SideNormal(int v, int edge, bool left)
		{
			if (needsJoin[v] && (outerLeft[v] == left))
				return edgeNormals[edge];
			return vertexNormals[v];
		}

		// One end of an antialiased segment: its four lines' points.
		void AddEnd(Float2 p, Float2 l, Float2 r)
		{
			vertices.Add(VGVertex.Solid(p + (l * outerHalf), strokeColor, 0.0f));
			vertices.Add(VGVertex.Solid(p + (l * innerHalf), strokeColor, 1.0f));
			vertices.Add(VGVertex.Solid(p - (r * innerHalf), strokeColor, 1.0f));
			vertices.Add(VGVertex.Solid(p - (r * outerHalf), strokeColor, 0.0f));
		}

		let segmentCount = closed ? n : (n - 1);
		for (int i = 0; i < segmentCount; i++)
		{
			let j = (i + 1) % n;
			let pi = points[i];
			let pj = points[j];
			let li = SideNormal(i, i, true);
			let ri = SideNormal(i, i, false);
			let lj = SideNormal(j, i, true);
			let rj = SideNormal(j, i, false);
			let baseIndex = (uint32)vertices.Count;
			if (antiAlias)
			{
				// Four lines along the segment, at each end: the left fringe (coverage 0), the left
				// edge, the right edge (coverage 1) and the right fringe.
				AddEnd(pi, li, ri);
				AddEnd(pj, lj, rj);
				for (uint32 band = 0; band < 3; band++)
				{
					// Start: this line and the next; end: the same.
					AddQuad(indices, baseIndex + band, baseIndex + 4 + band, baseIndex + 5 + band,
						baseIndex + band + 1);
				}
			}
			else
			{
				vertices.Add(VGVertex.Solid(pi + (li * halfWidth), color));
				vertices.Add(VGVertex.Solid(pi - (ri * halfWidth), color));
				vertices.Add(VGVertex.Solid(pj + (lj * halfWidth), color));
				vertices.Add(VGVertex.Solid(pj - (rj * halfWidth), color));
				indices.Add(baseIndex);
				indices.Add(baseIndex + 2);
				indices.Add(baseIndex + 1);
				indices.Add(baseIndex + 1);
				indices.Add(baseIndex + 2);
				indices.Add(baseIndex + 3);
			}
		}

		// The joins: the wedge between the two square segment ends, solid to the edge and,
		// antialiased, with a fringe outside it as the segments have.
		for (int i = 0; i < n; i++)
		{
			if (!needsJoin[i])
				continue;

			let previousEdge = closed ? ((i + edgeCount - 1) % edgeCount) : (i - 1);
			let nextEdge = closed ? (i % edgeCount) : i;
			AddJoin(points[i], edgeNormals[previousEdge], edgeNormals[nextEdge],
				antiAlias ? innerHalf : halfWidth, antiAlias ? outerHalf : 0.0f, style.Join, strokeColor,
				vertices, indices);
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
				AddCap(points[0], -direction, edgeNormals[0], innerHalf,
					antiAlias ? outerHalf : innerHalf, style.Cap, strokeColor, vertices, indices);
			}
		}
		{
			var direction = points[n - 1] - points[n - 2];
			let length = Length(direction);
			if (length > cEpsilon)
			{
				direction = direction / length;
				AddCap(points[n - 1], direction, edgeNormals[edgeCount - 1], innerHalf,
					antiAlias ? outerHalf : innerHalf, style.Cap, strokeColor, vertices, indices);
			}
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

	/// The wedge of a round or bevel join, outside the turn: solid to `solidHalf`, then, when
	/// `fringeHalf` is past it, a fringe fading out to `fringeHalf`.
	private static void AddJoin(Float2 point, Float2 previousNormal, Float2 nextNormal,
		float solidHalf, float fringeHalf, VGLineJoin joinType, Color color, List<VGVertex> vertices,
		List<uint32> indices)
	{
		let cross = (previousNormal.X * nextNormal.Y) - (previousNormal.Y * nextNormal.X);
		if (Abs(cross) < cJoinEpsilon)
			return;
		if ((joinType != .Round) && (joinType != .Bevel))
			return;
		let side = (cross > 0.0f) ? -1.0f : 1.0f; // the outside of the turn: right when turning left

		// The rim: unit directions from the point, from the incoming segment's normal to the
		// outgoing one's (two for a bevel, an arc's worth for a round join).
		let rim = scope List<Float2>();
		let from = previousNormal * side;
		let to = nextNormal * side;
		if (joinType == .Round)
		{
			// The short way from one to the other, the turn's own angle.
			let startAngle = Atan2(from.Y, from.X);
			let endAngle = startAngle + Atan2((from.X * to.Y) - (from.Y * to.X), (from.X * to.X) + (from.Y * to.Y));
			// Segment count scales with both the sweep and the radius, so a wide stroke's corner is
			// no coarser than a thin one's.
			let segments = ArcSegments(Abs(endAngle - startAngle) * solidHalf * 0.5f, 3);
			let angleStep = (endAngle - startAngle) / (float)segments;
			for (int32 k = 0; k <= segments; k++)
			{
				let angle = startAngle + (angleStep * (float)k);
				rim.Add(.(Cos(angle), Sin(angle)));
			}
		}
		else
		{
			rim.Add(from);
			rim.Add(to);
		}

		let centre = (uint32)vertices.Count;
		vertices.Add(VGVertex.Solid(point, color, 1.0f));
		let solid = (uint32)vertices.Count;
		for (let d in rim)
			vertices.Add(VGVertex.Solid(point + (d * solidHalf), color, 1.0f));
		for (uint32 k = 0; (k + 1) < (uint32)rim.Count; k++)
		{
			indices.Add(centre);
			indices.Add(solid + k);
			indices.Add(solid + k + 1);
		}
		if (fringeHalf <= solidHalf)
			return;
		// A bevel's fringe runs along its chord: its rim points pushed out across the chord.
		let chordOut = (joinType == .Round) ? Float2.Zero : (Normalized(from + to) * (fringeHalf - solidHalf));
		let fringe = (uint32)vertices.Count;
		for (let d in rim)
		{
			let edge = (joinType == .Round) ? (point + (d * fringeHalf)) : (point + (d * solidHalf) + chordOut);
			vertices.Add(VGVertex.Solid(edge, color, 0.0f));
		}
		for (uint32 k = 0; (k + 1) < (uint32)rim.Count; k++)
			AddQuad(indices, solid + k, fringe + k, fringe + k + 1, solid + k + 1);
	}

	/// The geometry past the end of an open stroke. Its outline runs from the stroke's one side, out
	/// through `direction`, round to its other side: solid to `innerHalf`, and with a fringe
	/// (`outerHalf` beyond it) faded by coverage to nothing there, meeting the body's fringe at
	/// either side.
	private static void AddCap(Float2 point, Float2 direction, Float2 normal, float innerHalf,
		float outerHalf, VGLineCap capType, Color color, List<VGVertex> vertices,
		List<uint32> indices)
	{
		// The outline's offsets per unit of radius.
		let outline = scope List<Float2>();
		if (capType == .Square)
		{
			outline.Add(normal);
			outline.Add(normal + direction);
			outline.Add(direction - normal);
			outline.Add(-normal);
		}
		else if (capType == .Round)
		{
			// A half turn from one side of the stroke to the other, through its direction (an angle
			// from the normal alone would turn the end cap back over the stroke).
			let segments = ArcSegments(outerHalf * 0.5f, 4);
			for (int32 i = 0; i <= segments; i++)
			{
				let angle = Pi * (float)i / (float)segments;
				outline.Add((normal * Cos(angle)) + (direction * Sin(angle)));
			}
		}
		else
			return;

		let count = (uint32)outline.Count;
		let centre = (uint32)vertices.Count;
		vertices.Add(VGVertex.Solid(point, color));
		let inner = (uint32)vertices.Count;
		for (let offset in outline)
			vertices.Add(VGVertex.Solid(point + (offset * innerHalf), color));
		for (uint32 i = 0; (i + 1) < count; i++)
		{
			indices.Add(centre);
			indices.Add(inner + i);
			indices.Add(inner + i + 1);
		}
		if (outerHalf <= innerHalf)
			return;

		let outer = (uint32)vertices.Count;
		for (let offset in outline)
			vertices.Add(VGVertex.Solid(point + (offset * outerHalf), color, 0.0f));
		for (uint32 i = 0; (i + 1) < count; i++)
			AddQuad(indices, inner + i, outer + i, outer + i + 1, inner + i + 1);
	}
}
