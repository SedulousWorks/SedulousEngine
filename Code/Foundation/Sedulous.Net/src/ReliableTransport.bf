using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;

namespace Sedulous.Net;

/// Reliable UDP over the unreliable datagram substrate.
///
/// Per remote it layers on: a packet header (protocol, type, sequence, ack, ack bits),
/// ack-driven round trip estimation, RELIABLE messages re-included in every packet until a
/// packet carrying them is acked and then released IN ORDER by message id, unreliable pass
/// through (SEQUENCED ones numbered per channel, a stale one dropped), a connect handshake
/// whose challenge cookie keeps a server from holding anything for a request until the client
/// answers from its address, a session token on every packet that tells a new session from the
/// same address apart, and keepalive and timeout.
///
/// The model is include-every-unacked-reliable-per-packet, which suits a low message rate:
/// there is no separate retransmit path to get wrong, and a lost packet costs one round trip
/// rather than a stall. CONGESTION CONTROL IS NOT IMPLEMENTED.
///
/// Tested headlessly against SimDatagramNetwork's loss and reorder, with no sockets.
class ReliableTransport : INetTransport
{
	private enum PacketType : uint8
	{
		case ConnectRequest = 0;
		case ConnectAccept = 1;
		case Data = 2;
		case Disconnect = 3;
		/// Server: the cookie a ConnectResponse must echo.
		case Challenge = 4;
		/// Client: the ConnectRequest again, with the challenge's cookie.
		case ConnectResponse = 5;
	}

	/// A handshake packet's size: protocol, type, token and a cookie. A ConnectRequest is padded
	/// to it, so a challenge is never bigger than the request that drew it (no amplification
	/// toward a spoofed address).
	private const int cHandshakeBytes = 2 + 1 + 4 + 8;
	/// A cookie is good for the window it was made in and the one after.
	private const double cCookieWindowMs = 10000.0;
	/// Reliable message ids in flight at once: the sender sends none past its oldest unacked id
	/// plus this, and the receiver buffers none past its next expected id plus this. Every id
	/// below the sender's oldest unacked one has reached the receiver, so a sender inside its
	/// window is inside the receiver's. Both ends use it, so it is not a setting; it keeps ids
	/// well inside the sixteen bit half range, where SeqGreater stops telling older from newer.
	private const uint16 cReliableWindow = 1024;

	/// A message queued to go out. A reliable one lives here until it is acked.
	private class OutMessage
	{
		public uint8 Channel = 0;
		public bool Reliable = false;
		/// Reliable: its message id. Sequenced: its number on its channel.
		public uint16 Id = 0;
		/// Unreliable, but a stale one is dropped at the far end (UnreliableSequenced).
		public bool Sequenced = false;
		// A large reliable message is split into pieces with CONSECUTIVE ids and a shared
		// group, so ordered delivery hands them to the receiver in order and reassembly is a
		// running append rather than a sparse buffer.
		public bool Fragmented = false;
		public uint32 FragGroup = 0;
		public uint32 FragIndex = 0;
		public uint32 FragCount = 1;
		/// Far in the past, so the first send is always due.
		public double LastSentMs = -1.0e9;
		/// Times sent. Before a round trip is measured, each resend waits twice the last.
		public uint32 SendCount = 0;
		public List<uint8> Data = new .() ~ delete _;
	}

	/// A Data packet we sent, kept until it is acked so the ack can retire its messages and
	/// sample the round trip.
	private class SentPacket
	{
		public uint16 Seq = 0;
		public double SendTimeMs = 0.0;
		public bool Acked = false;
		public List<uint16> ReliableIds = new .() ~ delete _;
	}

	/// A reliable message that arrived ahead of its turn.
	private class BufferedIn
	{
		public uint16 Id = 0;
		public uint8 Channel = 0;
		public bool Fragmented = false;
		public uint32 FragGroup = 0;
		public uint32 FragIndex = 0;
		public uint32 FragCount = 1;
		public List<uint8> Data = new .() ~ delete _;
	}

	/// The fragments of one large reliable message, accumulating. Ordered delivery means they
	/// arrive one at a time and in sequence, so one of these per connection is enough.
	private class Reassembly
	{
		public bool Active = false;
		public uint32 Group = 0;
		public uint32 NextIndex = 0;
		public uint32 Count = 0;
		public uint8 Channel = 0;
		public List<uint8> Data = new .() ~ delete _;

		public void Reset()
		{
			Active = false;
			Group = 0;
			NextIndex = 0;
			Count = 0;
			Channel = 0;
			Data.Clear();
		}
	}

	/// One queued event waiting to be drained by Poll.
	private class QueuedEvent
	{
		public NetEventKind Kind = .Received;
		public PeerId Peer = InvalidPeer;
		public uint8 Channel = 0;
		public List<uint8> Payload = new .() ~ delete _;
	}

