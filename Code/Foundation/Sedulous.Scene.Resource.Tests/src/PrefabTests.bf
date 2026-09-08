using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Scene.Resource.Tests;

/// Capture, spawn, and the deltas derived from what an instance became.
class PrefabTests
{
	/// A template scene with a two entity subtree and a component on the root.
	private static EntityHandle BuildTemplate(Scene scene, out HealthManager manager)
	{
		manager = scene.AddSystem<HealthManager>();
		let root = scene.CreateEntity("Turret");
		let barrel = scene.CreateEntity("Barrel");
		scene.SetParent(barrel, root);

		var transform = Transform();
		transform.Position = .(0, 1, 0);
		scene.SetLocalTransform(barrel, transform);

		manager.Add(root).Value = 200.0f;
		return root;
	}

	private static void CaptureTo(Scene scene, EntityHandle root, MemoryStream payload,
		SceneStreamEncoding encoding = .Binary)
	{
		Test.Assert(PrefabCapture.Capture(scene, root, payload, encoding) case .Ok);
		payload.Seek(0, .Begin);
	}

	private static Guid PrefabId => .(0xABCD, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);

	[Test]
	public static void APrefabCapturesAndSpawnsAsAnIndependentCopy()
	{
		let template = scope Scene();
		let root = BuildTemplate(template, var templateManager);

		let payload = scope MemoryStream();
		CaptureTo(template, root, payload);

		// Spawned into the TEMPLATE'S OWN scene, which is where "fresh ids" is a claim
		// with any content. A guid is scene scoped, so two separate scenes minting the
		// same sequence from the same seed is expected rather than a collision.
		let spawned = PrefabSpawn.Spawn(template, payload, PrefabId);

		Test.Assert(spawned.IsAssigned);
		Test.Assert(template.GetEntityName(spawned) == "Turret");
		Test.Assert(template.GetChildCount(spawned) == 1);
		Test.Assert(template.GetEntityName(template.GetFirstChild(spawned)) == "Barrel");
		Test.Assert(templateManager.Get(spawned).Value == 200.0f);

		// The template's guids stay the template's: an instance sharing one would BE that
		// entity as far as every map in the scene is concerned.
		Test.Assert(spawned != root);
		Test.Assert(template.GetEntityId(spawned) != template.GetEntityId(root));

		// And the instance is recorded, with a baseline per member.
		Test.Assert(template.PrefabInstanceCount == 1);
		let state = template.FindPrefabInstanceByRoot(template.GetEntityId(spawned));
		Test.Assert(state != null);
		Test.Assert(state.PrefabId == PrefabId);
		Test.Assert(state.SourceIds.Count == 2);
		Test.Assert(state.ComponentBaselines.Count == 1);
	}

	/// Two instances of one payload are independent: editing one leaves the other alone.
	[Test]
	public static void TwoInstancesOfOnePayloadAreIndependent()
	{
		let template = scope Scene();
		let root = BuildTemplate(template, var templateManager);
		let payload = scope MemoryStream();
		CaptureTo(template, root, payload);

		let target = scope Scene();
		let manager = target.AddSystem<HealthManager>();

		let first = PrefabSpawn.Spawn(target, payload, PrefabId);
		payload.Seek(0, .Begin);
		let second = PrefabSpawn.Spawn(target, payload, PrefabId);

		Test.Assert(first.IsAssigned && second.IsAssigned);
		Test.Assert(first != second);
		Test.Assert(target.GetEntityId(first) != target.GetEntityId(second));
		Test.Assert(target.PrefabInstanceCount == 2);

		manager.Get(first).Value = 5.0f;
		Test.Assert(manager.Get(second).Value == 200.0f, "the other instance was untouched");
	}

	/// An instance that was NOT edited has no overrides. That is what makes an override
	/// meaningful: if spawning itself produced differences, every save would carry noise.
	[Test]
	public static void AnUntouchedInstanceHasNoOverrides()
	{
		let template = scope Scene();
		let root = BuildTemplate(template, var templateManager);
		let payload = scope MemoryStream();
		CaptureTo(template, root, payload);

		let target = scope Scene();
		target.AddSystem<HealthManager>();
		let spawned = PrefabSpawn.Spawn(target, payload, PrefabId);
		let state = target.FindPrefabInstanceByRoot(target.GetEntityId(spawned));

		let delta = PrefabDeltas.Compute(target, state);
		defer delete delta;

		Test.Assert(delta.ComponentOps.IsEmpty, "nothing was changed, so nothing is written");
		Test.Assert(delta.OverrideTransformIds.IsEmpty);
		Test.Assert(delta.DestroyedMembers.IsEmpty);
	}

	/// Every kind of edit shows up as exactly one op, DERIVED from the baseline rather than
	/// tracked as it happened.
	[Test]
	public static void EditsAreDerivedAsOverrides()
	{
		let template = scope Scene();
		let root = BuildTemplate(template, var templateManager);
		let payload = scope MemoryStream();
		CaptureTo(template, root, payload);

		let target = scope Scene();
		let manager = target.AddSystem<HealthManager>();
		let spawned = PrefabSpawn.Spawn(target, payload, PrefabId);
		let state = target.FindPrefabInstanceByRoot(target.GetEntityId(spawned));

		// A changed component value.
		manager.Get(spawned).Value = 42.0f;

		// A moved member.
		let barrel = target.GetFirstChild(spawned);
		var moved = Transform();
		moved.Position = .(9, 9, 9);
		target.SetLocalTransform(barrel, moved);

		let delta = PrefabDeltas.Compute(target, state);
		defer delete delta;

		Test.Assert(delta.ComponentOps.Count == 1);
		Test.Assert(delta.ComponentOps[0].Op == .Modify);
		Test.Assert(delta.OverrideTransformIds.Count == 1);
		Test.Assert(delta.OverrideTransforms[0].Position.X == 9.0f);
	}

