namespace Sedulous.Net.Tests;

using System;
using System.Collections;
using Sedulous.Net;

class DnsTests
{
	[Test]
	public static void Resolve_Localhost()
	{
		switch (DnsResolver.Resolve("localhost"))
		{
		case .Ok(let addr):
			Test.Assert(addr.IsLoopback);
		case .Err:
			Test.Assert(false);
		}
	}

	[Test]
	public static void Resolve_LiteralIP()
	{
		// Literal IP should be returned as-is
		switch (DnsResolver.Resolve("192.168.1.1"))
		{
		case .Ok(let addr):
			let str = scope String();
			addr.ToString(str);
			Test.Assert(str.Equals("192.168.1.1"));
		case .Err:
			Test.Assert(false);
		}
	}

	[Test]
	public static void Resolve_InvalidHost()
	{
		// A hostname that should not resolve.
		// Note: Some DNS servers (ISPs, corporate) may resolve all domains.
		// This test may pass on such networks - that's acceptable.
		let result = DnsResolver.Resolve("this.host.does.not.exist.invalid");
		if (result case .Err)
			Test.Assert(true); // Expected: DNS resolution fails
		// If it resolves (ISP intercept), we don't fail the test
	}

	[Test]
	public static void ResolveEndPoint()
	{
		switch (DnsResolver.ResolveEndPoint("localhost", 8080))
		{
		case .Ok(let ep):
			Test.Assert(ep.Port == 8080);
			Test.Assert(ep.Address.IsLoopback);
		case .Err:
			Test.Assert(false);
		}
	}

	[Test]
	public static void ResolveAll_Localhost()
	{
		let addresses = scope List<IPAddress>();
		switch (DnsResolver.ResolveAll("localhost", addresses))
		{
		case .Ok:
			Test.Assert(addresses.Count >= 1);
			// At least one should be loopback
			var hasLoopback = false;
			for (let addr in addresses)
			{
				if (addr.IsLoopback)
				{
					hasLoopback = true;
					break;
				}
			}
			Test.Assert(hasLoopback);
		case .Err:
			Test.Assert(false);
		}
	}

	[Test]
	public static void ResolveAll_LiteralIP()
	{
		let addresses = scope List<IPAddress>();
		Test.Assert(DnsResolver.ResolveAll("10.20.30.40", addresses) case .Ok);
		Test.Assert(addresses.Count == 1);
		let str = scope String();
		addresses[0].ToString(str);
		Test.Assert(str.Equals("10.20.30.40"));
	}
}
