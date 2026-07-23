namespace Sedulous.Editor;

using System;
using System.Collections;
using System.IO;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core;
using Sedulous.Core.Logging.Abstractions;
using Sedulous.Editor.Core;
using Sedulous.Resources;
using Sedulous.VFS;

/// Manages dock layout persistence and editor page lifecycle (open/close/activate).
/// Handles wiring pages to dock panels and saving/restoring the layout and
/// open page list across editor sessions.
class EditorLayoutManager
{
	private EditorApplication mEditor;
	private bool mIsRestoringLayout;
	private DockablePanel mPlaceholderPanel; // "Open an asset..." placeholder, removed when first page opens
	private Dictionary<ObjectKey<IEditorPage>, DockablePanel> mPageDockPanels = new .() ~ delete _;

	public this(EditorApplication editor)
	{
		mEditor = editor;
	}

	/// Whether the layout manager is currently in the middle of restoring
	/// a saved layout (suppresses auto-docking in OnPageOpened).
	public bool IsRestoringLayout => mIsRestoringLayout;

	/// The placeholder panel shown when no pages are open.
	public DockablePanel PlaceholderPanel => mPlaceholderPanel;

	/// The map of pages to their dock panels.
	public Dictionary<ObjectKey<IEditorPage>, DockablePanel> PageDockPanels => mPageDockPanels;

	// ==================== Layout Persistence ====================

	public void GetLayoutFilePath(String outPath)
	{
		if (mEditor.Project.IsLoaded)
			System.IO.Path.InternalCombine(outPath, mEditor.Project.ProjectDirectory, "editor_layout.oddl");
	}

	public bool TryRestoreLayout(DockManager dockManager)
	{
		let layoutPath = scope String();
		GetLayoutFilePath(layoutPath);
		if (layoutPath.Length == 0)
		{
			mEditor.Logger?.Log(.Debug, "Restore layout: no project loaded, skipping");
			return false;
		}

		let provider = mEditor.ResourceSystem?.SerializerProvider;
		if (provider == null)
		{
			mEditor.Logger?.Log(.Warning, "Restore layout: no serializer provider");
			return false;
		}

		if (EditorLayoutPersistence.RestoreLayout(dockManager, layoutPath, provider) case .Ok)
		{
			mEditor.Logger?.Log(.Debug, scope $"Editor layout restored from {layoutPath}");
			return true;
		}
		else
		{
			mEditor.Logger?.Log(.Debug, scope $"No saved layout found at {layoutPath}");
			return false;
		}
	}

	public void SaveEditorLayout()
	{
		let dockManager = mEditor.EditorContext?.DockManager;
		if (dockManager == null) return;

		let layoutPath = scope String();
		GetLayoutFilePath(layoutPath);
		if (layoutPath.Length == 0) return;

		let provider = mEditor.ResourceSystem?.SerializerProvider;
		if (provider == null)
		{
			mEditor.Logger?.Log(.Warning, "Save layout: no serializer provider");
			return;
		}

		if (EditorLayoutPersistence.SaveLayout(dockManager, layoutPath, provider) case .Ok)
			mEditor.Logger.Log(.Information, "Editor layout saved.");
		else
			mEditor.Logger.Log(.Warning, "Editor layout save failed");
	}

	public void SaveOpenPages()
	{
		if (!mEditor.Project.IsLoaded) return;

		let pages = mEditor.EditorContext.PageManager.OpenPages;
		let activePage = mEditor.EditorContext.PageManager.ActivePage;

		int32 activeIndex = -1;
		for (int32 i = 0; i < pages.Length; i++)
		{
			if (pages[i] === activePage)
			{
				activeIndex = i;
				break;
			}
		}

		// Resolve each page's absolute FilePath to a scheme://locator URI so
		// the saved list is portable. Pages that aren't inside any mount (e.g.
		// untitled unsaved pages) are dropped.
		let uris = scope List<String>();
		defer { for (let s in uris) delete s; }

		for (let page in pages)
		{
			if (page.FilePath.Length == 0) continue;
			let uri = new String();
			if (MountResolver.TryResolveAbsoluteToUri(mEditor.EditorContext.MountEntries, page.FilePath, uri))
				uris.Add(uri);
			else
				delete uri;
		}

		let views = scope List<StringView>();
		for (let u in uris) views.Add(u);

		mEditor.Project.SetOpenPageUris(views, activeIndex);
		mEditor.Project.Save();
	}

