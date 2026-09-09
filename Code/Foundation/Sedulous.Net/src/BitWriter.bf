using System;
using System.Collections;
using System.Diagnostics;
using Sedulous.Core;

namespace Sedulous.Net;

/// Packs values to the BIT rather than the byte.
///
/// Bandwidth is the scarce resource in a game protocol, so the reliability layer, RPC and
/// replication all encode through this rather than through a byte serializer: a bool costs one
/// bit, a length costs one byte, and a position costs whatever precision it actually needs.
///
/// LSB FIRST within a byte: a value's low bit goes to the byte's bit zero. The reader is
/// symmetric, and the only contract between them is the same call sequence.
class BitWriter
{
	private List<uint8> mBytes = new .() ~ delete _;
	/// Bits written but not yet whole enough to flush. Fewer than eight between calls.
	private uint64 mScratch = 0;
	private uint32 mScratchBits = 0;

	/// The low `bits` of `value`, up to thirty two.
	public void WriteBits(uint32 value, uint32 bits)
	{
		Debug.Assert(bits <= 32);
		if (bits == 0)
			return;

		// A thirty two bit shift is undefined rather than a no-op, so the full width case
		// skips the mask instead of building it.
		let masked = (bits >= 32) ? value : (value & (((uint32)1 << bits) - 1));
		mScratch |= ((uint64)masked << mScratchBits);
		mScratchBits += bits;

		while (mScratchBits >= 8)
		{
			mBytes.Add((uint8)(mScratch & 0xFF));
			mScratch >>= 8;
			mScratchBits -= 8;
		}
	}

	public void WriteBool(bool value) => WriteBits(value ? 1 : 0, 1);
	public void WriteU8(uint8 value) => WriteBits(value, 8);
	public void WriteU16(uint16 value) => WriteBits(value, 16);
	public void WriteU32(uint32 value) => WriteBits(value, 32);

	public void WriteU64(uint64 value)
	{
		WriteBits((uint32)(value & 0xFFFFFFFF), 32);
		WriteBits((uint32)(value >> 32), 32);
	}

	public void WriteI32(int32 value) => WriteU32((uint32)value);

	public void WriteFloat(float value)
	{
		var value;
		WriteU32(*(uint32*)&value);
	}

	public void WriteDouble(double value)
	{
		var value;
		WriteU64(*(uint64*)&value);
	}

	/// A variable length unsigned, seven bits to a byte. A small value costs ONE byte, which
	/// is what makes lengths and ids cheap.
	public void WriteVarU32(uint32 value)
	{
		var value;
		while (value >= 0x80)
		{
			WriteBits((value & 0x7F) | 0x80, 8);
			value >>= 7;
		}
		WriteBits(value, 8);
	}

	/// Quantises into `bits` over [min, max], CLAMPED. Lossy on purpose: a position or a
	/// rotation rarely needs a whole float, and this is where most of the bandwidth saving
	/// comes from. Symmetric with ReadFloatRanged of the same three arguments.
	public void WriteFloatRanged(float value, float min, float max, uint32 bits)
	{
		Debug.Assert((bits >= 1) && (bits <= 32));
		let span = max - min;
		let t = (span > 0.0f) ? Clamp((value - min) / span, 0.0f, 1.0f) : 0.0f;
		let maxQuantised = (bits >= 32) ? (uint32)0xFFFFFFFF : (((uint32)1 << bits) - 1);
		// The half rounds to nearest rather than truncating, which halves the worst case
		// error.
		WriteBits((uint32)(t * (float)maxQuantised + 0.5f), bits);
	}

	public void WriteBytes(Span<uint8> data)
	{
		for (let b in data)
			WriteBits(b, 8);
	}

	/// The finished buffer, flushing a partial trailing byte with zero padding. Idempotent,
	/// so asking twice does not pad twice.
	public Span<uint8> Data
	{
		get
		{
			Flush();
			return .(mBytes.Ptr, mBytes.Count);
		}
	}

	public int ByteCount
	{
		get
		{
			Flush();
			return mBytes.Count;
		}
	}

	/// Bits written so far, BEFORE any flush padding.
	public int BitCount => mBytes.Count * 8 + (int)mScratchBits;

	public void Reset()
	{
		mBytes.Clear();
		mScratch = 0;
		mScratchBits = 0;
	}

	private void Flush()
	{
		if (mScratchBits > 0)
		{
			mBytes.Add((uint8)(mScratch & 0xFF));
			mScratch = 0;
			mScratchBits = 0;
		}
	}
}
