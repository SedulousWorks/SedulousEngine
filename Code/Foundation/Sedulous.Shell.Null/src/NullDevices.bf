using System;
using Sedulous.Shell;

namespace Sedulous.Shell.Null;

/// Devices that report nothing.
///
/// They exist so a headless caller can use Input uniformly with no null checks. A shell
/// whose Input returned null would push that check into every consumer, and the one that
/// forgets it crashes only on the headless path.
class NullKeyboard : IKeyboard
{
	public bool IsKeyDown(KeyCode key) => false;
	public bool IsKeyPressed(KeyCode key) => false;
	public bool IsKeyReleased(KeyCode key) => false;
	public KeyModifiers Modifiers => .None;
}

class NullMouse : IMouse
{
	public float X => 0.0f;
	public float Y => 0.0f;
	public float GlobalX => 0.0f;
	public float GlobalY => 0.0f;
	public float DeltaX => 0.0f;
	public float DeltaY => 0.0f;
	public float ScrollX => 0.0f;
	public float ScrollY => 0.0f;

	public bool IsButtonDown(MouseButton button) => false;
	public bool IsButtonPressed(MouseButton button) => false;
	public bool IsButtonReleased(MouseButton button) => false;

	public bool RelativeMode => false;
	public void SetRelativeMode(bool enabled) {}
	/// Visible, because that is the state a headless run is notionally in and a consumer
	/// asking is usually deciding whether to draw its own cursor.
	public bool CursorVisible => true;
	public void SetCursorVisible(bool visible) {}
	public void SetCursor(CursorType cursor) {}
	public void SetGlobalCapture(bool enabled) {}
}

class NullTouch : ITouch
{
	public int32 TouchCount => 0;
	public bool HasTouch => false;

	public bool GetTouchPoint(int32 index, out TouchPoint point)
	{
		point = default;
		return false;
	}
}

class NullInputManager : IInputManager
{
	private NullKeyboard mKeyboard = new .() ~ delete _;
	private NullMouse mMouse = new .() ~ delete _;
	private NullTouch mTouch = new .() ~ delete _;

	public IKeyboard Keyboard => mKeyboard;
	public IMouse Mouse => mMouse;
	public ITouch Touch => mTouch;

	public int32 GamepadCount => 0;
	public IGamepad GetGamepad(int32 index) => null;

	public Span<InputEvent> Events => .();
	public uint32 HoverWindow => 0;
	public uint32 FocusedWindow => 0;

	public void Update() {}
}
