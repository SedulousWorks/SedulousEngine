namespace Sedulous.Editor;

using System;
using Sedulous.Runtime;
using Sedulous.Resources;
using Sedulous.Shell;
using Sedulous.Shell.Input;
using Sedulous.Engine;

/// IApplicationHost adapter for the editor.
///
/// EditorApplication itself can't implement IApplicationHost directly:
/// its inherited Application.Context returns the editor's app-level
/// Context, but project modules need the EMBEDDED runtime Context where
/// their subsystems get registered. The adapter pulls everything from
/// the editor instance while routing IApplicationHost.Context to
/// EditorApplication.RuntimeContext.
class EditorApplicationHost : IApplicationHost
{
	private EditorApplication mEditor;

	public this(EditorApplication editor)
	{
		mEditor = editor;
	}

	public Context Context => mEditor.RuntimeContext;
	public ResourceSystem ResourceSystem => mEditor.ResourceSystem;
	public IShell Shell => mEditor.Shell;
	public IWindow Window => mEditor.Window;
	public StringView AssetDirectory => mEditor.AssetDirectory;
	public StringView AssetCacheDirectory => mEditor.AssetCacheDirectory;
	public StringView RuntimeDirectory => mEditor.RuntimeDirectory;

	// Sub-phase A passthrough. A later sub-phase will introduce a
	// viewport-scoped adapter the running GameEditorPage provides (so
	// cursor coords are in page-viewport space and keyboard / gamepad
	// gate on viewport focus). Until then the module gets shell input
	// directly, identical to today.
	public IMouse Mouse => mEditor.Shell?.InputManager?.Mouse;
	public IKeyboard Keyboard => mEditor.Shell?.InputManager?.Keyboard;
	public IGamepad GetGamepad(int32 index) =>
		mEditor.Shell?.InputManager?.GetGamepad(index);

	public void GetAssetPath(StringView relativePath, String outPath)
	{
		mEditor.GetAssetPath(relativePath, outPath);
	}
}
