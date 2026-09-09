using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Net;

/// A deterministic in memory link joining two endpoints, with injectable conditions.
///
/// This is what makes rolling our own transport safe: latency, jitter, loss, reorder and
/// duplication under a SEEDED generator and a MANUAL clock, so the reliability and
/// replication layers above become headless unit tests with no sockets and no flake.
///
/// The link OWNS both endpoints.
class LoopbackLink
{
	/// The remote peer id each side sees. A pair has exactly one remote, so it is always one.
	public const PeerId RemotePeer = 1;

	/// A packet waiting for its delivery time.
	private class InFlight
	{
		public uint32 DestinationSide = 0;
		public uint8 Channel = 0;
		public List<uint8> Data = new .() ~ delete _;
		public double DeliverAt = 0.0;
		/// Breaks a tie between two packets due at the same instant, keeping delivery first
		/// in first out.
		public uint64 Order = 0;
	}

	private SimConditions mSim;
	private Sedulous.Core.Random mRng;
	private double mNowMs = 0.0;
	private uint64 mOrderCounter = 0;
	private List<InFlight> mInFlight = new .() ~ DeleteContainerAndItems!(_);
	private LoopbackEndpoint mA ~ delete _;
	private LoopbackEndpoint mB ~ delete _;

	public this(SimConditions sim = .())
	{
		mSim = sim;
		mRng = .(sim.Seed);
		mA = new .(this, 0);
		mB = new .(this, 1);

		// Both sides see the connection at once. A real handshake belongs to the session
		// layer; a pair that exists is already connected.
		DeliverControl(0, .Connected);
		DeliverControl(1, .Connected);
	}

	public INetTransport A => mA;
	public INetTransport B => mB;

	public SimConditions Sim => mSim;
	public void SetSim(SimConditions sim) => mSim = sim;

	/// Advances the clock and delivers everything whose time has come, in delivery order.
	public void Advance(float deltaMs)
	{
		mNowMs += (double)deltaMs;
		while (!mInFlight.IsEmpty && (mInFlight[0].DeliverAt <= mNowMs))
		{
			let packet = mInFlight[0];
			mInFlight.RemoveAt(0);

			Side(packet.DestinationSide).[Friend]Deliver(.Received, RemotePeer, packet.Channel,
				packet.Data);
			delete packet;
		}
	}

	private LoopbackEndpoint Side(uint32 side) => (side == 0) ? mA : mB;

	private void DeliverControl(uint32 side, NetEventKind kind)
	{
		Side(side).[Friend]Deliver(kind, RemotePeer, 0, .());
	}

	/// The heart of the sim: apply loss, duplication and reorder, then latency and jitter, and
	/// queue.
	///
	/// The impairments apply to UNRELIABLE channels only. A reliable channel is a
	/// guaranteed-delivery abstraction at this level; the real ack and resend behaviour lives
	/// in ReliableTransport, which is tested over the lossy datagram sim instead.
	private void Submit(uint32 sourceSide, uint8 channel, Span<uint8> data,
		Reliability reliability)
	{
		let destinationSide = (sourceSide == 0) ? (uint32)1 : (uint32)0;
		Side(sourceSide).[Friend]AddSentBytes(data.Length);

		let unreliable = (reliability != .ReliableOrdered);
		if (unreliable && Chance(mSim.LossPct))
			return;

		var deliverAt = mNowMs + (double)Max(0.0f, mSim.LatencyMs + Jitter());
		if (unreliable && Chance(mSim.ReorderPct))
			deliverAt += (double)(mRng.NextFloat() * Max(1.0f, mSim.LatencyMs));

		Enqueue(destinationSide, channel, data, deliverAt);

		if (unreliable && Chance(mSim.DupPct))
			Enqueue(destinationSide, channel, data, deliverAt + (double)mRng.NextFloat());
	}

	/// Inserts keeping the queue ordered by delivery time, then by order.
	private void Enqueue(uint32 destinationSide, uint8 channel, Span<uint8> data, double deliverAt)
	{
		let packet = new InFlight();
		packet.DestinationSide = destinationSide;
		packet.Channel = channel;
		packet.Data.AddRange(data);
		packet.DeliverAt = deliverAt;
		packet.Order = mOrderCounter;
		mOrderCounter++;

		var index = mInFlight.Count;
		while (index > 0)
		{
			let previous = mInFlight[index - 1];
			if ((previous.DeliverAt < deliverAt)
				|| ((previous.DeliverAt == deliverAt) && (previous.Order < packet.Order)))
				break;
			index--;
		}
		mInFlight.Insert(index, packet);
	}

	private bool Chance(float pct) => (pct > 0.0f) && (mRng.NextFloat() < pct);

	private float Jitter() =>
		(mSim.JitterMs > 0.0f) ? ((mRng.NextFloat() * 2.0f - 1.0f) * mSim.JitterMs) : 0.0f;
}
