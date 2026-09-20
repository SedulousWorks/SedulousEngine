using System;
using Sedulous.Shell;
using Sedulous.Input;
using Sedulous.UI.Viewport;

namespace Sedulous.Editor.Scene;

/// The game's input, read through the viewport's surface so the run only sees the mouse and
/// keyboard while the viewport has them, and the event stream only while it is focused.
class GameViewportInputSource : IInputSourceProvider
{
	/// Both borrowed.
	public ViewportView Viewport = null;
	public IInputManager ShellInput = null;

	public IKeyboard Keyboard => (Viewport != null) ? Viewport.Keyboard : null;
	public IMouse Mouse => (Viewport != null) ? Viewport.Mouse : null;
	public int32 GamepadCount => (ShellInput != null) ? Math.Min(ShellInput.GamepadCount, InputSurface.MaxGamepads) : 0;

	public IGamepad GetGamepad(int32 index)
	{
		let surface = (Viewport != null) ? Viewport.Surface : null;
		return (surface != null) ? surface.Gamepad(index) : null;
	}

	public ITouch Touch => (Viewport != null) ? Viewport.Touch : null;

	public Span<InputEvent> Events
	{
		get
		{
			let surface = (Viewport != null) ? Viewport.Surface : null;
			if ((surface == null) || !surface.Focused || (ShellInput == null))
				return .();
			return ShellInput.Events;
		}
	}
}
