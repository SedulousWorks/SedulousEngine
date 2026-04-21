namespace Sedulous.Editor.Core;

using System;
using System.Collections;

/// Manages all open editor pages (scenes + assets). Tracks active page.
class EditorPageManager
{
	private List<IEditorPage> mPages = new .() ~ delete _;
	private List<IEditorPageFactory> mFactories = new .() ~ delete _;
	private IEditorPage mActivePage;

	public Event<delegate void(IEditorPage)> OnActivePageChanged ~ _.Dispose();
	public Event<delegate void(IEditorPage)> OnPageOpened ~ _.Dispose();
	public Event<delegate void(IEditorPage)> OnPageClosed ~ _.Dispose();

	/// The currently active page (visible tab).
	public IEditorPage ActivePage => mActivePage;

	/// All open pages.
	public Span<IEditorPage> OpenPages =>
		mPages.Count > 0 ? .(mPages.Ptr, mPages.Count) : .();

	/// Register a page factory for file types.
	public void RegisterFactory(IEditorPageFactory factory)
	{
		mFactories.Add(factory);
	}

	/// Open a file. Finds the registered factory for the extension.
	/// If already open, switches to the existing tab.
	public IEditorPage Open(StringView path)
	{
		// Check if already open.
		for (let page in mPages)
		{
			if (page.FilePath == path)
			{
				SetActive(page);
				return page;
			}
		}

		// Find factory.
		for (let factory in mFactories)
		{
			if (factory.CanOpen(path))
			{
				// Context is not available here - factories receive it via CreatePage.
				// The caller (EditorApplication) passes the context.
				return null; // Caller should use OpenWithContext instead.
			}
		}

		return null;
	}

	/// Open a file with an explicit editor context. Used by EditorApplication.
	public IEditorPage OpenWithContext(StringView path, EditorContext context)
	{
		// Check if already open.
		for (let page in mPages)
		{
			if (page.FilePath == path)
			{
				SetActive(page);
				return page;
			}
		}

		// Find factory.
		for (let factory in mFactories)
		{
			if (factory.CanOpen(path))
			{
				let page = factory.CreatePage(path, context);
				if (page != null)
				{
					AddPage(page);
					return page;
				}
			}
		}

		return null;
	}

	/// Add a page directly (e.g., new unsaved scene).
	public void AddPage(IEditorPage page)
	{
		mPages.Add(page);
		OnPageOpened(page);
		SetActive(page);
	}

	/// Set the active page.
	public void SetActive(IEditorPage page)
	{
		if (mActivePage === page) return;

		mActivePage?.OnDeactivated();
		mActivePage = page;
		mActivePage?.OnActivated();
		OnActivePageChanged(page);
	}

	/// Save the active page.
	public void Save(IEditorPage page)
	{
		page?.Save();
	}

	/// Close a page. Returns true if closed (may prompt for save).
	public bool Close(IEditorPage page)
	{
		if (page == null) return false;

		// TODO: prompt for unsaved changes

		let idx = mPages.IndexOf(page);
		if (idx < 0) return false;

		mPages.RemoveAt(idx);
		OnPageClosed(page);

		// Switch to adjacent page.
		if (mActivePage === page)
		{
			if (mPages.Count > 0)
			{
				let newIdx = Math.Min(idx, mPages.Count - 1);
				SetActive(mPages[newIdx]);
			}
			else
			{
				mActivePage = null;
				OnActivePageChanged(null);
			}
		}

		page.Dispose();
		delete page;
		return true;
	}

	/// Close all pages.
	public void CloseAll()
	{
		while (mPages.Count > 0)
			Close(mPages.Back);
	}

	/// Shutdown - close all pages and clean up factories.
	public void Shutdown()
	{
		CloseAll();
		for (let factory in mFactories)
			delete factory;
		mFactories.Clear();
	}
}
