using System;
using Sedulous.Core;
using Sedulous.Engine.UI;
using Sedulous.Input;
using Sedulous.Scene;
using Sedulous.Shell;
using Sedulous.UI;

namespace Sedulous.Engine.UI.Tests;

/// A pad and a mouse behind one provider: a handheld, whose cursor is hidden but still has
/// a position.
class PadAndMouseDevices : IInputSourceProvider
{
	public NavFakePad Pad = new .() ~ delete _;
	public PointerFakeMouse FakeMouse = new .() ~ delete _;

	public IKeyboard Keyboard => null;
	public IMouse Mouse => FakeMouse;
	public int32 GamepadCount => 1;
	public IGamepad GetGamepad(int32 index) => (index == 0) ? Pad : null;
	public Span<InputEvent> Events => .();
}

/// Only a pointer in use hovers, and focus a pad navigates by shows its ring. On a Steam Deck
/// the hidden cursor rested over a menu's last button: it lit up like focus while the real
/// focus, set by the screen, drew nothing.
class UIPointerIdleTests
{
	[Test]
	public static void AnIdlePointerDoesNotHoverAndPadFocusShows()
	{
		let fixture = scope UITestFixture(true);
		let devices = scope PadAndMouseDevices();
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

		// The cursor rests over the bottom button from the very first frame: a position with
		// no motion, as the platform first reports one.
		devices.FakeMouse.X = 100.0f;
		devices.FakeMouse.Y = 58.0f;
		fixture.Frame();
		let root = fixture.UI.SceneRoot(scene);
		Test.Assert(root != null);
		root.ViewportSize = .(800.0f, 600.0f);
		fixture.UI.UiContext.UpdateRootView(root);
		let top = (canvas.Root as ViewGroup).FindByName<Button>("top");
		let bottom = (canvas.Root as ViewGroup).FindByName<Button>("bottom");
		Test.Assert((top != null) && (bottom != null));

		// The screen's default focus, set by itself.
		let focus = fixture.UI.UiContext.GetFocusManager();
		focus.SetFocus(top);
		fixture.Frame();
		fixture.Frame();
		let input = fixture.UI.UiContext.GetInputManager();
		Test.Assert(!bottom.IsHovered(), "a pointer that never moved hovers nothing");
		Test.Assert(top.IsFocusVisible(), "with a pad connected, the default focus shows its ring");

		// The pointer moves: it is in use, and hovers.
		devices.FakeMouse.Y = 60.0f;
		devices.FakeMouse.DeltaY = 2.0f;
		fixture.Frame();
		devices.FakeMouse.DeltaY = 0.0f;
		Test.Assert(input.HoveredId == bottom.Id, "a moved pointer hovers");

		// The pad takes over: the hover goes, and stays gone while the pointer rests.
		devices.Pad.SetDown(.DPadDown);
		fixture.Frame();
		devices.Pad.SetDown(.DPadDown, false);
		fixture.Frame();
		Test.Assert(!bottom.IsHovered(), "pad input drops the hover");
	}
}
