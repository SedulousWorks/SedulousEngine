using System;
using System.Collections;
using Sedulous.Core.Logging;
using Sedulous.RHI;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi.Common;
using Win32.System.Threading;
using Win32.System.WindowsProgramming;

namespace Sedulous.RHI.DX12;

/// One shot uploads: a command list of its own, and the staging buffers feeding it.
///
/// Every write allocates an UPLOAD heap buffer, copies into it, and records a GPU copy out of
/// it. Those staging buffers cannot be released until the GPU has read them, which is what
/// separates the two submits: Submit waits on its own fence and frees them, while SubmitAsync
/// signals the caller's fence and leaves them, so the caller must wait and then call Reset.
///
/// The list, allocator, fence and every staging buffer are owned here.
class DxTransferBatch : ITransferBatch
{
	private ID3D12Device* mDevice = null; // NOT owned
	private ID3D12CommandQueue* mQueue = null; // NOT owned, the queue that made this
	private ID3D12CommandAllocator* mAllocator = null; // owned
	private ID3D12GraphicsCommandList* mCmdList = null; // owned
	private ID3D12Fence* mFence = null; // owned
	private HANDLE mFenceEvent = default;
	private uint64 mFenceValue = 0;
	private bool mIsRecording = false;
	private List<ID3D12Resource*> mStagingBuffers = new .() ~ delete _; // owned, each released

	public Result<void> Initialize(ID3D12Device* device, ID3D12CommandQueue* queue,
		QueueType queueType)
	{
		mDevice = device;
		mQueue = queue;

		let listType = DxConversions.ToCommandListType(queueType);

		var hr = device.CreateCommandAllocator(listType, ID3D12CommandAllocator.IID,
			(void**)&mAllocator);
		if (FAILED(hr))
		{
			GlobalLog(.Error, "DxTransferBatch: CreateCommandAllocator failed (0x{0:X8})",
				(uint32)hr);
			return .Err;
		}

		hr = device.CreateCommandList(0, listType, mAllocator, null,
			ID3D12GraphicsCommandList.IID, (void**)&mCmdList);
		if (FAILED(hr))
		{
			GlobalLog(.Error, "DxTransferBatch: CreateCommandList failed (0x{0:X8})", (uint32)hr);
			return .Err;
		}

		// A new command list arrives OPEN, so it is closed until there is something to record.
		mCmdList.Close();

		hr = device.CreateFence(0, .D3D12_FENCE_FLAG_NONE, ID3D12Fence.IID, (void**)&mFence);
		if (FAILED(hr))
		{
			GlobalLog(.Error, "DxTransferBatch: CreateFence failed (0x{0:X8})", (uint32)hr);
			return .Err;
		}

		mFenceEvent = CreateEventW(null, FALSE, FALSE, null);
		mFenceValue = 0;
		return .Ok;
	}

	/// An upload heap buffer of `size`, already tracked for release. Null on failure.
	private ID3D12Resource* CreateStaging(uint64 size)
	{
		D3D12_HEAP_PROPERTIES heapProps = .();
		heapProps.Type = .D3D12_HEAP_TYPE_UPLOAD;

		D3D12_RESOURCE_DESC rd = .();
		rd.Dimension = .D3D12_RESOURCE_DIMENSION_BUFFER;
		rd.Width = size;
		rd.Height = 1;
		rd.DepthOrArraySize = 1;
		rd.MipLevels = 1;
		rd.Format = .DXGI_FORMAT_UNKNOWN;
		rd.SampleDesc.Count = 1;
		rd.SampleDesc.Quality = 0;
		rd.Layout = .D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
		rd.Flags = .D3D12_RESOURCE_FLAG_NONE;

		ID3D12Resource* staging = null;
		if (FAILED(mDevice.CreateCommittedResource(&heapProps, .D3D12_HEAP_FLAG_NONE, &rd,
			.D3D12_RESOURCE_STATE_GENERIC_READ, null, ID3D12Resource.IID, (void**)&staging)))
			return null;

		mStagingBuffers.Add(staging);
		return staging;
	}

	public void WriteBuffer(IBuffer dst, uint64 dstOffset, Span<uint8> data)
	{
		let dxDst = dst as DxBuffer;
		if ((dxDst == null) || (data.Length == 0))
			return;

		EnsureRecording();

		let stagingSize = (uint64)data.Length;
		let staging = CreateStaging(stagingSize);
		if (staging == null)
			return;

		void* mapped = null;
		staging.Map(0, null, &mapped);
		Internal.MemCpy(mapped, data.Ptr, data.Length);
		staging.Unmap(0, null);

		mCmdList.CopyBufferRegion(dxDst.Handle, dstOffset, staging, 0, stagingSize);
	}

