using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Shell;
using Sedulous.Graphics;
using Sedulous.Fonts;
using Sedulous.Fonts.DistanceField.Baker;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.Engine.DefaultApp;
using Sedulous.Render;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Settings;
using Sedulous.Pipeline.Core;
using Sedulous.Editor.Core;
using Sedulous.Editor.Look;
using Sedulous.Editor.Project;
using Sedulous.Profiler;
using Sedulous.Profiler.Capture;
using Sedulous.Engine.Project; // ProjectLayout.DistDir: where exports go

namespace Sedulous.Editor.App;

/// The editor as a runtime IApplication. It keeps the lifecycle alone: it configures the engine,
/// starts its parts in order, hands each frame to them
/// and shuts them down. The parts are their own files: the window and its GUI (EditorWindow), its
/// dock (EditorDock), the Assets panel and the Console in it (AssetsView, LogView), the pages in it (EditorPages), its menu bar (ActionMenuBar) and keys (ActionShortcuts), the open project (EditorSession), export
/// (EditorExport), asset creation (EditorAssetCreation), files imported (AssetImport, reviewed in
/// ImportWindow), the MCP host (EditorMcpService) and the
/// editor-wide actions (EditorAppActions). Underneath are the EditorContext and the services from Editor.Core and
/// Editor.Project, and the EMBEDDED runtime every scene, preview and Game tab is hosted in: the
/// same DefaultApplication the player runs.
///
/// A project's packages are compiled into its own build, never loaded into this editor:
/// Project > Build Project makes that build and Open With This Build moves the project to it.
class EditorApplication : IApplication
{
	private EditorAppConfig mConfig ~ delete _;
	/// Borrowed.
	private IApplicationHost mHost = null;
	/// Borrowed; the executable injects it.
	private ISceneRenderer mSceneRenderer = null;
	/// OnStartup got past its window check: what it set up, OnShutdown takes down.
	private bool mStarted = false;

	/// The per-user disk cache for distance-field font bakes: a font cook in this process bakes
	/// through it (FontAtlasBakerFactory.Bake), so an unchanged font's atlas loads instead of
	/// running msdfgen again.
	private FontAtlasDiskCache mFontAtlasCache = null ~ delete _;

	// The embedded runtime: gameplay subsystems and all scene hosting live here. The application
	// registers subsystems it OWNS (render, audio, input, UI) into the context, so the context is
	// declared after the application and goes first, unregistering them while they are alive.
	private EmbeddedApplicationHost mEmbeddedHost = null ~ delete _;
	private DefaultApplication mEmbeddedApp = null ~ delete _;
	private SubsystemManager mRuntimeContext = new .() ~ delete _;
	/// The host borrows it for as long as it is installed.
	private delegate void(int) mEmbeddedExitHandler = null ~ delete _;

	/// The one source every page factory asks for PageServices (the registrations borrow it).
	/// Declared before the context, so it outlives the factories the context's registry holds.
	private AssetPageServicesSource mPageServices ~ delete _;
	/// The code pages' languages, read through the window's resources.
	private CodeLanguages mCodeLanguages ~ delete _;
	/// Build Project's builds, run on the build lane. Declared before the context, so it outlives
	/// a build the context's tasks still hold.
	private ProjectBuildService mBuildService = new .() ~ delete _;
	/// The watch over the open project's own code (WatchCode), swept every CodeWatch.cPollSeconds.
	private CodeWatch mCodeWatch = new .() ~ delete _;
	/// The project the watch last swept; null for none.
	private EditorProject mCodeWatched = null;
	/// When it last swept, on the stopwatch; 0: at the next frame.
	private int64 mCodeWatchSwept = 0;
	// The services the parts share. Declared before the parts, so they outlive them.
	private EditorContext mContext = new .() ~ delete _;
	/// Exe-assembled (RegisterEditors).
	private BuilderRegistry mBuilders = new .() ~ delete _;
	private EditorCookService mCookService = new .() ~ delete _;
	/// Per project (the session configures it).
	private ThumbnailService mThumbnailService = new .() ~ delete _;
	/// The per-user editor preferences, <user-data>/editor.settings.xml.
	private Settings mEditorSettings = new .() ~ delete _;
	/// The user's registry of projects.
	private ProjectManagerController mProjectManager ~ delete _;

	// The parts, in the order they start; they go in reverse (a later field's cleanup runs
	// first), the session before the parts its hooks reach.
	private EditorWindow mWindow = new .() ~ delete _;
	private EditorDock mDock = new .() ~ delete _;
	/// Made with the application: every frame hands them its hooks, a window or not.
	private EditorPages mPages ~ delete _;
	/// Rename, duplicate, delete, cook: the assets browser's and an agent's. Made with the
	/// application; after the pages its closes reach, so it goes first.
	private AssetOperations mAssetOps ~ delete _;
	/// Files into the project (a drop, Import...). Made with the application; after the cook and
	/// the jobs it borrows, before the import window that borrows it.
	private AssetImport mAssetImport ~ delete _;
	/// The frame's menu bar, from the actions: made in OnStartup once they are all declared.
	private ActionMenuBar mMenus = null ~ delete _;
	/// The actions' keys in the GUI's keymap, made with the menu bar.
	private ActionShortcuts mShortcuts = null ~ delete _;
	/// Every action by name (View > Command Palette), made the first time it opens.
	private CommandPalette mPalette = null ~ delete _;
	/// Edit > Preferences, made the first time it opens.
	private EditorPreferencesDialog mPreferences = null ~ delete _;
	/// A type's icon, asked of the type; made with the slots' table.
	private EditorIcons mTypeIcons = null ~ delete _;
	/// The one picker (paths, groups, components), made the first time it shows.
	private Picker mPicker = null ~ delete _;
	/// An asset slot's picker, made the first time it shows.
	private AssetPickerWindow mAssetPicker = null ~ delete _;
	/// Create Asset, while open (and after, until the next one opens).
	private AssetCreate mCreateAsset = null ~ delete _;
	/// The name prompt, while open (and after, until the next).
	private NamePrompt mNamePrompt = null ~ delete _;
	/// Add Native Code's dialog, while open (and after, until the next).
	private NativeCodeDialog mNativeCodeDialog = null ~ delete _;
	/// What an asset slot asks of the editor, made the first time a slot needs it; after the icons
	/// and the picker it reaches, so it goes first.
	private ResourceRefServices mRefs = null ~ delete _;
	/// The import's review, made the first time one needs it; after the picker its group field
	/// opens, so it goes first.
	private ImportWindow mImportWindow = null ~ delete _;
	/// Project > Project Settings, made the first time it opens; its slots borrow mRefs.
	private ProjectSettingsDialog mProjectSettings = null ~ delete _;
	/// The Project panel while a project is open (made with its markup when one opens).
	private ProjectHomeView mHome = null ~ delete _;
	/// The Console panel's content, made with the dock.
	private LogView mConsole = null ~ delete _;
	/// The Profiler page's content, made with the dock.
	private ProfilerPanel mProfiler = null ~ delete _;
	/// The MCP panel's content, made with the dock.
	private McpPanel mMcpPanel = null ~ delete _;
	/// The Assets panel's content, made with the dock; after the type icons it borrows, so it
	/// goes first.
	private AssetsView mAssets = null ~ delete _;
	/// The last log entry the Console took.
	private uint64 mLogSequence = 0;
	/// Started with the editor: the time each line the Console takes shows.
	private EditorExport mExport = null ~ delete _;
	/// Project > Export (its project's presets, EditorExport's), made again for each project;
	/// after mExport, so it goes first.
	private ExportDialog mExportDialog = null ~ delete _;
	/// The project mExportDialog edits. Borrowed: compared, never reached.
	private EditorProject mExportProject = null;
	private EditorAssetCreation mCreation ~ delete _;
	/// The MCP tools the project's plugins add through their Tooling parts: attached to each
	/// project's plugin host by the session, and serving the MCP host's server while it runs.
	/// Before the two, so it goes after them.
	private Sedulous.Editor.Mcp.McpPluginServices mMcpPluginTools = new .() ~ delete _;
	private EditorMcpService mMcp = null ~ delete _;
	/// The open project: after the parts its hooks reach, so it closes first.
	private EditorSession mSession ~ delete _;
	/// Project > Build and Relaunch: its build waited on, then the relaunch. Made with the
	/// application; after the session its seams reach, so it goes first.
	private BuildAndRelaunch mBuildAndRelaunch ~ delete _;
	/// When this application was made (DateTime ticks, UTC): a relaunch's start is timed to it and
	/// its restore from it.
	private int64 mCreatedTicks = DateTime.UtcNow.Ticks;

	/// Screenshots of the editor's windows: --screenshot, editor_screenshot, View > Screenshot.
	private EditorWindowCapture mWindowCapture = new .() ~ delete _;
	/// The window's focus listener's token (0: none), which has Content/ looked at on a return.
	private uint32 mFocusListener = 0;
	/// The auto-exit, auto-rebuild and screenshot accumulator.
	private float mElapsed = 0.0f;
	/// The --screenshot one shot is armed.
	private bool mScreenshotFired = false;
	/// View > Screenshot: tell the user when it is written.
	private bool mAnnounceScreenshot = false;
	private bool mAutoRebuilt = false;
	/// OnStartup is running: its steps go to the splash.
	private bool mStarting = false;

