using System;
using Sedulous.Shell;
using Sedulous.Input;

namespace Sedulous.Engine.Input.Tests;

/// A source that reports nothing, standing in for one viewport's gated facades.
///
/// The cases below compare source IDENTITY and never read a device, so the whole fake is
/// the interface's defaults. Input.Tests has a fuller one, but reaching across two test
/// projects for it would cost more than this.
class StubSource : IInputSourceProvider
{
	public IKeyboard Keyboard => null;
	public IMouse Mouse => null;
	public int32 GamepadCount => 0;
	public IGamepad GetGamepad(int32 index) => null;
}
