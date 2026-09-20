using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Shell;
using Sedulous.Graphics;
using Sedulous.Fonts;
using Sedulous.Fonts.Resource;
using Sedulous.Fonts.TrueType;
using Sedulous.Fonts.DistanceField.Baker;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.Engine.DefaultApp;
using Sedulous.Render;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.UI.Runtime;
using Sedulous.UI.Application;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.Resource;
using Sedulous.Settings;
using Sedulous.Pipeline.Core;
using Sedulous.Editor.Core;
using Sedulous.Editor.Preview;

namespace Sedulous.Editor.App;

/// The editor as a runtime IApplication: the TrueType font service, UIHost and
/// RuntimeDockableWindowHost (floating panels as borderless OS windows), the EditorShell chrome
/// on the main window, with the EditorContext and EditorProject underneath, and a second,
/// embedded runtime context populated by the same DefaultApplication the player runs, where
/// every scene is hosted. Opens or scaffolds the project on startup, or starts on the project
/// manager; restores the per-project dock layout and saves it on shutdown.
class EditorApplication : IApplication
{
	/// False is the classic per-size raster ramp; true is MSDF distance-field atlases, one
	/// 48px bake per family served at every requested size.
	private const bool cUseDistanceFieldFonts = true;

	private EditorAppConfig mConfig ~ delete _;
	/// Borrowed.
	private IApplicationHost mHost = null;
	/// Borrowed; the exe injects it.
	private ISceneRenderer mSceneRenderer = null;

	/// The disk cache for the startup MSDF font bake.
	private FontAtlasDiskCache mFontAtlasCache = null ~ delete _;
	private TrueTypeFontService mFontService = null ~ delete _;
	private ToolkitThemeExtension mToolkitTheme = new .() ~ delete _;
	private StyleSheet mStyleSheet = null ~ { if (_ != null) _.ReleaseRef(); };

	// The embedded runtime: gameplay subsystems and all scene hosting live here. The app
	// registers subsystems it OWNS (render, audio, input, UI) into the context, so the
	// context is declared after the app and disposes first, unregistering them while they
	// are alive; the page holders below are declared later still, so every page's
	// preview scene leaves the context before it goes.
	private EmbeddedApplicationHost mEmbeddedHost = null ~ delete _;
	private DefaultApplication mEmbeddedApp = null ~ delete _;
	private Context mRuntimeContext = new .() ~ delete _;
	private bool mStopGameRequested = false;

	// The log drain state.
	private List<EditorLogEntry> mPendingLog = new .() ~ DeleteContainerAndItems!(_);
	private uint64 mLogSequence = 0;

	private EditorContext mContext = new .() ~ delete _;
	private EditorProject mProject = null ~ delete _;
	/// Exe-assembled through RegisterEditors.
	private BuilderRegistry mBuilders = new .() ~ delete _;
	private EditorCookService mCookService = new .() ~ delete _;
	private ThumbnailService mThumbnailService = new .() ~ delete _;
	/// The GPU half, per project.
	private ThumbnailStage mThumbnailStage = null ~ delete _;
	/// Background jobs: export, imports, native builds.
	private EditorJobService mJobService = new .() ~ delete _;
	/// The per-user editor preferences, <user-data>/editor.settings.xml.
	private Settings mEditorSettings = new .() ~ delete _;
	private ProjectManagerController mProjectManager ~ delete _;
	/// The per-project editor state: one store, typed sections.
	private Settings mProjectEditorSettings = null ~ delete _;
	private PendingExport mPendingExport = new .() ~ delete _;
	private ExportPresetsController mPresetsController = new .() ~ delete _;
	/// The export's pre-transcoded scene wires.
	private Dictionary<Guid, List<uint8>> mExportSceneStreams = new .() ~ { for (let e in _) delete e.value; delete _; };
	/// The main-thread loaded presets for the running job.
	private ExportPresetSet mExportPresets = new .() ~ delete _;
	/// The main-thread pre-scan: the reachable closure roots.
	private List<Guid> mExportReachableRoots = new .() ~ delete _;
	/// True when the pre-scan ran; otherwise no pruning this run.
	private bool mExportReachableValid = false;
	/// The primary game tab, the focus target; extras go untracked.
	private UIEditorPage mGamePage = null;
	/// The unique persistence id for "Play New Instance" tabs.
	private uint32 mGamePageCounter = 0;
	/// The auto-exit, auto-rebuild and screenshot accumulator.
	private float mElapsed = 0.0f;
	/// The --screenshot capture; the request is one shot.
	private ScreenshotCapture mScreenshot = new .() ~ delete _;
	private bool mScreenshotFired = false;
	private float mTestOpenElapsed = 0.0f;
	private uint32 mTestOpenStage = 0;
	private bool mAutoRebuilt = false;
	private float mResourceReportTimer = 0.0f;
	private List<DroppedFile> mDroppedFiles = new .() ~ DeleteContainerAndItems!(_);
	private List<IResourceFactory> mResourceFactories = new .() ~ DeleteContainerAndItems!(_);
	private ResourceManager mResources = null ~ delete _;

