using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Fonts.TrueType;
using Sedulous.Graphics;
using Sedulous.Image;
using Sedulous.Runtime.Client;
using Sedulous.UI;
using Sedulous.UI.Application;
using Sedulous.UI.Runtime;
using Sedulous.UI.Toolkit;
using Sedulous.UI.VFS;
using Sedulous.UI.Viewport;
using Sedulous.Graphics;
using Sedulous.RHI;
using Sedulous.Shaders;
using Sedulous.Shell;
using Samples.Common;
using Sedulous.VFS;

namespace Samples.UISandbox;

/// The on-screen exercise of the whole UI stack.
///
/// It builds one tabbed window over the real host: the UI core's controls, layouts, text input,
/// data views, overlays, drag and drop and animation, then the toolkit's bars, property grid,
/// curve editor and node graph, then a viewport and a docking demo that put panels into actual
/// OS windows. What it proves is INTEGRATION, which no headless test can: the styling, the
/// layout, the input routing and the renderer all have to agree at once.
class UISandboxApp : IApplication
{
	private uint32 mWidth = 820;
	private uint32 mHeight = 720;

	private TrueTypeFontService mFonts = null;

	// The UI.
	private RootView mRoot = null;
	private ToastHost mToastHost = null;
	private StyleSheet mSheet = null;
	private FlexLayout mMain = null;
	/// OWNED, and borrowed by the image and drawable demos.
	private OwnedImageData mTestImage = null;
	/// BORROWED: ticked every frame for hold to repeat.
	private RepeatButton mRepeatButton = null;
	private int32 mRepeatCount = 0;

	private int32 mThemeIndex = 0;
	/// BORROWED. Shows the current theme's name and cycles on click.
	private Button mThemeButton = null;

	/// The theme extension must OUTLIVE every theme build, because the registry holds it by
	/// reference, so it lives on the application rather than in the builder that registers it.
	private ToolkitThemeExtension mToolkitTheme = new .() ~ delete _;

	// The item view data sources. The views BORROW them, so the application keeps them alive.
	private DemoListAdapter mListAdapter = new .(1000) ~ delete _;
	private DemoTreeAdapter mTreeAdapter = new .() ~ delete _;
	private DemoGridAdapter mGridAdapter = new .(200) ~ delete _;

	/// The draggable tree BORROWS it, so it lives on the application.
	private ReorderableListAdapter mReorderAdapter =
		new .("Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot") ~ delete _;

	/// The docking host, which floats panels into real OS windows.
	private RuntimeDockableWindowHost mDockHost = null;

	// The VFS the markup and the .sss themes are read through, rooted at the UI asset
	// directory. Built on first use and kept for the application's life.
	/// OWNED: this sample has no application to resolve the data root for it.
	private NativeFileSystem mDataMount = null ~ delete _;
	private NativeFileSystem mUIFileSystem = null;
	private VfsResourceProvider mResourceProvider = null;

	// The viewport and what draws into it. The view owns its offscreen targets and its gated
	// input surface; the application owns the router, the camera and the cube.
	/// BORROWED: the panel tree owns it.
	private ViewportView mViewport = null;
	/// The window currently hosting the viewport, which changes when its panel is floated.
	private RenderWindow mViewportWindow = null;
	private RenderWindow mMainWindow = null;
	private InputRouter mViewportRouter = null;
	private ShaderCompiler mCubeCompiler = null;
	private SpinningCube mCube = new .() ~ delete _;
	private FlyCamera mCamera = .();
	private float mTime = 0.0f;

	/// The UI on runtime bridge, which owns the context and the per window renderer and input.
	private UIHost mUIHost = null;

	public ~this()
	{
		// The root and the style sheet are NOT released here: AttachWindow and SetStyleSheet
		// both consume the reference they were handed, and the host and the context release
		// them with themselves.
		if (mDockHost != null)
			delete mDockHost;

		if (mUIHost != null)
			delete mUIHost;

		if (mTestImage != null)
			delete mTestImage;

		if (mFonts != null)
			delete mFonts;

		if (mResourceProvider != null)
			delete mResourceProvider;

		if (mUIFileSystem != null)
			delete mUIFileSystem;
	}

