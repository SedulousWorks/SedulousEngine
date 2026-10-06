using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Messaging;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Engine.GameInstance;
using Sedulous.Engine.Script;
using Sedulous.Engine.Script.Facades;
using Sedulous.Script.AngelScript;

namespace Sedulous.Engine.GameScript.Tests;

/// The Game tier: an orchestrator class launched on a run, ticked by time the run's scale does not
/// touch (that scale is its scenes'), hearing the run bus, driving level loads through `Run`, and
/// stopped with its exit.
static class GameScriptTests
{
	private const String cGame = """
		class Game
		{
			int launches = 0;
			int updates = 0;
			float elapsed = 0;
			float real = 0;
			int exits = 0;
			int score = 0;
			string last;
			void launch() { launches++; }
			void update(float dt) { updates++; elapsed += dt; real += Run.RealDeltaTime; }
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

		// The run's time scale pauses or slows the run's scenes, not the orchestrator that sets
		// it: at nought and in slow motion its dt is still real time, which is what lets it
		// unpause and time a celebration or a countdown over a frozen screen.
		run.Instance.InstanceTimeScale = 0.0f;
		run.Step(2);
		Test.Assert(run.PropInt("updates") == 5, "ticked while paused");
		Test.Assert(Math.Abs(run.PropFloat("elapsed") - 5.0f / 60.0f) < 1e-4f, "its time passing");
		Test.Assert(Math.Abs(run.PropFloat("real") - 5.0f / 60.0f) < 1e-4f);
		run.Instance.InstanceTimeScale = 0.12f;
		run.Step(1);
		Test.Assert(Math.Abs(run.PropFloat("elapsed") - 6.0f / 60.0f) < 1e-4f, "and in slow motion");
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

	/// A scene destroyed while it runs (a level load replacing the level it is in: a retry) is
	/// stopped first, so its script system unhooks its handlers from the run's bus, which
	/// outlives the scene. Destroyed unstopped, the bus kept handlers the system had freed and
	/// the next event drained into them.
	[Test]
	public static void ADestroyedRunningSceneLeavesNoHandlersOnTheRunBus()
	{
		let run = scope GameRun("scratch_game_scene_unhook");
		let game = run.Class("Game", cGame);
		let listener = run.Class("Listener", """
			class Listener
			{
				Entity self;
				Scene@ scene;
				void onPing(int value) { scene.Scripts.Emit("Score", value); }
			}
			""");
		Test.Assert(run.Instance.StartScript(game));

		let level = run.Instance.CreateScene("level");
		let components = level.GetSystem<ScriptComponentManager>();
		let e = level.CreateEntity("e");
		let behavior = new ScriptBehavior();
		behavior.Script.SetDirect(listener);
		components.Add(e).Behaviors.Add(behavior);
		level.Start();
		level.SetSimulationEnabled(true);
		run.Step(2);

		// Subscribed: a ping reaches the listener, which answers with a score the Game counts.
		let before = run.PropInt("score");
		run.Instance.Emit("Ping", 5);
		run.Step(3);
		Test.Assert(run.PropInt("score") == before + 5, scope $"the listener heard the ping (score {run.PropInt("score")})");

		// Gone while running, then the run carries on: the event must reach no freed handler.
		run.Instance.DestroyScene(level);
		run.Instance.Emit("Ping", 1);
		run.Step(2);
		Test.Assert(run.Instance.GetScene() == null);
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
		// The fault is remembered with where it happened, and the run's clock kept moving.
		Test.Assert(run.Instance.ScriptFault.StartsWith("faulted in update"), scope String(run.Instance.ScriptFault));
		Test.Assert(Math.Abs(run.Instance.RunTime - 4.0 / 60.0) < 1e-5);
		run.Instance.ResetRunClock();
		Test.Assert(run.Instance.RunTime == 0);
		// A new start clears it.
		Test.Assert(run.Instance.StartScript(game));
		Test.Assert(run.Instance.ScriptFault.IsEmpty);
		run.Instance.StopScript();
		Test.Assert(run.Instance.ScriptFault.IsEmpty, "a clean stop is not a fault");
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

	/// The math values' operators, as the engine's Beef operators compute them: vector
	/// arithmetic, scalars on either side, negation, component-wise products, equality, the
	/// compound assignments, and a quaternion product composing in the engine's order.
	[Test]
	public static void ScriptsDoVectorArithmeticWithOperators()
	{
		let run = scope GameRun("scratch_game_operators");
		let game = run.Class("Game", """
			class Game
			{
				Float3 sum; Float3 diff; Float3 scaled; Float3 scaledLeft; Float3 halved; Float3 negated;
				Float3 product; Float3 quotient; Float3 accumulated; Float2 flat; Float4 wide;
				bool same; bool different; Quaternion turned; Color tint;
				void launch()
				{
					Float3 a = Float3(1, 2, 3);
					Float3 b = Float3(4, 5, 6);
					sum = a + b;
					diff = b - a;
					scaled = a * 2.0f;
					scaledLeft = 3.0f * a;
					halved = b / 2.0f;
					negated = -a;
					product = a * b;
					quotient = b / a;
					accumulated = a;
					accumulated += b;
					accumulated *= 2.0f;
					accumulated -= Float3(1, 1, 1);
					flat = Float2(1, 2) + Float2(3, 4) * 2.0f;
					wide = -(Float4(1, 2, 3, 4) * 2.0f);
					same = (a + b) == Float3(5, 7, 9);
					different = a != b;
					turned = Quaternion::FromAxisAngle(Float3::UnitY, 0.5f) * Quaternion::FromAxisAngle(Float3::UnitX, 0.25f);
					tint = Color(0.25f, 0.5f, 0.25f, 1.0f) * 2.0f;
				}
			}
			""");
		Test.Assert(run.Instance.StartScript(game));
		Float3 F3(StringView name) => run.Prop(name).AsFloat3;
		Test.Assert(F3("sum") == Float3(5, 7, 9));
		Test.Assert(F3("diff") == Float3(3, 3, 3));
		Test.Assert(F3("scaled") == Float3(2, 4, 6));
		Test.Assert(F3("scaledLeft") == Float3(3, 6, 9));
		Test.Assert(F3("halved") == Float3(2, 2.5f, 3));
		Test.Assert(F3("negated") == Float3(-1, -2, -3));
		Test.Assert(F3("product") == Float3(4, 10, 18));
		Test.Assert(F3("quotient") == Float3(4, 2.5f, 2));
		Test.Assert(F3("accumulated") == Float3(9, 13, 17));
		Test.Assert(run.Prop("flat").AsFloat2 == Float2(7, 10));
		Test.Assert(run.Prop("wide").AsFloat4 == Float4(-2, -4, -6, -8));
		Test.Assert(run.PropBool("same"));
		Test.Assert(run.PropBool("different"));
		let expected = Quaternion.FromAxisAngle(.(0, 1, 0), 0.5f) * Quaternion.FromAxisAngle(.(1, 0, 0), 0.25f);
		let turned = run.Prop("turned").AsQuaternion;
		Test.Assert(Math.Abs(turned.X - expected.X) + Math.Abs(turned.Y - expected.Y) + Math.Abs(turned.Z - expected.Z) + Math.Abs(turned.W - expected.W) < 1e-5, "the engine's composition order");
		let tint = run.Prop("tint").AsColor;
		Test.Assert(Math.Abs(tint.R - 0.5f) + Math.Abs(tint.G - 1.0f) + Math.Abs(tint.A - 2.0f) < 1e-5);
	}

	/// A script rumbles its own run's pad and stops it; the run's end stops it too, and another
	/// run's pad hears none of it.
	[Test]
	public static void AScriptRumblesItsOwnRunsPadAndTheRunsEndStopsIt()
	{
		const String cRumbler = """
			class Game
			{
				int step = 0;
				void launch() {}
				void update(float dt)
				{
					step++;
					if (step == 1) { Input.Rumble(0.6f, 0.3f, 0.2f); }
					if (step == 2) { Input.Rumble(0, 1.0f, 0.0f, 0.5f); }
					if (step == 3) { Input.StopRumble(); }
					if (step == 4) { Input.Rumble(0.5f, 0.5f, 1.0f); }
				}
			}
			""";
		let runA = scope GameRun("scratch_game_rumble_a");
		let runB = scope GameRun("scratch_game_rumble_b");
		let sourceA = scope OnePadSource();
		let sourceB = scope OnePadSource();
		runA.Instance.SetInputSource(sourceA);
		runB.Instance.SetInputSource(sourceB);
		Test.Assert(runA.Instance.StartScript(runA.Class("Game", cRumbler)));

		// Asked in the update, applied by the next input drive through the run's own source.
		runA.Step();
		runA.Instance.DriveInput(1.0f / 60.0f, 1.0f);
		runB.Instance.DriveInput(1.0f / 60.0f, 1.0f);
		Test.Assert(Math.Abs(sourceA.Gamepad.RumbleLow - 0.6f) < 1e-4f);
		Test.Assert(Math.Abs(sourceA.Gamepad.RumbleHigh - 0.3f) < 1e-4f);
		Test.Assert(sourceA.Gamepad.RumbleMs == 200);
		Test.Assert(sourceB.Gamepad.RumbleCalls == 0, "another run's pad is not touched");

		// By pad index, then stopped.
		runA.Step();
		runA.Instance.DriveInput(1.0f / 60.0f, 1.0f);
		Test.Assert(Math.Abs(sourceA.Gamepad.RumbleLow - 1.0f) < 1e-4f);
		runA.Step();
		runA.Instance.DriveInput(1.0f / 60.0f, 1.0f);
		Test.Assert(sourceA.Gamepad.RumbleLow == 0.0f);
		Test.Assert(sourceA.Gamepad.RumbleMs == 0);

		// Rumbling at the run's end: stopping the script stops the pad at once.
		runA.Step();
		runA.Instance.DriveInput(1.0f / 60.0f, 1.0f);
		Test.Assert(sourceA.Gamepad.RumbleLow == 0.5f);
		runA.Instance.StopScript();
		Test.Assert(sourceA.Gamepad.RumbleLow == 0.0f);
		Test.Assert(sourceB.Gamepad.RumbleCalls == 0);
	}

	/// Each run counts itself and keeps a best time; the second sees the first's values. The
	/// first never flushes: the run writes what changed as it stops.
	[Test]
	public static void AGameKeepsItsValuesBetweenRunsThroughSave()
	{
		const String cCounter = """
			class Game
			{
				void launch()
				{
					int runs = Save.GetInt("runs", 0);
					Save.SetInt("runs", runs + 1);
					if (Save.GetFloat("best", 999.0f) > 41.5f) { Save.SetFloat("best", 41.5f); }
					Save.SetBool("seen", Save.Has("runs"));
					Save.SetString("name", "Hopper");
					Save.SetInt("scratch", 1);
					Save.Remove("scratch");
				}
				void update(float dt) {}
			}
			""";
		let scratch = "scratch_game_save";
		RemoveDirectoryRecursive(scratch);
		defer RemoveDirectoryRecursive(scratch);
		let path = PathJoin(scratch, "game.xml", .. scope String());

		for (int32 runIndex = 1; runIndex <= 2; runIndex++)
		{
			let run = scope GameRun(scope $"scratch_game_save_run{runIndex}");
			run.Instance.SetSaveFile(path);
			Test.Assert(run.Instance.StartScript(run.Class("Game", cCounter)));
			Test.Assert(run.Instance.Saves.Values.GetInt("runs", 0) == runIndex);
			run.Instance.StopScript();
		}

		let reread = scope RunSave();
		reread.Open(path);
		Test.Assert(reread.Values.GetInt("runs", 0) == 2);
		Test.Assert(reread.Values.GetFloat("best", 0.0f) == 41.5f);
		Test.Assert(reread.Values.GetBool("seen", false));
		Test.Assert(reread.Values.GetText("name", "") == "Hopper");
		Test.Assert(!reread.Values.Has("scratch"));
	}

	/// A recorded run is a list of numbers: one run saves it, the next reads it back whole, and a
	/// key that is not a list fills nothing.
	[Test]
	public static void AGameSavesAListOfNumbersAndTheNextRunReadsItBack()
	{
		let scratch = "scratch_game_save_floats";
		RemoveDirectoryRecursive(scratch);
		defer RemoveDirectoryRecursive(scratch);
		let path = PathJoin(scratch, "game.xml", .. scope String());

		{
			let run = scope GameRun("scratch_game_save_floats_a");
			run.Instance.SetSaveFile(path);
			Test.Assert(run.Instance.StartScript(run.Class("Game", """
				class Game
				{
					void launch()
					{
						array<float> ghost = {1.5f, -2.25f, 30.0f};
						Save.SetFloats("ghost.Course", ghost);
						Save.SetInt("best", 3);
					}
					void update(float dt) {}
				}
				""")));
			run.Instance.StopScript();
		}

		let reread = scope RunSave();
		reread.Open(path);
		let written = scope List<float>();
		Test.Assert(reread.Values.GetFloats("ghost.Course", written));
		Test.Assert((written.Count == 3) && (written[1] == -2.25f));

		{
			let run = scope GameRun("scratch_game_save_floats_b");
			run.Instance.SetSaveFile(path);
			Test.Assert(run.Instance.StartScript(run.Class("Game", """
				class Game
				{
					bool had = false;
					int count = 0;
					float last = 0.0f;
					bool notList = true;
					int notListCount = -1;
					void launch()
					{
						array<float> ghost;
						had = Save.GetFloats("ghost.Course", ghost);
						count = ghost.length();
						last = ghost[2];
						array<float> other = {9.0f};
						notList = Save.GetFloats("best", other);
						notListCount = other.length();
					}
					void update(float dt) {}
				}
				""")));
			Test.Assert(run.PropBool("had"));
			Test.Assert(run.PropInt("count") == 3);
			Test.Assert(run.PropFloat("last") == 30.0f);
			Test.Assert(!run.PropBool("notList"));
			Test.Assert(run.PropInt("notListCount") == 0);
			run.Instance.StopScript();
		}
	}

	/// Flush writes while the run goes on, Clear forgets everything, and a run with no file
	/// keeps its values for the run alone.
	[Test]
	public static void SaveFlushesOnRequestAndClearsAndARunWithNoFileWritesNowhere()
	{
		let scratch = "scratch_game_save_flush";
		RemoveDirectoryRecursive(scratch);
		defer RemoveDirectoryRecursive(scratch);
		let path = PathJoin(scratch, "game.xml", .. scope String());

		{
			let run = scope GameRun("scratch_game_save_flush_a");
			run.Instance.SetSaveFile(path);
			Test.Assert(run.Instance.StartScript(run.Class("Game", """
				class Game
				{
					bool flushed = false;
					void launch() { Save.SetInt("coins", 37); flushed = Save.Flush(); }
					void update(float dt) {}
				}
				""")));
			Test.Assert(run.PropBool("flushed"));
			// Written at the flush, while the run is still going.
			let reread = scope RunSave();
			reread.Open(path);
			Test.Assert(reread.Values.GetInt("coins", 0) == 37);
			run.Instance.StopScript();
		}
		{
			let run = scope GameRun("scratch_game_save_flush_b");
			run.Instance.SetSaveFile(path);
			Test.Assert(run.Instance.StartScript(run.Class("Game", """
				class Game
				{
					void launch() { Save.Clear(); }
					void update(float dt) {}
				}
				""")));
			run.Instance.StopScript();
			let reread = scope RunSave();
			reread.Open(path);
			Test.Assert(reread.Values.Count == 0);
		}
		{
			// No file named: the game's values last the run, its reads see them, nothing is
			// written.
			let run = scope GameRun("scratch_game_save_flush_c");
			Test.Assert(run.Instance.StartScript(run.Class("Game", """
				class Game
				{
					int coins = 0;
					void launch() { Save.SetInt("coins", 5); coins = Save.GetInt("coins", 0); }
					void update(float dt) {}
				}
				""")));
			Test.Assert(run.PropInt("coins") == 5);
			Test.Assert(!run.Instance.Saves.Flush());
			run.Instance.StopScript();
		}
	}

	/// A run's behaviours get its services with no game script at all: the run's own Input
	/// (its action runtime, with the project's map), its Save and Run, never the idle ones
	/// the application's configurator installs for scripts outside a run.
	[Test]
	public static void ARunsBehavioursGetItsServicesWithoutAGameScript()
	{
		let run = scope GameRun("scratch_game_services");
		let surface = run.Surface;
		let idleInput = scope InputFacade(null);
		let idleSave = scope SaveFacade(null);
		// What the application does: bind the surface and install the idle services first.
		delete run.Instance.RunHost.Configure;
		run.Instance.RunHost.Configure = new [=](runtime) =>
			{
				runtime.Bind(surface);
				ClearAndDeleteItems!(runtime.Problems);
				runtime.SetService(idleInput);
				runtime.SetService(idleSave);
			};

		Test.Assert(!run.Instance.ScriptRunning);
		let runtime = run.Instance.RunHost.EnsureRuntime(AngelScriptBackend.cLanguage);
		Test.Assert(runtime != null);
		let context = runtime.Context;
		Test.Assert(context.FindService(typeof(InputFacade)) === run.Instance.[Friend]mInputFacade, "the run's Input");
		Test.Assert(context.FindService(typeof(SaveFacade)) === run.Instance.[Friend]mSaveFacade, "the run's Save");
		Test.Assert(context.FindService(typeof(GameInstance)) === run.Instance, "and Run");
	}
}
