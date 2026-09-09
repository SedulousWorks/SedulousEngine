using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Net;

/// Roles, a peer registry and the connect and disconnect lifecycle over the reliable
/// transport.
///
/// This is what a game talks to: the server tracks its clients, the client tracks its one
/// server, and Broadcast fans a message out. RPC and replication build on it rather than on
/// the transport.
///
/// The session OWNS its transport but BORROWS the socket underneath.
class NetSession
{
	/// Reserved for session-internal control. It never surfaces as a user event, so games use
	/// nought to two hundred and fifty three (RPC takes two hundred and fifty four).
	public const uint8 ControlChannel = 255;

	private enum ControlType : uint8
	{
		case TimeSync = 0;
	}

	private ReliableTransport mTransport ~ delete _;
	private NetRole mRole = .None;
	private PeerId mServerPeer = InvalidPeer;
	private double mNowMs = 0.0;
	private List<NetPeer> mPeers = new .() ~ delete _;

	/// Events held for the caller's own drain, after the session has taken its cut.
	private List<NetEvent> mEvents = new .() ~ DeleteContainerAndItems!(_);
	private int mEventHead = 0;
	/// Reused across the transport drain, so a busy tick does not allocate per packet.
	private NetEvent mScratchEvent = new .() ~ delete _;

	// Clock sync.
	/// Twenty hertz, which is a turn-based-appropriate network tick.
	private float mFixedStepMs = 50.0f;
	private float mSyncIntervalMs = 250.0f;
	private double mLastSyncSendMs = -1.0e9;
	/// Client only: network time is local time plus this.
	private double mTimeOffsetMs = 0.0;
	private bool mHasSync = false;

	public this(IDatagramSocket socket, ReliableConfig config = .())
	{
		mTransport = new .(socket, config);
	}

	/// Server: begin accepting. Dedicated means headless, with no local player.
	public void StartServer(bool dedicated = false)
	{
		mRole = dedicated ? .DedicatedServer : .ListenServer;
		mTransport.SetAccepting(true);
	}

	/// Client: connect. The returned peer is the server's; a Connected event confirms it.
	public PeerId Connect(DatagramEndpoint server)
	{
		mRole = .Client;
		mServerPeer = mTransport.Connect(server);
		return mServerPeer;
	}

	// ---- Messaging ----------------------------------------------------------------------------

	public void Send(PeerId peer, uint8 channel, Span<uint8> data, Reliability reliability) =>
		mTransport.Send(peer, channel, data, reliability);

	/// Server: to every connected peer.
	public void Broadcast(uint8 channel, Span<uint8> data, Reliability reliability)
	{
		for (let peer in mPeers)
			mTransport.Send(peer.Id, channel, data, reliability);
	}

	/// Server: to everyone but one, which is how an order is echoed to the other clients
	/// without bouncing back to its author.
	public void BroadcastExcept(PeerId except, uint8 channel, Span<uint8> data,
		Reliability reliability)
	{
		for (let peer in mPeers)
		{
			if (peer.Id != except)
				mTransport.Send(peer.Id, channel, data, reliability);
		}
	}

	public void Disconnect(PeerId peer) => mTransport.Disconnect(peer);

	// ---- Pump ---------------------------------------------------------------------------------

	public void Update(float deltaMs)
	{
		mNowMs += (double)deltaMs;
		mTransport.Update(deltaMs);

		while (mTransport.Poll(mScratchEvent))
		{
			if (mScratchEvent.Kind == .Connected)
				AddPeer(mScratchEvent.Peer);
			else if (mScratchEvent.Kind == .Disconnected)
				RemovePeer(mScratchEvent.Peer);
			else if ((mScratchEvent.Kind == .Received)
				&& (mScratchEvent.Channel == ControlChannel))
			{
				// Consumed here: control is the session's own traffic and never reaches the
				// game.
				HandleControl(mScratchEvent);
				continue;
			}

			let queued = new NetEvent();
			queued.Set(mScratchEvent.Kind, mScratchEvent.Peer, mScratchEvent.Channel,
				mScratchEvent.Payload);
			mEvents.Add(queued);
		}

		// Server: broadcast the authoritative clock so clients can align their tick to it.
		if (IsServer && !mPeers.IsEmpty
			&& ((mNowMs - mLastSyncSendMs) >= (double)mSyncIntervalMs))
		{
			mLastSyncSendMs = mNowMs;
			let writer = scope BitWriter();
			writer.WriteU8((uint8)ControlType.TimeSync);
			writer.WriteDouble(mNowMs);
			// Unreliable, because the next sync supersedes this one: a resent stale clock is
			// worse than a missed one.
			Broadcast(ControlChannel, writer.Data, .Unreliable);
		}
	}

	/// Fills outEvent with one session event. False when none remain.
	public bool PollEvent(NetEvent outEvent)
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

	// ---- Clock ---------------------------------------------------------------------------------

	public void SetFixedStepMs(float stepMs) => mFixedStepMs = (stepMs > 0.0f) ? stepMs : 1.0f;
	public void SetTimeSyncIntervalMs(float ms) => mSyncIntervalMs = ms;

	/// The server's authoritative time. On the server it IS the local time; on a client it is
	/// the local time plus the offset estimated from the server's syncs.
	public double NetworkTimeMs => IsServer ? mNowMs : (mNowMs + mTimeOffsetMs);

	/// The synced tick number, which is what puts clients in the server's lane.
	public uint64 NetworkTick
	{
		get
		{
			let time = NetworkTimeMs;
			return (time > 0.0) ? (uint64)(time / (double)mFixedStepMs) : 0;
		}
	}

	/// Client: whether any server sync has landed. Until then the network time is local only.
	public bool HasClockSync => mHasSync;

	// ---- Queries --------------------------------------------------------------------------------

	public NetRole Role => mRole;
	public bool IsServer => (mRole == .ListenServer) || (mRole == .DedicatedServer);
	public bool IsClient => mRole == .Client;
	public Span<NetPeer> Peers => mPeers;
	public int PeerCount => mPeers.Count;
	/// Client side: the server's peer.
	public PeerId ServerPeer => mServerPeer;
	public TransportStats Stats(PeerId peer) => mTransport.Stats(peer);
	public ReliableTransport Transport => mTransport;

	// ---- Internals -------------------------------------------------------------------------------

	private void AddPeer(PeerId id)
	{
		for (let peer in mPeers)
		{
			if (peer.Id == id)
				return;
		}
		mPeers.Add(.(id, mNowMs));
	}

	private void RemovePeer(PeerId id)
	{
		for (int i = 0; i < mPeers.Count; i++)
		{
			if (mPeers[i].Id == id)
			{
				mPeers.RemoveAt(i);
				return;
			}
		}
	}

	private void HandleControl(NetEvent event)
	{
		let reader = scope BitReader(event.Payload);
		let type = reader.ReadU8();
		if (!reader.Ok)
			return;

		if (((ControlType)type != .TimeSync) || IsServer)
			return;

		let serverTime = reader.ReadDouble();
		if (!reader.Ok)
			return;

		// The sync took about half a round trip to arrive, so the server's clock has moved on
		// by that much since it was stamped.
		let rtt = (double)mTransport.Stats(event.Peer).RttMs;
		let estimatedServerNow = serverTime + rtt * 0.5;
		let sample = estimatedServerNow - mNowMs;
		// Smoothed after the first, so jitter on one sync does not jump the clock.
		mTimeOffsetMs = mHasSync ? (mTimeOffsetMs * 0.9 + sample * 0.1) : sample;
		mHasSync = true;
	}
}
