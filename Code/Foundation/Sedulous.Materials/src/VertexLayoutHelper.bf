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

	/// SkinnedMesh: Mesh attributes + JointIndices (uint4) + JointWeights (float4)
	public static VertexAttribute[7] SkinnedMeshAttributes = .(
		.(VertexFormat.Float32x3, 0, 0),   // Position
		.(VertexFormat.Float32x3, 12, 1),  // Normal
		.(VertexFormat.Float32x2, 24, 2),  // UV
		.(VertexFormat.Unorm8x4, 32, 3), // Color
		.(VertexFormat.Float32x3, 36, 4),  // Tangent
		.(VertexFormat.Uint32x4, 48, 5),   // Joint Indices
		.(VertexFormat.Float32x4, 64, 6)   // Joint Weights
	);

	/// Instance data: 4 x float4 (world matrix rows) - for GPU instancing
	/// Used as second vertex buffer with per-instance step rate
	/// Instance data starts at location 5 (after Position=0, Normal=1, UV=2, Color=3, Tangent=4)
	/// Use CreateInstanceDataAttributes() to get attributes at a custom starting location if needed.
	public static VertexAttribute[4] InstanceDataAttributes = .(
		.(VertexFormat.Float32x4, 0, 5),   // WorldRow0 (location 5)
		.(VertexFormat.Float32x4, 16, 6),  // WorldRow1 (location 6)
		.(VertexFormat.Float32x4, 32, 7),  // WorldRow2 (location 7)
		.(VertexFormat.Float32x4, 48, 8)   // WorldRow3 (location 8)
	);

	/// Instance data stride (4 x float4 = 64 bytes).
	public const uint32 InstanceDataStride = 64;

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
		case .SkinnedMesh: return 80;        // Mesh + uint4 + float4
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

	/// Creates instance data attributes at a given starting location.
	/// Use this when the shader has a different number of per-vertex attributes.
	/// For a depth shader (Position, Normal, UV), startLocation should be 3.
	/// For a forward shader with tangent (Position, Normal, UV, Tangent), startLocation should be 4.
	public static void CreateInstanceDataAttributes(uint32 startLocation, out VertexAttribute[4] outAttributes)
	{
		outAttributes = .(
			.(VertexFormat.Float32x4, 0, startLocation),       // WorldRow0
			.(VertexFormat.Float32x4, 16, startLocation + 1),  // WorldRow1
			.(VertexFormat.Float32x4, 32, startLocation + 2),  // WorldRow2
			.(VertexFormat.Float32x4, 48, startLocation + 3)   // WorldRow3
		);
	}

	/// Creates an instance buffer layout for GPU instancing.
	/// The instance buffer uses per-instance step mode (advances once per instance, not per vertex).
	public static VertexBufferLayout CreateInstanceBufferLayout()
	{
		return .(InstanceDataStride, InstanceDataAttributes, .Instance);
	}

	/// Creates an instance buffer layout at a custom starting location.
	public static VertexBufferLayout CreateInstanceBufferLayoutAt(uint32 startLocation)
	{
		VertexAttribute[4] attrs = default;
		CreateInstanceDataAttributes(startLocation, out attrs);
		return .(InstanceDataStride, attrs, .Instance);
	}

	/// Creates a vertex buffer layout array for instanced mesh rendering.
	/// First buffer is per-vertex mesh data, second buffer is per-instance data.
	public static void CreateInstancedMeshLayout(
		VertexLayoutType vertexLayout,
		out VertexBufferLayout[2] outLayouts)
	{
		outLayouts = .(
			CreateBufferLayout(vertexLayout),
			CreateInstanceBufferLayout()
		);
	}
}
