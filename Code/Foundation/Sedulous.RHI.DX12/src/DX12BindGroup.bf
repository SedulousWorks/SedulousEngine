namespace Sedulous.RHI.DX12;

using System;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi.Common;
using Sedulous.RHI;
using System.Collections;

/// DX12 implementation of IBindGroup.
/// Allocates contiguous descriptor ranges in GPU-visible heaps
/// and writes descriptors for all bound resources.
class DX12BindGroup : IBindGroup
{
	private DX12Device mDevice;
	private DX12BindGroupLayout mLayout;

	// GPU heap allocation offsets (-1 = not allocated)
	private int32 mCbvSrvUavOffset = -1;
	private int32 mSamplerOffset = -1;

	/// GPU virtual addresses for dynamic offset bindings (indexed by dynamic binding order).
	private List<uint64> mDynamicGpuAddresses = new .() ~ delete _;

	public IBindGroupLayout Layout => mLayout;

	public this() { }

	public Result<void> Init(DX12Device device, BindGroupDesc desc)
	{
		mDevice = device;
		mLayout = desc.Layout as DX12BindGroupLayout;
		if (mLayout == null)
		{
			System.Diagnostics.Debug.WriteLine("DX12BindGroup: bind group layout is null");
			return .Err;
		}

		// Allocate CPU-visible heap blocks (non-shader-visible, readable for staging copy)
		if (mLayout.CbvSrvUavCount > 0)
		{
			mCbvSrvUavOffset = device.CpuSrvHeap.Allocate(mLayout.CbvSrvUavCount);
			if (mCbvSrvUavOffset < 0)
			{
				System.Diagnostics.Debug.WriteLine("DX12BindGroup: CPU CBV/SRV/UAV heap allocation failed");
				return .Err;
			}
		}

		if (mLayout.SamplerCount > 0)
		{
			mSamplerOffset = device.CpuSamplerHeap.Allocate(mLayout.SamplerCount);
			if (mSamplerOffset < 0)
			{
				System.Diagnostics.Debug.WriteLine("DX12BindGroup: CPU sampler heap allocation failed");
				return .Err;
			}
		}

		// Write descriptors
		WriteDescriptors(device, desc);
		return .Ok;
	}

	private void WriteDescriptors(DX12Device device, BindGroupDesc desc)
	{
		// Entries are positional: entry[j] provides the resource for the j-th non-bindless layout range.
		// Bindless ranges are skipped - they are populated via UpdateBindless().
		// Dynamic offset bindings store GPU addresses instead of writing heap descriptors.
		int entryIdx = 0;
		for (int i = 0; i < mLayout.Ranges.Count; i++)
		{
			let rangeInfo = mLayout.Ranges[i];

			// Skip bindless ranges - not populated at creation time
			switch (rangeInfo.Type)
			{
			case .BindlessTextures, .BindlessSamplers, .BindlessStorageBuffers, .BindlessStorageTextures:
				continue;
			default:
			}

			if (entryIdx >= desc.Entries.Length) break;
			let entry = desc.Entries[entryIdx];
			entryIdx++;

			// Dynamic offset bindings: store GPU virtual address for root descriptor binding
			if (rangeInfo.HasDynamicOffset)
			{
				if (let dxBuf = entry.Buffer as DX12Buffer)
					mDynamicGpuAddresses.Add(dxBuf.Handle.GetGPUVirtualAddress() + entry.BufferOffset);
				else
					mDynamicGpuAddresses.Add(0);
				continue;
			}

			if (rangeInfo.IsSampler)
				WriteSamplerDescriptor(device, entry, rangeInfo);
			else
				WriteCbvSrvUavDescriptor(device, entry, rangeInfo);
		}
	}

