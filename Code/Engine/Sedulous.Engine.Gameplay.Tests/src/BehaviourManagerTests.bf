using System;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;
using internal Sedulous.Engine.Gameplay;

namespace Sedulous.Engine.Gameplay.Tests;

/// The manager owns its behaviours: one per entity, found by entity, deleted on removal, on
/// the entity's destruction and with the manager, OnDestroy first only for one that started.
/// The pool cases mirror Scene.Tests' ComponentTests for a struct pool.
class BehaviourManagerTests
{
	[Test]
	public static void AddAttachesAndGetFindsByEntity()
	{
		let scene = scope Scene();
		let movers = scene.AddSystem<BehaviourManager<Mover>>();
		let a = scene.CreateEntity("a");
		let b = scene.CreateEntity("b");

		let mover = movers.Add(a);
		Test.Assert(mover.Scene == scene);
		Test.Assert(mover.Entity == a);
		Test.Assert(mover.Enabled);
		Test.Assert(mover.IsActive);
		Test.Assert(movers.Get(a) == mover);
		Test.Assert(movers.Get(b) == null);
		Test.Assert(movers.HasComponent(a) && !movers.HasComponent(b));
		Test.Assert(movers.ComponentType == typeof(Mover));
		Test.Assert(movers.SerializationTypeId == "test.mover");

		Test.Assert(movers.AddDefaultComponent(b));
		Test.Assert(!movers.AddDefaultComponent(b), "one per entity");
		Test.Assert(movers.ComponentCount == 2);
		Test.Assert(movers.OwnerHandles.Length == 2);

		// IsActive follows Enabled and the entity's own active state.
		mover.Enabled = false;
		Test.Assert(!mover.IsActive);
		mover.Enabled = true;
		scene.SetActive(a, false);
		Test.Assert(!mover.IsActive);
	}

	/// The address the tools read fields through is the object itself, so a field read at
	/// its reflected offset from it is the live field.
	[Test]
	public static void TheComponentAddressIsTheInstance()
	{
		let scene = scope Scene();
		let movers = scene.AddSystem<BehaviourManager<Mover>>();
		let entity = scene.CreateEntity("e");
		let mover = movers.Add(entity);
		mover.Speed = 4.25f;

		let address = movers.GetComponentAddress(entity);
		Test.Assert(address == Internal.UnsafeCastToPtr(mover));
		Test.Assert(movers.GetComponentAddress(scene.CreateEntity("none")) == null);

		bool found = false;
		for (let field in typeof(Mover).GetFields())
		{
			if (field.Name != "Speed")
				continue;
			if (field.GetValueReference<float>(address, typeof(Mover)) case .Ok(let speed))
				found = *speed == 4.25f;
		}
		Test.Assert(found, "[Behaviour] reflects the fields, read at their offsets from the instance");
	}

	/// A behaviour reaches a component and a sibling behaviour on its own entity, and gets
	/// null where there is none or no manager for it.
	[Test]
	public static void ABehaviourReachesItsEntitysComponentsAndBehaviours()
	{
		let scene = scope Scene();
		let movers = scene.AddSystem<BehaviourManager<Mover>>();
		let tags = scene.AddSystem<ComponentManager<Tag>>();
		let a = scene.CreateEntity("a");
		let b = scene.CreateEntity("b");

		let mover = movers.Add(a);
		Test.Assert(mover.Get<Tag>() == null);
		Test.Assert(mover.Get<Marker>() == null, "no manager for it");

		tags.Add(a).Value = 12;
		tags.Add(b).Value = 13;
		Test.Assert(mover.Get<Tag>().Value == 12, "its own entity's");

		let markers = scene.AddSystem<BehaviourManager<Marker>>();
		Test.Assert(mover.Get<Marker>() == null);
		let marker = markers.Add(a);
		markers.Add(b);
		Test.Assert(mover.Get<Marker>() == marker);
		Test.Assert(marker.Get<Mover>() == mover);
	}

