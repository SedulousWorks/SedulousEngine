using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Scene.Resource.Tests;

/// A scene with prefab instances, saved and loaded.
///
/// The whole point of reference plus deltas: a saved scene stores which prefab, where, and
/// what differs. Editing the prefab afterwards changes every instance, and what the user
/// changed on an instance survives that.
class PrefabPersistenceTests
{
	private static Guid PrefabId => .(0xABCD, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);

	/// The template: a turret with a barrel, and health on the root.
	private static void CapturePayload(MemoryStream payload, SceneStreamEncoding encoding = .Binary)
	{
		let template = scope Scene();
		let manager = template.AddSystem<HealthManager>();
		let root = template.CreateEntity("Turret");
		let barrel = template.CreateEntity("Barrel");
		template.SetParent(barrel, root);
		manager.Add(root).Value = 200.0f;

		Test.Assert(PrefabCapture.Capture(template, root, payload, encoding) case .Ok);
		payload.Seek(0, .Begin);
	}

	private static void RoundTrip(Scene source, Scene target, SceneStreamEncoding encoding = .Binary)
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

	/// A saved scene stores the instance as a REFERENCE: its members are not written as
	/// plain entities, so editing the prefab later reaches every instance.
	[Test]
	public static void AnInstanceSavesAsAReferenceNotAsItsEntities()
	{
		let payload = scope MemoryStream();
		CapturePayload(payload);

		let scene = scope Scene();
		scene.AddSystem<HealthManager>();
		let spawned = PrefabSpawn.Spawn(scene, payload, PrefabId);
		Test.Assert(spawned.IsAssigned);
		Test.Assert(scene.EntityCount == 2);

		let loaded = scope Scene();
		loaded.AddSystem<HealthManager>();
		RoundTrip(scene, loaded);

		// The members did NOT come back as plain entities: they are a parked descriptor
		// waiting for their payload.
		Test.Assert(loaded.EntityCount == 0, "the instance's entities are not in the entity array");
		Test.Assert(loaded.PendingPrefabInstanceCount == 1);
	}

	/// Resolving respawns it, with its identity and its place intact.
	[Test]
	public static void ResolvingRespawnsTheInstanceWithItsIdentity()
	{
		let payload = scope MemoryStream();
		CapturePayload(payload);

		let scene = scope Scene();
		scene.AddSystem<HealthManager>();
		let spawned = PrefabSpawn.Spawn(scene, payload, PrefabId);
		let spawnedId = scene.GetEntityId(spawned);
		let barrelId = scene.GetEntityId(scene.GetFirstChild(spawned));

		let loaded = scope Scene();
		let loadedManager = loaded.AddSystem<HealthManager>();
		RoundTrip(scene, loaded);

		payload.Seek(0, .Begin);
		// The pass owns what it is handed, so each call gets its own stream.
		ScenePrefabs.PayloadResolver resolver = scope [&](prefabId) =>
		{
			if (prefabId != PrefabId)
				return null;
			let copy = new MemoryStream();
			copy.Write(payload.Bytes);
			copy.Seek(0, .Begin);
			return (IStream)copy;
		};
		ScenePrefabs.ResolveScenePrefabs(loaded, resolver);

		Test.Assert(loaded.PendingPrefabInstanceCount == 0);
		Test.Assert(loaded.EntityCount == 2);

		// The SAME guids: everything else in the scene that named a member still resolves.
		let root = loaded.FindEntity(spawnedId);
		Test.Assert(root.IsAssigned, "the instance root kept its id");
		Test.Assert(loaded.FindEntity(barrelId).IsAssigned, "and so did its member");
		Test.Assert(loaded.GetEntityName(root) == "Turret");
		Test.Assert(loadedManager.Get(root).Value == 200.0f);
		Test.Assert(loaded.PrefabInstanceCount == 1);
	}

