namespace Sedulous.Materials;

using System;
using Sedulous.RHI;

/// Helper for converting VertexLayoutType to RHI vertex descriptors.
public static class VertexLayoutHelper
{
	/// Vertex attribute definitions for each layout type.

	/// PositionOnly: Position (float3)
	public static VertexAttribute[1] PositionOnlyAttributes = .(
		.(VertexFormat.Float32x3, 0, 0)   // Position
	);

	/// PositionUVColor: Position (float3) + UV (float2) + Color (float4)
	public static VertexAttribute[3] PositionUVColorAttributes = .(
		.(VertexFormat.Float32x3, 0, 0),   // Position
		.(VertexFormat.Float32x2, 12, 1),  // UV
		.(VertexFormat.Float32x4, 20, 2)   // Color
	);

	/// MeshNoTangent: Position (float3) + Normal (float3) + UV (float2) - simple format without tangent
	public static VertexAttribute[3] MeshNoTangentAttributes = .(
		.(VertexFormat.Float32x3, 0, 0),   // Position
		.(VertexFormat.Float32x3, 12, 1),  // Normal
		.(VertexFormat.Float32x2, 24, 2)   // UV
	);

	/// Mesh: Position (float3) + Normal (float3) + UV (float2) + Color (ubyte4) + Tangent (float3)
	/// Matches Sedulous.Geometry.StaticMesh.SetupCommonVertexFormat() - 48 bytes
	public static VertexAttribute[5] MeshAttributes = .(
		.(VertexFormat.Float32x3, 0, 0),   // Position
		.(VertexFormat.Float32x3, 12, 1),  // Normal
		.(VertexFormat.Float32x2, 24, 2),  // UV
		.(VertexFormat.Unorm8x4, 32, 3), // Color
		.(VertexFormat.Float32x3, 36, 4)   // Tangent (float3)
	);

	/// SkinnedMesh: Mesh attributes + JointIndices (2x uint32 = 4x uint16 packed) + JointWeights (float4)
	/// 72 bytes total. Bone indices packed as 4x uint16 in 2x uint32 for memory savings.
	public static VertexAttribute[7] SkinnedMeshAttributes = .(
		.(VertexFormat.Float32x3, 0, 0),   // Position
		.(VertexFormat.Float32x3, 12, 1),  // Normal
		.(VertexFormat.Float32x2, 24, 2),  // UV
		.(VertexFormat.Unorm8x4, 32, 3),   // Color
		.(VertexFormat.Float32x3, 36, 4),  // Tangent
		.(VertexFormat.Uint32x2, 48, 5),   // Joint Indices (4x uint16 packed in 2x uint32)
		.(VertexFormat.Float32x4, 56, 6)   // Joint Weights
	);

	/// Per-instance DataOffsets attribute: uint4 of indices into per-frame data buffers.
	/// Bound as a second vertex buffer at slot 1 with per-instance step rate.
	/// Used by the instanced mesh path; .x = entity index into Instances[], .y/.z/.w reserved
	/// for future per-instance buffers (custom data, material data, skinning).
	/// Starts at location 5 (after Position=0, Normal=1, UV=2, Color=3, Tangent=4).
	public static VertexAttribute[1] DataOffsetsAttributes = .(
		.(VertexFormat.Uint32x4, 0, 5)
	);

	/// DataOffsets stride (1 x uint4 = 16 bytes).
	public const uint32 DataOffsetsStride = 16;

	/// Gets the vertex stride for a layout type.
	public static uint32 GetStride(VertexLayoutType layoutType)
	{
		switch (layoutType)
		{
		case .None: return 0;
		case .PositionOnly: return 12;       // float3
		case .PositionUVColor: return 36;    // float3 + float2 + float4
		case .MeshNoTangent: return 32;      // float3 + float3 + float2
		case .Mesh: return 48;               // float3 + float3 + float2 + ubyte4 + float3
		case .SkinnedMesh: return 72;        // Mesh + uint2(packed uint16x4) + float4
		case .Custom: return 0;              // Custom layouts define their own stride
		}
	}

	/// Gets the number of vertex attributes for a layout type.
	public static uint32 GetAttributeCount(VertexLayoutType layoutType)
	{
		switch (layoutType)
		{
		case .None: return 0;
		case .PositionOnly: return 1;
		case .PositionUVColor: return 3;
		case .MeshNoTangent: return 3;
		case .Mesh: return 5;
		case .SkinnedMesh: return 7;
		case .Custom: return 0;
		}
	}

	/// Gets vertex attributes as a span for a layout type.
	public static Span<VertexAttribute> GetAttributes(VertexLayoutType layoutType)
	{
		switch (layoutType)
		{
		case .None: return default;
		case .PositionOnly: return PositionOnlyAttributes;
		case .PositionUVColor: return PositionUVColorAttributes;
		case .MeshNoTangent: return MeshNoTangentAttributes;
		case .Mesh: return MeshAttributes;
		case .SkinnedMesh: return SkinnedMeshAttributes;
		case .Custom: return default;
		}
	}

	/// Creates a VertexBufferLayout for a layout type.
	public static VertexBufferLayout CreateBufferLayout(VertexLayoutType layoutType)
	{
		let stride = GetStride(layoutType);
		let attrs = GetAttributes(layoutType);
		return .(stride, attrs);
	}

	/// Fills an output array with vertex attributes for the given layout type.
	/// Returns the number of attributes written.
	public static int FillAttributes(VertexLayoutType layoutType, Span<VertexAttribute> outAttributes)
	{
		let attrs = GetAttributes(layoutType);
		let count = Math.Min(attrs.Length, outAttributes.Length);

		for (int i = 0; i < count; i++)
			outAttributes[i] = attrs[i];

		return count;
	}

	/// Creates a vertex buffer layout array with a single layout.
	public static void CreateSingleBufferLayout(
		VertexLayoutType layoutType,
		out VertexBufferLayout[1] outLayouts)
	{
		outLayouts = .(CreateBufferLayout(layoutType));
	}

	/// Creates a DataOffsets vertex buffer layout for instanced mesh rendering.
	/// Single uint4 attribute at location 5, per-instance step rate.
	public static VertexBufferLayout CreateDataOffsetsBufferLayout()
	{
		return .(DataOffsetsStride, DataOffsetsAttributes, .Instance);
	}

	/// Creates a vertex buffer layout array for instanced mesh rendering.
	/// First buffer is per-vertex mesh data, second buffer is per-instance DataOffsets.
	public static void CreateInstancedMeshLayout(
		VertexLayoutType vertexLayout,
		out VertexBufferLayout[2] outLayouts)
	{
		outLayouts = .(
			CreateBufferLayout(vertexLayout),
			CreateDataOffsetsBufferLayout()
		);
	}
}
