namespace Sedulous.Editor;

using System;
using Sedulous.Runtime;
using Sedulous.Resources;
using Sedulous.Shell;
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

	public void GetAssetPath(StringView relativePath, String outPath)
	{
		mEditor.GetAssetPath(relativePath, outPath);
	}
}
