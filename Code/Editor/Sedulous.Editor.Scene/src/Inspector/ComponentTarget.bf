using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Editor.Scene;

/// A component on an entity, both named so the target survives the pool moving.
class ComponentTarget : InspectorTarget
{
	public readonly Guid Id;
	public readonly Type Type;

	public this(SceneEditContext edit, Guid id, Type type) : base(edit)
	{
		Id = id;
		Type = type;
	}

	public override Type TargetType => Type;

	public override void* Address
	{
		get
		{
			let mgr = mEdit.FindManager(Type);
			let e = mEdit.Resolve(Id);
			if ((mgr == null) || !e.IsAssigned)
				return null;
			return mgr.GetComponentAddress(e);
		}
	}

	public override void SetProperty(StringView field, Variant value)
		=> mEdit.SetComponentProperty(Id, Type, field, value);

	public override void SetPropertyRaw(StringView field, int64 raw)
		=> mEdit.SetComponentPropertyRaw(Id, Type, field, raw);

	public override void SetEntityRef(StringView field, Guid target)
		=> mEdit.SetComponentEntityRef(Id, Type, field, target);

	/// Only a serializable component can be snapshotted; anything else is left alone.
	public override void Mutate(delegate void(void* instance) mutate, StringView mergeKey)
	{
		let e = mEdit.Resolve(Id);
		let mgr = mEdit.FindManager(Type);
		if ((mgr == null) || !e.IsAssigned || !mgr.HasComponent(e))
			return;
		let before = scope List<uint8>();
		mEdit.CopyComponent(Id, Type, before); // snapshot A, the current state
		if (before.IsEmpty)
			return;
		let live = mgr.GetComponentAddress(e);
		if (live == null)
			return;
		mutate(live); // live is now B
		let after = scope List<uint8>();
		mEdit.CopyComponent(Id, Type, after); // snapshot B
		RestoreBlob(mgr, e, before); // back to A, so the paste below is the one undoable step
		if (!after.IsEmpty)
			mEdit.PasteComponent(Id, after, mergeKey);
	}

	/// Reads a copied component blob (its manager id, then the component) straight back in.
	private static void RestoreBlob(ComponentManagerBase mgr, EntityHandle e, List<uint8> blob)
	{
		let buffer = scope MemoryStream();
		buffer.Write(blob);
		buffer.Seek(0, .Begin);
		let ar = scope BinarySerializer(buffer, .Read);
		let typeId = scope String();
		Sedulous.Core.Serialization.Serialize(ar, "type", typeId);
		mgr.ReadComponent(ar, e);
	}
}