	/// TAKES OWNERSHIP of the config.
	public this(EditorAppConfig config)
	{
		mConfig = config;
		// What the running editor was built as: a build replaces the file it runs from, not it.
		EditorBuildTools.NoteRunningExecutable();
		mPageServices = new .(new [=this] () => PageServices());
		mCodeLanguages = new .(new [=this] (path, outText) => mWindow.LoadText(path, outText));
		mProjectManager = new ProjectManagerController(mEditorSettings);
		// Thumbnails are reachable from the constructor on: the registration block, where each
		// domain folds its thumbnail generator in, runs before the project opens.
		mContext.Thumbnails = mThumbnailService;
		// A thumbnail ready is told to the views showing thumbnails (the assets browser).
		mThumbnailService.OnThumbnailReady = new (id) => { mContext.NotifyThumbnailReady(id); };
		mPages = new EditorPages(PagesServices());
		mAssetOps = new AssetOperations(AssetOpsServices());
		{
			let imports = new AssetImportServices();
			imports.Context = mContext;
			imports.Cook = mCookService;
			imports.Tasks = mContext.Tasks; // reads and writes on the build lane
			imports.Lane = mContext.BuildLane;
			mAssetImport = new AssetImport(imports);
		}
		mCreation = new EditorAssetCreation(CreationServices());
		mSession = new EditorSession(SessionServices());
		mBuildAndRelaunch = new BuildAndRelaunch(RelaunchServices());
	}

	public EditorContext Context => mContext;
	/// Null with no project open.
	public EditorProject Project => mSession.Project;
	/// The executable registers every engine builder here, the cook CLI's set; the cook service
	/// routes through it.
	public BuilderRegistry Builders => mBuilders;
	/// The engine data root this editor runs from (its config's, resolved at launch).
	public StringView DataRoot => mConfig.DataRoot;
	/// The project manager that launched this editor (--manager), which Close Project starts again;
	/// empty when none said so.
	public StringView ManagerPath => mConfig.ManagerPath;
	public EditorCookService CookService => mCookService;

	/// Cooks `page`'s asset and what it needs (`force`: again, changed or not), saving the page's
	/// changes first.
	private void CookPage(EditorPage page, bool force)
	{
		if (page.IsDirty)
			mPages.Save(page);
		Guid[1] ids = .(page.InstanceId);
		mCookService.RequestCookFor(ids, force);
	}
	/// The resources over the open project's cooked database; null with no project.
	public ResourceManager Resources => mSession.Resources;
	/// Valid after OnStartup; the Game page drives its play bracket through it.
	public DefaultApplication EmbeddedApplication => mEmbeddedApp;
	public EditorWindow Window => mWindow;
	public EditorDock Dock => mDock;
	public EditorPages Pages => mPages;
	public EditorAssetCreation AssetCreation => mCreation;
	public EditorSession Session => mSession;
	/// Null until StartParts.
	public EditorExport Export => mExport;
	/// Null until StartParts.
	public EditorMcpService McpService => mMcp;

	/// The renderer interface the application drives its per-frame scene bracket through; null
	/// means no scene rendering. Borrowed.
	public void SetSceneRenderer(ISceneRenderer renderer) => mSceneRenderer = renderer;

	/// A toast, as every notice and job result is said.
	/// TAKES OWNERSHIP of `action` (a button's, keeping the toast until closed).
	public void ShowToast(NoticeKind kind, StringView message, StringView actionText = default, delegate void() action = null)
		=> mWindow.ShowToast(kind, message, actionText, action);

	private EditorAssetCreationServices CreationServices()
	{
		let services = new EditorAssetCreationServices();
		services.Context = mContext;
		services.Cook = mCookService;
		services.Builders = mBuilders;
		services.OnOpenPage = new (instance) => { mPages.Open(instance); };
		// The assets view shows the new row once it is on the GUI.
		return services;
	}

	/// What the assets' verbs reach: a deleted asset's pages closed at once, a confirmed delete
	/// run at the GUI's next drain (after the event that answered it).
	private AssetOperationsServices AssetOpsServices()
	{
		let services = new AssetOperationsServices();
		services.Context = mContext;
		services.Cook = mCookService;
		services.ClosePages = new (id) => { mPages.CloseAssetNow(id); };
		services.Later = new (work) => { Later(work); };
		return services;
	}

	/// `work` at the main window's GUI's next drain; at once with no window. TAKES OWNERSHIP of
	/// `work`.
	private void Later(delegate void() work)
	{
		let root = mWindow.Root;
		let queue = (root != null) ? root.MutationQueue : null;
		if (queue == null)
		{
			defer delete work;
			work();
			return;
		}
		queue.Enqueue(work);
	}

	/// The pages in the dock; their dialogs over the main window.
	private EditorPagesServices PagesServices()
	{
		let services = new EditorPagesServices();
		services.Context = mContext;
		services.Dock = mDock;
		services.Cook = mCookService;
		services.Project = new () => mSession.Project;
		services.Resources = new () => mSession.Resources;
		services.DialogRoot = new () => mWindow.Root;
		services.LoadMarkup = new (path) => mWindow.LoadMarkup(path);
		services.Languages = mCodeLanguages;
		return services;
	}

	/// A project's first open: its default scene, by guid (else by path, for a manifest without
	/// one).
	private void OpenDefaultScene(EditorProject project)
	{
		Instance instance = null;
		if (project.Settings.DefaultSceneId.IsSet)
			instance = project.SourceDb.GetInstance(project.Settings.DefaultSceneId);
		if ((instance == null) && !project.Settings.DefaultScene.IsEmpty)
			instance = project.SourceDb.GetInstanceByPath(project.Settings.DefaultScene);
		if (instance != null)
			mPages.Open(instance);
	}

	private EditorSessionServices SessionServices()
	{
		let services = new EditorSessionServices();
		services.Context = mContext;
		services.Cook = mCookService;
		services.Builders = mBuilders;
		services.Thumbnails = mThumbnailService;
		services.UserSettings = mEditorSettings;
		services.Projects = mProjectManager;
		services.PluginTools = mMcpPluginTools;
		services.SeedNewProject = new (context, project) =>
			{
				if (mConfig.SeedNewProject != null)
					mConfig.SeedNewProject(context, project);
			};
		services.OnOpened = new (project) =>
			{
				// The project's layout, else the default (the one before was another project's).
				let store = mSession.Store;
				mDock.TakeLayout(store);
				// The pages from the last session (a restored layout kept their places), else the
				// project's default scene.
				delegate void(StringView name, float done) progress = scope (name, done) =>
					{
						ReportStartup(scope $"Opening {name}", 0.72f + 0.26f * done);
					};
				if ((store == null) || !mPages.Restore(store, progress))
					OpenDefaultScene(project);
				// After a relaunch: the pages kept aside, the Game tabs and the active page, before
				// the panels nothing provides are let go (a Game tab is provided again here).
				RestoreRelaunch();
				// What the layout names and nothing reopened (a Game tab, a page whose asset is
				// gone) goes, rather than staying a placeholder.
				ProjectEditorSettings.ForgetUnprovidedPanels(mDock.Controller);
				// The Project panel shows the project's page; its links open assets as the pages do.
				if (mWindow.IsOpen)
				{
					mHome = new ProjectHomeView(mContext, mCookService, mWindow.LoadMarkup(ProjectHomeView.cMarkupPath));
					mHome.SetOnOpenAsset(new (id) => { mPages.Open(id); });
					mHome.SetOnNewScene(new () =>
						{
							for (let creator in mContext.Creators)
							{
								if (creator.SetsDefaultScene) // the scene's creator, as File > New Scene
								{
									mCreation.CreateAndOpen(creator);
									return;
								}
							}
						});
					mHome.SetOnShowFolder(new (folder) =>
						{
							if (let dialogs = ShellDialogs())
								dialogs.OpenPath(folder);
						});
					mHome.SetOnProjectSettings(new () => { OpenProjectSettings(); });
					mDock.SetProjectContent(mHome.Content);
				}
				if (mExport != null)
					mExport.SetProject(project);
				mCreation.SetProject(project);
				if (mMcp != null)
					mMcp.Start(project); // the agent surface over this project, if enabled
			};
		services.OnClosing = new () =>
			{
				mDock.SetProjectContent(null); // the welcome again
				DeleteAndNullify!(mHome);
				mPages.CloseAll(); // their resources while the project's services live
				if (mMcp != null)
					mMcp.Stop(); // no agent call may run against services that are going away
				if (mExport != null)
					mExport.SetProject(null);
				mCreation.SetProject(null);
			};
		services.CaptureState = new (store) =>
			{
				mDock.CaptureLayout(store);
				mPages.Capture(store);
			};
		services.OnCookFinished = new () =>
			{
				// Failures stay until dismissed (the Console has the log); a cook of nothing says
				// nothing, since the watcher fires those constantly.
				let failed = mCookService.LastCookSummary.Failed;
				let cooked = mCookService.LastCookSummary.Cooked;
				if (failed > 0)
					ShowToast(.Error, scope $"Cook: {failed} failed, {cooked} cooked (see Console).");
				else if (cooked > 0)
					ShowToast(.Success, scope $"Cook finished: {cooked} asset(s).");
			};
		// The Project page shows the settings: filled again at the next frame.
		services.OnSettingsChanged = new () =>
			{
				if (mHome != null)
					mHome.MarkChanged();
			};
		return services;
	}

	/// The main window presents as every editor window does (EditorWindow.EditorRenderWindowDesc).
	public RenderWindowDesc MainRenderWindow => EditorWindow.EditorRenderWindowDesc();

	public void Configure(IApplicationHost host)
	{
		if (mConfig.ConfigureEngine != null)
			mConfig.ConfigureEngine(host);
	}

	/// Tells the splash what startup is doing (EditorAppConfig.StartupProgress), while it is
	/// starting; a project opened later reports nothing.
	private void ReportStartup(StringView status, float progress)
	{
		if (mStarting && (mConfig.StartupProgress != null))
			mConfig.StartupProgress(status, progress);
	}