	/// BORROWED, and null when this checkout carries no UI assets. Built on first use.
	public VfsResourceProvider ResourceProvider
	{
		get
		{
			if (mResourceProvider != null)
				return mResourceProvider;

			let root = scope String();
			if (!SandboxContent.FindDirectory(SandboxContent.cUiAssetDir, root))
				return null;

			mUIFileSystem = new NativeFileSystem(root);
			mResourceProvider = new VfsResourceProvider(mUIFileSystem);
			return mResourceProvider;
		}
	}

	public void OnStartup(IApplicationHost host)
	{
		let mainWindow = host.MainRenderWindow;
		if (mainWindow == null)
			return;

		mWidth = mainWindow.Window.Width;
		mHeight = mainWindow.Window.Height;

		LoadFonts();

		// This sample is not an application, so it finds the data root itself and mounts it;
		// the UI host reads the vector shaders through the mount like everything else.
		let dataRoot = scope String();
		FindDataRoot(dataRoot);
		mDataMount = new NativeFileSystem(dataRoot);
		mUIHost = new UIHost(host.Graphics, host.Shell, mFonts, mDataMount);
		// The docking host needs both, and the docking tab needs IT, so it comes first.
		mDockHost = new RuntimeDockableWindowHost(host, mUIHost);

		BuildUI();

		// Adds the root to the context and wires this window's renderer and input.
		mUIHost.AttachWindow(mainWindow, mRoot);

		mMainWindow = mainWindow;
		// AFTER the attach: the window's renderer does not exist until then.
		WireViewport(host);
	}

	public void SetViewport(ViewportView viewport) => mViewport = viewport;

	/// Brings the 3D content up: the viewport's target registered with the window's renderer,
	/// the cube built against the viewport's OWN formats, and an input router carrying the
	/// view's gated surface.
	private void WireViewport(IApplicationHost host)
	{
		if ((mViewport == null) || (mMainWindow == null))
			return;

		let device = host.Graphics.Raw;
		mViewport.Initialize(device, mUIHost.RendererFor(mMainWindow), host.Shell.Input,
			mMainWindow.Window.Id);
		mViewportWindow = mMainWindow;

		mCubeCompiler = new ShaderCompiler();
		if (mCubeCompiler.Initialize() case .Ok)
		{
			mCube.Init(device, mCubeCompiler, (int32)host.Graphics.FramesInFlight,
				mViewport.ColorFormat, mViewport.DepthFormat).IgnoreError();
		}

		// Framing the cube, and slower than the default so it stays usable in a small panel.
		mCamera.Position = .(0.0f, 0.0f, 4.5f);
		mCamera.Yaw = 0.0f;
		mCamera.Pitch = 0.0f;
		mCamera.MoveSpeed = 4.0f;
		mCamera.FastSpeed = 12.0f;

		mViewport.OnRender = new (view, encoder, frameIndex) =>
			{
				let width = view.RenderWidth;
				let height = view.RenderHeight;
				if ((width == 0) || (height == 0))
					return;

				let aspect = (float)width / (float)height;
				let projection = Float4x4.PerspectiveFovRH(1.0f, aspect, 0.1f, 100.0f);
				let view4 = Float4x4.LookAtRH(mCamera.Position,
					mCamera.Position + mCamera.Forward, mCamera.Up);
				let model = Float4x4.RotationY(mTime) * Float4x4.RotationX(mTime * 0.5f);
				// ROW VECTOR order: the vector goes through model, then view, then projection.
				let mvp = model * view4 * projection;

				mCube.Render(encoder, view.ColorTargetView, view.DepthTargetView, width, height,
					view.ClearColor, mvp, frameIndex);
			};

		// The host's own router is private, so the surface gets one of ours.
		mViewportRouter = new InputRouter(host.Shell.Input);
		if (mViewport.Surface != null)
			mViewportRouter.AddSurface(mViewport.Surface);
	}

