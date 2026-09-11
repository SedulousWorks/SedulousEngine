using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Scene.Resource.Tests;

/// Prefabs that contain instances of other prefabs.
///
/// The hard part is that a nested instance carries TWO layers of customisation. What the
/// person editing the OUTER prefab changed about the inner one becomes the nested
/// instance's baseline, so editing the outer template still reaches every placement of it.
/// What somebody changed about one PLACEMENT sits on top as an override, and is the only
/// layer a scene file records.
class PrefabNestingTests
{
	private static Guid InnerId => .(0x1111, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);
	private static Guid OuterId => .(0x2222, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);

	/// A resolver over a fixed set of payloads. Hands out a fresh copy each call, since the
	/// spawn owns what it is given.
	private class Payloads
	{
		private Dictionary<Guid, List<uint8>> mByPrefab = new .() ~ DeleteDictionaryAndValues!(_);

		public void Add(Guid prefabId, MemoryStream source)
		{
			let bytes = new List<uint8>();
			bytes.AddRange(source.Bytes);
			if (mByPrefab.ContainsKey(prefabId))
			{
				delete mByPrefab[prefabId];
				mByPrefab[prefabId] = bytes;
				return;
			}
			mByPrefab[prefabId] = bytes;
		}

		public IStream Resolve(Guid prefabId)
		{
			if (!mByPrefab.TryGetValue(prefabId, let bytes))
				return null;
			let stream = new MemoryStream();
			stream.Write(bytes);
			stream.Seek(0, .Begin);
			return stream;
		}
	}

	/// The inner prefab: a barrel carrying health.
	private static void CaptureInner(MemoryStream payload, float health = 10.0f)
	{
		let scene = scope Scene();
		let manager = scene.AddSystem<HealthManager>();
		let root = scene.CreateEntity("Barrel");
		manager.Add(root).Value = health;
		Test.Assert(PrefabCapture.Capture(scene, root, payload, .Binary) case .Ok);
		payload.Seek(0, .Begin);
	}

	/// The outer prefab: a turret with an instance of the inner one under it.
	///
	/// `innerOverride` is what the OUTER prefab's author changed about the inner instance,
	/// which is the layer that has to become a baseline rather than an override.
	private static void CaptureOuter(MemoryStream outer, Payloads payloads, float innerOverride)
	{
		let scene = scope Scene();
		let manager = scene.AddSystem<HealthManager>();
		let root = scene.CreateEntity("Turret");
		manager.Add(root).Value = 100.0f;

		let inner = payloads.Resolve(InnerId);
		defer delete inner;
		let nested = PrefabSpawn.Spawn(scene, inner, InnerId, root);
		Test.Assert(nested.IsAssigned);

		// The outer prefab's author customises the inner instance.
		manager.Get(nested).Value = innerOverride;

		Test.Assert(PrefabCapture.Capture(scene, root, outer, .Binary) case .Ok);
		outer.Seek(0, .Begin);
	}

	[Test]
	public static void AContainedInstanceStaysAnInstanceThroughCapture()
	{
		let payloads = scope Payloads();
		let innerPayload = scope MemoryStream();
		CaptureInner(innerPayload);
		payloads.Add(InnerId, innerPayload);

		let outerPayload = scope MemoryStream();
		CaptureOuter(outerPayload, payloads, 55.0f);
		payloads.Add(OuterId, outerPayload);

		let scene = scope Scene();
		let manager = scene.AddSystem<HealthManager>();
		ScenePrefabs.PayloadResolver resolver = scope (id) => payloads.Resolve(id);

		let outer = payloads.Resolve(OuterId);
		defer delete outer;
		let spawned = PrefabSpawn.Spawn(scene, outer, OuterId, .Invalid, null, resolver);

		Test.Assert(spawned.IsAssigned);
		Test.Assert(scene.GetEntityName(spawned) == "Turret");
		Test.Assert(scene.GetChildCount(spawned) == 1, "the nested instance came with it");

		let nested = scene.GetFirstChild(spawned);
		Test.Assert(scene.GetEntityName(nested) == "Barrel");

		// It is still an INSTANCE, linked to its owner, not a flattened copy.
		Test.Assert(scene.PrefabInstanceCount == 2);
		let nestedState = scene.FindPrefabInstanceByRoot(scene.GetEntityId(nested));
		Test.Assert(nestedState != null);
		Test.Assert(nestedState.PrefabId == InnerId);
		Test.Assert(nestedState.OwnerRootEntityId == scene.GetEntityId(spawned));

		// And the outer prefab's customisation of it came through.
		Test.Assert(manager.Get(nested).Value == 55.0f);
	}

