using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;

namespace Sedulous.Scene.Resource;

/// Whole scene serialization, in ONE bidirectional pass.
///
/// Read and write are the same function because a format described twice is a format that
/// drifts: the sections, their order and their keys are stated once, and the mode decides
/// which way the data moves.
///
/// Entities persist by GUID. Parent links and component owners are stored as guids and
/// relinked once every entity exists, so a stream carries no pool indices and nothing
/// depends on the order slots happened to be allocated in.
///
/// Components are serialized BY THEIR OWNING MANAGER, which is the only thing that knows
/// the concrete type, and routed back on load by a stable string id. A record whose
/// manager is absent is kept verbatim rather than dropped.
static class SceneSerializer
{
	/// Runs the whole stream.
	///
	/// `includeSettings` is false for a prefab payload: a prefab is a subtree template
	/// rather than a world, and spawning has to be able to walk PAST the section without
	/// applying anybody's settings to the target scene.
	public static void SerializeScene(ISerializer ar, Scene scene,
		ScenePrefabMode prefabMode = .Referenced, bool includeSettings = true,
		SceneStreamEncoding encoding = .Binary)
	{
		let writing = ar.Mode == .Write;
		let text = encoding == .Text;

		if (writing)
			SceneStreamFormat.WriteHeader(ar);
		else if (SceneStreamFormat.ReadHeader(ar) case .Err)
			return;

		// Referenced excludes an instance's members from the plain arrays: they respawn
		// from their prefab, and only the reference and the deltas persist.
		let prefabMembers = scope HashSet<Guid>();
		if (writing && (prefabMode == .Referenced))
		{
			scene.ForEachPrefabInstance(scope [&](state) =>
			{
				for (let live in state.LiveIds)
					prefabMembers.Add(live);
			});
		}

		SerializeName(ar, scene, writing);
		SerializeEntities(ar, scene, writing, prefabMembers);
		SerializeComponents(ar, scene, writing, text, prefabMembers);
		SerializeSettings(ar, scene, writing, text, includeSettings);
		SerializePrefabSection(ar, scene, writing, prefabMode);
	}

	private static void SerializeName(ISerializer ar, Scene scene, bool writing)
	{
		let name = scope String();
		if (writing)
			name.Set(scene.Name);

		Sedulous.Core.Serialization.Serialize(ar, "name", name);

		if (!writing)
			scene.SetName(name);
	}

