namespace Sedulous.Editor;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.RuntimeGraphics;
using Sedulous.Engine.App;
using Sedulous.Shell;
using Sedulous.Shell.Input;
using Sedulous.Shaders;
using Sedulous.Fonts;
using Sedulous.Fonts.TTF;
using Sedulous.Fonts.Resources;
using Sedulous.VG;
using Sedulous.VG.Renderer;
using Sedulous.UI;
using Sedulous.UI.Shell;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;
using Sedulous.Editor.Core;
using Sedulous.UI.Viewport;
using Sedulous.Profiler;
using Sedulous.Engine.Core;
using Sedulous.Core;
using Sedulous.Core.Logging.Abstractions;
using Sedulous.Engine.Core.Resources;
using Sedulous.Engine;
using Sedulous.Engine.Render;
using Sedulous.Geometry.Resources;
using Sedulous.Resources;
using Sedulous.VFS;
using Sedulous.VFS.Disk;
using Sedulous.Engine.Navigation;
using Sedulous.Engine.Audio;
using Sedulous.Audio;
using Sedulous.Audio.Decoders;
using Sedulous.Audio.Resources;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Physics;
using Sedulous.Engine.DefaultApp;
using Sedulous.Models.FBX;
using Sedulous.Models.GLTF;
using Sedulous.Images.STB;
using System.IO;
using Sedulous.Serialization;
using Sedulous.Editor.Pages;

/// The Sedulous Editor application.
/// Implements IApplication for hosting via ApplicationHost. Manages its own
/// UIContext/RootView and rendering pipeline (not via UISubsystem).
/// Creates a RuntimeContext with engine subsystems for scene preview.
class EditorApplication : IApplication
{
	// Stored references from Configure/OnStartup
	private Sedulous.Runtime.Client.IApplicationHost mApplicationHost;
	private IDevice mDevice;
	private IShell mShell;
	private GraphicsDevice mGraphicsDevice;
	private IWindow mMainWindow; // main OS window (from host.MainWindow.Window)

	// Infrastructure the editor owns directly (these were provided by
	// the old Application base class).
	private String mBuiltInAssetDirectory = new .() ~ delete _;
	private String mAssetCacheDirectory = new .() ~ delete _;
	private FileSystemMount mBuiltinMount ~ delete _;
	private ResourceSystem mResourceSystem ~ delete _;
	private ILogger mLogger ~ delete _;

	// Runtime context (embedded engine for scene preview)
	// Deleted explicitly in OnShutdown before Device is destroyed.
	private Context mRuntimeContext;

	// Optional project module (e.g., TowerDefenseModule). When set, the
	// editor invokes its IApplication lifecycle around the runtime
	// context's startup/shutdown so the project's subsystems land alongside
	// the engine ones at edit time. Set on the EditorApplication instance
	// before Run() - the editor does not own / delete this.
	private Sedulous.Runtime.Client.IApplication mApp;
	private Sedulous.Engine.UI.EngineUISubsystem mRuntimeUISub;

	// Adapter that exposes EditorApplication state to project modules via
	// IApplicationHost (in particular, routing Context to mRuntimeContext
	// instead of the inherited Application.Context).
	private EditorApplicationHost mEditorHost ~ delete _;

	// Captured working directory at startup. For TowerDefense.Editor this
	// is Projects/TowerDefense/TowerDefense.Editor/; project modules walk
	// one level up to find shared assets.
	private String mRuntimeDirectory = new .() ~ delete _;

	// FixedUpdate accumulator for runtime context ticking. Runs every
	// frame; each scene's Scene.SimulationEnabled gates whether its
	// FixedUpdate functions actually do work, so edit-mode scenes pay
	// only the empty-loop cost. Simulation-mode scenes (Simulate button)
	// get physics / animation ticks here.
	private const float kFixedTimeStep = 1.0f / 60.0f;
	private const int32 kMaxFixedStepsPerFrame = 8;
	private float mFixedUpdateAccumulator = 0.0f;

	// Timing state tracked by the editor itself
	private float mDeltaTime;
	private float mTotalTime;

	/// The embedded runtime context where the engine's component managers
	/// and the project module's subsystems live. Distinct from the
	/// ApplicationHost's Context (which manages editor-app state).
	public Context RuntimeContext => mRuntimeContext;

	/// Working directory at startup. Project modules use this to resolve
	/// per-project content directories.
	public StringView RuntimeDirectory => mRuntimeDirectory;

	/// The platform shell (windowing, input, clipboard).
	public IShell Shell => mShell;

	/// The RHI device for GPU operations.
	public IDevice Device => mDevice;

	/// The main OS window.
	public IWindow Window => mMainWindow;

	/// Engine built-in assets directory.
	public StringView BuiltInAssetDirectory => mBuiltInAssetDirectory;

	/// Asset cache directory (shader cache, thumbnails).
	public StringView AssetCacheDirectory => mAssetCacheDirectory;

	/// The shared resource system.
	public ResourceSystem ResourceSystem => mResourceSystem;

	/// The application's built-in asset mount (builtin:// scheme).
	public FileSystemMount BuiltinMount => mBuiltinMount;

	/// Per-project assets directory for the currently-open project.
	/// Editor convention is that the `.sedproj` file lives inside the
	/// assets folder, so `EditorProject.ProjectDirectory` already IS the
	/// assets dir - we return it as-is. Mirror of
	/// EngineApplication.ProjectAssetDirectory so module code reads the
	/// right path through IApplicationHost regardless of host.
	public StringView ProjectAssetDirectory
	{
		get
		{
			if (mProject == null) return "";
			return mProject.ProjectDirectory;
		}
	}

	/// Returns the first running GameEditorPage, or null if none is
	/// playing. EditorApplicationHost uses this to route the module's
	/// host.Mouse / Keyboard / GetGamepad to the page's viewport-scoped
	/// adapters; with no running game, the host falls back to direct
	/// shell devices.
	public GameEditorPage RunningGamePage
	{
		get
		{
			if (mEditorContext?.PageManager == null) return null;
			for (let page in mEditorContext.PageManager.OpenPages)
				if (let game = page as GameEditorPage)
					if (game.IsRunning) return game;
			return null;
		}
	}

	/// Optional project module. Configure / OnStartup / OnShutdown fire
	/// around the runtime context's startup so the project's subsystems
	/// are registered alongside the engine's at edit time. Must be set
	/// before Run().
	public Sedulous.Runtime.Client.IApplication App
	{
		get => mApp;
		set => mApp = value;
	}

	// --- Accessors for extracted manager classes ---

	/// The ApplicationHost that owns the editor process.
	public Sedulous.Runtime.Client.IApplicationHost ApplicationHost => mApplicationHost;

	/// The editor's UIContext (manages all root views and input).
	public UIContext UIContext => mUIContext;

	/// The main RootView for the editor shell.
	public RootView MainRoot => mMainRoot;

	/// The editor's font service.
	public TrueTypeFontService FontService => mFontService;

	/// The editor's shader system.
	public ShaderSystem ShaderSystem => mShaderSystem;

	/// The editor's VG external texture cache (shared across windows).
	public VGExternalTextureCache ExternalTextureCache => mExternalTextureCache;

	/// The editor's VGRenderer for the main window.
	public VGRenderer VGRenderer => mVGRenderer;

	/// The editor context (service locator for plugins, pages, panels).
	public EditorContext EditorContext => mEditorContext;

	/// The editor project.
	public EditorProject Project => mProject;

