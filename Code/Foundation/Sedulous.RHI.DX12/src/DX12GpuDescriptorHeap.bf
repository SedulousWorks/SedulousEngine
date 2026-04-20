namespace Sedulous.RHI.DX12;

using System;
using System.Collections;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;

/// GPU-visible descriptor heap with contiguous block allocation.
/// Used for CBV/SRV/UAV and Sampler heaps that are shader-visible.
class DX12GpuDescriptorHeap
{
	private ID3D12DescriptorHeap* mHeap;
	private D3D12_DESCRIPTOR_HEAP_TYPE mType;
	private D3D12_CPU_DESCRIPTOR_HANDLE mCpuStart;
	private D3D12_GPU_DESCRIPTOR_HANDLE mGpuStart;
	private uint32 mIncrementSize;
	private uint32 mCapacity;
	private uint32 mNextFree;
	private List<FreeBlock> mFreeBlocks = new .() ~ delete _;

	struct FreeBlock
	{
		public uint32 Offset;
		public uint32 Count;
	}

	private bool mShaderVisible;

	public this(ID3D12Device* device, D3D12_DESCRIPTOR_HEAP_TYPE type, uint32 capacity,
		bool shaderVisible = true)
	{
		mType = type;
		mCapacity = capacity;
		mShaderVisible = shaderVisible;

		D3D12_DESCRIPTOR_HEAP_DESC desc = .()
		{
			Type = type,
			NumDescriptors = capacity,
			Flags = shaderVisible ? .D3D12_DESCRIPTOR_HEAP_FLAG_SHADER_VISIBLE : .D3D12_DESCRIPTOR_HEAP_FLAG_NONE,
			NodeMask = 0
		};

		device.CreateDescriptorHeap(&desc, ID3D12DescriptorHeap.IID, (void**)&mHeap);
		mCpuStart = mHeap.GetCPUDescriptorHandleForHeapStart();
		if (shaderVisible)
			mGpuStart = mHeap.GetGPUDescriptorHandleForHeapStart();
		mIncrementSize = device.GetDescriptorHandleIncrementSize(type);
	}

	/// Allocates a contiguous block of descriptors.
	/// Returns the offset, or -1 on failure.
	public int32 Allocate(uint32 count)
	{
		if (count == 0) return -1;

		// Search free list for first fit
		for (int i = 0; i < mFreeBlocks.Count; i++)
		{
			let block = mFreeBlocks[i];
			if (block.Count >= count)
			{
				let offset = block.Offset;
				if (block.Count == count)
					mFreeBlocks.RemoveAt(i);
				else
					mFreeBlocks[i] = .() { Offset = block.Offset + count, Count = block.Count - count };
				return (int32)offset;
			}
		}

		// Bump allocate
		if (mNextFree + count <= mCapacity)
		{
			let offset = mNextFree;
			mNextFree += count;
			return (int32)offset;
		}

		return -1; // Out of space
	}

	/// Frees a previously allocated block, coalescing with adjacent free blocks.
	public void Free(uint32 offset, uint32 count)
	{
		if (count == 0) return;

		var mergedOffset = offset;
		var mergedCount = count;

		// Coalesce with adjacent free blocks (iterate backwards to safely remove)
		for (int i = mFreeBlocks.Count - 1; i >= 0; i--)
		{
			let block = mFreeBlocks[i];
			if (block.Offset + block.Count == mergedOffset)
			{
				// Block is immediately before us - merge left
				mergedOffset = block.Offset;
				mergedCount += block.Count;
				mFreeBlocks.RemoveAt(i);
			}
			else if (mergedOffset + mergedCount == block.Offset)
			{
				// Block is immediately after us - merge right
				mergedCount += block.Count;
				mFreeBlocks.RemoveAt(i);
			}
		}

		// If merged block extends to the bump pointer, reclaim it
		if (mergedOffset + mergedCount == mNextFree)
			mNextFree = mergedOffset;
		else
			mFreeBlocks.Add(.() { Offset = mergedOffset, Count = mergedCount });
	}

	/// Gets the CPU handle at the given offset.
	public D3D12_CPU_DESCRIPTOR_HANDLE GetCpuHandle(uint32 offset)
	{
		D3D12_CPU_DESCRIPTOR_HANDLE handle = default;
		handle.ptr = mCpuStart.ptr + offset * mIncrementSize;
		return handle;
	}

	/// Gets the GPU handle at the given offset.
	public D3D12_GPU_DESCRIPTOR_HANDLE GetGpuHandle(uint32 offset)
	{
		D3D12_GPU_DESCRIPTOR_HANDLE handle = default;
		handle.ptr = mGpuStart.ptr + offset * mIncrementSize;
		return handle;
	}

	public void Destroy()
	{
		if (mHeap != null)
		{
			mHeap.Release();
			mHeap = null;
		}
	}

	public ID3D12DescriptorHeap* Heap => mHeap;
	public uint32 IncrementSize => mIncrementSize;
	public D3D12_DESCRIPTOR_HEAP_TYPE HeapType => mType;
}
