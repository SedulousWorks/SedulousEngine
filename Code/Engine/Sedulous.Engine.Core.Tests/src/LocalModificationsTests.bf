namespace Sedulous.Engine.Core.Tests;

using System;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.Core.Mathematics;

class LocalModificationsTests
{
	// --- Property Modifications ---

	[Test]
	public static void SetPropertyModified_MarksProperty()
	{
		let lm = scope LocalModifications();
		let entity = EntityHandle() { Index = 0, Generation = 1 };

		lm.SetPropertyModified(entity, "Test.HealthComponent", "Health");

		Test.Assert(lm.IsPropertyModified(entity, "Test.HealthComponent", "Health"));
		Test.Assert(lm.HasModifications(entity));
		Test.Assert(lm.TrackedEntityCount == 1);
	}

	[Test]
	public static void IsPropertyModified_ReturnsFalse_WhenNotSet()
	{
		let lm = scope LocalModifications();
		let entity = EntityHandle() { Index = 0, Generation = 1 };

		Test.Assert(!lm.IsPropertyModified(entity, "Test.HealthComponent", "Health"));
		Test.Assert(!lm.HasModifications(entity));
	}

	[Test]
	public static void SetPropertyModified_MultipleProperties()
	{
		let lm = scope LocalModifications();
		let entity = EntityHandle() { Index = 0, Generation = 1 };

		lm.SetPropertyModified(entity, "Test.HealthComponent", "Health");
		lm.SetPropertyModified(entity, "Test.HealthComponent", "Armor");
		lm.SetPropertyModified(entity, "Test.TargetComponent", "FollowDistance");

		Test.Assert(lm.IsPropertyModified(entity, "Test.HealthComponent", "Health"));
		Test.Assert(lm.IsPropertyModified(entity, "Test.HealthComponent", "Armor"));
		Test.Assert(lm.IsPropertyModified(entity, "Test.TargetComponent", "FollowDistance"));
		Test.Assert(!lm.IsPropertyModified(entity, "Test.HealthComponent", "IsInvulnerable"));
	}

	[Test]
	public static void SetPropertyModified_Idempotent()
	{
		let lm = scope LocalModifications();
		let entity = EntityHandle() { Index = 0, Generation = 1 };

		lm.SetPropertyModified(entity, "Test.HealthComponent", "Health");
		lm.SetPropertyModified(entity, "Test.HealthComponent", "Health");

		let state = lm.GetObjectState(entity);
		Test.Assert(state != null);
		Test.Assert(state.ModifiedPropertyCount == 1);
	}

	[Test]
	public static void ClearPropertyModified_RemovesProperty()
	{
		let lm = scope LocalModifications();
		let entity = EntityHandle() { Index = 0, Generation = 1 };

		lm.SetPropertyModified(entity, "Test.HealthComponent", "Health");
		lm.SetPropertyModified(entity, "Test.HealthComponent", "Armor");
		lm.ClearPropertyModified(entity, "Test.HealthComponent", "Health");

		Test.Assert(!lm.IsPropertyModified(entity, "Test.HealthComponent", "Health"));
		Test.Assert(lm.IsPropertyModified(entity, "Test.HealthComponent", "Armor"));
	}

	[Test]
	public static void ClearPropertyModified_RemovesEmptyState()
	{
		let lm = scope LocalModifications();
		let entity = EntityHandle() { Index = 0, Generation = 1 };

		lm.SetPropertyModified(entity, "Test.HealthComponent", "Health");
		lm.ClearPropertyModified(entity, "Test.HealthComponent", "Health");

		Test.Assert(!lm.HasModifications(entity));
		Test.Assert(lm.GetObjectState(entity) == null);
		Test.Assert(lm.TrackedEntityCount == 0);
	}

	[Test]
	public static void ClearPropertyModified_NoOpWhenNotSet()
	{
		let lm = scope LocalModifications();
		let entity = EntityHandle() { Index = 0, Generation = 1 };

		// Should not crash
		lm.ClearPropertyModified(entity, "Test.HealthComponent", "Health");
		Test.Assert(lm.TrackedEntityCount == 0);
	}

	// --- Added Children ---

	[Test]
	public static void AddChild_TracksAddedChild()
	{
		let lm = scope LocalModifications();
		let entity = EntityHandle() { Index = 0, Generation = 1 };
		let childId = Guid.Create();

		lm.AddChild(entity, childId);

		let state = lm.GetObjectState(entity);
		Test.Assert(state != null);
		Test.Assert(state.IsChildAdded(childId));
		Test.Assert(state.AddedChildCount == 1);
	}

	// --- Removed Children ---

