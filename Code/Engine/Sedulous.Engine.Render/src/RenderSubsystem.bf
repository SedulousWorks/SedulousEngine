namespace Sedulous.Engine.Render;

using System;
using Sedulous.Runtime;
using Sedulous.Engine.Core;
using Sedulous.Engine;
using Sedulous.RHI;
using Sedulous.Shell;
using Sedulous.Shaders;
using Sedulous.Renderer;
using Sedulous.Renderer.Passes;
using Sedulous.Renderer.Renderers;
using Sedulous.Particles;
using Sedulous.Renderer.Shadows;
using Sedulous.Core.Mathematics;
using Sedulous.Profiler;
using Sedulous.Resources;
using Sedulous.Geometry.Resources;
using Sedulous.Textures.Resources;
using Sedulous.Materials.Resources;
using System.Collections;

/// Implements ISceneRenderer - renders the 3D scene to application-provided output targets.
/// Runs late (UpdateOrder 500) - all scene updates and extraction are complete by this point.
/// Injects render component managers (Mesh, Light, Camera, etc.) into scenes via ISceneAware.
///
/// Does NOT own swapchain, frame pacing, or presentation. The application owns those and
/// calls RenderScene() with an encoder and output targets, then handles blit + overlays + present.
class RenderSubsystem : Subsystem, ISceneAware, IWindowAware, ISceneRenderer
{
	// Set by EngineApplication before context startup
	private IDevice mDevice;
	private IWindow mWindow;
	private IQueue mGraphicsQueue;

	// Resource system (not owned - passed by application)
	private Sedulous.Resources.ResourceSystem mResourceSystem;

	// Renderer (shared infrastructure)
	private RenderContext mRenderContext ~ delete _;

	// Per-scene pipelines (created in OnSceneCreated, destroyed in OnSceneDestroyed)
	private Dictionary<Scene, Pipeline> mScenePipelines = new .() ~ {
		for (let kv in _) { kv.value.Shutdown(); delete kv.value; }
		delete _;
	};

	// Shadow pipeline (renders depth into the shared shadow atlas, one call per shadow caster)
	private ShadowPipeline mShadowPipeline ~ delete _;

	// Resource managers (registered with mResourceSystem)
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

	/// Previous frame's main-view ViewProjectionMatrix, used for motion vectors.
	private Matrix mPrevViewProjectionMatrix = .Identity;
	/// Current frame index during RenderScene (set by caller, used by shadow methods).
	private int32 mFrameIndex;

	// Timing
	private float mDeltaTime;
	private float mTotalTime;

	public this(Sedulous.Resources.ResourceSystem resourceSystem)
	{
		mResourceSystem = resourceSystem;
	}

	public override int32 UpdateOrder => 500;

	// ==================== Properties (set by app before startup) ====================

	public IDevice Device { get => mDevice; set => mDevice = value; }
	public IWindow Window { get => mWindow; set => mWindow = value; }

	/// Shader system (set by app, not owned).
	public ShaderSystem ShaderSystem { get; set; }

	/// Asset directory (set by app, not owned).
	public String AssetDirectory { get; set; }

	// ==================== ISceneRenderer ====================

	public IQueue GraphicsQueue => mGraphicsQueue;
	public RenderContext RenderContext => mRenderContext;

	public Pipeline GetPipeline(Scene scene)
	{
		if (mScenePipelines.TryGetValue(scene, let pipeline))
			return pipeline;
		return null;
	}

	/// Convenience accessor for the immediate-mode debug draw API.
	/// Equivalent to `RenderContext.DebugDraw`.
	public Sedulous.Renderer.Debug.DebugDraw DebugDraw => mRenderContext?.DebugDraw;

	// ==================== Lifecycle ====================

