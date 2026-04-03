namespace Sedulous.Net;

using System;

/// Static utility for reading big-endian values from byte spans.
static class NetReader
{
	public static Result<uint8> ReadUInt8(Span<uint8> src, int offset)
	{
		if (offset + 1 > src.Length)
			return .Err;
		return .Ok(src[offset]);
	}

	public static Result<uint16> ReadUInt16(Span<uint8> src, int offset)
	{
		if (offset + 2 > src.Length)
			return .Err;
		return .Ok(((uint16)src[offset] << 8) | src[offset + 1]);
	}

	public static Result<uint32> ReadUInt32(Span<uint8> src, int offset)
	{
		if (offset + 4 > src.Length)
			return .Err;
		return .Ok(((uint32)src[offset] << 24) | ((uint32)src[offset + 1] << 16) |
			((uint32)src[offset + 2] << 8) | src[offset + 3]);
	}

	public static Result<uint64> ReadUInt64(Span<uint8> src, int offset)
	{
		if (offset + 8 > src.Length)
			return .Err;
		return .Ok(((uint64)src[offset] << 56) | ((uint64)src[offset + 1] << 48) |
			((uint64)src[offset + 2] << 40) | ((uint64)src[offset + 3] << 32) |
			((uint64)src[offset + 4] << 24) | ((uint64)src[offset + 5] << 16) |
			((uint64)src[offset + 6] << 8) | src[offset + 7]);
	}

	public static Result<int16> ReadInt16(Span<uint8> src, int offset)
	{
		if (ReadUInt16(src, offset) case .Ok(let val))
			return .Ok((int16)val);
		return .Err;
	}

	public static Result<int32> ReadInt32(Span<uint8> src, int offset)
	{
		if (ReadUInt32(src, offset) case .Ok(let val))
			return .Ok((int32)val);
		return .Err;
	}

	public static Result<int64> ReadInt64(Span<uint8> src, int offset)
	{
		if (ReadUInt64(src, offset) case .Ok(let val))
			return .Ok((int64)val);
		return .Err;
	}
}
