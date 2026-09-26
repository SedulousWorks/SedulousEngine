using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Settings;
using Sedulous.Mcp;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Editor.Core;

/// The central service object handed to every page, panel and plugin: Sedulous's
/// EditorContext, Traktor's IEditor. Holds the open project, the registries, the open pages
/// and the active one, the global asset selection, the status sink, and the seams the
/// application and the subsystem editors wire. The per subsystem editor modules register
/// their factories here from their RegisterEditor; the statically assembled editor
/// executable calls those entry points.
///
/// Everything the app owns is BORROWED here: the project, the job service, the thumbnails,
/// the resources, the settings stores. The hooks are owned delegates the app assigns.
class EditorContext : IAssetEditSink
{
	public typealias OpenAssetInterceptor = delegate bool(Instance instance);
	public typealias ImportListener = delegate void(Instance instance, ImportOptions options);

	private class InterceptorEntry
	{
		public uint64 Id;
		public OpenAssetInterceptor Fn ~ delete _;
	}

	private class PendingAssetEdit
	{
		public Guid Id;
		public AssetEditPersist Persist ~ delete _;
	}

	// ---- borrowed services ----
	private EditorProject mProject = null;
	private EditorJobService mJobs = null;
	private ThumbnailService mThumbnails = null;
	private ResourceManager mResources = null;
	private Settings mProjectEditorSettings = null;
	private Settings mUserEditorSettings = null;

	// ---- owned state ----
	private ImporterRegistry mImporters = new .() ~ delete _;
	private EditorPageRegistry mPageRegistry = new .() ~ delete _;
	private List<AssetCreator> mCreators = new .() ~ DeleteContainerAndItems!(_);
	private List<EditorSettingsContribution> mSettingsContributions = new .() ~ DeleteContainerAndItems!(_);
	private List<delegate void(McpServer server)> mMcpToolContributions = new .() ~ DeleteContainerAndItems!(_);
	private String mClipboardKind = new .() ~ delete _;
	private List<uint8> mClipboard = new .() ~ delete _;
	private List<Guid> mFavorites = new .() ~ delete _;
	private List<ImportListener> mImportListeners = new .() ~ DeleteContainerAndItems!(_);
	private List<EditorPage> mPages = new .() ~ DeleteContainerAndItems!(_);
	private EditorPage mActivePage = null;
	private Selection<Instance> mAssetSelection = new .() ~ delete _;
	private List<InterceptorEntry> mOpenInterceptors = new .() ~ DeleteContainerAndItems!(_);
	private uint64 mNextInterceptorId = 0;
	private List<PendingAssetEdit> mPendingAssetEdits = new .() ~ DeleteContainerAndItems!(_);
	private List<ScriptBreakpoint> mBreakpoints = new .() ~ DeleteContainerAndItems!(_);
	private ScriptExecutionPoint mExecutionPoint = new .() ~ delete _;
	private uint64 mExecutionPointVersion = 0;

	// ---- events and seams the app or a plugin wires; all owned ----

