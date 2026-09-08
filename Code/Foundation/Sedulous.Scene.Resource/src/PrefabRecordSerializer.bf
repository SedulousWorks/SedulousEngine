using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace Sedulous.Scene.Resource;

/// The wire form of one prefab instance: which prefab, where it sits, its member map, and
/// what it overrides.
///
/// A component override travels as its component's own fields in TEXT, so a person reading
/// a diff sees what changed rather than a wall of hex, and as a blob in BINARY. The text
/// form needs the manager to decode, so an override of a type this build does not have is
/// dropped there and survives in binary.
static class PrefabRecordSerializer
{
	/// A count larger than this is a misparse, not a record.
	///
	/// A serializer offers no error state to poll mid read, so a garbage count would
	/// otherwise be believed and allocated: that is how a corrupt scene turns into a hang
	/// rather than a message.
	private const uint32 cMaxEntries = 1 << 20;

	public static void Write(ISerializer ar, Scene scene, PendingPrefabInstance record, bool text)
	{
		WriteHeaderFields(ar, record);
		WriteMembers(ar, record);
		WriteDestroyed(ar, record);
		WriteTransformOverrides(ar, record);
		WriteComponentOps(ar, scene, record, text);
	}

	public static void Read(ISerializer ar, Scene scene, PendingPrefabInstance record, bool text)
	{
		ReadHeaderFields(ar, record);
		if (!ReadMembers(ar, record))
			return;
		if (!ReadDestroyed(ar, record))
			return;
		if (!ReadTransformOverrides(ar, record))
			return;
		ReadComponentOps(ar, scene, record, text);
	}

	// ---- header ----

	private static void WriteHeaderFields(ISerializer ar, PendingPrefabInstance record)
	{
		var prefabId = record.PrefabId;
		var parentId = record.ParentEntityId;
		var rootTransform = record.RootTransform;
		var rootLiveId = record.RootLiveId;
		var ownerRootId = record.OwnerRootEntityId;
		var nestedRootSourceId = record.NestedRootSourceId;
		var nextSiblingId = record.NextSiblingId;
		var placement = record.ApplyPlacement ? (uint8)1 : (uint8)0;

		SerializeValue(ar, "prefab", ref prefabId);
		SerializeValue(ar, "parent", ref parentId);
		SceneStreamFormat.SerializeTransform(ar, ref rootTransform);
		SerializeValue(ar, "rootLive", ref rootLiveId);
		SerializeValue(ar, "owner", ref ownerRootId);
		SerializeValue(ar, "nestedSrcRoot", ref nestedRootSourceId);
		SerializeValue(ar, "nextSibling", ref nextSiblingId);
		SerializeValue(ar, "placement", ref placement);
	}

	private static void ReadHeaderFields(ISerializer ar, PendingPrefabInstance record)
	{
		uint8 placement = 1;
		SerializeValue(ar, "prefab", ref record.PrefabId);
		SerializeValue(ar, "parent", ref record.ParentEntityId);
		SceneStreamFormat.SerializeTransform(ar, ref record.RootTransform);
		SerializeValue(ar, "rootLive", ref record.RootLiveId);
		SerializeValue(ar, "owner", ref record.OwnerRootEntityId);
		SerializeValue(ar, "nestedSrcRoot", ref record.NestedRootSourceId);
		SerializeValue(ar, "nextSibling", ref record.NextSiblingId);
		SerializeValue(ar, "placement", ref placement);
		record.ApplyPlacement = placement != 0;
	}

	// ---- the member map ----

	private static void WriteMembers(ISerializer ar, PendingPrefabInstance record)
	{
		uint32 count = (uint32)record.SourceIds.Count;
		ar.Key("members");
		ar.BeginArray(ref count);
		for (int i = 0; i < record.SourceIds.Count; i++)
		{
			var source = record.SourceIds[i];
			var live = record.LiveIds[i];
			SerializeValue(ar, "src", ref source);
			SerializeValue(ar, "live", ref live);
		}
		ar.EndArray();
	}