	/// The OUTER prefab's customisation of the inner instance is a BASELINE, not an
	/// override: a scene that changed nothing writes no overrides for it.
	[Test]
	public static void TheOwnersCustomisationBecomesTheBaseline()
	{
		let payloads = scope Payloads();
		let innerPayload = scope MemoryStream();
		CaptureInner(innerPayload);
		payloads.Add(InnerId, innerPayload);

		let outerPayload = scope MemoryStream();
		CaptureOuter(outerPayload, payloads, 55.0f);
		payloads.Add(OuterId, outerPayload);

		let scene = scope Scene();
		scene.AddSystem<HealthManager>();
		ScenePrefabs.PayloadResolver resolver = scope (id) => payloads.Resolve(id);
		let outer = payloads.Resolve(OuterId);
		defer delete outer;
		let spawned = PrefabSpawn.Spawn(scene, outer, OuterId, .Invalid, null, resolver);

		let nested = scene.GetFirstChild(spawned);
		let nestedState = scene.FindPrefabInstanceByRoot(scene.GetEntityId(nested));

		let delta = PrefabDeltas.Compute(scene, nestedState);
		defer delete delta;

		Test.Assert(delta.ComponentOps.IsEmpty,
			"the owner's customisation is the baseline, so the scene records nothing");
	}

	/// A change to ONE placement is an override on top, and only that layer is a scene's.
	[Test]
	public static void ASceneEditOfANestedInstanceIsAnOverride()
	{
		let payloads = scope Payloads();
		let innerPayload = scope MemoryStream();
		CaptureInner(innerPayload);
		payloads.Add(InnerId, innerPayload);
		let outerPayload = scope MemoryStream();
		CaptureOuter(outerPayload, payloads, 55.0f);
		payloads.Add(OuterId, outerPayload);

		let scene = scope Scene();
		let manager = scene.AddSystem<HealthManager>();
		ScenePrefabs.PayloadResolver resolver = scope (id) => payloads.Resolve(id);
		let outer = payloads.Resolve(OuterId);
		defer delete outer;
		let spawned = PrefabSpawn.Spawn(scene, outer, OuterId, .Invalid, null, resolver);

		let nested = scene.GetFirstChild(spawned);
		let nestedState = scene.FindPrefabInstanceByRoot(scene.GetEntityId(nested));

		manager.Get(nested).Value = 999.0f;

		let delta = PrefabDeltas.Compute(scene, nestedState);
		defer delete delta;
		Test.Assert(delta.ComponentOps.Count == 1);
		Test.Assert(delta.ComponentOps[0].Op == .Modify);
	}