	private void WriteCbvSrvUavDescriptor(DX12Device device, BindGroupEntry entry, DX12BindingRangeInfo rangeInfo, uint32 arrayIndex = 0)
	{
		uint32 heapOffset = (uint32)mCbvSrvUavOffset + rangeInfo.HeapOffset + arrayIndex;
		D3D12_CPU_DESCRIPTOR_HANDLE destHandle = device.CpuSrvHeap.GetCpuHandle(heapOffset);

		switch (rangeInfo.Type)
		{
		case .UniformBuffer:
			if (let dxBuf = entry.Buffer as DX12Buffer)
			{
				D3D12_CONSTANT_BUFFER_VIEW_DESC cbvDesc = .()
				{
					BufferLocation = dxBuf.Handle.GetGPUVirtualAddress() + entry.BufferOffset,
					SizeInBytes = (uint32)((entry.BufferSize > 0)
						? ((entry.BufferSize + 255) & ~(uint64)255)
						: ((dxBuf.Size + 255) & ~(uint64)255))
				};
				device.Handle.CreateConstantBufferView(&cbvDesc, destHandle);
			}

		case .StorageBufferReadOnly, .BindlessStorageBuffers:
			if (let dxBuf = entry.Buffer as DX12Buffer)
			{
				D3D12_SHADER_RESOURCE_VIEW_DESC srvDesc = default;
				srvDesc.ViewDimension = .D3D12_SRV_DIMENSION_BUFFER;
				srvDesc.Shader4ComponentMapping = 5768; // D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING
				let bufSize = (entry.BufferSize > 0) ? entry.BufferSize : dxBuf.Size;

				if (rangeInfo.StorageBufferStride > 0)
				{
					// StructuredBuffer SRV
					srvDesc.Format = .DXGI_FORMAT_UNKNOWN;
					srvDesc.Buffer.FirstElement = entry.BufferOffset / rangeInfo.StorageBufferStride;
					srvDesc.Buffer.NumElements = (uint32)(bufSize / rangeInfo.StorageBufferStride);
					srvDesc.Buffer.StructureByteStride = rangeInfo.StorageBufferStride;
					srvDesc.Buffer.Flags = .D3D12_BUFFER_SRV_FLAG_NONE;
}
				else
				{
					// Raw buffer SRV (ByteAddressBuffer)
					srvDesc.Format = .DXGI_FORMAT_R32_TYPELESS;
					srvDesc.Buffer.FirstElement = entry.BufferOffset / 4;
					srvDesc.Buffer.NumElements = (uint32)(bufSize / 4);
					srvDesc.Buffer.Flags = .D3D12_BUFFER_SRV_FLAG_RAW;
				}
				device.Handle.CreateShaderResourceView(dxBuf.Handle, &srvDesc, destHandle);
			}

		case .StorageBufferReadWrite:
			if (let dxBuf = entry.Buffer as DX12Buffer)
			{
				D3D12_UNORDERED_ACCESS_VIEW_DESC uavDesc = default;
				uavDesc.ViewDimension = .D3D12_UAV_DIMENSION_BUFFER;
				let bufSize = (entry.BufferSize > 0) ? entry.BufferSize : dxBuf.Size;

				if (rangeInfo.StorageBufferStride > 0)
				{
					// StructuredBuffer UAV
					uavDesc.Format = .DXGI_FORMAT_UNKNOWN;
					uavDesc.Buffer.FirstElement = entry.BufferOffset / rangeInfo.StorageBufferStride;
					uavDesc.Buffer.NumElements = (uint32)(bufSize / rangeInfo.StorageBufferStride);
					uavDesc.Buffer.StructureByteStride = rangeInfo.StorageBufferStride;
					uavDesc.Buffer.Flags = .D3D12_BUFFER_UAV_FLAG_NONE;
				}
				else
				{
					// Raw buffer UAV (RWByteAddressBuffer)
					uavDesc.Format = .DXGI_FORMAT_R32_TYPELESS;
					uavDesc.Buffer.FirstElement = entry.BufferOffset / 4;
					uavDesc.Buffer.NumElements = (uint32)(bufSize / 4);
					uavDesc.Buffer.Flags = .D3D12_BUFFER_UAV_FLAG_RAW;
				}
				device.Handle.CreateUnorderedAccessView(dxBuf.Handle, null, &uavDesc, destHandle);
			}

		case .SampledTexture, .BindlessTextures:
			if (let dxView = entry.TextureView as DX12TextureView)
			{
				// Copy from the texture view's CPU-side SRV
				let srcHandle = dxView.GetSrv();
				device.Handle.CopyDescriptorsSimple(1, destHandle, srcHandle,
					.D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV);
			}

		case .StorageTextureReadOnly, .StorageTextureReadWrite, .BindlessStorageTextures:
			if (let dxView = entry.TextureView as DX12TextureView)
			{
				let srcHandle = dxView.GetUav();
				device.Handle.CopyDescriptorsSimple(1, destHandle, srcHandle,
					.D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV);
			}

		case .AccelerationStructure:
			if (let dxAs = entry.AccelStruct as DX12AccelStruct)
			{
				D3D12_SHADER_RESOURCE_VIEW_DESC srvDesc = default;
				srvDesc.Format = .DXGI_FORMAT_UNKNOWN;
				srvDesc.ViewDimension = .D3D12_SRV_DIMENSION_RAYTRACING_ACCELERATION_STRUCTURE;
				srvDesc.Shader4ComponentMapping = 5768; // D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING
				srvDesc.RaytracingAccelerationStructure.Location = dxAs.GpuAddress;
				device.Handle.CreateShaderResourceView(null, &srvDesc, destHandle);
			}

		default:
		}
	}

