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
// From foundation.ui's ViewportView (UI.Viewport): its fit (ContentFit, for the picture and the
// pointer alike), its formats (RGBA16Float and Depth32Float by default), a fixed resolution, a clear
// when there is nothing to draw. Not carried: the editor's game-in-a-panel keyboard capture and
// hosted text input, which wait for an embedded GUI to need them.

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
	private bool mRegistered = false;

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

	public bool IsReady => (mColorView != null) && (mDepthView != null);
	/// The targets, this one's: null until it is bound and placed.
	public ITextureView ColorView => mColorView;
	public ITextureView DepthView => mDepthView;
	public ITexture ColorTexture => mColorTexture;
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

	public void Place(Rectangle windowPixels, Float2 windowSize)
	{
		// The targets follow the node in device pixels, unless the content has a size of its own.
		let width = (mFixedWidth > 0) ? mFixedWidth : (uint32)Math.Max(1.0f, windowPixels.Width + 0.5f);
		let height = (mFixedHeight > 0) ? mFixedHeight : (uint32)Math.Max(1.0f, windowPixels.Height + 0.5f);
		if ((width != mWidth) || (height != mHeight) || (!IsReady && (mDevice != null)))
			Resize(width, height);
		if (mSurface == null)
			return;
		mSurface.SetRegion(windowPixels);
		mSurface.SetWindowSize(windowSize);
		mSurface.SetContentSize(.((float)mWidth, (float)mHeight));
		mSurface.SetFitMode(mFit);
	}

	public void Record(ICommandEncoder encoder, int32 frameIndex)
	{
		if (!IsReady)
			return;
		encoder.TransitionTexture(mColorTexture, mColorState, .RenderTarget);
		if (mOnRender == null)
		{
			// Nothing to draw: the colour target still holds something defined to sample.
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
		if (mDevice.CreateTexture(colorDesc) case .Ok(let colorTexture))
			mColorTexture = colorTexture;
		if ((mColorTexture != null) && (mDevice.CreateTextureView(mColorTexture, .()) case .Ok(let colorView)))
			mColorView = colorView;
		if (mColorView == null)
		{
			DestroyTargets();
			return;
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
