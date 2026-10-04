using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Editor.Scene;

/// A scene system's settings block, named by its type.
///
/// The values a row shows are the ones in effect: a profile's while the block's source is a
/// profile, the scene's own otherwise. A [SceneOnly] field's rows read the scene's own block
/// through SceneOnlyTarget. An edit is routed by the edit context, field by field.
class SettingsTarget : InspectorTarget
{
	public readonly Type Type;
	public readonly bool SceneOnly;
	private SettingsTarget mSceneOnlyTarget ~ delete _;

	public this(SceneEditContext edit, Type settingsType, bool sceneOnly = false) : base(edit)
	{
		Type = settingsType;
		SceneOnly = sceneOnly;
	}

	public override Type TargetType => Type;

	public override void* Address => mEdit.SettingsValues(Type, SceneOnly);

	public override InspectorTarget SceneOnlyTarget
	{
		get
		{
			if (SceneOnly)
				return this;
			if (mSceneOnlyTarget == null)
				mSceneOnlyTarget = new SettingsTarget(mEdit, Type, true);
			return mSceneOnlyTarget;
		}
	}

	public override void SetProperty(StringView field, Variant value)
		=> mEdit.SetSceneSettingProperty(Type, field, value);

	public override void SetPropertyRaw(StringView field, int64 raw)
		=> mEdit.SetSceneSettingPropertyRaw(Type, field, raw);

	/// A settings block holds no entity references.
	public override void SetEntityRef(StringView field, Guid target) {}

	/// Mutates the scene's own block: the blocks that take a profile's values have no field
	/// edited this way.
	public override void Mutate(delegate void(void* instance) mutate, StringView mergeKey)
	{
		let system = mEdit.FindSystemBySettingsType(Type);
		if (system == null)
			return;
		let live = system.SettingsInstance;
		if (live == null)
			return;
		let before = scope List<uint8>();
		SceneSettingsBlock.Capture(system, before);
		mutate(live);
		let after = new List<uint8>();
		SceneSettingsBlock.Capture(system, after);
		SceneSettingsBlock.Apply(system, before);
		mEdit.ApplySceneSettingsBlock(Type, after);
	}
}
