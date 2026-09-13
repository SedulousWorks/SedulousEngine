using System;
using Sedulous.Shell;

namespace Sedulous.Engine.UI.Tests;

/// A mouse a case places and clicks directly. The polled shape a real source presents, since
/// the pointer pump reads position and button state rather than events.
class PointerFakeMouse : IMouse
{
	private bool[8] mButtons = .();

	public float X { get; set; } = 0.0f;
	public float Y { get; set; } = 0.0f;
	public float GlobalX => X;
	public float GlobalY => Y;
	public float DeltaX => 0.0f;
	public float DeltaY => 0.0f;
	public float ScrollX => 0.0f;
	public float ScrollY => 0.0f;

	public bool IsButtonDown(MouseButton button) => mButtons[(uint32)button & 7];
	public bool IsButtonPressed(MouseButton button) => false;
	public bool IsButtonReleased(MouseButton button) => false;

	public void SetButtonDown(MouseButton button, bool value) =>
		mButtons[(uint32)button & 7] = value;

	public bool RelativeMode => false;
	public void SetRelativeMode(bool enabled) {}
	public bool CursorVisible => true;
	public void SetCursorVisible(bool visible) {}
	public void SetCursor(CursorType cursor) {}
	public void SetGlobalCapture(bool enabled) {}
}
