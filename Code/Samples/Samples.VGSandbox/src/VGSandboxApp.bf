using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.Shaders;
using Sedulous.VG;
using Sedulous.VG.Renderer;
using Samples.Framework;

namespace Samples.VGSandbox;

/// The whole vector graphics stack end to end, in the style of NanoVG's demo.
///
/// Per frame: a scene draws into a VGContext, the context's batch goes through the
/// VGRenderer, and the renderer records into one render pass. The pass renders into a four
/// sample colour target with a stencil attachment and resolves into the swap chain, because
/// the stencil is what makes the self intersecting fills correct and the multisampling is
/// what makes the moving edges clean.
class VGSandboxApp : SampleApp
{
	private const int32 cFrames = 2;

	private ShaderSystemHost mShaderHost = null ~ delete _;
	/// BORROWED from the shader host, which owns and frees the modules.
	private IShaderModule mVertexShader;
	private IShaderModule mFragmentShader;
	private IShaderModule mDistanceFieldFragmentShader;
	private IShaderModule mRadialGradientFragmentShader;
	private IShaderModule mConicGradientFragmentShader;
	private IShaderModule mBoxShadowFragmentShader;

	private ITexture mMultisampleColor = null;
	private ITextureView mMultisampleColorView = null;
	private ITexture mDepthStencil = null;
	private ITextureView mDepthStencilView = null;
	/// Whether the renderer was brought up with multisampling and a stencil.
	private bool mQuality = false;

	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;
	private int32 mFrameIndex = 0;

	private SandboxScene mScene = null ~ delete _;
	private VGContext mVG = null ~ delete _;
	private VGRenderer mRenderer = new VGRenderer() ~ delete _;

	public this()
	{
		mWidth = 1000;
		mHeight = 720;
	}

	protected override StringView Title => "VG Sandbox";
	protected override uint32 BufferCount => cFrames;

	protected override Result<void> OnInit()
	{
		// The VG shaders come out of the engine corpus, resolved the same way the runtime
		// UI resolves them, rather than being compiled from a string in this file.
		let shaderRoot = scope String();
		if (!SandboxContent.FindDirectory(SandboxContent.cShaderRoot, shaderRoot))
		{
			Console.Error.WriteLine(scope $"VGSandbox: '{SandboxContent.cShaderRoot}' was not found");
			return .Err;
		}

		mShaderHost = new ShaderSystemHost();
		if (mShaderHost.Initialize(mDevice, shaderRoot) case .Err)
			return .Err;

		mVertexShader = mShaderHost.GetVariant("vg", .Vertex, .None);
		mFragmentShader = mShaderHost.GetVariant("vg", .Fragment, .None);
		mDistanceFieldFragmentShader = mShaderHost.GetVariant("vg_df", .Fragment, .None);
		mRadialGradientFragmentShader = mShaderHost.GetVariant("vg_grad_radial", .Fragment, .None);
		mConicGradientFragmentShader = mShaderHost.GetVariant("vg_grad_conic", .Fragment, .None);
		mBoxShadowFragmentShader = mShaderHost.GetVariant("vg_shadow", .Fragment, .None);
		if ((mVertexShader == null) || (mFragmentShader == null)
			|| (mDistanceFieldFragmentShader == null) || (mRadialGradientFragmentShader == null)
			|| (mConicGradientFragmentShader == null) || (mBoxShadowFragmentShader == null))
		{
			Console.Error.WriteLine("VGSandbox: a VG shader variant did not resolve");
			return .Err;
		}

		// Four sample colour plus a stencil. Failing that, which would be unusual on a
		// desktop adapter, falls back to a plain single sampled pass with tessellated fills.
		var targetConfig = VGTargetConfig();
		if (CreateQualityTargets())
		{
			mQuality = true;
			targetConfig.SampleCount = 4;
			targetConfig.DepthStencilFormat = .Depth24PlusStencil8;
		}

		if (mRenderer.Initialize(mDevice, mVertexShader, mFragmentShader, mSwapChain.Format,
			cFrames, mDistanceFieldFragmentShader, mRadialGradientFragmentShader,
			mConicGradientFragmentShader, targetConfig, mBoxShadowFragmentShader) case .Err)
			return .Err;

		if (!(mDevice.CreateCommandPool(.Graphics) case .Ok(let pool)))
			return .Err;
		mPool = pool;
		if (!(mDevice.CreateFence(0) case .Ok(let fence)))
			return .Err;
		mFence = fence;

		mScene = new SandboxScene();
		mScene.Initialize();

		mVG = new VGContext(mScene.FontService);
		// The renderer was given the radial and conic shaders above, so the gradients can
		// take their exact per pixel falloff rather than the affine ramp approximation.
		mVG.SetPerPixelGradients(true);
		mVG.SetStencilFills(mRenderer.StencilFillsSupported);
		return .Ok;
	}

