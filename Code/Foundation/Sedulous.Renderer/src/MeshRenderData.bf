namespace Sedulous.Renderer;

using Sedulous.Core.Mathematics;
using Sedulous.RHI;

/// Render data for a static mesh draw call.
/// One MeshRenderData per submesh per material slot.
struct MeshRenderData
{
	/// Base render data (position, bounds, sorting).
	public RenderData Base;

	/// World transform matrix.
	public Matrix WorldMatrix;

	/// Previous frame world transform (for motion vectors).
	public Matrix PrevWorldMatrix;

	/// GPU mesh handle (resolved to vertex/index buffers at draw time via GPUResourceManager).
	public GPUMeshHandle MeshHandle;

	/// Submesh index within the mesh.
	public uint32 SubMeshIndex;

	/// Material bind group (set 2: textures, params, samplers).
	public IBindGroup MaterialBindGroup;

	/// Material sort key for batching.
	public uint32 MaterialKey;
}
