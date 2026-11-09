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
using Sedulous.Run;
using Sedulous.Runtime;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.VFS;

namespace Sedulous.Engine.GUI;

/// The engine's GUI on Sedulous.GUI: every game's interface.
///
/// One GUIContext and style manager for the application, the GUI's built-in theme under the
/// game's sheets (a list, in order, each an @import of its guid), and the fonts; a screen tier (a
/// root holding the gamekit's screen stack and an overlay layer above it, outside any scene, so it
/// survives a scene swap) and a scene tier (a root per scene, drawn wherever the scene renders);
/// both drawn into the engine's overlay passes through GUI.Hosting's GuiPassRenderer
/// (GuiOverlayDraw.bf). A sheet or document whose cooked product changes restyles the
/// GUI (hot reload). The GUI ticks on unscaled time (menus move while the game is paused), so its
/// work is in BeginFrame.
///
/// The game's screen: the screen tier lays out at the game's render resolution and draws, at the
/// target's own, into the rectangle that size is fitted into, turned when the game's orientation is
/// not the target's, as the game's image is. With run screens on (the editor), each run (a Game
/// tab's game) has a screen tier of its own, drawn for its tab (SetRenderRun); the overlay layer
/// stays on the shared tier above it. A script with no run (a headless tool's, a test's) uses the
/// shared tier, as every script does in the player; in the editor every scene that runs scripts
/// has a run (a Game tab's, a scene page's).
///
/// The components live (GuiComponentSync.bf, GuiRenderTextures.bf): a canvas's document in its
/// scene's root or a texture of its own, a billboard over its entity, a world panel on its
/// entity's sprite, each in line with its component every frame.
///
/// The input (GuiInputPump.bf): the engine's active input source into one root a frame through
/// GUI.Shell's bridge, the action layer told what the GUI took.
///
/// The scripts: `Gui` to a run's scripts is a GuiFacade whose root is that run's screen tier
/// (ScriptFacadeFor), offered among the run's services, the shared tier's on the application's;
/// the components reach their trees as nodes (`Root()`).
class GuiSubsystem : Subsystem, ISceneObserver, IRunListener
{
	/// Early in the frame, so a game's GUI sees the same frame; all work in BeginFrame.
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
	/// The project's earlier services, kept to the end: a label measured with one holds its
	/// CachedFont (borrowed) until it is styled again, so freeing the service at once left those
	/// labels pointing at freed fonts (a cook finishing mid-play sets the fonts again).
	private List<ResourceFontService> mRetiredFonts = new .() ~ DeleteContainerAndItems!(_);
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
	/// The run whose tier the next screen overlay draws under the shared one's, by id; nought for
	/// none.
	private RunId mRenderRun = 0;
	/// BORROWED: the runs subscribed to, from OnReady to OnShutdown.
	private IRunManager mRunManager = null;
	/// The shared tier's overlay layer. A HELD reference.
	private UIWidget mOverlay = null;
	/// The touch controls' guide, beneath the shared tier's screens. A HELD reference.
	private GuiTouchGuide mTouchGuide = null;
	/// A finger has touched the screen: the guide shows.
	private bool mTouchSeen = false;
	/// The GUI input reaches is editing text, as of the last input pump.
	private bool mTextWanted = false;
	/// `Gui` to scripts outside every run, its root the shared tier's, on the application's
	/// services. OWNED: each
	/// runtime it is set on borrows it, so it lives as long as the subsystem.
	private GuiFacade mScriptFacade ~ delete _;
	/// `Gui` to one run's scripts, its root that run's tier (ScriptFacadeFor), each OWNED, by the
	/// run's id.
	private List<(RunId run, GuiFacade facade)> mRunFacades = new .() ~ { for (let entry in _) delete entry.facade; delete _; };
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
	/// The game kit's prompts, installed on the GUI's context: they read mPromptRuntime (else the
	/// input subsystem's), told again when its bindings' version moves.
	private InputPrompts mPrompts = new .() ~ delete _;
	/// BORROWED: the host's, outliving its use here (null: the input subsystem's own).
	private ActionRuntime mPromptRuntime = null;
	/// The runtime the prompts read now, and its bindings' version they last saw.
	private ActionRuntime mPromptsRead = null;
	private uint64 mPromptsVersion = 0;
	/// BORROWED: the window whose platform text input follows the GUI's focus; null leaves it alone.
	private Sedulous.Shell.IWindow mTextInputTarget = null;
	/// The root input went to last, and the root a held press began in: BORROWED, each forgotten
	/// as its root goes (ForgetInputRoot).
	private SceneRoot mActiveRoot = null;
	private SceneRoot mPressRoot = null;
	/// That press began over GUI that takes the pointer.
	private bool mPressTaken = false;
	/// The GUI took the pointer this frame.
	private bool mPointerTaken = false;
	/// Where a held press on a panel last was, in its pixels.
	private Float2 mPanelPoint = .(0.0f, 0.0f);

