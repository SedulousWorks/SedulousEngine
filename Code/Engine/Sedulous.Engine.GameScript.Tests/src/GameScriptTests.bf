using System;
using Sedulous.Core;
using Sedulous.Messaging;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Engine.GameInstance;
using Sedulous.Engine.Script;

namespace Sedulous.Engine.GameScript.Tests;

/// The Game tier: an orchestrator class launched on a run, ticked with gameplay time,
/// hearing the run bus, driving level loads through `Run`, and stopped with its exit.
static class GameScriptTests
{
	private const String cGame = """
		class Game
		{
			int launches = 0;
			int updates = 0;
			float elapsed = 0;
			int exits = 0;
			int score = 0;
			string last;
			void launch() { launches++; }
			void update(float dt) { updates++; elapsed += dt; }
			void exit() { exits++; }
			void onScore(int points) { score += points; }
			void onSaid(const string &in what) { last = what; }
		}
		""";

	[Test]
	public static void LaunchUpdateAndExitRunOnTheRunsClock()
	{
		let run = scope GameRun("scratch_game_lifecycle");
		let game = run.Class("Game", cGame);
		Test.Assert(run.Instance.StartScript(game), "launched");
		Test.Assert(run.Instance.ScriptRunning);
		Test.Assert(run.PropInt("launches") == 1);
		Test.Assert(run.PropInt("updates") == 0, "update waits for the tick");

		run.Step(3);
		Test.Assert(run.PropInt("updates") == 3);
		Test.Assert(Math.Abs(run.PropFloat("elapsed") - 3.0f / 60.0f) < 1e-4f);

		// The run's time scale scales what the orchestrator sees, and it still runs at nought,
		// which is what lets it unpause.
		run.Instance.InstanceTimeScale = 0.0f;
		run.Step(2);
		Test.Assert(run.PropInt("updates") == 5, "ticked while paused");
		Test.Assert(Math.Abs(run.PropFloat("elapsed") - 3.0f / 60.0f) < 1e-4f, "with no time passing");
		run.Instance.InstanceTimeScale = 1.0f;

		// A second start replaces the first, exit() included: the new one has seen nothing.
		Test.Assert(run.Instance.StartScript(game));
		Test.Assert((run.PropInt("updates") == 0) && (run.PropInt("exits") == 0), "a fresh instance");

		run.Instance.StopScript();
		Test.Assert(!run.Instance.ScriptRunning);
		run.Instance.StopScript(); // idempotent
	}

	[Test]
	public static void TheRunBusReachesTheOrchestratorsHandlers()
	{
		let run = scope GameRun("scratch_game_events");
		let game = run.Class("Game", cGame);
		Test.Assert(run.Instance.StartScript(game));

		// Published from native code, delivered at the drain, not inside the publish.
		run.Instance.RunEvents.Publish(StringHash("Score"), Variant.Create((int32)5));
		Test.Assert(run.PropInt("score") == 0);
		run.Step();
		Test.Assert(run.PropInt("score") == 5);

		// Published by the run's own verb, a string payload.
		run.Instance.Emit("Said", "hello");
		run.Step();
		Test.Assert(run.Prop("last").AsString == "hello");

		// An event nobody declared is nothing, and the stop unsubscribes.
		run.Instance.Emit("Nothing", 1);
		run.Step();
		run.Instance.StopScript();
		run.Instance.Emit("Score", 7);
		run.Step();
		Test.Assert(run.Instance.RunEvents.SubscriberCount == 0, "unsubscribed with the script");
	}

	[Test]
	public static void ABehaviourInTheRunsSceneEmitsOntoTheSameBus()
	{
		let run = scope GameRun("scratch_game_scene_bus");
		let game = run.Class("Game", cGame);
		let shouter = run.Class("Shouter", """
			class Shouter
			{
				Entity self;
				Scene@ scene;
				bool done = false;
				void onUpdate(float dt) { if (!done) { done = true; scene.Scripts.Emit("Score", 3); } }
			}
			""");
		Test.Assert(run.Instance.StartScript(game));

		// A scene the instance created: its behaviours run on the instance's host, and its
		// bus IS the run bus.
		let level = run.Instance.CreateScene("level");
		let components = level.GetSystem<ScriptComponentManager>();
		Test.Assert(components != null, "the run's scenes compose the script managers");
		let e = level.CreateEntity("e");
		let behavior = new ScriptBehavior();
		behavior.Script.SetDirect(shouter);
		components.Add(e).Behaviors.Add(behavior);
		level.Start();
		level.SetSimulationEnabled(true);

		run.Step(2);
		Test.Assert(run.PropInt("score") == 3, scope $"the Game heard the behaviour, score {run.PropInt("score")}");
	}

