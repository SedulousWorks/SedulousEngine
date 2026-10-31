using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Fonts;
using Sedulous.Graphics;
using Sedulous.RHI;
using Sedulous.VG;
using Sedulous.VG.Renderer;

namespace Sedulous.GUI;

// GuiHost: the GUI on the runtime's multi-window graphics host (Sedulous.Graphics).
//
// One GUIContext and one style manager for the application, and a SceneRoot per RenderWindow with
// that window's VG context, VG renderer and pass targets (multisampling, and the stencil the fills
// use), stashed on the window as its payload. A window may hold more roots, panes, each over a
// region of it with an input surface and bridge of its own (a root has a dispatcher of its own)
// and, when it belongs to another GUI (a tool's, such as the inspector), that GUI's style manager.
// The picture baker serves every window: a picture baked once registers with each window's
// renderer. An application constructs one host, attaches a root to its main window (and to each
// window it opens), and calls Update from its update and RenderWindow from its render.
//
// Input: the pointer goes to the window under it, or to the window a press began in until every
// button is up (the GUI has no capture to ask, so a held press is one), each of its panes pumped
// through its own surface (the router gates them by region); keys, text and the gamepad go to the
// focused window's pane that was clicked last, else its first; a file dropped goes to the window it
// landed on. An application may take a pane's pointer for itself first (a tool picking what is
// under it) and draw over a window after its panes (a tool's highlights). A root draws when it
// needs a frame (E8a's NeedsFrame: something changed, an animation runs, a bake landed); otherwise
// its window re-encodes the batch it drew last, since the runtime host presents every frame.
//
// Windows of its own (D6): given an opener (the application's), the host opens an OS window for a
// root and closes it, tells its owner what happens to each window by its root (moved, resized,
// focus, a close asked for), and says which root is under a screen point and where a root's point
// is on the screen, where the window system lets it place windows (not Wayland).
//
// Order of teardown: detach a window before its RenderWindow goes (its renderer leaves the baker's
// targets), and let the host go before the shader library whose modules it draws with.

/// One window's GUI, the payload GuiHost stashes on its RenderWindow (which owns it, and deletes it
/// after the GPU is done with it).
class GuiWindowData : IRenderWindowData
{
	/// A root over a region of the window (empty: all of it), with its own input. It holds a
	/// reference to its root, and owns its surface and bridge.
	public class Pane
	{
		public SceneRoot Root = null ~ _?.ReleaseRef();
		public Rectangle Region = .();
		/// Another GUI's; null: the host's. Borrowed.
		public StyleManager Styles = null;
		public Sedulous.Shell.InputSurface Surface = null ~ delete _;
		public GuiInputBridge Bridge = null ~ delete _;
	}

	/// Targets a resize replaced, kept until the frames in flight that drew into them are done.
	public class RetiredTargets
	{
		public VGPassTargets Targets ~ delete _;
		public uint32 FramesLeft = 0;

		/// Takes `targets`.
		public this(VGPassTargets targets, uint32 framesLeft)
		{
			Targets = targets;
			FramesLeft = framesLeft;
		}
	}

	/// The first is the window's root.
	public List<Pane> Panes = new .() ~ DeleteContainerAndItems!(_);
	public VGContext Canvas = null ~ delete _;
	public VGRenderer Renderer = new .() ~ delete _;
	/// Null: a plain single-sampled pass.
	public VGPassTargets Targets = null ~ delete _;
	/// Its renderer draws the multisampled pass (its targets were made), never the plain one.
	public bool Multisampled = false;
	public List<RetiredTargets> Retired = new .() ~ DeleteContainerAndItems!(_);
	/// Blends encoded values, through the backbuffer's UNORM view.
	public bool Encoded = false;
	public TextureFormat DrawFormat = .Undefined;
	/// Update's verdict: the panes draw this frame, else the last batch is encoded.
	public bool NeedsFrame = true;
	/// The frame size its sizes were last logged at.
	public uint32 LoggedWidth = 0;
	public uint32 LoggedHeight = 0;

	public SceneRoot Root => Panes.IsEmpty ? null : Panes[0].Root;
}

class GuiHost
{
	/// Takes a pane's pointer for the application before the pane sees it (a tool picking what is
	/// under it, a boundary being dragged): true when it did, and the pane is not pumped.
	public typealias PointerFilter = delegate bool(SceneRoot pane, Sedulous.Shell.InputSurface surface);
	/// Draws over a window after its panes, in the window's pixels.
	public typealias Overlay = delegate void(Sedulous.Graphics.RenderWindow window, DrawContext context);
	/// Told what happens to a window the host serves, by the window's root: moved, resized, focus
	/// gained or lost, a close asked for (the host closes nothing itself: its owner decides).
	public typealias WindowEventListener = delegate void(SceneRoot root, Sedulous.Shell.WindowEvent event);

	/// Opens and closes the OS windows the host makes for a root: the application's (its
	/// IApplicationHost's OpenWindow and CloseWindow), which owns them. It owns its two delegates.
	public class WindowOpener
	{
		public delegate Sedulous.Graphics.RenderWindow(Sedulous.Shell.WindowSettings settings) Open = null ~ delete _;
		public delegate void(Sedulous.Graphics.RenderWindow window) Close = null ~ delete _;
	}

	private struct Attached
	{
		public Sedulous.Graphics.RenderWindow Window;
		public GuiWindowData Data; // the RenderWindow's

		public this(Sedulous.Graphics.RenderWindow window, GuiWindowData data)
		{
			Window = window;
			Data = data;
		}
	}

	private struct Hosted
	{
		public IHostedContent Content;
		public Sedulous.Graphics.RenderWindow Window; // the window it is bound to
		public bool Routed; // its surface in the router: bound and its node shown

		public this(IHostedContent content)
		{
			Content = content;
			Window = null;
			Routed = false;
		}
	}