	/// Entities, written in TREE order: roots in list order, then depth first.
	///
	/// Load recreates and relinks in FILE order, so sibling ORDER round trips. Pool order
	/// would shuffle siblings back to creation order, and the hierarchy is something a
	/// person arranges deliberately.
	private static void SerializeEntities(ISerializer ar, Scene scene, bool writing,
		HashSet<Guid> prefabMembers)
	{
		let handles = scope List<EntityHandle>();
		uint32 entityCount = 0;

		if (writing)
		{
			let stack = scope List<EntityHandle>();
			var root = scene.FirstRoot;
			while (root.IsAssigned)
			{
				stack.Add(root);
				while (!stack.IsEmpty)
				{
					let entity = stack.PopBack();

					// A prefab member persists as reference and deltas, never as a plain
					// record. Its non member children, entities a user parented INTO an
					// instance, still serialize: their saved parent guid stays valid
					// because an instance respawns with its SAVED member guids.
					if (!prefabMembers.Contains(scene.GetEntityId(entity)))
						handles.Add(entity);

					let children = scope:: List<EntityHandle>();
					var child = scene.GetFirstChild(entity);
					while (child.IsAssigned)
					{
						children.Add(child);
						child = scene.GetNextSibling(child);
					}
					// Reversed, so they pop in list order.
					for (int i = children.Count - 1; i >= 0; i--)
						stack.Add(children[i]);
				}
				root = scene.GetNextSibling(root);
			}
			entityCount = (uint32)handles.Count;
		}

		ar.Key("entities");
		ar.BeginArray(ref entityCount);

		if (writing)
		{
			for (let entity in handles)
			{
				var id = scene.GetEntityId(entity);
				let name = scope:: String(scene.GetEntityName(entity));
				var active = scene.IsActive(entity) ? (uint8)1 : (uint8)0;
				let parent = scene.GetParent(entity);
				var parentId = parent.IsAssigned ? scene.GetEntityId(parent) : Guid();
				var transform = scene.GetLocalTransform(entity);

				SerializeValue(ar, "id", ref id);
				Sedulous.Core.Serialization.Serialize(ar, "name", name);
				SerializeValue(ar, "active", ref active);
				SerializeValue(ar, "parent", ref parentId);
				SceneStreamFormat.SerializeTransform(ar, ref transform);
			}
		}
		else
		{
			let ids = scope List<Guid>();
			let parents = scope List<Guid>();

			for (uint32 i < entityCount)
			{
				Guid id = .();
				let name = scope:: String();
				uint8 active = 0;
				Guid parentId = .();
				Transform transform = .();

				SerializeValue(ar, "id", ref id);
				Sedulous.Core.Serialization.Serialize(ar, "name", name);
				SerializeValue(ar, "active", ref active);
				SerializeValue(ar, "parent", ref parentId);
				SceneStreamFormat.SerializeTransform(ar, ref transform);

				// Corrupt save recovery: a DUPLICATE entity guid gets a fresh one, so every
				// entity stays uniquely addressable. Records addressed to the shared guid,
				// components and parent links, route to its first holder.
				EntityHandle handle;
				if (scene.FindEntity(id).IsAssigned)
				{
					GlobalLog(.Warning,
						"SceneSerializer: a duplicate entity guid in the save for '{}', assigning a fresh one",
						name);
					handle = scene.CreateEntity(name);
					// Relink by the FRESH id, since that is what the entity now answers to.
					ids.Add(scene.GetEntityId(handle));
				}
				else
				{
					handle = scene.CreateEntity(id, name);
					ids.Add(id);
				}

				scene.SetActive(handle, active != 0);
				scene.SetLocalTransform(handle, transform);
				parents.Add(parentId);
			}

			// Relink only now that every entity exists: a parent may appear after its child
			// in the file, and a forward reference has to resolve either way.
			for (int i = 0; i < ids.Count; i++)
			{
				if (parents[i] == Guid())
					continue;
				let child = scene.FindEntity(ids[i]);
				let parent = scene.FindEntity(parents[i]);
				if (child.IsAssigned && parent.IsAssigned)
					scene.SetParent(child, parent);
			}
		}

		ar.EndArray();
	}

