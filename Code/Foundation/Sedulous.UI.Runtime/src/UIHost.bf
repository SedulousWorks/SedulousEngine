using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Graphics;
using Sedulous.Image;
using Sedulous.RHI;
using Sedulous.Shaders;
using Sedulous.Shell;
using Sedulous.UI;
using Sedulous.UI.Shell;
using Sedulous.VG;
using Sedulous.VG.Renderer;

namespace Sedulous.UI.Runtime;

/// Draws the UI on the runtime's multi-window graphics host.
///
/// ONE context with one root view per window: the context is what makes focus, popups and
/// drag-and-drop cross windows, and each window brings its own vector context, renderer and
/// input surface.
///
/// TOOLKIT FREE by design. It renders any root view, so a single-window game and a
/// multi-window editor share it; the docking workbench sits above this and is the only thing
/// that pulls the toolkit in.
///
/// An application owns one of these, attaches its window once, then calls Update from its
/// update and RenderWindow from its render. No bespoke swap chain or vector bring-up in the
/// application at all.
class UIHost
{
	/// The user's scale preference, multiplied onto each window's OS content scale. Bounded so
	/// a bad setting cannot make the UI unusable.
	private const float MinUiScale = 0.5f;
	private const float MaxUiScale = 3.0f;

	/// BORROWED: the device, the shell and the font service all outlive the host.
	private GraphicsDevice mDevice;
	private IShell mShell;
	private IFontService mFonts;

	/// OWNED: the shader host owns the vector modules, and the rest are the host's own.
	private ShaderSystemHost mShaderHost = new .() ~ delete _;
	private UIContext mContext = new .() ~ delete _;
	private InputRouter mRouter = null ~ delete _;
	private UIInputBridge mBridge = null ~ delete _;
	private ShellClipboard mClipboard = null ~ delete _;

	/// BORROWED from the shader host.
	private IShaderModule mVertexShader = null;
	private IShaderModule mFragmentShader = null;
	private IShaderModule mGradientRadialShader = null;
	private IShaderModule mGradientConicShader = null;
	private IShaderModule mDistanceFieldShader = null;
	private IShaderModule mBoxShadowShader = null;

	private List<AttachedWindow> mAttached = new .() ~ delete _;

	/// The baked icon atlases. OWNED here; the drawables' variants borrow them.
	private List<OwnedImageData> mBakedIconAtlases = new .() ~ DeleteContainerAndItems!(_);
	private bool mThemeIconsBaked = false;

	private bool mDamageGateEnabled = true;
	/// Frame scoped: decided in Update, read by RenderWindow.
	private bool mFrameDamaged = true;
	private uint64 mFramesDrawn = 0;
	private uint64 mFramesSkipped = 0;
	private uint64 mFramesLaidOut = 0;

	/// Frames seen with the button up while a drag was still latched. See the watchdog.
	private uint32 mDragReleaseMissedFrames = 0;

	private float mUiScale = 1.0f;
	/// Near black, stored LINEAR. See SetClearColor for why.
	private ClearColor mClearColor = .(0.006f, 0.006f, 0.009f, 1.0f);

	public this(GraphicsDevice device, IShell shell, IFontService fonts)
	{
		mDevice = device;
		mShell = shell;
		mFonts = fonts;

		mRouter = new InputRouter(shell.Input);
		mBridge = new UIInputBridge(mContext);
		mClipboard = new ShellClipboard(shell);
		mContext.SetClipboard(mClipboard);
		mContext.SetFontService(fonts);

		InitShaders();
	}

	// ---- The shared context -------------------------------------------------------------------

	/// The one context every window's root lives in. Set the theme on it, ask it about focus.
	public UIContext Context => mContext;

	public float UiScale => mUiScale;

	/// The user's scale preference. Roots pick it up on the next Update; a caller with baked
	/// icon sets re-bakes them itself at the new effective scale.
	public void SetUiScale(float scale)
	{
		mUiScale = Clamp(scale, MinUiScale, MaxUiScale);
	}

	/// The background behind the UI, taken as AUTHORED in sRGB like every other UI colour.
	///
	/// Stored linearised, because a pass's clear value is interpreted as linear and hardware
	/// encoded on store, while the UI's own vertex path linearises for itself. Without this
	/// the background clears visibly LIGHTER than the same colour drawn by the UI, which a
	/// mostly bare screen shows loudest.
	public void SetClearColor(float r, float g, float b, float a = 1.0f)
	{
		mClearColor = .(SrgbToLinear(r), SrgbToLinear(g), SrgbToLinear(b), a);
	}

