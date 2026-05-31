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

	/// Layer mask for visibility filtering. Bitwise AND against the active
	/// pass's `PerFrameResources.CurrentLayerMask` determines whether this
	/// entry is rendered. Defaults to "in every layer" - the metal sphere
	/// and other glossy meshes clear the high bit so ProbeCapturePass (which
	/// sets CurrentLayerMask = 0x7FFFFFFF for its captures) excludes them
	/// from the cubemap, preventing self-reflection feedback.
	public uint32 LayerMask = 0xFFFFFFFF;
}
