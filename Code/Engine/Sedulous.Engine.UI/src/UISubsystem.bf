using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Engine.Input;
using Sedulous.Engine.Render;
using Sedulous.Engine.Scene;
using Sedulous.Fonts;
using Sedulous.Profiler;
using Sedulous.Fonts.Resource;
using Sedulous.Fonts.TrueType;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.Runtime;
using Sedulous.Scene;
using Sedulous.Shaders;
using Sedulous.Shell;
using Sedulous.UI;
using Sedulous.UI.Gamekit;
using Sedulous.UI.Resource;
using Sedulous.UI.Shell;
using Sedulous.VG.Renderer;

namespace Sedulous.Engine.UI;

/// The GAME screen tier.
///
/// It owns ONE UI context with the game stylesheet and the core controls, never the toolkit;
/// instantiates a fresh view tree per canvas; lays each out against its render target; draws
/// them through the vector renderer into an overlay pass AFTER the scene, which is the
/// player's backbuffer and an editor's viewport texture alike; and feeds UI input from the
/// SAME device facades the action layer reads, publishing what the UI consumed so a click on
/// a menu never also fires a gameplay action.
///
/// UI ticks on UNSCALED time, which is why the work runs in the frame's opening lane: menus
/// have to animate while the game is paused.
///
/// PARTIAL PORT. The context, both tiers, the scene roots, the screen overlays, the theme and
/// font binding and the GPU bring up are here. The canvas synchronisation, the input pump,
/// the overlay drawing and the render texture canvases are still in the ledger.
class UISubsystem : Subsystem, ISceneObserver
{
	/// Before the scene subsystem, so a page reading canvas visibility sees this frame's.
	/// The lane matters more than the order: ALL of it runs on the raw delta.
	public override int32 UpdateOrder => -650;

	private String mFontPath = new .() ~ delete _;

	private UIContext mContext = new .() ~ delete _;
	private UIInputBridge mBridge ~ delete _;

	private RootView mScreenRoot = null;
	private ScreenStack mScreenStack = new .() ~ delete _;
	/// The scene LESS screen tier, ABOVE everything.
	private ViewGroup mOverlayLayer = null;
	private StyleSheet mTheme = null;

	private TrueTypeFontService mFonts ~ delete _;
	/// The cooked font service, once a default font product is bound.
	private ResourceFontService mResourceFonts ~ delete _;

	private List<UISceneUI> mSceneUIs = new .() ~ DeleteContainerAndItems!(_);
	private List<UITextureCanvasRoot> mTextureCanvasRoots = new .() ~ DeleteContainerAndItems!(_);

	/// BORROWED.
	private InputSubsystem mInput = null;
	private RenderSubsystem mRender = null;

	/// Gates the canvas textures to ONE pass per UI frame.
	private uint64 mCanvasTexturesSerial = uint64.MaxValue;

	/// Gates the vector rings to ONE rewind per UI frame.
	private uint64 mFrameSerial = 0;

	private UIRenderState mRenderState = null ~ delete _;

	// The polled pointer's edges, since the buttons are read per frame rather than streamed.
	private bool[3] mPrevButtons = .(false, false, false);
	/// True while an interactive canvas is under the pointer or holds text focus, which
	/// mirrors the published mask.
	private bool mPointerConsumed = false;

	// Gamepad focus navigation, held and repeating per direction: up, down, left, right.
	private float[4] mNavRepeat = .(0.0f, 0.0f, 0.0f, 0.0f);
	private bool[4] mNavHeld = .(false, false, false, false);
	private float mNavDeltaTime = 0.0f;

	public this()
	{
		mBridge = new UIInputBridge(mContext);
	}

	/// An optional font for the default face. Empty tries the repository's own, and without
	/// either, text simply does not render until a cooked font binds. Set before startup.
	public void SetFontPath(StringView path) => mFontPath.Set(path);

	/// The window whose platform text input follows GAME UI focus.
	///
	/// The player sets its main window. A host whose text input another bridge owns, which an
	/// editor is, leaves this null, and null also clears it.
	public void SetTextInputTarget(IWindow window) => mBridge.SetTextInputTarget(window);

	public UIContext Context => mContext;