	/// The recent projects list.
	public RecentProjects RecentProjects => mRecentProjects;

	/// The editor logger.
	public EditorLogger Logger => mEditorLogger;

	/// The project asset mount (project:// scheme).
	public FileSystemMount ProjectMount => mProjectMount;

	/// The project identity index.
	public InMemoryResourceIndex ProjectIndex => mProjectIndex;

	/// The asset browser panel.
	public AssetBrowserPanel AssetBrowserPanel => mAssetBrowserPanel;

	/// The dock host (IDockableWindowHost implementation).
	public EditorDockHost DockHost => mDockHost;

	/// The layout manager (layout persistence + page lifecycle).
	public EditorLayoutManager LayoutManager => mLayoutManager;

	/// The project manager (project open/close, scene creation, save).
	public EditorProjectManager ProjectManager => mProjectManager;

	// Scene serialization (owned)
	private ComponentTypeRegistry mTypeRegistry ~ delete _;
	private SceneResourceManager mSceneManager ~ delete _;
	private PrefabResourceManager mPrefabManager ~ delete _;

	// Default primitive identity index (builtin:// scheme). The mount
	// itself is owned by the base Application class.
	private InMemoryResourceIndex mBuiltinIndex ~ delete _;

	// Project asset mount + index (project:// scheme)
	private FileSystemMount mProjectMount ~ delete _;
	private InMemoryResourceIndex mProjectIndex ~ delete _;

	// Editor context (service locator for plugins, pages, panels)
	private EditorContext mEditorContext ~ delete _;

	// UI (owned directly, not via subsystem)
	private UIContext mUIContext;
	private RootView mMainRoot;
	private TrueTypeFontService mFontService ~ delete _;
	private VGContext mVGContext ~ delete _;
	private VGRenderer mVGRenderer;
	// Slice token threaded from per-frame Prepare to per-frame Render.
	private VGRenderSlice mVGSlice;

	// GPU thumbnail renderer for mesh/material/scene/prefab/etc. Created
	// after the RuntimeContext starts (so SceneSubsystem + ISceneRenderer
	// are available). Owned by the editor; generators borrow a reference
	// through their constructors.
	private ThumbnailRenderer mThumbnailRenderer ~ delete _;
	private VGExternalTextureCache mExternalTextureCache = new .() ~ delete _;
	private ShaderSystem mShaderSystem;
	private ShellClipboardAdapter mClipboard ~ delete _;
	private UIInputHelper mInputHelper = new .() ~ delete _;
	private float mFrameDelta;

	// Logging
	private EditorLogger mEditorLogger;
	private EditorLogBuffer mLogBuffer = new .() ~ delete _;

	// Editor state
	private View mEditorShellView;
	private EditorProject mProject = new .() ~ delete _;
	private RecentProjects mRecentProjects = new .() ~ delete _;
	private AssetBrowserPanel mAssetBrowserPanel ~ delete _;
	private AudioDecoderFactory mAudioDecoder ~ delete _;
	private LogView mLogView;

	// Extracted managers (each takes a reference to this EditorApplication)
	private EditorDockHost mDockHost ~ delete _;
	private EditorLayoutManager mLayoutManager ~ delete _;
	private EditorProjectManager mProjectManager ~ delete _;

	public this() { }

	public ApplicationSettings Settings()
	{
		return .()
		{
			Title = "Sedulous Editor",
			Width = 1600,
			Height = 900,
			EnableShaderCache = true
		};
	}

	/// Returns a path relative to the assets directory.
	public void GetAssetPath(StringView relativePath, String outPath)
	{
		outPath.Clear();
		System.IO.Path.InternalCombine(outPath, mBuiltInAssetDirectory, relativePath);
	}

	/// Returns a path relative to the asset cache directory.
	public void GetAssetCachePath(StringView relativePath, String outPath)
	{
		outPath.Clear();
		System.IO.Path.InternalCombine(outPath, mAssetCacheDirectory, relativePath);
	}

	public void Configure(Sedulous.Runtime.Client.IApplicationHost host)
	{
		mApplicationHost = host;
		mDevice = host.Graphics.Raw;
		mShell = host.Shell;
		mGraphicsDevice = host.Graphics;
		mMainWindow = host.MainWindow.Window;

		// Store asset directories from the host's discovery
		mBuiltInAssetDirectory.Set(host.BuiltInAssetDirectory);
		mAssetCacheDirectory.Set(host.AssetCacheDirectory);

		// Create own ResourceSystem (the editor manages its own)
		// Editor ships at Debug during active development so page-open,
		// asset-resolve, and mount traces are visible in the LogView panel.
		mEditorLogger = new EditorLogger(.Debug);
		mEditorLogger.AddListener(mLogBuffer);
		mLogger = mEditorLogger;

		mResourceSystem = new Sedulous.Resources.ResourceSystem(mLogger);
		mResourceSystem.EnableHotReload();
		mResourceSystem.SetSerializerProvider(new Sedulous.Serialization.OpenDDL.OpenDDLSerializerProvider());
		mResourceSystem.Startup();

		// Mount the discovered asset directory under `builtin://` so the
		// editor can read bundled assets (fonts, shaders, default primitives,
		// etc.) through the VFS rather than raw disk paths.
		mBuiltinMount = new FileSystemMount(mBuiltInAssetDirectory);
		mResourceSystem.Mount("builtin", mBuiltinMount);

		// Create extracted managers
		mDockHost = new EditorDockHost(this);
		mLayoutManager = new EditorLayoutManager(this);
		mProjectManager = new EditorProjectManager(this);

		// Subscribe to window events for secondary window close handling
		mShell.WindowManager.OnWindowEvent.Subscribe(new => mDockHost.HandleWindowEvent);
		// Closing the main window quits the app.
		mShell.WindowManager.OnWindowEvent.Subscribe(new => HandleMainWindowEvent);
	}

	/// Closing the main editor window exits the app, even while secondary
	/// (floating dock) windows are open. The shell otherwise only quits on
	/// SDL's last-window-closed QUIT, which an open secondary window suppresses.
	private void HandleMainWindowEvent(IWindow window, WindowEvent evt)
	{
		if (evt.Type == .CloseRequested && window === mMainWindow)
			mApplicationHost?.RequestExit();
	}

