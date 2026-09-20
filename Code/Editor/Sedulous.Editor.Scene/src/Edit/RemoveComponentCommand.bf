using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Removes a component, keeping enough to bring it back exactly: its serialized bytes when
/// the manager has them, otherwise a snapshot of every reflected field.
class RemoveComponentCommand : EditorCommand
{
	private SceneEditContext mCtx;
	private Guid mEntity;
	private Type mType;
	private List<uint8> mBlob = new .() ~ delete _;
	private List<PropertySnapshot> mProperties = new .() ~ DeleteContainerAndItems!(_);

	public this(SceneEditContext ctx, Guid entity, Type componentType)
	{
		mCtx = ctx;
		mEntity = entity;
		mType = componentType;
	}

	public override bool Execute()
	{
		let e = mCtx.Resolve(mEntity);
		let mgr = mCtx.FindManager(mType);
		if (!e.IsAssigned || (mgr == null) || !mgr.HasComponent(e))
			return false;

		mBlob.Clear();
		ClearAndDeleteItems(mProperties);
		if (mgr.IsSerializable)
		{
			SceneStreamFormat.ComponentToBlob(mgr, e, mBlob);
		}
		else
		{
			let component = mgr.GetComponentAddress(e);
			for (let field in mType.GetFields())
			{
				// A reference or pointer field names storage the destroyed component owned;
				// restoring it would dangle. The default component gets fresh storage.
				if (field.IsStatic || field.FieldType.IsObject || field.FieldType.IsPointer)
					continue;
				if (!(RawFieldAccess.Read(field, component, mType) case .Ok(let value)))
					continue;
				let snap = new PropertySnapshot();
				snap.Name.Set(field.Name);
				snap.Value = value;
				mProperties.Add(snap);
			}
		}

		mgr.RemoveComponent(e);
		return true;
	}

	public override void Undo()
	{
		let e = mCtx.Resolve(mEntity);
		let mgr = mCtx.FindManager(mType);
		if (!e.IsAssigned || (mgr == null))
			return;
		if (mgr.IsSerializable && !mBlob.IsEmpty)
		{
			SceneStreamFormat.ComponentFromBlob(mgr, e, mBlob); // adds and fills
			// Re-bind the restored refs' proxies so the component renders this frame.
			mCtx.ResolveRestoredResources();
			return;
		}
		if (!mgr.AddDefaultComponent(e))
			return;
		let component = mgr.GetComponentAddress(e);
		for (let snap in mProperties)
		{
			if (RawFieldAccess.FindField(mType, snap.Name) case .Ok(let field))
				RawFieldAccess.Write(field, component, mType, snap.Value).IgnoreError();
		}
		mCtx.ResolveRestoredResources();
	}

	public override StringView TypeId => "remove_component";
}
