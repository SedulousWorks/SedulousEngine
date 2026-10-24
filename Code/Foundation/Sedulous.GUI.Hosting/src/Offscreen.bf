using System;
using System.Diagnostics;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RHI.Capture;
using Sedulous.VG;
using Sedulous.VG.Renderer;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// GuiOffscreen: a root drawn into a picture on the host's device.
//
// What a test or a tool draws with, not a window: the image tests' pictures, the bench's frames, a
// sweep's or an audit's. A target of a size and format of its own, a VG renderer and pass targets
// of its own (the bakes registered with it, as with a window's), drawn on an encoder and fence of
// its own and waited for, so a picture asked for is read back in the call. Each draw times its
// stages: the GUI's draw, the renderer's prepare, and the GPU's work with the wait.
//
// The device is idled before a draw: the host's windows may share the baker's frame slots.

class GuiOffscreen
{
	/// What a draw cost, in milliseconds.
	public struct Times
	{
		/// The GUI's draw into the canvas.
		public double Draw = 0.0;
		/// The renderer's upload.
		public double Prepare = 0.0;
		/// The GPU's work, waited for.
		public double Gpu = 0.0;

		public this() {}

		public this(double draw, double prepare, double gpu)
		{
			Draw = draw;
			Prepare = prepare;
			Gpu = gpu;
		}
	}

	private GuiHost mHost; // borrowed: it outlives this
	private VGRenderer mRenderer = new .() ~ delete _;
	private VGPassTargets mTargets = new .() ~ delete _;
	private VGContext mCanvas = null ~ delete _;
	private ITexture mTexture = null;
	private ITextureView mView = null;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;
	private ScreenshotCapture mCapture = new .() ~ delete _;
	private uint32 mWidth;
	private uint32 mHeight;
	private TextureFormat mFormat;
	private VGBlendSpace mSpace = .Linear;
	private bool mReady = false;

	/// A `width` by `height` target in `format` (one a picture can be read back from: 8-bit RGBA
	/// or BGRA), blending in `space`. The host is borrowed and outlives this.
	public this(GuiHost host, uint32 width, uint32 height, TextureFormat format = .RGBA8UnormSrgb, VGBlendSpace space = .Linear)
	{
		mHost = host;
		mWidth = width;
		mHeight = height;
		mFormat = format;
		mSpace = space;
		let device = host.mDevice.Raw;
		if ((device == null) || !host.mShaders.IsUsable || (width == 0) || (height == 0))
			return;
		var desc = TextureDesc.RenderTarget(format, width, height);
		desc.Usage = desc.Usage | .CopySrc;
		if (device.CreateTexture(desc) case .Ok(let texture))
			mTexture = texture;
		if ((mTexture != null) && (device.CreateTextureView(mTexture, .()) case .Ok(let view)))
			mView = view;
		if ((mView != null) && (device.CreateCommandPool(.Graphics) case .Ok(let pool)))
			mPool = pool;
		if ((mPool != null) && (device.CreateFence(0) case .Ok(let fence)))
			mFence = fence;
		if (mFence == null)
			return;
		mTargets.Configure(device);
		let targets = mTargets.Create(format, width, height);
		var config = targets ? mTargets.ConfigFor(space) : VGTargetConfig();
		config.BlendSpace = space;
		let shaders = host.mShaders;
		if (mRenderer.Initialize(device, shaders.Vertex, shaders.Fragment, format, 1, shaders.DistanceField, shaders.GradientRadial,
			shaders.GradientConic, config, shaders.BoxShadow, shaders.BoxVertex, shaders.BoxFragment, shaders.Layer,
			shaders.BlurVertex, shaders.BlurFragment) case .Err)
			return;
		mCanvas = new .(host.mFonts);
		mCanvas.SetPerPixelGradients((shaders.GradientRadial != null) && (shaders.GradientConic != null));
		mCanvas.SetAnalyticBoxes((shaders.BoxVertex != null) && (shaders.BoxFragment != null));
		mCanvas.SetLayers(shaders.Layer != null);
		mCanvas.SetStencilFills(mRenderer.StencilFillsSupported);
		if (host.EnsureBaker(format, space))
			host.mBaker.AddTarget(mRenderer);
		mReady = true;
	}

	public ~this()
	{
		// No early return: it would skip the fields' own deletes after this body.
		let device = mHost.mDevice.Raw;
		if (device != null)
			Release(device);
	}

