using System;
using System.Collections;

namespace Sedulous.Net;

/// A name to handler registry for remote calls over a session.
///
/// Register once, Call or CallAll to invoke remotely, and Dispatch the matching received
/// events. Arguments go through the bit-exact wire layer, so an auto-marshalling convenience
/// built on reflection later layers cleanly on top of this rather than replacing it.
///
/// For a turn-based game this is the PRIMARY gameplay path: a client calls an order on the
/// server, the server validates and resolves it, and calls the result back out to everyone.
///
/// The table OWNS its handlers.
class RpcTable
{
	/// Reserved for RPC. Two hundred and fifty five is session control, so games use nought to
	/// two hundred and fifty three.
	public const uint8 RpcChannel = 254;

	/// sender is who invoked it; args carries the call's serialized arguments, which may be
	/// empty.
	public typealias Handler = delegate void(PeerId sender, BitReader args);
	/// Writes a call's arguments. Null for a call that takes none.
	public typealias ArgumentWriter = delegate void(BitWriter args);

	private Dictionary<uint32, Handler> mHandlers = new .() ~ DeleteDictionaryAndValues!(_);

	/// Registers a handler, REPLACING any handler already under that name. Names are hashed to
	/// the wire, so both ends must spell them identically.
	///
	/// Ownership of the handler transfers here.
	public void On(StringView name, Handler handler)
	{
		let id = Hash(name);
		if (mHandlers.TryGetValue(id, let existing))
			delete existing;
		mHandlers[id] = handler;
	}

	/// Invokes on one peer.
	public void Call(NetSession session, PeerId peer, StringView name,
		ArgumentWriter writeArgs = null, Reliability reliability = .ReliableOrdered)
	{
		let writer = scope BitWriter();
		writer.WriteU32(Hash(name));
		if (writeArgs != null)
			writeArgs(writer);
		session.Send(peer, RpcChannel, writer.Data, reliability);
	}

	/// Invokes on every connected peer.
	public void CallAll(NetSession session, StringView name, ArgumentWriter writeArgs = null,
		Reliability reliability = .ReliableOrdered)
	{
		let writer = scope BitWriter();
		writer.WriteU32(Hash(name));
		if (writeArgs != null)
			writeArgs(writer);
		session.Broadcast(RpcChannel, writer.Data, reliability);
	}

	/// Whether a received event is an RPC. Route those to Dispatch and handle the rest.
	public static bool IsRpcChannel(uint8 channel) => channel == RpcChannel;

	/// Dispatches a received payload to its handler. A no-op for an unregistered id or a
	/// truncated payload, so a peer calling something this build does not have is ignored
	/// rather than fatal.
	public void Dispatch(PeerId sender, Span<uint8> payload)
	{
		let reader = scope BitReader(payload);
		let id = reader.ReadU32();
		if (!reader.Ok)
			return;

		if (mHandlers.TryGetValue(id, let handler))
			handler(sender, reader);
	}

	/// Drains a session's events, routing RPCs here and handing the rest to onOther.
	public void Pump(NetSession session, delegate void(NetEvent) onOther = null)
	{
		let event = scope NetEvent();
		while (session.PollEvent(event))
		{
			if ((event.Kind == .Received) && IsRpcChannel(event.Channel))
				Dispatch(event.Peer, event.Payload);
			else if (onOther != null)
				onOther(event);
		}
	}

	/// The wire id a name maps to, FNV-1a. Public for tests and for debugging a mismatch.
	public static uint32 Hash(StringView name)
	{
		uint32 hash = 2166136261;
		for (let c in name)
		{
			hash ^= (uint32)(uint8)c;
			// Wrapping on purpose: FNV relies on the multiply overflowing, and the plain
			// operator traps wherever those checks are on.
			hash = hash &* 16777619;
		}
		return hash;
	}
}
