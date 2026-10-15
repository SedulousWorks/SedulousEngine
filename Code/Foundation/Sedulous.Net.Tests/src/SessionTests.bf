using System;
using System.Collections;
using Sedulous.Net;

namespace Sedulous.Net.Tests;

/// Roles, the peer registry, broadcast and the server-authoritative clock.
class SessionTests
{
	/// A server and two clients over one sim network.
	private class Fixture
	{
		public SimDatagramNetwork Network ~ delete _;
		public NetSession Server ~ delete _;
		public NetSession ClientOne ~ delete _;
		public NetSession ClientTwo ~ delete _;
		public PeerId ClientOneServerPeer;
		public PeerId ClientTwoServerPeer;

		public IDatagramSocket ServerSocket => mServerSocket;

		private IDatagramSocket mServerSocket;

		public this(float latencyMs = 10.0f)
		{
			var sim = SimConditions();
			sim.LatencyMs = latencyMs;
			Network = new .(sim);

			mServerSocket = Network.CreateSocket();
			Server = new .(mServerSocket);
			ClientOne = new .(Network.CreateSocket());
			ClientTwo = new .(Network.CreateSocket());
		}

		public void StartAndConnect()
		{
			Server.StartServer();
			ClientOneServerPeer = ClientOne.Connect(mServerSocket.LocalEndpoint);
			ClientTwoServerPeer = ClientTwo.Connect(mServerSocket.LocalEndpoint);
			Pump(40);
		}

		public void Step(float deltaMs = 10.0f)
		{
			Network.Advance(deltaMs);
			Server.Update(deltaMs);
			ClientOne.Update(deltaMs);
			ClientTwo.Update(deltaMs);
		}

		public void Pump(int steps, float deltaMs = 10.0f)
		{
			for (int i = 0; i < steps; i++)
				Step(deltaMs);
		}
	}

	/// Drains a session, collecting the first byte of each Received payload.
	private static void Drain(NetSession session, List<uint8> outFirstBytes = null)
	{
		let event = scope NetEvent();
		while (session.PollEvent(event))
		{
			if ((outFirstBytes != null) && (event.Kind == .Received) && !event.Payload.IsEmpty)
				outFirstBytes.Add(event.Payload[0]);
		}
	}

	[Test]
	public static void RolesAreSetByStartServerAndConnect()
	{
		let fixture = scope Fixture();
		Test.Assert(fixture.Server.Role == .None);

		fixture.Server.StartServer();
		Test.Assert(fixture.Server.Role == .ListenServer);
		Test.Assert(fixture.Server.IsServer);
		Test.Assert(!fixture.Server.IsClient);

		fixture.ClientOne.Connect(fixture.ServerSocket.LocalEndpoint);
		Test.Assert(fixture.ClientOne.Role == .Client);
		Test.Assert(fixture.ClientOne.IsClient);
	}

	[Test]
	public static void ADedicatedServerIsStillAServer()
	{
		let fixture = scope Fixture();
		fixture.Server.StartServer(true);
		Test.Assert(fixture.Server.Role == .DedicatedServer);
		Test.Assert(fixture.Server.IsServer);
	}

	[Test]
	public static void TheServerTracksItsClients()
	{
		let fixture = scope Fixture();
		fixture.StartAndConnect();
		Drain(fixture.Server);

		Test.Assert(fixture.Server.PeerCount == 2);

		// One leaves, and the registry follows.
		fixture.ClientOne.Disconnect(fixture.ClientOneServerPeer);
		fixture.Pump(20);
		Drain(fixture.Server);
		Test.Assert(fixture.Server.PeerCount == 1);
	}