	public void RestoreOpenPages()
	{
		if (!mEditor.Project.IsLoaded) return;

		// Stored URIs are mount-relative. Resolve each to an absolute path
		// against the current machine's mount table before handing to the
		// page manager (asset browser and equality checks work in abs paths).
		// A URI whose scheme isn't mounted on this machine is silently dropped.
		for (let uri in mEditor.Project.OpenPageUris)
		{
			if (uri.Length == 0) continue;
			let absPath = scope String();
			if (!MountResolver.TryResolveUriToAbsolute(mEditor.EditorContext.MountEntries, uri, absPath))
				continue;
			if (!File.Exists(absPath)) continue;
			mEditor.EditorContext.PageManager.OpenWithContext(absPath, mEditor.EditorContext);
		}

		// Restore active page
		let pages = mEditor.EditorContext.PageManager.OpenPages;
		let idx = mEditor.Project.ActivePageIndex;
		if (idx >= 0 && idx < pages.Length)
			mEditor.EditorContext.PageManager.SetActive(pages[idx]);
	}

	// ==================== Page Lifecycle ====================

	public void OnPageOpened(IEditorPage page)
	{
		if (page == null || page.ContentView == null) return;
		let dockManager = mEditor.EditorContext.DockManager;
		if (dockManager == null) return;

		// Create dock panel for this page.
		let panel = dockManager.AddPanel(page.Title, page.ContentView);
		panel.Closable = true;

		// Persistence ID uses the URI form (scheme://locator) instead of the
		// absolute filesystem path so editor_layout.oddl is portable across
		// machines and operating systems. Falls back to silently skipping if
		// the page's file isn't inside a mounted scheme (e.g. an unsaved page).
		if (page.FilePath.Length > 0)
		{
			let uri = scope String();
			if (MountResolver.TryResolveAbsoluteToUri(mEditor.EditorContext.MountEntries, page.FilePath, uri))
				panel.SetPersistenceId(scope $"page:{uri}");
		}

		// When dock tab X is clicked, detach content (page owns it) and close via PageManager.
		// Note: DockManager's own OnCloseRequested handler (registered first in AddPanel)
		// calls ClosePanel before this handler runs, so the dock panel is already undocked.
		let capturedPage = page;
		let editorCtx = mEditor.EditorContext;
		panel.OnCloseRequested.Add(new (dp) => {
			// Detach content before dock manager deletes the panel.
			if (capturedPage.ContentView?.Parent != null)
				if (let parent = capturedPage.ContentView.Parent as ViewGroup)
					parent.RemoveView(capturedPage.ContentView, false);

			// Close through PageManager (fires OnPageClosed, handles cleanup + placeholder).
			editorCtx.PageManager.Close(capturedPage);
		});

		// During layout restore, skip auto-docking - ApplyLayout will position the panel.
		if (!mIsRestoringLayout)
		{
			// Dock in the right place.
			if (mPlaceholderPanel != null)
			{
				let placeholder = mPlaceholderPanel;
				mPlaceholderPanel = null;
				dockManager.DockPanelRelativeTo(panel, .Center, placeholder.Parent);
				dockManager.ClosePanel(placeholder);
			}
			else
			{
				// Subsequent pages: dock as tab next to existing pages.
				DockablePanel relativePanel = null;
				for (let kv in mPageDockPanels)
				{
					relativePanel = kv.value;
					break;
				}

				if (relativePanel != null)
					dockManager.DockPanelRelativeTo(panel, .Center, relativePanel.Parent);
				else
					dockManager.DockPanel(panel, .Center);
			}
		}

		mPageDockPanels[.(page)] = panel;
		// (Docking activates the new tab - DockManager behavior since the
		// dock-activates change - so no explicit ActivatePanel is needed here.)
	}