	[Test]
	public static void RemoveChild_TracksRemovedChild()
	{
		let lm = scope LocalModifications();
		let entity = EntityHandle() { Index = 0, Generation = 1 };
		let childId = Guid.Create();

		lm.RemoveChild(entity, childId);

		let state = lm.GetObjectState(entity);
		Test.Assert(state != null);
		Test.Assert(state.IsChildRemoved(childId));
		Test.Assert(state.RemovedChildCount == 1);
	}

	// --- Multiple Entities ---

	[Test]
	public static void MultipleEntities_IndependentState()
	{
		let lm = scope LocalModifications();
		let e1 = EntityHandle() { Index = 0, Generation = 1 };
		let e2 = EntityHandle() { Index = 1, Generation = 1 };

		lm.SetPropertyModified(e1, "Test.HealthComponent", "Health");
		lm.SetPropertyModified(e2, "Test.HealthComponent", "Armor");

		Test.Assert(lm.IsPropertyModified(e1, "Test.HealthComponent", "Health"));
		Test.Assert(!lm.IsPropertyModified(e1, "Test.HealthComponent", "Armor"));
		Test.Assert(!lm.IsPropertyModified(e2, "Test.HealthComponent", "Health"));
		Test.Assert(lm.IsPropertyModified(e2, "Test.HealthComponent", "Armor"));
		Test.Assert(lm.TrackedEntityCount == 2);
	}

	// --- ClearEntity ---

	[Test]
	public static void ClearEntity_RemovesAllModifications()
	{
		let lm = scope LocalModifications();
		let entity = EntityHandle() { Index = 0, Generation = 1 };

		lm.SetPropertyModified(entity, "Test.HealthComponent", "Health");
		lm.SetPropertyModified(entity, "Test.HealthComponent", "Armor");
		lm.AddChild(entity, Guid.Create());
		lm.RemoveChild(entity, Guid.Create());

		lm.ClearEntity(entity);

		Test.Assert(!lm.HasModifications(entity));
		Test.Assert(lm.GetObjectState(entity) == null);
		Test.Assert(lm.TrackedEntityCount == 0);
	}

	[Test]
	public static void ClearEntity_DoesNotAffectOtherEntities()
	{
		let lm = scope LocalModifications();
		let e1 = EntityHandle() { Index = 0, Generation = 1 };
		let e2 = EntityHandle() { Index = 1, Generation = 1 };

		lm.SetPropertyModified(e1, "Test.HealthComponent", "Health");
		lm.SetPropertyModified(e2, "Test.HealthComponent", "Armor");

		lm.ClearEntity(e1);

		Test.Assert(!lm.HasModifications(e1));
		Test.Assert(lm.IsPropertyModified(e2, "Test.HealthComponent", "Armor"));
		Test.Assert(lm.TrackedEntityCount == 1);
	}

	[Test]
	public static void ClearEntity_NoOpForUnknownEntity()
	{
		let lm = scope LocalModifications();
		let entity = EntityHandle() { Index = 99, Generation = 1 };

		// Should not crash
		lm.ClearEntity(entity);
		Test.Assert(lm.TrackedEntityCount == 0);
	}

	// --- Scene Integration ---

	[Test]
	public static void Scene_HasLocalModifications()
	{
		let scene = scope Scene();
		Test.Assert(scene.LocalModifications != null);
		Test.Assert(scene.LocalModifications.TrackedEntityCount == 0);
	}

	[Test]
	public static void Scene_DestroyEntity_ClearsModifications()
	{
		let scene = scope Scene();
		let entity = scene.CreateEntity("PrefabEntity");

		scene.LocalModifications.SetPropertyModified(entity, "Test.HealthComponent", "Health");
		Test.Assert(scene.LocalModifications.HasModifications(entity));

		scene.DestroyEntity(entity);

		Test.Assert(!scene.LocalModifications.HasModifications(entity));
		Test.Assert(scene.LocalModifications.TrackedEntityCount == 0);
	}

	// --- ObjectState direct tests ---

	[Test]
	public static void ObjectState_IsEmpty_WhenNew()
	{
		let state = scope ObjectState();
		Test.Assert(state.IsEmpty);
		Test.Assert(state.ModifiedPropertyCount == 0);
		Test.Assert(state.AddedChildCount == 0);
		Test.Assert(state.RemovedChildCount == 0);
	}

	[Test]
	public static void ObjectState_Clear_ResetsEverything()
	{
		let state = scope ObjectState();
		state.AddModifiedProperty("Test.HealthComponent", "Health");
		state.AddChild(Guid.Create());
		state.RemoveChild(Guid.Create());

		state.Clear();

		Test.Assert(state.IsEmpty);
	}
}
