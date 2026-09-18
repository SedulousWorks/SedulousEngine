#if BF_PLATFORM_WINDOWS
using System;
using System.Collections;
using Sedulous.RHI;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi.Common;

namespace Sedulous.RHI.DX12;

/// One bind group: descriptors written into the slots its layout reserved.
///
/// A bind group is IMMUTABLE except through UpdateBindless, so its descriptors are written
/// once here and the table is bound by offset thereafter.
///
/// Samplers are treated differently from everything else. CBV/SRV/UAV descriptors live in a
/// CPU heap and are copied into the shader visible one per draw, but the shader visible
/// SAMPLER heap has a hard cap of 2048 and cannot take per draw staging, so each group's
/// sampler table is BAKED into it once at creation and bound directly.
class DxBindGroup : IBindGroup
{
	private ID3D12Device* mDevice = null; // NOT owned
	private DxBindGroupLayout mLayout = null; // NOT owned
	private DxGpuDescriptorHeap mCpuSrvHeap = null; // none owned, all the device's
	private DxGpuDescriptorHeap mCpuSamplerHeap = null;
	private DxGpuDescriptorHeap mGpuSamplerHeap = null;

	// Cached so Cleanup need not reach into the layout, which may be destroyed first.
	private uint32 mCachedCbvSrvUavCount = 0;
	private uint32 mCachedSamplerCount = 0;

	private int32 mCbvSrvUavOffset = -1;
	private int32 mSamplerOffset = -1;
	private int32 mGpuSamplerOffset = -1; // the baked table in the shader visible sampler heap
	private List<uint64> mDynAddrs = new .() ~ delete _;

	public IBindGroupLayout Layout => mLayout;
	public int32 CbvSrvUavOffset => mCbvSrvUavOffset;
	public int32 SamplerOffset => mSamplerOffset;
	/// Offset of this group's baked sampler table in the shader visible sampler heap.
	public int32 GpuSamplerOffset => mGpuSamplerOffset;
	public Span<uint64> DynamicGpuAddresses => mDynAddrs;

	public Result<void> Initialize(ID3D12Device* device, BindGroupDesc d,
		DxGpuDescriptorHeap cpuSrvHeap, DxGpuDescriptorHeap cpuSamplerHeap,
		DxGpuDescriptorHeap gpuSamplerHeap)
	{
		mDevice = device;
		mLayout = d.Layout as DxBindGroupLayout;
		mCpuSrvHeap = cpuSrvHeap;
		mCpuSamplerHeap = cpuSamplerHeap;
		mGpuSamplerHeap = gpuSamplerHeap;

		if (mLayout == null)
			return .Err;

		mCachedCbvSrvUavCount = mLayout.CbvSrvUavCount;
		mCachedSamplerCount = mLayout.SamplerCount;

		if (mCachedCbvSrvUavCount > 0)
		{
			mCbvSrvUavOffset = cpuSrvHeap.Allocate(mCachedCbvSrvUavCount);
			if (mCbvSrvUavOffset < 0)
				return .Err;
		}

		if (mCachedSamplerCount > 0)
		{
			mSamplerOffset = cpuSamplerHeap.Allocate(mCachedSamplerCount);
			if (mSamplerOffset < 0)
				return .Err;

			mGpuSamplerOffset = gpuSamplerHeap.Allocate(mCachedSamplerCount);
			if (mGpuSamplerOffset < 0)
				return .Err;
		}

		WriteDescriptors(d);
		return .Ok;
	}

	public void UpdateBindless(Span<BindlessUpdateEntry> entries)
	{
		let ranges = mLayout.Ranges;
		for (let e in entries)
		{
			if (e.LayoutIndex >= (uint32)ranges.Length)
				continue;

			let r = ranges[(int)e.LayoutIndex];

			BindGroupEntry bgEntry = .();
			bgEntry.Buffer = e.Buffer;
			bgEntry.BufferOffset = e.BufferOffset;
			bgEntry.BufferSize = e.BufferSize;
			bgEntry.TextureView = e.TextureView;
			bgEntry.Sampler = e.Sampler;

			if (r.IsSampler)
				WriteSampler(bgEntry, r, e.ArrayIndex);
			else
				WriteCbvSrvUav(bgEntry, r, e.ArrayIndex);
		}
	}

	public void Cleanup()
	{
		if ((mCbvSrvUavOffset >= 0) && (mCachedCbvSrvUavCount > 0))
			mCpuSrvHeap.Free((uint32)mCbvSrvUavOffset, mCachedCbvSrvUavCount);
		if ((mSamplerOffset >= 0) && (mCachedSamplerCount > 0))
			mCpuSamplerHeap.Free((uint32)mSamplerOffset, mCachedSamplerCount);
		if ((mGpuSamplerOffset >= 0) && (mCachedSamplerCount > 0))
			mGpuSamplerHeap.Free((uint32)mGpuSamplerOffset, mCachedSamplerCount);

		mCbvSrvUavOffset = -1;
		mSamplerOffset = -1;
		mGpuSamplerOffset = -1;
	}

	private void WriteDescriptors(BindGroupDesc d)
	{
		let ranges = mLayout.Ranges;
		int entryIdx = 0;

		for (let r in ranges)
		{
			// A bindless range has no entry of its own; it is filled through UpdateBindless.
			switch (r.Type)
			{
			case .BindlessTextures, .BindlessSamplers, .BindlessStorageBuffers,
				.BindlessStorageTextures:
				continue;
			default:
			}

			if (entryIdx >= d.Entries.Length)
				break;

			let e = d.Entries[entryIdx++];

			if (r.HasDynamicOffset)
			{
				// Bound as a root descriptor, so what is recorded is the ADDRESS rather than
				// a descriptor written into a table.
				if (let buf = e.Buffer as DxBuffer)
					mDynAddrs.Add(buf.GpuAddress + e.BufferOffset);
				else
					mDynAddrs.Add(0);
				continue;
			}

			if (r.IsSampler)
				WriteSampler(e, r);
			else
				WriteCbvSrvUav(e, r);
		}
	}