	/// Everything known about one remote.
	private class Connection
	{
		public PeerId Peer = InvalidPeer;
		public DatagramEndpoint Remote;
		public ConnectionState State = .Connecting;
		/// The session's token, which the client picks and the server echoes: a request with
		/// another one from the same address is a new session (a client that restarted), not a
		/// resend of this one's.
		public uint32 Token = 0;

		// Outgoing sequencing and ack tracking.
		public uint16 LocalSeq = 0;
		/// The highest Data sequence received.
		public uint16 RemoteSeq = 0;
		/// Which of the thirty two packets before RemoteSeq arrived.
		public uint32 ReceivedBits = 0;
		public bool AnyReceived = false;
		/// The sent packets kept for acking, by sequence modulo the window: a slot holds the
		/// newest packet with that remainder, so an ack finds its packet without a search.
		public SentPacket[] SentWindow = new SentPacket[cSentWindowLimit] ~ DeleteContainerAndItems!(_);

		// Reliable messages.
		public uint16 NextOutReliableId = 0;
		public uint32 NextFragGroup = 0;
		public List<OutMessage> UnackedReliable = new .() ~ DeleteContainerAndItems!(_);
		public List<OutMessage> PendingUnreliable = new .() ~ DeleteContainerAndItems!(_);
		/// The next id to release upward.
		public uint16 NextInReliableId = 0;
		public List<BufferedIn> ReorderBuffer = new .() ~ DeleteContainerAndItems!(_);
		public Reassembly Reassembly = new .() ~ delete _;

		// Sequenced unreliable messages, per channel.
		public Dictionary<uint8, uint16> NextOutSequenced = new .() ~ delete _;
		/// The newest number delivered on each channel; one at or before it is stale.
		public Dictionary<uint8, uint16> LastInSequenced = new .() ~ delete _;

		// Timing.
		public double RttMs = 0.0;
		/// An ack has measured a round trip (a 0 ms one counts).
		public bool RttSampled = false;
		public double LastRecvMs = 0.0;
		public double LastSendMs = -1000.0;
		public double LastConnectSendMs = -1000.0;
		/// Client: the server's challenge, echoed until accepted.
		public uint64 Cookie = 0;
		public bool HaveCookie = false;
		/// Data arrived since our last send, so an ack is owed promptly.
		public bool AckPending = false;
		public uint32 SentBytes = 0;
		public uint32 RecvBytes = 0;
	}

	/// The window of sent packets kept for acking. Thirty two would be the minimum the ack
	/// bits can describe; this is generous so a burst does not lose ack coverage.
	private const int cSentWindowLimit = 256;
	/// Headroom for the packet header plus a message header carrying fragment fields.
	private const uint32 cFragmentHeadroom = 64;
	/// What one reliable message costs on top of its bytes, when budgeting a packet.
	private const int cReliableOverhead = 24;
	private const int cUnreliableOverhead = 12;

	private IDatagramSocket mSocket;
	private ReliableConfig mConfig;
	private bool mAccepting = false;
	private double mNowMs = 0.0;
	private PeerId mNextPeer = 1;
	private List<Connection> mConnections = new .() ~ DeleteContainerAndItems!(_);
	/// The live connections by remote and by peer: a received packet and a send find theirs
	/// without a search, so the cost per connection does not grow with their number.
	private Dictionary<DatagramEndpoint, Connection> mByRemote = new .() ~ delete _;
	private Dictionary<PeerId, Connection> mByPeer = new .() ~ delete _;
	private Sedulous.Core.Random mRandom = .FromSystemEntropy();
	/// Keys the handshake cookies; drawn once, so a cookie made by another transport, or before
	/// a restart, is not this one's.
	private uint64 mCookieSecret = 0;
	private List<QueuedEvent> mEvents = new .() ~ DeleteContainerAndItems!(_);
	private int mEventHead = 0;

	/// Scratch reused across receives, so draining a tick does not allocate per datagram.
	private List<uint8> mReceiveBuffer = new .() ~ delete _;

	public this(IDatagramSocket socket, ReliableConfig config = .())
	{
		mSocket = socket;
		mConfig = config;
		mCookieSecret = ((uint64)mRandom.NextU32() << 32) | (uint64)mRandom.NextU32();
	}

	// ---- Connection establishment ------------------------------------------------------------
	// Not part of INetTransport: the session layer above decides who connects to whom.

	/// Client: begin connecting. The returned peer is usable at once, but a Connected event
	/// only follows once the other side accepts.
	public PeerId Connect(DatagramEndpoint remote)
	{
		let connection = OpenConnection(remote);
		connection.State = .Connecting;
		connection.Token = NewToken();
		SendConnectRequest(connection);
		return connection.Peer;
	}

	/// Server: accept incoming requests. OFF by default, so a client's socket does not quietly
	/// become a server.
	public void SetAccepting(bool accepting) => mAccepting = accepting;

	// ---- INetTransport -----------------------------------------------------------------------