	/// Loads the per-user editor settings from <user-data>/editor.settings.xml, registering the
	/// section types first (the per-project store's among them). Absent on a first run, the store
	/// stays empty and the sections read as defaults.
	private void LoadEditorSettings()
	{
		EditorSerializables.RegisterAll();
		EditorAppSerializables.RegisterEditorProjectSettingsTypes();
		if (EditorSettingsStore.LoadFromUserData(mEditorSettings) case .Err(let error))
		{
			// NotFound (a first run) is fine; anything else is a partial load, since Settings
			// aborts at the first section it cannot make, which a later save would write back
			// without the sections it dropped (the project registry most painfully).
			if (error != .NotFound)
				GlobalLog(.Error, "Editor: editor.settings.xml load FAILED (partial store), check for unregistered section types; later saves may drop sections");
		}
	}

	public void OnStartup(IApplicationHost host)
	{
		mHost = host;
		if (host.MainRenderWindow == null)
			return;
		mStarted = true;
		// The editor's own profiler, which a Play-in-editor game shares (one process): what
		// profiler_capture records.
		if (!HasGlobalProfiler())
			InitGlobalProfiler(new Sedulous.Profiler.Profiler(), true);
		// A font cook's distance-field bakes hit the per-user disk cache: the first bakes and
		// stores, every one after loads the atlas instead.
		mFontAtlasCache = new FontAtlasDiskCache(PathJoin(GetUserDataDirectory(.. scope .()), "font-atlas-cache", .. scope .()));
		FontAtlasBakerFactory.SetAtlasCache(mFontAtlasCache);

		mStarting = true; // the splash hears startup's steps until the editor is ready
		ReportStartup("Loading settings", 0.12f);
		LoadEditorSettings();
		// Domains reach their own sections through the context.
		mContext.UserEditorSettings = mEditorSettings;

		ReportStartup("Preparing the interface", 0.30f);
		let look = scope EditorLook();
		look.ReadFrom(mEditorSettings.Find<EditorUiSettings>());
		if (mWindow.Open(host, mConfig.DataRoot, look, PathJoin(GetUserDataDirectory(.. scope .()), EditorWindow.cThemeFolder, .. scope .())))
		{
			OpenDock();
			// Back from another window (where a pull or another tool changed the project's files):
			// Content/ is looked at now, not at the next tick of its clock.
			mFocusListener = mWindow.Host.AddWindowEventListener(new (root, event) =>
				{
					if (event.Type == .FocusGained)
						mCookService.PollContentSoon();
				});
		}
		// The window's close button asks about unsaved pages first, as File > Exit does.
		if (host.Shell != null)
			host.Shell.SetMainWindowCloseHandler(new () => ConfirmExit());
		delete mContext.OnNotice;
		mContext.OnNotice = new (kind, message) =>
			{
				ShowToast(kind, message);
				mContext.SetStatus(message);
			};
		delete mContext.OnStatus;
		mContext.OnStatus = new (message) => { mWindow.SetStatus(message); };

		ReportStartup("Starting the renderer", 0.45f);
		StartEmbeddedRuntime(host);
		mSession.SetEmbedded(mEmbeddedHost, mEmbeddedApp);

		ReportStartup("Loading the editors", 0.62f);
		StartParts();
		// The per-subsystem editor plugins register here with the EMBEDDED host (every page's
		// scenes live there); once per run, since what they register outlives a project.
		if (mConfig.RegisterEditors != null)
			mConfig.RegisterEditors(this, mEmbeddedHost);
		// The user's shortcut overrides, once every domain has declared its actions (an override
		// names an id; a domain not loaded keeps its entry for a later run).
		if (let shortcuts = mEditorSettings.Find<EditorShortcutSettings>())
			shortcuts.ApplyTo(mContext.Actions);
		BuildMenus();

		// The editor has one project, given on its command line (main starts the project manager
		// instead when none is).
		ReportStartup(scope $"Opening {PathFilename(mConfig.ProjectDirectory, .. scope .())}", 0.70f);
		var options = EditorSessionOpenOptions();
		options.Scaffold = true; // a command line's bare folder becomes a project
		options.ScaffoldName = mConfig.ProjectName;
		options.Seed = mConfig.SeedOnScaffold;
		options.Restamp = mConfig.Restamp; // the manager's: an older engine's project, upgraded
		mSession.Open(mConfig.ProjectDirectory, options);

		// Ready: the splash goes and the main window (created hidden) comes up.
		ReportStartup("Ready", 1.0f);
		mStarting = false;
		if (mConfig.StartupFinished != null)
			mConfig.StartupFinished();
	}

	/// The parts that need no window, in order: export, the MCP host, then the editor-wide
	/// actions (before the domains register theirs: the menu bar follows registration order).
	/// OnStartup calls it once the window and the embedded runtime are up; a headless run (the
	/// tests) calls it alone. Once: a second call does nothing.
	public void StartParts()
	{
		if (mExport != null)
			return;
		let exportServices = new EditorExportServices();
		exportServices.Context = mContext;
		exportServices.Cook = mCookService;
		exportServices.Tasks = mContext.Tasks;
		exportServices.Lane = mContext.BuildLane;
		exportServices.Builders = mBuilders;
		exportServices.BuildService = mBuildService;
		exportServices.DataRoot.Set(mConfig.DataRoot);
		// It stays, its button showing the build in the system's file manager (the old editor's).
		exportServices.OnExported = new (folder) =>
			{
				let exported = new String(folder);
				ShowToast(.Success, scope $"Exported to {folder}", "Open Folder", new [=this, =exported] () =>
					{
						if (let dialogs = ShellDialogs())
							dialogs.OpenPath(exported);
					} ~ delete exported);
			};
		mExport = new EditorExport(exportServices);

		let mcpServices = new EditorMcpServiceServices();
		mcpServices.Context = mContext;
		mcpServices.Cook = mCookService;
		mcpServices.Builders = mBuilders;
		mcpServices.UserSettings = mEditorSettings;
		mcpServices.Log = mConfig.LogBuffer;
		mcpServices.PluginTools = mMcpPluginTools;
		mcpServices.DataRoot.Set(mConfig.DataRoot);
		mcpServices.ForceEnabled = mConfig.McpEnabled;
		mcpServices.Port = mConfig.McpPort;
		mcpServices.BuildService = mBuildService;
		mcpServices.OnCreated = new (creator, instance) => { mCreation.AfterCreate(creator, instance); };
		// What follows an import, as the Import dialog's: the editor told (a model's prefab made).
		mcpServices.OnImported = new (primary, options) => { mContext.NotifyImported(primary, options); };
		// The pages, over the paths the tabs take (a close at the next frame).
		mcpServices.OpenPage = new (id) => mPages.Open(id);
		mcpServices.OpenFile = new (path, outError) => mPages.OpenFile(path, outError);
		mcpServices.ClosePage = new (page) => { mPages.Close(page); };
		// An agent's delete is the browser's own: its pages closed, the default scene let go.
		mcpServices.DeleteAsset = new (id) => mAssetOps.DeleteOne(id);
		// The windows' screenshots, over the same capture as View > Screenshot.
		mcpServices.Windows = new (outWindows) => { CapturableWindows(outWindows); };
		mcpServices.RequestShots = new (requests) => { mWindowCapture.Request(requests); };
		mcpServices.Shots = new (outShots) => { mWindowCapture.Shots(outShots); };
		// The main window's GUI, which the input tools drive.
		mcpServices.GuiRoot = new () => mWindow.Root;
		// What a file dropped on it does, which editor_drop does too.
		mcpServices.DropFiles = new (paths, error) => DropFiles(paths, error);
		// The dock's layout tools, over its controller, the action bridge, its unattended
		// calls refusing the window root's modal windows (both outlive the host, which stops
		// first; a headless run has no root, so nothing to refuse), and the build tools.
		mcpServices.AddTools = new (server) =>
			{
				EditorLayoutTools.Register(server, mDock.Controller);
				let actionSeams = new ActionToolSeams();
				actionSeams.Context = mContext;
				actionSeams.Dialogs = (mWindow.Root != null) ? mWindow.Root.EventDispatcher : null;
				EditorActionTools.Register(server, actionSeams);
				EditorBuildTools.Register(server, BuildToolServices());
			};
		mMcp = new EditorMcpService(mcpServices);

		RegisterActions();
	}

	/// The parts stopped in the order shutdown needs: the project closed (its hook stops the MCP
	/// host first, then the cook, the thumbnails and the resources go), the MCP host released,
	/// the cook joined, and the jobs joined before the export whose data a running one reads.
	/// OnShutdown calls it; a headless run (the tests) calls it alone. Again: nothing left to do.
	public void StopParts()
	{
		mSession.Close();
		DeleteAndNullify!(mMcp);
		mCookService.Shutdown(); // joins a cook in flight
		// The editor's long work: what waits is dropped, what runs is told and waited for (an export
		// reading EditorExport's copies), no cancelled completion run.
		mContext.Tasks.CancelAll();
		mContext.Tasks.Finish();
	}

