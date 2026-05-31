namespace Sedulous.Renderer;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Materials;
using Sedulous.Core.Mathematics;
using Sedulous.Core.Memory;
using Sedulous.Jobs;
using Sedulous.Renderer.Shadows;
using Sedulous.Renderer.Debug;
using Sedulous.Renderer.IBL;

/// Shared rendering infrastructure - owns GPU resources, materials, pipeline cache,
/// lighting, and bind group layouts that are common across all views/pipelines.
///
/// Sits between the RHI (raw GPU API) and per-view Pipeline (pass execution).
/// One Renderer per application. Multiple Pipelines can reference the same Renderer.
public class RenderContext : IDisposable
{
	private IDevice mDevice;
	private IQueue mQueue;

	// GPU resource management
	private GPUResourceManager mGPUResources ~ delete _;

	// Material system
	private MaterialSystem mMaterialSystem ~ { _?.Dispose(); delete _; };

	// Default material bind group (cached from MaterialSystem, ref held on instance)
	private IBindGroup mDefaultMaterialBindGroup;
	private MaterialInstance mDefaultMaterialInstanceRef;

	// Pipeline state cache
	private PipelineStateCache mPipelineStateCache ~ delete _;

	// Compute skinning
	private SkinningSystem mSkinningSystem ~ { _?.Dispose(); delete _; };
	private Sedulous.Renderer.IBL.IBLPrefilterSystem mIBLPrefilterSystem ~ { _?.Dispose(); delete _; };
	private Sedulous.Renderer.IBL.IBLSH9System mIBLSH9System ~ { _?.Dispose(); delete _; };

	// Shadow system (atlas + data buffer + bind group)
	private ShadowSystem mShadowSystem ~ { _?.Dispose(); delete _; };

	// Debug draw system (font texture + per-frame vertex buffers) + immediate-mode API
	private DebugDrawSystem mDebugDrawSystem ~ { _?.Dispose(); delete _; };
	private DebugDraw mDebugDraw = new DebugDraw() ~ delete _;

	// Sprite system (shared sprite material template + per-frame instance buffers)
	private SpriteSystem mSpriteSystem ~ { _?.Dispose(); delete _; };

	// Per-frame scratch allocator for render data extraction.
	// Reset at the start of each frame via BeginFrame().
	// .Allow - Beef classes carry Object's destructor chain; we let the allocator
	// track and run them on Reset. Render data subclasses should not define user
	// destructors (convention, not enforced).
	private FrameAllocator mFrameAllocator = new FrameAllocator(.Allow) ~ delete _;

	// Per-worker frame allocators for parallel extraction. One per worker thread
	// + one for the calling thread. Initialized lazily on first use.
	// Reset alongside the main allocator in BeginFrame().
	private FrameAllocator[] mWorkerAllocators ~ { if (_ != null) { for (let a in _) delete a; delete _; } };

	// Registered renderers, keyed by category. RenderContext owns the instances -
	// shared across all Pipeline / ShadowPipeline instances built on this context.
	private List<Renderer>[RenderCategories.Count] mRenderersByCategory;
	// Flat owning list (a renderer may appear in multiple categories).
	private List<Renderer> mOwnedRenderers = new .() ~ DeleteContainerAndItems!(_);

	// Shader system (not owned)
	private Sedulous.Shaders.ShaderSystem mShaderSystem;

	// Shared bind group layouts (frequency model)
	private IBindGroupLayout mFrameBindGroupLayout;
	private IBindGroupLayout mDrawCallBindGroupLayout;

	/// Bind group layout for instanced draws (set 3): StructuredBuffer<InstanceData>.
	private IBindGroupLayout mInstanceBindGroupLayout;

	// ==================== IBL ====================
	//
	// Resources bound at the frame level for image-based lighting. The cubemap
	// array, probe buffer, and SH9 buffer are placeholders until reflection
	// probes come online (Sub-phase C); the BRDF LUT and linear sampler are
	// the real shipping resources used directly by the forward shader.
	//
	// All five live on RenderContext (not PerFrameResources) because they're
	// shared across views and frames. Per-scene replacement (when probes
	// actually exist) will happen by Pipeline binding scene-specific
	// alternatives in place of the defaults at frame-bind-group rebuild time.

