using System;
using Sedulous.Core;
using Sedulous.Engine.UI;
using Sedulous.Scene;
using Sedulous.Shell;
using Sedulous.UI;

namespace Sedulous.Engine.UI.Tests;

/// A pad's directions reach the focused control first, as the arrow keys do: right steps a
/// focused slider, and down, which the slider leaves alone, moves focus on. A settings menu of
/// volume sliders and a Back button is driven entirely from a pad.
class UIPadSliderTests
{
	[Test]
	public static void APadStepsAFocusedSliderAndMovesPastIt()
	{
		let fixture = scope UITestFixture(true);
		let devices = scope NavFakeDevices();
		fixture.Input.SetSourceProvider(devices);

		let scene = fixture.Scenes.CreateScene("settings");
		let e = scene.CreateEntity("menu");
		let canvas = scene.GetSystem<UICanvasComponentManager>().Add(e);
		let document = UITestFixture.MakeDocument(
			"""
			<Flex direction="vertical" spacing="4">
			<Slider id="music" min="0" max="1" value="0.5" width="200" height="24"/>
			<Button id="back" text="Back" width="200" height="36"/>
			</Flex>
			""");
		defer delete document;
		canvas.Document.SetDirect(document);
		fixture.Frame();
		let root = fixture.UI.SceneRoot(scene);
		root.ViewportSize = .(800.0f, 600.0f);
		fixture.UI.UiContext.UpdateRootView(root);

		let slider = (canvas.Root as ViewGroup).FindByName<Slider>("music");
		Test.Assert(slider != null);
		let focus = fixture.UI.UiContext.GetFocusManager();
		focus.SetFocus(slider);

		// Right: the slider takes it and steps a twentieth of its range.
		devices.Pad.SetDown(.DPadRight);
		fixture.Frame();
		devices.Pad.SetDown(.DPadRight, false);
		fixture.Frame();
		Test.Assert(Math.Abs(slider.Value.Value - 0.55f) < 0.0001f, scope $"stepped to {slider.Value.Value}");
		Test.Assert(focus.FocusedView === slider, "and kept focus");

		// Down: the slider leaves it, so focus moves on to the button.
		devices.Pad.SetDown(.DPadDown);
		fixture.Frame();
		devices.Pad.SetDown(.DPadDown, false);
		fixture.Frame();
		Test.Assert(focus.FocusedView.Name == "back", scope $"focus on '{focus.FocusedView.Name}'");
		Test.Assert(Math.Abs(slider.Value.Value - 0.55f) < 0.0001f, "the value untouched");
	}
}