	private static bool ReadMembers(ISerializer ar, PendingPrefabInstance record)
	{
		uint32 count = 0;
		ar.Key("members");
		ar.BeginArray(ref count);
		if (!Plausible(count, ar))
		{
			ar.EndArray();
			return false;
		}
		for (uint32 i < count)
		{
			Guid source = .();
			Guid live = .();
			SerializeValue(ar, "src", ref source);
			SerializeValue(ar, "live", ref live);
			record.SourceIds.Add(source);
			record.LiveIds.Add(live);
		}
		ar.EndArray();
		return true;
	}

	// ---- members the user deleted out of the instance ----

	private static void WriteDestroyed(ISerializer ar, PendingPrefabInstance record)
	{
		uint32 count = (uint32)record.DestroyedMembers.Count;
		ar.Key("destroyed");
		ar.BeginArray(ref count);
		for (int i = 0; i < record.DestroyedMembers.Count; i++)
		{
			var dead = record.DestroyedMembers[i];
			SerializeValue(ar, "src", ref dead);
		}
		ar.EndArray();
	}

	private static bool ReadDestroyed(ISerializer ar, PendingPrefabInstance record)
	{
		uint32 count = 0;
		ar.Key("destroyed");
		ar.BeginArray(ref count);
		if (!Plausible(count, ar))
		{
			ar.EndArray();
			return false;
		}
		for (uint32 i < count)
		{
			Guid dead = .();
			SerializeValue(ar, "src", ref dead);
			record.DestroyedMembers.Add(dead);
		}
		ar.EndArray();
		return true;
	}

	// ---- moved members ----

	private static void WriteTransformOverrides(ISerializer ar, PendingPrefabInstance record)
	{
		uint32 count = (uint32)record.OverrideTransformIds.Count;
		ar.Key("transformOverrides");
		ar.BeginArray(ref count);
		for (int i = 0; i < record.OverrideTransformIds.Count; i++)
		{
			var source = record.OverrideTransformIds[i];
			var transform = record.OverrideTransforms[i];
			SerializeValue(ar, "src", ref source);
			SceneStreamFormat.SerializeTransform(ar, ref transform);
		}
		ar.EndArray();
	}

	private static bool ReadTransformOverrides(ISerializer ar, PendingPrefabInstance record)
	{
		uint32 count = 0;
		ar.Key("transformOverrides");
		ar.BeginArray(ref count);
		if (!Plausible(count, ar))
		{
			ar.EndArray();
			return false;
		}
		for (uint32 i < count)
		{
			Guid source = .();
			Transform transform = .();
			SerializeValue(ar, "src", ref source);
			SceneStreamFormat.SerializeTransform(ar, ref transform);
			record.OverrideTransformIds.Add(source);
			record.OverrideTransforms.Add(transform);
		}
		ar.EndArray();
		return true;
	}

	// ---- component overrides ----

	private static void WriteComponentOps(ISerializer ar, Scene scene,
		PendingPrefabInstance record, bool text)
	{
		uint32 count = (uint32)record.ComponentOps.Count;
		ar.Key("componentOps");
		ar.BeginArray(ref count);

		// One scratch entity for the whole section: the text form decodes a blob into a
		// real component to write its FIELDS, and needs somewhere to put it.
		var scratch = EntityHandle.Invalid;
		defer
		{
			if (scratch.IsAssigned)
				scene.DestroyEntity(scratch);
		}

		for (let op in record.ComponentOps)
		{
			var source = op.SourceEntity;
			var kind = (uint8)op.Op;

			if (!text)
			{
				SerializeValue(ar, "src", ref source);
				Sedulous.Core.Serialization.Serialize(ar, "type", op.TypeId);
				SerializeValue(ar, "op", ref kind);
				SceneSerializer.[Friend]SerializeBlob(ar, "blob", op.Blob);
				continue;
			}

			ar.BeginObject();
			SerializeValue(ar, "src", ref source);
			Sedulous.Core.Serialization.Serialize(ar, "type", op.TypeId);
			SerializeValue(ar, "op", ref kind);

			// A remove carries no payload: there is nothing left to describe.
			if (op.Op != .Remove)
			{
				let manager = scene.FindManagerBySerializationId(op.TypeId);
				// Form one is the component's own fields, which only a manager can write.
				// Form zero is the raw blob, so an override of an absent type still
				// survives a transcode.
				var form = (manager != null) ? (uint8)1 : (uint8)0;
				SerializeValue(ar, "form", ref form);

				if (manager != null)
				{
					if (!scratch.IsAssigned)
						scratch = scene.CreateEntity("__op_write");
					SceneStreamFormat.ComponentFromBlob(manager, scratch, op.Blob);
					ar.Key("data");
					ar.BeginObject();
					manager.WriteComponent(ar, scratch);
					ar.EndObject();
					manager.RemoveComponent(scratch);
				}
				else
				{
					SceneSerializer.[Friend]SerializeBlob(ar, "blob", op.Blob);
				}
			}
			ar.EndObject();
		}
		ar.EndArray();
	}

