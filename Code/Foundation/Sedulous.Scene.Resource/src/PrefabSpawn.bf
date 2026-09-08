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
	public static EntityHandle Spawn(Scene scene, IStream payload, Guid prefabId,
		EntityHandle parent = .Invalid, Dictionary<Guid, Guid> preassigned = null)
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

		state.RootEntityId = scene.GetEntityId(firstRoot);
		state.ReferencedPrefabIds.Add(prefabId);
		scene.AddPrefabInstance(state);
		return firstRoot;
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