	public void Send(PeerId peer, uint8 channel, Span<uint8> data, Reliability reliability)
	{
		let connection = FindByPeer(peer);
		if ((connection == null) || (connection.State == .Disconnected))
			return;

		if ((uint32)data.Length > mConfig.MaxMessageBytes)
		{
			GlobalLog(.Warning, "Net: message {} B exceeds maxMessageBytes {}, dropped",
				data.Length, mConfig.MaxMessageBytes);
			return;
		}

		let limit = FragmentPayloadLimit;
		if (reliability != .ReliableOrdered)
		{
			// Unreliable messages are single datagram on purpose: fragmenting fire and forget
			// data makes no sense, because one lost piece orphans the rest with nothing to
			// ask for it again.
			if (data.Length > limit)
			{
				GlobalLog(.Warning,
					"Net: unreliable message {} B exceeds one datagram ({} B), dropped",
					data.Length, limit);
				return;
			}
			let message = new OutMessage();
			message.Channel = channel;
			message.Reliable = false;
			if (reliability == .UnreliableSequenced)
			{
				message.Sequenced = true;
				uint16 next = 0;
				connection.NextOutSequenced.TryGetValue(channel, out next);
				message.Id = next;
				connection.NextOutSequenced[channel] = (uint16)(next + 1);
			}
			message.Data.AddRange(data);
			connection.PendingUnreliable.Add(message);
			return;
		}

		// A peer that stays connected but stops acking would grow the queue without end.
		let pieces = Math.Max((data.Length + limit - 1) / limit, 1);
		if ((connection.UnackedReliable.Count + pieces) > (int)mConfig.MaxQueuedReliable)
		{
			GlobalLog(.Warning, "Net: peer {}: {} reliable messages unacked, over MaxQueuedReliable {}, disconnecting",
				connection.Peer, connection.UnackedReliable.Count, mConfig.MaxQueuedReliable);
			SendControl(connection, .Disconnect);
			connection.State = .Disconnected;
			PushEvent(.Disconnected, connection.Peer, 0, .());
			return;
		}

		if (data.Length <= limit)
		{
			let message = new OutMessage();
			message.Channel = channel;
			message.Reliable = true;
			message.Id = connection.NextOutReliableId;
			connection.NextOutReliableId++;
			message.Data.AddRange(data);
			connection.UnackedReliable.Add(message);
			return;
		}

		let fragmentCount = (uint32)((data.Length + limit - 1) / limit);
		let group = connection.NextFragGroup;
		connection.NextFragGroup++;
		for (uint32 i = 0; i < fragmentCount; i++)
		{
			let offset = (int)i * limit;
			let length = Min(limit, data.Length - offset);
			let message = new OutMessage();
			message.Channel = channel;
			message.Reliable = true;
			message.Id = connection.NextOutReliableId;
			connection.NextOutReliableId++;
			message.Fragmented = true;
			message.FragGroup = group;
			message.FragIndex = i;
			message.FragCount = fragmentCount;
			message.Data.AddRange(data.Slice(offset, length));
			connection.UnackedReliable.Add(message);
		}
	}

	public void Disconnect(PeerId peer)
	{
		let connection = FindByPeer(peer);
		if ((connection == null) || (connection.State == .Disconnected))
			return;

		SendControl(connection, .Disconnect);
		connection.State = .Disconnected;
	}

	/// Says goodbye to every connection, connected or still connecting, as Disconnect does to
	/// one: the other ends hear it at once instead of waiting out their timeout.
	public void DisconnectAll()
	{
		for (let connection in mConnections)
		{
			if (connection.State == .Disconnected)
				continue;
			SendControl(connection, .Disconnect);
			connection.State = .Disconnected;
		}
	}

	public bool Poll(NetEvent outEvent)
	{
		if (mEventHead >= mEvents.Count)
			return false;

		let entry = mEvents[mEventHead];
		mEventHead++;
		outEvent.Set(entry.Kind, entry.Peer, entry.Channel, entry.Payload);

		if (mEventHead >= mEvents.Count)
		{
			ClearAndDeleteItems!(mEvents);
			mEventHead = 0;
		}
		return true;
	}

	public void Update(float deltaMs)
	{
		mNowMs += (double)deltaMs;
		ReceiveAll();
		for (let connection in mConnections)
			UpdateConnection(connection);
		RemoveDisconnected();
	}

	public TransportStats Stats(PeerId peer)
	{
		var stats = TransportStats();
		if (let connection = FindByPeer(peer))
		{
			stats.RttMs = (float)connection.RttMs;
			stats.SentBytes = connection.SentBytes;
			stats.RecvBytes = connection.RecvBytes;
		}
		return stats;
	}

	// ---- Connection table --------------------------------------------------------------------

	/// True when seq1 is strictly newer than seq2, accounting for the sixteen bit wrap. Half
	/// the space is the boundary: past that a "newer" value is really an older one that wrapped.
	private static bool SeqGreater(uint16 seq1, uint16 seq2) =>
		((seq1 > seq2) && ((uint32)(seq1 - seq2) <= 0x8000))
		|| ((seq1 < seq2) && ((uint32)(seq2 - seq1) > 0x8000));

