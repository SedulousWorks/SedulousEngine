#if BF_PLATFORM_WINDOWS
using System;
using System.Collections;
using Sedulous.RHI;
using Win32;
using Win32.Graphics.Direct3D12;

namespace Sedulous.RHI.DX12;

/// CPU descriptors in pages, with a free list over each.
///
/// D3D12 descriptors live in heaps the application sizes up front. When every page is full another
/// of the same size is made, so an allocation never fails while the device can make heaps: a fixed
/// heap handed out a zero handle when full, and the view written through it took the process down.
/// A zero handle comes back only when a new page cannot be made, and callers check for it. The
/// search RESUMES where the last allocation landed rather than restarting, which keeps a page that
/// is mostly full from costing a full scan per allocation.
///
/// The pages' heaps are COM objects owned here and released in Destroy.
class DxDescriptorHeapAllocator
{
	private class Page
	{
		public ID3D12DescriptorHeap* Heap = null; // owned, released in Destroy
		public D3D12_CPU_DESCRIPTOR_HANDLE Start = .();
		public List<uint8> Alive = new .() ~ delete _;
		public uint32 Count = 0;
		public uint32 SearchStart = 0;
	}

	private ID3D12Device* mDevice = null; // borrowed: the device outlives its heaps
	private D3D12_DESCRIPTOR_HEAP_TYPE mType = .D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV;
	private D3D12_DESCRIPTOR_HEAP_FLAGS mFlags = .D3D12_DESCRIPTOR_HEAP_FLAG_NONE;
	private uint32 mPageSize = 0;
	private uint32 mDescriptorSize = 0;
	private int mCurrentPage = 0;
	private List<Page> mPages = new .() ~ DeleteContainerAndItems!(_);

	public uint32 DescriptorSize => mDescriptorSize;
	public int PageCount => mPages.Count;

	public Result<void> Initialize(ID3D12Device* device, D3D12_DESCRIPTOR_HEAP_TYPE type,
		uint32 maxCount,
		D3D12_DESCRIPTOR_HEAP_FLAGS flags = .D3D12_DESCRIPTOR_HEAP_FLAG_NONE)
	{
		mDevice = device;
		mType = type;
		mFlags = flags;
		mPageSize = maxCount;
		mDescriptorSize = device.GetDescriptorHandleIncrementSize(type);
		return AddPage() ? .Ok : .Err;
	}

	/// A free slot, a new page made when every page is full; a zero handle only when the device
	/// made no new heap.
	public D3D12_CPU_DESCRIPTOR_HANDLE Allocate()
	{
		for (int p < mPages.Count)
		{
			let pageIndex = (mCurrentPage + p) % mPages.Count;
			let page = mPages[pageIndex];
			if (page.Count == mPageSize)
				continue;
			for (uint32 i = 0; i < mPageSize; i++)
			{
				let idx = (page.SearchStart + i) % mPageSize;
				if (page.Alive[(int)idx] == 0)
				{
					page.Alive[(int)idx] = 1;
					page.Count++;
					page.SearchStart = (idx + 1) % mPageSize;
					mCurrentPage = pageIndex;

					D3D12_CPU_DESCRIPTOR_HANDLE h = .();
					h.ptr = page.Start.ptr + (uint)idx * (uint)mDescriptorSize;
					return h;
				}
			}
		}

		if (!AddPage())
			return .(); // the device made no new heap: the caller reports it
		mCurrentPage = mPages.Count - 1;
		return Allocate();
	}

	public void Free(D3D12_CPU_DESCRIPTOR_HANDLE handle)
	{
		for (let page in mPages)
		{
			if (handle.ptr < page.Start.ptr)
				continue;
			let offset = (handle.ptr - page.Start.ptr) / (uint)mDescriptorSize;
			if (offset >= (uint)mPageSize)
				continue;
			if (page.Alive[(int)offset] != 0)
			{
				page.Alive[(int)offset] = 0;
				page.Count--;
			}
			return;
		}
	}

	public void Destroy()
	{
		for (let page in mPages)
		{
			if (page.Heap != null)
				page.Heap.Release();
			delete page;
		}
		mPages.Clear();
	}

	private bool AddPage()
	{
		if ((mDevice == null) || (mPageSize == 0))
			return false;
		D3D12_DESCRIPTOR_HEAP_DESC hd = .();
		hd.Type = mType;
		hd.NumDescriptors = mPageSize;
		hd.Flags = mFlags;
		ID3D12DescriptorHeap* heap = null;
		if (FAILED(mDevice.CreateDescriptorHeap(&hd, ID3D12DescriptorHeap.IID, (void**)&heap)))
			return false;
		let page = new Page();
		page.Heap = heap;
		page.Start = heap.GetCPUDescriptorHandleForHeapStart();
		page.Alive.Resize((int)mPageSize, 0);
		mPages.Add(page);
		return true;
	}
}

#endif // BF_PLATFORM_WINDOWS
