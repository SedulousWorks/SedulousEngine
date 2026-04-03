namespace Sedulous.Net;

using System;
using System.Net;

struct IPEndPoint : IEquatable<IPEndPoint>, IHashable
{
	public IPAddress Address;
	public uint16 Port;

	public this(IPAddress address, uint16 port)
	{
		Address = address;
		Port = port;
	}

	public this(uint8 a, uint8 b, uint8 c, uint8 d, uint16 port)
	{
		Address = .(a, b, c, d);
		Port = port;
	}

	public static Result<IPEndPoint, NetError> Parse(StringView str)
	{
		// Format: "address:port"
		let lastColon = str.LastIndexOf(':');
		if (lastColon < 0)
			return .Err(.ParseError);

		let addrPart = str.Substring(0, lastColon);
		let portPart = str.Substring(lastColon + 1);

		let address = Try!(IPAddress.Parse(addrPart));

		if (uint16.Parse(portPart) case .Ok(let port))
			return .Ok(IPEndPoint(address, port));

		return .Err(.ParseError);
	}

	public override void ToString(String strBuffer)
	{
		Address.ToString(strBuffer);
		strBuffer.AppendF(":{}", Port);
	}

	public Socket.SockAddr_in ToSockAddr()
	{
		Socket.SockAddr_in addr = default;
		addr.sin_family = Socket.AF_INET;
		addr.sin_addr = Address.ToIPv4();
		addr.sin_port = (uint16)Socket.htons((int16)Port);
		return addr;
	}

	public Socket.SockAddr_in6 ToSockAddr6()
	{
		Socket.SockAddr_in6 addr = default;
		addr.sin6_family = Socket.AF_INET6;
		addr.sin6_addr = Address.ToIPv6();
		addr.sin6_port = (uint16)Socket.htons((int16)Port);
		return addr;
	}

	public static IPEndPoint FromSockAddr(Socket.SockAddr_in sockAddr)
	{
		let port = (uint16)Socket.htons((int16)sockAddr.sin_port);
		return .(.(sockAddr.sin_addr), port);
	}

	public bool Equals(IPEndPoint other)
	{
		return Address.Equals(other.Address) && Port == other.Port;
	}

	public int GetHashCode()
	{
		return Address.GetHashCode() * 31 + Port;
	}
}
