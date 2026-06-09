namespace Sedulous.Renderer;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Core.Mathematics;
using Sedulous.Materials;
using Sedulous.Profiler;
using Sedulous.Renderer.Debug;

/// Per-view pass execution engine.
///
/// Owns the pass list, per-frame resources, output texture, and render graph.
/// References shared infrastructure (GPU resources, materials, shaders) from Renderer.
///
/// The pipeline renders to its own output texture - it doesn't know about swapchains.
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

	// Pipeline output dimensions (texture owned by application)
	private uint32 mOutputWidth;
	private uint32 mOutputHeight;
	private TextureFormat mOutputFormat = .RGBA16Float;

	/// Number of frames of depth history kept (current + N-1 previous).
	/// Independent of MaxFramesInFlight: that controls CPU/GPU pipelining
	/// (fence-driven), this controls how many frames back can be sampled by
	/// temporal effects. 2 = "current + one previous", which is what TAA
	/// disocclusion, temporal SSAO, and motion-vector validation all want.
	/// Bump only if a real consumer needs deeper history - each extra slot
	/// is a full-resolution depth target (~8 MB at 1080p D24S8).
	private const int SceneDepthHistoryCount = 2;

	// Pipeline-owned persistent depth ping-pong. SceneDepthHistoryCount slots
	// so previous-frame depth can be sampled by history-aware effects (TAA
	// disocclusion, temporal SSAO, motion-vector validation). Each frame:
	//   * slot[Curr] is imported as "SceneDepth"     (this frame's write target)
	//   * slot[Prev] is imported as "PrevSceneDepth" (last frame's write target)
	// then the indices advance at end of Render. Resource allocation, resize,
	// clear, and disposal are pipeline concerns - DepthPrepass and downstream
	// consumers (ParticlePass, DecalPass, ForwardTransparentPass, SkyPass,
	// DebugGeometryPass) only see the imported names.
	private ITexture[SceneDepthHistoryCount] mSceneDepthTextures;
	private ITextureView[SceneDepthHistoryCount] mSceneDepthViews;
	/// Depth-only sub-views used for shader sampling (soft particles, decals,
	/// TAA disocclusion). Distinct from the main views because the depth-
	/// stencil format carries both aspects but sampled views must be
	/// single-aspect under Vulkan.
	private ITextureView[SceneDepthHistoryCount] mSceneDepthOnlyViews;
	/// Index of the slot the current frame writes to. The other slot(s) hold
	/// previous frames' depth and are exposed as "PrevSceneDepth".
	private int32 mSceneDepthCurrIndex = 0;
	/// True once every slot has been cleared at least once. While false,
	/// Pipeline.Render adds extra clear passes for the non-current slots so
	/// PrevSceneDepth reads as far-plane (1.0) instead of uninitialized
	/// memory until normal ping-pong writes have populated each slot.
	private bool mSceneDepthAllSlotsCleared = false;
	/// Tracked resource state per depth slot so ImportTarget gets the actual
	/// current state instead of the stale creation-time InitialState.
	private ResourceState[SceneDepthHistoryCount] mSceneDepthStates;
	private const TextureFormat SceneDepthFormat = .Depth24PlusStencil8;
	/// Expose SceneDepthFormat so render passes can reference it for pipeline
	/// state creation instead of hardcoding Depth24PlusStencil8.
	public static TextureFormat DepthFormat => SceneDepthFormat;

	// Post-processing
	private PostProcessStack mPostProcessStack;

	// Frame counter
	private uint64 mFrameNumber = 0;

	// Per-pipeline debug draw (scene-specific gizmos, editor overlays).
	// Separate from RenderContext.DebugDraw which is global.
	private DebugDraw mDebugDraw = new .() ~ delete _;

	// Per-pipeline overlay registry. Non-owning - callers manage
	// implementation lifetime via Register/UnregisterOverlay. Insertion-
	// sorted by Order so iteration is a forward walk.
	private List<IPipelineOverlay> mOverlays = new .() ~ delete _;

	// Per-pipeline light buffer. Each scene has different lights; the forward
	// pass reads this pipeline's buffer, not a shared one.
	private LightBuffer mLightBuffer ~ delete _;

	// Per-pipeline line vertex buffers for debug drawing. Each pipeline uploads
	// its own merged debug vertices so scenes don't overwrite each other.
	private IBuffer[MaxFramesInFlight] mLineVertexBuffers;

	// Previous frame's view-projection matrix for motion vectors.
	// Per-pipeline so each scene tracks its own camera history independently.
	private Matrix mPrevViewProjectionMatrix = .Identity;

	// TAA jitter state
	private int32 mJitterIndex = 0;
	private Vector2 mPrevJitterOffset = .Zero;
	private bool mTAAEnabled = false;
	private float mJitterScale = 1.0f;

	// ==================== Properties ====================

	/// The shared renderer infrastructure.
	public RenderContext RenderContext => mRenderContext;

	/// Per-pipeline debug draw for scene-specific overlays (gizmos, editor shapes).
	/// Use this instead of RenderContext.DebugDraw for draws that should only
	/// appear in this pipeline's viewport.
	public DebugDraw DebugDraw => mDebugDraw;

	/// Iterates the per-pipeline overlay registry in Order-sorted sequence.
	public Span<IPipelineOverlay> Overlays => mOverlays;

	/// Registers an overlay with this pipeline. Insertion-sorted by Order;
	/// ties preserve registration order. Non-owning - the caller must
	/// `UnregisterOverlay` before deleting the implementation.
	public void RegisterOverlay(IPipelineOverlay overlay)
	{
		if (overlay == null) return;

		int idx = 0;
		while (idx < mOverlays.Count && mOverlays[idx].Order <= overlay.Order)
			idx++;
		mOverlays.Insert(idx, overlay);
	}

	/// Removes an overlay from this pipeline's registry. No-op if not
	/// registered.
	public void UnregisterOverlay(IPipelineOverlay overlay)
	{
		if (overlay == null) return;
		mOverlays.Remove(overlay);
	}

	/// Per-pipeline light buffer. Each scene uploads its own lights here.
	public LightBuffer LightBuffer => mLightBuffer;

	/// Gets the per-pipeline line vertex buffer for the given frame.
	public IBuffer GetLineVertexBuffer(int32 frameIndex) => mLineVertexBuffers[frameIndex % MaxFramesInFlight];

	/// Previous frame's view-projection matrix for this pipeline's camera.
	/// Used by motion vector passes to compute per-pixel screen-space deltas.
	public Matrix PrevViewProjectionMatrix
	{
		get => mPrevViewProjectionMatrix;
		set => mPrevViewProjectionMatrix = value;
	}

	/// Enable/disable TAA jitter on the projection matrix.
	/// When enabled, a sub-pixel Halton(2,3) offset is applied each frame.
	public bool TAAEnabled
	{
		get => mTAAEnabled;
		set => mTAAEnabled = value;
	}

	/// Scale factor for TAA jitter offsets. 1.0 = full Halton offset,
	/// 0.5 = half (less jitter, less sub-pixel detail), 0.0 = no jitter.
	public float JitterScale
	{
		get => mJitterScale;
		set => mJitterScale = value;
	}

	/// The render graph.
	public RenderGraph RenderGraph => mRenderGraph;

	/// Current frame number (monotonic, for deferred deletion timing).
	public uint64 FrameNumber => mFrameNumber;

	/// Gets per-frame resources for a frame index.
	public PerFrameResources GetFrameResources(int32 frameIndex)
	{
		return mFrameResources[frameIndex % MaxFramesInFlight];
	}

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
		mOutputWidth = width;
		mOutputHeight = height;

		// Render graph
		mRenderGraph = new RenderGraph(renderContext.Device, .() { FrameBufferCount = MaxFramesInFlight });

		// Per-pipeline light buffer
		mLightBuffer = new LightBuffer();
		if (mLightBuffer.Initialize(renderContext.Device) case .Err)
			return .Err;

		// Per-pipeline line vertex buffers for debug drawing
		let device = renderContext.Device;
		for (int i = 0; i < MaxFramesInFlight; i++)
		{
			BufferDesc lineDesc = .()
			{
				Label = "Pipeline DebugLine Vertices",
				Size = (uint64)(Debug.DebugDrawSystem.MaxLineVertices * Sedulous.DebugFont.DebugVertex.SizeInBytes),
				Usage = .Vertex,
				Memory = .CpuToGpu
			};
			if (device.CreateBuffer(lineDesc) case .Ok(let buf))
				mLineVertexBuffers[i] = buf;
			else
				return .Err;
		}

		// Create per-frame resources (buffers + bind groups)
		if (CreatePerFrameResources() case .Err)
			return .Err;

		// Allocate the pipeline-owned SceneDepth ping-pong.
		RecreateSceneDepth(width, height);
		for (int i = 0; i < SceneDepthHistoryCount; i++)
			if (mSceneDepthViews[i] == null)
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
	/// Must be called once per frame before the first Render() call.
	/// frameIndex is provided by the application (owns frame pacing).
	public void BeginFrame(int32 frameIndex)
	{
		let frame = mFrameResources[frameIndex % MaxFramesInFlight];
		if (frame == null) return;

		// Flush deferred bind group destructions from previous frame
		if (frame.StaleFrameBindGroups.Count > 0)
		{
			let device = mRenderContext.Device;
			for (var bg in frame.StaleFrameBindGroups)
				device.DestroyBindGroup(ref bg);
			frame.StaleFrameBindGroups.Clear();
		}

		frame.SceneBufferOffset = 0;
		frame.ObjectBufferOffset = 0;
		frame.InstanceOffset = 0;
		frame.InstanceOffsetsCount = 0;
		frame.CurrentSceneOffset = 0;
	}

	/// Dispatches a render batch for a category to every renderer registered with
	/// the RenderContext for that category. Called by render passes after they've
	/// set up render targets, pipeline state, viewport, and frame-level bind groups.
	public void RenderCategory(IRenderPassEncoder encoder, RenderDataCategory category,
		PerFrameResources frame, RenderView view, RenderBatchFlags flags, PipelineConfig passConfig)
	{
		let batch = view.RenderData?.GetBatch(category);
		if (batch == null || batch.Count == 0)
			return;

		let renderers = mRenderContext.GetRenderersFor(category);
		if (renderers == null)
			return;

		for (let renderer in renderers)
			renderer.RenderBatch(encoder, batch, mRenderContext, this, frame, view, flags, passConfig);
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

		// Release per-pipeline line vertex buffers
		if (device != null)
		{
			for (int i = 0; i < MaxFramesInFlight; i++)
			{
				if (mLineVertexBuffers[i] != null)
					device.DestroyBuffer(ref mLineVertexBuffers[i]);
			}

			// Release SceneDepth ping-pong (WaitIdle above already flushed in-flight refs).
			for (int i = 0; i < SceneDepthHistoryCount; i++)
			{
				if (mSceneDepthOnlyViews[i] != null) device.DestroyTextureView(ref mSceneDepthOnlyViews[i]);
				if (mSceneDepthViews[i] != null) device.DestroyTextureView(ref mSceneDepthViews[i]);
				if (mSceneDepthTextures[i] != null) device.DestroyTexture(ref mSceneDepthTextures[i]);
			}
		}

		mRenderContext = null;
	}

	// ==================== Rendering ====================

	/// Renders a view to the provided output texture.
	///
	/// Contract:
	///   - The caller owns the output texture and must clear it before calling.
	///   - The output texture must be in RenderTarget state on entry.
	///   - On return, the output texture is still in RenderTarget state.
	///     The caller is responsible for transitioning to ShaderRead (for blit sampling)
	///     or any other required state after this call.
	///   - frameIndex is provided by the caller (application owns frame pacing).
	public void Render(ICommandEncoder encoder, RenderView view, ITexture outputTexture, ITextureView outputTextureView, int32 frameIndex)
	{
		using (Profiler.Begin("Pipeline.Render"))
		{
		let frameSlot = frameIndex % MaxFramesInFlight;
		let frame = mFrameResources[frameSlot];

		// Apply TAA jitter to the projection matrix before uploading uniforms.
		if (mTAAEnabled)
		{
			var jitter = HaltonJitter(mJitterIndex, view.Width, view.Height);
			jitter.X *= mJitterScale;
			jitter.Y *= mJitterScale;
			view.PrevJitterOffset = mPrevJitterOffset;
			view.JitterOffset = jitter;
			view.ProjectionMatrix.M31 += jitter.X;
			view.ProjectionMatrix.M32 += jitter.Y;
			view.ViewProjectionMatrix = view.ViewMatrix * view.ProjectionMatrix;
			mPrevJitterOffset = jitter;
			mJitterIndex = (mJitterIndex + 1) % 8;
		}
		else
		{
			view.JitterOffset = .Zero;
			view.PrevJitterOffset = .Zero;
		}

		// Update per-view uniforms (appends into the per-frame ring buffers).
		using (Profiler.Begin("UploadUniforms"))
		{
			// Append this view's scene uniforms into the ring buffer and remember the
			// offset so passes can bind the frame group with the right dynamic offset.
			frame.CurrentSceneOffset = WriteSceneUniforms(frame, view);

			// Upload light data to this pipeline's own light buffer
			if (mRenderContext.IBLSystem != null)
				mLightBuffer.IBLMaxLod = mRenderContext.IBLSystem.PrefilterMaxLod;
			if (view.RenderData != null)
				mLightBuffer.Upload(view.RenderData, frameIndex);

			// Process pending IBL generation (equirect->cubemap->irradiance)
			if (mRenderContext.IBLSystem != null)
				mRenderContext.IBLSystem.ProcessPending(encoder, frameIndex);

			// Rebuild frame bind group (includes this pipeline's light buffer + IBL views)
			RebuildFrameBindGroup(frame, frameIndex);
		}

		// Process deferred GPU resource deletions
		mRenderContext.ProcessDeletions(mFrameNumber);

		// Set output size for render graph (affects relative-sized transients)
		mRenderGraph.SetOutputSize(mOutputWidth, mOutputHeight);

		// Begin render graph frame
		mRenderGraph.BeginFrame(frameSlot);

		// Import the pipeline-owned SceneDepth and clear it once. Every depth
		// consumer (DepthPrepass, ParticlePass, DecalPass, ForwardTransparentPass,
		// SkyPass, DebugGeometryPass, post-process effects) reads SceneDepth, so the
		// resource exists regardless of whether DepthPrepass has any opaque
		// geometry to draw. DepthPrepass becomes a pure early-Z optimizer that
		// uses LoadOp.Load on this same target when there is opaque to draw.
		bool allDepthSlotsReady = true;
		for (int i = 0; i < SceneDepthHistoryCount; i++)
			if (mSceneDepthViews[i] == null) { allDepthSlotsReady = false; break; }

		if (allDepthSlotsReady)
		{
			let currIdx = mSceneDepthCurrIndex;
			// "Previous" is one step backward in the ring (matches the swap
			// formula at end of Render). Works for any SceneDepthHistoryCount >= 2.
			let prevIdx = (currIdx + SceneDepthHistoryCount - 1) % SceneDepthHistoryCount;

			// Current slot: this frame's depth writes. Pass both views so
			// RenderGraph.GetDepthOnlyTextureView returns a valid sampled view
			// for ParticlePass / DecalPass / SSAO / TAA.
			// Pass the tracked state so the barrier solver knows the actual DX12
			// resource state instead of the stale creation-time InitialState.
			let depthHandle = mRenderGraph.ImportTarget("SceneDepth",
				mSceneDepthTextures[currIdx], mSceneDepthViews[currIdx], mSceneDepthOnlyViews[currIdx],
				currentState: mSceneDepthStates[currIdx]);

			// Previous slot: last frame's depth, exposed by name for effects
			// that want disocclusion testing / temporal stability. If nothing
			// reads it, the import is harmless - no pass writes to it so
			// nothing depends on it.
			mRenderGraph.ImportTarget("PrevSceneDepth",
				mSceneDepthTextures[prevIdx], mSceneDepthViews[prevIdx], mSceneDepthOnlyViews[prevIdx],
				currentState: mSceneDepthStates[prevIdx]);

			mRenderGraph.AddRenderPass("SceneDepthClear", scope (builder) => {
				builder
					.SetDepthTarget(depthHandle, .Clear, .Store, 1.0f)
					.NeverCull()
					// Empty execute is intentional: ExecuteRenderPass skips any pass
					// with a null callback (including the LoadOp.Clear on its
					// attachments). The empty body still drives the
					// BeginRenderPass/End cycle that performs the clear.
					.SetExecute(new (encoder) => {});
			});

			// First frame after Initialize/OnResize: also clear every non-current
			// slot so PrevSceneDepth (and any deeper-history slots if
			// SceneDepthHistoryCount > 2) read as far-plane (1.0) instead of
			// uninitialized memory until normal ping-pong writes populate them.
			if (!mSceneDepthAllSlotsCleared)
			{
				for (int s = 0; s < SceneDepthHistoryCount; s++)
				{
					if (s == currIdx) continue;
					let staleHandle = mRenderGraph.ImportTarget(scope $"SceneDepthInitClear[{s}]",
						mSceneDepthTextures[s], mSceneDepthViews[s], mSceneDepthOnlyViews[s],
						currentState: mSceneDepthStates[s]);
					mRenderGraph.AddRenderPass(scope $"SceneDepthInitClear[{s}]", scope (builder) => {
						builder
							.SetDepthTarget(staleHandle, .Clear, .Store, 1.0f)
							.NeverCull()
							.SetExecute(new (encoder) => {});
					});
				}
				mSceneDepthAllSlotsCleared = true;
			}
		}

		let hasPostProcess = mPostProcessStack != null && mPostProcessStack.HasActiveEffects;

		if (hasPostProcess)
		{
			// With post-processing:
			//   "PipelineOutput" = transient HDR texture (scene passes write here)
			//   "FinalOutput"    = imported caller-owned output (post-process stack writes here)
			//
			// The transient HDR texture is internal to the render graph - the caller never
			// sees it. It does NOT need an explicit clear pass because ForwardOpaquePass
			// (the first writer) already uses LoadOp.Clear on color target 0. If a future
			// pass becomes the first writer, it must also use LoadOp.Clear, or an explicit
			// clear pass should be added here:
			//
			//   mRenderGraph.AddRenderPass("ClearSceneHDR", scope (builder) => {
			//       builder
			//           .SetColorTarget(0, sceneHdrHandle, .Clear, .Store, ClearColor(0, 0, 0, 1))
			//           .NeverCull()
			//           .SetExecute(new (encoder) => {});
			//   });
			let finalHandle = mRenderGraph.ImportTarget("FinalOutput", outputTexture, outputTextureView);
			let hdrDesc = RGTextureDesc(mOutputFormat) { Usage = .RenderTarget | .Sampled };
			let sceneHdrHandle = mRenderGraph.CreateTransient("PipelineOutput", hdrDesc);

			for (let pass in mPasses)
				pass.AddPasses(mRenderGraph, view, this);

			let depthHandle = mRenderGraph.GetResource("SceneDepth");
			mPostProcessStack.Execute(mRenderGraph, view, sceneHdrHandle, depthHandle, finalHandle);
		}
		else
		{
			// Without post-processing: scene passes write directly to the caller-owned output.
			// The caller clears the output before calling Render(). ForwardOpaquePass also
			// uses LoadOp.Clear, so the caller's clear is technically redundant here - but
			// the contract requires it for correctness if the pass order ever changes.
			// Import so passes can find it by name via graph.GetResource("PipelineOutput").
			mRenderGraph.ImportTarget("PipelineOutput", outputTexture, outputTextureView);

			for (let pass in mPasses)
				pass.AddPasses(mRenderGraph, view, this);
		}

		// Compile and execute the graph
		using (Profiler.Begin("RenderGraph.Execute"))
			mRenderGraph.Execute(encoder);

		// Save SceneDepth states before EndFrame clears the resource list.
		// This ensures the next frame's ImportTarget gets the actual post-execution
		// state instead of the stale creation-time InitialState.
		if (allDepthSlotsReady)
		{
			let currIdx = mSceneDepthCurrIndex;
			let prevIdx = (currIdx + SceneDepthHistoryCount - 1) % SceneDepthHistoryCount;
			let currHandle = mRenderGraph.GetResource("SceneDepth");
			let prevHandle = mRenderGraph.GetResource("PrevSceneDepth");
			if (currHandle.IsValid) mSceneDepthStates[currIdx] = mRenderGraph.GetResourceState(currHandle);
			if (prevHandle.IsValid) mSceneDepthStates[prevIdx] = mRenderGraph.GetResourceState(prevHandle);
		}

		// End render graph frame
		mRenderGraph.EndFrame();

		// Advance SceneDepth ping-pong: what we just wrote becomes the previous
		// slot for the next frame, and the next slot in the ring becomes the
		// new write target. Modulo arithmetic so this works for any history
		// count >= 2 without touching this site.
		mSceneDepthCurrIndex = (int32)((mSceneDepthCurrIndex + 1) % SceneDepthHistoryCount);

		mFrameNumber++;
		} // Pipeline.Render scope
	}

	/// Notifies the pipeline of a resize. Updates internal dimensions and
	/// notifies passes. The application owns the output texture and recreates it.
	public void OnResize(uint32 width, uint32 height)
	{
		if (width == 0 || height == 0)
			return;
		if (width == mOutputWidth && height == mOutputHeight)
			return;

		mOutputWidth = width;
		mOutputHeight = height;

		RecreateSceneDepth(width, height);

		for (let pass in mPasses)
			pass.OnResize(width, height);
	}

	/// Writes object uniforms (world matrix + per-instance color) to the per-frame object buffer and returns the dynamic offset.
	/// Returns uint32.MaxValue if the buffer is full.
	public uint32 WriteObjectUniforms(int32 frameIndex, Matrix worldMatrix, Matrix prevWorldMatrix, Vector4 instanceColor)
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
			PrevWorldMatrix = prevWorldMatrix,
			InstanceColor = instanceColor
		};

		TransferHelper.WriteMappedBuffer(
			frame.ObjectUniformBuffer, (uint64)offset,
			Span<uint8>((uint8*)&objData, ObjectUniforms.Size)
		);

		frame.ObjectBufferOffset += PerFrameResources.ObjectAlignment;
		return offset;
	}

	/// Writes arbitrary per-draw uniform bytes to the per-frame object buffer and
	/// returns the dynamic offset. Used by renderers whose per-draw uniforms have
	/// a layout different from ObjectUniforms (e.g. DecalRenderer packs world +
	/// invWorld + color + angleFade). The caller is responsible for honoring the
	/// 256-byte slot alignment (data.Length must be ≤ ObjectAlignment).
	public uint32 WriteDrawCallBytes(int32 frameIndex, Span<uint8> data)
	{
		let frame = mFrameResources[frameIndex % MaxFramesInFlight];
		if (frame == null || frame.ObjectUniformBuffer == null)
			return uint32.MaxValue;

		if (frame.ObjectBufferOffset >= PerFrameResources.MaxObjects * PerFrameResources.ObjectAlignment)
			return uint32.MaxValue;
		if (data.Length > PerFrameResources.ObjectAlignment)
			return uint32.MaxValue;

		let offset = frame.ObjectBufferOffset;
		TransferHelper.WriteMappedBuffer(frame.ObjectUniformBuffer, (uint64)offset, data);
		frame.ObjectBufferOffset += PerFrameResources.ObjectAlignment;
		return offset;
	}

	public void Dispose()
	{
		Shutdown();
	}

	// ==================== Internal ====================

	/// GPU-packed object uniforms. Must match forward.vert.hlsl ObjectUniforms.
	/// Layout: 2 matrices (128 bytes) + Vector4 InstanceColor (16 bytes) = 144.
	[CRepr]
	private struct ObjectUniforms
	{
		public Matrix WorldMatrix;
		public Matrix PrevWorldMatrix;
		public Vector4 InstanceColor;
		public const uint64 Size = 144;
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
			PrevViewProjectionMatrix = view.PrevViewProjectionMatrix,
			CameraPosition = view.CameraPosition,
			NearPlane = view.NearPlane,
			FarPlane = view.FarPlane,
			Time = view.TotalTime,
			DeltaTime = view.DeltaTime,
			ScreenSize = .(view.Width, view.Height),
			InvScreenSize = .(1.0f / Math.Max(view.Width, 1), 1.0f / Math.Max(view.Height, 1)),
			JitterOffset = view.JitterOffset,
			PrevJitterOffset = view.PrevJitterOffset,
			MaterialLodBias = mTAAEnabled ? -0.5f : 0.0f
		};

		TransferHelper.WriteMappedBuffer(
			frame.SceneUniformBuffer, (uint64)offset,
			Span<uint8>((uint8*)&uniforms, SceneUniforms.Size)
		);

		frame.SceneBufferOffset += PerFrameResources.SceneAlignment;
		return offset;
	}

	/// Helper for passes - binds the Frame bind group with the dynamic offset for
	/// the view currently being rendered. Use this instead of calling SetBindGroup
	/// directly so passes don't need to know about the scene UBO ring buffer layout.
	public void BindFrameGroup(IRenderPassEncoder encoder, PerFrameResources frame)
	{
		if (frame.FrameBindGroup == null)
			return;
		uint32[1] sceneOffsets = .(frame.CurrentSceneOffset);
		encoder.SetBindGroup(BindGroupFrequency.Frame, frame.FrameBindGroup, sceneOffsets);
	}

