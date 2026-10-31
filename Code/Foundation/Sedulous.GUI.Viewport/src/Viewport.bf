using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.VG;
using Sedulous.VG.Renderer;

namespace Sedulous.GUI;

// GUI.Viewport: Viewport, a widget that shows content drawn into a colour target (and depth) of its
// own: a 3D scene, a game in an editor's panel. foundation.ui's counterpart: UI.Viewport
// (Specs/gui-lab-evolution-3.md in Raptor, V1 and V2).
//
// The application fills OnRender, which records into the targets on the frame's encoder (the
// barriers around it are the widget's). The widget is hosted content (GUI.Hosting's IHostedContent):
// handed to the host once (HostIn), it is bound to the renderer of the window its node is in and
// bound again when the node moves to another window, its targets follow the node's size in that
// window's device pixels (or a fixed resolution), its drawing is recorded on that window's frame
// before the GUI samples the colour target, and its input surface is placed over the node, so the
// content's keyboard and mouse (Mouse, Keyboard, Touch) are gated to it: a camera reads them while
// the node is hovered or focused (IsActive), and a drag begun in it keeps them past its edge.
//
// Content can also be drawn outside OnRender, by a renderer with a frame of its own that runs
// before the GUI's (an editor's scene renderer, one bracket for every page): it imports the colour
// target in ColorState, leaves it ready to sample and says so by setting ColorState to ShaderRead;
// the widget then keeps what it drew.
//
// From foundation.ui's ViewportView (UI.Viewport): its fit (ContentFit, for the picture and the
// pointer alike), its formats (RGBA16Float and Depth32Float by default), a fixed resolution, a clear
// while there is nothing defined to show, the colour target's state for a renderer that owns its
// transitions. For a game in a panel (the editor's Game tab) it also carries: the colour target's
// sRGB or UNORM twin view (the game's screen UI blends encoded values through it), the resolution
// the content draws at inside the targets (the pointer maps into that), hosted text input (the
// game's own text field asks for the window's text input through the focused node), and a clear
// once content drawn outside stops. A game in a panel takes every key while focused through the
// node's CapturesAllKeys (its release chord, Shift+F1 by default, frees it).

class Viewport : UIWidget, IHostedContent
{
	/// Records the content into the targets (a pass on ColorView and DepthView, cleared to
	/// LinearClearColor); the targets are in their render states while it runs.
	public typealias RenderHandler = delegate void(Viewport viewport, ICommandEncoder encoder, int32 frameIndex);
	public typealias ResizeHandler = delegate void(uint32 width, uint32 height);

	/// What shows where the content draws nothing, as authored (sRGB).
	public Color ClearColor = .(0.347f, 0.347f, 0.377f, 1.0f);

	private RenderHandler mOnRender = null ~ delete _;
	private ResizeHandler mOnResized = null ~ delete _;
	private GuiHost mHost = null; // borrowed: it outlives this, or this leaves it first
	private IDevice mDevice = null; // borrowed
	private VGRenderer mRenderer = null; // its window's, borrowed
	/// What the renderer knows the colour target by: an image only in name, its pixels on the GPU.
	private Sedulous.Image.ImageDataRef mKey = null ~ delete _;
	private ITexture mColorTexture = null;
	private ITextureView mColorView = null;
	private ITextureView mColorAlternateView = null; // in its sRGB or UNORM twin, if it has one
	private ITexture mDepthTexture = null;
	private ITextureView mDepthView = null;
	private ResourceState mColorState = .Undefined;
	private ResourceState mDepthState = .Undefined;
	private TextureFormat mColorFormat = .RGBA16Float;
	private TextureFormat mDepthFormat = .Depth32Float;
	private Sedulous.Shell.InputSurface mSurface = null ~ delete _;
	private FitMode mFit = .Stretch;
	private uint32 mWidth = 0;
	private uint32 mHeight = 0;
	private uint32 mFixedWidth = 0;
	private uint32 mFixedHeight = 0;
	private uint32 mWindowId = 0;
	private uint32 mClears = 0;
	private uint32 mContentWidth = 0; // the content's own resolution inside the targets (0: theirs)
	private uint32 mContentHeight = 0;
	private FitMode mContentFit = .Stretch;
	private ContentRotation mContentRotation = .None;
	private bool mRegistered = false;
	private bool mHostedTextInput = false;
	private bool mClearPending = false;

	public this()
	{
		Tag = "viewport";
		TabFocusable = true; // a click focuses it: the content then has the keyboard
	}

	public ~this()
	{
		if (mHost != null)
			mHost.RemoveContent(this);
		ReleaseTargets();
	}

