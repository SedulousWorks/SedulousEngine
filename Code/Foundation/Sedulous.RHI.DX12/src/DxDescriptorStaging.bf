#if BF_PLATFORM_WINDOWS
using System;
using System.Collections;
using Sedulous.Core.Logging;
using Sedulous.RHI;
using Win32.Graphics.Direct3D12;

namespace Sedulous.RHI.DX12;

/// Copies a bind group's descriptors from the CPU heap into the shader visible one.
///
/// D3D12 can only sample descriptors from a SHADER VISIBLE heap, and those are small, so a
/// bind group's descriptors live in a big CPU heap and are copied in for the frame that uses
/// them. This is the bump allocator over that copy, per command pool.
///
/// Runs are DEDUPLICATED within a cycle. A bind group is immutable after creation, so binding
/// the same group in fifty draws should cost one staged copy, not fifty.
///
/// It owns no heap. Both belong to the device; what it owns is the BLOCKS it has taken out of
/// the shader visible one, which Destroy hands back.
class DxDescriptorStaging
{
	private struct RetiredBlock
	{
		public int32 Offset;
		public uint32 Capacity;
	}

	private struct StagedRun
	{
		public uint32 SrcOffset;
		public uint32 Count;
		public int32 StagedOffset;
	}

	/// Bound on the dedup cache's linear scan; runs beyond it stage without caching.
	private const int cMaxDedupEntries = 256;

	private DxGpuDescriptorHeap mCpuHeap = null; // NOT owned, the device's
	private DxGpuDescriptorHeap mGpuHeap = null; // NOT owned, the device's
	private ID3D12Device* mDevice = null; // NOT owned
	private D3D12_DESCRIPTOR_HEAP_TYPE mHeapType = .D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV;
	private int32 mBlockOffset = -1;
	private uint32 mCapacity = 0;
	private uint32 mCurrent = 0;
	private bool mFailLogged = false;
	private List<RetiredBlock> mRetiredBlocks = new .() ~ delete _;
	private List<StagedRun> mStaged = new .() ~ delete _; // dedup cache, cleared each Reset

	public void Initialize(DxGpuDescriptorHeap cpuHeap, DxGpuDescriptorHeap gpuHeap,
		ID3D12Device* device, D3D12_DESCRIPTOR_HEAP_TYPE heapType, uint32 initialCapacity)
	{
		mCpuHeap = cpuHeap;
		mGpuHeap = gpuHeap;
		mDevice = device;
		mHeapType = heapType;
		mCapacity = initialCapacity;
	}

	/// Copy `count` descriptors from `srcOffset` in the CPU heap into staging, and answer
	/// where they landed in the shader visible heap. -1 when the heap is exhausted.
	public int32 CopyFrom(uint32 srcOffset, uint32 count)
	{
		if (count == 0)
			return -1;

		// Already staged this cycle? Bind groups are immutable, so the old copy still stands.
		for (let e in mStaged)
		{
			if ((e.SrcOffset == srcOffset) && (e.Count == count))
				return e.StagedOffset;
		}

		// The block is taken on first use rather than at construction, so a pool that never
		// binds anything costs no heap space.
		if (mBlockOffset < 0)
		{
			mBlockOffset = mGpuHeap.Allocate(mCapacity);
			if (mBlockOffset < 0)
			{
				LogExhausted();
				return -1;
			}
			mCurrent = 0;
		}

		// Out of room: retire this block and take a bigger one. The retired block cannot be
		// freed yet because draws already recorded still point into it; Reset frees it once
		// the pool recycles behind a fence.
		if (mCurrent + count > mCapacity)
		{
			let newCap = Math.Max(mCapacity * 2, mCurrent + count);
			let newBlock = mGpuHeap.Allocate(newCap);
			if (newBlock < 0)
			{
				LogExhausted();
				return -1;
			}

			mRetiredBlocks.Add(.() { Offset = mBlockOffset, Capacity = mCapacity });
			mBlockOffset = newBlock;
			mCapacity = newCap;
			mCurrent = 0;
		}

		let dstOffset = (uint32)mBlockOffset + mCurrent;
		mDevice.CopyDescriptorsSimple(count, mGpuHeap.GetCpuHandle(dstOffset),
			mCpuHeap.GetCpuHandle(srcOffset), mHeapType);
		mCurrent += count;

		if (mStaged.Count < cMaxDedupEntries)
		{
			mStaged.Add(.() { SrcOffset = srcOffset, Count = count,
				StagedOffset = (int32)dstOffset });
		}

		return (int32)dstOffset;
	}

	/// Rewind. Called when the command pool resets, which is after its fence has been waited
	/// on, so everything staged is known to be finished with.
	public void Reset()
	{
		mCurrent = 0;
		mStaged.Clear(); // the prior cycle's staged copies are gone once the pool recycles
		mFailLogged = false;

		for (let b in mRetiredBlocks)
			mGpuHeap.Free((uint32)b.Offset, b.Capacity);
		mRetiredBlocks.Clear();
	}

	public void Destroy()
	{
		if (mBlockOffset >= 0)
		{
			mGpuHeap.Free((uint32)mBlockOffset, mCapacity);
			mBlockOffset = -1;
		}

		for (let b in mRetiredBlocks)
			mGpuHeap.Free((uint32)b.Offset, b.Capacity);
		mRetiredBlocks.Clear();
	}

	/// A silent staging failure leaves the PREVIOUS root descriptor table bound, so draws
	/// sample stale, and later recycled, descriptors: flickering at best and a device hang at
	/// worst. Say so once per cycle, so exhaustion is never silent and never a wall of text.
	private void LogExhausted()
	{
		if (mFailLogged)
			return;

		mFailLogged = true;
		GlobalLog(.Error,
			"DxDescriptorStaging: shader visible descriptor heap exhausted (type {0}), so bind groups will go stale this frame",
			(int)mHeapType);
	}
}

#endif // BF_PLATFORM_WINDOWS
