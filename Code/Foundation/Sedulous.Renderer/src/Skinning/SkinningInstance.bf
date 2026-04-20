namespace Sedulous.Renderer;

using Sedulous.RHI;

/// Per-skinned-mesh GPU resources for compute skinning.
/// Owned by SkinningSystem. One instance per visible skinned mesh.
class SkinningInstance
{
	/// Uniform buffer with vertex count and bone count.
	public IBuffer ParamsBuffer;

	/// Output buffer: skinned vertices (48 bytes/vertex, Mesh layout).
	public IBuffer SkinnedVertexBuffer;

	/// Bind group for compute dispatch.
	public IBindGroup BindGroup;

	/// Source vertex buffer reference (NOT owned - from GPUMesh).
	public IBuffer SourceVertexBuffer;

	/// Bone matrix buffer handle (NOT owned - from GPUResourceManager).
	public GPUBoneBufferHandle BoneBufferHandle;

	/// Number of vertices.
	public int32 VertexCount;

	/// Number of bones.
	public int32 BoneCount;

	/// Whether the bind group needs rebuilding (bone buffer changed, etc.)
	public bool BindGroupDirty = true;

	/// Whether this instance is active this frame.
	public bool Active;

	/// Frees owned GPU resources.
	public void Release(IDevice device)
	{
		if (device == null) return;

		if (BindGroup != null)
			device.DestroyBindGroup(ref BindGroup);
		if (SkinnedVertexBuffer != null)
			device.DestroyBuffer(ref SkinnedVertexBuffer);
		if (ParamsBuffer != null)
			device.DestroyBuffer(ref ParamsBuffer);
	}
}
