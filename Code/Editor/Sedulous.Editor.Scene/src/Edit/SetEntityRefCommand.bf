using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Points a component's EntityRef field at another entity.
class SetEntityRefCommand : EditorCommand
{
	private SceneEditContext mCtx;
	private Guid mEntity;
	private Type mType;
	private String mProperty = new .() ~ delete _;
	private Guid mNew;
	private Guid mOld = .();
	private bool mHasOld = false;

	public this(SceneEditContext ctx, Guid entity, Type componentType, StringView property,
		Guid target)
	{
		mCtx = ctx;
		mEntity = entity;
		mType = componentType;
		mProperty.Set(property);
		mNew = target;
	}

	public override bool Execute()
	{
		let reference = ResolveRef();
		if (reference == null)
			return false;
		if (!mHasOld)
		{
			mOld = reference.Id;
			mHasOld = true;
		}
		reference.Id = mNew;
		return true;
	}

	public override void Undo()
	{
		let reference = ResolveRef();
		if (reference != null)
			reference.Id = mOld;
	}

	public override StringView TypeId => "set_entity_ref";

	private EntityRef* ResolveRef()
	{
		let e = mCtx.Resolve(mEntity);
		let mgr = mCtx.FindManager(mType);
		if (!e.IsAssigned || (mgr == null))
			return null;
		let component = mgr.GetComponentAddress(e);
		if (component == null)
			return null;
		if (!(RawFieldAccess.FindField(mType, mProperty) case .Ok(let field)))
			return null;
		if (field.FieldType != typeof(EntityRef))
			return null;
		return (EntityRef*)RawFieldAccess.AddressOf(field, component);
	}
}
