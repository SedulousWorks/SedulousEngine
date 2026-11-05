using System;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Engine.Script;
using Sedulous.Run;
using Sedulous.Runtime;

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

	private class Plain { }
	private class Other { }
	private class Lone { }
	/// A run of its own (a GameInstance is the real one).
	private class TestRun : RunBase
	{
		public this() : base("test") {}
	}

	/// A run host's scripts find a service as they ask: the host's own, then its run's, then the
	/// application's; a run's service goes with the run, the application's then answering.
	[Test]
	public static void AServiceIsTheHostsThenTheRunsThenTheApplications()
	{
		let application = scope SubsystemManager();
		let appPlain = scope Plain();
		let appOther = scope Other();
		let lone = scope Lone();
		application.RegisterService(appPlain);
		application.RegisterService(appOther);
		application.RegisterService(lone);
		let host = scope ScriptRunHost();
		host.Subsystems = application;
		Test.Assert(host.FindService(typeof(Plain)) === appPlain, "outside every run: the application's");

		let run = scope TestRun();
		let runPlain = scope Plain();
		run.Register(runPlain);
		host.OwningRun = run;
		Test.Assert(host.FindService(typeof(Plain)) === runPlain, "the run's before the application's");
		Test.Assert(host.FindService(typeof(Lone)) === lone, "a type only the application offers");

		let hostOther = scope Other();
		host.SetService(hostOther);
		Test.Assert(host.FindService(typeof(Other)) === hostOther, "the host's own first");

		run.Dispose(); // the run gone: its services with it
		Test.Assert(host.FindService(typeof(Plain)) === appPlain, "the run's gone with it");
		host.OwningRun = null;
		host.Subsystems = null;
		Test.Assert(host.FindService(typeof(Plain)) == null);
	}
}
