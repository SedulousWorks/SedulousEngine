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
///
/// Layout + VG batch construction + slice allocation happen during
/// `AddPasses` (CPU phase). Per-component render passes are scheduled
/// with the corresponding slice captured in their execute closure; the
/// GPU consumes each slice's data at its byte offset in the shared
/// vertex/index/uniform buffers (per-pipeline shared `VGRenderer`).
class WorldUIPass : PipelinePass
{
	public override StringView Name => "WorldUI";

	/// Set by `EngineUISubsystem` when this pass is wired to a pipeline.
	/// `AddPasses` uses the manager's shared `VGContext` + `VGRenderer`
	/// for every dirty component - one BeginFrame per frame, one slice
	/// per component, one shared upload.
	public UIComponentManager Manager;

	/// Set each frame by UIComponentManager with the list of dirty components.
	public List<UIComponent> DirtyViews = new .() ~ delete _;

	public override void AddPasses(RenderGraph graph, RenderView view, Pipeline pipeline)
	{
		if (DirtyViews.Count == 0)
			return;
		if (Manager == null) return;

		let sharedVG = Manager.SharedVG;
		let sharedRenderer = Manager.SharedVGRenderer;
		if (sharedVG == null || sharedRenderer == null) return;

		// One BeginFrame for the shared renderer this frame.
		sharedRenderer.BeginFrame(0);

		for (let comp in DirtyViews)
		{
			if (comp.Texture == null || comp.TextureView == null) continue;
			if (comp.Root == null || comp.UIContext == null) continue;

			let w = comp.PixelWidth;
			let h = comp.PixelHeight;
			let uiCtx = comp.UIContext;

			// Apply per-component debug settings during layout.
			let savedDebug = uiCtx.DebugSettings;
			if (comp.DebugShowBounds)
				uiCtx.DebugSettings.ShowBounds = true;

			uiCtx.UpdateRootView(comp.Root);

			// Build VG geometry into the shared context. Cleared per
			// component because Prepare immediately captures the batch
			// into the shared buffers + draw-command list - the VG
			// context is just CPU scratch and is safe to overwrite for
			// the next component.
			sharedVG.Clear();
			uiCtx.DrawRootView(comp.Root, sharedVG);

			uiCtx.DebugSettings = savedDebug;

			let batch = sharedVG.GetBatch();
			if (batch == null || batch.Commands.Count == 0)
				continue;

			// Upload this component's batch into the shared frame buffers
			// at its own byte offset; the slice records that offset for
			// the GPU-phase Render call.
			let slice = sharedRenderer.Prepare(batch, 0, w, h);
			if (!slice.IsValid) continue;

			// Import the component's texture into the render graph.
			let name = scope String();
			name.AppendF("WorldUI_{}", (int)Internal.UnsafeCastToPtr(comp));
			let handle = graph.ImportTarget(name, comp.Texture, comp.TextureView);

			// Transition to ShaderRead after rendering so sprites can sample it.
			graph.RequireReadableAfterWrite(handle);

			// Capture per-pass state for the GPU-phase closure.
			let capturedRenderer = sharedRenderer;
			let capturedSlice = slice;
			let cw = w;
			let ch = h;

			graph.AddRenderPass(name, scope [&] (builder) => {
				builder
					.SetColorTarget(0, handle, .Clear, .Store)
					.NeverCull()
					.SetExecute(new [=] (encoder) => {
						encoder.SetViewport(0, 0, (float)cw, (float)ch, 0, 1);
						encoder.SetScissor(0, 0, cw, ch);
						capturedRenderer.Render(encoder, cw, ch, 0, capturedSlice);
					});
			});
		}

		DirtyViews.Clear();
	}
}