	public void OnPageClosed(IEditorPage page)
	{
		let key = ObjectKey<IEditorPage>(page);

		// Detach content view from dock panel before the page deletes it.
		// During normal tab close, OnCloseRequested already did this.
		// During shutdown, PageManager.Close calls us directly - need to ensure detach.
		if (page.ContentView?.Parent != null)
			if (let parent = page.ContentView.Parent as ViewGroup)
				parent.RemoveView(page.ContentView, false);

		// Close the dock panel if it still exists.
		if (mPageDockPanels.TryGetValue(key, let panel))
			mEditor.EditorContext.DockManager?.ClosePanel(panel);

		mPageDockPanels.Remove(key);

		// If that was the last page, restore the placeholder panel.
		if (mPageDockPanels.Count == 0 && mPlaceholderPanel == null)
		{
			let dockManager = mEditor.EditorContext.DockManager;
			if (dockManager != null)
			{
				let placeholderContent = new Label();
				placeholderContent.SetText("Open an asset from the Asset Browser, or File > New Scene");
				placeholderContent.FontSize.Value = 14;
				placeholderContent.HAlign.Value = .Center;
				placeholderContent.VAlign.Value = .Middle;
				placeholderContent.TextColor.Value = .(100, 100, 115, 255);
				mPlaceholderPanel = dockManager.AddPanel("Editor", placeholderContent);
				mPlaceholderPanel.OnCloseRequested.Add(new (p) => { mPlaceholderPanel = null; });
				// Dock above the remaining root (console/assets) to recreate the original split
				dockManager.DockPanelRelativeTo(mPlaceholderPanel, .Top, dockManager.RootNode);
			}
		}
	}

	/// Surface the dock tab matching the newly active page. Fired by the page
	/// manager whenever SetActive runs - including the dedup path where the
	/// user double-clicks an already-open asset.
	public void OnActivePageChanged(IEditorPage page)
	{
		if (page == null) return;
		let dockManager = mEditor.EditorContext?.DockManager;
		if (dockManager == null) return;
		if (mPageDockPanels.TryGetValue(.(page), let panel))
			dockManager.ActivatePanel(panel);
	}

	/// Syncs the dock panel title with the page's current title (e.g.
	/// after save changes the display name).
	public void SyncDockPanelTitle(IEditorPage page)
	{
		let key = Sedulous.Core.ObjectKey<IEditorPage>(page);
		if (mPageDockPanels.TryGetValue(key, let panel))
			panel.SetTitle(page.Title);
	}

	/// Registers a saved page's resource in the project registry index.
	public void RegisterInProjectRegistry(IEditorPage page)
	{
		if (mEditor.ProjectIndex == null || mEditor.ProjectMount == null || page.FilePath.Length == 0) return;

		if (let scenePage = page as SceneEditorPage)
		{
			let sceneGuid = scenePage.LastSavedGuid;
			if (sceneGuid == .Empty) return;

			// Resolve the page's absolute FilePath to a mount-relative locator
			// against the editor's mount entries. Slash and trailing-separator
			// conventions vary across platforms - MountResolver normalizes them.
			// If the file isn't inside any mounted scheme, refuse to register
			// (a URI we can't load later isn't worth recording).
			IMount mount = null;
			let locator = scope String();
			if (!MountResolver.TryResolveAbsolute(mEditor.EditorContext.MountEntries, page.FilePath, out mount, locator))
			{
				mEditor.Logger.Log(.Warning,
					scope String()..AppendF("Skipping registry write: '{}' is not inside any mounted scheme", page.FilePath));
				return;
			}

			// Find the scheme the resolved mount is registered under.
			let scheme = scope String();
			for (let entry in mEditor.EditorContext.MountEntries)
			{
				if (entry.Mount === mount)
				{
					scheme.Set(entry.Scheme);
					break;
				}
			}

			let uri = scope String()..AppendF("{}://{}", scheme, locator);
			mEditor.ProjectIndex.Register(sceneGuid, uri);

			// Save index back through the project mount
			let indexStream = scope MemoryStream();
			if (mEditor.ProjectIndex.SerializeTo(indexStream) case .Ok)
			{
				indexStream.Position = 0;
				mEditor.ProjectMount.Save("project.registry", indexStream);
			}
			mEditor.Logger.Log(.Information, scope String()..AppendF("Registered in project registry: {}", uri));
		}
	}

	// ==================== Layout Restore Helpers ====================

	/// Begins a layout restore session (suppresses auto-docking).
	public void BeginRestore()
	{
		mIsRestoringLayout = true;
	}

	/// Ends a layout restore session.
	public void EndRestore()
	{
		mIsRestoringLayout = false;
	}

	/// Sets the placeholder panel reference (used during BuildEditorShell).
	public void SetPlaceholderPanel(DockablePanel panel)
	{
		mPlaceholderPanel = panel;
	}

	/// Clears the placeholder panel (e.g. when pages are restored and it's
	/// no longer needed).
	public void ClearPlaceholderPanel()
	{
		mPlaceholderPanel = null;
	}
}