	private struct WindowListener
	{
		public uint32 Token;
		public WindowEventListener Listener;
		public bool Removed; // taken out while the listeners were told: deleted once they return
	}

	// The GUI's roots' places, as its drags ask them: the host's windows.
	private class Places : IRootPlaces
	{
		private GuiHost mHost;

		public this(GuiHost host)
		{
			mHost = host;
		}

		public EventDispatcher DispatcherAt(Float2 screen, out Float2 local)
		{
			let root = mHost.RootAt(screen, out local);
			return (root != null) ? root.EventDispatcher : null;
		}

		public bool ToScreen(EventDispatcher dispatcher, Float2 local, out Float2 screen)
		{
			screen = .();
			for (let attached in mHost.mAttached)
			{
				for (let pane in attached.Data.Panes)
				{
					if (pane.Root.EventDispatcher == dispatcher)
						return mHost.ToScreen(pane.Root, local, out screen);
				}
			}
			return false;
		}
	}

	// What GuiOffscreen draws with (the C++ friend): the device, shaders, fonts, baker and clear.
	internal GraphicsDevice mDevice; // borrowed
	private Sedulous.Shell.IShell mShell; // borrowed
	internal IFontService mFonts; // borrowed
	internal VgShaderSet mShaders; // borrowed modules
	private GUIContext mContext = new .() ~ _.ReleaseRef();
	private StyleManager mStyles = new .() ~ delete _;
	private ShellClipboard mClipboard = null ~ delete _;
	private Sedulous.Shell.InputRouter mRouter = null ~ delete _;
	private Sedulous.Input.InputKindTracker mInputKind = new .() ~ delete _; // the host's, from the shell's devices (K2b)
	private Sedulous.Shell.InputRouter mContentRouter = null ~ delete _; // the hosted contents' surfaces
	internal GpuPictureBaker mBaker = null ~ delete _;
	private PictureBakerSetup mBakerSetup = .();
	internal bool mBakerReady = false;
	private bool mBakesRecorded = false;
	private List<Attached> mAttached = new .() ~ delete _;
	private List<Hosted> mContents = new .() ~ delete _;
	private PointerFilter mPointerFilter = null ~ delete _;
	private Overlay mOverlay = null ~ delete _;
	private delegate void(Sedulous.Shell.DroppedFile file) mDropObserver = null ~ delete _;
	private uint32 mPressWindow = 0; // the window a held press began in
	private WindowOpener mOpener = null ~ delete _;
	private List<WindowListener> mWindowListeners = new .() ~ { for (let listener in _) delete listener.Listener; delete _; };
	private bool mTellingListeners = false;
	private uint32 mNextWindowListener = 1;
	private Places mPlaces ~ delete _;
	private List<uint32> mFocusOrder = new .() ~ delete _; // window ids, the one focused last first
	private float mUiScale = 1.0f;
	private VGBlendSpace mBlendSpace = .Encoded;
	internal Color mClear = .(0.07f, 0.07f, 0.09f, 1.0f);
	private uint64 mFramesDrawn = 0;
	private uint64 mFramesReused = 0;

	/// `fonts` is the font service the GUI's text and an SVG's text draw with; `shaders` the VG
	/// shaders (a VgShaderLibrary's), which outlive the host. All borrowed.
	public this(GraphicsDevice device, Sedulous.Shell.IShell shell, IFontService fonts, VgShaderSet shaders)
	{
		mDevice = device;
		mShell = shell;
		mFonts = fonts;
		mShaders = shaders;
		mPlaces = new .(this);
		mContext.FontService = fonts;
		mContext.RootPlaces = mPlaces; // a drag goes on from window to window
		mStyles.FontService = fonts;
		mClipboard = new .(shell);
		mRouter = new .(shell.Input);
		mContentRouter = new .(shell.Input);
		if ((mDevice.Raw != null) && mShaders.IsUsable)
		{
			mBaker = new GpuPictureBaker(mDevice.Raw, fonts);
			var setup = PictureBakerSetup();
			setup.VertexShader = mShaders.Vertex;
			setup.FragmentShader = mShaders.Fragment;
			setup.GradientRadialShader = mShaders.GradientRadial;
			setup.GradientConicShader = mShaders.GradientConic;
			setup.DistanceFieldShader = mShaders.DistanceField;
			setup.FrameCount = (int32)mDevice.FramesInFlight;
			mBakerSetup = setup; // initialized by the first window, which knows the format
		}
	}

	public ~this()
	{
		mContext.RootPlaces = null;
		for (var hosted in ref mContents)
			Unbind(ref hosted);
		mContents.Clear();
		for (let attached in mAttached)
			Forget(attached);
		mAttached.Clear();
		if (mBaker != null)
			mBaker.Dispose();
	}

	/// The GUI: its data, keymap, commands and resources. A root for a window is made with it.
	/// The host's: a root takes a reference of its own.
	public GUIContext Context => mContext;
	/// The GUI with a reference added for the caller, which releases it.
	public GUIContext ContextRef()
	{
		mContext.AddRef();
		return mContext;
	}
	/// The style manager every root is styled through: the theme, the application's sheet.
	public StyleManager Styles => mStyles;
	/// The baker every window's SVG skins draw from; null without a device or shaders. The host's.
	public GpuPictureBaker Baker => mBaker;

