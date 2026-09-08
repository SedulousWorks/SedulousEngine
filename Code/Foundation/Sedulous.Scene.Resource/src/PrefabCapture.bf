using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Xml.Serialization;

namespace Sedulous.Scene.Resource;

/// Capturing an entity subtree as a prefab PAYLOAD.
///
/// Written with the subtree's OWN guids. Those become the stable source ids every
/// instance's deltas are keyed on, which is why a template's entities must keep their
/// identity: rewriting them would orphan the overrides on every instance already placed.
///
/// The stream is deliberately the same shape a scene has, so the thing that loads a scene
/// loads a prefab unchanged and a prefab can be opened for editing like any other.
static class PrefabCapture
{
	/// Captures `root`'s subtree. A source captures as TEXT; binary stays available for an
	/// in memory payload, and spawning sniffs, so either reads back.
	public static Result<void, ErrorCode> Capture(Scene scene, EntityHandle root, IStream output,
		SceneStreamEncoding encoding = .Text)
	{
		if (!root.IsAssigned)
			return .Err(.NotFound);

		if (encoding == .Binary)
		{
			let ar = scope BinarySerializer(output, .Write);
			return WriteBody(ar, scene, root, false);
		}

		let ar = scope XmlSerializer();
		if (WriteBody(ar, scene, root, true) case .Err(let error))
			return .Err(error);

		let text = scope String();
		ar.GetOutput(text);
		return (output.Write(.((uint8*)text.Ptr, text.Length)) == text.Length)
			? .Ok : .Err(.Unknown);
	}

	private static Result<void, ErrorCode> WriteBody(ISerializer ar, Scene scene, EntityHandle root,
		bool text)
	{
		SceneStreamFormat.WriteHeader(ar);

		let name = scope String(scene.GetEntityName(root));
		Sedulous.Core.Serialization.Serialize(ar, "name", name);

		// An instance INSIDE the subtree persists as a record, not as its entities: it is
		// still an instance, and flattening it would quietly turn it into a copy that an
		// edit to its own prefab would never reach again.
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
			var id = scene.GetEntityId(entity);
			let entityName = scope:: String(scene.GetEntityName(entity));
			var active = scene.IsActive(entity) ? (uint8)1 : (uint8)0;
			// The subtree's ROOT records a nil parent: spawning re-parents it wherever it
			// is being placed, and a captured parent would name an entity outside the
			// template.
			var parentId = (entity == root) ? Guid() : scene.GetEntityId(scene.GetParent(entity));
			var transform = scene.GetLocalTransform(entity);

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
			SceneSerializer.[Friend]WriteComponentRecord(ar, scene, managers[i], owners[i], text);
		ar.EndArray();

		// An EMPTY settings section, so the stream stays loadable as a scene while carrying
		// nobody's settings into whatever it is spawned in: a prefab is a subtree template,
		// not a world.
		uint32 settingsCount = 0;
		ar.Key("systemSettings");
		ar.BeginArray(ref settingsCount);
		ar.EndArray();

		// The contained instances, as records.
		var sectionMode = SceneStreamFormat.cPrefabWireReferenced;
		SerializeValue(ar, "prefabMode", ref sectionMode);

		let records = scope List<PendingPrefabInstance>();
		defer { ClearAndDeleteItems!(records); }
		for (let nested in contained)
			records.Add(BuildNestedRecord(scene, nested));

		uint32 nestedCount = (uint32)records.Count;
		ar.Key("prefabInstances");
		ar.BeginArray(ref nestedCount);
		for (let record in records)
			PrefabRecordSerializer.Write(ar, scene, record, text);
		ar.EndArray();

		return ar.IsPayloadOk ? .Ok : .Err(.Unknown);
	}

	/// One contained instance as a record in the OWNER's namespace.
	///
	/// Its identity here is the root's live guid, which is what a scene record matches
	/// against when the owner is spawned again. The deltas are the ordinary live versus
	/// baseline ones: what the person editing this prefab changed about the inner one.
	private static PendingPrefabInstance BuildNestedRecord(Scene scene, PrefabInstanceState nested)
	{
		let record = PrefabDeltas.Compute(scene, nested);
		record.RootLiveId = nested.RootEntityId;
		record.NestedRootSourceId = (nested.NestedRootSourceId != Guid())
			? nested.NestedRootSourceId : nested.RootEntityId;

		let root = scene.FindEntity(nested.RootEntityId);
		if (root.IsAssigned)
		{
			let parent = scene.GetParent(root);
			record.ParentEntityId = parent.IsAssigned ? scene.GetEntityId(parent) : Guid();
			let sibling = scene.GetNextSibling(root);
			record.NextSiblingId = sibling.IsAssigned ? scene.GetEntityId(sibling) : Guid();
			// A nested record's placement IS template content: where the outer prefab puts
			// the inner one is part of what the outer prefab says.
			record.RootTransform = scene.GetLocalTransform(root);
			record.ApplyPlacement = true;
		}
		return record;
	}
}
