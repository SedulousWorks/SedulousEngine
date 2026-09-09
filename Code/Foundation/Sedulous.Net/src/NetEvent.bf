using System;
using System.Collections;

namespace Sedulous.Net;

/// One event drained from a transport.
///
/// The caller SUPPLIES one of these to Poll and reuses it across the drain loop, so a busy
/// tick does not allocate an event per packet. Payload is refilled on each Poll and is only
/// meaningful for Received.
class NetEvent
{
	public NetEventKind Kind = .Received;
	public PeerId Peer = InvalidPeer;
	public uint8 Channel = 0;
	/// Owned by this event, and valid until the next Poll into it.
	public List<uint8> Payload = new .() ~ delete _;

	/// Takes on another event's contents. The payload is COPIED, because the queue keeps
	/// owning its own.
	public void Set(NetEventKind kind, PeerId peer, uint8 channel, Span<uint8> payload)
	{
		Kind = kind;
		Peer = peer;
		Channel = channel;
		Payload.Clear();
		Payload.AddRange(payload);
	}
}