	/// Takes ownership of the handler (null: none), deleting the last.
	public RenderHandler OnRender
	{
		get => mOnRender;
		set
		{
			if (value === mOnRender) // the same one: kept, not deleted
				return;
			delete mOnRender;
			mOnRender = value;
		}
	}

	/// The targets were made again, at this size (a camera's aspect follows it). Takes ownership
	/// of the handler (null: none), deleting the last.
	public ResizeHandler OnResized
	{
		get => mOnResized;
		set
		{
			if (value === mOnResized)
				return;
			delete mOnResized;
			mOnResized = value;
		}
	}

	/// Hosted by `host` from now on: bound, placed and drawn each frame while it is in a window.
	/// The host is borrowed: it outlives this, or this leaves it (HostIn another) first.
	public void HostIn(GuiHost host)
	{
		if (mHost == host)
			return;
		if (mHost != null)
			mHost.RemoveContent(this);
		mHost = host;
		host.AddContent(this);
	}

	public Sedulous.RHI.ClearColor LinearClearColor =>
		.(SrgbToLinear(ClearColor.R), SrgbToLinear(ClearColor.G), SrgbToLinear(ClearColor.B), ClearColor.A);

	/// How the targets' picture fits the node (and the pointer maps back into it).
	public FitMode FitMode
	{
		get => mFit;
		set
		{
			mFit = value;
			Invalidate();
		}
	}

	/// The targets' formats, which the content's pipelines are built for.
	public TextureFormat ColorFormat => mColorFormat;
	public TextureFormat DepthFormat => mDepthFormat;

	public void SetFormats(TextureFormat color, TextureFormat depth)
	{
		if ((color == mColorFormat) && (depth == mDepthFormat))
			return;
		mColorFormat = color;
		mDepthFormat = depth;
		if ((mWidth > 0) && (mHeight > 0))
			Resize(mWidth, mHeight);
	}

	/// A resolution of its own, whatever the node's size (0 by 0: the node's device pixels).
	public void SetFixedResolution(uint32 width, uint32 height)
	{
		mFixedWidth = width;
		mFixedHeight = height;
		if ((width > 0) && (height > 0))
			Resize(width, height);
	}

	/// The resolution the content draws at INSIDE the targets, fitted by `fit` (and turned by
	/// `rotation`), when it draws its own fitted picture (a game at its render resolution,
	/// letterboxed in a target the node's size): the pointer then maps into that resolution.
	/// 0 by 0: the targets' own.
	public void SetContentResolution(uint32 width, uint32 height, FitMode fit, ContentRotation rotation = .None)
	{
		mContentWidth = width;
		mContentHeight = height;
		mContentFit = fit;
		mContentRotation = rotation;
	}

	/// Whether the content it hosts has a text field taking text (a game's UI): the window's text
	/// input then follows, this node being the GUI's focused one. Set each frame by the content's
	/// owner.
	public void SetHostedTextInputWanted(bool wanted) => mHostedTextInput = wanted;
	public override bool WantsTextInput => mHostedTextInput;

	/// Content drawn outside stopped (a game ended): the picture is cleared to ClearColor on the
	/// next frame rather than keeping its last one.
	public void ClearPicture() => mClearPending = true;

	public bool IsReady => (mColorView != null) && (mDepthView != null);
	/// The colour target in its sRGB or UNORM twin format (null: its format has none): what draws
	/// encoded values into an sRGB target without the hardware encoding them again.
	public ITextureView ColorAlternateView => mColorAlternateView;
	/// The targets, this one's: null until it is bound and placed.
	public ITextureView ColorView => mColorView;
	public ITextureView DepthView => mDepthView;
	public ITexture ColorTexture => mColorTexture;
	/// The colour target's state: what a renderer drawing it outside OnRender imports it from
	/// (Undefined once it is made again), and tells the widget it left it in.
	public ResourceState ColorState
	{
		get => mColorState;
		set => mColorState = value;
	}
	/// How many frames it cleared for want of anything to show.
	public uint32 ClearCount => mClears;
	public uint32 RenderWidth => mWidth;
	public uint32 RenderHeight => mHeight;
	/// The window it is bound to (0: none).
	public uint32 WindowId => mWindowId;

	/// The content's input, gated to the node: read it while IsActive. Null until it is first bound.
	public Sedulous.Shell.IMouse Mouse => (mSurface != null) ? mSurface.Mouse : null;
	public Sedulous.Shell.IKeyboard Keyboard => (mSurface != null) ? mSurface.Keyboard : null;
	public Sedulous.Shell.ITouch Touch => (mSurface != null) ? mSurface.Touch : null;
	/// Whether the content should take input now: the node is hovered or focused.
	public bool IsActive => Hovered || IsFocused;

