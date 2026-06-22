namespace Sedulous.Renderer;

using Sedulous.RHI;

/// Per-skinned-mesh GPU resources for compute skinning.
/// Owned by SkinningSystem. One instance per visible skinned mesh.
class SkinningInstance
{
	/// Uniform buffer with vertex count and bone count.
	public IBuffer ParamsBuffer;

	/// Sub-range of SkinningSystem.OutputPool where this instance's
	/// skinned vertices live. The pool owns the actual VkBuffer; this
	/// instance just holds the offset+size.
	public uint64 OutputOffset;
	public uint64 OutputSize;

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

	/// Releases owned GPU resources and returns the output sub-range to the
	/// pool. Caller must pass the pool that originally allocated the range.
	public void Release(IDevice device, SkinnedVertexPool outputPool)
	{
		if (device == null) return;

		if (BindGroup != null)
			device.DestroyBindGroup(ref BindGroup);
		if (ParamsBuffer != null)
			device.DestroyBuffer(ref ParamsBuffer);
		if (outputPool != null && OutputSize > 0)
		{
			outputPool.Free(OutputOffset, OutputSize);
			OutputSize = 0;
		}
	}
}