	private ITexture mBRDFLutTexture;
	private ITextureView mBRDFLutView;
	/// Placeholder cubemap-array for prefiltered reflections. Sized to the
	/// final probe layout (128 x 128 x 6*MaxProbes, 5 mips) so Sub-phase C
	/// just writes into existing memory rather than reallocating.
	private ITexture mPrefilteredCubemapArray;
	private ITextureView mPrefilteredCubemapView;
	/// Mip-0-only TextureCubeArray view of the prefiltered cubemap, used as
	/// the SOURCE descriptor by the prefilter + SH9 compute passes. A separate
	/// view is required because Vulkan tracks per-subresource layout via the
	/// view: the prefilter pass writes mips 1..N as General, while the source
	/// descriptor demands ShaderRead for every subresource the view covers.
	/// Restricting the source view to mip 0 keeps those write-only mips out
	/// of the read view's coverage.
	private ITextureView mPrefilteredCubemapSourceView;
	/// Placeholder per-probe data StructuredBuffer (MaxProbes entries, all
	/// Enabled=0). Replaced when a scene gains probes.
	private IBuffer mProbeBuffer;
	/// Placeholder SH9 coefficients buffer (9 float4 entries per probe).
	private IBuffer mSH9Buffer;
	/// Linear, clamp sampler shared by the BRDF LUT and prefiltered cubemap.
	private ISampler mLinearSampler;

	/// IBL probe count cap. Matches the BeefGFX reference; sized for our
	/// scene scales. Bumping this means resizing mPrefilteredCubemapArray,
	/// mProbeBuffer, mSH9Buffer to match.
	public const int32 MaxIBLProbes = 8;
	/// Per-probe cube-face resolution. 128 matches Unity's default + the
	/// BeefGFX reference.
	public const int32 IBLProbeFaceSize = 128;
	/// Number of prefilter mip levels. Mip 0 is mirror (roughness 0), mip
	/// (Count-1) is the roughest sample.
	public const int32 IBLPrefilterMipCount = 5;
	/// SH9 coefficients per probe (9 RGB bands, each stored as float4).
	public const int32 IBLSH9CoeffPerProbe = 9;
	/// Byte stride of one GPU reflection probe entry. Hand-coded for now; will be
	/// replaced by `sizeof(GPUReflectionProbe)` when that struct lands in Sub-phase B.
	/// Layout: Position (12) + InfluenceRadius (4) + BoxMin (12) + Padding (4) +
	///         BoxMax (12) + SHCoeffStart (4) + CubemapLayer (4) + Enabled (4) +
	///         PrefilterMipCount (4) + BlendEdge (4) = 64 bytes (HLSL StructuredBuffer aligns to 16).
	public const uint32 ProbeStride = 64;

	// Default draw call bind group (identity transform)
	private IBindGroup mDefaultDrawCallBindGroup;
	private IBuffer mDefaultDrawCallBuffer;

	// ==================== Properties ====================

	/// The RHI device.
	public IDevice Device => mDevice;

	/// The graphics queue.
	public IQueue Queue => mQueue;

	/// Current frame's scene depth texture view (set by transparent pass for
	/// depth-dependent effects like soft particles). Reset each frame.
	public ITextureView CurrentSceneDepthView;


	/// GPU resource manager (meshes, textures, bone buffers).
	public GPUResourceManager GPUResources => mGPUResources;

	/// Material system (manages material bind groups, default textures, per-instance GPU resources).
	public MaterialSystem MaterialSystem => mMaterialSystem;

	/// Default material bind group (white albedo, 0.5 roughness, 0 metallic).
	public IBindGroup DefaultMaterialBindGroup => mDefaultMaterialBindGroup;

	/// Default draw call bind group (identity transform).
	public IBindGroup DefaultDrawCallBindGroup => mDefaultDrawCallBindGroup;

	/// Pipeline state cache (creates GPU pipelines on demand from material config).
	public PipelineStateCache PipelineStateCache => mPipelineStateCache;

	/// Compute skinning system.
	public SkinningSystem SkinningSystem => mSkinningSystem;

	/// GGX prefilter compute system. Owns the compute pipeline that builds
	/// the prefiltered specular mip chain for each reflection probe.
	public Sedulous.Renderer.IBL.IBLPrefilterSystem IBLPrefilterSystem => mIBLPrefilterSystem;

	/// SH9 projection compute system. Projects each probe's captured cubemap
	/// onto 9 SH coefficients per RGB channel (pre-convolved for irradiance).
	public Sedulous.Renderer.IBL.IBLSH9System IBLSH9System => mIBLSH9System;

