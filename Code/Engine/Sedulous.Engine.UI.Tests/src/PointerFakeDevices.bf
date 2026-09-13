using System;
using System.Collections;
using Sedulous.Input;
using Sedulous.Shell;

namespace Sedulous.Engine.UI.Tests;

/// A pointer capable provider: a settable mouse for the polled pump plus the tagged event
/// stream, which is the full shape a real source presents.
class PointerFakeDevices : IInputSourceProvider
{
	public PointerFakeMouse FakeMouse = new .() ~ delete _;
	/// False stands in for a pointer less frame, the pad or keyboard only path.
	public bool MousePresent = true;
	public List<InputEvent> Queue = new .() ~ delete _;

	public IKeyboard Keyboard => null;
	public IMouse Mouse => MousePresent ? FakeMouse : null;
	public int32 GamepadCount => 0;
	public IGamepad GetGamepad(int32 index) => null;
	public Span<InputEvent> Events => Queue;

	public void MoveTo(float x, float y)
	{
		FakeMouse.X = x;
		FakeMouse.Y = y;
	}

	public void PressLeft() => FakeMouse.SetButtonDown(.Left, true);
	public void ReleaseLeft() => FakeMouse.SetButtonDown(.Left, false);

	public void PushText(StringView text)
	{
		InputEvent e = .();
		e.Kind = .TextInput;
		int i = 0;
		for (; (i < text.Length) && (i < 31); ++i)
			e.Text[i] = text[i];
		e.Text[i] = 0;
		Queue.Add(e);
	}

	public void PushKey(InputEventKind kind, KeyCode key)
	{
		InputEvent e = .();
		e.Kind = kind;
		e.Key = key;
		Queue.Add(e);
	}
}
