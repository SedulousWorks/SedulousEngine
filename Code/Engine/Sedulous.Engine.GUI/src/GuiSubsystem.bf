using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Engine.Input;
using Sedulous.Engine.Render;
using Sedulous.Engine.Scene;
using Sedulous.Fonts;
using Sedulous.Fonts.Bidi;
using Sedulous.Fonts.HarfBuzz;
using Sedulous.Fonts.Resource;
using Sedulous.Fonts.TrueType;
using Sedulous.GUI;
using Sedulous.GUI.Resources;
using Sedulous.Input;
using Sedulous.Profiler;
using Sedulous.Render;
using Sedulous.Resource;
using Sedulous.Runtime;
using Sedulous.Scene;
using Sedulous.VFS;

namespace Sedulous.Engine.GUI;

/// The engine's GUI on Sedulous.GUI, Engine.UI's counterpart while both live.
///
/// One GUIContext and style manager for the application, the GUI's built-in theme under the
/// game's sheets (a list, in order, each an @import of its guid), and the fonts; a screen tier (a
/// root holding the gamekit's screen stack and an overlay layer above it, outside any scene, so it
/// survives a scene swap) and a scene tier (a root per scene, drawn wherever the scene renders);
/// both drawn into the engine's overlay passes through GUI.Hosting's GuiPassRenderer, above
/// Engine.UI's (GuiOverlayDraw.bf). A sheet or document whose cooked product changes restyles the
/// GUI (hot reload). The GUI ticks on unscaled time (menus move while the game is paused), so its
/// work is in BeginFrame.
///
/// The game's screen: the screen tier lays out at the game's render resolution and draws, at the
/// target's own, into the rectangle that size is fitted into, turned when the game's orientation is
/// not the target's, as the game's image is. With run screens on (the editor), each run (a Game
/// tab's game) has a screen tier of its own, drawn for its tab (SetRenderRun); the overlay layer
/// stays on the shared tier above it.
///
/// The components live (GuiComponentSync.bf, GuiRenderTextures.bf): a canvas's document in its
/// scene's root or a texture of its own, a billboard over its entity, a world panel on its
/// entity's sprite, each in line with its component every frame.
///
/// Still to come: input through GUI.Shell's bridge (E4) and the script surface (E5); each has its
/// hook where Raptor's runs it.
class GuiSubsystem : Subsystem, ISceneObserver
{
	/// After Engine.UI's (-650), so a game's GUI sees the same frame; all work in BeginFrame.
	public override int32 UpdateOrder => -640;

	/// BORROWED from the application: the VG shaders and the built-in font come from it.
	private IFileSystem mDataFileSystem = null;
	/// Declared first, so it goes last: every root holds a reference to it.
	private GUIContext mContext = new .() ~ _.ReleaseRef();
	private StyleManager mStyles = new .() ~ delete _;
	private GuiResourceProvider mResources = new .() ~ delete _;
	/// The built-in font; the project's, when it names a default. Borrowed by the context, the
	/// style manager and the renderer.
	private TrueTypeFontService mFonts ~ delete _;
	private ResourceFontService mProjectFonts ~ delete _;
	/// BORROWED: the resource manager's cache keeps the products alive.
	private Font mDefaultFont = null;
	private List<Font> mOtherFonts = new .() ~ delete _;
	private List<Guid> mSheets = new .() ~ delete _;
	private uint64 mSheetGeneration = 0;
	/// The shared tier.
	private GuiScreenTier mScreen = new .() ~ delete _;
	/// A tier per run, with run screens on.
	private List<GuiScreenTier> mRunTiers = new .() ~ DeleteContainerAndItems!(_);
	private bool mRunScreens = false;
	/// The run whose tier the next screen overlay draws under the shared one's; a key only.
	private Object mRenderRun = null;
	/// The shared tier's overlay layer. A HELD reference.
	private UIWidget mOverlay = null;
	// E5: the script binding (what each script context is given) goes here.
	private List<GuiSceneTier> mSceneTiers = new .() ~ DeleteContainerAndItems!(_);
	/// The roots of their own a render-texture canvas and a world panel draw in, OWNED.
	private List<GuiTextureRoot> mTextureRoots = new .() ~ DeleteContainerAndItems!(_);
	/// Counts BeginFrames; RenderTextures runs once a frame by it.
	private uint64 mFrameSerial = 0;
	/// The frame RenderTextures last ran in.
	private uint64 mTexturesSerial = uint64.MaxValue;
	private GuiRenderState mRenderState = null;
	/// BORROWED peers; null in a headless context.
	private RenderSubsystem mRender = null;
	private InputSubsystem mInput = null;
	// E4: the input kind tracker, the text input target, the active and press roots and what the
	// GUI took of the pointer go here.

