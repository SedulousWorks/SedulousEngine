namespace Sedulous.Renderer.Shadows;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Core.Mathematics;
using Sedulous.Profiler;
using Sedulous.Renderer;
using Sedulous.Materials;

/// Per-view shadow rendering pipeline.
///
/// Standalone (not a Pipeline subclass) - owns its own RenderGraph and per-frame
/// resources. The atlas is owned by ShadowSystem; ShadowPipeline.RenderAll imports
/// it as a depth target and renders all shadow views' depth into the atlas in a
/// single graph cycle (one render pass per shadow caster, all sharing the atlas).
///
/// Doing all shadow renders in one Execute is required so the render graph can
/// correctly track the atlas state across passes - multi-Execute would re-import
/// the atlas as Undefined each time, causing .Load to discard prior shadow contents.
public class ShadowPipeline : IRenderingPipeline, IDisposable
{
	public const int32 MaxFramesInFlight = 2;

	private RenderContext mRenderContext;
	private RenderGraph mRenderGraph ~ delete _;

	// Per-frame resources (independent from main Pipeline so simultaneous main +
	// shadow rendering doesn't fight over the same scene/object UBO ring buffers).
	private PerFrameResources[MaxFramesInFlight] mFrameResources;

	public RenderContext RenderContext => mRenderContext;
	public RenderGraph RenderGraph => mRenderGraph;
	public TextureFormat OutputFormat => .Undefined;

	public PerFrameResources GetFrameResources(int32 frameIndex)
	{
		return mFrameResources[frameIndex % MaxFramesInFlight];
	}

	public Result<void> Initialize(RenderContext renderContext)
	{
		mRenderContext = renderContext;

		mRenderGraph = new RenderGraph(renderContext.Device, .() { FrameBufferCount = MaxFramesInFlight });

		if (CreatePerFrameResources() case .Err)
			return .Err;

		return .Ok;
	}

	public void Shutdown()
	{
		let device = mRenderContext?.Device;
		if (device != null)
			device.WaitIdle();

		for (int i = 0; i < MaxFramesInFlight; i++)
		{
			if (mFrameResources[i] != null)
			{
				mFrameResources[i].Release(device);
				delete mFrameResources[i];
				mFrameResources[i] = null;
			}
		}

		mRenderContext = null;
	}

	/// Resets per-frame ring buffer offsets. Call once per frame before RenderAll.
	public void BeginFrame(int32 frameIndex)
	{
		let frame = mFrameResources[frameIndex % MaxFramesInFlight];
		if (frame == null) return;
		frame.SceneBufferOffset = 0;
		frame.ObjectBufferOffset = 0;
		frame.InstanceOffset = 0;
		frame.CurrentSceneOffset = 0;
	}

	/// One shadow view + its assigned atlas region.
	public struct ShadowJob
	{
		public RenderView View;
		public ShadowAtlasRegion Region;
	}

	/// Renders all queued shadow views in one graph cycle.
	/// First job clears the atlas; subsequent jobs use load. The atlas is left in
	/// ShaderRead via the imported finalState so the forward pass can sample it.
	public void RenderAll(ICommandEncoder encoder, Span<ShadowJob> jobs,
		ITexture atlas, ITextureView atlasView, int32 frameIndex)
	{
		if (jobs.Length == 0) return;

		using (Profiler.Begin("ShadowPipeline.RenderAll"))
		{
		let frameSlot = frameIndex % MaxFramesInFlight;
		let frame = mFrameResources[frameSlot];

		RebuildFrameBindGroup(frame, frameIndex);

		// Pre-write all scene uniforms so each pass callback has a valid offset.
		const int MaxJobs = (int)PerFrameResources.MaxScenes;
		uint32[MaxJobs] sceneOffsets = ?;
		let count = (jobs.Length < MaxJobs) ? jobs.Length : MaxJobs;
		for (int i = 0; i < count; i++)
			sceneOffsets[i] = WriteSceneUniforms(frame, jobs[i].View);

		let atlasW = (atlas != null) ? atlas.Desc.Width : 0;
		let atlasH = (atlas != null) ? atlas.Desc.Height : 0;
		mRenderGraph.SetOutputSize(atlasW, atlasH);
		mRenderGraph.BeginFrame((int32)frameSlot);

		// Import with finalState = ShaderRead so the graph emits the final transition.
		let atlasHandle = mRenderGraph.ImportTarget("ShadowAtlas", atlas, atlasView, .ShaderRead);

		for (int i = 0; i < count; i++)
		{
			let job = jobs[i];
			let isFirst = (i == 0);
			let sceneOffset = sceneOffsets[i];
			let capturedFrame = frame;
			let capturedSelf = this;

			mRenderGraph.AddRenderPass("ShadowDepth", scope [&] (builder) => {
				builder
					.SetDepthTarget(atlasHandle, isFirst ? .Clear : .Load, .Store, 1.0f)
					.NeverCull()
					.SetExecute(new [=] (passEncoder) => {
						capturedFrame.CurrentSceneOffset = sceneOffset;
						capturedSelf.ExecuteShadowDepth(passEncoder, job.View, capturedFrame, job.Region);
					});
			});
		}

		mRenderGraph.Execute(encoder);
		mRenderGraph.EndFrame();
		} // ShadowPipeline.RenderAll scope
	}

