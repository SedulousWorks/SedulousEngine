namespace Sedulous.RHI.DX12;

using System;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;

/// Simple CPU-side descriptor heap allocator with free-list.
class DX12DescriptorHeapAllocator
{
	private ID3D12DescriptorHeap* mHeap;
	private D3D12_DESCRIPTOR_HEAP_TYPE mType;
	private D3D12_CPU_DESCRIPTOR_HANDLE mHeapStart;
	private uint32 mDescriptorSize;
	private uint32 mMaxCount;
	private uint32 mAllocCount;
	private bool[] mAlive;
	private uint32 mSearchStart;

	public this(ID3D12Device* device, D3D12_DESCRIPTOR_HEAP_TYPE type, uint32 maxCount,
		D3D12_DESCRIPTOR_HEAP_FLAGS flags = .D3D12_DESCRIPTOR_HEAP_FLAG_NONE)
	{
		mType = type;
		mMaxCount = maxCount;
		mAlive = new bool[maxCount];

		D3D12_DESCRIPTOR_HEAP_DESC desc = .()
		{
			Type = type,
			NumDescriptors = maxCount,
			Flags = flags,
			NodeMask = 0
		};

		device.CreateDescriptorHeap(&desc, ID3D12DescriptorHeap.IID, (void**)&mHeap);
		mHeapStart = mHeap.GetCPUDescriptorHandleForHeapStart();
		mDescriptorSize = device.GetDescriptorHandleIncrementSize(type);
	}

	public D3D12_CPU_DESCRIPTOR_HANDLE Allocate()
	{
		for (uint32 i = 0; i < mMaxCount; i++)
		{
			let idx = (mSearchStart + i) % mMaxCount;
			if (!mAlive[(.)idx])
			{
				mAlive[(.)idx] = true;
				mAllocCount++;
				mSearchStart = (idx + 1) % mMaxCount;
				D3D12_CPU_DESCRIPTOR_HANDLE handle = default;
				handle.ptr = mHeapStart.ptr + idx * mDescriptorSize;
				return handle;
			}
		}
		return default; // Heap full
	}

	public void Free(D3D12_CPU_DESCRIPTOR_HANDLE handle)
	{
		if (handle.ptr < mHeapStart.ptr) return;
		uint32 offset = (uint32)(handle.ptr - mHeapStart.ptr) / mDescriptorSize;
		if (offset < mMaxCount && mAlive[(.)offset])
		{
			mAlive[(.)offset] = false;
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
		if (mAlive != null)
		{
			delete mAlive;
			mAlive = null;
		}
	}

	public ID3D12DescriptorHeap* Heap => mHeap;
	public uint32 DescriptorSize => mDescriptorSize;
}