	private static float SrgbToLinear(float channel)
	{
		if (channel <= 0.04045f)
			return channel / 12.92f;

		return Pow((channel + 0.055f) / 1.055f, 2.4f);
	}

	// ---- The damage gate ----------------------------------------------------------------------

	/// The gate's escape hatch. Off is the old behaviour: relayout and redraw every frame.
	public void SetDamageGatingEnabled(bool enabled) => mDamageGateEnabled = enabled;
	public bool DamageGatingEnabled => mDamageGateEnabled;

	public uint64 FramesDrawn => mFramesDrawn;
	public uint64 FramesSkipped => mFramesSkipped;
	/// Frames that ALSO re-measured and re-laid out. A subset of FramesDrawn, and the gap
	/// between them is the visual-only frames: a hover, a press, a caret blinking over a
	/// layout that is still valid.
	public uint64 FramesLaidOut => mFramesLaidOut;

	// ---- Windows ------------------------------------------------------------------------------

	/// Gives a render window a root view, building everything that window needs and stashing
	/// it on the window itself. CONSUMES the caller's reference to the root.
	public void AttachWindow(RenderWindow window, RootView root)
	{
		if ((window == null) || (root == null))
		{
			root?.ReleaseRef();
			return;
		}

		// The first window means the device is live, so the shared chrome glyphs can be baked.
		// A scale-aware host re-bakes on a DPI change.
		if (!mThemeIconsBaked)
			BakeThemeIcons(mUiScale);

		let data = new UIWindowData();
		data.Root = root;
		data.Device = mDevice.Raw;

		BuildWindowRenderer(data, window);
		BuildWindowSurface(data, window);

		mContext.AddRootView(root);
		mRouter.AddSurface(data.Surface);
		mBridge.SetTextInputTarget(window.Window);

		// RE-attaching swaps a window's root, which destroys the PREVIOUS payload - and that
		// payload's renderer still has pipelines and buffers the in-flight frames reference.
		// Idle first, or replacing a root spews in-use errors and can crash.
		if ((window.Data != null) && (mDevice.Raw != null))
			mDevice.Raw.WaitIdle();

		window.Data = data;
		mAttached.Add(.(window, data));
	}

	private void BuildWindowRenderer(UIWindowData data, RenderWindow window)
	{
		// Per-pixel gradients only when BOTH shaders resolved: a pre-cooked pack may predate
		// them, and then the context falls back to the affine lookup rather than half working.
		let perPixelGradients = (mGradientRadialShader != null) && (mGradientConicShader != null);

		// The renderer's pipelines must MATCH the pass, so the target configuration is decided
		// before the renderer is initialised, and any failure falls back wholesale.
		data.DepthStencilFormat = VGRenderer.PickStencilCapableFormat(data.Device,
			UIWindowData.MsaaSamples);

		let targetsOk = data.CreateTargets(window.Swap.Format, window.Window.Width,
			window.Window.Height);

		var targetConfig = VGTargetConfig();
		if (targetsOk)
		{
			targetConfig.SampleCount = UIWindowData.MsaaSamples;
			targetConfig.DepthStencilFormat = data.DepthStencilFormat;
		}

		data.Renderer.Initialize(mDevice.Raw, mVertexShader, mFragmentShader, window.Swap.Format,
			(int32)mDevice.FramesInFlight, mDistanceFieldShader, mGradientRadialShader,
			mGradientConicShader, targetConfig, mBoxShadowShader);

		data.VG.SetPerPixelGradients(perPixelGradients);
		data.VG.SetStencilFills(data.Renderer.StencilFillsSupported);
	}

	private void BuildWindowSurface(UIWindowData data, RenderWindow window)
	{
		let width = (float)window.Window.Width;
		let height = (float)window.Window.Height;

		data.Surface = new InputSurface(mShell.Input, window.Window.Id,
			ContentFit(.(0, 0, width, height), .(width, height), .Stretch));

		data.Root.ViewportSize = .(width, height);
		data.Root.DpiScale = window.Window.ContentScale * mUiScale;
	}

	/// Stops routing input to a window and takes its root out of the context, so nothing draws
	/// or hit tests it any more.
	///
	/// The GPU payload is deliberately LEFT on the render window. Freeing it here would race
	/// the GPU, since nothing has idled; it goes when the host destroys the window, which
	/// idles first. So a docking teardown is DetachWindow followed by the host closing it.
	public void DetachWindow(RenderWindow window)
	{
		for (int i < mAttached.Count)
		{
			if (mAttached[i].Window != window)
				continue;

			let data = mAttached[i].Data;

			// A detached root gets no input and no ticks, so its open popups could never
			// dismiss: they would still be showing if it were re-attached later.
			if (let popups = data.Root.GetPopupLayer())
				popups.CloseAllPopups();

			mRouter.RemoveSurface(data.Surface);
			mContext.RemoveRootView(data.Root);
			mAttached.RemoveAt(i);
			return;
		}
	}

