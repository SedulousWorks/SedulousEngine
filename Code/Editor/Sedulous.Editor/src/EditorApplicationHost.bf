namespace Sedulous.Editor;

using System;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.RuntimeGraphics;
using Sedulous.Platform;
using Sedulous.Platform.Input;
using Sedulous.Editor.Core;

/// IApplicationHost adapter for the editor.
///
/// EditorApplication itself can't implement IApplicationHost directly
/// because IApplication and IApplicationHost are distinct roles: the
/// editor IS the application, but project modules need a host that
/// routes Context to the EMBEDDED runtime Context (not the
/// ApplicationHost's own). The adapter pulls everything from the editor
/// instance while routing IApplicationHost.Ctx to
/// EditorApplication.RuntimeContext.
///
/// Input is routed through viewport-scoped adapters when a game page is
/// running, so cursor coords land in the page-viewport's local space and
/// keyboard/gamepad gate on viewport focus.
class EditorApplicationHost : Sedulous.Runtime.Client.IApplicationHost
{
	private EditorApplication mEditor;

	public this(EditorApplication editor)
	{
		mEditor = editor;
	}

	public Context Ctx => mEditor.RuntimeContext;
	public IPlatform Platform => mEditor.Platform;

	// The editor's GraphicsDevice is available now (passed through
	// from the outer ApplicationHost). Returning null is still safe
	// for modules that don't touch Graphics directly when hosted by
	// the editor - they render into the GameEditorPage's viewport
	// texture, not a swapchain. But providing it means
	// DefaultApplication.Configure can read Raw for subsystem init.
	public GraphicsDevice Graphics => null;

	public StringView BuiltInAssetDirectory => mEditor.BuiltInAssetDirectory;
	public StringView AssetCacheDirectory => mEditor.AssetCacheDirectory;
	// Dynamic - reads from the live EditorProject so it reflects late project opens.
	public StringView ProjectAssetDirectory => mEditor.ProjectAssetDirectory;
	public StringView RuntimeDirectory => mEditor.RuntimeDirectory;

	// No main RenderWindow in the editor -- the module's scene renders
	// into the GameEditorPage's viewport texture, not a swapchain.
	public RenderWindow MainWindow => null;

	// --- Scoped input ---
	// When a GameEditorPage is running, the module reads through that
	// page's viewport-scoped adapters -- cursor coords land in the page
	// texture's local space and keyboard / gamepad gate on whether the
	// Game tab is the active editor page. With no running game (idle
	// editor, asset-only project), falls back to direct platform devices.

	public IMouse Mouse
	{
		get
		{
			let page = mEditor.RunningGamePage;
			if (page?.MouseAdapter != null) return page.MouseAdapter;
			return mEditor.Platform?.InputManager?.Mouse;
		}
	}

	public IKeyboard Keyboard
	{
		get
		{
			let page = mEditor.RunningGamePage;
			if (page?.KeyboardAdapter != null) return page.KeyboardAdapter;
			return mEditor.Platform?.InputManager?.Keyboard;
		}
	}

	public IGamepad GetGamepad(int32 index)
	{
		let page = mEditor.RunningGamePage;
		let adapter = page?.GetGamepadAdapter(index);
		if (adapter != null) return adapter;
		return mEditor.Platform?.InputManager?.GetGamepad(index);
	}

	// Window creation not supported in the editor host.
	public RenderWindow OpenWindow(WindowSettings settings, RenderWindowDesc renderDesc) => null;

	// Window close is a no-op.
	public void CloseWindow(RenderWindow window) {}

	public void RequestExit(int32 code = 0)
	{
		// In the editor, "exit" means stop the play session. Deferred
		// to the end of the frame so the module's UI event handlers
		// finish before the view tree is torn down.
		let page = mEditor.RunningGamePage;
		if (page != null)
			page.RequestStop();
	}
}
