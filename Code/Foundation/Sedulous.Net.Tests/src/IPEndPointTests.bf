namespace Sedulous.Net.Tests;

using System;
using Sedulous.Net;

class IPEndPointTests
{
	[Test]
	public static void Constructor_AddressPort()
	{
		let ep = IPEndPoint(IPAddress(192, 168, 1, 1), 8080);
		Test.Assert(ep.Port == 8080);
		Test.Assert(ep.Address.Equals(IPAddress(192, 168, 1, 1)));
	}

	[Test]
	public static void Constructor_Convenience()
	{
		let ep = IPEndPoint(127, 0, 0, 1, 443);
		Test.Assert(ep.Port == 443);
		Test.Assert(ep.Address.IsLoopback);
	}

	[Test]
	public static void ToString_Format()
	{
		let ep = IPEndPoint(10, 0, 0, 1, 9090);
		let str = scope String();
		ep.ToString(str);
		Test.Assert(str.Equals("10.0.0.1:9090"));
	}

	[Test]
	public static void Parse_Valid()
	{
		let result = IPEndPoint.Parse("192.168.0.1:3000");
		Test.Assert(result case .Ok(let ep));
		Test.Assert(ep.Port == 3000);
		let addrStr = scope String();
		ep.Address.ToString(addrStr);
		Test.Assert(addrStr.Equals("192.168.0.1"));
	}

	[Test]
	public static void Parse_Invalid()
	{
		Test.Assert(IPEndPoint.Parse("no-port") case .Err);
		Test.Assert(IPEndPoint.Parse(":8080") case .Err);
	}

	[Test]
	public static void ToSockAddr_SetsFields()
	{
		let ep = IPEndPoint(127, 0, 0, 1, 80);
		let sa = ep.ToSockAddr();
		Test.Assert(sa.sin_addr.b1 == 127);
		Test.Assert(sa.sin_addr.b2 == 0);
		Test.Assert(sa.sin_addr.b3 == 0);
		Test.Assert(sa.sin_addr.b4 == 1);
	}

	[Test]
	public static void Equals_Same()
	{
		let a = IPEndPoint(1, 2, 3, 4, 100);
		let b = IPEndPoint(1, 2, 3, 4, 100);
		Test.Assert(a.Equals(b));
	}

	[Test]
	public static void Equals_DifferentPort()
	{
		let a = IPEndPoint(1, 2, 3, 4, 100);
		let b = IPEndPoint(1, 2, 3, 4, 200);
		Test.Assert(!a.Equals(b));
	}
}