	/// The data mount is BORROWED for the subsystem's life: the VG shaders and the built-in font
	/// come from it.
	public this(IFileSystem dataFileSystem)
	{
		mDataFileSystem = dataFileSystem;
		mContext.ResourceProvider = mResources;
		mStyles.ResourceProvider = mResources; // the sheets' @import, url() and fonts
	}

	public ~this()
	{
		// Shut down already when a context drove it; else what OnInit made goes here. No early
		// return: the fields' own cleanups would be skipped.
		DropTiers();
		delete mRenderState;
		mRenderState = null;
	}

	/// The GUI: its data, keymap, commands and resources. Named apart from the subsystem's
	/// runtime Context, which it would otherwise shadow (Raptor's Context()). The subsystem's.
	public GUIContext GuiContext => mContext;
	/// The GUI with a reference added for the caller, which releases it.
	public GUIContext ContextRef()
	{
		mContext.AddRef();
		return mContext;
	}
	/// The style manager every root is styled through: the built-in theme, the game's sheets.
	public StyleManager Styles => mStyles;
	public GuiResourceProvider Resources => mResources;
	/// The fonts the GUI's text draws with: the project's, else the built-in font.
	public IFontService Fonts => (mProjectFonts != null) ? (IFontService)mProjectFonts : mFonts;

	/// The project's fonts, which it shares with Engine.UI (defaultUiFontId, uiFontIds): the
	/// default and the others, each a family a label picks by `font-family`. Without a default the
	/// built-in font serves (the others wait for one). The products are BORROWED: the resource
	/// manager's cache keeps them alive.
	public void SetFonts(Font defaultFont, Span<Font> others)
	{
		mDefaultFont = defaultFont;
		mOtherFonts.Clear();
		for (let font in others)
		{
			if (font != null)
				mOtherFonts.Add(font);
		}
		let was = mProjectFonts;
		mProjectFonts = null;
		if (mDefaultFont != null)
		{
			mProjectFonts = new ResourceFontService();
			mProjectFonts.AddFont(mDefaultFont);
			mProjectFonts.SetDefaultFamily(mDefaultFont.Family);
			for (let font in mOtherFonts)
				mProjectFonts.AddFont(font);
		}
		else if (!mOtherFonts.IsEmpty)
			GlobalLog(.Warning, "GUI: {} GUI font(s) wait for a default font", mOtherFonts.Count);
		// Everything that measures or draws text from now on asks the new service; every root
		// measures again.
		let fonts = Fonts;
		mContext.FontService = fonts;
		mStyles.FontService = fonts;
		ApplyUserAgentSheet(); // the default family is the new service's
		if ((mRenderState != null) && (mRenderState.Renderer != null))
			mRenderState.Renderer.SetFontService(fonts);
		// The old service goes once nothing asks it any more.
		delete was;
		if (mScreen.Root != null)
			mScreen.Root.RequestLayoutTree();
		for (let tier in mRunTiers)
			tier.Root.RequestLayoutTree();
		for (let tier in mSceneTiers)
			tier.Root.RequestLayoutTree();
		for (let root in mTextureRoots)
			root.Root.RequestLayoutTree();
	}

