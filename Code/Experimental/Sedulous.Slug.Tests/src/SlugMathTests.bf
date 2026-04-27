using System;
using Sedulous.Slug;

namespace Sedulous.Slug.Tests;

class SlugMathTests
{
	[Test]
	public static void FloatToHalf_Zero()
	{
		let result = SlugTextureBuilder.FloatToHalf(0.0f);
		Test.Assert(result == 0, "FloatToHalf(0.0) should be 0");
	}

	[Test]
	public static void FloatToHalf_One()
	{
		let result = SlugTextureBuilder.FloatToHalf(1.0f);
		Test.Assert(result == 0x3C00, "FloatToHalf(1.0) should be 0x3C00");
	}

	[Test]
	public static void FloatToHalf_NegOne()
	{
		let result = SlugTextureBuilder.FloatToHalf(-1.0f);
		Test.Assert(result == 0xBC00, "FloatToHalf(-1.0) should be 0xBC00");
	}

	[Test]
	public static void FloatToHalf_Half()
	{
		let result = SlugTextureBuilder.FloatToHalf(0.5f);
		Test.Assert(result == 0x3800, "FloatToHalf(0.5) should be 0x3800");
	}

	[Test]
	public static void Box2D_Dimensions()
	{
		let @box = Box2D(1.0f, 2.0f, 4.0f, 6.0f);
		Test.Assert(@box.Width == 3.0f);
		Test.Assert(@box.Height == 4.0f);
		Test.Assert(!@box.IsEmpty);
	}

	[Test]
	public static void Box2D_Empty()
	{
		let @box = Box2D(5.0f, 5.0f, 1.0f, 1.0f);
		Test.Assert(@box.IsEmpty);
	}

	[Test]
	public static void Vertex4U_Size()
	{
		Test.Assert(sizeof(Vertex4U) == 68, scope $"Vertex4U should be 68 bytes, got {sizeof(Vertex4U)}");
	}

	[Test]
	public static void VertexRGBA_Size()
	{
		Test.Assert(sizeof(VertexRGBA) == 80, scope $"VertexRGBA should be 80 bytes, got {sizeof(VertexRGBA)}");
	}

	[Test]
	public static void Triangle16_Size()
	{
		Test.Assert(sizeof(Triangle16) == 6, scope $"Triangle16 should be 6 bytes, got {sizeof(Triangle16)}");
	}

	[Test]
	public static void Triangle32_Size()
	{
		Test.Assert(sizeof(Triangle32) == 12, scope $"Triangle32 should be 12 bytes, got {sizeof(Triangle32)}");
	}
}
