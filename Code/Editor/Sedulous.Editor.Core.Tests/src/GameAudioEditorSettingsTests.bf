using System;
using Sedulous.Editor.Core;
using Sedulous.Settings;

namespace Sedulous.Editor.Core.Tests;

/// The editor's game audio preference: off by default (only the focused Game tab is heard),
/// read from the user store, and contributed to Preferences as its own category.
static class GameAudioEditorSettingsTests
{
	[Test]
	public static void HearingEveryGameTabIsOffUntilTheUserTurnsItOn()
	{
		let context = scope EditorContext();
		Test.Assert(!GameAudioEditorSettings.HearAllGameInstances(context), "no store: the default");

		let store = scope Settings();
		context.UserEditorSettings = store;
		Test.Assert(!GameAudioEditorSettings.HearAllGameInstances(context), "no section: the default");

		GameAudioEditorSettings.Register(context);
		let contribution = context.EditorSettingsContributions[context.EditorSettingsContributions.Count - 1];
		Test.Assert(contribution.Category == "Game audio");
		Test.Assert(contribution.Bools.Count == 1);
		contribution.Bools[0].Set(true); // what the Preferences toggle does
		Test.Assert(GameAudioEditorSettings.HearAllGameInstances(context));
		Test.Assert(store.Find<GameAudioEditorSettings>().HearAllInstances);
		Test.Assert(contribution.Bools[0].Get());
		context.UserEditorSettings = null;
	}
}
