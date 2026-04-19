namespace Sedulous.Engine.UI;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Renderer;
using Sedulous.VG;
using Sedulous.VG.Renderer;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Pipeline pass that renders dirty world-space UI views to their textures.
/// Runs before the main scene passes so sprite textures are ready for sampling.
class WorldUIPass : PipelinePass
{
	public override StringView Name => "WorldUI";

	/// Set each frame by UIComponentManager with the list of dirty components.
	public List<UIComponent> DirtyViews = new .() ~ delete _;

	public override void AddPasses(RenderGraph graph, RenderView view, Pipeline pipeline)
	{
		if (DirtyViews.Count == 0)
			return;

		for (let comp in DirtyViews)
		{
			if (comp.Texture == null || comp.TextureView == null) continue;
			if (comp.VG == null || comp.Renderer == null || comp.Root == null) continue;
			if (comp.UIContext == null) continue;

			// Import the component's texture into the render graph.
			let name = scope String();
			name.AppendF("WorldUI_{}", (int)Internal.UnsafeCastToPtr(comp));
			let handle = graph.ImportTarget(name, comp.Texture, comp.TextureView);

			// Transition to ShaderRead after rendering so sprites can sample it.
			graph.RequireReadableAfterWrite(handle);

			// Capture for the closure.
			let capturedComp = comp;

			graph.AddRenderPass(name, scope [&] (builder) => {
				builder
					.SetColorTarget(0, handle, .Clear, .Store)
					.NeverCull()
					.SetExecute(new [=] (encoder) => {
						ExecuteWorldUI(encoder, capturedComp);
					});
			});
		}

		DirtyViews.Clear();
	}

	private static void ExecuteWorldUI(IRenderPassEncoder encoder, UIComponent comp)
	{
		let w = comp.PixelWidth;
		let h = comp.PixelHeight;
		let uiCtx = comp.UIContext;

		// Apply per-component debug settings.
		let savedDebug = uiCtx.DebugSettings;
		if (comp.DebugShowBounds)
			uiCtx.DebugSettings.ShowBounds = true;

		// Layout.
		uiCtx.UpdateRootView(comp.Root);

		// Build VG geometry.
		comp.VG.Clear();
		uiCtx.DrawRootView(comp.Root, comp.VG);

		// Restore debug settings.
		uiCtx.DebugSettings = savedDebug;
		let batch = comp.VG.GetBatch();
		if (batch == null || batch.Commands.Count == 0)
			return;

		// Upload + render.
		comp.Renderer.UpdateProjection(w, h, 0);
		comp.Renderer.Prepare(batch, 0);

		encoder.SetViewport(0, 0, (float)w, (float)h, 0, 1);
		encoder.SetScissor(0, 0, w, h);
		comp.Renderer.Render(encoder, w, h, 0);
	}
}
