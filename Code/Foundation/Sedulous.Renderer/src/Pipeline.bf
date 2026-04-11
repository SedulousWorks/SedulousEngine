namespace Sedulous.Renderer;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Core.Mathematics;
using Sedulous.Profiler;

/// Per-view pass execution engine.
///
/// Owns the pass list, per-frame resources, output texture, and render graph.
/// References shared infrastructure (GPU resources, materials, shaders) from Renderer.
///
/// The pipeline renders to its own output texture — it doesn't know about swapchains.
/// The caller (RenderSubsystem) blits the pipeline output to the backbuffer.
public class Pipeline : IRenderingPipeline, IDisposable
{
	// Shared infrastructure (not owned)
	private RenderContext mRenderContext;

	// Passes
	private List<PipelinePass> mPasses = new .() ~ delete _;

	// Per-frame resources (double-buffered)
	public const int32 MaxFramesInFlight = 2;
	private PerFrameResources[MaxFramesInFlight] mFrameResources;

	// Render graph
	private RenderGraph mRenderGraph ~ delete _;

	// Pipeline output
	private ITexture mOutputTexture;
	private ITextureView mOutputTextureView;
	private uint32 mOutputWidth;
	private uint32 mOutputHeight;
	private TextureFormat mOutputFormat = .RGBA16Float;

	// Post-processing
	private PostProcessStack mPostProcessStack;

	// Frame counter
	private uint64 mFrameNumber = 0;

	// ==================== Properties ====================

	/// The shared renderer infrastructure.
	public RenderContext RenderContext => mRenderContext;

	/// The render graph.
	public RenderGraph RenderGraph => mRenderGraph;

	/// Current frame number (monotonic, for deferred deletion timing).
	public uint64 FrameNumber => mFrameNumber;

	/// Gets per-frame resources for a frame index.
	public PerFrameResources GetFrameResources(int32 frameIndex)
	{
		return mFrameResources[frameIndex % MaxFramesInFlight];
	}

	/// The pipeline output texture. Read this after Render() to blit.
	public ITexture OutputTexture => mOutputTexture;

	/// The pipeline output texture view.
	public ITextureView OutputTextureView => mOutputTextureView;

	/// Output width in pixels.
	public uint32 OutputWidth => mOutputWidth;

	/// Output height in pixels.
	public uint32 OutputHeight => mOutputHeight;

	/// Output format.
	public TextureFormat OutputFormat => mOutputFormat;

	/// Post-processing stack (optional). Set before adding passes.
	public PostProcessStack PostProcessStack
	{
		get => mPostProcessStack;
		set => mPostProcessStack = value;
	}

	// ==================== Lifecycle ====================

	/// Initializes the pipeline with a reference to the shared renderer.
	public Result<void> Initialize(RenderContext renderContext, uint32 width, uint32 height, TextureFormat outputFormat = .RGBA16Float)
	{
		mRenderContext = renderContext;
		mOutputFormat = outputFormat;

		// Render graph
		mRenderGraph = new RenderGraph(renderContext.Device, .() { FrameBufferCount = MaxFramesInFlight });

		// Create output texture
		if (CreateOutputTexture(width, height) case .Err)
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

	/// Resets per-frame ring buffer offsets for the given frame slot.
	/// Must be called once per frame before the first Render() call. RenderSubsystem
	/// calls this on every Pipeline that will render this frame (main pipeline + any
	/// shadow pipelines) so multiple Render() calls within the frame can append to
	/// the same per-frame resources without overwriting each other.
	public void BeginFrame(int32 frameIndex)
	{
		let frame = mFrameResources[frameIndex % MaxFramesInFlight];
		if (frame == null) return;
		frame.SceneBufferOffset = 0;
		frame.ObjectBufferOffset = 0;
		frame.CurrentSceneOffset = 0;
	}

	/// Dispatches a render batch for a category to every renderer registered with
	/// the RenderContext for that category. Called by render passes after they've
	/// set up render targets, pipeline state, viewport, and frame-level bind groups.
	public void RenderCategory(IRenderPassEncoder encoder, RenderDataCategory category,
		PerFrameResources frame, RenderView view, RenderBatchFlags flags)
	{
		let batch = view.RenderData?.GetBatch(category);
		if (batch == null || batch.Count == 0)
			return;

		let renderers = mRenderContext.GetRenderersFor(category);
		if (renderers == null)
			return;

		for (let renderer in renderers)
			renderer.RenderBatch(encoder, batch, mRenderContext, this, frame, view, flags);
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

	/// Shuts down the pipeline and releases per-view resources.
	public void Shutdown()
	{
		let device = mRenderContext?.Device;
		if (device != null)
			device.WaitIdle();

		// Shutdown post-process stack
		if (mPostProcessStack != null)
		{
			mPostProcessStack.Shutdown();
			delete mPostProcessStack;
			mPostProcessStack = null;
		}

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
				mFrameResources[i].Release(device);
				delete mFrameResources[i];
				mFrameResources[i] = null;
			}
		}

		// Release output texture
		DestroyOutputTexture();

		mRenderContext = null;
	}

