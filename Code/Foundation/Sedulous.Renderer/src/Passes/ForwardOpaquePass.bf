namespace Sedulous.Renderer.Passes;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Renderer;
using Sedulous.Materials;
using Sedulous.Profiler;

/// Forward pass — renders opaque and masked geometry with PBR lighting.
/// Reads SceneDepth from DepthPrepass (depth test LessEqual, no depth write).
/// Masked geometry uses the same shader with AlphaCutoff for discard.
class ForwardOpaquePass : PipelinePass
{
	public override StringView Name => "ForwardOpaque";

	public override void AddPasses(Sedulous.RenderGraph.RenderGraph graph, RenderView view, Pipeline pipeline)
	{
		let data = view.RenderData;
		if (data == null)
			return;

		if (data.GetBatchCount(RenderCategories.Opaque) == 0 &&
			data.GetBatchCount(RenderCategories.Masked) == 0)
			return;

		let outputHandle = graph.GetResource("PipelineOutput");
		if (!outputHandle.IsValid)
			return;

		// Read SceneDepth from DepthPrepass
		let depthHandle = graph.GetResource("SceneDepth");
		let hasDepth = depthHandle.IsValid;

		graph.AddRenderPass("ForwardOpaque", scope (builder) => {
			builder.SetColorTarget(0, outputHandle, .Clear, .Store, ClearColor(0.0f, 0.0f, 0.0f, 1.0f));

			if (hasDepth)
				builder.SetDepthTarget(depthHandle, .Load, .Store, 1.0f);

			builder
				.NeverCull()
				.SetExecute(new [=] (encoder) => {
					ExecuteForwardOpaque(encoder, view, pipeline, hasDepth);
				});
		});
	}

	private void ExecuteForwardOpaque(IRenderPassEncoder encoder, RenderView view, Pipeline pipeline, bool hasDepth)
	{
		using (Profiler.Begin("ForwardOpaque"))
		{
		let renderContext = pipeline.RenderContext;
		let cache = renderContext.PipelineStateCache;
		if (cache == null)
			return;

		encoder.SetViewport(0, 0, (float)view.Width, (float)view.Height, 0.0f, 1.0f);
		encoder.SetScissor(0, 0, view.Width, view.Height);

		let frame = pipeline.GetFrameResources(view.FrameIndex);

		// Build pipeline config
		var config = PipelineConfig();
		config.ShaderName = "forward";
		config.BlendMode = .Opaque;
		config.CullMode = .Back;
		config.ColorTargetCount = 1;

		if (hasDepth)
		{
			// ReadWrite so masked geometry (which the depth prepass skipped) writes
			// its depth. Opaque pixels already have correct depth from the prepass;
			// re-writing the same value is a no-op. Without this, SkyPass fills
			// masked pixels because their depth is still at far-plane.
			config.DepthMode = .ReadWrite;
			config.DepthCompare = .LessEqual;
			config.DepthFormat = .Depth24PlusStencil8;
		}
		else
		{
			config.DepthMode = .Disabled;
		}

		let vertexLayout = VertexLayoutHelper.CreateBufferLayout(.Mesh);
		VertexBufferLayout[1] vertexBuffers = .(vertexLayout);

		let pipelineResult = cache.GetPipeline(config, vertexBuffers, null, pipeline.OutputFormat,
			hasDepth ? .Depth24PlusStencil8 : .Undefined);
		if (pipelineResult case .Err)
			return;

		let rhiPipeline = pipelineResult.Value;

		encoder.SetPipeline(rhiPipeline);

		pipeline.BindFrameGroup(encoder, frame);

		if (renderContext.DefaultMaterialBindGroup != null)
			encoder.SetBindGroup(BindGroupFrequency.Material, renderContext.DefaultMaterialBindGroup, default);

		// Bind shadow data (set 4) so the forward shader can sample the atlas.
		let shadowSystem = renderContext.ShadowSystem;
		if (shadowSystem != null)
		{
			let shadowBg = shadowSystem.GetBindGroup(view.FrameIndex);
			if (shadowBg != null)
				encoder.SetBindGroup(BindGroupFrequency.Shadow, shadowBg, default);
		}

		// Dispatch to registered renderers (MeshRenderer, future: particles, etc.)
		pipeline.RenderCategory(encoder, RenderCategories.Opaque, frame, view, .BindMaterial);
		pipeline.RenderCategory(encoder, RenderCategories.Masked, frame, view, .BindMaterial);

		} // ForwardOpaque scope
	}
}
