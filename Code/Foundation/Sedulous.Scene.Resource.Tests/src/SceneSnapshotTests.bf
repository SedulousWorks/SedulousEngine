using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Scene.Resource.Tests;

/// Snapshot, run, restore: what entering play in an editor is built on.
class SceneSnapshotTests
{
	private static Guid PrefabId => .(0xABCD, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);

	[Test]
	public static void ASnapshotRestoresTheSceneItCaptured()
	{
		let scene = scope Scene();
		scene.SetName("world");
		let manager = scene.AddSystem<HealthManager>();
		let world = scene.AddSystem<WorldSystem>();
		world.Settings.Gravity = -2.5f;

		let player = scene.CreateEntity("Player");
		let weapon = scene.CreateEntity("Weapon");
		scene.SetParent(weapon, player);
		manager.Add(player).Value = 88.0f;
		let playerId = scene.GetEntityId(player);

		let snapshot = SceneSnapshot.Capture(scene);
		Test.Assert(snapshot != null);
		defer delete snapshot;

		// Play: things move, die and are born.
		manager.Get(player).Value = 1.0f;
		scene.DestroyEntity(weapon);
		scene.CreateEntity("Bullet");
		world.Settings.Gravity = 0.0f;

		Test.Assert(snapshot.Restore(scene) case .Ok);

		Test.Assert(scene.EntityCount == 2, "the bullet is gone and the weapon is back");
		let restored = scene.FindEntity(playerId);
		Test.Assert(restored.IsAssigned, "and it came back under the SAME id");
		Test.Assert(manager.Get(restored).Value == 88.0f);
		Test.Assert(scene.FindEntityByPath("Player/Weapon").IsAssigned);
		Test.Assert(scene.FindEntityByName("Bullet") == EntityHandle.Invalid);
		Test.Assert(world.Settings.Gravity == -2.5f, "settings restored too");
	}

	/// Restoring goes back INTO the same scene object, so anything holding it stays valid.
	[Test]
	public static void RestoringReusesTheSameSceneObject()
	{
		let scene = scope Scene();
		scene.AddSystem<HealthManager>();
		scene.CreateEntity("A");

		let snapshot = SceneSnapshot.Capture(scene);
		defer delete snapshot;

		let manager = scene.GetSystem<HealthManager>();
		scene.CreateEntity("B");
		Test.Assert(snapshot.Restore(scene) case .Ok);

		Test.Assert(scene.GetSystem<HealthManager>() === manager, "the systems are the same objects");
		Test.Assert(scene.EntityCount == 1);
	}

	/// A snapshot is SELF CONTAINED: a scene with prefab instances restores with no payload
	/// to resolve, because expanded mode wrote the members flat and the state beside them.
	/// A snapshot that needed the project would be no protection against the project
	/// changing while the game runs.
	[Test]
	public static void ASnapshotWithPrefabInstancesRestoresWithoutAResolver()
	{
		let template = scope Scene();
		let templateManager = template.AddSystem<HealthManager>();
		let root = template.CreateEntity("Turret");
		template.SetParent(template.CreateEntity("Barrel"), root);
		templateManager.Add(root).Value = 200.0f;

		let payload = scope MemoryStream();
		Test.Assert(PrefabCapture.Capture(template, root, payload, .Binary) case .Ok);
		payload.Seek(0, .Begin);

		let scene = scope Scene();
		let manager = scene.AddSystem<HealthManager>();
		let spawned = PrefabSpawn.Spawn(scene, payload, PrefabId);
		manager.Get(spawned).Value = 33.0f;
		let spawnedId = scene.GetEntityId(spawned);

		let snapshot = SceneSnapshot.Capture(scene);
		Test.Assert(snapshot != null);
		defer delete snapshot;

		// Play wrecks it.
		scene.DestroyEntity(spawned);
		Test.Assert(scene.EntityCount == 0);

		Test.Assert(snapshot.Restore(scene) case .Ok);

		Test.Assert(scene.EntityCount == 2, "the members came back as flat entities");
		let restored = scene.FindEntity(spawnedId);
		Test.Assert(restored.IsAssigned);
		Test.Assert(manager.Get(restored).Value == 33.0f, "including the override");

		// The instance bookkeeping came back too, so a later save still writes it as a
		// reference rather than as loose entities.
		Test.Assert(scene.PrefabInstanceCount == 1);
		let state = scene.FindPrefabInstanceByRoot(spawnedId);
		Test.Assert(state != null);
		Test.Assert(state.PrefabId == PrefabId);
		Test.Assert(state.SourceIds.Count == 2);
		Test.Assert(state.ComponentBaselines.Count == 1, "and the baselines, so overrides still derive");
	}
}