	/// The open pages list or the active page changed.
	public delegate void() OnPagesChanged ~ delete _;
	/// Fired after the project settings are SAVED, the settings dialog invoking it through
	/// NotifyProjectSettingsChanged, so session state derived from them re-applies without
	/// a reopen.
	public delegate void() OnProjectSettingsChanged ~ delete _;
	/// A request for an incremental cook, wired by the app to its cook service. A page calls
	/// RequestCook after saving a builder backed asset so the product refreshes.
	public delegate void(bool rebuild) OnCookRequested ~ delete _;
	/// Whether a cook is running, wired by the app; a page that must not start against a
	/// half written cooked database polls it and defers. Unwired is never busy.
	public delegate bool() CookBusy ~ delete _;
	/// Transient status bar text.
	public delegate void(StringView text) OnStatus ~ delete _;
	/// A transient user facing notification, a toast. Unwired falls back to the status bar,
	/// so a page can Notify unconditionally.
	public delegate void(NoticeKind kind, StringView message) OnNotice ~ delete _;
	/// Opens the asset with this guid for editing: the app maps it to the instance and the
	/// SAME page path a browser double click takes.
	public delegate void(Guid id) OpenAsset ~ delete _;
	/// Reveals the asset with this guid in the asset browser.
	public delegate void(Guid id) RevealAsset ~ delete _;
	/// Fired on every favorite toggle; the app persists to the project's Editor/ state.
	public delegate void() OnFavoritesChanged ~ delete _;
	/// The app's persist hook for the project editor settings.
	public delegate void() OnProjectEditorSettingsSaveRequested ~ delete _;
	/// Fired on every breakpoint toggle: the gutter repaints, a live run re-applies.
	public delegate void() OnBreakpointsChanged ~ delete _;
	/// The play in editor seam: makes the Game page. `newInstance` false reuses the app's
	/// primary game instance; true spins up an additional one. Registered by the scene editor
	/// plugin; unset, the Game menu item notifies.
	public delegate EditorPage(bool newInstance) GamePageFactory ~ delete _;
	/// Stops the Game tab's live run, if any; the embedded app's RequestExit lands here,
	/// deferred to after the page update loop. Set by the Game page.
	public delegate void() StopGameRun ~ delete _;
	/// The export seam: transcodes a scene or prefab instance's TEXT stream to the binary
	/// wire for staging. Registered by the scene editor plugin; false for a non scene
	/// instance or on failure, and the exporter then stages the source verbatim. MAIN
	/// THREAD only.
	public delegate bool(Instance instance, List<uint8> outBytes) SceneStreamStager ~ delete _;
	/// The export reachability seam: the assets a scene or prefab references, its component
	/// resource Refs into `outResources` and its nested prefab instance ids into
	/// `outPrefabs`. Registered by the scene editor plugin. MAIN THREAD only, which is why
	/// the editor pre-scans on the main thread and hands the set to the background job.
	public delegate bool(Instance instance, ContentDatabase db, List<Guid> outResources, List<Guid> outPrefabs) SceneRefScanner ~ delete _;
	/// The debugger's value lookup for hover inspection: an identifier's display text,
	/// "value : Type", or empty when unavailable. Installed by the Game page for the run.
	public delegate void(StringView identifier, String outText) ScriptValueProbe ~ delete _;

	// ---- project and services ----

	/// The app owns the project; the context borrows it. Null is no project open.
	public void SetProject(EditorProject project)
	{
		mProject = project;
		mAssetSelection.Clear();
	}

	public EditorProject Project => mProject;

	/// The app's background job runner. Null in a headless or test context, and callers
	/// then fall back to synchronous work.
	public EditorJobService Jobs
	{
		get => mJobs;
		set => mJobs = value;
	}

	/// The app's thumbnail service, borrowed; null in a headless context.
	public ThumbnailService Thumbnails
	{
		get => mThumbnails;
		set => mThumbnails = value;
	}

	/// The runtime products over the project's cooked database, owned by the application
	/// and made at project open; pages resolve scene refs and the pickers bind through it.
	public ResourceManager Resources
	{
		get => mResources;
		set => mResources = value;
	}

	/// The importers, OS file to Sources/ plus a typed asset instance; registered by the
	/// executable.
	public ImporterRegistry Importers => mImporters;

	/// The PER PROJECT editor state store, <project>/Editor/: the dock layout, favorites,
	/// open pages, per page preferences. Borrowed for the lifetime of the open project.
	/// Pages mutate their section then RequestProjectEditorSettingsSave.
	public Settings ProjectEditorSettings
	{
		get => mProjectEditorSettings;
		set => mProjectEditorSettings = value;
	}

	/// The PER USER editor settings store. Borrowed; domains keep their OWN typed sections
	/// in it, the app never learning their shapes.
	public Settings UserEditorSettings
	{
		get => mUserEditorSettings;
		set => mUserEditorSettings = value;
	}

	public void RequestProjectEditorSettingsSave()
	{
		if (OnProjectEditorSettingsSaveRequested != null)
			OnProjectEditorSettingsSaveRequested();
	}

