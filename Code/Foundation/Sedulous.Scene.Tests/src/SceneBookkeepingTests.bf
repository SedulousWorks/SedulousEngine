using System;
using System.Collections;
using Sedulous.Scene;

namespace Sedulous.Scene.Tests;

/// The records a scene HOLDS but does not interpret: prefab instance state, parked prefab
/// descriptors, and the component and settings records whose code has not arrived.
///
/// Scene.Resource drives all of it. The scene owns it because the scene owns the entities
/// it points at, and these are about that ownership behaving.
class SceneBookkeepingTests
{
	private static Guid Id(uint32 value)
		=> .(value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);

	/// An instance is found by its ROOT, and removing it frees the record without touching
	/// the entities, which are the caller's business.
	[Test]
	public static void PrefabInstanceStateIsFoundByItsRootAndRemovedByIt()
	{
		let scene = scope Scene("prefabs");
		let root = scene.CreateEntity("root");
		let rootId = scene.GetEntityId(root);

		let state = new PrefabInstanceState();
		state.PrefabId = Id(1);
		state.RootEntityId = rootId;
		scene.AddPrefabInstance(state);

		Test.Assert(scene.PrefabInstanceCount == 1);
		Test.Assert(scene.FindPrefabInstanceByRoot(rootId) === state);
		Test.Assert(scene.FindPrefabInstanceByRoot(Id(99)) == null);

		scene.RemovePrefabInstance(rootId);
		Test.Assert(scene.PrefabInstanceCount == 0);
		Test.Assert(scene.IsValid(root), "the entities were left alone");
	}

	/// A record whose root entity was DESTROYED is pruned during the walk, so nothing has
	/// to be kept in step through a destroy hook.
	[Test]
	public static void WalkingPrefabInstancesPrunesTheOnesWhoseRootIsGone()
	{
		let scene = scope Scene("prefabs");
		let liveRoot = scene.CreateEntity("live");
		let deadRoot = scene.CreateEntity("dead");

		let live = new PrefabInstanceState();
		live.RootEntityId = scene.GetEntityId(liveRoot);
		scene.AddPrefabInstance(live);

		let dead = new PrefabInstanceState();
		dead.RootEntityId = scene.GetEntityId(deadRoot);
		scene.AddPrefabInstance(dead);

		scene.DestroyEntity(deadRoot);

		int visited = 0;
		scene.ForEachPrefabInstance(scope [&](state) =>
		{
			visited++;
			Test.Assert(state === live);
		});

		Test.Assert(visited == 1);
		Test.Assert(scene.PrefabInstanceCount == 1, "the orphan was pruned, not merely skipped");
	}

	/// A parked descriptor is walked WITHOUT being consumed, so a load then save with no
	/// resolve in between re-emits it verbatim and stays lossless. Taking them is the
	/// separate, consuming operation.
	[Test]
	public static void PendingPrefabsAreWalkedWithoutConsumingAndTakenSeparately()
	{
		let scene = scope Scene("pending");

		let first = new PendingPrefabInstance();
		first.PrefabId = Id(1);
		scene.AddPendingPrefabInstance(first);
		let second = new PendingPrefabInstance();
		second.PrefabId = Id(2);
		scene.AddPendingPrefabInstance(second);

		int walked = 0;
		scene.ForEachPendingPrefabInstance(scope [&](pending) => { walked++; });
		Test.Assert(walked == 2);
		Test.Assert(scene.PendingPrefabInstanceCount == 2, "walking consumed nothing");

		let taken = scope List<PendingPrefabInstance>();
		defer { ClearAndDeleteItems!(taken); }
		scene.TakePendingPrefabInstances(taken);

		Test.Assert(taken.Count == 2);
		Test.Assert(scene.PendingPrefabInstanceCount == 0, "and taking took them");
	}

	/// A component record whose manager is absent is kept VERBATIM and taken by type when
	/// the manager arrives. Never dropped: dropping it would silently lose a plugin's data
	/// from every save made while the plugin was not loaded.
	[Test]
	public static void UnresolvedComponentsAreKeptAndTakenByType()
	{
		let scene = scope Scene("unresolved");

		let a = new UnresolvedComponent();
		a.TypeId.Set("plugin.Health");
		a.Owner = Id(1);
		scene.AddUnresolvedComponent(a);

		let b = new UnresolvedComponent();
		b.TypeId.Set("plugin.Health");
		b.Owner = Id(2);
		scene.AddUnresolvedComponent(b);

		let other = new UnresolvedComponent();
		other.TypeId.Set("plugin.Mana");
		scene.AddUnresolvedComponent(other);

		Test.Assert(scene.UnresolvedComponents.Length == 3);

		let taken = scope List<UnresolvedComponent>();
		defer { ClearAndDeleteItems!(taken); }
		scene.TakeUnresolvedComponents("plugin.Health", taken);

		Test.Assert(taken.Count == 2, "both of that type");
		Test.Assert(scene.UnresolvedComponents.Length == 1, "and the other type stayed");
		Test.Assert(scene.UnresolvedComponents[0].TypeId == "plugin.Mana");
	}

	/// The same bargain for a SYSTEM's settings block, one level up. There is at most one
	/// per system, so taking it is a single record rather than a list.
	[Test]
	public static void UnresolvedSettingsAreKeptAndTakenBySystem()
	{
		let scene = scope Scene("unresolved");

		let settings = new UnresolvedSettings();
		settings.SystemId.Set("plugin.contrib");
		scene.AddUnresolvedSettings(settings);
		Test.Assert(scene.UnresolvedSettingsRecords.Length == 1);

		Test.Assert(scene.TakeUnresolvedSettings("plugin.missing") == null);
		Test.Assert(scene.UnresolvedSettingsRecords.Length == 1, "a miss takes nothing");

		let taken = scene.TakeUnresolvedSettings("plugin.contrib");
		defer delete taken;
		Test.Assert(taken === settings);
		Test.Assert(scene.UnresolvedSettingsRecords.Length == 0);
	}
}
