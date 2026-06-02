namespace Sedulous.Renderer.Probes;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Core.Mathematics;
using Sedulous.Profiler;
using Sedulous.Renderer;
using Sedulous.Renderer.IBL;
using Sedulous.Renderer.Passes;
using Sedulous.Renderer.Renderers;
using Sedulous.Materials;

/// Standalone pipeline for rendering reflection probe cubemap faces.
/// Modeled after ShadowPipeline — owns its own RenderGraph and PerFrameResources,
/// receives the main Pipeline's LightBuffer as a parameter.
///
/// Renders forward + sky into an intermediate face texture, then blits each face
/// into the probe cubemap with a horizontal flip to correct CreateLookAt mirroring.
///
/// Binds IBLSystem.SkyIrradianceView/SkyPrefilterView (NOT the active views) to
/// prevent feedback loops where the probe renders with its own IBL output.
public class ProbePipeline : IRenderingPipeline, IDisposable
{
	public const int32 MaxFramesInFlight = 2;

	private RenderContext mRenderContext;
	private RenderGraph mRenderGraph ~ delete _;
	private PerFrameResources[MaxFramesInFlight] mFrameResources;

	// Intermediate face render targets (reused across faces, lazily sized)
	private ITexture mFaceColor;
	private ITextureView mFaceColorView;
	private ITexture mFaceDepth;
	private ITextureView mFaceDepthView;
	private uint32 mFaceSize;

	// Blit pipeline for face orientation correction (horizontal flip)
	private IRenderPipeline mBlitPipeline;
	private IPipelineLayout mBlitLayout;
	private IBindGroupLayout mBlitBGLayout;

	// Stale blit bind groups (double-buffered deferred destruction)
	private List<IBindGroup>[2] mStaleBlitBindGroups = .(new .(), new .()) ~ { delete _[0]; delete _[1]; };


	public RenderContext RenderContext => mRenderContext;
	public RenderGraph RenderGraph => mRenderGraph;
	public TextureFormat OutputFormat => .RGBA16Float;

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
		if (CreateBlitPipeline() case .Err)
			return .Err;

