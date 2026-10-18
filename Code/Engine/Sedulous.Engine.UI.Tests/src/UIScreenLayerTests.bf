using System;
using Sedulous.Core;
using Sedulous.Engine.UI;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.UI;

namespace Sedulous.Engine.UI.Tests;

/// The screen tier's offscreen layers: recorded before the host's overlay pass, so a faded group
/// fades as one in a game's screen UI as it does in the editor.
class UIScreenLayerTests
{
	/// The screen tier records itself before the host's overlay pass (PrepareOverlay), so a faded
	/// group's layer is drawn in a pass of its own there, and the overlay pass only composites
	/// it. A Render with no prepare step draws inside the pass, the group's layer an opacity push.
	[Test]
	public static void TheScreenTierDrawsAFadedGroupsLayerBeforeTheOverlayPass()
	{
		// DECLARED FIRST so it is freed LAST: the fixture's teardown shuts the subsystem down,
		// which releases pipelines and textures THROUGH this device.
		let device = scope NullDevice();
		// With the data root: the screen tier draws only once the vector shaders resolve.
		let fixture = scope UITestFixture(false, true);
		fixture.UI.EnsureRenderReady(device, 2);

		let group = new FrameLayout();
		group.Opacity = 0.5f;
		group.AddView(new ColorView(.Red, 40.0f, 40.0f));
		group.AddView(new ColorView(.Blue, 40.0f, 40.0f));
		fixture.UI.PushScreenOverlay(group);
		defer fixture.UI.RemoveScreenOverlay(group);
		fixture.Frame();

		var view = ScreenOverlayView();
		view.Width = 128;
		view.Height = 128;
		view.TargetFormat = .RGBA8UnormSrgb;
		Test.Assert(device.CreateCommandPool(.Graphics) case .Ok(var pool));
		defer device.DestroyCommandPool(ref pool);
		Test.Assert(pool.CreateEncoder() case .Ok(var encoder));
		defer pool.DestroyEncoder(ref encoder);

		let passesBefore = device.Counters().RenderPasses;
		fixture.UI.PrepareOverlay(encoder, view);
		let layerPasses = device.Counters().RenderPasses - passesBefore;
		Test.Assert(layerPasses == 1, scope $"{layerPasses} passes: the group's layer, before the overlay pass opens");

		let pass = encoder.BeginRenderPass(.());
		Test.Assert(pass != null);
		let drawsBefore = device.Counters().Draws;
		fixture.UI.Render(pass, view);
		Test.Assert(device.Counters().Draws > drawsBefore, "the composite, at least");
		Test.Assert(device.Counters().RenderPasses - passesBefore == layerPasses + 1, "Render opened none");

		// No prepare step: the screen draws in the pass all the same, and still opens no pass.
		let drawsUnprepared = device.Counters().Draws;
		fixture.UI.Render(pass, view);
		Test.Assert(device.Counters().Draws > drawsUnprepared);
		Test.Assert(device.Counters().RenderPasses - passesBefore == layerPasses + 1);
		pass.End();
	}
}
