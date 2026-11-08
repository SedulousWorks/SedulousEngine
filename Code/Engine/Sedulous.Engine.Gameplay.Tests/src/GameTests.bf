using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Run;
using Sedulous.Runtime;
using Sedulous.Scene;
using Sedulous.Engine.Composition;
using Sedulous.Engine.GameInstance;
using Sedulous.Engine.Gameplay;

namespace Sedulous.Engine.Gameplay.Tests;

/// A game that logs each hook into GameLog as "<call> ", listens for doors from its launch,
/// sums its updates' deltas, and saves the doors it heard as it exits.
class ProbeGame : Game
{
	private float mElapsed = 0.0f;
	private int32 mDoors = 0;

	protected override void OnLaunch()
	{
		GameLog.Text.Append("Launch ");
		GameLog.Listening = Listen<DoorOpened>(new [=this] (evt) =>
			{
				mDoors += evt.Door;
				GameLog.Text.AppendF("Door{} ", evt.Door);
			});
		GameLog.Launched = this;
	}

	protected override void OnUpdate(float dt)
	{
		mElapsed += dt;
		GameLog.Elapsed = mElapsed;
	}

	protected override void OnSceneActivated(Scene scene)
	{
		GameLog.Text.AppendF("Scene:{} ", scene.Name);
	}

	protected override void OnExit()
	{
		GameLog.Text.Append("Exit ");
		Instance.Get<SaveFacade>().SetInt("game.doors", mDoors);
		GameLog.ListenedAtExit = Listen<CoinTaken>(new (evt) => {});
	}
}

/// A second game, which a build that has one already may not register.
class OtherGame : Game
{
}

/// What the probe game's hooks wrote.
static class GameLog
{
	public static String Text = new .() ~ delete _;
	public static float Elapsed = 0.0f;
	public static bool Listening = false;
	public static bool ListenedAtExit = false;
	/// BORROWED: the game last launched; compared, never read.
	public static ProbeGame Launched = null;

	public static void Reset()
	{
		Text.Clear();
		Elapsed = 0.0f;
		Listening = false;
		ListenedAtExit = false;
		Launched = null;
	}
}

/// A game's Engine part registering its game, and then another, as a build that has two would.
class GameProbePart : PluginPart
{
	public static bool FirstSet = false;
	public static bool SecondSet = true;

	public override StringView PluginId => "game_probe";
	public override PluginPartKind Kind => .Engine;

	public override void Load(PluginContext context)
	{
		let engine = context.Find<EnginePluginServices>();
		FirstSet = GameplayServices.SetGame<ProbeGame>(engine);
		SecondSet = GameplayServices.SetGame<OtherGame>(engine);
	}
}

/// The Game: registered through the engine's run listener, launched by its run, updated with the
/// delta the run's scale does not touch, told of each scene, and ended as the session stops,
/// before the run writes its save.
class GameTests
{
	private static String ProbeManifest()
	{
		let manifest = scope PluginManifest();
		manifest.Id.Set("game_probe");
		manifest.Version.Set("0.1.0");
		manifest.EngineVersion.Set("0.1");
		let part = new PluginManifestPart();
		part.Kind.Set("Engine");
		manifest.Parts.Add(part);
		let platform = new PluginPlatform();
		platform.Platform.Set(PluginHost.HostPlatform);
		manifest.Platforms.Add(platform);
		return manifest.Write(.. new .());
	}

