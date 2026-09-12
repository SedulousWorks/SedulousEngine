using System;
using System.Net;

namespace Sedulous.Net;

/// Packing and resolving for IPv4 datagram endpoints.
///
/// An endpoint's value is (ip << 16) | port in HOST order. IPv4 only, which is what the
/// reliable transport's connection keying assumes.
static class NetAddress
{
	/// The port a socket actually bound to.
	///
	/// Beef's corlib socket can bind port zero and let the operating system choose, but it
	/// never reports back which port that was, so this asks the socket directly. Raptor gets
	/// the same answer out of its own Core/System layer; here corlib supplies everything
	/// EXCEPT this one call.
	[CLink]
	private static extern int32 getsockname(Socket.HSocket socket, Socket.SockAddr* address,
		int32* addressLength);

	public static DatagramEndpoint MakeEndpoint(uint32 ip, uint16 port) =>
		.(((uint64)ip << 16) | (uint64)port);

	public static uint32 EndpointIp(DatagramEndpoint endpoint) => (uint32)(endpoint.Value >> 16);

	public static uint16 EndpointPort(DatagramEndpoint endpoint) =>
		(uint16)(endpoint.Value & 0xFFFF);

	/// Host order, so the octets read left to right the way the dotted quad does.
	public static uint32 PackIPv4(Socket.IPv4Address address) =>
		((uint32)address.b1 << 24) | ((uint32)address.b2 << 16) | ((uint32)address.b3 << 8)
			| (uint32)address.b4;

	public static Socket.IPv4Address UnpackIPv4(uint32 ip) =>
		.((uint8)(ip >> 24), (uint8)(ip >> 16), (uint8)(ip >> 8), (uint8)ip);

	/// A strict dotted quad, the way inet_pton reads one: four decimal octets, one dot
	/// between each, and nothing else.
	public static bool ParseIPv4(StringView text, out uint32 outIp)
	{
		outIp = 0;

		uint32 packed = 0;
		int index = 0;
		for (int part < 4)
		{
			int digits = 0;
			uint32 octet = 0;
			while ((index < text.Length) && text[index].IsDigit)
			{
				octet = (octet * 10) + (uint32)(text[index] - '0');
				digits++;
				if ((octet > 255) || (digits > 3))
					return false;
				index++;
			}
			if (digits == 0)
				return false;

			packed = (packed << 8) | octet;
			if (part == 3)
				break;

			// Every octet but the last is followed by exactly one dot.
			if ((index >= text.Length) || (text[index] != '.'))
				return false;
			index++;
		}
		// A trailing anything, a fifth octet included, is not a dotted quad.
		if (index != text.Length)
			return false;

		outIp = packed;
		return true;
	}

	/// The address for a host, which may be a dotted quad or a name.
	///
	/// A NAME BLOCKS for the lookup, so this belongs at a connect edge and not in a frame.
	/// False when the host does not resolve to an IPv4 address.
	public static bool ResolveHostIPv4(StringView host, out uint32 outIp)
	{
		outIp = 0;

		// Windows resolves an EMPTY name to the local host where Linux calls it unknown, so
		// the refusal has to be ours. Raptor's Win32System.cpp:667 rejects it the same way.
		if (host.IsEmpty)
			return false;

		// A literal never touches the resolver, so it answers with no network reachable and
		// before Winsock is up.
		if (ParseIPv4(host, out outIp))
			return true;

		// Winsock has to be STARTED before any call reaches it, and this is a resolver: it
		// touches the stack without anyone having made a socket first. The socket types init
		// in their constructors, so a caller that connects before resolving happens to work
		// and one that resolves first gets WSANOTINITIALISED. A no-op everywhere but Windows,
		// and Windows refcounts it, which is why the socket types call it freely too.
		Socket.Init();

		if (Socket.GetAddrInfo(host, Socket.AddrInfo() { ai_family = Socket.AF_INET })
			case .Ok(var info))
		{
			defer info.Dispose();
			if (info.AddressFamily != Socket.AF_INET)
				return false;
			outIp = PackIPv4(info.IPv4);
			return true;
		}
		return false;
	}

	/// The endpoint for a host and port, or an invalid one when the host does not resolve.
	public static DatagramEndpoint ResolveEndpoint(StringView host, uint16 port)
	{
		if (!ResolveHostIPv4(host, let ip))
			return .();
		return MakeEndpoint(ip, port);
	}

	/// The port `socket` is bound to, or nought when it is not bound or the query fails.
	public static uint16 BoundPort(Socket socket)
	{
		if (!socket.IsOpen)
			return 0;

		Socket.SockAddr_in address = default;
		int32 length = sizeof(Socket.SockAddr_in);
		if (getsockname(socket.NativeSocket, (Socket.SockAddr*)&address, &length) != 0)
			return 0;
		// The kernel reports network order; the rest of this module works in host order.
		return (uint16)Socket.htons((int16)address.sin_port);
	}
}
