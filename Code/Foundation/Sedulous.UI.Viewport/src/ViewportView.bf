using System;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.RHI;
using Sedulous.Shell;
using Sedulous.UI;
using Sedulous.VG;
using Sedulous.VG.Renderer;

namespace Sedulous.UI.Viewport;

/// A view that hosts rendered 3D content.
///
/// It owns an offscreen colour and depth target, fires a callback so the application draws into
/// them, and then shows the colour target as an image through the UI's own vector context. So
/// three dimensional content becomes an ordinary view that docks, scrolls and layers like any
/// other.
///
/// The fit maths is ContentFit, the SAME value the input surface uses. Drawing takes its
/// destination and source rectangles from it, and input remaps points through it, so where the
/// picture is drawn and where a click lands cannot drift apart.
///
/// A SINGLE offscreen target, not a per-frame ring: only the GPU touches it - the 3D pass
/// writes, the UI pass samples - on one queue, so submission order already serialises the next
/// frame's write after this frame's read.
class ViewportView : View
{
	private const uint32 DefaultSize = 256;

	/// Records the 3D content into the offscreen targets. The surrounding barriers are handled
	/// by RenderContent, so a handler owns only its passes and its draws.
	public delegate void(ViewportView view, ICommandEncoder encoder, int32 frameIndex) OnRender ~ delete _;
	/// Fired after the target is rebuilt, with the new pixel size, so a system that must lay
	/// out at the same resolution can follow.
	public delegate void(uint32 width, uint32 height) OnRenderTargetResized ~ delete _;

	/// The 3D pass's background, read by the render callback.
	public ClearColor ClearColor = .(0.098f, 0.098f, 0.118f, 1.0f);

	/// BORROWED: the device and the window's renderer both outlive the view.
	private IDevice mDevice = null;
	private VGRenderer mRenderer = null;

	/// The key the renderer knows the colour target by. An image only in name: it carries the
	/// size and format so the vector context can place it, and the pixels live on the GPU.
	private ImageDataRef mImageRef ~ delete _;

	private ITexture mColorTexture = null;
	private ITextureView mColorView = null;
	private ITexture mDepthTexture = null;
	private ITextureView mDepthView = null;
	private ResourceState mColorState = .Undefined;
	private ResourceState mDepthState = .Undefined;

	private bool mRegistered = false;
	private bool mHostedTextInputWanted = false;

	private uint32 mFixedWidth = 0;
	private uint32 mFixedHeight = 0;
	private uint32 mTextureWidth = 0;
	private uint32 mTextureHeight = 0;

	private FitMode mFitMode = .Stretch;
	private TextureFormat mColorFormat = .RGBA16Float;
	private TextureFormat mDepthFormat = .Depth32Float;

	/// OWNED: the gated, content-space view of the platform's devices.
	private InputSurface mSurface = null ~ delete _;

	public this()
	{
		IsFocusable = true;
	}

	public ~this()
	{
		ReleaseResources();
	}

	// ---- Wiring -------------------------------------------------------------------------------

	/// Binds the device, the renderer for the window this view is drawn in, and the input.
	/// Called once before the first layout.
	public void Initialize(IDevice device, VGRenderer renderer, IInputManager input, uint32 windowId)
	{
		mDevice = device;
		mRenderer = renderer;

		if ((input != null) && (mSurface == null))
			mSurface = new InputSurface(input, windowId, ContentFit(.(0, 0, 1, 1), .(1, 1), mFitMode));
	}

	/// Rebinds to a different window's renderer.
	///
	/// For a dockable panel moving windows: undocking into a float, or redocking into the main
	/// one. The colour target is re-registered with the new renderer so that window's UI can
	/// sample it, and the surface is re-aimed so the router routes there. The GPU targets
	/// themselves do not change.
	///
	/// ONE renderer at a time: sampling a single target in two windows at once would need a
	/// shared external texture cache, which does not exist.
	public void AttachToWindow(VGRenderer renderer, uint32 windowId)
	{
		if (renderer != mRenderer)
		{
			if (mRegistered && (mRenderer != null))
			{
				// Idle first: the old renderer may still be sampling the target this frame.
				if (mDevice != null)
					mDevice.WaitIdle();

				mRenderer.UnregisterExternalTexture(mImageRef);
				mRegistered = false;
			}

			mRenderer = renderer;

			if ((mRenderer != null) && (mColorView != null))
			{
				mRenderer.RegisterExternalTexture(mImageRef, mColorView);
				mRegistered = true;
			}
		}

		if (mSurface != null)
			mSurface.SetWindow(windowId);
	}

