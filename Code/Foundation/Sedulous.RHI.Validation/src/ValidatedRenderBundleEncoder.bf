namespace Sedulous.RHI.Validation;

using System;
using Sedulous.RHI;

/// Validation wrapper for IRenderBundleEncoder.
/// Checks: pipeline bound before draw, null arguments, double-finish, etc.
/// Viewport/scissor are deliberately absent from the bundle interface — they are
/// inherited from the parent render pass. The compiler enforces this; the
/// validation layer guards the remaining draw-recording surface.
class ValidatedRenderBundleEncoder : IRenderBundleEncoder
{
	private IRenderBundleEncoder mInner;
	private bool mPipelineBound;
	private bool mFinished;

	public this(IRenderBundleEncoder inner)
	{
		mInner = inner;
	}

	private bool CheckActive(StringView method)
	{
		if (mFinished)
		{
			let msg = scope String();
			msg.AppendF("{}: bundle encoder already finished", method);
			ValidationLogger.Error(msg);
			return false;
		}
		return true;
	}

	private bool CheckDrawReady(StringView method)
	{
		if (!CheckActive(method)) return false;

		if (!mPipelineBound)
		{
			let msg = scope String();
			msg.AppendF("{}: no render pipeline bound (call SetPipeline first)", method);
			ValidationLogger.Error(msg);
			return false;
		}
		return true;
	}

	// ===== Pipeline & Binding =====

	public void SetPipeline(IRenderPipeline pipeline)
	{
		if (!CheckActive("SetPipeline")) return;
		if (pipeline == null)
		{
			ValidationLogger.Error("SetPipeline: pipeline is null");
			return;
		}
		mPipelineBound = true;
		mInner.SetPipeline(pipeline);
	}

	public void SetBindGroup(uint32 index, IBindGroup bindGroup, Span<uint32> dynamicOffsets = default)
	{
		if (!CheckActive("SetBindGroup")) return;
		if (bindGroup == null)
		{
			ValidationLogger.Error("SetBindGroup: bindGroup is null");
			return;
		}
		if (!mPipelineBound)
		{
			ValidationLogger.Warn("SetBindGroup: no pipeline bound yet");
		}
		mInner.SetBindGroup(index, bindGroup, dynamicOffsets);
	}

	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data)
	{
		if (!CheckActive("SetPushConstants")) return;
		if (!mPipelineBound)
		{
			ValidationLogger.Error("SetPushConstants: no pipeline bound (call SetPipeline first)");
			return;
		}
		if (data == null && size > 0)
		{
			ValidationLogger.Error("SetPushConstants: data is null but size > 0");
			return;
		}
		if (size == 0)
		{
			ValidationLogger.Warn("SetPushConstants: size is 0");
			return;
		}
		if (offset % 4 != 0)
		{
			ValidationLogger.Error("SetPushConstants: offset must be 4-byte aligned");
		}
		if (size % 4 != 0)
		{
			ValidationLogger.Error("SetPushConstants: size must be 4-byte aligned");
		}
		mInner.SetPushConstants(stages, offset, size, data);
	}

	// ===== Vertex & Index Buffers =====

	public void SetVertexBuffer(uint32 slot, IBuffer buffer, uint64 offset = 0)
	{
		if (!CheckActive("SetVertexBuffer")) return;
		if (buffer == null)
		{
			ValidationLogger.Error("SetVertexBuffer: buffer is null");
			return;
		}
		if (!mPipelineBound)
		{
			ValidationLogger.Error("SetVertexBuffer: no pipeline bound - call SetPipeline before SetVertexBuffer (DX12 needs pipeline to determine vertex stride)");
		}
		mInner.SetVertexBuffer(slot, buffer, offset);
	}

	public void SetIndexBuffer(IBuffer buffer, IndexFormat format, uint64 offset = 0)
	{
		if (!CheckActive("SetIndexBuffer")) return;
		if (buffer == null)
		{
			ValidationLogger.Error("SetIndexBuffer: buffer is null");
			return;
		}
		mInner.SetIndexBuffer(buffer, format, offset);
	}

	// ===== Draw Commands =====

	public void Draw(uint32 vertexCount, uint32 instanceCount = 1, uint32 firstVertex = 0, uint32 firstInstance = 0)
	{
		if (!CheckDrawReady("Draw")) return;
		if (vertexCount == 0)
		{
			ValidationLogger.Warn("Draw: vertexCount is 0");
		}
		mInner.Draw(vertexCount, instanceCount, firstVertex, firstInstance);
	}

	public void DrawIndexed(uint32 indexCount, uint32 instanceCount = 1, uint32 firstIndex = 0, int32 baseVertex = 0, uint32 firstInstance = 0)
	{
		if (!CheckDrawReady("DrawIndexed")) return;
		if (indexCount == 0)
		{
			ValidationLogger.Warn("DrawIndexed: indexCount is 0");
		}
		mInner.DrawIndexed(indexCount, instanceCount, firstIndex, baseVertex, firstInstance);
	}

	public void DrawIndirect(IBuffer buffer, uint64 offset, uint32 drawCount = 1, uint32 stride = 0)
	{
		if (!CheckDrawReady("DrawIndirect")) return;
		if (buffer == null) { ValidationLogger.Error("DrawIndirect: buffer is null"); return; }
		mInner.DrawIndirect(buffer, offset, drawCount, stride);
	}

	public void DrawIndexedIndirect(IBuffer buffer, uint64 offset, uint32 drawCount = 1, uint32 stride = 0)
	{
		if (!CheckDrawReady("DrawIndexedIndirect")) return;
		if (buffer == null) { ValidationLogger.Error("DrawIndexedIndirect: buffer is null"); return; }
		mInner.DrawIndexedIndirect(buffer, offset, drawCount, stride);
	}

	// ===== Finish =====

	public IRenderBundle Finish()
	{
		if (mFinished)
		{
			ValidationLogger.Error("Finish: bundle encoder already finished");
			return null;
		}
		mFinished = true;
		return mInner.Finish();
	}
}
