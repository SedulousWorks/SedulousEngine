using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Fonts;
using Sedulous.Fonts.Bidi;
using Sedulous.Fonts.DistanceField.Baker;
using Sedulous.Fonts.HarfBuzz;
using Sedulous.Fonts.TrueType;
using Sedulous.Graphics;
using Sedulous.GUI;
using Sedulous.GUI.VFS;
using Sedulous.I18N;
using Sedulous.Image;
using Sedulous.RHI;
using Sedulous.RHI.Capture;
using Sedulous.Runtime.Client;
using Sedulous.Shaders;
using Sedulous.Shell;
using Sedulous.VFS;
using Sedulous.VG;
using Sedulous.Xml;
using Sedulous.Xml.Serialization;
using Samples.Common;

namespace Samples.GUISandbox;

// The GUI's demo, built from the
// GUI itself. A shell (Data/Samples/UI/sandbox/shell.xml: a header, a sidebar of pages, the page on
// show) whose sidebar buttons run page.<id> commands; each page is pages/<id>.xml with an optional
// pages/<id>.css, so a new page is a button and its files. This host sizes the shell, wires what
// the pages do (SandboxPages.bf: their handlers, bindings and tweens), fills the few hosts that
// need native models or widgets (the data views, the menu bar, the context menu, the floating
// window, the message box, an image, the toolkit's sources, the dock space, the viewport's cube),
// and switches the theme. The game menu (Data/Samples/UI/showcase, its behaviour GameMenu.bf) is a
// second layer of the same root: it shares the data, and its Leave brings the player back here.
//
// It runs on the runtime host through GUI.Hosting's GuiHost, which takes the window's input, draws
// through VG with everything it has (analytic boxes, layers and blurs, the MSAA and stencil pass)
// on frames that need it, and bakes the SVG skins. The image tests and the bench draw offscreen
// instead (SandboxChecks.bf), as do the sweep, the soak and the mirror audit's checks.
//
// The file is split: this one builds and runs the sandbox; the native
// hosts and the dock space are SandboxHosts.bf, the Toolkit page SandboxToolkit.bf, the checks
// (--keys, --sweep, --soak, --mirror-audit, --image-tests, --bench) SandboxChecks.bf. With
// --editor-mock it shows the editor's mock (EditorMock.bf, over MockTypes.bf) instead.

/// The sandbox: one GUI, one root, on the runtime host.
class GUISandboxApp : IApplication
{
	public const String cRoboto = "Engine/Fonts/roboto/Roboto-Regular.ttf";
	public const String cLilita = "Samples/Fonts/lilita-one/LilitaOne-Regular.ttf";
	/// Arabic, which Roboto has not.
	public const String cDejaVu = "Samples/Fonts/dejavu/DejaVuSansMono.ttf";
	public const String cStrings = "Samples/UI/sandbox/i18n/sandbox.strings.xml";
	public const String cSandboxDir = "Samples/UI/sandbox/";
	public const String cMenuDir = "Samples/UI/showcase/";
	public const String cPageCommand = "page.";

	public const float cHeaderHeight = 60.0f;
	public const float cSidebarWidth = 210.0f;

	// === Options (Program sets them from the command line) ===

	private String mStartPage = new .("controls") ~ delete _;
	private String mStartLanguage = new .("en") ~ delete _;
	private bool mNarrate = false;
	private bool mOpenMenuAtStart = false;
	/// --light: the light colour scheme from the start.
	private bool mLightAtStart = false;
	/// --editor-mock: the editor's mock instead of the sandbox (EditorMock.bf).
	private bool mEditorMockMode = false;
	/// --mock-side-by-side: its two scene pages side by side.
	private bool mMockSideBySide = false;
	/// --mock-kit: the kit page in front.
	private bool mMockKit = false;
	/// --mock-page <id>: a page of the mock in front by its id.
	private String mMockPage = new .() ~ delete _;
	/// --mock-size <w>x<h>: its window; a full HD display's by default, the user's (2026-10-24).
	private uint32 mMockWidth = 1920;
	private uint32 mMockHeight = 1080;
	/// Keystrokes to type into the root, one every 15 frames.
	private String mKeys = new .() ~ delete _;
	/// F9: the debug overlay's layout half.
	private bool mLayoutOverlay = false;
	/// F8: its input half (focus path, tab order, navigation, pointer, redraws).
	private bool mInputOverlay = false;
	/// The page scrolled down this far once it is up (a screenshot further down).
	private float mScroll = 0.0f;
	private bool mAlwaysRedraw = false;
	private bool mFrameStats = false;
	private int32 mStressLoad = 1;
	private float mNextStressStatsTime = 0.0f;
	private bool mOpenInspector = false; // --inspector
	private String mInspectSelector = new .() ~ delete _; // --inspect <selector>: selected once the GUI is up
	private ScreenshotOptions mScreenshotOptions = new .() ~ delete _;

	// === On the runtime host ===

	private IApplicationHost mHost = null;
	private IShell mShell = null;
	private IWindow mWindow = null;
	private RenderWindow mMainWindow = null;
	private IDevice mDevice = null;
	/// The window's pixels.
	private uint32 mWidth = 960;
	private uint32 mHeight = 820;
	private float mDeltaTime = 0.0f;
	private float mTotalTime = 0.0f;
	/// Frames the loop ran.
	private uint64 mFrames = 0;
	private float mNextStatsTime = 1.0f;
	private String mDataRoot = new .() ~ delete _;
	// The data folder mounted (the VG shaders, the GUI's pictures): before what reads it.
	private NativeFileSystem mDataFileSystem = null ~ delete _;
	private VgShaderLibrary mShaders = null ~ delete _;
	/// The window's GUI: its context and styles, input, frames, the picture baker.
	private GuiHost mGuiHost = null ~ delete _;
	/// What the image tests and the bench draw into.
	private GuiOffscreen mOffscreen = null ~ delete _;
	private TrueTypeFontService mFontService = null ~ delete _;
	/// Roboto 16, for what native code builds. The font service's.
	private CachedFont mFont = null;

	// F12 and --screenshot: the window as presented, written once the GPU has run the frame.
	private ScreenshotCapture mScreenshot = new .() ~ delete _;
	private uint32 mScreenshotsTaken = 0;
	private uint32 mScreenshotSerial = 0;
	private uint64 mPresentedFrames = 0;
	private bool mScreenshotExitPending = false;

	// === The GUI: one context, one root ===