	/// Component records: an owner guid, a stable type id, and the data.
	///
	/// TEXT puts each record in its own object scope with the fields inline, which is
	/// diffable and lets a reader skip a record it does not understand by scope. BINARY
	/// length prefixes the payload, which is what lets a reader skip a type this build
	/// does not know instead of aborting the whole section.
	private static void SerializeComponents(ISerializer ar, Scene scene, bool writing, bool text,
		HashSet<Guid> prefabMembers)
	{
		let managers = scope List<ComponentManagerBase>();
		let owners = scope List<EntityHandle>();
		uint32 componentCount = 0;

		if (writing)
		{
			scene.ForEachManager(scope [&](manager) =>
			{
				if (!manager.IsSerializable)
					return;
				for (let owner in manager.OwnerHandles)
				{
					if (prefabMembers.Contains(scene.GetEntityId(owner)))
						continue;
					managers.Add(manager);
					owners.Add(owner);
				}
			});
			componentCount = (uint32)managers.Count;

			// A record whose manager was absent at load writes back VERBATIM, so a save
			// never drops a plugin's components. A record captured in the OTHER encoding
			// cannot be re-encoded without understanding it, so those are dropped LOUDLY
			// rather than silently mangled.
			uint32 dropped = 0;
			for (let record in scene.UnresolvedComponents)
			{
				if (record.Text == text)
					componentCount++;
				else
					dropped++;
			}
			if (dropped > 0)
			{
				GlobalLog(.Warning,
					"SceneSerializer: dropping {} unresolved component record(s) captured in the other encoding. Load their plugin and re save to convert them.",
					dropped);
			}
		}

		ar.Key("components");
		ar.BeginArray(ref componentCount);

		if (writing)
		{
			for (int i = 0; i < managers.Count; i++)
				WriteComponentRecord(ar, scene, managers[i], owners[i], text);

			for (let record in scene.UnresolvedComponents)
			{
				if (record.Text != text)
					continue;

				var ownerId = record.Owner;
				if (text)
				{
					ar.BeginObject();
					SerializeValue(ar, "owner", ref ownerId);
					Sedulous.Core.Serialization.Serialize(ar, "type", record.TypeId);
					// Re injects the captured element untouched.
					ar.RawRemainder(record.Payload);
					ar.EndObject();
				}
				else
				{
					SerializeValue(ar, "owner", ref ownerId);
					Sedulous.Core.Serialization.Serialize(ar, "type", record.TypeId);
					SerializeBlob(ar, "data", record.Payload);
				}
			}
		}
		else
		{
			let warned = scope HashSet<String>();
			defer { ClearAndDeleteItems!(warned); }

			for (uint32 i < componentCount)
				ReadComponentRecord(ar, scene, text, warned);
		}

		ar.EndArray();
	}

	private static void WriteComponentRecord(ISerializer ar, Scene scene,
		ComponentManagerBase manager, EntityHandle owner, bool text)
	{
		var ownerId = scene.GetEntityId(owner);
		let typeId = scope String(manager.SerializationTypeId);

		if (text)
		{
			ar.BeginObject();
			SerializeValue(ar, "owner", ref ownerId);
			Sedulous.Core.Serialization.Serialize(ar, "type", typeId);
			ar.Key("data");
			ar.BeginObject();
			manager.WriteComponent(ar, owner);
			ar.EndObject();
			ar.EndObject();
			return;
		}

		SerializeValue(ar, "owner", ref ownerId);
		Sedulous.Core.Serialization.Serialize(ar, "type", typeId);
		let blob = scope List<uint8>();
		SceneStreamFormat.ComponentToBlob(manager, owner, blob);
		SerializeBlob(ar, "data", blob);
	}

	private static void ReadComponentRecord(ISerializer ar, Scene scene, bool text,
		HashSet<String> warned)
	{
		if (text)
			ar.BeginObject();

		Guid ownerId = .();
		let typeId = scope String();
		SerializeValue(ar, "owner", ref ownerId);
		Sedulous.Core.Serialization.Serialize(ar, "type", typeId);

		let owner = scene.FindEntity(ownerId);
		let manager = scene.FindManagerBySerializationId(typeId);

		if (text)
		{
			if ((manager != null) && owner.IsAssigned)
			{
				ar.Key("data");
				ar.BeginObject();
				manager.ReadComponent(ar, owner);
				ar.EndObject();
			}
			else if (manager == null)
			{
				KeepUnresolvedComponent(ar, scene, ownerId, typeId, true, warned);
			}
			ar.EndObject();
			return;
		}

		let blob = scope List<uint8>();
		SerializeBlob(ar, "data", blob);

		if ((manager != null) && owner.IsAssigned)
			SceneStreamFormat.ComponentFromBlob(manager, owner, blob);
		else if (manager == null)
			KeepUnresolvedComponentBlob(scene, ownerId, typeId, blob, warned);
	}

	/// Keeps a text record's remaining element verbatim, so a save writes it back untouched
	/// and it becomes a real component the moment its manager arrives.
	private static void KeepUnresolvedComponent(ISerializer ar, Scene scene, Guid ownerId,
		StringView typeId, bool text, HashSet<String> warned)
	{
		let record = new UnresolvedComponent();
		record.Owner = ownerId;
		record.TypeId.Set(typeId);
		record.Text = text;

		if (ar.RawRemainder(record.Payload))
			scene.AddUnresolvedComponent(record);
		else
			delete record;

		WarnOnce(warned, typeId,
			"SceneSerializer: component type '{}' has no manager in this build, records kept unresolved and preserved on save");
	}