	// TEARDOWN ORDER: the UIHost owns the UIContext and input manager, so it is declared
	// before every view-holding member below and destructs after them; a view's teardown
	// detaches from its context.
	/// The data mount.
	private NativeFileSystem mDataFileSystem = null ~ delete _;
	private UIHost mUiHost = null ~ delete _;
	/// The content scale the icon set was last baked for.
	private float mIconBakeScale = 0.0f;
	/// Built on the first EnterManagerMode.
	private ProjectManagerView mManagerView = null ~ delete _;
	/// The starter-content request from CreateFromManager.
	private bool mSeedAfterOpen = false;
	private bool mInManagerMode = false;
	/// References the UI host; dies first.
	private RuntimeDockableWindowHost mDockHost = null ~ delete _;
	private EditorShell mShell = new .() ~ delete _;
	private AssetsView mAssetsView = null ~ { if (_ != null) _.ReleaseRef(); };
	/// Borrowed; the shell root owns it.
	private ToastHost mToastHost = null;
	private List<PagePanel> mPagePanels = new .() ~ delete _;

	/// Takes ownership of the config.
	public this(EditorAppConfig config)
	{
		mConfig = config;
		mProjectManager = new ProjectManagerController(mEditorSettings);
		// Thumbnails are reachable from the constructor on: the registration block, where
		// each domain folds its thumbnail generator in, runs before the UI boot phase.
		mContext.Thumbnails = mThumbnailService;
	}

	public EditorContext Context => mContext;
	public EditorProject Project => mProject;
	public EditorShell Shell => mShell;
	/// The exe registers every engine builder here, mirroring the cook CLI's set; the cook
	/// service routes through it.
	public BuilderRegistry Builders => mBuilders;
	public EditorCookService CookService => mCookService;
	public ResourceManager Resources => mResources;
	/// Valid after OnStartup; the Game page drives its play bracket through it.
	public DefaultApplication EmbeddedApplication => mEmbeddedApp;

	/// The exe registers runtime resource factories here; the app owns them and the
	/// ResourceManager over the project's cooked database. Takes ownership.
	public void AddResourceFactory(IResourceFactory factory)
	{
		if (factory == null)
			return;
		if (mResources != null)
			mResources.AddFactory(factory);
		mResourceFactories.Add(factory);
	}

	/// The renderer interface the app drives its per-frame scene bracket through; null means
	/// no scene rendering. Borrowed.
	public void SetSceneRenderer(ISceneRenderer renderer) => mSceneRenderer = renderer;

	public void Configure(IApplicationHost host)
	{
		if (mConfig.ConfigureEngine != null)
			mConfig.ConfigureEngine(host);
	}