	/// The user's scale on every window's content scale (a preference, accessibility), 0.5 to 3.
	public float UiScale
	{
		get => mUiScale;
		set => mUiScale = Math.Clamp(value, 0.5f, 3.0f);
	}
	/// How a window attached after the call blends: Encoded (the default) as browsers and design
	/// tools do, half black over white a 50% grey, when its swapchain offers its UNORM view;
	/// Linear otherwise.
	public VGBlendSpace BlendSpace
	{
		get => mBlendSpace;
		set => mBlendSpace = value;
	}
	/// What shows behind a root that does not cover its window, as authored (sRGB).
	public void SetClearColor(Color color)
	{
		mClear = color;
	}
	/// Takes ownership of `filter` (null: none), replacing the last.
	public void SetPointerFilter(PointerFilter filter)
	{
		delete mPointerFilter;
		mPointerFilter = filter;
	}
	/// The input kind the host tracks from the shell's devices each frame and gives every pane
	/// (K2b): the pointer, the keyboard or a pad. An application reads it, or sets a starting kind.
	public Sedulous.Input.InputKindTracker InputKindTracker => mInputKind;
	/// Every pane's cursor follows its GUI again (after the application set one of its own, a
	/// boundary's resize cursor).
	public void ResetCursors()
	{
		let mouse = (mShell.Input != null) ? mShell.Input.Mouse : null;
		for (let attached in mAttached)
		{
			for (let pane in attached.Data.Panes)
				pane.Bridge.SetCursorTarget(mouse);
		}
	}
	/// Takes ownership of `overlay` (null: none), replacing the last.
	public void SetOverlay(Overlay overlay)
	{
		delete mOverlay;
		mOverlay = overlay;
	}
	/// Content its node shows that draws outside the GUI (a viewport's scene): bound, placed and
	/// recorded by the host each frame while it is added. Borrowed: remove it before it goes.
	public void AddContent(IHostedContent content)
	{
		for (let hosted in mContents)
		{
			if (hosted.Content == content)
				return;
		}
		mContents.Add(.(content));
	}
	/// Whether `content`'s input surface is routed now (bound, and its node shown).
	public bool Routes(IHostedContent content)
	{
		for (let hosted in mContents)
		{
			if (hosted.Content == content)
				return hosted.Routed;
		}
		return false;
	}
	public void RemoveContent(IHostedContent content)
	{
		for (int i < mContents.Count)
		{
			if (mContents[i].Content != content)
				continue;
			Unbind(ref mContents[i]);
			mContents.RemoveAt(i);
			return;
		}
	}
	/// Told of each file the OS drops, before the window it landed on is. Takes ownership of
	/// `observer` (null: none), replacing the last.
	public void SetDropObserver(delegate void(Sedulous.Shell.DroppedFile file) observer)
	{
		delete mDropObserver;
		mDropObserver = observer;
	}

	/// Gives `window` the root `root` (made with Context) over all of it: its canvas, renderer,
	/// targets and input. Attaching again replaces the window's panes. The host takes a reference
	/// to the root of its own (the caller keeps its).
	public void AttachWindow(Sedulous.Graphics.RenderWindow window, SceneRoot root)
	{
		if ((root == null) || (mDevice.Raw == null) || !mShaders.IsUsable)
			return;
		if (Find(window) != null)
			DetachWindow(window);
		let data = new GuiWindowData();
		data.Canvas = new .(mFonts);
		let swap = window.Swap;
		data.Encoded = (mBlendSpace == .Encoded) && (swap != null) && (swap.AlternateViewFormat != .Undefined);
		data.DrawFormat = (swap == null) ? .RGBA8UnormSrgb : (data.Encoded ? swap.AlternateViewFormat : swap.Format);
		data.Targets = MakeTargets(data.DrawFormat, window.Window.PixelWidth, window.Window.PixelHeight);
		let targets = data.Targets != null;
		data.Multisampled = targets;
		VGBlendSpace space = data.Encoded ? .Encoded : .Linear;
		var config = targets ? data.Targets.ConfigFor(space) : VGTargetConfig();
		config.BlendSpace = space;
		if (data.Renderer.Initialize(mDevice.Raw, mShaders.Vertex, mShaders.Fragment, data.DrawFormat,
			(int32)mDevice.FramesInFlight, mShaders.DistanceField, mShaders.GradientRadial, mShaders.GradientConic, config,
			mShaders.BoxShadow, mShaders.BoxVertex, mShaders.BoxFragment, mShaders.Layer, mShaders.BlurVertex,
			mShaders.BlurFragment) case .Err)
		{
			delete data;
			return;
		}
		data.Canvas.SetPerPixelGradients((mShaders.GradientRadial != null) && (mShaders.GradientConic != null));
		data.Canvas.SetAnalyticBoxes((mShaders.BoxVertex != null) && (mShaders.BoxFragment != null));
		data.Canvas.SetLayers(mShaders.Layer != null);
		data.Canvas.SetStencilFills(data.Renderer.StencilFillsSupported);

		// The bakes: the first window gives the baker its format, every window samples them.
		if (EnsureBaker(data.DrawFormat, config.BlendSpace))
			mBaker.AddTarget(data.Renderer);

		// A payload replaced while frames in flight use it: wait for them first.
		if (window.Data != null)
			mDevice.Raw.WaitIdle();
		window.Data = data;
		mAttached.Add(.(window, data));
		AddPane(window, root, .());
	}

	/// Another root in `window` (attached first), over `region` of it in its pixels (empty: all of
	/// it), with its own input; `styles` styles it when it belongs to another GUI (a tool's), else
	/// the host's do. Drawn after the window's root and the panes added before it. The host takes a
	/// reference to the root of its own; `styles` is borrowed.
	public void AddPane(Sedulous.Graphics.RenderWindow window, SceneRoot root, Rectangle region, StyleManager styles = null)
	{
		let data = Find(window);
		if ((data == null) || (root == null))
			return;
		let pane = new GuiWindowData.Pane();
		root.AddRef();
		pane.Root = root;
		pane.Region = region;
		pane.Styles = styles;
		let area = AreaOf(window, region);
		pane.Surface = new .(mShell.Input, window.Window.Id, ContentFit(InWindowUnits(window, area), .(area.Width, area.Height), .Stretch));
		mRouter.AddSurface(pane.Surface);
		pane.Bridge = new .(root.EventDispatcher);
		pane.Bridge.SetTextInputTarget(window.Window);
		if (mShell.Input != null)
			pane.Bridge.SetCursorTarget(mShell.Input.Mouse);
		pane.Bridge.SetInputKindTracker(mInputKind); // the pointer, the keys or a pad (K2b)
		root.EventDispatcher.Clipboard = mClipboard;
		root.DisplayScale = window.Window.ContentScale * mUiScale;
		root.ViewportSize = .(area.Width, area.Height);
		data.Panes.Add(pane);
		data.NeedsFrame = true;
	}

