namespace Sedulous.Renderer;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Core.Mathematics;

/// Orchestrates rendering by managing pipeline passes, per-frame resources,
/// GPU resource management, and the render graph.
///
/// The pipeline renders to its own output texture — it doesn't know about swapchains.
/// The caller (RenderSubsystem) blits the pipeline output to the backbuffer, an editor
/// viewport, an offscreen target, etc.
///
/// Scene-independent. Receives a RenderView (camera + extracted data), renders it
/// using registered passes, and produces an output texture.
public class Pipeline : IDisposable
{
	private IDevice mDevice;
	private IQueue mQueue;

	// Passes
	private List<PipelinePass> mPasses = new .() ~ delete _;

	// Per-frame resources (double-buffered)
	public const int32 MaxFramesInFlight = 2;
	private PerFrameResources[MaxFramesInFlight] mFrameResources;

	// GPU resource management
	private GPUResourceManager mGPUResources ~ delete _;

	// Render graph
	private RenderGraph mRenderGraph ~ delete _;

	// Shared bind group layouts (frequency model)
	private IBindGroupLayout mFrameBindGroupLayout;
	private IBindGroupLayout mDrawCallBindGroupLayout;

	// Pipeline output (owned, persistent)
	private ITexture mOutputTexture;
	private ITextureView mOutputTextureView;
	private uint32 mOutputWidth;
	private uint32 mOutputHeight;
	private TextureFormat mOutputFormat = .RGBA16Float;

	// Shader system (optional, set by subsystem — not owned)
	private Sedulous.Shaders.ShaderSystem mShaderSystem;

	// Pipeline state cache
	private PipelineStateCache mPipelineStateCache ~ delete _;

	// Frame counter
	private uint64 mFrameNumber = 0;

	// ==================== Properties ====================

	/// The RHI device.
	public IDevice Device => mDevice;

	/// The graphics queue.
	public IQueue Queue => mQueue;

	/// GPU resource manager (meshes, textures, bone buffers).
	public GPUResourceManager GPUResources => mGPUResources;

	/// The render graph.
	public RenderGraph RenderGraph => mRenderGraph;

	/// Current frame number (monotonic, for deferred deletion timing).
	public uint64 FrameNumber => mFrameNumber;

	/// Gets per-frame resources for a frame index.
	public PerFrameResources GetFrameResources(int32 frameIndex)
	{
		return mFrameResources[frameIndex % MaxFramesInFlight];
	}

	/// Frame-level bind group layout (set 0).
	public IBindGroupLayout FrameBindGroupLayout => mFrameBindGroupLayout;

	/// Draw-call bind group layout (set 3).
	public IBindGroupLayout DrawCallBindGroupLayout => mDrawCallBindGroupLayout;

	/// Shader system (optional, for passes that need to compile shaders).
	public Sedulous.Shaders.ShaderSystem ShaderSystem
	{
		get => mShaderSystem;
		set
		{
			mShaderSystem = value;
			// Create/recreate pipeline state cache when shader system is set
			delete mPipelineStateCache;
			if (value != null)
				mPipelineStateCache = new PipelineStateCache(mDevice, value, this);
		}
	}

	/// Pipeline state cache (creates GPU pipelines on demand from material config).
	public PipelineStateCache PipelineStateCache => mPipelineStateCache;

	/// The pipeline output texture. Read this after Render() to blit to the final target.
	public ITexture OutputTexture => mOutputTexture;

	/// The pipeline output texture view.
	public ITextureView OutputTextureView => mOutputTextureView;

	/// Output width in pixels.
	public uint32 OutputWidth => mOutputWidth;

	/// Output height in pixels.
	public uint32 OutputHeight => mOutputHeight;

	/// Output format.
	public TextureFormat OutputFormat => mOutputFormat;

	// ==================== Lifecycle ====================

	/// Initializes the pipeline.
	public Result<void> Initialize(IDevice device, IQueue queue, uint32 width, uint32 height, TextureFormat outputFormat = .RGBA16Float)
	{
		mDevice = device;
		mQueue = queue;
		mOutputFormat = outputFormat;

		// GPU resource manager
		mGPUResources = new GPUResourceManager();
		if (mGPUResources.Initialize(device, queue) case .Err)
			return .Err;

		// Render graph
		mRenderGraph = new RenderGraph(device, .() { FrameBufferCount = MaxFramesInFlight });

		// Create output texture
		if (CreateOutputTexture(width, height) case .Err)
			return .Err;

		// Create shared bind group layouts (needed before per-frame bind groups)
		if (CreateBindGroupLayouts() case .Err)
			return .Err;

		// Create per-frame resources (buffers + bind groups)
		if (CreatePerFrameResources() case .Err)
			return .Err;

		return .Ok;
	}

