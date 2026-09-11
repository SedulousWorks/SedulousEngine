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

	/// The docking host, which floats panels into real OS windows.
	private RuntimeDockableWindowHost mDockHost = null;

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
	}

	public void OnStartup(IApplicationHost host)
	{
		let mainWindow = host.MainRenderWindow;
		if (mainWindow == null)
			return;

		mWidth = mainWindow.Window.Width;
		mHeight = mainWindow.Window.Height;

		LoadFonts();

		// The shipped layout keeps the shaders beside the binary; a checkout keeps them under
		// the data directory, and the host has to be told which this is or the vector shaders
		// resolve to nothing and the window comes up blank.
		let shaderRoot = scope String("Shaders");
		SandboxContent.FindDirectory(SandboxContent.cShaderRoot, shaderRoot);
		mUIHost = new UIHost(host.Graphics, host.Shell, mFonts, shaderRoot);
		// The docking host needs both, and the docking tab needs IT, so it comes first.
		mDockHost = new RuntimeDockableWindowHost(host, mUIHost);

		BuildUI();

		// Adds the root to the context and wires this window's renderer and input.
		mUIHost.AttachWindow(mainWindow, mRoot);
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
	}

	public void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		if (mUIHost != null)
			mUIHost.RenderWindow(ref frame);
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
		mThemeButton.OnClick.Add(new [&](sender) =>
			{
				mThemeIndex = (mThemeIndex + 1) % 3;
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

	public void SetRepeatButton(RepeatButton button) => mRepeatButton = button;

	public int32 BumpRepeatCount() => ++mRepeatCount;

	private void ApplyTheme()
	{
		switch (mThemeIndex)
		{
		case 0: mSheet = DarkTheme.Create();
		case 1: mSheet = LightTheme.Create();
		default: mSheet = RoundedDarkTheme.Create();
		}

		// CONSUMES the sheet, and releases whichever one it was showing before.
		mUIHost.Context.SetStyleSheet(mSheet);

		if (mThemeButton == null)
			return;

		StringView[3] names = .("Dark", "Light", "Rounded Dark");
		mThemeButton.SetText(scope $"Theme: {names[mThemeIndex]}");
	}
}
