using System;

namespace Sedulous.Geometry;

/// Index buffer for mesh indices
public class IndexBuffer
{
	public enum IndexFormat
	{
		UInt16,
		UInt32
	}

	private uint8[] mData ~ delete _;
	private int32 mIndexCount;
	private IndexFormat mFormat;

	public int32 IndexCount => mIndexCount;
	public IndexFormat Format => mFormat;

	public this(IndexFormat format)
	{
		mFormat = format;
		mIndexCount = 0;
	}

	public void Reserve(int32 count)
	{
		int32 size = GetIndexSize();
		int32 newSize = count * size;
		if (mData == null || mData.Count < newSize)
		{
			let newData = new uint8[newSize];
			if (mData != null)
			{
				Internal.MemCpy(&newData[0], &mData[0], mData.Count);
				delete mData;
			}
			mData = newData;
		}
	}

	public void Resize(int32 count)
	{
		mIndexCount = count;
		Reserve(count);
	}

	public int32 GetIndexSize()
	{
		switch (mFormat)
		{
		case .UInt16: return 2;
		case .UInt32: return 4;
		}
	}

	public void SetIndex(int32 index, uint32 value)
	{
		var value;
		if (index >= mIndexCount) return;

		int32 size = GetIndexSize();
		int32 offset = index * size;

		switch (mFormat)
		{
		case .UInt16:
			uint16 val = (uint16)value;
			Internal.MemCpy(&mData[offset], &val, 2);
		case .UInt32:
			Internal.MemCpy(&mData[offset], &value, 4);
		}
	}

	public uint32 GetIndex(int32 index)
	{
		if (index >= mIndexCount) return 0;

		int32 size = GetIndexSize();
		int32 offset = index * size;

		switch (mFormat)
		{
		case .UInt16:
			uint16 val = 0;
			Internal.MemCpy(&val, &mData[offset], 2);
			return (uint32)val;
		case .UInt32:
			uint32 val = 0;
			Internal.MemCpy(&val, &mData[offset], 4);
			return val;
		}
	}

	public uint8* GetRawData()
	{
		if (mData == null || mData.Count == 0)
			return null;
		return &mData[0];
	}

	public int32 GetDataSize() => mIndexCount * GetIndexSize();
}
