using System;
using Sedulous.Core;
using Sedulous.Runtime;
using Sedulous.Scene;
using Sedulous.Net;
using Sedulous.Net.Manager;
using Sedulous.Net.Replication;
using Sedulous.Engine.Net;

namespace Sedulous.Engine.Net.Tests;

/// Replication rides the per scene FIXED lane while the transport half pumps per frame.
///
/// The two are deliberately separate, and these prove it both ways: a round trip driven by
/// the fixed lane, and a live connection that carries nothing while that lane is paused.
class ReplicationLaneTests
{
	private const float cStep = 1.0f / 60.0f;

	/// Installs the managers and the driver, points the endpoint at the scene and the scene's
	/// driver back at the endpoint, which is what the run's controller does at its edges.
	private static void Bind(NetworkManager endpoint, Scene scene)
	{
		NetworkScene.AddNetworkSceneManagers(scene);
		endpoint.SetReplicatedScene(scene);
		scene.GetSystem<NetworkSceneSystem>().Endpoint = endpoint;
	}

	[Test]
	public static void ReplicationRidesTheSceneFixedLane()
	{
		var conditions = SimConditions();
		conditions.LatencyMs = 15.0f;
		conditions.Seed = 11;
		let network = scope SimDatagramNetwork(conditions);
		let serverSocket = network.CreateSocket();
		let server = scope NetworkManager(serverSocket);
		let client = scope NetworkManager(network.CreateSocket());
		// The latest state, which is deterministic once the movement stops.
		client.SetInterpolationDelayMs(0.0);

		let serverScene = scope Scene("server");
		Bind(server, serverScene);
		let clientScene = scope Scene("client");
		Bind(client, clientScene);

		let entity = serverScene.CreateEntity("Mover");
		serverScene.GetSystem<NetworkComponentManager>().Add(entity);
		serverScene.GetSystem<NetworkedTransformComponentManager>().Add(entity);
		var start = Transform();
		start.Position = .(1, 0, 0);
		serverScene.SetLocalTransform(entity, start);
		// Author then assign, the way the demo does: the id pass runs again now it exists.
		server.SetReplicatedScene(serverScene);
		let id = serverScene.GetSystem<NetworkComponentManager>().Get(entity).Id;
		Test.Assert(id.IsValid);

		// The handshake is TRANSPORT only: a connection does not need a scene.
		server.StartServer(true);
		client.ConnectTo(serverSocket.LocalEndpoint);
		for (int i < 60)
		{
			if (server.Session.PeerCount != 0)
				break;
			network.Advance(10.0f);
			server.UpdateTransport(10.0f);
			client.UpdateTransport(10.0f);
		}
		Test.Assert(server.Session.PeerCount == 1);

		var moved = Transform();
		moved.Position = .(9, 3, -5);
		serverScene.SetLocalTransform(entity, moved);

		EntityHandle mirrored = .Invalid;
		for (int i < 400)
		{
			serverScene.FixedUpdate(cStep); // the driver captures and sends
			server.UpdateTransport(10.0f);
			network.Advance(10.0f);
			client.UpdateTransport(10.0f);
			clientScene.FixedUpdate(cStep); // the driver samples and applies
			mirrored = client.Replication.FindEntity(id);
		}

		Test.Assert(clientScene.IsValid(mirrored));
		let arrived = clientScene.GetLocalTransform(mirrored);
		Test.Assert(Math.Abs(arrived.Position.X - 9.0f) < 0.01f);
		Test.Assert(Math.Abs(arrived.Position.Y - 3.0f) < 0.01f);
		Test.Assert(Math.Abs(arrived.Position.Z + 5.0f) < 0.01f);
	}

	/// A paused scene sends nothing even though its connection is live, because capture is
	/// gated on the fixed lane and transport is not.
	[Test]
	public static void APausedSceneSendsNoDeltasWhileTheTransportStillPumps()
	{
		var conditions = SimConditions();
		conditions.Seed = 5;
		let network = scope SimDatagramNetwork(conditions);
		let serverSocket = network.CreateSocket();
		let server = scope NetworkManager(serverSocket);
		let client = scope NetworkManager(network.CreateSocket());
		client.SetInterpolationDelayMs(0.0);

		let serverScene = scope Scene("server");
		Bind(server, serverScene);
		let clientScene = scope Scene("client");
		Bind(client, clientScene);

		let entity = serverScene.CreateEntity("Mover");
		serverScene.GetSystem<NetworkComponentManager>().Add(entity);
		serverScene.GetSystem<NetworkedTransformComponentManager>().Add(entity);
		server.SetReplicatedScene(serverScene);
		let id = serverScene.GetSystem<NetworkComponentManager>().Get(entity).Id;

		server.StartServer(true);
		client.ConnectTo(serverSocket.LocalEndpoint);

		// The server's lane NEVER runs here, and only the client's does.
		for (int i < 200)
		{
			network.Advance(10.0f);
			server.UpdateTransport(10.0f);
			client.UpdateTransport(10.0f);
			clientScene.FixedUpdate(cStep);
		}
		Test.Assert(server.Session.PeerCount == 1, "the connection is live");
		Test.Assert(!clientScene.IsValid(client.Replication.FindEntity(id)), "and carried nothing");

		EntityHandle mirrored = .Invalid;
		for (int i < 400)
		{
			if (clientScene.IsValid(mirrored))
				break;
			serverScene.FixedUpdate(cStep);
			server.UpdateTransport(10.0f);
			network.Advance(10.0f);
			client.UpdateTransport(10.0f);
			clientScene.FixedUpdate(cStep);
			mirrored = client.Replication.FindEntity(id);
		}
		Test.Assert(clientScene.IsValid(mirrored), "the server's lane is what gates it");
	}

	[Test]
	public static void ADriverWithNoEndpointIsInert()
	{
		let scene = scope Scene("bare");
		NetworkScene.AddNetworkSceneManagers(scene);

		let system = scene.GetSystem<NetworkSceneSystem>();
		Test.Assert(system != null);
		Test.Assert(system.Endpoint == null);

		scene.FixedUpdate(cStep); // nothing to drive, and nothing to fault on
		Test.Assert(system.Endpoint == null);
	}
}
