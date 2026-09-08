using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Xml.Serialization;

namespace Sedulous.Scene.Resource;

/// Applying an instance BACK to its prefab: what the user built in the scene becomes the
/// template.
///
/// Two rules make this safe for every OTHER instance of the same prefab.
///
/// The members are written under their SOURCE ids rather than their live ones, so the
/// deltas every other instance keys on still name the same things afterwards. An entity the
/// user ADDED keeps its live guid, which becomes a brand new source id: it was never in the
/// template, so nothing can be keyed on it yet.
///
/// The root's transform is written from its spawn time BASELINE, not from where the
/// instance currently sits. A root transform is the PLACEMENT of that one instance, not
/// content of the template, and letting it through would teleport every other instance to
/// wherever this one happened to be.
static class PrefabApply
{
	/// Captures `state`'s instance as a template payload. A source lands in the prefab
	/// asset as text.
	public static Result<void, ErrorCode> CaptureAsTemplate(Scene scene,
		PrefabInstanceState state, IStream output, SceneStreamEncoding encoding = .Text)
	{
		if (encoding == .Binary)
		{
			let ar = scope BinarySerializer(output, .Write);
			return WriteBody(ar, scene, state, false);
		}

		let ar = scope XmlSerializer();
		if (WriteBody(ar, scene, state, true) case .Err(let error))
			return .Err(error);

		let text = scope String();
		ar.GetOutput(text);
		return (output.Write(.((uint8*)text.Ptr, text.Length)) == text.Length)
			? .Ok : .Err(.Unknown);
	}

	private static Result<void, ErrorCode> WriteBody(ISerializer ar, Scene scene,
		PrefabInstanceState state, bool text)
	{
		let root = scene.FindEntity(state.RootEntityId);
		if (!root.IsAssigned)
			return .Err(.NotFound);

		// Live id to source id, for every member that is still there.
		let sourceOf = scope Dictionary<Guid, Guid>();
		for (int i = 0; i < state.SourceIds.Count; i++)
			sourceOf[state.LiveIds[i]] = state.SourceIds[i];

		Guid Substituted(Guid live)
		{
			// A user added entity has no source id, so its live guid BECOMES one.
			if (sourceOf.TryGetValue(live, let source))
				return source;
			return live;
		}

		// The template's own root transform, which is the baseline rather than wherever
		// this instance was placed.
		var rootTemplateTransform = scene.GetLocalTransform(root);
		for (int i = 0; i < state.LiveIds.Count; i++)
		{
			if ((state.LiveIds[i] == state.RootEntityId) && (i < state.BaselineTransforms.Count))
			{
				rootTemplateTransform = state.BaselineTransforms[i];
				break;
			}
		}

		SceneStreamFormat.WriteHeader(ar);

		let name = scope String(scene.GetEntityName(root));
		Sedulous.Core.Serialization.Serialize(ar, "name", name);

		let handles = scope List<EntityHandle>();
		SceneStreamFormat.CollectSubtree(scene, root, handles);

		uint32 entityCount = (uint32)handles.Count;
		ar.Key("entities");
		ar.BeginArray(ref entityCount);
		for (let entity in handles)
		{
			var id = Substituted(scene.GetEntityId(entity));
			let entityName = scope:: String(scene.GetEntityName(entity));
			var active = scene.IsActive(entity) ? (uint8)1 : (uint8)0;
			var parentId = (entity == root)
				? Guid() : Substituted(scene.GetEntityId(scene.GetParent(entity)));
			var transform = (entity == root)
				? rootTemplateTransform : scene.GetLocalTransform(entity);

			SerializeValue(ar, "id", ref id);
			Sedulous.Core.Serialization.Serialize(ar, "name", entityName);
			SerializeValue(ar, "active", ref active);
			SerializeValue(ar, "parent", ref parentId);
			SceneStreamFormat.SerializeTransform(ar, ref transform);
		}
		ar.EndArray();

		let managers = scope List<ComponentManagerBase>();
		let owners = scope List<EntityHandle>();
		scene.ForEachManager(scope [&](manager) =>
		{
			if (!manager.IsSerializable)
				return;
			for (let owner in manager.OwnerHandles)
			{
				if (handles.Contains(owner))
				{
					managers.Add(manager);
					owners.Add(owner);
				}
			}
		});

		uint32 componentCount = (uint32)managers.Count;
		ar.Key("components");
		ar.BeginArray(ref componentCount);
		for (int i = 0; i < managers.Count; i++)
		{
			var ownerId = Substituted(scene.GetEntityId(owners[i]));
			let typeId = scope:: String(managers[i].SerializationTypeId);

			if (text)
			{
				ar.BeginObject();
				SerializeValue(ar, "owner", ref ownerId);
				Sedulous.Core.Serialization.Serialize(ar, "type", typeId);
				ar.Key("data");
				ar.BeginObject();
				managers[i].WriteComponent(ar, owners[i]);
				ar.EndObject();
				ar.EndObject();
				continue;
			}

			SerializeValue(ar, "owner", ref ownerId);
			Sedulous.Core.Serialization.Serialize(ar, "type", typeId);
			let blob = scope:: List<uint8>();
			SceneStreamFormat.ComponentToBlob(managers[i], owners[i], blob);
			SceneSerializer.[Friend]SerializeBlob(ar, "data", blob);
		}
		ar.EndArray();

		// A template carries nobody's settings.
		uint32 settingsCount = 0;
		ar.Key("systemSettings");
		ar.BeginArray(ref settingsCount);
		ar.EndArray();

		// The nested record section. Empty until nesting lands, matching capture.
		var sectionMode = SceneStreamFormat.cPrefabWireReferenced;
		SerializeValue(ar, "prefabMode", ref sectionMode);
		uint32 nestedCount = 0;
		ar.Key("prefabInstances");
		ar.BeginArray(ref nestedCount);
		ar.EndArray();

		return ar.IsPayloadOk ? .Ok : .Err(.Unknown);
	}
}