	/// The whole loop: a scene with a nested instance saves, loads and resolves back to
	/// what it was, with both layers in the right places.
	[Test]
	public static void ANestedInstanceSurvivesSaveAndLoad()
	{
		let payloads = scope Payloads();
		let innerPayload = scope MemoryStream();
		CaptureInner(innerPayload);
		payloads.Add(InnerId, innerPayload);
		let outerPayload = scope MemoryStream();
		CaptureOuter(outerPayload, payloads, 55.0f);
		payloads.Add(OuterId, outerPayload);

		let scene = scope Scene();
		let manager = scene.AddSystem<HealthManager>();
		ScenePrefabs.PayloadResolver resolver = scope (id) => payloads.Resolve(id);
		let outer = payloads.Resolve(OuterId);
		defer delete outer;
		let spawned = PrefabSpawn.Spawn(scene, outer, OuterId, .Invalid, null, resolver);

		// One scene level edit of the nested instance.
		let nested = scene.GetFirstChild(spawned);
		manager.Get(nested).Value = 999.0f;
		let nestedId = scene.GetEntityId(nested);
		let outerId = scene.GetEntityId(spawned);

		// Save and load.
		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			SceneSerializer.SerializeScene(writer, scene, .Referenced, true, .Binary);
		}
		buffer.Seek(0, .Begin);

		let loaded = scope Scene();
		let loadedManager = loaded.AddSystem<HealthManager>();
		let reader = scope BinarySerializer(buffer, .Read);
		SceneSerializer.SerializeScene(reader, loaded, .Referenced, true, .Binary);

		Test.Assert(loaded.EntityCount == 0, "both instances persisted as references");
		Test.Assert(loaded.PendingPrefabInstanceCount == 2, "the outer and its nested record");

		ScenePrefabs.ResolveScenePrefabs(loaded, resolver);

		Test.Assert(loaded.EntityCount == 2);
		let restoredOuter = loaded.FindEntity(outerId);
		Test.Assert(restoredOuter.IsAssigned, "the outer kept its id");
		let restoredNested = loaded.FindEntity(nestedId);
		Test.Assert(restoredNested.IsAssigned, "and so did the nested one");
		Test.Assert(loaded.GetParent(restoredNested) == restoredOuter);