	private static void KeepUnresolvedComponentBlob(Scene scene, Guid ownerId, StringView typeId,
		List<uint8> blob, HashSet<String> warned)
	{
		let record = new UnresolvedComponent();
		record.Owner = ownerId;
		record.TypeId.Set(typeId);
		record.Text = false;
		record.Payload.AddRange(blob);
		scene.AddUnresolvedComponent(record);

		WarnOnce(warned, typeId,
			"SceneSerializer: component type '{}' has no manager in this build, records kept unresolved and preserved on save");
	}

	/// One warning per type, not per record: a scene with a thousand components of an
	/// absent type has one problem, not a thousand.
	private static void WarnOnce(HashSet<String> warned, StringView key, StringView message)
	{
		let owned = scope String(key);
		if (warned.Contains(owned))
			return;
		warned.Add(new String(key));
		GlobalLog(.Warning, message, key);
	}

	/// A byte payload, count prefixed then written whole.
	private static void SerializeBlob(ISerializer ar, StringView key, List<uint8> bytes)
	{
		ar.Key(key);
		uint32 count = (uint32)bytes.Count;
		ar.BeginArray(ref count);
		if (ar.Mode == .Read)
		{
			bytes.Clear();
			bytes.Resize((int)count);
		}
		if (count > 0)
			ar.Blob(bytes.Ptr, (int)count);
		ar.EndArray();
	}

	/// A scene system's settings block: its stable id, then a versioned payload.
	///
	/// Same skippability bargain as a component. TEXT gets it from the per record object
	/// scope with the payload inline; BINARY from a length prefixed blob, so a reader
	/// steps over a system this build does not have instead of losing the section.
	private static void SerializeSettings(ISerializer ar, Scene scene, bool writing, bool text,
		bool includeSettings)
	{
		let systems = scope List<SceneSystem>();
		uint32 settingsCount = 0;

		if (writing)
		{
			if (includeSettings)
			{
				for (let system in scene.Systems)
				{
					if (system.SettingsType != null)
						systems.Add(system);
				}
			}
			settingsCount = (uint32)systems.Count;

			uint32 dropped = 0;
			for (let record in scene.UnresolvedSettingsRecords)
			{
				if (record.Text == text)
					settingsCount++;
				else
					dropped++;
			}
			if (dropped > 0)
			{
				GlobalLog(.Warning,
					"SceneSerializer: dropping {} unresolved settings record(s) captured in the other encoding.",
					dropped);
			}
		}

		ar.Key("systemSettings");
		ar.BeginArray(ref settingsCount);

		if (writing)
		{
			for (let system in systems)
				WriteSettingsRecord(ar, system, text);

			for (let record in scene.UnresolvedSettingsRecords)
			{
				if (record.Text != text)
					continue;
				if (text)
				{
					ar.BeginObject();
					Sedulous.Core.Serialization.Serialize(ar, "system", record.SystemId);
					ar.RawRemainder(record.Payload);
					ar.EndObject();
				}
				else
				{
					Sedulous.Core.Serialization.Serialize(ar, "system", record.SystemId);
					SerializeBlob(ar, "data", record.Payload);
				}
			}
		}
		else
		{
			for (uint32 i < settingsCount)
				ReadSettingsRecord(ar, scene, text);
		}

		ar.EndArray();
	}

