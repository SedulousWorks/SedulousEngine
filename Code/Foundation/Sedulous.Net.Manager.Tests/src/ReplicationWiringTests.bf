using System;
using Sedulous.Core;
using Sedulous.Net;
using Sedulous.Net.Manager;
using Sedulous.Net.Replication;
using Sedulous.Scene;

namespace Sedulous.Net.Manager.Tests;

/// StateReplication driven END TO END through NetworkManager over the sim transport: a server
/// assigned entity's replicated state reaching a connected client's scene, with no manual
/// wiring in between.
class ReplicationWiringTests
{
	private const float cEpsilon = 0.0001f;

	private static bool Near(float a, float b) => Abs(a - b) < cEpsilon;

	private static bool Near(Float3 a, Float3 b) =>
		Near(a.X, b.X) && Near(a.Y, b.Y) && Near(a.Z, b.Z);

	private static void Pump(SimDatagramNetwork network, NetworkManager server,
		NetworkManager client)
	{
		network.Advance(10.0f);
		server.Update(10.0f);
		client.Update(10.0f);
	}

	[Test]
	public static void StateReplicatesFromServerToClientThroughTheManagerAndTransport()
	{
		SimConditions conditions = .();
		conditions.LatencyMs = 15.0f;
		conditions.LossPct = 0.1f;
		conditions.Seed = 7;

		let network = scope SimDatagramNetwork(conditions);
		let serverSocket = network.CreateSocket();
		let server = scope NetworkManager(serverSocket);
		let client = scope NetworkManager(network.CreateSocket());

		let serverScene = scope Scene("server");
		serverScene.AddSystem<NetworkComponentManager>();
		let serverMovers = serverScene.AddSystem<RepMoverManager>();
		server.SetReplicatedScene(serverScene);

		let clientScene = scope Scene("client");
		clientScene.AddSystem<NetworkComponentManager>();
		clientScene.AddSystem<RepMoverManager>();
		client.SetReplicatedScene(clientScene);

		server.StartServer(true);
		client.ConnectTo(serverSocket.LocalEndpoint);

		for (int i = 0; (i < 60) && (server.Session.PeerCount == 0); i++)
			Pump(network, server, client);
		Test.Assert(server.Session.PeerCount == 1);

		// The server spawns a networked entity with replicated state.
		let entity = serverScene.CreateEntity("Unit");
		var moving = serverMovers.Add(entity);
		moving.Position = .(3, 0, -2);
		moving.Health = 42;
		let id = server.Replication.AssignNetworkId(serverScene, entity);
		Test.Assert(id.IsValid);

		// Reliable ordered delivery means this CONVERGES rather than merely probably arrives.
		var mirror = EntityHandle.Invalid;
		for (int i < 400)
		{
			Pump(network, server, client);
			mirror = client.Replication.FindEntity(id);
			if (clientScene.IsValid(mirror)
				&& (clientScene.GetSystem<RepMoverManager>().Get(mirror) != null))
				break;
		}
		Test.Assert(clientScene.IsValid(mirror));

		let mirrored = clientScene.GetSystem<RepMoverManager>().Get(mirror);
		Test.Assert(mirrored != null);
		Test.Assert(mirrored.Health == 42);
		Test.Assert(Near(mirrored.Position, .(3, 0, -2)));

		// A server side change propagates on the next ticks, with nothing re-sent that did not
		// change.
		moving.Health = 99;
		for (int i = 0; (i < 200) && (mirrored.Health != 99); i++)
			Pump(network, server, client);
		Test.Assert(mirrored.Health == 99);
	}