	// ==================== Rendering ====================

	/// Renders a view to the pipeline's output texture.
	public void Render(ICommandEncoder encoder, RenderView view)
	{
		using (Profiler.Begin("Pipeline.Render"))
		{
		let frameIndex = view.FrameIndex % MaxFramesInFlight;
		let frame = mFrameResources[frameIndex];

		// Update per-view uniforms (appends into the per-frame ring buffers).
		using (Profiler.Begin("UploadUniforms"))
		{
			// Append this view's scene uniforms into the ring buffer and remember the
			// offset so passes can bind the frame group with the right dynamic offset.
			frame.CurrentSceneOffset = WriteSceneUniforms(frame, view);

			// Upload light data
			if (view.RenderData != null)
				mRenderContext.LightBuffer.Upload(view.RenderData, view.FrameIndex);

			// Rebuild frame bind group (includes light buffer)
			RebuildFrameBindGroup(frame, view.FrameIndex);
		}

		// Process deferred GPU resource deletions
		mRenderContext.ProcessDeletions(mFrameNumber);

		// Set output size for render graph (affects relative-sized transients)
		mRenderGraph.SetOutputSize(mOutputWidth, mOutputHeight);

		// Begin render graph frame
		mRenderGraph.BeginFrame((int32)frameIndex);

		let hasPostProcess = mPostProcessStack != null && mPostProcessStack.HasActiveEffects;

		if (hasPostProcess)
		{
			// With post-processing:
			//   "PipelineOutput" = transient HDR texture (scene passes write here)
			//   "FinalOutput" = imported real output (post-process stack writes here)
			let finalHandle = mRenderGraph.ImportTarget("FinalOutput", mOutputTexture, mOutputTextureView);
			let hdrDesc = RGTextureDesc(mOutputFormat) { Usage = .RenderTarget | .Sampled };
			let sceneHdrHandle = mRenderGraph.CreateTransient("PipelineOutput", hdrDesc);

			mRenderGraph.AddRenderPass("ClearOutput", scope (builder) => {
				builder
					.SetColorTarget(0, sceneHdrHandle, .Clear, .Store, ClearColor(0.0f, 0.0f, 0.0f, 1.0f))
					.NeverCull()
					.SetExecute(new (encoder) => {});
			});

			for (let pass in mPasses)
				pass.AddPasses(mRenderGraph, view, this);

			let depthHandle = mRenderGraph.GetResource("SceneDepth");
			mPostProcessStack.Execute(mRenderGraph, view, sceneHdrHandle, depthHandle, finalHandle);
		}
		else
		{
			// Without post-processing: scene passes write directly to imported output
			let outputHandle = mRenderGraph.ImportTarget("PipelineOutput", mOutputTexture, mOutputTextureView);

			mRenderGraph.AddRenderPass("ClearOutput", scope (builder) => {
				builder
					.SetColorTarget(0, outputHandle, .Clear, .Store, ClearColor(0.0f, 0.0f, 0.0f, 1.0f))
					.NeverCull()
					.SetExecute(new (encoder) => {});
			});

			for (let pass in mPasses)
				pass.AddPasses(mRenderGraph, view, this);
		}

		// Compile and execute the graph
		using (Profiler.Begin("RenderGraph.Execute"))
			mRenderGraph.Execute(encoder);

		// End render graph frame
		mRenderGraph.EndFrame();

		mFrameNumber++;
		} // Pipeline.Render scope
	}

