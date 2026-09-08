using System;
using Sedulous.RHI;

namespace Sedulous.Materials;

/// The predefined vertex layouts, as concrete RHI attributes and strides.
///
/// ONE place that says what a mesh vertex looks like. A renderer, a pipeline builder and a
/// geometry cook all read it here, so a layout change is one edit rather than three that
/// have to agree.
static class VertexLayouts
{
	private static VertexAttribute[1] cPositionOnly = .(
		.(.Float32x3, 0, 0));

	private static VertexAttribute[3] cPositionUVColor = .(
		.(.Float32x3, 0, 0), .(.Float32x2, 12, 1), .(.Float32x4, 20, 2));

	private static VertexAttribute[3] cMeshNoTangent = .(
		.(.Float32x3, 0, 0), .(.Float32x3, 12, 1), .(.Float32x2, 24, 2));

	/// Position, normal, uv, a packed colour, and a tangent whose fourth component carries
	/// the handedness.
	private static VertexAttribute[5] cMesh = .(
		.(.Float32x3, 0, 0), .(.Float32x3, 12, 1), .(.Float32x2, 24, 2),
		.(.Unorm8x4, 32, 3), .(.Float32x4, 36, 4));

	/// Joints packed as two uint32s, then weights. At locations SIX and SEVEN because a
	/// skinned draw is always instanced, so the per instance data offsets take five, and
	/// the compiler assigns locations in declaration order.
	private static VertexAttribute[2] cSkinningStream = .(
		.(.Uint32x2, 0, 6), .(.Float32x4, 8, 7));

	/// The per instance data offsets, at location five.
	private static VertexAttribute[1] cInstanceOffsets = .(
		.(.Uint32x4, 0, 5));

	public static uint32 Stride(VertexLayoutType layout)
	{
		switch (layout)
		{
		case .None: return 0;
		case .PositionOnly: return 12;
		case .PositionUVColor: return 36;
		case .MeshNoTangent: return 32;
		case .Mesh: return 52;
		// A skinned mesh's buffer zero IS the static stream: the skinning data lives in a
		// SEPARATE buffer, which mirrors how a skinned mesh extends a static one in the
		// geometry module. So a skinned draw binds two vertex buffers.
		case .SkinnedMesh: return 52;
		// The caller supplies its own, so there is nothing predefined to report.
		case .Custom: return 0;
		}
	}

	public static Span<VertexAttribute> Attributes(VertexLayoutType layout)
	{
		switch (layout)
		{
		case .PositionOnly: return .(&cPositionOnly[0], cPositionOnly.Count);
		case .PositionUVColor: return .(&cPositionUVColor[0], cPositionUVColor.Count);
		case .MeshNoTangent: return .(&cMeshNoTangent[0], cMeshNoTangent.Count);
		case .Mesh, .SkinnedMesh: return .(&cMesh[0], cMesh.Count);
		case .None, .Custom: return .();
		}
	}

	public static VertexBufferLayout BufferLayout(VertexLayoutType layout)
	{
		var result = VertexBufferLayout();
		result.Stride = Stride(layout);
		result.StepMode = .Vertex;
		result.Attributes = Attributes(layout);
		return result;
	}

	/// The instance stepped buffer an instanced draw binds: one uint4 of data offsets per
	/// instance, whose first component indexes a per instance structured buffer.
	///
	/// Hardware instance stepping rather than the instance id system value, because the two
	/// backends disagree about what that value counts from, and a vertex attribute does not
	/// have that problem.
	public static VertexBufferLayout InstanceOffsetsBufferLayout()
	{
		var result = VertexBufferLayout();
		result.Stride = 16;
		result.StepMode = .Instance;
		result.Attributes = .(&cInstanceOffsets[0], cInstanceOffsets.Count);
		return result;
	}

	public static uint32 SkinningStreamStride() => 24;

	public static Span<VertexAttribute> SkinningStreamAttributes()
		=> .(&cSkinningStream[0], cSkinningStream.Count);

	public static VertexBufferLayout SkinningStreamBufferLayout()
	{
		var result = VertexBufferLayout();
		result.Stride = SkinningStreamStride();
		result.StepMode = .Vertex;
		result.Attributes = SkinningStreamAttributes();
		return result;
	}
}
