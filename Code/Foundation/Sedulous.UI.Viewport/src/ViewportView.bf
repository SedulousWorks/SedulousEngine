namespace Sedulous.UI.Viewport;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.UI;
using Sedulous.VG;
using Sedulous.VG.Renderer;
using Sedulous.Images;

/// Delegate for rendering 3D content to a viewport.
public delegate void ViewportRenderDelegate(ViewportView viewport, ICommandEncoder encoder, int32 frameIndex);

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

	/// Event fired when the viewport needs to render 3D content.
	/// The handler should render to ColorTexture/ColorTargetView.
	public Event<ViewportRenderDelegate> OnRender ~ _.Dispose();

	/// Clear color for the viewport background.
	public Color ClearColor = .(25, 25, 30, 255);

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

	/// Whether render targets are ready.
	public bool IsReady => mColorTextureView != null && mDepthTextureView != null;

	/// Input delegates - set by the owning page/controller.
	public delegate void(MouseEventArgs) OnMouseDownHandler ~ delete _;
	public delegate void(MouseEventArgs) OnMouseUpHandler ~ delete _;
	public delegate void(MouseEventArgs) OnMouseMoveHandler ~ delete _;
	public delegate void(MouseWheelEventArgs) OnMouseWheelHandler ~ delete _;

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

	// === Layout ===

	// === Input forwarding ===

	public override void OnMouseDown(MouseEventArgs e) { OnMouseDownHandler?.Invoke(e); }
	public override void OnMouseUp(MouseEventArgs e) { OnMouseUpHandler?.Invoke(e); }
	public override void OnMouseMove(MouseEventArgs e) { OnMouseMoveHandler?.Invoke(e); }
	public override void OnMouseWheel(MouseWheelEventArgs e) { OnMouseWheelHandler?.Invoke(e); }

	// === Layout ===

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		MeasuredSize = .(wSpec.Resolve(256), hSpec.Resolve(256));
	}

	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		let newWidth = (uint32)Math.Max(1, right - left);
		let newHeight = (uint32)Math.Max(1, bottom - top);

		if (newWidth != mTextureWidth || newHeight != mTextureHeight)
			ResizeRenderTarget(newWidth, newHeight);
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		if (mIsRegistered && mTextureWidth > 0 && mTextureHeight > 0)
		{
			ctx.VG.DrawImage(mImageRef, .(0, 0, Width, Height),
				.(0, 0, mTextureWidth, mTextureHeight), .White);
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
