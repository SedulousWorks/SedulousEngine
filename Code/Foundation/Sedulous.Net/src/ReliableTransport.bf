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
/// through (SEQUENCED ones numbered per channel, a stale one dropped), a connect and accept
/// handshake that tells a new session from the same address apart by its token, and keepalive
/// and timeout.
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
	}

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
		public double LastRecvMs = 0.0;
		public double LastSendMs = -1000.0;
		public double LastConnectSendMs = -1000.0;
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
	private List<QueuedEvent> mEvents = new .() ~ DeleteContainerAndItems!(_);
	private int mEventHead = 0;

	/// Scratch reused across receives, so draining a tick does not allocate per datagram.
	private List<uint8> mReceiveBuffer = new .() ~ delete _;

	public this(IDatagramSocket socket, ReliableConfig config = .())
	{
		mSocket = socket;
		mConfig = config;
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

	private void SendConnectRequest(Connection connection)
	{
		SendControl(connection, .ConnectRequest);
		connection.LastConnectSendMs = mNowMs;
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
	/// slow link is not flooded, and clamped so a fast one still backs off.
	private double ResendTimeout(Connection connection)
	{
		// `base` is a Beef keyword, so the local is named for what it is.
		let scaled = (connection.RttMs > 0.0)
			? (connection.RttMs * 1.5) : (double)mConfig.MinResendMs;
		return Clamp(scaled, (double)mConfig.MinResendMs, (double)mConfig.MaxResendMs);
	}

	private bool AnyReliableDue(Connection connection)
	{
		let timeout = ResendTimeout(connection);
		for (let message in connection.UnackedReliable)
		{
			if ((mNowMs - message.LastSentMs) >= timeout)
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
		let resendTimeout = ResendTimeout(connection);

		for (let message in connection.UnackedReliable)
		{
			// Not due yet: the round-trip-timed resend is what stops every packet from
			// carrying every outstanding message on a slow link.
			if ((mNowMs - message.LastSentMs) < resendTimeout)
				continue;
			if ((message.Data.Count + cReliableOverhead) > budget)
				break;
			chosen.Add(message);
			budget -= (message.Data.Count + cReliableOverhead);
			record.ReliableIds.Add(message.Id);
			message.LastSentMs = mNowMs;
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
		// A foreign or corrupt packet is dropped before anything else is read from it.
		if (!reader.Ok || (protocol != mConfig.ProtocolId))
			return;

		let type = (PacketType)typeRaw;
		var connection = FindByRemote(from);

		uint32 token = 0;
		if (type != .Data)
		{
			token = reader.ReadU32();
			if (!reader.Ok)
				return;
		}

		switch (type)
		{
		case .ConnectRequest:
			if (!mAccepting)
				return;
			if ((connection != null) && (connection.Token == token) && (connection.State != .Disconnected))
			{
				// Re-accept: our first accept was lost, and the client is still asking.
				connection.LastRecvMs = mNowMs;
				SendControl(connection, .ConnectAccept);
				return;
			}
			if ((connection != null) && (connection.State != .Disconnected))
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

		if ((connection == null) || (connection.State == .Disconnected))
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
		connection.RttMs = (connection.RttMs <= 0.0)
			? sample : (connection.RttMs * 0.9 + sample * 0.1);
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
			// Early: buffer it unless it is already buffered.
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
