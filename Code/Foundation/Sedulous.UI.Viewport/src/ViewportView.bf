namespace Sedulous.UI.Viewport;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.UI;
using Sedulous.VG;
using Sedulous.VG.Renderer;
using Sedulous.Images;

/// Delegate for rendering 3D content to a viewport.
public delegate void ViewportRenderDelegate(ViewportView viewport, ICommandEncoder encoder, int32 frameIndex);

/// How the render texture is mapped into the view's layout rect.
/// Mirrors the standalone-blit FitMode in Sedulous.Engine.App (the
/// values are intentionally identical-ordinal so the editor's page
/// builder can pass a converted cast directly).
public enum ViewportFitMode : uint8
{
	/// Fill the layout rect ignoring aspect (current default; matches
	/// pre-fit-mode behavior).
	Stretch,
	/// Preserve aspect, center, black bars on overflow axis.
	Letterbox,
	/// Preserve aspect, fill the layout rect, clip overflow axis.
	Crop
}

/// A UI View that displays 3D rendered content.
/// Creates offscreen color + depth render targets, fires OnRender for 3D drawing,
/// and displays the result as an image via VGContext.DrawImage.
/// Pure render surface - input handling is done by the owning page/controller.
public class ViewportView : View
{
	private IDevice mDevice;
	private VGRenderer mVGRenderer;
	private ImageDataRef mImageRef ~ delete _;

	// Render target resources
	private ITexture mColorTexture;
	private ITextureView mColorTextureView;
	private ITexture mDepthTexture;
	private ITextureView mDepthTextureView;

	private uint32 mTextureWidth;
	private uint32 mTextureHeight;
	private bool mIsRegistered;
	private bool mHasRendered;

	// Optional fixed render size. When both are > 0 the auto-resize in
	// OnLayout is bypassed and the texture stays at this resolution
	// regardless of layout. Drawing uses VG.DrawImage's free linear-
	// filter stretch to fit the layout rect. Used by the editor's
	// GameEditorPage to drive preview-resolution simulation.
	private uint32 mFixedRenderWidth;
	private uint32 mFixedRenderHeight;

	/// Event fired when the viewport needs to render 3D content.
	/// The handler should render to ColorTexture/ColorTargetView.
	public Event<ViewportRenderDelegate> OnRender ~ _.Dispose();

	/// Clear color for the viewport background.
	public Color32 ClearColor = .(25, 25, 30, 255);

	/// The color render target view. Use in your render pass.
	public ITextureView ColorTargetView => mColorTextureView;

	/// The color texture. Use for barriers/transitions.
	public ITexture ColorTexture => mColorTexture;

	/// The depth target view.
	public ITextureView DepthTargetView => mDepthTextureView;

	/// Current render width.
	public uint32 RenderWidth => mTextureWidth;

	/// Current render height.
	public uint32 RenderHeight => mTextureHeight;

	/// Fires after the render target is created or recreated. Subscribe
	/// to mirror the texture size into other systems (e.g. the editor's
	/// runtime UI subsystem which needs to lay out at the same canvas
	/// the viewport is rendering into). Args are (width, height) in pixels.
	public Event<delegate void(uint32 width, uint32 height)> OnRenderTargetResized ~ _.Dispose();


	/// How the texture is mapped into the layout rect when their aspects
	/// differ. Default Stretch matches pre-fit-mode behavior. Letterbox
	/// / Crop preserve the texture's aspect ratio.
	public ViewportFitMode FitMode = .Stretch;

	/// Pin the render texture to a specific size. Width / height must
	/// both be > 0 to take effect. Pass 0/0 to release (back to
	/// auto-tracking the layout). Triggers an immediate resize.
	public void SetFixedRenderSize(uint32 width, uint32 height)
	{
		if (width == mFixedRenderWidth && height == mFixedRenderHeight)
			return;

		mFixedRenderWidth = width;
		mFixedRenderHeight = height;

		if (width > 0 && height > 0)
		{
			if (width != mTextureWidth || height != mTextureHeight)
				ResizeRenderTarget(width, height);
		}
		else
		{
			// Falling back to layout-driven sizing - re-trigger from current layout.
			let newWidth = (uint32)Math.Max(1, Width);
			let newHeight = (uint32)Math.Max(1, Height);
			if (newWidth != mTextureWidth || newHeight != mTextureHeight)
				ResizeRenderTarget(newWidth, newHeight);
		}
	}

	/// Whether render targets are ready.
	public bool IsReady => mColorTextureView != null && mDepthTextureView != null;

	/// Input handlers processed in registration order (priority).
	/// First handler to set e.Handled = true stops propagation.
	private List<IViewportInputHandler> mInputHandlers = new .() ~ delete _;

	public this()
	{
		mImageRef = new ImageDataRef(1, 1);
		IsFocusable = true;
	}