	public void OnStartup(IApplicationHost host)
	{
		mHost = host;
		let mainRw = host.MainRenderWindow;
		if (mainRw == null)
			return;

		LoadEditorSettings(); // the per-user prefs first: the font paths honour them
		// Domains reach their own sections through the context.
		mContext.UserEditorSettings = mEditorSettings;

		// Fonts: CPU rasterisation and baking, no device needed. The resolution chain per
		// family is the Preferences override, the configured path, then the embedded face,
		// since a relocated editor must never come up textless. Every failure is loud.
		mFontService = new TrueTypeFontService();
		// The MSDF bakes hit the per-user disk cache: the first launch bakes and stores,
		// every launch after loads the atlas instead of re-running msdfgen.
		mFontAtlasCache = new FontAtlasDiskCache(PathJoin(GetUserDataDirectory(.. scope .()), "font-atlas-cache", .. scope .()));
		FontAtlasBakerFactory.SetAtlasCache(mFontAtlasCache);
		let fontPath = scope String(mConfig.FontPath);
		let monoFontPath = scope String(mConfig.MonoFontPath);
		if (let fontPrefs = mEditorSettings.Find<EditorFontSettings>())
		{
			if (!fontPrefs.FontPath.IsEmpty)
				fontPath.Set(fontPrefs.FontPath);
			if (!fontPrefs.MonoFontPath.IsEmpty)
				monoFontPath.Set(fontPrefs.MonoFontPath);
		}

		if (cUseDistanceFieldFonts)
		{
			// One atlas per family, baked at 48px, sampled crisp at every size the styles
			// request; the VG renderer switches to the distance-field pipeline per glyph run.
			DistanceFieldFonts.Initialize();
			var options = FontLoadOptions.DistanceField();
			options.FirstCodepoint = 32;
			options.LastCodepoint = 255;
			options.AtlasWidth = 1024;
			options.AtlasHeight = 1024;
			LoadFamily("Roboto", fontPath, scope float[](48.0f), options, mConfig.EmbeddedFont);
			LoadFamily("Mono", monoFontPath, scope float[](48.0f), options, .()); // no embedded twin
		}
		else
		{
			// A full ramp, so styles pick small, regular and heading sizes without a
			// mismatched rasterisation; the mono ramp only spans the code text range.
			LoadFamily("Roboto", fontPath, scope float[](10, 11, 12, 13, 14, 16, 18, 20, 24, 32), FontLoadOptions.ExtendedLatin(), mConfig.EmbeddedFont);
			LoadFamily("Mono", monoFontPath, scope float[](10, 11, 12, 13, 14, 16), FontLoadOptions.ExtendedLatin(), .());
		}
		EditorIcons.Initialize();
		// The editor's mount over the data root: the UI host reads its VG shaders through it.
		mDataFileSystem = new NativeFileSystem(mConfig.DataRoot);
		mUiHost = new UIHost(host.Graphics, host.Shell, mFontService, mDataFileSystem);
		mDockHost = new RuntimeDockableWindowHost(host, mUiHost);

		// The theme: the toolkit extension registers before the stylesheet is created, since
		// extensions only apply to themes built afterward. The warm Graphite and Orange
		// palette on the rounded theme.
		ThemeRegistry.RegisterExtension(mToolkitTheme);
		let palette = ThemePalette.GraphiteOrange();
		mStyleSheet = RoundedDarkTheme.Create(palette);
		// The window clear colour comes from the same palette: any surface the chrome does
		// not cover, the project manager screen most of all, reads as the theme's background.
		mUiHost.SetClearColor(palette.Background.R, palette.Background.G, palette.Background.B, 1.0f);
		// Editor overrides on the stock theme: property-grid fields read better smaller and
		// tighter than the theme's control chrome.
		mStyleSheet.ForClass("property-field")
			.Set(.FontSize, 12.0f)
			.Set(.Padding, Thickness(5, 2));

		// The icon bake: every editor SVG rasterised once, supersampled, into a shared atlas at
		// the chrome sizes the UI uses, so instances draw pixel-snapped quads with no
		// per-tab subpixel shimmer. The close X becomes a themed drawable for the dock chrome.
		{
			float uiScale = 1.0f;
			if (let uiPrefs = mEditorSettings.Find<EditorUiSettings>())
				uiScale = Math.Clamp(uiPrefs.UiScale, 1.0f, 2.0f);
			mUiHost.SetUiScale(uiScale);
			BakeEditorIcons(mainRw.Window.ContentScale * uiScale);
			if (EditorIcons.Close != null)
			{
				EditorIcons.Close.TintColor = Color(palette.Text.R, palette.Text.G, palette.Text.B, 190.0f / 255.0f);
				mStyleSheet.ForTypePseudo(typeof(DockablePanel), "close-button").Set(.Background, Retained(EditorIcons.Close));
				mStyleSheet.ForTypePseudo(typeof(DockTabGroup), "close-button").Set(.Background, Retained(EditorIcons.Close));
			}
		}
		mStyleSheet.AddRef();
		mUiHost.Context.SetStyleSheet(mStyleSheet);

		// Exit goes through the dirty check: the shell consults this before honouring the
		// main window's close button; File > Exit routes through the same helper.
		host.Shell.SetMainWindowCloseHandler(new () => ConfirmExitAllowed());

		mShell.Build(mContext, mDockHost, mainRw.Window.Width, mainRw.Window.Height);
		// The active page follows dock-tab activation, not just open and close: with
		// side-by-side tab groups Save was hitting whichever page opened last. Non-page
		// panels leave the active page alone.
		mShell.Docks.OnPanelActivated.Add(new (panel) =>
			{
				if (panel == null)
					return;
				for (let entry in mPagePanels)
				{
					if (entry.Panel === panel)
					{
						mContext.SetActivePage(entry.Page);
						return;
					}
				}
			});
		mShell.Root.AddRef();
		mUiHost.AttachWindow(mainRw, mShell.Root);

		// The toast overlay on the main window root; Notify routes here and mirrors to the
		// status bar.
		mToastHost = new ToastHost();
		mShell.Root.AddView(mToastHost);
		mContext.OnNotice = new (kind, message) =>
			{
				ShowToast(kind, message);
				mContext.SetStatus(message);
			};

		// ---- the embedded runtime ----
		// A second, persistent runtime context populated by the same DefaultApplication the
		// player runs: gameplay subsystems live there and every scene is hosted there. It
		// starts without a resource manager: the per-project manager late-attaches in
		// OpenProjectAt and detaches in CloseProject.
		mEmbeddedHost = new EmbeddedApplicationHost(host, mRuntimeContext);
		mEmbeddedHost.SetExitHandler(new (code) =>
			{
				// Exit from embedded game code stops the play session, deferred past the
				// page-update loop since the request usually fires from inside the script.
				GlobalLog(.Information, "Editor: embedded app requested exit({})", code);
				mStopGameRequested = true;
			});
		mEmbeddedApp = new DefaultApplication();
		mEmbeddedApp.SetDataRoot(mConfig.DataRoot); // the editor's root, not a re-walk
		mEmbeddedApp.Configure(mEmbeddedHost);
		// Un-bound input must never reach scene-tier game UI here: editing and Simulate HUDs
		// render WYSIWYG but are not interactive; the Game tab binds its scene on Play.
		if (mEmbeddedApp.Input != null)
			mEmbeddedApp.Input.UnboundScenePolicy = .ScreenTierOnly;
		mRuntimeContext.Startup();
		mEmbeddedApp.OnStartup(mEmbeddedHost);

		// The per-subsystem editor plugins register here, receiving the embedded host so
		// every page's context resolves to the runtime context. Once per run: the factories
		// capture the embedded host and app, which stay alive across project close and open.
		if (mConfig.RegisterEditors != null)
			mConfig.RegisterEditors(this, mEmbeddedHost, mUiHost);

		// Menus after registration: File > New builds from the creator registry.
		BuildMenus();

		if (mConfig.StartInProjectManager)
			EnterManagerMode();
		else
			OpenProjectAt(mConfig.ProjectDirectory);
	}

