using System;
using Sedulous.Shell;

namespace Sedulous.Input.Tests;

/// A mouse whose deltas and buttons a test sets directly.
class FakeMouse : IMouse
{
	private bool[8] mDown = .();
	private bool[8] mPressed = .();

	public float DeltaX { get; set; } = 0.0f;
	public float DeltaY { get; set; } = 0.0f;
	public float ScrollY { get; set; } = 0.0f;

	public float X => 0.0f;
	public float Y => 0.0f;
	public float GlobalX => 0.0f;
	public float GlobalY => 0.0f;
	public float ScrollX => 0.0f;

	public bool IsButtonDown(MouseButton button) => mDown[(uint32)button & 7];
	public bool IsButtonPressed(MouseButton button) => mPressed[(uint32)button & 7];
	public bool IsButtonReleased(MouseButton button) => false;

	public void SetDown(MouseButton button, bool value = true) => mDown[(uint32)button & 7] = value;
	public void SetPressed(MouseButton button, bool value = true) => mPressed[(uint32)button & 7] = value;

	public bool RelativeMode => false;
	public void SetRelativeMode(bool enabled) {}
	public bool CursorVisible => true;
	public void SetCursorVisible(bool visible) {}
	public void SetCursor(CursorType cursor) {}
	public void SetGlobalCapture(bool enabled) {}
}