	private void WriteCbvSrvUav(BindGroupEntry e, DxBindingRangeInfo r, uint32 arrayIdx = 0)
	{
		let off = (uint32)mCbvSrvUavOffset + r.HeapOffset + arrayIdx;
		let dest = mCpuSrvHeap.GetCpuHandle(off);

		switch (r.Type)
		{
		case .UniformBuffer:
			if (let buf = e.Buffer as DxBuffer)
			{
				D3D12_CONSTANT_BUFFER_VIEW_DESC cbv = .();
				cbv.BufferLocation = buf.GpuAddress + e.BufferOffset;
				let sz = (e.BufferSize > 0) ? e.BufferSize : buf.Desc.Size;
				cbv.SizeInBytes = (uint32)((sz + 255) & ~(uint64)255);
				mDevice.CreateConstantBufferView(&cbv, dest);
			}

		case .StorageBufferReadOnly:
			if (let buf = e.Buffer as DxBuffer)
			{
				let sz = (e.BufferSize > 0) ? e.BufferSize : buf.Desc.Size;

				D3D12_SHADER_RESOURCE_VIEW_DESC srv = .();
				srv.ViewDimension = .D3D12_SRV_DIMENSION_BUFFER;
				srv.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;

				// A stride makes it STRUCTURED; without one it is a raw byte address buffer,
				// which is what an unsized storage buffer becomes.
				if (r.StorageBufferStride > 0)
				{
					srv.Format = .DXGI_FORMAT_UNKNOWN;
					srv.Buffer.FirstElement = e.BufferOffset / r.StorageBufferStride;
					srv.Buffer.NumElements = (uint32)(sz / r.StorageBufferStride);
					srv.Buffer.StructureByteStride = r.StorageBufferStride;
				}
				else
				{
					srv.Format = .DXGI_FORMAT_R32_TYPELESS;
					srv.Buffer.FirstElement = e.BufferOffset / 4;
					srv.Buffer.NumElements = (uint32)(sz / 4);
					srv.Buffer.Flags = .D3D12_BUFFER_SRV_FLAG_RAW;
				}

				mDevice.CreateShaderResourceView(buf.Handle, &srv, dest);
			}

		case .StorageBufferReadWrite:
			if (let buf = e.Buffer as DxBuffer)
			{
				let sz = (e.BufferSize > 0) ? e.BufferSize : buf.Desc.Size;

				D3D12_UNORDERED_ACCESS_VIEW_DESC uav = .();
				uav.ViewDimension = .D3D12_UAV_DIMENSION_BUFFER;

				if (r.StorageBufferStride > 0)
				{
					uav.Format = .DXGI_FORMAT_UNKNOWN;
					uav.Buffer.FirstElement = e.BufferOffset / r.StorageBufferStride;
					uav.Buffer.NumElements = (uint32)(sz / r.StorageBufferStride);
					uav.Buffer.StructureByteStride = r.StorageBufferStride;
				}
				else
				{
					uav.Format = .DXGI_FORMAT_R32_TYPELESS;
					uav.Buffer.FirstElement = e.BufferOffset / 4;
					uav.Buffer.NumElements = (uint32)(sz / 4);
					uav.Buffer.Flags = .D3D12_BUFFER_UAV_FLAG_RAW;
				}

				mDevice.CreateUnorderedAccessView(buf.Handle, null, &uav, dest);
			}

		case .SampledTexture, .BindlessTextures:
			if (let v = e.TextureView as DxTextureView)
			{
				mDevice.CopyDescriptorsSimple(1, dest, v.GetSrv(),
					.D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV);
			}

		case .StorageTextureReadOnly, .StorageTextureReadWrite, .BindlessStorageTextures:
			if (let v = e.TextureView as DxTextureView)
			{
				mDevice.CopyDescriptorsSimple(1, dest, v.GetUav(),
					.D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV);
			}

		case .AccelerationStructure:
			if (let dxAs = e.AccelStruct as DxAccelStruct)
			{
				// An acceleration structure SRV names no resource: the address IS the view.
				D3D12_SHADER_RESOURCE_VIEW_DESC asSrv = .();
				asSrv.Format = .DXGI_FORMAT_UNKNOWN;
				asSrv.ViewDimension = .D3D12_SRV_DIMENSION_RAYTRACING_ACCELERATION_STRUCTURE;
				asSrv.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
				asSrv.RaytracingAccelerationStructure.Location = dxAs.DeviceAddress;
				mDevice.CreateShaderResourceView(null, &asSrv, dest);
			}

		default:
		}
	}

	private void WriteSampler(BindGroupEntry e, DxBindingRangeInfo r, uint32 arrayIdx = 0)
	{
		let s = e.Sampler as DxSampler;
		if (s == null)
			return;

		let off = (uint32)mSamplerOffset + r.HeapOffset + arrayIdx;
		mDevice.CopyDescriptorsSimple(1, mCpuSamplerHeap.GetCpuHandle(off), s.Handle,
			.D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER);

		// And mirror it into the baked shader visible table, which SetBindGroup binds
		// directly rather than staging per draw.
		let gpuOff = (uint32)mGpuSamplerOffset + r.HeapOffset + arrayIdx;
		mDevice.CopyDescriptorsSimple(1, mGpuSamplerHeap.GetCpuHandle(gpuOff), s.Handle,
			.D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER);
	}
}

#endif // BF_PLATFORM_WINDOWS
