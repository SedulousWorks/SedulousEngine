using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Scene.Resource.Tests;

/// A scene written and read back.
///
/// The one property that matters: what comes back IS what went out. A serializer is the
/// only code in an engine whose bugs are permanent, because a bad write is discovered when
/// the save is already the only copy.
class SceneRoundTripTests
{
	/// Builds a scene worth saving: a hierarchy in a deliberate sibling order, components
	/// on some of it, and a settings block.
	private static void Populate(Scene scene)
	{
		scene.SetName("world");
		let manager = scene.AddSystem<HealthManager>();
		let world = scene.AddSystem<WorldSystem>();
		world.Settings.Gravity = -3.5f;
		world.Settings.Wind = .(1, 2, 3);

		let player = scene.CreateEntity("Player");
		let weapon = scene.CreateEntity("Weapon");
		let muzzle = scene.CreateEntity("Muzzle");
		let enemy = scene.CreateEntity("Enemy");
		scene.SetParent(weapon, player);
		scene.SetParent(muzzle, weapon);

		var transform = Transform();
		transform.Position = .(1, 2, 3);
		transform.Scale = .(2, 2, 2);
		scene.SetLocalTransform(player, transform);
		scene.SetActive(enemy, false);

		manager.Add(player).Value = 55.0f;
		manager.Add(enemy).Armour = 7;
	}