	/// The data mount is BORROWED for the subsystem's life: the VG shaders and the built-in font
	/// come from it.
	public this(IFileSystem dataFileSystem)
	{
		mDataFileSystem = dataFileSystem;
		mContext.ResourceProvider = mResources;
		mStyles.ResourceProvider = mResources; // the sheets' @import, url() and fonts
		// A script's root is its run's screen tier, the shared one with no run (the player's),
		// asked at each call: none before OnInit makes it, nor after shutdown drops it, so a
		// script still running then finds no root rather than a freed one.
		mScriptFacade = new .(new [=this] () => ScreenRootFor(null));
	}

	public ~this()
	{
		// Shut down already when a context drove it; else what OnInit made goes here. No early
		// return: the fields' own cleanups would be skipped.
		DropTiers();
		delete mRenderState;
		mRenderState = null;
	}

	/// The GUI: its data, keymap, commands and resources. Named apart from
	/// what the subsystem's manager was called when it came, Context. The subsystem's.
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

	/// The project's fonts (defaultUiFontId, uiFontIds): the
	/// default and the others, each a family a label picks by `font-family`. Without a default the
	/// built-in font serves (the others wait for one). The products are BORROWED: the resource
	/// manager's cache keeps them alive.
	public void SetFonts(Font defaultFont, Span<Font> others)
	{
		// The same fonts again (the editor sets them after every cook): nothing to change.
		if ((defaultFont == mDefaultFont) && SameFonts(others))
			return;
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
		// The old service is kept (mRetiredFonts): a label holds its fonts until it is styled again.
		if (was != null)
			mRetiredFonts.Add(was);
		// Every root styled again, so each label takes its font from the new service, and measured.
		if (mScreen.Root != null)
			Restyle(mScreen.Root);
		for (let tier in mRunTiers)
			Restyle(tier.Root);
		for (let tier in mSceneTiers)
			Restyle(tier.Root);
		for (let root in mTextureRoots)
			Restyle(root.Root);
	}

	// Whether `others` are the fonts set now, in order (nulls left out, as SetFonts does).
	private bool SameFonts(Span<Font> others)
	{
		int count = 0;
		for (let font in others)
		{
			if (font == null)
				continue;
			if ((count >= mOtherFonts.Count) || (mOtherFonts[count] != font))
				return false;
			count++;
		}
		return count == mOtherFonts.Count;
	}

