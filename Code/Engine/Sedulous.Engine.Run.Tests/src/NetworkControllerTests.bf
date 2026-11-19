using System;
using Sedulous.Core;
using Sedulous.Engine.Run;
using Sedulous.Engine.Net;
using Sedulous.Net.Manager;
using Sedulous.Net.Replication;
using Sedulous.Scene;

namespace Sedulous.Engine.Run.Tests;

/// A run's networking: the role lifecycle, which scene a fresh endpoint replicates, and the
/// edges at which the replicated scene's fixed lane is wired to the endpoint and unwired
/// from it.
class NetworkControllerTests
{
	[Test]
	public static void TheRoleLifecycleStartsStopsAndReconnects()
	{
		// The injected spawn resolver is applied to EVERY endpoint the controller opens, a
		// reconnect included: the controller owns the factory rather than spending it.
		let controller = scope NetworkController();
		controller.SetSpawnResolverFactory(new () =>
			{
				return new (scene, prefab, id) => EntityHandle.Invalid;
			});

		Test.Assert(controller.NetEndpoint == null);

		Test.Assert(controller.StartServer(0, true));
		Test.Assert(controller.NetEndpoint != null);
		Test.Assert(controller.NetEndpoint.Session.IsServer);
		Test.Assert(controller.NetEndpoint.BoundPort != 0);
		Test.Assert(controller.NetEndpoint.Replication.HasSpawnHandler);

		controller.StopNetworking();
		Test.Assert(controller.NetEndpoint == null);

		// A fresh endpoint, and the resolver applied AGAIN.
		Test.Assert(controller.StartServer(0, true));
		Test.Assert(controller.NetEndpoint != null);
		Test.Assert(controller.NetEndpoint.Replication.HasSpawnHandler);
		// And it destructs here holding a live endpoint, which is the teardown path.
	}

	[Test]
	public static void AFreshEndpointReplicatesTheCachedScene()
	{
		// A scene cached while offline is applied to the endpoint the moment one opens, since
		// a server assigns network ids from it; a live change is forwarded to a running one.
		let controller = scope NetworkController();
		let scenes = scope SceneManager();

		let level = scenes.CreateScene("Level");
		Test.Assert(level != null);
		controller.SetReplicatedScene(level);

		Test.Assert(controller.StartServer(0, true));
		Test.Assert(controller.NetEndpoint != null);

		controller.SetReplicatedScene(null);
		controller.StopNetworking();
		Test.Assert(controller.NetEndpoint == null);
	}

	[Test]
	public static void OnlyTheReplicatedScenesLaneDrivesTheEndpoint()
	{
		// The endpoint is wired into ONLY the replicated scene's network system, at the
		// controller's own edges. Stopping detaches the system BEFORE the endpoint dies, and
		// reconnecting against a live scene re-wires it.
		let controller = scope NetworkController();
		let scene = scope Scene();
		NetworkScene.AddNetworkSceneManagers(scene);

		let system = scene.GetSystem<NetworkSceneSystem>();
		Test.Assert(system != null);

		controller.SetReplicatedScene(scene);
		// Attached while offline, and so inert: there is no endpoint yet.
		Test.Assert(system.Endpoint == null);

		Test.Assert(controller.StartServer(0, true));
		Test.Assert(system.Endpoint === controller.NetEndpoint);

		controller.StopNetworking();
		Test.Assert(system.Endpoint == null);
		Test.Assert(controller.NetEndpoint == null);

		Test.Assert(controller.StartServer(0, true));
		Test.Assert(system.Endpoint === controller.NetEndpoint);

		// Unwired before the scene goes, so nothing is left pointing at a dead one.
		controller.SetReplicatedScene(null);
	}

