namespace Sedulous.Particles;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Renderer;
using Sedulous.Profiler;

/// Particle rendering pass. Runs after ForwardTransparentPass.
///
/// Declares both ReadDepth (depth testing) and ReadTexture (shader sampling)
/// on SceneDepth, which causes the render graph to transition the depth buffer
/// to VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL — allowing simultaneous
/// depth testing and soft-particle depth sampling in the fragment shader.
///
/// Dispatches RenderCategories.Particle through the ParticleRenderer drawer.
public class ParticlePass : PipelinePass
{
	public override StringView Name => "ParticlePass";

	public override void AddPasses(Sedulous.RenderGraph.RenderGraph graph, RenderView view, Pipeline pipeline)
	{
		let data = view.RenderData;
		if (data == null) return;
		if (data.GetBatchCount(RenderCategories.Particle) == 0) return;

		let outputHandle = graph.GetResource("PipelineOutput");
		if (!outputHandle.IsValid) return;

		let depthHandle = graph.GetResource("SceneDepth");
		if (!depthHandle.IsValid) return;

		graph.AddRenderPass("ParticlePass", scope (builder) => {
			builder.SetColorTarget(0, outputHandle, .Load, .Store);

			// Both depth attachment (read-only, for depth testing) and sampled
			// texture (for soft particle fade). The render graph + Vulkan backend
			// transitions to DEPTH_STENCIL_READ_ONLY_OPTIMAL for this combination.
			builder.ReadDepth(depthHandle);
			builder.ReadTexture(depthHandle);

			builder
				.NeverCull()
				.SetExecute(new [=] (encoder) => {
					Execute(encoder, view, pipeline, depthHandle);
				});
		});
	}

	private void Execute(IRenderPassEncoder encoder, RenderView view, Pipeline pipeline, RGHandle depthHandle)
	{
		using (Profiler.Begin("ParticlePass"))
		{
		let renderContext = pipeline.RenderContext;

		// Publish the scene depth view on RenderContext so the ParticleRenderer
		// can read it and build its depth bind group for soft particles.
		let depthView = pipeline.RenderGraph.GetDepthOnlyTextureView(depthHandle);
		renderContext.CurrentSceneDepthView = depthView;

		let frame = pipeline.GetFrameResources(view.FrameIndex);
		pipeline.RenderCategory(encoder, RenderCategories.Particle, frame, view, .BindMaterial);
		} // scope
	}
}