	/// Shadow system (atlas + data buffer + bind group). Created in Initialize.
	public ShadowSystem ShadowSystem => mShadowSystem;

	/// Debug draw system (GPU resources backing DebugDraw).
	public DebugDrawSystem DebugDrawSystem => mDebugDrawSystem;

	/// Immediate-mode debug draw API. Call Draw* methods from game code to
	/// queue lines, wire shapes, and text to be rendered by DebugPass + OverlayPass.
	/// Cleared at the end of each frame by the renderer.
	public DebugDraw DebugDraw => mDebugDraw;

	/// Sprite system (shared Material template + per-frame instance buffers for
	/// the SpriteRenderer drawer).
	public SpriteSystem SpriteSystem => mSpriteSystem;

	/// Per-frame scratch allocator. Render data allocated here is valid until
	/// the next BeginFrame() call, which rewinds the allocator.
	public FrameAllocator FrameAllocator => mFrameAllocator;

	/// Gets a worker allocator for parallel extraction. Index 0..WorkerAllocatorCount-1.
	/// Created in BeginFrame (single-threaded) so GetWorkerAllocator is safe to call
	/// from multiple threads during parallel extraction.
	public FrameAllocator GetWorkerAllocator(int32 index)
	{
		return mWorkerAllocators[index];
	}

	/// Number of available worker allocators.
	public int32 WorkerAllocatorCount => (mWorkerAllocators != null) ? (int32)mWorkerAllocators.Count : 0;

	/// Registers a per-type drawer. RenderContext takes ownership.
	/// The renderer is indexed against every category returned by GetSupportedCategories().
	/// All Pipelines built on this context share the same renderers.
	public void RegisterRenderer(Renderer renderer)
	{
		if (renderer == null) return;

		mOwnedRenderers.Add(renderer);

		// Let the renderer create its shared GPU resources (material templates,
		// bind group layouts, per-frame buffers) now that it has a live context.
		renderer.OnRegistered(this);

		let categories = renderer.GetSupportedCategories();
		for (let cat in categories)
		{
			if (cat.Value < RenderCategories.Count)
				mRenderersByCategory[cat.Value].Add(renderer);
		}
	}

	/// Gets the list of renderers registered against a category. May return null if
	/// no renderers participate in the category. Used by Pipeline.RenderCategory.
	public List<Renderer> GetRenderersFor(RenderDataCategory category)
	{
		if (category.Value >= RenderCategories.Count)
			return null;
		return mRenderersByCategory[category.Value];
	}

	/// Shader system (optional, for passes that need to compile shaders).
	public Sedulous.Shaders.ShaderSystem ShaderSystem
	{
		get => mShaderSystem;
		set
		{
			mShaderSystem = value;
			delete mPipelineStateCache;
			if (value != null)
				mPipelineStateCache = new PipelineStateCache(mDevice, value, this);

			// Initialize skinning system with shader system
			if (value != null && mSkinningSystem == null)
			{
				mSkinningSystem = new SkinningSystem();
				mSkinningSystem.Initialize(mDevice, value);
			}

			// Initialize IBL prefilter system once the cubemap + sampler exist.
			// InitializeIBL runs before ShaderSystem is assigned, so these
			// resources are already in place by now.
			if (value != null && mIBLPrefilterSystem == null
				&& mPrefilteredCubemapArray != null
				&& mPrefilteredCubemapSourceView != null
				&& mLinearSampler != null)
			{
				mIBLPrefilterSystem = new Sedulous.Renderer.IBL.IBLPrefilterSystem();
				mIBLPrefilterSystem.Initialize(mDevice, value,
					mPrefilteredCubemapArray, mPrefilteredCubemapSourceView, mLinearSampler);
			}

			// SH9 projection system uses the mip-0 source view (same view as
			// the prefilter source) and writes into the shared SH9 buffer.
			if (value != null && mIBLSH9System == null
				&& mPrefilteredCubemapSourceView != null
				&& mSH9Buffer != null
				&& mLinearSampler != null)
			{
				mIBLSH9System = new Sedulous.Renderer.IBL.IBLSH9System();
				mIBLSH9System.Initialize(mDevice, value,
					mPrefilteredCubemapSourceView, mSH9Buffer, mLinearSampler);
			}
		}
	}

