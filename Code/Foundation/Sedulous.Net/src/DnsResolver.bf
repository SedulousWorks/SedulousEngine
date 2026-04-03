namespace Sedulous.Net;

using System;
using System.Net;
using System.Collections;

static class DnsResolver
{
	/// Resolve hostname to first matching IPv4 address.
	public static Result<IPAddress, NetError> Resolve(StringView hostname)
	{
		SocketInit.EnsureInitialized();

		// Try parsing as literal IP first
		if (IPAddress.Parse(hostname) case .Ok(let addr))
			return .Ok(addr);

		Socket.AddrInfo hints = default;
		hints.ai_family = Socket.AF_INET;
		hints.ai_socktype = Socket.SOCK_STREAM;

		switch (Socket.GetAddrInfo(hostname, hints))
		{
		case .Ok(var info):
			defer info.Dispose();
			if (info.AddressFamily == Socket.AF_INET)
				return .Ok(IPAddress(info.IPv4));
			return .Err(.DnsResolutionFailed);
		case .Err:
			return .Err(.DnsResolutionFailed);
		}
	}

	/// Resolve hostname to all addresses.
	public static Result<void, NetError> ResolveAll(StringView hostname, List<IPAddress> outAddresses)
	{
		SocketInit.EnsureInitialized();

		// Try parsing as literal IP first
		if (IPAddress.Parse(hostname) case .Ok(let addr))
		{
			outAddresses.Add(addr);
			return .Ok;
		}

		Socket.AddrInfo hints = default;
		hints.ai_socktype = Socket.SOCK_STREAM;

		Socket.AddrInfo* result = null;
		switch (Socket.GetAddrInfo(hostname, hints, &result))
		{
		case .Ok:
			var current = result;
			while (current != null)
			{
				if (current.ai_family == Socket.AF_INET)
				{
					let sockAddr = (Socket.SockAddr_in*)current.ai_addr;
					outAddresses.Add(IPAddress(sockAddr.sin_addr));
				}
				current = (Socket.AddrInfo*)current.ai_next;
			}
			if (result != null)
			{
				var info = Socket.SockAddrInfo() { addrInfo = result };
				info.Dispose();
			}
			return .Ok;
		case .Err:
			return .Err(.DnsResolutionFailed);
		}
	}

	/// Resolve hostname + port to an endpoint.
	public static Result<IPEndPoint, NetError> ResolveEndPoint(StringView hostname, uint16 port)
	{
		switch (Resolve(hostname))
		{
		case .Ok(let addr):
			return .Ok(IPEndPoint(addr, port));
		case .Err(let err):
			return .Err(err);
		}
	}
}