	/// Moves a pane (the window's root too) to `region` of its window (empty: all of it).
	public void SetPaneRegion(SceneRoot root, Rectangle region)
	{
		let pane = FindPane(root);
		if ((pane == null) || ((pane.Region.X == region.X) && (pane.Region.Y == region.Y) && (pane.Region.Width == region.Width) &&
			(pane.Region.Height == region.Height)))
			return; // the same again changes nothing
		pane.Region = region;
		let data = FindData(root);
		if (data != null)
			data.NeedsFrame = true;
	}

	/// Takes a pane added with AddPane out of its window.
	public void RemovePane(SceneRoot root)
	{
		for (let attached in mAttached)
		{
			for (int i = 1; i < attached.Data.Panes.Count; i++)
			{
				let pane = attached.Data.Panes[i];
				if (pane.Root != root)
					continue;
				Forget(pane);
				attached.Data.Panes.RemoveAt(i);
				delete pane;
				attached.Data.NeedsFrame = true;
				return;
			}
		}
	}

	// === Windows of its own (D6) ===

	/// How the host opens a window for a root; without one it opens none. Takes ownership of
	/// `opener`, replacing the last.
	public void SetWindowOpener(WindowOpener opener)
	{
		if (opener === mOpener)
			return;
		delete mOpener;
		mOpener = opener;
	}

	/// It opens windows of its own: it has an opener, and the shell opens windows beside the main
	/// one (not the web's one canvas).
	public bool CanOpenWindows => (mOpener != null) && (mOpener.Open != null) && (mOpener.Close != null) && Capabilities.MultipleWindows;

	/// Opens an OS window as `settings` say and gives it `root` (made with Context); the window (its
	/// opener's), or null when it opens none.
	public Sedulous.Graphics.RenderWindow OpenWindow(SceneRoot root, Sedulous.Shell.WindowSettings settings)
	{
		if (!CanOpenWindows || (root == null))
			return null;
		let window = mOpener.Open(settings);
		if (window == null)
			return null;
		AttachWindow(window, root);
		if (Find(window) == null)
		{
			mOpener.Close(window); // attaching failed: no window without its GUI
			return null;
		}
		return window;
	}

	/// Closes the window OpenWindow opened for `root`: detached, then closed by its opener.
	public void CloseWindow(SceneRoot root)
	{
		let window = WindowFor(root);
		if ((window == null) || (mOpener == null) || (mOpener.Close == null))
			return;
		DetachWindow(window);
		mOpener.Close(window);
	}

	/// Adds a listener to the windows' events (the application's, docking's), each told in the
	/// order added; the token removes it. Takes ownership of `listener`.
	public uint32 AddWindowEventListener(WindowEventListener listener)
	{
		var entry = WindowListener();
		entry.Token = mNextWindowListener;
		entry.Listener = listener;
		entry.Removed = false;
		mWindowListeners.Add(entry);
		return mNextWindowListener++;
	}

	/// One removed while the listeners are told (by itself) is told no more, and goes once they
	/// return.
	public void RemoveWindowEventListener(uint32 token)
	{
		for (int i < mWindowListeners.Count)
		{
			if ((mWindowListeners[i].Token != token) || mWindowListeners[i].Removed)
				continue;
			if (mTellingListeners)
				mWindowListeners[i].Removed = true;
			else
			{
				delete mWindowListeners[i].Listener;
				mWindowListeners.RemoveAt(i);
			}
			return;
		}
	}

	/// Whether its windows hold the places it gives them and the pointer is read across them, as
	/// the shell says (not Wayland, where a client does neither, nor the web's one canvas).
	public bool PlacesWindows => Capabilities.PlacesWindows;

	/// The screens there are, as the shell last read them (the shell's, valid until it reads them
	/// again).
	public Span<Sedulous.Shell.Screen> Screens
	{
		get
		{
			let windows = mShell.WindowManager;
			return (windows != null) ? windows.Screens : .();
		}
	}

	/// The root under `screen` (screen units), the pane on top in the window focused last where
	/// windows overlap, and the point in it (`local`, the root's pointer units); null over none.
	/// Where the host cannot place windows, every window's place is unknown: null.
	public SceneRoot RootAt(Float2 screen, out Float2 local)
	{
		local = .();
		if (!PlacesWindows)
			return null;
		for (let id in mFocusOrder) // the window focused last first
		{
			let attached = FindById(id);
			if (attached.HasValue)
			{
				let root = UnderPoint(attached.Value, screen, out local);
				if (root != null)
					return root;
			}
		}
		for (let attached in mAttached)
		{
			let root = UnderPoint(attached, screen, out local);
			if (root != null)
				return root;
		}
		return null;
	}

	public SceneRoot RootAt(Float2 screen)
	{
		Float2 local = .();
		return RootAt(screen, out local);
	}

	/// Where `local` (a point in `root`, its pointer units) is on the screen; false when the root is
	/// in no window or the host cannot place windows. (What its GUI's drags ask, as IRootPlaces.)
	public bool ToScreen(SceneRoot root, Float2 local, out Float2 screen)
	{
		screen = .();
		if (!PlacesWindows)
			return false;
		for (let attached in mAttached)
		{
			for (let pane in attached.Data.Panes)
			{
				if (pane.Root != root)
					continue;
				let window = attached.Window.Window;
				let area = AreaOf(attached.Window, pane.Region);
				let ratio = PixelsPerUnit(window); // the pane's pixels back to window units
				screen = .((float)window.X + (area.X + local.X) / ratio.X, (float)window.Y + (area.Y + local.Y) / ratio.Y);
				return true;
			}
		}
		return false;
	}

