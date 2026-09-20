using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Editor.Scene;

/// A scene system's settings block, named by its type.
class SettingsTarget : InspectorTarget
{
	public readonly Type Type;

	public this(SceneEditContext edit, Type settingsType) : base(edit)
	{
		Type = settingsType;
	}

	public override Type TargetType => Type;

	public override void* Address
	{
		get
		{
			let system = mEdit.FindSystemBySettingsType(Type);
			return (system != null) ? system.SettingsInstance : null;
		}
	}

	public override void SetProperty(StringView field, Variant value)
		=> mEdit.SetSceneSettingProperty(Type, field, value);

	public override void SetPropertyRaw(StringView field, int64 raw)
		=> mEdit.SetSceneSettingPropertyRaw(Type, field, raw);

	/// A settings block holds no entity references.
	public override void SetEntityRef(StringView field, Guid target) {}

	public override void Mutate(delegate void(void* instance) mutate)
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