	protected override void OnInit()
	{
		if (mDevice == null || mWindow == null)
			return;

		// Graphics queue
		mGraphicsQueue = mDevice.GetQueue(.Graphics);

		// Renderer (shared infrastructure)
		mRenderContext = new RenderContext();
		mRenderContext.Initialize(mDevice, mGraphicsQueue);
		mRenderContext.ShaderSystem = ShaderSystem;

		// Register per-type drawers on the shared context. Both the main Pipeline
		// and the ShadowPipeline dispatch through these.
		mRenderContext.RegisterRenderer(new MeshRenderer());
		mRenderContext.RegisterRenderer(new SpriteRenderer());
		mRenderContext.RegisterRenderer(new DecalRenderer());
		mRenderContext.RegisterRenderer(new ParticleRenderer());

		// Shadow pipeline (separate per-view pipeline that renders into the shared atlas)
		mShadowPipeline = new ShadowPipeline();
		mShadowPipeline.Initialize(mRenderContext);

		// Per-scene pipelines are created in OnSceneCreated.

		// Register resource managers with the resource system
		mStaticMeshManager = new StaticMeshResourceManager();
		mSkinnedMeshManager = new SkinnedMeshResourceManager();
		mTextureManager = new TextureResourceManager();
		mMaterialManager = new MaterialResourceManager();

		mResourceSystem.AddResourceManager(mStaticMeshManager);
		mResourceSystem.AddResourceManager(mSkinnedMeshManager);
		mResourceSystem.AddResourceManager(mTextureManager);
		mResourceSystem.AddResourceManager(mMaterialManager);

		// Shared resource resolver
		mResolver = new RenderResourceResolver(mResourceSystem, mRenderContext.GPUResources, mRenderContext.MaterialSystem);
	}

	protected override void OnShutdown()
	{
		if (mDevice == null)
			return;

		mDevice.WaitIdle();

		// Unregister resource managers
		if (mStaticMeshManager != null)
			mResourceSystem.RemoveResourceManager(mStaticMeshManager);
		if (mSkinnedMeshManager != null)
			mResourceSystem.RemoveResourceManager(mSkinnedMeshManager);
		if (mTextureManager != null)
			mResourceSystem.RemoveResourceManager(mTextureManager);
		if (mMaterialManager != null)
			mResourceSystem.RemoveResourceManager(mMaterialManager);

		// Shutdown pipelines then renderer (pipelines first - they reference renderer)
		for (let kv in mScenePipelines)
		{
			kv.value.Shutdown();
			delete kv.value;
		}
		mScenePipelines.Clear();
		if (mShadowPipeline != null)
			mShadowPipeline.Shutdown();
		if (mRenderContext != null)
			mRenderContext.Shutdown();
	}

	// ==================== Frame ====================

	public override void BeginFrame(float deltaTime)
	{
		mDeltaTime = deltaTime;
		mTotalTime += deltaTime;
	}

	/// Renders a specific scene to application-provided output targets.
	///
	/// Contract:
	///   - Each scene has its own Pipeline (created in OnSceneCreated).
	///   - The application owns the encoder, output textures, and frame pacing.
	///   - colorTexture/colorTarget must be pre-cleared and in RenderTarget state on entry.
	///   - On return, colorTexture is transitioned to ShaderRead - ready for blit sampling.
	///   - frameIndex is the application's frame-in-flight index (0..MAX_FRAMES-1).
	///   - w/h are the output dimensions.
	public void RenderScene(Scene scene, ICommandEncoder encoder, ITexture colorTexture, ITextureView colorTarget,
		uint32 w, uint32 h, int32 frameIndex, CameraOverride? camera = null)
	{
		if (mDevice == null || scene == null)
			return;

		if (!mScenePipelines.TryGetValue(scene, let pipeline))
			return;

		mFrameIndex = frameIndex;

		// Update pipeline dimensions if they differ.
		if (w != pipeline.OutputWidth || h != pipeline.OutputHeight)
			pipeline.OnResize(w, h);

		// Reset the view pool first - drops references to last frame's arena entries
		// before BeginFrame() rewinds the frame allocator.
		mViewPool.BeginFrame();
		mRenderContext.BeginFrame();

		// Acquire and populate the main view from the scene's active camera.
		let mainView = mViewPool.Acquire();
		mainView.FrameIndex = frameIndex;
		mainView.DeltaTime = mDeltaTime;
		mainView.TotalTime = mTotalTime;
		mainView.Width = w;
		mainView.Height = h;
		using (Profiler.Begin("SceneExtraction"))
			ExtractMainView(mainView, scene, camera);

		// Allocate shadow maps for shadow-casting lights from the main view.
		using (Profiler.Begin("ShadowSetup"))
			SetupShadows(mainView);

		// Reset per-frame ring buffer offsets.
		pipeline.BeginFrame(frameIndex);
		mShadowPipeline.BeginFrame(frameIndex);

		// Render shadow views first (main forward pass samples the atlas).
		using (Profiler.Begin("ShadowRender"))
			RenderShadows(encoder, frameIndex);

		// Render to the application-provided output target.
		pipeline.Render(encoder, mainView, colorTexture, colorTarget, frameIndex);

		// Save this frame's VP for next frame's motion vectors.
		mPrevViewProjectionMatrix = mainView.ViewProjectionMatrix;

		// Clear accumulated debug draws - commands have been recorded into the
		// command buffer at this point, and the per-frame GPU vertex buffers hold
		// the uploaded data until the GPU consumes it on the next fence wait.
		mRenderContext.DebugDraw.Clear();

		// Transition output to ShaderRead for the application to blit.
		encoder.TransitionTexture(colorTexture, .RenderTarget, .ShaderRead);
	}