	/// Loads one family across the sizes; falls back to the embedded face when the path
	/// fails outright. Loud on total failure.
	private bool LoadFamily(StringView family, StringView path, Span<float> sizes, FontLoadOptions options, Span<uint8> embedded)
	{
		var options;
		bool anyLoaded = false;
		for (let size in sizes)
		{
			options.PixelHeight = size;
			if (!path.IsEmpty && (mFontService.LoadFont(family, path, options) == .Success))
			{
				anyLoaded = true;
				continue;
			}
			if (!embedded.IsEmpty && (mFontService.LoadFontFromMemory(family, embedded, options) == .Success))
				anyLoaded = true;
		}
		if (!anyLoaded)
		{
			GlobalLog(.Error, "Editor: font family '{}' failed to load (path '{}', embedded fallback {}), its text will not render",
				family, path, embedded.IsEmpty ? "absent" : "failed");
		}
		return anyLoaded;
	}

	private static Drawable Retained(Drawable drawable)
	{
		if (drawable != null)
			drawable.AddRef();
		return drawable;
	}

	/// The page keeps its content view; the dock takes a reference of its own.
	private static View RetainedView(View view)
	{
		if (view != null)
			view.AddRef();
		return view;
	}

	/// Opening a page over uncooked content queues a scoped cook: every resource id that was
	/// requested during the page's resolve but has no product (product guid equals source
	/// guid, so the misses are the exact missing-dependency roots), plus the page's own asset
	/// when its cook is missing or failed. Fully cooked pages request nothing.
	public void CookMissingForPage(Instance instance)
	{
		if (mProject == null)
			return;
		let unresolved = scope List<Guid>();
		if (mResources != null)
			mResources.CollectUnresolved(unresolved);
		// Only ids with a live source instance can cook: a stale ref to a deleted asset stays
		// unresolved forever and must not re-request a cook on every open.
		let roots = scope List<Guid>();
		for (let id in unresolved)
		{
			if (mProject.SourceDb.GetInstance(id) != null)
				roots.Add(id);
		}
		let badge = mCookService.BadgeFor(instance);
		if ((badge == .Missing) || (badge == .Failed))
			roots.Add(instance.Id);
		if (roots.IsEmpty)
			return;
		mCookService.RequestCookFor(roots, false);
	}

	/// Opens or focuses the Game tab: play-in-editor, the page's own toolbar running Play and
	/// Stop, created through the scene plugin's factory seam. `newInstance` opens an
	/// additional tab driving its own game instance.
	public void OpenGamePage(bool newInstance = false)
	{
		if (!newInstance && (mGamePage != null))
		{
			for (let entry in mPagePanels)
			{
				if (entry.Page === mGamePage)
				{
					mShell.Docks.ActivatePanel(entry.Panel);
					mContext.SetActivePage(mGamePage);
					return;
				}
			}
		}
		if (mContext.GamePageFactory == null)
		{
			mContext.Notify(.Info, "No game page registered in this build.");
			return;
		}
		let page = mContext.GamePageFactory(newInstance);
		if (page == null)
			return;
		// Every page in this app is a UIEditorPage, the Game page too.
		let uiPage = mContext.AdoptPage(page) as UIEditorPage;
		if (uiPage == null)
			return;
		if (!newInstance)
			mGamePage = uiPage; // only the primary tab is the focus target

		let panel = mShell.AddPagePanel(uiPage.Title, RetainedView(uiPage.ContentView));
		// A unique persistence id per tab, so a docking restore cannot collide.
		if (newInstance)
			panel.SetPersistenceId(scope $"game-page-{++mGamePageCounter}");
		else
			panel.SetPersistenceId("game-page");
		panel.OnCloseRequested.Add(new [=uiPage, =this](p) =>
			{
				mUiHost.Context.MutationQueue.QueueAction(new [=uiPage, =this]() => { ClosePage(uiPage); });
			});
		mPagePanels.Add(.(uiPage, panel));
	}

