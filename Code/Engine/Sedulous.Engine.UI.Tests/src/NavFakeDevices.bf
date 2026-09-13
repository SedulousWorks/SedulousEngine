using System;
using Sedulous.Input;
using Sedulous.Shell;

namespace Sedulous.Engine.UI.Tests;

/// One pad behind a provider, for the navigation pump.
///
/// Input.Tests has a fuller set of fakes, but a test project cannot depend on another test
/// project and the nav cases read exactly two things off a pad.
class NavFakeDevices : IInputSourceProvider
{
	public NavFakePad Pad = new .() ~ delete _;

	public IKeyboard Keyboard => null;
	public IMouse Mouse => null;
	public int32 GamepadCount => 1;
	public IGamepad GetGamepad(int32 index) => (index == 0) ? Pad : null;
}