	/// The live connection to `remote`, or a new one. One that has disconnected is let go
	/// first, so connecting again starts a session from nothing rather than carrying the old
	/// one's sequences and message ids.
	private Connection OpenConnection(DatagramEndpoint remote)
	{
		if (let existing = FindByRemote(remote))
		{
			if (existing.State != .Disconnected)
				return existing;
			Forget(existing);
		}

		let connection = new Connection();
		connection.Peer = mNextPeer;
		mNextPeer++;
		connection.Remote = remote;
		connection.LastRecvMs = mNowMs;
		mConnections.Add(connection);
		mByRemote[remote] = connection;
		mByPeer[connection.Peer] = connection;
		return connection;
	}

	/// Takes a connection out of the lookups, so its address is free for a new one. It stays in
	/// the list (its peer finds nothing) until RemoveDisconnected deletes it.
	private void Forget(Connection connection)
	{
		if (mByRemote.TryGetValue(connection.Remote, let byRemote) && (byRemote == connection))
			mByRemote.Remove(connection.Remote);
		if (mByPeer.TryGetValue(connection.Peer, let byPeer) && (byPeer == connection))
			mByPeer.Remove(connection.Peer);
	}

	/// Deletes the connections that have disconnected. Their Disconnected events are queued
	/// already, and nothing is said on the wire for them any more.
	private void RemoveDisconnected()
	{
		for (int i = mConnections.Count - 1; i >= 0; i--)
		{
			let connection = mConnections[i];
			if (connection.State != .Disconnected)
				continue;
			Forget(connection);
			mConnections.RemoveAt(i);
			delete connection;
		}
	}

	private Connection FindByPeer(PeerId peer)
	{
		if (mByPeer.TryGetValue(peer, let connection))
			return connection;
		return null;
	}

	private Connection FindByRemote(DatagramEndpoint remote)
	{
		if (mByRemote.TryGetValue(remote, let connection))
			return connection;
		return null;
	}

	/// A session token: nonzero, and, drawn from the system's entropy, unlikely to repeat across a
	/// client's restarts.
	private uint32 NewToken()
	{
		var token = mRandom.NextU32();
		if (token == 0)
			token = 1;
		return token;
	}

	private void PushEvent(NetEventKind kind, PeerId peer, uint8 channel, Span<uint8> payload)
	{
		let entry = new QueuedEvent();
		entry.Kind = kind;
		entry.Peer = peer;
		entry.Channel = channel;
		entry.Payload.AddRange(payload);
		mEvents.Add(entry);
	}

	// ---- Sending ------------------------------------------------------------------------------

	private void RawSend(Connection connection, BitWriter writer)
	{
		let bytes = writer.Data;
		connection.SentBytes += (uint32)bytes.Length;
		mSocket.Send(connection.Remote, bytes);
		connection.LastSendMs = mNowMs;
	}

	/// Client: the request, or once challenged, the response with the server's cookie.
	private void SendConnectRequest(Connection connection)
	{
		let writer = scope BitWriter();
		writer.WriteU16(mConfig.ProtocolId);
		writer.WriteU8((uint8)(connection.HaveCookie ? PacketType.ConnectResponse : PacketType.ConnectRequest));
		writer.WriteU32(connection.Token);
		// The request's is padding, to cHandshakeBytes.
		writer.WriteU64(connection.HaveCookie ? connection.Cookie : 0);
		RawSend(connection, writer);
		connection.LastConnectSendMs = mNowMs;
	}

	/// Server: a packet to an address it holds no connection for (a challenge, a refusal).
	private void SendStateless(DatagramEndpoint to, PacketType type, uint32 token, bool withCookie,
		uint64 cookie = 0)
	{
		let writer = scope BitWriter();
		writer.WriteU16(mConfig.ProtocolId);
		writer.WriteU8((uint8)type);
		writer.WriteU32(token);
		if (withCookie)
			writer.WriteU64(cookie);
		mSocket.Send(to, writer.Data);
	}

	/// The cookie for a handshake from `remote` with `token` in cookie window `window`: a hash
	/// keyed by this transport's secret, so only an address that received the challenge can
	/// answer it.
	private uint64 Cookie(DatagramEndpoint remote, uint32 token, uint64 window)
	{
		var secret = mCookieSecret;
		var address = remote.Value;
		var tokenBytes = token;
		var windowBytes = window;
		uint8[28] input = .();
		Internal.MemCpy(&input[0], &secret, 8);
		Internal.MemCpy(&input[8], &address, 8);
		Internal.MemCpy(&input[16], &tokenBytes, 4);
		Internal.MemCpy(&input[20], &windowBytes, 8);
		var digest = Sha256.Of(.(&input[0], 28));
		uint64 cookie = 0;
		Internal.MemCpy(&cookie, &digest.Bytes[0], 8);
		return cookie;
	}

	private uint64 CookieWindow => (uint64)(mNowMs / cCookieWindowMs);

