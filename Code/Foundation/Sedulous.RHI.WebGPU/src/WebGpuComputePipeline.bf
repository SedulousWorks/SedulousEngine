using System;
using wgpu_Beef;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// A compute pipeline.
sealed class WebGpuComputePipeline : IComputePipeline
{
	private WGPUComputePipeline mHandle;
	private WebGpuPipelineLayout mLayout;
	/// Snapshotted off the layout so a pass encoder can resolve it on SetPipeline.
	private PushConstantEmulation mPushConstants;

	public IPipelineLayout Layout => mLayout;
	public WGPUComputePipeline Handle => mHandle;
	public PushConstantEmulation PushConstants => mPushConstants;

	public ~this()
	{
		if (mHandle != null)
		{
			wgpuComputePipelineRelease(mHandle);
			mHandle = null;
		}
	}

	public Result<void> Initialize(WGPUDevice device, ComputePipelineDesc desc)
	{
		mLayout = desc.Layout as WebGpuPipelineLayout;
		let module = desc.Compute.Module as WebGpuShaderModule;
		if ((mLayout == null) || (module == null))
			return .Err;

		mPushConstants = mLayout.EmulationInfo;

		WGPUComputePipelineDescriptor wgpu = .();
		wgpu.label = WebGpuConversions.ToWgpuStringView(desc.Label);
		wgpu.layout = mLayout.Handle;
		wgpu.compute.module = module.Handle;
		wgpu.compute.entryPoint = WebGpuConversions.ToWgpuStringView(desc.Compute.EntryPoint);

		mHandle = wgpuDeviceCreateComputePipeline(device, &wgpu);
		return (mHandle != null) ? .Ok : .Err;
	}
}