	/// Adds a pass to the pipeline. The pipeline takes ownership.
	public Result<void> AddPass(PipelinePass pass)
	{
		if (pass.OnInitialize(this) case .Err)
			return .Err;

		mPasses.Add(pass);
		return .Ok;
	}

	/// Gets a pass by type.
	public T GetPass<T>() where T : PipelinePass
	{
		for (let pass in mPasses)
		{
			if (let typed = pass as T)
				return typed;
		}
		return null;
	}

	/// Shuts down the pipeline and releases all resources.
	public void Shutdown()
	{
		if (mDevice != null)
			mDevice.WaitIdle();

		// Shutdown passes in reverse order
		for (int i = mPasses.Count - 1; i >= 0; i--)
		{
			mPasses[i].OnShutdown();
			delete mPasses[i];
		}
		mPasses.Clear();

		// Release per-frame resources
		for (int i = 0; i < MaxFramesInFlight; i++)
		{
			if (mFrameResources[i] != null)
			{
				mFrameResources[i].Release(mDevice);
				delete mFrameResources[i];
				mFrameResources[i] = null;
			}
		}

		// Release output texture
		DestroyOutputTexture();

		// Release bind group layouts
		if (mFrameBindGroupLayout != null)
			mDevice.DestroyBindGroupLayout(ref mFrameBindGroupLayout);
		if (mDrawCallBindGroupLayout != null)
			mDevice.DestroyBindGroupLayout(ref mDrawCallBindGroupLayout);
	}

	// ==================== Rendering ====================

	/// Renders a view to the pipeline's output texture.
	/// After this call, read OutputTexture/OutputTextureView to blit the result
	/// to a swapchain, editor viewport, offscreen target, etc.
	public void Render(ICommandEncoder encoder, RenderView view)
	{
		let frameIndex = view.FrameIndex % MaxFramesInFlight;
		let frame = mFrameResources[frameIndex];

		// Update per-frame uniforms
		UploadSceneUniforms(frame, view);

		// Process deferred GPU resource deletions
		mGPUResources.ProcessDeletions(mFrameNumber);

		// Set output size for render graph (affects relative-sized transients)
		mRenderGraph.SetOutputSize(mOutputWidth, mOutputHeight);

		// Begin render graph frame
		mRenderGraph.BeginFrame((int32)frameIndex);

		// Import the pipeline output as the render target
		// Passes write to "PipelineOutput" — this is the pipeline's own texture
		let outputHandle = mRenderGraph.ImportTarget("PipelineOutput", mOutputTexture, mOutputTextureView);

		// Always clear the output to a known state before passes run.
		// Passes use LoadOp.Load and build on top of this.
		mRenderGraph.AddRenderPass("ClearOutput", scope (builder) => {
			builder
				.SetColorTarget(0, outputHandle, .Clear, .Store, ClearColor(0.0f, 0.0f, 0.0f, 1.0f))
				.NeverCull()
				.SetExecute(new (encoder) => {});
		});

		// Let each pass add its graph nodes
		for (let pass in mPasses)
			pass.AddPasses(mRenderGraph, view, this);

		// Compile and execute the graph
		mRenderGraph.Execute(encoder);

		// End render graph frame
		mRenderGraph.EndFrame();

		mFrameNumber++;
	}

	/// Resizes the pipeline output.
	public void OnResize(uint32 width, uint32 height)
	{
		if (width == 0 || height == 0)
			return;
		if (width == mOutputWidth && height == mOutputHeight)
			return;

		mDevice.WaitIdle();
		DestroyOutputTexture();
		CreateOutputTexture(width, height);

		for (let pass in mPasses)
			pass.OnResize(width, height);
	}

	// ==================== Internal ====================

	private Result<void> CreateOutputTexture(uint32 width, uint32 height)
	{
		mOutputWidth = width;
		mOutputHeight = height;

		TextureDesc texDesc = .()
		{
			Label = "Pipeline Output",
			Width = width,
			Height = height,
			Depth = 1,
			Format = mOutputFormat,
			Usage = .RenderTarget | .Sampled | .CopySrc,
			Dimension = .Texture2D,
			MipLevelCount = 1,
			ArrayLayerCount = 1,
			SampleCount = 1
		};

		if (mDevice.CreateTexture(texDesc) case .Ok(let tex))
			mOutputTexture = tex;
		else
			return .Err;

		TextureViewDesc viewDesc = .()
		{
			Label = "Pipeline Output View",
			Format = mOutputFormat,
			Dimension = .Texture2D
		};

		if (mDevice.CreateTextureView(mOutputTexture, viewDesc) case .Ok(let view))
			mOutputTextureView = view;
		else
			return .Err;

		return .Ok;
	}