	/// Where asset guids resolve (the application's resource manager); null resolves nothing.
	/// Borrowed.
	public void SetResourceManager(ResourceManager resources)
	{
		mResources.SetResourceManager(resources);
		ApplySheets(); // the sheets resolve in the new project (or not at all)
	}

	/// The game's sheets, over the built-in theme, each over the ones before it (a game's own over
	/// a shared one). Re-read when one's cooked product changes. Nil guids are left out.
	public void SetStyleSheets(Span<Guid> sheets)
	{
		mSheets.Clear();
		for (let sheet in sheets)
		{
			if (!sheet.IsNil)
				mSheets.Add(sheet);
		}
		ApplySheets();
	}

	public Span<Guid> StyleSheets => .(mSheets.Ptr, mSheets.Count);
	/// How many times the game's sheets were applied (set, or a cooked product changed).
	public uint64 SheetGeneration => mSheetGeneration;

	/// The screen tier, outside any scene: its root, the gamekit's screen stack in it, and the
	/// overlay layer above the stack (a loading screen, a system menu). The subsystem's.
	public SceneRoot ScreenRoot => mScreen.Root;
	public ScreenStack Screens => mScreen.Screens;

	// ==================== the game's screen ====================

	/// The screen tier at the game's render resolution, fitted into its target by `fit`, its text
	/// crisp at the target's resolution; nought on either axis: the target's own size.
	public void SetScreenResolution(uint32 width, uint32 height, FitMode fit) => ApplyResolution(mScreen, width, height, fit);
	public bool HasScreenResolution => mScreen.HasResolution;
	/// The game's orientation: on a target of the other shape the screen tier lays out at the
	/// game's shape and draws turned a quarter. Any: never turned.
	public void SetScreenOrientation(ScreenOrientation orientation) => mScreen.Orientation = orientation;

	/// Where a tier at `resolution` (none: 0 x 0), fitted by `fit` and held to `orientation`,
	/// draws on a `target`-sized target.
	public static GuiScreenPlacement PlaceScreen(Float2 resolution, FitMode fit, ScreenOrientation orientation, Float2 target)
	{
		var place = GuiScreenPlacement();
		if ((target.X <= 0.0f) || (target.Y <= 0.0f))
			return place;
		let turn = ContentFit.TurnFor(orientation, target.X, target.Y);
		let hasResolution = (resolution.X > 0.0f) && (resolution.Y > 0.0f);
		if (!hasResolution && (turn == .None))
			return place; // the plain draw
		let swaps = (turn == .Quarter) || (turn == .ThreeQuarter);
		// The game's frame: its resolution, else the target's own pixels at the game's shape.
		let content = hasResolution ? resolution : (swaps ? Float2(target.Y, target.X) : target);
		let placed = ContentFit(.(0, 0, target.X, target.Y), content, hasResolution ? fit : .Stretch, turn);
		place.Fitted = true;
		place.Turn = turn;
		place.Rect = placed.DstRect();
		place.DrawSize = swaps ? Float2(place.Rect.Height, place.Rect.Width) : Float2(place.Rect.Width, place.Rect.Height);
		let scale = placed.Scale().Y; // layout units per target pixel, down the game's height
		place.DpiScale = (scale > 0.0f) ? (1.0f / scale) : 1.0f;
		if (turn != .None)
		{
			// The root's pixels onto the rectangle's, turned as the game's image is: the image of
			// the origin and of each axis through the same fit, as a row-vector affine.
			let turned = ContentFit(.(0, 0, place.Rect.Width, place.Rect.Height), place.DrawSize, .Stretch, turn);
			let origin = turned.FromContent(.(0, 0));
			let xAxis = turned.FromContent(.(1, 0));
			let yAxis = turned.FromContent(.(0, 1));
			place.Transform = Float4x4(
				xAxis.X - origin.X, xAxis.Y - origin.Y, 0, 0,
				yAxis.X - origin.X, yAxis.Y - origin.Y, 0, 0,
				0, 0, 1, 0,
				origin.X, origin.Y, 0, 1);
		}
		return place;
	}

