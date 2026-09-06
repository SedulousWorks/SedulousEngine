using System;
using System.Collections;

namespace Sedulous.Geometry;

/// A format tagged index buffer, 16 or 32 bit, held as raw bytes so it uploads to a GPU
/// index buffer verbatim.
///
/// The write cursor is what lets the primitive builders and importers stream indices in:
/// size it once with Resize, then Add or AddTriangle without tracking a position.
class IndexBuffer
{
	public enum Format : uint8
	{
		case U16;
		case U32;
	}

	private List<uint8> mData = new .() ~ delete _;
	private uint32 mCount;
	private uint32 mWritePos;
	private Format mFormat;

	public this(Format format = .U32)
	{
		mFormat = format;
	}

	public Format IndexFormat => mFormat;
	public uint32 IndexSize => (mFormat == .U16) ? 2 : 4;
	public uint32 Count => mCount;
	public uint32 DataSize => mCount * IndexSize;

	/// The raw bytes, or null when empty. Null rather than a dangling empty pointer,
	/// because the caller hands this straight to an upload.
	public uint8* RawData => (mCount > 0) ? mData.Ptr : null;

	public void Reserve(uint32 count)
	{
		let needed = (int)(count * IndexSize);
		if (mData.Count < needed)
			mData.Resize(needed);
	}

	/// Sets the logical count, growing storage, and rewinds the append cursor.
	public void Resize(uint32 count)
	{
		mCount = count;
		Reserve(count);
		mWritePos = 0;
	}

	public void Clear()
	{
		mCount = 0;
		mWritePos = 0;
	}

	/// Out of range writes are dropped rather than trapping: a malformed mesh should
	/// render wrong, not take the process down.
	public void Set(uint32 index, uint32 value)
	{
		if (index >= mCount)
			return;

		let offset = (int)(index * IndexSize);
		if (mFormat == .U16)
		{
			var narrow = (uint16)value;
			Internal.MemCpy(mData.Ptr + offset, &narrow, 2);
		}
		else
		{
			var wide = value;
			Internal.MemCpy(mData.Ptr + offset, &wide, 4);
		}
	}

	public uint32 Get(uint32 index)
	{
		if (index >= mCount)
			return 0;

		let offset = (int)(index * IndexSize);
		if (mFormat == .U16)
		{
			uint16 narrow = 0;
			Internal.MemCpy(&narrow, mData.Ptr + offset, 2);
			return narrow;
		}

		uint32 wide = 0;
		Internal.MemCpy(&wide, mData.Ptr + offset, 4);
		return wide;
	}

	/// Appends through the internal cursor. Resize first: this writes into the space the
	/// count already covers and does nothing once it is full.
	public void Add(uint32 value)
	{
		if (mWritePos >= mCount)
			return;

		Set(mWritePos, value);
		mWritePos++;
	}

	public void AddTriangle(uint32 a, uint32 b, uint32 c)
	{
		Add(a);
		Add(b);
		Add(c);
	}
}
