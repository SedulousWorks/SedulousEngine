using System;
using System.Collections;

namespace Sedulous.Core;

/// A fixed capacity list stored INLINE, with a live count.
///
/// For small collections with a known upper bound, render pass colour attachments being
/// the case it exists for. No heap allocation, and copyable as a value, which is what lets
/// a descriptor hold one and still be passed around freely.
///
/// The capacity is a const generic parameter, so `FixedList<ColorAttachment, const 8>` is
/// its own type and the bound is known at compile time. Overrunning it ASSERTS rather than
/// growing: the capacity is chosen as a bound that cannot legitimately be exceeded, so
/// exceeding it is a mistake to surface rather than absorb.
struct FixedList<T, TCapacity> where TCapacity : const int
{
	private T[TCapacity] mData = .();
	private int mCount = 0;

	public this()
	{
		mCount = 0;
	}

	/// A list of exactly one, for the common case of a single colour attachment.
	public this(T item)
	{
		Runtime.Assert(TCapacity > 0);
		mData[0] = item;
		mCount = 1;
	}

	public this(Span<T> items)
	{
		Runtime.Assert(items.Length <= TCapacity);
		for (int i < items.Length)
			mData[i] = items[i];
		mCount = items.Length;
	}

	/// The inline storage. Valid only while this list is, and a COPY of the list has its
	/// own, so a pointer taken from one does not follow the other.
	public T* Ptr mut => &mData;

	public int Count
	{
		get => mCount;
		set mut
		{
			Runtime.Assert(value <= TCapacity);
			mCount = value;
		}
	}

	public bool IsEmpty => mCount == 0;
	public static int Capacity => TCapacity;

	public T this[int index]
	{
		get
		{
			Runtime.Assert((index >= 0) && (index < mCount));
			return mData[index];
		}
	}

	public ref T this[int index]
	{
		get mut
		{
			Runtime.Assert((index >= 0) && (index < mCount));
			return ref mData[index];
		}
		set mut
		{
			Runtime.Assert((index >= 0) && (index < mCount));
			mData[index] = value;
		}
	}

	public ref T Back
	{
		get mut
		{
			Runtime.Assert(mCount > 0);
			return ref mData[mCount - 1];
		}
	}

	public void Add(T item) mut
	{
		Runtime.Assert(mCount < TCapacity);
		mData[mCount] = item;
		mCount++;
	}

	public void AddRange(Span<T> items) mut
	{
		Runtime.Assert((mCount + items.Length) <= TCapacity);
		for (int i < items.Length)
		{
			mData[mCount] = items[i];
			mCount++;
		}
	}

	/// Replaces the contents outright.
	public void SetRange(Span<T> items) mut
	{
		Runtime.Assert(items.Length <= TCapacity);
		Clear();
		AddRange(items);
	}

	/// Empties it AND zeroes the storage, so a cleared list holds no stale reference to
	/// something the caller went on to free.
	public void Clear() mut
	{
		mData = .();
		mCount = 0;
	}

	/// Removes and returns the last element.
	public T PopBack() mut
	{
		Runtime.Assert(mCount > 0);
		mCount--;
		return mData[mCount];
	}

	/// The live elements. Points at the inline storage, with the same lifetime caveat as
	/// Ptr.
	public Span<T> AsSpan() mut => .(&mData, mCount);

	public Enumerator GetEnumerator() => .(this);

	public struct Enumerator : IRefEnumerator<T*>, IEnumerator<T>, IResettable
	{
		private FixedList<T, TCapacity> mList;
		private int mIndex;
		private T* mCurrent;

		public this(FixedList<T, TCapacity> list)
		{
			mList = list;
			mIndex = 0;
			mCurrent = null;
		}

		public bool MoveNext() mut
		{
			if ((uint)mIndex < (uint)mList.Count)
			{
				mCurrent = &mList[mIndex];
				mIndex++;
				return true;
			}
			mIndex = mList.Count + 1;
			mCurrent = null;
			return false;
		}

		public int Count => mList.Count;
		public T Current => *mCurrent;
		public ref T CurrentRef => ref *mCurrent;
		public int Index => mIndex - 1;

		public void Reset() mut
		{
			mIndex = 0;
			mCurrent = null;
		}

		public Result<T> GetNext() mut
		{
			if (!MoveNext())
				return .Err;
			return Current;
		}

		public Result<T*> GetNextRef() mut
		{
			if (!MoveNext())
				return .Err;
			return &CurrentRef;
		}
	}
}

/// Equality for value elements, compared pairwise over the live range.
extension FixedList<T, TCapacity>
	where TCapacity : const int
	where T : IEquatable<T>
{
	public bool Equals(Self other)
	{
		if (this.Count != other.Count)
			return false;
		for (int i < this.Count)
		{
			if (!this[i].Equals(other[i]))
				return false;
		}
		return true;
	}

	[Commutable]
	public static bool operator==(Self lhs, Self rhs) => lhs.Equals(rhs);
}

/// Equality for reference elements, by IDENTITY: two lists are equal when they hold the
/// same objects, which is what a descriptor comparison wants.
extension FixedList<T, TCapacity>
	where TCapacity : const int
	where T : class
{
	public bool Equals(Self other)
	{
		if (this.Count != other.Count)
			return false;
		for (int i < this.Count)
		{
			if (this[i] !== other[i])
				return false;
		}
		return true;
	}

	[Commutable]
	public static bool operator==(Self lhs, Self rhs) => lhs.Equals(rhs);
}

extension FixedList<T, TCapacity>
	where TCapacity : const int
	where T : IHashable
{
	public int GetHashCode()
	{
		int hash = 0;
		for (int i < Count)
			hash = HashCode.Mix(hash, mData[i].GetHashCode());
		return hash;
	}
}
