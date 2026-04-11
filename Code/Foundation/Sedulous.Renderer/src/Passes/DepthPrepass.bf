namespace Sedulous.Renderer.Passes;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Renderer;
using Sedulous.Materials;
using Sedulous.Profiler;

/// Depth prepass — renders opaque geometry to the depth buffer only.
/// Establishes early-Z for the forward pass to minimize overdraw.
/// Creates the SceneDepth transient resource.
class DepthPrepass : PipelinePass
{
	public override StringView Name => "DepthPrepass";

	public override void AddPasses(Sedulous.RenderGraph.RenderGraph graph, RenderView view, Pipeline pipeline)
	{
		let data = view.RenderData;
		if (data == null)
			return;

		if (data.GetBatchCount(RenderCategories.Opaque) == 0)
			return;

		// Create SceneDepth as a transient depth texture
		let depthDesc = RGTextureDesc(.Depth24PlusStencil8)
		{
			Usage = .DepthStencil | .Sampled
		};
		let depthHandle = graph.CreateTransient("SceneDepth", depthDesc);

		graph.AddRenderPass("DepthPrepass", scope (builder) => {
			builder
				.SetDepthTarget(depthHandle, .Clear, .Store, 1.0f)
				.NeverCull()
				.SetExecute(new [=] (encoder) => {
					ExecuteDepthPrepass(encoder, view, pipeline);
				});
		});
	}

	private void ExecuteDepthPrepass(IRenderPassEncoder encoder, RenderView view, Pipeline pipeline)
	{
		using (Profiler.Begin("DepthPrepass"))
		{
		let renderContext = pipeline.RenderContext;
		let cache = renderContext.PipelineStateCache;
		if (cache == null)
			return;

		encoder.SetViewport(0, 0, (float)view.Width, (float)view.Height, 0.0f, 1.0f);
		encoder.SetScissor(0, 0, view.Width, view.Height);

		// Depth-only pipeline config: no color output, write depth
		var config = PipelineConfig();
		config.ShaderName = "depth_only";
		config.DepthMode = .ReadWrite;
		config.DepthCompare = .Less;
		config.DepthFormat = .Depth24PlusStencil8;
		config.CullMode = .Back;
		config.ColorTargetCount = 0;
		config.DepthOnly = true;

		let vertexLayout = VertexLayoutHelper.CreateBufferLayout(.Mesh);
		VertexBufferLayout[1] vertexBuffers = .(vertexLayout);

		let pipelineResult = cache.GetPipeline(config, vertexBuffers, null, .Undefined, .Depth24PlusStencil8);
		if (pipelineResult case .Err)
			return;

		let rhiPipeline = pipelineResult.Value;

		encoder.SetPipeline(rhiPipeline);

		let frame = pipeline.GetFrameResources(view.FrameIndex);
		pipeline.BindFrameGroup(encoder, frame);

		// Dispatch to registered renderers — depth pass skips material binding.
		pipeline.RenderCategory(encoder, RenderCategories.Opaque, frame, view, .None);
		} // DepthPrepass scope
	}
}
