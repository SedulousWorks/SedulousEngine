namespace Sedulous.Net;

using System;
using System.Collections;

/// Static utility for writing big-endian values into byte collections.
static class NetWriter
{
	public static void WriteUInt8(List<uint8> dest, uint8 val)
	{
		dest.Add(val);
	}

	public static void WriteUInt16(List<uint8> dest, uint16 val)
	{
		dest.Add((uint8)(val >> 8));
		dest.Add((uint8)(val & 0xFF));
	}

	public static void WriteUInt32(List<uint8> dest, uint32 val)
	{
		dest.Add((uint8)(val >> 24));
		dest.Add((uint8)((val >> 16) & 0xFF));
		dest.Add((uint8)((val >> 8) & 0xFF));
		dest.Add((uint8)(val & 0xFF));
	}

	public static void WriteUInt64(List<uint8> dest, uint64 val)
	{
		dest.Add((uint8)(val >> 56));
		dest.Add((uint8)((val >> 48) & 0xFF));
		dest.Add((uint8)((val >> 40) & 0xFF));
		dest.Add((uint8)((val >> 32) & 0xFF));
		dest.Add((uint8)((val >> 24) & 0xFF));
		dest.Add((uint8)((val >> 16) & 0xFF));
		dest.Add((uint8)((val >> 8) & 0xFF));
		dest.Add((uint8)(val & 0xFF));
	}

	public static void WriteInt16(List<uint8> dest, int16 val)
	{
		WriteUInt16(dest, (uint16)val);
	}

	public static void WriteInt32(List<uint8> dest, int32 val)
	{
		WriteUInt32(dest, (uint32)val);
	}

	public static void WriteInt64(List<uint8> dest, int64 val)
	{
		WriteUInt64(dest, (uint64)val);
	}

	/// Write uint16 at a specific offset in an existing buffer
	public static void WriteUInt16At(Span<uint8> dest, int offset, uint16 val)
	{
		dest[offset] = (uint8)(val >> 8);
		dest[offset + 1] = (uint8)(val & 0xFF);
	}

	/// Write uint32 at a specific offset in an existing buffer
	public static void WriteUInt32At(Span<uint8> dest, int offset, uint32 val)
	{
		dest[offset] = (uint8)(val >> 24);
		dest[offset + 1] = (uint8)((val >> 16) & 0xFF);
		dest[offset + 2] = (uint8)((val >> 8) & 0xFF);
		dest[offset + 3] = (uint8)(val & 0xFF);
	}

	/// Write uint64 at a specific offset in an existing buffer
	public static void WriteUInt64At(Span<uint8> dest, int offset, uint64 val)
	{
		dest[offset] = (uint8)(val >> 56);
		dest[offset + 1] = (uint8)((val >> 48) & 0xFF);
		dest[offset + 2] = (uint8)((val >> 40) & 0xFF);
		dest[offset + 3] = (uint8)((val >> 32) & 0xFF);
		dest[offset + 4] = (uint8)((val >> 24) & 0xFF);
		dest[offset + 5] = (uint8)((val >> 16) & 0xFF);
		dest[offset + 6] = (uint8)((val >> 8) & 0xFF);
		dest[offset + 7] = (uint8)(val & 0xFF);
	}
}
