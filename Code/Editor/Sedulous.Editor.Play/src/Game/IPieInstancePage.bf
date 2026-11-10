using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Input;
using Sedulous.Editor.Scene;

namespace Sedulous.Editor.Play;

/// What one play-in-editor instance, a Game tab, lets the PIE tools act through: beyond what
/// the scene tools read (IGameScenePage: its id, whether it runs and its scene), its run's start
/// and stop, the state of the run, a capture of what it renders, scripted input in place of the
/// viewport's, and the resolution it draws at. The Game page implements it; a module reaches it
/// with `page as IPieInstancePage`.
interface IPieInstancePage : IGameScenePage
{
	/// Asks for a cook and starts the run once the cook is idle; nothing while running.
	void Play();
	/// Stops the run; the tab stays open.
	void Stop();

	/// Play was asked for and the run waits on the cook.
	bool IsStarting { get; }
	/// The scene the run is in, empty when it has none (a game that owns boot, between
	/// levels).
	StringView SceneName { get; }
	/// Seconds of frames since the run started, unscaled: it keeps going while the game has
	/// its scene paused at time scale 0 (behind a menu, which still works). Scripted input is
	/// timed by it.
	double RunTime { get; }
	/// Frames rendered since the run started.
	uint64 FrameCount { get; }

	/// Asks for the viewport's next rendered frame, after the game's own UI and overlays,
	/// as a PNG at `path` (its directory must exist), replacing a pending request.
	void RequestViewportCapture(StringView path);
	/// The latest request's state, as it advances frame by frame. BORROWED.
	ViewportCapture LastViewportCapture { get; }

	/// The class name of the run's native game (the build's Game, launched by the run),
	/// appended to `outTypeName`; false when none runs: a build without one, or the run
	/// stopped.
	bool GetNativeGame(String outTypeName);
	/// A field of the running native game, read by reflection: `path` names a field of its
	/// class, public or private ([Game] reflects them all), then keys and indices inside it
	/// ("mSpawn.y"), the value as entity_inspect writes a field. OWNED; null with the reason in
	/// `outError`.
	JsonValue GetGameField(StringView path, String outError);
	/// A field of the running scene's active native Level, read as GetGameField reads the
	/// game's: "<field>" while one level is active, "<Level>.<field>" (its class name or level
	/// id) to name one. OWNED; null with the reason in `outError`, or null with `outError` left
	/// empty when the scene has no native level active.
	JsonValue GetLevelField(StringView path, String outError);

	/// Plays `source` into this instance in place of the viewport's input, its time zero now:
	/// the page advances it each frame by the run's time. OWNERSHIP transfers; a script
	/// already playing is dropped.
	void BeginScriptedInput(ScriptedInputSource source);
	/// Ends the script: one frame letting go of everything it holds, then the viewport's input
	/// returns. A stop ends it at once.
	void EndScriptedInput();
	/// A script is installed (until the viewport's input is back).
	bool IsScripted { get; }

	/// The resolutions the tab's dropdown offers, in its order, fresh (an export preset or a
	/// preview resolution added since shows). BORROWED: the page's own list.
	List<GameResolutionChoice> ResolutionChoices();
	/// The chosen one's key.
	StringView ResolutionKey { get; }
	/// Chooses the entry with this key as the dropdown does: shown there, kept for the
	/// project, applied at once. False when no entry has it.
	bool SelectResolution(StringView key);
	/// The tab previews a phone held upright (its Phone toggle).
	bool PhonePreview { get; }
	/// Sets the Phone toggle as a click does: shown, kept for the project, applied at once.
	void SelectPhonePreview(bool on);
}
