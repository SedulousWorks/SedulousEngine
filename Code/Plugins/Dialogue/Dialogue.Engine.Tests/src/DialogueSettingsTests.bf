using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Runtime;
using Sedulous.Engine.Project;
using Dialogue;

namespace Dialogue.Tests;

/// The dialogue plugin's settings, as the project's entry for the plugin holds them and as Project
/// Settings shows them.
class DialogueSettingsTests
{
	[Test]
	public static void AnEntryWithNoneGivesTheDefaults()
	{
		let settings = scope DialogueSettings();
		Test.Assert(EnabledPlugin.ReadSettings(default, settings) case .Ok);
		Test.Assert(settings.Cast == .() && settings.Assets == .());
		Test.Assert(settings.Commands.IsEmpty);
		Test.Assert(settings.ProvidedFlags.IsEmpty);
		Test.Assert(settings.FlagPrefix == "flag.");
		Test.Assert(!settings.StockBox);
		Test.Assert(settings.TypingSpeed == 40);
		Test.Assert(settings.AdvanceAction == "Interact");
		Test.Assert(!settings.PortraitOnRight);
		Test.Assert(Math.Abs(settings.FadeSeconds - 0.5f) < 1e-5f);
		Test.Assert(settings.FadeColor.W == 1.0f);
	}

	[Test]
	public static void TheyReadBackFromTheEntryAsTheyWereWritten()
	{
		let written = scope DialogueSettings();
		written.Commands.Add(new .("move <who:entity> to <target:entity> [running] [and wait]"));
		written.Commands.Add(new .("fight <foe:list(foes)> leaves"));
		written.ProvidedFlags.Add(new .("seen_*"));
		written.FlagPrefix.Set("story.");
		written.StockBox = true;
		written.TypingSpeed = 60;
		written.AdvanceAction.Set("Confirm");
		written.PortraitOnRight = true;
		written.FadeSeconds = 1.25f;
		written.StockBoxSheet = Guid(3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3);
		written.FadeColor = .(1.0f, 1.0f, 1.0f, 1.0f);
		written.Cast = Guid(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);
		written.Assets = Guid(11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1);
		let entry = scope List<uint8>();
		Test.Assert(EnabledPlugin.WriteSettings(written, entry) case .Ok);

		let read = scope DialogueSettings();
		Test.Assert(EnabledPlugin.ReadSettings(entry, read) case .Ok);
		Test.Assert(read.Commands.Count == 2);
		Test.Assert(read.Commands[0] == written.Commands[0]);
		Test.Assert(read.Commands[1] == written.Commands[1]);
		Test.Assert((read.ProvidedFlags.Count == 1) && (read.ProvidedFlags[0] == "seen_*"));
		Test.Assert(read.FlagPrefix == "story.");
		Test.Assert(read.StockBox);
		Test.Assert(read.TypingSpeed == 60);
		Test.Assert(read.AdvanceAction == "Confirm");
		Test.Assert(read.PortraitOnRight);
		Test.Assert(Math.Abs(read.FadeSeconds - 1.25f) < 1e-5f);
		Test.Assert(read.FadeColor.X == 1.0f);
		Test.Assert(read.StockBoxSheet == written.StockBoxSheet);
		Test.Assert((read.Cast == written.Cast) && (read.Assets == written.Assets));
	}

	[Test]
	public static void EverySettingHasALabelForProjectSettings()
	{
		var count = 0;
		for (let field in typeof(DialogueSettings).GetFields())
		{
			if (!field.IsPublic || field.IsStatic)
				continue;
			count++;
			Test.Assert(field.GetCustomAttribute<SettingAttribute>() case .Ok, scope $"{field.Name} has no label");
		}
		Test.Assert(count == 12);
	}
}