	public void WriteTexture(ITexture dst, Span<uint8> data, TextureDataLayout layout,
		Extent3D extent, uint32 mipLevel = 0, uint32 arrayLayer = 0)
	{
		let dxTex = dst as DxTexture;
		if ((dxTex == null) || (data.Length == 0))
			return;

		EnsureRecording();

		// D3D12 wants each row of a copy source 256 byte aligned, which the caller's data
		// almost never is, so the staging copy re-pitches it row by row.
		let alignedRowPitch = (layout.BytesPerRow + 255) & ~(uint32)255;
		let rowsPerImage = (layout.RowsPerImage > 0) ? layout.RowsPerImage : extent.Height;
		let stagingSize = (uint64)alignedRowPitch * rowsPerImage * extent.Depth;

		let staging = CreateStaging(stagingSize);
		if (staging == null)
			return;

		void* mapped = null;
		staging.Map(0, null, &mapped);
		let srcPtr = data.Ptr + layout.Offset;
		let dstPtr = (uint8*)mapped;
		for (uint32 z = 0; z < extent.Depth; z++)
		{
			for (uint32 row = 0; row < rowsPerImage; row++)
			{
				Internal.MemCpy(dstPtr + (z * rowsPerImage + row) * alignedRowPitch,
					srcPtr + (z * rowsPerImage + row) * layout.BytesPerRow, layout.BytesPerRow);
			}
		}
		staging.Unmap(0, null);

		// Through the shared helper rather than an ALL_SUBRESOURCES barrier built from the
		// current state: that is only valid while the texture is uniform, and re-uploading one
		// mip of a texture that has been through mip generation, which leaves per subresource
		// tracking behind, would otherwise carry a stale before state and be rejected.
		DxTexture.TransitionWhole(mCmdList, dxTex, .D3D12_RESOURCE_STATE_COPY_DEST);

		let subresource = mipLevel + arrayLayer * dxTex.Desc.MipLevelCount;

		D3D12_TEXTURE_COPY_LOCATION srcLoc = .();
		srcLoc.pResource = staging;
		srcLoc.Type = .D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT;
		srcLoc.PlacedFootprint.Offset = 0;
		srcLoc.PlacedFootprint.Footprint.Format = DxConversions.ToDxgiFormat(dxTex.Desc.Format);
		srcLoc.PlacedFootprint.Footprint.Width = extent.Width;
		srcLoc.PlacedFootprint.Footprint.Height = extent.Height;
		srcLoc.PlacedFootprint.Footprint.Depth = extent.Depth;
		srcLoc.PlacedFootprint.Footprint.RowPitch = alignedRowPitch;

		D3D12_TEXTURE_COPY_LOCATION dstLoc = .();
		dstLoc.pResource = dxTex.Handle;
		dstLoc.Type = .D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
		dstLoc.SubresourceIndex = subresource;

		mCmdList.CopyTextureRegion(&dstLoc, 0, 0, 0, &srcLoc, null);

		// Back to common, which is the resting state the rest of the backend assumes.
		DxTexture.TransitionWhole(mCmdList, dxTex, .D3D12_RESOURCE_STATE_COMMON);
	}

	public Result<void> Submit()
	{
		if (!mIsRecording)
			return .Ok;

		mCmdList.Close();
		mIsRecording = false;

		ID3D12CommandList*[1] lists = .((ID3D12CommandList*)mCmdList);
		mQueue.ExecuteCommandLists(1, &lists[0]);

		// Waits here, which is what makes it safe to free the staging buffers below.
		mFenceValue++;
		mQueue.Signal(mFence, mFenceValue);
		if (mFence.GetCompletedValue() < mFenceValue)
		{
			mFence.SetEventOnCompletion(mFenceValue, mFenceEvent);
			WaitForSingleObject(mFenceEvent, INFINITE);
		}

		ReleaseStagingBuffers();
		return .Ok;
	}

	public Result<void> SubmitAsync(IFence fence, uint64 signalValue)
	{
		if (!mIsRecording)
			return .Ok;

		mCmdList.Close();
		mIsRecording = false;

		ID3D12CommandList*[1] lists = .((ID3D12CommandList*)mCmdList);
		mQueue.ExecuteCommandLists(1, &lists[0]);

		if (let dxFence = fence as DxFence)
			mQueue.Signal(dxFence.Handle, signalValue);

		// The staging buffers STAY, because the GPU has not read them yet. The caller waits on
		// the fence and then calls Reset.
		return .Ok;
	}

	public void Reset() => ReleaseStagingBuffers();

	public void Destroy()
	{
		ReleaseStagingBuffers();

		if (mFenceEvent != default)
		{
			CloseHandle(mFenceEvent);
			mFenceEvent = default;
		}

		if (mFence != null) { mFence.Release(); mFence = null; }
		if (mCmdList != null) { mCmdList.Release(); mCmdList = null; }
		if (mAllocator != null) { mAllocator.Release(); mAllocator = null; }
	}

	private void EnsureRecording()
	{
		if (!mIsRecording)
		{
			mAllocator.Reset();
			mCmdList.Reset(mAllocator, null);
			mIsRecording = true;
		}
	}

	private void ReleaseStagingBuffers()
	{
		for (let s in mStagingBuffers)
			s.Release();
		mStagingBuffers.Clear();
	}
}
