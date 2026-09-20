using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Editor.Scene;

/// The clipboard verbs: entities and components as byte blobs that survive a trip through
/// another scene, and the duplicate that is a copy-paste onto the same parent.
extension SceneEditContext
{
	/// A subtree as clipboard bytes; empty when the entity is gone.
	public void CopyEntity(Guid entity, List<uint8> outBlob)
	{
		outBlob.Clear();
		let root = Resolve(entity);
		if (!root.IsAssigned)
			return;
		let records = scope List<SubtreeRecord>();
		defer { ClearAndDeleteItems(records); }
		SubtreeRecords.Capture(mScene, root, records, true);
		SubtreeRecords.Write(records, outBlob);
	}

	/// Pastes a copied subtree under `parent` (nil for a root) with fresh guids, selecting
	/// and answering the new root; nil for a malformed blob.
	public Guid PasteEntities(Span<uint8> blob, Guid parent = .())
	{
		let records = new List<SubtreeRecord>();
		SubtreeRecords.Parse(blob, records);
		if (records.IsEmpty)
		{
			delete records;
			return .();
		}
		return RunPasteCommand(records, parent);
	}

	/// A copy pasted beside the original, named apart from it, as one undo step.
	public Guid DuplicateEntity(Guid entity)
	{
		let root = Resolve(entity);
		if (!root.IsAssigned)
			return .();
		let records = new List<SubtreeRecord>();
		SubtreeRecords.Capture(mScene, root, records, true);
		if (records.IsEmpty)
		{
			delete records;
			return .();
		}
		let parentHandle = mScene.GetParent(root);
		let parent = mScene.GetEntityId(parentHandle);
		let unique = scope String();
		UniqueSiblingName(records[0].Name, parentHandle, unique);
		records[0].Name.Set(unique);
		return RunPasteCommand(records, parent);
	}

	/// "Name (2)", "Name (3)", ... whichever is first free among `parent`'s children. A base
	/// that already carries a " (n)" suffix has it stripped first, so a copy of a copy is
	/// "Name (3)" rather than "Name (2) (2)".
	public void UniqueSiblingName(StringView baseName, EntityHandle parent, String outName)
	{
		var stem = baseName;
		if (!stem.IsEmpty && (stem[stem.Length - 1] == ')'))
		{
			var open = stem.Length;
			for (int i = stem.Length; i > 0; i--)
			{
				if (stem[i - 1] == '(')
				{
					open = i - 1;
					break;
				}
			}
			if ((open >= 2) && (stem[open - 1] == ' '))
				stem = stem.Substring(0, open - 1);
		}
		for (uint32 counter = 2;; counter++)
		{
			outName.Set(stem);
			outName.AppendF(" ({})", counter);
			var taken = false;
			mScene.ForEachEntity(scope [&](e) =>
			{
				if ((mScene.GetParent(e) == parent) && (mScene.GetEntityName(e) == outName))
					taken = true;
			});
			if (!taken)
				return;
		}
	}

	/// A component as clipboard bytes: its manager's id, then the component. Empty for an
	/// entity without one, or a manager that does not serialize.
	public void CopyComponent(Guid entity, Type componentType, List<uint8> outBlob)
	{
		outBlob.Clear();
		let e = Resolve(entity);
		let mgr = FindManager(componentType);
		if (!e.IsAssigned || (mgr == null) || !mgr.IsSerializable || !mgr.HasComponent(e))
			return;
		let buffer = scope MemoryStream();
		let ar = scope BinarySerializer(buffer, .Write);
		let typeId = scope String(mgr.SerializationTypeId);
		Sedulous.Core.Serialization.Serialize(ar, "type", typeId);
		mgr.WriteComponent(ar, e);
		if (ar.IsPayloadOk)
			outBlob.AddRange(buffer.Bytes);
	}

	/// The manager id a component blob was copied from, which is what a paste menu greys
	/// out against; empty for a malformed blob.
	public static void PeekComponentTypeId(Span<uint8> blob, String outTypeId)
	{
		outTypeId.Clear();
		let buffer = scope MemoryStream();
		buffer.Write(blob);
		buffer.Seek(0, .Begin);
		let ar = scope BinarySerializer(buffer, .Read);
		Sedulous.Core.Serialization.Serialize(ar, "type", outTypeId);
		if (!ar.IsPayloadOk)
			outTypeId.Clear();
	}

	/// Pastes a component blob onto an entity, adding or overwriting; false when the blob
	/// names a manager this scene lacks.
	public bool PasteComponent(Guid entity, Span<uint8> blob)
		=> mCommands.Execute(new PasteComponentCommand(this, entity, blob));

	/// CONSUMES `records`.
	private Guid RunPasteCommand(List<SubtreeRecord> records, Guid parent)
	{
		let command = new PasteEntitiesCommand(this, records, parent);
		if (!mCommands.Execute(command))
			return .();
		let created = command.RootGuid;
		mSelection.Set(created);
		return created;
	}
}
