using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Editor.Scene;

/// Capturing an entity subtree as records, and the clipboard encoding of those records.
static class SubtreeRecords
{
	/// Captures `root` and its descendants, parents first, with every serializable component.
	///
	/// `rootParentNil` nils the root's parent, the clipboard shape, where a paste supplies the
	/// parent; false keeps the actual parent, the destroy shape, where undo puts the subtree
	/// back where it was.
	public static void Capture(Sedulous.Scene.Scene scene, EntityHandle root,
		List<SubtreeRecord> outRecords, bool rootParentNil)
	{
		Visit(scene, root, outRecords, rootParentNil);
	}

	private static void Visit(Sedulous.Scene.Scene scene, EntityHandle e,
		List<SubtreeRecord> outRecords, bool rootParentNil)
	{
		let record = new SubtreeRecord();
		record.Id = scene.GetEntityId(e);
		let parent = scene.GetEntityId(scene.GetParent(e));
		record.Parent = (rootParentNil && outRecords.IsEmpty) ? Guid() : parent;
		record.Name.Set(scene.GetEntityName(e));
		record.Local = scene.GetLocalTransform(e);
		record.Active = scene.IsActive(e);
		scene.ForEachManager(scope [&](mgr) =>
		{
			if (!mgr.IsSerializable || !mgr.HasComponent(e))
				return;
			let component = new SubtreeComponentRecord();
			component.TypeId.Set(mgr.SerializationTypeId);
			SceneStreamFormat.ComponentToBlob(mgr, e, component.Blob);
			record.Components.Add(component);
		});
		outRecords.Add(record);

		for (var c = scene.GetFirstChild(e); c.IsAssigned; c = scene.GetNextSibling(c))
			Visit(scene, c, outRecords, rootParentNil);
	}

	/// Restores one record's components onto a live entity, skipping any whose manager this
	/// scene does not have.
	public static void ApplyComponents(Sedulous.Scene.Scene scene, EntityHandle e,
		SubtreeRecord record)
	{
		for (let component in record.Components)
		{
			let mgr = scene.FindManagerBySerializationId(component.TypeId);
			if (mgr == null)
				continue;
			SceneStreamFormat.ComponentFromBlob(mgr, e, component.Blob);
		}
	}

	/// The clipboard encoding: a count, then each record in order.
	public static void Write(List<SubtreeRecord> records, List<uint8> outBlob)
	{
		let stream = scope MemoryStream();
		let ar = scope BinarySerializer(stream, .Write);
		uint32 count = (uint32)records.Count;
		SerializeValue(ar, "count", ref count);
		for (let r in records)
		{
			SerializeValue(ar, "id", ref r.Id);
			SerializeValue(ar, "parent", ref r.Parent);
			Sedulous.Core.Serialization.Serialize(ar, "name", r.Name);
			SerializeValue(ar, "position", ref r.Local.Position);
			SerializeValue(ar, "rotation", ref r.Local.Rotation);
			SerializeValue(ar, "scale", ref r.Local.Scale);
			SerializeValue(ar, "active", ref r.Active);
			uint32 componentCount = (uint32)r.Components.Count;
			SerializeValue(ar, "components", ref componentCount);
			for (let c in r.Components)
			{
				Sedulous.Core.Serialization.Serialize(ar, "type", c.TypeId);
				WriteBlob(ar, c.Blob);
			}
		}
		outBlob.Clear();
		if (ar.IsPayloadOk)
			outBlob.AddRange(stream.Bytes);
	}

	/// Parses a clipboard blob; an empty list for anything malformed. The caller owns the
	/// records.
	public static void Parse(Span<uint8> blob, List<SubtreeRecord> outRecords)
	{
		let stream = scope MemoryStream();
		stream.Write(blob);
		stream.Seek(0, .Begin);
		let ar = scope BinarySerializer(stream, .Read);
		uint32 count = 0;
		SerializeValue(ar, "count", ref count);
		for (uint32 i = 0; (i < count) && ar.IsPayloadOk; i++)
		{
			let r = new SubtreeRecord();
			outRecords.Add(r);
			SerializeValue(ar, "id", ref r.Id);
			SerializeValue(ar, "parent", ref r.Parent);
			Sedulous.Core.Serialization.Serialize(ar, "name", r.Name);
			SerializeValue(ar, "position", ref r.Local.Position);
			SerializeValue(ar, "rotation", ref r.Local.Rotation);
			SerializeValue(ar, "scale", ref r.Local.Scale);
			SerializeValue(ar, "active", ref r.Active);
			uint32 componentCount = 0;
			SerializeValue(ar, "components", ref componentCount);
			for (uint32 c = 0; (c < componentCount) && ar.IsPayloadOk; c++)
			{
				let component = new SubtreeComponentRecord();
				r.Components.Add(component);
				Sedulous.Core.Serialization.Serialize(ar, "type", component.TypeId);
				ReadBlob(ar, component.Blob);
			}
		}
		if (!ar.IsPayloadOk)
			ClearAndDeleteItems(outRecords);
	}

	private static void WriteBlob(ISerializer ar, List<uint8> bytes)
	{
		ar.Key("blob");
		uint32 count = (uint32)bytes.Count;
		ar.BeginArray(ref count);
		if (count > 0)
			ar.Blob(bytes.Ptr, (int)count);
		ar.EndArray();
	}

	private static void ReadBlob(ISerializer ar, List<uint8> bytes)
	{
		ar.Key("blob");
		uint32 count = 0;
		ar.BeginArray(ref count);
		bytes.Clear();
		bytes.Resize((int)count);
		if (count > 0)
			ar.Blob(bytes.Ptr, (int)count);
		ar.EndArray();
	}
}
