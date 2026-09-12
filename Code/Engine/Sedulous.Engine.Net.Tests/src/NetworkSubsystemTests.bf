using System;
using Sedulous.Core;
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

	/// The pump alone connects a peer: no fan out from the app, and no scene involved.
	[Test]
	public static void TheTransportPumpDrivesEveryEnumeratedEndpoint()
	{
		let network = scope SimDatagramNetwork(SimConditions());
		let serverSocket = network.CreateSocket();
		let server = scope NetworkManager(serverSocket);
		let client = scope NetworkManager(network.CreateSocket());
		server.StartServer(true);
		client.ConnectTo(serverSocket.LocalEndpoint);

		let context = scope Context();
		let subsystem = context.AddSubsystem<NetworkSubsystem>();
		context.Startup();

		// Typed rather than inferred: the parameter is itself a delegate, so there is
		// nothing for the compiler to infer it from.
		delegate void(delegate void(NetworkManager)) source = scope (visit) =>
			{
				visit(server);
				visit(client);
			};
		subsystem.SetEndpointSource(source);

		for (int i < 200)
		{
			if (server.Session.PeerCount != 0)
				break;
			network.Advance(10.0f);
			context.PostUpdate(0.010f); // ten milliseconds, which the pump converts
		}
		Test.Assert(server.Session.PeerCount == 1, "the pump alone connected the peer");

		// Cleared before the visitor goes, which is the contract the setter documents.
		subsystem.SetEndpointSource(null);
		context.Shutdown();
	}
}
