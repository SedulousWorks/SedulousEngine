using System;
using System.Collections;
using Sedulous.Shell;

namespace Sedulous.Input.Tests;

/// Every synthetic device behind one provider.
class FakeDevices : IInputSourceProvider
{
	public FakeKeyboard FakeKeyboard = new .() ~ delete _;
	public FakeMouse FakeMouse = new .() ~ delete _;
	public FakeTouch FakeTouch = new .() ~ delete _;
	public List<FakeGamepad> Pads = new .() ~ DeleteContainerAndItems!(_);

	public IKeyboard Keyboard => FakeKeyboard;
	public IMouse Mouse => FakeMouse;
	public ITouch Touch => FakeTouch;
	public int32 GamepadCount => (int32)Pads.Count;

	public IGamepad GetGamepad(int32 index)
		=> ((index >= 0) && (index < (int32)Pads.Count)) ? Pads[index] : null;

	/// Adds a pad reporting the index it sits at, which is what a device filtered binding
	/// matches against.
	public FakeGamepad AddPad()
	{
		let pad = new FakeGamepad();
		pad.Index = (int32)Pads.Count;
		Pads.Add(pad);
		return pad;
	}
}
