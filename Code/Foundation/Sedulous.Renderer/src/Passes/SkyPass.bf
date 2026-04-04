namespace Sedulous.Renderer.Passes;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Renderer;

/// Sky pass — renders sky/environment behind all opaque geometry.
/// Reads SceneDepth to only render where depth == far plane.
/// Writes to PipelineOutput (or SceneColor).
class SkyPass : PipelinePass
{
	public override StringView Name => "Sky";

	public override void AddPasses(Sedulous.RenderGraph.RenderGraph graph, RenderView view, Pipeline pipeline)
	{
		let data = view.RenderData;
		if (data == null)
			return;

		let skyBatch = data.GetSortedBatch(RenderCategories.Sky);
		if (skyBatch.Length == 0)
			return;

		let depthHandle = graph.GetResource("SceneDepth");
		let backbufferHandle = graph.GetResource("PipelineOutput");

		if (!backbufferHandle.IsValid)
			return;

		graph.AddRenderPass("Sky", scope (builder) => {
			builder
				.SetColorTarget(0, backbufferHandle, .Load, .Store);

			if (depthHandle.IsValid)
				builder.ReadDepth(depthHandle);

			builder.SetExecute(new [=] (encoder) => {
				ExecuteSky(encoder, view, pipeline);
			});
		});
	}

	private void ExecuteSky(IRenderPassEncoder encoder, RenderView view, Pipeline pipeline)
	{
		encoder.SetViewport(0, 0, (float)view.Width, (float)view.Height, 0.0f, 1.0f);
		encoder.SetScissor(0, 0, view.Width, view.Height);

		// TODO: render sky (cubemap, procedural, HDRI)
		// For now: structure only — needs sky shader and pipeline
	}
}
