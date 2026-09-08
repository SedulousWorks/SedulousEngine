using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Scene.Resource.Tests;

/// Applying an instance back to its prefab.
///
/// The two rules that keep every OTHER instance working: members keep their SOURCE ids, so
/// the deltas keyed on them still name the same things, and the root's placement does not
/// become template content.
class PrefabApplyTests
{
	private static Guid PrefabId => .(0xABCD, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);

	private static void CapturePayload(MemoryStream payload, float health = 200.0f)
	{
		let template = scope Scene();
		let manager = template.AddSystem<HealthManager>();
		let root = template.CreateEntity("Turret");
		template.SetParent(template.CreateEntity("Barrel"), root);
		manager.Add(root).Value = health;
		Test.Assert(PrefabCapture.Capture(template, root, payload, .Binary) case .Ok);
		payload.Seek(0, .Begin);
	}

	/// What the instance became IS the template afterwards, and a second instance spawned
	/// from it agrees.
	[Test]
	public static void AnInstancesEditsBecomeTheTemplate()
	{
		let payload = scope MemoryStream();
		CapturePayload(payload);

		let scene = scope Scene();
		let manager = scene.AddSystem<HealthManager>();
		let spawned = PrefabSpawn.Spawn(scene, payload, PrefabId);
		let state = scene.FindPrefabInstanceByRoot(scene.GetEntityId(spawned));

		manager.Get(spawned).Value = 77.0f;

		let applied = scope MemoryStream();
		Test.Assert(PrefabApply.CaptureAsTemplate(scene, state, applied, .Binary) case .Ok);
		applied.Seek(0, .Begin);

		// A fresh instance of the NEW template carries the edit.
		let target = scope Scene();
		let targetManager = target.AddSystem<HealthManager>();
		let fresh = PrefabSpawn.Spawn(target, applied, PrefabId);

		Test.Assert(fresh.IsAssigned);
		Test.Assert(target.GetEntityName(fresh) == "Turret");
		Test.Assert(target.GetChildCount(fresh) == 1);
		Test.Assert(targetManager.Get(fresh).Value == 77.0f, "the edit is in the template now");
	}

	/// Members keep their SOURCE ids, so another instance's overrides still name the same
	/// things after an apply. Writing live ids would orphan every delta in the project.
	[Test]
	public static void MembersKeepTheirSourceIdsSoOtherInstancesStillMatch()
	{
		let payload = scope MemoryStream();
		CapturePayload(payload);

		let scene = scope Scene();
		let manager = scene.AddSystem<HealthManager>();
		let first = PrefabSpawn.Spawn(scene, payload, PrefabId);
		payload.Seek(0, .Begin);
		let second = PrefabSpawn.Spawn(scene, payload, PrefabId);

		let firstState = scene.FindPrefabInstanceByRoot(scene.GetEntityId(first));
		// The second instance is remembered by its root GUID, not by its state: a rebuild
		// destroys and recreates the state objects, so a pointer held across one dangles.
		let secondRootId = scene.GetEntityId(second);

		// The second instance has an override of its own.
		manager.Get(second).Value = 5.0f;

		// The FIRST is applied back to the prefab.
		manager.Get(first).Value = 77.0f;
		let applied = scope MemoryStream();
		Test.Assert(PrefabApply.CaptureAsTemplate(scene, firstState, applied, .Binary) case .Ok);
		applied.Seek(0, .Begin);
		let appliedBytes = scope List<uint8>();
		appliedBytes.AddRange(applied.Bytes);

		// The source ids in the written template are the ones the OTHER instance is keyed
		// on, so a rebuild against it still finds its member and keeps its override.
		Test.Assert(PrefabRebuild.Rebuild(scene, PrefabId, appliedBytes) == 2);

		let survivor = scene.FindEntity(secondRootId);
		Test.Assert(survivor.IsAssigned);
		Test.Assert(manager.Get(survivor).Value == 5.0f,
			"the other instance's override survived the apply");
	}

