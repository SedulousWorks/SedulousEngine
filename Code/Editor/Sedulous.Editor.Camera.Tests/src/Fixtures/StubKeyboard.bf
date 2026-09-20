using Sedulous.Shell;

namespace Sedulous.Editor.Camera.Tests;

/// Just enough for the camera's Update to read.
class StubKeyboard : IKeyboard
{
	public bool WDown = false;
	public bool ShiftDown = false;

	public bool IsKeyDown(KeyCode key) => ((key == .W) && WDown) || ((key == .LeftShift) && ShiftDown);
	public bool IsKeyPressed(KeyCode key) => false;
	public bool IsKeyReleased(KeyCode key) => false;
	public KeyModifiers Modifiers => .None;
}