	/// The host's context (borrowed: the host holds it).
	private GUIContext mGui = null;
	/// The host's style manager: the theme, the sandbox's sheet, the pages' sheets.
	private StyleManager mStyles = null;
	/// The sandbox's root (a reference of ours).
	private SceneRoot mRoot = null;
	/// The game menu: a layer of the sandbox's one root (one root per window), hidden until it
	/// opens as a modal layer over the shell, back in its place when it closes. A reference.
	private Node mMenu = null;
	/// The GUI's pictures (an Image's src, a sheet's url()) and @imports, from the data folder.
	private VfsResourceProvider mResources = null ~ delete _;
	/// The inspector: a pane of its own root on the right, Ctrl+Shift+I.
	private Sedulous.GUI.Inspector.Inspector mInspector = null ~ delete _;
	private bool mInspectorOpen = false;
	/// Logical units; the boundary drags it.
	private float mInspectorWidth = 460.0f;
	/// The boundary is held.
	private bool mResizingInspector = false;
	/// The pointer is on the boundary (or holds it).
	private bool mOverInspectorEdge = false;
	private bool mShowingMenu = false;
	/// When the game menu's Leave has faded: back to the sandbox.
	private float mMenuLeaveAt = -1.0f;

	// The shell and its pages. The shell is a reference; the rest are the tree's.
	private Node mShellNode = null;
	private Node mHeader = null;
	private Node mBody = null;
	private Node mSidebar = null;
	private ScrollView mContent = null;
	private Sedulous.GUI.Button mThemeToggle = null;
	/// The toast host over the whole window (the Toolkit page posts to it). A reference.
	private ToastHost mToasts = null;

	/// A page of the sandbox: what the sidebar names.
	private class Page
	{
		public String Id = new .() ~ delete _;
		/// In the content scroller (the tree's).
		public Node Node = null;
		/// In the sidebar (the tree's).
		public Node NavButton = null;
		/// Its .css, which styles it alone.
		public String Sheet = new .() ~ delete _;
	}
	private List<Page> mPages = new .() ~ DeleteContainerAndItems!(_);
	private String mCurrent = new .() ~ delete _;
	private bool mLight = false;

	// The game menu's actions, which its prompts read (K7): a stand-in for a game's input map.
	private Sedulous.Input.ActionRuntime mMenuInput = new .() ~ delete _;
	private InputPrompts mMenuPrompts = new .() ~ delete _;

	// The texts the Language and direction page shows, the GUI's localization: the GUI is told to
	// let go of them before they go. The narrating bridge likewise.
	private StringTable mStrings = new .() ~ delete _;
	private Localization mLocalization = new .() ~ delete _;
	private NarrateBridge mNarrator = null ~ delete _;

	// The Stress page's builder and its views' models, and the Code page's languages and service:
	// deleted after the root, so the views and editors that point at them go first.
	private StressPage mStress = null ~ delete _;
	private CodePage mCode = null ~ delete _;
	/// The editor mock, likewise: its dock controller and inspectors' sources go after the root.
	private EditorMock mEditorMock = null ~ delete _;
	/// The game menu's behaviour, likewise: the handlers it gave the screens capture it.
	private GameMenu mGameMenu = null ~ delete _;
	/// What the pages and the game menu reach the GUI's data, commands and keys through, over the
	/// root (cleared before the root goes).
	private GuiFacade mGuiFacade = null ~ delete _;

	// === The Viewport page ===

	/// The tree's.
	private Viewport mViewport = null;
	private SpinningCube mCube = new .() ~ delete _;
	private FlyCamera mCamera = .();
	private ShaderCompiler mCubeCompiler = null ~ delete _;
	private float mSpin = 0.0f;

	// === Setters for the command line ===

	public void SetStartPage(StringView id) => mStartPage.Set(id);
	/// --stress <n>: start on the Stress page, built at load n.
	public void SetStress(int32 load)
	{
		mStartPage.Set("stress");
		mStressLoad = load;
	}
	public void SetOpenMenu(bool open) => mOpenMenuAtStart = open;
	public void SetLightAtStart(bool light) => mLightAtStart = light;
	public void SetEditorMock(bool on) => mEditorMockMode = on;
	public bool IsEditorMock => mEditorMockMode;
	public void SetMockSideBySide(bool on) => mMockSideBySide = on;
	public void SetMockKit(bool on) => mMockKit = on;
	/// --mock-page <id>: that page of the mock in front (the input map's designs: input-outline, input-split).
	public void SetMockPage(StringView id) => mMockPage.Set(id);
	/// --mock-size <w>x<h>: the mock's window at another size (a large monitor, a laptop).
	public void SetMockSize(uint32 width, uint32 height)
	{
		mMockWidth = width;
		mMockHeight = height;
	}
	public uint32 MockWidth => mMockWidth;
	public uint32 MockHeight => mMockHeight;
	public void SetKeys(StringView keys) => mKeys.Set(keys);
	public void SetAlwaysRedraw(bool always) => mAlwaysRedraw = always;
	public void SetFrameStats(bool stats) => mFrameStats = stats;
	public void SetScroll(float pixels) => mScroll = pixels;
	public void SetLayoutOverlay(bool on) => mLayoutOverlay = on;
	public void SetInputOverlay(bool on) => mInputOverlay = on;
	public void SetOpenInspector(bool on) => mOpenInspector = on;
	public void SetInspectSelector(StringView selector)
	{
		mOpenInspector = true;
		mInspectSelector.Set(selector);
	}
	/// --lang <locale>: the GUI's language at start ("pseudo": English pseudolocalized).
	public void SetStartLanguage(StringView locale) => mStartLanguage.Set(locale);
	/// --narrate: a stand-in screen reader on the console.
	public void SetNarrate(bool on) => mNarrate = on;
	/// The --screenshot flags (and F12): a picture of the window as presented. Takes ownership.
	public void SetScreenshots(ScreenshotOptions options)
	{
		delete mScreenshotOptions;
		mScreenshotOptions = options;
	}

	// === Building ===