	/// The editor owns a second, persistent runtime context populated by the SAME
	/// DefaultApplication the player runs: gameplay subsystems live there, and every scene
	/// (editing pages, Simulate, previews, the Game tab) is hosted there. It starts with no
	/// resource manager: projects open and close at runtime, so each project's manager attaches
	/// and detaches (EditorSession).
	private void StartEmbeddedRuntime(IApplicationHost host)
	{
		mEmbeddedHost = new EmbeddedApplicationHost(host, mRuntimeContext);
		delete mEmbeddedExitHandler;
		mEmbeddedExitHandler = new (code) =>
			{
				// A Game tab routes its own instance's exit to its own run; what reaches here is
				// an instance no tab is playing, which has no run to stop.
				GlobalLog(.Information, "Editor: embedded app requested exit({}) with no Game tab playing it", code);
			};
		mEmbeddedHost.SetExitHandler(mEmbeddedExitHandler);
		mEmbeddedApp = new DefaultApplication();
		mEmbeddedApp.SetDataRoot(mConfig.DataRoot); // the editor's root, not a re-walk
		mEmbeddedApp.Configure(mEmbeddedHost);
		// Un-bound input never reaches scene-tier game UI here: editing and Simulate HUDs render
		// as they will but do not take input; the Game tab is the interactive surface.
		if (mEmbeddedApp.Input != null)
			mEmbeddedApp.Input.UnboundScenePolicy = .ScreenTierOnly;
		// Each Game tab runs its own game inside this one application, with screens of its own
		// (menus, HUD, pause), so tabs never draw or drive each other's screens.
		if (mEmbeddedApp.Gui != null)
			mEmbeddedApp.Gui.RunScreens = true;
		mRuntimeContext.Startup();
		mEmbeddedApp.OnStartup(mEmbeddedHost);
	}

	/// The dock in the frame: the shared panels, their contents the window's markup, Assets the
	/// project's content, the Console the log.
	private void OpenDock()
	{
		let into = mWindow.FindById("frame-dock");
		if (into == null)
		{
			GlobalLog(.Error, "Editor: the frame has no frame-dock: the editor runs without its dock");
			return;
		}
		let contents = new EditorDockContents();
		contents.Welcome = new () => mWindow.LoadMarkup("Editor/Welcome.xml");
		{
			let assets = new AssetsViewServices();
			assets.Context = mContext;
			assets.Cook = mCookService;
			RefServices(); // the type icons
			assets.Icons = mTypeIcons;
			assets.Open = new (instance) => { mPages.OpenForUser(instance.Id); };
			assets.Picture = new (id) => mThumbnailService.Get(id);
			assets.Operations = mAssetOps;
			assets.Create = new (creator, group, name) => { mCreation.CreateAndOpen(creator, group, name); };
			assets.AskName = new (request) => { AskName(request); };
			assets.Import = new (group) => { PickFilesToImport(group); };
			mAssets = new AssetsView(assets, mWindow.LoadMarkup(AssetsView.cMarkupPath));
			// A slot's reveal (and any other) shows the asset where it lives, the panel to the front.
			delete mContext.RevealAsset;
			mContext.RevealAsset = new (id) =>
				{
					if ((mAssets != null) && mAssets.Reveal(id))
						mDock.BringToFront(EditorDock.cPanelAssets);
				};
			if (mContext.OpenAsset == null)
				mContext.OpenAsset = new (id) => { mPages.OpenForUser(id); };
		}
		contents.Assets = new () =>
			{
				let content = mAssets.Content;
				if (content != null)
					content.AddRef(); // the dock's
				return content;
			};
		mConsole = new LogView(mWindow.LoadMarkup(LogView.cMarkupPath));
		mConsole.SetOnCopied(new (lines) => { mContext.Notify(.Success, (lines == 1) ? "Copied 1 log line" : scope:: $"Copied {lines} log lines"); });
		contents.Console = new () =>
			{
				let content = mConsole.Content;
				if (content != null)
					content.AddRef(); // the dock's
				return content;
			};
		{
			let seams = new ProfilerPanelSeams();
			seams.Store = GlobalProfiler(); // installed at start-up
			seams.Recorder = CaptureRecorder.Process;
			PathJoin(GetUserDataDirectory(.. scope .()), "profiles", seams.Folder);
			seams.Pick = new (request) => { ShowPicker(request); };
			// A save's toast stays with Open Folder, as an export's does.
			seams.Notify = new (kind, message, folder) =>
				{
					if (folder.IsEmpty)
					{
						ShowToast(kind, message);
						return;
					}
					let saved = new String(folder);
					ShowToast(kind, message, "Open Folder", new [=this, =saved] () =>
						{
							if (let dialogs = ShellDialogs())
								dialogs.OpenPath(saved);
						} ~ delete saved);
				};
			mProfiler = new ProfilerPanel(seams, mWindow.LoadMarkup(ProfilerPanel.cMarkupPath));
		}
		contents.Profiler = new () =>
			{
				let content = mProfiler.Content;
				if (content != null)
					content.AddRef(); // the dock's
				return content;
			};
		{
			let seams = new McpPanelSeams();
			seams.Activity = new () => (mMcp != null) ? mMcp.Activity : null;
			seams.Listening = new () => (mMcp != null) && mMcp.IsRunning;
			seams.Port = new () => (mMcp != null) ? mMcp.Port : 0;
			seams.ConfiguredPort = new () => (mMcp != null) ? mMcp.ConfiguredPort : 0;
			seams.Client = new (outClient) =>
				{
					if ((mMcp == null) || mMcp.ClientName.IsEmpty)
						return;
					outClient.Append(mMcp.ClientName);
					if (!mMcp.ClientVersion.IsEmpty)
						outClient.AppendF(" {}", mMcp.ClientVersion);
				};
			seams.Start = new () => (mMcp != null) && mMcp.StartByUser(mSession.Project);
			seams.Stop = new () =>
				{
					if (mMcp != null)
						mMcp.StopByUser();
				};
			seams.ConnectCommand = new (outCommand) =>
				{
					if (mMcp != null)
						mMcp.ConnectCommand(outCommand);
				};
			seams.StartsWithProject = new () => mEditorSettings.Section<EditorMcpSettings>().Enabled;
			seams.SetStartsWithProject = new (on) =>
				{
					mEditorSettings.Section<EditorMcpSettings>().Enabled = on;
					if (!(EditorSettingsStore.SaveToUserData(mEditorSettings) case .Ok))
						mContext.Notify(.Warning, "The MCP preference could not be saved.");
				};
			seams.Copy = new (text, what) =>
				{
					let root = mWindow.Root;
					let dispatcher = (root != null) ? root.EventDispatcher : null;
					mContext.CopyText((dispatcher != null) ? dispatcher.Clipboard : null, text, what);
				};
			seams.Preferences = new () => { OpenPreferences(); };
			mMcpPanel = new McpPanel(seams, mWindow.LoadMarkup(McpPanel.cMarkupPath));
		}
		contents.Mcp = new () =>
			{
				let content = mMcpPanel.Content;
				if (content != null)
					content.AddRef(); // the dock's
				return content;
			};
		mDock.Open(into, mWindow.Host, contents);
		if (let status = mWindow.StatusBar)
			status.SetOnAgentClicked(new () => { mDock.BringToFront(EditorDock.cPanelMcp); });
	}

	/// The log's new lines into the Console, once a frame on the main thread.
	private void DrainLog()
	{
		if ((mConsole == null) || (mConfig.LogBuffer == null))
			return;
		let entries = scope List<EditorLogEntry>();
		defer { ClearAndDeleteItems!(entries); }
		mLogSequence = mConfig.LogBuffer.CollectSince(mLogSequence, entries);
		for (let entry in entries)
			mConsole.AddEntry(entry.Level, entry.Category, entry.Message, entry.Time);
	}

	/// The frame's menu bar and keys from the action registry, File > New <creator> leading the
	/// File menu (a creator with a category in a submenu of that name). Nothing with no interface.
	private void BuildMenus()
	{
		let bar = mWindow.FindById("menubar") as Sedulous.GUI.MenuBar;
		if ((bar == null) || (mWindow.Root == null))
			return; // no interface
		mShortcuts = new ActionShortcuts(mWindow.Host.Context.Keymap, mWindow.Root, mContext.Actions);
		mMenus = new ActionMenuBar(bar, mContext.Actions);
		// The application's menus in their places; a domain's menu (Scene) or an extension's takes
		// the "*" slot, so Help stays last however late they register.
		mMenus.SetMenuOrder(scope StringView[]("File", "Edit", "Project", "Build", "Game", "View", "*", "Help"));
		mMenus.AddLeadingItems("File", new (file) => { mCreation.AddNewItems(file); });
	}

	/// The palette over the main window, its frame the editor's markup (read the first time).
	/// Nothing with no interface.
	private void OpenCommandPalette()
	{
		let root = mWindow.Root;
		if (root == null)
			return;
		if (mPalette == null)
			mPalette = new CommandPalette(mContext.Actions, mWindow.LoadMarkup(CommandPalette.cMarkupPath));
		mPalette.Open(root);
	}

	/// Preferences over the main window (made the first time), the look shown live in the window.
	/// Nothing with no interface.
	private void OpenPreferences()
	{
		let root = mWindow.Root;
		if (root == null)
			return;
		if (mPreferences == null)
		{
			let services = new EditorPreferencesServices();
			services.User = mEditorSettings;
			services.Actions = mContext.Actions;
			services.Warn = new (text) => { mContext.Notify(.Warning, text); };
			services.Contributions = mContext.EditorSettingsContributions;
			services.McpChanged = new () =>
				{
					// The host follows the saved section, over the open project:
					// started, moved to its new port, or stopped (Start stops a running one first);
					// the user's own Start or Stop no longer holds.
					if (mMcp == null)
						return;
					mMcp.Restart(mSession.Project);
				};
			services.ShowLook = new (look) => { mWindow.SetLook(look); };
			// Said on the status line, or as an error, as the Sedulous.UI dialog said it.
			services.Persist = new () =>
				{
					if (EditorSettingsStore.SaveToUserData(mEditorSettings) case .Ok)
					{
						mContext.SetStatus("Preferences saved.");
						return true;
					}
					mContext.Notify(.Error, "Preferences save FAILED (see console).");
					return false;
				};
			mPreferences = new EditorPreferencesDialog(services, mWindow.LoadMarkup(EditorPreferencesDialog.cMarkupPath));
		}
		mPreferences.Open(root);
	}

