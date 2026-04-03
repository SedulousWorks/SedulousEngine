namespace Sedulous.RHI.Validation;

using System;
using Sedulous.RHI;

/// Validation wrapper for IComputePassEncoder.
/// Checks: pipeline bound before dispatch.
class ValidatedComputePassEncoder : IComputePassEncoder
{
	private ValidatedCommandEncoder mParent;
	private IComputePassEncoder mInner;
	private bool mPipelineBound;
	private bool mEnded;

	public this(ValidatedCommandEncoder parent)
	{
		mParent = parent;
	}

	public void Begin(IComputePassEncoder inner)
	{
		mInner = inner;
		mPipelineBound = false;
		mEnded = false;
	}

	private bool CheckActive(StringView method)
	{
		if (mEnded)
		{
			let msg = scope String();
			msg.AppendF("{}: compute pass has ended", method);
			ValidationLogger.Error(msg);
			return false;
		}
		return true;
	}

	public void SetPipeline(IComputePipeline pipeline)
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
		if (data == null && size > 0)
		{
			ValidationLogger.Error("SetPushConstants: data is null but size > 0");
			return;
		}
		if (size > 0 && offset % 4 != 0)
		{
			ValidationLogger.Error("SetPushConstants: offset must be 4-byte aligned");
		}
		if (size % 4 != 0)
		{
			ValidationLogger.Error("SetPushConstants: size must be 4-byte aligned");
		}
		mInner.SetPushConstants(stages, offset, size, data);
	}

	public void Dispatch(uint32 x, uint32 y = 1, uint32 z = 1)
	{
		if (!CheckActive("Dispatch")) return;
		if (!mPipelineBound)
		{
			ValidationLogger.Error("Dispatch: no compute pipeline bound (call SetPipeline first)");
			return;
		}
		if (x == 0 || y == 0 || z == 0)
		{
			ValidationLogger.Warn("Dispatch: one or more dimensions is 0");
		}
		mInner.Dispatch(x, y, z);
	}

	public void DispatchIndirect(IBuffer buffer, uint64 offset)
	{
		if (!CheckActive("DispatchIndirect")) return;
		if (!mPipelineBound)
		{
			ValidationLogger.Error("DispatchIndirect: no compute pipeline bound");
			return;
		}
		if (buffer == null)
		{
			ValidationLogger.Error("DispatchIndirect: buffer is null");
			return;
		}
		mInner.DispatchIndirect(buffer, offset);
	}

	public void ComputeBarrier()
	{
		if (!CheckActive("ComputeBarrier")) return;
		mInner.ComputeBarrier();
	}

	public void WriteTimestamp(IQuerySet querySet, uint32 index)
	{
		if (!CheckActive("WriteTimestamp")) return;
		if (querySet == null) { ValidationLogger.Error("WriteTimestamp: querySet is null"); return; }
		mInner.WriteTimestamp(querySet, index);
	}

	public void End()
	{
		if (mEnded)
		{
			ValidationLogger.Error("ComputePass.End: already ended");
			return;
		}
		mEnded = true;
		mInner.End();
		mParent.OnPassEnded();
	}
}
