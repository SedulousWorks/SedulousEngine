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
using Sedulous.Renderer.Renderers;
using Sedulous.Renderer.Shadows;
using Sedulous.Core.Mathematics;
using Sedulous.Profiler;
using Sedulous.Resources;
using Sedulous.Geometry.Resources;
using Sedulous.Textures.Resources;
using Sedulous.Materials.Resources;
using System.Collections;

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

	// Renderer (shared infrastructure)
	private RenderContext mRenderContext ~ delete _;

	// Pipeline (per-view pass execution)
	private Pipeline mPipeline ~ delete _;

	// Shadow pipeline (renders depth into the shared shadow atlas, one call per shadow caster)
	private ShadowPipeline mShadowPipeline ~ delete _;

	// Blit helper (fullscreen triangle to copy pipeline output → swapchain)
	private BlitHelper mBlitHelper ~ delete _;

	// Resource managers (registered with Context.Resources)
	private StaticMeshResourceManager mStaticMeshManager ~ delete _;
	private SkinnedMeshResourceManager mSkinnedMeshManager ~ delete _;
	private TextureResourceManager mTextureManager ~ delete _;
	private MaterialResourceManager mMaterialManager ~ delete _;

	// Shared resource resolver
	private RenderResourceResolver mResolver ~ delete _;

	// Per-view extraction (one RenderView per frame view: main + shadow casters)
	private RenderViewPool mViewPool = new .() ~ delete _;

	// Per-frame list of shadow render jobs (cleared each frame in SetupShadows).
	private List<ShadowPipeline.ShadowJob> mShadowDraws = new .() ~ delete _;

	// Per-frame state
	private int32 mFrameIndex = 0;

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
	public RenderContext RenderContext => mRenderContext;
	public Pipeline Pipeline => mPipeline;

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

		// Renderer (shared infrastructure)
		mRenderContext = new RenderContext();
		mRenderContext.Initialize(mDevice, mGraphicsQueue);
		mRenderContext.ShaderSystem = ShaderSystem;

		// Register per-type drawers on the shared context. Both the main Pipeline
		// and the ShadowPipeline dispatch through these.
		mRenderContext.RegisterRenderer(new MeshRenderer());

		// Pipeline (per-view pass execution)
		mPipeline = new Pipeline();
		mPipeline.Initialize(mRenderContext, (uint32)mWindow.Width, (uint32)mWindow.Height);

		// Shadow pipeline (separate per-view pipeline that renders into the shared atlas)
		mShadowPipeline = new ShadowPipeline();
		mShadowPipeline.Initialize(mRenderContext);

		// Register default passes
		mPipeline.AddPass(new SkinningPass());
		mPipeline.AddPass(new DepthPrepass());
		mPipeline.AddPass(new ForwardOpaquePass());
		mPipeline.AddPass(new ForwardTransparentPass());
		mPipeline.AddPass(new SkyPass());

		// Post-processing stack
		let postStack = new PostProcessStack();
		postStack.Initialize(mRenderContext);
		postStack.AddEffect(new TonemapEffect());
		mPipeline.PostProcessStack = postStack;

		// Blit helper (copies pipeline output to swapchain)
		if (ShaderSystem != null)
		{
			mBlitHelper = new BlitHelper();
			mBlitHelper.Initialize(mDevice, mSwapChainFormat, ShaderSystem);
		}


		// Register resource managers with the resource system
		mStaticMeshManager = new StaticMeshResourceManager();
		mSkinnedMeshManager = new SkinnedMeshResourceManager();
		mTextureManager = new TextureResourceManager();
		mMaterialManager = new MaterialResourceManager();

		Context.Resources.AddResourceManager(mStaticMeshManager);
		Context.Resources.AddResourceManager(mSkinnedMeshManager);
		Context.Resources.AddResourceManager(mTextureManager);
		Context.Resources.AddResourceManager(mMaterialManager);

		// Shared resource resolver
		mResolver = new RenderResourceResolver(Context.Resources, mRenderContext.GPUResources, mRenderContext.MaterialSystem);
	}

	protected override void OnShutdown()
	{
		if (mDevice == null)
			return;

		mDevice.WaitIdle();

		// Unregister resource managers
		if (mStaticMeshManager != null)
			Context.Resources.RemoveResourceManager(mStaticMeshManager);
		if (mSkinnedMeshManager != null)
			Context.Resources.RemoveResourceManager(mSkinnedMeshManager);
		if (mTextureManager != null)
			Context.Resources.RemoveResourceManager(mTextureManager);
		if (mMaterialManager != null)
			Context.Resources.RemoveResourceManager(mMaterialManager);

		// Destroy blit helper
		if (mBlitHelper != null)
			mBlitHelper.Dispose();

		// Shutdown pipelines then renderer (pipelines first — they reference renderer)
		if (mShadowPipeline != null)
			mShadowPipeline.Shutdown();
		if (mPipeline != null)
			mPipeline.Shutdown();
		if (mRenderContext != null)
			mRenderContext.Shutdown();

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

		// Reset the view pool first — drops references to last frame's arena entries
		// before BeginFrame() rewinds the frame allocator.
		mViewPool.BeginFrame();
		mRenderContext.BeginFrame();

		// Acquire and populate the main view from the active camera.
		let mainView = mViewPool.Acquire();
		using (Profiler.Begin("SceneExtraction"))
			ExtractMainView(mainView);

		// Allocate shadow maps for shadow-casting lights from the main view, build
		// per-shadow RenderViews, and extract them.
		using (Profiler.Begin("ShadowSetup"))
			SetupShadows(mainView);

		// Reset per-frame ring buffer offsets before any Render() calls this frame.
		mPipeline.BeginFrame(mFrameIndex);
		mShadowPipeline.BeginFrame(mFrameIndex);

		// Render shadow views first (main forward pass samples the atlas).
		using (Profiler.Begin("ShadowRender"))
			RenderShadows(encoder);

		// Render to pipeline output
		mPipeline.Render(encoder, mainView);

		// Blit pipeline output → swapchain
		using (Profiler.Begin("Blit"))
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

	/// Populates the main view from the active camera and extracts render data into it.
	private void ExtractMainView(RenderView view)
	{
		// Find camera for view setup
		CameraComponent activeCamera = null;
		Scene cameraScene = null;

		let sceneSub = Context?.GetSubsystem<SceneSubsystem>();
		if (sceneSub == null)
			return;

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

		view.ViewMatrix = viewMatrix;
		view.ProjectionMatrix = projMatrix;
		view.ViewProjectionMatrix = viewMatrix * projMatrix;
		view.CameraPosition = cameraPos;
		view.NearPlane = nearPlane;
		view.FarPlane = farPlane;
		view.Width = mPipeline.OutputWidth;
		view.Height = mPipeline.OutputHeight;
		view.FrameIndex = mFrameIndex;
		view.DeltaTime = mDeltaTime;
		view.TotalTime = mTotalTime;

		ExtractIntoView(view);
	}

	/// Runs all IRenderDataProvider modules against the given view, populating
	/// view.RenderData. Future per-view culling (frustum, layer mask) plugs in here.
	private void ExtractIntoView(RenderView view)
	{
		view.RenderData.SetView(view.ViewMatrix, view.ProjectionMatrix, view.CameraPosition,
			view.NearPlane, view.FarPlane, view.Width, view.Height);

		RenderExtractionContext context = .()
		{
			RenderContext = mRenderContext,
			RenderData = view.RenderData,
			ViewMatrix = view.ViewMatrix,
			ViewProjectionMatrix = view.ViewProjectionMatrix,
			CameraPosition = view.CameraPosition,
			NearPlane = view.NearPlane,
			FarPlane = view.FarPlane,
			FrameIndex = mFrameIndex,
			LayerMask = 0xFFFFFFFF,
			LODBias = 0
		};

		let sceneSub = Context?.GetSubsystem<SceneSubsystem>();
		if (sceneSub == null)
			return;

		for (let scene in sceneSub.ActiveScenes)
		{
			for (let module in scene.Modules)
			{
				if (let provider = module as IRenderDataProvider)
					provider.ExtractRenderData(context);
			}
		}

		view.RenderData.SortAndBatch();
	}


	/// Allocates atlas regions for all shadow-casting lights in the main view, builds
	/// per-shadow RenderViews, extracts each, and uploads shadow data to the GPU.
	private void SetupShadows(RenderView mainView)
	{
		mShadowDraws.Clear();

		let shadowSystem = mRenderContext.ShadowSystem;
		if (shadowSystem == null) return;

		let lights = mainView.RenderData.Lights;
		if (lights == null || lights.Count == 0)
		{
			shadowSystem.Upload(mFrameIndex);
			return;
		}

		// Pass 1: directional lights (need 4 contiguous cells per light, easier to satisfy first).
		for (let entry in lights)
		{
			let light = entry as LightRenderData;
			if (light == null || !light.CastsShadows || light.Type != .Directional)
				continue;
			AllocateDirectionalShadow(light, mainView, shadowSystem);
		}

		// Pass 2: spot lights (single cell each).
		for (let entry in lights)
		{
			let light = entry as LightRenderData;
			if (light == null || !light.CastsShadows || light.Type != .Spot)
				continue;
			AllocateSpotShadow(light, shadowSystem);
		}

		shadowSystem.Upload(mFrameIndex);
	}

	/// Allocates and queues a single shadow map for a spot light.
	private void AllocateSpotShadow(LightRenderData light, ShadowSystem shadowSystem)
	{
		ShadowAtlasRegion region;
		int32 shadowIdx;
		if (shadowSystem.AllocateShadow(out region) case .Ok(let idx))
			shadowIdx = idx;
		else
			return;

		let lightVP = ShadowMatrices.SpotLightViewProj(light);
		let invShadowMapSize = 1.0f / (float)shadowSystem.Atlas.CellSize;

		GPUShadowData data = .()
		{
			LightViewProj = lightVP,
			AtlasUVRect = region.UVRect,
			CascadeSplits = .Zero,
			Bias = light.ShadowBias,
			NormalBias = light.ShadowNormalBias,
			InvShadowMapSize = invShadowMapSize,
			CascadeCount = 0,
			// Spot lights: rough world texel size = range / cellSize (not exact but
			// close enough for the normal-offset bias).
			WorldTexelSize = light.Range / (float)shadowSystem.Atlas.CellSize
		};
		shadowSystem.SetShadowData(shadowIdx, data);

		light.ShadowIndex = shadowIdx;

		let shadowView = mViewPool.Acquire();
		shadowView.ViewMatrix = .Identity;
		shadowView.ProjectionMatrix = lightVP;
		shadowView.ViewProjectionMatrix = lightVP;
		shadowView.CameraPosition = light.Position;
		shadowView.NearPlane = 0.1f;
		shadowView.FarPlane = Math.Max(light.Range, 0.2f);
		shadowView.Width = region.Width;
		shadowView.Height = region.Height;
		shadowView.FrameIndex = mFrameIndex;
		shadowView.DeltaTime = mDeltaTime;
		shadowView.TotalTime = mTotalTime;

		ExtractIntoView(shadowView);

		mShadowDraws.Add(ShadowPipeline.ShadowJob() { View = shadowView, Region = region });
	}

	/// Allocates and queues 4 cascade shadow maps for a directional light.
	/// The base GPUShadowData entry holds CascadeCount + CascadeSplits so the
	/// fragment shader can pick the right cascade by view-space depth.
	private void AllocateDirectionalShadow(LightRenderData light, RenderView mainView, ShadowSystem shadowSystem)
	{
		let cascadeCount = ShadowConstants.MaxCascades;

		// Need 4 contiguous shadow data entries AND 4 contiguous atlas cells.
		uint32 baseCell;
		if (shadowSystem.Atlas.AllocateContiguous((uint32)cascadeCount) case .Ok(let cell))
			baseCell = cell;
		else
			return;

		// Reserve 4 shadow data slots (one per cascade). Atlas cells were already
		// allocated above; ReserveShadowSlot only takes data buffer slots.
		int32 baseShadowIdx = -1;
		ShadowAtlasRegion[ShadowConstants.MaxCascades] regions = ?;
		for (int32 c = 0; c < cascadeCount; c++)
		{
			regions[c] = shadowSystem.Atlas.GetRegion(baseCell + (uint32)c);

			int32 idx;
			if (shadowSystem.ReserveShadowSlot() case .Ok(let i))
				idx = i;
			else
				return; // shadow data buffer full

			if (baseShadowIdx < 0) baseShadowIdx = idx;
		}

		let cellSize = shadowSystem.Atlas.CellSize;
		let cascades = ShadowMatrices.DirectionalCascades(light, mainView, cellSize);
		let invShadowMapSize = 1.0f / (float)cellSize;

		light.ShadowIndex = baseShadowIdx;

		for (int32 c = 0; c < cascadeCount; c++)
		{
			let region = regions[c];
			let isBase = (c == 0);
			let texelWorld = (c == 0) ? cascades.WorldTexelSizes.X :
			                 (c == 1) ? cascades.WorldTexelSizes.Y :
			                 (c == 2) ? cascades.WorldTexelSizes.Z :
			                            cascades.WorldTexelSizes.W;

			GPUShadowData data = .()
			{
				LightViewProj = cascades.ViewProjs[c],
				AtlasUVRect = region.UVRect,
				CascadeSplits = isBase ? cascades.Splits : .Zero,
				Bias = light.ShadowBias,
				NormalBias = light.ShadowNormalBias,
				InvShadowMapSize = invShadowMapSize,
				CascadeCount = isBase ? cascadeCount : 0,
				WorldTexelSize = texelWorld
			};
			shadowSystem.SetShadowData(baseShadowIdx + c, data);

			let shadowView = mViewPool.Acquire();
			shadowView.ViewMatrix = .Identity;
			shadowView.ProjectionMatrix = cascades.ViewProjs[c];
			shadowView.ViewProjectionMatrix = cascades.ViewProjs[c];
			shadowView.CameraPosition = .Zero; // not used for ortho
			shadowView.NearPlane = 0.1f;
			shadowView.FarPlane = 1000.0f;
			shadowView.Width = region.Width;
			shadowView.Height = region.Height;
			shadowView.FrameIndex = mFrameIndex;
			shadowView.DeltaTime = mDeltaTime;
			shadowView.TotalTime = mTotalTime;

			ExtractIntoView(shadowView);

			mShadowDraws.Add(ShadowPipeline.ShadowJob() { View = shadowView, Region = region });
		}
	}

	/// Renders all queued shadow views into the atlas in a single graph cycle.
	/// Called between BeginFrame and the main pipeline.Render. The graph imports
	/// the atlas with finalState = ShaderRead, so it's left ready for sampling.
	private void RenderShadows(ICommandEncoder encoder)
	{
		if (mShadowDraws.Count == 0) return;

		let shadowSystem = mRenderContext.ShadowSystem;
		if (shadowSystem == null) return;

		let atlas = shadowSystem.Atlas.Texture;
		let atlasView = shadowSystem.Atlas.TextureView;

		Span<ShadowPipeline.ShadowJob> jobs = .(&mShadowDraws[0], mShadowDraws.Count);
		mShadowPipeline.RenderAll(encoder, jobs, atlas, atlasView, mFrameIndex);
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
		meshMgr.GPUResources = mRenderContext?.GPUResources;
		meshMgr.Resolver = mResolver;
		scene.AddModule(meshMgr);

		let skinnedMeshMgr = new SkinnedMeshComponentManager();
		skinnedMeshMgr.GPUResources = mRenderContext?.GPUResources;
		skinnedMeshMgr.Resolver = mResolver;
		scene.AddModule(skinnedMeshMgr);

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
