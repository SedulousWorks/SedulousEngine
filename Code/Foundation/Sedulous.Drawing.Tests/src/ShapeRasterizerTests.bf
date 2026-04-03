using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.Drawing.Tests;

class ShapeRasterizerTests
{
	[Test]
	public static void RasterizeRect_Creates4Vertices6Indices()
	{
		let rasterizer = scope ShapeRasterizer();
		let vertices = scope List<DrawVertex>();
		let indices = scope List<uint16>();

		rasterizer.RasterizeRect(.(0, 0, 100, 50), vertices, indices, Color.Red);

		Test.Assert(vertices.Count == 4);
		Test.Assert(indices.Count == 6);
	}

	[Test]
	public static void RasterizeRect_VerticesAtCorrectPositions()
	{
		let rasterizer = scope ShapeRasterizer();
		let vertices = scope List<DrawVertex>();
		let indices = scope List<uint16>();

		rasterizer.RasterizeRect(.(10, 20, 100, 50), vertices, indices, Color.Red);

		// Check corners
		Test.Assert(vertices[0].Position.X == 10 && vertices[0].Position.Y == 20);  // Top-left
		Test.Assert(vertices[1].Position.X == 110 && vertices[1].Position.Y == 20); // Top-right
		Test.Assert(vertices[2].Position.X == 110 && vertices[2].Position.Y == 70); // Bottom-right
		Test.Assert(vertices[3].Position.X == 10 && vertices[3].Position.Y == 70);  // Bottom-left
	}

	[Test]
	public static void RasterizeRect_IndicesFormTwoTriangles()
	{
		let rasterizer = scope ShapeRasterizer();
		let vertices = scope List<DrawVertex>();
		let indices = scope List<uint16>();

		rasterizer.RasterizeRect(.(0, 0, 100, 50), vertices, indices, Color.Red);

		// First triangle: 0, 1, 2
		Test.Assert(indices[0] == 0);
		Test.Assert(indices[1] == 1);
		Test.Assert(indices[2] == 2);
		// Second triangle: 0, 2, 3
		Test.Assert(indices[3] == 0);
		Test.Assert(indices[4] == 2);
		Test.Assert(indices[5] == 3);
	}

	[Test]
	public static void RasterizeCircle_CreatesCorrectVertexCount()
	{
		let rasterizer = scope ShapeRasterizer();
		let vertices = scope List<DrawVertex>();
		let indices = scope List<uint16>();

		rasterizer.RasterizeCircle(.(50, 50), 25, vertices, indices, Color.Blue);

		// Should have center + perimeter vertices (segments + 1 perimeter points for closed loop)
		let segments = rasterizer.CalculateCircleSegments(25);
		Test.Assert(vertices.Count == 1 + segments + 1);
	}

	[Test]
	public static void RasterizeCircle_CenterVertexIsAtCenter()
	{
		let rasterizer = scope ShapeRasterizer();
		let vertices = scope List<DrawVertex>();
		let indices = scope List<uint16>();

		rasterizer.RasterizeCircle(.(100, 200), 30, vertices, indices, Color.Green);

		// First vertex should be center (use approximate comparison for floats)
		Test.Assert(Math.Abs(vertices[0].Position.X - 100) < 0.001f);
		Test.Assert(Math.Abs(vertices[0].Position.Y - 200) < 0.001f);
	}

	[Test]
	public static void RasterizeLine_Creates4Vertices()
	{
		let rasterizer = scope ShapeRasterizer();
		let vertices = scope List<DrawVertex>();
		let indices = scope List<uint16>();

		rasterizer.RasterizeLine(.(0, 0), .(100, 0), 4.0f, vertices, indices, Color.Black, .Butt);

		// Line body creates 4 vertices (quad)
		Test.Assert(vertices.Count == 4);
		Test.Assert(indices.Count == 6);
	}

	[Test]
	public static void RasterizeLine_WithRoundCap_CreatesMoreVertices()
	{
		let rasterizer = scope ShapeRasterizer();
		let vertices = scope List<DrawVertex>();
		let indices = scope List<uint16>();

		rasterizer.RasterizeLine(.(0, 0), .(100, 0), 10.0f, vertices, indices, Color.Black, .Round);

		// Line body (4) + round cap vertices at each end
		Test.Assert(vertices.Count > 4);
	}

	[Test]
	public static void RasterizeEllipse_CreatesCorrectShape()
	{
		let rasterizer = scope ShapeRasterizer();
		let vertices = scope List<DrawVertex>();
		let indices = scope List<uint16>();

		rasterizer.RasterizeEllipse(.(50, 50), 40, 20, vertices, indices, Color.Purple);

		// Should have center + perimeter
		Test.Assert(vertices.Count > 1);
		Test.Assert(indices.Count > 0);
	}

	[Test]
	public static void RasterizeRoundedRect_CreatesGeometry()
	{
		let rasterizer = scope ShapeRasterizer();
		let vertices = scope List<DrawVertex>();
		let indices = scope List<uint16>();

		rasterizer.RasterizeRoundedRect(.(0, 0, 100, 50), 10.0f, vertices, indices, Color.Orange);

		Test.Assert(vertices.Count > 0);
		Test.Assert(indices.Count > 0);
	}