	/// Stops drawing and feeding the window's panes, and lets their roots go; its renderer forgets
	/// the bakes. The rest of the payload stays on the RenderWindow, which deletes it when it goes
	/// (after the GPU is idle).
	public void DetachWindow(Sedulous.Graphics.RenderWindow window)
	{
		for (int i < mAttached.Count)
		{
			if (mAttached[i].Window != window)
				continue;
			Forget(mAttached[i]);
			mAttached.RemoveAt(i);
			let id = window.Window.Id;
			if (mPressWindow == id)
				mPressWindow = 0;
			for (int f < mFocusOrder.Count)
			{
				if (mFocusOrder[f] == id)
				{
					mFocusOrder.RemoveAt(f);
					break;
				}
			}
			return;
		}
	}

	/// Each pane's root takes its window's size and scale now (Update does it too): an
	/// application that sizes its own nodes from a root's size calls it first, so they follow a
	/// resized window in the same frame rather than the next.
	public void SizePanes()
	{
		for (let attached in mAttached)
		{
			if (SizePanes(attached.Data, attached.Window, attached.Window.Window.ContentScale * mUiScale))
				attached.Data.NeedsFrame = true;
		}
	}

	/// Once per frame: each window's input to its panes, the GUI's clock, then every pane styled
	/// and laid out at its region's size and its window's scale, and asked whether it needs a frame
	/// (a pane of another GUI runs on that GUI's clock, which its owner advances).
	public void Update(float deltaTime)
	{
		// What the player uses now, from this frame's devices, before the panes' bridges pass it
		// on with their input (K2b).
		let devices = scope Sedulous.Input.ShellInputSource(mShell.Input);
		mInputKind.Update(devices);
		mRouter.Update();
		ReportWindowEvents();
		RouteInput();
		// By ticks: TimeSpan.FromSeconds would round to whole milliseconds.
		mContext.Update(TimeSpan((int64)((double)deltaTime * (double)TimeSpan.TicksPerSecond)));
		for (let attached in mAttached)
		{
			let data = attached.Data;
			let window = attached.Window;
			let scale = window.Window.ContentScale * mUiScale;
			bool needs = SizePanes(data, window, scale) || data.NeedsFrame;
			for (let pane in data.Panes)
			{
				StyleAndLayOut(pane.Root, pane.Styles);
				needs = pane.Root.NeedsFrame() || needs;
			}
			data.NeedsFrame = needs;
		}
		PlaceContents();
		// Placing can change what a node shows after the panes were asked (a viewport made again at
		// a new size frees the image the last batch drew): such a window draws again, never reuses.
		for (let attached in mAttached)
		{
			for (let pane in attached.Data.Panes)
			{
				if (pane.Root.NeedsRedraw)
					attached.Data.NeedsFrame = true;
			}
		}
		mBakesRecorded = false;
	}

	/// Draws `frame`'s window: its panes when any needs a frame (else the batch drawn last) and the
	/// overlay, the baker's queue (once a frame, before any pass samples it), the layers, then the
	/// pass.
	public void RenderWindow(ref FrameContext frame)
	{
		if (!frame.Valid || (frame.Encoder == null))
			return;
		let data = Find(frame.Window);
		if (data == null)
			return;
		if (data.NeedsFrame)
		{
			data.Canvas.Clear();
			let context = scope DrawContext(data.Canvas);
			for (let pane in data.Panes)
			{
				let area = AreaOf(frame.Window, pane.Region);
				data.Canvas.PushState();
				data.Canvas.Translate(area.X, area.Y);
				let paneContext = scope DrawContext(data.Canvas);
				pane.Root.DrawFrame(paneContext);
				data.Canvas.PopState();
			}
			if (mOverlay != null)
				mOverlay(frame.Window, context);
			data.NeedsFrame = false;
			mFramesDrawn++;
		}
		else
			mFramesReused++;
		if ((mBaker != null) && mBakerReady && !mBakesRecorded)
		{
			mBaker.Record(frame.Encoder, (int32)frame.FrameIndex);
			mBakesRecorded = true;
		}
		// What the window's nodes show from outside the GUI, drawn before the GUI samples it.
		for (let hosted in mContents)
		{
			let node = hosted.Content.HostedNode;
			if ((hosted.Window == frame.Window) && (node != null) && node.IsTreeVisible)
				hosted.Content.Record(frame.Encoder, (int32)frame.FrameIndex);
		}
		// Every size a window's drawing depends on, once per frame size: on a scaled display the
		// window's units, its pixels, the swapchain and the root's viewport must agree to fill it.
		if ((frame.Width != data.LoggedWidth) || (frame.Height != data.LoggedHeight))
		{
			data.LoggedWidth = frame.Width;
			data.LoggedHeight = frame.Height;
			let os = frame.Window.Window;
			let root = data.Root;
			let swap = frame.Window.Swap;
			GlobalLog(.Information, "GUI: window {}: {}x{} units, {}x{} pixels, content scale {}; frame {}x{}; swapchain {}x{}; root viewport {}x{}, size {}x{}, display scale {}",
				os.Id, os.Width, os.Height, os.PixelWidth, os.PixelHeight, os.ContentScale, frame.Width, frame.Height,
				(swap != null) ? swap.Width : 0, (swap != null) ? swap.Height : 0,
				(root != null) ? root.ViewportSize.X : 0.0f, (root != null) ? root.ViewportSize.Y : 0.0f,
				(root != null) ? root.Size.X : 0.0f, (root != null) ? root.Size.Y : 0.0f,
				(root != null) ? root.DisplayScale : 0.0f);
		}
		let batch = data.Canvas.GetBatch();
		let slot = (int32)frame.FrameIndex;
		data.Renderer.BeginFrame(slot);
		let slice = data.Renderer.Prepare(batch, slot, frame.Width, frame.Height);
		data.Renderer.RenderLayers(frame.Encoder, slot, slice);
		let clear = ClearFor(data.Encoded);
		let view = data.Encoded ? frame.BackbufferAlternateView : frame.BackbufferView;
		// The targets follow the backbuffer this frame draws into, not the window: while a window
		// is resized its swapchain need not match it, and a pass resolves only into its own size.
		// New ones are made at once and the old retired, freed once the frames in flight that drew
		// into them are done: no wait for the GPU, which on the web would yield to the browser with
		// the canvas's texture taken.
		RetireTargets(data);
		if (data.Multisampled && ((data.Targets == null) || !data.Targets.Matches(frame.Width, frame.Height)))
		{
			if (data.Targets != null)
				data.Retired.Add(new GuiWindowData.RetiredTargets(data.Targets, mDevice.FramesInFlight));
			data.Targets = MakeTargets(data.DrawFormat, frame.Width, frame.Height);
		}
		if ((data.Targets != null) && data.Targets.Matches(frame.Width, frame.Height))
		{
			let pass = data.Targets.BeginPass(frame.Encoder, view, clear, "GUI");
			if (let encoder = frame.Encoder.BeginRenderPass(pass))
			{
				data.Renderer.Render(encoder, frame.Width, frame.Height, slot, slice);
				encoder.End();
			}
			return;
		}
		// A renderer made for the multisampled pass cannot draw the plain one (its pipelines'
		// sample count is the targets'): with no targets at this size the frame is only cleared,
		// and the next draws again.
		if (let backbufferPass = frame.BeginBackbufferPass(clear, view))
		{
			if (!data.Multisampled)
				data.Renderer.Render(backbufferPass, frame.Width, frame.Height, slot, slice);
			else
				data.NeedsFrame = true;
		}
		frame.EndBackbufferPass();
	}