	/// Opens or focuses a page for the instance and docks its content as a centre tab.
	public UIEditorPage OpenInstancePage(Instance instance)
	{
		let before = mContext.OpenPages.Count;
		let page = mContext.OpenPage(instance);
		if (page == null)
		{
			// The toast stays short; the log carries the identifying details, since an
			// unresolvable type is a retired or unregistered identity and the spelling is
			// the clue.
			GlobalLog(.Warning, "Editor: no editor page for asset '{}', stored type '{}', guid {} (unknown type name, or no page factory registered)",
				instance.Name, instance.TypeName, instance.Id);
			mContext.Notify(.Warning, "No editor registered for this asset type.");
			return null;
		}
		let uiPage = page as UIEditorPage;
		if (uiPage == null)
			return null;
		if (mContext.OpenPages.Count == before)
		{
			// An existing page was focused: its tab selects.
			for (let entry in mPagePanels)
			{
				if (entry.Page === uiPage)
				{
					mShell.Docks.ActivatePanel(entry.Panel);
					break;
				}
			}
			return uiPage;
		}

		let panel = mShell.AddPagePanel(uiPage.Title, RetainedView(uiPage.ContentView));
		// A guid-keyed persistence id: the saved dock layout re-places this page's panel when
		// the page reopens on the next launch.
		panel.SetPersistenceId(uiPage.InstanceId.ToString(.. scope .(), 'D'));
		// The DockManager's own close handling destroys the panel through its deferred queue;
		// the page tears down too, deferred through the mutation queue.
		panel.OnCloseRequested.Add(new [=uiPage, =this](p) =>
			{
				mUiHost.Context.MutationQueue.QueueAction(new [=uiPage, =this]() => { ClosePage(uiPage); });
			});
		// Dirty pages do not close silently: the gesture is vetoed and Save, Discard or Cancel
		// prompted. The dialog's buttons raise OnCloseRequested directly, bypassing the veto.
		panel.OnCloseInterceptor = new [=uiPage, =this](p) =>
			{
				if (!uiPage.IsDirty)
					return true;
				ShowDirtyCloseDialog(uiPage, p);
				return false;
			};
		mPagePanels.Add(.(uiPage, panel));
		CookMissingForPage(instance); // uncooked dependencies cook without a manual step
		return uiPage;
	}

	/// Binds the project's default UI theme and font onto the embedded app's game UI.
	/// Idempotent: at project open, after every finished cook (a fresh checkout's first cook
	/// creates the products the open-time bind missed), and on settings save.
	public void ApplyProjectUiDefaults()
	{
		if ((mProject == null) || (mResources == null) || (mEmbeddedApp == null) || (mEmbeddedApp.UI == null))
			return;
		let themeId = mProject.Settings.DefaultUiThemeId;
		if (themeId.IsSet)
		{
			let theme = mResources.Bind<Sedulous.UI.Resource.UITheme>(themeId).Get;
			if (theme != null)
				mEmbeddedApp.UI.SetDefaultTheme(theme);
		}
		let fontId = mProject.Settings.DefaultUiFontId;
		if (fontId.IsSet)
		{
			let font = mResources.Bind<Font>(fontId).Get;
			if (font != null)
				mEmbeddedApp.UI.SetDefaultFont(font);
		}
	}

	/// A context notice as a toast: errors stick until closed, the rest self-expire.
	public void ShowToast(NoticeKind kind, StringView message)
	{
		if (mToastHost == null)
			return;
		var request = ToastRequest(message);
		switch (kind)
		{
		case .Success: request.Severity = .Success;
		case .Warning: request.Severity = .Warning;
		case .Error: request.Severity = .Error;
		default: request.Severity = .Info;
		}
		request.DurationSeconds = (kind == .Error) ? 0.0f : 5.0f;
		mToastHost.Show(request);
	}

	public void SaveActivePage()
	{
		let page = mContext.ActivePage;
		if (page == null)
			return;
		if (page.Save() case .Ok)
			mContext.Notify(.Success, scope $"Saved '{page.Title}'.");
		else
			mContext.Notify(.Error, "Save FAILED (see Console).");
		FlushPendingAssetEdits();
	}

