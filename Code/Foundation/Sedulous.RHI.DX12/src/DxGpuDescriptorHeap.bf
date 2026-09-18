using System;
using System.Collections;
using System.Threading;
using Sedulous.RHI;
using Win32;
using Win32.Graphics.Direct3D12;

namespace Sedulous.RHI.DX12;

/// A descriptor heap that hands out CONTIGUOUS BLOCKS, with a free list and coalescing.
///
/// Different from DxDescriptorHeapAllocator, which hands out single slots: a bind group needs
/// its descriptors adjacent, because a descriptor table is named by one handle and a count.
///
/// THREAD SAFE, and that is not decoration. Per pool descriptor staging calls this
/// concurrently while render bundles are recorded on job system workers. An unsynchronised
/// bump or free list hands two workers overlapping blocks, which corrupts live shader visible
/// descriptors and hangs the GPU.
class DxGpuDescriptorHeap
{
	private struct FreeBlock
	{
		public uint32 Offset;
		public uint32 Count;
	}

	private ID3D12DescriptorHeap* mHeap = null; // owned, released in Destroy
	private D3D12_CPU_DESCRIPTOR_HANDLE mCpuStart = .();
	private D3D12_GPU_DESCRIPTOR_HANDLE mGpuStart = .();
	private uint32 mIncrementSize = 0;
	private uint32 mCapacity = 0;
	private uint32 mNextFree = 0;
	private List<FreeBlock> mFreeBlocks = new .() ~ delete _;
	private Monitor mMonitor = new .() ~ delete _; // guards mNextFree and mFreeBlocks

	public ID3D12DescriptorHeap* Heap => mHeap;
	public uint32 IncrementSize => mIncrementSize;

	public Result<void> Initialize(ID3D12Device* device, D3D12_DESCRIPTOR_HEAP_TYPE type,
		uint32 capacity, bool shaderVisible = true)
	{
		mCapacity = capacity;

		D3D12_DESCRIPTOR_HEAP_DESC hd = .();
		hd.Type = type;
		hd.NumDescriptors = capacity;
		hd.Flags = shaderVisible
			? .D3D12_DESCRIPTOR_HEAP_FLAG_SHADER_VISIBLE
			: .D3D12_DESCRIPTOR_HEAP_FLAG_NONE;

		if (FAILED(device.CreateDescriptorHeap(&hd, ID3D12DescriptorHeap.IID, (void**)&mHeap)))
			return .Err;

		mCpuStart = mHeap.GetCPUDescriptorHandleForHeapStart();
		// Only a shader visible heap has a GPU handle; asking a CPU one is invalid.
		if (shaderVisible)
			mGpuStart = mHeap.GetGPUDescriptorHandleForHeapStart();
		mIncrementSize = device.GetDescriptorHandleIncrementSize(type);
		return .Ok;
	}

	/// A contiguous block of `count` descriptors, or -1 when the heap cannot fit one.
	public int32 Allocate(uint32 count)
	{
		if (count == 0)
			return -1;

		using (mMonitor.Enter())
		{
			// First fit from the free list.
			for (int i = 0; i < mFreeBlocks.Count; i++)
			{
				var b = mFreeBlocks[i];
				if (b.Count >= count)
				{
					let off = b.Offset;
					if (b.Count == count)
						mFreeBlocks.RemoveAt(i);
					else
						mFreeBlocks[i] = .() { Offset = b.Offset + count, Count = b.Count - count };
					return (int32)off;
				}
			}

			// Otherwise bump.
			if (mNextFree + count <= mCapacity)
			{
				let off = mNextFree;
				mNextFree += count;
				return (int32)off;
			}

			return -1;
		}
	}

	/// Give a block back, coalescing with any neighbour so the heap does not fragment into
	/// blocks too small to reuse.
	public void Free(uint32 offset, uint32 count)
	{
		if (count == 0)
			return;

		using (mMonitor.Enter())
		{
			var mOff = offset;
			var mCnt = count;

			for (int i = 0; i < mFreeBlocks.Count;)
			{
				if (mFreeBlocks[i].Offset + mFreeBlocks[i].Count == mOff)
				{
					mOff = mFreeBlocks[i].Offset;
					mCnt += mFreeBlocks[i].Count;
					mFreeBlocks.RemoveAt(i);
				}
				else if (mOff + mCnt == mFreeBlocks[i].Offset)
				{
					mCnt += mFreeBlocks[i].Count;
					mFreeBlocks.RemoveAt(i);
				}
				else
				{
					i++;
				}
			}

			// Touching the bump pointer? Give it straight back rather than listing it.
			if (mOff + mCnt == mNextFree)
				mNextFree = mOff;
			else
				mFreeBlocks.Add(.() { Offset = mOff, Count = mCnt });
		}
	}

	public D3D12_CPU_DESCRIPTOR_HANDLE GetCpuHandle(uint32 offset)
	{
		D3D12_CPU_DESCRIPTOR_HANDLE h = .();
		h.ptr = mCpuStart.ptr + (uint)offset * (uint)mIncrementSize;
		return h;
	}

	public D3D12_GPU_DESCRIPTOR_HANDLE GetGpuHandle(uint32 offset)
	{
		D3D12_GPU_DESCRIPTOR_HANDLE h = .();
		h.ptr = mGpuStart.ptr + (uint64)offset * (uint64)mIncrementSize;
		return h;
	}

	public void Destroy()
	{
		if (mHeap != null)
		{
			mHeap.Release();
			mHeap = null;
		}
		mFreeBlocks.Clear();
	}
}
