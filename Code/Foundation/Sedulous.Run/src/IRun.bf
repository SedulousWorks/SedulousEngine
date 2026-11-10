using System;
using Sedulous.Messaging;

namespace Sedulous.Run;

/// A run's id: never reused in the process; nought is no run.
typealias RunId = uint64;

enum RunState : uint8
{
	/// Made, or between sessions.
	Idle,
	/// A session is playing.
	Running,
	/// The host paused it (the toolbar, a debugger break): not the game's own pause.
	Paused,
	/// A session is ending: its services' and listeners' stop hooks are running.
	Stopping,
	/// Gone; nothing reaches it after its destruction is announced.
	Disposed,
}

/// What a run's lifecycle is told to: a subsystem keeping per-run state (through the run
/// manager), and the run manager itself (from each run).
interface IRunListener
{
	void OnRunCreated(IRun run) {}
	void OnRunStarted(IRun run) {}
	void OnRunPaused(IRun run, bool paused) {}
	void OnRunStopping(IRun run) {}
	void OnRunDestroyed(IRun run) {}
	void OnFocusChanged(IRun focused) {}
}

/// A service a run holds may implement this to hear its run pause and stop (in reverse order of
/// registration).
interface IRunService
{
	void OnRunPaused(IRun run, bool paused) {}
	void OnRunStopping(IRun run) {}
}

/// A running game, however it is implemented: a player's game, each editor Game tab's game, an
/// in-editor dedicated server. Its id, name, state, event bus, and the services it holds by type.
///
/// A run is not a scheduler: it holds services and runs their lifecycle hooks; its owner ticks
/// what it ticks. Plays are sessions inside a run: Idle, Running and Paused, Stopping, Idle again,
/// as many times as the host plays, then Disposed.
interface IRun
{
	RunId Id { get; }
	StringView Name { get; }
	RunState State { get; }
	/// The run's event bus: its scenes' and its game code's. BORROWED.
	EventBus Events { get; }
	/// The service of exactly `type` the run holds, or null. BORROWED.
	Object FindService(Type type);
}


/// The live runs, the focused one, and every run's lifecycle announced.
interface IRunManager
{
	void ForEachRun(delegate void(IRun run) visit);
	IRun Find(RunId id);
	/// The run the user is playing; null is no preference.
	IRun Focused { get; }
	void SetFocused(IRun run);
	/// A listener subscribing after runs exist finds them with ForEachRun. BORROWED.
	void Subscribe(IRunListener listener);
	void Unsubscribe(IRunListener listener);
}

/// The typed lookups over IRun.FindService.
static class RunServices
{
	/// The service of type `T` the run holds, or null.
	public static T Get<T>(IRun run) where T : class => (run != null) ? (T)run.FindService(typeof(T)) : null;
	public static bool Has<T>(IRun run) where T : class => (run != null) && (run.FindService(typeof(T)) != null);
}
