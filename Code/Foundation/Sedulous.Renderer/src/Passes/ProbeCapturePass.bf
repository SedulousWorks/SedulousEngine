namespace Sedulous.Renderer.Passes;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Renderer;
using Sedulous.Renderer.IBL;
using Sedulous.Core.Mathematics;
using Sedulous.Materials;
using Sedulous.Profiler;

/// Captures one face of one reflection probe per frame, round-robin across all
/// active probes' faces. Renders the scene's Opaque + Masked categories from
/// the probe's position into the corresponding cubemap-array slice using a
/// 90 deg FOV, square projection.
///
/// The shader is the standard `forward` shader compiled with `IBL_CAPTURE`
/// defined so its fragment output drops the MRT normal + velocity targets
/// (the cubemap face is a single-RT render target). Sub-phase F will use the
/// same define to gate the IBL evaluation block so probes don't sample their
/// own previous output.
///
/// Shadows are skipped (no shadow bind-group set 4). Shadow contribution in
/// indirect lighting is low-frequency anyway and gets further blurred by the
/// GGX prefilter (Sub-phase D).
class ProbeCapturePass : PipelinePass
{
	public override StringView Name => "ProbeCapture";

	private ProbeCaptureScheduler mScheduler;

	public override void AddPasses(Sedulous.RenderGraph.RenderGraph graph, RenderView view, Pipeline pipeline)
	{
		let data = view.RenderData;
		if (data == null) return;

		let probes = data.GetBatch(RenderCategories.ReflectionProbe);
		if (probes == null || probes.Count == 0) return;

		// Compact active probes (filtering ArraySlot < 0).
		ReflectionProbeRenderData[Sedulous.Renderer.RenderContext.MaxIBLProbes] active = ?;
		int32 activeCount = 0;
		for (let entry in probes)
		{
			let probe = entry as ReflectionProbeRenderData;
			if (probe == null) continue;
			if (probe.ArraySlot < 0) continue;
			if (activeCount >= Sedulous.Renderer.RenderContext.MaxIBLProbes) break;
			active[activeCount] = probe;
			activeCount++;
		}
		if (activeCount == 0) return;

		// Pick (active-index, face) for this frame.
		int32 schedSlot;
		int32 faceIndex;
		if (!mScheduler.TryAdvance(activeCount, out schedSlot, out faceIndex)) return;
		if (schedSlot < 0 || schedSlot >= activeCount) return;

		let probe = active[schedSlot];
		let cubemapLayer = (uint32)(probe.ArraySlot * 6 + faceIndex);

		let renderContext = pipeline.RenderContext;
		let cubeTex = renderContext.PrefilteredCubemapTexture;
		let cubeView = renderContext.PrefilteredCubemapView;
		if (cubeTex == null || cubeView == null) return;

		// Build probe view + projection. Far plane = InfluenceRadius * 2 so the
		// whole influence volume is in-frustum at worst case.
		let captureView = ProbeCaptureView.BuildFaceView(probe.ProbePosition, faceIndex);
		let captureProj = ProbeCaptureView.BuildFaceProjection(probe.InfluenceRadius * 2.0f);

		// Stash a per-capture scene-uniform slot. Captured by the execute
		// callback so the dispatch binds the frame group with this offset
		// rather than the main view's.
		let frame = pipeline.GetFrameResources(view.FrameIndex);
		let captureSceneOffset = pipeline.WriteSceneUniformsForCapture(
			frame, captureView, captureProj, probe.ProbePosition,
			ProbeCaptureView.CaptureNear, probe.InfluenceRadius * 2.0f,
			(uint32)Sedulous.Renderer.RenderContext.IBLProbeFaceSize,
			(uint32)Sedulous.Renderer.RenderContext.IBLProbeFaceSize);

		// Import cubemap as a render target with final state ShaderRead so the
		// graph emits the right transition for the forward shader in Sub-phase F.
		// RequireReadableAfterWrite chains a ShaderRead transition onto the END
		// of each pass that writes a subresource of the cubemap (face capture +
		// every prefilter slice), so by the time the forward shader's frame
		// bind group accesses the all-mips PrefilteredCubemap descriptor, every
		// previously-written (mip, layer) is back in ShaderRead. Subresource-
		// aware barrier tracking is what makes this safe across the 24+ writers
		// per probe per frame.
		let cubeHandle = graph.ImportTarget("ProbeCubemap", cubeTex, cubeView, .ShaderRead);
		graph.RequireReadableAfterWrite(cubeHandle);

		// Transient depth for this capture - 128x128 D24S8, recycled each frame.
		// Explicit DepthStencil usage; the transient pool needs it for allocation.
		let depthDesc = RGTextureDesc(.Depth24PlusStencil8,
			(uint32)Sedulous.Renderer.RenderContext.IBLProbeFaceSize,
			(uint32)Sedulous.Renderer.RenderContext.IBLProbeFaceSize)
			{ Usage = .DepthStencil };
		let depthHandle = graph.CreateTransient("ProbeCaptureDepth", depthDesc);

		// Per-face render target = (mip 0, one array layer).
		let colorSubres = RGSubresourceRange(0, 1, cubemapLayer, 1);
		let mainSceneOffset = frame.CurrentSceneOffset;
		let viewCapture = view;
		let pipelineCapture = pipeline;

		graph.AddRenderPass("ProbeCaptureFace", scope (builder) => {
			builder
				.SetColorTarget(0, cubeHandle, .Clear, .Store, ClearColor(0, 0, 0, 1), colorSubres)
				.SetDepthTarget(depthHandle, .Clear, .Store, 1.0f)
				.NeverCull()
				.SetExecute(new [=] (encoder) => {
					ExecuteCaptureFace(encoder, pipelineCapture, viewCapture, frame,
						captureSceneOffset, mainSceneOffset);
				});
		});

		// Sky fill: paints sky into all far-plane pixels of the just-captured
		// face. Without this the cubemap's empty (sky-facing) regions stay
		// black and the top hemisphere of any glossy surface reflects nothing,
		// which made the metal sphere look dead in early IBL tests. Runs in
		// its own render pass that loads the captured color, reads depth as
		// read-only, and dispatches the standard SkyPass shader with the
		// probe's scene-uniform slot bound.
		let skyPass = pipeline.GetPass<SkyPass>();
		if (skyPass != null)
		{
			let skyPassRef = skyPass;
			graph.AddRenderPass("ProbeCaptureSky", scope (builder) => {
				builder
					.SetColorTarget(0, cubeHandle, .Load, .Store, ClearColor(0, 0, 0, 1), colorSubres)
					.SetReadOnlyDepthTarget(depthHandle)
					.NeverCull()
					.SetExecute(new [=] (encoder) => {
						ExecuteCaptureSky(encoder, skyPassRef, pipelineCapture, viewCapture, frame,
							captureSceneOffset, mainSceneOffset);
					});
			});
		}

		// Prefilter: build the GGX mip chain for THIS probe's 6 faces from
		// whatever's currently in mip 0. Even though only one face was freshly
		// written this frame, we re-filter all 6 faces so the mip chain stays
		// internally consistent; over a 6-frame cycle each face contributes a
		// fresh capture and the result fully converges.
		//
		// Render-pass based (one pass per face/mip slice writing through a
		// fragment shader) - sidesteps the SPIR-V storage-image format
		// declaration that compute would otherwise require.
		let prefilter = renderContext.IBLPrefilterSystem;
		if (prefilter == null) return;

		let probeSlot = (int32)probe.ArraySlot;
		prefilter.AddPrefilterPasses(graph, cubeHandle, probeSlot);

		// SH9 projection: re-project this probe's cubemap onto SH coefficients
		// for the diffuse irradiance lookup in the forward shader. Same probe
		// as the prefilter; runs after prefilter completes (depends on the
		// cubemap content, not on the prefiltered mips, so it could run in
		// parallel - but sequencing keeps the bind state simpler).
		let sh9 = renderContext.IBLSH9System;
		if (sh9 == null) return;

		graph.AddComputePass("ProbeCaptureSH9", scope (builder) => {
			builder
				.ReadTexture(cubeHandle, RGSubresourceRange(0, 1, 0, 0))
				.NeverCull()
				.HasSideEffects()  // writes to the SH9 buffer (not a graph resource)
				.SetComputeExecute(new [=] (computeEncoder) => {
					ExecuteSH9(computeEncoder, pipelineCapture, probeSlot);
				});
		});
	}