	[Test]
	public static void BroadcastReachesEveryClientAndBroadcastExceptSkipsOne()
	{
		let fixture = scope Fixture();
		fixture.StartAndConnect();
		Drain(fixture.ClientOne);
		Drain(fixture.ClientTwo);

		let message = scope uint8[](0x42);
		fixture.Server.Broadcast(0, message, .ReliableOrdered);
		fixture.Pump(30);

		let one = scope List<uint8>();
		let two = scope List<uint8>();
		Drain(fixture.ClientOne, one);
		Drain(fixture.ClientTwo, two);
		Test.Assert(one.Count == 1);
		Test.Assert(two.Count == 1);

		// Now skip whichever peer the first client is on the server.
		let skipped = fixture.Server.Peers[0].Id;
		let second = scope uint8[](0x43);
		fixture.Server.BroadcastExcept(skipped, 0, second, .ReliableOrdered);
		fixture.Pump(30);

		one.Clear();
		two.Clear();
		Drain(fixture.ClientOne, one);
		Drain(fixture.ClientTwo, two);
		// Exactly one of the two got it.
		Test.Assert((one.Count + two.Count) == 1);
	}

	[Test]
	public static void ControlTrafficNeverSurfacesAsAUserEvent()
	{
		let fixture = scope Fixture();
		fixture.StartAndConnect();
		Drain(fixture.ClientOne);

		// Long enough for several clock syncs, which ride the control channel.
		fixture.Pump(200);

		let event = scope NetEvent();
		while (fixture.ClientOne.PollEvent(event))
			Test.Assert(event.Channel != NetSession.ControlChannel);
	}

	/// The server tells each client the id it knows it by, reliably (some packets are lost
	/// here); the welcome is the session's own business and never reaches the game.
	[Test]
	public static void TheServerWelcomesEachClientWithTheIdItKnowsItBy()
	{
		var sim = SimConditions();
		sim.LatencyMs = 20.0f;
		sim.LossPct = 0.2f;
		sim.Seed = 5;
		let network = scope SimDatagramNetwork(sim);
		let serverSocket = network.CreateSocket();
		let server = scope NetSession(serverSocket);
		let clientA = scope NetSession(network.CreateSocket());
		let clientB = scope NetSession(network.CreateSocket());
		server.StartServer();
		Test.Assert(clientA.LocalPeer == InvalidPeer, "not welcomed yet");
		clientA.Connect(serverSocket.LocalEndpoint);
		clientB.Connect(serverSocket.LocalEndpoint);
		for (int i < 60)
		{
			network.Advance(10.0f);
			server.Update(10.0f);
			clientA.Update(10.0f);
			clientB.Update(10.0f);
		}
		Test.Assert(server.PeerCount == 2);
		Test.Assert((clientA.LocalPeer != InvalidPeer) && (clientB.LocalPeer != InvalidPeer));
		Test.Assert(clientA.LocalPeer != clientB.LocalPeer);
		// Each client's id is one the server holds for it.
		Test.Assert((server.Peers[0].Id == clientA.LocalPeer) || (server.Peers[1].Id == clientA.LocalPeer));
		Test.Assert((server.Peers[0].Id == clientB.LocalPeer) || (server.Peers[1].Id == clientB.LocalPeer));
		Test.Assert(server.LocalPeer == InvalidPeer, "the server is no one's client");
		let event = scope NetEvent();
		while (clientA.PollEvent(event))
			Test.Assert(event.Kind != .Received, "no welcome reaches the game");
	}

	[Test]
	public static void TheClientClockSyncsToTheServer()
	{
		let fixture = scope Fixture(40.0f);
		// Before anything is pumped: network time is local only until a server sync lands.
		Test.Assert(!fixture.ClientOne.HasClockSync);

		fixture.StartAndConnect();
		fixture.Pump(200);
		Drain(fixture.ClientOne);
		Test.Assert(fixture.ClientOne.HasClockSync);

		// The client's network time tracks the server's, allowing for the trip it took to get
		// here. A generous window, because this is an estimate and not a measurement.
		let difference = fixture.ClientOne.NetworkTimeMs - fixture.Server.NetworkTimeMs;
		Test.Assert((difference > -200.0) && (difference < 200.0));
	}

	[Test]
	public static void TheNetworkTickFollowsTheFixedStep()
	{
		let fixture = scope Fixture();
		fixture.Server.StartServer();
		fixture.Server.SetFixedStepMs(50.0f);
		fixture.Pump(20);

		// Two hundred milliseconds at a fifty millisecond step is tick four.
		Test.Assert(fixture.Server.NetworkTick == (uint64)(fixture.Server.NetworkTimeMs / 50.0));
	}
}