	/// Project Settings over the main window (made the first time), the manifest as it is now.
	/// Nothing with no interface.
	private void OpenProjectSettings()
	{
		let root = mWindow.Root;
		if (root == null)
			return;
		if (mProjectSettings == null)
			mProjectSettings = new ProjectSettingsDialog(mContext, RefServices(), mWindow.LoadMarkup(ProjectSettingsDialog.cMarkupPath));
		mProjectSettings.Open(root);
	}

	/// The shell's native dialogs; null with no shell.
	private IDialogService ShellDialogs() => ((mHost != null) && (mHost.Shell != null)) ? mHost.Shell.Dialogs : null;

	/// Project > Add Native Code: asks which parts of the game's package to scaffold (those it has
	/// show checked), then scaffolds them (GamePackage.Scaffold) and says what it did.
	private void AddNativeCode()
	{
		let project = mSession.Project;
		let root = mWindow.Root;
		if ((project == null) || (root == null))
			return;
		let info = scope GamePackageInfo();
		let request = new NativeCodeRequest();
		if (GamePackage.Find(project, info))
			request.Existing.AddRange(info.Parts);
		// "Code/", the folder the dialog says it makes or adds to.
		request.Path.AppendF("{}/", info.Path);
		request.Accepted = new [=this] (parts) =>
			{
				let open = mSession.Project;
				if (open == null)
					return;
				if (GamePackage.Scaffold(open, parts) case .Err(let err))
				{
					if (err == .AlreadyExists)
						mContext.Notify(.Warning, "Those parts are there already, or the game's id is enabled elsewhere or a part's folder is in Code/ already: nothing was touched.");
					else
						mContext.Notify(.Error, "Add Native Code failed (see Console).");
					return;
				}
				mContext.NotifyProjectSettingsChanged();
				mContext.Notify(.Success, "Native code scaffolded in the game's package in Code/: Project > Build Project builds it.");
			};
		// The one before is closed: the dialog is modal, so it is asked again only once it is.
		DeleteAndNullify!(mNativeCodeDialog);
		mNativeCodeDialog = NativeCodeDialog.Open(root, mWindow.LoadMarkup(NativeCodeDialog.cMarkupPath), request);
	}

	/// Project > Build Project: the project's own editor, in Debug (a BuildJob of BuildTarget.Editor)
	/// on the build lane through the build service, BeefBuild's output to the Console as it comes.
	private void BuildProject()
	{
		let project = mSession.Project;
		if (project == null)
			return;
		if (mContext.Tasks.IsLaneBusy(mContext.BuildLane))
		{
			mContext.Notify(.Info, "The build lane is busy: build the project once it is done.");
			return;
		}
		let error = scope String();
		let job = EditorBuildTools.StartBuild(mContext, mBuildService, project, mConfig.DataRoot, .Editor, "", "", error);
		if (job == null)
		{
			mContext.Notify(.Error, scope $"Build Project: {error}.");
			return;
		}
		job.ReleaseRef();
		mContext.SetStatus("Building the project...");
		// Said when it starts, not only when it ends: the first build compiles the engine beside
		// the project's packages, which takes minutes.
		mContext.Notify(.Info, "Building the project - this takes a few minutes (see Console).");
	}

	/// What the build tools work through: the build service, the open project, the pages'
	/// unsaved work, this host's port, and the launch and exit Open With This Build makes.
	private BuildToolSeams BuildToolServices()
	{
		let seams = new BuildToolSeams();
		seams.Service = mBuildService;
		seams.DataRoot.Set(mConfig.DataRoot);
		seams.Start = new (target, config, platform, outError) =>
			{
				let project = mSession.Project;
				if (project == null)
				{
					outError.Append("no project is open");
					return null;
				}
				return EditorBuildTools.StartBuild(mContext, mBuildService, project, mConfig.DataRoot, target, config, platform, outError);
			};
		seams.Project = new () => mSession.Project;
		seams.UnsavedWork = new (outLines) => { mPages.UnsavedWork(outLines); };
		seams.McpPort = new () => (mMcp != null) ? mMcp.Port : 0;
		seams.Launch = new (executable, arguments) => Sedulous.Core.Process.Start(executable, arguments);
		seams.Context = mContext;
		seams.ManagerPath.Set(mConfig.ManagerPath);
		seams.NeedsBuild = new (project) => EditorRelaunch.NeedsBuildOverSdk(project, mConfig.DataRoot);
		seams.KeepAside = new (folder, state, outRefused) => mPages.KeepAside(folder, state, outRefused);
		seams.AskUnsaved = new (proceed) => { mPages.ConfirmUnsavedThen("Save All and Relaunch", "Relaunch Without Saving", proceed); };
		seams.SaveState = new (state) =>
			{
				mPages.CaptureRelaunch(state); // each page's view, the Game tabs, the active page
				mSession.SaveStore(); // the open pages and the dock, written for the next editor
			};
		// The relaunch kept or dropped what is unsaved, or nothing is: no prompt. The store stays as
		// the relaunch wrote it while this editor closes.
		seams.Exit = new () =>
			{
				mSession.FreezeStore();
				if (mHost != null)
					mHost.RequestExit();
			};
		return seams;
	}

	/// The seams Build and Relaunch works through: the build tools', the next editor serving MCP
	/// as Open With This Build passes it on (on this host's port while it listens, else as the
	/// command line asked).
	private BuildToolSeams RelaunchServices()
	{
		let seams = BuildToolServices();
		seams.McpServes = new () => ((mMcp != null) && mMcp.IsRunning) || mConfig.McpEnabled;
		delete seams.McpPort;
		seams.McpPort = new () => ((mMcp != null) && mMcp.IsRunning) ? mMcp.Port : (uint16)mConfig.McpPort;
		return seams;
	}

	/// What the editor this one replaced kept (--relaunch): the pages kept aside given their content
	/// back unsaved, the Game tabs opened and played again, the active page brought forward, and the
	/// relaunch's phases logged. The folder goes once everything came back; a page that did not
	/// leaves it, said. Once: the next project open restores nothing.
	private void RestoreRelaunch()
	{
		if (mConfig.RelaunchFolder.IsEmpty)
			return;
		let folder = scope String(mConfig.RelaunchFolder);
		mConfig.RelaunchFolder.Clear();
		let state = RelaunchState.Load(folder);
		if (state == null)
		{
			GlobalLog(.Warning, "Editor: --relaunch named '{}', which holds no relaunch state: nothing restored beyond the project's pages", folder);
			return;
		}
		defer delete state;
		if (mPages.RestoreRelaunch(folder, state))
			RemoveDirectoryRecursive(folder);
		let timings = state.DescribeTimings(mCreatedTicks, DateTime.UtcNow.Ticks, .. scope .());
		GlobalLog(.Information, "Editor: relaunched ({} page(s) kept aside, {} Game tab(s)): {}", state.Kept.Count, state.Games.Count, timings);
		mContext.SetStatus(scope $"Relaunched: {timings}");
	}

	/// The watch over the open project's own code, swept every CodeWatch.cPollSeconds on this
	/// thread as the cook's watch over Sources/ is (the packages less what builds write are a
	/// game's source, a few files): a change this editor lacks is said once, with what to do.
	private void WatchCode()
	{
		let project = mSession.Project;
		if (project !== mCodeWatched)
		{
			mCodeWatch.Reset();
			mCodeWatched = project;
			mCodeWatchSwept = 0;
		}
		if ((project == null) || !ProjectBuild.HasPackages(project.Settings))
			return;
		let now = System.Diagnostics.Stopwatch.GetTimestamp();
		if ((mCodeWatchSwept != 0) && ((now - mCodeWatchSwept) < (int64)(CodeWatch.cPollSeconds * 1000000)))
			return;
		mCodeWatchSwept = now;
		let game = ProjectBuild.GameName(project.Settings.Name, .. scope .());
		let editor = ProjectBuild.ExecutablePath(project.Directory, game, true, EditorBuildTools.cEditorConfig, .. scope .());
		if (!mCodeWatch.Observe(ProjectBuild.NewestSource(project.Directory, project.Settings), ProjectBuild.FileTime(editor),
			EditorBuildTools.RunningExecutableTime, ProjectBuild.LinksPackages(project.Settings, mContext.Plugins)))
			return;
		let text = CodeWatch.NoticeText(mCodeWatch.State, .. scope .());
		GlobalLog(.Information, "Editor: {}", text);
		mContext.Notify(.Info, text);
		mContext.SetStatus(text);
	}

	/// Project > Open With This Build: starts the project's own editor (Build Project's, in
	/// Debug) on the project and this editor's data root, then this one exits the usual way,
	/// asking about unsaved pages. When this editor serves MCP, the new one serves it on the same
	/// port, so a connected agent reconnects there; otherwise the command line's MCP options
	/// pass on as given.
	private void OpenWithThisBuild()
	{
		let project = mSession.Project;
		if (project == null)
			return;
		let game = ProjectBuild.GameName(project.Settings.Name, .. scope .());
		let editor = ProjectBuild.ExecutablePath(project.Directory, game, true, "Debug", .. scope .());
		if (!FileExists(editor))
		{
			mContext.Notify(.Error, "Build Project first: the project's own editor is not built.");
			return;
		}
		let listening = (mMcp != null) && mMcp.IsRunning;
		let commandLine = scope List<String>();
		defer { ClearAndDeleteItems!(commandLine); }
		EditorBuildTools.RelaunchArguments(project.Directory, mConfig.DataRoot, listening || mConfig.McpEnabled,
			listening ? (uint32)mMcp.Port : mConfig.McpPort, commandLine);
		let arguments = scope StringView[commandLine.Count];
		for (int i < commandLine.Count)
			arguments[i] = commandLine[i];
		if (!Sedulous.Core.Process.Start(editor, arguments))
		{
			mContext.Notify(.Error, scope $"Could not start '{editor}'.");
			return;
		}
		GlobalLog(.Information, "Editor: the project opened in its own build ({}); this editor exits", editor);
		ConfirmExit();
	}

