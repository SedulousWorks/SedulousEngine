using System;
using Sedulous.RHI;

namespace Sedulous.RHI.Validation;

/// Watches a compute pass: still open, something bound, and dispatches that do work.
class ValidatedComputePassEncoder : IComputePassEncoder
{
	private IComputePassEncoder mInner;
	/// The encoder that opened this pass, so ending it returns that encoder to recording.
	private ValidatedCommandEncoder mOwner;
	private bool mEnded = false;
	private bool mPipelineBound = false;

	public this(IComputePassEncoder inner, ValidatedCommandEncoder owner = null)
	{
		mInner = inner;
		mOwner = owner;
	}

	public IComputePassEncoder Inner => mInner;

	public void SetPipeline(IComputePipeline pipeline)
	{
		if (Ended("SetPipeline"))
			return;
		if (pipeline == null)
		{
			ValidationLog.Error("ComputePass.SetPipeline: pipeline is null");
			return;
		}
		mPipelineBound = true;
		mInner.SetPipeline(pipeline);
	}

	public void SetBindGroup(uint32 index, IBindGroup group, Span<uint32> dynamicOffsets)
	{
		if (Ended("SetBindGroup"))
			return;
		if (group == null)
		{
			ValidationLog.Error("ComputePass.SetBindGroup: group is null");
			return;
		}
		if (!mPipelineBound)
			ValidationLog.Warn("ComputePass.SetBindGroup: no pipeline is bound");
		mInner.SetBindGroup(index, group, dynamicOffsets);
	}

	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data)
	{
		if (Ended("SetPushConstants"))
			return;
		if (!mPipelineBound)
			ValidationLog.Warn("ComputePass.SetPushConstants: no pipeline is bound");
		if (data == null)
		{
			ValidationLog.Error("ComputePass.SetPushConstants: data is null");
			return;
		}
		if ((offset % 4) != 0)
		{
			ValidationLog.Error("ComputePass.SetPushConstants: offset must be 4 byte aligned");
			return;
		}
		if ((size % 4) != 0)
		{
			ValidationLog.Error("ComputePass.SetPushConstants: size must be 4 byte aligned");
			return;
		}
		mInner.SetPushConstants(stages, offset, size, data);
	}

	public void Dispatch(uint32 x, uint32 y, uint32 z)
	{
		if (Ended("Dispatch"))
			return;
		if (!mPipelineBound)
		{
			ValidationLog.Error("ComputePass.Dispatch: no pipeline is bound");
			return;
		}
		// A zero in any dimension launches nothing, which is almost always a count that
		// was computed rather than one that was meant.
		if ((x == 0) || (y == 0) || (z == 0))
			ValidationLog.Warn("ComputePass.Dispatch: a workgroup dimension is zero");
		mInner.Dispatch(x, y, z);
	}

	public void DispatchIndirect(IBuffer buffer, uint64 offset)
	{
		if (Ended("DispatchIndirect"))
			return;
		if (!mPipelineBound)
		{
			ValidationLog.Error("ComputePass.DispatchIndirect: no pipeline is bound");
			return;
		}
		if (buffer == null)
		{
			ValidationLog.Error("ComputePass.DispatchIndirect: buffer is null");
			return;
		}
		mInner.DispatchIndirect(buffer, offset);
	}

	public void ComputeBarrier()
	{
		if (Ended("ComputeBarrier"))
			return;
		mInner.ComputeBarrier();
	}

	public void WriteTimestamp(IQuerySet querySet, uint32 index)
	{
		if (Ended("WriteTimestamp"))
			return;
		if (querySet == null)
		{
			ValidationLog.Error("ComputePass.WriteTimestamp: querySet is null");
			return;
		}
		mInner.WriteTimestamp(querySet, index);
	}

	public void End()
	{
		if (mEnded)
		{
			ValidationLog.Error("ComputePass.End: the pass has already ended");
			return;
		}
		mEnded = true;
		mInner.End();
		if (mOwner != null)
			mOwner.OnPassEnded();
	}

	private bool Ended(StringView operation)
	{
		if (!mEnded)
			return false;
		ValidationLog.Error(scope $"ComputePass.{operation}: the compute pass has ended");
		return true;
	}
}
