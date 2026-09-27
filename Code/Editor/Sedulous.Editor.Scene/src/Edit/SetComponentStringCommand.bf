using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Sets a component's String field IN PLACE, as the inspector's text row does: the string
/// object stays the component's own (its manager allocated it and frees it), only its text
/// changes. The old text is kept for undo. Refused when the field holds no string. Not merged:
/// an agent's call is one step.
class SetComponentStringCommand : EditorCommand
{
	private SceneEditContext mCtx;
	private Guid mEntity;
	private Type mType;
	private String mProperty = new .() ~ delete _;
	private String mNew = new .() ~ delete _;
	private String mOld = new .() ~ delete _;
	private bool mHasOld = false;

	public this(SceneEditContext ctx, Guid entity, Type componentType, StringView property, StringView text)
	{
		mCtx = ctx;
		mEntity = entity;
		mType = componentType;
		mProperty.Set(property);
		mNew.Set(text);
	}

	public override bool Execute()
	{
		let text = Resolve();
		if (text == null)
			return false;
		if (!mHasOld)
		{
			mOld.Set(text);
			mHasOld = true;
		}
		text.Set(mNew);
		return true;
	}

	public override void Undo()
	{
		if (let text = Resolve())
			text.Set(mOld);
	}

	public override StringView TypeId => "set_component_string";

	/// The component's string object, re-found on every apply (the pool moves); null when the
	/// field is not a String or holds none.
	private String Resolve()
	{
		let e = mCtx.Resolve(mEntity);
		let mgr = mCtx.FindManager(mType);
		if (!e.IsAssigned || (mgr == null))
			return null;
		let component = mgr.GetComponentAddress(e);
		if (component == null)
			return null;
		if (!(RawFieldAccess.FindField(mType, mProperty) case .Ok(let field)) || (field.FieldType != typeof(String)))
			return null;
		return *(String*)RawFieldAccess.AddressOf(field, component);
	}
}
