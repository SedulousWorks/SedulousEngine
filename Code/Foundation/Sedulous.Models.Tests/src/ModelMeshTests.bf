using System;
using Sedulous.Models;
using Sedulous.Core.Mathematics;

namespace Sedulous.Models.Tests;

class ModelMeshTests
{
	[Test]
	public static void TestModelMeshCreation()
	{
		let mesh = new ModelMesh();
		defer delete mesh;

		Test.Assert(mesh.VertexCount == 0);
		Test.Assert(mesh.IndexCount == 0);
	}

	[Test]
	public static void TestModelMeshVertexFormat()
	{
		let mesh = new ModelMesh();
		defer delete mesh;

		mesh.AddVertexElement(VertexElement(.Position, .Float3, 0));
		mesh.AddVertexElement(VertexElement(.Normal, .Float3, 12));

		Test.Assert(mesh.VertexElements.Count == 2);
		Test.Assert(mesh.VertexElements[0].Semantic == .Position);
		Test.Assert(mesh.VertexElements[1].Offset == 12);
	}

	[Test]
	public static void TestModelMeshAllocate()
	{
		let mesh = new ModelMesh();
		defer delete mesh;

		mesh.AllocateVertices(100, 48);
		mesh.AllocateIndices(300, false);

		Test.Assert(mesh.VertexCount == 100);
		Test.Assert(mesh.VertexStride == 48);
		Test.Assert(mesh.IndexCount == 300);
		Test.Assert(!mesh.Use32BitIndices);
	}

	[Test]
	public static void TestModelMeshParts()
	{
		let mesh = new ModelMesh();
		defer delete mesh;

		mesh.AddPart(ModelMeshPart(0, 100, 0));
		mesh.AddPart(ModelMeshPart(100, 200, 1));

		Test.Assert(mesh.Parts.Count == 2);
		Test.Assert(mesh.Parts[1].IndexStart == 100);
		Test.Assert(mesh.Parts[1].MaterialIndex == 1);
	}

	[Test]
	public static void TestVertexElementSize()
	{
		Test.Assert(VertexElement(.Position, .Float, 0).Size == 4);
		Test.Assert(VertexElement(.Position, .Float2, 0).Size == 8);
		Test.Assert(VertexElement(.Position, .Float3, 0).Size == 12);
		Test.Assert(VertexElement(.Position, .Float4, 0).Size == 16);
		Test.Assert(VertexElement(.Color, .Byte4, 0).Size == 4);
	}
}
