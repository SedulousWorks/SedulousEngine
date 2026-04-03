namespace Sedulous.RHI.Null;

using System;

class NullCommandPool : ICommandPool
{
	public Result<ICommandEncoder> CreateEncoder()
	{
		return .Ok(new NullCommandEncoder());
	}

	public void DestroyEncoder(ref ICommandEncoder encoder)
	{
		if (encoder != null)
		{
			delete encoder;
			encoder = null;
		}
	}

	public void Reset() { }
}

class NullCommandBuffer : ICommandBuffer
{
}

class NullCommandEncoder : ICommandEncoder, IRayTracingEncoderExt
{
	private NullRenderPassEncoder mRenderPassEncoder = new .() ~ delete _;
	private NullComputePassEncoder mComputePassEncoder = new .() ~ delete _;
	private NullCommandBuffer mCommandBuffer = new .() ~ delete _;

	public IRenderPassEncoder BeginRenderPass(RenderPassDesc desc) => mRenderPassEncoder;
	public IComputePassEncoder BeginComputePass(StringView label = default) => mComputePassEncoder;

	public void Barrier(BarrierGroup barriers) { }
	public void CopyBufferToBuffer(IBuffer src, uint64 srcOffset, IBuffer dst, uint64 dstOffset, uint64 size) { }
	public void CopyBufferToTexture(IBuffer src, ITexture dst, BufferTextureCopyRegion region) { }
	public void CopyTextureToBuffer(ITexture src, IBuffer dst, BufferTextureCopyRegion region) { }
	public void CopyTextureToTexture(ITexture src, ITexture dst, TextureCopyRegion region) { }
	public void Blit(ITexture src, ITexture dst) { }
	public void GenerateMipmaps(ITexture texture) { }
	public void ResolveTexture(ITexture src, ITexture dst) { }
	public void ResetQuerySet(IQuerySet querySet, uint32 first, uint32 count) { }
	public void WriteTimestamp(IQuerySet querySet, uint32 index) { }
	public void ResolveQuerySet(IQuerySet querySet, uint32 first, uint32 count, IBuffer dst, uint64 dstOffset) { }
	public void BeginDebugLabel(StringView label, float r = 0, float g = 0, float b = 0, float a = 1) { }
	public void EndDebugLabel() { }
	public void InsertDebugLabel(StringView label, float r = 0, float g = 0, float b = 0, float a = 1) { }
	public ICommandBuffer Finish() => mCommandBuffer;

	// ===== IRayTracingEncoderExt =====

	public void BuildBottomLevelAccelStruct(
		IAccelStruct dst, IBuffer scratchBuffer, uint64 scratchOffset,
		Span<AccelStructGeometryTriangles> triangleGeometries,
		Span<AccelStructGeometryAABBs> aabbGeometries) { }

	public void BuildTopLevelAccelStruct(
		IAccelStruct dst, IBuffer scratchBuffer, uint64 scratchOffset,
		IBuffer instanceBuffer, uint64 instanceOffset, uint32 instanceCount) { }

	public void SetRayTracingPipeline(IRayTracingPipeline pipeline) { }
	public void SetBindGroup(uint32 index, IBindGroup bindGroup, Span<uint32> dynamicOffsets = default) { }
	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data) { }

	public void TraceRays(
		IBuffer raygenSBT, uint64 raygenOffset, uint64 raygenStride,
		IBuffer missSBT, uint64 missOffset, uint64 missStride,
		IBuffer hitSBT, uint64 hitOffset, uint64 hitStride,
		uint32 width, uint32 height, uint32 depth = 1) { }
}

class NullRenderPassEncoder : IRenderPassEncoder, IMeshShaderPassExt
{
	public void SetPipeline(IRenderPipeline pipeline) { }
	public void SetBindGroup(uint32 index, IBindGroup bindGroup, Span<uint32> dynamicOffsets = default) { }
	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data) { }
	public void SetVertexBuffer(uint32 slot, IBuffer buffer, uint64 offset = 0) { }
	public void SetIndexBuffer(IBuffer buffer, IndexFormat format, uint64 offset = 0) { }
	public void SetViewport(float x, float y, float w, float h, float minDepth, float maxDepth) { }
	public void SetScissor(int32 x, int32 y, uint32 w, uint32 h) { }
	public void SetBlendConstant(float r, float g, float b, float a) { }
	public void SetStencilReference(uint32 reference) { }
	public void Draw(uint32 vertexCount, uint32 instanceCount = 1, uint32 firstVertex = 0, uint32 firstInstance = 0) { }
	public void DrawIndexed(uint32 indexCount, uint32 instanceCount = 1, uint32 firstIndex = 0, int32 baseVertex = 0, uint32 firstInstance = 0) { }
	public void DrawIndirect(IBuffer buffer, uint64 offset, uint32 drawCount = 1, uint32 stride = 0) { }
	public void DrawIndexedIndirect(IBuffer buffer, uint64 offset, uint32 drawCount = 1, uint32 stride = 0) { }
	public void WriteTimestamp(IQuerySet querySet, uint32 index) { }
	public void BeginOcclusionQuery(IQuerySet querySet, uint32 index) { }
	public void EndOcclusionQuery(IQuerySet querySet, uint32 index) { }
	public void End() { }

	// ===== IMeshShaderPassExt =====

	public void SetMeshPipeline(IMeshPipeline pipeline) { }
	public void DrawMeshTasks(uint32 groupCountX, uint32 groupCountY = 1, uint32 groupCountZ = 1) { }
	public void DrawMeshTasksIndirect(IBuffer buffer, uint64 offset, uint32 drawCount = 1, uint32 stride = 0) { }
	public void DrawMeshTasksIndirectCount(IBuffer buffer, uint64 offset,
		IBuffer countBuffer, uint64 countOffset,
		uint32 maxDrawCount, uint32 stride) { }
}

class NullComputePassEncoder : IComputePassEncoder
{
	public void SetPipeline(IComputePipeline pipeline) { }
	public void SetBindGroup(uint32 index, IBindGroup bindGroup, Span<uint32> dynamicOffsets = default) { }
	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data) { }
	public void Dispatch(uint32 x, uint32 y = 1, uint32 z = 1) { }
	public void DispatchIndirect(IBuffer buffer, uint64 offset) { }
	public void ComputeBarrier() { }
	public void WriteTimestamp(IQuerySet querySet, uint32 index) { }
	public void End() { }
}
