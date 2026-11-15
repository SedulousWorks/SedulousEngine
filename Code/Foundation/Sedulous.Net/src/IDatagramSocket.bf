using System;
using System.Collections;

namespace Sedulous.Net;

/// Connectionless, unreliable datagram I/O: the substrate reliability rides on.
///
/// No ordering and no delivery guarantee. A datagram arrives WHOLE or not at all, which is
/// the one property the reliability layer above is allowed to assume.
///
/// Splitting this from reliability is what lets the protocol be tested against deterministic
/// loss and reorder with no operating system sockets involved.
interface IDatagramSocket
{
	void Send(DatagramEndpoint to, Span<uint8> data);

	/// Dequeues one received datagram into outData, setting outFrom to the sender. False when
	/// none is waiting.
	bool Receive(out DatagramEndpoint outFrom, List<uint8> outData);

	DatagramEndpoint LocalEndpoint { get; }

	/// The transport is done with `remote`: its connection ended and no other uses the address.
	/// A socket that holds a connection per remote, as the WebSocket gateway holds a client,
	/// closes it; a UDP socket holds nothing per remote.
	void CloseRemote(DatagramEndpoint remote)
	{
	}
}