	private static void ApplyResolution(GuiScreenTier tier, uint32 width, uint32 height, FitMode fit)
	{
		tier.Resolution = ((width > 0) && (height > 0)) ? Float2((float)width, (float)height) : .Zero;
		tier.Fit = fit;
	}

	/// A render-space point in the tier's root pixels: the part of the resolution a crop leaves out
	/// offsets it, and the root's scale takes it to its pixels, as PlaceScreen fitted it on the last
	/// draw. E4's input maps the pointer through it.
	private static Float2 ScreenPointerPoint(GuiScreenTier tier, Float2 point)
	{
		if (!tier.HasResolution)
			return point; // the target's own pixels (a turned game's pointer arrives in its frame)
		let fit = ContentFit(.(0, 0, tier.TargetSize.X, tier.TargetSize.Y), tier.Resolution, tier.Fit, tier.Turn);
		let source = fit.SrcRect();
		let scale = fit.Scale().Y;
		let dpi = (scale > 0.0f) ? (1.0f / scale) : 1.0f;
		return .((point.X - source.X) * dpi, (point.Y - source.Y) * dpi);
	}

	// ==================== a screen tier per run (the editor's Game tabs) ====================

	/// On: each run its own screen tier (the editor sets it once). Off (the player's): one.
	public bool RunScreens
	{
		get => mRunScreens;
		set => mRunScreens = value;
	}

	/// `run`'s screen stack and root, made on first use; the shared tier's with run screens off
	/// or no run. The subsystem's.
	public ScreenStack ScreensFor(Object run)
	{
		let tier = TierOfRoot(ScreenRootFor(run));
		return (tier != null) ? tier.Screens : null;
	}

	public SceneRoot ScreenRootFor(Object run)
	{
		if (!mRunScreens || (run == null) || (mScreen.Root == null))
			return mScreen.Root;
		if (let found = FindRunTier(run))
			return found.Root;
		let tier = new GuiScreenTier();
		tier.Run = run;
		MakeScreenTier(tier);
		mRunTiers.Add(tier);
		return tier.Root;
	}

	/// `run`'s tier sized, made on first use so a tab can size it before anything is pushed.
	public void SetScreenResolution(Object run, uint32 width, uint32 height, FitMode fit)
	{
		if (let tier = TierOfRoot(ScreenRootFor(run)))
			ApplyResolution(tier, width, height, fit);
	}

	public void SetScreenOrientation(Object run, ScreenOrientation orientation)
	{
		if (let tier = TierOfRoot(ScreenRootFor(run)))
			tier.Orientation = orientation;
	}

	/// The run whose screen tier the next screen overlay draws under the shared one's overlays
	/// (null: none), set by a host around its overlays for that run's view.
	public void SetRenderRun(Object run) => mRenderRun = run;

	/// The run ended: its screen tier and every screen on it go.
	public void EndRunScreens(Object run)
	{
		for (int i < mRunTiers.Count)
		{
			if (mRunTiers[i].Run !== run)
				continue;
			// E4: the active and press roots forgotten when they are this tier's.
			let tier = mRunTiers[i];
			mRunTiers.RemoveAt(i);
			tier.Screens.Clear();
			delete tier;
			break;
		}
		if (mRenderRun === run)
			mRenderRun = null;
	}

	public int RunScreenCount => mRunTiers.Count;

	/// The overlay layer above every screen. The subsystem's.
	public UIWidget OverlayLayer => mOverlay;

	/// `document` built and shown on the overlay layer, above every screen (a loading screen, a
	/// system menu), modal while it shows unless it takes no pointer (`pointer-events: none` on its
	/// root: a watermark). The tree, to take off again, with a reference the CALLER releases; null
	/// when it does not build.
	public Node PushOverlay(GuiDocument document)
	{
		let tree = BuildDocument(document);
		if (tree != null)
			PushOverlay(tree);
		return tree;
	}