	/// Resizes the pipeline output.
	public void OnResize(uint32 width, uint32 height)
	{
		if (width == 0 || height == 0)
			return;
		if (width == mOutputWidth && height == mOutputHeight)
			return;

		mRenderContext.Device.WaitIdle();
		DestroyOutputTexture();
		CreateOutputTexture(width, height);

		for (let pass in mPasses)
			pass.OnResize(width, height);
	}

	/// Writes object uniforms (world matrix) to the per-frame object buffer and returns the dynamic offset.
	/// Returns uint32.MaxValue if the buffer is full.
	public uint32 WriteObjectUniforms(int32 frameIndex, Matrix worldMatrix, Matrix prevWorldMatrix)
	{
		let frame = mFrameResources[frameIndex % MaxFramesInFlight];
		if (frame == null || frame.ObjectUniformBuffer == null)
			return uint32.MaxValue;

		if (frame.ObjectBufferOffset >= PerFrameResources.MaxObjects * PerFrameResources.ObjectAlignment)
			return uint32.MaxValue;

		let offset = frame.ObjectBufferOffset;

		ObjectUniforms objData = .()
		{
			WorldMatrix = worldMatrix,
			PrevWorldMatrix = prevWorldMatrix
		};

		TransferHelper.WriteMappedBuffer(
			frame.ObjectUniformBuffer, (uint64)offset,
			Span<uint8>((uint8*)&objData, ObjectUniforms.Size)
		);

		frame.ObjectBufferOffset += PerFrameResources.ObjectAlignment;
		return offset;
	}

	public void Dispose()
	{
		Shutdown();
	}

	// ==================== Internal ====================

	/// GPU-packed object uniforms. Must match forward.vert.hlsl ObjectUniforms.
	[CRepr]
	private struct ObjectUniforms
	{
		public Matrix WorldMatrix;
		public Matrix PrevWorldMatrix;
		public const uint64 Size = 128;
	}

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

		if (mRenderContext.Device.CreateTexture(texDesc) case .Ok(let tex))
			mOutputTexture = tex;
		else
			return .Err;

		TextureViewDesc viewDesc = .()
		{
			Label = "Pipeline Output View",
			Format = mOutputFormat,
			Dimension = .Texture2D
		};

		if (mRenderContext.Device.CreateTextureView(mOutputTexture, viewDesc) case .Ok(let view))
			mOutputTextureView = view;
		else
			return .Err;