	private static void RoundTrip(Scene source, Scene target, SceneStreamEncoding encoding)
	{
		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			SceneSerializer.SerializeScene(writer, source, .Referenced, true, encoding);
		}
		buffer.Seek(0, .Begin);
		let reader = scope BinarySerializer(buffer, .Read);
		SceneSerializer.SerializeScene(reader, target, .Referenced, true, encoding);
	}

	[Test]
	public static void AWholeSceneSurvivesABinaryRoundTrip()
	{
		let source = scope Scene();
		Populate(source);

		let target = scope Scene();
		let manager = target.AddSystem<HealthManager>();
		let world = target.AddSystem<WorldSystem>();

		RoundTrip(source, target, .Binary);

		Test.Assert(target.Name == "world");
		Test.Assert(target.EntityCount == 4);

		// Identity survives: an entity is found by the SAME guid it was saved under.
		for (let name in String[4]("Player", "Weapon", "Muzzle", "Enemy"))
		{
			let original = source.FindEntityByName(name);
			let restored = target.FindEntity(source.GetEntityId(original));
			Test.Assert(restored.IsAssigned, scope $"{name} came back under its own id");
			Test.Assert(target.GetEntityName(restored) == name);
		}

		// The hierarchy, by path, which only resolves if parents relinked correctly.
		Test.Assert(target.FindEntityByPath("Player/Weapon/Muzzle").IsAssigned);

		let player = target.FindEntityByName("Player");
		let transform = target.GetLocalTransform(player);
		Test.Assert(transform.Position.X == 1.0f);
		Test.Assert(transform.Scale.Y == 2.0f);

		let enemy = target.FindEntityByName("Enemy");
		Test.Assert(!target.IsActive(enemy), "the active flag round trips");

		// Components came back on the RIGHT entities, with their values.
		Test.Assert(manager.Count == 2);
		Test.Assert(manager.Get(player).Value == 55.0f);
		Test.Assert(manager.Get(enemy).Armour == 7);
		Test.Assert(manager.Get(target.FindEntityByName("Weapon")) == null);

		Test.Assert(world.Settings.Gravity == -3.5f);
		Test.Assert(world.Settings.Wind.Z == 3.0f);
	}

	/// Sibling ORDER round trips, which pool order would not: the hierarchy is something a
	/// person arranges, and a save that reshuffled it every time would be useless.
	[Test]
	public static void SiblingOrderRoundTrips()
	{
		let source = scope Scene();
		source.AddSystem<HealthManager>();
		let a = source.CreateEntity("a");
		let b = source.CreateEntity("b");
		let c = source.CreateEntity("c");
		// Deliberately not creation order.
		source.MoveBefore(c, a);
		source.MoveBefore(b, a);

		let target = scope Scene();
		target.AddSystem<HealthManager>();
		RoundTrip(source, target, .Binary);

		let first = target.FirstRoot;
		let second = target.GetNextSibling(first);
		let third = target.GetNextSibling(second);
		Test.Assert(target.GetEntityName(first) == "c");
		Test.Assert(target.GetEntityName(second) == "b");
		Test.Assert(target.GetEntityName(third) == "a");
	}

	/// A component whose manager is ABSENT is kept verbatim rather than dropped, and
	/// written straight back out. Losing a plugin's data because its plugin was not loaded
	/// is the one failure a save must never have.
	[Test]
	public static void AComponentWithNoManagerIsPreservedAndWrittenBack()
	{
		let source = scope Scene();
		Populate(source);

		// A target with NO health manager: the records have nowhere to go.
		let bare = scope Scene();
		bare.AddSystem<WorldSystem>();
		RoundTrip(source, bare, .Binary);

		Test.Assert(bare.UnresolvedComponents.Length == 2, "both records were kept");
		Test.Assert(bare.UnresolvedComponents[0].TypeId == "test.Health");
		Test.Assert(!bare.UnresolvedComponents[0].Payload.IsEmpty);

		// Saving that scene and loading it into one that DOES have the manager restores
		// them as real components: the data survived a full trip through a build that
		// could not understand it.
		let restored = scope Scene();
		let manager = restored.AddSystem<HealthManager>();
		restored.AddSystem<WorldSystem>();
		RoundTrip(bare, restored, .Binary);

		Test.Assert(restored.UnresolvedComponents.IsEmpty);
		Test.Assert(manager.Count == 2);
		Test.Assert(manager.Get(restored.FindEntityByName("Player")).Value == 55.0f);
	}

	/// The same bargain for a system's settings block.
	[Test]
	public static void SettingsOfAnAbsentSystemArePreservedAndWrittenBack()
	{
		let source = scope Scene();
		Populate(source);

		let bare = scope Scene();
		bare.AddSystem<HealthManager>();
		RoundTrip(source, bare, .Binary);

		Test.Assert(bare.UnresolvedSettingsRecords.Length == 1);
		Test.Assert(bare.UnresolvedSettingsRecords[0].SystemId == "test.World");

		let restored = scope Scene();
		restored.AddSystem<HealthManager>();
		let world = restored.AddSystem<WorldSystem>();
		RoundTrip(bare, restored, .Binary);

		Test.Assert(restored.UnresolvedSettingsRecords.IsEmpty);
		Test.Assert(world.Settings.Gravity == -3.5f);
	}

	/// A stream that is not ours stops at the header rather than being parsed as though it
	/// were. The next thing read would be a count, and a garbage count allocates.
	[Test]
	public static void AForeignStreamIsRefusedAtTheHeader()
	{
		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			uint32 notOurMagic = 0x12345678;
			SerializeValue(writer, "magic", ref notOurMagic);
		}
		buffer.Seek(0, .Begin);

		let target = scope Scene();
		let reader = scope BinarySerializer(buffer, .Read);
		SceneSerializer.SerializeScene(reader, target);

		Test.Assert(target.EntityCount == 0, "nothing was invented from a foreign stream");
		Test.Assert(!reader.IsPayloadOk, "and the payload is marked failed");
	}
	/// An own-active child under a saved-inactive parent comes back DARK, with its own flag
	/// intact.
	///
	/// The load order is what makes this worth pinning: the entities block sets the active
	/// flags and the parents are relinked afterwards, so the reparent has to settle the
	/// effective state or the child runs for a frame it was never meant to.
	[Test]
	public static void AChildUnderASavedInactiveParentLoadsDark()
	{
		let source = scope Scene();
		source.AddSystem<HealthManager>();
		let parent = source.CreateEntity("parent");
		let child = source.CreateEntity("child");
		source.SetParent(child, parent);
		source.SetActive(parent, false); // the child's own flag stays set

		let parentId = source.GetEntityId(parent);
		let childId = source.GetEntityId(child);

		let target = scope Scene();
		target.AddSystem<HealthManager>();
		RoundTrip(source, target, .Binary);

		let restoredParent = target.FindEntity(parentId);
		let restoredChild = target.FindEntity(childId);
		Test.Assert(restoredParent.IsAssigned);
		Test.Assert(restoredChild.IsAssigned);

		Test.Assert(!target.IsActive(restoredParent));
		Test.Assert(target.IsActive(restoredChild), "its own flag round trips");
		Test.Assert(!target.IsEffectivelyActive(restoredParent));
		Test.Assert(!target.IsEffectivelyActive(restoredChild), "dark from frame one");

		// And activating the parent at runtime brings the subtree up.
		target.SetActive(restoredParent, true);
		Test.Assert(target.IsEffectivelyActive(restoredChild));
	}
}