	/// A tree made in code shown on the overlay layer, which takes a reference of its own.
	public void PushOverlay(Node overlay)
	{
		if ((mOverlay != null) && (overlay != null) && (overlay.Parent == null))
			mOverlay.AddChild(overlay);
	}

	public void RemoveOverlay(Node overlay)
	{
		if ((mOverlay != null) && (overlay != null) && (overlay.Parent === mOverlay))
			mOverlay.RemoveChild(overlay);
	}

	public int OverlayCount => (mOverlay != null) ? mOverlay.ChildCount : 0;

	/// The scene tier's root for `scene`; null when the scene is unknown. The subsystem's.
	public SceneRoot SceneRootFor(Scene scene)
	{
		let tier = FindSceneTier(scene);
		return (tier != null) ? tier.Root : null;
	}

	// ==================== lifecycle ====================

	protected override void OnInit()
	{
		RegisterGuiElements(); // the GUI's widgets, by tag from markup
		RegisterGamekitElements(); // and a game's screens and prompts
		// Before any font loads: a font gets its shaper and its atlas's glyphs when it loads.
		HarfBuzzShaping.Install();
		BidiAlgorithm.Install();
		mFonts = new TrueTypeFontService();
		// The built-in font through the data mount (in a dev tree and any dist that stages it); the
		// project's own fonts come with the player's settings.
		if (!LoadBuiltInFont())
			GlobalLog(.Information, "GUI: built-in font '{}' not in the data root: GUI text needs the project's fonts", cBuiltInFont);
		mContext.FontService = mFonts;
		mStyles.FontService = mFonts;
		ApplyUserAgentSheet();
		ApplySheets();

		// The shared screen tier: the screen stack, and the overlay layer above it, each filling the
		// root. Neither paints, so neither takes the pointer from the game until something in it does.
		MakeScreenTier(mScreen);
		mOverlay = new UIWidget();
		mOverlay.Tag = "overlays";
		using (Node.StyleWriteScope(mOverlay))
		{
			mOverlay.EditLayoutStyle(scope (s) => { s.Kind = .Stack; });
		}
		mScreen.Root.AddChild(mOverlay);
		// E5: a script's root is its run's screen tier (the shared one in the player): the script
		// binding's resolve is set here, ScreenRootFor(the script's current run).
	}

	protected override void OnReady()
	{
		if (Context == null)
			return;
		mInput = Context.GetSubsystem<InputSubsystem>();
		if (let scenes = Context.GetSubsystem<SceneSubsystem>())
		{
			scenes.RegisterObserver(this, .SystemsReady);
			scenes.RegisterObserver(this, .Destroying);
		}
		// Headless contexts (tests, the cooker) have no render subsystem: nothing registers.
		mRender = Context.GetSubsystem<RenderSubsystem>();
		if (mRender != null)
		{
			mRender.RegisterOverlay((ISceneOverlay)this);
			mRender.RegisterOverlay((IScreenOverlay)this);
		}
	}

	protected override void OnShutdown()
	{
		if (mRender != null)
		{
			mRender.UnregisterOverlay((ISceneOverlay)this);
			mRender.UnregisterOverlay((IScreenOverlay)this);
			mRender = null;
		}
		if (Context != null)
		{
			if (let scenes = Context.GetSubsystem<SceneSubsystem>())
				scenes.UnregisterObserver(this);
		}
		// E4: the active and press roots forgotten.
		mInput = null;
		DropTiers();
		mResources.SetTextureSink(null);
		mContext.PictureBaker = null;
		delete mRenderState; // waits for the GPU, then lets the renderers go
		mRenderState = null;
	}

