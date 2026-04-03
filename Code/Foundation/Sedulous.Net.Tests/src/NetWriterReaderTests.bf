namespace Sedulous.Net.Tests;

using System;
using System.Collections;
using Sedulous.Net;

class NetWriterReaderTests
{
	[Test]
	public static void WriteRead_UInt16()
	{
		let list = scope List<uint8>();
		NetWriter.WriteUInt16(list, 0x1234);
		Test.Assert(list.Count == 2);
		Test.Assert(NetReader.ReadUInt16(Span<uint8>(list.Ptr, list.Count), 0) case .Ok(0x1234));
	}

	[Test]
	public static void WriteRead_UInt32()
	{
		let list = scope List<uint8>();
		NetWriter.WriteUInt32(list, 0xABCD1234);
		Test.Assert(list.Count == 4);
		Test.Assert(NetReader.ReadUInt32(Span<uint8>(list.Ptr, list.Count), 0) case .Ok(0xABCD1234));
	}

	[Test]
	public static void WriteRead_UInt64()
	{
		let list = scope List<uint8>();
		NetWriter.WriteUInt64(list, 0x0102030405060708);
		Test.Assert(list.Count == 8);
		Test.Assert(NetReader.ReadUInt64(Span<uint8>(list.Ptr, list.Count), 0) case .Ok(0x0102030405060708));
	}

	[Test]
	public static void WriteRead_Int16()
	{
		let list = scope List<uint8>();
		NetWriter.WriteInt16(list, -500);
		Test.Assert(NetReader.ReadInt16(Span<uint8>(list.Ptr, list.Count), 0) case .Ok(-500));
	}

	[Test]
	public static void WriteRead_Int32()
	{
		let list = scope List<uint8>();
		NetWriter.WriteInt32(list, -123456);
		Test.Assert(NetReader.ReadInt32(Span<uint8>(list.Ptr, list.Count), 0) case .Ok(-123456));
	}

	[Test]
	public static void BigEndian_Verification()
	{
		let list = scope List<uint8>();
		NetWriter.WriteUInt16(list, 0x0102);
		Test.Assert(list[0] == 0x01);
		Test.Assert(list[1] == 0x02);
	}

	[Test]
	public static void ReadOutOfBounds_ReturnsError()
	{
		uint8[2] data = .(1, 2);
		Test.Assert(NetReader.ReadUInt32(Span<uint8>(&data, 2), 0) case .Err);
		Test.Assert(NetReader.ReadUInt16(Span<uint8>(&data, 2), 1) case .Err);
	}

	[Test]
	public static void WriteAt_UInt16()
	{
		uint8[4] data = .(0, 0, 0, 0);
		NetWriter.WriteUInt16At(Span<uint8>(&data, 4), 1, 0xABCD);
		Test.Assert(data[1] == 0xAB);
		Test.Assert(data[2] == 0xCD);
	}

	[Test]
	public static void WriteAt_UInt32()
	{
		uint8[8] data = default;
		NetWriter.WriteUInt32At(Span<uint8>(&data, 8), 2, 0x12345678);
		Test.Assert(data[2] == 0x12);
		Test.Assert(data[3] == 0x34);
		Test.Assert(data[4] == 0x56);
		Test.Assert(data[5] == 0x78);
	}

	[Test]
	public static void ReadAtOffset()
	{
		uint8[6] data = .(0, 0, 0x12, 0x34, 0, 0);
		Test.Assert(NetReader.ReadUInt16(Span<uint8>(&data, 6), 2) case .Ok(0x1234));
	}
}
