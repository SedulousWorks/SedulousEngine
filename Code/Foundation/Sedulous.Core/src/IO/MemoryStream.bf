using System;
using System.Collections;

namespace Sedulous.Core.IO;

/// An IStream over a growable in-memory buffer.
///
/// The buffer is owned. Bytes hands out a view of it, valid until the next write.
class MemoryStream : IStream
{
	private List<uint8> mData = new .() ~ delete _;
	private int64 mPosition;

	public override bool IsValid => true;

	/// The bytes written so far, whatever the current position is.
	public Span<uint8> Bytes => .(mData.Ptr, mData.Count);

	public override int Read(Span<uint8> destination)
	{
		let available = mData.Count - (int)mPosition;
		var toRead = destination.Length;
		if (toRead > available)
			toRead = available;

		if (toRead > 0)
		{
			Internal.MemCpy(destination.Ptr, mData.Ptr + mPosition, toRead);
			mPosition += toRead;
		}
		return toRead;
	}

	public override int Write(Span<uint8> source)
	{
		let bytes = source.Length;
		if (bytes == 0)
			return 0;

		let end = (int)mPosition + bytes;
		if (end > mData.Count)
		{
			// Grow the capacity geometrically, so a run of small writes stays amortised
			// constant. Reserve allocates exactly what it is asked for, so resizing to the
			// exact end on every write would make a byte at a time serialization of a large
			// blob quadratic.
			if (end > mData.Capacity)
			{
				var capacity = (mData.Capacity == 0) ? 64 : mData.Capacity;
				while (capacity < end)
					capacity *= 2;
				mData.Reserve(capacity);
			}
			mData.Resize(end);
		}

		Internal.MemCpy(mData.Ptr + mPosition, source.Ptr, bytes);
		mPosition += bytes;
		return bytes;
	}

	public override int64 Seek(int64 offset, SeekOrigin origin)
	{
		int64 origin_;
		switch (origin)
		{
		case .Begin: origin_ = 0;
		case .Current: origin_ = mPosition;
		case .End: origin_ = mData.Count;
		}

		let target = origin_ + offset;
		if ((target < 0) || (target > mData.Count))
			return -1;

		mPosition = target;
		return target;
	}

	public override int64 Tell() => mPosition;
	public override int64 Size() => mData.Count;

	public void Clear()
	{
		mData.Clear();
		mPosition = 0;
	}
}