	private void Release(IDevice device)
	{
		device.WaitIdle();
		mCapture.Release(device); // its read back buffer
		if (mHost.mBaker != null)
			mHost.mBaker.RemoveTarget(mRenderer);
		if (mRenderer.IsInitialized)
			mRenderer.Dispose();
		mTargets.Destroy();
		if (mFence != null)
			device.DestroyFence(ref mFence);
		if (mPool != null)
			device.DestroyCommandPool(ref mPool);
		if (mView != null)
			device.DestroyTextureView(ref mView);
		if (mTexture != null)
			device.DestroyTexture(ref mTexture);
	}

	public bool IsReady => mReady;
	public uint32 Width => mWidth;
	public uint32 Height => mHeight;
	/// The colour target the last draw went into (left in ShaderRead). This one's.
	public ITexture Texture => mTexture;

	/// `root` styled, laid out at this target's size (at its own display scale) and drawn, the
	/// GPU's work waited for. False when the target is not ready.
	public bool Draw(SceneRoot root)
	{
		var times = Times();
		return Render(root, default, null, ref times);
	}

	/// Draw, the stages timed into `times`.
	public bool Draw(SceneRoot root, out Times times)
	{
		times = .();
		return Render(root, default, null, ref times);
	}

	/// Draw, and the picture read back into `outImage` and written to `path` as a PNG.
	public bool Picture(SceneRoot root, StringView path, Sedulous.Image.Image outImage)
	{
		var times = Times();
		return Render(root, path, outImage, ref times);
	}

	/// Picture, the stages timed into `times`.
	public bool Picture(SceneRoot root, StringView path, Sedulous.Image.Image outImage, out Times times)
	{
		times = .();
		return Render(root, path, outImage, ref times);
	}

	private bool Render(SceneRoot root, StringView path, Sedulous.Image.Image outImage, ref Times times)
	{
		if (!mReady)
			return false;
		let device = mHost.mDevice.Raw;
		device.WaitIdle(); // the baker's frame slots are the windows' too
		root.ViewportSize = .((float)mWidth, (float)mHeight);
		mHost.StyleAndLayOut(root);
		root.NeedsFrame(); // closes the frame's stats, as a window's frame does

		let drawWatch = scope Stopwatch(true);
		mCanvas.Clear();
		{
			let context = scope DrawContext(mCanvas);
			root.DrawFrame(context);
		}
		let drawMs = drawWatch.Elapsed.TotalMilliseconds;

		mPool.Reset();
		ICommandEncoder encoder = null;
		if (mPool.CreateEncoder() case .Ok(let made))
			encoder = made;
		if (encoder == null)
			return false;
		if ((mHost.mBaker != null) && mHost.mBakerReady)
			mHost.mBaker.Record(encoder, 0);
		let prepareWatch = scope Stopwatch(true);
		mRenderer.BeginFrame(0);
		let slice = mRenderer.Prepare(mCanvas.GetBatch(), 0, mWidth, mHeight);
		let prepareMs = prepareWatch.Elapsed.TotalMilliseconds;
		let gpuWatch = scope Stopwatch(true);
		mRenderer.RenderLayers(encoder, 0, slice);
		encoder.TransitionTexture(mTexture, .Undefined, .RenderTarget);
		let background = mHost.mClear;
		let clear = (mSpace == .Encoded)
			? ClearColor(background.R, background.G, background.B, background.A)
			: ClearColor(SrgbToLinear(background.R), SrgbToLinear(background.G), SrgbToLinear(background.B), background.A);
		var pass = RenderPassDesc();
		if (mTargets.Matches(mWidth, mHeight))
			pass = mTargets.BeginPass(encoder, mView, clear, "GUI offscreen");
		else
		{
			var color = ColorAttachment();
			color.View = mView;
			color.LoadOp = .Clear;
			color.StoreOp = .Store;
			color.ClearValue = clear;
			pass.ColorAttachments.Add(color);
		}
		if (let passEncoder = encoder.BeginRenderPass(pass))
		{
			mRenderer.Render(passEncoder, mWidth, mHeight, 0, slice);
			passEncoder.End();
		}
		bool recorded = true;
		if (outImage != null)
		{
			mCapture.Request(path);
			recorded = mCapture.Record(device, encoder, mTexture, mFormat, mWidth, mHeight);
		}
		encoder.TransitionTexture(mTexture, .RenderTarget, .ShaderRead);
		let commands = encoder.Finish();
		var buffers = ICommandBuffer[1](commands);
		mFenceValue++;
		device.GetQueue(.Graphics, 0).Submit(buffers, mFence, mFenceValue);
		mFence.Wait(mFenceValue, uint64.MaxValue);
		let gpuMs = gpuWatch.Elapsed.TotalMilliseconds;
		mPool.DestroyEncoder(ref encoder);
		times = .(drawMs, prepareMs, gpuMs);
		return (outImage == null) || (recorded && (mCapture.Complete(device, outImage) case .Ok));
	}
}
