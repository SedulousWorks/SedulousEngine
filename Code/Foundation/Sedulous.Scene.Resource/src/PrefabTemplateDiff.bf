using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace Sedulous.Scene.Resource;

/// Diffing a nested instance against the PURE template of the prefab it is an instance of.
///
/// Apply-to-prefab needs this and the ordinary baseline diff will not do. A nested
/// instance's baselines already have the OWNER's customisation folded into them, on
/// purpose: that is what makes an owner edit propagate rather than pin. But when the owner
/// is being written back as a template, that customisation is exactly what has to end up
/// in the record, and a baseline diff would report it as nothing at all and lose it.
///
/// So the baselines come from the child's own template payload instead: what the inner
/// prefab says, against what this instance actually is.
static class PrefabTemplateDiff
{
	/// The record for `state`, keyed against `templatePayload` rather than its baselines.
	///
	/// Falls back to the ordinary baseline diff when the template cannot be read: losing
	/// the owner's customisation is bad, and losing the record entirely is worse.
	public static PendingPrefabInstance ComputeVsTemplate(Scene scene, PrefabInstanceState state,
		IStream templatePayload)
	{
		let reader = scope SceneStreamReader();
		if (!(reader.Open(templatePayload) case .Ok(let ar)))
			return PrefabDeltas.Compute(scene, state);

		let text = reader.Encoding == .Text;
		if (SceneStreamFormat.ReadHeader(ar) case .Err)
		{
			GlobalLog(.Error,
				"PrefabTemplateDiff: the child template is not in the current format, falling back to the baseline diff. Re-save it.");
			return PrefabDeltas.Compute(scene, state);
		}

		let name = scope String();
		Sedulous.Core.Serialization.Serialize(ar, "name", name);

		let templateTransforms = scope Dictionary<Guid, Transform>();
		ReadTemplateEntities(ar, templateTransforms);

		let templateBlobs = scope List<(Guid source, String typeId, List<uint8> blob)>();
		defer
		{
			for (let entry in templateBlobs)
			{
				delete entry.typeId;
				delete entry.blob;
			}
		}
		ReadTemplateComponents(ar, scene, text, templateBlobs);

		if (!ar.IsPayloadOk)
			return PrefabDeltas.Compute(scene, state);

		return BuildRecord(scene, state, templateTransforms, templateBlobs);
	}

	private static void ReadTemplateEntities(ISerializer ar, Dictionary<Guid, Transform> outTransforms)
	{
		uint32 entityCount = 0;
		ar.Key("entities");
		ar.BeginArray(ref entityCount);
		for (uint32 i < entityCount)
		{
			Guid id = .();
			let entityName = scope:: String();
			uint8 active = 0;
			Guid parentId = .();
			Transform transform = .();

			SerializeValue(ar, "id", ref id);
			Sedulous.Core.Serialization.Serialize(ar, "name", entityName);
			SerializeValue(ar, "active", ref active);
			SerializeValue(ar, "parent", ref parentId);
			SceneStreamFormat.SerializeTransform(ar, ref transform);

			outTransforms[id] = transform;
		}
		ar.EndArray();
	}

	/// The template's components as blobs, so they compare against a live component the same
	/// way a baseline does.
	///
	/// A TEXT template stores fields rather than bytes, so reading one needs a manager to
	/// decode into a scratch entity and re-blob. A type with no manager is simply skipped:
	/// nothing here can say whether it changed.
	private static void ReadTemplateComponents(ISerializer ar, Scene scene, bool text,
		List<(Guid source, String typeId, List<uint8> blob)> outBlobs)
	{
		uint32 componentCount = 0;
		ar.Key("components");
		ar.BeginArray(ref componentCount);

		var scratch = EntityHandle.Invalid;
		defer
		{
			if (scratch.IsAssigned)
				scene.DestroyEntity(scratch);
		}

		for (uint32 i = 0; (i < componentCount) && ar.IsPayloadOk; i++)
		{
			Guid source = .();
			let typeId = new String();
			let blob = new List<uint8>();

			if (text)
			{
				ar.BeginObject();
				SerializeValue(ar, "owner", ref source);
				Sedulous.Core.Serialization.Serialize(ar, "type", typeId);

				let manager = scene.FindManagerBySerializationId(typeId);
				if (manager != null)
				{
					if (!scratch.IsAssigned)
						scratch = scene.CreateEntity("__template_read");
					ar.Key("data");
					ar.BeginObject();
					manager.ReadComponent(ar, scratch);
					ar.EndObject();
					SceneStreamFormat.ComponentToBlob(manager, scratch, blob);
					manager.RemoveComponent(scratch);
					outBlobs.Add((source, typeId, blob));
				}
				else
				{
					delete typeId;
					delete blob;
				}
				ar.EndObject();
				continue;
			}

			SerializeValue(ar, "owner", ref source);
			Sedulous.Core.Serialization.Serialize(ar, "type", typeId);
			SceneSerializer.[Friend]SerializeBlob(ar, "data", blob);
			outBlobs.Add((source, typeId, blob));
		}
		ar.EndArray();
	}