	private void ExecuteShadowDepth(IRenderPassEncoder encoder, RenderView view,
		PerFrameResources frame, ShadowAtlasRegion region)
	{
		let cache = mRenderContext.PipelineStateCache;
		if (cache == null)
			return;

		// Restrict drawing to this view's atlas region.
		encoder.SetViewport((float)region.X, (float)region.Y,
			(float)region.Width, (float)region.Height, 0.0f, 1.0f);
		encoder.SetScissor((int32)region.X, (int32)region.Y, region.Width, region.Height);

		// Depth-only pipeline (same shader as main DepthPrepass, but Depth32Float to
		// match the atlas). Hardware depth bias eliminates shadow acne on surfaces
		// nearly perpendicular to the light without risking peter-panning.
		var config = PipelineConfig();
		config.ShaderName = "depth_only";
		config.DepthMode = .ReadWrite;
		config.DepthCompare = .Less;
		config.DepthFormat = mRenderContext.ShadowSystem.Atlas.Format;
		config.CullMode = .Back;
		config.ColorTargetCount = 0;
		config.DepthOnly = true;
		config.DepthBias = 50;           // constant offset in depth-buffer units
		config.DepthBiasSlopeScale = 1.5f; // slope-scaled offset

		let vertexLayout = VertexLayoutHelper.CreateBufferLayout(.Mesh);
		VertexBufferLayout[1] vertexBuffers = .(vertexLayout);

		let pipelineResult = cache.GetPipeline(config, vertexBuffers, null,
			.Undefined, mRenderContext.ShadowSystem.Atlas.Format);
		if (pipelineResult case .Err)
			return;

		encoder.SetPipeline(pipelineResult.Value);

		BindFrameGroup(encoder, frame);

		// Dispatch to registered renderers (MeshRenderer) for shadow casters.
		// Opaque + Masked categories cast shadows; Transparent does not.
		// .None - no material binding required for depth-only writes.
		RenderCategory(encoder, RenderCategories.Opaque, frame, view, .None, config);
		RenderCategory(encoder, RenderCategories.Masked, frame, view, .None, config);
	}

	/// Helper for the shadow depth pass - same pattern as Pipeline.BindFrameGroup.
	public void BindFrameGroup(IRenderPassEncoder encoder, PerFrameResources frame)
	{
		if (frame.FrameBindGroup == null)
			return;
		uint32[1] sceneOffsets = .(frame.CurrentSceneOffset);
		encoder.SetBindGroup(BindGroupFrequency.Frame, frame.FrameBindGroup, sceneOffsets);
	}

	/// Dispatches a category to all registered renderers - exposed so MeshRenderer
	/// is reachable through the shadow pipeline. Mirrors Pipeline.RenderCategory.
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

	/// Writes object uniforms to the per-frame ring buffer (mirrors Pipeline.WriteObjectUniforms).
	/// MeshRenderer calls this through the Pipeline reference passed to RenderBatch.
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

	[CRepr]
	private struct ObjectUniforms
	{
		public Matrix WorldMatrix;
		public Matrix PrevWorldMatrix;
		public const uint64 Size = 128;
	}