	/// The multisampled targets `window`'s GUI draws into, sized to its backbuffer as each frame
	/// draws; null when it has none (a plain single-sampled pass). The window's.
	public VGPassTargets PassTargetsFor(Sedulous.Graphics.RenderWindow window)
	{
		let data = Find(window);
		return ((data != null) && data.Multisampled) ? data.Targets : null;
	}

	/// How many replaced targets `window` still keeps for the frames in flight.
	public int RetiredTargetsFor(Sedulous.Graphics.RenderWindow window)
	{
		let data = Find(window);
		return (data != null) ? data.Retired.Count : 0;
	}

	/// The renderer drawing `window`'s GUI (where a viewport registers its target); null when it has
	/// none. The window's.
	public VGRenderer RendererFor(Sedulous.Graphics.RenderWindow window)
	{
		let data = Find(window);
		return (data != null) ? data.Renderer : null;
	}

	/// The window `root` is a pane of (its root or another); null when it is in none.
	public Sedulous.Graphics.RenderWindow WindowFor(SceneRoot root)
	{
		for (let attached in mAttached)
		{
			for (let pane in attached.Data.Panes)
			{
				if (pane.Root == root)
					return attached.Window;
			}
		}
		return null;
	}

	/// Where `root` draws in its window's pixels; empty when it is in none.
	public Rectangle PaneArea(SceneRoot root)
	{
		for (let attached in mAttached)
		{
			for (let pane in attached.Data.Panes)
			{
				if (pane.Root == root)
					return AreaOf(attached.Window, pane.Region);
			}
		}
		return .();
	}

	public int WindowCount => mAttached.Count;

	/// Styles `root` through `styles` (null: the host's) and lays it out, as Update does each
	/// pane's: for a root drawn elsewhere (offscreen).
	public void StyleAndLayOut(SceneRoot root, StyleManager styles = null)
	{
		let manager = (styles != null) ? styles : mStyles;
		manager.MediaContext = root.MediaContext;
		manager.ApplyTree(root);
		root.UpdateLayout();
	}

	/// Frames a window's panes were drawn in, and frames a window encoded its last batch again.
	public uint64 FramesDrawn => mFramesDrawn;
	public uint64 FramesReused => mFramesReused;

	private Sedulous.Shell.WindowCapabilities Capabilities
	{
		get
		{
			let windows = mShell.WindowManager;
			return (windows != null) ? windows.Capabilities : .(false, false);
		}
	}

	// The panes' roots at their regions' sizes and the window's scale; whether one changed.
	private bool SizePanes(GuiWindowData data, Sedulous.Graphics.RenderWindow window, float scale)
	{
		bool changed = false;
		for (let pane in data.Panes)
		{
			let root = pane.Root;
			let area = AreaOf(window, pane.Region);
			if (root.DisplayScale != scale)
				root.DisplayScale = scale;
			let size = root.ViewportSize;
			if ((size.X != area.Width) || (size.Y != area.Height))
			{
				root.ViewportSize = .(area.Width, area.Height);
				changed = true;
			}
		}
		return changed;
	}

	// The baker's renderer takes the first target's format and blend space; false without one.
	internal bool EnsureBaker(TextureFormat format, VGBlendSpace space)
	{
		if (mBaker == null)
			return false;
		if (!mBakerReady)
		{
			mBakerSetup.Format = format;
			mBakerSetup.BlendSpace = space;
			mBakerReady = mBaker.Initialize(mBakerSetup) case .Ok;
			if (mBakerReady)
				mContext.PictureBaker = mBaker;
		}
		return mBakerReady;
	}

	// A pane's area in its window's pixels (a region is given in them too): all of the window by
	// default. The GUI lays out to it and draws into the swapchain at the same size, so a scaled
	// display (more pixels than window units) is filled, not drawn into a corner.
	private static Rectangle AreaOf(Sedulous.Graphics.RenderWindow window, Rectangle region)
	{
		if ((region.Width > 0.0f) && (region.Height > 0.0f))
			return region;
		return .(0.0f, 0.0f, (float)window.Window.PixelWidth, (float)window.Window.PixelHeight);
	}

