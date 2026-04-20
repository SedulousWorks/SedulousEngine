namespace Sedulous.Renderer;

using Sedulous.Core.Mathematics;
using Sedulous.RHI;

/// Render data for a static or skinned mesh draw call.
/// One MeshRenderData per submesh per material slot.
///
/// Allocated from RenderContext.FrameAllocator - trivially destructible.
public class MeshRenderData : RenderData
{
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

	/// Bone matrix buffer handle (for skinned meshes).
	public GPUBoneBufferHandle BoneBufferHandle;

	/// Whether this mesh is skinned (needs compute skinning pass).
	public bool IsSkinned;
}