	/// Releases the GPU targets and the registration EAGERLY, while the device and the window's
	/// renderer are both still alive.
	///
	/// A view can outlive the window it was drawn in, sitting in a retained tree, so the
	/// destructor must not be what unregisters. Idempotent; the destructor then does nothing.
	public void Shutdown()
	{
		ReleaseResources();
		mRenderer = null;
		mDevice = null;
	}

	// ---- Presentation -------------------------------------------------------------------------

	public FitMode FitMode
	{
		get => mFitMode;
		set
		{
			mFitMode = value;
			if (mSurface != null)
				mSurface.SetFitMode(value);
		}
	}

	public TextureFormat ColorFormat => mColorFormat;
	public TextureFormat DepthFormat => mDepthFormat;

	/// The view owns the offscreen formats, so a render callback building a pipeline from them
	/// always agrees with the actual attachments. High dynamic range by default; a plain game
	/// in a panel, or one wanting stencil, overrides.
	public void SetFormats(TextureFormat color, TextureFormat depth)
	{
		if ((color == mColorFormat) && (depth == mDepthFormat))
			return;

		mColorFormat = color;
		mDepthFormat = depth;

		if ((mTextureWidth > 0) && (mTextureHeight > 0))
			ResizeRenderTarget(mTextureWidth, mTextureHeight);
	}

	public bool IsReady => (mColorView != null) && (mDepthView != null);
	public ITextureView ColorTargetView => mColorView;
	public ITextureView DepthTargetView => mDepthView;
	public ITexture ColorTexture => mColorTexture;
	public uint32 RenderWidth => mTextureWidth;
	public uint32 RenderHeight => mTextureHeight;
	public uint32 FixedWidth => mFixedWidth;
	public uint32 FixedHeight => mFixedHeight;

	/// A FIXED render resolution, rendering at that size whatever the panel's size. Nought by
	/// nought follows the layout, which is the default.
	///
	/// Pair it with Letterbox so the presentation AND the input stay aspect correct: both go
	/// through the same ContentFit, so they agree by construction.
	public void SetFixedResolution(uint32 width, uint32 height)
	{
		if ((mFixedWidth == width) && (mFixedHeight == height))
			return;

		mFixedWidth = width;
		mFixedHeight = height;

		if ((width > 0) && (height > 0))
			ResizeRenderTarget(width, height);
		else if ((Width > 0.0f) && (Height > 0.0f))
			ResizeRenderTarget((uint32)Max(1.0f, Width), (uint32)Max(1.0f, Height));
	}

	/// The tracked colour state, for content that manages its own transitions - a frame graph
	/// importing the target needs to know what state it is in and to say what it left behind.
	/// Content going through RenderContent never touches these.
	public ResourceState ColorState
	{
		get => mColorState;
		set => mColorState = value;
	}

	// ---- Input --------------------------------------------------------------------------------

	/// Borrowed; null until Initialize has been given an input manager.
	public InputSurface Surface => mSurface;
	public IMouse Mouse => (mSurface != null) ? mSurface.Mouse : null;
	public IKeyboard Keyboard => (mSurface != null) ? mSurface.Keyboard : null;
	public ITouch Touch => (mSurface != null) ? mSurface.Touch : null;

	/// Whether the content this viewport hosts has a text editor focused.
	///
	/// The viewport is the HOST context's focused view, so it reports on the embedded content's
	/// behalf. That way the host window's IME follows the embedded focus, instead of two
	/// bridges fighting over starting and stopping composition.
	public void SetHostedTextInputWanted(bool wanted) => mHostedTextInputWanted = wanted;

	public override bool WantsTextInput() => mHostedTextInputWanted;

	/// Whether the host UI's keyboard focus is on something OTHER than this viewport.
	///
	/// Fed into the router's external capture so the hosted content stops receiving keys an
	/// editor widget is consuming. Absent focus does NOT count as elsewhere: clicking dead
	/// editor space must not mute a running game.
	public bool HostKeyboardFocusElsewhere
	{
		get
		{
			if (Context == null)
				return false;

			let focused = Context.GetFocusManager().FocusedView;
			return (focused != null) && (focused != this);
		}
	}

