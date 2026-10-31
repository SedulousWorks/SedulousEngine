using System;
using System.Collections;
using Sedulous.Input;
using Sedulous.Shell;

namespace Sedulous.Engine.GUI.Tests;

/// Fingers a test puts down (normalized over an 800 x 600 screen) and lifts.
class GuiFakeTouch : ITouch
{
	public List<TouchPoint> Points = new .() ~ delete _;

	public int32 TouchCount => (int32)Points.Count;
	public bool HasTouch => !Points.IsEmpty;

	public bool GetTouchPoint(int32 index, out TouchPoint point)
	{
		point = .();
		if ((index < 0) || (index >= Points.Count))
			return false;
		point = Points[index];
		return true;
	}

	public void Put(uint64 id, float x, float y)
	{
		Points.Clear();
		Points.Add(.(id, x / 800.0f, y / 600.0f, 1.0f, x, y));
	}
}

/// The engine's active input source as a test drives it: the mouse, a touch screen when present,
/// and this frame's events.
class GuiFakeDevices : IInputSourceProvider
{
	public GuiFakeMouse FakeMouse = new .() ~ delete _;
	public GuiFakeTouch FakeTouch = new .() ~ delete _;
	/// A touch screen; off, the devices are a desktop's.
	public bool TouchPresent = false;
	public ITouch Touch => TouchPresent ? FakeTouch : null;
	public List<InputEvent> Queue = new .() ~ delete _;

	public IKeyboard Keyboard => null;
	public IMouse Mouse => FakeMouse;
	public int32 GamepadCount => 0;
	public IGamepad GetGamepad(int32 index) => null;
	public Span<InputEvent> Events => Queue;

	/// `key` pressed and let go this frame.
	public void Key(Sedulous.Shell.KeyCode key)
	{
		InputEvent down = .();
		down.Kind = .KeyDown;
		down.Key = key;
		Queue.Add(down);
		var up = down;
		up.Kind = .KeyUp;
		Queue.Add(up);
	}

	/// The frame read: its events gone, the mouse's buttons its last.
	public void EndOfFrame()
	{
		Queue.Clear();
		FakeMouse.WasDown = FakeMouse.Down;
	}
}
