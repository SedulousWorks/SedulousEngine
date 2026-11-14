using System;
using Sedulous.Core;
using Sedulous.Engine.Project;

namespace Sedulous.Engine.Project.Tests;

/// The quality level a game starts at: the player's saved choice while the game still lists it,
/// else the manifest's default (a dist's is its export preset's) while listed, else the list's
/// last; none at all when the game lists no levels (the engine's own highest).
class QualityLevelTests
{
	[Test]
	public static void TheLevelAGameStartsAtInOrderOfWhoChoseIt()
	{
		let settings = scope ProjectSettings();
		let low = Guid(0x11, 0x12, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		let medium = Guid(0x13, 0x14, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		let high = Guid(0x15, 0x16, 0, 0, 0, 0, 0, 0, 0, 0, 0);

		// No levels: none, whatever a save says.
		Test.Assert(!settings.StartupQuality(Guid()).IsSet);
		Test.Assert(!settings.StartupQuality(low).IsSet);

		// Levels without a default: the list's last.
		settings.QualityLevelIds.Add(low);
		settings.QualityLevelIds.Add(medium);
		settings.QualityLevelIds.Add(high);
		Test.Assert(settings.StartupQuality(Guid()) == high);

		// The manifest's default (the project's, or a dist's from its preset).
		settings.DefaultQualityId = medium;
		Test.Assert(settings.StartupQuality(Guid()) == medium);

		// The player's own choice over both.
		Test.Assert(settings.StartupQuality(low) == low);

		// A saved level the game no longer lists is ignored, and so is a default it does not list.
		let gone = Guid(0x17, 0x18, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		Test.Assert(settings.StartupQuality(gone) == medium);
		settings.DefaultQualityId = gone;
		Test.Assert(settings.StartupQuality(Guid()) == high);
		Test.Assert(settings.IsQualityLevel(medium));
		Test.Assert(!settings.IsQualityLevel(gone));
	}
}
