namespace Sedulous.RHI.DX12;

using System;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Sedulous.RHI;

/// DX12 implementation of IBuffer.
class DX12Buffer : IBuffer
{
	private ID3D12Resource* mResource;
	private BufferDesc mDesc;
	private D3D12_RESOURCE_STATES mState;
	private void* mMappedPtr;

	public BufferDesc Desc => mDesc;
	public uint64 Size => mDesc.Size;
	public BufferUsage Usage => mDesc.Usage;

	public this() { }

	public Result<void> Init(DX12Device device, BufferDesc desc)
	{
		mDesc = desc;

		let heapType = DX12Conversions.ToHeapType(desc.Memory);
		let flags = DX12Conversions.ToBufferFlags(desc.Usage);

		// Determine initial state based on heap type
		mState = .D3D12_RESOURCE_STATE_COMMON;
		if (heapType == .D3D12_HEAP_TYPE_UPLOAD)
			mState = .D3D12_RESOURCE_STATE_GENERIC_READ;
		else if (heapType == .D3D12_HEAP_TYPE_READBACK)
			mState = .D3D12_RESOURCE_STATE_COPY_DEST;

		uint64 alignedSize = (desc.Size + 255) & ~(uint64)255; // 256-byte alignment for CBVs

		D3D12_HEAP_PROPERTIES heapProps = .()
		{
			Type = heapType,
			CPUPageProperty = .D3D12_CPU_PAGE_PROPERTY_UNKNOWN,
			MemoryPoolPreference = .D3D12_MEMORY_POOL_UNKNOWN,
			CreationNodeMask = 0,
			VisibleNodeMask = 0
		};

		D3D12_RESOURCE_DESC resourceDesc = .()
		{
			Dimension = .D3D12_RESOURCE_DIMENSION_BUFFER,
			Alignment = 0,
			Width = alignedSize,
			Height = 1,
			DepthOrArraySize = 1,
			MipLevels = 1,
			Format = .DXGI_FORMAT_UNKNOWN,
			SampleDesc = .() { Count = 1, Quality = 0 },
			Layout = .D3D12_TEXTURE_LAYOUT_ROW_MAJOR,
			Flags = flags
		};

		HRESULT hr = device.Handle.CreateCommittedResource(
			&heapProps, .D3D12_HEAP_FLAG_NONE,
			&resourceDesc, mState, null,
			ID3D12Resource.IID, (void**)&mResource);

		if (!SUCCEEDED(hr))
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12Buffer: CreateCommittedResource failed (0x{hr:X})");
			return .Err;
		}

		// Persistently map upload/readback buffers
		if (heapType == .D3D12_HEAP_TYPE_UPLOAD || heapType == .D3D12_HEAP_TYPE_READBACK)
		{
			mResource.Map(0, null, &mMappedPtr);
		}

		return .Ok;
	}

	public void* Map()
	{
		if (mMappedPtr != null) return mMappedPtr;

		void* ptr = null;
		if (SUCCEEDED(mResource.Map(0, null, &ptr)))
			return ptr;
		return null;
	}

	public void Unmap()
	{
		// Don't unmap persistently mapped buffers
		if (mMappedPtr != null) return;
		mResource.Unmap(0, null);
	}

	public void Cleanup(DX12Device device)
	{
		if (mMappedPtr != null)
		{
			mResource.Unmap(0, null);
			mMappedPtr = null;
		}
		if (mResource != null)
		{
			mResource.Release();
			mResource = null;
		}
	}

	// --- Internal ---
	public ID3D12Resource* Handle => mResource;
	public D3D12_RESOURCE_STATES State { get => mState; set => mState = value; }
}