	/// An instance's PLACEMENT does not become template content. A root transform belongs
	/// to the one instance; letting it through would teleport every other instance to
	/// wherever this one happened to be sitting.
	[Test]
	public static void ThePlacementDoesNotLeakIntoTheTemplate()
	{
		let payload = scope MemoryStream();
		CapturePayload(payload);

		let scene = scope Scene();
		scene.AddSystem<HealthManager>();
		let spawned = PrefabSpawn.Spawn(scene, payload, PrefabId);
		let state = scene.FindPrefabInstanceByRoot(scene.GetEntityId(spawned));

		// The user drags it somewhere.
		var placed = Transform();
		placed.Position = .(100, 200, 300);
		scene.SetLocalTransform(spawned, placed);

		let applied = scope MemoryStream();
		Test.Assert(PrefabApply.CaptureAsTemplate(scene, state, applied, .Binary) case .Ok);
		applied.Seek(0, .Begin);

		let target = scope Scene();
		target.AddSystem<HealthManager>();
		let fresh = PrefabSpawn.Spawn(target, applied, PrefabId);

		let transform = target.GetLocalTransform(fresh);
		Test.Assert(transform.Position.X == 0.0f, "the placement stayed with the instance");
		Test.Assert(transform.Position.Y == 0.0f);
		Test.Assert(transform.Position.Z == 0.0f);
	}

	/// An entity the user ADDED under the instance becomes part of the template, under a
	/// brand new source id: it was never in the template, so nothing was keyed on it.
	[Test]
	public static void AUserAddedEntityJoinsTheTemplate()
	{
		let payload = scope MemoryStream();
		CapturePayload(payload);

		let scene = scope Scene();
		scene.AddSystem<HealthManager>();
		let spawned = PrefabSpawn.Spawn(scene, payload, PrefabId);
		let state = scene.FindPrefabInstanceByRoot(scene.GetEntityId(spawned));

		let addition = scene.CreateEntity("Scope");
		scene.SetParent(addition, scene.GetFirstChild(spawned));

		let applied = scope MemoryStream();
		Test.Assert(PrefabApply.CaptureAsTemplate(scene, state, applied, .Binary) case .Ok);
		applied.Seek(0, .Begin);

		let target = scope Scene();
		target.AddSystem<HealthManager>();
		PrefabSpawn.Spawn(target, applied, PrefabId);

		Test.Assert(target.EntityCount == 3, "the addition came with it");
		Test.Assert(target.FindEntityByPath("Turret/Barrel/Scope").IsAssigned,
			"and in the same place");
	}

	/// A moved MEMBER is template content, unlike the root: it is where the template says
	/// that part sits, not where the instance was put.
	[Test]
	public static void AMovedMemberIsTemplateContent()
	{
		let payload = scope MemoryStream();
		CapturePayload(payload);

		let scene = scope Scene();
		scene.AddSystem<HealthManager>();
		let spawned = PrefabSpawn.Spawn(scene, payload, PrefabId);
		let state = scene.FindPrefabInstanceByRoot(scene.GetEntityId(spawned));

		var moved = Transform();
		moved.Position = .(0, 7, 0);
		scene.SetLocalTransform(scene.GetFirstChild(spawned), moved);

		let applied = scope MemoryStream();
		Test.Assert(PrefabApply.CaptureAsTemplate(scene, state, applied, .Binary) case .Ok);
		applied.Seek(0, .Begin);

		let target = scope Scene();
		target.AddSystem<HealthManager>();
		let fresh = PrefabSpawn.Spawn(target, applied, PrefabId);

		Test.Assert(target.GetLocalTransform(target.GetFirstChild(fresh)).Position.Y == 7.0f);
	}

	/// Applying an instance whose root is gone says so rather than writing a ruin.
	[Test]
	public static void ApplyingADeadInstanceIsRefused()
	{
		let payload = scope MemoryStream();
		CapturePayload(payload);

		let scene = scope Scene();
		scene.AddSystem<HealthManager>();
		let spawned = PrefabSpawn.Spawn(scene, payload, PrefabId);
		let state = scene.FindPrefabInstanceByRoot(scene.GetEntityId(spawned));
		scene.DestroyEntity(spawned);

		let applied = scope MemoryStream();
		Test.Assert(PrefabApply.CaptureAsTemplate(scene, state, applied, .Binary) case .Err(.NotFound));
	}
}
