using System;
using Sedulous.Geometry;
using Sedulous.Core.Mathematics;

namespace Sedulous.Geometry.Tests;

class MeshBuilderTests
{
	[Test]
	public static void TestMeshCreation()
	{
		let mesh = new MeshBuilder();
		defer delete mesh;

		mesh.SetupCommonVertexFormat();
		mesh.Vertices.Resize(3);
		mesh.Indices.Resize(3);

		Test.Assert(mesh.Vertices.VertexCount == 3);
		Test.Assert(mesh.Indices.IndexCount == 3);
	}

	[Test]
	public static void TestMeshVertexData()
	{
		let mesh = new MeshBuilder();
		defer delete mesh;

		mesh.SetupCommonVertexFormat();
		mesh.Vertices.Resize(3);

		mesh.SetPosition(0, .(1, 2, 3));
		mesh.SetNormal(0, .(0, 1, 0));
		mesh.SetUV(0, .(0.5f, 0.5f));
		mesh.SetColor(0, 0xFF00FF00);

		let pos = mesh.GetPosition(0);
		Test.Assert(pos.X == 1 && pos.Y == 2 && pos.Z == 3);

		let normal = mesh.GetNormal(0);
		Test.Assert(normal.Y == 1);

		let uv = mesh.GetUV(0);
		Test.Assert(uv.X == 0.5f && uv.Y == 0.5f);

		let color = mesh.GetColor(0);
		Test.Assert(color == 0xFF00FF00);
	}

	[Test]
	public static void TestCreateTriangle()
	{
		let mesh = MeshBuilder.CreateTriangle();
		defer delete mesh;

		Test.Assert(mesh.VertexCount == 3);
		Test.Assert(mesh.IndexCount == 3);
		Test.Assert(mesh.SubMeshes.Count == 1);
	}

	[Test]
	public static void TestCreateQuad()
	{
		let mesh = MeshBuilder.CreateQuad(2.0f, 2.0f);
		defer delete mesh;

		Test.Assert(mesh.VertexCount == 4);
		Test.Assert(mesh.IndexCount == 6);
	}

	[Test]
	public static void TestCreateCube()
	{
		let mesh = MeshBuilder.CreateCube(1.0f);
		defer delete mesh;

		Test.Assert(mesh.VertexCount == 24);
		Test.Assert(mesh.IndexCount == 36);
	}

	[Test]
	public static void TestCreateSphere()
	{
		let mesh = MeshBuilder.CreateSphere(0.5f, 16, 8);
		defer delete mesh;

		Test.Assert(mesh.VertexCount > 0);
		Test.Assert(mesh.IndexCount > 0);
	}

	[Test]
	public static void TestCreatePlane()
	{
		let mesh = MeshBuilder.CreatePlane(10.0f, 10.0f, 2, 2);
		defer delete mesh;

		Test.Assert(mesh.VertexCount == 9); // (2+1) * (2+1)
		Test.Assert(mesh.IndexCount == 24); // 2 * 2 * 6
	}

	[Test]
	public static void TestStaticMeshBounds()
	{
		let mesh = MeshBuilder.CreateCube(2.0f);
		defer delete mesh;

		let bounds = mesh.GetBounds();

		// Cube size 2, so bounds should be -1 to 1
		Test.Assert(Math.Abs(bounds.Min.X - (-1.0f)) < 0.001f);
		Test.Assert(Math.Abs(bounds.Max.X - 1.0f) < 0.001f);
	}
}
