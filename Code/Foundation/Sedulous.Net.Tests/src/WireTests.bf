using System;
using Sedulous.Net;

namespace Sedulous.Net.Tests;

/// The bit layer: widths, typed helpers, varints, quantisation and overflow safety.
class WireTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) =>
		((a - b) <= epsilon) && ((b - a) <= epsilon);

	[Test]
	public static void ArbitraryBitWidthsRoundTripInOrder()
	{
		let writer = scope BitWriter();
		writer.WriteBits(1, 1);
		writer.WriteBits(5, 3);
		writer.WriteBits(0, 4);
		// Ten bits starting at bit eight, so this one spans a byte boundary.
		writer.WriteBits(0x2AA, 10);
		writer.WriteBits(0xFFFFFFFF, 32);

		let reader = scope BitReader(writer.Data);
		Test.Assert(reader.ReadBits(1) == 1);
		Test.Assert(reader.ReadBits(3) == 5);
		Test.Assert(reader.ReadBits(4) == 0);
		Test.Assert(reader.ReadBits(10) == 0x2AA);
		Test.Assert(reader.ReadBits(32) == 0xFFFFFFFF);
		Test.Assert(reader.Ok);
	}

	[Test]
	public static void TheTypedHelpersRoundTrip()
	{
		let writer = scope BitWriter();
		writer.WriteBool(true);
		writer.WriteBool(false);
		writer.WriteU8(0xAB);
		writer.WriteU16(0x1234);
		writer.WriteU32(0xDEADBEEF);
		writer.WriteU64(0x1122334455667788);
		writer.WriteI32(-42);
		writer.WriteFloat(3.14159f);
		writer.WriteDouble(-2.5);

		let reader = scope BitReader(writer.Data);
		Test.Assert(reader.ReadBool());
		Test.Assert(!reader.ReadBool());
		Test.Assert(reader.ReadU8() == 0xAB);
		Test.Assert(reader.ReadU16() == 0x1234);
		Test.Assert(reader.ReadU32() == 0xDEADBEEF);
		Test.Assert(reader.ReadU64() == 0x1122334455667788);
		Test.Assert(reader.ReadI32() == -42);
		Test.Assert(Near(reader.ReadFloat(), 3.14159f));
		Test.Assert(reader.ReadDouble() == -2.5);
		Test.Assert(reader.Ok);
	}

	[Test]
	public static void AVarintCostsOneByteForASmallValue()
	{
		let writer = scope BitWriter();
		writer.WriteVarU32(0);
		writer.WriteVarU32(127);
		writer.WriteVarU32(128);
		writer.WriteVarU32(300);
		writer.WriteVarU32(0xFFFFFFFF);
		// One, one, two, two and five: the whole point is that a small id is cheap.
		Test.Assert(writer.ByteCount == 11);

		let reader = scope BitReader(writer.Data);
		Test.Assert(reader.ReadVarU32() == 0);
		Test.Assert(reader.ReadVarU32() == 127);
		Test.Assert(reader.ReadVarU32() == 128);
		Test.Assert(reader.ReadVarU32() == 300);
		Test.Assert(reader.ReadVarU32() == 0xFFFFFFFF);
		Test.Assert(reader.Ok);
	}

	[Test]
	public static void QuantisationStaysWithinItsResolutionAndClamps()
	{
		let writer = scope BitWriter();
		writer.WriteFloatRanged(0.0f, -1.0f, 1.0f, 16);
		writer.WriteFloatRanged(0.5f, 0.0f, 1.0f, 16);
		writer.WriteFloatRanged(2.0f, 0.0f, 1.0f, 8);
		writer.WriteFloatRanged(-9.0f, 0.0f, 1.0f, 8);

		let reader = scope BitReader(writer.Data);
		Test.Assert(Near(reader.ReadFloatRanged(-1.0f, 1.0f, 16), 0.0f));
		Test.Assert(Near(reader.ReadFloatRanged(0.0f, 1.0f, 16), 0.5f));
		// Out of range in either direction clamps rather than wrapping.
		Test.Assert(Near(reader.ReadFloatRanged(0.0f, 1.0f, 8), 1.0f));
		Test.Assert(Near(reader.ReadFloatRanged(0.0f, 1.0f, 8), 0.0f));
		Test.Assert(reader.Ok);
	}

	[Test]
	public static void BytesRoundTripFromANonAlignedStart()
	{
		let payload = scope uint8[](0x00, 0x7F, 0x80, 0xFF, 0x42, 0x13);

		let writer = scope BitWriter();
		// One bit first, so the byte run is deliberately not byte aligned.
		writer.WriteBool(true);
		writer.WriteBytes(payload);

		let reader = scope BitReader(writer.Data);
		Test.Assert(reader.ReadBool());
		let got = scope uint8[payload.Count];
		reader.ReadBytes(got);
		for (int i = 0; i < payload.Count; i++)
			Test.Assert(got[i] == payload[i]);
		Test.Assert(reader.Ok);
	}

	[Test]
	public static void ReadingPastTheEndDegradesSafely()
	{
		let writer = scope BitWriter();
		writer.WriteU16(0xBEEF);

		let reader = scope BitReader(writer.Data);
		Test.Assert(reader.ReadU16() == 0xBEEF);
		Test.Assert(reader.Ok);
		Test.Assert(reader.AtEnd);

		reader.ReadU32();
		// Flagged rather than returning whatever was next in memory.
		Test.Assert(!reader.Ok);
	}
}