		return .Ok;
	}

	public void Shutdown()
	{
		let device = mRenderContext?.Device;
		if (device != null)
			device.WaitIdle();

		// Flush stale blit bind groups (both slots)
		for (int s = 0; s < 2; s++)
		{
			for (var bg in mStaleBlitBindGroups[s])
				device?.DestroyBindGroup(ref bg);
			mStaleBlitBindGroups[s].Clear();
		}

		// Blit pipeline
		if (mBlitPipeline != null) device.DestroyRenderPipeline(ref mBlitPipeline);
		if (mBlitLayout != null) device.DestroyPipelineLayout(ref mBlitLayout);
		if (mBlitBGLayout != null) device.DestroyBindGroupLayout(ref mBlitBGLayout);

		// Face textures
		if (mFaceColorView != null) device.DestroyTextureView(ref mFaceColorView);
		if (mFaceColor != null) device.DestroyTexture(ref mFaceColor);
		if (mFaceDepthView != null) device.DestroyTextureView(ref mFaceDepthView);
		if (mFaceDepth != null) device.DestroyTexture(ref mFaceDepth);

		// Per-frame resources
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

	public void BeginFrame(int32 frameIndex)
	{
		let frame = mFrameResources[frameIndex % MaxFramesInFlight];
		if (frame == null) return;

		// Flush stale blit bind groups (2+ frames old)
		let device = mRenderContext.Device;
		for (var bg in mStaleBlitBindGroups[0])
			device.DestroyBindGroup(ref bg);
		mStaleBlitBindGroups[0].Clear();
		let temp = mStaleBlitBindGroups[0];
		mStaleBlitBindGroups[0] = mStaleBlitBindGroups[1];
		mStaleBlitBindGroups[1] = temp;

		frame.SceneBufferOffset = 0;
		frame.ObjectBufferOffset = 0;
		frame.InstanceOffset = 0;
		frame.InstanceOffsetsCount = 0;
		frame.CurrentSceneOffset = 0;
	}

	/// Captures a probe cubemap. Renders 6 faces with forward + sky, blits each
	/// with horizontal flip into the output cubemap layers.
	public void Capture(
		ICommandEncoder encoder,
		Vector3 probePosition,
		float nearClip, float farClip,
		uint32 faceSize,
		ITextureView[6] outputFaceViews,
		int32 frameIndex,
		LightBuffer lightBuffer,
		RenderView mainView,
		SkyPass skyPass)
	{
		using (Profiler.Begin("ProbePipeline.Capture"))
		{

		EnsureFaceTextures(faceSize);
		if (mFaceColor == null || mFaceDepth == null) return;

		let frameSlot = frameIndex % MaxFramesInFlight;
		let frame = mFrameResources[frameSlot];

		// Face directions and up vectors — same as ShadowMatrices.PointLightFaceViewProj
		Vector3[6] forwards = .(.( 1, 0, 0), .(-1, 0, 0), .(0, 1, 0), .(0,-1, 0), .(0, 0, 1), .(0, 0,-1));
		Vector3[6] ups      = .(.(0, 1, 0), .( 0, 1, 0), .(0, 0,-1), .(0, 0, 1), .(0, 1, 0), .(0, 1, 0));

		let projMatrix = Matrix.CreatePerspectiveFieldOfView(Math.PI_f * 0.5f, 1.0f, nearClip, farClip);

		// Build frame bind group with sky IBL (not probe IBL — prevents feedback)
		RebuildFrameBindGroup(frame, frameIndex, lightBuffer);

		// Save main view camera state (restored after all faces)
		let savedViewMatrix = mainView.ViewMatrix;
		let savedProjMatrix = mainView.ProjectionMatrix;
		let savedVPMatrix = mainView.ViewProjectionMatrix;
		let savedPrevVPMatrix = mainView.PrevViewProjectionMatrix;
		let savedCamPos = mainView.CameraPosition;
		let savedNear = mainView.NearPlane;
		let savedFar = mainView.FarPlane;
		let savedWidth = mainView.Width;
		let savedHeight = mainView.Height;

		for (int face = 0; face < 6; face++)
		{
			let viewMatrix = Matrix.CreateLookAt(probePosition, probePosition + forwards[face], ups[face]);
			let vpMatrix = viewMatrix * projMatrix;

			// Configure main view for this face (restored after all faces)
			ConfigureFaceView(mainView, viewMatrix, projMatrix, vpMatrix, probePosition,
				nearClip, farClip, faceSize, frameIndex);
			frame.CurrentSceneOffset = WriteSceneUniforms(frame, mainView);

			// --- Render forward + sky into intermediate face texture ---
			mRenderGraph.SetOutputSize(faceSize, faceSize);
			mRenderGraph.BeginFrame(frameSlot);

			let colorHandle = mRenderGraph.ImportTarget("ProbeColor", mFaceColor, mFaceColorView);
			let depthHandle = mRenderGraph.ImportTarget("ProbeDepth", mFaceDepth, mFaceDepthView);

			// Forward opaque pass
			let capturedFrame = frame;
			let capturedSelf = this;
			let capturedFaceView = mainView;

			mRenderGraph.AddRenderPass("ProbeForward", scope [&] (builder) => {
				builder
					.SetColorTarget(0, colorHandle, .Clear, .Store, ClearColor(0, 0, 0, 1))
					.SetDepthTarget(depthHandle, .Clear, .Store, 1.0f)
					.NeverCull()
					.SetExecute(new [=] (passEncoder) => {
						capturedSelf.ExecuteForward(passEncoder, capturedFaceView, capturedFrame);
					});
			});

			// Sky pass (renders at far depth where nothing was drawn)
			if (skyPass != null)
			{
				let capturedSkyPass = skyPass;
				mRenderGraph.AddRenderPass("ProbeSky", scope [&] (builder) => {
					builder
						.SetColorTarget(0, colorHandle, .Load, .Store)
						.SetReadOnlyDepthTarget(depthHandle)
						.NeverCull()
						.SetExecute(new [=] (passEncoder) => {
							capturedSelf.ExecuteSky(passEncoder, capturedFaceView, capturedFrame, capturedSkyPass);
						});
				});
			}

			mRenderGraph.Execute(encoder);
			mRenderGraph.EndFrame();

			// --- Blit face to cubemap layer with horizontal flip ---
			encoder.TransitionTexture(mFaceColor, .RenderTarget, .ShaderRead);
			BlitFaceToLayer(encoder, mFaceColorView, outputFaceViews[face], faceSize);
			encoder.TransitionTexture(mFaceColor, .ShaderRead, .RenderTarget);
		}

		// Restore main view camera state
		mainView.ViewMatrix = savedViewMatrix;
		mainView.ProjectionMatrix = savedProjMatrix;
		mainView.ViewProjectionMatrix = savedVPMatrix;
		mainView.PrevViewProjectionMatrix = savedPrevVPMatrix;
		mainView.CameraPosition = savedCamPos;
		mainView.NearPlane = savedNear;
		mainView.FarPlane = savedFar;
		mainView.Width = savedWidth;
		mainView.Height = savedHeight;

		} // ProbePipeline.Capture scope
	}

	// ==================== IRenderingPipeline ====================

	public void BindFrameGroup(IRenderPassEncoder encoder, PerFrameResources frame)
	{
		if (frame.FrameBindGroup == null) return;
		uint32[1] sceneOffsets = .(frame.CurrentSceneOffset);
		encoder.SetBindGroup(BindGroupFrequency.Frame, frame.FrameBindGroup, sceneOffsets);
	}

	public void RenderCategory(IRenderPassEncoder encoder, RenderDataCategory category,
		PerFrameResources frame, RenderView view, RenderBatchFlags flags, PipelineConfig passConfig)
	{
		let batch = view.RenderData?.GetBatch(category);
		if (batch == null || batch.Count == 0) return;

		let renderers = mRenderContext.GetRenderersFor(category);
		if (renderers == null) return;

		for (let renderer in renderers)
			renderer.RenderBatch(encoder, batch, mRenderContext, this, frame, view, flags, passConfig);
	}

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

	public void Dispose()
	{
		Shutdown();
	}

	// ==================== Internal ====================

	/// GPU-packed object uniforms. Must match the layout in forward.vert.hlsl's
	/// ObjectUniforms cbuffer AND the main Pipeline's identical struct - if this
	/// drifts, the shader reads garbage from past the end of our write. The
	/// previous 128-byte version dropped InstanceColor, leaving the 16 bytes
	/// after PrevWorldMatrix as whatever was last in the ring buffer. The
	/// shader's `alpha = BaseColor.a * albedoSample.a * input.Color.a`
	/// computation then multiplied by garbage `.a` (often ~0), tripped the
	/// AlphaCutoff `discard`, and skinned meshes silently vanished from probe
	/// captures.
	[CRepr]
	private struct ObjectUniforms
	{
		public Matrix WorldMatrix;
		public Matrix PrevWorldMatrix;
		public Vector4 InstanceColor;
		public const uint64 Size = 144;
	}

	/// Configure the main view for one cubemap face (modifies in place).
	/// The main view's RenderData is shared across all faces — only the
	/// camera matrices and viewport change.
	private void ConfigureFaceView(RenderView view, Matrix viewMatrix, Matrix projMatrix,
		Matrix vpMatrix, Vector3 position, float nearClip, float farClip,
		uint32 size, int32 frameIndex)
	{
		view.ViewMatrix = viewMatrix;
		view.ProjectionMatrix = projMatrix;
		view.ViewProjectionMatrix = vpMatrix;
		view.PrevViewProjectionMatrix = vpMatrix;
		view.CameraPosition = position;
		view.NearPlane = nearClip;
		view.FarPlane = farClip;
		view.Width = size;
		view.Height = size;
	}

	/// Render the forward opaque pass for one probe face.
	private void ExecuteForward(IRenderPassEncoder encoder, RenderView view, PerFrameResources frame)
	{
		let cache = mRenderContext.PipelineStateCache;
		if (cache == null) return;

		encoder.SetViewport(0, 0, (float)view.Width, (float)view.Height, 0.0f, 1.0f);
		encoder.SetScissor(0, 0, view.Width, view.Height);

		// Single color target (no MRT — probes don't need normals/motion vectors)
		var config = PipelineConfig();
		config.ShaderName = "forward";
		config.BlendMode = .Opaque;
		config.CullMode = .Back;
		config.ColorTargetCount = 1;
		config.DepthMode = .ReadWrite;
		config.DepthCompare = .LessEqual;
		config.DepthFormat = Pipeline.DepthFormat;

		let vertexLayout = VertexLayoutHelper.CreateBufferLayout(.Mesh);
		VertexBufferLayout[1] vertexBuffers = .(vertexLayout);

		let pipelineResult = cache.GetPipeline(config, vertexBuffers, null, OutputFormat, Pipeline.DepthFormat);
		if (pipelineResult case .Err) return;

		encoder.SetPipeline(pipelineResult.Value);
		BindFrameGroup(encoder, frame);

		if (mRenderContext.DefaultMaterialBindGroup != null)
			encoder.SetBindGroup(BindGroupFrequency.Material, mRenderContext.DefaultMaterialBindGroup, default);

		// Bind shadow data so probe captures include shadows
		let shadowSystem = mRenderContext.ShadowSystem;
		if (shadowSystem != null)
		{
			let shadowBg = shadowSystem.GetBindGroup(view.FrameIndex);
			if (shadowBg != null)
				encoder.SetBindGroup(BindGroupFrequency.Shadow, shadowBg, default);
		}

		RenderCategory(encoder, RenderCategories.Opaque, frame, view, .BindMaterial, config);
		RenderCategory(encoder, RenderCategories.Masked, frame, view, .BindMaterial, config);
	}

	/// Render sky for one probe face using the existing SkyPass.
	private void ExecuteSky(IRenderPassEncoder encoder, RenderView view,
		PerFrameResources frame, SkyPass skyPass)
	{
		// SkyPass.ExecuteForProbe creates a temporary bind group and returns it.
		// We defer its destruction so it survives until the GPU is done.
		let probeSkyBG = skyPass.ExecuteForProbe(encoder, view, this, frame);
		if (probeSkyBG != null)
			mStaleBlitBindGroups[1].Add(probeSkyBG);
	}

	/// Blit the intermediate face texture to a cubemap face view with horizontal flip.
	private void BlitFaceToLayer(ICommandEncoder encoder, ITextureView sourceFace,
		ITextureView destLayer, uint32 size)
	{
		if (mBlitPipeline == null || mBlitBGLayout == null) return;

		// Create blit bind group (source texture + sampler)
		IBindGroup blitBG = null;
		BindGroupEntry[2] entries = .(
			BindGroupEntry.Texture(sourceFace),
			BindGroupEntry.Sampler(mRenderContext.IBLSystem.EnvironmentSampler)
		);

		if (mRenderContext.Device.CreateBindGroup(.() { Label = "Probe Blit BG", Layout = mBlitBGLayout, Entries = entries }) case .Ok(let bg))
			blitBG = bg;
		else
			return;

		// Render blit pass
		ColorAttachment[1] colorAttachments = .(.()
		{
			View = destLayer,
			LoadOp = .DontCare,
			StoreOp = .Store
		});

		RenderPassDesc rpDesc = .()
		{
			Label = "ProbeBlit",
			ColorAttachments = .(colorAttachments)
		};

		let rp = encoder.BeginRenderPass(rpDesc);
		rp.SetPipeline(mBlitPipeline);
		rp.SetBindGroup(0, blitBG, default);
		rp.SetViewport(0, 0, size, size, 0, 1);
		rp.SetScissor(0, 0, size, size);
		rp.Draw(3, 1, 0, 0);
		rp.End();

		// Defer blit bind group destruction
		mStaleBlitBindGroups[1].Add(blitBG);
	}

	// ==================== Resource Creation ====================

	private void RebuildFrameBindGroup(PerFrameResources frame, int32 frameIndex, LightBuffer lightBuffer)
	{
		let frameLayout = mRenderContext.FrameBindGroupLayout;
		if (frameLayout == null || frame.SceneUniformBuffer == null)
			return;

		let device = mRenderContext.Device;

		// Defer previous bind group
		if (frame.FrameBindGroup != null)
		{
			frame.StaleFrameBindGroups.Add(frame.FrameBindGroup);
			frame.FrameBindGroup = null;
		}

		let lightBuf = lightBuffer.GetLightBuffer(frameIndex);
		let lightParamsBuf = lightBuffer.GetLightParamsBuffer(frameIndex);

		if (lightBuf == null || lightParamsBuf == null)
			return;

		let lightBufferSize = (uint64)(Math.Max(lightBuffer.LightCount, 1) * GPULight.Size);

		// Use SKY IBL views (not active/probe views) to prevent feedback loops
		let iblSystem = mRenderContext.IBLSystem;
		if (iblSystem == null || iblSystem.BRDFLutView == null ||
			iblSystem.SkyIrradianceView == null || iblSystem.SkyPrefilterView == null ||
			iblSystem.EnvironmentSampler == null)
			return;

		BindGroupEntry[7] bgEntries = .(
			BindGroupEntry.Buffer(frame.SceneUniformBuffer, 0, SceneUniforms.Size),
			BindGroupEntry.Buffer(lightParamsBuf, 0, (uint64)LightParams.Size),
			BindGroupEntry.Buffer(lightBuf, 0, lightBufferSize),
			BindGroupEntry.Texture(iblSystem.SkyIrradianceView),   // SKY, not active
			BindGroupEntry.Texture(iblSystem.SkyPrefilterView),    // SKY, not active
			BindGroupEntry.Texture(iblSystem.BRDFLutView),
			BindGroupEntry.Sampler(iblSystem.EnvironmentSampler)
		);

		BindGroupDesc bgDesc = .()
		{
			Label = "Probe Frame BindGroup",
			Layout = frameLayout,
			Entries = bgEntries
		};

		if (device.CreateBindGroup(bgDesc) case .Ok(let bg))
			frame.FrameBindGroup = bg;
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

	private void EnsureFaceTextures(uint32 size)
	{
		if (size == mFaceSize && mFaceColor != null && mFaceDepth != null)
			return;

		let device = mRenderContext.Device;

		// Destroy old
		if (mFaceColorView != null) device.DestroyTextureView(ref mFaceColorView);
		if (mFaceColor != null) device.DestroyTexture(ref mFaceColor);
		if (mFaceDepthView != null) device.DestroyTextureView(ref mFaceDepthView);
		if (mFaceDepth != null) device.DestroyTexture(ref mFaceDepth);

		mFaceSize = size;

		// Color
		let colorDesc = TextureDesc.Tex2D(.RGBA16Float, size, size, .RenderTarget | .Sampled,
			label: "Probe Face Color");
		if (device.CreateTexture(colorDesc) case .Ok(let colorTex))
		{
			mFaceColor = colorTex;
			if (device.CreateTextureView(colorTex, .() { Format = .RGBA16Float, Dimension = .Texture2D }) case .Ok(let v))
				mFaceColorView = v;
		}

		// Depth
		let depthDesc = TextureDesc.DepthBuffer(Pipeline.DepthFormat, size, size,
			label: "Probe Face Depth");
		if (device.CreateTexture(depthDesc) case .Ok(let depthTex))
		{
			mFaceDepth = depthTex;
			if (device.CreateTextureView(depthTex, .() { Format = Pipeline.DepthFormat, Dimension = .Texture2D }) case .Ok(let v))
				mFaceDepthView = v;
		}
	}

	private Result<void> CreateBlitPipeline()
	{
		let shaderSystem = mRenderContext.ShaderSystem;
		if (shaderSystem == null) return .Err;

		let vertResult = shaderSystem.GetShader("fullscreen", .Vertex);
		if (vertResult case .Err) return .Err;
		let fragResult = shaderSystem.GetShader("probe_blit", .Fragment);
		if (fragResult case .Err) return .Err;

		let device = mRenderContext.Device;

		// Layout: t0 source texture, s0 sampler
		BindGroupLayoutEntry[2] entries = .(
			.SampledTexture(0, .Fragment, .Texture2D),
			.Sampler(0, .Fragment)
		);

		if (device.CreateBindGroupLayout(.() { Label = "ProbeBlit BGL", Entries = entries }) case .Ok(let bgl))
			mBlitBGLayout = bgl;
		else
			return .Err;

		IBindGroupLayout[1] layouts = .(mBlitBGLayout);
		if (device.CreatePipelineLayout(.(layouts)) case .Ok(let pl))
			mBlitLayout = pl;
		else
			return .Err;

		ColorTargetState[1] colorTargets = .(.(TextureFormat.RGBA16Float));

		RenderPipelineDesc pipelineDesc = .()
		{
			Label = "ProbeBlit Pipeline",
			Layout = mBlitLayout,
			Vertex = .() { Shader = .(vertResult.Value.Module, "main") },
			Fragment = .()
			{
				Shader = .(fragResult.Value.Module, "main"),
				Targets = .(&colorTargets[0], 1)
			},
			Primitive = .() { Topology = .TriangleList, CullMode = .None },
			DepthStencil = null,
			Multisample = .() { Count = 1, Mask = uint32.MaxValue }
		};

		if (device.CreateRenderPipeline(pipelineDesc) case .Ok(let pipe))
			mBlitPipeline = pipe;
		else
			return .Err;

		return .Ok;
	}

	private Result<void> CreatePerFrameResources()
	{
		let device = mRenderContext.Device;

		for (int i = 0; i < MaxFramesInFlight; i++)
		{
			let frame = new PerFrameResources();

			// Scene uniform ring buffer
			let sceneBufferSize = (uint64)(PerFrameResources.MaxScenes * PerFrameResources.SceneAlignment);
			BufferDesc sceneUBDesc = .()
			{
				Label = "Probe Scene Uniforms",
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

			// Object uniform ring buffer
			let objectBufferSize = (uint64)(256 * 4096);
			BufferDesc objectUBDesc = .()
			{
				Label = "Probe Object Uniforms",
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

			// Draw call bind group
			let drawCallLayout = mRenderContext.DrawCallBindGroupLayout;
			if (drawCallLayout != null)
			{
				BindGroupEntry[1] drawBgEntries = .(
					BindGroupEntry.Buffer(frame.ObjectUniformBuffer, 0, PerFrameResources.ObjectAlignment)
				);

				BindGroupDesc drawBgDesc = .()
				{
					Label = "Probe DrawCall BindGroup",
					Layout = drawCallLayout,
					Entries = drawBgEntries
				};

				if (device.CreateBindGroup(drawBgDesc) case .Ok(let drawBg))
					frame.DrawCallBindGroup = drawBg;
			}

			// Instance buffer
			let instanceBufferSize = (uint64)(PerFrameResources.MaxInstances * PerFrameResources.InstanceStride);
			BufferDesc instanceBufDesc = .()
			{
				Label = "Probe Instance Buffer",
				Size = instanceBufferSize,
				Usage = .StorageRead,
				Memory = .CpuToGpu
			};

			if (device.CreateBuffer(instanceBufDesc) case .Ok(let instanceBuf))
				frame.InstanceBuffer = instanceBuf;

			// Instance offsets vertex buffer
			let offsetsBufferSize = (uint64)(PerFrameResources.MaxInstances * PerFrameResources.DataOffsetsStride);
			BufferDesc offsetsBufDesc = .()
			{
				Label = "Probe Instance Offsets Buffer",
				Size = offsetsBufferSize,
				Usage = .Vertex,
				Memory = .CpuToGpu
			};

			if (device.CreateBuffer(offsetsBufDesc) case .Ok(let offsetsBuf))
				frame.InstanceOffsetsBuffer = offsetsBuf;

			// Instance bind group
			let instanceLayout = mRenderContext.InstanceBindGroupLayout;
			if (instanceLayout != null && frame.InstanceBuffer != null)
			{
				BindGroupEntry[1] instanceBgEntries = .(
					BindGroupEntry.Buffer(frame.InstanceBuffer, 0, instanceBufferSize)
				);

				BindGroupDesc instanceBgDesc = .()
				{
					Label = "Probe Instance BindGroup",
					Layout = instanceLayout,
					Entries = instanceBgEntries
				};

				if (device.CreateBindGroup(instanceBgDesc) case .Ok(let instanceBg))
					frame.InstanceBindGroup = instanceBg;
			}

			mFrameResources[i] = frame;
		}

		return .Ok;
	}
}