	public void OnStartup(IApplicationHost host)
	{
		mHost = host;
		mShell = host.Shell;
		mMainWindow = host.MainRenderWindow;
		if ((mShell == null) || (mMainWindow == null) || (host.Graphics == null) || (host.Graphics.Raw == null))
		{
			Console.Error.WriteLine("GUISandbox: no window or device");
			host.RequestExit(1);
			return;
		}
		mWindow = mMainWindow.Window;
		mDevice = host.Graphics.Raw;
		mWidth = mWindow.Width;
		mHeight = mWindow.Height;
		// The data folder: fonts, pages, pictures, and the VG shaders (cooked, or compiled from Shaders/).
		FindDataRoot(mDataRoot);
		if (mDataRoot.IsEmpty)
		{
			Console.Error.WriteLine("GUISandbox: no data folder");
			host.RequestExit(1);
			return;
		}
		mDataFileSystem = new NativeFileSystem(mDataRoot);
		RegisterGuiElements(); // the GUI's widgets, creatable by tag from markup
		RegisterToolkitElements(); // and the toolkit's
		RegisterCodeElements(); // and the code editor
		RegisterGamekitElements(); // and the gamekit's (the game menu's screens and prompts)
		mShaders = new VgShaderLibrary();
		if (!mShaders.Load(mDevice, mDataFileSystem))
		{
			Console.Error.WriteLine("GUISandbox: the VG shaders did not load");
			host.RequestExit(1);
			return;
		}

		// Mixed-direction text reorders by the Unicode bidirectional algorithm. Shaped by HarfBuzz:
		// Arabic joins its letters. Installed before any font loads, so each one's atlas takes the
		// joined forms its shaping reaches.
		BidiAlgorithm.Install();
		HarfBuzzShaping.Install();
		mFontService = new TrueTypeFontService();
		LoadFonts();
		// The window's GUI: its input, its frames, its renderer and the picture baker. The sandbox
		// blends in linear light, as its references were drawn; the mock blends as the editor will:
		// the host's default, sRGB, as CSS does (the editor's hover tints are tuned for it).
		mGuiHost = new GuiHost(host.Graphics, mShell, mFontService, mShaders.Set);
		if (!mEditorMockMode)
			mGuiHost.BlendSpace = .Linear;
		mStyles = mGuiHost.Styles;
		// The windows the host opens for a root (the Docking page's floats in OS windows) are the
		// runtime host's.
		{
			let opener = new GuiHost.WindowOpener();
			opener.Open = new (settings) => host.OpenWindow(settings, RenderWindowDesc());
			opener.Close = new (window) => host.CloseWindow(window);
			mGuiHost.SetWindowOpener(opener);
		}

		mGui = mGuiHost.Context;
		// The data the pages and the game menu share.
		let data = mGui.Data;
		data.Set("volume", System.Variant.Create(0.7f));
		data.Set("music", System.Variant.Create(true));
		var name = TextVariant("Ada");
		data.Set("name", name);
		name.Dispose();
		data.Set("clicks", System.Variant.Create((int32)0));
		data.Set("cuts", System.Variant.Create((int32)0));
		var menu = TextVariant("pick an item");
		data.Set("menu", menu);
		menu.Dispose();
		var status = TextVariant("Loading...");
		data.Set("status", status);
		status.Dispose();
		data.Set("progress", System.Variant.Create(0.0f));
		data.Set("quit", System.Variant.Create(false));
		data.Set("files", System.Variant.Create((int32)3)); // the Language page's count
		LoadStrings();
		if (mNarrate)
		{
			mNarrator = new NarrateBridge();
			mGui.AccessibilityBridge = mNarrator;
		}

		BuildSandbox();
		BuildMenu();
		if (mOpenMenuAtStart)
			OpenMenu();

		// The Viewport page's cube, its pipeline built for the widget's formats.
		if (mViewport != null)
		{
			mCubeCompiler = new ShaderCompiler();
			if (mCubeCompiler.Initialize() case .Ok)
				mCube.Init(mDevice, mCubeCompiler, (int32)host.Graphics.FramesInFlight, mViewport.ColorFormat, mViewport.DepthFormat).IgnoreError();
		}

		// What the sandbox does to the host's input and drawing: the inspector picks and draws over
		// the page, its boundary takes the pointer, a desk test hears of the OS's drops.
		mGuiHost.SetPointerFilter(new (pane, surface) => FilterPointer(pane, surface));
		mGuiHost.SetOverlay(new (window, context) =>
			{
				if (!mInspectorOpen)
					return;
				mInspector.RecordFrame(mRoot.LastFrameStats);
				mInspector.DrawOverTarget(context);
				// The boundary, lit while the pointer is on it or drags it.
				if (mOverInspectorEdge)
					context.VG.FillRect(.((float)mWidth - InspectorPixels - 1.0f, 0.0f, 2.0f, (float)mHeight), .(0.31f, 0.61f, 1.0f, 1.0f));
			});
		mGuiHost.SetDropObserver(new (drop) =>
			{
				// Said, for a desk test of a desktop's drops.
				Console.WriteLine("GUISandbox: OS drop on window {} (this {}) at {:F0}, {:F0}: {}", drop.Window, mWindow.Id, drop.X, drop.Y, drop.Path);
			});
		// The image tests and the bench draw the root offscreen; otherwise it is the window's.
		if (DrawsOffscreen)
		{
			mOffscreen = new GuiOffscreen(mGuiHost, cImageWidth, cImageHeight, mMainWindow.Swap.Format, .Linear);
		}
		else
		{
			mGuiHost.AttachWindow(mMainWindow, mRoot);
			if (mInspectorOpen)
				mGuiHost.AddPane(mMainWindow, mInspector.Root, .(), mInspector.Styles);
			Layout();
		}
	}

	/// The Language and direction page's table: the serialized StringTable in the data folder,
	/// read through the XML serializer, given to the GUI as its localization in the start language.
	private void LoadStrings()
	{
		let text = ReadText(cStrings, .. scope String());
		let document = scope XmlDocument();
		if (text.IsEmpty || (document.Parse(text) != .Ok))
		{
			Console.Error.WriteLine("GUISandbox: the string table did not load");
			return;
		}
		let reader = scope XmlSerializer(document);
		mStrings.Serialize(reader);
		if (!reader.IsPayloadOk)
		{
			Console.Error.WriteLine("GUISandbox: the string table did not read");
			return;
		}
		mLocalization.AddTable(mStrings);
		mGui.Localization = mLocalization;
		SetLanguage(mStartLanguage);
	}

	/// The GUI's language: a locale, or "pseudo" (English pseudolocalized).
	private void SetLanguage(StringView locale)
	{
		let pseudo = locale == "pseudo";
		let options = scope PseudoOptions();
		options.Enabled = pseudo;
		// Rich-text tags and bindings stay as they are.
		options.Untouched.Add(new UntouchedSpan("[", "]"));
		options.Untouched.Add(new UntouchedSpan("{{", "}}"));
		mLocalization.SetPseudolocalization(options);
		mLocalization.SetLanguage(pseudo ? "en" : locale);
		mGui.Announce(mLocalization.Text("lang.changed"));
	}

	private void SetPageDirection(Node.LayoutDirection direction)
	{
		for (let page in mPages)
		{
			if (page.Id == "language")
				page.Node.SetLayoutDirection(direction);
		}
	}