	private bool CookieValid(DatagramEndpoint remote, uint32 token, uint64 cookie)
	{
		let window = CookieWindow;
		return (cookie == Cookie(remote, token, window))
			|| ((window > 0) && (cookie == Cookie(remote, token, window - 1)));
	}

	private int LiveConnections()
	{
		int live = 0;
		for (let connection in mConnections)
		{
			if (connection.State != .Disconnected)
				live++;
		}
		return live;
	}

	/// A control packet, carrying the session's token so the far end can tell this session
	/// from an earlier one at the same address.
	private void SendControl(Connection connection, PacketType type)
	{
		let writer = scope BitWriter();
		writer.WriteU16(mConfig.ProtocolId);
		writer.WriteU8((uint8)type);
		writer.WriteU32(connection.Token);
		RawSend(connection, writer);
	}

	/// The most payload one fragment may carry, leaving room for the packet and message
	/// headers.
	private int FragmentPayloadLimit =>
		(mConfig.MaxPacketBytes > cFragmentHeadroom)
			? (int)(mConfig.MaxPacketBytes - cFragmentHeadroom) : 1;

	/// How long to wait before resending an unacked reliable: scaled to the round trip so a
	/// slow link is not flooded, and clamped so a fast one still backs off. Before a round trip
	/// is measured, InitialResendMs doubled per resend: the floor alone resent every message
	/// every 20 ms on a link whose acks had not come back yet.
	private double ResendTimeout(Connection connection, OutMessage message)
	{
		var timeout = connection.RttMs * 1.5;
		if (!connection.RttSampled)
		{
			timeout = (double)mConfig.InitialResendMs;
			for (uint32 i = 1; (i < message.SendCount) && (timeout < (double)mConfig.MaxResendMs); i++)
				timeout *= 2.0;
		}
		return Clamp(timeout, (double)mConfig.MinResendMs, (double)mConfig.MaxResendMs);
	}

	/// Whether a message is inside the send window. UnackedReliable is in id order, oldest first.
	private static bool InSendWindow(Connection connection, OutMessage message) =>
		(uint16)(message.Id - connection.UnackedReliable[0].Id) < cReliableWindow;

	private bool AnyReliableDue(Connection connection)
	{
		for (let message in connection.UnackedReliable)
		{
			if (!InSendWindow(connection, message))
				break;
			if ((mNowMs - message.LastSentMs) >= ResendTimeout(connection, message))
				return true;
		}
		return false;
	}

	/// Builds and sends one Data packet: the header, then as many DUE reliable messages and
	/// then pending unreliable ones as the byte budget allows.
	private void SendDataPacket(Connection connection)
	{
		let writer = scope BitWriter();
		writer.WriteU16(mConfig.ProtocolId);
		writer.WriteU8((uint8)PacketType.Data);
		// The session's: a packet of another session at this address is dropped.
		writer.WriteU32(connection.Token);

		let seq = connection.LocalSeq;
		connection.LocalSeq++;
		writer.WriteU16(seq);
		// Nothing received yet, nothing acked: an ack of the default sequence would retire the
		// far end's first packet, lost or not, and with it the reliable messages it carried.
		writer.WriteBool(connection.AnyReceived);
		if (connection.AnyReceived)
		{
			writer.WriteU16(connection.RemoteSeq);
			writer.WriteU32(connection.ReceivedBits);
		}

		let record = new SentPacket();
		record.Seq = seq;
		record.SendTimeMs = mNowMs;

		let chosen = scope List<OutMessage>();
		var budget = (int)mConfig.MaxPacketBytes;

		for (let message in connection.UnackedReliable)
		{
			// Past the window: it waits for the window to move.
			if (!InSendWindow(connection, message))
				break;
			// Not due yet: the round-trip-timed resend is what stops every packet from
			// carrying every outstanding message on a slow link.
			if ((mNowMs - message.LastSentMs) < ResendTimeout(connection, message))
				continue;
			if ((message.Data.Count + cReliableOverhead) > budget)
				break;
			chosen.Add(message);
			budget -= (message.Data.Count + cReliableOverhead);
			record.ReliableIds.Add(message.Id);
			message.LastSentMs = mNowMs;
			message.SendCount++;
		}

		int unreliableTaken = 0;
		for (let message in connection.PendingUnreliable)
		{
			if ((message.Data.Count + cUnreliableOverhead) > budget)
				break;
			chosen.Add(message);
			budget -= (message.Data.Count + cUnreliableOverhead);
			unreliableTaken++;
		}
		// One that fits no packet at all (unreliable messages are not fragmented) goes, rather
		// than holding the queue up for ever.
		if ((unreliableTaken == 0) && !connection.PendingUnreliable.IsEmpty
			&& ((connection.PendingUnreliable[0].Data.Count + cUnreliableOverhead) > (int)mConfig.MaxPacketBytes))
			unreliableTaken = 1;

		writer.WriteVarU32((uint32)chosen.Count);
		for (let message in chosen)
		{
			writer.WriteU8(message.Channel);
			writer.WriteBool(message.Reliable);
			if (!message.Reliable)
			{
				writer.WriteBool(message.Sequenced);
				if (message.Sequenced)
					writer.WriteU16(message.Id);
			}
			else
			{
				writer.WriteU16(message.Id);
				writer.WriteBool(message.Fragmented);
				if (message.Fragmented)
				{
					writer.WriteVarU32(message.FragGroup);
					writer.WriteVarU32(message.FragIndex);
					writer.WriteVarU32(message.FragCount);
				}
			}
			writer.WriteVarU32((uint32)message.Data.Count);
			writer.WriteBytes(message.Data);
		}

		// Unreliable is sent once. Only those this packet carried leave the queue (they were
		// written above, so they may go now); the rest go in the next packet. Dropping the
		// rest, as this once did, lost every unreliable message past the first packet's worth.
		if (unreliableTaken > 0)
		{
			for (int i < unreliableTaken)
				delete connection.PendingUnreliable[i];
			connection.PendingUnreliable.RemoveRange(0, unreliableTaken);
		}

		RecordSent(connection, record);
		RawSend(connection, writer);
	}

