using System;
using System.Collections;

namespace Sedulous.Core.Memory;

/// Resettable bump allocator based on corlib's System.BumpAllocator.
/// Pool memory is retained across Reset() calls — ideal for per-frame scratch
/// allocations (render data extraction, particle simulation, broadphase temps).
///
/// Differences from System.BumpAllocator:
///   1. Tracks a current pool index, so on overflow the allocator advances to
///      the next existing pool before growing a new one.
///   2. Reset() runs destructors on tracked objects, frees large allocations,
///      and rewinds to pool 0 without freeing retained pool memory.
///
/// Usage:
///   let alloc = new FrameAllocator() ~ delete _;
///   let data = new:alloc MyRenderData();
///   // ... use data ...
///   alloc.Reset(); // pool memory retained, pointers into it are now invalid
class FrameAllocator : ITypedAllocator
{
	struct DtorEntry
	{
		public uint16 mPoolIdx;
		public uint16 mPoolOfs;
	}

	struct DtorEntryEx
	{
		public uint32 mPoolIdx;
		public uint32 mPoolOfs;
	}

	public enum DestructorHandlingKind
	{
		Allow,
		Fail,
		Ignore,
	}

	List<Span<uint8>> mPools;
	List<DtorEntry> mDtorEntries;
	List<DtorEntryEx> mDtorEntriesEx;
	List<void*> mLargeRawAllocs;
	List<Object> mLargeDtorAllocs;
	int mPoolsSize;
	int mLargeAllocs;
	public DestructorHandlingKind DestructorHandling = .Allow;

	/// Index of the pool currently being filled. -1 means "no pool active" —
	/// the next allocation triggers AdvanceOrGrowPool to pick up pool 0.
	int mCurrentPoolIdx = -1;

	uint8* mCurAlloc;
	uint8* mCurPtr;
	uint8* mCurEnd;

	public int PoolSizeMin = 4 * 1024;
	public int PoolSizeMax = 64 * 1024;

#if BF_ENABLE_REALTIME_LEAK_CHECK
	// We will either contain only data that needs to be marked or not, based on the first
	//  data allocated. The paired allocator will contain the other type of data.
	bool mMarkData;
	FrameAllocator mPairedAllocator ~ delete _;
#endif

	public this(DestructorHandlingKind destructorHandling = .Allow)
	{
		DestructorHandling = destructorHandling;
		mCurAlloc = null;
		mCurPtr = null;
		mCurEnd = null;
	}

	public ~this()
	{
		if (mDtorEntries != null)
		{
			for (var dtorEntry in ref mDtorEntries)
			{
				uint8* ptr = mPools[dtorEntry.mPoolIdx].Ptr + dtorEntry.mPoolOfs;
				Object obj = Internal.UnsafeCastToObject(ptr);
				delete:null obj;
			}
			delete mDtorEntries;
		}

		if (mDtorEntriesEx != null)
		{
			for (var dtorEntry in ref mDtorEntriesEx)
			{
				uint8* ptr = mPools[(int)dtorEntry.mPoolIdx].Ptr + dtorEntry.mPoolOfs;
				Object obj = Internal.UnsafeCastToObject(ptr);
				delete:null obj;
			}
			delete mDtorEntriesEx;
		}

		if (mPools != null)
		{
			for (var span in mPools)
				FreePool(span);
			delete mPools;
		}

		if (mLargeDtorAllocs != null)
		{
			for (var obj in mLargeDtorAllocs)
			{
				delete:null obj;
				FreeLarge(Internal.UnsafeCastToPtr(obj));
			}
			delete mLargeDtorAllocs;
		}

		if (mLargeRawAllocs != null)
		{
			for (var ptr in mLargeRawAllocs)
				FreeLarge(ptr);
			delete mLargeRawAllocs;
		}
	}

	protected virtual void* AllocLarge(int size, int align)
	{
		return new uint8[size]* (?);
	}

	protected virtual void FreeLarge(void* ptr)
	{
		delete ptr;
	}

	protected virtual Span<uint8> AllocPool()
	{
		int poolSize = (mPools != null) ? mPools.Count : 0;
		int allocSize = Math.Clamp((int)Math.Pow(poolSize, 1.5) * PoolSizeMin, PoolSizeMin, PoolSizeMax);
		return Span<uint8>(new uint8[allocSize]* (?), allocSize);
	}