	private static void Restyle(Node root)
	{
		root.MarkStyleDirty(true);
		root.RequestLayoutTree();
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
	/// draw. The input pump maps the pointer through it.
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
	/// or no run. The subsystem's. A run's tier goes with its session (the run's stop, or the run
	/// gone without one), every screen on it too: the run manager says so.
	public ScreenStack ScreensFor(IRun run)
	{
		let tier = TierOfRoot(ScreenRootFor(run));
		return (tier != null) ? tier.Screens : null;
	}

	public SceneRoot ScreenRootFor(IRun run) => ScreenRootFor((run != null) ? run.Id : 0);

	private SceneRoot ScreenRootFor(RunId run)
	{
		if (!mRunScreens || (run == 0) || (mScreen.Root == null))
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
	public void SetScreenResolution(IRun run, uint32 width, uint32 height, FitMode fit)
	{
		if (let tier = TierOfRoot(ScreenRootFor(run)))
			ApplyResolution(tier, width, height, fit);
	}

	public void SetScreenOrientation(IRun run, ScreenOrientation orientation)
	{
		if (let tier = TierOfRoot(ScreenRootFor(run)))
			tier.Orientation = orientation;
	}

	/// The run whose screen tier the next screen overlay draws under the shared one's overlays
	/// (null: none), set by a host around its overlays for that run's view.
	public void SetRenderRun(IRun run) => mRenderRun = (run != null) ? run.Id : 0;

	/// The run's tier and every screen on it go.
	private void EndRunScreens(RunId run)
	{
		for (int i < mRunTiers.Count)
		{
			if (mRunTiers[i].Run != run)
				continue;
			let tier = mRunTiers[i];
			ForgetInputRoot(tier.Root);
			mRunTiers.RemoveAt(i);
			tier.Screens.Clear();
			delete tier;
			break;
		}
		if (mRenderRun == run)
			mRenderRun = 0;
	}

	// IRunListener: a run's `Gui` as it is made; its tier goes with its session.
	public void OnRunCreated(IRun run) => OfferRunFacade(run);
	public void OnRunStopping(IRun run) => EndRunScreens(run.Id);
	public void OnRunDestroyed(IRun run) => EndRunScreens(run.Id);

	public int RunScreenCount => mRunTiers.Count;

	/// The overlay layer above every screen. The subsystem's.
	public UIWidget OverlayLayer => mOverlay;
	/// Whether the GUI input reaches is editing text (a field has the focus), as of the last input
	/// pump: a host that owns the window's text input (the editor's Game tab) starts it.
	public bool WantsTextInput => mTextWanted;
	/// The touch controls' guide, beneath the shared tier's screens (tests). The subsystem's.
	public GuiTouchGuide TouchGuide => mTouchGuide;

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

	/// `document`'s tree built in the GUI's context (its resources and fonts, its `{{values}}` bound
	/// to the GUI's data), placed nowhere: a native host's screen to push on Screens. With the
	/// CALLER's reference; null when it does not build.
	public Node BuildDocument(GuiDocument document)
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

	/// The action runtime the GUI's prompts (GUI.Gamekit's Prompt) name the bindings of: the game's
	/// (the application's primary game instance's, as the default application sets it); null, the
	/// input subsystem's own. BORROWED: it outlives its use here, or is set to null first. Its
	/// bindings' changes (a map loaded, a rebinding, a set enabled) are seen at the next frame and
	/// every prompt reads them again.
	public void SetPromptRuntime(ActionRuntime runtime)
	{
		mPromptRuntime = runtime;
	}

	public ActionRuntime PromptRuntime => (mPromptRuntime != null) ? mPromptRuntime : ((mInput != null) ? mInput.Runtime : null);

	public InputPrompts Prompts => mPrompts;

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

	// ==================== scripts ====================

	/// `Gui` to scripts outside every run is the shared tier's facade (`Gui.Root()`, its stack
	/// `ScreenStack::Of(Gui.Root().Find("screens"))`), on the application's services; each run's
	/// own is among the run's services, offered as the run is made, so its scripts find it first.
	public override void OnRegister(SubsystemManager manager)
	{
		base.OnRegister(manager);
		manager.RegisterService(mScriptFacade);
	}

	public override void OnUnregister()
	{
		if (Manager != null)
			Manager.UnregisterService<GuiFacade>();
		base.OnUnregister();
	}

	// `run`'s own `Gui` among its services: `Gui.Root()` is its screen tier (ScreenRootFor), its
	// own with run screens on, the shared one without.
	private void OfferRunFacade(IRun run)
	{
		if (let held = run as RunBase)
			held.Register<GuiFacade>(ScriptFacadeFor(run));
	}

	// The runs still alive let go of their `Gui` as this subsystem shuts down.
	private void WithdrawRunFacades()
	{
		if (mRunManager == null)
			return;
		mRunManager.ForEachRun(scope (run) =>
			{
				let held = run as RunBase;
				if (held == null)
					return;
				let offered = held.FindService(typeof(GuiFacade));
				for (let entry in mRunFacades)
				{
					if (entry.facade === offered)
					{
						held.Remove<GuiFacade>();
						break;
					}
				}
			});
	}

	/// The `Gui` a run's scripts are given, made on first use (as the run is made, among its
	/// services). Its root is asked at each call, so a run whose screens ended (its stop) and plays
	/// again gets its tier back. The shared one with no run. The subsystem's until EndRunScripts or
	/// its own end; BORROWED by the run.
	public GuiFacade ScriptFacadeFor(IRun run)
	{
		if (run == null)
			return mScriptFacade;
		let id = run.Id;
		for (let entry in mRunFacades)
		{
			if (entry.run == id)
				return entry.facade;
		}
		let facade = new GuiFacade(new [=this, =id] () => ScreenRootFor(id));
		mRunFacades.Add((id, facade));
		return facade;
	}

	/// The run is gone for good: its `Gui` goes. After every runtime the run made, which borrow
	/// it, is gone, so its host says so (by the run's id, the run itself gone by then): the run's
	/// destruction comes first.
	public void EndRunScripts(RunId run)
	{
		for (int i < mRunFacades.Count)
		{
			if (mRunFacades[i].run != run)
				continue;
			delete mRunFacades[i].facade;
			mRunFacades.RemoveAt(i);
			return;
		}
	}

	public int RunScriptFacadeCount => mRunFacades.Count;

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
		mOverlay.HitTestVisible = false; // over the screens: only what is on it takes the pointer
		using (Node.StyleWriteScope(mOverlay))
		{
			mOverlay.EditLayoutStyle(scope (s) => { s.Kind = .Stack; });
		}
		mScreen.Root.AddChild(mOverlay);
		// The touch controls' guide, beneath the screens pushed on this tier and the overlays.
		mTouchGuide = new GuiTouchGuide();
		mScreen.Root.AddChildAt(mTouchGuide, 0);
		// The scripts' facades resolve their roots from here (made with the subsystem: a host may
		// install them before it starts).
	}

	protected override void OnReady()
	{
		if (Manager == null)
			return;
		mInput = Manager.GetSubsystem<InputSubsystem>();
		PointBridgesAtInputKinds(); // the shared tier's was made before the input was found
		mPrompts.Install(mContext); // every prompt in the game's GUI names its bindings through it
		SyncPrompts();
		if (let scenes = Manager.GetSubsystem<SceneSubsystem>())
		{
			scenes.RegisterObserver(this, .SystemsReady);
			scenes.RegisterObserver(this, .Destroying);
		}
		// The runs' lifecycle: a run's tier goes with its session.
		mRunManager = Manager.RunManager;
		if (mRunManager != null)
		{
			mRunManager.Subscribe(this);
			// The runs made before this was ready get their `Gui` too.
			mRunManager.ForEachRun(scope (run) => { OfferRunFacade(run); });
		}
		// Headless contexts (tests, the cooker) have no render subsystem: nothing registers.
		mRender = Manager.GetSubsystem<RenderSubsystem>();
		if (mRender != null)
		{
			mRender.RegisterOverlay((ISceneOverlay)this);
			mRender.RegisterOverlay((IScreenOverlay)this);
		}
	}

	protected override void OnShutdown()
	{
		WithdrawRunFacades();
		if (mRunManager != null)
		{
			mRunManager.Unsubscribe(this);
			mRunManager = null;
		}
		if (mRender != null)
		{
			mRender.UnregisterOverlay((ISceneOverlay)this);
			mRender.UnregisterOverlay((IScreenOverlay)this);
			mRender = null;
		}
		if (Manager != null)
		{
			if (let scenes = Manager.GetSubsystem<SceneSubsystem>())
				scenes.UnregisterObserver(this);
		}
		mActiveRoot = null;
		mPressRoot = null;
		InputPrompts.Uninstall(mContext);
		mPrompts.SetRuntime(null);
		mPromptsRead = null;
		mInput = null;
		PointBridgesAtInputKinds(); // none: the tracker goes with the input subsystem
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
		mRenderRun = 0;
		// The shared tier's bridge borrows its root's dispatcher: it goes before the root.
		delete mScreen.Bridge;
		mScreen.Bridge = null;
		if (mScreen.Screens != null)
			mScreen.Screens.Clear();
		if (mOverlay != null)
		{
			mOverlay.ReleaseRef();
			mOverlay = null;
		}
		if (mTouchGuide != null)
		{
			mTouchGuide.ReleaseRef();
			mTouchGuide = null;
		}
		// The script facades resolve through the shared root, gone below: a script still running
		// finds no root, not a freed one.
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
			if (mResources.TakeImagesArrived())
			{
				// A texture an image asked for before it loaded is here: every root lays out again,
				// and the images that got nothing ask again.
				if (mScreen.Root != null)
					mScreen.Root.RequestLayoutTree();
				for (let tier in mRunTiers)
					tier.Root.RequestLayoutTree();
				for (let tier in mSceneTiers)
					tier.Root.RequestLayoutTree();
				for (let root in mTextureRoots)
					root.Root.RequestLayoutTree();
			}
			SyncPrompts();
			SyncComponents(); // each scene's billboards, canvases and world panels in line
			PumpInput(); // before the clock, so this frame's input sees this frame's time
			// By ticks: TimeSpan.FromSeconds would round to whole milliseconds.
			mContext.Update(TimeSpan((int64)((double)deltaTime * (double)TimeSpan.TicksPerSecond)));
			if (mScreen.Root != null)
				StyleAndLayOut(mScreen.Root, mScreen.Root.ViewportSize);
			for (let tier in mRunTiers)
				StyleAndLayOut(tier.Root, tier.Root.ViewportSize);
		}
	}