	// ==================== Extraction ====================

	/// Populates the main view from the active camera (or override) and extracts render data into it.
	private void ExtractMainView(RenderView view, Scene scene, CameraOverride? cameraOverride = null)
	{
		Matrix viewMatrix = .Identity;
		Matrix projMatrix = .Identity;
		Vector3 cameraPos = .Zero;
		float nearPlane = 0.1f;
		float farPlane = 1000.0f;

		if (cameraOverride.HasValue)
		{
			// Use externally provided camera (editor camera)
			let cam = cameraOverride.Value;
			viewMatrix = cam.ViewMatrix;
			projMatrix = cam.ProjectionMatrix;
			cameraPos = cam.CameraPosition;
			nearPlane = cam.NearPlane;
			farPlane = cam.FarPlane;
		}
		else
		{
			// Query scene's active camera
			let cameraMgr = scene.GetModule<CameraComponentManager>();
			let activeCamera = (cameraMgr != null) ? cameraMgr.GetActiveCamera() : null;

			if (activeCamera != null)
			{
				let viewportAspect = (view.Height > 0) ?
					(float)view.Width / (float)view.Height : 1.0f;
				viewMatrix = activeCamera.GetViewMatrix(scene);
				projMatrix = activeCamera.GetProjectionMatrix(viewportAspect);
				cameraPos = scene.GetWorldMatrix(activeCamera.Owner).Translation;
				nearPlane = activeCamera.NearPlane;
				farPlane = activeCamera.FarPlane;
			}
		}

		view.ViewMatrix = viewMatrix;
		view.ProjectionMatrix = projMatrix;
		view.ViewProjectionMatrix = viewMatrix * projMatrix;
		view.PrevViewProjectionMatrix = mPrevViewProjectionMatrix;
		view.CameraPosition = cameraPos;
		view.NearPlane = nearPlane;
		view.FarPlane = farPlane;
		// Width, Height, FrameIndex, DeltaTime, TotalTime are set by the caller
		// (RenderScene) from application-provided values.

		ExtractIntoView(view, scene);
	}

