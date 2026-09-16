using System;
using wgpu_Beef;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// A compute pass.
class WebGpuComputePassEncoder : IComputePassEncoder
{
	private WGPUComputePassEncoder mEncoder;
	private PushConstantEmulator mPushConstants = new .() ~ delete _;

	public void Begin(WGPUDevice device, WGPUComputePassEncoder encoder)
	{
		mEncoder = encoder;
		mPushConstants.Begin(device);
	}

	public void SetPipeline(IComputePipeline pipeline)
	{
		let wgpuPipeline = pipeline as WebGpuComputePipeline;
		if (wgpuPipeline == null)
			return;

		wgpuComputePassEncoderSetPipeline(mEncoder, wgpuPipeline.Handle);
		mPushConstants.SetPipeline(wgpuPipeline.PushConstants);
	}

	public void SetBindGroup(uint32 index, IBindGroup group, Span<uint32> dynamicOffsets = default)
	{
		let wgpuGroup = group as WebGpuBindGroup;
		if (wgpuGroup == null)
			return;

		wgpuComputePassEncoderSetBindGroup(mEncoder, index, wgpuGroup.Handle,
			(uint)dynamicOffsets.Length, dynamicOffsets.Ptr);
	}

	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data)
	{
		// An emulating pipeline folds this into the shadow, to be bound before the next
		// dispatch. Otherwise the pipeline declared native immediates, so issue them.
		if (!mPushConstants.Write(offset, size, data))
			WebGpuApi.NativeOnly.ComputeSetImmediates(mEncoder, offset, data, size);
	}

	public void Dispatch(uint32 x, uint32 y = 1, uint32 z = 1)
	{
		FlushPushConstants();
		wgpuComputePassEncoderDispatchWorkgroups(mEncoder, x, y, z);
	}

	public void DispatchIndirect(IBuffer buffer, uint64 offset)
	{
		let wgpuBuffer = buffer as WebGpuBuffer;
		if (wgpuBuffer == null)
			return;

		FlushPushConstants();
		wgpuComputePassEncoderDispatchWorkgroupsIndirect(mEncoder, wgpuBuffer.Handle, offset);
	}

	/// Nothing to do: WebGPU tracks hazards itself, and dispatch ordering within a pass
	/// is already dependency correct.
	public void ComputeBarrier()
	{
	}

	/// Nothing to do: a timestamp INSIDE a pass has no WebGPU shape, which only has
	/// begin and end of pass writes.
	public void WriteTimestamp(IQuerySet querySet, uint32 index)
	{
	}

	public void End()
	{
		wgpuComputePassEncoderEnd(mEncoder);
		// AFTER End: the pass commands hold their own references now, so the emulated
		// uniform buffers and bind groups can go.
		mPushConstants.Release();
		wgpuComputePassEncoderRelease(mEncoder);
		mEncoder = null;
	}

	/// Uploads and binds any pending emulated block before a dispatch. A no-op for a
	/// pipeline using native immediates.
	private void FlushPushConstants()
	{
		if (mPushConstants.FlushBeforeDraw(let group, let bindGroup))
			wgpuComputePassEncoderSetBindGroup(mEncoder, (uint32)group, bindGroup, 0, null);
	}
}
