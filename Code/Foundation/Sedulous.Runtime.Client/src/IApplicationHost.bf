using System;
using Sedulous.RuntimeGraphics;
using Sedulous.Shell;
using Sedulous.Shell.Input;
using Sedulous.Runtime;

namespace Sedulous.Runtime.Client;

/// The host as seen by the application: register subsystems via Ctx, reach
/// platform/graphics services, manage runtime windows, request exit.
/// Implemented by ApplicationHost (and by the editor for its embedded runtime).
public interface IApplicationHost
{
	/// The subsystem container. Register subsystems here in Configure().
	Context Ctx { get; }

	/// The platform shell (windowing, input, clipboard).
	IShell Shell { get; }

	/// The shared GPU device (null for headless runs).
	GraphicsDevice Graphics { get; }

	/// The main window (created during Start). Null for headless runs.
	RenderWindow MainWindow { get; }

	/// Mouse the module should consume during OnUpdate. Standalone hosts
	/// passthrough to Shell.InputManager.Mouse. The editor's
	/// GameEditorPage returns a viewport-scoped adapter so cursor
	/// coords are in the page-viewport's local space and click events
	/// match the rendered scene.
	IMouse Mouse { get => Shell?.InputManager?.Mouse; }

	/// Keyboard the module should consume during OnUpdate. Standalone
	/// hosts passthrough to Shell.InputManager.Keyboard. The editor's
	/// GameEditorPage returns a focus-gated adapter that reports
	/// "nothing pressed" while the game viewport is not focused.
	IKeyboard Keyboard { get => Shell?.InputManager?.Keyboard; }

	/// Returns a gamepad the module can consume during OnUpdate.
	/// Standalone passes through to Shell.InputManager.GetGamepad.
	/// Editor returns a focus-gated adapter. Returns null if index
	/// is out of range.
	IGamepad GetGamepad(int32 index) => Shell?.InputManager?.GetGamepad(index);

	/// Engine built-in assets directory (shaders, fonts, default meshes).
	/// Discovered by walking up from cwd looking for Assets/.assets marker.
	StringView BuiltInAssetDirectory { get; }

	/// Asset cache directory (shader cache, thumbnails).
	StringView AssetCacheDirectory { get; }

	/// Per-project assets directory. Standalone hosts derive this from
	/// the working directory convention (<parent of cwd>/assets). The
	/// editor returns the currently open project's directory. Empty
	/// when no project convention applies or no project is loaded.
	StringView ProjectAssetDirectory { get; }

	/// Working directory at startup.
	StringView RuntimeDirectory { get; }

	/// Open an OS window at runtime backed by a RenderWindow.
	/// Returns null when running headless (no graphics).
	RenderWindow OpenWindow(WindowSettings settings, RenderWindowDesc renderDesc);

	/// Close a window (deferred to frame end).
	void CloseWindow(RenderWindow window);

	/// Request the host to exit. Standalone exits the process; editor stops the play session.
	void RequestExit(int32 code = 0);
}
