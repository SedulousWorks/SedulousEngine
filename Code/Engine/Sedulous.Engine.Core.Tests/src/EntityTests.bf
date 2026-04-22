namespace Sedulous.Engine.Core.Tests;

using System;

class EntityTests
{
	[Test]
	public static void CreateEntity_ReturnsValidHandle()
	{
		let scene = scope Scene();
		let entity = scene.CreateEntity();

		Test.Assert(entity.IsAssigned);
		Test.Assert(scene.IsValid(entity));
		Test.Assert(scene.EntityCount == 1);
	}

	[Test]
	public static void CreateMultipleEntities_UniqueHandles()
	{
		let scene = scope Scene();
		let e1 = scene.CreateEntity();
		let e2 = scene.CreateEntity();
		let e3 = scene.CreateEntity();

		Test.Assert(e1 != e2);
		Test.Assert(e2 != e3);
		Test.Assert(scene.EntityCount == 3);
	}

	[Test]
	public static void DestroyEntity_InvalidatesHandle()
	{
		let scene = scope Scene();
		let entity = scene.CreateEntity();
		Test.Assert(scene.IsValid(entity));

		scene.DestroyEntity(entity);
		Test.Assert(!scene.IsValid(entity));
		Test.Assert(scene.EntityCount == 0);
	}

	[Test]
	public static void DestroyEntity_SlotReused_GenerationIncremented()
	{
		let scene = scope Scene();
		let e1 = scene.CreateEntity();
		let oldIndex = e1.Index;

		scene.DestroyEntity(e1);
		let e2 = scene.CreateEntity();

		// Slot reused
		Test.Assert(e2.Index == oldIndex);
		// Generation incremented - old handle no longer valid
		Test.Assert(e2.Generation > e1.Generation);
		Test.Assert(!scene.IsValid(e1));
		Test.Assert(scene.IsValid(e2));
	}

	[Test]
	public static void EntityName()
	{
		let scene = scope Scene();
		let entity = scene.CreateEntity("Player");

		Test.Assert(scene.GetEntityName(entity) == "Player");
	}

	[Test]
	public static void InvalidHandle_IsNotValid()
	{
		let scene = scope Scene();
		Test.Assert(!scene.IsValid(.Invalid));
	}

	[Test]
	public static void SetActive_TogglesState()
	{
		let scene = scope Scene();
		let entity = scene.CreateEntity();

		Test.Assert(scene.IsActive(entity));

		scene.SetActive(entity, false);
		Test.Assert(!scene.IsActive(entity));

		scene.SetActive(entity, true);
		Test.Assert(scene.IsActive(entity));
	}

	[Test]
	public static void DestroyEntity_DestroysChildren()
	{
		let scene = scope Scene();
		let parent = scene.CreateEntity("Parent");
		let child1 = scene.CreateEntity("Child1");
		let child2 = scene.CreateEntity("Child2");

		scene.SetParent(child1, parent);
		scene.SetParent(child2, parent);
		Test.Assert(scene.EntityCount == 3);

		scene.DestroyEntity(parent);
		Test.Assert(!scene.IsValid(parent));
		Test.Assert(!scene.IsValid(child1));
		Test.Assert(!scene.IsValid(child2));
		Test.Assert(scene.EntityCount == 0);
	}
}
