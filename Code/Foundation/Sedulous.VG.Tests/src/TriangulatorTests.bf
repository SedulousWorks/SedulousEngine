namespace Sedulous.VG.Tests;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.VG;

class TriangulatorTests
{
	[Test]
	public static void ConvexPolygon_CorrectTriangleCount()
	{
		// Square: 4 vertices -> 2 triangles -> 6 indices
		Vector2[4] points = .(.(0, 0), .(10, 0), .(10, 10), .(0, 10));
		let indices = scope List<uint32>();
		Triangulator.Triangulate(Span<Vector2>(&points, 4), .EvenOdd, indices);

		Test.Assert(indices.Count == 6);
	}

	[Test]
	public static void Concave_ProducesValidMesh()
	{
		// L-shape (concave)
		Vector2[6] points = .(
			.(0, 0), .(10, 0), .(10, 5),
			.(5, 5), .(5, 10), .(0, 10)
		);
		let indices = scope List<uint32>();
		Triangulator.Triangulate(Span<Vector2>(&points, 6), .EvenOdd, indices);

		// 6 vertices -> 4 triangles -> 12 indices
		Test.Assert(indices.Count == 12);
		// All indices should be valid
		for (let idx in indices)
			Test.Assert(idx < 6);
	}

	[Test]
	public static void PolygonArea_CCW_Positive()
	{
		// CCW square
		Vector2[4] points = .(.(0, 0), .(10, 0), .(10, 10), .(0, 10));
		let area = Triangulator.PolygonArea(Span<Vector2>(&points, 4));
		Test.Assert(area > 0);
	}

	[Test]
	public static void PolygonArea_CW_Negative()
	{
		// CW square
		Vector2[4] points = .(.(0, 0), .(0, 10), .(10, 10), .(10, 0));
		let area = Triangulator.PolygonArea(Span<Vector2>(&points, 4));
		Test.Assert(area < 0);
	}

	[Test]
	public static void PolygonArea_CorrectValue()
	{
		// 10x10 square -> area = 100
		Vector2[4] points = .(.(0, 0), .(10, 0), .(10, 10), .(0, 10));
		let area = Triangulator.PolygonArea(Span<Vector2>(&points, 4));
		Test.Assert(Math.Abs(area - 100.0f) < 0.01f);
	}

	[Test]
	public static void PointInTriangle_Inside()
	{
		Test.Assert(Triangulator.PointInTriangle(.(5, 5), .(0, 0), .(10, 0), .(5, 10)));
	}

	[Test]
	public static void PointInTriangle_Outside()
	{
		Test.Assert(!Triangulator.PointInTriangle(.(15, 5), .(0, 0), .(10, 0), .(5, 10)));
	}

	[Test]
	public static void Pentagon_CorrectTriangles()
	{
		// Regular pentagon: 5 vertices -> 3 triangles -> 9 indices
		Vector2[5] points = default;
		for (int i = 0; i < 5; i++)
		{
			let angle = Math.PI_f * 2.0f * i / 5.0f - Math.PI_f * 0.5f;
			points[i] = .(Math.Cos(angle) * 10, Math.Sin(angle) * 10);
		}

		let indices = scope List<uint32>();
		Triangulator.Triangulate(Span<Vector2>(&points, 5), .EvenOdd, indices);

		Test.Assert(indices.Count == 9);
	}
}