	private static PendingPrefabInstance BuildRecord(Scene scene, PrefabInstanceState state,
		Dictionary<Guid, Transform> templateTransforms,
		List<(Guid source, String typeId, List<uint8> blob)> templateBlobs)
	{
		let record = new PendingPrefabInstance();
		record.PrefabId = state.PrefabId;
		record.SourceIds.AddRange(state.SourceIds);
		record.LiveIds.AddRange(state.LiveIds);
		record.RootLiveId = state.RootEntityId;

		let liveRoot = scene.FindEntity(state.RootEntityId);
		if (liveRoot.IsAssigned)
		{
			let parent = scene.GetParent(liveRoot);
			record.ParentEntityId = parent.IsAssigned ? scene.GetEntityId(parent) : Guid();
			record.RootTransform = scene.GetLocalTransform(liveRoot);
			let sibling = scene.GetNextSibling(liveRoot);
			record.NextSiblingId = sibling.IsAssigned ? scene.GetEntityId(sibling) : Guid();
		}

		// The placement counts only when it differs from what the child TEMPLATE says.
		for (int i = 0; i < state.LiveIds.Count; i++)
		{
			if (state.LiveIds[i] != state.RootEntityId)
				continue;
			if (liveRoot.IsAssigned && templateTransforms.TryGetValue(state.SourceIds[i], let templateRoot))
				record.ApplyPlacement = !PrefabDeltas.TransformsEqual(record.RootTransform, templateRoot);
			break;
		}

		for (int i = 0; i < state.SourceIds.Count; i++)
		{
			let sourceId = state.SourceIds[i];
			let live = scene.FindEntity(state.LiveIds[i]);
			if (!live.IsAssigned)
			{
				record.DestroyedMembers.Add(sourceId);
				continue;
			}

			if (state.LiveIds[i] != state.RootEntityId)
			{
				let transform = scene.GetLocalTransform(live);
				// A member the template does not mention at all counts as moved: it is not
				// where the template put it, because the template does not put it anywhere.
				if (!templateTransforms.TryGetValue(sourceId, let templateTransform)
					|| !PrefabDeltas.TransformsEqual(transform, templateTransform))
				{
					record.OverrideTransformIds.Add(sourceId);
					record.OverrideTransforms.Add(transform);
				}
			}

			CollectOps(scene, sourceId, live, templateBlobs, record);
		}

		for (let op in state.UnresolvedComponentOps)
			record.ComponentOps.Add(PrefabDeltas.CopyOp(op));

		return record;
	}

	private static void CollectOps(Scene scene, Guid sourceId, EntityHandle live,
		List<(Guid source, String typeId, List<uint8> blob)> templateBlobs,
		PendingPrefabInstance record)
	{
		scene.ForEachManager(scope (manager) =>
		{
			if (!manager.IsSerializable)
				return;

			List<uint8> templateBlob = null;
			for (let entry in templateBlobs)
			{
				if ((entry.source == sourceId) && (entry.typeId == manager.SerializationTypeId))
				{
					templateBlob = entry.blob;
					break;
				}
			}

			let op = new PendingPrefabComponentOp();
			op.SourceEntity = sourceId;
			op.TypeId.Set(manager.SerializationTypeId);

			if (manager.HasComponent(live))
			{
				let current = scope List<uint8>();
				SceneStreamFormat.ComponentToBlob(manager, live, current);

				if (templateBlob == null)
				{
					op.Op = .Add;
					op.Blob.AddRange(current);
				}
				else if (!SceneStreamFormat.BlobsEqual(current, templateBlob))
				{
					op.Op = .Modify;
					op.Blob.AddRange(current);
				}
				else
				{
					delete op;
					return;
				}
			}
			else if (templateBlob != null)
			{
				op.Op = .Remove;
			}
			else
			{
				delete op;
				return;
			}

			record.ComponentOps.Add(op);
		});
	}
}