	private static void ReadComponentOps(ISerializer ar, Scene scene,
		PendingPrefabInstance record, bool text)
	{
		uint32 count = 0;
		ar.Key("componentOps");
		ar.BeginArray(ref count);
		if (!Plausible(count, ar))
		{
			ar.EndArray();
			return;
		}

		var scratch = EntityHandle.Invalid;
		defer
		{
			if (scratch.IsAssigned)
				scene.DestroyEntity(scratch);
		}

		for (uint32 i < count)
		{
			let op = new PendingPrefabComponentOp();
			var source = Guid();
			uint8 kind = 0;

			if (!text)
			{
				SerializeValue(ar, "src", ref source);
				Sedulous.Core.Serialization.Serialize(ar, "type", op.TypeId);
				SerializeValue(ar, "op", ref kind);
				SceneSerializer.[Friend]SerializeBlob(ar, "blob", op.Blob);
				op.SourceEntity = source;
				op.Op = (PendingPrefabComponentOp.Kind)kind;
				record.ComponentOps.Add(op);
				continue;
			}

			ar.BeginObject();
			SerializeValue(ar, "src", ref source);
			Sedulous.Core.Serialization.Serialize(ar, "type", op.TypeId);
			SerializeValue(ar, "op", ref kind);
			op.SourceEntity = source;
			op.Op = (PendingPrefabComponentOp.Kind)kind;

			var keep = true;
			if (op.Op != .Remove)
			{
				uint8 form = 0;
				SerializeValue(ar, "form", ref form);

				if (form == 1)
				{
					let manager = scene.FindManagerBySerializationId(op.TypeId);
					if (manager != null)
					{
						if (!scratch.IsAssigned)
							scratch = scene.CreateEntity("__op_read");
						ar.Key("data");
						ar.BeginObject();
						manager.ReadComponent(ar, scratch);
						ar.EndObject();
						SceneStreamFormat.ComponentToBlob(manager, scratch, op.Blob);
						manager.RemoveComponent(scratch);
					}
					else
					{
						// Inline fields need the manager to decode them, so an unknown type
						// cannot be preserved here the way a blob record can.
						GlobalLog(.Warning,
							"PrefabRecordSerializer: dropping an override of unknown component type '{}'",
							op.TypeId);
						keep = false;
					}
				}
				else
				{
					SceneSerializer.[Friend]SerializeBlob(ar, "blob", op.Blob);
				}
			}
			ar.EndObject();

			if (keep)
				record.ComponentOps.Add(op);
			else
				delete op;
		}
		ar.EndArray();
	}

	private static bool Plausible(uint32 count, ISerializer ar)
	{
		if (count <= cMaxEntries)
			return true;
		GlobalLog(.Error,
			"PrefabRecordSerializer: a record claims {} entries, which is a misparse rather than a record",
			count);
		ar.FailPayload(.OutOfRange);
		return false;
	}
}