	/// Live edits to cooked products (terrain sculpt writes the runtime heightfield in place)
	/// are registered on the context by their viewport tool; a save writes them back to their
	/// source assets and recooks. Context-wide: any Save flushes whatever a tool queued.
	public void FlushPendingAssetEdits()
	{
		if ((mProject == null) || !mContext.HasPendingAssetEdits)
			return;
		if (mContext.DrainAssetEdits(mProject.SourceDb) case .Ok)
			mContext.Notify(.Success, "Persisted live asset edits.");
		else
			mContext.Notify(.Error, "Asset-edit persist FAILED (see Console).");
	}

	/// Tears down a page whose panel is closing or closed; the DockManager owns the panel.
	public void ClosePage(UIEditorPage page)
	{
		if (page === mGamePage)
			mGamePage = null;
		for (int i < mPagePanels.Count)
		{
			if (mPagePanels[i].Page === page)
			{
				if (page.IsDirty)
					mContext.SetStatus("Closed page had unsaved changes."); // no save prompt here
				page.OnClose(); // GPU and scene resources release while the device lives
				mPagePanels.RemoveAt(i);
				mContext.ClosePage(page); // destroys the page
				return;
			}
		}
	}

	public void OnUpdate(IApplicationHost host, float dt)
	{
		if (mThumbnailStage != null)
			mThumbnailStage.Update(); // the next queued GPU thumbnail job
		// A periodic resident-product report while a project is open: the background work
		// after open is what accumulates, so a single post-open snapshot misses it.
		if (mProject != null)
		{
			mResourceReportTimer += dt;
			if (mResourceReportTimer >= 15.0f)
			{
				mResourceReportTimer = 0.0f;
				ReportResourceMemory();
			}
		}
		// DPI drift: the window moved to a monitor with a different content scale, so the
		// icon set re-bakes at the new device sizes and stays texel crisp.
		if (mUiHost != null)
		{
			if (let mainRw = host.MainRenderWindow)
			{
				let scale = mainRw.Window.ContentScale * mUiHost.UiScale;
				if ((scale > 0.1f) && (Math.Abs(scale - mIconBakeScale) > 0.01f))
					BakeEditorIcons(scale);
			}
		}

		// The embedded runtime's frame lanes run first: per-scene fixed stepping in
		// BeginFrame, physics interpolation in Update, so pages read fresh state. EndFrame
		// closes in OnRenderWindow after the scene bracket. The embedded app's own OnUpdate
		// ticks every game instance's script once per frame.
		if (mEmbeddedApp != null)
		{
			let scaled = dt * mRuntimeContext.TimeScale;
			mRuntimeContext.BeginFrame(dt);
			mRuntimeContext.Update(scaled);
			mRuntimeContext.PostUpdate(scaled);
			mEmbeddedApp.OnUpdate(mEmbeddedHost, dt);
		}

		// A screenshot recorded last frame: wait for the GPU, then map and write it.
		if (mScreenshot.Recorded)
		{
			let graphics = host.Graphics;
			if ((graphics != null) && (graphics.Raw != null))
			{
				graphics.Raw.WaitIdle();
				let written = scope Sedulous.Image.Image();
				if (mScreenshot.Complete(graphics.Raw, written) case .Ok)
					GlobalLog(.Information, "Editor: screenshot written to {}", mConfig.ScreenshotPath);
			}
		}

		mElapsed += dt;
		if (!mConfig.ScreenshotPath.IsEmpty && !mScreenshotFired && (mElapsed >= mConfig.ScreenshotAfterSeconds))
		{
			mScreenshotFired = true;
			mScreenshot.Request(mConfig.ScreenshotPath);
		}
		if ((mConfig.AutoExitSeconds > 0.0f) || (mConfig.AutoRebuildSeconds > 0.0f))
		{
			if ((mConfig.AutoExitSeconds > 0.0f) && (mElapsed >= mConfig.AutoExitSeconds))
				host.RequestExit();
			if ((mConfig.AutoRebuildSeconds > 0.0f) && !mAutoRebuilt && (mElapsed >= mConfig.AutoRebuildSeconds))
			{
				mAutoRebuilt = true;
				mCookService.RequestCook(true);
			}
		}
		RunTestHooks(dt);

		DrainLog();
		SyncPageTitles();
		// Background-cook progress reaches the status bar; a finished cook refreshes the
		// Assets badges through OnCookFinished.
		mCookService.Update(scope (line) => { mContext.SetStatus(line); });

		// Background jobs: pump, drain job logs, and once an export's pre-cook has finished,
		// submit the export's pack and stage job. The running job's step and percent show in
		// the status bar.
		mJobService.Update(scope (line) => { mContext.SetStatus(line); });
		if (mPendingExport.Active && mPendingExport.WaitingCook && !mCookService.IsCooking)
		{
			mPendingExport.WaitingCook = false;
			SubmitExportJob(mPendingExport.PresetName, mPendingExport.All);
			mPendingExport.Active = false; // the job owns it now
		}
		if (mJobService.IsBusy)
		{
			let p = scope JobProgress();
			mJobService.Progress(p);
			if (p.Active)
			{
				let s = scope String(p.Title);
				if (!p.Step.IsEmpty)
					s.AppendF(": {}", p.Step);
				s.AppendF(" ({}%)", (int)(p.Fraction * 100.0f + 0.5f));
				mContext.SetStatus(s);
			}
		}

		if (mAssetsView != null)
			mAssetsView.Refresh();
		if (mResources != null)
		{
			mResources.Pump(); // async resource loads finalise
			mResources.CollectGarbage(); // hot-reloaded-away products release
		}

		// OS file drops, from any editor window, land in the Assets panel's selected group
		// through one review session for the whole drop.
		if ((mAssetsView != null) && (host.Shell != null))
		{
			ClearAndDeleteItems(mDroppedFiles);
			host.Shell.DrainDroppedFiles(mDroppedFiles);
			if (!mDroppedFiles.IsEmpty)
			{
				let paths = scope List<StringView>();
				for (let drop in mDroppedFiles)
					paths.Add(drop.Path);
				mAssetsView.ImportFiles(paths);
			}
		}
		if (mUiHost != null)
			mUiHost.Update(dt);
		if (mToastHost != null)
			mToastHost.Update(dt);
		if (mDockHost != null)
			mDockHost.Tick(); // the drag-follow for floating OS windows

		// The page hooks after the UI laid out, so viewport rects are current for input gating.
		for (let entry in mPagePanels)
			entry.Page.OnUpdate(host, dt);

		// The deferred embedded exit: safe here, no script dispatch on the stack.
		if (mStopGameRequested)
		{
			mStopGameRequested = false;
			if (mContext.StopGameRun != null)
				mContext.StopGameRun();
		}
	}

