namespace Sedulous.Engine.Core.Tests;

using System;

class GuidTests
{
	[Test]
	public static void Entity_HasPersistentId()
	{
		let scene = scope Scene();
		let entity = scene.CreateEntity();

		let id = scene.GetEntityId(entity);
		Test.Assert(id != .Empty);
	}

	[Test]
	public static void TwoEntities_DifferentGuids()
	{
		let scene = scope Scene();
		let e1 = scene.CreateEntity();
		let e2 = scene.CreateEntity();

		Test.Assert(scene.GetEntityId(e1) != scene.GetEntityId(e2));
	}

	[Test]
	public static void FindEntity_ByGuid()
	{
		let scene = scope Scene();
		let entity = scene.CreateEntity("TestEntity");
		let id = scene.GetEntityId(entity);

		let found = scene.FindEntity(id);
		Test.Assert(found == entity);
	}

	[Test]
	public static void FindEntity_InvalidGuid_ReturnsInvalid()
	{
		let scene = scope Scene();
		let found = scene.FindEntity(Guid.Create());
		Test.Assert(!found.IsAssigned);
	}

	[Test]
	public static void CreateEntity_WithSpecificGuid()
	{
		let scene = scope Scene();
		let specificId = Guid.Create();

		let entity = scene.CreateEntity(specificId, "Restored");
		Test.Assert(scene.GetEntityId(entity) == specificId);
		Test.Assert(scene.FindEntity(specificId) == entity);
	}

	[Test]
	public static void DestroyEntity_RemovesFromIdMap()
	{
		let scene = scope Scene();
		let entity = scene.CreateEntity();
		let id = scene.GetEntityId(entity);

		scene.DestroyEntity(entity);
		Test.Assert(scene.FindEntity(id) == .Invalid);
	}

	[Test]
	public static void EntityRef_ResolveAfterCreation()
	{
		let scene = scope Scene();
		let entity = scene.CreateEntity();

		// Create ref from scene + handle
		var eref = EntityRef(scene, entity);
		Test.Assert(eref.IsSet);
		Test.Assert(eref.CachedHandle == entity);

		// Resolve against same scene
		Test.Assert(eref.Resolve(scene));
		Test.Assert(eref.CachedHandle == entity);
	}

	[Test]
	public static void EntityRef_ResolveByGuid()
	{
		let scene = scope Scene();
		let entity = scene.CreateEntity();
		let id = scene.GetEntityId(entity);

		// Create ref from just a Guid (as if deserialized)
		var eref = EntityRef(id);
		Test.Assert(eref.IsSet);
		Test.Assert(!eref.CachedHandle.IsAssigned); // not resolved yet

		// Resolve
		Test.Assert(eref.Resolve(scene));
		Test.Assert(eref.CachedHandle == entity);
	}

	[Test]
	public static void EntityRef_InvalidAfterDestroy()
	{
		let scene = scope Scene();
		let entity = scene.CreateEntity();
		var eref = EntityRef(scene, entity);

		scene.DestroyEntity(entity);
		Test.Assert(!eref.IsValid(scene));
	}
}