		Test.Assert(loadedManager.Get(restoredNested).Value == 999.0f,
			"the scene's own edit came back");
		Test.Assert(loaded.PrefabInstanceCount == 2);
		let state = loaded.FindPrefabInstanceByRoot(nestedId);
		Test.Assert(state != null);
		Test.Assert(state.OwnerRootEntityId == outerId, "still linked to its owner");
	}

	/// Editing the INNER prefab reaches a nested instance, through the outer one.
	[Test]
	public static void EditingTheInnerPrefabReachesANestedInstance()
	{
		let payloads = scope Payloads();
		let innerPayload = scope MemoryStream();
		CaptureInner(innerPayload, 10.0f);
		payloads.Add(InnerId, innerPayload);
		let outerPayload = scope MemoryStream();
		// This time the outer prefab does NOT customise the inner instance, so the inner
		// template's value is what shows.
		CaptureOuter(outerPayload, payloads, 10.0f);
		payloads.Add(OuterId, outerPayload);

		let scene = scope Scene();
		let manager = scene.AddSystem<HealthManager>();
		ScenePrefabs.PayloadResolver resolver = scope (id) => payloads.Resolve(id);
		let outer = payloads.Resolve(OuterId);
		defer delete outer;
		let spawned = PrefabSpawn.Spawn(scene, outer, OuterId, .Invalid, null, resolver);
		Test.Assert(manager.Get(scene.GetFirstChild(spawned)).Value == 10.0f);

		// The INNER prefab changes.
		let editedInner = scope MemoryStream();
		CaptureInner(editedInner, 44.0f);
		payloads.Add(InnerId, editedInner);
		let editedBytes = scope List<uint8>();
		editedBytes.AddRange(editedInner.Bytes);

		// Rebuilding the inner prefab reaches the nested instance.
		let rebuilt = PrefabRebuild.Rebuild(scene, InnerId, editedBytes, resolver);
		Test.Assert(rebuilt >= 1);

		let nested = scene.FindEntityByName("Barrel");
		Test.Assert(nested.IsAssigned);
		Test.Assert(manager.Get(nested).Value == 44.0f, "the inner edit reached it");
	}

	/// A nested record whose owner never came back spawns STANDALONE rather than being
	/// lost: a demoted instance is recoverable, a deleted one is not.
	[Test]
	public static void AnOrphanedNestedRecordSpawnsStandalone()
	{
		let payloads = scope Payloads();
		let innerPayload = scope MemoryStream();
		CaptureInner(innerPayload);
		payloads.Add(InnerId, innerPayload);
		let outerPayload = scope MemoryStream();
		CaptureOuter(outerPayload, payloads, 55.0f);
		payloads.Add(OuterId, outerPayload);

		let scene = scope Scene();
		scene.AddSystem<HealthManager>();
		ScenePrefabs.PayloadResolver resolver = scope (id) => payloads.Resolve(id);
		let outer = payloads.Resolve(OuterId);
		defer delete outer;
		PrefabSpawn.Spawn(scene, outer, OuterId, .Invalid, null, resolver);

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

		// A resolver that can no longer reach the OUTER prefab: its record cannot spawn, so
		// the nested one is orphaned.
		ScenePrefabs.PayloadResolver partial = scope (id) =>
		{
			if (id == OuterId)
				return null;
			return payloads.Resolve(id);
		};
		ScenePrefabs.ResolveScenePrefabs(loaded, partial);

		let survivor = loaded.FindEntityByName("Barrel");
		Test.Assert(survivor.IsAssigned, "the nested instance was not lost with its owner");
		Test.Assert(loaded.GetParent(survivor) == EntityHandle.Invalid, "it became top level");
	}

	/// Applying an outer instance back to its prefab KEEPS what that instance says about
	/// its nested one.
	///
	/// This is why a nested record is diffed against the child's own template rather than
	/// against the instance's baselines. The owner's customisation was folded INTO those
	/// baselines on purpose, so a baseline diff reports it as nothing at all, and the
	/// applied template would come out having forgotten it.
	[Test]
	public static void ApplyingAnOwnerKeepsWhatItSaysAboutItsNestedInstance()
	{
		let payloads = scope Payloads();
		let innerPayload = scope MemoryStream();
		CaptureInner(innerPayload, 10.0f);
		payloads.Add(InnerId, innerPayload);
		let outerPayload = scope MemoryStream();
		CaptureOuter(outerPayload, payloads, 55.0f);
		payloads.Add(OuterId, outerPayload);

		let scene = scope Scene();
		let manager = scene.AddSystem<HealthManager>();
		ScenePrefabs.PayloadResolver resolver = scope (id) => payloads.Resolve(id);
		let outer = payloads.Resolve(OuterId);
		defer delete outer;
		let spawned = PrefabSpawn.Spawn(scene, outer, OuterId, .Invalid, null, resolver);
		let state = scene.FindPrefabInstanceByRoot(scene.GetEntityId(spawned));

		// Sanity: the outer's customisation of the inner is live and is the baseline.
		Test.Assert(manager.Get(scene.GetFirstChild(spawned)).Value == 55.0f);

		// Apply this instance back to the outer prefab.
		let applied = scope MemoryStream();
		Test.Assert(PrefabApply.CaptureAsTemplate(scene, state, applied, resolver, .Binary) case .Ok);
		applied.Seek(0, .Begin);
		payloads.Add(OuterId, applied);

		// A FRESH instance of the applied template still customises its nested one.
		let target = scope Scene();
		let targetManager = target.AddSystem<HealthManager>();
		let reapplied = payloads.Resolve(OuterId);
		defer delete reapplied;
		let fresh = PrefabSpawn.Spawn(target, reapplied, OuterId, .Invalid, null, resolver);

		Test.Assert(fresh.IsAssigned);
		Test.Assert(target.GetChildCount(fresh) == 1, "the nested instance came with the template");
		Test.Assert(targetManager.Get(target.GetFirstChild(fresh)).Value == 55.0f,
			"and the owner's customisation of it survived the apply");
	}
}
