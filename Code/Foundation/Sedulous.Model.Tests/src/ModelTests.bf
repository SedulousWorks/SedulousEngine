using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Model;

namespace Sedulous.Model.Tests;

/// The importer's model representation. Raptor has one trivial test here, so these are
/// written from scratch against what the types are actually for.
class ModelTests
{
	private static bool Near(float a, float b, float tolerance = 0.0001f) => Abs(a - b) <= tolerance;

	/// The vertex layouts are a size contract, and Beef reorders struct fields for packing
	/// without [CRepr]. Offsets as well as sizes, since two same sized fields could swap
	/// and leave the total unchanged.
	[Test]
	public static void TheVertexLayoutsAreTheDeclaredSizes()
	{
		Test.Assert(sizeof(ModelVertex) == 52, scope $"static vertex is {sizeof(ModelVertex)}");
		Test.Assert(sizeof(SkinnedModelVertex) == 76, scope $"skinned vertex is {sizeof(SkinnedModelVertex)}");

		var vertex = ModelVertex();
		let start = (uint8*)&vertex;
		Test.Assert((uint8*)&vertex.Position - start == 0);
		Test.Assert((uint8*)&vertex.Normal - start == 12);
		Test.Assert((uint8*)&vertex.TexCoord - start == 24);
		Test.Assert((uint8*)&vertex.Color - start == 32);
		Test.Assert((uint8*)&vertex.Tangent - start == 36);

		var skinned = SkinnedModelVertex();
		let skinnedStart = (uint8*)&skinned;
		// The static half is laid out exactly as ModelVertex, with the skinning on the end.
		Test.Assert((uint8*)&skinned.Position - skinnedStart == 0);
		Test.Assert((uint8*)&skinned.Tangent - skinnedStart == 36);
		Test.Assert((uint8*)&skinned.Joints - skinnedStart == 52);
		Test.Assert((uint8*)&skinned.Weights - skinnedStart == 60);
	}

	[Test]
	public static void AVertexElementKnowsItsOwnSize()
	{
		Test.Assert(VertexElement(.Position, .Float3, 0).Size == 12);
		Test.Assert(VertexElement(.TexCoord, .Float2, 0).Size == 8);
		Test.Assert(VertexElement(.Color, .Byte4, 0).Size == 4);
		Test.Assert(VertexElement(.Joints, .UShort4, 0).Size == 8);
		Test.Assert(VertexElement(.Weights, .Float4, 0).Size == 16);
		Test.Assert(VertexElement(.Normal, .Float, 0).Size == 4);
		Test.Assert(VertexElement(.TexCoord, .UShort2, 0).Size == 4);

		// The semantic index is what distinguishes a second UV channel from the first.
		let second = VertexElement(.TexCoord, .Float2, 20, 1);
		Test.Assert(second.SemanticIndex == 1);
		Test.Assert(second.Offset == 20);
	}

	/// A mesh is untyped bytes plus a layout, so the offset lookup is how anything finds a
	/// position or a joint index.
	[Test]
	public static void AMeshFindsItsElementsBySemantic()
	{
		let mesh = scope ModelMesh();
		mesh.AddVertexElement(.(.Position, .Float3, 0));
		mesh.AddVertexElement(.(.Normal, .Float3, 12));
		mesh.AddVertexElement(.(.TexCoord, .Float2, 24));

		Test.Assert(mesh.OffsetOf(.Position) == 0);
		Test.Assert(mesh.OffsetOf(.Normal) == 12);
		Test.Assert(mesh.OffsetOf(.TexCoord) == 24);
		Test.Assert(mesh.OffsetOf(.Joints) == -1, "a semantic the layout does not have");
	}

	private static ModelMesh BuildTriangle()
	{
		let mesh = new ModelMesh();
		mesh.AddVertexElement(.(.Position, .Float3, 0));
		mesh.AllocateVertices(3, 12);

		Float3[3] positions = .(.(0, 0, 0), .(2, 0, 0), .(0, 4, 0));
		mesh.SetVertexData(.((uint8*)&positions[0], 36));

		mesh.AllocateIndices(3, false);
		uint16[3] indices = .(0, 1, 2);
		mesh.SetIndexData(Span<uint16>(&indices[0], 3));
		return mesh;
	}

	[Test]
	public static void VertexAndIndexBuffersAreSizedByTheirAllocation()
	{
		let mesh = BuildTriangle();
		defer delete mesh;

		Test.Assert(mesh.VertexCount == 3);
		Test.Assert(mesh.VertexStride == 12);
		Test.Assert(mesh.VertexDataSize == 36);
		Test.Assert(mesh.VertexData != null);

		Test.Assert(mesh.IndexCount == 3);
		Test.Assert(!mesh.Use32BitIndices);
		Test.Assert(mesh.IndexDataSize == 6, "three sixteen bit indices");

		let empty = scope ModelMesh();
		Test.Assert(empty.VertexData == null, "nothing allocated means no pointer");
		Test.Assert(empty.IndexData == null);
	}

