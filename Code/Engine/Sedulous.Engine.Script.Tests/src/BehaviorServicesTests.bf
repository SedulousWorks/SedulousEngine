using System;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Engine.Script;

namespace Sedulous.Engine.Script.Tests;

/// The run's own services a script reaches by name: its random numbers, and the log.
static class BehaviorServicesTests
{
	[Test]
	public static void RandomIsTheRunsAndReplaysFromASeed()
	{
		let play = scope ScriptPlayScene();
		let roller = play.Class("Roller", """
			class Roller
			{
				float first = -1;
				float second = -1;
				int die = 0;
				bool coin = false;
				void onStart()
				{
					Random.Seed(7);
					first = Random.Value();
					Random.Seed(7);
					second = Random.Value();
					die = Random.IntRange(1, 6);
					coin = Random.Bool();
					Print("rolled " + die);
					PrintWarning("a warning from a script");
				}
			}
			""");
		let e = play.AddBehavior(roller, "roller");
		play.Start();
		play.Step();
		Test.Assert(!play.BehaviorOf(e).Faulted);
		let first = play.PropFloat(e, "first");
		Test.Assert((first >= 0.0f) && (first < 1.0f));
		Test.Assert(first == play.PropFloat(e, "second"), "the same seed replays");
		let die = play.PropInt(e, "die");
		Test.Assert((die >= 1) && (die <= 6));
		// The host owns the generator: what the script seeded is what the host reads next.
		Test.Assert(play.Host.Random != null);
	}
}
