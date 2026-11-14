using System;
using System.Collections;
using Sedulous.Engine.GameInstance;

namespace Sedulous.Engine.GameScript.Tests;

/// `RenderQuality` to a game script: it lists the levels its run offers, reads the one it plays
/// at and switches to another by its label, through the run's facade, whose choose hook (the
/// host's: the player plays at the level and keeps the choice) hears it. A label the run does
/// not offer is refused, and a run that offers none lists nothing.
class RenderQualityFacadeRunTests
{
	[Test]
	public static void AGameScriptListsTheLevelsReadsTheCurrentOneAndSwitchesByLabel()
	{
		let run = scope GameRun("scratch_quality_run");
		let quality = run.Instance.Quality;
		let low = Guid(1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		let medium = Guid(2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		let high = Guid(3, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		quality.Add(low, "Low");
		quality.Add(medium, "Medium");
		quality.Add(high, "High");
		quality.CurrentId = high;
		let played = scope List<Guid>();
		quality.SetOnChoose(new [&] (id) => { played.Add(id); });

		let game = run.Class("Game", """
			class Game
			{
				string listed = "";
				string before = "";
				string after = "";
				bool switched = false;
				bool refused = true;
				void launch()
				{
					for (int i = 0; i < RenderQuality.Count(); i++)
					{
						if (i > 0)
							listed += ",";
						listed += RenderQuality.Label(i);
					}
					before = RenderQuality.Current();
					switched = RenderQuality.Set("Low");
					refused = RenderQuality.Set("Ultra");
					after = RenderQuality.Current();
				}
			}
			""");
		Test.Assert(run.Instance.StartScript(game));
		run.Step();
		Test.Assert(run.Prop("listed").AsString == "Low,Medium,High", scope String(run.Prop("listed").AsString));
		Test.Assert(run.Prop("before").AsString == "High");
		Test.Assert(run.PropBool("switched"));
		Test.Assert(!run.PropBool("refused"), "Ultra is not offered");
		Test.Assert(run.Prop("after").AsString == "Low");
		Test.Assert(quality.CurrentId == low);
		Test.Assert((played.Count == 1) && (played[0] == low), "the refused set asked for nothing");
		run.Instance.StopScript();

		// A run that offers none lists nothing, reads an empty label and refuses a set.
		quality.Clear();
		Test.Assert(quality.Count() == 0);
		Test.Assert(quality.Current().IsEmpty);
		Test.Assert(!quality.Set("Low"));
		Test.Assert(played.Count == 1);
	}
}
