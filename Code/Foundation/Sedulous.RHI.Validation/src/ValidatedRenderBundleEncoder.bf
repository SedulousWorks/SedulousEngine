using System;
using Sedulous.RHI;

namespace Sedulous.RHI.Validation;

/// Watches a bundle recording. The same draw checks as a pass, MINUS the pass level state:
/// a bundle inherits viewport and scissor rather than setting them, so requiring them here
/// would reject every correct bundle.
class ValidatedRenderBundleEncoder : IRenderBundleEncoder
{
	private IRenderBundleEncoder mInner;
	private bool mFinished = false;
	private bool mPipelineBound = false;

	public this(IRenderBundleEncoder inner) => mInner = inner;

	public IRenderBundleEncoder Inner => mInner;

	public void SetPipeline(IRenderPipeline pipeline)
	{
		if (Finished("SetPipeline"))
			return;
		if (pipeline == null)
		{
			ValidationLog.Error("Bundle.SetPipeline: pipeline is null");
			return;
		}
		mPipelineBound = true;
		mInner.SetPipeline(pipeline);
	}

	public void SetBindGroup(uint32 index, IBindGroup group, Span<uint32> dynamicOffsets)
	{
		if (Finished("SetBindGroup"))
			return;
		if (group == null)
		{
			ValidationLog.Error("Bundle.SetBindGroup: group is null");
			return;
		}
		mInner.SetBindGroup(index, group, dynamicOffsets);
	}

	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data)
	{
		if (Finished("SetPushConstants"))
			return;
		if ((data == null) && (size > 0))
		{
			ValidationLog.Error("Bundle.SetPushConstants: data is null but size is not zero");
			return;
		}
		if ((offset % 4) != 0)
		{
			ValidationLog.Error("Bundle.SetPushConstants: offset must be 4 byte aligned");
			return;
		}
		if ((size % 4) != 0)
		{
			ValidationLog.Error("Bundle.SetPushConstants: size must be 4 byte aligned");
			return;
		}
		mInner.SetPushConstants(stages, offset, size, data);
	}

	public void SetVertexBuffer(uint32 slot, IBuffer buffer, uint64 offset)
	{
		if (Finished("SetVertexBuffer"))
			return;
		if (buffer == null)
		{
			ValidationLog.Error("Bundle.SetVertexBuffer: buffer is null");
			return;
		}
		mInner.SetVertexBuffer(slot, buffer, offset);
	}

	public void SetIndexBuffer(IBuffer buffer, IndexFormat format, uint64 offset)
	{
		if (Finished("SetIndexBuffer"))
			return;
		if (buffer == null)
		{
			ValidationLog.Error("Bundle.SetIndexBuffer: buffer is null");
			return;
		}
		mInner.SetIndexBuffer(buffer, format, offset);
	}

	public void Draw(uint32 vertexCount, uint32 instanceCount, uint32 firstVertex,
		uint32 firstInstance)
	{
		if (!ReadyToDraw("Draw"))
			return;
		if (vertexCount == 0)
			ValidationLog.Warn("Bundle.Draw: vertexCount is zero");
		mInner.Draw(vertexCount, instanceCount, firstVertex, firstInstance);
	}

	public void DrawIndexed(uint32 indexCount, uint32 instanceCount, uint32 firstIndex,
		int32 baseVertex, uint32 firstInstance)
	{
		if (!ReadyToDraw("DrawIndexed"))
			return;
		if (indexCount == 0)
			ValidationLog.Warn("Bundle.DrawIndexed: indexCount is zero");
		mInner.DrawIndexed(indexCount, instanceCount, firstIndex, baseVertex, firstInstance);
	}

	public void DrawIndirect(IBuffer buffer, uint64 offset, uint32 drawCount, uint32 stride)
	{
		if (!ReadyToDraw("DrawIndirect"))
			return;
		if (buffer == null)
		{
			ValidationLog.Error("Bundle.DrawIndirect: buffer is null");
			return;
		}
		mInner.DrawIndirect(buffer, offset, drawCount, stride);
	}

	public void DrawIndexedIndirect(IBuffer buffer, uint64 offset, uint32 drawCount,
		uint32 stride)
	{
		if (!ReadyToDraw("DrawIndexedIndirect"))
			return;
		if (buffer == null)
		{
			ValidationLog.Error("Bundle.DrawIndexedIndirect: buffer is null");
			return;
		}
		mInner.DrawIndexedIndirect(buffer, offset, drawCount, stride);
	}

	public IRenderBundle Finish()
	{
		if (mFinished)
		{
			ValidationLog.Error("Bundle.Finish: already finished");
			return null;
		}
		mFinished = true;
		let bundle = mInner.Finish();
		if (bundle == null)
			ValidationLog.Error("Bundle.Finish: the inner encoder returned null");
		return bundle;
	}

	private bool Finished(StringView operation)
	{
		if (!mFinished)
			return false;
		ValidationLog.Error(scope $"Bundle.{operation}: the bundle is already finished");
		return true;
	}

	private bool ReadyToDraw(StringView operation)
	{
		if (Finished(operation))
			return false;
		if (!mPipelineBound)
		{
			ValidationLog.Error(scope $"Bundle.{operation}: no pipeline is bound");
			return false;
		}
		return true;
	}
}
