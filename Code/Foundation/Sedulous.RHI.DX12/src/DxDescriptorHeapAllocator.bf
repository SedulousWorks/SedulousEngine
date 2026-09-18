using System;
using System.Collections;
using Sedulous.RHI;
using Win32;
using Win32.Graphics.Direct3D12;

namespace Sedulous.RHI.DX12;

/// A fixed CPU descriptor heap with a free list over it.
///
/// D3D12 descriptors live in heaps the application sizes up front, so this hands out slots
/// from one and takes them back. The search RESUMES where the last allocation landed rather
/// than restarting, which keeps a heap that is mostly full from costing a full scan per
/// allocation.
///
/// The heap is a COM object owned here and released in Destroy.
class DxDescriptorHeapAllocator
{
	private ID3D12DescriptorHeap* mHeap = null; // owned, released in Destroy
	private D3D12_CPU_DESCRIPTOR_HANDLE mHeapStart = .();
	private uint32 mDescriptorSize = 0;
	private uint32 mMaxCount = 0;
	private uint32 mAllocCount = 0;
	private uint32 mSearchStart = 0;
	private List<uint8> mAlive = new .() ~ delete _;

	public ID3D12DescriptorHeap* Heap => mHeap;
	public uint32 DescriptorSize => mDescriptorSize;

	public Result<void> Initialize(ID3D12Device* device, D3D12_DESCRIPTOR_HEAP_TYPE type,
		uint32 maxCount,
		D3D12_DESCRIPTOR_HEAP_FLAGS flags = .D3D12_DESCRIPTOR_HEAP_FLAG_NONE)
	{
		mMaxCount = maxCount;
		mAlive.Clear();
		mAlive.Resize((int)maxCount, 0);

		D3D12_DESCRIPTOR_HEAP_DESC hd = .();
		hd.Type = type;
		hd.NumDescriptors = maxCount;
		hd.Flags = flags;

		if (FAILED(device.CreateDescriptorHeap(&hd, ID3D12DescriptorHeap.IID, (void**)&mHeap)))
			return .Err;

		mHeapStart = mHeap.GetCPUDescriptorHandleForHeapStart();
		mDescriptorSize = device.GetDescriptorHandleIncrementSize(type);
		return .Ok;
	}

	/// A free slot, or a zero handle when the heap is full.
	public D3D12_CPU_DESCRIPTOR_HANDLE Allocate()
	{
		for (uint32 i = 0; i < mMaxCount; i++)
		{
			let idx = (mSearchStart + i) % mMaxCount;
			if (mAlive[(int)idx] == 0)
			{
				mAlive[(int)idx] = 1;
				mAllocCount++;
				mSearchStart = (idx + 1) % mMaxCount;

				D3D12_CPU_DESCRIPTOR_HANDLE h = .();
				h.ptr = mHeapStart.ptr + (uint)idx * (uint)mDescriptorSize;
				return h;
			}
		}

		return .(); // heap full
	}

	public void Free(D3D12_CPU_DESCRIPTOR_HANDLE handle)
	{
		if (handle.ptr < mHeapStart.ptr)
			return;

		let offset = (uint32)((handle.ptr - mHeapStart.ptr) / (uint)mDescriptorSize);
		if ((offset < mMaxCount) && (mAlive[(int)offset] != 0))
		{
			mAlive[(int)offset] = 0;
			mAllocCount--;
		}
	}

	public void Destroy()
	{
		if (mHeap != null)
		{
			mHeap.Release();
			mHeap = null;
		}
		mAlive.Clear();
	}
}
