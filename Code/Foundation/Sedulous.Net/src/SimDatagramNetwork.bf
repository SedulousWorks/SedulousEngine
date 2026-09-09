using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Net;

/// A deterministic in memory datagram network: it hands out sockets with unique endpoints and
/// routes datagrams between them under injectable conditions.
///
/// LOSSY ON PURPOSE. This is the reliability layer's test harness, and a seeded generator plus
/// a manual clock is what turns "works most of the time" into a repeatable failure.
class SimDatagramNetwork
{
	/// A datagram waiting for its delivery time.
	private class InFlight
	{
		public DatagramEndpoint From;
		public DatagramEndpoint To;
		public List<uint8> Data = new .() ~ delete _;
		public double DeliverAt = 0.0;
		/// Breaks a tie between two datagrams due at the same instant, so delivery stays
		/// first in first out rather than depending on the sort.
		public uint64 Order = 0;
	}

	private SimConditions mSim;
	private Sedulous.Core.Random mRng;
	private double mNowMs = 0.0;
	private uint64 mNextEndpoint = 1;
	private uint64 mOrderCounter = 0;
	/// Ordered by delivery time, then by order.
	private List<InFlight> mInFlight = new .() ~ DeleteContainerAndItems!(_);
	private List<SimDatagramSocket> mSockets = new .() ~ DeleteContainerAndItems!(_);

	public this(SimConditions sim = .())
	{
		mSim = sim;
		mRng = .(sim.Seed);
	}

	public SimConditions Sim => mSim;

	/// Replaces the conditions. Datagrams already in flight keep the times they were given.
	public void SetSim(SimConditions sim) => mSim = sim;

	/// A socket with a fresh endpoint. The network OWNS it; the caller borrows.
	public IDatagramSocket CreateSocket()
	{
		let socket = new SimDatagramSocket(this, .(mNextEndpoint));
		mNextEndpoint++;
		mSockets.Add(socket);
		return socket;
	}

	/// Advances the clock and delivers everything whose time has come, in delivery order.
	public void Advance(float deltaMs)
	{
		mNowMs += (double)deltaMs;
		while (!mInFlight.IsEmpty && (mInFlight[0].DeliverAt <= mNowMs))
		{
			let packet = mInFlight[0];
			mInFlight.RemoveAt(0);

			// A datagram to an endpoint nobody is listening on is simply lost, which is
			// what a real network does with it too.
			if (let destination = Find(packet.To))
				destination.[Friend]Deliver(packet.From, packet.Data);
			delete packet;
		}
	}

	private SimDatagramSocket Find(DatagramEndpoint endpoint)
	{
		for (let socket in mSockets)
		{
			if (socket.LocalEndpoint == endpoint)
				return socket;
		}
		return null;
	}

	/// Every datagram is subject to loss, reorder and duplication: this IS the unreliable
	/// layer, and nothing above it may assume otherwise.
	private void Route(DatagramEndpoint from, DatagramEndpoint to, Span<uint8> data)
	{
		if (Chance(mSim.LossPct))
			return;

		var deliverAt = mNowMs + (double)Max(0.0f, mSim.LatencyMs + Jitter());
		if (Chance(mSim.ReorderPct))
		{
			// An extra delay of up to one latency, which is what lets this arrive after a
			// datagram sent later.
			deliverAt += (double)(mRng.NextFloat() * Max(1.0f, mSim.LatencyMs));
		}
		Enqueue(from, to, data, deliverAt);

		if (Chance(mSim.DupPct))
			Enqueue(from, to, data, deliverAt + (double)mRng.NextFloat());
	}

	/// Inserts keeping the queue ordered by delivery time, then by order.
	private void Enqueue(DatagramEndpoint from, DatagramEndpoint to, Span<uint8> data,
		double deliverAt)
	{
		let packet = new InFlight();
		packet.From = from;
		packet.To = to;
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
