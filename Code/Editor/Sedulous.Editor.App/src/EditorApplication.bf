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
using Sedulous.Editor.Project;
using Sedulous.Profiler;

namespace Sedulous.Editor.App;

/// The editor as a runtime IApplication. It keeps the lifecycle alone (Raptor's editor-gui spec,
/// 5.1, layer 3): it configures the engine, starts its parts in order, hands each frame to them
/// and shuts them down. The parts are their own files: the window and its GUI (EditorWindow), its
/// dock (EditorDock), the pages in it (EditorPages), its menu bar (ActionMenuBar) and keys (ActionShortcuts), the open project (EditorSession), export
/// (EditorExport), asset creation (EditorAssetCreation), the MCP host (EditorMcpService), the
/// project manager over the window while no project is open (ProjectManagerMode) and the
/// editor-wide actions (EditorAppActions). Underneath are the EditorContext and the services from Editor.Core and
/// Editor.Project, and the EMBEDDED runtime every scene, preview and Game tab is hosted in: the
/// same DefaultApplication the player runs.
///
/// Raptor's native module is not a part here: Sedulous's editor does not handle a project's
/// native code (RaptorSync.md, "Standing differences").
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
	private Context mRuntimeContext = new .() ~ delete _;
	/// The host borrows it for as long as it is installed.
	private delegate void(int) mEmbeddedExitHandler = null ~ delete _;

	// The services the parts share. Declared before the parts, so they outlive them.
	private EditorContext mContext = new .() ~ delete _;
	/// Exe-assembled (RegisterEditors).
	private BuilderRegistry mBuilders = new .() ~ delete _;
	private EditorCookService mCookService = new .() ~ delete _;
	/// Background jobs: export, imports.
	private EditorJobService mJobService = new .() ~ delete _;
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
	/// The frame's menu bar, from the actions: made in OnStartup once they are all declared.
	private ActionMenuBar mMenus = null ~ delete _;
	/// The actions' keys in the GUI's keymap, made with the menu bar.
	private ActionShortcuts mShortcuts = null ~ delete _;
	/// Every action by name (View > Command Palette), made the first time it opens.
	private CommandPalette mPalette = null ~ delete _;
	/// Edit > Preferences, made the first time it opens.
	private EditorPreferencesDialog mPreferences = null ~ delete _;
	/// The Project panel while a project is open (made with its markup when one opens).
	private ProjectHomeView mHome = null ~ delete _;
	private EditorExport mExport = null ~ delete _;
	private EditorAssetCreation mCreation ~ delete _;
	private EditorMcpService mMcp = null ~ delete _;
	/// The open project: after the parts its hooks reach, so it closes first.
	private EditorSession mSession ~ delete _;
	/// The project manager while no project is open: after the session and the pages it reaches,
	/// so it goes first.
	private ProjectManagerMode mManagerMode ~ delete _;

	/// Screenshots of the editor's windows: --screenshot, editor_screenshot, View > Screenshot.
	private EditorWindowCapture mWindowCapture = new .() ~ delete _;
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
		mProjectManager = new ProjectManagerController(mEditorSettings);
		// Thumbnails are reachable from the constructor on: the registration block, where each
		// domain folds its thumbnail generator in, runs before the project opens.
		mContext.Thumbnails = mThumbnailService;
		mPages = new EditorPages(PagesServices());
		mCreation = new EditorAssetCreation(CreationServices());
		mSession = new EditorSession(SessionServices());
		mManagerMode = new ProjectManagerMode(ManagerModeServices());
	}

	public EditorContext Context => mContext;
	/// Null with no project open.
	public EditorProject Project => mSession.Project;
	/// The executable registers every engine builder here, the cook CLI's set; the cook service
	/// routes through it.
	public BuilderRegistry Builders => mBuilders;
	/// The engine data root this editor runs from (its config's, resolved at launch).
	public StringView DataRoot => mConfig.DataRoot;
	public EditorCookService CookService => mCookService;
	/// The resources over the open project's cooked database; null with no project.
	public ResourceManager Resources => mSession.Resources;
	/// Valid after OnStartup; the Game page drives its play bracket through it.
	public DefaultApplication EmbeddedApplication => mEmbeddedApp;
	public EditorWindow Window => mWindow;
	public EditorDock Dock => mDock;
	public EditorPages Pages => mPages;
	public EditorAssetCreation AssetCreation => mCreation;
	public EditorSession Session => mSession;
	/// The project manager's part; null once shut down.
	public ProjectManagerMode ManagerMode => mManagerMode;
	/// Null until StartParts.
	public EditorExport Export => mExport;
	/// Null until StartParts.
	public EditorMcpService McpService => mMcp;

	/// The renderer interface the application drives its per-frame scene bracket through; null
	/// means no scene rendering. Borrowed.
	public void SetSceneRenderer(ISceneRenderer renderer) => mSceneRenderer = renderer;

	/// A toast, as every notice and job result is said.
	public void ShowToast(NoticeKind kind, StringView message) => mWindow.ShowToast(kind, message);

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
		services.Jobs = mJobService;
		services.Builders = mBuilders;
		services.Thumbnails = mThumbnailService;
		services.UserSettings = mEditorSettings;
		services.Projects = mProjectManager;
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
				// The Project panel shows the project's page; its links open assets as the pages do.
				if (mWindow.IsOpen)
				{
					mHome = new ProjectHomeView(mContext, mCookService, mWindow.LoadMarkup(ProjectHomeView.cMarkupPath));
					mHome.SetOnOpenAsset(new (id) => { mPages.Open(id); });
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

	/// The project manager over the main window: its dialogs the shell's, the user's settings saved
	/// as its list changes.
	private ProjectManagerModeServices ManagerModeServices()
	{
		let services = new ProjectManagerModeServices();
		services.Projects = mProjectManager;
		services.Session = mSession;
		services.Pages = mPages;
		services.Root = new () => mWindow.Root;
		services.Dialogs = new () => ((mHost != null) && (mHost.Shell != null)) ? mHost.Shell.Dialogs : null;
		services.ShowScreen = new (screen) => { mWindow.ShowScreen(screen); };
		services.LoadMarkup = new (path) => mWindow.LoadMarkup(path);
		services.StoreChanged = new () => { EditorSettingsStore.SaveToUserData(mEditorSettings).IgnoreError(); };
		return services;
	}

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
		if (mWindow.Open(host, mConfig.DataRoot, look))
			OpenDock();
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

		if (mConfig.StartInProjectManager)
		{
			ReportStartup("Opening the project manager", 0.80f);
			mManagerMode.Enter();
		}
		else
		{
			ReportStartup(scope $"Opening {PathFilename(mConfig.ProjectDirectory, .. scope .())}", 0.70f);
			var options = EditorSessionOpenOptions();
			options.Scaffold = true; // a command line's bare folder becomes a project
			options.ScaffoldName = mConfig.ProjectName;
			options.Seed = mConfig.SeedOnScaffold;
			mSession.Open(mConfig.ProjectDirectory, options);
		}

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
		exportServices.Jobs = mJobService;
		exportServices.Builders = mBuilders;
		exportServices.UserSettings = mEditorSettings;
		exportServices.DataRoot.Set(mConfig.DataRoot);
		exportServices.OnExported = new (folder) => { ShowToast(.Success, scope $"Exported to {folder}"); };
		mExport = new EditorExport(exportServices);

		let mcpServices = new EditorMcpServiceServices();
		mcpServices.Context = mContext;
		mcpServices.Cook = mCookService;
		mcpServices.Jobs = mJobService;
		mcpServices.Builders = mBuilders;
		mcpServices.UserSettings = mEditorSettings;
		mcpServices.Log = mConfig.LogBuffer;
		mcpServices.DataRoot.Set(mConfig.DataRoot);
		mcpServices.ForceEnabled = mConfig.McpEnabled;
		mcpServices.Port = mConfig.McpPort;
		mcpServices.TemplatesRoot = new (outPath) => { mExport.TemplatesRoot(outPath); };
		mcpServices.OnCreated = new (creator, instance) => { mCreation.AfterCreate(creator, instance); };
		// The pages, over the paths the tabs take (a close at the next frame).
		mcpServices.OpenPage = new (id) => mPages.Open(id);
		mcpServices.ClosePage = new (page) => { mPages.Close(page); };
		// The windows' screenshots, over the same capture as View > Screenshot. The import notice
		// comes back with its layer; an agent's delete takes the database's own until the assets
		// view is on the GUI.
		mcpServices.Windows = new (outWindows) => { CapturableWindows(outWindows); };
		mcpServices.RequestShots = new (requests) => { mWindowCapture.Request(requests); };
		mcpServices.Shots = new (outShots) => { mWindowCapture.Shots(outShots); };
		// The dock's layout tools, over its controller, and the action bridge, its unattended
		// calls refusing the window root's modal windows (both outlive the host, which stops
		// first; a headless run has no root, so nothing to refuse).
		mcpServices.AddTools = new (server) =>
			{
				EditorLayoutTools.Register(server, mDock.Controller);
				let actionSeams = new ActionToolSeams();
				actionSeams.Context = mContext;
				actionSeams.Dialogs = (mWindow.Root != null) ? mWindow.Root.EventDispatcher : null;
				EditorActionTools.Register(server, actionSeams);
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
		mJobService.Shutdown(); // joins a job in flight (an export reading EditorExport's copies)
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
		if (mEmbeddedApp.UI != null)
			mEmbeddedApp.UI.RunScreens = true;
		if (mEmbeddedApp.Gui != null)
			mEmbeddedApp.Gui.RunScreens = true; // and the engine GUI's
		mRuntimeContext.Startup();
		mEmbeddedApp.OnStartup(mEmbeddedHost);
	}

	/// The dock in the frame: the shared panels, their contents the window's markup (Assets and
	/// Console a line each until their contents port, X4).
	private void OpenDock()
	{
		let into = mWindow.FindById("frame-dock");
		if (into == null)
		{
			GlobalLog(.Error, "Editor: the frame has no frame-dock: the editor runs without its dock");
			return;
		}
		let contents = new EditorDockContents();
		contents.Welcome = new () => mWindow.LoadMarkup("Editor/Welcome.gml");
		contents.Assets = Placeholder("The asset browser is not on the new interface yet.");
		contents.Console = Placeholder("The console is not on the new interface yet.");
		mDock.Open(into, mWindow.Host, contents);
	}

	/// A panel's content until its own ports: a line saying so. The caller owns the hook.
	private static delegate Sedulous.GUI.Node() Placeholder(StringView text)
	{
		let line = new String(text);
		return new () =>
			{
				let label = new Sedulous.GUI.Label();
				label.AddClass("panel-placeholder");
				label.Text = line;
				return label; // its one reference, the dock's
			} ~ delete line;
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
					// The host follows the saved section over the open project: started, moved to
					// its new port, or stopped (Start stops a running one first).
					if ((mMcp == null) || (mSession.Project == null))
						return;
					mMcp.Start(mSession.Project);
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
		// Back to the project manager: only when it launched the editor (a project given on the
		// command line keeps its one project; Exit is the way out).
		if (mConfig.StartInProjectManager)
		{
			file.CloseProject = new () =>
				{
					if (mManagerMode != null)
						mManagerMode.CloseProject();
				};
		}
		EditorAppActions.RegisterFileActions(actions, file);
		let edit = new EditActions();
		edit.Preferences = new () => { OpenPreferences(); };
		EditorAppActions.RegisterEditActions(actions, edit);

		let project = new ProjectActions();
		project.Context = mContext; // Report Resource Memory reads the session's resources through it
		EditorAppActions.RegisterProjectActions(actions, project);

		EditorAppActions.RegisterBuildActions(actions, mContext);

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
		view.Screenshot = new () => { TakeEditorScreenshot(); };
		view.CommandPalette = new () => { OpenCommandPalette(); };
		EditorAppActions.RegisterViewActions(actions, view);

		let help = new HelpActions();
		help.About = new () => { ShowAbout(); };
		EditorAppActions.RegisterHelpActions(actions, help);
	}

	/// The version, in a message box over the editor. Nothing with no interface.
	private void ShowAbout()
	{
		let root = mWindow.Root;
		if (root == null)
			return;
		let about = new Sedulous.GUI.MessageBox();
		defer about.ReleaseRef(); // the popup and the tree hold it while it is open
		about.Configure("About SedulousEngine", scope $"Version {EditorMcpService.BuildStamp(.. scope .())}", .Ok);
		about.OpenModal(root);
	}

	public void OnUpdate(IApplicationHost host, float dt)
	{
		if (mMcp != null)
			mMcp.Pump(); // a waiting agent call is answered here: tools touch main-thread state
		// The embedded runtime's frame first (per-scene fixed steps in BeginFrame, physics
		// interpolation in Update), so pages read fresh state; EndFrame closes in OnRenderWindow
		// after the scene bracket. The embedded app's own OnUpdate ticks every game instance's
		// script once a frame, however many Game tabs.
		if (mEmbeddedApp != null)
		{
			let scaled = dt * mRuntimeContext.TimeScale;
			mRuntimeContext.BeginFrame(dt);
			mRuntimeContext.Update(scaled);
			mRuntimeContext.PostUpdate(scaled);
			mEmbeddedApp.OnUpdate(mEmbeddedHost, dt);
		}
		UpdateCaptures(host, dt);
		LeakProbe.Update(dt);
		// The cook's and the jobs' progress to the status line; an export waiting on its cook
		// starts.
		mCookService.Update(scope (line) => { mContext.SetStatus(line); });
		mJobService.Update(scope (line) => { mContext.SetStatus(line); });
		if (mExport != null)
			mExport.Pump();
		UpdateStatusBar();
		if (let resources = mSession.Resources)
		{
			resources.Pump(); // async loads finish
			resources.CollectGarbage(); // products a hot reload replaced go
		}
		mWindow.Update(dt);
		mPages.Update(host, dt); // after the GUI laid out: viewport rects are current
		if (mHome != null)
			mHome.Refresh();
	}

	/// The status bar's job (a job's title, how far, its step of how many; else a cook, of
	/// unknown length) and agent (the MCP host while it listens). A job's progress no longer takes
	/// the message line.
	private void UpdateStatusBar()
	{
		let status = mWindow.StatusBar;
		if (status == null)
			return;
		let progress = scope JobProgress();
		if (mJobService.IsBusy)
			mJobService.Progress(progress);
		status.ShowWork(progress, mCookService.IsCooking);
		let host = (mMcp != null) ? mMcp.Host : null;
		if ((host != null) && host.IsRunning)
			status.SetAgent(scope $"MCP on 127.0.0.1:{host.BoundPort}");
		else
			status.SetAgent("");
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
			mPages.Render(host, ref frame);
			if (mSceneRenderer != null)
				mSceneRenderer.EndRendering();
			mPages.AfterSceneRender(host, ref frame); // overlays on the composed targets (the Game tab's UI)
			if (mEmbeddedApp != null)
				mRuntimeContext.EndFrame();
		}
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
		DeleteAndNullify!(mManagerMode); // its dialogs closed, while the window is there
		DeleteAndNullify!(mPalette); // closed, while the window's root is there
		DeleteAndNullify!(mMenus); // the bar left empty while the window's tree holds it
		DeleteAndNullify!(mShortcuts); // its keys and the root's handlers, while both are there
		mDock.Close(); // its floats' windows, then the GUI before the device goes
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
