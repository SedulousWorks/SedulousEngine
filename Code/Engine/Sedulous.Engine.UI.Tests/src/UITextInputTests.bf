using System;
using Sedulous.Engine.UI;
using Sedulous.Scene;
using Sedulous.Shell;
using Sedulous.Shell.Null;
using Sedulous.UI;

namespace Sedulous.Engine.UI.Tests;

/// Key and text events reaching a focused editor, and the platform text input target that
/// follows focus.
class UITextInputTests
{
	[Test]
	public static void KeyAndTextEventsReachAFocusedEditTextAndTheImeFollowsFocus()
	{
		let fixture = scope UITestFixture(true);
		let devices = scope PointerFakeDevices();
		// Event first: no polled pointer, only this frame's tagged stream.
		devices.MousePresent = false;
		fixture.Input.SetSourceProvider(devices);

		// The player window's text input target, headless.
		let window = scope NullWindow(1, WindowSettings());
		fixture.UI.SetTextInputTarget(window);

		let scene = fixture.Scenes.CreateScene("menu");
		let e = scene.CreateEntity("form");
		let document = UITestFixture.MakeDocument(
			"""
			<Flex direction="vertical"><EditText id="name-field" width="200" height="30"/></Flex>
			""");
		defer delete document;
		scene.GetSystem<UICanvasComponentManager>().Add(e).Document.SetDirect(document);

		fixture.Frame();
		let root = fixture.UI.SceneRoot(scene);
		Test.Assert(root != null);
		root.ViewportSize = .(800.0f, 600.0f);
		fixture.UI.UiContext.UpdateRootView(root);

		let edit = root.FindByName<EditText>("name-field");
		Test.Assert(edit != null);

		// Nothing focused: no platform text input, and the keyboard is not consumed.
		fixture.Frame();
		Test.Assert(!window.IsTextInputActive);
		Test.Assert(!fixture.Input.Runtime.GetConsumptionMask().Keyboard);

		// Focusing the field starts platform text input on the next pump, since the editor
		// wants it, and publishes the keyboard consumption class.
		fixture.UI.UiContext.GetFocusManager().SetFocus(edit);
		fixture.Frame();
		Test.Assert(window.IsTextInputActive);
		Test.Assert(fixture.Input.Runtime.GetConsumptionMask().Keyboard);

		// Text flows through the provider's event stream into the editor...
		devices.PushText("hi");
		fixture.Frame();
		devices.Queue.Clear();
		Test.Assert(edit.Text == "hi");

		// ...and so do ordered key events, Backspace erasing the last character.
		devices.PushKey(.KeyDown, .Backspace);
		devices.PushKey(.KeyUp, .Backspace);
		fixture.Frame();
		devices.Queue.Clear();
		Test.Assert(edit.Text == "h");

		// Dropping focus stops text input and releases the keyboard class.
		fixture.UI.UiContext.GetFocusManager().ClearFocus();
		fixture.Frame();
		Test.Assert(!window.IsTextInputActive);
		Test.Assert(!fixture.Input.Runtime.GetConsumptionMask().Keyboard);
	}
}
