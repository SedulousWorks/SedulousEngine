using System;
using System.Collections;
using Sedulous.Net;

namespace Sedulous.Net.Tests;

/// Reliable UDP over the lossy datagram sim: handshake, ordering, resend, fragmentation and
/// timeout. No sockets are involved.
class ReliableTests
{
	/// A client and server pair over one sim network, with a pump.
	private class Fixture
	{
		public SimDatagramNetwork Network ~ delete _;
		public IDatagramSocket ClientSocket;
		public IDatagramSocket ServerSocket;
		public ReliableTransport Client ~ delete _;
		public ReliableTransport Server ~ delete _;

		public this(SimConditions sim, ReliableConfig config = .())
		{
			Network = new .(sim);
			ClientSocket = Network.CreateSocket();
			ServerSocket = Network.CreateSocket();
			Client = new .(ClientSocket, config);
			Server = new .(ServerSocket, config);
		}

		public void Step(float deltaMs = 10.0f)
		{
			Network.Advance(deltaMs);
			Client.Update(deltaMs);
			Server.Update(deltaMs);
		}

		public void Pump(int steps, float deltaMs = 10.0f)
		{
			for (int i = 0; i < steps; i++)
				Step(deltaMs);
		}
	}

	/// The first byte of every Received payload, in arrival order.
	private static void DrainReceived(INetTransport transport, List<uint8> outFirstBytes)
	{
		let event = scope NetEvent();
		while (transport.Poll(event))
		{
			if ((event.Kind == .Received) && !event.Payload.IsEmpty)
				outFirstBytes.Add(event.Payload[0]);
		}
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

	private static SimConditions Conditions(float latencyMs, float lossPct = 0.0f,
		float dupPct = 0.0f, float reorderPct = 0.0f, uint64 seed = 0x9E3779B97F4A7C15UL)
	{
		var sim = SimConditions();
		sim.LatencyMs = latencyMs;
		sim.LossPct = lossPct;
		sim.DupPct = dupPct;
		sim.ReorderPct = reorderPct;
		sim.Seed = seed;
		return sim;
	}

	[Test]
	public static void TheHandshakeConnectsBothSides()
	{
		let fixture = scope Fixture(Conditions(20.0f));
		fixture.Server.SetAccepting(true);

		let serverPeer = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		Test.Assert(serverPeer != InvalidPeer);

		fixture.Pump(20);
		Test.Assert(AnyKind(fixture.Client, .Connected));
		Test.Assert(AnyKind(fixture.Server, .Connected));
	}

	[Test]
	public static void ANonAcceptingServerRefusesToConnect()
	{
		let fixture = scope Fixture(Conditions(20.0f));
		// Accepting is off by default, so a client's socket does not quietly become a server.
		fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(20);
		Test.Assert(!AnyKind(fixture.Client, .Connected));
	}

	[Test]
	public static void EveryReliableMessageArrivesInOrderDespiteHeavyLoss()
	{
		let fixture = scope Fixture(Conditions(20.0f, 0.5f, 0.0f, 0.2f, 5));
		fixture.Server.SetAccepting(true);
		let serverPeer = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(40);
		AnyKind(fixture.Server, .Connected);

		for (uint8 i = 0; i < 20; i++)
		{
			let message = scope uint8[](i);
			fixture.Client.Send(serverPeer, 0, message, .ReliableOrdered);
		}

		let got = scope List<uint8>();
		for (int step = 0; step < 200; step++)
		{
			fixture.Step();
			DrainReceived(fixture.Server, got);
			if (got.Count >= 20)
				break;
		}

		Test.Assert(got.Count == 20);
		// In order and exactly once, which is what the ordered release plus the duplicate
		// check together promise.
		for (int i = 0; i < got.Count; i++)
			Test.Assert(got[i] == (uint8)i);
	}

	[Test]
	public static void DuplicationNeverDoubleDelivers()
	{
		let fixture = scope Fixture(Conditions(20.0f, 0.0f, 1.0f, 0.0f, 11));
		fixture.Server.SetAccepting(true);
		let serverPeer = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(30);
		AnyKind(fixture.Server, .Connected);

		for (uint8 i = 0; i < 10; i++)
		{
			let message = scope uint8[](i);
			fixture.Client.Send(serverPeer, 0, message, .ReliableOrdered);
		}

		let got = scope List<uint8>();
		for (int step = 0; step < 200; step++)
		{
			fixture.Step();
			DrainReceived(fixture.Server, got);
		}

		Test.Assert(got.Count == 10);
		for (int i = 0; i < got.Count; i++)
			Test.Assert(got[i] == (uint8)i);
	}

	[Test]
	public static void UnreliableMessagesCanDropBecauseNothingResendsThem()
	{
		let fixture = scope Fixture(Conditions(20.0f, 0.6f, 0.0f, 0.0f, 3));
		fixture.Server.SetAccepting(true);
		let serverPeer = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(30);
		AnyKind(fixture.Server, .Connected);

		for (uint8 i = 0; i < 40; i++)
		{
			let message = scope uint8[](i);
			fixture.Client.Send(serverPeer, 0, message, .Unreliable);
			fixture.Step();
		}
		fixture.Pump(40);

		let got = scope List<uint8>();
		DrainReceived(fixture.Server, got);
		Test.Assert(got.Count < 40);
	}

	[Test]
	public static void TheRoundTripIsEstimatedFromAcks()
	{
		let fixture = scope Fixture(Conditions(40.0f));
		fixture.Server.SetAccepting(true);
		let serverPeer = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(10);

		for (int i = 0; i < 5; i++)
		{
			let message = scope uint8[](1);
			fixture.Client.Send(serverPeer, 0, message, .ReliableOrdered);
			fixture.Pump(10);
		}

		let stats = fixture.Client.Stats(serverPeer);
		// At least one one-way trip, and realistically about two.
		Test.Assert(stats.RttMs > 40.0f);
		Test.Assert(stats.RttMs < 200.0f);
	}

	[Test]
	public static void ASilentPeerTimesOut()
	{
		var config = ReliableConfig();
		config.TimeoutMs = 500.0f;
		let fixture = scope Fixture(Conditions(10.0f), config);
		fixture.Server.SetAccepting(true);
		fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(20);
		Test.Assert(AnyKind(fixture.Client, .Connected));

		// The server goes dark: only the client and the network are ticked from here.
		var disconnected = false;
		for (int step = 0; step < 100; step++)
		{
			fixture.Network.Advance(10.0f);
			fixture.Client.Update(10.0f);
			if (AnyKind(fixture.Client, .Disconnected))
			{
				disconnected = true;
				break;
			}
		}
		Test.Assert(disconnected);
	}

	[Test]
	public static void ALargeMessageFragmentsAndReassemblesIntactOverLoss()
	{
		let fixture = scope Fixture(Conditions(20.0f, 0.3f, 0.0f, 0.2f, 31));
		fixture.Server.SetAccepting(true);
		let serverPeer = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(20);
		AnyKind(fixture.Server, .Connected);

		// Several times one datagram, so this has to fragment.
		let payload = scope List<uint8>();
		for (int i = 0; i < 5000; i++)
			payload.Add((uint8)(i * 7));
		fixture.Client.Send(serverPeer, 0, payload, .ReliableOrdered);

		let received = scope List<uint8>();
		let event = scope NetEvent();
		for (int step = 0; step < 400; step++)
		{
			fixture.Step();
			while (fixture.Server.Poll(event))
			{
				if ((event.Kind == .Received) && (event.Payload.Count > 1))
				{
					received.Clear();
					received.AddRange(event.Payload);
				}
			}
			if (received.Count == payload.Count)
				break;
		}

		// Whole, and byte for byte: a fragment that arrived twice or out of order would show
		// up here rather than as a plausible-looking wrong message.
		Test.Assert(received.Count == payload.Count);
		for (int i = 0; i < payload.Count; i++)
			Test.Assert(received[i] == payload[i]);
	}

	[Test]
	public static void ResendIsRoundTripTimedRatherThanPerTick()
	{
		// Nothing gets through, so the message stays unacked and every packet is a resend.
		let fixture = scope Fixture(Conditions(20.0f, 1.0f));
		fixture.Server.SetAccepting(true);
		let serverPeer = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(5);

		let message = scope uint8[](7);
		fixture.Client.Send(serverPeer, 0, message, .ReliableOrdered);

		let before = fixture.Client.Stats(serverPeer).SentBytes;
		// A hundred one-millisecond ticks. A per-tick resend would send about a hundred
		// packets; the floor allows about five.
		for (int step = 0; step < 100; step++)
			fixture.Step(1.0f);
		let sent = fixture.Client.Stats(serverPeer).SentBytes - before;

		Test.Assert(sent > 0);
		Test.Assert(sent < 40 * (uint32)message.Count + 2000);
	}

	[Test]
	public static void AnExplicitDisconnectNotifiesThePeer()
	{
		let fixture = scope Fixture(Conditions(10.0f));
		fixture.Server.SetAccepting(true);
		let serverPeer = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(20);
		AnyKind(fixture.Server, .Connected);

		fixture.Client.Disconnect(serverPeer);
		fixture.Pump(10);
		Test.Assert(AnyKind(fixture.Server, .Disconnected));
	}
}
