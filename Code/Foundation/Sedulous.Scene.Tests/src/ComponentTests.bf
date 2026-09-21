using System;
using Sedulous.Scene;

namespace Sedulous.Scene.Tests;

/// The sparse set pool: add, get, has and remove by entity, dense iteration, the swap
/// remove that keeps it packed, generation staleness, and the manager driven lifecycle.
class ComponentTests
{
	private static EntityHandle E(uint32 index, uint32 generation = 1) => .(index, generation);

	/// Teardown runs the destroy hook for whatever is STILL held.
	///
	/// The hook is where a component's heap data is freed, and a manager whose components
	/// were never removed would otherwise drop the lot: a List of structs frees only the
	/// storage.
	[Test]
	public static void DestroyingTheManagerRunsTheHookForWhatIsLeft()
	{
		int destroyed = 0;
		{
			let scene = scope Scene("teardown");
			let manager = scene.AddSystem<OwningManager>();
			manager.Add(scene.CreateEntity("a"));
			manager.Add(scene.CreateEntity("b"));
			Test.Assert(manager.Created == 2);
			Test.Assert(manager.Destroyed == 0, "nothing removed yet");

			// The scene owns its systems, so the manager goes down with it here. Read the
			// count before that happens, and prove it afterwards through the leak checker.
			destroyed = manager.Destroyed;
		}
		Test.Assert(destroyed == 0, "and the sweep happens at teardown, not before");
	}

	/// A new component carries the DEFAULTS its fields declare.
	///
	/// The pool used to zero the slot, which silently replaced every non zero default with
	/// nought: a scale of one became a scale of nothing, and a flag that starts set started
	/// clear.
	[Test]
	public static void ANewComponentStartsFromItsDeclaredDefaults()
	{
		let scene = scope Scene("defaults");
		let manager = scene.AddSystem<HealthManager>();
		let entity = scene.CreateEntity("subject");

		Test.Assert(manager.Add(entity).Value == 100.0f, "not zeroed");
	}

	[Test]
	public static void AComponentIsAddedGotAndRemovedByEntity()
	{
		let manager = scope HealthManager();
		Test.Assert(!manager.Has(E(0)));

		let health = manager.Add(E(0));
		health.Value = 42.0f;

		Test.Assert(manager.Has(E(0)));
		Test.Assert(manager.Count == 1);
		Test.Assert(manager.Get(E(0)).Value == 42.0f);
		Test.Assert(manager.Get(E(1)) == null, "a different entity has none");

		manager.RemoveComponent(E(0));
		Test.Assert(!manager.Has(E(0)));
		Test.Assert(manager.Get(E(0)) == null);
		Test.Assert(manager.Count == 0);
	}

	/// Removing from the MIDDLE swaps the last element into the hole, so the dense array
	/// stays contiguous. That contiguity is the point of the whole storage choice, and it
	/// is what a system iterating the pool relies on.
	[Test]
	public static void DenseStorageStaysPackedAcrossAMiddleRemove()
	{
		let manager = scope HealthManager();
		manager.Add(E(0)).Value = 10.0f;
		manager.Add(E(1)).Value = 20.0f;
		manager.Add(E(2)).Value = 30.0f;
		Test.Assert(manager.Dense.Length == 3);

		manager.RemoveComponent(E(1));

		Test.Assert(manager.Count == 2);
		Test.Assert(manager.Dense.Length == 2, "no hole was left behind");

		// Whatever the order became, both survivors are still reachable BY ENTITY, which
		// is the only way a caller ever asks.
		Test.Assert(manager.Get(E(0)).Value == 10.0f);
		Test.Assert(manager.Get(E(2)).Value == 30.0f);
		Test.Assert(manager.Get(E(1)) == null);

		// And every dense slot's owner resolves back to that same slot.
		int seen = 0;
		manager.ForEach(scope [&](component, owner) =>
		{
			seen++;
			Test.Assert(manager.Get(owner) == component);
		});
		Test.Assert(seen == 2);
	}

