namespace Sedulous.Renderer;

using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.Materials;

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

	/// Per-instance color tint. Multiplied with vertex color + material
	/// albedo in the shader, with alpha folded into final fragment alpha.
	/// Default (1, 1, 1, 1) is a no-op (existing meshes look unchanged).
	/// Used by mesh-particle extraction (per-particle Color stream) and
	/// per-entity tinting via MeshComponent.Color / SkinnedMeshComponent.Color
	/// (damage flash, team colors, status-effect overlays without
	/// duplicating MaterialInstances).
	public Vector4 InstanceColor = .(1, 1, 1, 1);

	/// GPU mesh handle (resolved to vertex/index buffers at draw time via GPUResourceManager).
	public GPUMeshHandle MeshHandle;

	/// Submesh index within the mesh.
	public uint32 SubMeshIndex;

	/// Material bind group (set 2: textures, params, samplers).
	public IBindGroup MaterialBindGroup;

	/// Material bind group layout (needed for pipeline creation).
	public IBindGroupLayout MaterialBindGroupLayout;

	/// Material's pipeline config (cull mode, blend mode, shader flags, etc.).
	/// Used by MeshRenderer to create the correct pipeline variant per material.
	public PipelineConfig MaterialPipelineConfig;

	/// Material sort key for batching.
	public uint32 MaterialKey;

	/// Bone matrix buffer handle (for skinned meshes).
	public GPUBoneBufferHandle BoneBufferHandle;

	/// Whether this mesh is skinned (needs compute skinning pass).
	public bool IsSkinned;

	/// Entity index for GPU picking (encoded as color in pick pass).
	public uint32 EntityIndex;

	/// Index (in matrix units, not bytes) into the global bone matrix pool
	/// where this skinned instance's bone matrices begin. Populated during
	/// extraction for skinned meshes; zero for static meshes. Flowed to the
	/// vertex shader via DataOffsets.y so the skinned vertex variant can
	/// fetch its own slab from BoneMatrices[boneStart + jointIndex].
	public uint32 BoneStartIndex;

	/// Previous frame's BoneStartIndex. Same pool, same matrix-units,
	/// just the offset for the prev-frame bones (the bone pool stores
	/// current then previous frames per skeleton). Used by the skinned
	/// vertex variant to compute the prev clip-space position for motion
	/// vectors / per-bone motion blur. Zero for static.
	public uint32 PrevBoneStartIndex;
}
