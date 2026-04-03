namespace Sedulous.Net.Tests;

using System;
using Sedulous.Net;

class NetBufferTests
{
	// ==================== Basic Write/Read ====================

	[Test]
	public static void WriteReadUInt8()
	{
		let buf = scope NetBuffer();
		buf.WriteUInt8(0xAB);
		Test.Assert(buf.Length == 1);
		Test.Assert(buf.ReadUInt8() case .Ok(0xAB));
	}

	[Test]
	public static void WriteReadInt8()
	{
		let buf = scope NetBuffer();
		buf.WriteInt8(-42);
		Test.Assert(buf.ReadInt8() case .Ok(-42));
	}

	[Test]
	public static void WriteReadUInt16()
	{
		let buf = scope NetBuffer();
		buf.WriteUInt16(0x1234);
		Test.Assert(buf.ReadUInt16() case .Ok(0x1234));
	}

	[Test]
	public static void WriteReadInt16()
	{
		let buf = scope NetBuffer();
		buf.WriteInt16(-1000);
		Test.Assert(buf.ReadInt16() case .Ok(-1000));
	}

	[Test]
	public static void WriteReadUInt32()
	{
		let buf = scope NetBuffer();
		buf.WriteUInt32(0xDEADBEEF);
		Test.Assert(buf.ReadUInt32() case .Ok(0xDEADBEEF));
	}

	[Test]
	public static void WriteReadInt32()
	{
		let buf = scope NetBuffer();
		buf.WriteInt32(-123456);
		Test.Assert(buf.ReadInt32() case .Ok(-123456));
	}

	[Test]
	public static void WriteReadUInt64()
	{
		let buf = scope NetBuffer();
		buf.WriteUInt64(0x0102030405060708);
		Test.Assert(buf.ReadUInt64() case .Ok(0x0102030405060708));
	}

	[Test]
	public static void WriteReadFloat()
	{
		let buf = scope NetBuffer();
		buf.WriteFloat(3.14f);
		if (buf.ReadFloat() case .Ok(let val))
			Test.Assert(Math.Abs(val - 3.14f) < 0.001f);
		else
			Test.Assert(false);
	}

	[Test]
	public static void WriteReadDouble()
	{
		let buf = scope NetBuffer();
		buf.WriteDouble(2.718281828);
		if (buf.ReadDouble() case .Ok(let val))
			Test.Assert(Math.Abs(val - 2.718281828) < 0.000001);
		else
			Test.Assert(false);
	}

	// ==================== Endianness ====================

	[Test]
	public static void BigEndian_UInt16()
	{
		let buf = scope NetBuffer();
		buf.WriteUInt16(0x0102);
		let data = buf.Data;
		Test.Assert(data[0] == 0x01);
		Test.Assert(data[1] == 0x02);
	}

	[Test]
	public static void BigEndian_UInt32()
	{
		let buf = scope NetBuffer();
		buf.WriteUInt32(0x01020304);
		let data = buf.Data;
		Test.Assert(data[0] == 0x01);
		Test.Assert(data[1] == 0x02);
		Test.Assert(data[2] == 0x03);
		Test.Assert(data[3] == 0x04);
	}

	// ==================== Strings ====================

	[Test]
	public static void WriteReadString()
	{
		let buf = scope NetBuffer();
		buf.WriteString("Hello, Net!");
		let result = scope String();
		Test.Assert(buf.ReadString(result) case .Ok);
		Test.Assert(result.Equals("Hello, Net!"));
	}

	[Test]
	public static void WriteReadEmptyString()
	{
		let buf = scope NetBuffer();
		buf.WriteString("");
		let result = scope String();
		Test.Assert(buf.ReadString(result) case .Ok);
		Test.Assert(result.IsEmpty);
	}

	[Test]
	public static void WriteReadRawString()
	{
		let buf = scope NetBuffer();
		buf.WriteRawString("raw");
		let result = scope String();
		Test.Assert(buf.ReadRawString(result, 3) case .Ok);
		Test.Assert(result.Equals("raw"));
	}

	// ==================== Bytes ====================