	/// The headless-debug hooks: ENV_TEST_OPEN=<guid> opens that instance's page ~2s in and
	/// again ~4s in, reproducing the browser's double-click paths in unattended runs;
	/// ENV_TEST_REIMPORT="<group>;<file>" deletes the group ~2s in and reimports the file
	/// ~4s in, scripting the delete-then-reimport repro. One hook per run.
	private void RunTestHooks(float dt)
	{
		if (mProject == null)
			return;
		let testOpen = scope String();
		if (GetEnvironmentVariable("ENV_TEST_OPEN", testOpen) case .Ok)
		{
			mTestOpenElapsed += dt;
			let first = (mTestOpenStage == 0) && (mTestOpenElapsed >= 2.0f);
			let second = (mTestOpenStage == 1) && (mTestOpenElapsed >= 4.0f);
			if (first || second)
			{
				mTestOpenStage++;
				if (Guid.Parse(testOpen) case .Ok(let id))
				{
					if (let instance = mProject.SourceDb.GetInstance(id))
						OpenInstancePage(instance);
				}
			}
		}
		let reimport = scope String();
		if (GetEnvironmentVariable("ENV_TEST_REIMPORT", reimport) case .Ok)
		{
			mTestOpenElapsed += dt;
			let semi = reimport.IndexOf(';');
			if (semi >= 0)
			{
				if ((mTestOpenStage == 0) && (mTestOpenElapsed >= 2.0f))
				{
					mTestOpenStage++;
					let groupName = StringView(reimport, 0, semi);
					if (let group = mProject.SourceDb.RootGroup.GetGroup(groupName))
					{
						mCookService.RunWhenIdle(new [=group, =this]() =>
							{
								mProject.SourceDb.DeleteGroup(group).IgnoreError();
								mContext.SetStatus("[test] deleted group");
								// Every source-database group mutation rebuilds the assets
								// tree before the next layout binds stale pointers.
								if (mAssetsView != null)
									mAssetsView.Rebuild();
							});
					}
				}
				else if ((mTestOpenStage == 1) && (mTestOpenElapsed >= 4.0f))
				{
					mTestOpenStage++;
					mContext.SetStatus("[test] reimporting");
					if (mAssetsView != null)
						mAssetsView.ImportFile(StringView(reimport, semi + 1));
				}
			}
		}
	}

