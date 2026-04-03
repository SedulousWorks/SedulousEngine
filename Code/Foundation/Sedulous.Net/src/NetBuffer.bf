namespace Sedulous.Net;

using System;
using System.Collections;

class NetBuffer
{
	private List<uint8> mData ~ delete _;
	private int mReadPos;
	private int mWritePos;

	public this(int initialCapacity = 256)
	{
		mData = new List<uint8>(initialCapacity);
		mReadPos = 0;
		mWritePos = 0;
	}

	public this(Span<uint8> data)
	{
		mData = new List<uint8>(data.Length);
		mData.AddRange(data);
		mReadPos = 0;
		mWritePos = data.Length;
	}

	public int Length => mWritePos;
	public int ReadPosition { get => mReadPos; set { mReadPos = value; } }
	public int WritePosition { get => mWritePos; set { mWritePos = value; } }
	public int ReadableBytes => mWritePos - mReadPos;
	public Span<uint8> Data => .(mData.Ptr, mWritePos);
	public uint8* Ptr => mData.Ptr;

	// ==================== Write ====================

	private void EnsureCapacity(int additionalBytes)
	{
		let needed = mWritePos + additionalBytes;
		while (mData.Count < needed)
			mData.Add(0);
	}

	public void WriteUInt8(uint8 val)
	{
		EnsureCapacity(1);
		mData[mWritePos++] = val;
	}

	public void WriteInt8(int8 val)
	{
		WriteUInt8((uint8)val);
	}

	public void WriteUInt16(uint16 val)
	{
		EnsureCapacity(2);
		// Big-endian (network byte order)
		mData[mWritePos++] = (uint8)(val >> 8);
		mData[mWritePos++] = (uint8)(val & 0xFF);
	}

	public void WriteInt16(int16 val)
	{
		WriteUInt16((uint16)val);
	}

	public void WriteUInt32(uint32 val)
	{
		EnsureCapacity(4);
		mData[mWritePos++] = (uint8)(val >> 24);
		mData[mWritePos++] = (uint8)((val >> 16) & 0xFF);
		mData[mWritePos++] = (uint8)((val >> 8) & 0xFF);
		mData[mWritePos++] = (uint8)(val & 0xFF);
	}

	public void WriteInt32(int32 val)
	{
		WriteUInt32((uint32)val);
	}

	public void WriteUInt64(uint64 val)
	{
		EnsureCapacity(8);
		mData[mWritePos++] = (uint8)(val >> 56);
		mData[mWritePos++] = (uint8)((val >> 48) & 0xFF);
		mData[mWritePos++] = (uint8)((val >> 40) & 0xFF);
		mData[mWritePos++] = (uint8)((val >> 32) & 0xFF);
		mData[mWritePos++] = (uint8)((val >> 24) & 0xFF);
		mData[mWritePos++] = (uint8)((val >> 16) & 0xFF);
		mData[mWritePos++] = (uint8)((val >> 8) & 0xFF);
		mData[mWritePos++] = (uint8)(val & 0xFF);
	}

	public void WriteInt64(int64 val)
	{
		WriteUInt64((uint64)val);
	}

	public void WriteFloat(float val)
	{
		var v = val;
		WriteUInt32(*(uint32*)&v);
	}

	public void WriteDouble(double val)
	{
		var v = val;
		WriteUInt64(*(uint64*)&v);
	}

	public void WriteBytes(Span<uint8> data)
	{
		EnsureCapacity(data.Length);
		Internal.MemCpy(mData.Ptr + mWritePos, data.Ptr, data.Length);
		mWritePos += data.Length;
	}

	/// Write length-prefixed string (uint16 length + UTF8 bytes)
	public void WriteString(StringView str)
	{
		WriteUInt16((uint16)str.Length);
		WriteBytes(Span<uint8>((uint8*)str.Ptr, str.Length));
	}

	/// Write raw string bytes without length prefix
	public void WriteRawString(StringView str)
	{
		WriteBytes(Span<uint8>((uint8*)str.Ptr, str.Length));
	}

	// ==================== Read ====================

	public Result<uint8, NetError> ReadUInt8()
	{
		if (mReadPos + 1 > mWritePos)
			return .Err(.BufferUnderflow);
		return .Ok(mData[mReadPos++]);
	}

