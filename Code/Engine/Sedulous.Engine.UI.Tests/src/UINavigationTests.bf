using System;
using Sedulous.Core;
using Sedulous.Engine.UI;
using Sedulous.Scene;
using Sedulous.Shell;
using Sedulous.UI;

namespace Sedulous.Engine.UI.Tests;

/// Pad driven navigation: which root the pump routes to, focus moving on a held dpad, and
/// South activating what is focused.
class UINavigationTests
{
	[Test]
	public static void GamepadDpadMovesFocusWithHoldRepeatAndSouthActivates()
	{
		let fixture = scope UITestFixture(true);
		let devices = scope NavFakeDevices();
		fixture.Input.SetSourceProvider(devices);

		let scene = fixture.Scenes.CreateScene("menu");
		let e = scene.CreateEntity("pause");
		let canvas = scene.GetSystem<UICanvasComponentManager>().Add(e);
		let document = UITestFixture.MakeDocument(
			"""
			<Flex direction="vertical" spacing="4">
			<Button id="top" text="Top" width="200" height="36"/>
			<Button id="bottom" text="Bottom" width="200" height="36"/>
			</Flex>
			""");
		defer delete document;
		canvas.Document.SetDirect(document);

		fixture.Frame();
		Test.Assert(canvas.Root != null);

		// The menu lives in the SCENE root. With no pointer and no overlay the pump routes
		// input there, which pad only navigation needs: a pause menu no pointer ever
		// hovered still has to be reachable.
		let root = fixture.UI.SceneRoot(scene);
		Test.Assert(root != null);
		root.ViewportSize = .(800.0f, 600.0f);
		fixture.UI.UiContext.UpdateRootView(root);
		Test.Assert(fixture.UI.UiContext.ActiveInputRoot == root);

		let focus = fixture.UI.UiContext.GetFocusManager();
		Test.Assert(focus != null);
		Test.Assert(focus.FocusedView == null);

		// The first Down press bootstraps focus onto the first focusable.
		devices.Pad.SetDown(.DPadDown);
		fixture.Frame();
		fixture.UI.UiContext.UpdateRootView(root);
		Test.Assert(focus.FocusedView != null);
		Test.Assert(focus.FocusedView.Name == "top");

		// Held, it waits out the initial repeat delay and then advances.
		fixture.Frame(0.1f);
		Test.Assert(focus.FocusedView.Name == "top");
		fixture.Frame(0.35f); // crosses the 0.4s initial delay
		Test.Assert(focus.FocusedView.Name == "bottom");
		devices.Pad.SetDown(.DPadDown, false);
		fixture.Frame();

		// South is Submit: the focused button activates through the Return path.
		bool clicked = false;
		let bottom = (canvas.Root as ViewGroup).FindByName<Button>("bottom");
		Test.Assert(bottom != null);
		bottom.OnClick.Add(new [&clicked](sender) => { clicked = true; });
		devices.Pad.SetPressed(.South);
		fixture.Frame();
		Test.Assert(clicked);
		devices.Pad.SetPressed(.South, false);

		// An OCCUPIED screen tier is modal: routing flips to the screen root.
		let modal = UITestFixture.MakeDocument("<Panel><Label text=\"Loading\"/></Panel>");
		defer delete modal;
		let overlay = fixture.UI.PushScreenOverlay(modal);
		Test.Assert(overlay != null);
		fixture.Frame();
		Test.Assert(fixture.UI.UiContext.ActiveInputRoot == fixture.UI.ScreenRoot);

		fixture.UI.RemoveScreenOverlay(overlay);
		fixture.Frame();
		Test.Assert(fixture.UI.UiContext.ActiveInputRoot == root, "back to the scene tier");
	}
}
