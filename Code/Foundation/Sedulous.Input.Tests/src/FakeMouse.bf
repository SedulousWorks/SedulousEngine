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

	/// What a pointer lock last set, and the SetRelativeMode calls (every one, and those that
	/// changed it).
	public bool Relative = false;
	public int RelativeCalls = 0;
	public int RelativeChanges = 0;
	public bool Visible = true;

	public bool RelativeMode => Relative;
	public void SetRelativeMode(bool enabled)
	{
		RelativeCalls++;
		if (enabled != Relative)
			RelativeChanges++;
		Relative = enabled;
	}
	public bool CursorVisible => Visible;
	public void SetCursorVisible(bool visible) => Visible = visible;
	public void SetCursor(CursorType cursor) {}
	public void SetGlobalCapture(bool enabled) {}
}