	public void NotifyProjectSettingsChanged()
	{
		if (OnProjectSettingsChanged != null)
			OnProjectSettingsChanged();
	}

	public void RequestCook(bool rebuild = false)
	{
		if (OnCookRequested != null)
			OnCookRequested(rebuild);
	}

	public bool IsCookBusy => (CookBusy != null) ? CookBusy() : false;

	/// TAKES OWNERSHIP.
	public void RegisterEditorSettingsContribution(EditorSettingsContribution contribution)
	{
		mSettingsContributions.Add(contribution);
	}

	public List<EditorSettingsContribution> EditorSettingsContributions => mSettingsContributions;

	/// Domain contributed MCP tools: a domain's RegisterEditor (the scene editor, ...) registers
	/// what only IT can serve over the live editor (the selection, simulate); the MCP host
	/// applies every contribution to its server when it starts. Registered at boot, before any
	/// host exists, like the settings contributions. TAKES OWNERSHIP.
	public void RegisterMcpToolContribution(delegate void(McpServer server) contribution)
	{
		mMcpToolContributions.Add(contribution);
	}

	/// Applies every contribution, in registration order, to a host's server.
	public void ApplyMcpToolContributions(McpServer server)
	{
		for (let contribution in mMcpToolContributions)
			contribution(server);
	}

	public int McpToolContributionCount => mMcpToolContributions.Count;

	// ---- pending asset edits: a viewport tool edits a cooked product live and registers
	// the closure persisting it back to its SOURCE; the save flow drains these ----

	/// The last edit per asset wins. A nil id or null closure, an in memory asset with no
	/// source, registers nothing.
	public void RegisterAssetEdit(Guid assetId, AssetEditPersist persist)
	{
		if (!assetId.IsSet || (persist == null))
		{
			delete persist;
			return;
		}
		for (let edit in mPendingAssetEdits)
		{
			if (edit.Id == assetId)
			{
				delete edit.Persist;
				edit.Persist = persist;
				return;
			}
		}
		let edit = new PendingAssetEdit();
		edit.Id = assetId;
		edit.Persist = persist;
		mPendingAssetEdits.Add(edit);
	}

	public bool HasPendingAssetEdits => !mPendingAssetEdits.IsEmpty;

	/// Runs and clears every pending edit, persisting through `db`; requests a recook when
	/// any succeeded. The first failure is reported, every edit still attempted.
	public Result<void, ErrorCode> DrainAssetEdits(ContentDatabase db)
	{
		if (mPendingAssetEdits.IsEmpty)
			return .Ok;
		let pending = scope List<PendingAssetEdit>();
		pending.AddRange(mPendingAssetEdits);
		mPendingAssetEdits.Clear();
		defer { ClearAndDeleteItems(pending); }
		Result<void, ErrorCode> result = .Ok;
		bool anyOk = false;
		for (let edit in pending)
		{
			let outcome = edit.Persist(db);
			if (outcome case .Ok)
				anyOk = true;
			else if (result case .Ok)
				result = outcome;
		}
		if (anyOk)
			RequestCook(false);
		return result;
	}

	// ---- notices ----

	public void SetStatus(StringView text)
	{
		if (OnStatus != null)
			OnStatus(text);
	}

	/// An error or a warning ALWAYS reaches the log too: a toast is transient, and a failure
	/// a user reports from memory must be reconstructable from the log.
	public void Notify(NoticeKind kind, StringView message)
	{
		if (kind == .Error)
			GlobalLog(.Error, "Editor: {}", message);
		else if (kind == .Warning)
			GlobalLog(.Warning, "Editor: {}", message);
		if (OnNotice != null)
			OnNotice(kind, message);
		else
			SetStatus(message);
	}

	// ---- asset open interception: a claimant, the scene page for animation clips into its
	// animation bar say, sees an OpenAsset BEFORE it routes to a page; newest first ----

