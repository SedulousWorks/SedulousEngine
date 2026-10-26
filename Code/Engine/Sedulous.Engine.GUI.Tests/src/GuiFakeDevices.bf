using System;
using System.Collections;
using Sedulous.Input;
using Sedulous.Shell;

namespace Sedulous.Engine.GUI.Tests;

/// The engine's active input source as a test drives it: the mouse, and this frame's events.
class GuiFakeDevices : IInputSourceProvider
{
	public GuiFakeMouse FakeMouse = new .() ~ delete _;
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