	public void OnStartup(Sedulous.Runtime.Client.IApplicationHost host)
	{
		// Set serializer provider on project for OpenDDL-based .sedproj files
		mProject.SetSerializerProvider(ResourceSystem.SerializerProvider);

		// Initialize model and image loaders + writers. The writer is needed
		// by the ThumbnailService to persist generated thumbnails to disk;
		// without it, ImageWriterFactory.SaveImage has no registered backend
		// and disk-cache writes fail (thumbnails still work in-memory).
		STBImageLoader.Initialize();
		Sedulous.Images.SDL.SDLImageWriter.Initialize();
		TrueTypeFonts.Initialize();
		GltfModels.Initialize();
		FbxModels.Initialize();

		// Shader system
		mShaderSystem = new ShaderSystem();
		let shaderDir = scope String();
		GetAssetPath("shaders", shaderDir);
		StringView[1] shaderPaths = .(shaderDir);

		let shaderCacheDir = scope String();
		GetAssetCachePath("shaders", shaderCacheDir);
		mShaderSystem.Initialize(mDevice, shaderPaths, shaderCacheDir);

		// Font service. Loads Roboto through the `builtin://` mount
		// instead of via raw disk paths. Locator is relative to the mount root.
		mFontService = new TrueTypeFontService(mBuiltinMount);
		let robotoLocator = "fonts/roboto/Roboto-Regular.ttf";
		if (mBuiltinMount.Exists(robotoLocator))
		{
			float[?] sizes = .(11, 12, 13, 14, 16, 18, 20, 24);
			for (let size in sizes)
				mFontService.LoadFont("Roboto", robotoLocator, .() { PixelHeight = size });
		}

		// VG renderer (for UI drawing)
		mVGContext = new VGContext(mFontService);
		mVGRenderer = new VGRenderer();
		mVGRenderer.Initialize(mDevice, host.MainWindow.Swap.Format, (int32)host.MainWindow.Swap.BufferCount, mShaderSystem);
		mVGRenderer.SetExternalCache(mExternalTextureCache);

		// Clipboard
		mClipboard = new ShellClipboardAdapter(mShell.Clipboard);

		// Editor icons (shared SVG drawables)
		EditorIcons.Initialize();

		// UI context
		Sedulous.UI.ThemeRegistry.RegisterExtension(new ToolkitThemeExtension());
		Sedulous.UI.ThemeRegistry.RegisterExtension(new EditorThemeExtension());
		mUIContext = new UIContext();
		mUIContext.FontService = mFontService;
		mUIContext.Clipboard = mClipboard;
		mUIContext.StyleSheet = DarkTheme.Create();
		mUIContext.StyleSheet.ReleaseRef();

		mMainRoot = new RootView();
		mUIContext.AddRootView(mMainRoot);

		// Runtime context (embedded engine for scene preview)
		mRuntimeContext = new Context();
		mTypeRegistry = new ComponentTypeRegistry();

		// Capture cwd + create the IApplicationHost adapter so the project
		// module sees a stable view of editor state during Configure.
		Directory.GetCurrentDirectory(mRuntimeDirectory);
		mEditorHost = new EditorApplicationHost(this);

		// When the module is a DefaultApplication, pre-set the editor's
		// shared infrastructure so Configure() reuses it instead of
		// creating duplicates. PresetInfrastructure sets
		// mOwnsInfrastructure = false so the module won't delete the
		// borrowed instances on shutdown.
		if (let defaultApp = mApp as DefaultApplication)
		{
			defaultApp.PresetInfrastructure(
				mResourceSystem, mShaderSystem,
				mFontService, mBuiltinMount);
		}

		// The module's Configure registers all engine subsystems on the
		// runtime context (via host.Ctx). DefaultApplication.Configure
		// registers the full set (Scene, Render, Physics, Animation,
		// Audio, Navigation, UI, Input); the game module adds its own
		// on top. Without a module, register the defaults directly so
		// the editor still has subsystems for scene editing.
		if (mApp != null)
			mApp.Configure(mEditorHost);
		else
			RegisterFallbackSubsystems();

		// After the module registers subsystems, tweak editor-specific
		// properties that differ from standalone defaults.
		ApplyEditorSubsystemOverrides();

		mRuntimeContext.Startup();

		// Project module OnStartup fires after the runtime context is up
		// so the module can resolve subsystems via Context.GetSubsystem<>.
		mApp?.OnStartup(mEditorHost);

		// Default primitive assets + registry
		mProjectManager.EnsureDefaultAssets();

		// Scene serialization
		mSceneManager = new SceneResourceManager(mTypeRegistry, ResourceSystem.SerializerProvider);
		mSceneManager.ResourceSystem = ResourceSystem;
		mPrefabManager = new PrefabResourceManager(mTypeRegistry, ResourceSystem.SerializerProvider);

		// Editor context
		mEditorContext = new EditorContext();
		mEditorContext.EditorAppContext = host.Ctx;
		mEditorContext.RuntimeContext = mRuntimeContext;
		mEditorContext.Logger = mEditorLogger;
		mEditorContext.SceneManager = mSceneManager;
		mEditorContext.PrefabManager = mPrefabManager;
		mEditorContext.PageManager = new EditorPageManager();
		mEditorContext.PageManager.SetResourceSystem(mResourceSystem);
		mEditorContext.SceneEditor = new EditorSceneManager();
		mEditorContext.AssetSelection = new AssetSelection();
		mEditorContext.PluginRegistry = new EditorPluginRegistry();
		mEditorContext.Project = mProject;
		mEditorContext.AssetCache = new EditorAssetCache();
		mEditorContext.AssetCache.SetSerializerProvider(ResourceSystem.SerializerProvider);
		mEditorContext.DialogService = mShell.Dialogs;
		mEditorContext.Thumbnails = new ThumbnailService(mEditorContext, mEditorLogger);
		mEditorContext.Shell = mShell;
		mEditorContext.ResourceSystem = mResourceSystem;
		mEditorContext.App = mApp;
		mEditorContext.ApplicationHost = mEditorHost;

		// Surface the builtin mount entry to panels (asset browser, etc.).
		if (mBuiltinMount != null)
		{
			mEditorContext.MountEntries.Add(new MountEntry(
				"builtin", mBuiltinMount, mBuiltinIndex, "builtin.registry", true));
		}

		// Discover plugins
		mEditorContext.PluginRegistry.DiscoverPlugins();

		// Recent projects
		let recentPath = scope String();
		GetAssetPath("cache/recent_projects.oddl", recentPath);
		mRecentProjects.Initialize(recentPath, ResourceSystem.SerializerProvider);

		// Register built-in asset creators
		mEditorContext.RegisterAssetCreator(new MaterialAssetCreator());
		mEditorContext.RegisterAssetCreator(new SceneAssetCreator());
		mEditorContext.RegisterAssetCreator(new PrefabAssetCreator());
		mEditorContext.RegisterAssetCreator(new ParticleAssetCreator());
		mEditorContext.RegisterAssetCreator(new SoundCueAssetCreator());
		mEditorContext.RegisterAssetCreator(new AnimGraphAssetCreator());
		mEditorContext.RegisterAssetCreator(new PropAnimAssetCreator());

		// Register built-in asset importers
		mEditorContext.RegisterAssetImporter(new ModelAssetImporter(mEditorLogger, mEditorContext.ResourceSystem));
		mEditorContext.RegisterAssetImporter(new TextureAssetImporter(mEditorLogger));
		mEditorContext.RegisterAssetImporter(new ImageAssetImporter(mEditorLogger));

		mAudioDecoder = new AudioDecoderFactory();
		mAudioDecoder.RegisterDefaultDecoders();
		mEditorContext.RegisterAssetImporter(new AudioAssetImporter(mAudioDecoder, mEditorLogger));
		mEditorContext.RegisterAssetImporter(new FontAssetImporter(mEditorLogger));

		// Register the font resource manager so .font files load through
		// the standard ResourceSystem path (used by the editor page and the
		// thumbnail generator).
		BakedFonts.Initialize(ResourceSystem);

		// Create the GPU thumbnail renderer. Needs SceneSubsystem +
		// ISceneRenderer from the RuntimeContext (already started above)
		// and the application's Device. Generators that produce 3D
		// thumbnails take this through their constructor.
		{
			let sceneSub = mRuntimeContext.GetSubsystem<SceneSubsystem>();
			let sceneRenderer = mRuntimeContext.GetSubsystemByInterface<ISceneRenderer>();
			if (sceneSub != null && sceneRenderer != null)
				mThumbnailRenderer = new ThumbnailRenderer(sceneSub, sceneRenderer, mDevice, ResourceSystem);
		}

		// Register asset thumbnail generators. Only registered extensions
		// generate thumbnails - everything else stays on its default icon.
		mEditorContext.RegisterThumbnailGenerator(".texture", new TextureThumbnailGenerator(ResourceSystem));
		mEditorContext.RegisterThumbnailGenerator(".font", new FontThumbnailGenerator(ResourceSystem));
		mEditorContext.RegisterThumbnailGenerator(".audioclip", new AudioClipThumbnailGenerator(ResourceSystem, mEditorLogger));
		mEditorContext.RegisterThumbnailGenerator(".soundcue", new SoundCueThumbnailGenerator(ResourceSystem, mEditorLogger));
		if (mThumbnailRenderer != null)
		{
			mEditorContext.RegisterThumbnailGenerator(".mesh", new MeshThumbnailGenerator(ResourceSystem, mThumbnailRenderer, mEditorLogger));
			mEditorContext.RegisterThumbnailGenerator(".skinnedmesh", new SkinnedMeshThumbnailGenerator(ResourceSystem, mThumbnailRenderer, mEditorLogger));
			mEditorContext.RegisterThumbnailGenerator(".material", new MaterialThumbnailGenerator(ResourceSystem, mThumbnailRenderer, mEditorLogger));
			mEditorContext.RegisterThumbnailGenerator(".prefab", new PrefabThumbnailGenerator(ResourceSystem, mThumbnailRenderer, mTypeRegistry, mEditorLogger));
			mEditorContext.RegisterThumbnailGenerator(".scene", new SceneThumbnailGenerator(ResourceSystem, mThumbnailRenderer, mTypeRegistry, mEditorLogger));
			mEditorContext.RegisterThumbnailGenerator(".skeleton", new SkeletonThumbnailGenerator(ResourceSystem, mThumbnailRenderer, mEditorLogger));
			mEditorContext.RegisterThumbnailGenerator(".particlefx", new ParticleFxThumbnailGenerator(ResourceSystem, mThumbnailRenderer, mEditorLogger));
		}

		// Register built-in page factories
		mEditorContext.RegisterPageFactory(new SceneEditorPageFactory(
			mDevice, mVGRenderer, mShell.InputManager.Keyboard, mTypeRegistry));
		mEditorContext.RegisterPageFactory(new PrefabEditorPageFactory(
			mDevice, mVGRenderer, mShell.InputManager.Keyboard, mTypeRegistry));
		mEditorContext.RegisterPageFactory(new TextureEditorPageFactory());
		mEditorContext.RegisterPageFactory(new ImageEditorPageFactory());
		mEditorContext.RegisterPageFactory(new MaterialEditorPageFactory(mDevice, mVGRenderer, mShell.InputManager.Keyboard));
		mEditorContext.RegisterPageFactory(new MeshEditorPageFactory(mDevice, mVGRenderer, mShell.InputManager.Keyboard));
		mEditorContext.RegisterPageFactory(new SkinnedMeshEditorPageFactory(mDevice, mVGRenderer, mShell.InputManager.Keyboard));
		mEditorContext.RegisterPageFactory(new AnimationEditorPageFactory(mDevice, mVGRenderer, mShell.InputManager.Keyboard));
		mEditorContext.RegisterPageFactory(new SkeletonEditorPageFactory(mDevice, mVGRenderer, mShell.InputManager.Keyboard));
		mEditorContext.RegisterPageFactory(new AnimGraphEditorPageFactory(mDevice, mVGRenderer, mShell.InputManager.Keyboard));
		mEditorContext.RegisterPageFactory(new AudioClipEditorPageFactory());
		mEditorContext.RegisterPageFactory(new SoundCueEditorPageFactory());
		mEditorContext.RegisterPageFactory(new FontEditorPageFactory());
		mEditorContext.RegisterPageFactory(new PropAnimEditorPageFactory(mDevice, mVGRenderer, mShell.InputManager.Keyboard, mTypeRegistry));
		mEditorContext.RegisterPageFactory(new ParticleEditorPageFactory(mDevice, mVGRenderer, mShell.InputManager.Keyboard));

		// Register built-in gizmo renderers
		mEditorContext.RegisterGizmoRenderer(typeof(LightComponent), new LightGizmoRenderer());
		mEditorContext.RegisterGizmoRenderer(typeof(ReflectionProbeComponent), new ReflectionProbeGizmoRenderer());

		// Initialize plugins after UI is set up.
		mEditorContext.PluginRegistry.InitializeAll(mEditorContext);

		// When no project module is loaded, show the picker now. When a
		// module is loaded, auto-open the module's project directory at
		// RuntimeDirectory/../assets. Creates the directory if it doesn't
		// exist (first run). RestoreOpenPages inside BuildEditorShell can
		// resolve factories cleanly here.
		if (mApp == null)
		{
			mProjectManager.BuildProjectPicker();
		}
		else
		{
			let projectDir = scope String();
			let runtimeParent = System.IO.Path.GetDirectoryPath(mRuntimeDirectory, .. scope .());
			System.IO.Path.InternalCombine(projectDir, runtimeParent, "assets");

			if (!Directory.Exists(projectDir))
				Directory.CreateDirectory(projectDir);

			mProjectManager.OpenProject(projectDir);
			BuildEditorShell();
		}

		mEditorLogger.Log(.Information, "Sedulous Editor initialized.");
	}

