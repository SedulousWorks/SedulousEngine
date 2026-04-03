namespace Sedulous.RHI.DX12;

using System;
using System.Collections;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi.Common;
using Win32.System.Threading;
using Sedulous.RHI;

/// DX12 implementation of ITransferBatch.
/// Uses upload heap staging buffers and a dedicated command list for transfers.
class DX12TransferBatch : ITransferBatch
{
	private DX12Device mDevice;
	private DX12Queue mQueue;
	private ID3D12CommandAllocator* mAllocator;
	private ID3D12GraphicsCommandList* mCmdList;
	private bool mIsRecording;

	// Staging buffers to clean up after submit
	private List<ID3D12Resource*> mStagingBuffers = new .() ~ delete _;

	// Fence for synchronous submit
	private ID3D12Fence* mFence;
	private uint64 mFenceValue;
	private HANDLE mFenceEvent;

	public this() { }

	public Result<void> Init(DX12Device device, DX12Queue queue)
	{
		mDevice = device;
		mQueue = queue;

		HRESULT hr = device.Handle.CreateCommandAllocator(
			DX12Conversions.ToCommandListType(queue.Type),
			ID3D12CommandAllocator.IID, (void**)&mAllocator);
		if (!SUCCEEDED(hr))
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12TransferBatch: CreateCommandAllocator failed (0x{hr:X})");
			return .Err;
		}

