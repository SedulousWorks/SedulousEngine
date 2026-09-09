using System;

namespace Sedulous.Net;

/// An opaque datagram address.
///
/// Real UDP packs an IPv4 address and a port; the sim uses a socket index. Comparable and
/// hashable, so a transport can key per remote connection state off one.
struct DatagramEndpoint : IHashable
{
	public uint64 Value = 0;

	public this() {}

	public this(uint64 value)
	{
		Value = value;
	}

	/// Zero is no endpoint, so a default constructed one is invalid rather than a real
	/// address.
	public bool IsValid => Value != 0;

	[Commutable]
	public static bool operator==(DatagramEndpoint a, DatagramEndpoint b) => a.Value == b.Value;

	public int GetHashCode() => (int)(Value ^ (Value >> 32));
}
