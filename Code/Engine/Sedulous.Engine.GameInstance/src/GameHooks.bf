using System;
using Sedulous.Scene;

namespace Sedulous.Engine.GameInstance;

/// What a run tells its native game: the game's own code compiled into the build (the
/// Gameplay library's Game). The run holds the game for the session and calls these; naming
/// only this interface keeps the run's library free of the game's.
///
/// The names are not the game's own hooks' (OnLaunch, OnUpdate, ...): a game implements these
/// explicitly and calls its hooks from them, so its own hooks stay protected and overridable.
interface IGameHooks
{
	/// Once, as LaunchGame takes the game.
	void Launch();
	/// Each frame TickScript runs, with the delta a game script's update(dt) gets: the host's
	/// through the context's and the current scene's scales, not the run's own
	/// (InstanceTimeScale), so a game that pauses its scenes keeps its own timers going.
	void Update(float dt);
	/// A scene became the run's current one: SetScene with another scene, or a tracked load
	/// activated, after the app's policy ran on it and the scene it replaced was destroyed.
	void SceneActivated(Scene scene);
	/// The game ends: its session stops, before the run's save is written and its networking
	/// closed, or StopGame ends it outside a session.
	void Exit();
}

/// Makes a run's native game. A run finds it among its services (the engine's game runner
/// registers itself on every run), and LaunchGame asks it.
interface IGameFactory
{
	/// A new game for `instance`, OWNED by the caller; null for none.
	IGameHooks CreateGame(GameInstance instance);
}
