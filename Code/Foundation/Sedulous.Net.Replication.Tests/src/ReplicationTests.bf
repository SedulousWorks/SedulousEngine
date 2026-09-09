using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Net;
using Sedulous.Net.Replication;
using Sedulous.Scene;

namespace Sedulous.Net.Replication.Tests;

/// NetworkId, the replicated field layout harvest, and the reflection driven codec.
///
/// The central bet is that a component MARKS fields and the wire format is generated from
/// reflection, with no hand written per component net code. These tests are what hold that
/// bet honest.
class ReplicationTests
{
	private const float cEpsilon = 0.0001f;

	private static bool Near(float a, float b) => Abs(a - b) < cEpsilon;

	private static bool Near(Float3 a, Float3 b) =>
		Near(a.X, b.X) && Near(a.Y, b.Y) && Near(a.Z, b.Z);

	/// A distinguishable Guid without a generator.
	private static Guid MakeGuid(uint32 seed) => .(seed, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

	/// A scene with the network managers and a Mover pool: what both ends of every exchange
	/// below need.
	private static void AddManagers(Scene scene)
	{
		scene.AddSystem<NetworkComponentManager>();
		scene.AddSystem<MoverManager>();
	}

	[Test]
	public static void ANetworkIdIsValidWhenItIsNotNought()
	{
		Test.Assert(!NetworkId.Invalid.IsValid);
		Test.Assert(NetworkId(7).IsValid);
		Test.Assert(NetworkId(7) == NetworkId(7));
		Test.Assert(NetworkId(7) != NetworkId(8));
	}

	[Test]
	public static void TheLayoutTakesMarkedAndSupportedFieldsOnly()
	{
		let layout = ReplicatedLayout.Fields(typeof(Mover));

		// position, rotation, speed, grounded, health. LocalOnly is unmarked and Tag is of an
		// unsupported type, so both are out.
		Test.Assert(layout.Length == 5);
		Test.Assert(layout[0].Name == "Position");
		Test.Assert(layout[4].Name == "Health");

		// Excluding an unsupported MARKED field is the point: both peers harvest the same
		// type, so both drop it, and the field sets still match.
		Test.Assert(!ReplicatedLayout.IsFieldTypeSupported(typeof(Guid)));
		Test.Assert(ReplicatedLayout.IsFieldTypeSupported(typeof(Float3)));
	}

	[Test]
	public static void AComponentRoundTripsItsReplicatedFieldsThroughTheWire()
	{
		Mover source = .();
		source.Position = .(1.5f, -2.0f, 3.25f);
		source.Rotation = .(0.1f, 0.2f, 0.3f, 0.9f);
		source.Speed = 12.5f;
		source.Grounded = true;
		source.Health = 77;
		source.LocalOnly = 999.0f;
		source.Tag = MakeGuid(5);

		let writer = scope BitWriter();
		Test.Assert(FieldCodec.WriteState(writer, typeof(Mover), &source) == 5);

		Mover destination = .();
		let reader = scope BitReader(writer.Data);
		Test.Assert(FieldCodec.ReadState(reader, typeof(Mover), &destination) == 5);
		Test.Assert(reader.Ok);

		Test.Assert(Near(destination.Position, source.Position));
		Test.Assert(Near(destination.Rotation.X, 0.1f));
		Test.Assert(Near(destination.Rotation.W, 0.9f));
		Test.Assert(Near(destination.Speed, 12.5f));
		Test.Assert(destination.Grounded);
		Test.Assert(destination.Health == 77);
		// The local field is untouched, and the unsupported one never crossed.
		Test.Assert(Near(destination.LocalOnly, 0.0f));
		Test.Assert(destination.Tag == Guid());
	}

	[Test]
	public static void TheFieldCodecRoundTripsSupportedScalarsAndRejectsUnsupported()
	{
		double pi = 3.141592653589793;
		Float3 vector = .(4.0f, 5.0f, 6.0f);
		int32 negative = -42;
		Guid unsupported = MakeGuid(1);

		let writer = scope BitWriter();
		Test.Assert(FieldCodec.WriteValue(writer, typeof(double), &pi));
		Test.Assert(FieldCodec.WriteValue(writer, typeof(Float3), &vector));
		Test.Assert(FieldCodec.WriteValue(writer, typeof(int32), &negative));
		// No codec support, so nothing is written and the stream stays where it was.
		Test.Assert(!FieldCodec.WriteValue(writer, typeof(Guid), &unsupported));

		let reader = scope BitReader(writer.Data);
		double readPi = 0.0;
		Float3 readVector = .();
		int32 readNegative = 0;
		Guid readGuid = .();
		Test.Assert(FieldCodec.ReadValue(reader, typeof(double), &readPi));
		Test.Assert(FieldCodec.ReadValue(reader, typeof(Float3), &readVector));
		Test.Assert(FieldCodec.ReadValue(reader, typeof(int32), &readNegative));
		// Reading an unsupported type consumes nothing and says so.
		Test.Assert(!FieldCodec.ReadValue(reader, typeof(Guid), &readGuid));

		Test.Assert(readPi == pi);
		Test.Assert(Near(readVector, vector));
		Test.Assert(readNegative == -42);
	}

	[Test]
	public static void AFullSnapshotRoundTripsNetworkedEntitiesFromServerToClient()
	{
		let server = scope Scene("server");
		AddManagers(server);
		let serverMovers = server.GetSystem<MoverManager>();
		let serverReplication = scope StateReplication();

		let a = server.CreateEntity("A");
		var movingA = serverMovers.Add(a);
		movingA.Position = .(1.0f, 2.0f, 3.0f);
		movingA.Speed = 10.0f;
		movingA.Health = 100;
		movingA.Grounded = true;
		let idA = serverReplication.AssignNetworkId(server, a);

		let b = server.CreateEntity("B");
		var movingB = serverMovers.Add(b);
		movingB.Position = .(-4.0f, 0.0f, 9.0f);
		movingB.Speed = 2.5f;
		movingB.Health = 42;
		let idB = serverReplication.AssignNetworkId(server, b);

		Test.Assert(idA.IsValid && idB.IsValid && (idA != idB));
		Test.Assert(serverReplication.NetworkedCount == 2);

		let writer = scope BitWriter();
		serverReplication.CaptureSnapshot(server, writer);

		let client = scope Scene("client");
		AddManagers(client);
		let clientMovers = client.GetSystem<MoverManager>();
		let clientReplication = scope StateReplication();

		let reader = scope BitReader(writer.Data);
		clientReplication.ApplySnapshot(client, reader);
		Test.Assert(reader.Ok);
		Test.Assert(clientReplication.NetworkedCount == 2);

		let mirrorA = clientMovers.Get(clientReplication.FindEntity(idA));
		let mirrorB = clientMovers.Get(clientReplication.FindEntity(idB));
		Test.Assert((mirrorA != null) && (mirrorB != null));
		Test.Assert(Near(mirrorA.Position, .(1.0f, 2.0f, 3.0f)));
		Test.Assert(Near(mirrorA.Speed, 10.0f));
		Test.Assert(mirrorA.Health == 100);
		Test.Assert(mirrorA.Grounded);
		Test.Assert(Near(mirrorB.Position, .(-4.0f, 0.0f, 9.0f)));
		Test.Assert(mirrorB.Health == 42);

		// Re-applying an updated snapshot mutates IN PLACE: the same entities, no duplicates.
		movingA.Health = 55;
		let writer2 = scope BitWriter();
		serverReplication.CaptureSnapshot(server, writer2);
		let reader2 = scope BitReader(writer2.Data);
		clientReplication.ApplySnapshot(client, reader2);
		Test.Assert(clientReplication.NetworkedCount == 2);
		Test.Assert(clientMovers.Get(clientReplication.FindEntity(idA)).Health == 55);
	}

	[Test]
	public static void NetworkedTransformBridgesTheEntityTransformThroughTheWire()
	{
		let server = scope Scene("server");
		ReplicationScene.AddNetworkSceneManagers(server);
		let serverReplication = scope StateReplication();

		let entity = server.CreateEntity("E");
		server.GetSystem<NetworkedTransformComponentManager>().Add(entity);
		server.SetLocalTransform(entity,
			Transform(.(5.0f, 6.0f, 7.0f), Quaternion.Identity, .(2.0f, 2.0f, 2.0f)));
		let id = serverReplication.AssignNetworkId(server, entity);
		Test.Assert(id.IsValid);

		// Server: pull the entity's transform INTO the component, then snapshot.
		ReplicationScene.CaptureEntityTransforms(server);
		Test.Assert(Near(
			server.GetSystem<NetworkedTransformComponentManager>().Get(entity).Position,
			.(5.0f, 6.0f, 7.0f)));

		let writer = scope BitWriter();
		serverReplication.CaptureSnapshot(server, writer);

		let client = scope Scene("client");
		ReplicationScene.AddNetworkSceneManagers(client);
		let clientReplication = scope StateReplication();
		let reader = scope BitReader(writer.Data);
		clientReplication.ApplySnapshot(client, reader);
		Test.Assert(reader.Ok);

		// Client: the snapshot filled the component; pushing it back moves the entity.
		let mirror = clientReplication.FindEntity(id);
		Test.Assert(client.IsValid(mirror));
		ReplicationScene.ApplyEntityTransforms(client);
		let transform = client.GetLocalTransform(mirror);
		Test.Assert(Near(transform.Position, .(5.0f, 6.0f, 7.0f)));
		Test.Assert(Near(transform.Scale, .(2.0f, 2.0f, 2.0f)));
	}

	[Test]
	public static void AssignSceneNetworkIdsCoversAuthoredEntitiesAndIsIdempotent()
	{
		let scene = scope Scene("authored");
		let manager = scene.AddSystem<NetworkComponentManager>();
		let replication = scope StateReplication();

		let a = scene.CreateEntity("A");
		manager.Add(a);
		let b = scene.CreateEntity("B");
		manager.Add(b);
		// No NetworkComponent, so it is never assigned.
		scene.CreateEntity("plain");

		Test.Assert(!manager.Get(a).Id.IsValid);
		replication.AssignSceneNetworkIds(scene);
		Test.Assert(manager.Get(a).Id.IsValid);
		Test.Assert(manager.Get(b).Id.IsValid);
		Test.Assert(manager.Get(a).Id != manager.Get(b).Id);

		// Idempotent: a second pass leaves an already assigned entity alone, which is what
		// lets both peers derive the same ids from the same authored scene.
		let idA = manager.Get(a).Id;
		replication.AssignSceneNetworkIds(scene);
		Test.Assert(manager.Get(a).Id == idA);
	}

	[Test]
	public static void APerPeerDeltaSendsOnlyWhatChangedSinceThatPeersLastDelta()
	{
		let server = scope Scene("server");
		AddManagers(server);
		let movers = server.GetSystem<MoverManager>();
		let replication = scope StateReplication();

		let a = server.CreateEntity("A");
		var movingA = movers.Add(a);
		movingA.Position = .(1.0f, 0.0f, 0.0f);
		movingA.Health = 10;
		let idA = replication.AssignNetworkId(server, a);

		let b = server.CreateEntity("B");
		var movingB = movers.Add(b);
		movingB.Position = .(0.0f, 1.0f, 0.0f);
		movingB.Health = 20;
		let idB = replication.AssignNetworkId(server, b);

		let peer = 1u;
		let client = scope Scene("client");
		AddManagers(client);
		let clientMovers = client.GetSystem<MoverManager>();
		let clientReplication = scope StateReplication();

		// First delta: everything is new to this peer.
		{
			let writer = scope BitWriter();
			Test.Assert(replication.CaptureDelta(server, peer, writer) == 2);
			let reader = scope BitReader(writer.Data);
			clientReplication.ApplyDelta(client, reader);
			Test.Assert(reader.Ok);
		}
		Test.Assert(clientReplication.NetworkedCount == 2);
		Test.Assert(clientMovers.Get(clientReplication.FindEntity(idA)).Health == 10);
		Test.Assert(clientMovers.Get(clientReplication.FindEntity(idB)).Health == 20);

		// Nothing changed, so nothing is sent. This is the whole point of a baseline.
		{
			let writer = scope BitWriter();
			Test.Assert(replication.CaptureDelta(server, peer, writer) == 0);
		}

		// Change only A.
		movingA.Health = 99;
		{
			let writer = scope BitWriter();
			Test.Assert(replication.CaptureDelta(server, peer, writer) == 1);
			let reader = scope BitReader(writer.Data);
			clientReplication.ApplyDelta(client, reader);
		}
		Test.Assert(clientMovers.Get(clientReplication.FindEntity(idA)).Health == 99);
		// B is untouched by A's delta.
		Test.Assert(clientMovers.Get(clientReplication.FindEntity(idB)).Health == 20);

		// Despawn B: the delta marks it removed and the client destroys it.
		let localB = clientReplication.FindEntity(idB);
		server.DestroyEntity(b);
		{
			let writer = scope BitWriter();
			Test.Assert(replication.CaptureDelta(server, peer, writer) == 1);
			let reader = scope BitReader(writer.Data);
			clientReplication.ApplyDelta(client, reader);
		}
		Test.Assert(!client.IsValid(localB));

		// Forgetting the peer re-sends everything, because the baseline was what the peer had.
		replication.ForgetPeer(peer);
		{
			let writer = scope BitWriter();
			Test.Assert(replication.CaptureDelta(server, peer, writer) == 1);
		}
	}

	[Test]
	public static void ALateJoinSnapshotSpawnsPrefabsThroughTheHandler()
	{
		let server = scope Scene("server");
		AddManagers(server);
		let movers = server.GetSystem<MoverManager>();
		let replication = scope StateReplication();

		let prefabA = MakeGuid(0xAAAA);
		let prefabB = MakeGuid(0xBBBB);
		let a = server.CreateEntity("A");
		movers.Add(a).Health = 7;
		let idA = replication.AssignNetworkId(server, a, prefabA);
		let b = server.CreateEntity("B");
		movers.Add(b).Health = 8;
		let idB = replication.AssignNetworkId(server, b, prefabB);

		let client = scope Scene("client");
		AddManagers(client);
		let clientMovers = client.GetSystem<MoverManager>();
		let clientReplication = scope StateReplication();

		// Stands in for the host's SpawnPrefab: records the id and produces a Mover bearing
		// entity, as a real prefab would.
		let spawned = scope List<Guid>();
		clientReplication.SetSpawnHandler(new [&](scene, prefab, id) =>
			{
				spawned.Add(prefab);
				let entity = scene.CreateEntity();
				scene.GetSystem<MoverManager>().Add(entity);
				return entity;
			});

		let writer = scope BitWriter();
		replication.CaptureSnapshot(server, writer);
		let reader = scope BitReader(writer.Data);
		clientReplication.ApplySnapshot(client, reader);
		Test.Assert(reader.Ok);

		Test.Assert(spawned.Count == 2);
		Test.Assert(spawned.Contains(prefabA));
		Test.Assert(spawned.Contains(prefabB));
		Test.Assert(clientMovers.Get(clientReplication.FindEntity(idA)).Health == 7);
		Test.Assert(clientMovers.Get(clientReplication.FindEntity(idB)).Health == 8);

		// The source prefab is recorded on the tag, which host migration and re-spawn need.
		let tags = client.GetSystem<NetworkComponentManager>();
		Test.Assert(tags.Get(clientReplication.FindEntity(idA)).Prefab == prefabA);
	}

	[Test]
	public static void ADeltaSpawnsANewlyAddedNetworkedEntityViaItsPrefab()
	{
		let server = scope Scene("server");
		AddManagers(server);
		let movers = server.GetSystem<MoverManager>();
		let replication = scope StateReplication();
		let peer = 1u;

		let client = scope Scene("client");
		AddManagers(client);
		let clientReplication = scope StateReplication();
		let spawned = scope List<Guid>();
		clientReplication.SetSpawnHandler(new [&](scene, prefab, id) =>
			{
				spawned.Add(prefab);
				let entity = scene.CreateEntity();
				scene.GetSystem<MoverManager>().Add(entity);
				return entity;
			});

		let prefab1 = MakeGuid(1);
		let a = server.CreateEntity();
		movers.Add(a).Health = 1;
		replication.AssignNetworkId(server, a, prefab1);
		{
			let writer = scope BitWriter();
			replication.CaptureDelta(server, peer, writer);
			let reader = scope BitReader(writer.Data);
			clientReplication.ApplyDelta(client, reader);
		}
		Test.Assert(spawned.Count == 1);
		Test.Assert(spawned[0] == prefab1);

		// A second entity added later: the next delta carries just its spawn.
		let prefab2 = MakeGuid(2);
		let b = server.CreateEntity();
		movers.Add(b).Health = 2;
		replication.AssignNetworkId(server, b, prefab2);
		{
			let writer = scope BitWriter();
			Test.Assert(replication.CaptureDelta(server, peer, writer) == 1);
			let reader = scope BitReader(writer.Data);
			clientReplication.ApplyDelta(client, reader);
		}
		Test.Assert(spawned.Count == 2);
		Test.Assert(spawned[1] == prefab2);
		Test.Assert(clientReplication.NetworkedCount == 2);
	}

	[Test]
	public static void LerpSmoothsFloatsAndVectorsAndSnapsDiscreteTypes()
	{
		float from = 0.0f, to = 10.0f, result = 0.0f;
		FieldInterpolation.Lerp(typeof(float), &from, &to, 0.5f, &result);
		Test.Assert(Near(result, 5.0f));

		Float3 vectorFrom = .(0, 0, 0), vectorTo = .(2, 4, 6), vectorResult = .();
		FieldInterpolation.Lerp(typeof(Float3), &vectorFrom, &vectorTo, 0.25f, &vectorResult);
		Test.Assert(Near(vectorResult, .(0.5f, 1.0f, 1.5f)));

		// A bool is discrete, so it SNAPS to the earlier sample even at t = 0.9: a half true
		// is a value the server never sent.
		bool boolFrom = false, boolTo = true, boolResult = true;
		FieldInterpolation.Lerp(typeof(bool), &boolFrom, &boolTo, 0.9f, &boolResult);
		Test.Assert(!boolResult);

		Test.Assert(FieldInterpolation.IsInterpolatableType(typeof(Float3)));
		Test.Assert(FieldInterpolation.IsInterpolatableType(typeof(Quaternion)));
		Test.Assert(!FieldInterpolation.IsInterpolatableType(typeof(int32)));
	}

	[Test]
	public static void TheInterpolationBufferLerpsAndSnapsAtARenderTime()
	{
		let buffer = scope InterpolationBuffer();
		let id = NetworkId(1);
		let typeHash = 0xABCDu;

		// Two states a hundred milliseconds apart.
		Mover first = .();
		first.Position = .(0, 0, 0);
		first.Speed = 0.0f;
		first.Health = 10;
		buffer.Record(id, typeHash, 0.0, typeof(Mover), &first);

		Mover second = .();
		second.Position = .(10, 0, 0);
		second.Speed = 5.0f;
		second.Health = 20;
		buffer.Record(id, typeHash, 100.0, typeof(Mover), &second);
		Test.Assert(buffer.TrackedEntities == 1);

		Mover sampled = .();
		// Midway: position and speed lerp, while health holds the earlier bracket's value.
		Test.Assert(buffer.Sample(id, typeHash, 50.0, typeof(Mover), &sampled));
		Test.Assert(Near(sampled.Position.X, 5.0f));
		Test.Assert(Near(sampled.Speed, 2.5f));
		Test.Assert(sampled.Health == 10);

		buffer.Sample(id, typeHash, 100.0, typeof(Mover), &sampled);
		Test.Assert(Near(sampled.Position.X, 10.0f));

		// Before the window it CLAMPS to the earliest rather than extrapolating backwards.
		buffer.Sample(id, typeHash, -30.0, typeof(Mover), &sampled);
		Test.Assert(Near(sampled.Position.X, 0.0f));

		buffer.Forget(id);
		Test.Assert(!buffer.Sample(id, typeHash, 50.0, typeof(Mover), &sampled));
		Test.Assert(buffer.TrackedEntities == 0);
	}

	[Test]
	public static void RelevancyHidesEntitiesAndRemovesThemWhenTheyLeaveIt()
	{
		let server = scope Scene("server");
		AddManagers(server);
		let movers = server.GetSystem<MoverManager>();
		let replication = scope StateReplication();

		let a = server.CreateEntity("A");
		movers.Add(a).Health = 1;
		let idA = replication.AssignNetworkId(server, a);
		let b = server.CreateEntity("B");
		movers.Add(b).Health = 2;
		let idB = replication.AssignNetworkId(server, b);

		var peerOneSeesA = true;
		replication.SetRelevance(new [&](peerId, id, entity) =>
			{
				if (peerId == 1)
					return (id == idA) && peerOneSeesA;
				// Peer two has full visibility.
				return true;
			});

		let clientOne = scope Scene("one");
		AddManagers(clientOne);
		let replicationOne = scope StateReplication();
		let clientTwo = scope Scene("two");
		AddManagers(clientTwo);
		let replicationTwo = scope StateReplication();

		// Peer one's delta: only A crosses.
		{
			let writer = scope BitWriter();
			Test.Assert(replication.CaptureDelta(server, 1, writer) == 1);
			let reader = scope BitReader(writer.Data);
			replicationOne.ApplyDelta(clientOne, reader);
		}
		Test.Assert(replicationOne.NetworkedCount == 1);
		Test.Assert(clientOne.IsValid(replicationOne.FindEntity(idA)));
		// B was never sent to peer one at all.
		Test.Assert(!clientOne.IsValid(replicationOne.FindEntity(idB)));

		{
			let writer = scope BitWriter();
			Test.Assert(replication.CaptureDelta(server, 2, writer) == 2);
			let reader = scope BitReader(writer.Data);
			replicationTwo.ApplyDelta(clientTwo, reader);
		}
		Test.Assert(replicationTwo.NetworkedCount == 2);

		// A leaves peer one's relevance: its next delta REMOVES A, so the hidden state is not
		// merely unsent but actively destroyed on that client.
		let localA = replicationOne.FindEntity(idA);
		Test.Assert(clientOne.IsValid(localA));
		peerOneSeesA = false;
		{
			let writer = scope BitWriter();
			Test.Assert(replication.CaptureDelta(server, 1, writer) == 1);
			let reader = scope BitReader(writer.Data);
			replicationOne.ApplyDelta(clientOne, reader);
		}
		Test.Assert(!clientOne.IsValid(localA));
		Test.Assert(replicationOne.NetworkedCount == 0);

		// Peer two is unaffected by peer one's relevance and sees no change.
		{
			let writer = scope BitWriter();
			Test.Assert(replication.CaptureDelta(server, 2, writer) == 0);
		}

		// A re-enters peer one's relevance and comes back as a fresh spawn.
		peerOneSeesA = true;
		{
			let writer = scope BitWriter();
			Test.Assert(replication.CaptureDelta(server, 1, writer) == 1);
			let reader = scope BitReader(writer.Data);
			replicationOne.ApplyDelta(clientOne, reader);
		}
		Test.Assert(replicationOne.NetworkedCount == 1);
		Test.Assert(clientOne.GetSystem<MoverManager>()
			.Get(replicationOne.FindEntity(idA)).Health == 1);
	}

	[Test]
	public static void ApplyDeltaRecordsInterpolatableStateAndSamplingSmoothsIt()
	{
		let server = scope Scene("server");
		AddManagers(server);
		let movers = server.GetSystem<MoverManager>();
		let serverReplication = scope StateReplication();

		let a = server.CreateEntity();
		var moving = movers.Add(a);
		moving.Position = .(0, 0, 0);
		moving.Health = 5;
		let id = serverReplication.AssignNetworkId(server, a);

		let client = scope Scene("client");
		AddManagers(client);
		let clientMovers = client.GetSystem<MoverManager>();
		let clientReplication = scope StateReplication();
		let buffer = scope InterpolationBuffer();
		let peer = 1u;

		// Delta one, recorded at server time nought.
		{
			let writer = scope BitWriter();
			serverReplication.CaptureDelta(server, peer, writer);
			let reader = scope BitReader(writer.Data);
			clientReplication.ApplyDelta(client, reader, buffer, 0.0);
		}
		// Move, then delta two at server time one hundred.
		moving.Position = .(10, 0, 0);
		{
			let writer = scope BitWriter();
			serverReplication.CaptureDelta(server, peer, writer);
			let reader = scope BitReader(writer.Data);
			clientReplication.ApplyDelta(client, reader, buffer, 100.0);
		}

		let mirror = clientReplication.FindEntity(id);
		Test.Assert(client.IsValid(mirror));
		// The direct apply left the LATEST value on the component.
		Test.Assert(Near(clientMovers.Get(mirror).Position.X, 10.0f));

		// Rendering halfway between the samples walks it back to the midpoint, which is what
		// makes a ten hertz update stream look continuous.
		clientReplication.SampleInterpolation(client, buffer, 50.0);
		Test.Assert(Near(clientMovers.Get(mirror).Position.X, 5.0f));

		clientReplication.SampleInterpolation(client, buffer, 0.0);
		Test.Assert(Near(clientMovers.Get(mirror).Position.X, 0.0f));
	}

	[Test]
	public static void AnInactiveEntitysTransformFreezesButItStaysInSnapshots()
	{
		let server = scope Scene("server");
		ReplicationScene.AddNetworkSceneManagers(server);
		let transforms = server.GetSystem<NetworkedTransformComponentManager>();
		let serverReplication = scope StateReplication();

		let entity = server.CreateEntity("E");
		transforms.Add(entity);
		server.SetLocalTransform(entity,
			Transform(.(1.0f, 0.0f, 0.0f), Quaternion.Identity, Float3.One));
		let id = serverReplication.AssignNetworkId(server, entity);
		Test.Assert(id.IsValid);
		ReplicationScene.CaptureEntityTransforms(server);

		// Deactivate, then move it. The replicated component keeps the LAST captured value:
		// an inactive entity is not simulating, so its state is not news.
		server.SetActive(entity, false);
		server.SetLocalTransform(entity,
			Transform(.(9.0f, 0.0f, 0.0f), Quaternion.Identity, Float3.One));
		ReplicationScene.CaptureEntityTransforms(server);
		Test.Assert(Near(transforms.Get(entity).Position, .(1.0f, 0.0f, 0.0f)));

		// It is still IN the snapshot, because existence and identity are scene data rather
		// than simulation, and a client has to spawn it either way.
		let writer = scope BitWriter();
		serverReplication.CaptureSnapshot(server, writer);

		let client = scope Scene("client");
		ReplicationScene.AddNetworkSceneManagers(client);
		let clientReplication = scope StateReplication();
		let reader = scope BitReader(writer.Data);
		clientReplication.ApplySnapshot(client, reader);
		Test.Assert(reader.Ok);
		Test.Assert(client.IsValid(clientReplication.FindEntity(id)));

		// Reactivating resumes capture from the live transform.
		server.SetActive(entity, true);
		ReplicationScene.CaptureEntityTransforms(server);
		Test.Assert(Near(transforms.Get(entity).Position, .(9.0f, 0.0f, 0.0f)));
	}
}
