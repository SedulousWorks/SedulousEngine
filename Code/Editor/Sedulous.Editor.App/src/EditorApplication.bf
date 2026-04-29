namespace Sedulous.Editor.App;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.Shell;
using Sedulous.Shell.Input;
using Sedulous.Shaders;
using Sedulous.Fonts;
using Sedulous.Fonts.TTF;
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

/// The Sedulous Editor application.
/// Extends Runtime.Client.Application for direct control over UI and rendering.
/// Creates a RuntimeContext with engine subsystems for scene preview.
class EditorApplication : Application, IFloatingWindowHost
{
	// Runtime context (embedded engine for scene preview)
	// Deleted explicitly in OnShutdown before Device is destroyed.
	private Context mRuntimeContext;

	// Scene serialization (owned)
	private ComponentTypeRegistry mTypeRegistry ~ delete _;
	private SceneResourceManager mSceneManager ~ delete _;

	// Default primitive registry
	private ResourceRegistry mPrimitiveRegistry ~ delete _;

	// Project asset registry
	private ResourceRegistry mProjectRegistry ~ delete _;

	// Editor context (service locator for plugins, pages, panels)
	private EditorContext mEditorContext ~ delete _;

	// UI (owned directly, not via subsystem)
	private UIContext mUIContext;
	private RootView mMainRoot;
	private FontService mFontService ~ delete _;
	private VGContext mVGContext ~ delete _;
	private VGRenderer mVGRenderer;
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
	private AssetBrowserPanel mAssetBrowserPanel ~ delete _;
	private LogView mLogView;
	private Dictionary<ObjectKey<IEditorPage>, DockablePanel> mPageDockPanels = new .() ~ delete _;
	private int32 mNewSceneCounter;

	// Multi-window (floating dock panels + cross-window drag)
	private Dictionary<View, SecondaryWindowContext> mFloatingWindowMap = new .() ~ delete _;
	private IWindow mDragSourceWindow;
	private float mDragWindowOffsetX;
	private float mDragWindowOffsetY;

	public this() : base() { }

	protected override ILogger CreateLogger()
	{
		mEditorLogger = new EditorLogger();
		mEditorLogger.AddListener(mLogBuffer);
		return mEditorLogger;
	}

	protected override void OnInitialize(Context context)
	{
		// Shader system
		mShaderSystem = new ShaderSystem();
		let shaderDir = scope String();
		GetAssetPath("shaders", shaderDir);
		StringView[1] shaderPaths = .(shaderDir);
		
		let shaderCacheDir = scope String();
		GetAssetCachePath("shaders", shaderCacheDir);
		mShaderSystem.Initialize(Device, shaderPaths, shaderCacheDir);

		// Font service
		mFontService = new FontService();
		let fontPath = scope String();
		GetAssetPath("fonts/roboto/Roboto-Regular.ttf", fontPath);
		if (System.IO.File.Exists(fontPath))
		{
			float[?] sizes = .(11, 12, 13, 14, 16, 18, 20, 24);
			for (let size in sizes)
				mFontService.LoadFont("Roboto", fontPath, .() { PixelHeight = size });
		}

		// VG renderer (for UI drawing)
		mVGContext = new VGContext(mFontService);
		mVGRenderer = new VGRenderer();
		mVGRenderer.Initialize(Device, SwapChain.Format, (int32)SwapChain.BufferCount, mShaderSystem);
		mVGRenderer.SetExternalCache(mExternalTextureCache);

		// Clipboard
		mClipboard = new ShellClipboardAdapter(Shell.Clipboard);

		// UI context
		Sedulous.UI.Theme.RegisterExtension(new ToolkitThemeExtension());
		mUIContext = new UIContext();
		mUIContext.FontService = mFontService;
		mUIContext.Clipboard = mClipboard;
		mUIContext.SetTheme(DarkTheme.Create(), true);

		mMainRoot = new RootView();
		mUIContext.AddRootView(mMainRoot);

		// Runtime context (embedded engine for scene preview)
		mRuntimeContext = new Context();

		// Register engine subsystems for scene rendering.
		// SceneSubsystem manages scene lifecycle.
		mRuntimeContext.RegisterSubsystem(new Sedulous.Engine.SceneSubsystem());

		// RenderSubsystem provides ISceneRenderer for viewport rendering.
		let renderSub = new Sedulous.Engine.Render.RenderSubsystem(mResourceSystem);
		renderSub.Device = Device;
		renderSub.Window = Window;
		renderSub.ShaderSystem = mShaderSystem;
		mRuntimeContext.RegisterSubsystem(renderSub);

		mRuntimeContext.Startup();

		// Default primitive assets + registry
		EnsureDefaultAssets();

		// Scene serialization
		mTypeRegistry = new ComponentTypeRegistry();
		mSceneManager = new SceneResourceManager(mTypeRegistry, ResourceSystem.SerializerProvider);

		// Editor context
		mEditorContext = new EditorContext();
		mEditorContext.RuntimeContext = mRuntimeContext;
		mEditorContext.SceneManager = mSceneManager;
		mEditorContext.PageManager = new EditorPageManager();
		mEditorContext.SceneEditor = new EditorSceneManager();
		mEditorContext.AssetSelection = new AssetSelection();
		mEditorContext.PluginRegistry = new EditorPluginRegistry();
		mEditorContext.Project = mProject;
		mEditorContext.DialogService = Shell.Dialogs;
		mEditorContext.Shell = Shell;
		mEditorContext.ResourceSystem = mResourceSystem;

		// Discover plugins
		mEditorContext.PluginRegistry.DiscoverPlugins();

		// Recent projects
		let recentPath = scope String();
		GetAssetPath("cache/recent_projects.txt", recentPath);
		mRecentProjects.Initialize(recentPath);

		// Start with project picker
		BuildProjectPicker();

		mEditorLogger.Log(.Information, "Sedulous Editor initialized.");
	}

