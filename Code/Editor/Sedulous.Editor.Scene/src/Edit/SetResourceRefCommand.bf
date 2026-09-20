using System;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Points a component's Ref<T> field at another resource and rebinds it through the
/// manager, so the swap shows this frame.
class SetResourceRefCommand<T> : EditorCommand where T : class
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
		let reference = ResolveRef();
		if (reference == null)
			return false;
		if (!mHasOld)
		{
			mOld = reference.Id;
			mHasOld = true;
		}
		reference.SetId(mNew);
		reference.Rebind(mResources);
		return true;
	}

	public override void Undo()
	{
		let reference = ResolveRef();
		if (reference == null)
			return;
		reference.SetId(mOld);
		reference.Rebind(mResources);
	}

	public override StringView TypeId => "set_resource_ref";

	private Ref<T>* ResolveRef()
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
		if (field.FieldType != typeof(Ref<T>))
			return null;
		return (Ref<T>*)RawFieldAccess.AddressOf(field, component);
	}
}