	private void LoadFonts()
	{
		// Roboto in coverage atlases (a size baked on first use), Lilita as one distance-field bake
		// drawn crisp at any size, whose field text effects read (12 texels: effects reach 6 past
		// the edge at the bake size).
		var roboto = FontLoadOptions.ExtendedLatin();
		roboto.PixelHeight = 16.0f;
		roboto.LastCodepoint = 0x17F; // Latin Extended-A too: European languages, and pseudolocalized text
		mFontService.LoadFont("Roboto", DataFile(cRoboto, .. scope String()), roboto);
		mFont = mFontService.GetFont("Roboto", 16.0f);
		DistanceFieldFonts.Initialize();
		var lilita = FontLoadOptions.DistanceField();
		lilita.PixelHeight = 48.0f;
		lilita.DistanceFieldRange = 12.0f;
		if (mFontService.LoadFont("Lilita", DataFile(cLilita, .. scope String()), lilita) != .Success)
			Console.Error.WriteLine("GUISandbox: the Lilita face did not load");
		// DejaVu Sans Mono for Arabic: Latin, Greek, Cyrillic, Hebrew and Arabic, and the joined
		// forms HarfBuzz reaches from them.
		var dejavu = FontLoadOptions.ExtendedLatin();
		dejavu.PixelHeight = 16.0f;
		dejavu.LastCodepoint = 0x6FF;
		dejavu.AtlasWidth = 2048;
		dejavu.AtlasHeight = 2048;
		if (mFontService.LoadFont("DejaVu", DataFile(cDejaVu, .. scope String()), dejavu) != .Success)
			Console.Error.WriteLine("GUISandbox: the DejaVu face did not load");
	}

	/// A sheet's @font-face: the file under the data folder, into the font service under the
	/// face's name, in coverage atlases as Roboto's are.
	private bool LoadFontFace(StringView face, StringView source)
	{
		var options = FontLoadOptions.ExtendedLatin();
		options.PixelHeight = 16.0f;
		options.LastCodepoint = 0x17F;
		if (mFontService.LoadFont(face, DataFile(source, .. scope String()), options) == .Success)
			return true;
		Console.Error.WriteLine("GUISandbox: the @font-face {} ({}) did not load", face, source);
		return false;
	}

	/// A path under the data folder, appended to `outPath`.
	private void DataFile(StringView relative, String outPath)
	{
		DataPath(mDataRoot, relative, outPath);
	}

	/// The text of a file under the data folder, appended to `outText`; nothing when it does not read.
	private void ReadText(StringView relative, String outText)
	{
		let path = DataFile(relative, .. scope String());
		File.ReadAllText(path, outText, true).IgnoreError();
	}

	/// A tree from markup, its `{{name}}` values bound to the GUI's data; null when it does not
	/// load. The node comes with one reference, the caller's.
	private Node LoadMarkup(StringView text)
	{
		let loader = scope MarkupLoader(mGui.ElementSet, null, mFontService);
		loader.SetDataModel(mGui.Data);
		return loader.LoadFromString(text);
	}

	/// The first widget under `node` (itself included) whose id is `id`; null when none is.
	private static Node FindById(Node node, StringView id)
	{
		return (node != null) ? node.FindElement(id) : null;
	}

	/// Every node under `node` (itself included) whose bound command starts with `prefix`.
	private static void CollectCommands(Node node, StringView prefix, List<Node> outNodes)
	{
		let command = node.Command;
		if ((command.Length > prefix.Length) && command.StartsWith(prefix))
			outNodes.Add(node);
		for (int i = 0; i < node.ChildCount; i++)
			CollectCommands(node.GetChildAt(i), prefix, outNodes);
	}

	private void BuildSandbox()
	{
		mRoot = new SceneRoot(mGui);
		mRoot.DisplayScale = (mWindow != null) ? mWindow.ContentScale : 1.0f;
		mRoot.ViewportSize = .((float)mWidth, (float)mHeight);
		if (mEditorMockMode)
		{
			BuildEditorMock();
			return;
		}

		mShellNode = LoadMarkup(ReadText(scope $"{cSandboxDir}shell.xml", .. scope String()));
		if (mShellNode == null)
		{
			Console.Error.WriteLine("GUISandbox: the shell did not load");
			return;
		}
		mRoot.AddChild(mShellNode);
		mGuiFacade = new GuiFacade(mRoot);
		mToasts = new ToastHost();
		mShellNode.AddChild(mToasts);
		mHeader = FindById(mShellNode, "header");
		mBody = FindById(mShellNode, "body");
		mSidebar = FindById(mShellNode, "sidebar");
		mContent = FindById(mShellNode, "content") as ScrollView;
		mThemeToggle = FindById(mShellNode, "theme-toggle") as Sedulous.GUI.Button;

		LoadPages();
		WirePages(); // once every page is in the tree: a page may reach another's widgets
		FillNativeHosts();
		for (let page in mPages)
		{
			if (page.Id != "stress")
				continue;
			mStress = new StressPage(mFont);
			mStress.SetLoad(mStressLoad);
			mStress.Attach(page.Node);
		}

		// The shell's commands; the sidebar's buttons are bound to page.<id>, the header's to the theme.
		mRoot.OnCommand("theme.toggle", new (e) => { ToggleTheme(); });
		mRoot.OnCommand("demo.window", new (e) => { OpenWindow(); });
		mRoot.OnCommand("demo.message", new (e) => { ShowMessage(); });
		mRoot.OnCommand("showcase.open", new (e) => { OpenMenu(); });
		mRoot.OnCommand("debug.layout", new (e) =>
			{
				mLayoutOverlay = !mLayoutOverlay;
				ApplyDebugOverlay();
			});
		mRoot.OnCommand("debug.input", new (e) =>
			{
				mInputOverlay = !mInputOverlay;
				ApplyDebugOverlay();
			});
		mGui.Keymap.Bind("f9", "debug.layout");
		mGui.Keymap.Bind("f8", "debug.input");
		mRoot.OnCommand("inspector.toggle", new (e) => { ToggleInspector(); });
		// The Language and direction page's.
		mRoot.OnCommand("lang.en", new (e) => { SetLanguage("en"); });
		mRoot.OnCommand("lang.pseudo", new (e) => { SetLanguage("pseudo"); });
		mRoot.OnCommand("lang.ar", new (e) => { SetLanguage("ar"); });
		mRoot.OnCommand("dir.language", new (e) => { SetPageDirection(.Inherit); });
		mRoot.OnCommand("dir.ltr", new (e) => { SetPageDirection(.LeftToRight); });
		mRoot.OnCommand("dir.rtl", new (e) => { SetPageDirection(.RightToLeft); });
		mRoot.OnCommand("files.more", new (e) => { CountFiles(1); });
		mRoot.OnCommand("files.fewer", new (e) => { CountFiles(-1); });
		mGui.Keymap.Bind("ctrl-shift-i", "inspector.toggle");
		BindCodeEditorKeys(mGui.Keymap); // the Code page's editors: VS Code's keys
		mRoot.DebugFont = mFont;
		ApplyDebugOverlay();

		mStyles.FontService = mFontService;
		mStyles.SetFontFaceLoader(new (face, source) => LoadFontFace(face, source));
		mGui.FontService = mFontService; // a rich text's own faces
		mResources = new VfsResourceProvider(mDataFileSystem);
		mStyles.ResourceProvider = mResources;
		mGui.ResourceProvider = mResources;
		ApplySandboxSheet();
		if (mLightAtStart)
			ToggleTheme();
		ShowPage(mStartPage);

		if (mOpenInspector)
			ToggleInspector();
		mRoot.EventDispatcher.TooltipDelay = 0.4f; // tooltips are the GUI's own
	}

