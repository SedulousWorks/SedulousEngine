using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Scene.Resource.Tests;

/// An instance override of a component type this build has no manager for.
///
/// The failure this guards against is the quiet one: a designer customises an instance, a
/// build without that plugin opens and saves the scene, and the customisation is gone with
/// nothing to say so. The op is kept verbatim and re-emitted instead, and applied the
/// moment the manager turns up.
class PrefabUnresolvedOpTests
{
	private static Guid PrefabId => .(0xABCD, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);

	private static void CapturePayload(MemoryStream payload)
	{
		let template = scope Scene();
		let manager = template.AddSystem<HealthManager>();
		let root = template.CreateEntity("Turret");
		manager.Add(root).Value = 200.0f;
		Test.Assert(PrefabCapture.Capture(template, root, payload, .Binary) case .Ok);
		payload.Seek(0, .Begin);
	}

	/// An op whose manager is absent is PARKED on the instance rather than dropped.
	[Test]
	public static void AnOpOfAnAbsentTypeIsParkedOnTheInstance()
	{
		let payload = scope MemoryStream();
		CapturePayload(payload);

		let scene = scope Scene();
		scene.AddSystem<HealthManager>();
		let spawned = PrefabSpawn.Spawn(scene, payload, PrefabId);
		let state = scene.FindPrefabInstanceByRoot(scene.GetEntityId(spawned));

		// A delta carrying an override of a type nothing here can decode.
		let delta = scope PendingPrefabInstance();
		delta.PrefabId = PrefabId;
		delta.SourceIds.AddRange(state.SourceIds);
		delta.LiveIds.AddRange(state.LiveIds);
		let op = new PendingPrefabComponentOp();
		op.SourceEntity = state.SourceIds[0];
		op.TypeId.Set("plugin.Shield");
		op.Op = .Modify;
		op.Blob.AddRange(scope uint8[](7, 7, 7));
		delta.ComponentOps.Add(op);

		PrefabDeltas.Apply(scene, state, delta);

		Test.Assert(state.UnresolvedComponentOps.Count == 1, "kept rather than discarded");
		Test.Assert(state.UnresolvedComponentOps[0].TypeId == "plugin.Shield");
		Test.Assert(state.UnresolvedComponentOps[0].Blob.Count == 3);
	}

	/// And it comes back out on save, so a build without the plugin round trips the scene
	/// without losing what somebody customised.
	[Test]
	public static void AParkedOpIsWrittenBackBySaving()
	{
		let payload = scope MemoryStream();
		CapturePayload(payload);

		let scene = scope Scene();
		scene.AddSystem<HealthManager>();
		let spawned = PrefabSpawn.Spawn(scene, payload, PrefabId);
		let state = scene.FindPrefabInstanceByRoot(scene.GetEntityId(spawned));

		let delta = scope PendingPrefabInstance();
		delta.PrefabId = PrefabId;
		delta.SourceIds.AddRange(state.SourceIds);
		delta.LiveIds.AddRange(state.LiveIds);
		let op = new PendingPrefabComponentOp();
		op.SourceEntity = state.SourceIds[0];
		op.TypeId.Set("plugin.Shield");
		op.Op = .Modify;
		op.Blob.AddRange(scope uint8[](7, 7, 7));
		delta.ComponentOps.Add(op);
		PrefabDeltas.Apply(scene, state, delta);

		// Save and load in a build that still has no such plugin.
		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			SceneSerializer.SerializeScene(writer, scene, .Referenced, true, .Binary);
		}
		buffer.Seek(0, .Begin);

		let loaded = scope Scene();
		loaded.AddSystem<HealthManager>();
		let reader = scope BinarySerializer(buffer, .Read);
		SceneSerializer.SerializeScene(reader, loaded, .Referenced, true, .Binary);

		Test.Assert(loaded.PendingPrefabInstanceCount == 1);

		var sawOp = false;
		loaded.ForEachPendingPrefabInstance(scope [&](descriptor) =>
		{
			for (let saved in descriptor.ComponentOps)
			{
				if (saved.TypeId != "plugin.Shield")
					continue;
				sawOp = true;
				Test.Assert(saved.Op == .Modify);
				Test.Assert(saved.Blob.Count == 3, "the payload came through untouched");
				Test.Assert(saved.Blob[0] == 7);
			}
		});
		Test.Assert(sawOp, "the override of the absent type survived the save");
	}

	/// When the manager joins (a plugin loading into a live scene), a parked op is applied:
	/// the override lands on the instance's member, and its references to the prefab's own
	/// members (source ids, as a generator writes them) name the instance's copies.
	[Test]
	public static void AParkedOpIsAppliedWhenItsManagerJoins()
	{
		let payload = scope MemoryStream();
		CapturePayload(payload);

		// The plugin is absent when the instance spawns.
		let scene = scope Scene();
		let spawned = PrefabSpawn.Spawn(scene, payload, PrefabId);
		let state = scene.FindPrefabInstanceByRoot(scene.GetEntityId(spawned));

		// The override: a health of 50 aimed at the prefab's own root, by its source id.
		let blob = scope List<uint8>();
		let typeId = scope String();
		{
			let scratch = scope Scene();
			let manager = scratch.AddSystem<HealthManager>();
			let entity = scratch.CreateEntity("x");
			let health = manager.Add(entity);
			health.Value = 50.0f;
			health.Target = .(state.SourceIds[0]);
			SceneStreamFormat.ComponentToBlob(manager, entity, blob);
			typeId.Set(manager.SerializationTypeId);
		}
		let delta = scope PendingPrefabInstance();
		delta.PrefabId = PrefabId;
		delta.SourceIds.AddRange(state.SourceIds);
		delta.LiveIds.AddRange(state.LiveIds);
		let op = new PendingPrefabComponentOp();
		op.SourceEntity = state.SourceIds[0];
		op.TypeId.Set(typeId);
		op.Op = .Modify;
		op.Blob.AddRange(blob);
		delta.ComponentOps.Add(op);
		PrefabDeltas.Apply(scene, state, delta);
		Test.Assert(state.UnresolvedComponentOps.Count == 1, "parked: no manager yet");

		// The manager joins, as a plugin's does, and the scene resolves what was parked.
		let healthManager = scene.AddSystem<HealthManager>();
		SceneResolve.ResolveAllUnresolvedRecords(scene);
		Test.Assert(state.UnresolvedComponentOps.IsEmpty, "applied, no longer pending");
		let health = healthManager.Get(spawned);
		Test.Assert(health != null);
		Test.Assert(health.Value == 50.0f, "the override, over the prefab's 200");
		Test.Assert(health.Target.Id == state.LiveIds[0], "the reference names the instance's member");
	}
}