	private uint32 WriteSceneUniforms(PerFrameResources frame, RenderView view)
	{
		if (frame.SceneUniformBuffer == null)
			return 0;

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
			InvScreenSize = .(1.0f / Math.Max(view.Width, 1), 1.0f / Math.Max(view.Height, 1))
		};

		TransferHelper.WriteMappedBuffer(
			frame.SceneUniformBuffer, (uint64)offset,
			Span<uint8>((uint8*)&uniforms, SceneUniforms.Size)
		);

		frame.SceneBufferOffset += PerFrameResources.SceneAlignment;
		return offset;
	}

	private Result<void> CreatePerFrameResources()
	{
		let device = mRenderContext.Device;

		for (int i = 0; i < MaxFramesInFlight; i++)
		{
			let frame = new PerFrameResources();

			let sceneBufferSize = (uint64)(PerFrameResources.SceneAlignment * PerFrameResources.MaxScenes);
			BufferDesc sceneUBDesc = .()
			{
				Label = "Shadow Scene Uniforms",
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

			let objectBufferSize = (uint64)(256 * 4096);
			BufferDesc objectUBDesc = .()
			{
				Label = "Shadow Object Uniforms",
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

			let drawCallLayout = mRenderContext.DrawCallBindGroupLayout;
			if (drawCallLayout != null)
			{
				BindGroupEntry[1] drawBgEntries = .(
					BindGroupEntry.Buffer(frame.ObjectUniformBuffer, 0, PerFrameResources.ObjectAlignment)
				);

				BindGroupDesc drawBgDesc = .()
				{
					Label = "Shadow DrawCall BindGroup",
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
				Label = "Shadow Instance Buffer",
				Size = instanceBufferSize,
				Usage = .Storage,
				Memory = .CpuToGpu
			};

			if (device.CreateBuffer(instanceBufDesc) case .Ok(let instanceBuf))
			{
				frame.InstanceBuffer = instanceBuf;

				let instanceLayout = mRenderContext.InstanceBindGroupLayout;
				if (instanceLayout != null)
				{
					BindGroupEntry[1] instanceBgEntries = .(
						BindGroupEntry.Buffer(instanceBuf, 0, instanceBufferSize)
					);

					BindGroupDesc instanceBgDesc = .()
					{
						Label = "Shadow Instance BindGroup",
						Layout = instanceLayout,
						Entries = instanceBgEntries
					};

					if (device.CreateBindGroup(instanceBgDesc) case .Ok(let instanceBg))
						frame.InstanceBindGroup = instanceBg;
				}
			}

			mFrameResources[i] = frame;
		}

		return .Ok;
	}

	private void RebuildFrameBindGroup(PerFrameResources frame, int32 frameIndex)
	{
		let frameLayout = mRenderContext.FrameBindGroupLayout;
		if (frameLayout == null || frame.SceneUniformBuffer == null)
			return;

		let device = mRenderContext.Device;

		if (frame.FrameBindGroup != null)
			device.DestroyBindGroup(ref frame.FrameBindGroup);

		let lightBuffer = mRenderContext.LightBuffer;
		let lightBuf = lightBuffer.GetLightBuffer(frameIndex);
		let lightParamsBuf = lightBuffer.GetLightParamsBuffer(frameIndex);

		if (lightBuf == null || lightParamsBuf == null)
			return;

		let lightBufferSize = (uint64)(Math.Max(lightBuffer.LightCount, 1) * GPULight.Size);

		BindGroupEntry[3] bgEntries = .(
			BindGroupEntry.Buffer(frame.SceneUniformBuffer, 0, SceneUniforms.Size),
			BindGroupEntry.Buffer(lightParamsBuf, 0, (uint64)LightParams.Size),
			BindGroupEntry.Buffer(lightBuf, 0, lightBufferSize)
		);

		BindGroupDesc bgDesc = .()
		{
			Label = "Shadow Frame BindGroup",
			Layout = frameLayout,
			Entries = bgEntries
		};

		if (device.CreateBindGroup(bgDesc) case .Ok(let bg))
			frame.FrameBindGroup = bg;
	}
}