	/// The editor's mock in place of the sandbox: the GUI's theme and its satellites' sheets as the
	/// user agent's, the editor's sheet the mock sets over them, the inspector on Ctrl+Shift+I.
	private void BuildEditorMock()
	{
		mStyles.FontService = mFontService;
		mStyles.SetFontFaceLoader(new (face, source) => LoadFontFace(face, source));
		mGui.FontService = mFontService;
		mResources = new VfsResourceProvider(mDataFileSystem);
		mStyles.ResourceProvider = mResources;
		mGui.ResourceProvider = mResources;
		let theme = scope $"{Theme.DefaultThemeCSS}\n{DockingSheetCSS()}\n{ToolkitSheetCSS()}\n{CodeSheetCSS()}";
		let userAgent = scope StyleSheet();
		CSSParser.Parse(theme, "theme", userAgent);
		mStyles.UserAgentSheet = userAgent;
		let host = new EditorMock.Host();
		host.Load = new (path) =>
			{
				let text = ReadText(path, .. scope String());
				return LoadMarkup(text);
			};
		host.Read = new (path, outText) => ReadText(path, outText);
		mEditorMock = new EditorMock(mGui, mRoot, mStyles, host);
		if (!mEditorMock.Build())
			Console.Error.WriteLine("GUISandbox: the editor mock did not load");
		if (mLightAtStart)
			mEditorMock.SetDark(false);
		if (mMockSideBySide)
			mEditorMock.SetSideBySide(true);
		if (mMockKit)
			mEditorMock.ShowKit();
		if (!mMockPage.IsEmpty)
			mEditorMock.ShowPage(mMockPage);
		mRoot.OnCommand("inspector.toggle", new (e) => { ToggleInspector(); });
		mGui.Keymap.Bind("ctrl-shift-i", "inspector.toggle");
		mRoot.DebugFont = mFont;
		if (mOpenInspector)
			ToggleInspector();
		mRoot.EventDispatcher.TooltipDelay = 0.4f;
	}

	/// The Language page's count of files, moved by `by` (never below none).
	private void CountFiles(int32 by)
	{
		let data = mGui.Data;
		double files = 0.0;
		NumberOf(data.Peek("files"), out files);
		data.Set("files", System.Variant.Create(Math.Max((int32)0, (int32)files + by)));
	}

	private void LoadPages()
	{
		// The pages are what the sidebar names: each button bound to page.<id>.
		let buttons = scope List<Node>();
		if (mSidebar != null)
			CollectCommands(mSidebar, cPageCommand, buttons);
		for (let button in buttons)
		{
			let page = new Page();
			page.Id.Set(button.Command.Substring(cPageCommand.Length));
			page.NavButton = button;
			let xml = scope $"{cSandboxDir}pages/{page.Id}.xml";
			let node = LoadMarkup(ReadText(xml, .. scope String()));
			if (node == null)
			{
				Console.Error.WriteLine("GUISandbox: page {} did not load", xml);
				delete page;
				continue;
			}
			node.Displayed = false; // out of the layout until shown
			mContent.AddChild(node);
			node.ReleaseRef(); // the scroller's keeps it
			page.Node = node;
			ReadText(scope $"{cSandboxDir}pages/{page.Id}.css", page.Sheet);
			if (page.Id == "stress")
				StressPage.Rules(1000, page.Sheet); // a large sheet's many rules
			let command = scope $"{cPageCommand}{page.Id}";
			mRoot.OnCommand(command, new (e) => { ShowPage(page.Id); });
			mPages.Add(page);
		}
	}

	private void ApplySandboxSheet()
	{
		// The built-in theme for the widgets (the user agent's), the sandbox's look over it, and each
		// page's own sheet over that, styling its page alone.
		let theme = scope $"{Theme.DefaultThemeCSS}\n{DockingSheetCSS()}\n{ToolkitSheetCSS()}\n{CodeSheetCSS()}"; // the satellites' over the widgets'
		let userAgent = scope StyleSheet();
		CSSParser.Parse(theme, "theme", userAgent);
		mStyles.UserAgentSheet = userAgent;
		let path = scope $"{cSandboxDir}sandbox.css";
		let sandbox = scope StyleSheet();
		CSSParser.Parse(ReadText(path, .. scope String()), path, sandbox);
		mStyles.StyleSheet = sandbox;
		for (let page in mPages)
		{
			if (page.Node == null)
				continue;
			let sheet = scope StyleSheet();
			CSSParser.Parse(page.Sheet, scope $"pages/{page.Id}.css", sheet);
			mStyles.SetSubtreeSheet(page.Node, sheet);
		}
	}

	/// The layout overlay (F9) and the input overlay (F8) on the root.
	private void ApplyDebugOverlay()
	{
		var overlay = mLayoutOverlay ? DebugOverlay.Layout : DebugOverlay();
		if (mInputOverlay)
		{
			let input = DebugOverlay.Input;
			overlay.FocusPath = input.FocusPath;
			overlay.TabOrder = input.TabOrder;
			overlay.Navigation = input.Navigation;
			overlay.Pointer = input.Pointer;
			overlay.RedrawFlash = input.RedrawFlash;
		}
		if (mRoot != null)
			mRoot.DebugOverlay = overlay;
	}