	private void RecordSent(Connection connection, SentPacket record)
	{
		let slot = (int)record.Seq % cSentWindowLimit;
		delete connection.SentWindow[slot];
		connection.SentWindow[slot] = record;
	}

	private void UpdateConnection(Connection connection)
	{
		if (connection.State == .Disconnected)
			return;

		if ((mNowMs - connection.LastRecvMs) > (double)mConfig.TimeoutMs)
		{
			connection.State = .Disconnected;
			PushEvent(.Disconnected, connection.Peer, 0, .());
			return;
		}

		if (connection.State == .Connecting)
		{
			if ((mNowMs - connection.LastConnectSendMs) >= (double)mConfig.ConnectResendMs)
				SendConnectRequest(connection);
			return;
		}

		// Connected: send when a reliable is due, an unreliable is queued, an ack is owed, or
		// a keepalive is due. The resend being round-trip-timed is what keeps this from
		// flooding once per tick.
		let haveWork = AnyReliableDue(connection) || !connection.PendingUnreliable.IsEmpty;
		let keepAliveDue = (mNowMs - connection.LastSendMs) >= (double)mConfig.KeepAliveMs;
		if (haveWork || connection.AckPending || keepAliveDue)
		{
			connection.AckPending = false;
			SendDataPacket(connection);
			// As many packets as the due work fills (a delta bigger than a packet, a burst), up
			// to a cap: one an update drained a big delta over several updates while the next
			// ones queued behind it, and the lag grew without end. Each reliable sent is
			// stamped, so the loop ends.
			for (uint32 more = 1; (more < mConfig.MaxPacketsPerUpdate)
				&& (AnyReliableDue(connection) || !connection.PendingUnreliable.IsEmpty); more++)
				SendDataPacket(connection);
		}
	}

	// ---- Receiving ----------------------------------------------------------------------------

	private void ReceiveAll()
	{
		while (mSocket.Receive(let from, mReceiveBuffer))
			HandlePacket(from, mReceiveBuffer);
	}