		hr = device.Handle.CreateCommandList(0,
			DX12Conversions.ToCommandListType(queue.Type),
			mAllocator, null,
			ID3D12GraphicsCommandList.IID, (void**)&mCmdList);
		if (!SUCCEEDED(hr))
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12TransferBatch: CreateCommandList failed (0x{hr:X})");
			return .Err;
		}

		// Command list starts open; close it until we need it
		mCmdList.Close();

		// Create fence for sync submit
		hr = device.Handle.CreateFence(0, .D3D12_FENCE_FLAG_NONE,
			ID3D12Fence.IID, (void**)&mFence);
		if (!SUCCEEDED(hr))
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12TransferBatch: CreateFence failed (0x{hr:X})");
			return .Err;
		}

		mFenceEvent = CreateEventW(null, FALSE, FALSE, null);
		mFenceValue = 0;

		return .Ok;
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

	public void WriteBuffer(IBuffer dst, uint64 dstOffset, Span<uint8> data)
	{
		let dxDst = dst as DX12Buffer;
		if (dxDst == null || data.Length == 0) return;

		EnsureRecording();

		// Create staging buffer
		let stagingSize = (uint64)data.Length;
		ID3D12Resource* staging = null;

		D3D12_HEAP_PROPERTIES heapProps = .()
		{
			Type = .D3D12_HEAP_TYPE_UPLOAD,
			CPUPageProperty = .D3D12_CPU_PAGE_PROPERTY_UNKNOWN,
			MemoryPoolPreference = .D3D12_MEMORY_POOL_UNKNOWN,
			CreationNodeMask = 0,
			VisibleNodeMask = 0
		};

		D3D12_RESOURCE_DESC resourceDesc = .()
		{
			Dimension = .D3D12_RESOURCE_DIMENSION_BUFFER,
			Alignment = 0,
			Width = stagingSize,
			Height = 1,
			DepthOrArraySize = 1,
			MipLevels = 1,
			Format = .DXGI_FORMAT_UNKNOWN,
			SampleDesc = .() { Count = 1, Quality = 0 },
			Layout = .D3D12_TEXTURE_LAYOUT_ROW_MAJOR,
			Flags = .D3D12_RESOURCE_FLAG_NONE
		};

		HRESULT hr = mDevice.Handle.CreateCommittedResource(
			&heapProps, .D3D12_HEAP_FLAG_NONE,
			&resourceDesc, .D3D12_RESOURCE_STATE_GENERIC_READ, null,
			ID3D12Resource.IID, (void**)&staging);
		if (!SUCCEEDED(hr)) return;

		// Map and copy data
		void* mapped = null;
		staging.Map(0, null, &mapped);
		Internal.MemCpy(mapped, data.Ptr, data.Length);
		staging.Unmap(0, null);

		mStagingBuffers.Add(staging);

		// Record copy command
		mCmdList.CopyBufferRegion(dxDst.Handle, dstOffset, staging, 0, stagingSize);
	}

	public void WriteTexture(ITexture dst, Span<uint8> data,
		TextureDataLayout dataLayout, Extent3D extent,
		uint32 mipLevel, uint32 arrayLayer)
	{
		let dxTex = dst as DX12Texture;
		if (dxTex == null || data.Length == 0) return;

		EnsureRecording();

		// Calculate aligned row pitch (D3D12 requires 256-byte row alignment)
		uint32 alignedRowPitch = (dataLayout.BytesPerRow + 255) & ~(uint32)255;
		uint32 rowsPerImage = (dataLayout.RowsPerImage > 0) ? dataLayout.RowsPerImage : extent.Height;
		uint64 stagingSize = (uint64)alignedRowPitch * rowsPerImage * extent.Depth;

		ID3D12Resource* staging = null;

		D3D12_HEAP_PROPERTIES heapProps = .()
		{
			Type = .D3D12_HEAP_TYPE_UPLOAD,
			CPUPageProperty = .D3D12_CPU_PAGE_PROPERTY_UNKNOWN,
			MemoryPoolPreference = .D3D12_MEMORY_POOL_UNKNOWN,
			CreationNodeMask = 0,
			VisibleNodeMask = 0
		};

		D3D12_RESOURCE_DESC resourceDesc = .()
		{
			Dimension = .D3D12_RESOURCE_DIMENSION_BUFFER,
			Alignment = 0,
			Width = stagingSize,
			Height = 1,
			DepthOrArraySize = 1,
			MipLevels = 1,
			Format = .DXGI_FORMAT_UNKNOWN,
			SampleDesc = .() { Count = 1, Quality = 0 },
			Layout = .D3D12_TEXTURE_LAYOUT_ROW_MAJOR,
			Flags = .D3D12_RESOURCE_FLAG_NONE
		};

		HRESULT hr = mDevice.Handle.CreateCommittedResource(
			&heapProps, .D3D12_HEAP_FLAG_NONE,
			&resourceDesc, .D3D12_RESOURCE_STATE_GENERIC_READ, null,
			ID3D12Resource.IID, (void**)&staging);
		if (!SUCCEEDED(hr)) return;

		// Map and copy data row by row (to handle pitch alignment)
		void* mapped = null;
		staging.Map(0, null, &mapped);

		uint8* srcPtr = data.Ptr + dataLayout.Offset;
		uint8* dstPtr = (uint8*)mapped;
		for (uint32 z = 0; z < extent.Depth; z++)
		{
			for (uint32 row = 0; row < rowsPerImage; row++)
			{
				Internal.MemCpy(
					dstPtr + (z * rowsPerImage + row) * alignedRowPitch,
					srcPtr + (z * rowsPerImage + row) * dataLayout.BytesPerRow,
					dataLayout.BytesPerRow);
			}
		}

		staging.Unmap(0, null);
		mStagingBuffers.Add(staging);

		// Transition texture to copy dest
		D3D12_RESOURCE_BARRIER barrier = default;
		barrier.Type = .D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
		barrier.Transition.pResource = dxTex.Handle;
		barrier.Transition.StateBefore = dxTex.State;
		barrier.Transition.StateAfter = .D3D12_RESOURCE_STATE_COPY_DEST;
		barrier.Transition.Subresource = 0xFFFFFFFF;
		if (dxTex.State != .D3D12_RESOURCE_STATE_COPY_DEST)
			mCmdList.ResourceBarrier(1, &barrier);

		let subresource = mipLevel + arrayLayer * dxTex.Desc.MipLevelCount;

		D3D12_TEXTURE_COPY_LOCATION srcLoc = default;
		srcLoc.pResource = staging;
		srcLoc.Type = .D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT;
		srcLoc.PlacedFootprint.Offset = 0;
		srcLoc.PlacedFootprint.Footprint.Format = DX12Conversions.ToDxgiFormat(dxTex.Desc.Format);
		srcLoc.PlacedFootprint.Footprint.Width = extent.Width;
		srcLoc.PlacedFootprint.Footprint.Height = extent.Height;
		srcLoc.PlacedFootprint.Footprint.Depth = extent.Depth;
		srcLoc.PlacedFootprint.Footprint.RowPitch = alignedRowPitch;

		D3D12_TEXTURE_COPY_LOCATION dstLoc = default;
		dstLoc.pResource = dxTex.Handle;
		dstLoc.Type = .D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
		dstLoc.SubresourceIndex = subresource;

		mCmdList.CopyTextureRegion(&dstLoc, 0, 0, 0, &srcLoc, null);

		// Transition back to common
		barrier.Transition.StateBefore = .D3D12_RESOURCE_STATE_COPY_DEST;
		barrier.Transition.StateAfter = .D3D12_RESOURCE_STATE_COMMON;
		mCmdList.ResourceBarrier(1, &barrier);
		dxTex.State = .D3D12_RESOURCE_STATE_COMMON;
	}

	public Result<void> Submit()
	{
		if (!mIsRecording) return .Ok;

		mCmdList.Close();
		mIsRecording = false;

		ID3D12CommandList*[1] lists = .((ID3D12CommandList*)mCmdList);
		mQueue.Handle.ExecuteCommandLists(1, &lists[0]);

		// Wait for completion
		mFenceValue++;
		mQueue.Handle.Signal(mFence, mFenceValue);
		if (mFence.GetCompletedValue() < mFenceValue)
		{
			mFence.SetEventOnCompletion(mFenceValue, mFenceEvent);
			WaitForSingleObject(mFenceEvent, 0xFFFFFFFF);
		}

		ReleaseStagingBuffers();
		return .Ok;
	}

	public Result<void> SubmitAsync(IFence fence, uint64 signalValue)
	{
		if (!mIsRecording) return .Ok;

		mCmdList.Close();
		mIsRecording = false;

		ID3D12CommandList*[1] lists = .((ID3D12CommandList*)mCmdList);
		mQueue.Handle.ExecuteCommandLists(1, &lists[0]);

		if (let dxFence = fence as DX12Fence)
			mQueue.Handle.Signal(dxFence.Handle, signalValue);

		// Note: staging buffers can't be released until GPU is done.
		// Caller must wait on the fence before calling Reset().
		return .Ok;
	}

	public void Reset()
	{
		ReleaseStagingBuffers();
	}

	public void Destroy()
	{
		ReleaseStagingBuffers();

		if (mFenceEvent != 0) { CloseHandle(mFenceEvent); mFenceEvent = default; }
		if (mFence != null) { mFence.Release(); mFence = null; }
		if (mCmdList != null) { mCmdList.Release(); mCmdList = null; }
		if (mAllocator != null) { mAllocator.Release(); mAllocator = null; }
	}

	private void ReleaseStagingBuffers()
	{
		for (let buf in mStagingBuffers)
			buf.Release();
		mStagingBuffers.Clear();
	}
}
