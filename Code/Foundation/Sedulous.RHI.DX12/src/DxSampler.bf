#if BF_PLATFORM_WINDOWS
using System;
using Sedulous.RHI;
using Win32.Graphics.Direct3D12;

namespace Sedulous.RHI.DX12;

/// One sampler, which on this backend is a descriptor rather than an object.
///
/// D3D12 has no sampler COM object: CreateSampler writes into a descriptor slot. So this owns
/// nothing but the SLOT, and Cleanup hands it back to the heap that lent it. The heap itself
/// belongs to the device and outlives every sampler cut from it.
class DxSampler : ISampler
{
	// Kept because ISampler asks for it: D3D12 keeps no sampler object to read it back from.
	private SamplerDesc mDesc = .();
	private D3D12_CPU_DESCRIPTOR_HANDLE mHandle = .();
	private DxDescriptorHeapAllocator mSamplerHeap = null; // NOT owned, the device's

	public SamplerDesc Desc => mDesc;
	public D3D12_CPU_DESCRIPTOR_HANDLE Handle => mHandle;

	public Result<void> Initialize(ID3D12Device* device, SamplerDesc d,
		DxDescriptorHeapAllocator samplerHeap)
	{
		mDesc = d;
		mSamplerHeap = samplerHeap;

		let isComparison = d.Compare.HasValue;

		D3D12_SAMPLER_DESC sd = .();
		if (isComparison)
			sd.Filter = DxConversions.ToFilter(d.MinFilter, d.MagFilter, d.MipmapFilter, true);
		else if (d.MaxAnisotropy > 1)
			sd.Filter = .D3D12_FILTER_ANISOTROPIC;
		else
			sd.Filter = DxConversions.ToFilter(d.MinFilter, d.MagFilter, d.MipmapFilter, false);

		sd.AddressU = DxConversions.ToAddressMode(d.AddressU);
		sd.AddressV = DxConversions.ToAddressMode(d.AddressV);
		sd.AddressW = DxConversions.ToAddressMode(d.AddressW);
		sd.MipLODBias = d.MipLodBias;
		sd.MaxAnisotropy = (uint32)d.MaxAnisotropy;
		sd.ComparisonFunc = isComparison
			? DxConversions.ToComparisonFunc(d.Compare.Value)
			: .D3D12_COMPARISON_FUNC_NEVER;
		sd.MinLOD = d.MinLod;
		sd.MaxLOD = d.MaxLod;

		switch (d.BorderColor)
		{
		case .TransparentBlack:
			sd.BorderColor = .(0, 0, 0, 0);
		case .OpaqueBlack:
			sd.BorderColor = .(0, 0, 0, 1);
		case .OpaqueWhite:
			sd.BorderColor = .(1, 1, 1, 1);
		}

		mHandle = samplerHeap.Allocate();
		device.CreateSampler(&sd, mHandle);
		return .Ok;
	}

	public void Cleanup()
	{
		if (mSamplerHeap != null)
			mSamplerHeap.Free(mHandle);
	}
}

#endif // BF_PLATFORM_WINDOWS