	/// Whether any interactive canvas is under the pointer or holds text focus.
	public bool PointerOverUI => mPointerConsumed;

	/// The frame's opening lane, on UNSCALED time: menus animate while the game is paused,
	/// which is the whole reason this work does not run in the update lane.
	public override void BeginFrame(float deltaTime)
	{
		using (ProfileScope("UI.BeginFrame"))
		{
			// One vector ring rewind per UI frame.
			mFrameSerial++;
			mContext.BeginFrame(deltaTime);
			mNavDeltaTime = deltaTime;

			SyncCanvases();
			PumpInput();
		}
	}

	/// The scene LESS screen tier's root: global overlays only, scene UI living in the per
	/// scene roots.
	public RootView ScreenRoot => mScreenRoot;

	/// Push, pop and replace of screens over that root. Owned by the tier so its lifetime
	/// matches the root's.
	public ScreenStack Screens => mScreenStack;

	/// The scene tier's root for a scene: its canvases above a shared billboard layer. Null
	/// for a scene this has never seen.
	public RootView SceneRoot(Scene scene)
	{
		let ui = FindSceneUI(scene);
		return (ui != null) ? ui.Root : null;
	}

	// ==================== the scene-less screen tier ====================
	// Global overlays OUTSIDE any scene: they survive a scene swap, which is what a loading
	// screen or a system menu needs, and draw ABOVE every scene's canvases in every target.
	// Pushed from code, and the caller keeps what it was given so it can take it away again.

	/// Instantiates a document and attaches it topmost. Null when the markup fails.
	public View PushScreenOverlay(UIDocument document)
	{
		if (document.Markup.IsEmpty || (mOverlayLayer == null))
			return null;

		let view = MarkupLoader.LoadFromString(document.Markup, mContext);
		if (view != null)
			mOverlayLayer.AddView(view);

		return view;
	}

	/// Instantiates a document's tree WITHOUT attaching it, so a caller pushing from inside
	/// an event handler can attach later through the mutation queue. Null when it fails.
	public View InstantiateScreenOverlay(UIDocument document)
	{
		if (document.Markup.IsEmpty || (mOverlayLayer == null))
			return null;

		return MarkupLoader.LoadFromString(document.Markup, mContext);
	}

	/// Attaches an already built view topmost, which is the code built overlay path.
	public void PushScreenOverlay(View view)
	{
		if ((view != null) && (mOverlayLayer != null))
			mOverlayLayer.AddView(view);
	}

	public void RemoveScreenOverlay(View view)
	{
		if ((view != null) && (mOverlayLayer != null))
			mOverlayLayer.RemoveView(view);
	}

	public int ScreenOverlayCount => (mOverlayLayer != null) ? mOverlayLayer.ChildCount : 0;

	/// Whether the global overlay layer should intercept input: it holds at least one HIT
	/// TESTABLE child.
	///
	/// A modal menu qualifies. A passive badge or watermark pushed with hit testing off does
	/// not, so it draws above every scene without shielding the heads up display beneath it
	/// from the pointer.
	public bool OverlayLayerWantsInput
	{
		get
		{
			if (mOverlayLayer == null)
				return false;

			for (int i < mOverlayLayer.ChildCount)
			{
				let child = mOverlayLayer.GetChildAt(i);
				if ((child != null) && child.IsHitTestVisible && (child.Visibility == .Visible))
					return true;
			}
			return false;
		}
	}

	// ==================== lifecycle ====================

	protected override void OnInit()
	{
		MarkupLoader.Initialize();
		// The screen element authored screens are written with.
		GamekitMarkup.Register();

		mFonts = new TrueTypeFontService();

		var fontPath = mFontPath.IsEmpty
			? "Data/Assets/fonts/roboto/Roboto-Regular.ttf"
			: StringView(mFontPath);

		if (mFonts.LoadFont("Roboto", fontPath) == .Success)
		{
			mFonts.SetDefaultFamily("Roboto");
		}
		else
		{
			// NOT fatal on its own: a cooked default font bound later replaces this probe,
			// and a host does that right after startup. Only when neither resolves does game
			// UI text fail to render at all.
			GlobalLog(.Information,
				"UISubsystem: the development fallback font '{}' is not present, which is normal outside the source tree. Game UI text needs the project's cooked default font to bind.",
				fontPath);
		}

		mContext.SetFontService(mFonts);

		mTheme = GameTheme.Create();
		mContext.SetStyleSheet(mTheme);

		// The scene LESS screen tier. The screen root holds ONLY the global overlay layer,
		// each scene's canvases and billboards living in that scene's own root, and it hit
		// tests only while it HOLDS overlays: an empty full screen layer must never swallow
		// the clicks meant for the canvases below it.
		mScreenRoot = new RootView();
		mContext.AddRootView(mScreenRoot);
		mScreenStack.Attach(mScreenRoot);

		let overlay = new FrameLayout();
		overlay.IsHitTestVisible = false;
		mOverlayLayer = overlay;
		mScreenRoot.AddView(mOverlayLayer);
	}

