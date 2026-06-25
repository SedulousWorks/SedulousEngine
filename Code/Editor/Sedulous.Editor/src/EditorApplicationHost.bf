namespace Sedulous.Editor;

using System;
using Sedulous.Runtime;
using Sedulous.Resources;
using Sedulous.Shell;
using Sedulous.Shell.Input;
using Sedulous.Engine;
using Sedulous.Editor.Core;

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
	public StringView ProjectAssetDirectory => mEditor.ProjectAssetDirectory;
	public StringView RuntimeDirectory => mEditor.RuntimeDirectory;

	// When a GameEditorPage is running, the module reads through that
	// page's viewport-scoped adapters - cursor coords land in the page
	// texture's local space and keyboard / gamepad gate on whether the
	// Game tab is the active editor page. With no running game (idle
	// editor, asset-only project), this falls back to direct shell
	// devices so the editor's own input bindings still work.
	public IMouse Mouse
	{
		get
		{
			let page = mEditor.RunningGamePage;
			if (page?.MouseAdapter != null) return page.MouseAdapter;
			return mEditor.Shell?.InputManager?.Mouse;
		}
	}

	public IKeyboard Keyboard
	{
		get
		{
			let page = mEditor.RunningGamePage;
			if (page?.KeyboardAdapter != null) return page.KeyboardAdapter;
			return mEditor.Shell?.InputManager?.Keyboard;
		}
	}

	public IGamepad GetGamepad(int32 index)
	{
		let page = mEditor.RunningGamePage;
		let adapter = page?.GetGamepadAdapter(index);
		if (adapter != null) return adapter;
		return mEditor.Shell?.InputManager?.GetGamepad(index);
	}

	public void GetAssetPath(StringView relativePath, String outPath)
	{
		mEditor.GetAssetPath(relativePath, outPath);
	}
}