	// === IHostedContent ===

	public Node HostedNode => this;

	public void Bind(IDevice device, VGRenderer renderer, Sedulous.Shell.IInputManager input, uint32 windowId)
	{
		mDevice = device;
		if (renderer != mRenderer)
		{
			if (mRegistered && (mRenderer != null))
			{
				mDevice.WaitIdle(); // frames in flight sample it through the old one
				mRenderer.UnregisterExternalTexture(mKey);
				mRegistered = false;
			}
			mRenderer = renderer;
			if ((mRenderer != null) && (mColorView != null))
			{
				mRenderer.RegisterExternalTexture(mKey, mColorView);
				mRegistered = true;
			}
		}
		mWindowId = windowId;
		if ((input != null) && (mSurface == null))
			mSurface = new .(input, windowId, ContentFit(.(0.0f, 0.0f, 1.0f, 1.0f), .(1.0f, 1.0f), mFit));
		else if (mSurface != null)
			mSurface.SetWindow(windowId);
		Invalidate();
	}

	public void Place(Rectangle windowPixels, Rectangle windowUnits, Float2 windowSize)
	{
		// The targets follow the node in device pixels, unless the content has a size of its own.
		let width = (mFixedWidth > 0) ? mFixedWidth : (uint32)Math.Max(1.0f, windowPixels.Width + 0.5f);
		let height = (mFixedHeight > 0) ? mFixedHeight : (uint32)Math.Max(1.0f, windowPixels.Height + 0.5f);
		if ((width != mWidth) || (height != mHeight) || (!IsReady && (mDevice != null)))
			Resize(width, height);
		if (mSurface == null)
			return;
		mSurface.SetWindowSize(windowSize);
		PlaceSurface(windowUnits); // the pointer arrives in window units
	}

	public void Record(ICommandEncoder encoder, int32 frameIndex)
	{
		if (!IsReady)
			return;
		// No content of its own: drawn outside (or cleared before), it is ready to sample, unless
		// that content stopped and asked for a clear.
		if ((mOnRender == null) && (mColorState == .ShaderRead) && !mClearPending)
			return;
		mClearPending = false;
		encoder.TransitionTexture(mColorTexture, mColorState, .RenderTarget);
		if (mOnRender == null)
		{
			// Nothing to draw: the colour target still holds something defined to sample.
			mClears++;
			var pass = RenderPassDesc();
			var color = ColorAttachment();
			color.View = mColorView;
			color.LoadOp = .Clear;
			color.StoreOp = .Store;
			color.ClearValue = LinearClearColor;
			pass.ColorAttachments.Add(color);
			if (let passEncoder = encoder.BeginRenderPass(pass))
				passEncoder.End();
		}
		else
		{
			if (mDepthState != .DepthStencilWrite)
			{
				encoder.TransitionTexture(mDepthTexture, mDepthState, .DepthStencilWrite);
				mDepthState = .DepthStencilWrite;
			}
			mOnRender(this, encoder, frameIndex);
		}
		encoder.TransitionTexture(mColorTexture, .RenderTarget, .ShaderRead);
		mColorState = .ShaderRead;
	}

	/// This one's: null until it is first bound with an input manager.
	public Sedulous.Shell.InputSurface HostedSurface => mSurface;