	public void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		// Every page's viewport content renders during the main window's frame, inside one
		// scene-renderer bracket, before any UI draws: offscreen targets are window-agnostic,
		// so floated panels' windows sample the textures this pass produced. Secondary-window
		// frames are UI-only.
		if (frame.Valid && (frame.Window === host.MainRenderWindow))
		{
			// Through the ISceneRenderer interface; the bracket self-guards while the renderer
			// is not ready.
			if (mSceneRenderer != null)
				mSceneRenderer.BeginRendering(frame.Encoder, frame.FrameIndex);
			for (let entry in mPagePanels)
				entry.Page.OnRenderWindow(host, ref frame);
			if (mThumbnailStage != null)
				mThumbnailStage.Render(ref frame); // the offscreen thumbnail job, same bracket
			if (mSceneRenderer != null)
				mSceneRenderer.EndRendering();
			// The post-compose overlays: the Game tab's screen-tier UI onto its viewport.
			for (let entry in mPagePanels)
				entry.Page.OnAfterSceneRender(host, ref frame);
			if (mEmbeddedApp != null)
				mRuntimeContext.EndFrame();
		}
		if (mUiHost != null)
			mUiHost.RenderWindow(ref frame);
		// After the last draw into the main backbuffer; stays armed for a frame that has one.
		if (mScreenshot.Armed && frame.Valid && (frame.Window === host.MainRenderWindow)
			&& (host.Graphics != null) && (host.Graphics.Raw != null) && (frame.Encoder != null))
		{
			mScreenshot.Record(host.Graphics.Raw, frame.Encoder, frame.Backbuffer,
				frame.Window.Swap.Format, frame.Width, frame.Height);
		}
	}

	public void OnShutdown(IApplicationHost host)
	{
		FontAtlasBakerFactory.SetAtlasCache(null); // ours dies with this app
		mCookService.Shutdown(); // joins any in-flight cook before the databases go away
		// Page resources release while the device and windows are alive; pages destroy their
		// scenes in the runtime context, so it outlives them.
		for (let entry in mPagePanels)
			entry.Page.OnClose();
		SaveLayout();
		if (mEmbeddedApp != null)
		{
			mEmbeddedApp.OnShutdown(mEmbeddedHost);
			mRuntimeContext.Shutdown();
		}
		EditorIcons.Shutdown();
		if (cUseDistanceFieldFonts)
			DistanceFieldFonts.Shutdown();
		if ((host.Graphics != null) && (host.Graphics.Raw != null))
			mScreenshot.Release(host.Graphics.Raw);
	}

	/// The tab titles mirror the dirty state with a " *" suffix, polled per frame; the name
	/// comes from the live instance, since a browser rename would leave the tab stale.
	private void SyncPageTitles()
	{
		for (let entry in mPagePanels)
		{
			let title = scope String();
			let instance = (mProject != null) ? mProject.SourceDb.GetInstance(entry.Page.InstanceId) : null;
			title.Set((instance != null) ? instance.Name : entry.Page.Title);
			if (entry.Page.IsDirty)
				title.Append(" *");
			if (entry.Panel.Title != title)
				entry.Panel.SetTitle(title);
		}
	}

	/// Buffered engine logs reach the Console panel once per frame on the main thread.
	private void DrainLog()
	{
		if ((mConfig.LogBuffer == null) || (mShell.Console == null))
			return;
		ClearAndDeleteItems(mPendingLog);
		mLogSequence = mConfig.LogBuffer.CollectSince(mLogSequence, mPendingLog);
		for (let entry in mPendingLog)
			mShell.Console.AddEntry(entry.Level, entry.Category, entry.Message);
	}

	/// Bakes, or re-bakes on a DPI change, the editor icon set at chrome sizes scaled to device
	/// pixels. Old atlases stay owned by the UIHost until shutdown: re-bakes are rare, the
	/// atlases small, and in-flight frames may still sample the previous one.
	private void BakeEditorIcons(float contentScale)
	{
		let scale = (contentScale > 0.1f) ? contentScale : 1.0f;
		let sizes = scope List<uint32>();
		for (let baseSize in scope uint32[](10, 12, 14, 16, 20, 24, 32))
		{
			let scaled = (uint32)((float)baseSize * scale + 0.5f);
			if (sizes.IsEmpty || (sizes.Back != scaled))
				sizes.Add(scaled);
		}
		let bakeable = scope List<BakedSVGDrawable>();
		EditorIcons.Bakeable(bakeable);
		mUiHost.BakeSvgDrawables(bakeable, sizes);
		// The shared theme chrome glyphs bake at the same scale; they are framework-owned.
		mUiHost.BakeThemeIcons(scale);
		mIconBakeScale = scale;
	}

	/// Logs the resource manager's live-product report: counts by type, unreferenced being
	/// the cache-only purge candidates.
	private void ReportResourceMemory()
	{
		if (mResources == null)
		{
			GlobalLog(.Information, "Editor: resource report: no resource manager (no project open)");
			return;
		}
		let rows = scope List<LiveProductRow>();
		mResources.ReportLiveProducts(rows);
		int totalLive = 0;
		int totalUnreferenced = 0;
		for (let row in rows)
		{
			GlobalLog(.Information, "Editor: resource report: type {:X}: live {}, pending {}, failed {}, unreferenced {}",
				row.ProductTypeId, row.Live, row.Pending, row.Failed, row.Unreferenced);
			totalLive += row.Live;
			totalUnreferenced += row.Unreferenced;
		}
		GlobalLog(.Information, "Editor: resource report: {} live products total, {} unreferenced (cache-only, what a purge would release)",
			totalLive, totalUnreferenced);
	}
}
