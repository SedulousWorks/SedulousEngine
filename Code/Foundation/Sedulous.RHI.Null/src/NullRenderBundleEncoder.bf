using System;
using Sedulous.RHI;

namespace Sedulous.RHI.Null;

/// Records nothing and finishes into a bundle it OWNS, matching the real contract that a
/// bundle belongs to the pool rather than the caller.
class NullRenderBundleEncoder : IRenderBundleEncoder
{
	private NullRenderBundle mBundle = new .() ~ delete _;
	/// What this recording has recorded, which the bundle counts each time it runs.
	private RecordedCounts mRecorded;

	public void SetPipeline(IRenderPipeline pipeline) => mRecorded.PipelineBinds++;
	public void SetBindGroup(uint32 index, IBindGroup group, Span<uint32> dynamicOffsets) => mRecorded.BindGroupBinds++;
	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data) {}
	public void SetVertexBuffer(uint32 slot, IBuffer buffer, uint64 offset) {}
	public void SetIndexBuffer(IBuffer buffer, IndexFormat format, uint64 offset) {}
	public void Draw(uint32 vertexCount, uint32 instanceCount, uint32 firstVertex,
		uint32 firstInstance) => mRecorded.Draws++;
	public void DrawIndexed(uint32 indexCount, uint32 instanceCount, uint32 firstIndex,
		int32 baseVertex, uint32 firstInstance) => mRecorded.Draws++;
	public void DrawIndirect(IBuffer buffer, uint64 offset, uint32 drawCount, uint32 stride) => mRecorded.Draws += drawCount;
	public void DrawIndexedIndirect(IBuffer buffer, uint64 offset, uint32 drawCount,
		uint32 stride) => mRecorded.Draws += drawCount;

	/// The one bundle takes what was recorded, and the next recording starts from nought.
	public IRenderBundle Finish()
	{
		mBundle.Counts = mRecorded;
		mRecorded = .();
		return mBundle;
	}
}
