namespace Sedulous.Renderer.Passes;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Renderer;
using Sedulous.Materials;
using Sedulous.Profiler;

/// Transparent forward pass — renders transparent geometry with PBR lighting.
/// Reads SceneDepth (depth test, no write). Alpha blended, back-to-front sorted.
/// Same forward shader as opaque, different pipeline state.
class ForwardTransparentPass : PipelinePass
{
	public override StringView Name => "ForwardTransparent";

	public override void AddPasses(Sedulous.RenderGraph.RenderGraph graph, RenderView view, Pipeline pipeline)
	{
		let data = view.RenderData;
		if (data == null)
			return;

		if (data.GetBatchCount(RenderCategories.Transparent) == 0)
			return;

		let outputHandle = graph.GetResource("PipelineOutput");
		if (!outputHandle.IsValid)
			return;

		let depthHandle = graph.GetResource("SceneDepth");
		let hasDepth = depthHandle.IsValid;

		graph.AddRenderPass("ForwardTransparent", scope (builder) => {
			builder.SetColorTarget(0, outputHandle, .Load, .Store);

			if (hasDepth)
				builder.SetDepthTarget(depthHandle, .Load, .Store, 1.0f);

			builder
				.NeverCull()
				.SetExecute(new [=] (encoder) => {
					ExecuteTransparent(encoder, view, pipeline, hasDepth);
				});
		});
	}

	private void ExecuteTransparent(IRenderPassEncoder encoder, RenderView view, Pipeline pipeline, bool hasDepth)
	{
		using (Profiler.Begin("ForwardTransparent"))
		{
		let renderContext = pipeline.RenderContext;
		let cache = renderContext.PipelineStateCache;
		if (cache == null)
			return;

		encoder.SetViewport(0, 0, (float)view.Width, (float)view.Height, 0.0f, 1.0f);
		encoder.SetScissor(0, 0, view.Width, view.Height);

		let frame = pipeline.GetFrameResources(view.FrameIndex);

		// Transparent pipeline: same forward shader, alpha blend, depth read-only
		var config = PipelineConfig();
		config.ShaderName = "forward";
		config.BlendMode = .AlphaBlend;
		config.CullMode = .Back;
		config.ColorTargetCount = 1;

		if (hasDepth)
		{
			config.DepthMode = .ReadOnly;
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

		// Dispatch to registered renderers for the transparent category.
		// Future: ParticleRenderer registered for Transparent will be called here too.
		pipeline.RenderCategory(encoder, RenderCategories.Transparent, frame, view, .BindMaterial);
		} // ForwardTransparent scope
	}
}