	[Test]
	public static void ANetworkedTransformReplicatesAnEntitysMovement()
	{
		SimConditions conditions = .();
		conditions.LatencyMs = 15.0f;
		conditions.Seed = 11;

		let network = scope SimDatagramNetwork(conditions);
		let serverSocket = network.CreateSocket();
		let server = scope NetworkManager(serverSocket);
		let client = scope NetworkManager(network.CreateSocket());
		// Sample the latest state, which is deterministic once movement stops.
		client.SetInterpolationDelayMs(0.0);

		// An AUTHORED networked entity with no id yet: SetReplicatedScene on the server assigns
		// one. This is the path a designer actually walks, with no manual AssignNetworkId.
		let serverScene = scope Scene("server");
		ReplicationScene.AddNetworkSceneManagers(serverScene);
		let entity = serverScene.CreateEntity("Mover");
		serverScene.GetSystem<NetworkComponentManager>().Add(entity);
		serverScene.GetSystem<NetworkedTransformComponentManager>().Add(entity);
		serverScene.SetLocalTransform(entity,
			Transform(.(1, 0, 0), Quaternion.Identity, Float3.One));

		let clientScene = scope Scene("client");
		ReplicationScene.AddNetworkSceneManagers(clientScene);

		server.StartServer(true);
		server.SetReplicatedScene(serverScene);
		client.SetReplicatedScene(clientScene);
		client.ConnectTo(serverSocket.LocalEndpoint);

		let id = serverScene.GetSystem<NetworkComponentManager>().Get(entity).Id;
		Test.Assert(id.IsValid);

		var mirror = EntityHandle.Invalid;
		for (int i = 0; (i < 400) && !clientScene.IsValid(mirror); i++)
		{
			Pump(network, server, client);
			mirror = client.Replication.FindEntity(id);
		}
		Test.Assert(clientScene.IsValid(mirror));

		// Move the server entity's LOCAL transform. The client's follows through the capture,
		// wire and apply bridge, with no synchronising code of its own.
		serverScene.SetLocalTransform(entity,
			Transform(.(9, 3, -5), Quaternion.Identity, Float3.One));
		for (int i < 300)
			Pump(network, server, client);

		let transform = clientScene.GetLocalTransform(mirror);
		Test.Assert(Near(transform.Position, .(9, 3, -5)));
	}

	[Test]
	public static void ASharedAuthoredSceneMatchesByStableIdWithoutDuplicating()
	{
		SimConditions conditions = .();
		conditions.Seed = 21;

		let network = scope SimDatagramNetwork(conditions);
		let serverSocket = network.CreateSocket();
		let server = scope NetworkManager(serverSocket);
		let client = scope NetworkManager(network.CreateSocket());
		client.SetInterpolationDelayMs(0.0);

		// Both peers author the SAME entity with the SAME Guid, as two clients loading one
		// scene from disk do. No hand authored network id: it is derived on both sides.
		let shared = Guid(0x01234567, 0x89AB, 0xCDEF, 0xFE, 0xDC, 0xBA, 0x98, 0x76, 0x54, 0x32,
			0x10);

		let serverScene = scope Scene("server");
		ReplicationScene.AddNetworkSceneManagers(serverScene);
		let serverEntity = serverScene.CreateEntity(shared, "Shared");
		serverScene.GetSystem<NetworkComponentManager>().Add(serverEntity);
		serverScene.GetSystem<NetworkedTransformComponentManager>().Add(serverEntity);

		let clientScene = scope Scene("client");
		ReplicationScene.AddNetworkSceneManagers(clientScene);
		let clientEntity = clientScene.CreateEntity(shared, "Shared");
		clientScene.GetSystem<NetworkComponentManager>().Add(clientEntity);
		clientScene.GetSystem<NetworkedTransformComponentManager>().Add(clientEntity);

		server.StartServer(true);
		server.SetReplicatedScene(serverScene);
		client.SetReplicatedScene(clientScene);
		client.ConnectTo(serverSocket.LocalEndpoint);

		let id = serverScene.GetSystem<NetworkComponentManager>().Get(serverEntity).Id;
		Test.Assert(id.IsValid);
		// Both agree without anyone authoring the number.
		Test.Assert(clientScene.GetSystem<NetworkComponentManager>().Get(clientEntity).Id == id);

		serverScene.SetLocalTransform(serverEntity,
			Transform(.(4, 5, 6), Quaternion.Identity, Float3.One));
		for (int i < 400)
			Pump(network, server, client);

		// The incoming state matched the client's OWN authored entity rather than minting a
		// second one beside it, which is the whole point of deriving the id.
		Test.Assert(client.Replication.FindEntity(id) == clientEntity);
		Test.Assert(clientScene.GetSystem<NetworkComponentManager>().OwnerHandles.Length == 1);

		let transform = clientScene.GetLocalTransform(clientEntity);
		Test.Assert(Near(transform.Position, .(4, 5, 6)));
	}
}
