using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.Drawing.Tests;

class DrawVertexTests
{
	[Test]
	public static void Constructor_SetsAllFields()
	{
		let vertex = DrawVertex(10.0f, 20.0f, 0.5f, 0.75f, Color.Red);

		Test.Assert(vertex.Position.X == 10.0f);
		Test.Assert(vertex.Position.Y == 20.0f);
		Test.Assert(vertex.TexCoord.X == 0.5f);
		Test.Assert(vertex.TexCoord.Y == 0.75f);
		Test.Assert(vertex.Color == Color.Red);
	}

	[Test]
	public static void Constructor_Vector2_SetsPositionAndTexCoord()
	{
		let pos = Vector2(100, 200);
		let uv = Vector2(0.25f, 0.5f);
		let vertex = DrawVertex(pos, uv, Color.Green);

		Test.Assert(vertex.Position == pos);
		Test.Assert(vertex.TexCoord == uv);
		Test.Assert(vertex.Color == Color.Green);
	}

	[Test]
	public static void SizeInBytes_Is20()
	{
		Test.Assert(DrawVertex.SizeInBytes == 20);
	}

	[Test]
	public static void Default_AllZero()
	{
		DrawVertex vertex = default;

		Test.Assert(vertex.Position == Vector2.Zero);
		Test.Assert(vertex.TexCoord == Vector2.Zero);
		Test.Assert(vertex.Color == Color(0, 0, 0, 0));
	}
}
