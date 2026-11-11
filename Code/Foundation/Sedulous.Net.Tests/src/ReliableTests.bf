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

	/// A socket that loses the first Data packet sent through it, and passes everything else.
	private class DropFirstDataSocket : IDatagramSocket
	{
		private IDatagramSocket mInner;
		public int Dropped = 0;

		public this(IDatagramSocket inner)
		{
			mInner = inner;
		}

		public void Send(DatagramEndpoint to, Span<uint8> data)
		{
			let reader = scope BitReader(data);
			reader.ReadU16(); // protocol
			let type = reader.ReadU8();
			if ((Dropped == 0) && reader.Ok && (type == 2)) // Data
			{
				Dropped++;
				return;
			}
			mInner.Send(to, data);
		}

		public bool Receive(out DatagramEndpoint outFrom, List<uint8> outData) => mInner.Receive(out outFrom, outData);

		public DatagramEndpoint LocalEndpoint => mInner.LocalEndpoint;
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

	/// More than a packet's worth due at once (a replication delta of a crowd) goes out the
	/// same update, not a packet an update: at one an update a big delta drained over several
	/// updates while the next ones queued behind it, and the delay grew without end.
	[Test]
	public static void ABurstBiggerThanAPacketGoesOutInOneUpdate()
	{
		let fixture = scope Fixture(Conditions(10.0f, 0.0f, 0.0f, 0.0f, 1));
		fixture.Server.SetAccepting(true);
		let serverPeer = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(20);
		DrainReceived(fixture.Server, scope .());

		for (uint8 i = 0; i < 20; i++)
		{
			let message = scope uint8[1000]; // one to a packet
			message[0] = i;
			fixture.Client.Send(serverPeer, 1, message, .ReliableOrdered);
		}
		fixture.Pump(3); // the latency and a step or two: far fewer updates than messages
		let got = scope List<uint8>();
		DrainReceived(fixture.Server, got);
		Test.Assert(got.Count == 20, scope $"{got.Count} of 20 arrived");
		for (int i < got.Count)
			Test.Assert(got[i] == (uint8)i);
	}

	/// Unreliable messages that do not fit the packet wait for the next one; they used to be
	/// dropped.
	[Test]
	public static void UnreliableMessagesBeyondOnePacketAreSentNotDropped()
	{
		let fixture = scope Fixture(Conditions(10.0f, 0.0f, 0.0f, 0.0f, 1));
		fixture.Server.SetAccepting(true);
		let serverPeer = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(20);
		DrainReceived(fixture.Server, scope .());

		for (uint8 i = 0; i < 10; i++)
		{
			let message = scope uint8[600]; // two do not fit one packet
			message[0] = i;
			fixture.Client.Send(serverPeer, 1, message, .Unreliable);
		}
		fixture.Pump(3);
		let got = scope List<uint8>();
		DrainReceived(fixture.Server, got);
		Test.Assert(got.Count == 10, scope $"{got.Count} of 10: no loss in the sim, so all of them");
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

	/// A reliable message in a connection's very first Data packet is resent when that packet is
	/// lost: the far end, having received nothing, acks nothing. The resend waits longer than the
	/// far end's first keepalive, so an ack of a packet never received would retire it first.
	[Test]
	public static void AReliableMessageInTheFirstPacketIsResentWhenThatPacketIsLost()
	{
		var config = ReliableConfig();
		config.KeepAliveMs = 50.0f;
		config.MinResendMs = 500.0f;
		let network = scope SimDatagramNetwork(Conditions(10.0f));
		let serverSocket = network.CreateSocket();
		let dropping = scope DropFirstDataSocket(network.CreateSocket());
		let client = scope ReliableTransport(dropping, config);
		let server = scope ReliableTransport(serverSocket, config);
		server.SetAccepting(true);

		let serverPeer = client.Connect(serverSocket.LocalEndpoint);
		// Queued while connecting, so it goes in the first Data packet, which is lost.
		client.Send(serverPeer, 0, scope uint8[](42), .ReliableOrdered);
		let got = scope List<uint8>();
		for (int step < 200)
		{
			network.Advance(10.0f);
			client.Update(10.0f);
			server.Update(10.0f);
			DrainReceived(server, got);
		}
		Test.Assert(dropping.Dropped == 1);
		Test.Assert((got.Count == 1) && (got[0] == 42), "resent, and delivered once");
	}

	/// A client that restarts and connects again from the same address starts a new session: the
	/// server ends the old one and accepts the new, whose messages arrive though their ids start
	/// over.
	[Test]
	public static void AClientRestartingAtTheSameAddressConnectsAgain()
	{
		let fixture = scope Fixture(Conditions(10.0f));
		fixture.Server.SetAccepting(true);
		let first = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(20);
		for (uint8 i = 0; i < 3; i++)
			fixture.Client.Send(first, 0, scope uint8[](i), .ReliableOrdered);
		fixture.Pump(20);
		let before = scope List<uint8>();
		DrainReceived(fixture.Server, before);
		Test.Assert(before.Count == 3);

		// The client process restarts on the same socket address.
		delete fixture.Client;
		fixture.Client = new .(fixture.ClientSocket);
		let second = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(20);
		Test.Assert(AnyKind(fixture.Client, .Connected));
		var disconnected = 0;
		var connected = 0;
		let event = scope NetEvent();
		while (fixture.Server.Poll(event))
		{
			if (event.Kind == .Disconnected)
				disconnected++;
			else if (event.Kind == .Connected)
				connected++;
		}
		Test.Assert((disconnected == 1) && (connected == 1), "the old session ends, the new one starts");

		fixture.Client.Send(second, 0, scope uint8[](7), .ReliableOrdered);
		fixture.Pump(20);
		let after = scope List<uint8>();
		DrainReceived(fixture.Server, after);
		Test.Assert((after.Count == 1) && (after[0] == 7), "the new session's first message arrives");
	}

	/// A client that disconnects and connects again to the same server gets a working session.
	[Test]
	public static void AClientThatDisconnectedConnectsAgain()
	{
		let fixture = scope Fixture(Conditions(10.0f));
		fixture.Server.SetAccepting(true);
		let first = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(20);
		fixture.Client.Send(first, 0, scope uint8[](1), .ReliableOrdered);
		fixture.Pump(20);
		fixture.Client.Disconnect(first);
		fixture.Pump(10);
		Test.Assert(AnyKind(fixture.Server, .Disconnected));

		let second = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(20);
		Test.Assert(AnyKind(fixture.Client, .Connected));
		fixture.Client.Send(second, 0, scope uint8[](9), .ReliableOrdered);
		fixture.Pump(20);
		let got = scope List<uint8>();
		DrainReceived(fixture.Server, got);
		Test.Assert((got.Count == 1) && (got[0] == 9), "the new session's message arrives");
	}

	/// Sequenced messages never arrive out of order: over a link that reorders, a stale one is
	/// dropped rather than delivered after a newer one.
	[Test]
	public static void SequencedMessagesNeverArriveOutOfOrder()
	{
		let fixture = scope Fixture(Conditions(20.0f, 0.0f, 0.1f, 0.5f, 11));
		fixture.Server.SetAccepting(true);
		let serverPeer = fixture.Client.Connect(fixture.ServerSocket.LocalEndpoint);
		fixture.Pump(20);
		AnyKind(fixture.Server, .Connected);

		let got = scope List<uint8>();
		for (uint8 i = 0; i < 200; i++)
		{
			fixture.Client.Send(serverPeer, 3, scope uint8[](i), .UnreliableSequenced);
			fixture.Step();
			DrainReceived(fixture.Server, got);
		}
		fixture.Pump(20);
		DrainReceived(fixture.Server, got);
		Test.Assert(got.Count > 50, "most arrive");
		for (int i = 1; i < got.Count; i++)
			Test.Assert(got[i] > got[i - 1], "each newer than the one before");
	}
}