	/// Initialize with device and VGRenderer (for external texture registration).
	public void Initialize(IDevice device, VGRenderer vgRenderer)
	{
		mDevice = device;
		mVGRenderer = vgRenderer;
	}

	/// Render the 3D content. Call from the frame loop before UI drawing.
	public void RenderContent(ICommandEncoder encoder, int32 frameIndex)
	{
		if (mDevice == null || mColorTextureView == null || !mIsRegistered)
			return;

		OnRender(this, encoder, frameIndex);

		// Mark the texture as ready in the shared cache - other VGRenderers
		// can now safely pick it up (texture is in ShaderRead state).
		if (mVGRenderer != null)
			mVGRenderer.MarkExternalTextureReady(mImageRef);
	}

	// === Input handlers ===

	/// Adds an input handler. Handlers are processed in registration order.
	public void AddInputHandler(IViewportInputHandler handler)
	{
		mInputHandlers.Add(handler);
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		for (let handler in mInputHandlers)
		{
			handler.OnMouseDown(e, this);
			if (e.Handled) break;
		}
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		for (let handler in mInputHandlers)
		{
			handler.OnMouseUp(e, this);
			if (e.Handled) break;
		}
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		for (let handler in mInputHandlers)
		{
			handler.OnMouseMove(e, this);
			if (e.Handled) break;
		}
	}

	public override void OnMouseWheel(MouseWheelEventArgs e)
	{
		for (let handler in mInputHandlers)
		{
			handler.OnMouseWheel(e, this);
			if (e.Handled) break;
		}
	}

