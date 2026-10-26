using System;
using Sedulous.Shell;

namespace Sedulous.Engine.GUI.Tests;

/// A mouse a test moves and presses; a press or release shows as an edge for one frame (the
/// fixture's Frame carries Down into WasDown after the frame's lane).
class GuiFakeMouse : IMouse
{
	public float X { get; set; } = -100.0f;
	public float Y { get; set; } = -100.0f;
	public bool Down = false;
	public bool WasDown = false;

	public float GlobalX => X;
	public float GlobalY => Y;
	public float DeltaX => 0.0f;
	public float DeltaY => 0.0f;
	public float ScrollX => 0.0f;
	public float ScrollY => 0.0f;

	public bool IsButtonDown(MouseButton button) => (button == .Left) && Down;
	public bool IsButtonPressed(MouseButton button) => (button == .Left) && Down && !WasDown;
	public bool IsButtonReleased(MouseButton button) => (button == .Left) && !Down && WasDown;

	public bool RelativeMode => false;
	public void SetRelativeMode(bool enabled) {}
	public bool CursorVisible => true;
	public void SetCursorVisible(bool visible) {}
	public void SetCursor(CursorType cursor) {}
	public void SetGlobalCapture(bool enabled) {}
}
