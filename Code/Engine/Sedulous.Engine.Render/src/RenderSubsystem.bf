namespace Sedulous.Engine.Render;

using System;
using Sedulous.Runtime;
using Sedulous.Scenes;
using Sedulous.Engine;
using Sedulous.RHI;
using Sedulous.Shell;
using Sedulous.Shaders;
using Sedulous.Renderer;
using Sedulous.Renderer.Passes;
using Sedulous.Core.Mathematics;

/// Owns the renderer pipeline, swapchain, command pools, and GPU frame pacing.
/// Runs late (UpdateOrder 500) — all scene updates and extraction are complete by this point.
/// Injects render component managers (Mesh, Light, Camera, etc.) into scenes via ISceneAware.
///
/// The pipeline renders to its own output texture. This subsystem blits it to the swapchain.
class RenderSubsystem : Subsystem, ISceneAware, IWindowAware
{
	private const int MAX_FRAMES_IN_FLIGHT = 2;

	// Set by EngineApplication before context startup
	private IDevice mDevice;
	private IWindow mWindow;
	private ISurface mSurface;
	private TextureFormat mSwapChainFormat = .BGRA8UnormSrgb;
	private PresentMode mPresentMode = .Fifo;

	// Frame pacing
	private ISwapChain mSwapChain;
	private IQueue mGraphicsQueue;
	private ICommandPool[MAX_FRAMES_IN_FLIGHT] mCommandPools;
	private IFence mFrameFence;
	private uint64 mNextFenceValue = 1;
	private uint64[MAX_FRAMES_IN_FLIGHT] mFrameFenceValues;

	// Pipeline
	private Pipeline mPipeline ~ delete _;

	// Blit helper (fullscreen triangle to copy pipeline output → swapchain)
	private BlitHelper mBlitHelper ~ delete _;

	// Extraction
	private ExtractedRenderData mExtractedData ~ delete _;

	// Per-frame state
	private int32 mFrameIndex = 0;
	private RenderView mRenderView = new .() ~ delete _;

	// Timing
	private float mDeltaTime;
	private float mTotalTime;

	public override int32 UpdateOrder => 500;

	// ==================== Properties (set by app before startup) ====================

	public IDevice Device { get => mDevice; set => mDevice = value; }
	public IWindow Window { get => mWindow; set => mWindow = value; }
	public ISurface Surface { get => mSurface; set => mSurface = value; }
	public TextureFormat SwapChainFormat { get => mSwapChainFormat; set => mSwapChainFormat = value; }
	public PresentMode PresentMode { get => mPresentMode; set => mPresentMode = value; }

	/// Shader system (set by app, not owned).
	public ShaderSystem ShaderSystem { get; set; }

	/// Asset directory (set by app, not owned).
	public String AssetDirectory { get; set; }

	public ISwapChain SwapChain => mSwapChain;
	public IQueue GraphicsQueue => mGraphicsQueue;
	public Pipeline Pipeline => mPipeline;

	/// TEMPORARY: Set by the app to provide render data until scene extraction is fully wired.
	/// When set, this overrides scene extraction. Set to null to use scene extraction.
	public ExtractedRenderData FrameRenderDataOverride { get; set; }

	// ==================== Lifecycle ====================

	protected override void OnInit()
	{
		if (mDevice == null || mSurface == null || mWindow == null)
			return;

		// Swapchain
		SwapChainDesc desc = .()
		{
			Width = (uint32)mWindow.Width,
			Height = (uint32)mWindow.Height,
			Format = mSwapChainFormat,
			PresentMode = mPresentMode
		};

		if (mDevice.CreateSwapChain(mSurface, desc) case .Ok(let swapChain))
			mSwapChain = swapChain;

		// Graphics queue
		mGraphicsQueue = mDevice.GetQueue(.Graphics);

		// Per-frame command pools
		for (int i = 0; i < MAX_FRAMES_IN_FLIGHT; i++)
		{
			if (mDevice.CreateCommandPool(.Graphics) case .Ok(let pool))
				mCommandPools[i] = pool;
		}

		// Frame fence
		if (mDevice.CreateFence(0) case .Ok(let fence))
			mFrameFence = fence;

		// Pipeline
		mPipeline = new Pipeline();
		mPipeline.Initialize(mDevice, mGraphicsQueue, (uint32)mWindow.Width, (uint32)mWindow.Height);
		mPipeline.ShaderSystem = ShaderSystem;

		// Register default passes
		mPipeline.AddPass(new DepthPrepass());
		mPipeline.AddPass(new ForwardOpaquePass());
		mPipeline.AddPass(new SkyPass());

		// Blit helper (copies pipeline output to swapchain)
		if (ShaderSystem != null)
		{
			mBlitHelper = new BlitHelper();
			mBlitHelper.Initialize(mDevice, mSwapChainFormat, ShaderSystem);
		}

		// Extraction buffer
		mExtractedData = new ExtractedRenderData();
	}