	/// Export over the main window, for the open project (made again for each project: it edits
	/// that project's presets). Nothing with no interface or no project.
	private void OpenExport()
	{
		let root = mWindow.Root;
		let project = mSession.Project;
		if ((root == null) || (mExport == null) || (project == null))
			return;
		if ((mExportDialog == null) || (mExportProject !== project))
		{
			DeleteAndNullify!(mExportDialog);
			mExportProject = project;
			let seams = new ExportDialogSeams();
			seams.Save = new () => { mExport.SavePresets(); };
			seams.RunExport = new (preset, all) => { mExport.Run(preset, all); };
			seams.PickFiles = new (chosen) =>
				{
					let dialogs = ShellDialogs();
					if (dialogs == null)
					{
						mContext.Notify(.Error, "File dialogs are unavailable.");
						chosen(.());
						delete chosen;
						return;
					}
					// The service consumes the callback once it answers.
					dialogs.ShowOpenFile(new [=chosen] (paths) => { chosen(paths); } ~ delete chosen, .(), "", true, 0);
				};
			seams.Pick = new (request) => { ShowPicker(request); };
			seams.Notify = new (message) => { mContext.Notify(.Warning, message); };
			// Absolute, as the system's dialog answers.
			if (PathIsAbsolute(project.Directory))
				seams.ProjectRoot.Set(project.Directory);
			else
				PathJoin(GetCurrentDirectory(.. scope .()), project.Directory, seams.ProjectRoot);
			seams.HostPlatform.Set(BuildLayout.HostPlatformName);
			seams.ProjectName.Set(project.Name);
			// Absolute, as the export writes it: the project directory can be relative.
			let dist = PathJoin(project.Directory, ProjectLayout.DistDir, .. scope .());
			if (PathIsAbsolute(dist))
				seams.OutputRoot.Set(dist);
			else
				PathJoin(GetCurrentDirectory(.. scope .()), dist, seams.OutputRoot);
			mExportDialog = new ExportDialog(mExport.Presets, seams, mWindow.LoadMarkup(ExportDialog.cMarkupPath));
		}
		mExportDialog.Open(root);
	}

	/// Shows a picker's request in the middle of the main window; the picker is made the first
	/// time. OWNERSHIP of `request` transfers, shown or not.
	public void ShowPicker(PickerRequest request)
	{
		let root = mWindow.Root;
		if (root == null)
		{
			delete request;
			return;
		}
		PickerMade().Open(root, request);
	}

	/// Opens the asset picker (its groups beside what each holds) over the main window for
	/// `request`; it is made the first time. OWNERSHIP of `request` transfers, shown or not.
	/// Opens Create Asset over the window, titled `title` ("New Clip"), the group `group` (null: the
	/// project's top) and the name `suggested` to start; `create` is told the group and the name
	/// chosen (the caller makes the asset). TAKES OWNERSHIP of `create`.
	public void ShowCreateAsset(StringView title, StringView suggested, Group group, delegate void(Group group, StringView name) create)
	{
		let root = mWindow.Root;
		let project = mContext.Project;
		if ((root == null) || (project == null))
		{
			delete create;
			return;
		}
		let sources = project.SourceDb;
		// The one before is closed: Create Asset is modal, so a page asks again only once it is.
		DeleteAndNullify!(mCreateAsset);
		mCreateAsset = AssetCreate.Open(root, mWindow.LoadMarkup(AssetCreate.cMarkupPath), sources,
			(group != null) ? group : sources.RootGroup, title, suggested, create);
	}

	/// Asks for a name (the name prompt) for `request` over the window. TAKES OWNERSHIP of
	/// `request`.
	public void AskName(NameRequest request)
	{
		let root = mWindow.Root;
		if (root == null)
		{
			delete request;
			return;
		}
		// The one before is closed: the prompt is modal, so it is asked again only once it is.
		DeleteAndNullify!(mNamePrompt);
		mNamePrompt = NamePrompt.Open(root, mWindow.LoadMarkup(NamePrompt.cMarkupPath), request);
	}

	public void ShowAssetPicker(AssetPickRequest request)
	{
		let root = mWindow.Root;
		if (root == null)
		{
			delete request;
			return;
		}
		if (mAssetPicker == null)
		{
			let services = new AssetPickerServices();
			services.Context = mContext;
			services.Icons = TypeIcons();
			services.Picture = new (id) => mThumbnailService.Get(id);
			mAssetPicker = new AssetPickerWindow(services, mWindow.LoadMarkup(AssetPickerWindow.cMarkupPath));
		}
		mAssetPicker.Open(root, request);
	}

	/// The one picker, made the first time.
	private Picker PickerMade()
	{
		if (mPicker == null)
			mPicker = new Picker(mWindow.LoadMarkup(Picker.cMarkupPath));
		return mPicker;
	}

	/// Imports files into a group: at once when nothing needs review, else through the import
	/// window over the main window (made the first time), which says so when one is open already.
	public void ImportFiles(Span<StringView> paths, Group group)
	{
		ImportWindow.Run(mAssetImport, mContext, paths, group, mWindow.Root, scope () => ImportWindowMade());
	}

	/// The import window over the main window, made the first time.
	private ImportWindow ImportWindowMade()
	{
		if (mImportWindow == null)
		{
			mImportWindow = new ImportWindow(mAssetImport, PickerMade(), mWindow.LoadMarkup(ImportWindow.cMarkupPath));
			mImportWindow.Icons = TypeIcons();
			mImportWindow.Previews = mContext.ImportPreviews;
			mImportWindow.Tasks = mContext.Tasks;
			mImportWindow.AskName = new (request) => { AskName(request); };
			mImportWindow.Operations = mAssetOps;
		}
		return mImportWindow;
	}

	/// Build > Reimport...: the import window on the page's asset's file, into its group, with the
	/// settings it was imported with; said when it cannot be.
	private void ReimportPage(EditorPage page)
	{
		let why = scope String();
		let session = mAssetImport.BeginReimport(page.InstanceId, why);
		if (session == null)
		{
			mContext.Notify(.Warning, why);
			return;
		}
		defer session.ReleaseRef(); // the window takes its own
		ImportWindow.Review(mContext, session, mWindow.Root, scope () => ImportWindowMade());
	}

	/// Import... in a group's menu: files picked with the OS's dialog, imported into the group,
	/// found again by its key when the dialog answers (it may have gone meanwhile).
	private void PickFilesToImport(Group group)
	{
		let dialogs = ShellDialogs();
		if (dialogs == null)
		{
			mContext.Notify(.Error, "File dialogs are unavailable.");
			return;
		}
		let key = GroupPicker.KeyOf(group, .. new .());
		// The service consumes the callback once it answers.
		dialogs.ShowOpenFile(new [=this, =key] (paths) =>
			{
				if (paths.Length == 0)
					return; // cancelled
				let project = mSession.Project;
				let into = (project != null) ? GroupPicker.Find(project.SourceDb, key) : null;
				if (into == null)
				{
					mContext.Notify(.Warning, "The group the import goes in is gone: choose another.");
					return;
				}
				let chosen = scope List<StringView>();
				for (let path in paths)
					chosen.Add(path);
				ImportFiles(chosen, into);
			} ~ delete key, .(), "", true, 0);
	}

	/// Files dropped on the main window (from the operating system, or editor_drop): imported into
	/// the group the Assets panel shows (else the top). False with `outError` when no project is
	/// open.
	public bool DropFiles(Span<StringView> paths, String outError)
	{
		let project = mSession.Project;
		if (project == null)
		{
			outError.Append("no project is open");
			return false;
		}
		ImportFiles(paths, ImportWindow.DropGroup(mAssets, project.SourceDb));
		return true;
	}

	/// Files dropped on the editor's windows this frame, handed to DropFiles. With no project they
	/// are let go.
	private void ImportDroppedFiles(IShell shell)
	{
		let dropped = scope List<DroppedFile>();
		defer { ClearAndDeleteItems!(dropped); }
		shell.DrainDroppedFiles(dropped);
		if (dropped.IsEmpty)
			return;
		let paths = scope List<StringView>();
		for (let file in dropped)
			paths.Add(file.Path);
		DropFiles(paths, scope .()); // with no project and no manager, a drop does nothing
	}

	/// What an asset slot or a page's picker asks of the editor (the scene page's prefab spawn, the
	/// inspector's references): the accepted types, the project's names, the picker (made the first
	/// time). The application's.
	public ResourceRefServices RefServices()
	{
		if (mRefs == null)
		{
			let window = mWindow;
			mTypeIcons = new EditorIcons(new [=window] (path) => (window.Resources != null) && window.Resources.Exists(path));
			mRefs = ResourceRefServices.From(mContext, mTypeIcons, new (request) => { ShowAssetPicker(request); });
		}
		return mRefs;
	}

	/// A type's icon, asked of the type (made the first time, with the slots' table). The
	/// application's.
	public EditorIcons TypeIcons()
	{
		RefServices();
		return mTypeIcons;
	}

	/// The source every page factory asks for PageServices; the registrations borrow it, and it
	/// lives as long as the editor.
	public AssetPageServicesSource PageServicesSource => mPageServices;

