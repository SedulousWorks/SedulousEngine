using System;
using Sedulous.Run;
using Sedulous.Scene;
using Sedulous.Engine.GameInstance;
using Sedulous.Engine.Gameplay;

namespace Sedulous.Engine.Gameplay.Tests;

/// A native game that writes the scenes it is told of into its factory's log.
class LoadWatchGame : IGameHooks
{
	/// BORROWED: the factory's log, which outlives every game.
	public String Log;

	public void Launch() {}
	public void Update(float dt) {}
	public void SceneActivated(Scene scene) { Log.AppendF("scene:{} ", scene.Name); }
	public void Exit() {}
}

/// Makes a LoadWatchGame for each launch, all writing one log.
class LoadWatchFactory : IGameFactory
{
	public String Log = new .() ~ delete _;

	public IGameHooks CreateGame(GameInstance instance)
	{
		let game = new LoadWatchGame();
		game.Log = Log;
		return game;
	}
}

/// The next level asked for, as a behaviour or the game hears it.
struct NextLevelRequested
{
	public int32 Level;

	public this(int32 level)
	{
		Level = level;
	}
}

/// A game that logs the scenes it is told of as "Scene:<name> " and, when LoadOnRequest is set
/// at its launch, loads the next level from its own handler, recording what was current as the
/// call returned.
[Game]
class SwitchGame : Game
{
	public static String Log = new .() ~ delete _;
	public static bool LoadOnRequest = false;
	public static bool Loaded = false;
	public static bool NewSceneAtReturn = false;

	public static void Reset()
	{
		Log.Clear();
		LoadOnRequest = false;
		Loaded = false;
		NewSceneAtReturn = false;
	}

	public static Game Create() => new SwitchGame();

	protected override void OnLaunch()
	{
		if (!LoadOnRequest)
			return;
		Listen<NextLevelRequested>(new [=this] (evt) =>
			{
				Loaded = Instance.LoadScene(Guid.Create());
				NewSceneAtReturn = (CurrentScene != null) && (CurrentScene.Name == "next");
			});
	}

	protected override void OnSceneActivated(Scene scene)
	{
		Log.AppendF("Scene:{} ", scene.Name);
	}
}

/// A level load asked for by a scene's own code, a behaviour or a level, from its update or its
/// fixed step: the scene that asked finishes its frame, and the new scene replaces it at the
/// host's next PumpLoads, the game told once.
class SceneLoadDeferralTests
{
	private const float cDt = 1.0f / 60.0f;

	/// Who asks for the load, and from which tick.
	private enum Asker
	{
		BehaviourUpdate,
		BehaviourFixed,
		LevelUpdate,
		LevelFixed
	}

	/// The run's scene ticks of one host frame: the fixed step, then the update.
	private static void TickScenes(GameInstance instance)
	{
		let time = FrameTime(cDt, 1.0f, 1.0f, 1.0f, cDt); // one fixed step a frame
		instance.Scenes.BeginFrame(time);
		instance.Scenes.Update(time);
	}