	public Result<int8, NetError> ReadInt8()
	{
		if (ReadUInt8() case .Ok(let val))
			return .Ok((int8)val);
		return .Err(.BufferUnderflow);
	}

	public Result<uint16, NetError> ReadUInt16()
	{
		if (mReadPos + 2 > mWritePos)
			return .Err(.BufferUnderflow);
		uint16 val = ((uint16)mData[mReadPos] << 8) | mData[mReadPos + 1];
		mReadPos += 2;
		return .Ok(val);
	}

	public Result<int16, NetError> ReadInt16()
	{
		if (ReadUInt16() case .Ok(let val))
			return .Ok((int16)val);
		return .Err(.BufferUnderflow);
	}

	public Result<uint32, NetError> ReadUInt32()
	{
		if (mReadPos + 4 > mWritePos)
			return .Err(.BufferUnderflow);
		uint32 val = ((uint32)mData[mReadPos] << 24) | ((uint32)mData[mReadPos + 1] << 16) |
			((uint32)mData[mReadPos + 2] << 8) | mData[mReadPos + 3];
		mReadPos += 4;
		return .Ok(val);
	}

	public Result<int32, NetError> ReadInt32()
	{
		if (ReadUInt32() case .Ok(let val))
			return .Ok((int32)val);
		return .Err(.BufferUnderflow);
	}

	public Result<uint64, NetError> ReadUInt64()
	{
		if (mReadPos + 8 > mWritePos)
			return .Err(.BufferUnderflow);
		uint64 val = ((uint64)mData[mReadPos] << 56) | ((uint64)mData[mReadPos + 1] << 48) |
			((uint64)mData[mReadPos + 2] << 40) | ((uint64)mData[mReadPos + 3] << 32) |
			((uint64)mData[mReadPos + 4] << 24) | ((uint64)mData[mReadPos + 5] << 16) |
			((uint64)mData[mReadPos + 6] << 8) | mData[mReadPos + 7];
		mReadPos += 8;
		return .Ok(val);
	}

	public Result<int64, NetError> ReadInt64()
	{
		if (ReadUInt64() case .Ok(let val))
			return .Ok((int64)val);
		return .Err(.BufferUnderflow);
	}

	public Result<float, NetError> ReadFloat()
	{
		if (ReadUInt32() case .Ok(let val))
		{
			var v = val;
			return .Ok(*(float*)&v);
		}
		return .Err(.BufferUnderflow);
	}

	public Result<double, NetError> ReadDouble()
	{
		if (ReadUInt64() case .Ok(let val))
		{
			var v = val;
			return .Ok(*(double*)&v);
		}
		return .Err(.BufferUnderflow);
	}

	public Result<int, NetError> ReadBytes(Span<uint8> dest, int count)
	{
		if (mReadPos + count > mWritePos)
			return .Err(.BufferUnderflow);
		let toCopy = Math.Min(count, dest.Length);
		Internal.MemCpy(dest.Ptr, mData.Ptr + mReadPos, toCopy);
		mReadPos += count;
		return .Ok(toCopy);
	}

	/// Read length-prefixed string (uint16 length + UTF8 bytes)
	public Result<void, NetError> ReadString(String outStr)
	{
		let length = Try!(ReadUInt16());
		if (mReadPos + length > mWritePos)
			return .Err(.BufferUnderflow);
		outStr.Append((char8*)(mData.Ptr + mReadPos), length);
		mReadPos += length;
		return .Ok;
	}

	/// Read raw string of specified length
	public Result<void, NetError> ReadRawString(String outStr, int length)
	{
		if (mReadPos + length > mWritePos)
			return .Err(.BufferUnderflow);
		outStr.Append((char8*)(mData.Ptr + mReadPos), length);
		mReadPos += length;
		return .Ok;
	}

	// ==================== Utility ====================

	public void Clear()
	{
		mReadPos = 0;
		mWritePos = 0;
	}

	/// Shift unread data to the beginning, discarding already-read bytes
	public void Compact()
	{
		if (mReadPos == 0) return;
		let remaining = ReadableBytes;
		if (remaining > 0)
			Internal.MemMove(mData.Ptr, mData.Ptr + mReadPos, remaining);
		mWritePos = remaining;
		mReadPos = 0;
	}
}