	// ==================== Editor Shell ====================

	public void BuildEditorShell()
	{
		let shell = new FlexLayout();
		shell.Direction = .Vertical;

		// Menu bar
		let menuBar = new MenuBar();
		BuildMenus(menuBar);
		mEditorContext.MenuBar = menuBar;
		shell.AddView(menuBar, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Wrap
		});

		// Dock manager (center area)
		let dockManager = new DockManager();
		dockManager.DockableWindowHost = mDockHost;
		mEditorContext.DockManager = dockManager;
		shell.AddView(dockManager, new FlexLayout.LayoutParams() {
			Width = .Match, Grow = 1
		});

		// Placeholder panel (center) - shown until first page is opened.
		let placeholderContent = new Label();
		placeholderContent.SetText("Open an asset from the Asset Browser, or File > New Scene");
		placeholderContent.FontSize.Value = 14;
		placeholderContent.HAlign.Value = .Center;
		placeholderContent.VAlign.Value = .Middle;
		placeholderContent.TextColor.Value = .(100, 100, 115, 255);
		let placeholderPanel = dockManager.AddPanel("Editor", placeholderContent);
		placeholderPanel.SetPersistenceId("editor");
		mLayoutManager.SetPlaceholderPanel(placeholderPanel);
		placeholderPanel.OnCloseRequested.Add(new (p) => { mLayoutManager.ClearPlaceholderPanel(); });

		// Wire page manager events - each page gets its own dock tab.
		mEditorContext.PageManager.OnPageOpened.Add(new (page) => mLayoutManager.OnPageOpened(page));
		mEditorContext.PageManager.OnPageClosed.Add(new (page) => mLayoutManager.OnPageClosed(page));
		// When SetActive runs (e.g. double-click on an already-open asset),
		// surface the matching dock tab so the user sees the activation.
		mEditorContext.PageManager.OnActivePageChanged.Add(new (page) => mLayoutManager.OnActivePageChanged(page));

		// When a dock tab is clicked, update the active page in the page manager.
		dockManager.OnPanelActivated.Add(new (panel) => {
			if (panel == null) return;
			for (let page in mEditorContext.PageManager.OpenPages)
			{
				if (mLayoutManager.PageDockPanels.TryGetValue(.(page), let p) && p === panel)
				{
					mEditorContext.PageManager.SetActive(page);
					break;
				}
			}
		});