	private void HandlePacket(DatagramEndpoint from, Span<uint8> bytes)
	{
		let reader = scope BitReader(bytes);
		let protocol = reader.ReadU16();
		let typeRaw = reader.ReadU8();
		// A foreign or corrupt packet, or a type this version does not know, is dropped before
		// anything else is read from it.
		if (!reader.Ok || (protocol != mConfig.ProtocolId) || (typeRaw > (uint8)PacketType.ConnectResponse))
			return;

		let type = (PacketType)typeRaw;
		var connection = FindByRemote(from);

		// Every packet carries its session's token, Data included.
		let token = reader.ReadU32();
		if (!reader.Ok)
			return;

		switch (type)
		{
		case .ConnectRequest:
			// Nothing is kept for a request: it is answered with a challenge, which only the
			// address that sent it receives, so a spoofed request costs one packet and no peer.
			if (!mAccepting || (bytes.Length < cHandshakeBytes))
				return;
			if ((connection != null) && (connection.Token == token) && (connection.State != .Disconnected))
			{
				// Re-accept: our accept was lost, and the client is still asking.
				connection.LastRecvMs = mNowMs;
				SendControl(connection, .ConnectAccept);
				return;
			}
			SendStateless(from, .Challenge, token, true, Cookie(from, token, CookieWindow));
			return;

		case .Challenge:
			let challengeCookie = reader.ReadU64();
			if (!reader.Ok || (connection == null) || (connection.Token != token)
				|| (connection.State != .Connecting))
				return;
			connection.Cookie = challengeCookie;
			connection.HaveCookie = true;
			// The response, now.
			SendConnectRequest(connection);
			return;

		case .ConnectResponse:
			let responseCookie = reader.ReadU64();
			if (!mAccepting || !reader.Ok || !CookieValid(from, token, responseCookie))
				return;
			if ((connection != null) && (connection.Token == token) && (connection.State != .Disconnected))
			{
				// Re-accept: our first accept was lost, and the client is still asking.
				connection.LastRecvMs = mNowMs;
				SendControl(connection, .ConnectAccept);
				return;
			}
			let replaces = (connection != null) && (connection.State != .Disconnected);
			if (!replaces && (LiveConnections() >= (int)mConfig.MaxPeers))
			{
				// Full: the client hears it and stops trying.
				SendStateless(from, .Disconnect, token, false);
				return;
			}
			if (replaces)
			{
				// Another session from the same address (the client restarted, or connected
				// again): the old one is over, and its state must not carry into the new one.
				connection.State = .Disconnected;
				PushEvent(.Disconnected, connection.Peer, 0, .());
			}
			let opened = OpenConnection(from);
			opened.State = .Connected;
			opened.Token = token;
			opened.LastRecvMs = mNowMs;
			SendControl(opened, .ConnectAccept);
			PushEvent(.Connected, opened.Peer, 0, .());
			return;

		case .ConnectAccept:
			// An accept for an earlier session (a late one, or a resend) is not this one's.
			if ((connection == null) || (connection.Token != token))
				return;
			connection.LastRecvMs = mNowMs;
			if (connection.State == .Connecting)
			{
				connection.State = .Connected;
				PushEvent(.Connected, connection.Peer, 0, .());
			}
			return;

		case .Disconnect:
			if ((connection != null) && (connection.Token == token) && (connection.State != .Disconnected))
			{
				connection.State = .Disconnected;
				PushEvent(.Disconnected, connection.Peer, 0, .());
			}
			return;

		case .Data:
			break;
		}

		if ((connection == null) || (connection.State == .Disconnected) || (connection.Token != token))
			return;

		connection.RecvBytes += (uint32)bytes.Length;
		connection.LastRecvMs = mNowMs;
		connection.AckPending = true;

		let seq = reader.ReadU16();
		let hasAck = reader.ReadBool();
		uint16 ack = 0;
		uint32 ackBits = 0;
		if (hasAck)
		{
			ack = reader.ReadU16();
			ackBits = reader.ReadU32();
		}
		if (!reader.Ok)
			return;

		if (hasAck)
			ProcessAcks(connection, ack, ackBits);
		UpdateReceivedHistory(connection, seq);

		let count = reader.ReadVarU32();
		for (uint32 i = 0; (i < count) && reader.Ok; i++)
		{
			let channel = reader.ReadU8();
			let reliable = reader.ReadBool();
			uint16 id = 0;
			var sequenced = false;
			var fragmented = false;
			uint32 fragGroup = 0;
			uint32 fragIndex = 0;
			uint32 fragCount = 1;
			if (!reliable)
			{
				sequenced = reader.ReadBool();
				if (sequenced)
					id = reader.ReadU16();
			}
			else
			{
				id = reader.ReadU16();
				fragmented = reader.ReadBool();
				if (fragmented)
				{
					fragGroup = reader.ReadVarU32();
					fragIndex = reader.ReadVarU32();
					fragCount = reader.ReadVarU32();
				}
			}

			let length = reader.ReadVarU32();
			// One message fits one datagram by construction, so a longer claim is a corrupt
			// or hostile packet and the rest of it is not worth reading.
			if (!reader.Ok || (length > mConfig.MaxPacketBytes))
				return;

			let payload = scope List<uint8>();
			payload.Count = (int)length;
			if (length > 0)
				reader.ReadBytes(payload);
			if (!reader.Ok)
				return;

			if (reliable)
				DeliverReliable(connection, id, channel, fragmented, fragGroup, fragIndex,
					fragCount, payload);
			else if (!sequenced || TakeSequenced(connection, channel, id))
				PushEvent(.Received, connection.Peer, channel, payload);
		}
	}

	/// Retires sent packets named by the ack and its history, acks their reliable messages and
	/// samples the round trip.
	private void ProcessAcks(Connection connection, uint16 ack, uint32 ackBits)
	{
		AckOne(connection, ack);
		for (uint32 bit = 0; bit < 32; bit++)
		{
			if ((ackBits & ((uint32)1 << bit)) != 0)
				AckOne(connection, (uint16)(ack - (bit + 1)));
		}
	}

	private void AckOne(Connection connection, uint16 seq)
	{
		let packet = connection.SentWindow[(int)seq % cSentWindowLimit];
		if ((packet == null) || (packet.Seq != seq) || packet.Acked)
			return;

		packet.Acked = true;
		let sample = mNowMs - packet.SendTimeMs;
		// A running average rather than the latest sample, so one delayed ack does not
		// swing the resend timing.
		connection.RttMs = !connection.RttSampled
			? sample : (connection.RttMs * 0.9 + sample * 0.1);
		connection.RttSampled = true;
		for (let messageId in packet.ReliableIds)
			AckReliableMessage(connection, messageId);
	}

