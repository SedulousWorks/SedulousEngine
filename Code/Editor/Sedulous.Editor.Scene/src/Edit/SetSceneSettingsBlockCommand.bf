using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Replaces a whole settings block from its serialized form: the old bytes are captured on
/// the first Execute and undo reads them back through the same versioned payload.
class SetSceneSettingsBlockCommand : EditorCommand
{
	private SceneEditContext mCtx;
	private Type mSettingsType;
	private List<uint8> mNew ~ delete _;
	private List<uint8> mOld = new .() ~ delete _;

	/// CONSUMES `newBlob`.
	public this(SceneEditContext ctx, Type settingsType, List<uint8> newBlob)
	{
		mCtx = ctx;
		mSettingsType = settingsType;
		mNew = newBlob;
	}

	public override bool Execute()
	{
		let system = mCtx.FindSystemBySettingsType(mSettingsType);
		if (system == null)
			return false;
		if (mOld.IsEmpty)
			SceneSettingsBlock.Capture(system, mOld);
		return SceneSettingsBlock.Apply(system, mNew);
	}

	public override void Undo()
	{
		let system = mCtx.FindSystemBySettingsType(mSettingsType);
		if (system != null)
			SceneSettingsBlock.Apply(system, mOld);
	}

	public override StringView TypeId => "set_scene_settings_block";
}