	private void DestroyOutputTexture()
	{
		if (mOutputTextureView != null)
			mDevice.DestroyTextureView(ref mOutputTextureView);
		if (mOutputTexture != null)
			mDevice.DestroyTexture(ref mOutputTexture);
		mOutputWidth = 0;
		mOutputHeight = 0;
	}

	private void UploadSceneUniforms(PerFrameResources frame, RenderView view)
	{
		if (frame.SceneUniformBuffer == null)
			return;

		Matrix invView = .Identity;
		Matrix.Invert(view.ViewMatrix, out invView);

		Matrix invProj = .Identity;
		Matrix.Invert(view.ProjectionMatrix, out invProj);

		Matrix invViewProj = .Identity;
		Matrix.Invert(view.ViewProjectionMatrix, out invViewProj);

		SceneUniforms uniforms = .()
		{
			ViewMatrix = view.ViewMatrix,
			ProjectionMatrix = view.ProjectionMatrix,
			ViewProjectionMatrix = view.ViewProjectionMatrix,
			InvViewMatrix = invView,
			InvProjectionMatrix = invProj,
			InvViewProjectionMatrix = invViewProj,
			CameraPosition = view.CameraPosition,
			NearPlane = view.NearPlane,
			FarPlane = view.FarPlane,
			Time = view.TotalTime,
			DeltaTime = view.DeltaTime,
			ScreenSize = .(view.Width, view.Height),
			InvScreenSize = .(1.0f / Math.Max(view.Width, 1), 1.0f / Math.Max(view.Height, 1))
		};

		TransferHelper.WriteMappedBuffer(
			frame.SceneUniformBuffer, 0,
			Span<uint8>((uint8*)&uniforms, SceneUniforms.Size)
		);
	}

	private Result<void> CreatePerFrameResources()
	{
		for (int i = 0; i < MaxFramesInFlight; i++)
		{
			let frame = new PerFrameResources();

			// Scene uniform buffer (set 0)
			BufferDesc sceneUBDesc = .()
			{
				Label = "Scene Uniforms",
				Size = SceneUniforms.Size,
				Usage = .Uniform,
				Memory = .CpuToGpu
			};

			if (mDevice.CreateBuffer(sceneUBDesc) case .Ok(let sceneBuf))
				frame.SceneUniformBuffer = sceneBuf;
			else
			{
				delete frame;
				return .Err;
			}

			// Object uniform buffer (set 3, dynamic offsets)
			// 256-byte aligned, supports up to 4096 objects
			let objectBufferSize = (uint64)(256 * 4096);
			BufferDesc objectUBDesc = .()
			{
				Label = "Object Uniforms",
				Size = objectBufferSize,
				Usage = .Uniform,
				Memory = .CpuToGpu
			};

			if (mDevice.CreateBuffer(objectUBDesc) case .Ok(let objBuf))
				frame.ObjectUniformBuffer = objBuf;
			else
			{
				frame.Release(mDevice);
				delete frame;
				return .Err;
			}

			// Create frame bind group (set 0) if layout is available
			if (mFrameBindGroupLayout != null && frame.SceneUniformBuffer != null)
			{
				BindGroupEntry[1] bgEntries = .(
					BindGroupEntry.Buffer(frame.SceneUniformBuffer, 0, SceneUniforms.Size)
				);

				BindGroupDesc bgDesc = .()
				{
					Label = "Frame BindGroup",
					Layout = mFrameBindGroupLayout,
					Entries = bgEntries
				};

				if (mDevice.CreateBindGroup(bgDesc) case .Ok(let bg))
					frame.FrameBindGroup = bg;
			}

			mFrameResources[i] = frame;
		}

		return .Ok;
	}

	private Result<void> CreateBindGroupLayouts()
	{
		// Frame bind group layout (set 0): scene uniforms
		BindGroupLayoutEntry[1] frameEntries = .(
			.UniformBuffer(0, .Vertex | .Fragment | .Compute)
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

		// Draw call bind group layout (set 3): object uniforms with dynamic offset
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

		return .Ok;
	}

	public void Dispose()
	{
		Shutdown();
	}
}
