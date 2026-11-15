using System;
using System.Collections;
using Sedulous.Run;
using Sedulous.Engine.GameInstance;

namespace Sedulous.Engine.GameInstance.Tests;

/// `RenderQuality` to a game's code: it lists the levels its run offers, reads the one it plays
/// at and switches to another by its label, through the run's facade, whose choose hook (the
/// host's: the player plays at the level and keeps the choice) hears it. A label the run does
/// not offer is refused, and a run that offers none lists nothing.
class RenderQualityFacadeRunTests
{
	[Test]
	public static void GameCodeListsTheLevelsReadsTheCurrentOneAndSwitchesByLabel()
	{
		let instance = scope GameInstance();
		let quality = instance.Quality;
		Test.Assert(RunServices.Get<RenderQualityFacade>(instance) === quality, "a service of the run");
		let low = Guid(1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		let medium = Guid(2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		let high = Guid(3, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		quality.Add(low, "Low");
		quality.Add(medium, "Medium");
		quality.Add(high, "High");
		quality.CurrentId = high;
		let played = scope List<Guid>();
		quality.SetOnChoose(new [&] (id) => { played.Add(id); });

		let listed = scope String();
		for (int32 i < quality.Count())
		{
			if (i > 0)
				listed.Append(",");
			listed.Append(quality.Label(i));
		}
		Test.Assert(listed == "Low,Medium,High", listed);
		Test.Assert(quality.Current() == "High");
		Test.Assert(quality.Set("Low"));
		Test.Assert(!quality.Set("Ultra"), "Ultra is not offered");
		Test.Assert(quality.Current() == "Low");
		Test.Assert(quality.CurrentId == low);
		Test.Assert((played.Count == 1) && (played[0] == low), "the refused set asked for nothing");

		// A run that offers none lists nothing, reads an empty label and refuses a set.
		quality.Clear();
		Test.Assert(quality.Count() == 0);
		Test.Assert(quality.Current().IsEmpty);
		Test.Assert(!quality.Set("Low"));
		Test.Assert(played.Count == 1);
	}
}