	[Test]
	public static void EachInstanceOwnsAnIndependentEndpoint()
	{
		let server = scope ApplicationRun();
		let client = scope ApplicationRun();
		Test.Assert(server.NetEndpoint == null);

		Test.Assert(server.StartServer(0, true));
		Test.Assert(server.NetEndpoint != null);
		Test.Assert(server.NetEndpoint.Session.IsServer);

		let port = server.NetEndpoint.BoundPort;
		Test.Assert(port != 0);

		Test.Assert(client.Connect("127.0.0.1", port));
		Test.Assert(client.NetEndpoint != null);
		Test.Assert(client.NetEndpoint.Session.IsClient);
		Test.Assert(server.NetEndpoint !== client.NetEndpoint);

		for (int i < 400)
		{
			if (server.NetEndpoint.Session.PeerCount != 0)
				break;

			server.NetEndpoint.UpdateTransport(16.0f);
			client.NetEndpoint.UpdateTransport(16.0f);
			System.Threading.Thread.Sleep(1);
		}
		Test.Assert(server.NetEndpoint.Session.PeerCount == 1);

		client.StopNetworking();
		Test.Assert(client.NetEndpoint == null);
		// The server is untouched by it, which is the isolation.
		Test.Assert(server.NetEndpoint != null);
	}

	[Test]
	public static void DestroyingTheReplicatedSceneClearsTheEndpointsScene()
	{
		// Destroying the CURRENT scene clears the pairing first, so the endpoint's own scene
		// and the controller's cache are both empty BEFORE the scene is freed. A later pump
		// or reconnect then never reaches dead storage.
		let instance = scope ApplicationRun();

		let level = instance.CreateScene("Level");
		Test.Assert(level != null);
		instance.SetScene(level);

		Test.Assert(instance.StartServer(0, true));
		Test.Assert(instance.NetEndpoint != null);

		instance.DestroyScene(level);
		Test.Assert(instance.GetScene() == null);
		// Still online: the endpoint outlives the scene.
		Test.Assert(instance.NetEndpoint != null);

		instance.NetEndpoint.UpdateTransport(16.0f);
		// And reconnecting with no current scene is safe.
		Test.Assert(instance.StartServer(0, true));
		instance.StopNetworking();
	}

	/// As the network subsystem pumps a run: its mutations deferred, flushed after.
	private static void Pump(ApplicationRun instance)
	{
		if (let endpoint = instance.NetEndpoint)
		{
			instance.Mutations.Enter();
			endpoint.UpdateTransport(16.0f);
			instance.Mutations.Leave();
			instance.Mutations.Flush();
		}
	}

	/// A message's handler that stops the networking and opens a new role at once, as a script's
	/// Net.Disconnect and Net.Host in a Net.On handler do: the run is offline at once and the new
	/// role opens, while the old endpoint, whose pump delivered the message, delivers nothing
	/// more and is deleted once the pump has returned.
	[Test]
	public static void NetworkingStoppedFromInsideThePumpIsDeletedAfterIt()
	{
		let server = scope ApplicationRun();
		let client = scope ApplicationRun();
		Test.Assert(server.StartServer(0, true));
		Test.Assert(client.Connect("127.0.0.1", server.NetEndpoint.BoundPort));
		bool offlineInHandler = false;
		int heard = 0;
		server.NetEndpoint.Rpc.On("leave", new [&] (sender, args) =>
			{
				heard++;
				server.StopNetworking();
				offlineInHandler = server.NetEndpoint == null;
				server.StartServer(0, true); // a new role, at once
			});
		for (int i < 400)
		{
			if (server.NetEndpoint.Session.PeerCount != 0)
				break;
			Pump(server);
			Pump(client);
			System.Threading.Thread.Sleep(1);
		}
		Test.Assert(server.NetEndpoint.Session.PeerCount == 1);

		let first = server.NetEndpoint;
		let joined = client.NetEndpoint;
		joined.Rpc.Call(joined.Session, joined.Session.ServerPeer, "leave");
		joined.Rpc.Call(joined.Session, joined.Session.ServerPeer, "leave");
		for (int i < 400)
		{
			if (offlineInHandler)
				break;
			Pump(client);
			Pump(server); // the handler deletes nothing under the pump
			System.Threading.Thread.Sleep(1);
		}
		Test.Assert(offlineInHandler, "offline inside the handler");
		Test.Assert(heard == 1, "the closed endpoint delivered nothing more");
		Test.Assert(server.NetEndpoint != null);
		Test.Assert(server.NetEndpoint !== first, "the new role's endpoint");
		Test.Assert(server.NetEndpoint.Session.PeerCount == 0);
		Test.Assert(server.Mutations.PendingCount == 0, "the old one deleted at the flush");
	}
}