	/// What the user changed on an instance survives the round trip, and what they did not
	/// touch comes from the template.
	[Test]
	public static void OverridesSurviveSaveAndLoad()
	{
		let payload = scope MemoryStream();
		CapturePayload(payload);

		let scene = scope Scene();
		let manager = scene.AddSystem<HealthManager>();
		let spawned = PrefabSpawn.Spawn(scene, payload, PrefabId);

		// One edit of each kind that has to persist.
		manager.Get(spawned).Value = 42.0f;
		let barrel = scene.GetFirstChild(spawned);
		var moved = Transform();
		moved.Position = .(9, 9, 9);
		scene.SetLocalTransform(barrel, moved);

		let loaded = scope Scene();
		let loadedManager = loaded.AddSystem<HealthManager>();
		RoundTrip(scene, loaded);

		payload.Seek(0, .Begin);
		ScenePrefabs.PayloadResolver resolver = scope [&](prefabId) =>
		{
			let copy = new MemoryStream();
			copy.Write(payload.Bytes);
			copy.Seek(0, .Begin);
			return (IStream)copy;
		};
		ScenePrefabs.ResolveScenePrefabs(loaded, resolver);

		let root = loaded.FindEntityByName("Turret");
		Test.Assert(root.IsAssigned);
		Test.Assert(loadedManager.Get(root).Value == 42.0f, "the edited value came back");
		Test.Assert(loaded.GetLocalTransform(loaded.GetFirstChild(root)).Position.X == 9.0f,
			"and so did the move");
	}

	/// A load then save that never resolved re-emits the parked descriptors VERBATIM, so a
	/// transcode with nothing mounted is lossless rather than quietly dropping every
	/// instance in the scene.
	[Test]
	public static void AnUnresolvedSceneReSavesItsInstancesVerbatim()
	{
		let payload = scope MemoryStream();
		CapturePayload(payload);

		let scene = scope Scene();
		scene.AddSystem<HealthManager>();
		let spawned = PrefabSpawn.Spawn(scene, payload, PrefabId);
		let spawnedId = scene.GetEntityId(spawned);

		// Load once, WITHOUT resolving.
		let parked = scope Scene();
		parked.AddSystem<HealthManager>();
		RoundTrip(scene, parked);
		Test.Assert(parked.PendingPrefabInstanceCount == 1);

		// Save and load that again: the descriptor survived untouched.
		let again = scope Scene();
		again.AddSystem<HealthManager>();
		RoundTrip(parked, again);
		Test.Assert(again.PendingPrefabInstanceCount == 1);

		var seenRoot = Guid();
		again.ForEachPendingPrefabInstance(scope [&](descriptor) =>
		{
			seenRoot = descriptor.RootLiveId;
			Test.Assert(descriptor.PrefabId == PrefabId);
			Test.Assert(descriptor.SourceIds.Count == 2, "the member map came through");
		});
		Test.Assert(seenRoot == spawnedId, "including which entity the root was");
	}

	/// An instance whose prefab cannot be reached is SKIPPED rather than half spawned, and
	/// the rest of the scene loads.
	[Test]
	public static void AnUnresolvablePrefabIsSkipped()
	{
		let payload = scope MemoryStream();
		CapturePayload(payload);

		let scene = scope Scene();
		scene.AddSystem<HealthManager>();
		PrefabSpawn.Spawn(scene, payload, PrefabId);
		scene.CreateEntity("Bystander");

		let loaded = scope Scene();
		loaded.AddSystem<HealthManager>();
		RoundTrip(scene, loaded);

		ScenePrefabs.PayloadResolver resolver = scope [&](prefabId) => null;
		ScenePrefabs.ResolveScenePrefabs(loaded, resolver);

		Test.Assert(loaded.PendingPrefabInstanceCount == 0, "the descriptor was consumed");
		Test.Assert(loaded.FindEntityByName("Bystander").IsAssigned, "the rest of the scene is fine");
		Test.Assert(loaded.FindEntityByName("Turret") == EntityHandle.Invalid);
	}

	/// The whole loop through TEXT, which is what a source scene is stored in.
	[Test]
	public static void TheLoopWorksThroughTheTextEncodingToo()
	{
		let payload = scope MemoryStream();
		CapturePayload(payload, .Text);

		let scene = scope Scene();
		let manager = scene.AddSystem<HealthManager>();
		let spawned = PrefabSpawn.Spawn(scene, payload, PrefabId);
		manager.Get(spawned).Value = 7.0f;

		let loaded = scope Scene();
		let loadedManager = loaded.AddSystem<HealthManager>();
		RoundTrip(scene, loaded, .Text);
		Test.Assert(loaded.PendingPrefabInstanceCount == 1);

		payload.Seek(0, .Begin);
		ScenePrefabs.PayloadResolver resolver = scope [&](prefabId) =>
		{
			let copy = new MemoryStream();
			copy.Write(payload.Bytes);
			copy.Seek(0, .Begin);
			return (IStream)copy;
		};
		ScenePrefabs.ResolveScenePrefabs(loaded, resolver);

		let root = loaded.FindEntityByName("Turret");
		Test.Assert(root.IsAssigned);
		Test.Assert(loadedManager.Get(root).Value == 7.0f);
	}
}