	private void BuildMenu()
	{
		let path = scope $"{cMenuDir}menu.xml";
		let menu = LoadMarkup(ReadText(path, .. scope String()));
		if (menu == null)
		{
			Console.Error.WriteLine("GUISandbox: the game menu did not load");
			return;
		}
		// Over the shell, last of the root's children; not shown until it opens. Its sheet styles it
		// alone, as a page's does.
		menu.Displayed = false;
		mRoot.AddChild(menu);
		mMenu = menu; // our reference, besides the tree's
		let css = scope $"{cMenuDir}menu.css";
		let sheet = scope StyleSheet();
		CSSParser.Parse(ReadText(css, .. scope String()), css, sheet);
		mStyles.SetSubtreeSheet(menu, sheet);
		// Leave: the menu fades out, then the sandbox comes back.
		let model = mGui.Data;
		menu.Bind(new () =>
			{
				var quit = ConvertVariant(model.Get("quit"), typeof(bool));
				defer quit.Dispose();
				if (quit.HasValue && quit.Get<bool>() && (mMenuLeaveAt < 0.0f))
					mMenuLeaveAt = mTotalTime + 0.7f;
			});
		// Its actions, as a game's input map would give them: its prompts show their controls for the
		// device in hand.
		let actions = scope Sedulous.Input.InputMap();
		let game = new Sedulous.Input.ActionSet();
		game.Name.Set("Game");
		let pause = new Sedulous.Input.InputAction();
		pause.Name.Set("pause");
		Sedulous.Input.Binding escape = .();
		escape.Source = .Key;
		escape.Code = (uint32)Sedulous.Shell.KeyCode.Escape;
		pause.Bindings.Add(escape);
		Sedulous.Input.Binding start = .();
		start.Source = .GamepadButton;
		start.Code = (uint32)Sedulous.Shell.GamepadButton.Start;
		pause.Bindings.Add(start);
		game.Actions.Add(pause); // the set owns it
		actions.Sets.Add(game); // the map owns it
		mMenuInput.SetMap(actions);
		mMenuPrompts.SetRuntime(mMenuInput);
		mMenuPrompts.Install(mGui);
		if (mGuiFacade != null)
		{
			mGameMenu = new GameMenu(mGuiFacade, menu);
			mGameMenu.Start();
		}
	}

	// === Running ===

	private void ShowPage(StringView id)
	{
		for (let page in mPages)
		{
			let shown = page.Id == id;
			page.Node.Displayed = shown;
			if (let button = page.NavButton as UIWidget)
			{
				if (shown)
					button.AddClass("current");
				else
					button.RemoveClass("current");
			}
		}
		mCurrent.Set(id);
		if ((mStress != null) && (id == "stress") && !mStress.IsBuilt)
			mStress.Build(mStressLoad); // built when first shown: the other pages start fast
		if (mContent != null)
			mContent.ScrollOffset = .(0.0f, 0.0f);
	}

	private void ToggleTheme()
	{
		mLight = !mLight;
		if (let shellWidget = mShellNode as UIWidget)
		{
			if (mLight)
				shellWidget.AddClass("light");
			else
				shellWidget.RemoveClass("light");
		}
		if (mThemeToggle != null)
			mThemeToggle.Text = mLight ? "Dark theme" : "Light theme";
		// The theme's light tokens come from its own media query: the GUI says the user's scheme.
		mGui.DarkScheme = !mLight;
	}

	/// The Menus page's floating window: a reference of ours, in the tree while it is open.
	private Sedulous.GUI.Window mFloating = null;
	/// The Menus page's message box: a reference of ours.
	private MessageBox mDialog = null;

	private void OpenWindow()
	{
		if (mFloating == null)
		{
			// A window to drag by its title and resize from its corner, holding tabs.
			mFloating = new Sedulous.GUI.Window();
			mFloating.Size = .(340.0f, 280.0f);
			mFloating.Title = "A floating window";
			mFloating.Font = mFont;
			let tabs = new TabView();
			tabs.Font = mFont;
			tabs.EditLayoutStyle(scope (s) => { s.Grow = 1.0f; });
			mFloating.Content.AddChild(tabs);
			tabs.ReleaseRef(); // the window's keeps it
			StringView[3] names = .("First", "Second", "Third");
			StringView[3] bodies = .("Tabs switch the page below them.", "Drag the title bar to move the window.",
				"Drag the bottom-right corner to resize it.");
			for (int i < 3)
			{
				let page = tabs.AddPage(names[i]);
				let body = new Sedulous.GUI.Label();
				body.Padding = .(12.0f);
				body.Font = mFont;
				body.WhiteSpace = .Normal;
				body.Text = bodies[i];
				body.AddClass("text");
				page.AddChild(body);
				body.ReleaseRef(); // the page's keeps it
			}
		}
		// The button toggles it, opening it in the middle each time; closed (its close button, or
		// this), it opens there again.
		if (mFloating.Parent != null)
			mFloating.Close();
		else
			mFloating.Open(mRoot);
	}

	private void ShowMessage()
	{
		if (mDialog == null)
		{
			mDialog = new MessageBox();
			mDialog.Font = mFont;
		}
		mDialog.Configure("A message box", "A modal dialog: the page behind it takes no clicks until it is answered.", .Ok);
		mDialog.OpenModal(mRoot);
	}

	private void OpenMenu()
	{
		if ((mMenu == null) || mShowingMenu)
			return;
		mShowingMenu = true;
		mMenuLeaveAt = -1.0f;
		mGui.Data.Set("quit", System.Variant.Create(false));
		// A modal layer over the shell: drawn over it, the shell inert below it, the focus inside it
		// and given back on close; Escape is its own (a manual layer: nothing closes it but it).
		mMenu.Displayed = true;
		let options = new PopupOptions();
		options.Kind = .Manual;
		options.Modal = true;
		options.TakesFocus = true;
		options.ReturnHome = true; // back in its place when it closes, to open again
		mRoot.EventDispatcher.OpenPopup(mRoot, mMenu, options);
		if (mGameMenu != null)
			mGameMenu.Enter(); // the title alone, nothing left from the last visit
	}

	private void CloseMenu()
	{
		if (!mShowingMenu)
			return;
		mShowingMenu = false;
		mMenuLeaveAt = -1.0f;
		mGui.Data.Set("quit", System.Variant.Create(false));
		mRoot.EventDispatcher.ClosePopup(mMenu);
		mMenu.Displayed = false;
		if (let back = FindById(mShellNode, "nav-game-menu"))
			back.FocusElement(); // where the player left from
	}

	private void LayOutShell()
	{
		// The shell fills the window: the header across the top, the sidebar down the left, the
		// page's scroller the rest; the game menu's layers fill it too.
		let size = mRoot.Size;
		if (mShellNode != null)
			mShellNode.Size = size;
		if (mHeader != null)
			mHeader.Size = .(size.X, cHeaderHeight);
		Float2 body = .(size.X, Math.Max(0.0f, size.Y - cHeaderHeight));
		if (mBody != null)
			mBody.Size = body;
		if (mSidebar != null)
			mSidebar.Size = .(cSidebarWidth, body.Y);
		if (mContent != null)
			mContent.Size = .(Math.Max(0.0f, body.X - cSidebarWidth), body.Y);
		if (mMenu != null)
		{
			mMenu.Position = .(0.0f, 0.0f);
			mMenu.Size = size;
			for (int i = 0; i < mMenu.ChildCount; i++)
				mMenu.GetChildAt(i).Size = size;
		}
	}

	/// The inspector's pane width in device pixels (0 while it is closed).
	private float InspectorPixels => mInspectorOpen ? mInspectorWidth * ((mWindow != null) ? mWindow.ContentScale : 1.0f) : 0.0f;