	/// Re-binds the viewport when its panel moves to another window, so its UI samples the
	/// right renderer's target and its input routes to the right window.
	private void UpdateViewportHostWindow()
	{
		if ((mViewport == null) || (mUIHost == null) || (mViewport.Root() == null))
			return;

		let host = mUIHost.WindowForRoot(mViewport.Root());
		if ((host == null) || (host == mViewportWindow))
			return;

		// Only once the new window's renderer exists, which is after its own attach ran.
		if (let renderer = mUIHost.RendererFor(host))
		{
			mViewport.AttachToWindow(renderer, host.Window.Id);
			mViewportWindow = host;
		}
	}

	public void OnUpdate(IApplicationHost host, float deltaTime)
	{
		// Hold to repeat is driven from here rather than from input, because a held button has
		// to keep firing while nothing at all is happening.
		if (mRepeatButton != null)
			mRepeatButton.UpdateRepeat(deltaTime);

		if (mUIHost != null)
			mUIHost.Update(deltaTime);

		if (mToastHost != null)
			mToastHost.Update(deltaTime);

		// Drag follow: a floating dock window tracks the desktop cursor.
		if (mDockHost != null)
			mDockHost.Tick();

		mTime += deltaTime;
		if ((mViewport == null) || (mViewportRouter == null))
			return;

		UpdateViewportHostWindow();
		// AFTER the UI laid out this frame, so the surface tracks where the view actually is.
		mViewport.SyncInputRegion();
		mViewportRouter.Update();

		// The camera reads the gated devices only while the UI says the viewport is genuinely
		// hovered or focused, so an occluded or inactive tab cannot leak input into it and a
		// look-drag off the view keeps going while it holds focus.
		if (mViewport.IsHovered() || mViewport.IsFocused())
			mCamera.Update(mViewport.Keyboard, mViewport.Mouse, deltaTime);
	}

	public void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		// The 3D content goes into its offscreen target BEFORE the UI draws, because the UI
		// samples that target as an image. Only on whichever window is hosting it.
		if ((mViewport != null) && mViewport.IsReady && frame.Valid &&
			(frame.Window == mViewportWindow))
			mViewport.RenderContent(frame.Encoder, (int32)frame.FrameIndex);

