using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace Sedulous.Scene.Resource;

/// Instantiating a prefab payload into a scene.
///
/// The members get FRESH guids, or preassigned ones when a load is restoring an instance
/// that already existed, and the instance records the map from the template's source ids
/// to them, plus a baseline of everything as it stood at spawn. That baseline is what
/// makes an override derivable later, so it has to be captured here and nowhere else.
static class PrefabSpawn
{
	/// Spawns `payload` under `parent`, returning the instance's root.
	///
	/// `preassigned` maps a source id to the live guid it must take, which is how a load
	/// restores an instance whose members are already named by the rest of the save. A
	/// source with no entry, or one whose guid is taken, gets a fresh id.
	///
	/// `resolver` reaches the payloads of the prefabs this one NESTS. Without one the
	/// nested records are skipped and only the outer subtree spawns, which is the right
	/// answer for a caller that has no database rather than a reason to fail.
	///
	/// `sceneDeltas` are the scene's own records for those nested instances, layered over
	/// the owner's customisation of them. `spawnNested` false stops the walk at this level,
	/// which is how a nested spawn avoids recursing into itself.
	public static EntityHandle Spawn(Scene scene, IStream payload, Guid prefabId,
		EntityHandle parent = .Invalid, Dictionary<Guid, Guid> preassigned = null,
		ScenePrefabs.PayloadResolver resolver = null,
		List<PendingPrefabInstance> sceneDeltas = null, bool spawnNested = true)
	{
		let reader = scope SceneStreamReader();
		if (!(reader.Open(payload) case .Ok(let ar)))
			return .Invalid;
		let text = reader.Encoding == .Text;

		if (SceneStreamFormat.ReadHeader(ar) case .Err)
			return .Invalid;

		let name = scope String();
		Sedulous.Core.Serialization.Serialize(ar, "name", name);

		let state = new PrefabInstanceState();
		state.PrefabId = prefabId;

		let liveBySource = scope Dictionary<Guid, Guid>();
		let sourceParents = scope List<Guid>();

		let firstRoot = ReadEntities(ar, scene, state, liveBySource, sourceParents, preassigned);
		if (!ar.IsPayloadOk || !firstRoot.IsAssigned)
		{
			delete state;
			return .Invalid;
		}

		if (!Relink(scene, state, sourceParents, liveBySource, firstRoot, parent))
		{
			delete state;
			return .Invalid;
		}

		ReadComponents(ar, scene, state, liveBySource, text);
		if (!ar.IsPayloadOk)
		{
			delete state;
			return .Invalid;
		}

		let rootGuid = scene.GetEntityId(firstRoot);
		state.RootEntityId = rootGuid;
		state.ReferencedPrefabIds.Add(prefabId);
		scene.AddPrefabInstance(state);

		if (spawnNested)
			SpawnNested(ar, scene, firstRoot, rootGuid, liveBySource, text, resolver, sceneDeltas,
				state);

		return firstRoot;
	}

	/// The payload's trailing section: an empty settings block, the mode tag, then the
	/// records for the instances this prefab CONTAINS.
	///
	/// Anything else is not the current payload shape. The outer subtree is already live by
	/// then, so the nested instances are skipped loudly rather than the whole spawn failing.
	private static void SpawnNested(ISerializer ar, Scene scene, EntityHandle firstRoot,
		Guid rootGuid, Dictionary<Guid, Guid> liveBySource, bool text,
		ScenePrefabs.PayloadResolver resolver, List<PendingPrefabInstance> sceneDeltas,
		PrefabInstanceState ownerState)
	{
		uint32 settingsCount = 0;
		ar.Key("systemSettings");
		ar.BeginArray(ref settingsCount);
		ar.EndArray();

		uint8 sectionMode = 0;
		SerializeValue(ar, "prefabMode", ref sectionMode);

		if (!ar.IsPayloadOk || (settingsCount != 0)
			|| (sectionMode != SceneStreamFormat.cPrefabWireReferenced))
		{
			GlobalLog(.Error,
				"PrefabSpawn: the payload's nested section is not in the current format, nested instances skipped. Re-save the prefab.");
			return;
		}

		let records = scope List<PendingPrefabInstance>();
		defer { ClearAndDeleteItems!(records); }

		uint32 recordCount = 0;
		ar.Key("prefabInstances");
		ar.BeginArray(ref recordCount);
		for (uint32 i = 0; (i < recordCount) && ar.IsPayloadOk; i++)
		{
			let record = new PendingPrefabInstance();
			PrefabRecordSerializer.Read(ar, scene, record, text);
			records.Add(record);
		}
		ar.EndArray();
		if (!ar.IsPayloadOk || records.IsEmpty)
			return;

		// The owner's namespace to live guids: this payload's own entities first, then each
		// spawned record's members as they arrive. Records are written in registration
		// order, so a parent is always mapped before whatever names it.
		let ownerNamespace = scope Dictionary<Guid, Guid>();
		for (let pair in liveBySource)
			ownerNamespace[pair.key] = pair.value;

		let order = scope List<(Guid entity, Guid nextSibling)>();

		for (let record in records)
		{
			// The owner RECORDS which prefabs its payload consumed, so editing one of them
			// rebuilds this instance and the nested one comes back from the new template.
			// Without it an edit to an inner prefab would reach a top level instance of it
			// and silently miss every nested one.
			if (!ownerState.ReferencedPrefabIds.Contains(record.PrefabId))
				ownerState.ReferencedPrefabIds.Add(record.PrefabId);

			let childRoot = SpawnOneNested(scene, firstRoot, rootGuid, record, ownerNamespace,
				resolver, sceneDeltas);
			if (!childRoot.IsAssigned)
				continue;
			order.Add((scene.GetEntityId(childRoot), record.NextSiblingId));
		}

		ScenePrefabs.RestoreSiblingOrder(scene, order);
	}