	/// What an asset page asks of the editor when it is made: its markup, the asset slots' table,
	/// the type icons, the host and the window's GUI a preview renders in. The caller owns it.
	public AssetPageServices PageServices()
	{
		let services = new AssetPageServices();
		let window = mWindow;
		services.LoadMarkup = new [=window] (path) => window.LoadMarkup(path);
		services.Refs = RefServices();
		services.Icons = TypeIcons();
		services.Host = mEmbeddedHost; // the runtime's, with its scenes and renderer (the scene page's too)
		services.Gui = mWindow.Host;
		services.Languages = mCodeLanguages;
		services.Pick = new (request) => { ShowPicker(request); };
		return services;
	}

	/// Exits once the unsaved pages are saved or let go; true when nothing needed asking (the
	/// shell's close handler: false keeps the window while the user is asked).
	private bool ConfirmExit()
	{
		return mPages.ConfirmUnsavedThen("Save All and Exit", "Exit Without Saving", new () =>
			{
				if (mHost != null)
					mHost.RequestExit();
			});
	}

	/// File > Close Project. The editor has one project, so closing it hands the user to the project
	/// manager (ManagerLauncher.Find: the one that launched this editor, else the one that ran last,
	/// else the SDK's own): once the unsaved pages are saved or let go, the manager starts and the
	/// editor exits. With no manager found, or one that does not start, it says so and stays, the
	/// project open. True when it went on at once (nothing unsaved to ask about).
	public bool CloseProject()
	{
		let manager = scope String();
		if (!ManagerLauncher.Find(mConfig.ManagerPath, mConfig.SdksPath, mConfig.DataRoot, manager))
		{
			mContext.Notify(.Warning, "No project manager was found to return to, so the project stays open (start the manager from the ProjectManager folder of your engine).");
			return false;
		}
		let path = new String(manager);
		return mPages.ConfirmUnsavedThen("Save All and Close", "Close Without Saving", new [=this, =path] () =>
			{
				if (!ManagerLauncher.Start(path, mConfig.DataRoot, mConfig.LaunchManager))
				{
					mContext.Notify(.Error, scope $"The project manager {path} did not start, so the project stays open.");
					return;
				}
				GlobalLog(.Information, "Editor: the project manager {} started; closing", path);
				if (mHost != null)
					mHost.RequestExit();
			} ~ delete path);
	}

	/// The editor-wide actions this lifecycle can run. What a later layer brings (saving the
	/// layout, the dialogs, the profiler) is given no hook here, so its action stays out until it
	/// can run.
	private void RegisterActions()
	{
		let actions = mContext.Actions;
		let file = new FileActions();
		file.Context = mContext;
		file.Save = new (page) => { mPages.Save(page); };
		file.SaveAs = new (page) => { mPages.SaveAs(page); };
		file.Exit = new () => { ConfirmExit(); };
		file.CloseProject = new () => { CloseProject(); };
		EditorAppActions.RegisterFileActions(actions, file);
		let edit = new EditActions();
		edit.Preferences = new () => { OpenPreferences(); };
		EditorAppActions.RegisterEditActions(actions, edit);

		let project = new ProjectActions();
		project.Context = mContext; // Report Resource Memory reads the session's resources through it
		project.Settings = new () => { OpenProjectSettings(); };
		project.ExportPresets = new () => { OpenExport(); };
		project.AddNativeCode = new () => { AddNativeCode(); };
		project.BuildProject = new () => { BuildProject(); };
		project.OpenWithThisBuild = new () => { OpenWithThisBuild(); };
		project.BuildAndRelaunch = new () => { mBuildAndRelaunch.Run(); };
		EditorAppActions.RegisterProjectActions(actions, project);

		// One page's asset: its changes saved first, so what cooks is what it shows.
		EditorAppActions.RegisterBuildActions(actions, mContext,
			new (page) => { CookPage(page, false); },
			new (page) => { CookPage(page, true); },
			new (page) => { ReimportPage(page); });

		// The Game tab through the context's GamePageFactory: unset until the play library
		// registers it, Play says so.
		let game = new GameActions();
		game.Context = mContext;
		game.Play = new () => { mPages.OpenGame(false); };
		game.PlayNewInstance = new () => { mPages.OpenGame(true); };
		EditorAppActions.RegisterGameActions(actions, game);

		let view = new ViewActions();
		view.Context = mContext;
		view.ResetLayout = new () => { mDock.ResetLayout(); };
		view.Assets = new () => { mDock.BringToFront(EditorDock.cPanelAssets); };
		view.Console = new () => { mDock.BringToFront(EditorDock.cPanelConsole); };
		view.Mcp = new () => { mDock.BringToFront(EditorDock.cPanelMcp); };
		view.Profiler = new () => { mDock.BringToFront(EditorDock.cPanelProfiler); };
		view.ProfilerRecording = new () => (mProfiler != null) && mProfiler.IsRecording;
		view.ProfilerRecord = new () =>
			{
				if (mProfiler == null)
					return;
				mDock.BringToFront(EditorDock.cPanelProfiler);
				if (mProfiler.IsRecording)
					mProfiler.Stop();
				else
					mProfiler.Start();
			};
		view.Screenshot = new () => { TakeEditorScreenshot(); };
		view.CommandPalette = new () => { OpenCommandPalette(); };
		EditorAppActions.RegisterViewActions(actions, view);

		let help = new HelpActions();
		help.About = new () => { ShowAbout(); };
		EditorAppActions.RegisterHelpActions(actions, help);
	}

	/// This build's identity, in a message box over the editor, with a button that copies it.
	/// Nothing with no interface.
	private void ShowAbout()
	{
		let root = mWindow.Root;
		if (root == null)
			return;
		let identity = Sedulous.Engine.Project.EngineVersion.BuildIdentity(.. scope .());
		let about = AboutBox.Make(identity, new (line) =>
			{
				let r = mWindow.Root;
				let dispatcher = (r != null) ? r.EventDispatcher : null;
				mContext.CopyText((dispatcher != null) ? dispatcher.Clipboard : null, line, "the version");
			});
		defer about.ReleaseRef(); // the popup and the tree hold it while it is open
		about.OpenModal(root);
	}

	public void OnUpdate(IApplicationHost host, float dt)
	{
		// Each step is scoped, so a frame capture accounts for the whole update.
		using (ProfileScope("Editor.Pumps"))
		{
			if (mMcp != null)
				mMcp.Pump(); // a waiting agent call is answered here: tools touch main-thread state
		}
		// The embedded runtime's frame first (per-scene fixed steps in BeginFrame, physics
		// interpolation in Update), so pages read fresh state; EndFrame closes in OnRenderWindow
		// after the scene bracket. The embedded app's own OnUpdate ticks every game instance's
		// game once a frame, however many Game tabs.
		if (mEmbeddedApp != null)
		{
			using (ProfileScope("Editor.Runtime"))
			{
				let scaled = dt * mRuntimeContext.TimeScale;
				mRuntimeContext.BeginFrame(dt);
				mRuntimeContext.Update(scaled);
				mRuntimeContext.PostUpdate(scaled);
				mEmbeddedApp.OnUpdate(mEmbeddedHost, dt);
			}
		}
		using (ProfileScope("Editor.Captures"))
		{
			UpdateCaptures(host, dt);
			if (let stage = mSession.Stage)
				stage.Update(); // take and stage the next queued GPU thumbnail
			LeakProbe.Update(dt);
		}
		// The cook's and the jobs' progress to the status line; an export waiting on its cook
		// starts.
		using (ProfileScope("Editor.Cook"))
		{
			mCookService.Update(scope (line) => { mContext.SetStatus(line); });
			if (mExport != null)
				mExport.Pump();
			WatchCode();
			mBuildAndRelaunch.Update(); // a Build and Relaunch whose build ended goes on
		}
		// The editor's long work: the import previews' reads, done off this thread; their completions
		// run here, their lines go to the status bar.
		using (ProfileScope("Editor.Tasks"))
		{
			mContext.Tasks.Pump(scope (task, line) => { mContext.SetStatus(line); });
			UpdateStatusBar();
		}
		if (let resources = mSession.Resources)
		{
			using (ProfileScope("Editor.Resources"))
			{
				resources.Pump(); // async loads finish
				resources.CollectGarbage(); // products a hot reload replaced go
			}
		}
		using (ProfileScope("Editor.Log"))
			DrainLog();
		if (mProfiler != null)
		{
			using (ProfileScope("Editor.Profiler"))
				mProfiler.Update(); // the frames recorded since, while recording
		}
		if (mMcpPanel != null)
		{
			using (ProfileScope("Editor.McpPanel"))
				mMcpPanel.Update(); // the host's state and the calls agents made since
		}
		if (mAssets != null)
		{
			using (ProfileScope("Editor.Assets"))
				mAssets.Refresh(); // an agent's write, a cook's badges: shown this frame
		}
		if (host.Shell != null)
			ImportDroppedFiles(host.Shell);
		using (ProfileScope("Editor.Window"))
			mWindow.Update(dt);
		using (ProfileScope("Editor.Pages"))
			mPages.Update(host, dt); // after the GUI laid out: viewport rects are current
		if (mImportWindow != null)
		{
			using (ProfileScope("Editor.ImportWindow"))
				mImportWindow.OnUpdate(host, dt); // the same for the import window's preview (a model's view)
		}
		if (mHome != null)
		{
			using (ProfileScope("Editor.Home"))
				mHome.Refresh();
		}
	}

