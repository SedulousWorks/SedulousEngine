using System;
using System.Threading;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Scene.Resource.Tests;

/// Spawning through the scene's system, by id and by reference: placement, the subtree bind,
/// the record, every way it answers nothing, and the prefab it spawns from being the loaded one
/// (an overwrite on disk reaches it only through a reload, an eviction refuses it, a first
/// spawn loads it at once, and what it nests loads through the manager too).
static class PrefabSpawnSystemTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-4f;

	/// A spawn system in a scene with the Ammo components, its source the fixture's manager.
	private static PrefabSpawnSystem Spawner(Scene scene, PrefabDatabaseFixture fixture)
	{
		scene.AddSystem<AmmoManager>();
		let spawner = scene.AddSystem<PrefabSpawnSystem>();
		spawner.SetSource(fixture.Resources);
		return spawner;
	}

	/// The rounds of the Ammo on `entity`.
	private static int32 Rounds(Scene scene, EntityHandle entity) => scene.GetSystem<AmmoManager>().Get(entity).Rounds;

	[Test]
	public static void ASpawnLandsWhereItWasAskedWithItsChildren()
	{
		let fixture = scope PrefabDatabaseFixture("scratch_prefab_spawn_system");
		let turret = fixture.StoreTurret("turret", 30);

		let scene = scope Scene("level");
		let spawner = Spawner(scene, fixture);
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
		let spawner = Spawner(scene, fixture);
		let ammo = scene.GetSystem<AmmoManager>();

		let older = scene.CreateEntity("older");
		ammo.Add(older).Rounds = 5;

		let root = spawner.Spawn(turret, .(0, 0, 0));
		Test.Assert(ammo.Get(root).Rounds == 30);
		Test.Assert(ammo.Get(root).Binds == 1, "the spawned component was bound");
		Test.Assert(ammo.Get(older).Binds == 0, "the one that was already there was not touched");
		Test.Assert(ammo.Resources === fixture.Resources, "and the manager remembers what it bound through");
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
		Test.Assert(!spawner.Spawn(Ref<PrefabResource>(turret), .(0, 0, 0)).IsAssigned);

		spawner.SetSource(fixture.Resources);
		Test.Assert(!spawner.Spawn(Guid.Empty, .(0, 0, 0)).IsAssigned, "the nil id");
		Test.Assert(!spawner.Spawn(Guid.Create(), .(0, 0, 0)).IsAssigned, "an unknown id");
		Test.Assert(!spawner.Spawn(Ref<PrefabResource>(Guid.Create()), .(0, 0, 0)).IsAssigned, "an unknown reference");

		// An instance that is not a prefab: no scene stream to spawn.
		let other = fixture.Database.RootGroup.CreateInstance("notes", PrefabDatabaseFixture.cPrefabTypeName);
		Test.Assert(!spawner.Spawn(other.Id, .(0, 0, 0)).IsAssigned);

		Test.Assert(scene.EntityCount == 0, "nothing half spawned");
	}

	/// The prefab is read once, when it loads: a rewrite of its file after the first spawn spawns
	/// nothing new until the prefab reloads, and then every spawn after does.
	[Test]
	public static void AnOverwriteOnDiskChangesNothingUntilAReload()
	{
		let fixture = scope PrefabDatabaseFixture("scratch_prefab_spawn_overwrite");
		let turret = fixture.StoreTurret("turret", 30);
		let scene = scope Scene("level");
		let spawner = Spawner(scene, fixture);

		Test.Assert(Rounds(scene, spawner.Spawn(turret, .(0, 0, 0))) == 30);
		Test.Assert(fixture.StoreTurret("turret", 45) == turret, "the same record rewritten");
		Test.Assert(Rounds(scene, spawner.Spawn(turret, .(0, 0, 0))) == 30, "the loaded prefab, not the file");

		fixture.Resources.Reload(turret);
		Test.Assert(Rounds(scene, spawner.Spawn(turret, .(0, 0, 0))) == 45, "reloaded: the rewrite");
		Test.Assert(Rounds(scene, spawner.Spawn(Ref<PrefabResource>(turret), .(0, 0, 0))) == 45, "by reference too");
	}

	/// A prefab deleted is still loaded until it is evicted (the editor evicts it when told of the
	/// deletion); evicted, the next spawn is refused, as an unknown prefab's is.
	[Test]
	public static void AnEvictedPrefabRefusesTheNextSpawn()
	{
		let fixture = scope PrefabDatabaseFixture("scratch_prefab_spawn_evict");
		let turret = fixture.StoreTurret("turret", 30);
		let scene = scope Scene("level");
		let spawner = Spawner(scene, fixture);

		Test.Assert(spawner.Spawn(turret, .(0, 0, 0)).IsAssigned);
		Test.Assert(fixture.Database.DeleteInstance(turret) case .Ok);
		Test.Assert(spawner.Spawn(turret, .(0, 0, 0)).IsAssigned, "loaded still: nothing evicted it yet");
		let before = scene.EntityCount;

		fixture.Resources.Evict(turret);
		Test.Assert(!spawner.Spawn(turret, .(0, 0, 0)).IsAssigned, "evicted: refused");
		Test.Assert(!spawner.Spawn(Ref<PrefabResource>(turret), .(0, 0, 0)).IsAssigned, "by reference too");
		Test.Assert(scene.EntityCount == before, "nothing half spawned");
	}

	/// A prefab nothing has loaded spawns at once, loaded synchronously, even when an
	/// asynchronous load of it is in flight: a spawn never waits a frame.
	[Test]
	public static void AFirstSpawnOfAnUnloadedPrefabArrivesAtOnce()
	{
		let fixture = scope PrefabDatabaseFixture("scratch_prefab_spawn_first");
		let turret = fixture.StoreTurret("turret", 30);
		let crate = fixture.StoreTurret("crate", 12);
		let tasks = scope TaskPool(2);
		let resources = scope ResourceManager(fixture.Database, tasks);
		resources.AddFactory(fixture.Prefabs);

		let scene = scope Scene("level");
		scene.AddSystem<AmmoManager>();
		let spawner = scene.AddSystem<PrefabSpawnSystem>();
		spawner.SetSource(resources);

		Test.Assert(resources.FindHandle(turret) == null, "not loaded");
		let root = spawner.Spawn(turret, .(0, 0, 0));
		Test.Assert(root.IsAssigned && (Rounds(scene, root) == 30), "spawned in the same call");
		Test.Assert(resources.FindHandle(turret).State == .Ready, "and loaded by it");

		let pending = resources.BindAsync<PrefabResource>(crate);
		Test.Assert(pending.State == .Pending, "its load on a worker");
		let crateRoot = spawner.Spawn(crate, .(0, 0, 0));
		Test.Assert(crateRoot.IsAssigned && (Rounds(scene, crateRoot) == 12), "the load finished for the spawn");
		Test.Assert(pending.State == .Ready);
	}

	/// A reference spawns the prefab it is bound to, or binds it then and there.
	[Test]
	public static void AReferenceSpawnsItsBoundPrefabOrBindsItAtOnce()
	{
		let fixture = scope PrefabDatabaseFixture("scratch_prefab_spawn_ref");
		let turret = fixture.StoreTurret("turret", 30);
		let scene = scope Scene("level");
		let spawner = Spawner(scene, fixture);

		var reference = Ref<PrefabResource>(turret);
		Test.Assert(!reference.IsBound);
		let first = spawner.Spawn(reference, .(1, 0, 0));
		Test.Assert(first.IsAssigned && (Rounds(scene, first) == 30), "unbound: bound at once");
		Test.Assert(Near(scene.GetLocalTransform(first).Position.X, 1));
		Test.Assert(fixture.Resources.FindHandle(turret) != null);

		reference.Bind(fixture.Resources);
		Test.Assert(reference.State == .Ready);
		let second = spawner.Spawn(reference, .(0, 0, 0));
		Test.Assert(second.IsAssigned && (second != first));
		Test.Assert(scene.FindPrefabInstanceByRoot(scene.GetEntityId(second)).PrefabId == turret, "recorded as that prefab");
	}

	/// A prefab nesting another: the inner one loads through the manager as its own prefab, so a
	/// reload of it alone reaches the outer one's next spawn.
	[Test]
	public static void ANestedPrefabSpawnsThroughTheManager()
	{
		let fixture = scope PrefabDatabaseFixture("scratch_prefab_spawn_nested");
		let inner = fixture.StoreTurret("turret", 30);

		// The outer prefab: a shell holding an instance of the inner one.
		Guid outer;
		{
			let template = scope Scene("shell");
			template.AddSystem<AmmoManager>();
			let shell = template.CreateEntity("Shell");
			let payload = fixture.Resources.Bind<PrefabResource>(inner).Get.OpenPayload();
			defer delete payload;
			Test.Assert(PrefabSpawn.Spawn(template, payload, inner, shell).IsAssigned);
			let captured = scope MemoryStream();
			Test.Assert(PrefabCapture.Capture(template, shell, captured, .Text) case .Ok);
			let record = fixture.Database.RootGroup.CreateInstance("shell", PrefabDatabaseFixture.cPrefabTypeName);
			let document = scope PrefabDocument();
			document.Name.Set("shell");
			Test.Assert(record.WriteObject(document) case .Ok);
			Test.Assert(record.WriteData(SceneStorage.cStreamName, captured.Bytes, .Text) case .Ok);
			outer = record.Id;
		}

		let scene = scope Scene("level");
		let spawner = Spawner(scene, fixture);
		let root = spawner.Spawn(outer, .(0, 0, 0));
		Test.Assert(root.IsAssigned && (scene.GetEntityName(root) == "Shell"));
		Test.Assert(scene.PrefabInstanceCount == 2, "the outer instance and the one it nests");
		let nested = scene.GetFirstChild(root);
		Test.Assert(nested.IsAssigned && (scene.GetEntityName(nested) == "Turret"));
		Test.Assert(Rounds(scene, nested) == 30);
		Test.Assert(fixture.Resources.FindHandle(outer).State == .Ready);

		// The inner prefab rewritten: what it nests is the loaded inner prefab, not its file.
		Test.Assert(fixture.StoreTurret("turret", 45) == inner);
		Test.Assert(Rounds(scene, scene.GetFirstChild(spawner.Spawn(outer, .(0, 0, 0)))) == 30, "not read from disk");
		// Reloaded alone, the outer untouched: the outer's next spawn has it.
		fixture.Resources.Reload(inner);
		let again = spawner.Spawn(outer, .(0, 0, 0));
		Test.Assert(Rounds(scene, scene.GetFirstChild(again)) == 45, "the inner prefab's edit reaches the outer's spawn");
	}
}
