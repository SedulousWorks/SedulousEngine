using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.RHI;

namespace Sedulous.Render;

/// Where one mesh lives on the GPU, ready to bind and draw.
///
/// The buffers are POOLED and shared, so a mesh is a pair of offsets into them rather than a
/// pair of buffers of its own. A skinned mesh carries a parallel skinning stream in a second
/// vertex buffer, which the skinned pipeline binds beside the first.
struct GpuMesh
{
	public IBuffer VertexBuffer = null;
	public uint64 VertexOffset = 0;

	public IBuffer IndexBuffer = null;
	public uint64 IndexOffset = 0;
	public uint32 IndexCount = 0;
	public IndexFormat IndexFormat = .UInt32;

	/// Null for a static mesh.
	public IBuffer SkinBuffer = null;
	public uint64 SkinOffset = 0;

	/// The depth only stream of a static mesh (position + uv, DepthStreamStride bytes a vertex,
	/// VertexLayoutType.DepthStream): what its shadow and depth prepass draws read, a fraction
	/// of the full vertex. Null for a skinned mesh, whose depth draws take the full stream.
	public IBuffer DepthBuffer = null;
	public uint64 DepthOffset = 0;

	/// Bytes a vertex takes in a mesh's depth stream: float3 position, float2 uv.
	public const uint32 DepthStreamStride = 20;

	/// A static mesh's depth stream, built from its full vertices: each one's position and uv,
	/// packed.
	public static void BuildDepthStream(Span<StaticMeshVertex> vertices, List<uint8> outStream)
	{
		outStream.Count = vertices.Length * DepthStreamStride;
		var p = outStream.Ptr;
		for (let v in vertices)
		{
			*(Float3*)p = v.Position;
			*(Float2*)(p + 12) = v.TexCoord;
			p += DepthStreamStride;
		}
	}

	public this() {}
}