	/// Every tier gone, the screens taken off theirs first: the scenes', the runs', the shared
	/// one's with its overlay layer. Idempotent.
	private void DropTiers()
	{
		ClearAndDeleteItems!(mTextureRoots);
		ClearAndDeleteItems!(mSceneTiers);
		for (let tier in mRunTiers)
			tier.Screens.Clear();
		ClearAndDeleteItems!(mRunTiers);
		mRenderRun = null;
		if (mScreen.Screens != null)
			mScreen.Screens.Clear();
		if (mOverlay != null)
		{
			mOverlay.ReleaseRef();
			mOverlay = null;
		}
		// E5: the script binding's resolve cleared, so a script still running finds no root.
		if (mScreen.Screens != null)
		{
			mScreen.Screens.ReleaseRef();
			mScreen.Screens = null;
		}
		if (mScreen.Root != null)
		{
			mScreen.Root.ReleaseRef();
			mScreen.Root = null;
		}
	}

	/// The frame's opening lane, on UNSCALED time: menus move while the game is paused.
	public override void BeginFrame(float deltaTime)
	{
		using (ProfileScope("GUI.BeginFrame"))
		{
			mFrameSerial++;
			if ((mRenderState != null) && (mRenderState.Renderer != null))
				mRenderState.Renderer.BeginFrame();
			if (mResources.Poll())
				ApplySheets(); // a sheet (or a document) was cooked again: the GUI restyles
			SyncComponents(); // each scene's billboards, canvases and world panels in line
			// E4: PumpInput() here, before the clock, as Raptor's.
			// By ticks: TimeSpan.FromSeconds would round to whole milliseconds.
			mContext.Update(TimeSpan((int64)((double)deltaTime * (double)TimeSpan.TicksPerSecond)));
			if (mScreen.Root != null)
				StyleAndLayOut(mScreen.Root, mScreen.Root.ViewportSize);
			for (let tier in mRunTiers)
				StyleAndLayOut(tier.Root, tier.Root.ViewportSize);
		}
	}

	/// The action layer's pointer and keyboard claims cleared after the frame read them: the next
	/// frame's BeginFrame lane republishes them (Engine.UI's, then the GUI's added by E4's pump).
	public override void EndFrame()
	{
		if (mInput == null)
			return;
		mInput.ForEachActionRuntime(scope (runtime) => { runtime.SetConsumptionMask(ConsumptionMask()); });
	}

	// ==================== the scene tier ====================

	public void OnSystemsReady(Scene scene)
	{
		if (FindSceneTier(scene) != null)
			return;
		let tier = new GuiSceneTier();
		tier.Scene = scene;
		tier.Root = new SceneRoot(mContext);
		using (Node.StyleWriteScope(tier.Root))
		{
			tier.Root.EditLayoutStyle(scope (s) => { s.Kind = .Stack; }); // each canvas fills it
		}
		// The billboards' layer, under every canvas; it paints nothing, so it takes no pointer.
		tier.Billboards = new UIWidget();
		tier.Billboards.Tag = "billboards";
		tier.Root.AddChild(tier.Billboards);
		// E4: the tier's bridge made here (MakeBridge).
		mSceneTiers.Add(tier);
	}

	public void OnDestroying(Scene scene)
	{
		// The scene's canvases' and panels' own roots go first.
		for (int i = mTextureRoots.Count - 1; i >= 0; i--)
		{
			if (mTextureRoots[i].Scene !== scene)
				continue;
			// E4: the active and press roots forgotten when they are this one's.
			delete mTextureRoots[i];
			mTextureRoots.RemoveAt(i);
		}
		for (int i < mSceneTiers.Count)
		{
			if (mSceneTiers[i].Scene !== scene)
				continue;
			// E4: the active and press roots forgotten when they are this tier's.
			let tier = mSceneTiers[i];
			mSceneTiers.RemoveAt(i);
			delete tier;
			return;
		}
	}

	private GuiSceneTier FindSceneTier(Scene scene)
	{
		for (let tier in mSceneTiers)
		{
			if (tier.Scene === scene)
				return tier;
		}
		return null;
	}

	// ==================== the tiers ====================