	/// Brings the input surface's region into line with where this view was laid out. Called
	/// each frame after layout and before the router updates.
	///
	/// The region is ALWAYS the real rectangle, so the coordinate transforms stay correct;
	/// whether the content actually reads the devices is the application's own hover and focus
	/// check, not something hidden in here.
	public void SyncInputRegion()
	{
		if (mSurface == null)
			return;

		// PHYSICAL pixels, not logical. The UI tree lays out in logical units - the root
		// divides the window by its DPI scale - but the router transforms the RAW mouse, which
		// is in physical window pixels. Mixing them drifts hover and picking by the scale
		// factor at any UI scale other than 100 per cent. The CONTENT resolution stays the
		// target's own size, so only the region needs converting.
		let root = RootOf(this);
		var dpi = 1.0f;
		if (let rootView = root as RootView)
			dpi = Max(rootView.DpiScale, 0.01f);

		let topLeft = LocalToScreen(.(0, 0));
		mSurface.SetRegion(.(topLeft.X * dpi, topLeft.Y * dpi, Width * dpi, Height * dpi));
		mSurface.SetContentSize(.(mTextureWidth, mTextureHeight));
		mSurface.SetFitMode(mFitMode);
		// The window's pixel size, which the touch transform converts normalised fingers
		// through.
		mSurface.SetWindowSize(.(root.Width * dpi, root.Height * dpi));
	}

	private static View RootOf(View view)
	{
		var current = view;
		while (current.Parent != null)
			current = current.Parent;

		return current;
	}

	// ---- Rendering ----------------------------------------------------------------------------

	/// Clears the colour target and leaves it readable.
	///
	/// For a host whose content is sometimes idle, a Game tab before play being the case: the
	/// UI samples the texture every frame, so even an undrawn frame has to define it.
	public void ClearContent(ICommandEncoder encoder)
	{
		if (!IsReady)
			return;

		encoder.TransitionTexture(mColorTexture, mColorState, .RenderTarget);

		var pass = RenderPassDesc();
		var color = ColorAttachment();
		color.View = mColorView;
		color.LoadOp = .Clear;
		color.StoreOp = .Store;
		color.ClearValue = ClearColor;
		pass.ColorAttachments.Add(color);

		if (let renderPass = encoder.BeginRenderPass(pass))
			renderPass.End();

		encoder.TransitionTexture(mColorTexture, .RenderTarget, .ShaderRead);
		mColorState = .ShaderRead;
	}

	/// Renders the 3D content. Called before the window's UI draws, since that samples this
	/// view's colour target.
	///
	/// BRACKETS the application's callback with the state transitions it needs, so a content
	/// renderer owns only its passes. RHI is explicit about resource state, which is the one
	/// place this had to depart from what it was adapted from.
	public void RenderContent(ICommandEncoder encoder, int32 frameIndex)
	{
		if (!IsReady || (OnRender == null))
			return;

		encoder.TransitionTexture(mColorTexture, mColorState, .RenderTarget);

		if (mDepthState != .DepthStencilWrite)
		{
			encoder.TransitionTexture(mDepthTexture, mDepthState, .DepthStencilWrite);
			mDepthState = .DepthStencilWrite;
		}

		OnRender(this, encoder, frameIndex);

		encoder.TransitionTexture(mColorTexture, .RenderTarget, .ShaderRead);
		mColorState = .ShaderRead;
	}

