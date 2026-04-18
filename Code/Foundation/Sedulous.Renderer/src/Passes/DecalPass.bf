namespace Sedulous.Renderer.Passes;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Renderer;
using Sedulous.Renderer.Renderers;
using Sedulous.Materials;
using Sedulous.Profiler;

/// Decal rendering pass. Runs after the forward opaque pass (so SceneDepth is
/// populated) and before SkyPass / ForwardTransparentPass so decals compose on
/// top of opaque geometry but underneath transparent content.
///
/// The pass reads SceneDepth as a sampled input — the render graph emits the
/// appropriate DepthStencilWrite -> ShaderRead barrier automatically when the
/// pass declares the depth handle as a read dependency.
///
/// Execution dispatches RenderCategories.Decal through the DecalRenderer drawer,
/// which owns its own pipeline state and bind group layouts.
class DecalPass : PipelinePass
{
	public override StringView Name => "DecalPass";

	public override void AddPasses(Sedulous.RenderGraph.RenderGraph graph, RenderView view, Pipeline pipeline)
	{
		let data = view.RenderData;
		if (data == null) return;
		if (data.GetBatchCount(RenderCategories.Decal) == 0) return;

		let outputHandle = graph.GetResource("PipelineOutput");
		if (!outputHandle.IsValid) return;

		let depthHandle = graph.GetResource("SceneDepth");
		if (!depthHandle.IsValid) return;

		graph.AddRenderPass("DecalPass", scope (builder) => {
			builder.SetColorTarget(0, outputHandle, .Load, .Store);
			builder.ReadTexture(depthHandle); // barrier: depth-attachment -> shader-read
			builder
				.NeverCull()
				.SetExecute(new [=] (encoder) => {
					Execute(encoder, view, pipeline, depthHandle);
				});
		});
	}

	private void Execute(IRenderPassEncoder encoder, RenderView view, Pipeline pipeline, RGHandle depthHandle)
	{
		using (Profiler.Begin("DecalPass"))
		{
		let renderContext = pipeline.RenderContext;

		// Locate the DecalRenderer drawer in the RenderContext registry and pass
		// it the current SceneDepth view so it can build its bind group for this
		// draw. The renderer caches the view so rebuilds are rare.
		let decalRenderer = FindDecalRenderer(renderContext);
		if (decalRenderer == null) return;

		// The depth texture is shared between the prepass (write) and here (read).
		// GetDepthOnlyTextureView returns a view with the stencil aspect stripped
		// so it can be bound as a plain sampled texture.
		let depthView = pipeline.RenderGraph.GetDepthOnlyTextureView(depthHandle);
		if (depthView == null) return;
		decalRenderer.UpdateForFrame(view.FrameIndex, depthView);

		let frame = pipeline.GetFrameResources(view.FrameIndex);

		var passConfig = PipelineConfig();
		passConfig.ColorTargetCount = 1;
		passConfig.DepthCompare = .LessEqual;
		passConfig.DepthMode = .Disabled;
		passConfig.BlendMode = .AlphaBlend;

		pipeline.RenderCategory(encoder, RenderCategories.Decal, frame, view, .None, passConfig);
		} // scope
	}

	/// Finds the DecalRenderer among the registered drawers on the RenderContext.
	/// Returns null if no decal renderer is registered.
	private DecalRenderer FindDecalRenderer(RenderContext context)
	{
		let renderers = context.GetRenderersFor(RenderCategories.Decal);
		if (renderers == null) return null;
		for (let r in renderers)
		{
			if (let dr = r as DecalRenderer) return dr;
		}
		return null;
	}
}
