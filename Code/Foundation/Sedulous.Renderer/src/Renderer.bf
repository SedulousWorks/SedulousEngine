namespace Sedulous.Renderer;

using System;
using Sedulous.RHI;
using Sedulous.Materials;
using Sedulous.Core.Mathematics;

/// Shared rendering infrastructure — owns GPU resources, materials, pipeline cache,
/// lighting, and bind group layouts that are common across all views/pipelines.
///
/// Sits between the RHI (raw GPU API) and per-view Pipeline (pass execution).
/// One Renderer per application. Multiple Pipelines can reference the same Renderer.
public class Renderer : IDisposable
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

		return .Ok;
	}

	/// Shuts down and releases all shared resources.
	public void Shutdown()
	{
		if (mDevice != null)
			mDevice.WaitIdle();

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

	public void Dispose()
	{
		Shutdown();
	}

	// ==================== Internal ====================

	private Result<void> CreateBindGroupLayouts()
	{
		// Frame bind group layout (set 0):
		//   b0: SceneUniforms
		//   b1: LightParams (light count, ambient)
		//   t0: Light buffer (StructuredBuffer<GPULight>)
		BindGroupLayoutEntry[3] frameEntries = .(
			.UniformBuffer(0, .Vertex | .Fragment | .Compute),                     // b0: SceneUniforms
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