	/// Through a plugin host: the part's game reaches the run made before it and the one made
	/// after; a second game is refused; the game runs a whole session; the unload takes the
	/// factory off the runs.
	[Test]
	public static void AGameRunsASessionOfItsRun()
	{
		GameLog.Reset();
		let scratch = "scratch_gameplay_game";
		RemoveDirectoryRecursive(scratch);
		defer RemoveDirectoryRecursive(scratch);
		let path = PathJoin(scratch, "save.xml", .. scope String());

		let instance = scope GameInstance();
		let later = scope GameInstance();
		let runs = scope RunRegistry();
		runs.Add(instance);
		let subsystems = scope SubsystemManager();
		subsystems.SetRunManager(runs);
		let engine = scope EnginePluginServices();
		let xml = ProbeManifest();
		defer delete xml;
		let probe = scope GameProbePart();
		{
			let host = scope PluginHost(subsystems, .Player, "0.1.0");
			Test.Assert(engine.Attach(host));
			PluginPart[1] parts = .(probe);
			Test.Assert(host.AddLinked(xml, parts) case .Ok);
			let report = scope PluginLoadReport();
			host.Load(scope StringView[]("game_probe"), report);
			Test.Assert(report.Loaded.Count == 1);

			Test.Assert(GameProbePart.FirstSet);
			Test.Assert(!GameProbePart.SecondSet, "one game per engine");
			let runner = engine.FindRunListener<GameRunner>();
			Test.Assert(runner != null);
			Test.Assert(runner.OfferCount == 1, "offered to the run made before it");
			runs.Add(later);
			Test.Assert(runner.OfferCount == 2, "and to the one made after");
			Test.Assert(later.Get<IGameFactory>() != null);

			// A session: launched, updated, told of its scene, then stopped.
			instance.SetSaveFile(path);
			Test.Assert(instance.LaunchGame());
			Test.Assert(GameLog.Text == "Launch ", GameLog.Text);
			Test.Assert(GameLog.Listening);
			Test.Assert((GameLog.Launched != null) && (GameLog.Launched.Instance === instance));
			Test.Assert((Object)GameLog.Launched.Run === instance);
			Test.Assert(GameLog.Launched.Running);
			Test.Assert((Object)instance.NativeGame === GameLog.Launched);
			Test.Assert(!instance.LaunchGame(), "one runs already");
			instance.Start();

			instance.InstanceTimeScale = 0.0f; // the game pauses its scenes; its own clock goes on
			instance.TickScript(0.5f, 1.0f);
			instance.TickScript(0.25f, 1.0f);
			Test.Assert(GameLog.Elapsed == 0.75f, scope $"{GameLog.Elapsed}");

			let scene = instance.CreateScene("arena");
			instance.SetScene(scene);
			Test.Assert(GameLog.Launched.CurrentScene === scene);
			GameEvents.Emit(instance, DoorOpened(2));
			GameEvents.Emit(instance, DoorOpened(3));
			Test.Assert(GameLog.Text == "Launch Scene:arena Door2 Door3 ", GameLog.Text);

			instance.Stop();
			Test.Assert(GameLog.Text == "Launch Scene:arena Door2 Door3 Exit ", GameLog.Text);
			Test.Assert(!GameLog.ListenedAtExit, "no new subscription from its exit");
			Test.Assert(!instance.HasNativeGame && (instance.Get<IGameHooks>() == null), "the session's stop deletes it");
			GameLog.Launched = null;
			GameEvents.Emit(instance, DoorOpened(4));
			Test.Assert(GameLog.Text == "Launch Scene:arena Door2 Door3 Exit ", "its subscription ended with it");

			let reread = scope RunSave();
			reread.Open(path);
			Test.Assert(reread.Values.GetInt("game.doors", 0) == 5, "what its exit saved was written");

			host.Unload();
			Test.Assert(engine.FindRunListener<GameRunner>() == null);
			Test.Assert((instance.Get<IGameFactory>() == null) && (later.Get<IGameFactory>() == null), "the unload takes the factory off the runs");
			Test.Assert(!instance.LaunchGame(), "no game registered: nothing launches");
		}
	}

	/// Without the engine's service, or in a host without runs, SetGame adds nothing.
	[Test]
	public static void SetGameNeedsAnEngineWithRuns()
	{
		Test.Assert(!GameplayServices.SetGame<ProbeGame>(null));

		let subsystems = scope SubsystemManager();
		let engine = scope EnginePluginServices();
		let host = scope PluginHost(subsystems, .Player, "0.1.0");
		Test.Assert(engine.Attach(host));
		Test.Assert(!GameplayServices.SetGame<ProbeGame>(engine), "no runs to hear");
		Test.Assert(engine.FindRunListener<GameRunner>() == null);
	}
}
