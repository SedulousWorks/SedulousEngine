using System;
using System.Collections;

namespace Sedulous.RHI;

struct FixedList<T, TCapacity> where TCapacity : const int
{
	private T[TCapacity] mData = .();

	private int mCurrentSize = 0;

	public T* Ptr mut => &mData;

	public int Count
	{
		get => mCurrentSize;
		set mut
		{
			Runtime.Assert(value <= TCapacity);
			mCurrentSize = value;
		}
	}

	public T this[int index]
	{
		get
		{
			Runtime.Assert(index < mCurrentSize);
			return mData[index];
		}
	}

	public ref T this[int index]
	{
		get mut { return ref mData[index]; }
		set mut
		{
			Runtime.Assert(index < mCurrentSize);
			mData[index] = value;
		}
	}

	public bool IsEmpty => mCurrentSize == 0;

	public ref T Back
	{
		get mut
		{
			Runtime.Assert(mCurrentSize > 0);
			return ref mData[mCurrentSize - 1];
		}
	}

	public this(T data)
	{
		Runtime.Assert(TCapacity > 0);
		mData[0] = data;
		mCurrentSize = 1;
	}

	public this(Span<T> data)
	{
		Runtime.Assert(data.Length <= TCapacity);

		for (int i = 0; i < data.Length; i++)
		{
			mData[i] = data[i];
		}
		mCurrentSize = data.Length;
	}

	/*
	public this(int length)
	{
		Runtime.Assert(length <= TCapacity);
		mCurrentSize = length;
	}
	*/

	public this()
	{
		mCurrentSize = 0;
	}

	public void Add(T item) mut
	{
		Runtime.Assert(mCurrentSize < TCapacity);
		mData[mCurrentSize++] = item;
	}

	public void AddRange(Span<T> items) mut
	{
		Runtime.Assert(mCurrentSize + items.Length <= TCapacity);

		for (int i = 0; i < items.Length; i++)
		{
			mData[mCurrentSize++] = items[i];
		}
	}

	public void SetRange(Span<T> items) mut
	{
		Runtime.Assert(items.Length <= TCapacity);

		Clear();

		AddRange(items);
	}

	public void Clear() mut
	{
		mData = .();
		mCurrentSize = 0;
	}

	public T PopBack() mut
	{
		Runtime.Assert(mCurrentSize > 0);
		return mData[mCurrentSize--];
	}

	public Enumerator GetEnumerator()
	{
		return .(this);
	}

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
			if ((uint(mIndex) < uint(mList.Count)))
			{
				mCurrent = &mList[mIndex];
				mIndex++;
				return true;
			}
			return MoveNextRare();
		}

		private bool MoveNextRare() mut
		{
			mIndex = mList.Count + 1;
			mCurrent = null;
			return false;
		}

		public int Count
		{
			get
			{
				return mList.Count;
			}
		}

		public T Current
		{
			get
			{
				return *mCurrent;
			}
		}

		public ref T CurrentRef
		{
			get
			{
				return ref *mCurrent;
			}
		}

		public int Index
		{
			get
			{
				return mIndex - 1;
			}
		}

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

extension FixedList<T, TCapacity>
	where TCapacity : const int
	where T : IEquatable<T>
{
	public bool Equals(Self other)
	{
		if (this.Count != other.Count)
			return false;

		for (int i = 0; i < this.Count; i++)
		{
			if (!this[i].Equals(other[i]))
				return false;
		}
		return true;
	}

	[Commutable]
	public static bool operator ==(Self lhs, Self rhs)
	{
		return lhs.Equals(rhs);
	}
}

extension FixedList<T, TCapacity>
	where TCapacity : const int
	where T : class
{
	public bool Equals(Self other)
	{
		if (this.Count != other.Count)
			return false;

		for (int i = 0; i < this.Count; i++)
		{
			if (!(this[i] == other[i]))
				return false;
		}
		return true;
	}

	[Commutable]
	public static bool operator ==(Self lhs, Self rhs)
	{
		return lhs.Equals(rhs);
	}
}

extension FixedList<T, TCapacity>
	where TCapacity : const int
	where T : IHashable
{
	public int GetHashCode()
	{
		int hash = 0;

		for (int i = 0; i < Count; i++)
		{
			hash = HashCode.Mix(hash, mData[i].GetHashCode());
		}

		return hash;
	}
}