namespace Sedulous.RHI.DX12;

using System;  // Math
using System.Collections;
using Win32.Graphics.Direct3D12;

/// Bump-allocating staging region within a GPU-visible descriptor heap.
/// Used by DX12CommandEncoder to copy bind group descriptors at bind time,
/// decoupling bind group lifetime from GPU execution.
///
/// Bind groups write descriptors into a CPU-visible (non-shader-visible) heap.
/// SetBindGroup copies from the CPU heap into this staging region in the GPU heap.
/// The bump pointer resets when the command pool resets (after fence wait).
class DX12DescriptorStaging
{
	struct Block
	{
		public int32 Offset;
		public uint32 Capacity;
	}

	private DX12GpuDescriptorHeap mCpuHeap;    // Source: CPU-visible, readable
	private DX12GpuDescriptorHeap mGpuHeap;    // Destination: GPU-visible staging region
	private ID3D12Device* mD3DDevice;
	private D3D12_DESCRIPTOR_HEAP_TYPE mHeapType;
	private int32 mBlockOffset = -1;  // Current block start offset in GPU heap
	private uint32 mCapacity;
	private uint32 mCurrent;           // Bump pointer (relative to mBlockOffset)
	private List<Block> mRetiredBlocks = new .() ~ delete _;  // Old blocks kept alive until reset

	public this(DX12GpuDescriptorHeap cpuHeap, DX12GpuDescriptorHeap gpuHeap,
		ID3D12Device* device, D3D12_DESCRIPTOR_HEAP_TYPE heapType, uint32 initialCapacity)
	{
		mCpuHeap = cpuHeap;
		mGpuHeap = gpuHeap;
		mD3DDevice = device;
		mHeapType = heapType;
		mCapacity = initialCapacity;
	}

	/// Copies `count` descriptors from `srcOffset` in the CPU heap into the
	/// staging region in the GPU heap. Returns the staging offset in the GPU heap,
	/// or -1 on failure.
	public int32 CopyFrom(uint32 srcOffset, uint32 count)
	{
		if (count == 0) return -1;

		// Lazy allocation on first use
		if (mBlockOffset < 0)
		{
			mBlockOffset = mGpuHeap.Allocate(mCapacity);
			if (mBlockOffset < 0) return -1;
			mCurrent = 0;
		}

		// Grow if needed: retire current block, allocate a bigger one
		if (mCurrent + count > mCapacity)
		{
			uint32 newCapacity = Math.Max(mCapacity * 2, mCurrent + count);
			int32 newBlock = mGpuHeap.Allocate(newCapacity);
			if (newBlock < 0) return -1;

			// Retire old block — don't free it yet, GPU may still reference staged descriptors
			mRetiredBlocks.Add(.() { Offset = mBlockOffset, Capacity = mCapacity });
			mBlockOffset = newBlock;
			mCapacity = newCapacity;
			mCurrent = 0;
		}

		uint32 dstOffset = (uint32)mBlockOffset + mCurrent;

		// Copy descriptors from CPU heap (bind group) → GPU heap (staging)
		mD3DDevice.CopyDescriptorsSimple(count,
			mGpuHeap.GetCpuHandle(dstOffset),
			mCpuHeap.GetCpuHandle(srcOffset),
			mHeapType);

		mCurrent += count;
		return (int32)dstOffset;
	}

	/// Resets the bump pointer. Called when the command pool resets after fence wait.
	/// Frees retired blocks since GPU is done with them.
	public void Reset()
	{
		mCurrent = 0;
		for (let block in mRetiredBlocks)
			mGpuHeap.Free((uint32)block.Offset, block.Capacity);
		mRetiredBlocks.Clear();
	}

	/// Frees all blocks back to the GPU heap.
	public void Destroy()
	{
		if (mBlockOffset >= 0)
		{
			mGpuHeap.Free((uint32)mBlockOffset, mCapacity);
			mBlockOffset = -1;
		}
		for (let block in mRetiredBlocks)
			mGpuHeap.Free((uint32)block.Offset, block.Capacity);
		mRetiredBlocks.Clear();
	}
}
