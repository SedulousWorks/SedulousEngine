namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.Editor.Core;

/// The asset browser dockable panel.
/// Shows mounted registries (left tree) and their contents (right list).
/// Supports navigation, selection, and will support import/context menus in later phases.
class AssetBrowserPanel : IEditorPanel
{
	private EditorContext mEditorContext;
	private View mContentView;
	private AssetBrowserBuilder.BuildResult mBuildResult;

	public this(EditorContext editorContext)
	{
		mEditorContext = editorContext;
		mBuildResult = AssetBrowserBuilder.Build(editorContext);
		mContentView = mBuildResult.RootView;
	}

	public ~this()
	{
		// Tree adapter and content adapter are owned by the tree/list views
		// which are owned by the layout, which is owned by the dock panel.
		// We only need to clean up the adapters we created.
		delete mBuildResult.TreeAdapter;
		delete mBuildResult.ContentAdapter;
	}

	public StringView PanelId => "AssetBrowser";
	public StringView Title => "Assets";
	public View ContentView => mContentView;

	public void OnActivated() { }
	public void OnDeactivated() { }

	public void Update(float deltaTime)
	{
	}

	/// Refreshes the registry tree (e.g. after mount/unmount).
	public void RefreshRegistries()
	{
		let registries = scope System.Collections.List<Sedulous.Resources.IResourceRegistry>();
		mEditorContext.ResourceSystem.GetRegistries(registries);
		mBuildResult.TreeAdapter.Refresh(registries);
	}

	/// Refreshes the content view (e.g. after import or file changes).
	public void RefreshContent()
	{
		mBuildResult.ContentAdapter.Rebuild();
	}

	public void Dispose()
	{
	}
}
