namespace Sedulous.Scenes.Tests;

using System;

class ActiveStateTests
{
	[Test]
	public static void SetActive_PropagatestoComponents()
	{
		let scene = scope Scene();
		let manager = new TestComponentManager();
		scene.AddModule(manager);

		let entity = scene.CreateEntity();
		let handle = manager.CreateComponent(entity);

		Test.Assert(manager.Get(handle).IsActive);

		scene.SetActive(entity, false);
		Test.Assert(!manager.Get(handle).IsActive);

		scene.SetActive(entity, true);
		Test.Assert(manager.Get(handle).IsActive);
	}

	[Test]
	public static void NewComponent_InheritsEntityActiveState()
	{
		let scene = scope Scene();
		let manager = new TestComponentManager();
		scene.AddModule(manager);

		let entity = scene.CreateEntity();
		scene.SetActive(entity, false);

		let handle = manager.CreateComponent(entity);
		Test.Assert(!manager.Get(handle).IsActive);
	}

	[Test]
	public static void GetForEntity_FindsComponent()
	{
		let scene = scope Scene();
		let manager = new TestComponentManager();
		scene.AddModule(manager);

		let entity = scene.CreateEntity();
		let handle = manager.CreateComponent(entity);
		manager.Get(handle).Score = 99;

		let found = manager.GetForEntity(entity);
		Test.Assert(found != null);
		Test.Assert(found.Score == 99);
	}

	[Test]
	public static void GetForEntity_ReturnsNull_WhenNoComponent()
	{
		let scene = scope Scene();
		let manager = new TestComponentManager();
		scene.AddModule(manager);

		let entity = scene.CreateEntity();
		Test.Assert(manager.GetForEntity(entity) == null);
	}
}
