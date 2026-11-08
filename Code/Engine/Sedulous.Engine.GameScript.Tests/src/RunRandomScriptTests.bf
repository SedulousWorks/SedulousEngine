using System;
using Sedulous.Core;
using Sedulous.Engine.GameInstance;

namespace Sedulous.Engine.GameScript.Tests;

/// A run's scripts and its native code draw from one generator: `Random` to a game script is
/// the run's RunRandom.
class RunRandomScriptTests
{
	[Test]
	public static void AGameScriptsRandomIsTheRunsRunRandom()
	{
		let run = scope GameRun("scratch_run_random");
		let random = run.Instance.Get<RunRandom>();
		Test.Assert(random != null);
		Test.Assert(run.Instance.RunHost.Random.Source === random, "the host's Random draws from the run's");
		let game = run.Class("Game", """
			class Game
			{
				float first = -1;
				float ranged = -1;
				int die = 0;
				void launch()
				{
					Random.Seed(11);
					first = Random.Value();
					ranged = Random.Range(2.0f, 4.0f);
					die = Random.IntRange(1, 6);
				}
			}
			""");
		Test.Assert(run.Instance.StartScript(game));
		Test.Assert(run.Instance.ScriptFault.IsEmpty, scope $"faulted: {run.Instance.ScriptFault}");

		let expected = scope RunRandom();
		expected.Seed(11);
		Test.Assert(run.PropFloat("first") == expected.Value(), "the script seeded and drew the run's");
		Test.Assert(run.PropFloat("ranged") == expected.Range(2.0f, 4.0f));
		Test.Assert(run.PropInt("die") == expected.IntRange(1, 6));
		Test.Assert(random.NextU32() == expected.NextU32(), "native code continues the script's sequence");
		run.Instance.StopScript();
	}
}
