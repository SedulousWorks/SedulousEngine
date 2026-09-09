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

	public this() {}
}
