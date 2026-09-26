using System;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// The generic twin of SetResourceRefCommand: points a component's reference-shaped field (a
/// Ref<T>, whatever T) at another asset through ReferenceShape, so no T is named - what an
/// agent's component_set uses. The identity is set, then rebound through the manager, or with
/// no manager the stale binding dropped so the next resolve binds it. Undo restores the old
/// identity the same way. Not merged.
class SetReferenceCommand : EditorCommand
{
	private SceneEditContext mCtx;
	private Guid mEntity;
	private Type mType;
	private String mProperty = new .() ~ delete _;
	private Guid mNew;
	private Guid mOld = .();
	private bool mHasOld = false;
	private ResourceManager mResources;

	public this(SceneEditContext ctx, Guid entity, Type componentType, StringView property,
		Guid value, ResourceManager resources)
	{
		mCtx = ctx;
		mEntity = entity;
		mType = componentType;
		mProperty.Set(property);
		mNew = value;
		mResources = resources;
	}

	public override bool Execute()
	{
		Type fieldType = ?;
		let address = ResolveAddress(out fieldType);
		if (address == null)
			return false;
		if (!mHasOld)
		{
			if (!(ReferenceShape.Id(fieldType, address) case .Ok(let old)))
				return false;
			mOld = old;
			mHasOld = true;
		}
		return ReferenceShape.Assign(fieldType, address, mNew, mResources) case .Ok;
	}

	public override void Undo()
	{
		Type fieldType = ?;
		let address = ResolveAddress(out fieldType);
		if (address != null)
			ReferenceShape.Assign(fieldType, address, mOld, mResources).IgnoreError();
	}

	public override StringView TypeId => "set_reference";

	/// The pool moves as components come and go, so the address re-derives on every apply;
	/// the field must be reference shaped.
	private void* ResolveAddress(out Type outFieldType)
	{
		outFieldType = null;
		let e = mCtx.Resolve(mEntity);
		let mgr = mCtx.FindManager(mType);
		if (!e.IsAssigned || (mgr == null))
			return null;
		let component = mgr.GetComponentAddress(e);
		if (component == null)
			return null;
		if (!(RawFieldAccess.FindField(mType, mProperty) case .Ok(let field)))
			return null;
		if (!ReferenceShape.Is(field.FieldType))
			return null;
		outFieldType = field.FieldType;
		return RawFieldAccess.AddressOf(field, component);
	}
}
