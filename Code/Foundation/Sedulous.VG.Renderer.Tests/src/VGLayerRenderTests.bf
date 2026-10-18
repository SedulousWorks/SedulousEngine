using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.VG;
using Sedulous.VG.Renderer;

namespace Sedulous.VG.Renderer.Tests;

/// Offscreen layers through the renderer: each drawn into a target of its own by RenderLayers,
/// then composited into what holds it.
class VGLayerRenderTests
{
	/// The batch: a fill on the target, a half layer holding a fill and a nested Screen layer,
	/// and a layer wholly off the canvas.
	private static void Record(VGContext context)
	{
		context.SetLayers(true);
		context.FillRect(.(0, 0, 8, 8), .White); // into the target
		context.PushLayer(0.5f);
		context.FillRect(.(10, 10, 20, 20), .Red);
		context.PushLayer(0.5f, .Screen); // nested, with a blend of its own
		context.FillRect(.(20, 20, 20, 20), .Blue);
		context.PopLayer();
		context.PopLayer();
		context.PushLayer(0.5f); // wholly off the canvas: never drawn, its composite skipped
		context.FillRect(.(200, 200, 10, 10), .Red);
		context.PopLayer();
	}

	/// Three frames over two slots, so the slots' targets are reused; returns the last frame's
	/// layer stats and the target's.
	private static void Run(RendererFixture fixture, IShaderModule layerShader, VGBatch batch,
		out VGRenderStats layers, out VGRenderStats onTarget)
	{
		layers = .();
		onTarget = .();
		var config = VGTargetConfig();
		// Layer targets resolve their own multisampled draws, and carry a stencil.
		config.SampleCount = 4;
		config.DepthStencilFormat = VGRenderer.PickStencilCapableFormat(fixture.Device, 4);
		let renderer = scope VGRenderer();
		Test.Assert(renderer.Initialize(fixture.Device, fixture.VertexShader, fixture.FragmentShader,
			.BGRA8UnormSrgb, 2, null, null, null, config, null, null, null, layerShader) case .Ok);
		defer renderer.Dispose();

		Test.Assert(fixture.Device.CreateCommandPool(.Graphics) case .Ok(var pool));
		defer fixture.Device.DestroyCommandPool(ref pool);
		for (int32 frame < 3)
		{
			let slot = frame % 2;
			renderer.BeginFrame(slot);
			let slice = renderer.Prepare(batch, slot, 64, 64);
			Test.Assert(slice.IsValid);
			Test.Assert(slice.LayerCount == 3);

			Test.Assert(pool.CreateEncoder() case .Ok(var encoder));
			renderer.RenderLayers(encoder, slot, slice);
			let pass = encoder.BeginRenderPass(.());
			renderer.Render(pass, 64, 64, slot, slice);
			pass.End();
			pool.DestroyEncoder(ref encoder);
			layers = renderer.LastLayerStats;
			onTarget = renderer.LastRenderStats;
		}
	}

	/// With the composite shader the two layers on the canvas are drawn (each its own fill, the
	/// outer one also the inner one's composite), and the target gets the white fill and the
	/// outer composite, the off canvas layer's composite skipped. Without it no layer is drawn
	/// and every composite is skipped, never drawn by the default shader, which would multiply
	/// the premultiplied colour again.
	[Test]
	public static void LayersDrawIntoTargetsOfTheirOwnThenCompositeIntoWhatHoldsThem()
	{
		let fixture = scope RendererFixture(false, true);
		let context = scope VGContext();
		Record(context);
		let batch = context.GetBatch();
		Test.Assert(batch.Layers.Count == 3);

		VGRenderStats layers;
		VGRenderStats onTarget;
		Run(fixture, fixture.LayerFragmentShader, batch, out layers, out onTarget);
		Test.Assert(layers.Layers == 2);
		Test.Assert(layers.Drawn == 3);
		Test.Assert(layers.Skipped == 0);
		Test.Assert(onTarget.Drawn == 2);
		Test.Assert(onTarget.Skipped == 1);

		Run(fixture, null, batch, out layers, out onTarget);
		Test.Assert(layers.Layers == 0);
		Test.Assert(onTarget.Drawn == 1);
		Test.Assert(onTarget.Skipped == 2);
	}
}
