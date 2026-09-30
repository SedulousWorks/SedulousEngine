using System;
using Sedulous.Core;

namespace Sedulous.Editor.Scene;

/// Where a PIE instance's startup script stands.
enum PieScriptState
{
	/// The project has no startup script, or the run has not started one.
	None,
	Running,
	/// It stopped on its own: a fault in one of its calls, or it did not instantiate.
	/// IPieInstancePage.ScriptFault says which.
	Faulted
}

/// What one play-in-editor instance, a Game tab, lets the PIE tools act through: its id, its
/// run's start and stop, the state of the run, and a capture of what it renders. The Game page
/// implements it; a module reaches it with `page as IPieInstancePage`.
interface IPieInstancePage
{
	/// The tab's id: `game-page` for the primary, `game-page-1`, `game-page-2`, ... for the
	/// instances Play New Instance opens. The dock persists the tab under it too.
	StringView PieId { get; }

	/// Asks for a cook and starts the run once the cook is idle; nothing while running.
	void Play();
	/// Stops the run; the tab stays open.
	void Stop();

	/// A run is going.
	bool IsRunning { get; }
	/// Play was asked for and the run waits on the cook.
	bool IsStarting { get; }
	/// The scene the run is in, empty when it has none (a script that owns boot, between
	/// levels).
	StringView SceneName { get; }
	/// Gameplay seconds since the run started, the clock the game script moves by.
	double GameTime { get; }
	/// Frames rendered since the run started.
	uint64 FrameCount { get; }
	/// The startup script's state, and the reason a faulted one stopped.
	PieScriptState ScriptState { get; }
	StringView ScriptFault { get; }

	/// Asks for the viewport's next rendered frame, after the game's own UI and overlays,
	/// as a PNG at `path` (its directory must exist), replacing a pending request.
	void RequestViewportCapture(StringView path);
	/// The latest request's state, as it advances frame by frame. BORROWED.
	ViewportCapture LastViewportCapture { get; }
}