	protected virtual void FreePool(Span<uint8> span)
	{
		delete span.Ptr;
	}

	protected void GrowPool()
	{
		var span = AllocPool();
		mPoolsSize += span.Length;
		if (mPools == null)
			mPools = new List<Span<uint8>>();
		mPools.Add(span);
		mCurAlloc = span.Ptr;
		mCurPtr = mCurAlloc;
		mCurEnd = mCurAlloc + span.Length;
	}

	/// Advances to the next existing pool if one exists, otherwise grows a new one.
	/// This is the key difference from System.BumpAllocator: after Reset() we can
	/// reuse the pools we already paid for without re-allocating.
	protected void AdvanceOrGrowPool()
	{
		mCurrentPoolIdx++;
		if (mPools != null && mCurrentPoolIdx < mPools.Count)
		{
			let pool = mPools[mCurrentPoolIdx];
			mCurAlloc = pool.Ptr;
			mCurPtr = pool.Ptr;
			mCurEnd = pool.Ptr + pool.Length;
		}
		else
		{
			GrowPool();
			// GrowPool appends to mPools — the current pool is now the last one.
			mCurrentPoolIdx = mPools.Count - 1;
		}
	}

	public void* Alloc(int size, int align)
	{
		mCurPtr = (uint8*)(void*)(((int)(void*)mCurPtr + align - 1) & ~(align - 1));

		while (mCurPtr + size >= mCurEnd)
		{
			if ((size > (mCurEnd - mCurAlloc) / 2) && (mCurAlloc != null))
			{
				mLargeAllocs += size;
				void* largeAlloc = AllocLarge(size, align);
				if (mLargeRawAllocs == null)
					mLargeRawAllocs = new List<void*>();
				mLargeRawAllocs.Add(largeAlloc);
				return largeAlloc;
			}

			AdvanceOrGrowPool();
			mCurPtr = (uint8*)(void*)(((int)(void*)mCurPtr + align - 1) & ~(align - 1));
		}

		uint8* ptr = mCurPtr;
		mCurPtr += size;
		return ptr;
	}

	protected void* AllocWithDtor(int size, int align)
	{
		mCurPtr = (uint8*)(void*)(((int)(void*)mCurPtr + align - 1) & ~(align - 1));

		while (mCurPtr + size >= mCurEnd)
		{
			if ((size > (mCurEnd - mCurAlloc) / 2) && (mCurAlloc != null))
			{
				mLargeAllocs += size;
				void* largeAlloc = AllocLarge(size, align);
				if (mLargeDtorAllocs == null)
					mLargeDtorAllocs = new List<Object>();
				mLargeDtorAllocs.Add(Internal.UnsafeCastToObject(largeAlloc));
				return largeAlloc;
			}

			AdvanceOrGrowPool();
			mCurPtr = (uint8*)(void*)(((int)(void*)mCurPtr + align - 1) & ~(align - 1));
		}

		uint32 poolOfs = (.)(mCurPtr - mCurAlloc);

		if (poolOfs <= 0xFFFF)
		{
			DtorEntry dtorEntry;
			dtorEntry.mPoolIdx = (uint16)mCurrentPoolIdx;
			dtorEntry.mPoolOfs = (uint16)(mCurPtr - mCurAlloc);
			if (mDtorEntries == null)
				mDtorEntries = new List<DtorEntry>();
			mDtorEntries.Add(dtorEntry);
		}
		else
		{
			DtorEntryEx dtorEntry;
			dtorEntry.mPoolIdx = (uint32)mCurrentPoolIdx;
			dtorEntry.mPoolOfs = (uint32)(mCurPtr - mCurAlloc);
			if (mDtorEntriesEx == null)
				mDtorEntriesEx = new List<DtorEntryEx>();
			mDtorEntriesEx.Add(dtorEntry);
		}

		uint8* ptr = mCurPtr;
		mCurPtr += size;
		return ptr;
	}

#if BF_ENABLE_REALTIME_LEAK_CHECK
	public void* AllocTyped(Type type, int size, int align)
	{
		bool markData = type.WantsMark;
		if (mPools == null)
		{
			mMarkData = markData;
		}
		else
		{
			if (mMarkData != markData)
			{
				if (mPairedAllocator == null)
				{
					mPairedAllocator = new FrameAllocator();
					mPairedAllocator.mMarkData = markData;
				}
				return mPairedAllocator.Alloc(size, align);
			}
		}

		if ((DestructorHandling != .Ignore) && (type.HasDestructor))
		{
			if (DestructorHandling == .Fail)
				Runtime.FatalError("Destructor not allowed");
			return AllocWithDtor(size, align);
		}

		return Alloc(size, align);
	}