	/// Index data of the wrong width is REFUSED. Writing it anyway would put sixteen bit
	/// values into a buffer read as thirty two bit ones, which draws a mesh that is half
	/// there.
	[Test]
	public static void IndexDataOfTheWrongWidthIsRefused()
	{
		let mesh = scope ModelMesh();
		mesh.AllocateIndices(4, true); // thirty two bit

		uint16[4] narrow = .(0, 1, 2, 3);
		Test.Assert(!mesh.SetIndexData(Span<uint16>(&narrow[0], 4)), "narrow into a wide buffer");

		uint32[4] wide = .(0, 1, 2, 3);
		Test.Assert(mesh.SetIndexData(Span<uint32>(&wide[0], 4)), "and the right width is taken");

		let narrowMesh = scope ModelMesh();
		narrowMesh.AllocateIndices(4, false);
		Test.Assert(!narrowMesh.SetIndexData(Span<uint32>(&wide[0], 4)), "wide into a narrow buffer");
	}

	/// More data than the buffer holds is refused rather than truncated: a partly written
	/// vertex buffer draws garbage, which is worse than not drawing.
	[Test]
	public static void OversizedVertexDataIsRefused()
	{
		let mesh = scope ModelMesh();
		mesh.AllocateVertices(2, 12);

		uint8[36] tooMuch = default;
		Test.Assert(!mesh.SetVertexData(.(&tooMuch[0], 36)), "three vertices into room for two");

		uint8[24] fits = default;
		Test.Assert(mesh.SetVertexData(.(&fits[0], 24)));
	}

	[Test]
	public static void MeshBoundsComeFromThePositions()
	{
		let mesh = BuildTriangle();
		defer delete mesh;

		mesh.CalculateBounds();
		Test.Assert(Near(mesh.Bounds.Min.X, 0.0f));
		Test.Assert(Near(mesh.Bounds.Max.X, 2.0f));
		Test.Assert(Near(mesh.Bounds.Max.Y, 4.0f));
		Test.Assert(Near(mesh.Bounds.Min.Z, 0.0f));
	}

	/// A mesh with no position element has no bounds to compute, and must say so rather
	/// than reading whatever sits at offset zero.
	[Test]
	public static void AMeshWithoutPositionsHasEmptyBounds()
	{
		let mesh = scope ModelMesh();
		mesh.AddVertexElement(.(.Color, .Byte4, 0));
		mesh.AllocateVertices(4, 4);
		mesh.CalculateBounds();

		Test.Assert(mesh.Bounds.Min == Float3.Zero);
		Test.Assert(mesh.Bounds.Max == Float3.Zero);

		let empty = scope ModelMesh();
		empty.CalculateBounds();
		Test.Assert(empty.Bounds.Min == Float3.Zero);
	}

	[Test]
	public static void ScalingPositionsRewritesTheVertexBuffer()
	{
		let mesh = BuildTriangle();
		defer delete mesh;

		mesh.ScalePositions(.(2.0f, 0.5f, 1.0f));
		mesh.CalculateBounds();

		Test.Assert(Near(mesh.Bounds.Max.X, 4.0f), "doubled in X");
		Test.Assert(Near(mesh.Bounds.Max.Y, 2.0f), "halved in Y");

		let positions = (Float3*)mesh.VertexData;
		Test.Assert(Near(positions[1].X, 4.0f));
		Test.Assert(Near(positions[2].Y, 2.0f));
	}

	/// Position is found by SEMANTIC, not assumed to be first. Every other mesh here puts
	/// it at offset zero, which cannot tell a semantic lookup apart from a hardcoded zero.
	[Test]
	public static void PositionIsFoundWhereverTheLayoutPutsIt()
	{
		let mesh = scope ModelMesh();
		// Colour first, position second: a layout a real file can easily produce.
		mesh.AddVertexElement(.(.Color, .Byte4, 0));
		mesh.AddVertexElement(.(.Position, .Float3, 4));
		mesh.AllocateVertices(2, 16);
		Test.Assert(mesh.OffsetOf(.Position) == 4);

		uint8[32] bytes = default;
		let first = (Float3*)(&bytes[0] + 4);
		*first = .(1, 2, 3);
		let second = (Float3*)(&bytes[0] + 16 + 4);
		*second = .(4, 6, 8);
		mesh.SetVertexData(.(&bytes[0], 32));

		mesh.CalculateBounds();
		Test.Assert(mesh.Bounds.Min.X == 1.0f, scope $"bounds read from offset {mesh.OffsetOf(.Position)}");
		Test.Assert(mesh.Bounds.Max.Z == 8.0f);

		mesh.ScalePositions(.(2, 1, 1));
		let scaled = (Float3*)(mesh.VertexData + 4);
		Test.Assert(scaled.X == 2.0f, "the position at offset four was the one scaled");
		Test.Assert(bytes[0] == 0, "and the colour bytes were left alone");
	}