	private static void LoadFromInsideTheScene(Asker asker)
	{
		LifecycleLog.Text.Clear();
		// Before the instance, so they outlive it: the group borrows the installer, and the game
		// writes the factory's log as the instance ends it.
		delegate void(Scene) installer = scope (scene) =>
			{
				scene.AddSystem<BehaviourSystem>();
				scene.AddSystem<BehaviourManager<Walker>>();
				scene.AddSystem<Gauntlet>();
			};
		let factory = scope LoadWatchFactory();
		let instance = scope GameInstance();
		instance.Scenes.SetSceneInstaller(installer);
		instance.Register<IGameFactory>(factory);
		// The level a load names: a fresh, inactive scene of the run, complete at once (no
		// resources to wait on).
		instance.SetSceneLoader(new [&] (sceneId) =>
			{
				var handle = SceneLoadHandle();
				handle.Scene = instance.CreateScene("next", false);
				return handle;
			});
		instance.SetSceneActivationPolicy(new (scene) =>
			{
				scene.Start();
				scene.SetSimulationEnabled(true);
			});

		let old = instance.CreateScene("old");
		old.GetSystem<BehaviourManager<Walker>>().Add(old.CreateEntity("e"));
		old.GetSystem<Gauntlet>().Active = true;
		old.Start();
		instance.SetScene(old);
		Test.Assert(instance.LaunchGame());

		// The first frame starts the behaviour and the level.
		TickScenes(instance);
		instance.PumpLoads();

		let target = Guid.Create();
		bool fired = false;
		bool loaded = false;
		bool currentAtCall = false;
		delegate void(IRun run) ask = scope [&] (run) =>
			{
				if (fired)
					return;
				fired = true;
				loaded = RunServices.Get<GameInstance>(run).LoadScene(target);
				currentAtCall = instance.CurrentScene === old;
			};
		delegate void(Walker walker) fromWalker = scope [&] (walker) => ask(walker.Run);
		delegate void(Gauntlet level) fromLevel = scope [&] (level) => ask(level.Run);
		switch (asker)
		{
		case .BehaviourUpdate: Walker.UpdateHook = fromWalker;
		case .BehaviourFixed: Walker.FixedHook = fromWalker;
		case .LevelUpdate: Gauntlet.UpdateHook = fromLevel;
		case .LevelFixed: Gauntlet.FixedHook = fromLevel;
		}
		defer
		{
			Walker.UpdateHook = null;
			Walker.FixedHook = null;
			Gauntlet.UpdateHook = null;
			Gauntlet.FixedHook = null;
		}

		LifecycleLog.Text.Clear();
		TickScenes(instance);
		Test.Assert(fired, "the hook ran");
		Test.Assert(loaded, "the load started");
		Test.Assert(currentAtCall, "the old scene is still current inside the call");
		Test.Assert(LifecycleLog.Text == "G.Fixed W:e.Fixed G.Update W:e.Update W:e.Late ", LifecycleLog.Text);
		Test.Assert(instance.CurrentScene === old, "the old scene finished its frame");
		Test.Assert(instance.Scenes.SceneCount == 2, "the new scene waits, inactive");
		Test.Assert(factory.Log.IsEmpty, factory.Log);

		instance.PumpLoads();
		let current = instance.CurrentScene;
		Test.Assert((current != null) && (current !== old) && (current.Name == "next"), "the new scene is current");
		Test.Assert(instance.Scenes.IsActive(current) && current.IsStarted, "activated by the policy");
		Test.Assert(instance.Scenes.SceneCount == 1, "the old scene is gone");
		Test.Assert(factory.Log == "scene:next ", factory.Log);

		// Nothing more to finish: the next frame and pump tell the game nothing again.
		TickScenes(instance);
		instance.PumpLoads();
		Test.Assert(factory.Log == "scene:next ", "told once");
		Test.Assert(instance.CurrentScene === current);
	}

	[Test]
	public static void ABehavioursLoadFromItsUpdateWaitsForTheFrame() => LoadFromInsideTheScene(.BehaviourUpdate);

	[Test]
	public static void ABehavioursLoadFromItsFixedStepWaitsForTheFrame() => LoadFromInsideTheScene(.BehaviourFixed);

	[Test]
	public static void ALevelsLoadFromItsUpdateWaitsForTheFrame() => LoadFromInsideTheScene(.LevelUpdate);

	[Test]
	public static void ALevelsLoadFromItsFixedStepWaitsForTheFrame() => LoadFromInsideTheScene(.LevelFixed);

	/// Outside a scene's tick (a game's launch, a tool) the load is immediate, as it was: the
	/// new scene is current when the call returns.
	[Test]
	public static void ALoadOutsideATickIsImmediate()
	{
		delegate void(Scene) installer = scope (scene) => { scene.AddSystem<BehaviourSystem>(); };
		let factory = scope LoadWatchFactory();
		let instance = scope GameInstance();
		instance.Scenes.SetSceneInstaller(installer);
		instance.Register<IGameFactory>(factory);
		instance.SetSceneLoader(new [&] (sceneId) =>
			{
				var handle = SceneLoadHandle();
				handle.Scene = instance.CreateScene("next", false);
				return handle;
			});
		let old = instance.CreateScene("old");
		instance.SetScene(old);
		Test.Assert(instance.LaunchGame());

		Test.Assert(instance.LoadScene(Guid.Create()));
		Test.Assert((instance.CurrentScene != null) && (instance.CurrentScene.Name == "next"));
		Test.Assert(instance.Scenes.SceneCount == 1, "the old scene destroyed at once");
		Test.Assert(factory.Log == "scene:next ", factory.Log);
	}

	// ---- from a handler, outside the scenes' tick ----

	/// How the event reaches the behaviour's handler.
	private enum Deliverer
	{
		RunDrain,
		GameEmit
	}

	/// A run whose game is a SwitchGame, with an "old" scene current holding a walker on "e",
	/// started by one frame; `onStart` runs from the walker's OnStart. The caller declares
	/// `installer` and `runner` before `instance`, so they outlive it.
	private static Scene StartSwitchRun(GameInstance instance, delegate void(Scene) installer,
		GameRunner runner, delegate void(Walker walker) onStart)
	{
		instance.Scenes.SetSceneInstaller(installer);
		instance.Register<IGameFactory>(runner);
		instance.SetSceneLoader(new [=instance] (sceneId) =>
			{
				var handle = SceneLoadHandle();
				handle.Scene = instance.CreateScene("next", false);
				return handle;
			});
		instance.SetSceneActivationPolicy(new (scene) =>
			{
				scene.Start();
				scene.SetSimulationEnabled(true);
			});

		let old = instance.CreateScene("old");
		old.GetSystem<BehaviourManager<Walker>>().Add(old.CreateEntity("e"));
		old.Start();
		instance.SetScene(old);
		Test.Assert(instance.LaunchGame());

		Walker.StartHook = onStart;
		TickScenes(instance);
		instance.PumpLoads();
		Walker.StartHook = null;
		return old;
	}

