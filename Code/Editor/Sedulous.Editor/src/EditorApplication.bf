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
class EditorApplication : IApplication, IDockableWindowHost
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
	/// shell devices (Sub-phase A behavior).
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
	private bool mProjectLoaded;
	private View mProjectPickerView;
	private View mEditorShellView;
	private EditorProject mProject = new .() ~ delete _;
	private RecentProjects mRecentProjects = new .() ~ delete _;
	private DockablePanel mPlaceholderPanel; // "Open an asset..." placeholder, removed when first page opens
	private bool mIsRestoringLayout; // Suppresses auto-docking in OnPageOpened during layout restore
	private AssetBrowserPanel mAssetBrowserPanel ~ delete _;
	private AudioDecoderFactory mAudioDecoder ~ delete _;
	private LogView mLogView;
	private Dictionary<ObjectKey<IEditorPage>, DockablePanel> mPageDockPanels = new .() ~ delete _;
	private int32 mNewSceneCounter;

	// Multi-window (floating dock panels + cross-window drag)
	private Dictionary<View, RenderWindow> mDockableWindowMap = new .() ~ delete _;
	private IWindow mDragSourceWindow;
	private float mDragWindowOffsetX;
	private float mDragWindowOffsetY;

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

		// Subscribe to window events for secondary window close handling
		mShell.WindowManager.OnWindowEvent.Subscribe(new => HandleWindowEvent);
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
		EnsureDefaultAssets();

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
			BuildProjectPicker();
		}
		else
		{
			let projectDir = scope String();
			let runtimeParent = System.IO.Path.GetDirectoryPath(mRuntimeDirectory, .. scope .());
			System.IO.Path.InternalCombine(projectDir, runtimeParent, "assets");

			if (!Directory.Exists(projectDir))
				Directory.CreateDirectory(projectDir);

			OpenProject(projectDir);
			BuildEditorShell();
		}

		mEditorLogger.Log(.Information, "Sedulous Editor initialized.");
	}

	// ==================== Project Picker ====================

	private void BuildProjectPicker()
	{
		let picker = new Panel();
		picker.SetStyle(.Background, new ColorDrawable(.(30, 32, 40, 255)));
		picker.Padding = .(40);

		let center = new FlexLayout();
		center.Direction = .Vertical;
		center.Spacing = 16;

		let title = new Label();
		title.SetText("Sedulous Editor");
		title.FontSize.Value = 24;
		title.HAlign.Value = .Center;
		center.AddView(title, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(32))
		});

		let subtitle = new Label();
		subtitle.SetText("Select a project to get started");
		subtitle.FontSize.Value = 13;
		subtitle.HAlign.Value = .Center;
		center.AddView(subtitle, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(20))
		});

		// Button row
		let btnRow = new FlexLayout();
		btnRow.Direction = .Horizontal;
		btnRow.Spacing = 12;

		let newBtn = new Button("New Project...");
		newBtn.OnClick.Add(new (b) => {
			mShell.Dialogs.ShowFolderDialog(new (paths) => {
				if (paths.Length > 0 && paths[0].Length > 0)
				{
					let path = scope String(paths[0]);
					mProject.Open(path);
					mProject.Save();
					OpenProject(path);
				}
			}, default, mMainWindow);
		});
		btnRow.AddView(newBtn, new FlexLayout.LayoutParams() { Height = .Fixed(.Px(32)) });

		let openBtn = new Button("Open Project...");
		openBtn.OnClick.Add(new (b) => {
			mShell.Dialogs.ShowFolderDialog(new (paths) => {
				if (paths.Length > 0 && paths[0].Length > 0)
					OpenProject(paths[0]);
			}, default, mMainWindow);
		});
		btnRow.AddView(openBtn, new FlexLayout.LayoutParams() { Height = .Fixed(.Px(32)) });

		center.AddView(btnRow, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Wrap
		});

		// Recent projects list
		if (mRecentProjects.Count > 0)
		{
			let recentLabel = new Label();
			recentLabel.SetText("Recent Projects:");
			recentLabel.FontSize.Value = 12;
			center.AddView(recentLabel, new FlexLayout.LayoutParams() {
				Width = .Match, Height = .Fixed(.Px(20))
			});

			for (int i = 0; i < mRecentProjects.Count; i++)
			{
				let idx = i;
				let btn = new Button(mRecentProjects.Get(i));
				btn.OnClick.Add(new (b) => {
					if (idx < mRecentProjects.Count)
					{
						var path = mRecentProjects.Get(idx);
						OpenProject(path);
					}
				});
				center.AddView(btn, new FlexLayout.LayoutParams() {
					Width = .Match, Height = .Fixed(.Px(28))
				});
			}
		}

		picker.AddView(center, new LayoutParams() {
			Width = .Wrap, Height = .Wrap
		});

		mProjectPickerView = picker;
		mMainRoot.AddView(picker, new LayoutParams() {
			Width = .Match, Height = .Match
		});
	}

	// ==================== Project Open ====================

	private void OpenProject(StringView path)
	{
		String pathToOpen = scope String(path);
		if (mProject.Open(pathToOpen) case .Err)
		{
			mEditorLogger.Log(.Error, "Failed to open project: {}", pathToOpen);
			return;
		}

		// Editor-side per-asset state (preview rig assignments, anim
		// graph node positions, etc.). Lives next to the project under
		// .editor/ so it travels with the repo if checked in, and is
		// cheap to wipe if not.
		mEditorContext.AssetCache?.Open(pathToOpen);

		mRecentProjects.Add(pathToOpen);
		mProjectLoaded = true;
		mEditorLogger.Log(.Information, scope $"Project opened: {pathToOpen}");

		// Mount the project directory under "project://" and load its identity index
		let projectDir = scope String();
		projectDir.Set(mProject.ProjectDirectory);

		// Point the thumbnail disk cache at this project's .editor/thumbnails/.
		mEditorContext.Thumbnails?.SetProjectDirectory(projectDir);

		// Load project_settings.oddl from the project's assets dir, if
		// present. Standalone reads the same file at boot via
		// EngineApplication; the editor's "Project Target" preview mode
		// reads this same data, so both stay in sync. Missing file is
		// silent - ProjectSettings keeps its in-memory defaults.
		mEditorContext.ProjectSettings = .();
		ProjectSettingsIO.Load(ProjectAssetDirectory,
			ResourceSystem.SerializerProvider, ref mEditorContext.ProjectSettings).IgnoreError();

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

		mProjectMount = new FileSystemMount(projectDir);
		ResourceSystem.Mount("project", mProjectMount);

		mProjectIndex = new InMemoryResourceIndex();
		if (mProjectMount.Exists("project.registry"))
		{
			let regStream = mProjectMount.Open("project.registry");
			if (regStream case .Ok(let s))
			{
				defer delete s;
				mProjectIndex.DeserializeFrom(s);
			}
		}
		ResourceSystem.AddIndex(mProjectIndex);
		// Insert project at the front so it lists before builtin everywhere
		// that iterates MountEntries in order (asset browser tree, asset
		// picker) - the project mount is what's interacted with most.
		mEditorContext.MountEntries.Insert(0, new MountEntry(
			"project", mProjectMount, mProjectIndex, "project.registry", true));
		mEditorLogger.Log(.Information, scope String()..AppendF("Project registry loaded ({} entries)", mProjectIndex.Count));

		// Defer view switch - the button that triggered this is inside the picker.
		// Deleting immediately would use-after-free in Button.FireClick.
		if (mProjectPickerView != null)
		{
			let pickerToRemove = mProjectPickerView;
			mProjectPickerView = null;
			mUIContext.MutationQueue.QueueAction(new () => {
				mMainRoot.RemoveView(pickerToRemove, true);
				BuildEditorShell();
			});
		}
	}

	private void BuildEditorShell()
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
		dockManager.DockableWindowHost = this;
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
		mPlaceholderPanel = dockManager.AddPanel("Editor", placeholderContent);
		mPlaceholderPanel.SetPersistenceId("editor");
		mPlaceholderPanel.OnCloseRequested.Add(new (p) => { mPlaceholderPanel = null; });

		// Wire page manager events - each page gets its own dock tab.
		mEditorContext.PageManager.OnPageOpened.Add(new (page) => OnPageOpened(page));
		mEditorContext.PageManager.OnPageClosed.Add(new (page) => OnPageClosed(page));
		// When SetActive runs (e.g. double-click on an already-open asset),
		// surface the matching dock tab so the user sees the activation.
		mEditorContext.PageManager.OnActivePageChanged.Add(new (page) => OnActivePageChanged(page));

		// When a dock tab is clicked, update the active page in the page manager.
		dockManager.OnPanelActivated.Add(new (panel) => {
			if (panel == null) return;
			for (let page in mEditorContext.PageManager.OpenPages)
			{
				if (mPageDockPanels.TryGetValue(.(page), let p) && p === panel)
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
		mIsRestoringLayout = true;
		RestoreOpenPages();
		mIsRestoringLayout = false;

		if (!TryRestoreLayout(dockManager))
		{
			// Default layout: placeholder or pages in center, assets+console at bottom.
			if (mPlaceholderPanel != null && mPageDockPanels.Count == 0)
			{
				dockManager.DockPanel(mPlaceholderPanel, .Center);
				dockManager.DockPanelRelativeTo(assetsPanel, .Bottom, mPlaceholderPanel.Parent);
			}
			else
			{
				// Pages were restored - dock them in center, remove placeholder.
				DockablePanel firstPagePanel = null;
				for (let kv in mPageDockPanels)
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

				if (mPlaceholderPanel != null)
				{
					dockManager.ClosePanel(mPlaceholderPanel);
					mPlaceholderPanel = null;
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
			if (mPageDockPanels.Count > 0 && mPlaceholderPanel != null)
			{
				dockManager.ClosePanel(mPlaceholderPanel);
				mPlaceholderPanel = null;
			}
		}
	}

	private void BuildMenus(MenuBar menuBar)
	{
		let fileMenu = menuBar.AddMenu("File");
		fileMenu.AddItem("New Scene", new () => OnNewScene());
		fileMenu.AddItem("Open Scene...", new () => OnOpenScene());
		fileMenu.AddSeparator();
		fileMenu.AddItem("Save", new () => OnSave());
		fileMenu.AddItem("Save As...", new () => OnSaveAs());
		fileMenu.AddItem("Save All", new () => OnSaveAll());
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
		gameMenu.AddItem("Open Game", new () => OnOpenGamePage());

		// Project menu - per-project authoring surfaces that aren't tied
		// to a specific asset. Currently just the Project Settings panel
		// (target resolution + fit mode); future additions can sit here too.
		let projectMenu = menuBar.AddMenu("Project");
		projectMenu.AddItem("Project Settings", new () => OnOpenProjectSettings());
	}

	private void OnOpenGamePage()
	{
		// Asset-only editor sessions are fully supported - Open Game is a
		// no-op when no module is loaded. The Game menu item stays visible
		// so users see the feature exists; first cut just logs and bails.
		if (mApp == null)
		{
			mEditorLogger.Log(.Information,
				"Open Game: no application module loaded - editor is running in asset-only mode.");
			return;
		}

		// If a Game page is already open, activate it instead of double-opening.
		for (let page in mEditorContext.PageManager.OpenPages)
		{
			if (page is GameEditorPage)
			{
				mEditorContext.PageManager.SetActive(page);
				return;
			}
		}

		let page = new GameEditorPage(mEditorContext);
		let sceneRenderer = mRuntimeContext.GetSubsystemByInterface<ISceneRenderer>();
		let screenRenderer = mRuntimeContext.GetSubsystemByInterface<IScreenRenderer>();
		let content = GamePageBuilder.Build(page, mEditorContext, mDevice, mVGRenderer,
			sceneRenderer, screenRenderer);
		page.SetContentView(content);
		mEditorContext.PageManager.AddPage(page);
	}

	private void OnOpenProjectSettings()
	{
		// Project Settings authoring is meaningful only when a project is
		// loaded - asset-only sessions without a project dir would have
		// nowhere to write the .oddl. Log instead of silently doing
		// nothing so users know why the menu seems to do nothing.
		if (mProject == null || !mProject.IsLoaded)
		{
			mEditorLogger.Log(.Information,
				"Project Settings: no project loaded - open a project before editing settings.");
			return;
		}

		// Singleton page - activate the existing tab if it's already open
		// rather than double-stacking.
		for (let page in mEditorContext.PageManager.OpenPages)
		{
			if (page is ProjectSettingsPage)
			{
				mEditorContext.PageManager.SetActive(page);
				return;
			}
		}

		let page = new ProjectSettingsPage(mEditorContext);
		let content = ProjectSettingsPageBuilder.Build(page);
		page.SetContentView(content);
		mEditorContext.PageManager.AddPage(page);
	}

	private void OnOpenScene()
	{
		let defaultPath = scope String();
		if (mProject.ProjectDirectory.Length > 0)
			defaultPath.Set(mProject.ProjectDirectory);

		mShell.Dialogs.ShowOpenFileDialog(
			new (paths) => {
				if (paths.Length > 0)
					OpenSceneFile(paths[0]);
			},
			scope StringView[]("*.scene"),
			defaultPath, false, mMainWindow);
	}

	private void OnSave()
	{
		let page = mEditorContext.PageManager.ActivePage;
		if (page == null) return;

		// Empty extension = page is read-only; menu items are still wired
		// (file menu, shortcuts) so we just no-op rather than show a dialog.
		if (page.SaveFileExtension.Length == 0) return;

		if (page.FilePath.Length == 0)
			OnSaveAs();
		else
		{
			page.Save();
			SyncDockPanelTitle(page);
			RegisterInProjectRegistry(page);
		}
	}

	private void OnSaveAs()
	{
		let page = mEditorContext.PageManager.ActivePage;
		if (page == null) return;

		let ext = page.SaveFileExtension;
		if (ext.Length == 0) return; // read-only page

		let defaultPath = scope String();
		if (mProject.ProjectDirectory.Length > 0)
			defaultPath.Set(mProject.ProjectDirectory);

		let filter = scope String()..AppendF("*{}", ext);

		mShell.Dialogs.ShowSaveFileDialog(
			new (paths) => {
				if (paths.Length > 0)
				{
					let extCopy = scope String(ext); // captured into the dialog callback
					let savePath = scope String(paths[0]);
					if (!savePath.EndsWith(extCopy, .OrdinalIgnoreCase))
						savePath.Append(extCopy);
					page.SaveAs(savePath);
					SyncDockPanelTitle(page);
					RegisterInProjectRegistry(page);
				}
			},
			scope StringView[](filter),
			defaultPath, mMainWindow);
	}

	/// Saves every open page that's dirty and savable. Pages with no FilePath
	/// (untitled) are skipped silently - the user can save them individually
	/// via the Save/Save As menu items.
	private void OnSaveAll()
	{
		if (mEditorContext?.PageManager == null) return;

		int savedCount = 0;
		for (let page in mEditorContext.PageManager.OpenPages)
		{
			if (page.SaveFileExtension.Length == 0) continue;  // read-only
			if (!page.IsDirty) continue;
			if (page.FilePath.Length == 0) continue;  // untitled - need Save As

			page.Save();
			SyncDockPanelTitle(page);
			RegisterInProjectRegistry(page);
			savedCount++;
		}

		mEditorLogger?.Log(.Information, scope String()..AppendF("Save All: saved {} page(s)", savedCount));
	}

	private void SyncDockPanelTitle(IEditorPage page)
	{
		let key = Sedulous.Core.ObjectKey<IEditorPage>(page);
		if (mPageDockPanels.TryGetValue(key, let panel))
			panel.SetTitle(page.Title);
	}

	private void RegisterInProjectRegistry(IEditorPage page)
	{
		if (mProjectIndex == null || mProjectMount == null || page.FilePath.Length == 0) return;

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
			if (!MountResolver.TryResolveAbsolute(mEditorContext.MountEntries, page.FilePath, out mount, locator))
			{
				mEditorLogger.Log(.Warning,
					scope String()..AppendF("Skipping registry write: '{}' is not inside any mounted scheme", page.FilePath));
				return;
			}

			// Find the scheme the resolved mount is registered under.
			let scheme = scope String();
			for (let entry in mEditorContext.MountEntries)
			{
				if (entry.Mount === mount)
				{
					scheme.Set(entry.Scheme);
					break;
				}
			}

			let uri = scope String()..AppendF("{}://{}", scheme, locator);
			mProjectIndex.Register(sceneGuid, uri);

			// Save index back through the project mount
			let indexStream = scope MemoryStream();
			if (mProjectIndex.SerializeTo(indexStream) case .Ok)
			{
				indexStream.Position = 0;
				mProjectMount.Save("project.registry", indexStream);
			}
			mEditorLogger.Log(.Information, scope String()..AppendF("Registered in project registry: {}", uri));
		}
	}

	private void OpenSceneFile(StringView path)
	{
		let page = mEditorContext.PageManager.OpenWithContext(path, mEditorContext);
		if (page != null)
			mEditorLogger.Log(.Information, scope String()..AppendF("Opened scene: {}", path));
		else
			mEditorLogger.Log(.Error, scope String()..AppendF("Failed to open: {}", path));
	}

	private void OnPageOpened(IEditorPage page)
	{
		if (page == null || page.ContentView == null) return;
		let dockManager = mEditorContext.DockManager;
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
			if (MountResolver.TryResolveAbsoluteToUri(mEditorContext.MountEntries, page.FilePath, uri))
				panel.SetPersistenceId(scope $"page:{uri}");
		}

		// When dock tab X is clicked, detach content (page owns it) and close via PageManager.
		// Note: DockManager's own OnCloseRequested handler (registered first in AddPanel)
		// calls ClosePanel before this handler runs, so the dock panel is already undocked.
		let capturedPage = page;
		panel.OnCloseRequested.Add(new (dp) => {
			// Detach content before dock manager deletes the panel.
			if (capturedPage.ContentView?.Parent != null)
				if (let parent = capturedPage.ContentView.Parent as ViewGroup)
					parent.RemoveView(capturedPage.ContentView, false);

			// Close through PageManager (fires OnPageClosed, handles cleanup + placeholder).
			mEditorContext.PageManager.Close(capturedPage);
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

		// Activate the new tab so the opened page is immediately visible
		dockManager.ActivatePanel(panel);
	}

	private void OnPageClosed(IEditorPage page)
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
			mEditorContext.DockManager?.ClosePanel(panel);

		mPageDockPanels.Remove(key);

		// If that was the last page, restore the placeholder panel.
		if (mPageDockPanels.Count == 0 && mPlaceholderPanel == null)
		{
			let dockManager = mEditorContext.DockManager;
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
	private void OnActivePageChanged(IEditorPage page)
	{
		if (page == null) return;
		let dockManager = mEditorContext?.DockManager;
		if (dockManager == null) return;
		if (mPageDockPanels.TryGetValue(.(page), let panel))
			dockManager.ActivatePanel(panel);
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

	// ==================== Default Assets ====================

	/// Ensures default builtin assets exist on disk. Generates them on
	/// first run if missing, then loads the identity index and registers
	/// it with ResourceSystem. The `builtin://` mount itself is created
	/// by the base Application class before this runs.
	///
	/// Asset content lives in `BuiltinAssets.GenerateAll` - this method
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
			renderSub.BuiltInAssetDirectory = new String(mBuiltInAssetDirectory);
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

	/// owns only the gate (skip when `builtin.registry` exists) and the
	/// index lifecycle. New default assets should be added to
	/// `BuiltinAssets`, not here.
	private void EnsureDefaultAssets()
	{
		let assetRoot = scope String();
		GetAssetPath("", assetRoot);

		// Use the mount owned by this editor instance. We generate
		// and persist through this same mount so saves go through VFS.

		bool needsGeneration = !mBuiltinMount.Exists("builtin.registry");
		let tempIndex = scope InMemoryResourceIndex();

		if (needsGeneration)
		{
			mEditorLogger.Log(.Information, "Generating default builtin assets...");

			BuiltinAssets.GenerateAll(mBuiltinMount, tempIndex,
				ResourceSystem.SerializerProvider, assetRoot, mEditorLogger);

			let indexStream = scope MemoryStream();
			if (tempIndex.SerializeTo(indexStream) case .Ok)
			{
				indexStream.Position = 0;
				mBuiltinMount.Save("builtin.registry", indexStream);
			}
			mEditorLogger.Log(.Information, "Default builtin assets generated.");
		}

		// Load the persisted identity index
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

	// ==================== Scene Creation ====================

	private void OnNewScene()
	{
		// Create scene through RuntimeContext's SceneSubsystem so ISceneAware
		// subsystems (RenderSubsystem) inject their component managers.
		let sceneSub = mRuntimeContext.GetSubsystem<SceneSubsystem>();
		if (sceneSub == null)
		{
			mEditorLogger.Log(.Error, "No SceneSubsystem in RuntimeContext");
			return;
		}

		mNewSceneCounter++;
		let sceneName = scope String();
		sceneName.AppendF("Untitled {}", mNewSceneCounter);
		let scene = sceneSub.CreateScene(sceneName);

		// Editor mode: disable simulation so physics, animation, particles don't tick.
		// Play mode (future) will re-enable via scene.Start().
		scene.SimulationEnabled = false;

		// Create default camera
		let cameraEntity = scene.CreateEntity("Main Camera");
		scene.SetLocalTransform(cameraEntity, .() {
			Position = .(0, 2, 5),
			Rotation = .Identity,
			Scale = .One
		});

		// Add CameraComponent
		let cameraMgr = scene.GetModule<CameraComponentManager>();
		if (cameraMgr != null)
		{
			let camHandle = cameraMgr.CreateComponent(cameraEntity);
			if (let cam = cameraMgr.Get(camHandle))
				cam.IsActiveCamera = true;
		}

		// Create default directional light
		let lightEntity = scene.CreateEntity("Directional Light");
		scene.SetLocalTransform(lightEntity, .() {
			Position = .(0, 5, 0),
			Rotation = .Identity,
			Scale = .One
		});

		let lightMgr = scene.GetModule<LightComponentManager>();
		if (lightMgr != null)
		{
			let lightHandle = lightMgr.CreateComponent(lightEntity);
			if (let light = lightMgr.Get(lightHandle))
			{
				light.Type = .Directional;
				light.Intensity = 2.0f;
			}
		}

		// Load primitive meshes from disk (generated by EnsureDefaultAssets)
		let meshMgr = scene.GetModule<MeshComponentManager>();

		// Ground plane
		let planeEntity = scene.CreateEntity("Ground");
		scene.SetLocalTransform(planeEntity, .() { Position = .Zero, Rotation = .Identity, Scale = .One });

		if (meshMgr != null)
		{
			if (ResourceSystem.LoadResource<StaticMeshResource>("builtin://primitives/plane.mesh") case .Ok(var handle))
			{
				var planeRef = ResourceRef(handle.Resource.Id, "builtin://primitives/plane.mesh");
				let planeComp = meshMgr.CreateComponent(planeEntity);
				if (let comp = meshMgr.Get(planeComp))
					comp.SetMeshRef(planeRef);
				planeRef.Dispose();
				handle.Release();
			}
		}

		// Cube
		let cubeEntity = scene.CreateEntity("Cube");
		scene.SetLocalTransform(cubeEntity, .() { Position = .(0, 0.5f, 0), Rotation = .Identity, Scale = .One });

		if (meshMgr != null)
		{
			if (ResourceSystem.LoadResource<StaticMeshResource>("builtin://primitives/cube.mesh") case .Ok(var handle))
			{
				var cubeRef = ResourceRef(handle.Resource.Id, "builtin://primitives/cube.mesh");
				let cubeComp = meshMgr.CreateComponent(cubeEntity);
				if (let comp = meshMgr.Get(cubeComp))
					comp.SetMeshRef(cubeRef);
				cubeRef.Dispose();
				handle.Release();
			}
		}

		// Create page with layout
		let page = new SceneEditorPage(scene, "", mEditorContext);

		let sceneRenderer = mRuntimeContext.GetSubsystemByInterface<ISceneRenderer>();
		let content = ScenePageBuilder.Build(page, mEditorContext, mDevice, mVGRenderer,
			sceneRenderer, mShell.InputManager.Keyboard);
		page.SetContentView(content);

		mEditorContext.PageManager.AddPage(page);
		mEditorLogger.Log(.Information, "Created new scene");
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
					OnSaveAll();
				else if (keyboard.IsKeyDown(.LeftShift))
					OnSaveAs();
				else
					OnSave();
			}
			else if (keyboard.IsKeyPressed(.O))
			{
				OnOpenScene();
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
			for (let kv in mDockableWindowMap)
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
			if (dragDrop.IsDragging && mDragSourceWindow == null)
			{
				for (let kv in mDockableWindowMap)
				{
					if (kv.value.Window.Focused)
					{
						mDragSourceWindow = kv.value.Window;
						mDragWindowOffsetX = globalX - (float)mDragSourceWindow.X;
						mDragWindowOffsetY = globalY - (float)mDragSourceWindow.Y;
						break;
					}
				}
			}

			// Move the dockable OS window to follow cursor.
			if (mDragSourceWindow != null)
			{
				mDragSourceWindow.X = (int32)(globalX - mDragWindowOffsetX);
				mDragSourceWindow.Y = (int32)(globalY - mDragWindowOffsetY);
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
		if (mDragSourceWindow != null)
			mDragSourceWindow = null;

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
		ProcessFileDrops();
	}

	private void ProcessFileDrops()
	{
		let input = mShell.InputManager;
		if (input.DroppedFileCount == 0 || mAssetBrowserPanel == null) return;

		let panelView = mAssetBrowserPanel.ContentView;
		if (panelView == null || panelView.Context == null) return;

		let adapter = mAssetBrowserPanel.ActiveContentAdapter;
		let entry = adapter?.ActiveEntry;
		if (entry == null) return;
		let writable = entry.Mount as IWritableMount;
		if (writable == null) return;

		// SDL drops report window-relative *physical* pixels; UI views
		// live in logical pixels. Divide by ContentScale once.
		let scale = mMainWindow.ContentScale;
		let dpiScale = (scale > 0.0001f) ? scale : 1.0f;

		let topLeft = panelView.LocalToScreen(.Zero);
		let panelRect = Sedulous.Core.Mathematics.RectangleF(
			topLeft.X, topLeft.Y, panelView.Width, panelView.Height);

		for (int i = 0; i < input.DroppedFileCount; i++)
		{
			let path = input.GetDroppedFile(i);
			if (path.IsEmpty) continue;

			float dropX, dropY;
			if (!input.TryGetDroppedFilePosition(i, out dropX, out dropY)) continue;
			let logicalX = dropX / dpiScale;
			let logicalY = dropY / dpiScale;

			if (!panelRect.Contains(logicalX, logicalY)) continue;

			AssetBrowserBuilder.DispatchImportFile(mEditorContext, adapter,
				mAssetBrowserPanel, entry, writable, path);
		}
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
					if (mPageDockPanels.TryGetValue(.(page), let p) && p === panel)
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
			RenderDockableWindow(data, ref frame);
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

	private void RenderDockableWindow(DockableWindowData data, ref Sedulous.RuntimeGraphics.FrameContext frame)
	{
		// Prepare: update root view dimensions and layout
		data.RootView.DpiScale = frame.Window.Window.ContentScale;
		data.RootView.ViewportSize = .((float)frame.Window.Window.Width, (float)frame.Window.Window.Height);
		mUIContext.UpdateRootView(data.RootView);

		// Clear the dockable window
		ColorAttachment[1] colorAttachments = .(.()
		{
			View = frame.BackbufferView,
			LoadOp = .Clear,
			StoreOp = .Store,
			ClearValue = .(0.12f, 0.12f, 0.15f, 1)
		});

		RenderPassDesc passDesc = .() { ColorAttachments = .(colorAttachments) };
		let renderPass = frame.Encoder.BeginRenderPass(passDesc);
		if (renderPass == null)
			return;

		// Render UI into the dockable window
		let vg = data.VGContext;
		let renderer = data.VGRenderer;
		let w = frame.Window.Swap.Width;
		let h = frame.Window.Swap.Height;

		vg.Clear();
		mUIContext.DrawRootView(data.RootView, vg);
		let batch = vg.GetBatch();
		if (batch != null && batch.Commands.Count > 0)
		{
			let fi = (int32)frame.FrameIndex;
			renderer.BeginFrame(fi);
			let slice = renderer.Prepare(batch, fi, w, h);
			renderer.Render(renderPass, w, h, fi, slice);
		}

		renderPass.End();
	}

	// ==================== IDockableWindowHost ====================

	public bool SupportsOSWindows => true;

	public void CreateDockableWindow(View dockableWindow, float width, float height,
		float screenX, float screenY, delegate void(View) onCloseRequested = null)
	{
		let settings = Sedulous.Shell.WindowSettings()
		{
			Title = scope .("Float"),
			Width = (int32)width,
			Height = (int32)height,
			Resizable = true,
			Bordered = false
		};

		let renderDesc = RenderWindowDesc()
		{
			Format = mApplicationHost.MainWindow.Swap.Format,
			PresentMode = .Fifo
		};

		let rw = mApplicationHost.OpenWindow(settings, renderDesc);
		if (rw == null)
		{
			mEditorLogger.Log(.Error, "Failed to create floating OS window");
			delete onCloseRequested;
			return;
		}

		rw.Window.X = mMainWindow.X + (int32)screenX;
		rw.Window.Y = mMainWindow.Y + (int32)screenY;

		let data = new DockableWindowData();
		data.OnCloseDelegate = onCloseRequested;

		data.RootView = new RootView();
		data.RootView.DpiScale = rw.Window.ContentScale;
		data.RootView.ViewportSize = .((float)rw.Window.Width, (float)rw.Window.Height);
		mUIContext.AddRootView(data.RootView);
		data.RootView.AddView(dockableWindow);
		data.DockableView = dockableWindow;

		data.VGContext = new VGContext(mFontService);
		data.VGRenderer = new VGRenderer();
		data.VGRenderer.Initialize(mDevice, rw.Swap.Format,
			(int32)rw.Swap.BufferCount, mShaderSystem);
		data.VGRenderer.SetExternalCache(mExternalTextureCache);

		rw.SetData(data);
		mDockableWindowMap[dockableWindow] = rw;
	}

	public void DestroyDockableWindow(View dockableWindow)
	{
		DestroyDockableWindowImpl(dockableWindow);
	}

	public void MoveDockableWindow(View dockableWindow, float screenX, float screenY)
	{
		if (mDockableWindowMap.TryGetValue(dockableWindow, let rw))
		{
			let nx = mMainWindow.X + (int32)screenX;
			let ny = mMainWindow.Y + (int32)screenY;
			if (rw.Window.X != nx) rw.Window.X = nx;
			if (rw.Window.Y != ny) rw.Window.Y = ny;
		}
	}

	public void ResizeDockableWindow(View dockableWindow, float screenX, float screenY, float width, float height)
	{
		if (mDockableWindowMap.TryGetValue(dockableWindow, let rw))
		{
			// Only push when the value actually changes - SDL_SetWindowPosition
			// and SDL_SetWindowSize fire a window event each call, invalidating
			// the swapchain even on no-ops. Spammed VK_ERROR_OUT_OF_DATE_KHR
			// during resize otherwise.
			let nx = mMainWindow.X + (int32)screenX;
			let ny = mMainWindow.Y + (int32)screenY;
			let nw = (int32)width;
			let nh = (int32)height;
			if (rw.Window.X != nx) rw.Window.X = nx;
			if (rw.Window.Y != ny) rw.Window.Y = ny;
			if (rw.Window.Width != nw) rw.Window.Width = nw;
			if (rw.Window.Height != nh) rw.Window.Height = nh;
		}
	}

	public bool TryGetDockableWindowBounds(View dockableWindow, out float x, out float y, out float width, out float height)
	{
		if (mDockableWindowMap.TryGetValue(dockableWindow, let rw))
		{
			x = rw.Window.X - mMainWindow.X;
			y = rw.Window.Y - mMainWindow.Y;
			width = rw.Window.Width;
			height = rw.Window.Height;
			return true;
		}
		x = 0;
		y = 0;
		width = 0;
		height = 0;
		return false;
	}

	public void GetGlobalMousePosition(out float globalX, out float globalY)
	{
		let mouse = mShell.InputManager.Mouse;
		if (mouse != null)
		{
			globalX = mouse.GlobalX;
			globalY = mouse.GlobalY;
		}
		else
		{
			globalX = 0;
			globalY = 0;
		}
	}

	private void DestroyDockableWindowImpl(View dockableWindow, bool detachView = true)
	{
		if (!mDockableWindowMap.TryGetValue(dockableWindow, let rw))
			return;

		mDockableWindowMap.Remove(dockableWindow);

		if (let data = rw.Data as DockableWindowData)
		{
			if (detachView && dockableWindow.Parent == data.RootView)
				data.RootView.RemoveView(dockableWindow, false);

			mUIContext.RemoveRootView(data.RootView);
		}

		// RenderWindow dtor calls WaitIdle and cleans up GPU resources + data
		mApplicationHost.CloseWindow(rw);
	}

	// ==================== Window Event Handling ====================

	private void HandleWindowEvent(IWindow window, WindowEvent evt)
	{
		if (evt.Type != .CloseRequested)
			return;

		// Check if it's a dockable window
		for (let kv in mDockableWindowMap)
		{
			if (kv.value.Window == window)
			{
				if (let data = kv.value.Data as DockableWindowData)
				{
					if (data.OnCloseDelegate != null)
						data.OnCloseDelegate(kv.key);
				}
				return;
			}
		}
	}

	// ==================== Layout Persistence ====================

	private void GetLayoutFilePath(String outPath)
	{
		if (mProject.IsLoaded)
			System.IO.Path.InternalCombine(outPath, mProject.ProjectDirectory, "editor_layout.oddl");
	}

	private bool TryRestoreLayout(DockManager dockManager)
	{
		let layoutPath = scope String();
		GetLayoutFilePath(layoutPath);
		if (layoutPath.Length == 0)
		{
			mEditorLogger?.Log(.Debug, "Restore layout: no project loaded, skipping");
			return false;
		}

		let provider = ResourceSystem?.SerializerProvider;
		if (provider == null)
		{
			mEditorLogger?.Log(.Warning, "Restore layout: no serializer provider");
			return false;
		}

		if (EditorLayoutPersistence.RestoreLayout(dockManager, layoutPath, provider) case .Ok)
		{
			mEditorLogger?.Log(.Debug, scope $"Editor layout restored from {layoutPath}");
			return true;
		}
		else
		{
			mEditorLogger?.Log(.Debug, scope $"No saved layout found at {layoutPath}");
			return false;
		}
	}

	private void SaveEditorLayout()
	{
		let dockManager = mEditorContext?.DockManager;
		if (dockManager == null) return;

		let layoutPath = scope String();
		GetLayoutFilePath(layoutPath);
		if (layoutPath.Length == 0) return;

		let provider = ResourceSystem?.SerializerProvider;
		if (provider == null)
		{
			mEditorLogger?.Log(.Warning, "Save layout: no serializer provider");
			return;
		}

		if (EditorLayoutPersistence.SaveLayout(dockManager, layoutPath, provider) case .Ok)
			mEditorLogger.Log(.Information, "Editor layout saved.");
		else
			mEditorLogger.Log(.Warning, "Editor layout save failed");
	}

	private void SaveOpenPages()
	{
		if (!mProject.IsLoaded) return;

		let pages = mEditorContext.PageManager.OpenPages;
		let activePage = mEditorContext.PageManager.ActivePage;

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
			if (MountResolver.TryResolveAbsoluteToUri(mEditorContext.MountEntries, page.FilePath, uri))
				uris.Add(uri);
			else
				delete uri;
		}

		let views = scope List<StringView>();
		for (let u in uris) views.Add(u);

		mProject.SetOpenPageUris(views, activeIndex);
		mProject.Save();
	}

	private void RestoreOpenPages()
	{
		if (!mProject.IsLoaded) return;

		// Stored URIs are mount-relative. Resolve each to an absolute path
		// against the current machine's mount table before handing to the
		// page manager (asset browser and equality checks work in abs paths).
		// A URI whose scheme isn't mounted on this machine is silently dropped.
		for (let uri in mProject.OpenPageUris)
		{
			if (uri.Length == 0) continue;
			let absPath = scope String();
			if (!MountResolver.TryResolveUriToAbsolute(mEditorContext.MountEntries, uri, absPath))
				continue;
			if (!File.Exists(absPath)) continue;
			mEditorContext.PageManager.OpenWithContext(absPath, mEditorContext);
		}

		// Restore active page
		let pages = mEditorContext.PageManager.OpenPages;
		let idx = mProject.ActivePageIndex;
		if (idx >= 0 && idx < pages.Length)
			mEditorContext.PageManager.SetActive(pages[idx]);
	}

	// ==================== Shutdown ====================

	public void OnShutdown(Sedulous.Runtime.Client.IApplicationHost host)
	{
		// Save editor state before shutting down
		SaveEditorLayout();
		SaveOpenPages();

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
		mPageDockPanels.Clear();

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
		for (let kv in mDockableWindowMap)
			dockableViews.Add(kv.key);
		for (let view in dockableViews)
			DestroyDockableWindowImpl(view, detachView: false);
		mDockableWindowMap.Clear();

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
