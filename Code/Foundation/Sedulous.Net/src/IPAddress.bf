namespace Sedulous.Net;

using System;
using System.Net;

struct IPAddress : IEquatable<IPAddress>, IHashable
{
	public enum Family
	{
		IPv4,
		IPv6
	}

	private Family mFamily;
	private Socket.IPv4Address mIPv4;
	private Socket.IPv6Address mIPv6;

	public this(uint8 a, uint8 b, uint8 c, uint8 d)
	{
		mFamily = .IPv4;
		mIPv4 = .(a, b, c, d);
		mIPv6 = default;
	}

	public this(Socket.IPv4Address addr)
	{
		mFamily = .IPv4;
		mIPv4 = addr;
		mIPv6 = default;
	}

	public this(Socket.IPv6Address addr)
	{
		mFamily = .IPv6;
		mIPv4 = default;
		mIPv6 = addr;
	}

	public Family AddressFamily => mFamily;

	public bool IsLoopback
	{
		get
		{
			if (mFamily == .IPv4)
				return mIPv4.b1 == 127 && mIPv4.b2 == 0 && mIPv4.b3 == 0 && mIPv4.b4 == 1;
			// IPv6 ::1
			for (int i = 0; i < 15; i++)
				if (mIPv6.byte[i] != 0) return false;
			return mIPv6.byte[15] == 1;
		}
	}

	public bool IsAny
	{
		get
		{
			if (mFamily == .IPv4)
				return mIPv4.b1 == 0 && mIPv4.b2 == 0 && mIPv4.b3 == 0 && mIPv4.b4 == 0;
			for (int i = 0; i < 16; i++)
				if (mIPv6.byte[i] != 0) return false;
			return true;
		}
	}

	public static readonly IPAddress Any = .(0, 0, 0, 0);
	public static readonly IPAddress Loopback = .(127, 0, 0, 1);
	public static readonly IPAddress Broadcast = .(255, 255, 255, 255);
	public static readonly IPAddress IPv6Any = .(Socket.IN6ADDR_ANY);
	public static readonly IPAddress IPv6Loopback = .(Socket.IPv6Address(0, 0, 0, 0, 0, 0, 0, 1));

	public Socket.IPv4Address ToIPv4() => mIPv4;
	public Socket.IPv6Address ToIPv6() => mIPv6;

	public static Result<IPAddress, NetError> Parse(StringView str)
	{
		// Try IPv4: a.b.c.d
		var parts = str.Split('.');
		uint8[4] octets = default;
		int count = 0;

		for (var part in parts)
		{
			if (count >= 4)
				return .Err(.ParseError);
			if (uint8.Parse(part) case .Ok(let val))
				octets[count++] = val;
			else
				return .Err(.ParseError);
		}

		if (count == 4)
			return .Ok(IPAddress(octets[0], octets[1], octets[2], octets[3]));

		return .Err(.ParseError);
	}

	public override void ToString(String strBuffer)
	{
		if (mFamily == .IPv4)
			strBuffer.AppendF("{}.{}.{}.{}", mIPv4.b1, mIPv4.b2, mIPv4.b3, mIPv4.b4);
		else
		{
			// Simplified IPv6 formatting
			for (int i = 0; i < 8; i++)
			{
				if (i > 0) strBuffer.Append(':');
				uint16 word = mIPv6.word[i];
				// Display in host order (word is stored in network order)
				strBuffer.AppendF("{:x}", Socket.htons((int16)word));
			}
		}
	}

	public bool Equals(IPAddress other)
	{
		if (mFamily != other.mFamily) return false;
		if (mFamily == .IPv4)
			return mIPv4.b1 == other.mIPv4.b1 && mIPv4.b2 == other.mIPv4.b2 &&
				   mIPv4.b3 == other.mIPv4.b3 && mIPv4.b4 == other.mIPv4.b4;
		for (int i = 0; i < 16; i++)
			if (mIPv6.byte[i] != other.mIPv6.byte[i]) return false;
		return true;
	}

	public int GetHashCode()
	{
		if (mFamily == .IPv4)
			return (int)(((uint32)mIPv4.b1 << 24) | ((uint32)mIPv4.b2 << 16) | ((uint32)mIPv4.b3 << 8) | mIPv4.b4);
		int hash = 17;
		for (int i = 0; i < 16; i++)
			hash = hash * 31 + mIPv6.byte[i];
		return hash;
	}
}