	/// The per-window renderer for an attached window, or null.
	///
	/// Exposed so an application can register an external texture - a viewport's offscreen
	/// target, say - into the SAME renderer that draws that window's UI, which is what lets
	/// the UI sample it.
	public VGRenderer RendererFor(RenderWindow window)
	{
		let data = Find(window);
		return (data != null) ? data.Renderer : null;
	}

	/// The window a root view is attached to, or null.
	public RenderWindow WindowForRoot(RootView root)
	{
		if (root == null)
			return null;

		for (let attached in mAttached)
		{
			if (attached.Data.Root == root)
				return attached.Window;
		}
		return null;
	}

	private UIWindowData Find(RenderWindow window)
	{
		for (let attached in mAttached)
		{
			if (attached.Window == window)
				return attached.Data;
		}
		return null;
	}

	private int FindIndexByWindowId(uint32 windowId)
	{
		for (int i < mAttached.Count)
		{
			if (mAttached[i].Window.Window.Id == windowId)
				return i;
		}
		return -1;
	}

	// ---- The frame ----------------------------------------------------------------------------

	/// Once per frame: pump each window's input, tick the context, lay out every root.
	public void Update(float deltaTime)
	{
		mRouter.Update();
		WatchForMissedDragRelease();
		PumpInput();
		DispatchKeyboard();
		SyncGlobalCapture();

		mContext.BeginFrame(deltaTime);
		RunDamageGate();
	}

	/// Catches a drag whose RELEASE never arrived.
	///
	/// A cross-window drag can lose its button-up: the release happens over a window the drag
	/// did not start in, and nothing routes it back. The drag would then latch forever, with
	/// the adorner following the cursor and no way to put it down.
	///
	/// A full frame of the button being up while still dragging is the signal. The release is
	/// replayed at the cursor first, so a drop target that should have had it still gets it;
	/// only a drag that is STILL latched after that is cancelled outright.
	private void WatchForMissedDragRelease()
	{
		let dragDrop = mContext.DragDrop;
		let mouse = (mShell.Input != null) ? mShell.Input.Mouse : null;

		if (!dragDrop.IsDragging || (mouse == null) || mouse.IsButtonDown(.Left))
		{
			mDragReleaseMissedFrames = 0;
			return;
		}

		// ONE full frame, not the first sight of it: the release and the drag state are
		// observed at different points in a frame, so a single reading can disagree harmlessly.
		if (mDragReleaseMissedFrames++ < 1)
			return;

		let index = FindActiveIndex();
		if (index >= 0)
			PumpWindowAtGlobal(ref mAttached[index]);

		if (dragDrop.IsDragging)
			dragDrop.CancelDrag();

		mDragReleaseMissedFrames = 0;
	}

	/// The pointer goes to ONE window per frame. A captured interaction or a drag keeps it
	/// where it started; otherwise it follows the hover.
	private void PumpInput()
	{
		let dragging = mContext.DragDrop.IsDragging;
		let captured = mContext.GetFocusManager().CapturedView != null;

		if (dragging || captured)
		{
			// While captured, the surface freezes its position once the cursor leaves, so the
			// window is pumped at LIVE desktop coordinates instead. Otherwise a resize or a
			// drag stalls at the window edge and a release outside it is lost entirely.
			let index = FindActiveIndex();
			if (index >= 0)
				PumpWindowAtGlobal(ref mAttached[index]);

			return;
		}

		let hoverId = (mShell.Input != null) ? mShell.Input.HoverWindow : 0;
		var index = FindIndexByWindowId(hoverId);
		if ((index < 0) && !mAttached.IsEmpty)
			index = 0;

		if (index < 0)
			return;

		let attached = mAttached[index];
		SyncSurfaceToWindow(attached);
		mContext.SetActiveInputRoot(attached.Data.Root);
		mBridge.PumpFromSurface(attached.Data.Surface);
	}

	private int FindActiveIndex()
	{
		let active = mContext.ActiveInputRoot;
		for (int i < mAttached.Count)
		{
			if (mAttached[i].Data.Root == active)
				return i;
		}
		return mAttached.IsEmpty ? -1 : 0;
	}