	protected override void OnShutdown()
	{
		if (mDevice == null)
			return;

		mDevice.WaitIdle();

		// Destroy blit helper
		if (mBlitHelper != null)
			mBlitHelper.Dispose();

		// Shutdown pipeline
		if (mPipeline != null)
			mPipeline.Shutdown();

		// Frame pacing resources
		for (int i = 0; i < MAX_FRAMES_IN_FLIGHT; i++)
		{
			if (mCommandPools[i] != null)
				mDevice.DestroyCommandPool(ref mCommandPools[i]);
		}

		if (mFrameFence != null)
			mDevice.DestroyFence(ref mFrameFence);

		if (mSwapChain != null)
			mDevice.DestroySwapChain(ref mSwapChain);
	}

	// ==================== Frame ====================

	public override void BeginFrame(float deltaTime)
	{
		mDeltaTime = deltaTime;
		mTotalTime += deltaTime;
	}

	public override void EndFrame()
	{
		if (mDevice == null || mSwapChain == null || mPipeline == null)
			return;

		if (mWindow.State == .Minimized)
			return;

		mFrameIndex = (int32)mSwapChain.CurrentImageIndex;

		// Wait for this frame's previous GPU work
		if (mFrameFenceValues[mFrameIndex] > 0)
			mFrameFence.Wait(mFrameFenceValues[mFrameIndex]);

		mCommandPools[mFrameIndex].Reset();

		// Acquire swapchain image
		if (mSwapChain.AcquireNextImage() case .Err)
		{
			OnWindowResized(mWindow, mWindow.Width, mWindow.Height);
			return;
		}

		let pool = mCommandPools[mFrameIndex];
		var encoder = pool.CreateEncoder().Value;

		// Get render data — either from override (temporary) or scene extraction
		ExtractedRenderData renderData;
		if (FrameRenderDataOverride != null)
		{
			renderData = FrameRenderDataOverride;
		}
		else
		{
			renderData = ExtractFromScenes();
		}

		// Build RenderView from camera + extracted data
		SetupRenderView(renderData);

		// Render to pipeline output
		mPipeline.Render(encoder, mRenderView);

		// Blit pipeline output → swapchain
		BlitToSwapchain(encoder);

		// Transition swapchain to present
		encoder.TransitionTexture(mSwapChain.CurrentTexture, .RenderTarget, .Present);

		let commandBuffer = encoder.Finish();

		// Submit + present
		mFrameFenceValues[mFrameIndex] = mNextFenceValue++;
		ICommandBuffer[1] bufs = .(commandBuffer);
		mGraphicsQueue.Submit(bufs, mFrameFence, mFrameFenceValues[mFrameIndex]);

		if (mSwapChain.Present(mGraphicsQueue) case .Err)
			OnWindowResized(mWindow, mWindow.Width, mWindow.Height);

		pool.DestroyEncoder(ref encoder);
	}

	// ==================== Extraction ====================

