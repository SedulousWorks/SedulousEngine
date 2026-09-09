using System;
using System.Threading;
using Sedulous.Core;
using Sedulous.Net;
using Sedulous.Net.Manager;

namespace Sedulous.Net.Manager.Tests;

/// The endpoint's own mechanics: roles, RPC routing through the manager's pump, the owning
/// factories over real loopback, and startup from config.
class NetworkManagerTests
{
	private static double ReadDouble(BitReader reader)
	{
		var bits = reader.ReadU64();
		return *(double*)&bits;
	}

	private static void WriteDouble(BitWriter writer, double value)
	{
		var value;
		writer.WriteU64(*(uint64*)&value);
	}

	[Test]
	public static void AServerAndClientConnectAndAnRpcRoutesThroughTheManager()
	{
		SimConditions conditions = .();
		conditions.LatencyMs = 20.0f;
		conditions.LossPct = 0.2f;
		conditions.Seed = 3;

		let network = scope SimDatagramNetwork(conditions);
		let serverSocket = network.CreateSocket();
		let server = scope NetworkManager(serverSocket);
		let client = scope NetworkManager(network.CreateSocket());

		server.StartServer(true);
		let serverPeer = client.ConnectTo(serverSocket.LocalEndpoint);
		Test.Assert(server.Session.IsServer);
		Test.Assert(client.Session.IsClient);

		// A server side handler, driven by the manager's OWN pump inside Update.
		var received = false;
		var argument = 0.0;
		var from = InvalidPeer;
		server.Rpc.On("order", new [&](sender, args) =>
			{
				argument = ReadDouble(args);
				from = sender;
				received = true;
			});

		for (int i < 40)
		{
			network.Advance(10.0f);
			server.Update(10.0f);
			client.Update(10.0f);
		}
		Test.Assert(server.Session.PeerCount == 1);

		client.Rpc.Call(client.Session, serverPeer, "order",
			scope (args) => WriteDouble(args, 42.5));

		for (int i = 0; (i < 200) && !received; i++)
		{
			network.Advance(10.0f);
			server.Update(10.0f);
			client.Update(10.0f);
		}
		Test.Assert(received);
		Test.Assert(argument == 42.5);
		Test.Assert(from == server.Session.Peers[0].Id);
	}

	[Test]
	public static void TheFactoriesOwnTheirSocketsAndExchangeAnRpcOverLoopback()
	{
		// The self contained runtime path: each endpoint opens its OWN real socket, with no
		// shared sim network and nothing borrowed. Two managers in one process over real
		// loopback, which is exactly the in editor server and client scenario.
		let server = NetworkManager.HostServer(0, true);
		Test.Assert(server != null);
		defer delete server;
		Test.Assert(server.Session.IsServer);
		// Assigned by the operating system, and surfaced so a client can reach it.
		Test.Assert(server.BoundPort != 0);

		let client = NetworkManager.JoinServer("127.0.0.1", server.BoundPort);
		Test.Assert(client != null);
		defer delete client;
		Test.Assert(client.Session.IsClient);
		Test.Assert(client.BoundPort != server.BoundPort);

		var received = false;
		var argument = 0.0;
		server.Rpc.On("order", new [&](sender, args) =>
			{
				argument = ReadDouble(args);
				received = true;
			});

		for (int i = 0; (i < 400) && (server.Session.PeerCount == 0); i++)
		{
			server.Update(16.0f);
			client.Update(16.0f);
			Thread.Sleep(1);
		}
		Test.Assert(server.Session.PeerCount == 1);

		client.Rpc.Call(client.Session, client.Session.ServerPeer, "order",
			scope (args) => WriteDouble(args, 7.25));

		for (int i = 0; (i < 400) && !received; i++)
		{
			server.Update(16.0f);
			client.Update(16.0f);
			Thread.Sleep(1);
		}
		Test.Assert(received);
		Test.Assert(argument == 7.25);
	}

	[Test]
	public static void ARoleOfNoneYieldsAnInactiveRuntime()
	{
		NetworkStartup config = .();
		let runtime = NetworkRuntime.Start(config);
		defer delete runtime;

		// Single player: nothing is opened at all, rather than an endpoint nobody talks to.
		Test.Assert(!runtime.IsActive);
		Test.Assert(runtime.Socket == null);
		Test.Assert(runtime.Manager == null);
	}

	[Test]
	public static void StartupTakesAServerAndClientFromConfigToAConnectionOverLoopback()
	{
		NetworkStartup serverConfig = .();
		serverConfig.Role = .Server;
		serverConfig.Dedicated = true;
		serverConfig.ListenPort = 0;

		let server = NetworkRuntime.Start(serverConfig);
		defer delete server;
		Test.Assert(server.IsActive);
		Test.Assert(server.Socket.IsOpen);
		Test.Assert(server.Manager.Session.IsServer);

		NetworkStartup clientConfig = .();
		clientConfig.Role = .Client;
		clientConfig.ServerHost = "127.0.0.1";
		// The server's ACTUAL port, which only exists after the socket bound.
		clientConfig.ServerPort = server.Socket.BoundPort;

		let client = NetworkRuntime.Start(clientConfig);
		defer delete client;
		Test.Assert(client.IsActive);
		Test.Assert(client.Manager.Session.IsClient);

		for (int i = 0; (i < 300) && (server.Manager.Session.PeerCount == 0); i++)
		{
			server.Manager.Update(16.0f);
			client.Manager.Update(16.0f);
		}
		Test.Assert(server.Manager.Session.PeerCount == 1);
	}
}