	private static EntityHandle SpawnOneNested(Scene scene, EntityHandle firstRoot, Guid rootGuid,
		PendingPrefabInstance record, Dictionary<Guid, Guid> ownerNamespace,
		ScenePrefabs.PayloadResolver resolver, List<PendingPrefabInstance> sceneDeltas)
	{
		let childPayload = (resolver != null) ? resolver(record.PrefabId) : null;
		if (childPayload == null)
		{
			GlobalLog(.Warning,
				"PrefabSpawn: a nested record was skipped, its payload did not resolve");
			return .Invalid;
		}
		defer delete childPayload;

		// The SCENE's own record for this nested instance, matched on the identity it has in
		// the owner's namespace.
		PendingPrefabInstance sceneRecord = null;
		if (sceneDeltas != null)
		{
			for (let candidate in sceneDeltas)
			{
				if ((candidate != null) && (candidate.NestedRootSourceId == record.RootLiveId))
				{
					sceneRecord = candidate;
					break;
				}
			}
		}

		let childPreassigned = scope Dictionary<Guid, Guid>();
		if (sceneRecord != null)
		{
			for (int i = 0; (i < sceneRecord.SourceIds.Count) && (i < sceneRecord.LiveIds.Count); i++)
				childPreassigned[sceneRecord.SourceIds[i]] = sceneRecord.LiveIds[i];
		}

		var recordParent = firstRoot;
		if (ownerNamespace.TryGetValue(record.ParentEntityId, let liveParent))
		{
			let resolved = scene.FindEntity(liveParent);
			if (resolved.IsAssigned)
				recordParent = resolved;
		}

		// Not nested itself: this walk goes one level at a time, through the records, so a
		// prefab that names itself cannot spin.
		let child = PrefabSpawn.Spawn(scene, childPayload, record.PrefabId, recordParent,
			childPreassigned, null, null, false);
		if (!child.IsAssigned)
			return .Invalid;

		let childRootGuid = scene.GetEntityId(child);
		let childState = scene.FindPrefabInstanceByRoot(childRootGuid);
		if (childState == null)
			return .Invalid;

		childState.OwnerRootEntityId = rootGuid;
		childState.NestedRootSourceId = record.RootLiveId;

		for (let member in childState.LiveIds)
			ownerNamespace[member] = member;

		// The owner's customisation goes on FIRST and then becomes the baseline, so a scene
		// save records only what the scene changed and an edit to the owner template still
		// reaches this instance.
		scene.SetLocalTransform(child, record.RootTransform);
		PrefabDeltas.Apply(scene, childState, record);
		PrefabNesting.RecaptureBaselines(scene, childState);

		if (sceneRecord != null)
		{
			// A placement the scene never moved takes the owner template's, so moving a
			// nested part in the outer prefab reaches every placement of it.
			if (sceneRecord.ApplyPlacement)
			{
				if (sceneRecord.ParentEntityId != Guid())
				{
					let sceneParent = scene.FindEntity(sceneRecord.ParentEntityId);
					if (sceneParent.IsAssigned)
						scene.SetParent(child, sceneParent);
				}
				scene.SetLocalTransform(child, sceneRecord.RootTransform);
			}
			PrefabDeltas.Apply(scene, childState, sceneRecord);
		}

		return child;
	}

	private static EntityHandle ReadEntities(ISerializer ar, Scene scene, PrefabInstanceState state,
		Dictionary<Guid, Guid> liveBySource, List<Guid> sourceParents,
		Dictionary<Guid, Guid> preassigned)
	{
		uint32 entityCount = 0;
		ar.Key("entities");
		ar.BeginArray(ref entityCount);

		var firstRoot = EntityHandle.Invalid;
		for (uint32 i < entityCount)
		{
			Guid sourceId = .();
			let entityName = scope:: String();
			uint8 active = 0;
			Guid sourceParent = .();
			Transform transform = .();

			SerializeValue(ar, "id", ref sourceId);
			Sedulous.Core.Serialization.Serialize(ar, "name", entityName);
			SerializeValue(ar, "active", ref active);
			SerializeValue(ar, "parent", ref sourceParent);
			SceneStreamFormat.SerializeTransform(ar, ref transform);

			EntityHandle live;
			if ((preassigned != null) && preassigned.TryGetValue(sourceId, let wanted)
				&& !scene.FindEntity(wanted).IsAssigned)
				live = scene.CreateEntity(wanted, entityName);
			else
				// A fresh id: the template's own guid belongs to the template, and two
				// instances sharing it would be one entity as far as every map is concerned.
				live = scene.CreateEntity(entityName);

			scene.SetActive(live, active != 0);
			scene.SetLocalTransform(live, transform);

			let liveId = scene.GetEntityId(live);
			liveBySource[sourceId] = liveId;
			state.SourceIds.Add(sourceId);
			state.LiveIds.Add(liveId);
			state.BaselineTransforms.Add(transform);
			sourceParents.Add(sourceParent);

			if ((sourceParent == Guid()) && !firstRoot.IsAssigned)
				firstRoot = live;
		}
		ar.EndArray();
		return firstRoot;
	}