	[Test]
	public static void RasterizeArc_CreatesGeometry()
	{
		let rasterizer = scope ShapeRasterizer();
		let vertices = scope List<DrawVertex>();
		let indices = scope List<uint16>();

		// Use a larger sweep angle to ensure segments are created
		rasterizer.RasterizeArc(.(50, 50), 50, 0, 1.57f, vertices, indices, Color.Cyan);

		// Arc should create at minimum 1 center + 2 edge vertices
		Test.Assert(vertices.Count >= 3);
		// And at least one triangle
		Test.Assert(indices.Count >= 3);
	}

	[Test]
	public static void RasterizeStrokeRect_CreatesOutline()
	{
		let rasterizer = scope ShapeRasterizer();
		let vertices = scope List<DrawVertex>();
		let indices = scope List<uint16>();

		rasterizer.RasterizeStrokeRect(.(0, 0, 100, 50), 2.0f, vertices, indices, Color.Black);

		// Creates 8 vertices (4 outer + 4 inner) and 24 indices (4 edges * 6)
		Test.Assert(vertices.Count == 8);
		Test.Assert(indices.Count == 24);
	}

	[Test]
	public static void RasterizeStrokeCircle_CreatesOutline()
	{
		let rasterizer = scope ShapeRasterizer();
		let vertices = scope List<DrawVertex>();
		let indices = scope List<uint16>();

		rasterizer.RasterizeStrokeCircle(.(50, 50), 30, 2.0f, vertices, indices, Color.Black);

		Test.Assert(vertices.Count > 0);
		Test.Assert(indices.Count > 0);
	}

	[Test]
	public static void RasterizePolygon_Triangle_Creates3Vertices()
	{
		let rasterizer = scope ShapeRasterizer();
		let vertices = scope List<DrawVertex>();
		let indices = scope List<uint16>();
		Vector2[] points = scope .(.(0, 0), .(100, 0), .(50, 100));

		rasterizer.RasterizePolygon(points, vertices, indices, Color.Red);

		Test.Assert(vertices.Count == 3);
		Test.Assert(indices.Count == 3);
	}

	[Test]
	public static void RasterizePolygon_Pentagon_Creates5Vertices()
	{
		let rasterizer = scope ShapeRasterizer();
		let vertices = scope List<DrawVertex>();
		let indices = scope List<uint16>();
		Vector2[] points = scope .(.(50, 0), .(100, 35), .(80, 100), .(20, 100), .(0, 35));

		rasterizer.RasterizePolygon(points, vertices, indices, Color.Blue);

		Test.Assert(vertices.Count == 5);
		// Fan triangulation: n-2 triangles = 3 triangles = 9 indices
		Test.Assert(indices.Count == 9);
	}

	[Test]
	public static void RasterizePolyline_Creates4VerticesPerSegment()
	{
		let rasterizer = scope ShapeRasterizer();
		let vertices = scope List<DrawVertex>();
		let indices = scope List<uint16>();
		Vector2[] points = scope .(.(0, 0), .(100, 0), .(100, 100));

		rasterizer.RasterizePolyline(points, 2.0f, vertices, indices, Color.Black, .Butt, .Miter);

		// 2 segments * 4 vertices = 8 vertices (without caps)
		Test.Assert(vertices.Count == 8);
	}

	[Test]
	public static void RasterizeTexturedQuad_CreatesQuadWithUVs()
	{
		let rasterizer = scope ShapeRasterizer();
		let vertices = scope List<DrawVertex>();
		let indices = scope List<uint16>();

		rasterizer.RasterizeTexturedQuad(.(0, 0, 100, 50), .(0, 0, 256, 128), 256, 128, vertices, indices, Color.White);

		Test.Assert(vertices.Count == 4);
		Test.Assert(indices.Count == 6);

		// Check UV coordinates
		Test.Assert(vertices[0].TexCoord.X == 0 && vertices[0].TexCoord.Y == 0);      // Top-left
		Test.Assert(vertices[1].TexCoord.X == 1 && vertices[1].TexCoord.Y == 0);      // Top-right
		Test.Assert(vertices[2].TexCoord.X == 1 && vertices[2].TexCoord.Y == 1);      // Bottom-right
		Test.Assert(vertices[3].TexCoord.X == 0 && vertices[3].TexCoord.Y == 1);      // Bottom-left
	}

	[Test]
	public static void CalculateCircleSegments_IncreasesWithRadius()
	{
		let rasterizer = scope ShapeRasterizer();

		let small = rasterizer.CalculateCircleSegments(10);
		let medium = rasterizer.CalculateCircleSegments(50);
		let large = rasterizer.CalculateCircleSegments(200);

		Test.Assert(small >= 12);
		Test.Assert(medium >= small);
		Test.Assert(large >= medium);
	}

	[Test]
	public static void SolidShapes_UseFixedUV()
	{
		let rasterizer = scope ShapeRasterizer();

		let vertices = scope List<DrawVertex>();
		let indices = scope List<uint16>();
		rasterizer.RasterizeRect(.(0, 0, 10, 10), vertices, indices, Color.White);

		// Solid shapes use fixed UV (0.5, 0.5) for 1x1 white texture sampling
		Test.Assert(vertices[0].TexCoord.X == 0.5f);
		Test.Assert(vertices[0].TexCoord.Y == 0.5f);
	}
}
