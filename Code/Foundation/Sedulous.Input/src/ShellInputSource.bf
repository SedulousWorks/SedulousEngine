using System;
using Sedulous.Shell;

namespace Sedulous.Input;

/// The common case: the whole application's devices, straight off the shell.
class ShellInputSource : IInputSourceProvider
{
	private IInputManager mInput;

	/// The manager is BORROWED. A shell outlives the runtime reading from it, and two
	/// owners of one device list is not a thing this can be.
	public this(IInputManager input)
	{
		mInput = input;
	}

	/// Rebinds to another manager, or to none: a shell that restarts hands over a new one
	/// rather than making everything holding a source rebuild.
	public void SetInput(IInputManager input)
	{
		mInput = input;
	}

	public IKeyboard Keyboard => (mInput != null) ? mInput.Keyboard : null;
	public IMouse Mouse => (mInput != null) ? mInput.Mouse : null;
	public ITouch Touch => (mInput != null) ? mInput.Touch : null;
	public int32 GamepadCount => (mInput != null) ? mInput.GamepadCount : 0;
	public IGamepad GetGamepad(int32 index) => (mInput != null) ? mInput.GetGamepad(index) : null;
	public Span<InputEvent> Events => (mInput != null) ? mInput.Events : .();
}