	// === Layout ===

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(256), constraints.ConstrainHeight(256));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		// Fixed-size opt-in: texture stays at the pinned dims; layout
		// change only affects on-screen presentation (VG.DrawImage stretches
		// to the layout rect).
		if (mFixedRenderWidth > 0 && mFixedRenderHeight > 0)
			return;

		let newWidth = (uint32)Math.Max(1, width);
		let newHeight = (uint32)Math.Max(1, height);

		if (newWidth != mTextureWidth || newHeight != mTextureHeight)
			ResizeRenderTarget(newWidth, newHeight);
	}

	// === Fit Mode ===

	/// Computes the destination rect (where texture content lands in the
	/// view's layout rect) AND the source rect (which texels are sampled)
	/// for the current FitMode.
	///   Stretch:   dst = full layout, src = full texture
	///   Letterbox: dst = aspect-fit (smaller than layout, black bars),
	///              src = full texture
	///   Crop:      dst = full layout (always inside the view bounds),
	///              src = aspect-fit slice of the texture (off-axis pixels
	///              are clipped, not drawn outside the view)
	private void ComputeContentRect(out float dx, out float dy, out float dw, out float dh,
		out float sx, out float sy, out float sw, out float sh)
	{
		let lw = Width;
		let lh = Height;
		let rw = (float)mTextureWidth;
		let rh = (float)mTextureHeight;

		dx = 0; dy = 0; dw = lw; dh = lh;
		sx = 0; sy = 0; sw = rw; sh = rh;

		if (FitMode == .Stretch || rw <= 0 || rh <= 0 || lw <= 0 || lh <= 0)
			return;

		let srcAspect = rw / rh;
		let dstAspect = lw / lh;
		if (FitMode == .Letterbox)
		{
			if (srcAspect > dstAspect)
			{
				dw = lw; dh = lw / srcAspect; dx = 0; dy = (lh - dh) * 0.5f;
			}
			else
			{
				dh = lh; dw = lh * srcAspect; dy = 0; dx = (lw - dw) * 0.5f;
			}
		}
		else // Crop - keep dst at full layout; slice the source instead
		{
			if (srcAspect > dstAspect)
			{
				// Texture wider than layout aspect - crop horizontally
				sh = rh;
				sw = rh * dstAspect;
				sx = (rw - sw) * 0.5f;
				sy = 0;
			}
			else
			{
				// Texture taller than layout aspect - crop vertically
				sw = rw;
				sh = rw / dstAspect;
				sy = (rh - sh) * 0.5f;
				sx = 0;
			}
		}
	}

	/// Maps a point in the view's layout rect into texture pixel space.
	/// Returns false if the input lands outside the texture content
	/// (Letterbox bars - no UI hit). For Crop / Stretch the function
	/// always succeeds since the visible layout is fully covered by
	/// texture content.
	public bool ScreenToTexture(float layoutX, float layoutY, out float texX, out float texY)
	{
		texX = layoutX;
		texY = layoutY;
		if (mTextureWidth == 0 || mTextureHeight == 0) return false;

		float dx, dy, dw, dh, sx, sy, sw, sh;
		ComputeContentRect(out dx, out dy, out dw, out dh, out sx, out sy, out sw, out sh);
		if (dw <= 0 || dh <= 0) return false;

		let relX = layoutX - dx;
		let relY = layoutY - dy;
		if (FitMode == .Letterbox)
		{
			if (relX < 0 || relX > dw || relY < 0 || relY > dh)
				return false;
		}

		texX = sx + relX * sw / dw;
		texY = sy + relY * sh / dh;
		return true;
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		if (mIsRegistered && mTextureWidth > 0 && mTextureHeight > 0)
		{
			float dx, dy, dw, dh, sx, sy, sw, sh;
			ComputeContentRect(out dx, out dy, out dw, out dh, out sx, out sy, out sw, out sh);
			// Letterbox shows bars on the overflow axis - paint the
			// background black so they read as bars and not as
			// whatever was previously in the framebuffer.
			if (FitMode == .Letterbox && (dw < Width || dh < Height))
				ctx.VG.FillRect(.(0, 0, Width, Height), .(0, 0, 0, 255));
			ctx.VG.DrawImage(mImageRef, .(dx, dy, dw, dh), .(sx, sy, sw, sh), .White);
		}
		else
		{
			// Fallback: dark background
			ctx.VG.FillRect(.(0, 0, Width, Height), .(25, 25, 30, 255));
		}
	}

	// === Render Target Management ===

	private void ResizeRenderTarget(uint32 width, uint32 height)
	{
		if (mDevice == null) return;

		if (mColorTexture != null || mDepthTexture != null)
			mDevice.WaitIdle();

		// Unregister old texture
		if (mIsRegistered && mVGRenderer != null)
		{
			mVGRenderer.UnregisterExternalTexture(mImageRef);
			mIsRegistered = false;
		}

		// Destroy old resources
		if (mDepthTextureView != null) mDevice.DestroyTextureView(ref mDepthTextureView);
		if (mDepthTexture != null) mDevice.DestroyTexture(ref mDepthTexture);
		if (mColorTextureView != null) mDevice.DestroyTextureView(ref mColorTextureView);
		if (mColorTexture != null) mDevice.DestroyTexture(ref mColorTexture);

		mTextureWidth = width;
		mTextureHeight = height;

		// Update the image ref dimensions so DrawImage uses correct source rect
		delete mImageRef;
		mImageRef = new ImageDataRef(width, height);

		// Create color render target
		TextureDesc colorDesc = .()
		{
			Label = "ViewportColor",
			Width = width,
			Height = height,
			Depth = 1,
			Format = .RGBA16Float,
			Usage = .RenderTarget | .Sampled,
			Dimension = .Texture2D,
			MipLevelCount = 1,
			ArrayLayerCount = 1,
			SampleCount = 1
		};

		if (mDevice.CreateTexture(colorDesc) case .Ok(let tex))
			mColorTexture = tex;
		else
			return;

		if (mDevice.CreateTextureView(mColorTexture, .() { Format = .RGBA16Float }) case .Ok(let view))
			mColorTextureView = view;
		else
			return;

		// Create depth buffer
		TextureDesc depthDesc = .()
		{
			Label = "ViewportDepth",
			Width = width,
			Height = height,
			Depth = 1,
			Format = .Depth32Float,
			Usage = .DepthStencil,
			Dimension = .Texture2D,
			MipLevelCount = 1,
			ArrayLayerCount = 1,
			SampleCount = 1
		};

		if (mDevice.CreateTexture(depthDesc) case .Ok(let depthTex))
			mDepthTexture = depthTex;
		else
			return;

		if (mDevice.CreateTextureView(mDepthTexture, .() { Format = .Depth32Float }) case .Ok(let depthView))
			mDepthTextureView = depthView;

		// Register immediately with VGRenderer for smooth resize (same-window case).
		// The shared cache entry starts as not-ready - other VGRenderers won't pick
		// it up until MarkReady is called after the first RenderContent.
		if (mVGRenderer != null && mColorTextureView != null)
		{
			mVGRenderer.RegisterExternalTexture(mImageRef, mColorTextureView);
			mIsRegistered = true;
		}

		OnRenderTargetResized(width, height);
	}

	// === Cleanup ===

	public ~this()
	{
		// Ensure GPU is done with our textures before freeing them.
		if (mDevice != null && (mColorTexture != null || mDepthTexture != null))
			mDevice.WaitIdle();

		if (mIsRegistered && mVGRenderer != null)
		{
			mVGRenderer.UnregisterExternalTexture(mImageRef);
			mIsRegistered = false;
		}
		if (mDepthTextureView != null) mDevice?.DestroyTextureView(ref mDepthTextureView);
		if (mDepthTexture != null) mDevice?.DestroyTexture(ref mDepthTexture);
		if (mColorTextureView != null) mDevice?.DestroyTextureView(ref mColorTextureView);
		if (mColorTexture != null) mDevice?.DestroyTexture(ref mColorTexture);
	}
}
