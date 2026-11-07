using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.Gameplay;

namespace Sedulous.Engine.Gameplay.Tests;

/// A behaviour in a prefab: captured and spawned like a component, its overrides derived by
/// the whole-record compare, and its EntityRef fields remapped to the instance's members.
/// Mirrors PrefabTests (Scene.Resource.Tests) for a struct component.
class BehaviourPrefabTests
{
	private static Guid PrefabId => .(0xABCD, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);

	/// A turret whose root's mover names its barrel.
	private static EntityHandle BuildTemplate(Scene scene, out EntityHandle barrel)
	{
		let movers = scene.AddSystem<BehaviourManager<Mover>>();
		let root = scene.CreateEntity("Turret");
		barrel = scene.CreateEntity("Barrel");
		scene.SetParent(barrel, root);

		let mover = movers.Add(root);
		mover.Speed = 200.0f;
		mover.Target = .(scene.GetEntityId(barrel));
		return root;
	}

	private static void CaptureTo(Scene scene, EntityHandle root, MemoryStream payload)
	{
		Test.Assert(PrefabCapture.Capture(scene, root, payload, .Binary) case .Ok);
		payload.Seek(0, .Begin);
	}

	/// An untouched instance has no ops; a changed field is exactly one Modify op, which
	/// applied to a fresh instance reproduces the change (mirrors
	/// PrefabTests.AnUntouchedInstanceHasNoOverrides and EditsAreDerivedAsOverrides).
	[Test]
	public static void AChangedFieldIsOneModifyOp()
	{
		let template = scope Scene();
		let root = BuildTemplate(template, ?);
		let payload = scope MemoryStream();
		CaptureTo(template, root, payload);

		let target = scope Scene();
		let movers = target.AddSystem<BehaviourManager<Mover>>();
		let spawned = PrefabSpawn.Spawn(target, payload, PrefabId);
		Test.Assert(spawned.IsAssigned);
		let state = target.FindPrefabInstanceByRoot(target.GetEntityId(spawned));
		Test.Assert(state != null);
		Test.Assert(movers.Get(spawned).Speed == 200.0f);

		{
			let untouched = PrefabDeltas.Compute(target, state);
			defer delete untouched;
			Test.Assert(untouched.ComponentOps.IsEmpty, "spawning itself is not an override");
		}

		// Runtime state is not data: it is no override either.
		movers.Get(spawned).Bob = 3.0f;
		{
			let stateOnly = PrefabDeltas.Compute(target, state);
			defer delete stateOnly;
			Test.Assert(stateOnly.ComponentOps.IsEmpty, "a private field is not part of the record");
		}

		movers.Get(spawned).Speed = 42.0f;
		let delta = PrefabDeltas.Compute(target, state);
		defer delete delta;
		Test.Assert(delta.ComponentOps.Count == 1);
		Test.Assert(delta.ComponentOps[0].Op == .Modify);
		Test.Assert(delta.ComponentOps[0].TypeId == "test.mover");

		// A second instance of the same payload (so the same source ids), the op applied: it
		// takes the change, read into a fresh instance.
		payload.Seek(0, .Begin);
		let second = PrefabSpawn.Spawn(target, payload, PrefabId);
		let secondState = target.FindPrefabInstanceByRoot(target.GetEntityId(second));
		Test.Assert(movers.Get(second).Speed == 200.0f);
		let replay = scope PendingPrefabInstance();
		replay.ComponentOps.Add(PrefabDeltas.CopyOp(delta.ComponentOps[0]));
		PrefabDeltas.Apply(target, secondState, replay);
		Test.Assert(movers.Get(second).Speed == 42.0f);
	}

	/// A behaviour's EntityRef naming another member of the template names the instance's own
	/// copy once spawned (mirrors PrefabTests.AnEntityReferenceInsideTheTemplateFollowsTheInstance).
	[Test]
	public static void AnEntityRefInsideABehaviourFollowsTheInstance()
	{
		let template = scope Scene();
		let root = BuildTemplate(template, var barrel);
		let movers = template.GetSystem<BehaviourManager<Mover>>();
		let payload = scope MemoryStream();
		CaptureTo(template, root, payload);

		// Into the template's own scene, where "the instance's barrel, not the template's" is a
		// distinction the ids can express.
		let spawned = PrefabSpawn.Spawn(template, payload, PrefabId);
		let spawnedBarrel = template.GetFirstChild(spawned);

		Test.Assert(movers.Get(spawned).Target.Id == template.GetEntityId(spawnedBarrel),
			"the reference follows the instance");
		Test.Assert(movers.Get(spawned).Target.Id != template.GetEntityId(barrel),
			"and no longer names the template's own");
	}

	/// The remap itself, by reflection over the behaviour's fields at the instance's address
	/// (mirrors PrefabEntityRefTests): inside the map it is rewritten, outside it is left.
	[Test]
	public static void TheRemapRewritesOnlyReferencesIntoThePrefab()
	{
		let scene = scope Scene();
		let movers = scene.AddSystem<BehaviourManager<Mover>>();
		let entity = scene.CreateEntity("member");
		let other = scene.CreateEntity("other");

		let sourceId = Guid(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);
		let liveId = Guid(2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);
		let map = scope Dictionary<Guid, Guid>();
		map[sourceId] = liveId;

		movers.Add(entity).Target = .(sourceId);
		PrefabEntityRefs.Remap(movers, entity, map);
		Test.Assert(movers.Get(entity).Target.Id == liveId);

		let outsider = scene.GetEntityId(other);
		movers.Get(entity).Target = .(outsider);
		PrefabEntityRefs.Remap(movers, entity, map);
		Test.Assert(movers.Get(entity).Target.Id == outsider);

		PrefabEntityRefs.Remap(movers, other, map); // no behaviour there: a no op
	}
}