		return .Ok;
	}

	private void DestroyOutputTexture()
	{
		let device = mRenderContext?.Device;
		if (device == null) return;

		if (mOutputTextureView != null)
			device.DestroyTextureView(ref mOutputTextureView);
		if (mOutputTexture != null)
			device.DestroyTexture(ref mOutputTexture);
		mOutputWidth = 0;
		mOutputHeight = 0;
	}

	/// Writes the view's scene uniforms into the per-frame ring buffer and returns
	/// the byte offset of the slot. The Frame bind group is bound with this offset
	/// as a dynamic offset for binding 0.
	private uint32 WriteSceneUniforms(PerFrameResources frame, RenderView view)
	{
		if (frame.SceneUniformBuffer == null)
			return 0;

		// Wrap if we exceed the ring (caller should configure MaxScenes large enough).
		if (frame.SceneBufferOffset >= PerFrameResources.MaxScenes * PerFrameResources.SceneAlignment)
			frame.SceneBufferOffset = 0;

		let offset = frame.SceneBufferOffset;

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
			frame.SceneUniformBuffer, (uint64)offset,
			Span<uint8>((uint8*)&uniforms, SceneUniforms.Size)
		);

		frame.SceneBufferOffset += PerFrameResources.SceneAlignment;
		return offset;
	}

	/// Helper for passes — binds the Frame bind group with the dynamic offset for
	/// the view currently being rendered. Use this instead of calling SetBindGroup
	/// directly so passes don't need to know about the scene UBO ring buffer layout.
	public void BindFrameGroup(IRenderPassEncoder encoder, PerFrameResources frame)
	{
		if (frame.FrameBindGroup == null)
			return;
		uint32[1] sceneOffsets = .(frame.CurrentSceneOffset);
		encoder.SetBindGroup(BindGroupFrequency.Frame, frame.FrameBindGroup, sceneOffsets);
	}

	private Result<void> CreatePerFrameResources()
	{
		let device = mRenderContext.Device;

		for (int i = 0; i < MaxFramesInFlight; i++)
		{
			let frame = new PerFrameResources();

			// Scene uniform ring buffer (set 0, binding 0, dynamic offset)
			let sceneBufferSize = (uint64)(PerFrameResources.SceneAlignment * PerFrameResources.MaxScenes);
			BufferDesc sceneUBDesc = .()
			{
				Label = "Scene Uniforms",
				Size = sceneBufferSize,
				Usage = .Uniform,
				Memory = .CpuToGpu
			};

			if (device.CreateBuffer(sceneUBDesc) case .Ok(let sceneBuf))
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

			if (device.CreateBuffer(objectUBDesc) case .Ok(let objBuf))
				frame.ObjectUniformBuffer = objBuf;
			else
			{
				frame.Release(device);
				delete frame;
				return .Err;
			}

			// Draw call bind group with dynamic offset into the object buffer
			let drawCallLayout = mRenderContext.DrawCallBindGroupLayout;
			if (drawCallLayout != null)
			{
				BindGroupEntry[1] drawBgEntries = .(
					BindGroupEntry.Buffer(frame.ObjectUniformBuffer, 0, PerFrameResources.ObjectAlignment)
				);

				BindGroupDesc drawBgDesc = .()
				{
					Label = "DrawCall BindGroup (Dynamic)",
					Layout = drawCallLayout,
					Entries = drawBgEntries
				};

				if (device.CreateBindGroup(drawBgDesc) case .Ok(let drawBg))
					frame.DrawCallBindGroup = drawBg;
			}

			// Frame bind group is rebuilt each frame (includes light buffer which changes)
			mFrameResources[i] = frame;
		}

		return .Ok;
	}

	/// Rebuilds the frame bind group with current light data for this frame.
	private void RebuildFrameBindGroup(PerFrameResources frame, int32 frameIndex)
	{
		let frameLayout = mRenderContext.FrameBindGroupLayout;
		if (frameLayout == null || frame.SceneUniformBuffer == null)
			return;

		let device = mRenderContext.Device;

		// Destroy previous bind group
		if (frame.FrameBindGroup != null)
			device.DestroyBindGroup(ref frame.FrameBindGroup);

		let lightBuffer = mRenderContext.LightBuffer;
		let lightBuf = lightBuffer.GetLightBuffer(frameIndex);
		let lightParamsBuf = lightBuffer.GetLightParamsBuffer(frameIndex);

		if (lightBuf == null || lightParamsBuf == null)
			return;

		// Light buffer size: at least 1 light worth (Vulkan requires non-zero)
		let lightBufferSize = (uint64)(Math.Max(lightBuffer.LightCount, 1) * GPULight.Size);

		// Scene UBO is bound at offset 0 with size = one slot — the dynamic offset
		// at SetBindGroup time selects which slot in the ring buffer to read.
		BindGroupEntry[3] bgEntries = .(
			BindGroupEntry.Buffer(frame.SceneUniformBuffer, 0, SceneUniforms.Size),
			BindGroupEntry.Buffer(lightParamsBuf, 0, (uint64)LightParams.Size),
			BindGroupEntry.Buffer(lightBuf, 0, lightBufferSize)
		);

		BindGroupDesc bgDesc = .()
		{
			Label = "Frame BindGroup",
			Layout = frameLayout,
			Entries = bgEntries
		};

		if (device.CreateBindGroup(bgDesc) case .Ok(let bg))
			frame.FrameBindGroup = bg;
	}
}