	private void SyncSurfaceToWindow(AttachedWindow attached)
	{
		let width = (float)attached.Window.Window.Width;
		let height = (float)attached.Window.Window.Height;
		attached.Data.Surface.SetRegion(.(0, 0, width, height));
		attached.Data.Surface.SetContentSize(.(width, height));
	}

	/// Keys, text and the IME follow the FOCUSED window rather than the hovered one: typing
	/// goes where the operating system says the keyboard is, not where the pointer happens to
	/// rest.
	private void DispatchKeyboard()
	{
		let input = mShell.Input;
		if (input == null)
			return;

		var index = FindIndexByWindowId(input.FocusedWindow);
		if ((index < 0) && !mAttached.IsEmpty)
			index = 0;

		if (index >= 0)
		{
			mContext.SetActiveInputRoot(mAttached[index].Data.Root);
			mBridge.SetTextInputTarget(mAttached[index].Window.Window);
		}

		for (let e in input.Events)
		{
			switch (e.Kind)
			{
			case .KeyDown, .KeyUp, .TextInput:
				mBridge.Dispatch(e);
			default:
			}
		}
	}

	/// Keeps mouse events flowing across window edges during a drag or a captured interaction.
	///
	/// Without an application-global capture the operating system stops delivering once the
	/// cursor leaves the window, which stalls a multi-window drag at the edge and loses a
	/// release that happens outside.
	private void SyncGlobalCapture()
	{
		if (mShell.Input == null)
			return;

		let mouse = mShell.Input.Mouse;
		if (mouse == null)
			return;

		let capturing = mContext.DragDrop.IsDragging ||
			(mContext.GetFocusManager().CapturedView != null);

		mouse.SetGlobalCapture(capturing);

		// A borderless float has no window manager to draw resize grips, so the cursor under
		// the pointer is pushed to the OS here.
		mBridge.SyncCursor(mouse);
	}

	/// One frame-scoped decision for EVERY window.
	///
	/// When nothing invalidated, and no window resized or changed scale, both the layout and
	/// the draw-tree walk are skipped: RenderWindow re-encodes the retained batch, so the
	/// present pipeline is untouched and nothing flickers.
	private void RunDamageGate()
	{
		let structural = SyncRootsToWindows();

		mFrameDamaged = !mDamageGateEnabled || structural || mContext.NeedsRedraw ||
			mContext.NeedsLayout;

		if (!mFrameDamaged)
		{
			mFramesSkipped++;
			return;
		}

		mFramesDrawn++;

		if (structural || mContext.NeedsLayout)
		{
			mFramesLaidOut++;
			for (let attached in mAttached)
				mContext.UpdateRootView(attached.Data.Root);
		}

		mContext.ClearLayoutDamage();
	}

	/// Brings each root into line with its window, answering whether anything MOVED - a resize
	/// or a scale change forces a layout however quiet the UI was.
	private bool SyncRootsToWindows()
	{
		var structural = false;

		for (let attached in mAttached)
		{
			let width = (float)attached.Window.Window.Width;
			let height = (float)attached.Window.Window.Height;
			let dpi = attached.Window.Window.ContentScale * mUiScale;
			let root = attached.Data.Root;

			if ((root.ViewportSize.X != width) || (root.ViewportSize.Y != height) ||
				(root.DpiScale != dpi))
			{
				root.ViewportSize = .(width, height);
				root.DpiScale = dpi;
				structural = true;

				// The quality targets follow the swap chain. Recreated HERE, outside any open
				// frame, because it idles the GPU.
				RecreateTargets(attached, width, height);
			}
		}

		return structural;
	}

	private void RecreateTargets(AttachedWindow attached, float width, float height)
	{
		if (mDevice.Raw != null)
			mDevice.Raw.WaitIdle();

		attached.Data.CreateTargets(attached.Window.Swap.Format, (uint32)width, (uint32)height);
	}

	/// Pumps one window at LIVE desktop coordinates mapped into its own space.
	///
	/// The surface freezes its position when the cursor is not over it, so a captured resize
	/// or drag would stop updating. The button state still comes from the raw mouse, so the
	/// release that ends it still arrives.
	private void PumpWindowAtGlobal(ref AttachedWindow attached)
	{
		SyncSurfaceToWindow(attached);
		mContext.SetActiveInputRoot(attached.Data.Root);

		let mouse = (mShell.Input != null) ? mShell.Input.Mouse : null;
		if (mouse == null)
			return;

		let x = mouse.GlobalX - attached.Window.Window.X;
		let y = mouse.GlobalY - attached.Window.Window.Y;
		mBridge.PumpMouseAt(x, y, mouse);
	}

