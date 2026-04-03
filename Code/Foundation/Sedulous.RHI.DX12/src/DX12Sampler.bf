namespace Sedulous.RHI.DX12;

using System;
using Win32.Graphics.Direct3D12;
using Sedulous.RHI;

/// DX12 implementation of ISampler.
/// In DX12, samplers are descriptor handles in the sampler heap.
class DX12Sampler : ISampler
{
	private D3D12_CPU_DESCRIPTOR_HANDLE mHandle;
	private SamplerDesc mDesc;

	public SamplerDesc Desc => mDesc;

	public this() { }

	public Result<void> Init(DX12Device device, SamplerDesc desc)
	{
		mDesc = desc;

		bool isComparison = desc.Compare.HasValue;

		D3D12_SAMPLER_DESC samplerDesc = default;
		samplerDesc.Filter = isComparison
			? DX12Conversions.ToFilter(desc.MinFilter, desc.MagFilter, desc.MipmapFilter, true)
			: (desc.MaxAnisotropy > 1
				? .D3D12_FILTER_ANISOTROPIC
				: DX12Conversions.ToFilter(desc.MinFilter, desc.MagFilter, desc.MipmapFilter, false));
		samplerDesc.AddressU = DX12Conversions.ToAddressMode(desc.AddressU);
		samplerDesc.AddressV = DX12Conversions.ToAddressMode(desc.AddressV);
		samplerDesc.AddressW = DX12Conversions.ToAddressMode(desc.AddressW);
		samplerDesc.MipLODBias = desc.MipLodBias;
		samplerDesc.MaxAnisotropy = (uint32)desc.MaxAnisotropy;
		samplerDesc.ComparisonFunc = isComparison
			? DX12Conversions.ToComparisonFunc(desc.Compare.Value)
			: .D3D12_COMPARISON_FUNC_NEVER;
		samplerDesc.MinLOD = desc.MinLod;
		samplerDesc.MaxLOD = desc.MaxLod;

		// Border color
		switch (desc.BorderColor)
		{
		case .TransparentBlack: samplerDesc.BorderColor = .(0, 0, 0, 0);
		case .OpaqueBlack:      samplerDesc.BorderColor = .(0, 0, 0, 1);
		case .OpaqueWhite:      samplerDesc.BorderColor = .(1, 1, 1, 1);
		}

		mHandle = device.SamplerHeap.Allocate();
		device.Handle.CreateSampler(&samplerDesc, mHandle);

		return .Ok;
	}

	public void Cleanup(DX12Device device)
	{
		device.SamplerHeap.Free(mHandle);
	}

	// --- Internal ---
	public D3D12_CPU_DESCRIPTOR_HANDLE Handle => mHandle;
}