	/// Whether a sequenced message numbered `id` is newer than the last delivered on its
	/// channel, noting it if so. A stale one (reordered behind a newer one, or duplicated) is
	/// dropped.
	private bool TakeSequenced(Connection connection, uint8 channel, uint16 id)
	{
		if (connection.LastInSequenced.TryGetValue(channel, let last) && !SeqGreater(id, last))
			return false;
		connection.LastInSequenced[channel] = id;
		return true;
	}

	private void AckReliableMessage(Connection connection, uint16 id)
	{
		for (int i = 0; i < connection.UnackedReliable.Count; i++)
		{
			if (connection.UnackedReliable[i].Id == id)
			{
				delete connection.UnackedReliable[i];
				connection.UnackedReliable.RemoveAt(i);
				return;
			}
		}
	}

	/// Folds one received sequence into the ack history the next outgoing packet reports.
	private void UpdateReceivedHistory(Connection connection, uint16 seq)
	{
		if (!connection.AnyReceived)
		{
			connection.AnyReceived = true;
			connection.RemoteSeq = seq;
			connection.ReceivedBits = 0;
			return;
		}

		if (SeqGreater(seq, connection.RemoteSeq))
		{
			let shift = (uint16)(seq - connection.RemoteSeq);
			// A jump of thirty two or more leaves nothing of the old history to keep.
			connection.ReceivedBits = (shift >= 32)
				? 0 : ((connection.ReceivedBits << shift) | ((uint32)1 << (shift - 1)));
			connection.RemoteSeq = seq;
		}
		else
		{
			let difference = (uint16)(connection.RemoteSeq - seq);
			if ((difference >= 1) && (difference <= 32))
				connection.ReceivedBits |= ((uint32)1 << (difference - 1));
		}
	}

	// ---- Ordered reliable delivery --------------------------------------------------------------

	/// Releases in id order, buffering what arrives early and dropping what arrives twice.
	private void DeliverReliable(Connection connection, uint16 id, uint8 channel, bool fragmented,
		uint32 fragGroup, uint32 fragIndex, uint32 fragCount, Span<uint8> payload)
	{
		// Already delivered: a resend that crossed with our ack.
		if (SeqGreater(connection.NextInReliableId, id)
			|| (id == (uint16)(connection.NextInReliableId - 1)))
			return;

		if (id != connection.NextInReliableId)
		{
			// Early: buffer it unless it is already buffered, or past the window, which a sender
			// keeping to it never sends (the buffer is bounded by the window, not by the peer).
			if ((uint16)(id - connection.NextInReliableId) >= cReliableWindow)
				return;
			for (let buffered in connection.ReorderBuffer)
			{
				if (buffered.Id == id)
					return;
			}
			let entry = new BufferedIn();
			entry.Id = id;
			entry.Channel = channel;
			entry.Fragmented = fragmented;
			entry.FragGroup = fragGroup;
			entry.FragIndex = fragIndex;
			entry.FragCount = fragCount;
			entry.Data.AddRange(payload);
			connection.ReorderBuffer.Add(entry);
			return;
		}

		ReleaseMessage(connection, channel, fragmented, fragGroup, fragIndex, fragCount, payload);
		connection.NextInReliableId++;

		// Whatever was waiting on this one can now go too.
		for (;;)
		{
			var released = false;
			for (int i = 0; i < connection.ReorderBuffer.Count; i++)
			{
				let buffered = connection.ReorderBuffer[i];
				if (buffered.Id != connection.NextInReliableId)
					continue;

				connection.ReorderBuffer.RemoveAt(i);
				ReleaseMessage(connection, buffered.Channel, buffered.Fragmented,
					buffered.FragGroup, buffered.FragIndex, buffered.FragCount, buffered.Data);
				delete buffered;
				connection.NextInReliableId++;
				released = true;
				break;
			}
			if (!released)
				break;
		}
	}

	/// One reliable message, in order. A whole message is delivered as it is; a fragment is
	/// appended to the reassembly and the whole goes up when the last one lands.
	private void ReleaseMessage(Connection connection, uint8 channel, bool fragmented,
		uint32 fragGroup, uint32 fragIndex, uint32 fragCount, Span<uint8> payload)
	{
		if (!fragmented)
		{
			PushEvent(.Received, connection.Peer, channel, payload);
			return;
		}

		let reassembly = connection.Reassembly;
		if (fragIndex == 0)
		{
			reassembly.Reset();
			reassembly.Active = true;
			reassembly.Group = fragGroup;
			reassembly.Count = fragCount;
			reassembly.Channel = channel;
		}

		// Out of sequence, which ordered delivery should have made impossible. Dropped rather
		// than stitched into the wrong message.
		if (!reassembly.Active || (reassembly.Group != fragGroup)
			|| (reassembly.NextIndex != fragIndex))
		{
			reassembly.Active = false;
			return;
		}

		reassembly.Data.AddRange(payload);
		reassembly.NextIndex++;
		if (reassembly.NextIndex >= reassembly.Count)
		{
			PushEvent(.Received, connection.Peer, reassembly.Channel, reassembly.Data);
			reassembly.Reset();
		}
	}
}