	protected override void OnContextStarted()
	{
		// Initialize model and image loaders
		Sedulous.Images.STB.STBImageLoader.Initialize();
		Sedulous.Models.GLTF.GltfModels.Initialize();
		Sedulous.Models.FBX.FbxModels.Initialize();

		// Register built-in asset creators
		mEditorContext.RegisterAssetCreator(new MaterialAssetCreator());
		mEditorContext.RegisterAssetCreator(new SceneAssetCreator());

		// Register built-in asset importers
		mEditorContext.RegisterAssetImporter(new ModelAssetImporter());
		mEditorContext.RegisterAssetImporter(new TextureAssetImporter());

		// Initialize plugins after UI is set up.
		mEditorContext.PluginRegistry.InitializeAll(mEditorContext);
	}

	// ==================== Project Picker ====================

	private void BuildProjectPicker()
	{
		let picker = new Panel();
		picker.Background = new ColorDrawable(.(30, 32, 40, 255));
		picker.Padding = .(40);

		let center = new LinearLayout();
		center.Orientation = .Vertical;
		center.Spacing = 16;

		let title = new Label();
		title.SetText("Sedulous Editor");
		title.FontSize = 24;
		title.HAlign = .Center;
		center.AddView(title, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = 32
		});

		let subtitle = new Label();
		subtitle.SetText("Select a project to get started");
		subtitle.FontSize = 13;
		subtitle.HAlign = .Center;
		center.AddView(subtitle, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = 20
		});

		// Button row
		let btnRow = new LinearLayout();
		btnRow.Orientation = .Horizontal;
		btnRow.Spacing = 12;

		let newBtn = new Button();
		newBtn.SetText("New Project...");
		newBtn.OnClick.Add(new (b) => {
			Shell.Dialogs.ShowFolderDialog(new (paths) => {
				if (paths.Length > 0 && paths[0].Length > 0)
				{
					let path = scope String(paths[0]);
					mProject.Open(path);
					mProject.Save();
					OpenProject(path);
				}
			}, default, Window);
		});
		btnRow.AddView(newBtn, new LinearLayout.LayoutParams() { Height = 32 });

		let openBtn = new Button();
		openBtn.SetText("Open Project...");
		openBtn.OnClick.Add(new (b) => {
			Shell.Dialogs.ShowFolderDialog(new (paths) => {
				if (paths.Length > 0 && paths[0].Length > 0)
					OpenProject(paths[0]);
			}, default, Window);
		});
		btnRow.AddView(openBtn, new LinearLayout.LayoutParams() { Height = 32 });

		center.AddView(btnRow, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = LayoutParams.WrapContent
		});

		// Recent projects list
		if (mRecentProjects.Count > 0)
		{
			let recentLabel = new Label();
			recentLabel.SetText("Recent Projects:");
			recentLabel.FontSize = 12;
			center.AddView(recentLabel, new LinearLayout.LayoutParams() {
				Width = LayoutParams.MatchParent, Height = 20
			});

			for (int i = 0; i < mRecentProjects.Count; i++)
			{
				let idx = i;
				let btn = new Button();
				btn.SetText(mRecentProjects.Get(i));
				btn.OnClick.Add(new (b) => {
					if (idx < mRecentProjects.Count)
						OpenProject(mRecentProjects.Get(idx));
				});
				center.AddView(btn, new LinearLayout.LayoutParams() {
					Width = LayoutParams.MatchParent, Height = 28
				});
			}
		}

		picker.AddView(center, new LayoutParams() {
			Width = LayoutParams.WrapContent, Height = LayoutParams.WrapContent
		});

		mProjectPickerView = picker;
		mMainRoot.AddView(picker, new LayoutParams() {
			Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent
		});
	}

	// ==================== Project Open ====================

	private void OpenProject(StringView path)
	{
		if (mProject.Open(path) case .Err)
		{
			mEditorLogger.Log(.Error, "Failed to open project: {}", path);
			return;
		}

		mRecentProjects.Add(path);
		mProjectLoaded = true;
		mEditorLogger.Log(.Information, "Project opened: {}", path);

		// Load or create project registry
		let projectDir = scope String();
		projectDir.Set(mProject.ProjectDirectory);
		let projRegistryPath = scope String()..AppendF("{}/project.registry", projectDir);

		if (mProjectRegistry != null)
		{
			ResourceSystem.RemoveRegistry(mProjectRegistry);
			delete mProjectRegistry;
		}

		mProjectRegistry = new Sedulous.Resources.ResourceRegistry("project", projectDir);
		if (System.IO.File.Exists(projRegistryPath))
			mProjectRegistry.LoadFromFile(projRegistryPath);
		ResourceSystem.AddRegistry(mProjectRegistry);
		mEditorLogger.Log(.Information, scope String()..AppendF("Project registry loaded ({} entries)", mProjectRegistry.Count));

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
		let shell = new LinearLayout();
		shell.Orientation = .Vertical;

		// Menu bar
		let menuBar = new MenuBar();
		BuildMenus(menuBar);
		mEditorContext.MenuBar = menuBar;
		shell.AddView(menuBar, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = LayoutParams.WrapContent
		});

		// Dock manager (center area)
		let dockManager = new DockManager();
		dockManager.FloatingWindowHost = this;
		mEditorContext.DockManager = dockManager;
		shell.AddView(dockManager, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = 0, Weight = 1
		});

		// Placeholder panel (center) - shown until first page is opened.
		let placeholderContent = new Label();
		placeholderContent.SetText("Open an asset from the Asset Browser, or File > New Scene");
		placeholderContent.FontSize = 14;
		placeholderContent.HAlign = .Center;
		placeholderContent.VAlign = .Middle;
		placeholderContent.TextColor = .(100, 100, 115, 255);
		mPlaceholderPanel = dockManager.AddPanel("Editor", placeholderContent);
		mPlaceholderPanel.OnCloseRequested.Add(new (p) => { mPlaceholderPanel = null; });
		dockManager.DockPanel(mPlaceholderPanel, .Center);

		// Wire page manager events - each page gets its own dock tab.
		mEditorContext.PageManager.OnPageOpened.Add(new (page) => OnPageOpened(page));
		mEditorContext.PageManager.OnPageClosed.Add(new (page) => OnPageClosed(page));

		// Console panel (bottom)
		mLogView = new LogView();
		mLogBuffer.SetLogView(mLogView); // Flushes buffered startup logs
		let consolePanel = dockManager.AddPanel("Console", mLogView);
		dockManager.DockPanelRelativeTo(consolePanel, .Bottom, mPlaceholderPanel.Parent);

		// Asset browser panel (bottom tab with console)
		mAssetBrowserPanel = new AssetBrowserPanel(mEditorContext);
		let assetsPanel = dockManager.AddPanel("Assets", mAssetBrowserPanel.ContentView);
		dockManager.DockPanelRelativeTo(assetsPanel, .Center, consolePanel.Parent);

		// Set split ratio for page area vs console (70/30)
		if (let split = consolePanel.Parent?.Parent as DockSplit)
			split.SplitRatio = 0.7f;

		// Status bar
		let statusBar = new StatusBar();
		statusBar.AddSection("Ready");
		shell.AddView(statusBar, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = LayoutParams.WrapContent
		});

		mEditorShellView = shell;
		mMainRoot.AddView(shell, new LayoutParams() {
			Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent
		});
	}

	private void BuildMenus(MenuBar menuBar)
	{
		let fileMenu = menuBar.AddMenu("File");
		fileMenu.AddItem("New Scene", new () => OnNewScene());
		fileMenu.AddItem("Open Scene...", new () => OnOpenScene());
		fileMenu.AddSeparator();
		fileMenu.AddItem("Save", new () => OnSave());
		fileMenu.AddItem("Save As...", new () => OnSaveAs());
		fileMenu.AddSeparator();
		fileMenu.AddItem("Exit", new () => Exit());

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
	}

	private void OnOpenScene()
	{
		let defaultPath = scope String();
		if (mProject.ProjectDirectory.Length > 0)
			defaultPath.Set(mProject.ProjectDirectory);

		Shell.Dialogs.ShowOpenFileDialog(
			new (paths) => {
				if (paths.Length > 0)
					OpenSceneFile(paths[0]);
			},
			scope StringView[]("*.scene"),
			defaultPath, false, Window);
	}

	private void OnSave()
	{
		let page = mEditorContext.PageManager.ActivePage;
		if (page == null) return;

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

		let defaultPath = scope String();
		if (mProject.ProjectDirectory.Length > 0)
			defaultPath.Set(mProject.ProjectDirectory);

		Shell.Dialogs.ShowSaveFileDialog(
			new (paths) => {
				if (paths.Length > 0)
				{
					let savePath = scope String(paths[0]);
					if (!savePath.EndsWith(".scene", .OrdinalIgnoreCase))
						savePath.Append(".scene");
					page.SaveAs(savePath);
					SyncDockPanelTitle(page);
					RegisterInProjectRegistry(page);
				}
			},
			scope StringView[]("*.scene"),
			defaultPath, Window);
	}

	private void SyncDockPanelTitle(IEditorPage page)
	{
		let key = Sedulous.Core.ObjectKey<IEditorPage>(page);
		if (mPageDockPanels.TryGetValue(key, let panel))
			panel.SetTitle(page.Title);
	}

	private void RegisterInProjectRegistry(IEditorPage page)
	{
		if (mProjectRegistry == null || page.FilePath.Length == 0) return;

		if (let scenePage = page as SceneEditorPage)
		{
			let sceneGuid = scenePage.LastSavedGuid;
			if (sceneGuid == .Empty) return;

			// Convert absolute path to project-relative
			let projectDir = mProject.ProjectDirectory;
			let filePath = page.FilePath;

			let relativePath = scope String();
			if (filePath.StartsWith(projectDir))
			{
				var rel = filePath.Substring(projectDir.Length);
				if (rel.StartsWith("/") || rel.StartsWith("\\"))
					rel = rel.Substring(1);
				relativePath.Set(rel);
			}
			else
			{
				relativePath.Set(filePath);
			}

			relativePath.Replace('\\', '/');
			mProjectRegistry.Register(sceneGuid, relativePath);

			// Save registry to disk
			let registryPath = scope String()..AppendF("{}/project.registry", projectDir);
			mProjectRegistry.SaveToFile(registryPath);
			mEditorLogger.Log(.Information, scope String()..AppendF("Registered in project registry: {}", relativePath));
		}
	}

	private void OpenSceneFile(StringView path)
	{
		// Create scene through RuntimeContext so subsystems inject component managers
		let sceneSub = mRuntimeContext.GetSubsystem<SceneSubsystem>();
		if (sceneSub == null)
		{
			mEditorLogger.Log(.Error, "No SceneSubsystem in RuntimeContext");
			return;
		}

		// Extract scene name from filename
		let sceneName = scope String();
		System.IO.Path.GetFileNameWithoutExtension(path, sceneName);

		let scene = sceneSub.CreateScene(sceneName);

		// Read and deserialize scene file through the resource path
		let text = scope String();
		if (System.IO.File.ReadAllText(path, text) case .Err)
		{
			mEditorLogger.Log(.Error, scope String()..AppendF("Failed to read scene file: {}", path));
			sceneSub.DestroyScene(scene);
			return;
		}

		let reader = ResourceSystem.SerializerProvider.CreateReader(text);
		if (reader == null)
		{
			mEditorLogger.Log(.Error, "Failed to create scene reader");
			sceneSub.DestroyScene(scene);
			return;
		}
		defer delete reader;

		// Use a temporary SceneResource to deserialize through the Resource path
		// (reads header + scene data via SceneResource.OnSerialize)
		let tempResource = scope SceneResource();
		tempResource.Scene = scene;
		tempResource.TypeRegistry = mTypeRegistry;
		tempResource.Serialize(reader);

		// Create page
		let page = new SceneEditorPage(scene, path, mEditorContext);

		let sceneRenderer = mRuntimeContext.GetSubsystemByInterface<ISceneRenderer>();
		let content = ScenePageBuilder.Build(page, mEditorContext, Device, mVGRenderer,
			sceneRenderer, Shell.InputManager.Keyboard);
		page.SetContentView(content);

		mEditorContext.PageManager.AddPage(page);
		mEditorLogger.Log(.Information, scope String()..AppendF("Opened scene: {}", path));

		// Debug: check state after first update tick
	}

	private void OnPageOpened(IEditorPage page)
	{
		if (page == null || page.ContentView == null) return;
		let dockManager = mEditorContext.DockManager;
		if (dockManager == null) return;

		// Create dock panel for this page.
		let panel = dockManager.AddPanel(page.Title, page.ContentView);
		panel.Closable = true;

		// When dock tab X is clicked, detach content (page owns it) and close via PageManager.
		// Note: DockManager's own OnCloseRequested handler (registered first in AddPanel)
		// calls ClosePanel before this handler runs, so the dock panel is already undocked.
		let capturedPage = page;
		panel.OnCloseRequested.Add(new (dp) => {
			// Detach content before dock manager deletes the panel.
			if (capturedPage.ContentView?.Parent != null)
				if (let parent = capturedPage.ContentView.Parent as ViewGroup)
					parent.DetachView(capturedPage.ContentView);

			// Close through PageManager (fires OnPageClosed, handles cleanup + placeholder).
			mEditorContext.PageManager.Close(capturedPage);
		});

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

		mPageDockPanels[.(page)] = panel;
	}

	private void OnPageClosed(IEditorPage page)
	{
		let key = ObjectKey<IEditorPage>(page);

		// Detach content view from dock panel before the page deletes it.
		// During normal tab close, OnCloseRequested already did this.
		// During shutdown, PageManager.Close calls us directly - need to ensure detach.
		if (page.ContentView?.Parent != null)
			if (let parent = page.ContentView.Parent as ViewGroup)
				parent.DetachView(page.ContentView);

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
				placeholderContent.FontSize = 14;
				placeholderContent.HAlign = .Center;
				placeholderContent.VAlign = .Middle;
				placeholderContent.TextColor = .(100, 100, 115, 255);
				mPlaceholderPanel = dockManager.AddPanel("Editor", placeholderContent);
				mPlaceholderPanel.OnCloseRequested.Add(new (p) => { mPlaceholderPanel = null; });
				// Dock above the remaining root (console/assets) to recreate the original split
				dockManager.DockPanelRelativeTo(mPlaceholderPanel, .Top, dockManager.RootNode);
			}
		}
	}

	private void RenderActiveViewports(ICommandEncoder encoder, int32 frameIndex)
	{
		if (mEditorContext?.PageManager == null) return;

		// Render viewports for ALL open scene pages that still have dock panels.
		for (let page in mEditorContext.PageManager.OpenPages)
		{
			if (let scenePage = page as SceneEditorPage)
			{
				if (scenePage.ContentView != null && !scenePage.ContentView.IsPendingDeletion)
					RenderViewportsInTree(scenePage.ContentView, encoder, frameIndex);
			}
		}
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

	/// Ensures default builtin assets (primitives, materials) exist on disk.
	/// Creates them if missing, loads the registry, and adds it to ResourceSystem.
	private void EnsureDefaultAssets()
	{
		let assetRoot = scope String();
		GetAssetPath("", assetRoot);

		let registryPath = scope String();
		registryPath.AppendF("{}/builtin.registry", assetRoot);

		// Check if assets need generating
		bool needsGeneration = !System.IO.File.Exists(registryPath);

		if (needsGeneration)
		{
			mEditorLogger.Log(.Information, "Generating default builtin assets...");
			let provider = ResourceSystem.SerializerProvider;
			let tempRegistry = scope Sedulous.Resources.ResourceRegistry();

			GenerateDefaultPrimitives(assetRoot, provider, tempRegistry);
			GenerateDefaultMaterials(assetRoot, provider, tempRegistry);

			tempRegistry.SaveToFile(registryPath);
			mEditorLogger.Log(.Information, "Default builtin assets generated.");
		}

		// Load builtin registry with name "builtin" and root = asset directory
		mPrimitiveRegistry = new Sedulous.Resources.ResourceRegistry("builtin", assetRoot);
		if (mPrimitiveRegistry.LoadFromFile(registryPath) case .Ok)
		{
			ResourceSystem.AddRegistry(mPrimitiveRegistry);
			mEditorLogger.Log(.Information, scope String()..AppendF("Builtin registry loaded ({} entries)", mPrimitiveRegistry.Count));
		}
		else
		{
			mEditorLogger.Log(.Warning, "Failed to load builtin registry.");
		}
	}

	private void GenerateDefaultPrimitives(StringView assetRoot, Sedulous.Serialization.ISerializerProvider provider, Sedulous.Resources.ResourceRegistry registry)
	{
		let primDir = scope String()..AppendF("{}/primitives", assetRoot);
		if (!System.IO.Directory.Exists(primDir))
			System.IO.Directory.CreateDirectory(primDir);

		// Plane
		{
			let res = StaticMeshResource.CreatePlane(10, 10, 1, 1);
			res.Name = "Plane";
			let path = scope String()..AppendF("{}/plane.mesh", primDir);
			res.SaveToFile(path, provider);
			registry.Register(res.Id, "primitives/plane.mesh");
			delete res;
		}

		// Cube
		{
			let res = StaticMeshResource.CreateCube(1.0f);
			res.Name = "Cube";
			let path = scope String()..AppendF("{}/cube.mesh", primDir);
			res.SaveToFile(path, provider);
			registry.Register(res.Id, "primitives/cube.mesh");
			delete res;
		}

		// Sphere
		{
			let res = StaticMeshResource.CreateSphere(0.5f, 32, 16);
			res.Name = "Sphere";
			let path = scope String()..AppendF("{}/sphere.mesh", primDir);
			res.SaveToFile(path, provider);
			registry.Register(res.Id, "primitives/sphere.mesh");
			delete res;
		}
	}

	private void GenerateDefaultMaterials(StringView assetRoot, Sedulous.Serialization.ISerializerProvider provider, Sedulous.Resources.ResourceRegistry registry)
	{
		let matDir = scope String()..AppendF("{}/materials", assetRoot);
		if (!System.IO.Directory.Exists(matDir))
			System.IO.Directory.CreateDirectory(matDir);

		// Default PBR material
		{
			let mat = Sedulous.Materials.Materials.CreatePBR("Default", "forward");
			let res = new Sedulous.Materials.Resources.MaterialResource(mat, true);
			res.Name = "Default";
			let path = scope String()..AppendF("{}/default.material", matDir);
			res.SaveToFile(path, provider);
			registry.Register(res.Id, "materials/default.material");
			delete res;
		}

		// Default Unlit material
		{
			let mat = Sedulous.Materials.Materials.CreateUnlit("DefaultUnlit");
			let res = new Sedulous.Materials.Resources.MaterialResource(mat, true);
			res.Name = "DefaultUnlit";
			let path = scope String()..AppendF("{}/default_unlit.material", matDir);
			res.SaveToFile(path, provider);
			registry.Register(res.Id, "materials/default_unlit.material");
			delete res;
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
		let content = ScenePageBuilder.Build(page, mEditorContext, Device, mVGRenderer,
			sceneRenderer, Shell.InputManager.Keyboard);
		page.SetContentView(content);

		mEditorContext.PageManager.AddPage(page);
		mEditorLogger.Log(.Information, "Created new scene");
	}

	// ==================== Frame Loop ====================

	protected override void OnInput(FrameContext frame)
	{
		mFrameDelta = frame.DeltaTime;

		if (mUIContext == null) return;

		let mouse = Shell.InputManager.Mouse;
		let keyboard = Shell.InputManager.Keyboard;

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
				if (keyboard.IsKeyDown(.LeftShift))
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

		// Determine which window has the mouse.
		RootView inputRoot = mMainRoot;
		for (let kv in mFloatingWindowMap)
		{
			if (kv.value.Window.Focused)
			{
				if (let data = kv.value.UserData as FloatingWindowData)
					inputRoot = data.RootView;
				break;
			}
		}

		// Cross-window drag: move OS window, route input to main window.
		if ((dragDrop.IsDragging || dragDrop.IsPotentialDrag) && inputRoot !== mMainRoot)
		{
			let globalX = mouse.GlobalX;
			let globalY = mouse.GlobalY;

			// Capture drag offset on first frame.
			if (dragDrop.IsDragging && mDragSourceWindow == null)
			{
				for (let kv in mFloatingWindowMap)
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

			// Move the floating OS window to follow cursor.
			if (mDragSourceWindow != null)
			{
				mDragSourceWindow.X = (int32)(globalX - mDragWindowOffsetX);
				mDragSourceWindow.Y = (int32)(globalY - mDragWindowOffsetY);
			}

			// Route to main window with global-to-main-relative conversion.
			mUIContext.ActiveInputRoot = mMainRoot;
			let mx = globalX - (float)Window.X;
			let my = globalY - (float)Window.Y;
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
	}

	protected override void OnUpdate(FrameContext frame)
	{
		if (mUIContext == null) return;

		mFrameDelta = frame.DeltaTime;

		// Flush buffered log messages to the LogView on the main thread.
		mLogBuffer.Flush();

		// Tick RuntimeContext (component init, scene updates for editor mode).
		mRuntimeContext.BeginFrame(frame.DeltaTime);
		mRuntimeContext.Update(frame.DeltaTime);
		mRuntimeContext.PostUpdate(frame.DeltaTime);
		mRuntimeContext.EndFrame();

		// Update plugins
		mEditorContext.PluginRegistry.UpdateAll(frame.DeltaTime);

		// Update active page
		mEditorContext.PageManager.ActivePage?.Update(frame.DeltaTime);

		// UI frame
		mMainRoot.DpiScale = Window.ContentScale;
		mMainRoot.ViewportSize = .((float)Window.Width, (float)Window.Height);
		mUIContext.BeginFrame(frame.DeltaTime);
		mUIContext.UpdateRootView(mMainRoot);
	}

	protected override void OnPrepareFrame(FrameContext frame)
	{
		if (mUIContext == null || mVGContext == null || mVGRenderer == null) return;

		// Build VG geometry
		mVGContext.Clear();
		mUIContext.DrawRootView(mMainRoot, mVGContext);

		// Upload to GPU
		mVGRenderer.UpdateProjection(SwapChain.Width, SwapChain.Height, frame.FrameIndex);
		let batch = mVGContext.GetBatch();
		if (batch != null)
			mVGRenderer.Prepare(batch, frame.FrameIndex);
	}

	protected override bool OnRenderFrame(Sedulous.Runtime.Client.RenderContext render)
	{
		let encoder = render.Encoder;
		let frame = render.Frame;

		// Render active viewport views (3D scenes) to their offscreen textures
		// BEFORE UI rendering - the UI will display these textures via DrawImage.
		RenderActiveViewports(encoder, frame.FrameIndex);

		// Begin render pass for UI
		ColorAttachment[1] colorAttachments = .(.()
		{
			View = render.CurrentTextureView,
			LoadOp = .Clear,
			StoreOp = .Store,
			ClearValue = .(0.12f, 0.12f, 0.15f, 1)
		});

		RenderPassDesc passDesc = .() { ColorAttachments = .(colorAttachments) };
		let renderPass = encoder.BeginRenderPass(passDesc);
		if (renderPass != null)
		{
			mVGRenderer.Render(renderPass, SwapChain.Width, SwapChain.Height, frame.FrameIndex);
			renderPass.End();
		}

		return true;
	}

	// ==================== IFloatingWindowHost ====================

	public bool SupportsOSWindows => true;

	public void CreateFloatingWindow(View floatingWindow, float width, float height,
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

		if (CreateSecondaryWindow(settings) case .Err)
		{
			Console.WriteLine("Failed to create floating OS window");
			delete onCloseRequested;
			return;
		}

		let ctx = mSecondaryWindows[mSecondaryWindows.Count - 1];
		ctx.Window.X = Window.X + (int32)screenX;
		ctx.Window.Y = Window.Y + (int32)screenY;

		let data = new FloatingWindowData();
		data.OnCloseDelegate = onCloseRequested;
		if (onCloseRequested != null)
			ctx.OnCloseRequested = new (swCtx) => { data.OnCloseDelegate(floatingWindow); };
		else
			ctx.OnCloseRequested = new (swCtx) => { };

		data.RootView = new RootView();
		data.RootView.DpiScale = ctx.Window.ContentScale;
		data.RootView.ViewportSize = .((float)ctx.Window.Width, (float)ctx.Window.Height);
		mUIContext.AddRootView(data.RootView);
		data.RootView.AddView(floatingWindow);
		data.FloatingView = floatingWindow;

		data.VGContext = new VGContext(mFontService);
		data.VGRenderer = new VGRenderer();
		data.VGRenderer.Initialize(Device, ctx.SwapChain.Format,
			(int32)ctx.SwapChain.BufferCount, mShaderSystem);
		data.VGRenderer.SetExternalCache(mExternalTextureCache);

		ctx.UserData = data;
		mFloatingWindowMap[floatingWindow] = ctx;
	}

	public void DestroyFloatingWindow(View floatingWindow)
	{
		DestroyFloatingWindowImpl(floatingWindow);
	}

	public void MoveFloatingWindow(View floatingWindow, float screenX, float screenY)
	{
		if (mFloatingWindowMap.TryGetValue(floatingWindow, let ctx))
		{
			ctx.Window.X = Window.X + (int32)screenX;
			ctx.Window.Y = Window.Y + (int32)screenY;
		}
	}

	private void DestroyFloatingWindowImpl(View floatingWindow, bool detachView = true)
	{
		if (!mFloatingWindowMap.TryGetValue(floatingWindow, let ctx))
			return;

		mFloatingWindowMap.Remove(floatingWindow);

		if (let data = ctx.UserData as FloatingWindowData)
		{
			if (detachView && floatingWindow.Parent == data.RootView)
				data.RootView.DetachView(floatingWindow);

			mUIContext.RemoveRootView(data.RootView);
			Device.WaitIdle();
			delete data;
		}

		ctx.UserData = null;
		DestroySecondaryWindow(ctx);
	}

	// ==================== Secondary Window Rendering ====================

	protected override void OnPrepareSecondaryFrame(SecondaryWindowContext ctx, FrameContext frame)
	{
		if (let data = ctx.UserData as FloatingWindowData)
		{
			data.RootView.DpiScale = ctx.Window.ContentScale;
			data.RootView.ViewportSize = .((float)ctx.Window.Width, (float)ctx.Window.Height);
			mUIContext.UpdateRootView(data.RootView);
		}
	}

	protected override void OnRenderSecondaryWindow(SecondaryWindowContext ctx,
		IRenderPassEncoder renderPass, FrameContext frame)
	{
		if (let data = ctx.UserData as FloatingWindowData)
		{
			let vg = data.VGContext;
			let renderer = data.VGRenderer;
			let w = ctx.SwapChain.Width;
			let h = ctx.SwapChain.Height;

			vg.Clear();
			mUIContext.DrawRootView(data.RootView, vg);
			let batch = vg.GetBatch();
			if (batch == null || batch.Commands.Count == 0)
				return;

			renderer.UpdateProjection(w, h, frame.FrameIndex);
			renderer.Prepare(batch, frame.FrameIndex);
			renderer.Render(renderPass, w, h, frame.FrameIndex);
		}
	}

	// ==================== Shutdown ====================

	protected override void OnShutdown()
	{
		// Shutdown plugins
		mEditorContext.PluginRegistry.ShutdownAll();

		// Detach all page content views from dock panels before pages are deleted.
		// Don't call ClosePanel - the view tree will be cascade-deleted by
		// RootView's destructor during UIContext cleanup.
		for (let page in mEditorContext.PageManager.OpenPages)
		{
			if (page.ContentView?.Parent != null)
				if (let parent = page.ContentView.Parent as ViewGroup)
					parent.DetachView(page.ContentView);
		}
		mPageDockPanels.Clear();

		// Shutdown pages (deletes pages + their content views)
		mEditorContext.PageManager.Shutdown();

		// Close project
		mProject.Close();

		// Clean up editor context
		mEditorContext.Dispose();

		// Clean up runtime context (must be deleted before Device is destroyed
		// since its subsystems share the Device).
		mRuntimeContext.Shutdown();
		delete mRuntimeContext;
		mRuntimeContext = null;

		// Destroy floating windows (before UIContext so roots are removed cleanly)
		for (let kv in mFloatingWindowMap)
			DestroyFloatingWindowImpl(kv.key, detachView: false);
		mFloatingWindowMap.Clear();

		// Clean up UI
		if (mUIContext != null)
		{
			mUIContext.RemoveRootView(mMainRoot);
			delete mUIContext;
			mUIContext = null;
		}

		delete mMainRoot;
		mMainRoot = null;

		if (mVGRenderer != null)
		{
			mVGRenderer.Dispose();
			delete mVGRenderer;
			mVGRenderer = null;
		}

		mShaderSystem?.Dispose();
		delete mShaderSystem;
		mShaderSystem = null;
	}

	protected override void OnResize(int32 width, int32 height)
	{
		// UI updates viewport on next frame via mMainRoot.ViewportSize
	}
}