	[Test]
	public static void WriteReadBytes()
	{
		let buf = scope NetBuffer();
		uint8[4] data = .(1, 2, 3, 4);
		buf.WriteBytes(Span<uint8>(&data, 4));
		uint8[4] recv = default;
		Test.Assert(buf.ReadBytes(Span<uint8>(&recv, 4), 4) case .Ok(4));
		Test.Assert(recv[0] == 1 && recv[1] == 2 && recv[2] == 3 && recv[3] == 4);
	}

	// ==================== Buffer State ====================

	[Test]
	public static void ReadableBytes_Tracking()
	{
		let buf = scope NetBuffer();
		Test.Assert(buf.ReadableBytes == 0);
		buf.WriteUInt32(42);
		Test.Assert(buf.ReadableBytes == 4);
		buf.ReadUInt32();
		Test.Assert(buf.ReadableBytes == 0);
	}

	[Test]
	public static void ReadPastEnd_ReturnsError()
	{
		let buf = scope NetBuffer();
		buf.WriteUInt8(1);
		buf.ReadUInt8(); // consume the byte
		Test.Assert(buf.ReadUInt8() case .Err(.BufferUnderflow));
		Test.Assert(buf.ReadUInt16() case .Err(.BufferUnderflow));
		Test.Assert(buf.ReadUInt32() case .Err(.BufferUnderflow));
	}

	[Test]
	public static void Clear_ResetsPositions()
	{
		let buf = scope NetBuffer();
		buf.WriteUInt32(42);
		buf.ReadUInt16();
		buf.Clear();
		Test.Assert(buf.Length == 0);
		Test.Assert(buf.ReadableBytes == 0);
		Test.Assert(buf.ReadPosition == 0);
	}

	[Test]
	public static void Compact_ShiftsData()
	{
		let buf = scope NetBuffer();
		buf.WriteUInt8(1);
		buf.WriteUInt8(2);
		buf.WriteUInt8(3);
		buf.ReadUInt8(); // read first byte
		buf.Compact();
		Test.Assert(buf.ReadPosition == 0);
		Test.Assert(buf.ReadableBytes == 2);
		Test.Assert(buf.ReadUInt8() case .Ok(2));
		Test.Assert(buf.ReadUInt8() case .Ok(3));
	}

	[Test]
	public static void ConstructFromSpan()
	{
		uint8[3] data = .(10, 20, 30);
		let buf = scope NetBuffer(Span<uint8>(&data, 3));
		Test.Assert(buf.Length == 3);
		Test.Assert(buf.ReadUInt8() case .Ok(10));
		Test.Assert(buf.ReadUInt8() case .Ok(20));
		Test.Assert(buf.ReadUInt8() case .Ok(30));
	}

	// ==================== Multiple Sequential ====================

	[Test]
	public static void MultipleWritesThenReads()
	{
		let buf = scope NetBuffer();
		buf.WriteUInt8(1);
		buf.WriteUInt16(1000);
		buf.WriteUInt32(99999);
		buf.WriteString("test");

		Test.Assert(buf.ReadUInt8() case .Ok(1));
		Test.Assert(buf.ReadUInt16() case .Ok(1000));
		Test.Assert(buf.ReadUInt32() case .Ok(99999));
		let str = scope String();
		Test.Assert(buf.ReadString(str) case .Ok);
		Test.Assert(str.Equals("test"));
		Test.Assert(buf.ReadableBytes == 0);
	}

	// ==================== Edge Cases ====================

	[Test]
	public static void WriteReadZeroValues()
	{
		let buf = scope NetBuffer();
		buf.WriteUInt16(0);
		buf.WriteUInt32(0);
		buf.WriteFloat(0.0f);
		Test.Assert(buf.ReadUInt16() case .Ok(0));
		Test.Assert(buf.ReadUInt32() case .Ok(0));
		if (buf.ReadFloat() case .Ok(let val))
			Test.Assert(val == 0.0f);
	}

	[Test]
	public static void WriteReadMaxValues()
	{
		let buf = scope NetBuffer();
		buf.WriteUInt16(uint16.MaxValue);
		buf.WriteUInt32(uint32.MaxValue);
		Test.Assert(buf.ReadUInt16() case .Ok(uint16.MaxValue));
		Test.Assert(buf.ReadUInt32() case .Ok(uint32.MaxValue));
	}
}