	[Test]
	public static void TheOrchestratorLoadsTheFirstLevelThroughRun()
	{
		let run = scope GameRun("scratch_game_boot");
		let levelId = run.AuthorLevel("level", 3);
		// The level's id is in the source, as a shipped game's would be.
		let source = scope String();
		source.AppendF("""
			class Game
			{{
				int ticket = -1;
				bool ready = false;
				bool readyBefore = true;
				int entities = 0;
				void launch()
				{{
					readyBefore = Run.SceneReady;
					startCoroutine(ScriptCoroutine(this.boot));
				}}
				void boot()
				{{
					ticket = Run.LoadSceneAsync(Guid::FromString("{}"));
					while (!Run.LoadComplete(ticket)) yield();
					ready = Run.SceneReady;
					entities = int(Run.CurrentScene.EntityCount);
				}}
			}}
			""", levelId);
		let game = run.Class("Game", source);
		Test.Assert(run.Instance.StartScript(game));
		Test.Assert(!run.PropBool("readyBefore"), "no scene at launch");
		// The coroutine ran to its first yield inside launch(): the load is in flight.
		Test.Assert(run.PropInt("ticket") == 1, scope $"ticket {run.PropInt("ticket")}");
		Test.Assert(!run.PropBool("ready"));

		run.Step(20);
		for (let p in run.Instance.RunHost.Runtime.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(run.PropBool("ready"), "the scene is live once the load completed");
		Test.Assert(run.PropInt("entities") == 3, "the current scene is the loaded level");
		Test.Assert(run.Instance.SceneReady && (run.Instance.GetScene().EntityCount == 3));
		Test.Assert(run.Instance.Scenes.IsActive(run.Instance.GetScene()), "activated by the policy");
		Test.Assert(run.Instance.RunHost.Runtime.CoroutineCount == 0, "the boot coroutine finished");
	}

	[Test]
	public static void AnUnknownLevelFailsToStartAndExitReachesTheHost()
	{
		let run = scope GameRun("scratch_game_exit");
		let game = run.Class("Game", """
			class Game
			{
				int ticket = -1;
				bool synced = true;
				void launch()
				{
					ticket = Run.LoadSceneAsync(Guid());
					synced = Run.LoadScene(Guid());
					Run.RequestExit(3);
				}
			}
			""");
		Test.Assert(run.Instance.StartScript(game));
		Test.Assert(run.PropInt("ticket") == 0, "nought is the load that did not start");
		Test.Assert(!run.PropBool("synced"));
		Test.Assert((run.ExitCode == 3) && (run.Exits == 1), "the exit reached the host with its code");
	}

	[Test]
	public static void AFaultingUpdateStopsTheScriptNotTheRun()
	{
		let run = scope GameRun("scratch_game_fault");
		let game = run.Class("Game", """
			class Game
			{
				int updates = 0;
				void update(float dt) { updates++; if (updates == 2) { int[] a; a[5] = 1; } }
			}
			""");
		Test.Assert(run.Instance.StartScript(game));
		run.Step();
		Test.Assert(run.Instance.ScriptRunning);
		run.Step();
		Test.Assert(!run.Instance.ScriptRunning, "the fault stopped the script");
		run.Step(2); // and the run keeps ticking without it
		Test.Assert(run.Game == null);
	}

	[Test]
	public static void EachInstanceRunsItsOwnGameOnItsOwnHost()
	{
		let a = scope GameRun("scratch_game_a");
		let b = scope GameRun("scratch_game_b");
		let bLevel = b.AuthorLevel("level", 1);
		let game = """
			class Game
			{
				bool ready = false;
				void update(float dt) { ready = Run.SceneReady; }
			}
			""";
		Test.Assert(a.Instance.StartScript(a.Class("Game", game)));
		Test.Assert(b.Instance.StartScript(b.Class("Game", game)));
		Test.Assert(b.Instance.LoadScene(bLevel), "b has a scene");
		a.Step();
		b.Step();
		Test.Assert(!a.PropBool("ready"), "a's Run is a's instance");
		Test.Assert(b.PropBool("ready"), "b's Run is b's");
		Test.Assert(a.Instance.RunHost.Runtime !== b.Instance.RunHost.Runtime, "one gameplay context per run");
	}

	[Test]
	public static void ABreakpointInTheOrchestratorHoldsTheRunsScriptClock()
	{
		let run = scope GameRun("scratch_game_debug");
		let game = run.Class("Game", """
			class Game
			{
				int updates = 0;
				int after = 0;
				int score = 0;
				void update(float dt)
				{
					updates++;
					after++;
				}
				void onScore(int points) { score += points; }
			}
			""");
		Test.Assert(run.Instance.StartScript(game));
		IScriptDebugger debugger = null;
		run.Instance.RequestDebugger(new [&] (d) => { d.SetBreakpoint("Game.as", 9); debugger = d; });
		Test.Assert(debugger != null);

		run.Step();
		Test.Assert(run.Instance.IsDebugPaused, "held inside update");
		Test.Assert((run.PropInt("updates") == 1) && (run.PropInt("after") == 0));
		Test.Assert(run.Instance.ScriptRunning, "paused is not faulted");

		// Held: no new update, and the bus waits.
		run.Instance.Emit("Score", 4);
		run.Step(3);
		Test.Assert((run.PropInt("updates") == 1) && (run.PropInt("score") == 0));

		debugger.Continue();
		Test.Assert(!run.Instance.IsDebugPaused && (run.PropInt("after") == 1));
		debugger.ClearBreakpoints();
		run.Step();
		Test.Assert(run.PropInt("updates") == 2);
		Test.Assert(run.PropInt("score") == 4, "the event queued through the pause was delivered after it");
	}
}