	/// A screen tier's root, filled by its stack (its id what a script finds).
	private void MakeScreenTier(GuiScreenTier tier)
	{
		tier.Root = new SceneRoot(mContext);
		using (Node.StyleWriteScope(tier.Root))
		{
			tier.Root.EditLayoutStyle(scope (s) => { s.Kind = .Stack; });
		}
		tier.Screens = new ScreenStack();
		tier.Screens.Id = "screens"; // a script's ScreenStack::of(gui::root().find("screens"))
		tier.Root.AddChild(tier.Screens);
		// E4: the tier's bridge made here (MakeBridge).
	}

	/// `run`'s own tier, or null when none was made.
	private GuiScreenTier FindRunTier(Object run)
	{
		if (run == null)
			return null;
		for (let tier in mRunTiers)
		{
			if (tier.Run === run)
				return tier;
		}
		return null;
	}

	/// The tier whose root is `root`, or null.
	private GuiScreenTier TierOfRoot(SceneRoot root)
	{
		if (root == null)
			return null;
		if (root === mScreen.Root)
			return mScreen;
		for (let tier in mRunTiers)
		{
			if (tier.Root === root)
				return tier;
		}
		return null;
	}

	/// `root` at `size`, styled through the GUI's sheets and laid out.
	private void StyleAndLayOut(SceneRoot root, Float2 size)
	{
		if (root.ViewportSize != size)
			root.ViewportSize = size;
		mStyles.MediaContext = root.MediaContext;
		mStyles.ApplyTree(root);
		root.UpdateLayout();
	}

	// ==================== the sheets ====================

	/// The user agent's sheet: the built-in theme, and the text of every tree in the default family
	/// at the body size. The style applier gives text a font only where a family is declared, and a
	/// root is no text node to hold one: each tree's top elements (:root) declare it, the rest
	/// inherit, and the game's sheets, above the user agent, choose otherwise.
	private void ApplyUserAgentSheet()
	{
		let css = scope String(Theme.DefaultThemeCSS);
		if (let fonts = Fonts)
		{
			let family = fonts.GetDefaultFontFamily(.. scope String());
			if (!family.IsEmpty)
			{
				css.Append("\n:root { font-family: \"");
				css.Append(family);
				css.Append("\"; font-size: var(--font-body); }\n");
			}
		}
		let sheet = scope StyleSheet();
		CSSParser.Parse(css, "theme", sheet);
		mStyles.UserAgentSheet = sheet;
	}

	/// The game's sheets as one author sheet importing each, in order: the style manager expands
	/// the imports through the provider, each over the ones before it.
	private void ApplySheets()
	{
		let css = scope String();
		for (let sheet in mSheets)
		{
			css.Append("@import \"{");
			sheet.ToString(css);
			css.Append("}\";\n");
		}
		let parsed = scope StyleSheet();
		CSSParser.Parse(css, "game", parsed);
		mStyles.StyleSheet = parsed;
		mSheetGeneration++;
	}

	// ==================== documents ====================

	/// A document's tree, with the caller's reference; null when it does not build.
	private Node BuildDocument(GuiDocument document)
	{
		if ((document == null) || document.Markup.IsEmpty)
			return null;
		let loader = scope MarkupLoader(mContext.ElementSet, mResources, Fonts);
		loader.SetDataModel(mContext.Data);
		let root = loader.LoadFromString(document.Markup);
		if (root == null)
			GlobalLog(.Warning, "GUI: a document did not build");
		return root;
	}

	// ==================== the built-in font ====================

	private const String cBuiltInFont = "Assets/fonts/roboto/Roboto-Regular.ttf";

	private bool LoadBuiltInFont()
	{
		if ((mDataFileSystem == null) || !mDataFileSystem.Exists(cBuiltInFont))
			return false;
		let stream = mDataFileSystem.Open(cBuiltInFont, .Read);
		if (stream == null)
			return false;
		defer delete stream;
		let size = stream.Size();
		if (size <= 0)
			return false;
		let bytes = scope uint8[(int)size];
		if (stream.Read(bytes) != (int)size)
			return false;
		if (mFonts.LoadFontFromMemory("Roboto", bytes) != .Success)
			return false;
		mFonts.SetDefaultFamily("Roboto");
		return true;
	}
}
