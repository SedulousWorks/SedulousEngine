using System;
using System.Collections;
using Sedulous.Shell;

namespace Sedulous.Shell.Tests;

/// A mouse a test drives directly. Every field is public so a test reads like the state it
/// is describing rather than a sequence of setters.
class FakeMouse : IMouse
{
	public float PosX;
	public float PosY;
	public float GlobalPosX;
	public float GlobalPosY;
	public float MoveX;
	public float MoveY;
	public float WheelX;
	public float WheelY;

	public bool[5] Down;
	public bool[5] Pressed;
	public bool[5] Released;

	public bool Relative;
	public bool Visible = true;
	public CursorType LastCursor = .Default;
	public bool GlobalCapture;

	public float X => PosX;
	public float Y => PosY;
	public float GlobalX => GlobalPosX;
	public float GlobalY => GlobalPosY;
	public float DeltaX => MoveX;
	public float DeltaY => MoveY;
	public float ScrollX => WheelX;
	public float ScrollY => WheelY;

	public bool IsButtonDown(MouseButton button) => Down[(int)button];
	public bool IsButtonPressed(MouseButton button) => Pressed[(int)button];
	public bool IsButtonReleased(MouseButton button) => Released[(int)button];

	public bool RelativeMode => Relative;
	public void SetRelativeMode(bool enabled) => Relative = enabled;
	public bool CursorVisible => Visible;
	public void SetCursorVisible(bool visible) => Visible = visible;
	public void SetCursor(CursorType cursor) => LastCursor = cursor;
	public void SetGlobalCapture(bool enabled) => GlobalCapture = enabled;

	/// Presses a button: down and pressed this frame.
	public void Press(MouseButton button)
	{
		Down[(int)button] = true;
		Pressed[(int)button] = true;
		Released[(int)button] = false;
	}

	/// Releases a button: up, and released this frame.
	public void Release(MouseButton button)
	{
		Down[(int)button] = false;
		Pressed[(int)button] = false;
		Released[(int)button] = true;
	}

	/// Clears the edges, the way a real frame roll would, leaving the held state.
	public void NextFrame()
	{
		for (int i < 5)
		{
			Pressed[i] = false;
			Released[i] = false;
		}
		MoveX = 0; MoveY = 0; WheelX = 0; WheelY = 0;
	}
}

class FakeKeyboard : IKeyboard
{
	public HashSet<KeyCode> DownKeys = new .() ~ delete _;
	public HashSet<KeyCode> PressedKeys = new .() ~ delete _;
	public HashSet<KeyCode> ReleasedKeys = new .() ~ delete _;
	public KeyModifiers Mods = .None;

	public bool IsKeyDown(KeyCode key) => DownKeys.Contains(key);
	public bool IsKeyPressed(KeyCode key) => PressedKeys.Contains(key);
	public bool IsKeyReleased(KeyCode key) => ReleasedKeys.Contains(key);
	public KeyModifiers Modifiers => Mods;
}

class FakeGamepad : IGamepad
{
	public int32 DeviceIndex;
	public String DeviceName = new .("Fake Pad") ~ delete _;
	public bool IsConnected = true;
	public HashSet<GamepadButton> DownButtons = new .() ~ delete _;
	public float[6] Axes;

	public float LastRumbleLow;
	public float LastRumbleHigh;
	public uint32 LastRumbleMs;

	public int32 Index => DeviceIndex;
	public StringView Name => DeviceName;
	public bool Connected => IsConnected;

	public bool IsButtonDown(GamepadButton button) => DownButtons.Contains(button);
	public bool IsButtonPressed(GamepadButton button) => DownButtons.Contains(button);
	public bool IsButtonReleased(GamepadButton button) => false;
	public float Axis(GamepadAxis axis) => Axes[(int)axis];

	public void SetRumble(float lowFrequency, float highFrequency, uint32 durationMs)
	{
		LastRumbleLow = lowFrequency;
		LastRumbleHigh = highFrequency;
		LastRumbleMs = durationMs;
	}
}

class FakeTouch : ITouch
{
	public List<TouchPoint> Points = new .() ~ delete _;

	public int32 TouchCount => (int32)Points.Count;
	public bool HasTouch => !Points.IsEmpty;

	public bool GetTouchPoint(int32 index, out TouchPoint point)
	{
		if ((index < 0) || (index >= (int32)Points.Count))
		{
			point = default;
			return false;
		}
		point = Points[index];
		return true;
	}
}

class FakeInputManager : IInputManager
{
	public FakeMouse MouseDevice = new .() ~ delete _;
	public FakeKeyboard KeyboardDevice = new .() ~ delete _;
	public FakeTouch TouchDevice = new .() ~ delete _;
	public List<FakeGamepad> Gamepads = new .() ~ DeleteContainerAndItems!(_);
	public List<InputEvent> EventList = new .() ~ delete _;

	public uint32 Hover;
	public uint32 Focus;
	public int32 Updates;

	public IKeyboard Keyboard => KeyboardDevice;
	public IMouse Mouse => MouseDevice;
	public ITouch Touch => TouchDevice;

	public int32 GamepadCount => (int32)Gamepads.Count;
	public IGamepad GetGamepad(int32 index)
		=> ((index >= 0) && (index < (int32)Gamepads.Count)) ? Gamepads[index] : null;

	public Span<InputEvent> Events => .(EventList.Ptr, EventList.Count);
	public uint32 HoverWindow => Hover;
	public uint32 FocusedWindow => Focus;

	public void Update()
	{
		Updates++;
		MouseDevice.NextFrame();
		EventList.Clear();
	}
}