	/// Runs all IRenderDataProvider modules on the specified scene against the given view.
	private void ExtractIntoView(RenderView view, Scene scene)
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
			FrameIndex = view.FrameIndex,
			LayerMask = 0xFFFFFFFF,
			LODBias = 0
		};

		for (let module in scene.Modules)
		{
			if (let provider = module as IRenderDataProvider)
				provider.ExtractRenderData(context);
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

		// Pass 2: point lights (need 6 contiguous cells per light, one per cube face).
		for (let entry in lights)
		{
			let light = entry as LightRenderData;
			if (light == null || !light.CastsShadows || light.Type != .Point)
				continue;
			AllocatePointShadow(light, mainView, shadowSystem);
		}

		// Pass 3: spot lights (single cell each).
		for (let entry in lights)
		{
			let light = entry as LightRenderData;
			if (light == null || !light.CastsShadows || light.Type != .Spot)
				continue;
			AllocateSpotShadow(light, mainView, shadowSystem);
		}

		shadowSystem.Upload(mFrameIndex);
	}

	/// Allocates and queues a single shadow map for a spot light.
	private void AllocateSpotShadow(LightRenderData light, RenderView mainView, ShadowSystem shadowSystem)
	{
		ShadowAtlasRegion region;
		int32 shadowIdx;
		if (shadowSystem.AllocateShadow(.Medium, out region) case .Ok(let idx))
			shadowIdx = idx;
		else
			return;

		let lightVP = ShadowMatrices.SpotLightViewProj(light);
		let cellSize = shadowSystem.Atlas.GetCellSize(.Medium);
		let invShadowMapSize = 1.0f / (float)cellSize;

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
			WorldTexelSize = light.Range / (float)cellSize
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

		CopyShadowData(shadowView, mainView);

		mShadowDraws.Add(ShadowPipeline.ShadowJob() { View = shadowView, Region = region });
	}

	/// Allocates and queues 4 cascade shadow maps for a directional light.
	/// The base GPUShadowData entry holds CascadeCount + CascadeSplits so the
	/// fragment shader can pick the right cascade by view-space depth.
	private void AllocateDirectionalShadow(LightRenderData light, RenderView mainView, ShadowSystem shadowSystem)
	{
		let cascadeCount = ShadowConstants.MaxCascades;

		// Per-cascade tier assignment: near cascades get Large (2048) for crisp
		// shadows near the camera; far cascades get Medium (1024).
		ShadowTier[ShadowConstants.MaxCascades] cascadeTiers = .(
			.Large, .Large,    // cascade 0-1: high-res (2048)
			.Medium, .Medium   // cascade 2-3: medium-res (1024)
		);

		// Reserve 4 shadow data slots (contiguous in the data buffer so the shader
		// can do baseIndex + cascadeIdx). Atlas cells come from different tiers and
		// are NOT contiguous in pixel space - that's fine, each entry carries its
		// own AtlasUVRect.
		int32 baseShadowIdx = -1;
		ShadowAtlasRegion[ShadowConstants.MaxCascades] regions = ?;
		uint32[ShadowConstants.MaxCascades] cellSizes = ?;

		for (int32 c = 0; c < cascadeCount; c++)
		{
			let tier = cascadeTiers[c];
			ShadowAtlasRegion region;
			if (shadowSystem.Atlas.AllocateCell(tier) case .Ok(let r))
				region = r;
			else
				return; // atlas full at this tier

			regions[c] = region;
			cellSizes[c] = shadowSystem.Atlas.GetCellSize(tier);

			int32 idx;
			if (shadowSystem.ReserveShadowSlot() case .Ok(let i))
				idx = i;
			else
				return;
			if (baseShadowIdx < 0) baseShadowIdx = idx;
		}

		// Pass the LARGEST cascade resolution for the sphere-fit computation.
		// WorldTexelSizes are recomputed below per cascade with each cascade's
		// actual cell size.
		let maxCellSize = cellSizes[0]; // cascade 0 has the largest
		let cascades = ShadowMatrices.DirectionalCascades(light, mainView, maxCellSize);

		light.ShadowIndex = baseShadowIdx;

		for (int32 c = 0; c < cascadeCount; c++)
		{
			let region = regions[c];
			let isBase = (c == 0);

			// Recompute world texel size with THIS cascade's cell resolution.
			let rawTexel = (c == 0) ? cascades.WorldTexelSizes.X :
			               (c == 1) ? cascades.WorldTexelSizes.Y :
			               (c == 2) ? cascades.WorldTexelSizes.Z :
			                          cascades.WorldTexelSizes.W;
			// The original texel was computed with maxCellSize; scale by the ratio.
			let texelWorld = rawTexel * ((float)maxCellSize / (float)cellSizes[c]);
			let invShadowMapSize = 1.0f / (float)cellSizes[c];

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
			shadowView.CameraPosition = .Zero;
			shadowView.NearPlane = 0.1f;
			shadowView.FarPlane = 1000.0f;
			shadowView.Width = region.Width;
			shadowView.Height = region.Height;
			shadowView.FrameIndex = mFrameIndex;
			shadowView.DeltaTime = mDeltaTime;
			shadowView.TotalTime = mTotalTime;

			CopyShadowData(shadowView, mainView);

			mShadowDraws.Add(ShadowPipeline.ShadowJob() { View = shadowView, Region = region });
		}
	}

	/// Allocates and queues 6 cube-face shadow maps for a point light. Each face
	/// gets its own GPUShadowData entry with its own view-proj; the fragment
	/// shader picks the face at runtime via direction from light to surface.
	///
	/// light.ShadowIndex is set to the FIRST face's index; subsequent faces sit
	/// at consecutive indices. The base entry carries CascadeCount = 6 as a
	/// "face count" signal (spot lights have 0).
	private void AllocatePointShadow(LightRenderData light, RenderView mainView, ShadowSystem shadowSystem)
	{
		let faceCount = ShadowConstants.PointFaceCount;

		uint32 baseCell;
		if (shadowSystem.Atlas.AllocateContiguous(.Small, (uint32)faceCount) case .Ok(let cell))
			baseCell = cell;
		else
			return;

		int32 baseShadowIdx = -1;
		ShadowAtlasRegion[ShadowConstants.PointFaceCount] regions = ?;
		for (int32 f = 0; f < faceCount; f++)
		{
			regions[f] = shadowSystem.Atlas.GetRegion(.Small, baseCell + (uint32)f);
			int32 idx;
			if (shadowSystem.ReserveShadowSlot() case .Ok(let i))
				idx = i;
			else
				return;
			if (baseShadowIdx < 0) baseShadowIdx = idx;
		}

		let cellSize = shadowSystem.Atlas.GetCellSize(.Small);
		let invShadowMapSize = 1.0f / (float)cellSize;
		let worldTexel = Math.Max(light.Range, 1.0f) / (float)cellSize;

		light.ShadowIndex = baseShadowIdx;

		for (int32 f = 0; f < faceCount; f++)
		{
			let region = regions[f];
			let isBase = (f == 0);
			let faceVP = ShadowMatrices.PointLightFaceViewProj(light, f);

			GPUShadowData data = .()
			{
				LightViewProj = faceVP,
				AtlasUVRect = region.UVRect,
				CascadeSplits = .Zero,
				Bias = light.ShadowBias,
				NormalBias = light.ShadowNormalBias,
				InvShadowMapSize = invShadowMapSize,
				CascadeCount = isBase ? (int32)faceCount : 0,
				WorldTexelSize = worldTexel
			};
			shadowSystem.SetShadowData(baseShadowIdx + f, data);

			// Per-face shadow view - only ViewProjectionMatrix is used by the
			// depth-only shader, so we collapse view+proj into a single matrix
			// (View = Identity, Proj = faceVP) for the scene uniforms upload.
			let shadowView = mViewPool.Acquire();
			shadowView.ViewMatrix = .Identity;
			shadowView.ProjectionMatrix = faceVP;
			shadowView.ViewProjectionMatrix = faceVP;
			shadowView.CameraPosition = light.Position;
			shadowView.NearPlane = 0.1f;
			shadowView.FarPlane = Math.Max(light.Range, 0.2f);
			shadowView.Width = region.Width;
			shadowView.Height = region.Height;
			shadowView.FrameIndex = mFrameIndex;
			shadowView.DeltaTime = mDeltaTime;
			shadowView.TotalTime = mTotalTime;

			CopyShadowData(shadowView, mainView);

			mShadowDraws.Add(ShadowPipeline.ShadowJob() { View = shadowView, Region = region });
		}
	}

	/// Copies shadow-relevant render data (Opaque + Masked) from the main view
	/// into a shadow view. Avoids re-extracting the entire scene per shadow view.
	/// The RenderData entries are arena-allocated and valid until BeginFrame().
	private void CopyShadowData(RenderView shadowView, RenderView mainView)
	{
		let srcOpaque = mainView.RenderData.GetBatch(RenderCategories.Opaque);
		if (srcOpaque != null)
		{
			let dst = shadowView.RenderData.GetBatch(RenderCategories.Opaque);
			for (let entry in srcOpaque)
				dst.Add(entry);
		}

		let srcMasked = mainView.RenderData.GetBatch(RenderCategories.Masked);
		if (srcMasked != null)
		{
			let dst = shadowView.RenderData.GetBatch(RenderCategories.Masked);
			for (let entry in srcMasked)
				dst.Add(entry);
		}
	}

	/// Renders all queued shadow views into the atlas in a single graph cycle.
	/// Called between BeginFrame and the main pipeline.Render. The graph imports
	/// the atlas with finalState = ShaderRead, so it's left ready for sampling.
	private void RenderShadows(ICommandEncoder encoder, int32 frameIndex)
	{
		let shadowSystem = mRenderContext.ShadowSystem;
		if (shadowSystem == null) return;

		let atlas = shadowSystem.Atlas.Texture;
		if (atlas == null) return;

		if (mShadowDraws.Count == 0)
		{
			// No shadow casters - the atlas was never rendered to, so it's still
			// in UNDEFINED layout. Transition to ShaderRead so the forward shader
			// can safely sample it (reads all-ones depth = fully lit).
			encoder.TransitionTexture(atlas, .Undefined, .ShaderRead);
			return;
		}

		let atlasView = shadowSystem.Atlas.TextureView;
		Span<ShadowPipeline.ShadowJob> jobs = .(&mShadowDraws[0], mShadowDraws.Count);
		mShadowPipeline.RenderAll(encoder, jobs, atlas, atlasView, frameIndex);
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

		let spriteMgr = new SpriteComponentManager();
		spriteMgr.Resolver = mResolver;
		spriteMgr.RenderContext = mRenderContext;
		scene.AddModule(spriteMgr);

		let decalMgr = new DecalComponentManager();
		decalMgr.Resolver = mResolver;
		decalMgr.RenderContext = mRenderContext;
		scene.AddModule(decalMgr);

		let particleMgr = new ParticleComponentManager();
		particleMgr.Resolver = mResolver;
		particleMgr.RenderContext = mRenderContext;
		scene.AddModule(particleMgr);

		scene.AddModule(new CameraComponentManager());

		let lightMgr = new LightComponentManager();
		lightMgr.RenderContext = mRenderContext;
		scene.AddModule(lightMgr);

		// Create a pipeline for this scene.
		let pipeline = CreatePipelineForScene();
		mScenePipelines[scene] = pipeline;
	}

	public void OnSceneReady(Scene scene) { }

	public void OnSceneDestroyed(Scene scene)
	{
		if (mScenePipelines.TryGetValue(scene, let pipeline))
		{
			pipeline.Shutdown();
			delete pipeline;
			mScenePipelines.Remove(scene);
		}
	}

	/// Creates a fully configured Pipeline with default passes and post-processing.
	private Pipeline CreatePipelineForScene()
	{
		let pipeline = new Pipeline();
		pipeline.Initialize(mRenderContext, (uint32)mWindow.Width, (uint32)mWindow.Height);

		// Register default passes.
		// Order is significant:
		//   1. Skinning (compute)
		//   2. Depth prepass (opaque + masked)
		//   3. Forward opaque + masked (fills color + uses prepass depth)
		//   4. Decal pass (samples SceneDepth, composes on top of opaque)
		//   5. Sky (fills where depth == far)
		//   6. Forward transparent (sprites/particles blend over sky + opaque)
		//   7. Debug lines (depth-tested on top of everything)
		//   8. 2D overlay (no depth)
		pipeline.AddPass(new SkinningPass());
		pipeline.AddPass(new DepthPrepass());
		pipeline.AddPass(new ForwardOpaquePass());
		pipeline.AddPass(new DecalPass());
		pipeline.AddPass(new SkyPass());
		pipeline.AddPass(new ForwardTransparentPass());
		pipeline.AddPass(new ParticlePass());
		pipeline.AddPass(new DebugPass());
		pipeline.AddPass(new OverlayPass());

		// Post-processing stack
		let postStack = new PostProcessStack();
		postStack.Initialize(mRenderContext);
		let bloomEffect = new BloomEffect();
		bloomEffect.Threshold = 1.5f;
		bloomEffect.Intensity = 0.5f;
		postStack.AddEffect(bloomEffect);
		postStack.AddEffect(new TonemapEffect());
		pipeline.PostProcessStack = postStack;

		return pipeline;
	}

	// ==================== IWindowAware ====================

	public void OnWindowResized(IWindow window, int32 width, int32 height)
	{
		if (width == 0 || height == 0 || mDevice == null)
			return;

		for (let kv in mScenePipelines)
			kv.value.OnResize((uint32)width, (uint32)height);
	}
}