	/// The panes' regions in the window: the root on show, and the inspector's pane at its right.
	private void Layout()
	{
		if ((mGuiHost == null) || (mGuiHost.WindowFor(mRoot) == null))
			return;
		let pane = InspectorPixels;
		mGuiHost.SetPaneRegion(mRoot, .(0.0f, 0.0f, (float)mWidth - pane, (float)mHeight));
		if (mInspectorOpen)
			mGuiHost.SetPaneRegion(mInspector.Root, .((float)mWidth - pane, 0.0f, pane, (float)mHeight));
		mGuiHost.SizePanes(); // the roots at this frame's size: the shell is laid out from it
	}

	/// Before the host routes the frame's input: the boundary between the root on show and the pane.
	private void RouteInput()
	{
		if ((mShell == null) || (mShell.Input == null))
			return;
		ResizeInspector(mShell.Input);
		Layout();
	}

	/// The boundary between the root on show and the pane: on it the cursor shows the resize
	/// arrows, pressed it drags the pane's width (neither root sees the pointer meanwhile). True
	/// while it has the pointer.
	private bool ResizeInspector(IInputManager input)
	{
		if (!mInspectorOpen || (input.Mouse == null))
		{
			mResizingInspector = mOverInspectorEdge = false;
			return false;
		}
		let mouse = input.Mouse; // the window's, in its pixels
		let scale = (mWindow != null) ? mWindow.ContentScale : 1.0f;
		let edge = (float)mWidth - InspectorPixels;
		let near = (Math.Abs(mouse.X - edge) <= 4.0f * scale) && (mouse.Y >= 0.0f) && (mouse.Y < (float)mHeight);
		if (!mResizingInspector && near && mouse.IsButtonPressed(.Left))
			mResizingInspector = true;
		if (mResizingInspector)
		{
			if (!mouse.IsButtonDown(.Left))
				mResizingInspector = false;
			else
			{
				// The pane's width follows the pointer, leaving the root on show some room.
				let widest = Math.Max(260.0f, (float)mWidth / scale - 240.0f);
				mInspectorWidth = Math.Clamp(((float)mWidth - mouse.X) / scale, 260.0f, widest);
			}
		}
		let over = mResizingInspector || near;
		if (over != mOverInspectorEdge)
		{
			mOverInspectorEdge = over;
			mRoot.Invalidate(); // the boundary's highlight
			if (!over)
				mGuiHost.ResetCursors(); // the GUI's cursors take the pointer back
		}
		if (over)
			mouse.SetCursor(.ResizeEW);
		return mResizingInspector;
	}

	/// The pointer as the host would give a pane: true when the sandbox takes it first (the
	/// inspector picking, the boundary held, a --keys script driving the pointer).
	private bool FilterPointer(SceneRoot pane, InputSurface surface)
	{
		// While the boundary has the pointer, neither root sees it.
		if (mResizingInspector)
			return true;
		if (pane != mRoot)
			return false;
		if (mInspectorOpen && mInspector.Picking)
		{
			// Picking: the pointer over the root on show goes to the inspector, not to it.
			let mouse = surface.Mouse;
			if (surface.MouseActive)
			{
				mInspector.PickHover(.(mouse.X, mouse.Y));
				if (mouse.ScrollY != 0.0f)
					mInspector.PickWheel(mouse.ScrollY);
				if (mouse.IsButtonPressed(.Left))
					mInspector.PickClick();
			}
			return true;
		}
		return !mKeys.IsEmpty; // a --keys script owns the pointer: the desk's mouse would move it back
	}

	private void ToggleInspector()
	{
		if (mInspector == null)
			mInspector = new Sedulous.GUI.Inspector.Inspector(mGui, mFontService);
		mInspectorOpen = !mInspectorOpen;
		if (mInspectorOpen)
			mInspector.Inspect(mRoot, mStyles);
		else
			mInspector.Picking = false;
		// A pane of the window at the right (once the window has the root: at start, OnStartup adds it).
		if ((mGuiHost != null) && (mGuiHost.WindowFor(mRoot) != null))
		{
			if (mInspectorOpen)
				mGuiHost.AddPane(mMainWindow, mInspector.Root, .(), mInspector.Styles);
			else
				mGuiHost.RemovePane(mInspector.Root);
			Layout();
		}
		mRoot.Invalidate();
	}

	private void UpdateMenu()
	{
		if (mGameMenu != null)
			mGameMenu.Update(mDeltaTime);
		if ((mMenuLeaveAt >= 0.0f) && (mTotalTime >= mMenuLeaveAt))
			CloseMenu();
	}

	public void OnUpdate(IApplicationHost host, float deltaTime)
	{
		if (mGuiHost == null)
			return;
		mDeltaTime = deltaTime;
		mTotalTime += deltaTime;
		FinishScreenshot(); // last frame's, now the GPU has run it
		mWidth = mWindow.Width;
		mHeight = mWindow.Height;
		if (!mBenchPage.IsEmpty)
		{
			RunBench();
			return;
		}
		if (mImageTests)
		{
			RunImageTests();
			return;
		}
		if (mMirrorAudit && (mFrames >= 10) && !mMirrorAuditDone)
		{
			MirrorAudit();
			return;
		}
		let input = mShell.Input;
		if ((input != null) && (input.Keyboard != null) && input.Keyboard.IsKeyPressed(Sedulous.Shell.KeyCode.F12))
			RequestScreenshot();
		RouteInput();
		TypeKeys(mRoot);
		// --scroll: once the GUI is up (held a few frames while the page settles).
		if ((mScroll > 0.0f) && (mFrames >= 10) && (mFrames <= 20) && (mEditorMock != null))
			mEditorMock.ScrollKit(mScroll);
		else if ((mScroll > 0.0f) && (mFrames >= 10) && (mFrames <= 20) && (mContent != null))
			mContent.ScrollOffset = .(0.0f, mScroll);
		if (mSweep)
		{
			Sweep();
			if (mSoakSeconds > 0.0f)
				SoakFrame();
		}
		LayOutShell();
		if (mShowingMenu)
			UpdateMenu();
		if (mInspectorOpen)
		{
			if (mInspector.Target != mRoot)
				mInspector.Inspect(mRoot, mStyles);
			if (!mInspectSelector.IsEmpty && (mFrames == 10))
				mInspector.SelectQuery(mInspectSelector);
			mInspector.Refresh();
		}
		// The host: each pane's input, the GUI's clock, styles and layout; whether a frame is needed.
		mGuiHost.Update(deltaTime);
		// The Viewport page's camera reads the widget's gated input while it is hovered or focused.
		if ((mViewport != null) && mViewport.IsTreeVisible)
		{
			mSpin += deltaTime;
			if (mViewport.IsActive)
				mCamera.Update(mViewport.Keyboard, mViewport.Mouse, deltaTime);
		}

		mFrames++;
		if (mFrameStats && (mTotalTime >= mNextStatsTime))
		{
			Console.WriteLine("GUISandbox: drew {} of {} frames", mGuiHost.FramesDrawn, mFrames);
			// The last drawn frame's costs and what asked for it.
			Console.WriteLine("GUISandbox: last frame: {}", mRoot.LastFrameStats.Describe(.. scope String()));
			mNextStatsTime = mTotalTime + 1.0f;
		}
		// The Stress page shows the last frame's costs, each second.
		if ((mStress != null) && (mCurrent == "stress") && (mTotalTime >= mNextStressStatsTime))
		{
			mStress.ShowStats(mRoot.LastFrameStats);
			mNextStressStatsTime = mTotalTime + 1.0f;
		}
		if (mAlwaysRedraw)
			mRoot.Invalidate();
	}