	private static void ExecuteSH9(IComputePassEncoder encoder, Pipeline pipeline, int32 probeSlot)
	{
		using (Profiler.Begin("ProbeCapture.SH9"))
		{
			let sh9 = pipeline.RenderContext.IBLSH9System;
			if (sh9 == null) return;
			sh9.DispatchProject(encoder, probeSlot);
		}
	}

	private static void ExecuteCaptureSky(IRenderPassEncoder encoder, SkyPass skyPass,
		Pipeline pipeline, RenderView view, PerFrameResources frame,
		uint32 captureSceneOffset, uint32 mainSceneOffset)
	{
		using (Profiler.Begin("ProbeCapture.Sky"))
		{
			// Bind the probe's scene UBO slot so the sky shader gets the
			// per-face view-proj. Restore the main view's slot afterward so
			// nothing downstream sees the swapped offset.
			frame.CurrentSceneOffset = captureSceneOffset;
			let faceSize = (uint32)Sedulous.Renderer.RenderContext.IBLProbeFaceSize;
			skyPass.RenderInto(encoder, view, pipeline, faceSize, faceSize);
			frame.CurrentSceneOffset = mainSceneOffset;
		}
	}

	private static void ExecuteCaptureFace(IRenderPassEncoder encoder, Pipeline pipeline,
		RenderView view, PerFrameResources frame, uint32 captureSceneOffset, uint32 mainSceneOffset)
	{
		using (Profiler.Begin("ProbeCapture"))
		{
		let renderContext = pipeline.RenderContext;
		let cache = renderContext.PipelineStateCache;
		if (cache == null) return;

		let faceSize = (float)Sedulous.Renderer.RenderContext.IBLProbeFaceSize;
		encoder.SetViewport(0, 0, faceSize, faceSize, 0.0f, 1.0f);
		encoder.SetScissor(0, 0, (uint32)faceSize, (uint32)faceSize);

		// Pipeline config: single-RT (cubemap face), no MRT mini-G-buffer.
		// The `IBL_CAPTURE` shader flag selects the single-output FragmentOutput
		// variant in forward.frag.hlsl so the shader's MRT outputs match.
		var config = PipelineConfig();
		config.ShaderName = "forward";
		config.ShaderFlags = .IBLCapture;
		config.BlendMode = .Opaque;
		config.CullMode = .Back;
		config.ColorTargetCount = 1;
		config.DepthMode = .ReadWrite;
		config.DepthCompare = .Less;
		config.DepthFormat = .Depth24PlusStencil8;

		// Pre-bind a placeholder pipeline + the frame group so set 0 has a known
		// binding for any draw inside this pass. The Vulkan RHI's SetBindGroup
		// silently no-ops if no pipeline is bound (VulkanRenderPassEncoder
		// GetCurrentLayout returns null), so calling BindFrameGroup before any
		// SetPipeline would drop the descriptor set, and a later draw - even
		// from a future pass in the same command buffer - can hit "uses set 0
		// but that set is not bound". MeshRenderer overrides this pipeline with
		// per-group ones, but all forward-shader variants share set 0's
		// frame-bind-group layout, so the frame binding survives the switch.
		frame.CurrentSceneOffset = captureSceneOffset;

		let vertexLayout = VertexLayoutHelper.CreateBufferLayout(.Mesh);
		VertexBufferLayout[1] vertexBuffers = .(vertexLayout);
		let placeholderResult = cache.GetPipeline(config, vertexBuffers, null,
			pipeline.OutputFormat, .Depth24PlusStencil8);
		if (placeholderResult case .Err) return;
		encoder.SetPipeline(placeholderResult.Value);

		pipeline.BindFrameGroup(encoder, frame);

		if (renderContext.DefaultMaterialBindGroup != null)
			encoder.SetBindGroup(BindGroupFrequency.Material, renderContext.DefaultMaterialBindGroup, default);

		// Mask out the "glossy / no-probe-capture" layer (bit 31) so meshes
		// tagged 0x80000000 (e.g. the sandbox's metal sphere) are skipped by
		// MeshRenderer for the duration of this capture - no self-reflection
		// feedback into the probe's own cubemap. Restored afterwards so the
		// main forward pass sees the default everything-included mask.
		let savedLayerMask = frame.CurrentLayerMask;
		frame.CurrentLayerMask = 0x7FFFFFFF;

		// Dispatch opaque + masked. No transparent (doesn't make sense in
		// indirect lighting). Sky is filled into the depth-far pixels by a
		// follow-up render pass in AddPasses; no shadow bind group - the
		// capture doesn't sample shadows.
		pipeline.RenderCategory(encoder, RenderCategories.Opaque, frame, view, .BindMaterial, config);
		pipeline.RenderCategory(encoder, RenderCategories.Masked, frame, view, .BindMaterial, config);

		// Restore main view's scene offset + layer mask for subsequent passes.
		frame.CurrentSceneOffset = mainSceneOffset;
		frame.CurrentLayerMask = savedLayerMask;
		} // ProbeCapture scope
	}
}