	/// Frame-level bind group layout (set 0).
	public IBindGroupLayout FrameBindGroupLayout => mFrameBindGroupLayout;

	/// Material bind group layout (set 2) - from MaterialSystem.
	public IBindGroupLayout MaterialBindGroupLayout => mMaterialSystem?.DefaultMaterialLayout;

	/// Draw-call bind group layout (set 3).
	public IBindGroupLayout DrawCallBindGroupLayout => mDrawCallBindGroupLayout;

	/// Bind group layout for instanced draws (StructuredBuffer at set 3).
	public IBindGroupLayout InstanceBindGroupLayout => mInstanceBindGroupLayout;

	// ==================== IBL accessors ====================

	/// BRDF integration LUT view (set 0 t1). Real data; sampled by the forward
	/// shader for split-sum indirect specular.
	public ITextureView BRDFLutView => mBRDFLutView;

	/// Prefiltered cubemap-array view (set 0 t2). Placeholder until probes come
	/// online; Sub-phase C populates content per probe slot.
	public ITextureView PrefilteredCubemapView => mPrefilteredCubemapView;

	/// Underlying cubemap-array texture (rendered to per face by the probe
	/// capture pass, sampled via PrefilteredCubemapView by the forward shader).
	public ITexture PrefilteredCubemapTexture => mPrefilteredCubemapArray;

	/// Per-probe data StructuredBuffer (set 0 t3). Placeholder until probes
	/// exist. Sub-phase B writes from extracted ReflectionProbeRenderData.
	public IBuffer ProbeBuffer => mProbeBuffer;

	/// SH9 coefficients buffer (set 0 t4). Placeholder until SH9 projection
	/// compute pass runs (Sub-phase E).
	public IBuffer SH9Buffer => mSH9Buffer;

	/// Linear+clamp sampler shared by BRDF LUT and prefiltered cubemap (set 0 s1).
	public ISampler LinearSampler => mLinearSampler;

	// ==================== Lifecycle ====================

	/// Initializes the shared rendering infrastructure.
	public Result<void> Initialize(IDevice device, IQueue queue)
	{
		mDevice = device;
		mQueue = queue;

		for (int i = 0; i < RenderCategories.Count; i++)
			mRenderersByCategory[i] = new .();

		// GPU resource manager
		mGPUResources = new GPUResourceManager();
		if (mGPUResources.Initialize(device, queue) case .Err)
			return .Err;

		// Material system
		mMaterialSystem = new MaterialSystem();
		if (mMaterialSystem.Initialize(device, queue) case .Err)
			return .Err;

		// Cache default material bind group
		mDefaultMaterialInstanceRef = mMaterialSystem.DefaultMaterialInstance;
		mDefaultMaterialInstanceRef.AddRef();
		mDefaultMaterialBindGroup = mMaterialSystem.GetBindGroup(mDefaultMaterialInstanceRef);

		// Shared bind group layouts
		if (CreateBindGroupLayouts() case .Err)
			return .Err;

		// Shadow system (atlas, data buffer, bind group at set 4)
		mShadowSystem = new ShadowSystem();
		if (mShadowSystem.Initialize(device) case .Err)
			return .Err;

		// Debug draw (font + per-frame vertex buffers)
		mDebugDrawSystem = new DebugDrawSystem();
		if (mDebugDrawSystem.Initialize(device, queue) case .Err)
			return .Err;

		// Sprite system (material template + per-frame instance buffers)
		mSpriteSystem = new SpriteSystem();
		if (mSpriteSystem.Initialize(device, mMaterialSystem) case .Err)
			return .Err;

		// IBL resources bound at frame set 0 t1..t4 + s1:
		//   t1 BRDF LUT, t2 prefiltered cubemap array, t3 probe buffer,
		//   t4 SH9 buffer, s1 linear sampler.
		// The cubemap is the live target ProbeCapturePass renders into and the
		// prefilter/SH9 passes consume; the probe and SH9 buffers are populated
		// per-frame by ReflectionProbeUploader + IBLSH9System. Scenes without
		// probes leave the buffers zero-initialized (Enabled=0 short-circuits
		// the forward shader's IBL loop).
		if (InitializeIBL() case .Err)
			return .Err;

		return .Ok;
	}