	// ---- Layout and draw ----------------------------------------------------------------------

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(DefaultSize),
			constraints.ConstrainHeight(DefaultSize));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		let targetWidth = (mFixedWidth > 0) ? mFixedWidth : (uint32)Max(1.0f, width);
		let targetHeight = (mFixedHeight > 0) ? mFixedHeight : (uint32)Max(1.0f, height);

		if ((targetWidth != mTextureWidth) || (targetHeight != mTextureHeight))
			ResizeRenderTarget(targetWidth, targetHeight);
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		if (!mRegistered || (mTextureWidth == 0) || (mTextureHeight == 0))
		{
			// Nothing to sample yet: paint the clear colour so the panel reads as a viewport
			// rather than as a hole.
			ctx.VG.FillRect(.(0, 0, Width, Height),
				Color(0.098f, 0.098f, 0.118f, 1.0f));
			return;
		}

		// LIVE content: the target changes outside the UI's knowledge, so a visible viewport
		// keeps the damage chain alive itself. Self sustaining - a draw marks, and the mark
		// brings the next draw.
		Invalidate();

		let fit = ContentFit(.(0, 0, Width, Height), .(mTextureWidth, mTextureHeight), mFitMode);
		let dst = fit.DstRect();

		// Letterbox and integer scaling leave bars on one axis. Painted black, or they show
		// whatever was in the framebuffer before.
		if ((dst.Width < Width) || (dst.Height < Height))
			ctx.VG.FillRect(.(0, 0, Width, Height), Color(0, 0, 0, 1));

		ctx.VG.DrawImage(mImageRef, dst, fit.SrcRect(), Color.White);
	}

	// ---- Targets ------------------------------------------------------------------------------

	private void ResizeRenderTarget(uint32 width, uint32 height)
	{
		if (mDevice == null)
			return;

		// The GPU must be idle before targets it may still be sampling are freed. This is also
		// where the external registration stops being valid.
		if ((mColorTexture != null) || (mDepthTexture != null))
			mDevice.WaitIdle();

		if (mRegistered && (mRenderer != null))
		{
			mRenderer.UnregisterExternalTexture(mImageRef);
			mRegistered = false;
		}

		DestroyTargets();

		mTextureWidth = width;
		mTextureHeight = height;
		mColorState = .Undefined;
		mDepthState = .Undefined;

		if ((width == 0) || (height == 0))
			return;

		if (!CreateTargets(width, height))
		{
			DestroyTargets();
			return;
		}

		// The key the renderer knows the target by, remade at the new size.
		delete mImageRef;
		mImageRef = new ImageDataRef(width, height, .RGBA8);

		if (mRenderer != null)
		{
			mRenderer.RegisterExternalTexture(mImageRef, mColorView);
			mRegistered = true;
		}

		if (OnRenderTargetResized != null)
			OnRenderTargetResized(width, height);
	}

	private bool CreateTargets(uint32 width, uint32 height)
	{
		var colorDesc = TextureDesc();
		colorDesc.Width = width;
		colorDesc.Height = height;
		colorDesc.Format = mColorFormat;
		// Both: the 3D pass writes it and the UI pass samples it.
		colorDesc.Usage = .RenderTarget | .Sampled;
		if (mDevice.CreateTexture(colorDesc) case .Ok(let colorTexture))
			mColorTexture = colorTexture;
		else
			return false;

		if (mDevice.CreateTextureView(mColorTexture, .()) case .Ok(let colorView))
			mColorView = colorView;
		else
			return false;

		var depthDesc = TextureDesc();
		depthDesc.Width = width;
		depthDesc.Height = height;
		depthDesc.Format = mDepthFormat;
		depthDesc.Usage = .DepthStencil;
		if (mDevice.CreateTexture(depthDesc) case .Ok(let depthTexture))
			mDepthTexture = depthTexture;
		else
			return false;

		if (mDevice.CreateTextureView(mDepthTexture, .()) case .Ok(let depthView))
			mDepthView = depthView;
		else
			return false;

		return true;
	}

	private void DestroyTargets()
	{
		if (mDevice == null)
			return;

		// The device NULLS what it destroys, which is why these take a reference.
		if (mDepthView != null)
			mDevice.DestroyTextureView(ref mDepthView);
		if (mDepthTexture != null)
			mDevice.DestroyTexture(ref mDepthTexture);
		if (mColorView != null)
			mDevice.DestroyTextureView(ref mColorView);
		if (mColorTexture != null)
			mDevice.DestroyTexture(ref mColorTexture);
	}

	private void ReleaseResources()
	{
		if ((mDevice != null) && ((mColorTexture != null) || (mDepthTexture != null)))
			mDevice.WaitIdle();

		if (mRegistered && (mRenderer != null))
		{
			mRenderer.UnregisterExternalTexture(mImageRef);
			mRegistered = false;
		}

		DestroyTargets();
	}
}