	private void WriteSamplerDescriptor(DX12Device device, BindGroupEntry entry, DX12BindingRangeInfo rangeInfo, uint32 arrayIndex = 0)
	{
		uint32 heapOffset = (uint32)mSamplerOffset + rangeInfo.HeapOffset + arrayIndex;
		D3D12_CPU_DESCRIPTOR_HANDLE destHandle = device.CpuSamplerHeap.GetCpuHandle(heapOffset);

		if (let dxSampler = entry.Sampler as DX12Sampler)
		{
			device.Handle.CopyDescriptorsSimple(1, destHandle, dxSampler.Handle,
				.D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER);
		}
	}

	public void UpdateBindless(Span<BindlessUpdateEntry> entries)
	{
		for (let entry in entries)
		{
			if ((int)entry.LayoutIndex >= mLayout.Ranges.Count) continue;
			let rangeInfo = mLayout.Ranges[(int)entry.LayoutIndex];

			// Build a BindGroupEntry from the bindless update
			BindGroupEntry bgEntry = default;
			bgEntry.Buffer = entry.Buffer;
			bgEntry.BufferOffset = entry.BufferOffset;
			bgEntry.BufferSize = entry.BufferSize;
			bgEntry.TextureView = entry.TextureView;
			bgEntry.Sampler = entry.Sampler;

			if (rangeInfo.IsSampler)
				WriteSamplerDescriptor(mDevice, bgEntry, rangeInfo, entry.ArrayIndex);
			else
				WriteCbvSrvUavDescriptor(mDevice, bgEntry, rangeInfo, entry.ArrayIndex);
		}
	}

	public void Cleanup(DX12Device device)
	{
		if (mCbvSrvUavOffset >= 0 && mLayout != null)
		{
			device.CpuSrvHeap.Free((uint32)mCbvSrvUavOffset, mLayout.CbvSrvUavCount);
			mCbvSrvUavOffset = -1;
		}
		if (mSamplerOffset >= 0 && mLayout != null)
		{
			device.CpuSamplerHeap.Free((uint32)mSamplerOffset, mLayout.SamplerCount);
			mSamplerOffset = -1;
		}
	}

	// --- Internal ---
	public int32 CbvSrvUavOffset => mCbvSrvUavOffset;
	public int32 SamplerOffset => mSamplerOffset;
	public List<uint64> DynamicGpuAddresses => mDynamicGpuAddresses;
}
