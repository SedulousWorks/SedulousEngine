using System;
using System.Collections;
using Sedulous.Net;

namespace Sedulous.Net.Tests;

/// The loopback sim transport: deterministic latency, loss, reorder and duplication.
class TransportTests
{
	/// Drains everything queued, returning the first byte of each Received payload and
	/// counting the rest.
	private static int Drain(INetTransport transport, List<uint8> outFirstBytes = null)
	{
		var count = 0;
		let event = scope NetEvent();
		while (transport.Poll(event))
		{
			count++;
			if ((outFirstBytes != null) && (event.Kind == .Received) && !event.Payload.IsEmpty)
				outFirstBytes.Add(event.Payload[0]);
		}
		return count;
	}

	private static bool AnyKind(INetTransport transport, NetEventKind kind)
	{
		var found = false;
		let event = scope NetEvent();
		while (transport.Poll(event))
		{
			if (event.Kind == kind)
				found = true;
		}
		return found;
	}

	[Test]
	public static void BothSidesSeeConnectedWhenTheLinkIsMade()
	{
		let link = scope LoopbackLink();
		let event = scope NetEvent();

		Test.Assert(link.A.Poll(event));
		Test.Assert(event.Kind == .Connected);
		Test.Assert(event.Peer == LoopbackLink.RemotePeer);
		Test.Assert(!link.A.Poll(event));

		Test.Assert(link.B.Poll(event));
		Test.Assert(event.Kind == .Connected);
	}

	[Test]
	public static void AMessageArrivesAfterItsLatencyAndNotBefore()
	{
		var sim = SimConditions();
		sim.LatencyMs = 50.0f;
		let link = scope LoopbackLink(sim);
		Drain(link.A);
		Drain(link.B);

		let message = scope uint8[](0xDE, 0xAD, 0xBE, 0xEF);
		link.A.Send(LoopbackLink.RemotePeer, 0, message, .ReliableOrdered);

		link.Advance(30.0f);
		Test.Assert(Drain(link.B) == 0);

		link.Advance(30.0f);
		let event = scope NetEvent();
		Test.Assert(link.B.Poll(event));
		Test.Assert(event.Kind == .Received);
		Test.Assert(event.Payload.Count == 4);
		Test.Assert(event.Payload[0] == 0xDE);
		Test.Assert(event.Payload[3] == 0xEF);
	}

	[Test]
	public static void TheReliableChannelSurvivesTotalLoss()
	{
		var sim = SimConditions();
		// Everything droppable is dropped, and a reliable message is not droppable HERE: the
		// loopback treats reliability as guaranteed, and the real ack and resend behaviour is
		// exercised against the datagram sim instead.
		sim.LossPct = 1.0f;
		let link = scope LoopbackLink(sim);
		Drain(link.A);
		Drain(link.B);

		for (int i = 0; i < 10; i++)
		{
			let message = scope uint8[]((uint8)i);
			link.A.Send(LoopbackLink.RemotePeer, 0, message, .ReliableOrdered);
		}
		link.Advance(1.0f);
		Test.Assert(Drain(link.B) == 10);
	}

	[Test]
	public static void TheUnreliableChannelDropsUnderLossAndIsReproducible()
	{
		var sim = SimConditions();
		sim.LossPct = 0.5f;
		sim.Seed = 42;

		let first = CountUnreliableDelivered(sim);
		Test.Assert(first > 0);
		Test.Assert(first < 100);
		Test.Assert(CountUnreliableDelivered(sim) == first);
	}

	private static int CountUnreliableDelivered(SimConditions sim)
	{
		let link = scope LoopbackLink(sim);
		Drain(link.A);
		Drain(link.B);

		for (int i = 0; i < 100; i++)
		{
			let message = scope uint8[]((uint8)i);
			link.A.Send(LoopbackLink.RemotePeer, 0, message, .Unreliable);
		}
		link.Advance(1.0f);
		return Drain(link.B);
	}

	[Test]
	public static void ReorderCanDeliverUnreliableOutOfOrder()
	{
		var sim = SimConditions();
		sim.LatencyMs = 20.0f;
		sim.ReorderPct = 1.0f;
		sim.Seed = 7;
		let link = scope LoopbackLink(sim);
		Drain(link.A);
		Drain(link.B);

		for (uint8 i = 0; i < 20; i++)
		{
			let message = scope uint8[](i);
			link.A.Send(LoopbackLink.RemotePeer, 0, message, .Unreliable);
		}
		link.Advance(500.0f);

		let order = scope List<uint8>();
		Drain(link.B, order);
		Test.Assert(!order.IsEmpty);

		var sawOutOfOrder = false;
		for (int i = 1; i < order.Count; i++)
		{
			if (order[i] < order[i - 1])
				sawOutOfOrder = true;
		}
		Test.Assert(sawOutOfOrder);
	}

	[Test]
	public static void TheReliableChannelStaysInOrderDespiteReorderSettings()
	{
		var sim = SimConditions();
		sim.LatencyMs = 20.0f;
		sim.ReorderPct = 1.0f;
		sim.Seed = 7;
		let link = scope LoopbackLink(sim);
		Drain(link.A);
		Drain(link.B);

		for (uint8 i = 0; i < 20; i++)
		{
			let message = scope uint8[](i);
			link.A.Send(LoopbackLink.RemotePeer, 0, message, .ReliableOrdered);
		}
		link.Advance(500.0f);

		let order = scope List<uint8>();
		Drain(link.B, order);
		Test.Assert(order.Count == 20);
		for (int i = 0; i < order.Count; i++)
			Test.Assert(order[i] == (uint8)i);
	}

	[Test]
	public static void DisconnectNotifiesTheOtherSide()
	{
		let link = scope LoopbackLink();
		Drain(link.A);
		Drain(link.B);

		link.A.Disconnect(LoopbackLink.RemotePeer);
		Test.Assert(AnyKind(link.B, .Disconnected));
	}

	[Test]
	public static void UpdatingOneEndpointAdvancesTheSharedClock()
	{
		var sim = SimConditions();
		sim.LatencyMs = 50.0f;
		let link = scope LoopbackLink(sim);
		Drain(link.A);
		Drain(link.B);

		let message = scope uint8[](1);
		link.A.Send(LoopbackLink.RemotePeer, 0, message, .ReliableOrdered);

		// The clock belongs to the LINK, so pumping either side moves the pair.
		link.A.Update(60.0f);
		Test.Assert(Drain(link.B) == 1);
	}
}
