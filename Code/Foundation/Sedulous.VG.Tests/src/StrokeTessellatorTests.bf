namespace Sedulous.VG.Tests;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.VG;

class StrokeTessellatorTests
{
	[Test]
	public static void SolidLine_ProducesQuadStrip()
	{
		Vector2[2] points = .(.(0, 0), .(10, 0));
		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();

		StrokeTessellator.Tessellate(Span<Vector2>(&points, 2), false, .(2.0f), default, false, Color.White, vertices, indices);

		// Simple line should produce at least 4 vertices (quad strip)
		Test.Assert(vertices.Count >= 4);
		Test.Assert(indices.Count >= 6);
	}

	[Test]
	public static void ClosedPath_NoCaps()
	{
		// Triangle (closed)
		Vector2[3] points = .(.(0, 0), .(10, 0), .(5, 10));
		let verticesClosed = scope List<VGVertex>();
		let indicesClosed = scope List<uint32>();

		StrokeTessellator.Tessellate(Span<Vector2>(&points, 3), true, .(2.0f), default, false, Color.White, verticesClosed, indicesClosed);

		// Open path with square caps
		let verticesOpen = scope List<VGVertex>();
		let indicesOpen = scope List<uint32>();
		StrokeTessellator.Tessellate(Span<Vector2>(&points, 3), false, .(2.0f, .Square, .Miter), default, false, Color.White, verticesOpen, indicesOpen);

		// Closed path should not have caps, open path with Square caps should have more vertices
		Test.Assert(verticesOpen.Count > verticesClosed.Count || indicesOpen.Count > indicesClosed.Count);
	}

	[Test]
	public static void RoundCap_MoreVertices()
	{
		Vector2[2] points = .(.(0, 0), .(10, 0));

		let vertsButt = scope List<VGVertex>();
		let idxButt = scope List<uint32>();
		StrokeTessellator.Tessellate(Span<Vector2>(&points, 2), false, .(4.0f, .Butt, .Miter), default, false, Color.White, vertsButt, idxButt);

		let vertsRound = scope List<VGVertex>();
		let idxRound = scope List<uint32>();
		StrokeTessellator.Tessellate(Span<Vector2>(&points, 2), false, .(4.0f, .Round, .Miter), default, false, Color.White, vertsRound, idxRound);

		// Round caps should add more vertices
		Test.Assert(vertsRound.Count > vertsButt.Count);
	}

	[Test]
	public static void Polyline_MultipleSegments()
	{
		Vector2[4] points = .(.(0, 0), .(10, 0), .(10, 10), .(0, 10));
		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();

		StrokeTessellator.Tessellate(Span<Vector2>(&points, 4), false, .(2.0f), default, false, Color.White, vertices, indices);

		// 4 points = 3 segments, each needs a quad = at least 8 vertices
		Test.Assert(vertices.Count >= 8);
		Test.Assert(indices.Count >= 18); // 3 quads * 6 indices
	}
}