	/// Shuts down and releases all shared resources.
	public void Shutdown()
	{
		if (mDevice != null)
			mDevice.WaitIdle();

		// Clear per-category renderer indices. The instances themselves are owned by
		// mOwnedRenderers and deleted via its destructor.
		for (int i = 0; i < RenderCategories.Count; i++)
		{
			if (mRenderersByCategory[i] != null)
			{
				delete mRenderersByCategory[i];
				mRenderersByCategory[i] = null;
			}
		}

		// Pipeline state cache
		delete mPipelineStateCache;
		mPipelineStateCache = null;

		// Default material bind group ref
		mDefaultMaterialBindGroup = null;
		if (mDefaultMaterialInstanceRef != null)
		{
			mDefaultMaterialInstanceRef.ReleaseRef();
			mDefaultMaterialInstanceRef = null;
		}

		// Default draw call bind group
		if (mDefaultDrawCallBindGroup != null)
			mDevice.DestroyBindGroup(ref mDefaultDrawCallBindGroup);
		if (mDefaultDrawCallBuffer != null)
			mDevice.DestroyBuffer(ref mDefaultDrawCallBuffer);

		// IBL resources
		if (mBRDFLutView != null) mDevice.DestroyTextureView(ref mBRDFLutView);
		if (mBRDFLutTexture != null) mDevice.DestroyTexture(ref mBRDFLutTexture);
		if (mPrefilteredCubemapView != null) mDevice.DestroyTextureView(ref mPrefilteredCubemapView);
		if (mPrefilteredCubemapSourceView != null) mDevice.DestroyTextureView(ref mPrefilteredCubemapSourceView);
		if (mPrefilteredCubemapArray != null) mDevice.DestroyTexture(ref mPrefilteredCubemapArray);
		if (mProbeBuffer != null) mDevice.DestroyBuffer(ref mProbeBuffer);
		if (mSH9Buffer != null) mDevice.DestroyBuffer(ref mSH9Buffer);
		if (mLinearSampler != null) mDevice.DestroySampler(ref mLinearSampler);

		// Bind group layouts
		if (mFrameBindGroupLayout != null)
			mDevice.DestroyBindGroupLayout(ref mFrameBindGroupLayout);
		if (mDrawCallBindGroupLayout != null)
			mDevice.DestroyBindGroupLayout(ref mDrawCallBindGroupLayout);
		if (mInstanceBindGroupLayout != null)
			mDevice.DestroyBindGroupLayout(ref mInstanceBindGroupLayout);

		// Material system
		if (mMaterialSystem != null)
		{
			mMaterialSystem.Dispose();
			delete mMaterialSystem;
			mMaterialSystem = null;
		}
	}

	/// Processes deferred GPU resource deletions. Call once per frame.
	public void ProcessDeletions(uint64 frameNumber)
	{
		mGPUResources.ProcessDeletions(frameNumber);
	}

	/// Begins a new frame - rewinds the frame allocator and resets per-frame
	/// shadow allocations. Must be called after all previous-frame RenderData
	/// references have been released (typically after all pipelines have
	/// executed for the frame).
	public void BeginFrame()
	{
		mFrameAllocator.Reset();

		// Create worker allocators on first BeginFrame (single-threaded).
		// Must happen here, not lazily in GetWorkerAllocator, because
		// GetWorkerAllocator is called from multiple threads during ParallelFor.
		if (mWorkerAllocators == null && JobSystem.IsInitialized && JobSystem.WorkerCount > 0)
		{
			let count = JobSystem.WorkerCount + 1;
			mWorkerAllocators = new FrameAllocator[count];
			for (int i = 0; i < count; i++)
				mWorkerAllocators[i] = new FrameAllocator(.Allow);
		}

		if (mWorkerAllocators != null)
		{
			for (let alloc in mWorkerAllocators)
				alloc.Reset();
		}
		CurrentSceneDepthView = null;
		if (mShadowSystem != null)
			mShadowSystem.BeginFrame();
	}

	public void Dispose()
	{
		Shutdown();
	}

	// ==================== Internal ====================