	/// The status bar's job (a job's title, how far, its step of how many; else a cook, of
	/// unknown length) and the MCP item (its port or off, and the tool of a call still running). A
	/// job's progress no longer takes the message line.
	private void UpdateStatusBar()
	{
		let status = mWindow.StatusBar;
		if (status == null)
			return;
		let progress = scope JobProgress();
		if (let job = mContext.Tasks.RunningIn(mContext.BuildLane))
		{
			progress.Active = true;
			progress.Title.Set(job.Name);
			progress.Fraction = job.Fraction;
			job.GetStep(progress.Step);
			progress.StepIndex = job.StepIndex;
			progress.StepCount = job.StepCount;
		}
		status.ShowWork(progress, mCookService.IsCooking);
		let host = (mMcp != null) ? mMcp.Host : null;
		if ((host != null) && host.IsRunning)
		{
			let running = mMcp.Activity.RunningCall;
			let client = mMcp.ClientName;
			let tooltip = scope String();
			if (client.IsEmpty)
				tooltip.AppendF("MCP: listening on 127.0.0.1:{}. Show the MCP panel", host.BoundPort);
			else
				tooltip.AppendF("MCP: listening on 127.0.0.1:{}, {} connected. Show the MCP panel", host.BoundPort, client);
			status.SetAgent(true, scope $"MCP {host.BoundPort}", (running != null) ? (StringView)running.Tool : "", tooltip);
		}
		else
			status.SetAgent(false, "MCP off", "", "MCP: stopped. Show the MCP panel to start it");
	}

	/// Window screenshots: last frame's written, missing windows failed, the user told, and the
	/// command line's timed shot, rebuild and exit.
	private void UpdateCaptures(IApplicationHost host, float dt)
	{
		// Recorded last frame: written once the GPU has run the copies; a window closed before it
		// drew fails its capture rather than leaving it waiting.
		if ((host.Graphics != null) && (host.Graphics.Raw != null))
			mWindowCapture.Complete(host.Graphics.Raw);
		if (mWindowCapture.Busy)
		{
			let open = scope List<uint32>();
			if ((host.Shell != null) && (host.Shell.WindowManager != null))
			{
				for (let window in host.Shell.WindowManager.Windows)
				{
					if ((window != null) && window.IsOpen)
						open.Add(window.Id);
				}
			}
			mWindowCapture.FailMissing(open);
		}
		if (mAnnounceScreenshot && !mWindowCapture.Busy)
		{
			mAnnounceScreenshot = false;
			let shots = scope List<WindowShot>();
			mWindowCapture.Shots(shots);
			if (!shots.IsEmpty && (shots[0].State == .Written))
				mContext.Notify(.Success, scope $"Screenshot saved: {shots[0].Path}");
			else
				mContext.Notify(.Error, "The screenshot failed (the Console, category Screenshot, says why)");
		}

		let screenshotRequested = !mConfig.ScreenshotPath.IsEmpty;
		if ((mConfig.AutoExitSeconds <= 0.0f) && (mConfig.AutoRebuildSeconds <= 0.0f) && !screenshotRequested)
			return;
		mElapsed += dt;
		if ((mConfig.AutoExitSeconds > 0.0f) && (mElapsed >= mConfig.AutoExitSeconds))
			host.RequestExit();
		if ((mConfig.AutoRebuildSeconds > 0.0f) && !mAutoRebuilt && (mElapsed >= mConfig.AutoRebuildSeconds))
		{
			mAutoRebuilt = true;
			mCookService.RequestCook(true);
		}
		if (screenshotRequested && !mScreenshotFired && (mElapsed >= mConfig.ScreenshotAfterSeconds))
		{
			mScreenshotFired = true; // one shot: the next main-window frame records it
			if (let main = host.MainRenderWindow)
			{
				var request = WindowShotRequest(main.Window.Id, true, mConfig.ScreenshotPath);
				mWindowCapture.Request(.(&request, 1));
			}
		}
		// The capture settles a frame or two after it fires (record, then map and write); Busy
		// clears whether the file was written or the capture failed.
		if (screenshotRequested && mConfig.ScreenshotExit && mScreenshotFired && !mWindowCapture.Busy)
			host.RequestExit();
	}

	public void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		// Every page's viewport content renders in the MAIN window's frame, inside one
		// scene-renderer bracket, before the GUI draws: offscreen targets are window-agnostic, so
		// floats' windows sample what it made. Secondary-window frames are GUI only.
		if (frame.Valid && (frame.Window === host.MainRenderWindow))
		{
			// The bracket self-guards while the renderer is not ready.
			if (mSceneRenderer != null)
				mSceneRenderer.BeginRendering(frame.Encoder, frame.FrameIndex);
			using (ProfileScope("Editor.PagesRender"))
				mPages.Render(host, ref frame);
			if (mImportWindow != null)
			{
				using (ProfileScope("Editor.ImportWindowRender"))
					mImportWindow.OnRenderWindow(host, ref frame); // the import window's model preview
			}
			if (let stage = mSession.Stage)
				stage.Render(ref frame); // a thumbnail in the same bracket
			if (mSceneRenderer != null)
			{
				using (ProfileScope("Editor.SceneEnd"))
					mSceneRenderer.EndRendering();
			}
			using (ProfileScope("Editor.AfterScene"))
			{
				mPages.AfterSceneRender(host, ref frame); // overlays on the composed targets (the Game tab's UI)
				if (mEmbeddedApp != null)
					mRuntimeContext.EndFrame();
			}
		}
		using (ProfileScope("Editor.WindowRender"))
			mWindow.Render(ref frame);
		// A window screenshot: this window's finished backbuffer, the GUI included, when one of it
		// is armed. The copy sits in this frame's command stream; OnUpdate writes it next frame.
		if (frame.Valid && (frame.Window != null) && (frame.Encoder != null)
			&& (host.Graphics != null) && (host.Graphics.Raw != null))
		{
			mWindowCapture.Record(host.Graphics.Raw, frame.Encoder, frame.Window.Window.Id,
				frame.Backbuffer, frame.Window.Swap.Format, frame.Width, frame.Height);
		}
	}

	/// The ids of the windows that can draw a frame now, the main window first; empty while the
	/// main window is minimised (nothing to capture).
	private void CapturableWindows(List<uint32> outWindows)
	{
		outWindows.Clear();
		if (mHost == null)
			return;
		let main = mHost.MainRenderWindow;
		if ((main == null) || !main.Window.IsOpen || main.Window.IsMinimized)
			return; // a minimised editor draws no frame
		outWindows.Add(main.Window.Id);
		if ((mHost.Shell == null) || (mHost.Shell.WindowManager == null))
			return;
		for (let window in mHost.Shell.WindowManager.Windows)
		{
			if ((window != null) && (window.Id != main.Window.Id) && window.IsOpen && !window.IsMinimized)
				outWindows.Add(window.Id);
		}
	}

	/// View > Screenshot Editor (F12): the main window to a new PNG under
	/// <user-data>/screenshots, the path or the failure said once written.
	private void TakeEditorScreenshot()
	{
		let windows = scope List<uint32>();
		CapturableWindows(windows);
		if (windows.IsEmpty)
			return;
		let path = scope String();
		if (!EditorWindowTools.NewScreenshotPath("editor", path))
		{
			mContext.Notify(.Error, "Could not create the screenshots folder");
			return;
		}
		var request = WindowShotRequest(windows[0], true, path);
		mWindowCapture.Request(.(&request, 1));
		mAnnounceScreenshot = true;
	}

	public void OnShutdown(IApplicationHost host)
	{
		if ((host.Graphics != null) && (host.Graphics.Raw != null))
			mWindowCapture.Release(host.Graphics.Raw); // the readback buffers, while the device lives
		// The shell outlives the application: its close handler reaches this no more.
		if (mStarted && (host.Shell != null))
			host.Shell.SetMainWindowCloseHandler(null);
		StopParts();
		if (mEmbeddedApp != null)
		{
			mEmbeddedApp.OnShutdown(mEmbeddedHost);
			mRuntimeContext.Shutdown();
		}
		DeleteAndNullify!(mPreferences); // closed (the look back, unsaved), while the window is there
		DeleteAndNullify!(mProjectSettings); // closed (the manifest unchanged), while the window is there
		DeleteAndNullify!(mExportDialog); // closed, while the window and the export are there
		DeleteAndNullify!(mImportWindow); // closed (its session let go), while the window and the picker are there
		DeleteAndNullify!(mCreateAsset); // closed (its picking too), while the picker and the window are there
		DeleteAndNullify!(mPicker); // closed, while the window's root is there
		DeleteAndNullify!(mAssetPicker); // closed, while the window's root and the context are there
		DeleteAndNullify!(mPalette); // closed, while the window's root is there
		DeleteAndNullify!(mMenus); // the bar left empty while the window's tree holds it
		DeleteAndNullify!(mShortcuts); // its keys and the root's handlers, while both are there
		if ((mFocusListener != 0) && (mWindow.Host != null))
			mWindow.Host.RemoveWindowEventListener(mFocusListener);
		mFocusListener = 0;
		mDock.Close(); // its floats' windows, then the GUI before the device goes
		DeleteAndNullify!(mConsole); // its list let go, the dock having let go of its content
		DeleteAndNullify!(mProfiler); // the store let go if it records, the dock having let go of its content
		DeleteAndNullify!(mMcpPanel); // its list let go, the dock having let go of its content
		DeleteAndNullify!(mAssets); // its list and tree let go, the dock having let go of its content
		mWindow.Close();
		if (mStarted)
		{
			FontAtlasBakerFactory.SetAtlasCache(null); // ours goes with this application
			// A font cook registered the distance-field baker (FontAssetBuilder); it goes with the
			// editor, the cooks having stopped.
			DistanceFieldFonts.Shutdown();
		}
	}
}