	/// Uniform skinning widens every vertex and appends the two elements describing the
	/// new bytes, so the layout still describes the buffer.
	[Test]
	public static void UniformSkinningWidensEveryVertex()
	{
		let mesh = BuildTriangle();
		defer delete mesh;

		mesh.AddUniformSkinning(7);

		Test.Assert(mesh.VertexStride == 36, scope $"stride is {mesh.VertexStride}, expected 12 plus 24");
		Test.Assert(mesh.VertexDataSize == 108);
		Test.Assert(mesh.OffsetOf(.Joints) == 12);
		Test.Assert(mesh.OffsetOf(.Weights) == 20);

		for (int32 i < mesh.VertexCount)
		{
			let joints = (uint16*)(mesh.VertexData + (int)i * 36 + 12);
			Test.Assert(joints[0] == 7, scope $"vertex {i} joint");
			Test.Assert((joints[1] == 0) && (joints[2] == 0) && (joints[3] == 0));

			let weights = (float*)(mesh.VertexData + (int)i * 36 + 20);
			Test.Assert(weights[0] == 1.0f, "fully weighted to the one joint");
			Test.Assert((weights[1] == 0.0f) && (weights[2] == 0.0f) && (weights[3] == 0.0f));
		}

		// The positions came through the widening unchanged.
		let positions = (Float3*)mesh.VertexData;
		Test.Assert(Near(positions[0].X, 0.0f));
		let second = (Float3*)(mesh.VertexData + 36);
		Test.Assert(Near(second.X, 2.0f), "the second vertex is at the new stride");
	}

	/// Applying it twice would double the skinning data and leave the second copy unread,
	/// so a mesh that already has joints is left alone.
	[Test]
	public static void UniformSkinningIsNotAppliedTwice()
	{
		let mesh = BuildTriangle();
		defer delete mesh;

		mesh.AddUniformSkinning(1);
		let stride = mesh.VertexStride;
		let elements = mesh.VertexElements.Length;

		mesh.AddUniformSkinning(2);

		Test.Assert(mesh.VertexStride == stride, "it did not widen again");
		Test.Assert(mesh.VertexElements.Length == elements);
		let joints = (uint16*)(mesh.VertexData + 12);
		Test.Assert(joints[0] == 1, "and the original joint was kept");
	}

	[Test]
	public static void JointIndicesAreRemappedThroughTheMapping()
	{
		let mesh = BuildTriangle();
		defer delete mesh;
		mesh.AddUniformSkinning(1);

		// Joint 1 becomes joint 5.
		int32[3] remap = .(9, 5, 9);
		mesh.RemapJointIndices(.(&remap[0], 3));

		for (int32 i < mesh.VertexCount)
		{
			let joints = (uint16*)(mesh.VertexData + (int)i * 36 + 12);
			Test.Assert(joints[0] == 5, scope $"vertex {i} was not remapped");
			Test.Assert(joints[1] == 9, "the unused slots map through zero as well");
		}
	}

	/// An index outside the mapping keeps its value rather than being remapped to nothing.
	/// It stays wrong somewhere visible instead of silently binding to joint zero.
	[Test]
	public static void AJointOutsideTheMappingIsLeftAlone()
	{
		let mesh = BuildTriangle();
		defer delete mesh;
		mesh.AddUniformSkinning(40);

		int32[2] remap = .(0, 1);
		mesh.RemapJointIndices(.(&remap[0], 2));

		let joints = (uint16*)(mesh.VertexData + 12);
		Test.Assert(joints[0] == 40, "joint 40 is past the end of a two entry mapping");
	}

	/// Remapping a mesh with no joints does nothing, rather than rewriting whatever sits
	/// where joints would have been.
	[Test]
	public static void RemappingAMeshWithoutJointsDoesNothing()
	{
		let mesh = BuildTriangle();
		defer delete mesh;

		int32[2] remap = .(1, 1);
		mesh.RemapJointIndices(.(&remap[0], 2));

		let positions = (Float3*)mesh.VertexData;
		Test.Assert(Near(positions[1].X, 2.0f), "the vertex data is untouched");
	}
}