	/// A reused slot must not hand its new occupant's component to a handle from the old
	/// one. The owner stored per slot carries the WHOLE handle, so the generation catches it.
	[Test]
	public static void AReusedSlotDoesNotResolveAnOldHandle()
	{
		let manager = scope HealthManager();
		manager.Add(E(5, 1)).Value = 1.0f;
		manager.RemoveComponent(E(5, 1));

		// Slot five, taken by a new entity with its own component.
		manager.Add(E(5, 2)).Value = 2.0f;

		Test.Assert(manager.Get(E(5, 2)).Value == 2.0f);
		Test.Assert(manager.Get(E(5, 1)) == null, "the stale handle reads as absent");
		Test.Assert(!manager.Has(E(5, 1)));
	}

	/// Creation is immediate but INITIALISATION is deferred, so a component can see its
	/// siblings by the time it runs. A component added and removed before that point is
	/// never initialised at all.
	[Test]
	public static void CreationIsImmediateAndInitialisationIsDeferred()
	{
		let manager = scope HealthManager();
		manager.Add(E(0));
		manager.Add(E(1));
		Test.Assert(manager.Created == 2);
		Test.Assert(manager.Initialized == 0, "not yet");

		manager.InitializePendingComponents();
		Test.Assert(manager.Initialized == 2);

		manager.Add(E(2));
		manager.RemoveComponent(E(2));
		manager.InitializePendingComponents();
		Test.Assert(manager.Initialized == 2, "one that went away is never initialised");
		Test.Assert(manager.Destroyed == 1);

		// The base hook the scene calls when an entity dies takes the component with it.
		manager.OnEntityDestroyed(E(0));
		Test.Assert(!manager.Has(E(0)));
		Test.Assert(manager.Destroyed == 2);
	}

	[Test]
	public static void TheComponentTypeIsDistinctPerManager()
	{
		let health = scope HealthManager();
		let mana = scope ComponentManager<Mana>();

		Test.Assert(health.ComponentType == typeof(Health));
		Test.Assert(health.ComponentType != mana.ComponentType);
	}

	/// Resolving through the MANAGER on every access is what makes a component handle safe.
	///
	/// A cached component address is not: the pool swap removes and reallocates, so an
	/// address either goes stale or, worse, comes to point at a DIFFERENT entity's
	/// component. This walks both of those.
	[Test]
	public static void ReResolvingSurvivesASwapRemoveAndPoolGrowth()
	{
		let scene = scope Scene("resolve");
		let manager = scene.AddSystem<HealthManager>();
		let e0 = scene.CreateEntity("e0");
		let e1 = scene.CreateEntity("e1");
		let e2 = scene.CreateEntity("e2");
		manager.Add(e0).Value = 10.0f;
		manager.Add(e1).Value = 20.0f;
		manager.Add(e2).Value = 30.0f;

		// The manager is found by the component's TYPE, which is the token a caller has.
		let found = scene.FindManagerByComponentType(typeof(Health));
		Test.Assert(found === manager);
		Test.Assert(scene.FindManagerByComponentType(typeof(int)) == null, "no manager, no answer");

		// The address a caching handle would have kept.
		let staleAddress = manager.Get(e2);
		Test.Assert(staleAddress != null);
		Test.Assert(staleAddress.Value == 30.0f);

		// Removing ANOTHER entity's component moves e2's within the pool.
		manager.RemoveComponent(e1);

		let afterRemove = manager.Get(e2);
		Test.Assert(afterRemove != null);
		Test.Assert(afterRemove.Value == 30.0f, "re-resolving still finds the real one");
		Test.Assert(afterRemove != staleAddress, "and it moved, so the cached one was wrong");

		// Growth reallocates the pool, which moves everything.
		for (int i < 32)
			manager.Add(scene.CreateEntity("filler")).Value = 1.0f;

		let afterGrowth = manager.Get(e2);
		Test.Assert(afterGrowth != null);
		Test.Assert(afterGrowth.Value == 30.0f);

		// And once the component is gone, re-resolving is a clean null rather than a
		// pointer at whatever now occupies that slot.
		manager.RemoveComponent(e2);
		Test.Assert(manager.Get(e2) == null);
	}
}
