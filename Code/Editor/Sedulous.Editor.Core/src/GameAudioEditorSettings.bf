using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Core;

/// The editor's game audio preference, a section of the per user store (the Preferences
/// dialog's Game audio category): with several Game tabs running, hear only the focused one
/// (the default) or every instance at once.
[Serializable(1)]
class GameAudioEditorSettings
{
	public bool HearAllInstances = false;

	/// The preference's value; the default when no store or section exists (headless, tests).
	public static bool HearAllGameInstances(EditorContext context)
	{
		let store = context.UserEditorSettings;
		let section = (store != null) ? store.Find<GameAudioEditorSettings>() : null;
		return (section != null) && section.HearAllInstances;
	}

	/// Registers the Game audio category into the Preferences dialog; from registerEditors.
	public static void Register(EditorContext context)
	{
		let contribution = new EditorSettingsContribution("Game audio");
		contribution.Bools.Add(new EditorSettingsBoolField("Hear every Game tab",
			"With several Game tabs running, mix every instance's sound. Off (the default): only the focused tab is heard, the others run muted.",
			new [=context]() => HearAllGameInstances(context),
			new [=context](value) =>
			{
				if (let store = context.UserEditorSettings)
				{
					store.Section<GameAudioEditorSettings>().HearAllInstances = value;
					store.MarkChanged<GameAudioEditorSettings>();
				}
			}));
		context.RegisterEditorSettingsContribution(contribution);
	}
}
