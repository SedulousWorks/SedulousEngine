using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Engine.GameInstance;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Engine.GameInstance.Tests;

/// A native game that writes what the run tells it into its factory's record.
class ProbeGame : IGameHooks
{
	/// BORROWED: the factory that made it, which the tests declare before the run, so it
	/// outlives every game.
	public ProbeGameFactory Factory;
	public GameInstance Instance;

	public ~this()
	{
		Factory.Deleted++;
	}

	public void Launch()
	{
		Factory.Log.Append("launch ");
	}

	public void Update(float dt)
	{
		Factory.Updates++;
		Factory.LastDelta = dt;
	}

	public void SceneActivated(Scene scene)
	{
		Factory.Log.AppendF("scene:{} ", scene.Name);
		Factory.ScenesAtReport = Instance.Scenes.SceneCount;
		Factory.LastScene = scene;
	}

	/// Saves a value, as a game's exit does, when the factory says so.
	public void Exit()
	{
		Factory.Log.Append("exit ");
		if (Factory.SaveOnExit)
			Instance.Get<SaveFacade>().SetInt("exit.saved", 7);
	}
}

/// What a run's LaunchGame asks: a ProbeGame each time, and the record its games write.
class ProbeGameFactory : IGameFactory
{
	public String Log = new .() ~ delete _;
	public int Made = 0;
	public int Deleted = 0;
	public int Updates = 0;
	public float LastDelta = 0.0f;
	public int ScenesAtReport = 0;
	public bool SaveOnExit = false;
	/// BORROWED: the last game made, and the last scene reported; compared, never read.
	public ProbeGame Last = null;
	public Scene LastScene = null;

	public IGameHooks CreateGame(GameInstance instance)
	{
		Made++;
		let game = new ProbeGame();
		game.Factory = this;
		game.Instance = instance;
		Last = game;
		return game;
	}
}

/// A run's native game: LaunchGame makes it through the run's factory and holds it for the
/// session; the tick updates it, the scenes that become current are reported to it, and the
/// session's stop ends it before the save is written.
class NativeGameTests
{
	/// Without a factory nothing launches; with one, the game launches once, a second launch is
	/// refused while it runs, and the session's stop deletes it, so the next session makes a
	/// fresh one.
	[Test]
	public static void ALaunchHappensOnceAndASecondIsRefused()
	{
		let factory = scope ProbeGameFactory();
		let instance = scope GameInstance();

		Test.Assert(!instance.LaunchGame(), "no factory: nothing launched");
		Test.Assert(!instance.HasNativeGame && !instance.GameRunning);

		instance.Register<IGameFactory>(factory);
		Test.Assert(instance.LaunchGame());
		Test.Assert(factory.Made == 1);
		Test.Assert(factory.Log == "launch ", factory.Log);
		Test.Assert(instance.HasNativeGame && instance.GameRunning);
		Test.Assert((Object)instance.NativeGame === factory.Last);
		Test.Assert((Object)instance.Get<IGameHooks>() === factory.Last, "held as the run's service");

		Test.Assert(!instance.LaunchGame(), "one runs: refused");
		Test.Assert(factory.Made == 1);
		Test.Assert(factory.Log == "launch ", factory.Log);

		instance.Start();
		instance.Stop();
		Test.Assert(factory.Log == "launch exit ", factory.Log);
		Test.Assert(factory.Deleted == 1, "the session's stop deletes it");
		Test.Assert(!instance.HasNativeGame);
		Test.Assert(instance.Get<IGameHooks>() == null);

		Test.Assert(instance.LaunchGame(), "a new session launches a fresh game");
		Test.Assert(factory.Made == 2);
	}

	/// The update gets the host's delta through the context's scale and the scene's, never the
	/// run's own; the host's pause holds it.
	[Test]
	public static void TheUpdateTakesTheDeltaTheRunsScaleDoesNotTouch()
	{
		let factory = scope ProbeGameFactory();
		let instance = scope GameInstance();
		instance.Register<IGameFactory>(factory);
		instance.TickGame(0.25f, 1.0f);
		Test.Assert(factory.Updates == 0, "nothing launched, nothing updated");

		Test.Assert(instance.LaunchGame());
		instance.InstanceTimeScale = 0.0f; // the game's own pause of its scenes
		instance.TickGame(0.25f, 1.0f);
		Test.Assert(factory.Updates == 1);
		Test.Assert(factory.LastDelta == 0.25f, scope $"{factory.LastDelta}");
		instance.TickGame(0.25f, 2.0f);
		Test.Assert(factory.LastDelta == 0.5f, "the context's scale applies");

		let scene = instance.CreateScene("slow");
		scene.TimeScale = 0.5f;
		instance.SetScene(scene);
		instance.TickGame(0.25f, 1.0f);
		Test.Assert(factory.LastDelta == 0.125f, "and the current scene's");

		instance.Start();
		instance.SetPaused(true);
		instance.TickGame(0.25f, 1.0f);
		Test.Assert(factory.Updates == 3, "the host's pause holds it");
		instance.SetPaused(false);
		instance.TickGame(0.25f, 1.0f);
		Test.Assert(factory.Updates == 4);
	}