	private Result<void> CreateBindGroupLayouts()
	{
		// Frame bind group layout (set 0):
		//   b0: SceneUniforms (dynamic offset - per-view ring buffer)
		//   b1: LightParams (light count, ambient)
		//   t0: Light buffer (StructuredBuffer<GPULight>)
		//   t1: BRDF integration LUT (Texture2D RG16Float, for split-sum IBL)
		//   t2: Prefiltered cubemap array (TextureCubeArray RGBA16Float, IBL specular)
		//   t3: Reflection probe data (StructuredBuffer<GPUReflectionProbe>)
		//   t4: SH9 coefficients (StructuredBuffer<float4>, IBL diffuse)
		//   s1: Linear+clamp sampler shared by t1 and t2
		BindGroupLayoutEntry[8] frameEntries = .(
			.() { Binding = 0, Visibility = .Vertex | .Fragment | .Compute, Type = .UniformBuffer, HasDynamicOffset = true }, // b0: SceneUniforms
			.UniformBuffer(1, .Fragment),                                           // b1: LightParams
			.() { Binding = 0, Visibility = .Fragment, Type = .StorageBufferReadOnly, StorageBufferStride = (uint32)GPULight.Size }, // t0: Lights
			.SampledTexture(1, .Fragment, .Texture2D),                              // t1: BRDFLut
			.SampledTexture(2, .Fragment, .TextureCubeArray),                       // t2: Prefiltered cubemap array
			.() { Binding = 3, Visibility = .Fragment, Type = .StorageBufferReadOnly, StorageBufferStride = ProbeStride }, // t3: Probes
			.() { Binding = 4, Visibility = .Fragment, Type = .StorageBufferReadOnly, StorageBufferStride = 16 }, // t4: SH9 (float4 stride)
			.Sampler(1, .Fragment)                                                  // s1: LinearSampler
		);

		BindGroupLayoutDesc frameLayoutDesc = .()
		{
			Label = "Frame BindGroup Layout",
			Entries = frameEntries
		};

		if (mDevice.CreateBindGroupLayout(frameLayoutDesc) case .Ok(let layout))
			mFrameBindGroupLayout = layout;
		else
			return .Err;

		// Material bind group layout (set 2) is owned by MaterialSystem.

		// Draw call bind group layout (set 3): object uniforms with dynamic offset
		//   b0: ObjectUniforms (world matrix, prev world matrix) - dynamic offset per draw
		BindGroupLayoutEntry[1] drawEntries = .(
			// Vertex + Fragment visibility: mesh shaders only read object uniforms
			// in the vertex stage, but decals sample the cbuffer (InvWorld, Color,
			// AngleFade) from the fragment stage too.
			.() { Binding = 0, Visibility = .Vertex | .Fragment, Type = .UniformBuffer, HasDynamicOffset = true }
		);

		BindGroupLayoutDesc drawLayoutDesc = .()
		{
			Label = "DrawCall BindGroup Layout",
			Entries = drawEntries
		};

		if (mDevice.CreateBindGroupLayout(drawLayoutDesc) case .Ok(let drawLayout))
			mDrawCallBindGroupLayout = drawLayout;
		else
			return .Err;

		// Instance bind group layout (set 3: t0 = StructuredBuffer<InstanceData>).
		// Per-instance DataOffsets arrive via vertex attribute (slot 1), not a bind group.
		BindGroupLayoutEntry[1] instanceEntries = .(
			.() { Binding = 0, Visibility = .Vertex, Type = .StorageBufferReadOnly, StorageBufferStride = 144 }
		);

		BindGroupLayoutDesc instanceLayoutDesc = .()
		{
			Label = "Instance BindGroup Layout",
			Entries = instanceEntries
		};

		if (mDevice.CreateBindGroupLayout(instanceLayoutDesc) case .Ok(let instanceLayout))
			mInstanceBindGroupLayout = instanceLayout;
		else
			return .Err;

		// Default draw call bind group (identity transform)
		if (CreateDefaultDrawCallBindGroup() case .Err)
			return .Err;

		return .Ok;
	}

