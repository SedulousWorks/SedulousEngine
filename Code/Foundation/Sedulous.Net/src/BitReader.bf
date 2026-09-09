using System;
using System.Diagnostics;
using Sedulous.Core;

namespace Sedulous.Net;

/// Reads back what BitWriter wrote.
///
/// A read past the end sets an OVERFLOW flag and returns zeros rather than reading whatever
/// is next in memory, so a truncated or hostile packet degrades into a value the caller can
/// reject rather than into garbage it cannot tell from data. Check Ok before acting on
/// anything a packet decoded to.
///
/// The buffer is BORROWED and must outlive the reader.
class BitReader
{
	private Span<uint8> mData;
	private int mBytePosition = 0;
	private uint64 mScratch = 0;
	private uint32 mScratchBits = 0;
	private bool mOverflow = false;

	public this(Span<uint8> data)
	{
		mData = data;
	}

	public uint32 ReadBits(uint32 bits)
	{
		Debug.Assert(bits <= 32);
		if (bits == 0)
			return 0;

		uint32 result = 0;
		uint32 got = 0;
		while (got < bits)
		{
			if (mScratchBits == 0)
			{
				if (mBytePosition >= mData.Length)
				{
					// Whatever was decoded so far is returned, but Ok is false from here on
					// and the caller is expected to stop.
					mOverflow = true;
					return result;
				}
				mScratch = mData[mBytePosition];
				mBytePosition++;
				mScratchBits = 8;
			}

			// Spelled uint32 rather than left to inference: Beef widens the subtraction to
			// int, and an int shift count then poisons the compound assignments below.
			uint32 take = (uint32)Min(bits - got, mScratchBits);
			// The mask is built at sixty four bits because the scratch is, and because
			// shifting by a full width is undefined.
			let mask = ((uint64)1 << take) - (uint64)1;
			let chunk = (uint32)(mScratch & mask);
			result |= (chunk << got);
			mScratch >>= take;
			mScratchBits -= take;
			got += take;
		}
		return result;
	}

	public bool ReadBool() => ReadBits(1) != 0;
	public uint8 ReadU8() => (uint8)ReadBits(8);
	public uint16 ReadU16() => (uint16)ReadBits(16);
	public uint32 ReadU32() => ReadBits(32);

	public uint64 ReadU64()
	{
		let low = (uint64)ReadBits(32);
		return low | ((uint64)ReadBits(32) << 32);
	}

	public int32 ReadI32() => (int32)ReadU32();

	public float ReadFloat()
	{
		var bits = ReadU32();
		return *(float*)&bits;
	}

	public double ReadDouble()
	{
		var bits = ReadU64();
		return *(double*)&bits;
	}

	public uint32 ReadVarU32()
	{
		uint32 value = 0;
		uint32 shift = 0;
		for (;;)
		{
			let b = ReadBits(8);
			value |= (b & 0x7F) << shift;
			// The shift bound stops a malformed run of continuation bytes from looping
			// forever on a value that cannot fit anyway.
			if (((b & 0x80) == 0) || (shift >= 28))
				break;
			shift += 7;
		}
		return value;
	}

	public float ReadFloatRanged(float min, float max, uint32 bits)
	{
		Debug.Assert((bits >= 1) && (bits <= 32));
		let maxQuantised = (bits >= 32) ? (uint32)0xFFFFFFFF : (((uint32)1 << bits) - 1);
		let q = ReadBits(bits);
		let t = (maxQuantised > 0) ? ((float)q / (float)maxQuantised) : 0.0f;
		return min + t * (max - min);
	}

	public void ReadBytes(Span<uint8> outData)
	{
		for (int i = 0; i < outData.Length; i++)
			outData[i] = ReadU8();
	}

	/// False once ANY read ran past the end. Sticky, so one check after decoding a whole
	/// packet is enough.
	public bool Ok => !mOverflow;

	/// Nothing left to read, and nothing overflowed.
	public bool AtEnd => (mBytePosition >= mData.Length) && (mScratchBits == 0);
}