	/// Removal swaps the last into the hole and the index follows it.
	[Test]
	public static void RemovalKeepsTheRestFindable()
	{
		let scene = scope Scene();
		let movers = scene.AddSystem<BehaviourManager<Mover>>();
		let a = scene.CreateEntity("a");
		let b = scene.CreateEntity("b");
		let c = scene.CreateEntity("c");
		movers.Add(a).Lives = 1;
		movers.Add(b).Lives = 2;
		movers.Add(c).Lives = 3;

		movers.RemoveComponent(a);
		Test.Assert(movers.Count == 2);
		Test.Assert(movers.Get(a) == null);
		Test.Assert(movers.Get(b).Lives == 2);
		Test.Assert(movers.Get(c).Lives == 3);
		Test.Assert(movers.Instances[0].Entity == movers.OwnerHandles[0]);

		movers.RemoveComponent(a); // already gone: a no op
		Test.Assert(movers.Count == 2);

		// A stale handle reads as absent.
		scene.DestroyEntity(b);
		let reused = scene.CreateEntity("reused");
		Test.Assert(movers.Get(b) == null);
		Test.Assert(movers.Get(reused) == null);
	}

	/// Removing deletes; OnDestroy runs only for a behaviour that started, and while it is
	/// still attached to its scene.
	[Test]
	public static void RemovalCallsOnDestroyOnlyWhenStarted()
	{
		let scene = scope Scene();
		let tags = scene.AddSystem<ComponentManager<Tag>>();
		let movers = scene.AddSystem<BehaviourManager<Mover>>();
		let started = scene.CreateEntity("started");
		let fresh = scene.CreateEntity("fresh");
		tags.Add(started);
		movers.Add(started).mStarted = true;
		movers.Add(fresh);

		Mover.Destroyed = 0;
		Mover.LastDestroyFoundTag = false;
		movers.RemoveComponent(fresh);
		Test.Assert(Mover.Destroyed == 0, "never started: no OnDestroy");
		movers.RemoveComponent(started);
		Test.Assert(Mover.Destroyed == 1);
		Test.Assert(Mover.LastDestroyFoundTag, "OnDestroy before its entity's components go");
		Test.Assert(movers.Count == 0);
	}

	/// Destroying an entity deletes its behaviour, the same way.
	[Test]
	public static void DestroyingTheEntityDeletesItsBehaviour()
	{
		let scene = scope Scene();
		let movers = scene.AddSystem<BehaviourManager<Mover>>();
		let parent = scene.CreateEntity("parent");
		let child = scene.CreateEntity("child");
		let fresh = scene.CreateEntity("fresh");
		scene.SetParent(child, parent);
		movers.Add(parent).mStarted = true;
		movers.Add(child).mStarted = true;
		movers.Add(fresh);

		Mover.Destroyed = 0;
		scene.DestroyEntity(parent);
		Test.Assert(Mover.Destroyed == 2, "the subtree's started behaviours");
		Test.Assert(movers.Count == 1);

		scene.DestroyEntity(fresh);
		Test.Assert(Mover.Destroyed == 2);
		Test.Assert(movers.Count == 0);
	}

	/// The manager going (the scene torn down, or the manager removed) deletes what it holds,
	/// OnDestroy for the started. At teardown the scene is still whole, so OnDestroy reaches
	/// a component of an older manager.
	[Test]
	public static void TheManagerGoingDeletesItsBehaviours()
	{
		Mover.Destroyed = 0;
		Mover.LastDestroyFoundTag = false;
		{
			let torn = scope Scene();
			let tags = torn.AddSystem<ComponentManager<Tag>>();
			let pool = torn.AddSystem<BehaviourManager<Mover>>();
			let started = torn.CreateEntity("started");
			tags.Add(started);
			pool.Add(started).mStarted = true;
			pool.Add(torn.CreateEntity("fresh"));
		}
		Test.Assert(Mover.Destroyed == 1, "the scene's teardown");
		Test.Assert(Mover.LastDestroyFoundTag, "the scene still whole");

		Mover.Destroyed = 0;
		let kept = scope Scene();
		let movers = kept.AddSystem<BehaviourManager<Mover>>();
		movers.Add(kept.CreateEntity("started")).mStarted = true;
		Test.Assert(kept.RemoveSystem<BehaviourManager<Mover>>());
		Test.Assert(Mover.Destroyed == 1, "the manager removed");
	}
}
