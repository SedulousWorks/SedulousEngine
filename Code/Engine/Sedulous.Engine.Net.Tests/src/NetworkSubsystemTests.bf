using System;
using Sedulous.Core;
using Sedulous.Run;
using Sedulous.Runtime;
using Sedulous.Scene;
using Sedulous.Net;
using Sedulous.Net.Manager;
using Sedulous.Net.Replication;
using Sedulous.Engine.Net;

namespace Sedulous.Engine.Net.Tests;

/// The once per context half: what the module installs, and the transport pump.
class NetworkSubsystemTests
{
	/// The ENGINE module carries the fixed lane driver as well as foundation's managers, so
	/// the two cannot be installed apart.
	[Test]
	public static void TheSceneModuleInjectsTheManagersAndTheDriver()
	{
		let scene = scope Scene("level");

		// A bare scene is not networked.
		Test.Assert(scene.GetSystem<NetworkComponentManager>() == null);
		Test.Assert(scene.GetSystem<NetworkedTransformComponentManager>() == null);
		Test.Assert(scene.GetSystem<NetworkSceneSystem>() == null);

		NetworkScene.AddNetworkSceneManagers(scene);

		// Identity, replicated movement and the driver that sends them all have a home now.
		Test.Assert(scene.GetSystem<NetworkComponentManager>() != null);
		Test.Assert(scene.GetSystem<NetworkedTransformComponentManager>() != null);
		Test.Assert(scene.GetSystem<NetworkSceneSystem>() != null);
	}

	/// A network controller holding an endpoint, as a GameInstance's does.
	private class Controller : INetworkController
	{
		private NetworkManager mEndpoint;

		public this(NetworkManager endpoint)
		{
			mEndpoint = endpoint;
		}

		public NetworkManager NetEndpoint => mEndpoint;
	}

	/// A run of its own (a GameInstance is the real one).
	private class TestRun : RunBase
	{
		public this() : base("test") {}
	}

	/// The pump alone connects a peer: no fan out from the app, and no scene involved. It pumps
	/// every run's endpoint, found through the runs on its subsystem manager.
	[Test]
	public static void TheTransportPumpDrivesEveryRunsEndpoint()
	{
		let network = scope SimDatagramNetwork(SimConditions());
		let serverSocket = network.CreateSocket();
		let server = scope NetworkManager(serverSocket);
		let client = scope NetworkManager(network.CreateSocket());
		server.StartServer(true);
		client.ConnectTo(serverSocket.LocalEndpoint);

		// Two runs, each with a network controller holding its endpoint.
		let serverController = scope Controller(server);
		let clientController = scope Controller(client);
		let serverRun = scope TestRun();
		let clientRun = scope TestRun();
		serverRun.Register<INetworkController>(serverController);
		clientRun.Register<INetworkController>(clientController);
		let runs = scope RunRegistry();
		runs.Add(serverRun);
		runs.Add(clientRun);

		let context = scope SubsystemManager();
		context.AddSubsystem<NetworkSubsystem>();
		context.SetRunManager(runs);
		context.Startup();

		for (int i < 200)
		{
			if (server.Session.PeerCount != 0)
				break;
			network.Advance(10.0f);
			context.PostUpdate(0.010f); // ten milliseconds, which the pump converts
		}
		Test.Assert(server.Session.PeerCount == 1, "the pump alone connected the peer");
		context.Shutdown();
	}
}