		// Asset browser panel (bottom)
		mAssetBrowserPanel = new AssetBrowserPanel(mEditorContext);
		let assetsPanel = dockManager.AddPanel("Assets", mAssetBrowserPanel.ContentView);
		assetsPanel.SetPersistenceId("assets");

		// Console panel (bottom tab with assets)
		mLogView = new LogView();
		mLogBuffer.SetLogView(mLogView); // Flushes buffered startup logs
		let consolePanel = dockManager.AddPanel("Console", mLogView);
		consolePanel.SetPersistenceId("console");

		// Status bar. Publish the section label onto EditorContext so
		// pages (e.g. ProjectSettingsPage on save) can post transient
		// status without reaching for the shell themselves.
		let statusBar = new StatusBar();
		mEditorContext.StatusLabel = statusBar.AddSection("Ready");
		shell.AddView(statusBar, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Wrap
		});

		mEditorShellView = shell;
		mMainRoot.AddView(shell, new LayoutParams() {
			Width = .Match, Height = .Match
		});

		// Restore open pages first (creates page dock panels with PersistenceIds),
		// then apply layout to position everything. If no saved layout, use default.
		mLayoutManager.BeginRestore();
		mLayoutManager.RestoreOpenPages();
		mLayoutManager.EndRestore();

		if (!mLayoutManager.TryRestoreLayout(dockManager))
		{
			// Default layout: placeholder or pages in center, assets+console at bottom.
			if (mLayoutManager.PlaceholderPanel != null && mLayoutManager.PageDockPanels.Count == 0)
			{
				dockManager.DockPanel(mLayoutManager.PlaceholderPanel, .Center);
				dockManager.DockPanelRelativeTo(assetsPanel, .Bottom, mLayoutManager.PlaceholderPanel.Parent);
			}
			else
			{
				// Pages were restored - dock them in center, remove placeholder.
				DockablePanel firstPagePanel = null;
				for (let kv in mLayoutManager.PageDockPanels)
				{
					if (firstPagePanel == null)
					{
						dockManager.DockPanel(kv.value, .Center);
						firstPagePanel = kv.value;
					}
					else
					{
						dockManager.DockPanelRelativeTo(kv.value, .Center, firstPagePanel.Parent);
					}
				}

				if (mLayoutManager.PlaceholderPanel != null)
				{
					dockManager.ClosePanel(mLayoutManager.PlaceholderPanel);
					mLayoutManager.ClearPlaceholderPanel();
				}

				dockManager.DockPanelRelativeTo(assetsPanel, .Bottom, firstPagePanel?.Parent ?? dockManager.RootNode);
			}

			dockManager.DockPanelRelativeTo(consolePanel, .Center, assetsPanel.Parent);

			if (let split = assetsPanel.Parent?.Parent as DockSplit)
				split.SplitRatio = 0.7f;
		}
		else
		{
			// Layout restored - if pages were restored, the placeholder is not needed.
			if (mLayoutManager.PageDockPanels.Count > 0 && mLayoutManager.PlaceholderPanel != null)
			{
				dockManager.ClosePanel(mLayoutManager.PlaceholderPanel);
				mLayoutManager.ClearPlaceholderPanel();
			}
		}
	}

	private void BuildMenus(MenuBar menuBar)
	{
		let fileMenu = menuBar.AddMenu("File");
		fileMenu.AddItem("New Scene", new () => mProjectManager.OnNewScene());
		fileMenu.AddItem("Open Scene...", new () => mProjectManager.OnOpenScene());
		fileMenu.AddSeparator();
		fileMenu.AddItem("Save", new () => mProjectManager.OnSave());
		fileMenu.AddItem("Save As...", new () => mProjectManager.OnSaveAs());
		fileMenu.AddItem("Save All", new () => mProjectManager.OnSaveAll());
		fileMenu.AddSeparator();
		fileMenu.AddItem("Exit", new () => mApplicationHost?.RequestExit());

		let editMenu = menuBar.AddMenu("Edit");
		editMenu.AddItem("Undo", new () => {
			mEditorContext.PageManager.ActivePage?.CommandStack.Undo();
		});
		editMenu.AddItem("Redo", new () => {
			mEditorContext.PageManager.ActivePage?.CommandStack.Redo();
		});

		let viewMenu = menuBar.AddMenu("View");
		viewMenu.AddItem("Console", new () => { /* TODO: toggle console panel */ });
		viewMenu.AddItem("Asset Browser", new () => { /* TODO: toggle assets panel */ });

		// Game menu - opens the Game page in idle state. The page's own
		// toolbar Play/Stop buttons drive module.OnLaunch / OnExit. Keeping
		// page presence separate from running state means editor-layout
		// restore doesn't auto-launch gameplay.
		let gameMenu = menuBar.AddMenu("Game");
		gameMenu.AddItem("Open Game", new () => mProjectManager.OnOpenGamePage());

		// Project menu - per-project authoring surfaces that aren't tied
		// to a specific asset. Currently just the Project Settings panel
		// (target resolution + fit mode); future additions can sit here too.
		let projectMenu = menuBar.AddMenu("Project");
		projectMenu.AddItem("Project Settings", new () => mProjectManager.OnOpenProjectSettings());
	}

	private void RenderActiveViewports(ICommandEncoder encoder, int32 frameIndex)
	{
		if (mEditorContext?.PageManager == null) return;

		// Render viewports for every open page whose panel is actually visible.
		// Inactive dock tabs have their DockablePanel set to Visibility=Gone,
		// so we walk ancestors to skip those - no point doing GPU work for
		// hidden viewports. Any page that hosts a ViewportView in its content
		// tree (scene editor, preview pages, etc.) renders through here.
		for (let page in mEditorContext.PageManager.OpenPages)
		{
			if (page.ContentView != null && !page.ContentView.IsPendingDeletion
				&& IsViewEffectivelyVisible(page.ContentView))
			{
				RenderViewportsInTree(page.ContentView, encoder, frameIndex);
			}
		}
	}

	/// Checks if a view and all its ancestors are Visible (not Gone/Collapsed).
	private static bool IsViewEffectivelyVisible(View view)
	{
		var v = view;
		while (v != null)
		{
			if (v.Visibility != .Visible)
				return false;
			v = v.Parent;
		}
		return true;
	}

	private void RenderViewportsInTree(View view, ICommandEncoder encoder, int32 frameIndex)
	{
		if (let viewport = view as ViewportView)
		{
			viewport.RenderContent(encoder, frameIndex);
			return;
		}

		if (let group = view as ViewGroup)
		{
			for (int i = 0; i < group.ChildCount; i++)
				RenderViewportsInTree(group.GetChildAt(i), encoder, frameIndex);
		}
	}

	// ==================== Subsystem Registration ====================

	/// Registers the default engine subsystems when no project module is
	/// loaded. Mirrors what DefaultApplication.RegisterSubsystems does so
	/// the editor can still create/edit scenes without a game project.
	private void RegisterFallbackSubsystems()
	{
		mRuntimeContext.RegisterSubsystem(new Sedulous.Engine.Input.InputSubsystem());
		mRuntimeContext.RegisterSubsystem(new SceneSubsystem(mResourceSystem, mTypeRegistry));
		let renderSub = new RenderSubsystem(mResourceSystem);
		renderSub.Device = mDevice;
		renderSub.Window = mMainWindow;
		renderSub.ShaderSystem = mShaderSystem;
		renderSub.BuiltInAssetDirectory = mBuiltInAssetDirectory;
		mRuntimeContext.RegisterSubsystem(renderSub);
		mRuntimeContext.RegisterSubsystem(new PhysicsSubsystem());
		mRuntimeContext.RegisterSubsystem(new AnimationSubsystem(mResourceSystem));
		mRuntimeContext.RegisterSubsystem(new AudioSubsystem(mResourceSystem));
		mRuntimeContext.RegisterSubsystem(new NavigationSubsystem());
		let uiSub = new Sedulous.Engine.UI.EngineUISubsystem();
		uiSub.Device = mDevice;
		uiSub.Shell = mShell;
		uiSub.ShaderSystem = mShaderSystem;
		uiSub.OutputFormat = .RGBA16Float;
		uiSub.FontService = mFontService;
		mRuntimeContext.RegisterSubsystem(uiSub);
	}

	/// Tweaks subsystem properties for editor hosting after the module's
	/// Configure has registered them. Sets editor-specific values that
	/// differ from standalone defaults (e.g., PollShellInput = false,
	/// viewport-scoped render size).
	private void ApplyEditorSubsystemOverrides()
	{
		// SceneSubsystem: inject the editor's type registry for component
		// serialization (Add Component, inspector, scene save/load).
		let sceneSub = mRuntimeContext.GetSubsystem<SceneSubsystem>();
		if (sceneSub != null && mTypeRegistry != null)
			sceneSub.[Friend]mTypeRegistry = mTypeRegistry;

		// RenderSubsystem: ensure Device/Window/ShaderSystem are set
		// (the module's RegisterSubsystems may not have the editor's
		// Window since Graphics/MainWindow are null in the editor host).
		let renderSub = mRuntimeContext.GetSubsystem<RenderSubsystem>();
		if (renderSub != null)
		{
			renderSub.Device = mDevice;
			renderSub.Window = mMainWindow;
			renderSub.ShaderSystem = mShaderSystem;
			renderSub.BuiltInAssetDirectory = mBuiltInAssetDirectory;
		}

		// EngineUISubsystem: editor-specific overrides
		let uiSub = mRuntimeContext.GetSubsystem<Sedulous.Engine.UI.EngineUISubsystem>();
		if (uiSub != null)
		{
			uiSub.Device = mDevice;
			uiSub.Shell = mShell;
			uiSub.ShaderSystem = mShaderSystem;
			uiSub.RenderSize = .((float)mMainWindow.Width, (float)mMainWindow.Height);
			uiSub.DpiScale = mMainWindow.ContentScale;
			// Game-mode screen UI renders into the GameEditorPage viewport
			// (RGBA16Float/HDR) - pipelines must match that format.
			uiSub.OutputFormat = .RGBA16Float;
			// Input flows through GameEditorPage's viewport handler, not
			// the subsystem's own shell polling.
			uiSub.PollShellInput = false;
			uiSub.FontService = mFontService;
			mRuntimeUISub = uiSub;
		}
	}

	// ==================== Project Mount Helpers ====================
	// Used by EditorProjectManager to swap the project mount + index.

	/// Unmount and delete the current project mount + index, and drop
	/// any "project" MountEntry from EditorContext.
	public void UnmountProject()
	{
		if (mProjectIndex != null)
		{
			ResourceSystem.RemoveIndex(mProjectIndex);
			delete mProjectIndex;
			mProjectIndex = null;
		}
		if (mProjectMount != null)
		{
			ResourceSystem.Unmount("project");
			delete mProjectMount;
			mProjectMount = null;
		}

		// Drop any prior "project" MountEntry so we don't keep a dangling reference.
		for (int i = mEditorContext.MountEntries.Count - 1; i >= 0; i--)
		{
			if (mEditorContext.MountEntries[i].Scheme == "project")
			{
				delete mEditorContext.MountEntries[i];
				mEditorContext.MountEntries.RemoveAt(i);
			}
		}
	}

	/// Install a new project mount under "project://".
	public void MountProject(FileSystemMount mount)
	{
		mProjectMount = mount;
		ResourceSystem.Mount("project", mProjectMount);
	}

	/// Install a new project identity index and register it with
	/// ResourceSystem.
	public void SetProjectIndex(InMemoryResourceIndex index)
	{
		mProjectIndex = index;
		ResourceSystem.AddIndex(mProjectIndex);
	}

	/// Load the builtin identity index from the "builtin.registry" file
	/// inside the builtin mount. Called by EditorProjectManager after
	/// EnsureDefaultAssets generates the file.
	public void LoadBuiltinIndex()
	{
		mBuiltinIndex = new InMemoryResourceIndex();
		let regStream = mBuiltinMount.Open("builtin.registry");
		if (regStream case .Ok(let s))
		{
			defer delete s;
			if (mBuiltinIndex.DeserializeFrom(s) case .Ok)
			{
				ResourceSystem.AddIndex(mBuiltinIndex);
				mEditorLogger.Log(.Information, scope String()..AppendF("Builtin registry loaded ({} entries)", mBuiltinIndex.Count));
			}
			else
			{
				mEditorLogger.Log(.Warning, "Failed to load builtin registry.");
			}
		}
		else
		{
			mEditorLogger.Log(.Warning, "Failed to load builtin registry.");
		}
	}

	// ==================== Frame Loop ====================

	public void OnUpdate(Sedulous.Runtime.Client.IApplicationHost host, float deltaTime)
	{
		mDeltaTime = deltaTime;
		mTotalTime += deltaTime;
		mFrameDelta = deltaTime;

		// --- Input phase ---

		if (mUIContext == null) return;

		let mouse = mShell.InputManager.Mouse;
		let keyboard = mShell.InputManager.Keyboard;

		// F8 toggles UI debug overlay (all options at once).
		if (keyboard != null && keyboard.IsKeyPressed(.F8))
		{
			let on = !mUIContext.DebugSettings.ShowBounds;
			mUIContext.DebugSettings.ShowBounds = on;
			mUIContext.DebugSettings.ShowPadding = on;
			mUIContext.DebugSettings.ShowMargin = on;
			mUIContext.DebugSettings.ShowHitTarget = on;
			mUIContext.DebugSettings.ShowFocusPath = on;
		}

		// Keyboard shortcuts
		if (keyboard != null && keyboard.IsKeyDown(.LeftCtrl))
		{
			if (keyboard.IsKeyPressed(.S))
			{
				if (keyboard.IsKeyDown(.LeftAlt))
					mProjectManager.OnSaveAll();
				else if (keyboard.IsKeyDown(.LeftShift))
					mProjectManager.OnSaveAs();
				else
					mProjectManager.OnSave();
			}
			else if (keyboard.IsKeyPressed(.O))
			{
				mProjectManager.OnOpenScene();
			}
		}
		if (mouse == null) return;

		let dragDrop = mUIContext.DragDropManager;

		// Determine which window the mouse is OVER. Was previously based
		// on Window.Focused, but keyboard focus only changes on click /
		// Alt+Tab - so hovering the secondary window without clicking
		// kept input routed to the main window, and the mouse coords
		// (which SDL reports local to the hover window) drove hover
		// effects on whatever happened to sit at the same coords in
		// main. MouseHoverWindow comes from MOUSE_ENTER / LEAVE.
		RootView inputRoot = mMainRoot;
		let hover = mouse.MouseHoverWindow;
		if (hover != null && hover !== mMainWindow)
		{
			for (let kv in mDockHost.DockableWindowMap)
			{
				if (kv.value.Window === hover)
				{
					if (let data = kv.value.Data as DockableWindowData)
						inputRoot = data.RootView;
					break;
				}
			}
		}

		// Cross-window drag: move OS window, route input to main window.
		// Gate on IsDragging only - IsPotentialDrag fires on ANY mouse-down
		// over an IDragSource (and DockablePanel is one), so checking it
		// here would intercept ordinary clicks-and-hold inside a secondary
		// window the moment the user pressed the button. MouseUp would then
		// route to main and the secondary view's OnClick (which fires on
		// MouseUp) would never run - presenting as "first click on a
		// detached window does nothing, double-click works."
		if (dragDrop.IsDragging && inputRoot !== mMainRoot)
		{
			let globalX = mouse.GlobalX;
			let globalY = mouse.GlobalY;

			// Capture drag offset on first frame.
			if (dragDrop.IsDragging && mDockHost.DragSourceWindow == null)
			{
				for (let kv in mDockHost.DockableWindowMap)
				{
					if (kv.value.Window.Focused)
					{
						mDockHost.DragSourceWindow = kv.value.Window;
						mDockHost.DragWindowOffsetX = globalX - (float)mDockHost.DragSourceWindow.X;
						mDockHost.DragWindowOffsetY = globalY - (float)mDockHost.DragSourceWindow.Y;
						break;
					}
				}
			}

			// Move the dockable OS window to follow cursor. Set both axes in one
			// call - two per-axis writes race on X11 (the second reads back the
			// first axis' stale pre-move value and pins it).
			if (mDockHost.DragSourceWindow != null)
			{
				mDockHost.DragSourceWindow.SetPosition(
					(int32)(globalX - mDockHost.DragWindowOffsetX),
					(int32)(globalY - mDockHost.DragWindowOffsetY));
			}

			// Route to main window with global-to-main-relative conversion.
			mUIContext.ActiveInputRoot = mMainRoot;
			let mx = globalX - (float)mMainWindow.X;
			let my = globalY - (float)mMainWindow.Y;
			mInputHelper.ProcessMouseInput(mouse, mUIContext, mx, my);
			if (keyboard != null)
				mInputHelper.ProcessKeyboardInput(keyboard, mUIContext, mFrameDelta);
			return;
		}

		// Not cross-window dragging - clear drag source.
		if (mDockHost.DragSourceWindow != null)
			mDockHost.DragSourceWindow = null;

		// Normal routing to focused window.
		mUIContext.ActiveInputRoot = inputRoot;
		mInputHelper.ProcessMouseInput(mouse, mUIContext);
		if (keyboard != null)
			mInputHelper.ProcessKeyboardInput(keyboard, mUIContext, mFrameDelta);

		// Click-anywhere-in-a-panel = activate that page. DockTabGroup
		// already fires OnPanelActivated on tab-strip clicks; this covers
		// clicks into the panel's CONTENT, which matter for side-by-side
		// layouts and detached windows where the user expects clicking a
		// viewport to "focus" its page (so e.g. the game keyboard adapter
		// flips Focused via OnActivated and TD's space-to-start-wave
		// starts working).
		if (mouse.IsButtonPressed(.Left))
			ActivatePageUnderClick();

		// --- Update phase ---

		// Flush buffered log messages to the LogView on the main thread.
		mLogBuffer.Flush();

		// TickReadback first so a finished GPU thumbnail clears the
		// renderer's in-flight slot BEFORE the service tries to
		// dispatch the next request. Otherwise we lose a frame per
		// thumbnail (service sees busy, then we clear it - same frame
		// wasted).
		{
			let mainFence = host.MainWindow?.CurrentFence;
			if (mainFence != null)
				mThumbnailRenderer?.TickReadback(mainFence);
		}

		// Process queued thumbnail requests (throttled per frame inside Update).
		mEditorContext.Thumbnails?.Update();

		// Push live render-target dimensions + DPI into the runtime UI
		// subsystem before its Update runs. When a GameEditorPage is in
		// its IsRunning state, route to the page's *current* viewport
		// texture size - covers both fixed-size and layout-tracked
		// (MatchViewport) modes uniformly so the runtime UI canvas
		// always matches what the scene renders into. Falls back to
		// the editor window only when no game is running.
		if (mRuntimeUISub != null && mMainWindow != null)
		{
			var canvasW = (float)mMainWindow.Width;
			var canvasH = (float)mMainWindow.Height;
			var dpiScale = mMainWindow.ContentScale;
			let game = RunningGamePage;
			if (game != null && game.ViewportRenderWidth > 0 && game.ViewportRenderHeight > 0)
			{
				canvasW = (float)game.ViewportRenderWidth;
				canvasH = (float)game.ViewportRenderHeight;
				// Fixed-resolution previews render at the texture's pixel
				// grid, so the editor window's HiDPI factor shouldn't
				// scale UI again. MatchViewport keeps the window scale
				// because the texture really is at the window's pixel
				// density. ProjectTarget with a 0/0 setting collapses
				// to MatchViewport at the viewport layer, so check the
				// effective size (not just the enum) before forcing
				// 1.0 - otherwise HiDPI UI shrinks in that fallback.
				uint32 effW, effH;
				game.GetEffectivePreviewSize(out effW, out effH);
				if (effW > 0 && effH > 0)
					dpiScale = 1.0f;
			}
			mRuntimeUISub.RenderSize = .(canvasW, canvasH);
			mRuntimeUISub.DpiScale = dpiScale;
		}

		// Tick RuntimeContext (component init, scene updates for editor mode).
		mRuntimeContext.BeginFrame(deltaTime);

		// Fixed update loop. Runs unconditionally so simulating scene tabs
		// can drive their physics; non-simulating scenes have
		// SimulationEnabled=false and their FixedUpdate funcs no-op.
		// Clamped to avoid spiral-of-death after a frame stall.
		mFixedUpdateAccumulator += deltaTime;
		int32 fixedSteps = 0;
		// Check once per frame whether any Game page is currently running -
		// module.OnFixedUpdate only fires when a GameEditorPage is in its
		// IsRunning state, matching the OnLaunch/OnExit window. With only
		// one Game page allowed at a time this collapses to "is one open?"
		GameEditorPage runningGamePage = null;
		for (let page in mEditorContext.PageManager.OpenPages)
		{
			if (let gp = page as GameEditorPage)
			{
				if (gp.IsRunning) { runningGamePage = gp; break; }
			}
		}
		while (mFixedUpdateAccumulator >= kFixedTimeStep && fixedSteps < kMaxFixedStepsPerFrame)
		{
			mRuntimeContext.FixedUpdate(kFixedTimeStep);
			if (runningGamePage != null)
				mApp?.OnFixedUpdate(mEditorHost, kFixedTimeStep);
			mFixedUpdateAccumulator -= kFixedTimeStep;
			fixedSteps++;
		}
		if (mFixedUpdateAccumulator > kFixedTimeStep * 2)
			mFixedUpdateAccumulator = kFixedTimeStep * 2;

		mRuntimeContext.Update(deltaTime);
		mRuntimeContext.PostUpdate(deltaTime);
		mRuntimeContext.EndFrame();

		// Update plugins
		mEditorContext.PluginRegistry.UpdateAll(deltaTime);

		// Update every open page, not just the active one. Pages (e.g.
		// AnimationEditorPage) own their own playback timeline that has to
		// advance per frame independent of focus; with side-by-side panels
		// the user sees both pages rendering and expects both to play.
		for (let page in mEditorContext.PageManager.OpenPages)
			page?.Update(deltaTime);

		// UI frame
		mMainRoot.DpiScale = mMainWindow.ContentScale;
		mMainRoot.ViewportSize = .((float)mMainWindow.Width, (float)mMainWindow.Height);
		mUIContext.BeginFrame(deltaTime);
		mUIContext.UpdateRootView(mMainRoot);

		// Process OS file drops *after* UpdateRootView so the asset
		// browser panel's bounds reflect the current frame's layout
		// (LocalToScreen depends on cached layout positions). Drops
		// outside the panel's screen rect are silently ignored - this
		// is the gating UX the user asked for.
		mProjectManager.ProcessFileDrops();
	}

	private void ActivatePageUnderClick()
	{
		let pressed = mUIContext.GetViewById(mUIContext.InputManager.PressedId);
		if (pressed == null) return;

		var v = pressed;
		while (v != null)
		{
			if (let panel = v as DockablePanel)
			{
				for (let page in mEditorContext.PageManager.OpenPages)
				{
					if (mLayoutManager.PageDockPanels.TryGetValue(.(page), let p) && p === panel)
					{
						if (mEditorContext.PageManager.ActivePage !== page)
							mEditorContext.PageManager.SetActive(page);
						return;
					}
				}
				return;
			}
			v = v.Parent;
		}
	}

	public void OnRenderWindow(Sedulous.Runtime.Client.IApplicationHost host, ref Sedulous.RuntimeGraphics.FrameContext frame)
	{
		let data = frame.Window.Data as DockableWindowData;
		if (data != null)
		{
			// This is a dockable/secondary window
			mDockHost.RenderDockableWindow(data, ref frame);
		}
		else
		{
			// This is the main window
			RenderMainWindow(host, ref frame);
		}
	}

	private void RenderMainWindow(Sedulous.Runtime.Client.IApplicationHost host, ref Sedulous.RuntimeGraphics.FrameContext frame)
	{
		if (mUIContext == null || mVGContext == null || mVGRenderer == null) return;

		let encoder = frame.Encoder;
		let fi = (int32)frame.FrameIndex;
		let w = frame.Window.Swap.Width;
		let h = frame.Window.Swap.Height;

		// Build VG geometry (was OnPrepareFrame)
		mVGContext.Clear();
		mUIContext.DrawRootView(mMainRoot, mVGContext);

		// Upload to GPU
		mVGRenderer.BeginFrame(fi);
		let batch = mVGContext.GetBatch();
		if (batch != null)
			mVGSlice = mVGRenderer.Prepare(batch, fi, w, h);
		else
			mVGSlice = .Invalid;

		// Render active viewport views (3D scenes) to their offscreen textures
		// BEFORE UI rendering - the UI will display these textures via DrawImage.
		let sceneRenderer = mRuntimeContext?.GetSubsystemByInterface<ISceneRenderer>();
		if (sceneRenderer != null)
			sceneRenderer.BeginRendering(encoder, fi);

		RenderActiveViewports(encoder, fi);

		// Drive GPU thumbnail rendering inside the same Begin/End scope as
		// the viewports. NextFenceValue is the value the main window's
		// EndFrame will signal; ThumbnailRenderer records it so
		// TickReadback (called at frame start) knows when to read.
		if (mThumbnailRenderer != null && sceneRenderer != null)
			mThumbnailRenderer.RenderPending(encoder, fi, frame.Window.NextFenceValue);

		if (sceneRenderer != null)
			sceneRenderer.EndRendering();

		// Begin render pass for UI
		ColorAttachment[1] colorAttachments = .(.()
		{
			View = frame.BackbufferView,
			LoadOp = .Clear,
			StoreOp = .Store,
			ClearValue = .(0.12f, 0.12f, 0.15f, 1)
		});

		RenderPassDesc passDesc = .() { ColorAttachments = .(colorAttachments) };
		let renderPass = encoder.BeginRenderPass(passDesc);
		if (renderPass != null)
		{
			mVGRenderer.Render(renderPass, w, h, fi, mVGSlice);
			renderPass.End();
		}
	}

	// ==================== Shutdown ====================

	public void OnShutdown(Sedulous.Runtime.Client.IApplicationHost host)
	{
		// Save editor state before shutting down
		mLayoutManager.SaveEditorLayout();
		mLayoutManager.SaveOpenPages();

		// Silence the audio system before anything starts releasing
		// resources. Pages own SoundCue / AudioClip refs and the audio
		// thread holds raw AudioClip pointers via SourceNode; if we
		// free clips while the graph is still mixing them we UAF in
		// SourceNode.ProcessAudio. Pages also call StopAll on their
		// own destructors, but doing it once up here is the
		// defense-in-depth.
		if (let audio = mRuntimeContext?.GetSubsystem<Sedulous.Engine.Audio.AudioSubsystem>())
			audio.StopAll();

		// Shutdown plugins
		mEditorContext.PluginRegistry.ShutdownAll();

		// Detach all page content views from dock panels before pages are deleted.
		// Don't call ClosePanel - the view tree will be cascade-deleted by
		// RootView's destructor during UIContext cleanup.
		for (let page in mEditorContext.PageManager.OpenPages)
		{
			if (page.ContentView?.Parent != null)
				if (let parent = page.ContentView.Parent as ViewGroup)
					parent.RemoveView(page.ContentView, false);
		}
		mLayoutManager.PageDockPanels.Clear();

		// Shutdown pages (deletes pages + their content views)
		mEditorContext.PageManager.Shutdown();

		// Close project (and the per-asset editor cache)
		mEditorContext.AssetCache?.Close();
		mProject.Close();

		// Clean up editor context
		mEditorContext.Dispose();

		// Tear down the thumbnail renderer's scene BEFORE the runtime
		// context's SceneSubsystem is destroyed - the renderer's
		// destructor can't safely touch SceneSubsystem after that point.
		mThumbnailRenderer?.Shutdown();

		// Project module OnShutdown fires before the runtime context tears
		// down so the module can release subsystem-side refs.
		mApp?.OnShutdown(mEditorHost);

		// Clean up runtime context (must be deleted before Device is destroyed
		// since its subsystems share the Device).
		mRuntimeContext.Shutdown();
		delete mRuntimeContext;
		mRuntimeContext = null;

		// Destroy floating windows (before UIContext so roots are removed cleanly)
		let dockableViews = scope List<View>();
		for (let kv in mDockHost.DockableWindowMap)
			dockableViews.Add(kv.key);
		for (let view in dockableViews)
			mDockHost.DestroyDockableWindowImpl(view, detachView: false);
		mDockHost.DockableWindowMap.Clear();

		// Clean up UI
		if (mUIContext != null)
		{
			mUIContext.RemoveRootView(mMainRoot);
		}

		delete mMainRoot;
		mMainRoot = null;

		if (mUIContext != null)
		{
			delete mUIContext;
			mUIContext = null;
		}

		EditorIcons.Shutdown();

		// Unregister + dispose the baked-font resource manager that
		// BakedFonts.Initialize created earlier.
		BakedFonts.Shutdown();

		if (mVGRenderer != null)
		{
			mVGRenderer.Dispose();
			delete mVGRenderer;
			mVGRenderer = null;
		}

		mShaderSystem?.Dispose();
		delete mShaderSystem;
		mShaderSystem = null;

		// Shut down the resource system last (after everything that might
		// hold resource handles has been torn down).
		mResourceSystem?.Shutdown();
	}
}
