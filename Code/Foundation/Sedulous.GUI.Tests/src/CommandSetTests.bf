using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A GUI's commands by id, each observable. Raptor's command tests need the dispatcher and
/// markup (CommandTests), so these check the set itself until those land.
class CommandSetTests
{
	[Test]
	public static void ACommandIsDefinedOnceItsLabelTheIdUntilOneIsSet()
	{
		let commands = scope CommandSet();
		let save = commands.Define("save");
		Test.Assert(save.Id == "save");
		Test.Assert(save.Label == "save");
		Test.Assert(save.Enabled);
		Test.Assert(!save.Checked);
		Test.Assert(commands.Define("save") === save);
		Test.Assert(commands.Find("save") === save);
		Test.Assert(commands.Find("load") == null);
	}

	[Test]
	public static void AControlsBindingFollowsTheCommandAndTheSet()
	{
		let commands = scope CommandSet();
		let save = commands.Define("save");
		bool lit = false;
		int definitions = 0;
		let effect = scope Effect(new [&]() =>
			{
				commands.TrackChanges();
				definitions++;
				lit = save.Enabled;
			});
		Test.Assert(lit);
		save.Enabled = false;
		save.DisabledReason = "Nothing to save";
		Test.Assert(!lit);
		Test.Assert(save.DisabledReason == "Nothing to save");
		let before = definitions;
		commands.Define("load");
		Test.Assert(definitions == before + 1, "a definition is a change the set tells of");
		Test.Assert(effect.RunCount >= 3);
	}
}