	[DisableObjectAccessChecks]
	protected override void GCMarkMembers()
	{
		GC.Mark(mPools);
		GC.Mark(mLargeRawAllocs);
		GC.Mark(mLargeDtorAllocs);
		GC.Mark(mPairedAllocator);
		GC.Mark(mDtorEntries);
		GC.Mark(mDtorEntriesEx);
		if ((mMarkData) && (mPools != null))
		{
			let arr = mPools.[Friend]mItems;
			let size = mPools.[Friend]mSize;
			if (arr != null)
			{
				for (int idx < size)
				{
					var pool = arr[idx];
					GC.Mark(pool.Ptr, pool.Length);
				}
			}
		}
	}
#else
	public void* AllocTyped(Type type, int size, int align)
	{
		if ((DestructorHandling != .Ignore) && (type.HasDestructor))
		{
			if (DestructorHandling == .Fail)
				Runtime.FatalError("Destructor not allowed");
			return AllocWithDtor(size, align);
		}

		return Alloc(size, align);
	}
#endif

	[SkipCall]
	public void Free(void* ptr)
	{
		// Does nothing
	}

	/// Rewinds all pools, running destructors on tracked objects and freeing
	/// any large (pool-overflow) allocations. Retained pool memory is kept —
	/// subsequent allocations flow through pool 0 again.
	///
	/// All pointers returned from this allocator before Reset() become invalid.
	public void Reset()
	{
		// Run destructors on tracked in-pool objects.
		if (mDtorEntries != null)
		{
			for (var dtorEntry in ref mDtorEntries)
			{
				uint8* ptr = mPools[dtorEntry.mPoolIdx].Ptr + dtorEntry.mPoolOfs;
				Object obj = Internal.UnsafeCastToObject(ptr);
				delete:null obj;
			}
			mDtorEntries.Clear();
		}

		if (mDtorEntriesEx != null)
		{
			for (var dtorEntry in ref mDtorEntriesEx)
			{
				uint8* ptr = mPools[(int)dtorEntry.mPoolIdx].Ptr + dtorEntry.mPoolOfs;
				Object obj = Internal.UnsafeCastToObject(ptr);
				delete:null obj;
			}
			mDtorEntriesEx.Clear();
		}

		// Free large allocations — these are not part of retained pool memory.
		if (mLargeDtorAllocs != null)
		{
			for (var obj in mLargeDtorAllocs)
			{
				delete:null obj;
				FreeLarge(Internal.UnsafeCastToPtr(obj));
			}
			mLargeDtorAllocs.Clear();
		}

		if (mLargeRawAllocs != null)
		{
			for (var ptr in mLargeRawAllocs)
				FreeLarge(ptr);
			mLargeRawAllocs.Clear();
		}

		mLargeAllocs = 0;

		// Rewind to before pool 0. The next Alloc will trigger AdvanceOrGrowPool,
		// which picks up pool 0 (if any) or grows a fresh one.
		mCurrentPoolIdx = -1;
		mCurAlloc = null;
		mCurPtr = null;
		mCurEnd = null;

#if BF_ENABLE_REALTIME_LEAK_CHECK
		if (mPairedAllocator != null)
			mPairedAllocator.Reset();
#endif
	}

	/// Total bytes across all retained pool memory (does not count large allocs).
	public int GetTotalAllocSize()
	{
		return mPoolsSize;
	}

	/// Bytes currently used in the active pool (rough — does not sum prior filled pools).
	public int GetAllocSize()
	{
		return mPoolsSize - (mCurEnd - mCurPtr);
	}
}
