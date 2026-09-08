using System;
using Sedulous.Materials;
using Sedulous.RHI;

namespace Sedulous.Materials.Tests;

/// The predefined vertex layouts: the ONE place that says what a mesh vertex looks like.
class VertexLayoutTests
{
	[Test]
	public static void TheStridesMatchTheAttributesTheyDescribe()
	{
		Test.Assert(VertexLayouts.Stride(.None) == 0);
		Test.Assert(VertexLayouts.Stride(.PositionOnly) == 12);
		Test.Assert(VertexLayouts.Stride(.PositionUVColor) == 36);
		Test.Assert(VertexLayouts.Stride(.MeshNoTangent) == 32);
		Test.Assert(VertexLayouts.Stride(.Mesh) == 52);
		// The static stream: the skinning data is a SEPARATE buffer.
		Test.Assert(VertexLayouts.Stride(.SkinnedMesh) == 52);
		// The caller supplies its own, so there is nothing predefined to report.
		Test.Assert(VertexLayouts.Stride(.Custom) == 0);
	}

	[Test]
	public static void TheMeshLayoutIsPositionNormalUvColourTangent()
	{
		let attributes = VertexLayouts.Attributes(.Mesh);
		Test.Assert(attributes.Length == 5);

		Test.Assert((attributes[0].Format == .Float32x3) && (attributes[0].Offset == 0));
		Test.Assert((attributes[1].Format == .Float32x3) && (attributes[1].Offset == 12));
		Test.Assert((attributes[2].Format == .Float32x2) && (attributes[2].Offset == 24));
		Test.Assert((attributes[3].Format == .Unorm8x4) && (attributes[3].Offset == 32));
		// The fourth component is the handedness, which is why the tangent is a float4.
		Test.Assert((attributes[4].Format == .Float32x4) && (attributes[4].Offset == 36));

		for (int i = 0; i < attributes.Length; i++)
			Test.Assert(attributes[i].ShaderLocation == (uint32)i);
	}

	/// Every attribute has to FIT the stride it is declared against, which is the check
	/// that catches a layout edited on one side only.
	[Test]
	public static void EveryAttributeFitsInsideItsStride()
	{
		for (let layout in scope VertexLayoutType[](
			.PositionOnly, .PositionUVColor, .MeshNoTangent, .Mesh, .SkinnedMesh))
		{
			let stride = VertexLayouts.Stride(layout);
			for (let attribute in VertexLayouts.Attributes(layout))
				Test.Assert(attribute.Offset < stride, "an attribute past the end of a vertex");
		}
	}

	[Test]
	public static void TheLayoutsWithNoVertexInputHaveNoAttributes()
	{
		Test.Assert(VertexLayouts.Attributes(.None).IsEmpty);
		Test.Assert(VertexLayouts.Attributes(.Custom).IsEmpty);
	}

	/// A skinned draw binds buffer zero as the static stream, so the two share attributes.
	[Test]
	public static void ASkinnedMeshSharesTheStaticStream()
	{
		let mesh = VertexLayouts.Attributes(.Mesh);
		let skinned = VertexLayouts.Attributes(.SkinnedMesh);
		Test.Assert(mesh.Length == skinned.Length);
		Test.Assert(mesh.Ptr == skinned.Ptr, "the same table, not a copy of it");
	}

	/// The skinning stream sits at locations six and seven, because a skinned draw is
	/// always instanced and the per instance offsets take five.
	[Test]
	public static void TheSkinningStreamAvoidsTheInstanceLocation()
	{
		let layout = VertexLayouts.SkinningStreamBufferLayout();
		Test.Assert(layout.Stride == 24);
		Test.Assert(layout.StepMode == .Vertex, "joints are per vertex, not per instance");
		Test.Assert(layout.Attributes.Length == 2);
		Test.Assert(layout.Attributes[0].ShaderLocation == 6);
		Test.Assert(layout.Attributes[1].ShaderLocation == 7);

		let instances = VertexLayouts.InstanceOffsetsBufferLayout();
		Test.Assert(instances.Attributes[0].ShaderLocation == 5, "the one they step around");
	}

	/// The instance stream is INSTANCE stepped, which is the whole reason it exists: the
	/// instance id system value counts from different places on the two backends, and a
	/// vertex attribute does not have that problem.
	[Test]
	public static void TheInstanceStreamStepsPerInstance()
	{
		let layout = VertexLayouts.InstanceOffsetsBufferLayout();
		Test.Assert(layout.Stride == 16);
		Test.Assert(layout.StepMode == .Instance);
		Test.Assert(layout.Attributes.Length == 1);
		Test.Assert(layout.Attributes[0].Format == .Uint32x4);
	}

	[Test]
	public static void ABufferLayoutCarriesItsOwnStrideAndAttributes()
	{
		let layout = VertexLayouts.BufferLayout(.PositionUVColor);
		Test.Assert(layout.Stride == 36);
		Test.Assert(layout.StepMode == .Vertex);
		Test.Assert(layout.Attributes.Length == 3);
	}
}
