using System;
using wgpu_Beef;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// How a texture is read: filtering, addressing, and the optional compare.
class WebGpuSampler : ISampler
{
	private WGPUSampler mHandle;
	private SamplerDesc mDesc;

	public SamplerDesc Desc => mDesc;
	public WGPUSampler Handle => mHandle;

	public ~this()
	{
		if (mHandle != null)
		{
			wgpuSamplerRelease(mHandle);
			mHandle = null;
		}
	}

	public Result<void> Initialize(WGPUDevice device, SamplerDesc desc)
	{
		mDesc = desc;

		WGPUSamplerDescriptor wgpu = .();
		wgpu.label = WebGpuConversions.ToWgpuStringView(desc.Label);
		wgpu.addressModeU = WebGpuConversions.ToWgpuAddressMode(desc.AddressU);
		wgpu.addressModeV = WebGpuConversions.ToWgpuAddressMode(desc.AddressV);
		wgpu.addressModeW = WebGpuConversions.ToWgpuAddressMode(desc.AddressW);
		wgpu.magFilter = WebGpuConversions.ToWgpuFilterMode(desc.MagFilter);
		wgpu.minFilter = WebGpuConversions.ToWgpuFilterMode(desc.MinFilter);
		wgpu.mipmapFilter = WebGpuConversions.ToWgpuMipmapFilterMode(desc.MipmapFilter);
		wgpu.lodMinClamp = desc.MinLod;
		wgpu.lodMaxClamp = desc.MaxLod;

		if (desc.Compare.HasValue)
			wgpu.compare = WebGpuConversions.ToWgpuCompareFunction(desc.Compare.Value);

		// WebGPU only allows anisotropy above one when EVERY filter is linear, so an
		// anisotropic sampler with a nearest filter is clamped back to one rather than
		// refused. Asking for the invalid shape is a validation error, not a fallback.
		let allLinear = (desc.MinFilter == .Linear) && (desc.MagFilter == .Linear)
			&& (desc.MipmapFilter == .Linear);
		wgpu.maxAnisotropy = (allLinear && (desc.MaxAnisotropy > 0)) ? desc.MaxAnisotropy : 1;

		mHandle = wgpuDeviceCreateSampler(device, &wgpu);
		return (mHandle != null) ? .Ok : .Err;
	}
}