	protected override void OnRender()
	{
		if (mFenceValue > 0)
			mFence.Wait(mFenceValue);
		// A failed recreate leaves no four sample target, and the pipelines cannot draw a
		// single sampled pass.
		if (mQuality && (mMultisampleColorView == null))
			return;
		if (mSwapChain.AcquireNextImage() case .Err)
			return;

		mVG.Clear();
		mScene.Draw(mVG, (float)mWidth, (float)mHeight, mTotalTime);

		mRenderer.BeginFrame(mFrameIndex);
		let slice = mRenderer.Prepare(mVG.GetBatch(), mFrameIndex, mWidth, mHeight);

		mPool.Reset();
		if (!(mPool.CreateEncoder() case .Ok(var encoder)))
			return;

		encoder.TransitionTexture(mSwapChain.CurrentTexture, .Undefined, .RenderTarget);
		// The offscreen attachments need the same explicit transitions the swap chain gets:
		// the backend does not transition a pass's attachments on its own. From Undefined
		// every frame, because both are fully cleared and the old contents are discardable.
		if (mMultisampleColor != null)
		{
			encoder.TransitionTexture(mMultisampleColor, .Undefined, .RenderTarget);
			encoder.TransitionTexture(mDepthStencil, .Undefined, .DepthStencilWrite);
		}

		var colorAttachment = ColorAttachment();
		colorAttachment.LoadOp = .Clear;
		colorAttachment.StoreOp = .Store;
		colorAttachment.ClearValue = .(0.19f, 0.19f, 0.21f, 1.0f);

		var passDesc = RenderPassDesc();
		if (mMultisampleColorView != null)
		{
			colorAttachment.View = mMultisampleColorView;
			colorAttachment.ResolveTarget = mSwapChain.CurrentTextureView;
			// Resolved as the pass ends, so the multisampled texels themselves can go.
			colorAttachment.StoreOp = .DontCare;

			var depthStencil = DepthStencilAttachment();
			depthStencil.View = mDepthStencilView;
			depthStencil.DepthLoadOp = .Clear;
			depthStencil.DepthStoreOp = .DontCare;
			// Stencil then cover starts from zero.
			depthStencil.StencilLoadOp = .Clear;
			depthStencil.StencilStoreOp = .DontCare;
			depthStencil.StencilClearValue = 0;
			passDesc.DepthStencilAttachment = depthStencil;
		}
		else
		{
			colorAttachment.View = mSwapChain.CurrentTextureView;
		}
		passDesc.ColorAttachments.Add(colorAttachment);

		let pass = encoder.BeginRenderPass(passDesc);
		mRenderer.Render(pass, mWidth, mHeight, mFrameIndex, slice);
		pass.End();

		encoder.TransitionTexture(mSwapChain.CurrentTexture, .RenderTarget, .Present);

		let commandBuffer = encoder.Finish();
		mFenceValue++;
		var buffers = ICommandBuffer[1](commandBuffer);
		mGraphicsQueue.Submit(buffers, mFence, mFenceValue);
		mSwapChain.Present(mGraphicsQueue).IgnoreError();
		mPool.DestroyEncoder(ref encoder);

		mFrameIndex = (mFrameIndex + 1) % cFrames;
	}

	/// The multisampled colour target and the stencil, at the window's size.
	private bool CreateQualityTargets()
	{
		var colorDesc = TextureDesc.RenderTarget(mSwapChain.Format, mWidth, mHeight, 4,
			"VG MSAA color");

		var depthDesc = TextureDesc();
		depthDesc.Dimension = .Texture2D;
		depthDesc.Format = .Depth24PlusStencil8;
		depthDesc.Width = mWidth;
		depthDesc.Height = mHeight;
		depthDesc.Depth = 1;
		depthDesc.Usage = .DepthStencil;
		depthDesc.SampleCount = 4;
		depthDesc.Label = "VG stencil";

		if ((mDevice.CreateTexture(colorDesc) case .Ok(let color))
			&& (mDevice.CreateTexture(depthDesc) case .Ok(let depth)))
		{
			mMultisampleColor = color;
			mDepthStencil = depth;

			if ((mDevice.CreateTextureView(mMultisampleColor, .()) case .Ok(let colorView))
				&& (mDevice.CreateTextureView(mDepthStencil, .()) case .Ok(let depthView)))
			{
				mMultisampleColorView = colorView;
				mDepthStencilView = depthView;
				return true;
			}
		}

		DestroyQualityTargets();
		return false;
	}

	private void DestroyQualityTargets()
	{
		if (mMultisampleColorView != null) mDevice.DestroyTextureView(ref mMultisampleColorView);
		if (mMultisampleColor != null) mDevice.DestroyTexture(ref mMultisampleColor);
		if (mDepthStencilView != null) mDevice.DestroyTextureView(ref mDepthStencilView);
		if (mDepthStencil != null) mDevice.DestroyTexture(ref mDepthStencil);

		mMultisampleColorView = null;
		mMultisampleColor = null;
		mDepthStencilView = null;
		mDepthStencil = null;
	}

	protected override void OnResize(uint32 width, uint32 height)
	{
		// The framework has already idled the device and resized the swap chain. The
		// offscreen targets must follow, or the resolve out of an old sized target leaves
		// the grown region black. The pipelines themselves are size agnostic.
		if (!mQuality)
			return;

		DestroyQualityTargets();
		if (!CreateQualityTargets())
			Console.Error.WriteLine("VGSandbox: the quality targets could not be recreated, so frames are skipped");
	}

	protected override void OnShutdown()
	{
		if (mDevice != null)
			mDevice.WaitIdle();

		mRenderer.Dispose();
		DestroyQualityTargets();

		// The context borrows the scene's font service, so it goes first.
		delete mVG;
		mVG = null;
		delete mScene;
		mScene = null;

		if (mFence != null) mDevice.DestroyFence(ref mFence);
		if (mPool != null) mDevice.DestroyCommandPool(ref mPool);

		// The shader modules are BORROWED from the host's shader system, which frees them.
		// Null when initialization failed before the host was built, which is a shutdown
		// that still has to run.
		if (mShaderHost != null)
			mShaderHost.Shutdown();
	}
}
