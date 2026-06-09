namespace Sedulous.Renderer.Passes;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Renderer;
using Sedulous.Profiler;

/// Per-pipeline overlay pass.
///
/// Iterates `pipeline.Overlays` (sorted by `IPipelineOverlay.Order` at
/// registration) and calls each implementation's `Render` within a single
/// shared render pass with `LoadOp.Load` on the pipeline output. No depth
/// attachment - overlays draw always-on-top by default and configure
/// their own pipeline state for the draws they emit.
///
/// One render pass for all overlays avoids per-overlay BeginRenderPass/End
/// switching. Empty-registry early-out skips the pass entirely.
///
/// Pass ordering: this runs after `ParticlePass` (so overlays draw on top
/// of game content) but before `DebugGeometryPass` (so editor gizmos can
/// be manipulated above game UI) and `DebugScreenPass` (so diagnostic text
/// is never occluded).
class OverlayPass : PipelinePass
{
	public override StringView Name => "Overlay";

	public override void AddPasses(Sedulous.RenderGraph.RenderGraph graph, RenderView view, Pipeline pipeline)
	{
		if (pipeline.Overlays.Length == 0)
			return;

		let outputHandle = graph.GetResource("PipelineOutput");
		if (!outputHandle.IsValid)
			return;

		graph.AddRenderPass("Overlay", scope (builder) => {
			builder
				.SetColorTarget(0, outputHandle, .Load, .Store)
				.NeverCull()
				.SetExecute(new [=] (encoder) => {
					Execute(encoder, view, pipeline);
				});
		});
	}

	private void Execute(IRenderPassEncoder encoder, RenderView view, Pipeline pipeline)
	{
		using (Profiler.Begin("Overlay"))
		{
			for (let overlay in pipeline.Overlays)
				overlay.Render(encoder, view, pipeline);
		}
	}
}
