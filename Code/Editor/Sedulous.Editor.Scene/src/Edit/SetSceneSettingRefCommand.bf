using System;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Points a settings block's Ref<T> field at another resource and rebinds it.
class SetSceneSettingRefCommand<T> : EditorCommand where T : class
{
	private SceneEditContext mCtx;
	private Type mSettingsType;
	private String mProperty = new .() ~ delete _;
	private Guid mNew;
	private Guid mOld = .();
	private bool mHasOld = false;
	private ResourceManager mResources;

	public this(SceneEditContext ctx, Type settingsType, StringView property, Guid value,
		ResourceManager resources)
	{
		mCtx = ctx;
		mSettingsType = settingsType;
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

	public override StringView TypeId => "set_scene_setting_ref";

	private Ref<T>* ResolveRef()
	{
		let system = mCtx.FindSystemBySettingsType(mSettingsType);
		if (system == null)
			return null;
		let settings = system.SettingsInstance;
		if (settings == null)
			return null;
		if (!(RawFieldAccess.FindField(mSettingsType, mProperty) case .Ok(let field)))
			return null;
		if (field.FieldType != typeof(Ref<T>))
			return null;
		return (Ref<T>*)RawFieldAccess.AddressOf(field, settings);
	}
}