	/// Adding, removing and deleting are each their own kind of override.
	[Test]
	public static void AddRemoveAndDeleteAreDistinctOverrides()
	{
		let template = scope Scene();
		let root = BuildTemplate(template, var templateManager);
		let payload = scope MemoryStream();
		CaptureTo(template, root, payload);

		let target = scope Scene();
		let manager = target.AddSystem<HealthManager>();
		let spawned = PrefabSpawn.Spawn(target, payload, PrefabId);
		let state = target.FindPrefabInstanceByRoot(target.GetEntityId(spawned));

		// The barrel gains a component the template never gave it.
		let barrel = target.GetFirstChild(spawned);
		manager.Add(barrel).Value = 1.0f;
		// The root loses the one it had.
		manager.RemoveComponent(spawned);

		let delta = PrefabDeltas.Compute(target, state);
		defer delete delta;

		Test.Assert(delta.ComponentOps.Count == 2);
		var sawAdd = false;
		var sawRemove = false;
		for (let op in delta.ComponentOps)
		{
			if (op.Op == .Add) sawAdd = true;
			if (op.Op == .Remove) sawRemove = true;
		}
		Test.Assert(sawAdd && sawRemove);

		// And a member deleted out of the instance is itself an override: respawning must
		// not bring it back.
		target.DestroyEntity(barrel);
		let afterDelete = PrefabDeltas.Compute(target, state);
		defer delete afterDelete;
		Test.Assert(afterDelete.DestroyedMembers.Count == 1);
	}

	/// Re-applying a descriptor onto a fresh spawn reproduces the edited instance. This is
	/// the round trip a saved scene depends on: reference plus deltas, back to what it was.
	[Test]
	public static void ApplyingDeltasReproducesTheEditedInstance()
	{
		let template = scope Scene();
		let root = BuildTemplate(template, var templateManager);
		let payload = scope MemoryStream();
		CaptureTo(template, root, payload);

		let target = scope Scene();
		let manager = target.AddSystem<HealthManager>();
		let spawned = PrefabSpawn.Spawn(target, payload, PrefabId);
		let state = target.FindPrefabInstanceByRoot(target.GetEntityId(spawned));

		manager.Get(spawned).Value = 42.0f;
		let barrel = target.GetFirstChild(spawned);
		var moved = Transform();
		moved.Position = .(9, 9, 9);
		target.SetLocalTransform(barrel, moved);

		let delta = PrefabDeltas.Compute(target, state);
		defer delete delta;

		// A second scene: spawn clean, then apply.
		let restored = scope Scene();
		let restoredManager = restored.AddSystem<HealthManager>();
		payload.Seek(0, .Begin);
		let respawned = PrefabSpawn.Spawn(restored, payload, PrefabId);
		let respawnedState = restored.FindPrefabInstanceByRoot(restored.GetEntityId(respawned));

		Test.Assert(restoredManager.Get(respawned).Value == 200.0f, "clean, before the deltas");
		PrefabDeltas.Apply(restored, respawnedState, delta);

		Test.Assert(restoredManager.Get(respawned).Value == 42.0f);
		Test.Assert(restored.GetLocalTransform(restored.GetFirstChild(respawned)).Position.X == 9.0f);
	}

	/// A payload captured as TEXT spawns the same way: capture and spawn agree across both
	/// encodings, because spawning sniffs rather than being told.
	[Test]
	public static void ATextPayloadSpawnsTheSameWay()
	{
		let template = scope Scene();
		let root = BuildTemplate(template, var templateManager);
		let payload = scope MemoryStream();
		CaptureTo(template, root, payload, .Text);

		let target = scope Scene();
		let manager = target.AddSystem<HealthManager>();
		let spawned = PrefabSpawn.Spawn(target, payload, PrefabId);

		Test.Assert(spawned.IsAssigned);
		Test.Assert(target.GetEntityName(spawned) == "Turret");
		Test.Assert(target.GetChildCount(spawned) == 1);
		Test.Assert(manager.Get(spawned).Value == 200.0f);
	}

	/// A component's reference to another MEMBER of the template becomes the instance's
	/// own copy, so two instances do not both point at the same entity.
	[Test]
	public static void AnEntityReferenceInsideTheTemplateFollowsTheInstance()
	{
		let template = scope Scene();
		let manager = template.AddSystem<HealthManager>();
		let root = template.CreateEntity("Turret");
		let barrel = template.CreateEntity("Barrel");
		template.SetParent(barrel, root);
		// The root points at the barrel, by id.
		manager.Add(root).Target = .(template.GetEntityId(barrel));

		let payload = scope MemoryStream();
		CaptureTo(template, root, payload);

		// Into the template's own scene, so "the instance's barrel, not the template's" is
		// a distinction the ids can actually express.
		let spawned = PrefabSpawn.Spawn(template, payload, PrefabId);
		let spawnedBarrel = template.GetFirstChild(spawned);

		Test.Assert(manager.Get(spawned).Target.Id == template.GetEntityId(spawnedBarrel),
			"the reference follows the instance");
		Test.Assert(manager.Get(spawned).Target.Id != template.GetEntityId(barrel),
			"and no longer names the template's own");
	}
}