	/// SetScene reports a scene that was not current already, and only that.
	[Test]
	public static void SetSceneReportsANewCurrentScene()
	{
		let factory = scope ProbeGameFactory();
		let instance = scope GameInstance();
		instance.Register<IGameFactory>(factory);
		let first = instance.CreateScene("first");
		instance.SetScene(first);
		Test.Assert(factory.Log.IsEmpty, "no game, nobody told");

		Test.Assert(instance.LaunchGame());
		Test.Assert(factory.Log == "launch ", "a scene current before the launch is not reported");

		let second = instance.CreateScene("second");
		instance.SetScene(second);
		instance.SetScene(second);
		instance.SetScene(null);
		Test.Assert(factory.Log == "launch scene:second ", factory.Log);
		Test.Assert(factory.LastScene === second);
	}

	/// A tracked load reports its scene once activated: after the app's policy, with the scene
	/// it replaced destroyed.
	[Test]
	public static void ATrackedLoadReportsItsSceneAfterThePolicy()
	{
		let fixture = scope SceneContentFixture("scratch_gi_native_game_load");
		let level = fixture.Database.RootGroup.CreateInstance("level", SceneContentFixture.SceneTypeName);
		{
			let authored = scope Scene("level");
			authored.CreateEntity("a");
			Test.Assert(SceneStorage.SaveScene(authored, level) case .Ok);
		}
		let resources = scope ResourceManager(fixture.Database);

		let factory = scope ProbeGameFactory();
		let instance = scope GameInstance();
		instance.Register<IGameFactory>(factory);
		instance.SetSceneActivationPolicy(new [&] (scene) => { factory.Log.Append("policy "); });
		instance.SetScene(instance.CreateScene("old"));
		Test.Assert(instance.LaunchGame());

		let handle = instance.LoadSceneAsync(level, resources);
		Test.Assert(handle.Scene != null);
		let pending = handle.Scene;
		let ticket = instance.TrackLoad(handle);
		Test.Assert(factory.Log == "launch ", "not reported before it activates");

		instance.PumpLoads();
		Test.Assert(instance.LoadComplete(ticket));
		Test.Assert(factory.Log == "launch policy scene:level ", factory.Log);
		Test.Assert(factory.LastScene === pending);
		Test.Assert(factory.ScenesAtReport == 1, "the old scene is gone when the game hears");

		instance.PumpLoads();
		Test.Assert(factory.Log == "launch policy scene:level ", "once");
	}

	/// The session's stop runs the game's exit before the run writes its save: what the exit
	/// saved is in the file.
	[Test]
	public static void TheExitRunsBeforeTheSaveIsWritten()
	{
		let scratch = "scratch_gi_native_game_save";
		RemoveDirectoryRecursive(scratch);
		defer RemoveDirectoryRecursive(scratch);
		let path = PathJoin(scratch, "save.xml", .. scope String());

		let factory = scope ProbeGameFactory();
		factory.SaveOnExit = true;
		{
			let instance = scope GameInstance();
			instance.SetSaveFile(path);
			instance.Register<IGameFactory>(factory);
			Test.Assert(instance.LaunchGame());
			instance.Start();
			Test.Assert(!FileExists(path));
			instance.Stop();
			Test.Assert(factory.Log == "launch exit ", factory.Log);
			Test.Assert(FileExists(path), "written as the session stopped");
		}

		let reread = scope RunSave();
		reread.Open(path);
		Test.Assert(reread.Values.GetInt("exit.saved", 0) == 7, "what the exit saved was written");
	}

	/// A game launched outside a session ends by StopGame, or with its run: its exit runs and it
	/// is deleted, and a launch after StopGame makes a fresh one.
	[Test]
	public static void AGameOutsideASessionEndsByStopGameOrWithItsRun()
	{
		let factory = scope ProbeGameFactory();
		{
			let instance = scope GameInstance();
			instance.Register<IGameFactory>(factory);
			instance.StopGame(); // nothing runs: nothing happens
			Test.Assert(instance.LaunchGame());
			instance.StopGame();
			Test.Assert(factory.Log == "launch exit ", factory.Log);
			Test.Assert(factory.Deleted == 1);
			Test.Assert(!instance.HasNativeGame && (instance.Get<IGameHooks>() == null));
			instance.TickGame(0.25f, 1.0f);
			Test.Assert(factory.Updates == 0, "nothing updates a stopped game");

			Test.Assert(instance.LaunchGame());
			Test.Assert(factory.Made == 2);
		}
		Test.Assert(factory.Log == "launch exit launch exit ", factory.Log);
		Test.Assert(factory.Deleted == 2, "the run's end deletes it");
	}
}
