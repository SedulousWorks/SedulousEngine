namespace Sedulous.Renderer;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Materials;
using Sedulous.Core.Mathematics;
using Sedulous.Core.Memory;
using Sedulous.Renderer.Shadows;
using Sedulous.Renderer.Debug;

/// Shared rendering infrastructure — owns GPU resources, materials, pipeline cache,
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

	// Lighting
	private LightBuffer mLightBuffer ~ delete _;

	// Pipeline state cache
	private PipelineStateCache mPipelineStateCache ~ delete _;

	// Compute skinning
	private SkinningSystem mSkinningSystem ~ { _?.Dispose(); delete _; };

	// Shadow system (atlas + data buffer + bind group)
	private ShadowSystem mShadowSystem ~ { _?.Dispose(); delete _; };

	// Debug draw system (font texture + per-frame vertex buffers) + immediate-mode API
	private DebugDrawSystem mDebugDrawSystem ~ { _?.Dispose(); delete _; };
	private DebugDraw mDebugDraw = new DebugDraw() ~ delete _;

	// Per-frame scratch allocator for render data extraction.
	// Reset at the start of each frame via BeginFrame().
	// .Allow — Beef classes carry Object's destructor chain; we let the allocator
	// track and run them on Reset. Render data subclasses should not define user
	// destructors (convention, not enforced).
	private FrameAllocator mFrameAllocator = new FrameAllocator(.Allow) ~ delete _;

	// Registered renderers, keyed by category. RenderContext owns the instances —
	// shared across all Pipeline / ShadowPipeline instances built on this context.
	private List<Renderer>[RenderCategories.Count] mRenderersByCategory;
	// Flat owning list (a renderer may appear in multiple categories).
	private List<Renderer> mOwnedRenderers = new .() ~ DeleteContainerAndItems!(_);

	// Shader system (not owned)
	private Sedulous.Shaders.ShaderSystem mShaderSystem;

	// Shared bind group layouts (frequency model)
	private IBindGroupLayout mFrameBindGroupLayout;
	private IBindGroupLayout mDrawCallBindGroupLayout;

	// Default draw call bind group (identity transform)
	private IBindGroup mDefaultDrawCallBindGroup;
	private IBuffer mDefaultDrawCallBuffer;

	// ==================== Properties ====================

	/// The RHI device.
	public IDevice Device => mDevice;

	/// The graphics queue.
	public IQueue Queue => mQueue;

	/// GPU resource manager (meshes, textures, bone buffers).
	public GPUResourceManager GPUResources => mGPUResources;

	/// Material system (manages material bind groups, default textures, per-instance GPU resources).
	public MaterialSystem MaterialSystem => mMaterialSystem;

	/// Default material bind group (white albedo, 0.5 roughness, 0 metallic).
	public IBindGroup DefaultMaterialBindGroup => mDefaultMaterialBindGroup;

	/// Default draw call bind group (identity transform).
	public IBindGroup DefaultDrawCallBindGroup => mDefaultDrawCallBindGroup;

	/// Light buffer for uploading and accessing light data.
	public LightBuffer LightBuffer => mLightBuffer;

	/// Pipeline state cache (creates GPU pipelines on demand from material config).
	public PipelineStateCache PipelineStateCache => mPipelineStateCache;

	/// Compute skinning system.
	public SkinningSystem SkinningSystem => mSkinningSystem;

	/// Shadow system (atlas + data buffer + bind group). Created in Initialize.
	public ShadowSystem ShadowSystem => mShadowSystem;

	/// Debug draw system (GPU resources backing DebugDraw).
	public DebugDrawSystem DebugDrawSystem => mDebugDrawSystem;

	/// Immediate-mode debug draw API. Call Draw* methods from game code to
	/// queue lines, wire shapes, and text to be rendered by DebugPass + OverlayPass.
	/// Cleared at the end of each frame by the renderer.
	public DebugDraw DebugDraw => mDebugDraw;

	/// Per-frame scratch allocator. Render data allocated here is valid until
	/// the next BeginFrame() call, which rewinds the allocator.
	public FrameAllocator FrameAllocator => mFrameAllocator;

	/// Registers a per-type drawer. RenderContext takes ownership.
	/// The renderer is indexed against every category returned by GetSupportedCategories().
	/// All Pipelines built on this context share the same renderers.
	public void RegisterRenderer(Renderer renderer)
	{
		if (renderer == null) return;

		mOwnedRenderers.Add(renderer);

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
		}
	}

	/// Frame-level bind group layout (set 0).
	public IBindGroupLayout FrameBindGroupLayout => mFrameBindGroupLayout;

	/// Material bind group layout (set 2) — from MaterialSystem.
	public IBindGroupLayout MaterialBindGroupLayout => mMaterialSystem?.DefaultMaterialLayout;

	/// Draw-call bind group layout (set 3).
	public IBindGroupLayout DrawCallBindGroupLayout => mDrawCallBindGroupLayout;

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

		// Light buffer
		mLightBuffer = new LightBuffer();
		if (mLightBuffer.Initialize(device) case .Err)
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

		// Bind group layouts
		if (mFrameBindGroupLayout != null)
			mDevice.DestroyBindGroupLayout(ref mFrameBindGroupLayout);
		if (mDrawCallBindGroupLayout != null)
			mDevice.DestroyBindGroupLayout(ref mDrawCallBindGroupLayout);

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

	/// Begins a new frame — rewinds the frame allocator and resets per-frame
	/// shadow allocations. Must be called after all previous-frame RenderData
	/// references have been released (typically after all pipelines have
	/// executed for the frame).
	public void BeginFrame()
	{
		mFrameAllocator.Reset();
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
		//   b0: SceneUniforms (dynamic offset — per-view ring buffer)
		//   b1: LightParams (light count, ambient)
		//   t0: Light buffer (StructuredBuffer<GPULight>)
		BindGroupLayoutEntry[3] frameEntries = .(
			.() { Binding = 0, Visibility = .Vertex | .Fragment | .Compute, Type = .UniformBuffer, HasDynamicOffset = true }, // b0: SceneUniforms
			.UniformBuffer(1, .Fragment),                                           // b1: LightParams
			.() { Binding = 0, Visibility = .Fragment, Type = .StorageBufferReadOnly } // t0: Lights
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
		//   b0: ObjectUniforms (world matrix, prev world matrix) — dynamic offset per draw
		BindGroupLayoutEntry[1] drawEntries = .(
			.() { Binding = 0, Visibility = .Vertex, Type = .UniformBuffer, HasDynamicOffset = true }
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

		// Default draw call bind group (identity transform)
		if (CreateDefaultDrawCallBindGroup() case .Err)
			return .Err;

		return .Ok;
	}

	/// GPU-packed object uniforms. Must match forward.vert.hlsl ObjectUniforms.
	[CRepr]
	private struct DefaultObjectUniforms
	{
		public Matrix WorldMatrix;
		public Matrix PrevWorldMatrix;
		public const uint64 Size = 128;
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
				PrevWorldMatrix = .Identity
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