	/// 256 by 256 when nothing sizes it.
	public override Float2 MeasureContent(Float2 available) => .(256.0f, 256.0f);

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		let @box = ContentBounds;
		if (!mRegistered || (mWidth == 0) || (mHeight == 0))
		{
			ctx.VG.FillRect(@box.ToRectangle(), .(0.098f, 0.098f, 0.118f, 1.0f)); // not bound yet
			return;
		}
		// Live content changes outside the GUI's knowledge: a shown viewport asks for every frame.
		Invalidate();
		let fit = ContentFit(@box.ToRectangle(), .((float)mWidth, (float)mHeight), mFit);
		let at = fit.DstRect();
		if ((at.Width < @box.Width) || (at.Height < @box.Height))
			ctx.VG.FillRect(@box.ToRectangle(), .(0.0f, 0.0f, 0.0f, 1.0f)); // a letterbox's bars
		ctx.VG.DrawImage(mKey, at, fit.SrcRect(), Color.White);
	}

	// The surface over the node, the pointer mapped into the targets, or into the content's own
	// resolution through its fit; with a fixed resolution too (a phone's screen), in two steps: the
	// targets fitted into the node, the content into the targets.
	private void PlaceSurface(Rectangle region)
	{
		mSurface.SetRegion(region);
		mSurface.SetRotation(.None);
		let targets = Float2((float)mWidth, (float)mHeight);
		if ((mContentWidth == 0) || (mContentHeight == 0))
		{
			mSurface.SetContentSize(targets);
			mSurface.SetFitMode(mFit);
			return;
		}
		let content = Float2((float)mContentWidth, (float)mContentHeight);
		mSurface.SetContentSize(content);
		mSurface.SetFitMode(mContentFit);
		mSurface.SetRotation(mContentRotation);
		if ((mFixedWidth == 0) || (mFixedHeight == 0) || (targets.X <= 0.0f) || (targets.Y <= 0.0f))
			return;
		let drawn = ContentFit(region, targets, mFit).DstRect();
		if (mContentFit == .Crop)
		{
			mSurface.SetRegion(drawn); // no bars, a slice: the fit scales evenly
			return;
		}
		let inside = ContentFit(.(0.0f, 0.0f, targets.X, targets.Y), content, mContentFit, mContentRotation).DstRect();
		let sx = drawn.Width / targets.X;
		let sy = drawn.Height / targets.Y;
		mSurface.SetRegion(.(drawn.X + inside.X * sx, drawn.Y + inside.Y * sy, inside.Width * sx, inside.Height * sy));
		mSurface.SetFitMode(.Stretch); // the region is the content's rectangle
	}

	private void Resize(uint32 width, uint32 height)
	{
		if (mDevice == null)
		{
			mWidth = width;
			mHeight = height;
			return;
		}
		if ((mColorTexture != null) || (mDepthTexture != null))
			mDevice.WaitIdle(); // frames in flight sample the old ones
		if (mRegistered && (mRenderer != null))
		{
			mRenderer.UnregisterExternalTexture(mKey);
			mRegistered = false;
		}
		DestroyTargets();
		mWidth = width;
		mHeight = height;
		mColorState = .Undefined;
		mDepthState = .Undefined;
		delete mKey;
		mKey = new .(width, height); // what the renderer knows it by
		var colorDesc = TextureDesc.RenderTarget(mColorFormat, width, height, 1, "ViewportColor");
		colorDesc.Usage = colorDesc.Usage | .CopySrc; // a capture copies it out
		colorDesc.AlternateViewFormat = TextureFormats.SrgbTwin(mColorFormat);
		if (mDevice.CreateTexture(colorDesc) case .Ok(let colorTexture))
			mColorTexture = colorTexture;
		if ((mColorTexture != null) && (mDevice.CreateTextureView(mColorTexture, .()) case .Ok(let colorView)))
			mColorView = colorView;
		if (mColorView == null)
		{
			DestroyTargets();
			return;
		}
		if (colorDesc.AlternateViewFormat != .Undefined)
		{
			var alternate = TextureViewDesc();
			alternate.Format = colorDesc.AlternateViewFormat;
			// A miss leaves it null: what draws through it draws linear light instead.
			if (mDevice.CreateTextureView(mColorTexture, alternate) case .Ok(let alternateView))
				mColorAlternateView = alternateView;
		}
		let depthDesc = TextureDesc.DepthBuffer(mDepthFormat, width, height, 1, "ViewportDepth");
		if (mDevice.CreateTexture(depthDesc) case .Ok(let depthTexture))
			mDepthTexture = depthTexture;
		if ((mDepthTexture != null) && (mDevice.CreateTextureView(mDepthTexture, .()) case .Ok(let depthView)))
			mDepthView = depthView;
		if (mDepthView == null)
		{
			DestroyTargets();
			return;
		}
		if (mRenderer != null)
		{
			mRenderer.RegisterExternalTexture(mKey, mColorView);
			mRegistered = true;
		}
		Invalidate();
		if (mOnResized != null)
			mOnResized(width, height);
	}

	private void DestroyTargets()
	{
		if (mDevice == null)
			return;
		// The device nulls what it destroys.
		if (mDepthView != null)
			mDevice.DestroyTextureView(ref mDepthView);
		if (mDepthTexture != null)
			mDevice.DestroyTexture(ref mDepthTexture);
		if (mColorAlternateView != null)
			mDevice.DestroyTextureView(ref mColorAlternateView);
		if (mColorView != null)
			mDevice.DestroyTextureView(ref mColorView);
		if (mColorTexture != null)
			mDevice.DestroyTexture(ref mColorTexture);
	}

	private void ReleaseTargets()
	{
		if ((mDevice != null) && ((mColorTexture != null) || (mDepthTexture != null)))
			mDevice.WaitIdle();
		if (mRegistered && (mRenderer != null))
			mRenderer.UnregisterExternalTexture(mKey);
		mRegistered = false;
		DestroyTargets();
	}
}
