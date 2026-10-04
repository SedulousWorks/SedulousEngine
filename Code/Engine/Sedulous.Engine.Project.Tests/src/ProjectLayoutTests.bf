using System;
using Sedulous.Engine.Project;

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
}