/// Computes a Halton(2,3) jitter offset in clip space for TAA.
	/// Returns a sub-pixel offset centered around 0, scaled to clip space.
	private static Vector2 HaltonJitter(int32 index, uint32 width, uint32 height)
	{
		float HaltonSeq(int32 i, int32 @base)
		{
			float f = 1.0f;
			float r = 0.0f;
			var idx = i + 1; // 1-based
			while (idx > 0)
			{
				f /= (float)@base;
				r += f * (float)(idx % @base);
				idx /= @base;
			}
			return r;
		}

		// Halton(2,3) in [0,1], center to [-0.5, 0.5], then to clip space
		float x = HaltonSeq(index, 2) - 0.5f;
		float y = HaltonSeq(index, 3) - 0.5f;
		return .(x * 2.0f / Math.Max(width, 1), y * 2.0f / Math.Max(height, 1));
	}

	/// (Re)creates both slots of the pipeline-owned SceneDepth ping-pong at
	/// the given size. Called from Initialize, OnResize, and never from the
	/// per-frame path. Mirrors TAAEffect.RecreateHistoryTextures: WaitIdle
	/// before destroy so any in-flight frame that referenced the old depth
	/// targets finishes. Resets the ping-pong index so the next frame writes
	/// to slot 0 and the "both cleared" flag so PrevSceneDepth's first read
	/// is well-defined far-plane.
	private void RecreateSceneDepth(uint32 width, uint32 height)
	{
		let device = mRenderContext?.Device;
		if (device == null || width == 0 || height == 0) return;

		// Wait for any in-flight reference to the existing targets before destroying.
		bool hasAny = false;
		for (int i = 0; i < SceneDepthHistoryCount; i++)
			if (mSceneDepthTextures[i] != null) { hasAny = true; break; }
		if (hasAny)
			device.WaitIdle();

		for (int i = 0; i < SceneDepthHistoryCount; i++)
		{
			if (mSceneDepthOnlyViews[i] != null) device.DestroyTextureView(ref mSceneDepthOnlyViews[i]);
			if (mSceneDepthViews[i] != null) device.DestroyTextureView(ref mSceneDepthViews[i]);
			if (mSceneDepthTextures[i] != null) device.DestroyTexture(ref mSceneDepthTextures[i]);

			let label = scope $"SceneDepth[{i}]";
			TextureDesc desc = .()
			{
				Label = label,
				Width = width, Height = height, Depth = 1,
				Format = SceneDepthFormat,
				Usage = .DepthStencil | .Sampled,
				Dimension = .Texture2D,
				MipLevelCount = 1, ArrayLayerCount = 1, SampleCount = 1
			};
			if (device.CreateTexture(desc) case .Ok(let tex))
				mSceneDepthTextures[i] = tex;

			if (mSceneDepthTextures[i] != null
				&& device.CreateTextureView(mSceneDepthTextures[i], .() { Format = SceneDepthFormat }) case .Ok(let view))
				mSceneDepthViews[i] = view;

			// Depth-only companion view for shader sampling. Vulkan requires
			// sampled depth views to be single-aspect; the main view carries
			// Depth+Stencil and can't be bound to a fragment shader sampler.
			if (mSceneDepthTextures[i] != null
				&& device.CreateTextureView(mSceneDepthTextures[i], .() { Format = SceneDepthFormat, Aspect = .DepthOnly, Label = "SceneDepthOnlyView" }) case .Ok(let depthOnly))
				mSceneDepthOnlyViews[i] = depthOnly;
		}

		mSceneDepthCurrIndex = 0;
		mSceneDepthAllSlotsCleared = false;
		for (int i = 0; i < SceneDepthHistoryCount; i++)
			mSceneDepthStates[i] = mSceneDepthTextures[i] != null ? mSceneDepthTextures[i].InitialState : .Undefined;
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

			// Instance buffer for batched instanced draws (StructuredBuffer<InstanceData>)
			let instanceBufferSize = (uint64)(PerFrameResources.MaxInstances * PerFrameResources.InstanceStride);
			BufferDesc instanceBufDesc = .()
			{
				Label = "Instance Buffer",
				Size = instanceBufferSize,
				Usage = .StorageRead,
				Memory = .CpuToGpu
			};

			if (device.CreateBuffer(instanceBufDesc) case .Ok(let instanceBuf))
				frame.InstanceBuffer = instanceBuf;

			// Per-instance DataOffsets vertex buffer (uint4 per instance).
			let offsetsBufferSize = (uint64)(PerFrameResources.MaxInstances * PerFrameResources.DataOffsetsStride);
			BufferDesc offsetsBufDesc = .()
			{
				Label = "Instance Offsets Buffer",
				Size = offsetsBufferSize,
				Usage = .Vertex,
				Memory = .CpuToGpu
			};

			if (device.CreateBuffer(offsetsBufDesc) case .Ok(let offsetsBuf))
				frame.InstanceOffsetsBuffer = offsetsBuf;

			// Instance bind group (set 3: t0=InstanceBuffer)
			let instanceLayout = mRenderContext.InstanceBindGroupLayout;
			if (instanceLayout != null && frame.InstanceBuffer != null)
			{
				BindGroupEntry[1] instanceBgEntries = .(
					BindGroupEntry.Buffer(frame.InstanceBuffer, 0, instanceBufferSize)
				);

				BindGroupDesc instanceBgDesc = .()
				{
					Label = "Instance BindGroup",
					Layout = instanceLayout,
					Entries = instanceBgEntries
				};

				if (device.CreateBindGroup(instanceBgDesc) case .Ok(let instanceBg))
					frame.InstanceBindGroup = instanceBg;
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

		// Defer destruction of the previous bind group — it may still be referenced
		// by commands recorded into the current command buffer.
		if (frame.FrameBindGroup != null)
		{
			frame.StaleFrameBindGroups.Add(frame.FrameBindGroup);
			frame.FrameBindGroup = null;
		}

		let lightBuf = mLightBuffer.GetLightBuffer(frameIndex);
		let lightParamsBuf = mLightBuffer.GetLightParamsBuffer(frameIndex);

		if (lightBuf == null || lightParamsBuf == null)
			return;

		// Light buffer size: at least 1 light worth (Vulkan requires non-zero)
		let lightBufferSize = (uint64)(Math.Max(mLightBuffer.LightCount, 1) * GPULight.Size);

		// IBL system resources (fallback black cubemaps if no environment is set)
		let iblSystem = mRenderContext.IBLSystem;
		if (iblSystem == null || iblSystem.BRDFLutView == null ||
			iblSystem.IrradianceMapView == null || iblSystem.PrefilterMapView == null ||
			iblSystem.EnvironmentSampler == null)
		{
			System.Diagnostics.Debug.WriteLine("RebuildFrameBindGroup: IBL system not ready, skipping frame bind group");
			return;
		}

		// Scene UBO is bound at offset 0 with size = one slot - the dynamic offset
		// at SetBindGroup time selects which slot in the ring buffer to read.
		BindGroupEntry[7] bgEntries = .(
			BindGroupEntry.Buffer(frame.SceneUniformBuffer, 0, SceneUniforms.Size),
			BindGroupEntry.Buffer(lightParamsBuf, 0, (uint64)LightParams.Size),
			BindGroupEntry.Buffer(lightBuf, 0, lightBufferSize),
			BindGroupEntry.Texture(iblSystem.IrradianceMapView),
			BindGroupEntry.Texture(iblSystem.PrefilterMapView),
			BindGroupEntry.Texture(iblSystem.BRDFLutView),
			BindGroupEntry.Sampler(iblSystem.EnvironmentSampler)
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
