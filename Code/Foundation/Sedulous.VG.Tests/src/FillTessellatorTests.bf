namespace Sedulous.VG.Tests;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.VG;

class FillTessellatorTests
{
	[Test]
	public static void Rectangle_TwoTriangles()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);
		builder.LineTo(10, 10);
		builder.LineTo(0, 10);
		builder.Close();

		let path = builder.ToPath();
		defer delete path;
		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();

		FillTessellator.Tessellate(path, .EvenOdd, Color.White, false, vertices, indices);

		Test.Assert(vertices.Count == 4);
		Test.Assert(indices.Count == 6); // 2 triangles * 3 indices
	}

	[Test]
	public static void Circle_CreatesTriangles()
	{
		let builder = scope PathBuilder();
		ShapeBuilder.BuildCircle(.(50, 50), 25, builder);
		let path = builder.ToPath();
		defer delete path;

		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();

		FillTessellator.Tessellate(path, .EvenOdd, Color.Red, false, vertices, indices);

		// Circle should produce a reasonable number of vertices
		Test.Assert(vertices.Count > 8);
		Test.Assert(indices.Count > 8);
		// Should be valid triangles
		Test.Assert(indices.Count % 3 == 0);
	}

	[Test]
	public static void AA_HasMoreVertices()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);
		builder.LineTo(10, 10);
		builder.LineTo(0, 10);
		builder.Close();

		let path = builder.ToPath();
		defer delete path;

		let vertsNoAA = scope List<VGVertex>();
		let indicesNoAA = scope List<uint32>();
		FillTessellator.Tessellate(path, .EvenOdd, Color.White, false, vertsNoAA, indicesNoAA);

		let vertsAA = scope List<VGVertex>();
		let indicesAA = scope List<uint32>();
		FillTessellator.Tessellate(path, .EvenOdd, Color.White, true, vertsAA, indicesAA);

		// AA version should have more vertices (fringe quads)
		Test.Assert(vertsAA.Count > vertsNoAA.Count);
		Test.Assert(indicesAA.Count > indicesNoAA.Count);
	}

	[Test]
	public static void VertexCoverage_InnerIsOne()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);
		builder.LineTo(10, 10);
		builder.LineTo(0, 10);
		builder.Close();

		let path = builder.ToPath();
		defer delete path;
		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();

		FillTessellator.Tessellate(path, .EvenOdd, Color.White, false, vertices, indices);

		// All non-AA vertices should have coverage = 1.0
		for (let v in vertices)
			Test.Assert(v.Coverage == 1.0f);
	}
}