	/// TAKES OWNERSHIP; remove with the returned id when the claimant dies.
	public uint64 AddOpenAssetInterceptor(OpenAssetInterceptor interceptor)
	{
		let entry = new InterceptorEntry();
		entry.Id = ++mNextInterceptorId;
		entry.Fn = interceptor;
		mOpenInterceptors.Add(entry);
		return entry.Id;
	}

	public void RemoveOpenAssetInterceptor(uint64 id)
	{
		for (int i < mOpenInterceptors.Count)
		{
			if (mOpenInterceptors[i].Id == id)
			{
				delete mOpenInterceptors[i];
				mOpenInterceptors.RemoveAt(i);
				return;
			}
		}
	}

	public bool TryInterceptOpenAsset(Instance instance)
	{
		for (int i = mOpenInterceptors.Count - 1; i >= 0; i--)
			if ((mOpenInterceptors[i].Fn != null) && mOpenInterceptors[i].Fn(instance))
				return true;
		return false;
	}

	// ---- registries ----

	public EditorPageRegistry Pages => mPageRegistry;

	/// TAKES OWNERSHIP. A creator with no Run is dropped.
	public void RegisterCreator(AssetCreator creator)
	{
		if ((creator == null) || (creator.Run == null))
		{
			delete creator;
			return;
		}
		mCreators.Add(creator);
	}

	public List<AssetCreator> Creators => mCreators;

	// ---- favorites: pinned instances the browser and the pickers surface first ----

	public bool IsFavorite(Guid id)
	{
		for (let favorite in mFavorites)
			if (favorite == id)
				return true;
		return false;
	}

	public void ToggleFavorite(Guid id)
	{
		for (int i < mFavorites.Count)
		{
			if (mFavorites[i] == id)
			{
				mFavorites.RemoveAt(i);
				if (OnFavoritesChanged != null)
					OnFavoritesChanged();
				return;
			}
		}
		mFavorites.Add(id);
		if (OnFavoritesChanged != null)
			OnFavoritesChanged();
	}

	public List<Guid> Favorites => mFavorites;

	public void SetFavorites(Span<Guid> favorites)
	{
		mFavorites.Clear();
		mFavorites.AddRange(favorites);
	}

	// ---- the editor clipboard, one typed slot across pages: entity subtrees, components.
	// `kind` says what the bytes are; a consumer checks it before parsing ----

	public void SetClipboard(StringView kind, Span<uint8> data)
	{
		mClipboardKind.Set(kind);
		mClipboard.Clear();
		mClipboard.AddRange(data);
	}

	public StringView ClipboardKind => mClipboardKind;

	/// The bytes when the slot holds `kind`, else empty.
	public Span<uint8> ClipboardData(StringView kind) => (mClipboardKind == kind) ? Span<uint8>(mClipboard.Ptr, mClipboard.Count) : Span<uint8>();

	// ---- open pages ----

	/// Opens, or focuses, a page editing `instance`: an existing page for the instance is
	/// activated; otherwise the registry's nearest type factory creates one. Null when no
	/// factory matches or the instance's type is not one the registry can resolve.
	public EditorPage OpenPage(Instance instance)
	{
		for (let page in mPages)
		{
			if (page.InstanceId == instance.Id)
			{
				SetActivePage(page);
				return page;
			}
		}
		let factory = mPageRegistry.FindFactory(instance.TypeName);
		if (factory == null)
			return null;
		let page = factory.CreatePage(this, instance);
		if (page == null)
			return null;
		page.InstanceId = instance.Id;
		mPages.Add(page);
		mActivePage = page;
		NotifyPagesChanged();
		return page;
	}

	/// Adopts an instance LESS page, the Game tab, TAKING OWNERSHIP: the same ownership and
	/// active page flow as OpenPage, the caller having constructed it.
	public EditorPage AdoptPage(EditorPage page)
	{
		if (page == null)
			return null;
		mPages.Add(page);
		mActivePage = page;
		NotifyPagesChanged();
		return page;
	}