	/// Payload internal parents route through the map; the instance ROOT goes under the
	/// requested parent.
	///
	/// A prefab is SINGLE rooted, and capture, apply and revert all walk one root's
	/// subtree. A payload carrying more than one is not the current format and is REFUSED
	/// rather than normalised: quietly parenting the extras under the first invents a
	/// hierarchy nobody authored, and the deltas keyed on it would then describe a shape
	/// the template never had.
	private static bool Relink(Scene scene, PrefabInstanceState state, List<Guid> sourceParents,
		Dictionary<Guid, Guid> liveBySource, EntityHandle firstRoot, EntityHandle parent)
	{
		for (int i = 0; i < state.SourceIds.Count; i++)
		{
			let child = scene.FindEntity(state.LiveIds[i]);
			if (!child.IsAssigned)
				continue;

			if (sourceParents[i] == Guid())
			{
				if (child != firstRoot)
				{
					GlobalLog(.Error,
						"PrefabSpawn: the payload has more than one root, which is not the current single root format. Re-save the prefab.");
					return false;
				}
				if (parent.IsAssigned)
					scene.SetParent(child, parent);
				continue;
			}

			if (liveBySource.TryGetValue(sourceParents[i], let liveParent))
			{
				let resolved = scene.FindEntity(liveParent);
				if (resolved.IsAssigned)
					scene.SetParent(child, resolved);
			}
		}
		return true;
	}

	private static void ReadComponents(ISerializer ar, Scene scene, PrefabInstanceState state,
		Dictionary<Guid, Guid> liveBySource, bool text)
	{
		uint32 componentCount = 0;
		ar.Key("components");
		ar.BeginArray(ref componentCount);

		for (uint32 i < componentCount)
		{
			if (text)
				ar.BeginObject();

			Guid sourceOwner = .();
			let typeId = scope:: String();
			SerializeValue(ar, "owner", ref sourceOwner);
			Sedulous.Core.Serialization.Serialize(ar, "type", typeId);

			var owner = EntityHandle.Invalid;
			if (liveBySource.TryGetValue(sourceOwner, let liveId))
				owner = scene.FindEntity(liveId);
			let manager = scene.FindManagerBySerializationId(typeId);

			if (text)
			{
				if (owner.IsAssigned && (manager != null))
				{
					ar.Key("data");
					ar.BeginObject();
					manager.ReadComponent(ar, owner);
					ar.EndObject();
					CaptureBaseline(scene, state, manager, owner, sourceOwner, liveBySource);
				}
				else
				{
					GlobalLog(.Warning,
						"PrefabSpawn: a component record of type '{}' was skipped, having no owner or no manager",
						typeId);
				}
				ar.EndObject();
				continue;
			}

			let blob = scope:: List<uint8>();
			SceneSerializer.[Friend]SerializeBlob(ar, "data", blob);

			if (!owner.IsAssigned || (manager == null))
			{
				GlobalLog(.Warning,
					"PrefabSpawn: a component record of type '{}' was skipped, having no owner or no manager",
					typeId);
				continue;
			}

			SceneStreamFormat.ComponentFromBlob(manager, owner, blob);
			CaptureBaseline(scene, state, manager, owner, sourceOwner, liveBySource);
		}
		ar.EndArray();
	}

	/// Remaps the component's own entity references, then records what it now holds.
	///
	/// In that order, so the baseline reflects the REMAPPED value. Capturing first would
	/// make the remap itself read as an override on every instance, and every save would
	/// then write a difference that spawning had introduced.
	///
	/// The baseline is RE-SERIALIZED from the live component rather than kept as the
	/// payload's bytes: a data version bump changes the bytes for identical state, and the
	/// difference would show up as a phantom override on every instance ever placed.
	private static void CaptureBaseline(Scene scene, PrefabInstanceState state,
		ComponentManagerBase manager, EntityHandle owner, Guid sourceOwner,
		Dictionary<Guid, Guid> liveBySource)
	{
		PrefabEntityRefs.Remap(manager, owner, liveBySource);

		let baseline = new PrefabComponentBaseline();
		baseline.SourceEntity = sourceOwner;
		baseline.TypeId.Set(manager.SerializationTypeId);
		SceneStreamFormat.ComponentToBlob(manager, owner, baseline.Blob);
		state.ComponentBaselines.Add(baseline);
	}
}