	/// Extracts render data from all active scenes via IRenderDataProvider.
	private ExtractedRenderData ExtractFromScenes()
	{
		mExtractedData.Clear();

		// Find camera for view setup
		CameraComponent activeCamera = null;
		Scene cameraScene = null;

		let sceneSub = Context?.GetSubsystem<SceneSubsystem>();
		if (sceneSub == null)
			return mExtractedData;

		// First pass: find active camera
		for (let scene in sceneSub.ActiveScenes)
		{
			let cameraMgr = scene.GetModule<CameraComponentManager>();
			if (cameraMgr != null)
			{
				let camera = cameraMgr.GetActiveCamera();
				if (camera != null)
				{
					activeCamera = camera;
					cameraScene = scene;
					break;
				}
			}
		}

		// Build extraction context
		let viewportAspect = (mPipeline.OutputHeight > 0) ?
			(float)mPipeline.OutputWidth / (float)mPipeline.OutputHeight : 1.0f;

		Matrix viewMatrix = .Identity;
		Matrix projMatrix = .Identity;
		Vector3 cameraPos = .Zero;
		float nearPlane = 0.1f;
		float farPlane = 1000.0f;

		if (activeCamera != null && cameraScene != null)
		{
			viewMatrix = activeCamera.GetViewMatrix(cameraScene);
			projMatrix = activeCamera.GetProjectionMatrix(viewportAspect);
			cameraPos = cameraScene.GetWorldMatrix(activeCamera.Owner).Translation;
			nearPlane = activeCamera.NearPlane;
			farPlane = activeCamera.FarPlane;
		}

		let viewProjMatrix = viewMatrix * projMatrix;

		mExtractedData.SetView(viewMatrix, projMatrix, cameraPos,
			nearPlane, farPlane, mPipeline.OutputWidth, mPipeline.OutputHeight);

		RenderExtractionContext context = .()
		{
			RenderData = mExtractedData,
			ViewMatrix = viewMatrix,
			ViewProjectionMatrix = viewProjMatrix,
			CameraPosition = cameraPos,
			NearPlane = nearPlane,
			FarPlane = farPlane,
			FrameIndex = mFrameIndex,
			LayerMask = 0xFFFFFFFF,
			LODBias = 0
		};

		// Second pass: extract render data from all scenes
		for (let scene in sceneSub.ActiveScenes)
		{
			for (let module in scene.Modules)
			{
				if (let provider = module as IRenderDataProvider)
					provider.ExtractRenderData(context);
			}
		}

		mExtractedData.SortAndBatch();

		return mExtractedData;
	}

	/// Builds the RenderView from camera data and extracted render data.
	private void SetupRenderView(ExtractedRenderData renderData)
	{
		mRenderView.ViewMatrix = renderData.ViewMatrix;
		mRenderView.ProjectionMatrix = renderData.ProjectionMatrix;
		mRenderView.ViewProjectionMatrix = renderData.ViewProjectionMatrix;
		mRenderView.CameraPosition = renderData.CameraPosition;
		mRenderView.NearPlane = renderData.NearPlane;
		mRenderView.FarPlane = renderData.FarPlane;
		mRenderView.Width = mPipeline.OutputWidth;
		mRenderView.Height = mPipeline.OutputHeight;
		mRenderView.FrameIndex = mFrameIndex;
		mRenderView.DeltaTime = mDeltaTime;
		mRenderView.TotalTime = mTotalTime;
		mRenderView.RenderData = renderData;
	}

	/// Blits the pipeline output texture to the swapchain backbuffer.
	private void BlitToSwapchain(ICommandEncoder encoder)
	{
		let sourceView = mPipeline.OutputTextureView;
		if (sourceView == null || mBlitHelper == null || !mBlitHelper.IsReady)
			return;

		encoder.TransitionTexture(mPipeline.OutputTexture, .RenderTarget, .ShaderRead);

		ColorAttachment[1] colorAttachments = .(.()
		{
			View = mSwapChain.CurrentTextureView,
			LoadOp = .DontCare,
			StoreOp = .Store
		});

		RenderPassDesc passDesc = .() { ColorAttachments = .(colorAttachments) };
		let renderPass = encoder.BeginRenderPass(passDesc);

		mBlitHelper.Blit(renderPass, sourceView, mSwapChain.Width, mSwapChain.Height, mFrameIndex);

		renderPass.End();
	}

	// ==================== Scene Injection ====================

	public void OnSceneCreated(Scene scene)
	{
		let meshMgr = new MeshComponentManager();
		meshMgr.GPUResources = mPipeline?.GPUResources;
		scene.AddModule(meshMgr);

		scene.AddModule(new CameraComponentManager());
		scene.AddModule(new LightComponentManager());
	}

	public void OnSceneDestroyed(Scene scene)
	{
	}

	// ==================== IWindowAware ====================

	public void OnWindowResized(IWindow window, int32 width, int32 height)
	{
		if (width == 0 || height == 0 || mDevice == null || mSwapChain == null)
			return;

		mDevice.WaitIdle();
		mSwapChain.Resize((uint32)width, (uint32)height);

		if (mPipeline != null)
			mPipeline.OnResize((uint32)width, (uint32)height);
	}
}