	private static void WriteSettingsRecord(ISerializer ar, SceneSystem system, bool text)
	{
		let id = scope String(system.SettingsId);

		if (text)
		{
			ar.BeginObject();
			Sedulous.Core.Serialization.Serialize(ar, "system", id);
			BeginVersionedPayload(ar, TypeIdOf(id), system.SettingsDataVersion);
			ar.Key("settings");
			ar.BeginObject();
			system.SerializeSettings(ar);
			ar.EndObject();
			EndVersionedPayload(ar);
			ar.EndObject();
			return;
		}

		Sedulous.Core.Serialization.Serialize(ar, "system", id);

		// Into its own buffer first, so the record can be LENGTH PREFIXED: that length is
		// what lets a reader skip a system it does not have.
		let buffer = scope MemoryStream();
		{
			let sub = scope BinarySerializer(buffer, .Write);
			BeginVersionedPayload(sub, TypeIdOf(id), system.SettingsDataVersion);
			sub.Key("settings");
			sub.BeginObject();
			system.SerializeSettings(sub);
			sub.EndObject();
			EndVersionedPayload(sub);
		}

		let blob = scope List<uint8>();
		blob.AddRange(buffer.Bytes);
		SerializeBlob(ar, "data", blob);
	}

	private static void ReadSettingsRecord(ISerializer ar, Scene scene, bool text)
	{
		if (text)
			ar.BeginObject();

		let id = scope String();
		Sedulous.Core.Serialization.Serialize(ar, "system", id);

		SceneSystem target = null;
		for (let system in scene.Systems)
		{
			if ((system.SettingsType != null) && (system.SettingsId == id))
			{
				target = system;
				break;
			}
		}

		if (text)
		{
			if (target != null)
			{
				BeginVersionedPayload(ar, TypeIdOf(id), target.SettingsDataVersion);
				ar.Key("settings");
				ar.BeginObject();
				target.SerializeSettings(ar);
				ar.EndObject();
				EndVersionedPayload(ar);
			}
			else
			{
				let record = new UnresolvedSettings();
				record.SystemId.Set(id);
				record.Text = true;
				if (ar.RawRemainder(record.Payload))
					scene.AddUnresolvedSettings(record);
				else
					delete record;
				GlobalLog(.Warning,
					"SceneSerializer: settings of system '{}' kept unresolved, no such system in this build",
					id);
			}
			ar.EndObject();
			return;
		}

		let blob = scope List<uint8>();
		SerializeBlob(ar, "data", blob);

		if (target == null)
		{
			let record = new UnresolvedSettings();
			record.SystemId.Set(id);
			record.Text = false;
			record.Payload.AddRange(blob);
			scene.AddUnresolvedSettings(record);
			GlobalLog(.Warning,
				"SceneSerializer: settings of system '{}' kept unresolved, no such system in this build",
				id);
			return;
		}

		let buffer = scope MemoryStream();
		buffer.Write(blob);
		buffer.Seek(0, .Begin);
		let sub = scope BinarySerializer(buffer, .Read);
		BeginVersionedPayload(sub, TypeIdOf(id), target.SettingsDataVersion);
		sub.Key("settings");
		sub.BeginObject();
		target.SerializeSettings(sub);
		sub.EndObject();
		EndVersionedPayload(sub);
	}

	/// The prefab section: the stream's tail, and the mode tag that says how to read it.
	///
	/// The records themselves are NOT written yet: the machinery that derives an
	/// instance's deltas and respawns it lands with the prefab port. The tag and the empty
	/// array are written now so the format is whole and a stream written today reads
	/// unchanged once the records arrive.
	private static void SerializePrefabSection(ISerializer ar, Scene scene, bool writing,
		ScenePrefabMode prefabMode)
	{
		var sectionMode = (prefabMode == .Referenced)
			? SceneStreamFormat.cPrefabWireReferenced
			: SceneStreamFormat.cPrefabWireExpanded;
		SerializeValue(ar, "prefabMode", ref sectionMode);

		uint32 instanceCount = 0;
		ar.Key((sectionMode == SceneStreamFormat.cPrefabWireReferenced)
			? "prefabInstances" : "prefabStates");
		ar.BeginArray(ref instanceCount);
		ar.EndArray();
	}
}
