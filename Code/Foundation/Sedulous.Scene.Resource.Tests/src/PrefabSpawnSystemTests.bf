using System;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Scene.Resource.Tests;

/// Spawning by id through the scene's system: placement, the subtree bind, the record,
/// and every way it answers nothing.
static class PrefabSpawnSystemTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-4f;

	[Test]
	public static void ASpawnLandsWhereItWasAskedWithItsChildren()
	{
		let fixture = scope PrefabDatabaseFixture("scratch_prefab_spawn_system");
		let turret = fixture.StoreTurret("turret", 30);

		let scene = scope Scene("level");
		scene.AddSystem<AmmoManager>();
		let spawner = scene.AddSystem<PrefabSpawnSystem>();
		spawner.SetSource(fixture.Database, null);
		Test.Assert(spawner.HasSource);

		let anchor = scene.CreateEntity("anchor");
		scene.SetLocalPosition(anchor, .(10, 0, 0));

		let rotation = Quaternion.FromAxisAngle(.(0, 1, 0), 1.0f);
		let root = spawner.Spawn(turret, .(1, 2, 3), rotation, anchor);
		Test.Assert(root.IsAssigned);
		Test.Assert(scene.GetEntityName(root) == "Turret");
		Test.Assert(scene.GetParent(root) == anchor, "under the parent asked for");
		Test.Assert(scene.GetChildCount(root) == 1, "the child came with it");

		let local = scene.GetLocalTransform(root);
		Test.Assert(Near(local.Position.X, 1) && Near(local.Position.Z, 3), "position is local to the parent");
		Test.Assert(Near(local.Rotation.Y, rotation.Y));
		scene.UpdateTransforms();
		Test.Assert(Near(scene.GetWorldPosition(root).X, 11));

		// Twice is two instances, each recorded on the scene.
		let second = spawner.Spawn(turret, .(0, 0, 0));
		Test.Assert(second.IsAssigned && (second != root));
		Test.Assert(scene.GetParent(second) == .Invalid);
		Test.Assert(scene.FindPrefabInstanceByRoot(scene.GetEntityId(root)) != null);
		Test.Assert(scene.FindPrefabInstanceByRoot(scene.GetEntityId(second)) != null);
	}

	/// Only the spawned subtree is bound: what was already in the scene is not re-walked.
	[Test]
	public static void ASpawnBindsItsOwnSubtreeAndNothingElse()
	{
		let fixture = scope PrefabDatabaseFixture("scratch_prefab_spawn_bind");
		let turret = fixture.StoreTurret("turret", 30);

		let scene = scope Scene("level");
		let ammo = scene.AddSystem<AmmoManager>();
		let spawner = scene.AddSystem<PrefabSpawnSystem>();
		let resources = scope ResourceManager(null);
		spawner.SetSource(fixture.Database, resources);

		let older = scene.CreateEntity("older");
		ammo.Add(older).Rounds = 5;

		let root = spawner.Spawn(turret, .(0, 0, 0));
		Test.Assert(ammo.Get(root).Rounds == 30);
		Test.Assert(ammo.Get(root).Binds == 1, "the spawned component was bound");
		Test.Assert(ammo.Get(older).Binds == 0, "the one that was already there was not touched");
		Test.Assert(ammo.Resources === resources, "and the manager remembers what it bound through");

		// Without a manager the subtree arrives unbound, for a later resolve.
		spawner.SetSource(fixture.Database, null);
		let unbound = spawner.Spawn(turret, .(0, 0, 0));
		Test.Assert(ammo.Get(unbound).Binds == 0);
	}

	[Test]
	public static void EveryFailureIsAnUnassignedHandle()
	{
		let fixture = scope PrefabDatabaseFixture("scratch_prefab_spawn_fail");
		let turret = fixture.StoreTurret("turret", 1);

		let scene = scope Scene("level");
		scene.AddSystem<AmmoManager>();
		let spawner = scene.AddSystem<PrefabSpawnSystem>();

		// No source yet.
		Test.Assert(!spawner.HasSource);
		Test.Assert(!spawner.Spawn(turret, .(0, 0, 0)).IsAssigned);

		spawner.SetSource(fixture.Database, null);
		Test.Assert(!spawner.Spawn(Guid.Empty, .(0, 0, 0)).IsAssigned, "the nil id");
		Test.Assert(!spawner.Spawn(Guid.Create(), .(0, 0, 0)).IsAssigned, "an unknown id");

		// An instance that is not a prefab: no scene stream to spawn.
		let other = fixture.Database.RootGroup.CreateInstance("notes", PrefabDatabaseFixture.cPrefabTypeName);
		Test.Assert(!spawner.Spawn(other.Id, .(0, 0, 0)).IsAssigned);

		Test.Assert(scene.EntityCount == 0, "nothing half spawned");
	}
}
