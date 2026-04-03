namespace Sedulous.Scenes.Tests;

using System;

/// Test component with some data fields.
class TestComponent : Component
{
	public float Health = 100;
	public int32 Score = 0;
}

/// Test component manager.
class TestComponentManager : ComponentManager<TestComponent>
{
}

class ComponentTests
{
	[Test]
	public static void CreateComponent_ReturnsValidHandle()
	{
		let scene = scope Scene();
		let manager = new TestComponentManager();
		scene.AddModule(manager);

		let entity = scene.CreateEntity();
		let handle = manager.CreateComponent(entity);

		Test.Assert(handle.IsAssigned);
		Test.Assert(manager.IsValid(handle));
		Test.Assert(manager.ActiveCount == 1);
	}

	[Test]
	public static void GetComponent_ReturnsData()
	{
		let scene = scope Scene();
		let manager = new TestComponentManager();
		scene.AddModule(manager);

		let entity = scene.CreateEntity();
		let handle = manager.CreateComponent(entity);

		let comp = manager.Get(handle);
		Test.Assert(comp != null);
		Test.Assert(comp.Health == 100);
		Test.Assert(comp.Owner == entity);
	}

	[Test]
	public static void ModifyComponent_PersistsChanges()
	{
		let scene = scope Scene();
		let manager = new TestComponentManager();
		scene.AddModule(manager);

		let entity = scene.CreateEntity();
		let handle = manager.CreateComponent(entity);

		let comp = manager.Get(handle);
		comp.Health = 50;
		comp.Score = 42;

		let comp2 = manager.Get(handle);
		Test.Assert(comp2.Health == 50);
		Test.Assert(comp2.Score == 42);
	}

	[Test]
	public static void DestroyComponent_InvalidatesHandle()
	{
		let scene = scope Scene();
		let manager = new TestComponentManager();
		scene.AddModule(manager);

		let entity = scene.CreateEntity();
		let handle = manager.CreateComponent(entity);

		manager.DestroyComponent(handle);
		Test.Assert(!manager.IsValid(handle));
		Test.Assert(manager.Get(handle) == null);
		Test.Assert(manager.ActiveCount == 0);
	}

	[Test]
	public static void DestroyEntity_DestroysComponents()
	{
		let scene = scope Scene();
		let manager = new TestComponentManager();
		scene.AddModule(manager);

		let entity = scene.CreateEntity();
		let handle = manager.CreateComponent(entity);

		scene.DestroyEntity(entity);
		Test.Assert(!manager.IsValid(handle));
		Test.Assert(manager.ActiveCount == 0);
	}

	[Test]
	public static void StaleHandle_ReturnsNull()
	{
		let scene = scope Scene();
		let manager = new TestComponentManager();
		scene.AddModule(manager);

		let entity = scene.CreateEntity();
		let handle = manager.CreateComponent(entity);
		manager.DestroyComponent(handle);

		// Create a new component in the same slot
		let entity2 = scene.CreateEntity();
		let handle2 = manager.CreateComponent(entity2);

		// Old handle should not resolve to new component
		Test.Assert(manager.Get(handle) == null);
		Test.Assert(manager.Get(handle2) != null);
	}

	[Test]
	public static void IterateActiveComponents()
	{
		let scene = scope Scene();
		let manager = new TestComponentManager();
		scene.AddModule(manager);

		let e1 = scene.CreateEntity();
		let e2 = scene.CreateEntity();
		let e3 = scene.CreateEntity();

		let h1 = manager.CreateComponent(e1);
		let h2 = manager.CreateComponent(e2);
		let h3 = manager.CreateComponent(e3);

		manager.Get(h1).Score = 1;
		manager.Get(h2).Score = 2;
		manager.Get(h3).Score = 3;

		// Destroy middle one
		manager.DestroyComponent(h2);

		int32 sum = 0;
		int32 count = 0;
		for (let comp in manager.ActiveComponents)
		{
			sum += comp.Score;
			count++;
		}

		Test.Assert(count == 2);
		Test.Assert(sum == 4); // 1 + 3
	}
}
