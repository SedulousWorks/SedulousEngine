using System;
using Sedulous.Geometry;
using Sedulous.Core.Mathematics;

namespace Sedulous.Geometry.Tests;

class SkinnedMeshTests
{
	[Test]
	public static void TestSkinnedVertexDefault()
	{
		SkinnedVertex vertex = .();

		Test.Assert(vertex.Position == .Zero);
		Test.Assert(vertex.Color == 0xFFFFFFFF);
		Test.Assert(vertex.Weights.X == 1.0f);
		Test.Assert(vertex.Joints[0] == 0);
	}

	[Test]
	public static void TestSkinnedMeshCreation()
	{
		let mesh = new SkinnedMesh();
		defer delete mesh;

		Test.Assert(mesh.VertexCount == 0);
		Test.Assert(mesh.IndexCount == 0);
		Test.Assert(mesh.VertexSize == sizeof(SkinnedVertex));
	}

	[Test]
	public static void TestSkinnedMeshAddVertices()
	{
		let mesh = new SkinnedMesh();
		defer delete mesh;

		mesh.ResizeVertices(10);
		Test.Assert(mesh.VertexCount == 10);

		SkinnedVertex v = .();
		v.Position = .(1, 2, 3);
		v.Joints = .(0, 1, 2, 3);
		v.Weights = .(0.5f, 0.3f, 0.15f, 0.05f);

		mesh.SetVertex(0, v);
		let retrieved = mesh.GetVertex(0);

		Test.Assert(retrieved.Position.X == 1);
		Test.Assert(retrieved.Joints[1] == 1);
		Test.Assert(Math.Abs(retrieved.Weights.X - 0.5f) < 0.001f);
	}

	[Test]
	public static void TestSkinnedMeshIndices()
	{
		let mesh = new SkinnedMesh();
		defer delete mesh;

		mesh.ResizeVertices(4);
		mesh.ReserveIndices(6);

		mesh.AddTriangle(0, 1, 2);
		mesh.AddTriangle(0, 2, 3);

		Test.Assert(mesh.IndexCount == 6);
	}

	[Test]
	public static void TestSkinnedMeshBounds()
	{
		let mesh = new SkinnedMesh();
		defer delete mesh;

		mesh.ResizeVertices(3);

		SkinnedVertex v1 = .();
		v1.Position = .(0, 0, 0);
		mesh.SetVertex(0, v1);

		SkinnedVertex v2 = .();
		v2.Position = .(10, 0, 0);
		mesh.SetVertex(1, v2);

		SkinnedVertex v3 = .();
		v3.Position = .(0, 5, 0);
		mesh.SetVertex(2, v3);

		mesh.CalculateBounds();
		let bounds = mesh.Bounds;

		Test.Assert(bounds.Min.X == 0);
		Test.Assert(bounds.Max.X == 10);
		Test.Assert(bounds.Max.Y == 5);
	}

	[Test]
	public static void TestPackColor()
	{
		let packed = SkinnedMesh.PackColor(Vector4(1, 0, 0, 1));

		// Red channel should be 255
		uint8 r = (uint8)packed;
		Test.Assert(r == 255);

		// Green and blue should be 0
		uint8 g = (uint8)(packed >> 8);
		uint8 b = (uint8)(packed >> 16);
		Test.Assert(g == 0);
		Test.Assert(b == 0);

		// Alpha should be 255
		uint8 a = (uint8)(packed >> 24);
		Test.Assert(a == 255);
	}
}