	// How many of the window's pixels a window unit holds, across and down (1 on an unscaled display).
	private static Float2 PixelsPerUnit(Sedulous.Shell.IWindow window)
	{
		let w = (float)window.Width;
		let h = (float)window.Height;
		return .((w > 0.0f) ? (float)window.PixelWidth / w : 1.0f, (h > 0.0f) ? (float)window.PixelHeight / h : 1.0f);
	}

	// A pane's area in window units, where the pointer arrives.
	private static Rectangle InWindowUnits(Sedulous.Graphics.RenderWindow window, Rectangle area)
	{
		let ratio = PixelsPerUnit(window.Window);
		return .(area.X / ratio.X, area.Y / ratio.Y, area.Width / ratio.X, area.Height / ratio.Y);
	}

	// A window's multisampled targets at `width` x `height`, the caller's; null when the device
	// takes none.
	private VGPassTargets MakeTargets(TextureFormat format, uint32 width, uint32 height)
	{
		let targets = new VGPassTargets();
		targets.Configure(mDevice.Raw);
		if (!targets.Create(format, width, height))
		{
			delete targets;
			return null;
		}
		return targets;
	}

	// One of `data`'s frames begins: the retired targets age, those no frame in flight uses go.
	private static void RetireTargets(GuiWindowData data)
	{
		for (int i = data.Retired.Count; i > 0; i--)
		{
			let retired = data.Retired[i - 1];
			let left = retired.FramesLeft;
			retired.FramesLeft = (left > 0) ? (left - 1) : 0;
			if (left <= 1)
			{
				data.Retired.RemoveAt(i - 1);
				delete retired;
			}
		}
	}

	private GuiWindowData Find(Sedulous.Graphics.RenderWindow window)
	{
		for (let attached in mAttached)
		{
			if (attached.Window == window)
				return attached.Data;
		}
		return null;
	}

	private Attached? FindById(uint32 id)
	{
		if (id == 0)
			return null;
		for (let attached in mAttached)
		{
			if (attached.Window.Window.Id == id)
				return attached;
		}
		return null;
	}

	private GuiWindowData.Pane FindPane(SceneRoot root)
	{
		for (let attached in mAttached)
		{
			for (let pane in attached.Data.Panes)
			{
				if (pane.Root == root)
					return pane;
			}
		}
		return null;
	}

	private GuiWindowData FindData(SceneRoot root)
	{
		for (let attached in mAttached)
		{
			for (let pane in attached.Data.Panes)
			{
				if (pane.Root == root)
					return attached.Data;
			}
		}
		return null;
	}

	// The pane on top of `attached`'s window under `screen`, if the point is in the window and it
	// is not minimised.
	private SceneRoot UnderPoint(Attached attached, Float2 screen, out Float2 local)
	{
		local = .();
		let window = attached.Window.Window;
		// The screen is in window units; the panes are in the window's pixels.
		let ratio = PixelsPerUnit(window);
		let at = Float2((screen.X - (float)window.X) * ratio.X, (screen.Y - (float)window.Y) * ratio.Y);
		if ((at.X < 0.0f) || (at.Y < 0.0f) || (at.X >= (float)window.PixelWidth) || (at.Y >= (float)window.PixelHeight) || window.IsMinimized)
			return null;
		for (int i = attached.Data.Panes.Count; i > 0; i--) // the pane drawn last is on top
		{
			let pane = attached.Data.Panes[i - 1];
			let area = AreaOf(attached.Window, pane.Region);
			if ((at.X >= area.X) && (at.Y >= area.Y) && (at.X < area.X + area.Width) && (at.Y < area.Y + area.Height))
			{
				local = .(at.X - area.X, at.Y - area.Y);
				return pane.Root;
			}
		}
		return null;
	}

	// Each content bound to the window its node is in (again when that changes), and placed over
	// its node; then their router, so the application reads what it gates this frame. A content
	// whose node is not shown (a page behind another tab) leaves the router until it is: it keeps
	// the place it had, the shown one's, and the router's last match would give it the pointer
	// meant for what is in front.
	private void PlaceContents()
	{
		for (var hosted in ref mContents)
		{
			let node = hosted.Content.HostedNode;
			let root = (node != null) ? node.SceneRoot : null;
			let window = (root != null) ? WindowFor(root) : null;
			if (window != hosted.Window)
			{
				Unbind(ref hosted);
				if (window != null)
				{
					hosted.Content.Bind(mDevice.Raw, RendererFor(window), mShell.Input, window.Window.Id);
					hosted.Window = window;
				}
			}
			if (window == null)
				continue;
			let shown = node.IsTreeVisible;
			Route(ref hosted, shown);
			if (!shown)
				continue; // its targets kept for when it shows again
			let pane = PaneArea(root);
			let bounds = node.ScreenBounds; // the root's device pixels
			let pixels = Rectangle(pane.X + bounds.X, pane.Y + bounds.Y, bounds.Width, bounds.Height);
			hosted.Content.Place(pixels, InWindowUnits(window, pixels), .((float)window.Window.Width, (float)window.Window.Height));
		}
		mContentRouter.Update();
	}

	// Its surface in the content router (`on`) or out of it.
	private void Route(ref Hosted hosted, bool on)
	{
		let surface = hosted.Content.HostedSurface;
		if ((surface == null) || (hosted.Routed == on))
			return;
		if (on)
			mContentRouter.AddSurface(surface);
		else
			mContentRouter.RemoveSurface(surface);
		hosted.Routed = on;
	}

	private void Unbind(ref Hosted hosted)
	{
		if (hosted.Window == null)
			return;
		Route(ref hosted, false);
		hosted.Content.Bind(mDevice.Raw, null, mShell.Input, 0);
		hosted.Window = null;
	}

	private void Forget(GuiWindowData.Pane pane)
	{
		mRouter.RemoveSurface(pane.Surface);
		pane.Bridge.SetTextInputTarget(null); // the window may close after this
	}