	protected override void OnReady()
	{
		if (Context == null)
			return;

		mInput = base.Context.GetSubsystem<InputSubsystem>();

		if (let scenes = base.Context.GetSubsystem<SceneSubsystem>())
		{
			scenes.RegisterObserver(this, .SystemsReady);
			scenes.RegisterObserver(this, .Destroying);
		}

		// BOTH roles: the scene tier draws inside the compose per view, and the screen tier
		// when the host asks for its overlays per window target. A headless context has no
		// render subsystem at all, and then neither registers.
		mRender = base.Context.GetSubsystem<RenderSubsystem>();
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

		if (base.Context != null)
		{
			if (let scenes = base.Context.GetSubsystem<SceneSubsystem>())
				scenes.UnregisterObserver(this);
		}

		for (let ui in mSceneUIs)
		{
			if (ui.Root != null)
			{
				mContext.RemoveRootView(ui.Root);
				delete ui.Root;
			}
		}
		ClearAndDeleteItems!(mSceneUIs);

		for (let entry in mTextureCanvasRoots)
		{
			mContext.RemoveRootView(entry.Root);
			delete entry.Root;
		}
		ClearAndDeleteItems!(mTextureCanvasRoots);

		mOverlayLayer = null;
		if (mScreenRoot != null)
		{
			mContext.RemoveRootView(mScreenRoot);
			delete mScreenRoot;
			mScreenRoot = null;
		}

		delete mRenderState;
		mRenderState = null;

		if (mTheme != null)
		{
			mTheme.ReleaseRef();
			mTheme = null;
		}
	}

	public void OnSystemsReady(Scene scene)
	{
		// Each scene gets its OWN root, with the billboard layer below its canvases, which
		// the scene overlay pass draws wherever that scene renders.
		let ui = new UISceneUI();
		ui.Scene = scene;
		ui.Root = new RootView();

		let billboards = new AbsoluteLayout();
		// Nameplates never eat clicks.
		billboards.IsHitTestVisible = false;
		ui.BillboardLayer = billboards;
		ui.Root.AddView(ui.BillboardLayer);

		mContext.AddRootView(ui.Root);
		mSceneUIs.Add(ui);
	}

	public void OnDestroying(Scene scene)
	{
		for (int i < mSceneUIs.Count)
		{
			if (mSceneUIs[i].Scene !== scene)
				continue;

			if (mSceneUIs[i].Root != null)
			{
				mContext.RemoveRootView(mSceneUIs[i].Root);
				delete mSceneUIs[i].Root;
			}

			delete mSceneUIs[i];
			mSceneUIs.RemoveAt(i);
			break;
		}
	}

	private UISceneUI FindSceneUI(Scene scene)
	{
		for (let ui in mSceneUIs)
		{
			if (ui.Scene === scene)
				return ui;
		}
		return null;
	}

	// ==================== theme and font ====================

	/// The project's default font, a cooked product bound through the resource manager.
	///
	/// Swaps the context onto a service over that product's baked entries; null restores the
	/// on demand fallback. The product is BORROWED, the resource manager's cache keeping it
	/// alive.
	public void SetDefaultFont(Font font)
	{
		if ((font == null) || (font.EntryCount == 0))
		{
			// Back to the on demand service, which is the development path.
			delete mResourceFonts;
			mResourceFonts = null;
			mContext.SetFontService(mFonts);
			return;
		}

		delete mResourceFonts;
		mResourceFonts = new ResourceFontService();
		mResourceFonts.AddFont(font);
		mContext.SetFontService(mResourceFonts);

		GlobalLog(.Information, "UISubsystem: default font bound, '{}' with {} baked size(s)",
			font.Family, font.EntryCount);
	}

