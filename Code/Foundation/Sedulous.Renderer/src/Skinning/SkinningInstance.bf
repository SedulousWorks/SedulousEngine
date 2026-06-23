namespace Sedulous.Renderer;

using Sedulous.RHI;

/// Per-skinned-mesh GPU resources for compute skinning.
/// Owned by SkinningSystem. One instance per visible skinned mesh.
///
/// A.4 removed the per-instance ParamsBuffer + BindGroup: all params now
/// live in the frame-scoped SkinningRecords buffer, and a single mega bind
/// group bound at DispatchAllForView start covers every dispatch.
class SkinningInstance
{
	/// Sub-range of SkinningSystem.OutputPool where this instance's
	/// skinned vertices live. The pool owns the actual VkBuffer; this
	/// instance just holds the offset+size.
	public uint64 OutputOffset;
	public uint64 OutputSize;

	/// Source vertex buffer reference (NOT owned - from GPUMesh; for skinned
	/// meshes this is the shared SkinnedSourceVertexPool buffer).
	public IBuffer SourceVertexBuffer;

	/// Byte offset of this mesh's source vertices within SourceVertexBuffer.
	public uint64 SourceVertexOffset;

	/// Bone matrix buffer handle (NOT owned - from GPUResourceManager).
	public GPUBoneBufferHandle BoneBufferHandle;

	/// Number of vertices.
	public int32 VertexCount;

	/// Number of bones.
	public int32 BoneCount;

	/// Whether this instance is active this frame.
	public bool Active;

	/// Returns the output sub-range to the pool. Caller must pass the pool
	/// that originally allocated the range.
	public void Release(IDevice device, SkinnedVertexPool outputPool)
	{
		if (device == null) return;

		if (outputPool != null && OutputSize > 0)
		{
			outputPool.Free(OutputOffset, OutputSize);
			OutputSize = 0;
		}
	}
}