	/// Creates the BRDF LUT GPU texture, placeholder cubemap array + structured
	/// buffers, and the linear sampler. All five end up bound at set 0 t1..t4
	/// and s1 by Pipeline.RebuildFrameBindGroup.
	private Result<void> InitializeIBL()
	{
		// --- BRDF LUT (real data, sampled by forward shader in Sub-phase F) ---
		TextureDesc lutDesc = TextureDesc.Texture2D(
			(uint32)BRDFLutData.Width, (uint32)BRDFLutData.Height,
			.RG16Float, .Sampled | .CopyDst, 1, "BRDF LUT");

		if (mDevice.CreateTexture(lutDesc) case .Ok(let lutTex))
			mBRDFLutTexture = lutTex;
		else
			return .Err;

		TextureDataLayout lutLayout = .()
		{
			Offset = 0,
			BytesPerRow = (uint32)(BRDFLutData.Width * 4),  // 2 channels * 2 bytes per channel
			RowsPerImage = (uint32)BRDFLutData.Height
		};
		Extent3D lutExtent = .((uint32)BRDFLutData.Width, (uint32)BRDFLutData.Height, 1);
		TransferHelper.WriteTextureSync(mQueue, mDevice, mBRDFLutTexture,
			Span<uint8>(&BRDFLutData.Data[0], BRDFLutData.DataSize), lutLayout, lutExtent);

		if (mDevice.CreateTextureView(mBRDFLutTexture, .() { Format = .RG16Float }) case .Ok(let lutView))
			mBRDFLutView = lutView;
		else
			return .Err;

		// --- Placeholder prefiltered cubemap array ---
		// Sized to the final probe layout so Sub-phase C just writes content
		// into existing memory. 6*MaxProbes layers, 5 mips, RGBA16Float at 128x128.
		TextureDesc cubeDesc = .()
		{
			Dimension = .Texture2D,
			Format = .RGBA16Float,
			Width = (uint32)IBLProbeFaceSize,
			Height = (uint32)IBLProbeFaceSize,
			ArrayLayerCount = (uint32)(6 * MaxIBLProbes),
			MipLevelCount = (uint32)IBLPrefilterMipCount,
			// RenderTarget: ProbeCapturePass renders directly into face slices (Sub-phase C).
			// Storage: GGX prefilter compute writes mip chain (Sub-phase D).
			// Sampled: forward shader reads via TextureCubeArray (Sub-phase F).
			Usage = .Sampled | .Storage | .RenderTarget,
			Label = "IBL Prefiltered Cubemap Array"
		};

		if (mDevice.CreateTexture(cubeDesc) case .Ok(let cubeTex))
			mPrefilteredCubemapArray = cubeTex;
		else
			return .Err;

		// Cubemap-array view exposing ALL mips AND every probe's 6 layers.
		// Vulkan requires a TextureCubeArray view's layerCount to be a multiple
		// of 6 (one cubemap = 6 layers); the descriptor default of 1 fails
		// validation. The forward shader's IBL eval (Sub-phase F) needs every
		// mip so SampleLevel(N, roughness*maxMip) can pick the right
		// pre-filtered LOD.
		if (mDevice.CreateTextureView(mPrefilteredCubemapArray, .()
			{
				Format = .RGBA16Float,
				Dimension = .TextureCubeArray,
				MipLevelCount = (uint32)IBLPrefilterMipCount,
				ArrayLayerCount = (uint32)(6 * MaxIBLProbes)
			}) case .Ok(let cubeView))
			mPrefilteredCubemapView = cubeView;
		else
			return .Err;

		// Mip-0-only source view used by the prefilter + SH9 compute passes.
		// The prefilter writes mips 1..N as General within the same compute
		// dispatch, so the source descriptor's view must NOT cover those mips
		// or Vulkan flags a layout-mismatch validation error.
		if (mDevice.CreateTextureView(mPrefilteredCubemapArray, .()
			{
				Format = .RGBA16Float,
				Dimension = .TextureCubeArray,
				BaseMipLevel = 0,
				MipLevelCount = 1,
				ArrayLayerCount = (uint32)(6 * MaxIBLProbes),
				Label = "IBL Prefiltered Cubemap Source (mip 0)"
			}) case .Ok(let srcView))
			mPrefilteredCubemapSourceView = srcView;
		else
			return .Err;

		// --- Placeholder per-probe data StructuredBuffer ---
		// MaxProbes entries, all zero (Enabled = 0 disables them in the shader loop).
		let probeBufferSize = (uint64)(MaxIBLProbes * ProbeStride);
		BufferDesc probeBufDesc = .()
		{
			Label = "IBL Probe Buffer",
			Size = probeBufferSize,
			Usage = .StorageRead,
			Memory = .CpuToGpu
		};
		if (mDevice.CreateBuffer(probeBufDesc) case .Ok(let probeBuf))
			mProbeBuffer = probeBuf;
		else
			return .Err;

		// --- Placeholder SH9 coefficients buffer ---
		// 9 float4 per probe, all zero (no irradiance contribution).
		let sh9BufferSize = (uint64)(MaxIBLProbes * IBLSH9CoeffPerProbe * 16); // float4 = 16 bytes
		BufferDesc sh9BufDesc = .()
		{
			Label = "IBL SH9 Buffer",
			Size = sh9BufferSize,
			Usage = .StorageRead,
			Memory = .CpuToGpu
		};
		if (mDevice.CreateBuffer(sh9BufDesc) case .Ok(let sh9Buf))
			mSH9Buffer = sh9Buf;
		else
			return .Err;

		// --- Linear+clamp sampler shared by BRDF LUT and prefiltered cubemap ---
		SamplerDesc samplerDesc = .()
		{
			MinFilter = .Linear,
			MagFilter = .Linear,
			MipmapFilter = .Linear,  // smooth mip transitions on the prefiltered cubemap
			AddressU = .ClampToEdge,
			AddressV = .ClampToEdge,
			AddressW = .ClampToEdge
		};
		if (mDevice.CreateSampler(samplerDesc) case .Ok(let sampler))
			mLinearSampler = sampler;
		else
			return .Err;

		// Transition the cubemap from VK_IMAGE_LAYOUT_UNDEFINED (its initial
		// state after creation) to ShaderRead so the very first frame's bind
		// group passes Vulkan validation - the forward shader has the
		// PrefilteredCubemap descriptor bound every frame regardless of
		// whether the IBL loop actually samples it, and Vulkan requires the
		// resource to match the descriptor's expected layout when the
		// descriptor is written, not just when it is sampled.
		if (mQueue.CreateTransferBatch() case .Ok(var tb))
		{
			// Submit an empty batch just to flush any pending uploads, then
			// use a fresh command encoder for the transition itself - the
			// transfer batch API doesn't expose raw barrier injection.
			tb.Submit();
			mDevice.WaitIdle();
			mQueue.DestroyTransferBatch(ref tb);
		}
		if (mDevice.CreateCommandPool(.Graphics) case .Ok(let pool))
		{
			defer { var poolRef = pool; mDevice.DestroyCommandPool(ref poolRef); }
			if (pool.CreateEncoder() case .Ok(var encoder))
			{
				encoder.TransitionTexture(mPrefilteredCubemapArray, .Undefined, .ShaderRead);
				let cmdBuf = encoder.Finish();
				if (cmdBuf != null)
				{
					mQueue.Submit(cmdBuf);
					mQueue.WaitIdle();
				}
				pool.DestroyEncoder(ref encoder);
			}
		}

		return .Ok;
	}

