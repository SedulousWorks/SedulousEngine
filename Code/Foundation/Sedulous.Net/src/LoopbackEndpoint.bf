using System;
using System.Collections;

namespace Sedulous.Net;

/// One side of an in memory connected pair.
///
/// Send hands the packet to the shared link, which applies the conditions when its clock
/// advances; Poll drains what the link has delivered to this side. OWNED by its link.
class LoopbackEndpoint : INetTransport
{
	/// A delivered event waiting to be drained.
	private class Queued
	{
		public NetEventKind Kind = .Received;
		public PeerId Peer = InvalidPeer;
		public uint8 Channel = 0;
		public List<uint8> Payload = new .() ~ delete _;
	}

	private LoopbackLink mLink;
	/// Nought or one. Which half of the pair this is.
	private uint32 mSide = 0;
	private List<Queued> mReceived = new .() ~ DeleteContainerAndItems!(_);
	private int mReceivedHead = 0;
	private TransportStats mStats = .();

	public this(LoopbackLink link, uint32 side)
	{
		mLink = link;
		mSide = side;
	}

	public void Send(PeerId peer, uint8 channel, Span<uint8> data, Reliability reliability)
	{
		// A pair has exactly one remote, so which peer is asked for does not matter.
		if (mLink != null)
			mLink.[Friend]Submit(mSide, channel, data, reliability);
	}

	public void Disconnect(PeerId peer)
	{
		if (mLink == null)
			return;
		let other = (mSide == 0) ? (uint32)1 : (uint32)0;
		mLink.[Friend]DeliverControl(other, .Disconnected);
	}

	public bool Poll(NetEvent outEvent)
	{
		if (mReceivedHead >= mReceived.Count)
			return false;

		let entry = mReceived[mReceivedHead];
		mReceivedHead++;
		outEvent.Set(entry.Kind, entry.Peer, entry.Channel, entry.Payload);

		if (mReceivedHead >= mReceived.Count)
		{
			ClearAndDeleteItems!(mReceived);
			mReceivedHead = 0;
		}
		return true;
	}

	/// Delegates the clock to the shared link, so advancing either side advances the pair.
	public void Update(float deltaMs)
	{
		if (mLink != null)
			mLink.Advance(deltaMs);
	}

	public TransportStats Stats(PeerId peer)
	{
		var stats = mStats;
		// A round trip is two one way latencies. The sim has no measurement to make, so this
		// is what the conditions say it is rather than an estimate.
		if (mLink != null)
			stats.RttMs = 2.0f * mLink.Sim.LatencyMs;
		return stats;
	}

	/// The link hands a delivered event over. The queue entry is built HERE, so the entry type
	/// stays this endpoint's business.
	private void Deliver(NetEventKind kind, PeerId peer, uint8 channel, Span<uint8> payload)
	{
		let entry = new Queued();
		entry.Kind = kind;
		entry.Peer = peer;
		entry.Channel = channel;
		entry.Payload.AddRange(payload);
		mReceived.Add(entry);
	}

	private void AddSentBytes(int count) => mStats.SentBytes += (uint32)count;
}
