using System;
using Sedulous.RHI;

namespace Sedulous.RHI.Null;

/// Records nothing, and implements the ray tracing seam so a caller casting to
/// IRayTracingEncoderExt succeeds.
///
/// It OWNS one of each sub encoder and hands the same one back every time. A stub has no
/// per pass state to keep apart, and reusing them keeps the null backend allocation free
/// once a pool exists, which is what a headless test loop wants.
class NullCommandEncoder : ICommandEncoder, IRayTracingEncoderExt
{
	private NullRenderPassEncoder mRenderPass = new .() ~ delete _;
	private NullComputePassEncoder mComputePass = new .() ~ delete _;
	private NullRenderBundleEncoder mBundleEncoder = new .() ~ delete _;
	private NullCommandBuffer mCommandBuffer = new .() ~ delete _;

	/// The pool reaches this to answer its own CreateRenderBundleEncoder.
	public NullRenderBundleEncoder BundleEncoder => mBundleEncoder;

	public IRenderPassEncoder BeginRenderPass(RenderPassDesc desc) => mRenderPass;
	public IComputePassEncoder BeginComputePass(StringView label) => mComputePass;
	public IRenderBundleEncoder CreateRenderBundleEncoder(RenderBundleDesc desc)
		=> mBundleEncoder;

	public void Barrier(BarrierGroup group) {}

	public void CopyBufferToBuffer(IBuffer src, uint64 srcOffset, IBuffer dst, uint64 dstOffset,
		uint64 size) {}
	public void CopyBufferToTexture(IBuffer src, ITexture dst, BufferTextureCopyRegion region) {}
	public void CopyTextureToBuffer(ITexture src, IBuffer dst, BufferTextureCopyRegion region) {}
	public void CopyTextureToTexture(ITexture src, ITexture dst, TextureCopyRegion region) {}

	public void Blit(ITexture src, ITexture dst) {}
	public void GenerateMipmaps(ITexture texture) {}
	public void ResolveTexture(ITexture src, ITexture dst) {}

	public void ResetQuerySet(IQuerySet querySet, uint32 first, uint32 count) {}
	public void WriteTimestamp(IQuerySet querySet, uint32 index) {}
	public void ResolveQuerySet(IQuerySet querySet, uint32 first, uint32 count, IBuffer dst,
		uint64 dstOffset) {}

	public void BeginDebugLabel(StringView label, float r, float g, float b, float a) {}
	public void EndDebugLabel() {}
	public void InsertDebugLabel(StringView label, float r, float g, float b, float a) {}

	public ICommandBuffer Finish() => mCommandBuffer;

	// IRayTracingEncoderExt
	public void BuildBottomLevelAccelStruct(IAccelStruct dst, IBuffer scratchBuffer,
		uint64 scratchOffset, Span<AccelStructGeometryTriangles> triangles,
		Span<AccelStructGeometryAABBs> aabbs) {}
	public void BuildTopLevelAccelStruct(IAccelStruct dst, IBuffer scratchBuffer,
		uint64 scratchOffset, IBuffer instanceBuffer, uint64 instanceOffset,
		uint32 instanceCount) {}
	public void SetRayTracingPipeline(IRayTracingPipeline pipeline) {}
	public void SetBindGroup(uint32 index, IBindGroup group, Span<uint32> dynamicOffsets) {}
	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data) {}
	public void TraceRays(IBuffer raygenSBT, uint64 raygenOffset, uint64 raygenStride,
		IBuffer missSBT, uint64 missOffset, uint64 missStride,
		IBuffer hitSBT, uint64 hitOffset, uint64 hitStride,
		uint32 width, uint32 height, uint32 depth) {}
}