	/// A behaviour's run event handler, delivered outside the scenes' tick (the run's drain, or
	/// the game's Emit), loading a level: the load defers to the next PumpLoads, so the scene
	/// and the behaviour whose handler asked are not destroyed under it, and the game hears the
	/// new scene once.
	private static void BehaviourHandlerLoads(Deliverer deliverer)
	{
		SwitchGame.Reset();
		LifecycleLog.Text.Clear();
		delegate void(Scene) installer = scope (scene) =>
			{
				scene.AddSystem<BehaviourSystem>();
				scene.AddSystem<BehaviourManager<Walker>>();
			};
		let runner = scope GameRunner(=> SwitchGame.Create);
		let instance = scope GameInstance();

		bool loaded = false;
		bool oldAtReturn = false;
		bool codeRunningInside = false;
		Scene old = null;
		delegate void(Walker walker) subscribe = scope [&] (walker) =>
			{
				let listening = walker.Listen<NextLevelRequested>(new [&] (evt) =>
					{
						codeRunningInside = instance.SceneCodeRunning;
						loaded = instance.LoadScene(Guid.Create());
						oldAtReturn = instance.CurrentScene === old;
					});
				Test.Assert(listening);
			};
		old = StartSwitchRun(instance, installer, runner, subscribe);
		Test.Assert(!instance.SceneCodeRunning);

		switch (deliverer)
		{
		case .RunDrain:
			GameEvents.Post<NextLevelRequested>(instance, NextLevelRequested(1));
			instance.DrainRunEvents();
		case .GameEmit:
			let game = instance.NativeGame as SwitchGame;
			Test.Assert(game != null);
			game.Emit<NextLevelRequested>(NextLevelRequested(1));
		}
		Test.Assert(codeRunningInside, "the handler runs as its scene's code");
		Test.Assert(loaded, "the load started");
		Test.Assert(oldAtReturn, "the old scene is still current as the call returns");
		Test.Assert(!instance.SceneCodeRunning, "the mark ends with the handler");
		Test.Assert((instance.CurrentScene === old) && (instance.Scenes.SceneCount == 2), "the new scene waits, inactive");
		Test.Assert(SwitchGame.Log.IsEmpty, SwitchGame.Log);

		instance.PumpLoads();
		let current = instance.CurrentScene;
		Test.Assert((current != null) && (current.Name == "next"), "the new scene is current");
		Test.Assert(instance.Scenes.SceneCount == 1, "the old scene is gone");
		Test.Assert(SwitchGame.Log == "Scene:next ", SwitchGame.Log);

		TickScenes(instance);
		instance.PumpLoads();
		Test.Assert(SwitchGame.Log == "Scene:next ", "told once");
	}

	[Test]
	public static void ABehavioursHandlerLoadFromTheRunsDrainWaitsForThePump() => BehaviourHandlerLoads(.RunDrain);

	[Test]
	public static void ABehavioursHandlerLoadFromTheGamesEmitWaitsForThePump() => BehaviourHandlerLoads(.GameEmit);

	/// The game's own handler is not scene code: its load is immediate, and it reads the new
	/// scene as the call returns.
	[Test]
	public static void AGameHandlersLoadIsImmediate()
	{
		SwitchGame.Reset();
		SwitchGame.LoadOnRequest = true;
		defer SwitchGame.Reset();
		delegate void(Scene) installer = scope (scene) =>
			{
				scene.AddSystem<BehaviourSystem>();
				scene.AddSystem<BehaviourManager<Walker>>();
			};
		let runner = scope GameRunner(=> SwitchGame.Create);
		let instance = scope GameInstance();
		delegate void(Walker walker) nothing = scope (walker) => {};
		let old = StartSwitchRun(instance, installer, runner, nothing);

		GameEvents.Post<NextLevelRequested>(instance, NextLevelRequested(1));
		instance.DrainRunEvents();
		Test.Assert(SwitchGame.Loaded);
		Test.Assert(SwitchGame.NewSceneAtReturn, "the new scene is current as the call returns");
		Test.Assert((instance.CurrentScene !== old) && (instance.Scenes.SceneCount == 1));
		Test.Assert(SwitchGame.Log == "Scene:next ", SwitchGame.Log);
	}
}