	// A window leaves: its panes' roots are let go now (the trees may hold widgets showing models
	// their application frees next), its renderer forgets the bakes, and its hosted contents let it
	// go; the GPU half of the payload stays with the RenderWindow until the GPU is done with it.
	private void Forget(Attached attached)
	{
		for (let pane in attached.Data.Panes)
			Forget(pane);
		ClearAndDeleteItems!(attached.Data.Panes);
		for (var hosted in ref mContents) // their window goes: they let its renderer go
		{
			if (hosted.Window == attached.Window)
				Unbind(ref hosted);
		}
		if (mBaker != null)
			mBaker.RemoveTarget(attached.Data.Renderer);
	}

	// What happened to the windows it serves since the last pump: the focus order kept (where
	// windows overlap, the one focused last is on top), and each told by its root.
	private void ReportWindowEvents()
	{
		let windows = mShell.WindowManager;
		if (windows == null)
			return;
		// A copy: a listener may open or close windows, and the manager's list with them.
		let events = scope List<Sedulous.Shell.WindowEvent>();
		events.AddRange(windows.Events);
		for (let event in events)
		{
			let attached = FindById(event.WindowId);
			if (!attached.HasValue || attached.Value.Data.Panes.IsEmpty)
				continue;
			if (event.Type == .FocusGained)
			{
				for (int f < mFocusOrder.Count)
				{
					if (mFocusOrder[f] == event.WindowId)
					{
						mFocusOrder.RemoveAt(f);
						break;
					}
				}
				mFocusOrder.Insert(0, event.WindowId);
			}
			let root = attached.Value.Data.Panes[0].Root; // a listener may close it: held meanwhile
			root.AddRef();
			defer root.ReleaseRef();
			let wasTelling = mTellingListeners;
			mTellingListeners = true;
			for (int l = 0; l < mWindowListeners.Count; l++) // by place: one added meanwhile is told too
			{
				if (!mWindowListeners[l].Removed)
					mWindowListeners[l].Listener(root, event);
			}
			mTellingListeners = wasTelling;
			if (!mTellingListeners)
			{
				for (int l = 0; l < mWindowListeners.Count;)
				{
					if (mWindowListeners[l].Removed)
					{
						delete mWindowListeners[l].Listener;
						mWindowListeners.RemoveAt(l);
					}
					else
						l++;
				}
			}
		}
	}

	private void RouteInput()
	{
		let input = mShell.Input;
		if ((input == null) || mAttached.IsEmpty)
			return;
		// The pointer: the window a press began in while any button is held, and on the frame they
		// are let go (wherever the pointer is then: outside every window, over another), else the
		// one under it.
		bool held = false;
		let mouse = input.Mouse;
		if (mouse != null)
		{
			held = mouse.IsButtonDown(.Left) || mouse.IsButtonDown(.Middle) || mouse.IsButtonDown(.Right);
			mouse.SetGlobalCapture(held); // its events keep coming past the window's edge
		}
		var pointer = FindById(mPressWindow);
		if (!pointer.HasValue)
			pointer = FindById(input.HoverWindow);
		if (!pointer.HasValue && (mAttached.Count == 1))
			pointer = mAttached[0];
		if (pointer.HasValue)
		{
			let window = pointer.Value.Window;
			let size = Float2((float)window.Window.Width, (float)window.Window.Height);
			for (let pane in pointer.Value.Data.Panes)
			{
				// The pointer arrives in window units; the pane lays out in pixels, so the surface maps
				// the one to the other.
				let area = AreaOf(window, pane.Region);
				pane.Surface.SetRegion(InWindowUnits(window, area));
				pane.Surface.SetWindowSize(size); // places fingers
				pane.Surface.SetContentSize(.(area.Width, area.Height));
				if ((mPointerFilter == null) || !mPointerFilter(pane.Root, pane.Surface))
					pane.Bridge.PumpFromSurface(pane.Surface);
			}
			if (held && (mPressWindow == 0))
				mPressWindow = window.Window.Id;
		}
		if (!held)
			mPressWindow = 0; // its release was routed above
		// Keys, text and the gamepad: the focused window's pane clicked last, else its first.
		var focused = FindById(input.FocusedWindow);
		if (!focused.HasValue)
			focused = mAttached[0];
		let panes = focused.Value.Data.Panes;
		GuiWindowData.Pane keys = panes.IsEmpty ? null : panes[0];
		for (int i = 1; i < panes.Count; i++)
		{
			if (panes[i].Surface.Focused)
				keys = panes[i];
		}
		if (keys != null)
		{
			for (let event in input.Events)
			{
				switch (event.Kind)
				{
				case .KeyDown, .KeyUp, .TextInput, .GamepadButtonDown, .GamepadButtonUp, .GamepadAxis:
					keys.Bridge.Dispatch(event);
				default:
				}
			}
		}
		// Files the OS dropped: the window they landed on (its root). Drained, they are the host's.
		let drops = scope List<Sedulous.Shell.DroppedFile>();
		defer { ClearAndDeleteItems!(drops); }
		mShell.DrainDroppedFiles(drops);
		if (mDropObserver != null)
		{
			for (let drop in drops)
				mDropObserver(drop);
		}
		if (!drops.IsEmpty)
		{
			for (let attached in mAttached)
			{
				if (!attached.Data.Panes.IsEmpty)
					attached.Data.Panes[0].Bridge.DispatchFileDrops(.(drops.Ptr, drops.Count), attached.Window.Window.Id);
			}
		}
	}

	// The clear colour for a window: as authored when it blends encoded, else in linear light (an
	// sRGB target encodes what a pass clears to).
	private ClearColor ClearFor(bool encoded)
	{
		if (encoded)
			return .(mClear.R, mClear.G, mClear.B, mClear.A);
		return .(SrgbToLinear(mClear.R), SrgbToLinear(mClear.G), SrgbToLinear(mClear.B), mClear.A);
	}
}