	/// Closes and deletes a page; the caller save prompts a dirty one first.
	public void ClosePage(EditorPage page)
	{
		for (int i < mPages.Count)
		{
			if (mPages[i] == page)
			{
				if (mActivePage == page)
					mActivePage = (mPages.Count > 1) ? mPages[(i + 1 < mPages.Count) ? i + 1 : i - 1] : null;
				mPages.RemoveAt(i);
				delete page;
				NotifyPagesChanged();
				return;
			}
		}
	}

	public List<EditorPage> OpenPages => mPages;

	/// The source asset changed OUTSIDE its page (an apply to prefab, a regenerated model
	/// prefab or scene, an agent's write over MCP): every open page editing it is told
	/// (EditorPage.OnAssetExternallyModified) and refreshes by its own rule. Returns how many
	/// pages were told.
	public int NotifyAssetExternallyModified(Guid assetId)
	{
		int told = 0;
		for (let page in mPages)
		{
			if (page.InstanceId == assetId)
			{
				page.OnAssetExternallyModified();
				told++;
			}
		}
		return told;
	}

	public EditorPage ActivePage => mActivePage;

	public void SetActivePage(EditorPage page)
	{
		if (mActivePage == page)
			return;
		mActivePage = page;
		NotifyPagesChanged();
	}

	// ---- edit routing: Edit > Undo and Redo go to the active page's stack ----

	public bool CanUndo => (mActivePage != null) && mActivePage.Commands.CanUndo;
	public bool CanRedo => (mActivePage != null) && mActivePage.Commands.CanRedo;

	public void Undo()
	{
		if (mActivePage != null)
			mActivePage.Commands.Undo();
	}

	public void Redo()
	{
		if (mActivePage != null)
			mActivePage.Commands.Redo();
	}

	// ---- selection ----

	/// The global asset selection, the browser's and the pickers'. Entity selection is per
	/// scene page.
	public Selection<Instance> AssetSelection => mAssetSelection;

	// ---- import notifications: a step above the importer's layer, model to prefab say ----

	/// TAKES OWNERSHIP. Fired by the import flow AFTER the importer returned; `options` is
	/// the dialog edited options, null when none.
	public void AddImportListener(ImportListener listener)
	{
		mImportListeners.Add(listener);
	}

	public void NotifyImported(Instance instance, ImportOptions options)
	{
		for (let listener in mImportListeners)
			listener(instance, options);
	}

	// ---- script breakpoints and the execution point ----

	public void ToggleBreakpoint(StringView file, int32 line)
	{
		for (int i < mBreakpoints.Count)
		{
			if ((mBreakpoints[i].Line == line) && (mBreakpoints[i].File == file))
			{
				delete mBreakpoints[i];
				mBreakpoints.RemoveAt(i);
				if (OnBreakpointsChanged != null)
					OnBreakpointsChanged();
				return;
			}
		}
		mBreakpoints.Add(new ScriptBreakpoint(file, line));
		if (OnBreakpointsChanged != null)
			OnBreakpointsChanged();
	}

	public bool HasBreakpoint(StringView file, int32 line)
	{
		for (let breakpoint in mBreakpoints)
			if ((breakpoint.Line == line) && (breakpoint.File == file))
				return true;
		return false;
	}

	public List<ScriptBreakpoint> Breakpoints => mBreakpoints;

	public void SetScriptExecutionPoint(StringView file, int32 line)
	{
		mExecutionPoint.File.Set(file);
		mExecutionPoint.Line = line;
		mExecutionPoint.Active = true;
		mExecutionPointVersion++;
	}

	public void ClearScriptExecutionPoint()
	{
		if (!mExecutionPoint.Active)
			return;
		mExecutionPoint.Active = false;
		mExecutionPointVersion++;
	}

	public ScriptExecutionPoint ScriptExecution => mExecutionPoint;
	/// Stamped on every set and clear so a consumer polls cheaply per frame.
	public uint64 ScriptExecutionVersion => mExecutionPointVersion;

	private void NotifyPagesChanged()
	{
		if (OnPagesChanged != null)
			OnPagesChanged();
	}
}
