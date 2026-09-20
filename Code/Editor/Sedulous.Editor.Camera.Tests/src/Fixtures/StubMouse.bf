using Sedulous.Shell;

namespace Sedulous.Editor.Camera.Tests;

class StubMouse : IMouse
{
	public bool Rmb = false;
	public float Dx = 0.0f;
	public float Dy = 0.0f;
	public float Scroll = 0.0f;

	public float X => 0.0f;
	public float Y => 0.0f;
	public float GlobalX => 0.0f;
	public float GlobalY => 0.0f;
	public float DeltaX => Dx;
	public float DeltaY => Dy;
	public float ScrollX => 0.0f;
	public float ScrollY => Scroll;
	public bool IsButtonDown(MouseButton button) => (button == .Right) && Rmb;
	public bool IsButtonPressed(MouseButton button) => false;
	public bool IsButtonReleased(MouseButton button) => false;
	public bool RelativeMode => false;
	public void SetRelativeMode(bool enabled) {}
	public bool CursorVisible => true;
	public void SetCursorVisible(bool visible) {}
	public void SetCursor(CursorType cursor) {}
	public void SetGlobalCapture(bool capture) {}
}
