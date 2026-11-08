using System;
using Sedulous.Run;
using Sedulous.Script.Resource;
using Sedulous.Engine.DefaultApp;
using Sedulous.Engine.GameInstance;

namespace Sedulous.Engine.DefaultApp.Tests;

/// A native game that counts its launches and exits into its factory.
class LaunchProbeGame : IGameHooks
{
	/// BORROWED: the factory that made it, declared before the app, so it outlives every game.
	public LaunchProbeFactory Factory;

	public void Launch()
	{
		Factory.Launched++;
	}

	public void Update(float dt) {}
	public void SceneActivated(Sedulous.Scene.Scene scene) {}

	public void Exit()
	{
		Factory.Exited++;
	}
}

/// What the primary run's launch asks, standing in for a build's registered game.
class LaunchProbeFactory : IGameFactory
{
	public int Launched = 0;
	public int Exited = 0;

	public IGameHooks CreateGame(GameInstance instance)
	{
		let game = new LaunchProbeGame();
		game.Factory = this;
		return game;
	}
}

/// The player's launch of its game (DefaultApplication.LaunchGame): the native game when the build
/// registered one, a startup script beside it never resolved; otherwise the startup script,
/// resolved only when the project names one. GameRunning is a game of either kind.
class GameLaunchTests
{
	[Test]
	public static void TheNativeGameRunsAndAStartupScriptBesideItIsNeverResolved()
	{
		let factory = scope LaunchProbeFactory();
		let host = scope StubHost();
		let app = scope DefaultApplication();
		app.Configure(host);
		host.Subsystems.Startup();
		app.OnStartup(host);

		int resolved = 0;
		delegate ScriptClass() resolve = scope [&resolved] () =>
			{
				resolved++;
				return null;
			};

		// No native game: the script is resolved only when the project names one, and one that
		// does not resolve leaves nothing running.
		app.Instance.Start();
		Test.Assert(!app.LaunchGame(false, resolve));
		Test.Assert(resolved == 0, "no script named, none resolved");
		Test.Assert(!app.LaunchGame(true, resolve));
		Test.Assert(resolved == 1, "a script named is resolved");
		Test.Assert(!app.GameRunning);
		app.Instance.Stop();

		// A native game: it runs, the named script is never resolved.
		app.Instance.Register<IGameFactory>(factory);
		app.Instance.Start();
		Test.Assert(app.LaunchGame(true, resolve));
		Test.Assert(resolved == 1, "the native game wins: the script is not resolved");
		Test.Assert(factory.Launched == 1);
		Test.Assert(app.GameRunning && app.Instance.HasNativeGame && !app.Instance.ScriptRunning);
		app.Instance.Stop();
		Test.Assert(factory.Exited == 1, "the session's stop ends it");
		Test.Assert(!app.GameRunning);

		host.Subsystems.Shutdown();
		app.OnShutdown(host);
		host.Subsystems.Dispose();
	}
}
