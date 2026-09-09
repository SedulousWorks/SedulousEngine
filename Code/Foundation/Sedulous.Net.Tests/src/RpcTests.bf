using System;
using System.Collections;
using Sedulous.Net;

namespace Sedulous.Net.Tests;

/// The RPC table: name hashing, dispatch, broadcast and the pump.
class RpcTests
{
	private class Fixture
	{
		public SimDatagramNetwork Network ~ delete _;
		public NetSession Server ~ delete _;
		public NetSession Client ~ delete _;
		public PeerId ServerPeer;

		private IDatagramSocket mServerSocket;

		public this()
		{
			var sim = SimConditions();
			sim.LatencyMs = 10.0f;
			Network = new .(sim);
			mServerSocket = Network.CreateSocket();
			Server = new .(mServerSocket);
			Client = new .(Network.CreateSocket());

			Server.StartServer();
			ServerPeer = Client.Connect(mServerSocket.LocalEndpoint);
			Pump(40);
		}

		public void Pump(int steps, float deltaMs = 10.0f)
		{
			for (int i = 0; i < steps; i++)
			{
				Network.Advance(deltaMs);
				Server.Update(deltaMs);
				Client.Update(deltaMs);
			}
		}
	}

	[Test]
	public static void NameHashingIsStableAndDistinguishesNames()
	{
		Test.Assert(RpcTable.Hash("Fire") == RpcTable.Hash("Fire"));
		Test.Assert(RpcTable.Hash("Fire") != RpcTable.Hash("Move"));
		Test.Assert(RpcTable.Hash("") == 2166136261);
	}

	[Test]
	public static void AClientCallReachesTheServerHandlerWithItsArguments()
	{
		let fixture = scope Fixture();
		let table = scope RpcTable();

		var receivedX = 0;
		var receivedFlag = false;
		var senderSeen = InvalidPeer;
		table.On("Order", new [&](sender, args) =>
			{
				senderSeen = sender;
				receivedX = args.ReadI32();
				receivedFlag = args.ReadBool();
			});

		table.Call(fixture.Client, fixture.ServerPeer, "Order", scope (args) =>
			{
				args.WriteI32(-77);
				args.WriteBool(true);
			});
		fixture.Pump(30);

		table.Pump(fixture.Server);
		Test.Assert(receivedX == -77);
		Test.Assert(receivedFlag);
		Test.Assert(senderSeen != InvalidPeer);
	}

	[Test]
	public static void AnUnregisteredCallIsIgnoredRatherThanFatal()
	{
		let fixture = scope Fixture();
		let table = scope RpcTable();

		var handled = false;
		table.On("Known", new [&](sender, args) => { handled = true; });

		// A peer calling something this build does not have.
		table.Call(fixture.Client, fixture.ServerPeer, "Unknown");
		fixture.Pump(30);
		table.Pump(fixture.Server);
		Test.Assert(!handled);

		table.Call(fixture.Client, fixture.ServerPeer, "Known");
		fixture.Pump(30);
		table.Pump(fixture.Server);
		Test.Assert(handled);
	}

	[Test]
	public static void CallAllReachesEveryPeer()
	{
		let fixture = scope Fixture();
		let table = scope RpcTable();

		var count = 0;
		table.On("Tick", new [&](sender, args) => { count++; });

		table.CallAll(fixture.Server, "Tick");
		fixture.Pump(30);
		table.Pump(fixture.Client);
		Test.Assert(count == 1);
	}

	[Test]
	public static void RegisteringTwiceReplacesTheHandler()
	{
		let fixture = scope Fixture();
		let table = scope RpcTable();

		var first = 0;
		var second = 0;
		table.On("Once", new [&](sender, args) => { first++; });
		table.On("Once", new [&](sender, args) => { second++; });

		table.Call(fixture.Client, fixture.ServerPeer, "Once");
		fixture.Pump(30);
		table.Pump(fixture.Server);
		Test.Assert(first == 0);
		Test.Assert(second == 1);
	}

	[Test]
	public static void PumpForwardsWhatIsNotAnRpc()
	{
		let fixture = scope Fixture();
		let table = scope RpcTable();

		var others = 0;
		let message = scope uint8[](9);
		fixture.Client.Send(fixture.ServerPeer, 0, message, .ReliableOrdered);
		fixture.Pump(30);

		table.Pump(fixture.Server, scope [&](event) =>
			{
				if (event.Kind == .Received)
					others++;
			});
		Test.Assert(others == 1);
	}
}