	/// The action layer's pointer and keyboard claims cleared after the frame read them: the next
	/// frame's BeginFrame lane republishes them (the GUI's added by PumpInput).
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
		tier.Bridge = MakeBridge(tier.Root);
		mSceneTiers.Add(tier);
	}

	public void OnDestroying(Scene scene)
	{
		// The scene's canvases' and panels' own roots go first.
		for (int i = mTextureRoots.Count - 1; i >= 0; i--)
		{
			if (mTextureRoots[i].Scene !== scene)
				continue;
			ForgetInputRoot(mTextureRoots[i].Root);
			delete mTextureRoots[i];
			mTextureRoots.RemoveAt(i);
		}
		for (int i < mSceneTiers.Count)
		{
			if (mSceneTiers[i].Scene !== scene)
				continue;
			let tier = mSceneTiers[i];
			ForgetInputRoot(tier.Root);
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
		tier.Bridge = MakeBridge(tier.Root);
	}

	/// `run`'s own tier, or null when none was made.
	private GuiScreenTier FindRunTier(RunId run)
	{
		if (run == 0)
			return null;
		for (let tier in mRunTiers)
		{
			if (tier.Run == run)
				return tier;
		}
		return null;
	}

	private GuiScreenTier FindRunTier(IRun run) => (run != null) ? FindRunTier(run.Id) : null;

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

	// ==================== prompts ====================

	/// The prompts on the runtime they should read, told again when its bindings may have changed.
	private void SyncPrompts()
	{
		let runtime = PromptRuntime;
		if (runtime !== mPromptsRead)
		{
			mPromptsRead = runtime;
			mPromptsVersion = (runtime != null) ? runtime.BindingsVersion : 0;
			mPrompts.SetRuntime(runtime); // tells them
			return;
		}
		if ((runtime != null) && (runtime.BindingsVersion != mPromptsVersion))
		{
			mPromptsVersion = runtime.BindingsVersion;
			mPrompts.NotifyBindingsChanged();
		}
	}

	// ==================== the built-in font ====================

	private const String cBuiltInFont = "Engine/Fonts/roboto/Roboto-Regular.ttf";

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
