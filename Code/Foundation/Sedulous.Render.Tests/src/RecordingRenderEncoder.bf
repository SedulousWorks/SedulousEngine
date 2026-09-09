using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.Render.Tests;

/// A recording surface that COUNTS what was emitted into it and stubs the rest.
///
/// What draw emission produced is the thing to assert on; a real encoder would swallow it
/// into a command buffer.
class RecordingRenderEncoder : IRenderCommandEncoder
{
	public int PipelineCount = 0;
	public int DrawCount = 0;
	public int BindGroupCount = 0;
	public int VertexBufferCount = 0;
	public uint32 LastIndexCount = 0;
	public uint32 LastInstanceCount = 0;

	public void SetPipeline(IRenderPipeline pipeline)
	{
		PipelineCount++;
	}

	public void SetBindGroup(uint32 index, IBindGroup group, Span<uint32> dynamicOffsets)
	{
		BindGroupCount++;
	}

	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data) {}

	public void SetVertexBuffer(uint32 slot, IBuffer buffer, uint64 offset)
	{
		VertexBufferCount++;
	}
	public void SetIndexBuffer(IBuffer buffer, IndexFormat format, uint64 offset) {}

	public void Draw(uint32 vertexCount, uint32 instanceCount, uint32 firstVertex,
		uint32 firstInstance)
	{
		DrawCount++;
	}

	public void DrawIndexed(uint32 indexCount, uint32 instanceCount, uint32 firstIndex,
		int32 baseVertex, uint32 firstInstance)
	{
		DrawCount++;
		LastIndexCount = indexCount;
		LastInstanceCount = instanceCount;
	}

	public void DrawIndirect(IBuffer buffer, uint64 offset, uint32 drawCount, uint32 stride) {}
	public void DrawIndexedIndirect(IBuffer buffer, uint64 offset, uint32 drawCount, uint32 stride) {}

}