	/// Draws one window's root into its backbuffer. Does nothing for a window this host does
	/// not know, or an invalid frame.
	public void RenderWindow(ref FrameContext frame)
	{
		if (!frame.Valid)
			return;

		let data = Find(frame.Window);
		if (data == null)
			return;

		if (mFrameDamaged)
		{
			data.VG.Clear();
			mContext.DrawRootView(data.Root, data.VG);
		}

		// A clean frame re-encodes the RETAINED batch, built on the last damaged frame. The
		// backbuffer is still redrawn every frame; only the tree walk and the shaping are
		// skipped.
		let batch = data.VG.GetBatch();
		data.Renderer.BeginFrame((int32)frame.FrameIndex);
		let slice = data.Renderer.Prepare(batch, (int32)frame.FrameIndex, frame.Width, frame.Height);

		if (data.TargetsMatch(frame.Width, frame.Height) && (frame.Encoder != null))
		{
			RenderQualityPass(ref frame, data, slice);
			return;
		}

		RenderPlainPass(ref frame, data, slice);
	}

	/// The quality pass: into the multisampled target, resolved into the backbuffer, with the
	/// stencil cleared.
	private void RenderQualityPass(ref FrameContext frame, UIWindowData data, VGRenderSlice slice)
	{
		// The host transitions only the backbuffer, so the per-window attachments need their
		// own. From Undefined every frame: both are fully cleared, so the previous contents
		// are discardable.
		frame.Encoder.TransitionTexture(data.MsaaColor, .Undefined, .RenderTarget);
		frame.Encoder.TransitionTexture(data.DepthStencil, .Undefined, .DepthStencilWrite);

		var color = ColorAttachment();
		color.View = data.MsaaColorView;
		color.ResolveTarget = frame.BackbufferView;
		color.LoadOp = .Clear;
		// Resolved, so the multisampled texels can be dropped.
		color.StoreOp = .DontCare;
		color.ClearValue = mClearColor;

		var depthStencil = DepthStencilAttachment();
		depthStencil.View = data.DepthStencilView;
		depthStencil.DepthLoadOp = .Clear;
		depthStencil.DepthStoreOp = .DontCare;
		// Stencil-then-cover expects to start from nought.
		depthStencil.StencilLoadOp = .Clear;
		depthStencil.StencilStoreOp = .DontCare;
		depthStencil.StencilClearValue = 0;

		var pass = RenderPassDesc();
		pass.ColorAttachments.Add(color);
		pass.DepthStencilAttachment = depthStencil;
		pass.Label = "UI (msaa+stencil)";

		if (let renderPass = frame.Encoder.BeginRenderPass(pass))
		{
			data.Renderer.Render(renderPass, frame.Width, frame.Height, (int32)frame.FrameIndex, slice);
			renderPass.End();
		}
	}

	private void RenderPlainPass(ref FrameContext frame, UIWindowData data, VGRenderSlice slice)
	{
		if (let renderPass = frame.BeginBackbufferPass(mClearColor))
			data.Renderer.Render(renderPass, frame.Width, frame.Height, (int32)frame.FrameIndex, slice);

		frame.EndBackbufferPass();
	}

	// ---- Shaders ------------------------------------------------------------------------------

	/// Resolves the vector shaders through the shared shader host: cooked from a pack where
	/// there is no compiler, compiled on demand in development.
	///
	/// The vector shaders ship in the engine corpus like every other shader, so this is the
	/// same path the renderer itself uses rather than a bespoke inline compile.
	private void InitShaders()
	{
		if (mShaderHost.Initialize(mDevice.Raw, "Shaders") case .Err)
			return; // No compiler and no pack: the UI stays unrendered, loudly but not fatally.

		mVertexShader = mShaderHost.GetVariant("vg", .Vertex, .None);
		mFragmentShader = mShaderHost.GetVariant("vg", .Fragment, .None);
		mGradientRadialShader = mShaderHost.GetVariant("vg_grad_radial", .Fragment, .None);
		mGradientConicShader = mShaderHost.GetVariant("vg_grad_conic", .Fragment, .None);
		// A pack predating either of these means the feature falls back rather than being
		// mis-drawn: distance field glyphs use the default sampler, shadows are skipped.
		mDistanceFieldShader = mShaderHost.GetVariant("vg_df", .Fragment, .None);
		mBoxShadowShader = mShaderHost.GetVariant("vg_shadow", .Fragment, .None);
	}
}