	public void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		if ((mGuiHost == null) || !frame.Valid)
			return;
		mGuiHost.RenderWindow(ref frame);
		if ((frame.Window != mMainWindow) || (frame.Encoder == null))
			return;
		// F12 or --screenshot: this frame, as presented.
		mPresentedFrames++;
		if (mScreenshotOptions.Requested && (mScreenshotsTaken < mScreenshotOptions.Count) &&
			((mScreenshotsTaken > 0) || mScreenshotOptions.Due(mPresentedFrames, mTotalTime)))
		{
			mScreenshot.Request(mScreenshotOptions.PathFor(mScreenshotsTaken, .. scope String()));
			mScreenshotsTaken++;
			mScreenshotExitPending = mScreenshotOptions.ExitAfter && (mScreenshotsTaken == mScreenshotOptions.Count);
		}
		if (mScreenshot.Armed &&
			!mScreenshot.Record(mDevice, frame.Encoder, frame.Backbuffer, mMainWindow.Swap.Format, frame.Width, frame.Height) &&
			mScreenshotExitPending)
		{
			Console.Error.WriteLine("GUISandbox: the screenshot could not be taken (this surface cannot be copied)");
			Exit();
		}
	}

	private void Exit()
	{
		if (mHost != null)
			mHost.RequestExit(0);
	}

	/// The Viewport page's camera, framing the cube.
	private void ResetCamera()
	{
		mCamera.Position = .(0.0f, 0.0f, 4.5f);
		mCamera.Yaw = 0.0f;
		mCamera.Pitch = 0.0f;
		mCamera.MoveSpeed = 4.0f;
		mCamera.FastSpeed = 12.0f;
	}

	/// F12: the next frame, to <user data>/screenshots.
	private void RequestScreenshot()
	{
		let directory = GetUserDataDirectory(.. scope String());
		directory.Append("/screenshots");
		if (!CreateDirectory(directory))
		{
			Console.Error.WriteLine("GUISandbox: could not create the screenshots directory");
			return;
		}
		mScreenshotSerial++;
		mScreenshot.Request(scope $"{directory}/gui-sandbox-{DateTime.Now.Ticks}-{mScreenshotSerial}.png");
	}

	/// A screenshot recorded last frame: once the GPU has run it (a one-off, so wait for all),
	/// map, write, and honour --screenshot-exit.
	private void FinishScreenshot()
	{
		if (!mScreenshot.Recorded)
			return;
		mDevice.WaitIdle();
		let written = scope Sedulous.Image.Image();
		if (mScreenshot.Complete(mDevice, written) case .Ok)
			Console.WriteLine("GUISandbox: screenshot written to {}", mScreenshot.Path);
		if (mScreenshotExitPending)
			Exit();
	}

	public void OnShutdown(IApplicationHost host)
	{
		StopListeningForProblems(); // a sweep cut short gives the application its logger back
		if (mGuiHost == null)
		{
			// A start cut short: what it made goes while the device is here (the app outlives it).
			DeleteAndNullify!(mFontService);
			DeleteAndNullify!(mShaders);
			return;
		}
		Console.WriteLine("GUISandbox: drew {} of {} frames", mGuiHost.FramesDrawn, mFrames);
		mDevice.WaitIdle();
		InputPrompts.Uninstall(mGui); // the GUI may outlive the menu's actions
		mScreenshot.Release(mDevice); // its readback buffer
		mCube.Shutdown();
		DeleteAndNullify!(mCubeCompiler);
		DeleteAndNullify!(mOffscreen);
		// The Docking page's float windows close first (their roots on the GUI's context).
		SetDockWindows(false);
		// The window's panes leave the host (their renderer forgets the bakes) before the trees go.
		if (mGuiHost.WindowFor(mRoot) != null)
			mGuiHost.DetachWindow(mMainWindow);
		DeleteAndNullify!(mInspector); // its root on the GUI's context, before the context
		ReleaseNativeHosts(); // the context menu, the dock space and its controller (SandboxHosts.bf)
		if (mFloating != null)
		{
			mFloating.ReleaseRef();
			mFloating = null;
		}
		if (mDialog != null)
		{
			mDialog.ReleaseRef();
			mDialog = null;
		}
		if (mToasts != null)
		{
			mToasts.ReleaseRef();
			mToasts = null;
		}
		if (mMenu != null)
		{
			mMenu.ReleaseRef();
			mMenu = null;
		}
		if (mShellNode != null)
		{
			mShellNode.ReleaseRef();
			mShellNode = null;
		}
		mViewport = null; // its targets go with the tree, while the host and the device are here
		if (mEditorMock != null)
			mEditorMock.ReleaseTree(); // its frame and dock space, the tree's
		if (mGuiFacade != null)
			mGuiFacade.RootNode = null; // a call from here on finds no GUI
		// The widgets go with the tree, before the models and sources they read.
		mRoot.ReleaseRef();
		mRoot = null;
		ReleaseModels(); // the data views' models (SandboxHosts.bf)
		ReleaseToolkit(); // the Toolkit page's sources (SandboxToolkit.bf)
		DeleteAndNullify!(mStress);
		DeleteAndNullify!(mCode);
		DeleteAndNullify!(mEditorMock); // its dock controller, then its sources, then what they show
		DeleteAndNullify!(mGameMenu); // before the facade it borrows
		DeleteAndNullify!(mGuiFacade);
		// The GUI lets go of what it borrows from us before the host takes it away.
		mGui.Localization = null;
		mGui.AccessibilityBridge = null;
		mGui.FontService = null;
		mGui.ResourceProvider = null;
		mGui = null;
		mStyles = null;
		DeleteAndNullify!(mGuiHost); // the context, the baker
		DeleteAndNullify!(mResources);
		DeleteAndNullify!(mFontService);
		DeleteAndNullify!(mShaders); // the shader modules are its, the host drew with them
	}
}
