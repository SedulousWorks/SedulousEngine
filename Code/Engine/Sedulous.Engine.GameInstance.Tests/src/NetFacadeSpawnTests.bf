using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Engine.GameInstance;
using Sedulous.Engine.Net;
using Sedulous.Net.Replication;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.VFS;

namespace Sedulous.Engine.GameInstance.Tests;

/// Net.Spawn: the host puts a prefab into the replicated scene with a network id carrying
/// the prefab, so every client builds its own copy; a client's or an offline call spawns
/// nothing.
class NetFacadeSpawnTests
{
	[Test]
	public static void TheHostSpawnsANetworkedPrefabAndAClientSpawnsNothing()
	{
		let root = "scratch_net_spawn";
		RemoveDirectoryRecursive(root);
		CreateDirectory(root);
		defer RemoveDirectoryRecursive(root);
		let serializables = scope SerializableRegistry();
		SceneResources.RegisterAll(serializables);
		let mount = scope NativeFileSystem(root);
		SerializerFactory factory = new (stream, mode) => new BinarySerializerContext(stream, mode);
		defer delete factory;
		let database = scope ContentDatabase(mount, factory, "asset", serializables);
		let template = scope Scene("Guest");
		template.CreateEntity("Guest");
		let instance = database.RootGroup.CreateInstance("Guest", "Sedulous.Scene.Resource.PrefabDocument");
		Test.Assert(SceneStorage.SavePrefab(template, instance) case .Ok);
		let guest = instance.Id;

		let scene = scope Scene("Palace");
		NetworkScene.AddNetworkSceneManagers(scene);
		scene.AddSystem<PrefabSpawnSystem>().SetSource(database, null);
		let controller = scope NetworkController();
		controller.SetReplicatedScene(scene);
		let net = scope NetFacade(controller);

		Test.Assert(!net.Spawn(guest, .(1, 2, 3)).IsAssigned, "offline: nothing");

		Test.Assert(controller.StartServer(0, true));
		let spawned = net.Spawn(guest, .(1, 2, 3));
		Test.Assert(spawned.IsAssigned, "the host spawns it");
		Test.Assert(scene.GetEntityName(spawned) == "Guest");
		Test.Assert(Math.Abs(scene.GetLocalTransform(spawned).Position.Y - 2.0f) < 1e-4f);
		let component = scene.GetSystem<NetworkComponentManager>().Get(spawned);
		Test.Assert(component != null, "networked");
		Test.Assert(component.Id.IsValid);
		Test.Assert(component.Prefab == guest, "with its prefab, so a client can build its own");
		Test.Assert(!net.Spawn(Guid.Create(), .(0, 0, 0)).IsAssigned, "a prefab the scene cannot spawn: nothing");
		// The host's own spawn is its; one spawned for a client is that client's, not the host's.
		Test.Assert(component.Owner == 0);
		Test.Assert(net.IsMine(spawned), "the host's own");
		let theirs = net.SpawnFor(7, guest, .(0, 0, 0));
		Test.Assert(scene.GetSystem<NetworkComponentManager>().Get(theirs).Owner == 7);
		Test.Assert(!net.IsMine(theirs), "player 7's, not the host's");
		Test.Assert(!net.IsMine(scene.CreateEntity("plain")), "not networked: no one's");

		let clientScene = scope Scene("Palace");
		NetworkScene.AddNetworkSceneManagers(clientScene);
		clientScene.AddSystem<PrefabSpawnSystem>().SetSource(database, null);
		let clientController = scope NetworkController();
		clientController.SetReplicatedScene(clientScene);
		let clientNet = scope NetFacade(clientController);
		Test.Assert(clientController.Connect("127.0.0.1", controller.NetEndpoint.BoundPort));
		Test.Assert(!clientNet.Spawn(guest, .(4, 5, 6)).IsAssigned, "only the host spawns");
		clientController.SetReplicatedScene(null);
		controller.SetReplicatedScene(null);
	}
}
