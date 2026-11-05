using System;
using Sedulous.Engine.Project;
using Sedulous.Runtime;

namespace Sedulous.Engine.Project.Tests;

class ProjectLayoutTests
{
	/// The save's name, which a Game tab keeps under Editor/ and the player in the user data
	/// directory: the same name in both, so a save copied between them is found.
	[Test]
	public static void TheSaveFileIsNamedForTheProject()
	{
		Test.Assert(ProjectLayout.SaveFileName("Test Project", .. scope String()) == "Test Project.save.xml");
		Test.Assert(ProjectLayout.SaveFileName("", .. scope String()) == "project.save.xml");
	}

	/// A package's name gives a valid plugin id: lower cased, anything else an underscore, and
	/// prefixed when it would not start with a letter.
	[Test]
	public static void APackagesNameGivesAValidPluginId()
	{
		Test.Assert(ProjectLayout.PluginIdFromName("NativeSample", .. scope String()) == "nativesample");
		Test.Assert(ProjectLayout.PluginIdFromName("Old Game-2", .. scope String()) == "old_game_2");
		Test.Assert(ProjectLayout.PluginIdFromName("2 Fast", .. scope String()) == "game_2_fast");
		Test.Assert(ProjectLayout.PluginIdFromName("", .. scope String()) == "game_");
		Test.Assert(PluginManifest.IsValidId(ProjectLayout.PluginIdFromName("_x", .. scope String())));
	}
}
