using System;
using Sedulous.Core.Logging;
using Sedulous.RHI;
using Win32;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi.Common;

namespace Sedulous.RHI.DX12;

/// One committed buffer resource.
///
/// Upload and readback buffers are mapped ONCE and left mapped. Those heaps are CPU visible
/// by construction, so a map per write would be pure overhead, and the RHI's Map is allowed
/// to hand back the same pointer every time.
///
/// The resource is a COM object owned here. Cleanup unmaps before releasing, because a
/// persistent mapping outliving its resource is exactly the shape that corrupts on the next
/// allocation.
class DxBuffer : IBuffer
{
	private BufferDesc mDesc = .();
	private ID3D12Resource* mResource = null; // owned, released in Cleanup
	private D3D12_RESOURCE_STATES mState = .D3D12_RESOURCE_STATE_COMMON;
	private void* mPersistentMap = null;

	public BufferDesc Desc => mDesc;
	public ID3D12Resource* Handle => mResource;
	public D3D12_RESOURCE_STATES CurrentState => mState;

	public void SetState(D3D12_RESOURCE_STATES s) => mState = s;

	public uint64 GpuAddress => (mResource != null) ? mResource.GetGPUVirtualAddress() : 0;

	public Result<void> Initialize(ID3D12Device* device, BufferDesc d)
	{
		mDesc = d;

		let heapType = DxConversions.ToHeapType(d.Memory);
		let flags = DxConversions.ToBufferResourceFlags(d.Usage);

		// The state a heap starts in is fixed by the heap type: an upload buffer is read by
		// the GPU and a readback one is written to it, and neither ever transitions.
		mState = .D3D12_RESOURCE_STATE_COMMON;
		if (heapType == .D3D12_HEAP_TYPE_UPLOAD)
			mState = .D3D12_RESOURCE_STATE_GENERIC_READ;
		if (heapType == .D3D12_HEAP_TYPE_READBACK)
			mState = .D3D12_RESOURCE_STATE_COPY_DEST;

		let alignedSize = (d.Size + 255) & ~(uint64)255; // 256 byte alignment for CBVs

		D3D12_HEAP_PROPERTIES heapProps = .();
		heapProps.Type = heapType;

		D3D12_RESOURCE_DESC rd = .();
		rd.Dimension = .D3D12_RESOURCE_DIMENSION_BUFFER;
		rd.Width = alignedSize;
		rd.Height = 1;
		rd.DepthOrArraySize = 1;
		rd.MipLevels = 1;
		rd.Format = .DXGI_FORMAT_UNKNOWN;
		rd.SampleDesc.Count = 1;
		rd.SampleDesc.Quality = 0;
		rd.Layout = .D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
		rd.Flags = flags;

		let hr = device.CreateCommittedResource(&heapProps, .D3D12_HEAP_FLAG_NONE, &rd, mState,
			null, ID3D12Resource.IID, (void**)&mResource);
		if (FAILED(hr))
		{
			GlobalLog(.Error, "DxBuffer: CreateCommittedResource failed (0x{0:X8})", (uint32)hr);
			return .Err;
		}

		if ((heapType == .D3D12_HEAP_TYPE_UPLOAD) || (heapType == .D3D12_HEAP_TYPE_READBACK))
			mResource.Map(0, null, &mPersistentMap);

		return .Ok;
	}

	public void* Map()
	{
		if (mPersistentMap != null)
			return mPersistentMap;

		void* ptr = null;
		if (SUCCEEDED(mResource.Map(0, null, &ptr)))
			return ptr;
		return null;
	}

	public void Unmap()
	{
		// A persistent mapping is never given up here; Cleanup owns that.
		if (mPersistentMap != null)
			return;

		mResource.Unmap(0, null);
	}

	public void Cleanup()
	{
		if (mPersistentMap != null)
		{
			mResource.Unmap(0, null);
			mPersistentMap = null;
		}

		if (mResource != null)
		{
			mResource.Release();
			mResource = null;
		}
	}
}