	/// GPU-packed object uniforms. Must match forward.vert.hlsl ObjectUniforms.
	/// Layout: 2 matrices (128) + Vector4 InstanceColor (16) = 144.
	[CRepr]
	private struct DefaultObjectUniforms
	{
		public Matrix WorldMatrix;
		public Matrix PrevWorldMatrix;
		public Vector4 InstanceColor;
		public const uint64 Size = 144;
	}

	private Result<void> CreateDefaultDrawCallBindGroup()
	{
		BufferDesc drawBufDesc = .()
		{
			Label = "Default DrawCall Uniforms",
			Size = DefaultObjectUniforms.Size,
			Usage = .Uniform,
			Memory = .CpuToGpu
		};

		if (mDevice.CreateBuffer(drawBufDesc) case .Ok(let drawBuf))
		{
			mDefaultDrawCallBuffer = drawBuf;

			DefaultObjectUniforms objData = .()
			{
				WorldMatrix = .Identity,
				PrevWorldMatrix = .Identity,
				InstanceColor = .(1, 1, 1, 1)
			};
			TransferHelper.WriteMappedBuffer(drawBuf, 0,
				Span<uint8>((uint8*)&objData, DefaultObjectUniforms.Size));
		}
		else
			return .Err;

		BindGroupEntry[1] drawBgEntries = .(
			BindGroupEntry.Buffer(mDefaultDrawCallBuffer, 0, DefaultObjectUniforms.Size)
		);

		BindGroupDesc drawBgDesc = .()
		{
			Label = "Default DrawCall BindGroup",
			Layout = mDrawCallBindGroupLayout,
			Entries = drawBgEntries
		};

		if (mDevice.CreateBindGroup(drawBgDesc) case .Ok(let drawBg))
			mDefaultDrawCallBindGroup = drawBg;
		else
			return .Err;

		return .Ok;
	}
}
