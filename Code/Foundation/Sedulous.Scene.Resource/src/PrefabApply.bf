using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
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
	/// `resolver` reaches the templates of the prefabs this instance CONTAINS. Their
	/// records are diffed against those pure templates rather than against baselines that
	/// already have this owner's customisation folded in; without a resolver the diff
	/// degrades to the baseline one and that customisation is lost, which is said out loud
	/// rather than quietly.
	public static Result<void, ErrorCode> CaptureAsTemplate(Scene scene,
		PrefabInstanceState state, IStream output, ScenePrefabs.PayloadResolver resolver = null,
		SceneStreamEncoding encoding = .Text)
	{
		if (encoding == .Binary)
		{
			let ar = scope BinarySerializer(output, .Write);
			return WriteBody(ar, scene, state, false, resolver);
		}

		let ar = scope XmlSerializer();
		if (WriteBody(ar, scene, state, true, resolver) case .Err(let error))
			return .Err(error);

		let text = scope String();
		ar.GetOutput(text);
		return (output.Write(.((uint8*)text.Ptr, text.Length)) == text.Length)
			? .Ok : .Err(.Unknown);
	}

	private static Result<void, ErrorCode> WriteBody(ISerializer ar, Scene scene,
		PrefabInstanceState state, bool text, ScenePrefabs.PayloadResolver resolver)
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

		// An instance inside the subtree becomes a nested RECORD rather than plain entities:
		// an owner-linked one keeps its stable identity, and one somebody spawned inside is
		// absorbed as a new record.
		let contained = scope List<PrefabInstanceState>();
		let nestedMembers = scope HashSet<Guid>();
		PrefabNesting.CollectContained(scene, root, contained, nestedMembers);

		let all = scope List<EntityHandle>();
		SceneStreamFormat.CollectSubtree(scene, root, all);
		let handles = scope List<EntityHandle>();
		for (let entity in all)
		{
			if (!nestedMembers.Contains(scene.GetEntityId(entity)))
				handles.Add(entity);
		}

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

		var sectionMode = SceneStreamFormat.cPrefabWireReferenced;
		SerializeValue(ar, "prefabMode", ref sectionMode);

		let records = scope List<PendingPrefabInstance>();
		defer { ClearAndDeleteItems!(records); }
		for (let nested in contained)
			records.Add(BuildNestedRecord(scene, nested, resolver, scope (live) => Substituted(live)));

		uint32 nestedCount = (uint32)records.Count;
		ar.Key("prefabInstances");
		ar.BeginArray(ref nestedCount);
		for (let record in records)
			PrefabRecordSerializer.Write(ar, scene, record, text);
		ar.EndArray();

		return ar.IsPayloadOk ? .Ok : .Err(.Unknown);
	}

	/// One contained instance as a record in the template being written.
	///
	/// Diffed against the child's OWN template when the resolver can reach it. The
	/// instance's baselines cannot serve: they already have this owner's customisation
	/// folded in, so diffing against them would report that customisation as nothing and
	/// drop it out of the template being written.
	private static PendingPrefabInstance BuildNestedRecord(Scene scene,
		PrefabInstanceState nested, ScenePrefabs.PayloadResolver resolver,
		delegate Guid(Guid) substituted)
	{
		PendingPrefabInstance record;
		let childTemplate = (resolver != null) ? resolver(nested.PrefabId) : null;
		if (childTemplate != null)
		{
			defer:: delete childTemplate;
			record = PrefabTemplateDiff.ComputeVsTemplate(scene, nested, childTemplate);
		}
		else
		{
			GlobalLog(.Warning,
				"PrefabApply: a nested template did not resolve, so this owner's customisation of it may be lost");
			record = PrefabDeltas.Compute(scene, nested);
		}

		// Its identity in the template being written is the one it already answers to in
		// its owner's namespace, so a scene record still matches it after the apply.
		if (nested.NestedRootSourceId != Guid())
			record.RootLiveId = nested.NestedRootSourceId;

		record.ParentEntityId = substituted(record.ParentEntityId);
		record.NextSiblingId = substituted(record.NextSiblingId);
		// The links belong to the live scene, not to a template.
		record.OwnerRootEntityId = Guid();
		record.NestedRootSourceId = Guid();
		return record;
	}
}