		if (mUIHost != null)
			mUIHost.RenderWindow(ref frame);
	}

	public void OnShutdown(IApplicationHost host)
	{
		// The viewport's targets and its external texture registration go while the device and
		// the per window renderer are still alive: the view outlives the window inside the tree.
		if (mViewport != null)
			mViewport.Shutdown();

		mCube.Shutdown();

		if (mViewportRouter != null)
		{
			delete mViewportRouter;
			mViewportRouter = null;
		}

		if (mCubeCompiler != null)
		{
			delete mCubeCompiler;
			mCubeCompiler = null;
		}
	}

	// ---- fonts ------------------------------------------------------------------------------

	private void LoadFonts()
	{
		// CPU rasterisation, so no device is needed and this can run before the host has one.
		mFonts = new TrueTypeFontService();

		let path = scope String();
		if (!SandboxContent.FindFile(SandboxContent.cFontFile, path))
		{
			Console.Error.WriteLine("UISandbox: no font data in this checkout; text will not draw");
			return;
		}

		for (let size in float[](14.0f, 16.0f, 24.0f))
			LoadFontSize("Roboto", path, size);

		// The decorative families the pause menu demonstrates. A missing family falls back to
		// Roboto, so the demo still renders when a checkout does not carry them.
		let monster = scope String();
		let jungle = scope String();
		let hasMonster = SandboxContent.FindFile(SandboxContent.cMonsterFontFile, monster);
		let hasJungle = SandboxContent.FindFile(SandboxContent.cJungleFontFile, jungle);

		for (let size in float[](14.0f, 18.0f, 24.0f, 32.0f))
		{
			if (hasMonster)
				LoadFontSize("AttackOfMonster", monster, size);

			if (hasJungle)
				LoadFontSize("JungleAdventurer", jungle, size);
		}
	}

	private void LoadFontSize(StringView family, StringView path, float pixelHeight)
	{
		var options = FontLoadOptions.ExtendedLatin();
		options.PixelHeight = pixelHeight;
		mFonts.LoadFont(family, path, options);
	}

	// ---- the tree ---------------------------------------------------------------------------

	private void BuildUI()
	{
		// The toolkit's styling has to be registered BEFORE the first theme is built: an
		// extension only reaches themes created after it.
		ThemeRegistry.RegisterExtension(mToolkitTheme);
		ApplyTheme();

		mRoot = new RootView();
		mRoot.ViewportSize = .((float)mWidth, (float)mHeight);
		mRoot.DpiScale = 1.0f;

		mTestImage = SandboxViews.MakeCheckerboard();

		mMain = SandboxViews.VFlex();
		mRoot.AddView(mMain);

		// The notification overlay spans the whole window and is input transparent outside its
		// own cards.
		mToastHost = new ToastHost();
		mRoot.AddView(mToastHost);

		mThemeButton = new Button("Theme: Dark");
		mThemeButton.OnClick.Add(new (sender) =>
			{
				mThemeIndex = (mThemeIndex + 1) % 5;
				ApplyTheme();
			});
		mMain.AddView(mThemeButton,
			SandboxViews.Sized(SizeSpec.Wrap(), SizeSpec.Fixed(Unit.Px(34))));

		let tabView = new TabView();
		tabView.TabsClosable.Value = false;
		mMain.AddView(tabView, SandboxViews.Grow(1));

		ControlsTab.Build(this, tabView);
		ScrollViewTab.Build(tabView);
		LayoutsTab.Build(tabView);
		TabPlacementTab.Build(tabView);
		TextInputTab.Build(tabView);
		DataControlsTab.Build(this, tabView);
		OverlaysTab.Build(this, tabView);
		DragDropTab.Build(tabView);
		AnimationsTab.Build(this, tabView);
		ToolkitTab.Build(this, tabView);
		PropertyGridTab.Build(tabView);
		CurveEditorTab.Build(tabView);
		NodeGraphTab.Build(tabView);
		ViewportTab.Build(this, tabView);
		DockingTab.Build(this, tabView);
		PauseMenuTab.Build(this, tabView);
	}

	/// BORROWED, for the tab builders.
	public OwnedImageData TestImage => mTestImage;

	/// BORROWED.
	public ToastHost Toasts => mToastHost;

	/// BORROWED.
	public RuntimeDockableWindowHost DockHost => mDockHost;

	/// BORROWED.
	public UIHost Host => mUIHost;

	/// BORROWED, all three.
	public DemoListAdapter ListAdapter => mListAdapter;
	public DemoTreeAdapter TreeAdapter => mTreeAdapter;
	public DemoGridAdapter GridAdapter => mGridAdapter;
	public ReorderableListAdapter ReorderAdapter => mReorderAdapter;

	public void SetRepeatButton(RepeatButton button) => mRepeatButton = button;

	public int32 BumpRepeatCount() => ++mRepeatCount;

	private void ApplyTheme()
	{
		switch (mThemeIndex)
		{
		case 0: mSheet = DarkTheme.Create();
		case 1: mSheet = LightTheme.Create();
		case 2: mSheet = RoundedDarkTheme.Create();
		case 3: mSheet = SandboxThemes.CreateTextured();
		default: mSheet = SandboxThemes.LoadSheet(ResourceProvider, "themes/breeze.sss",
			ThemePalette.Dark());
		}

		// CONSUMES the sheet, and releases whichever one it was showing before.
		mUIHost.Context.SetStyleSheet(mSheet);

		if (mThemeButton == null)
			return;

		StringView[5] names = .("Dark", "Light", "Rounded Dark", "Textured", "Breeze (.sss)");
		mThemeButton.SetText(scope $"Theme: {names[mThemeIndex]}");
	}
}
