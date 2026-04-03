namespace Sedulous.Net.Tests;

using System;
using Sedulous.Net;

class IPAddressTests
{
	[Test]
	public static void Parse_ValidIPv4()
	{
		let result = IPAddress.Parse("192.168.1.1");
		Test.Assert(result case .Ok(let addr));
		let str = scope String();
		addr.ToString(str);
		Test.Assert(str.Equals("192.168.1.1"));
	}

	[Test]
	public static void Parse_Loopback()
	{
		let result = IPAddress.Parse("127.0.0.1");
		Test.Assert(result case .Ok(let addr));
		Test.Assert(addr.IsLoopback);
	}

	[Test]
	public static void Parse_Any()
	{
		let result = IPAddress.Parse("0.0.0.0");
		Test.Assert(result case .Ok(let addr));
		Test.Assert(addr.IsAny);
	}

	[Test]
	public static void Parse_Invalid_ReturnsError()
	{
		Test.Assert(IPAddress.Parse("not.an.ip") case .Err);
		Test.Assert(IPAddress.Parse("256.1.1.1") case .Err);
		Test.Assert(IPAddress.Parse("1.2.3") case .Err);
		Test.Assert(IPAddress.Parse("") case .Err);
	}

	[Test]
	public static void ToString_Roundtrip()
	{
		let addr = IPAddress(10, 20, 30, 40);
		let str = scope String();
		addr.ToString(str);
		Test.Assert(str.Equals("10.20.30.40"));

		let parsed = IPAddress.Parse(str);
		Test.Assert(parsed case .Ok(let addr2));
		Test.Assert(addr.Equals(addr2));
	}

	[Test]
	public static void Static_Loopback()
	{
		Test.Assert(IPAddress.Loopback.IsLoopback);
		Test.Assert(!IPAddress.Loopback.IsAny);
	}

	[Test]
	public static void Static_Any()
	{
		Test.Assert(IPAddress.Any.IsAny);
		Test.Assert(!IPAddress.Any.IsLoopback);
	}

	[Test]
	public static void Equals_SameAddress()
	{
		let a = IPAddress(192, 168, 0, 1);
		let b = IPAddress(192, 168, 0, 1);
		Test.Assert(a.Equals(b));
	}

	[Test]
	public static void Equals_DifferentAddress()
	{
		let a = IPAddress(192, 168, 0, 1);
		let b = IPAddress(192, 168, 0, 2);
		Test.Assert(!a.Equals(b));
	}

	[Test]
	public static void AddressFamily_IPv4()
	{
		let addr = IPAddress(1, 2, 3, 4);
		Test.Assert(addr.AddressFamily == .IPv4);
	}
}