	/// The project's default theme, parsed with the game palette and set as the context's
	/// stylesheet. Null, empty or unparseable falls back to the built in one, and a per
	/// canvas override still layers on top.
	public void SetDefaultTheme(UITheme theme)
	{
		StyleSheet sheet = null;

		if ((theme != null) && !theme.StyleSheet.IsEmpty)
		{
			let loader = scope StyleSheetLoader();
			loader.SetPalette(GameTheme.Palette());
			sheet = loader.Load(theme.StyleSheet);

			if (sheet == null)
			{
				GlobalLog(.Warning,
					"UISubsystem: the default UI theme failed to parse, so the built in one stands");
			}
		}

		if (mTheme != null)
			mTheme.ReleaseRef();

		mTheme = (sheet != null) ? sheet : GameTheme.Create();
		mContext.SetStyleSheet(mTheme);
	}

	// ==================== GPU bring-up ====================

	/// One time device and shader bring up, by whoever owns graphics. IDEMPOTENT, and without
	/// it the overlay draws nothing at all.
	public void EnsureRenderReady(IDevice device, int32 frameCount)
	{
		if (mRenderState == null)
			mRenderState = new UIRenderState(mContext.FontService);

		if (mRenderState.Device != null)
			return;

		mRenderState.Device = device;
		mRenderState.FrameCount = frameCount;

		// Resolved through the shared host: a cooked pack where there is one, and the
		// compiler over the shader directory otherwise. The vector shaders ship in the
		// engine's own corpus like every other shader.
		let root = scope String();
		if (!FindShaderRoot(root))
		{
			GlobalLog(.Error,
				"UISubsystem: no shader directory and no shader pack, so game UI will not render");
			return;
		}

		if (mRenderState.ShaderHost.Initialize(device, root) case .Err)
		{
			GlobalLog(.Error,
				"UISubsystem: no shader compiler and no shader pack, so game UI will not render");
			return;
		}

		mRenderState.VertexShader = mRenderState.ShaderHost.GetVariant("vg", .Vertex, .None);
		mRenderState.FragmentShader = mRenderState.ShaderHost.GetVariant("vg", .Fragment, .None);
		mRenderState.GradRadialShader = mRenderState.ShaderHost.GetVariant("vg_grad_radial",
			.Fragment, .None);
		mRenderState.GradConicShader = mRenderState.ShaderHost.GetVariant("vg_grad_conic",
			.Fragment, .None);
		// The signed distance field text fragment.
		mRenderState.DistanceFieldShader = mRenderState.ShaderHost.GetVariant("vg_df", .Fragment,
			.None);
		mRenderState.BoxShadowShader = mRenderState.ShaderHost.GetVariant("vg_shadow", .Fragment,
			.None);

		// The per pixel gradients only where BOTH resolved, since a pre cooked pack may
		// predate them; otherwise everything falls back to the affine ramp.
		mRenderState.Context.SetPerPixelGradients((mRenderState.GradRadialShader != null)
			&& (mRenderState.GradConicShader != null));

		// Stencil for the CANVAS render to texture passes, which are the only passes this
		// subsystem OWNS: the scene and screen overlay passes belong to the renderer and the
		// host, and stay colour only until they carry an attachment themselves.
		mRenderState.CanvasStencilFormat = VGRenderer.PickStencilCapableFormat(device, 1);
	}

	/// Walks up from the working directory for the shader root, a Beef workspace carrying no
	/// compiled in source path.
	private static bool FindShaderRoot(String outPath)
	{
		let current = scope String();
		GetCurrentDirectory(current);

		for (int depth < 8)
		{
			let candidate = scope:: String();
			PathJoin(current, "Data/Shaders", candidate);
			if (System.IO.Directory.Exists(candidate))
			{
				outPath.Set(candidate);
				return true;
			}

			let parent = scope:: String();
			PathParent(current, parent);
			if (parent.IsEmpty || (parent == current))
				break;
			current.Set(parent);
		}
		return false;
	}
}
