using System;
using Sedulous.Shell;
using Sedulous.Input;

namespace Sedulous.Editor.Play;

/// The game's input, read through the viewport's surface so the run only sees the mouse while it
/// hovers the viewport, and the keys, gamepads and event stream only while the viewport is the
/// GUI's focused node: a field elsewhere in the editor types without the game reading it (one app
/// keyboard).
class GameViewportInputSource : IInputSourceProvider
{
	/// Both borrowed.
	public Sedulous.GUI.Viewport Viewport = null;
	public IInputManager ShellInput = null;

	public IKeyboard Keyboard => ((Viewport != null) && Viewport.IsFocused) ? Viewport.Keyboard : null;
	public IMouse Mouse => (Viewport != null) ? Viewport.Mouse : null;
	public int32 GamepadCount => (ShellInput != null) ? Math.Min(ShellInput.GamepadCount, InputSurface.MaxGamepads) : 0;

	public IGamepad GetGamepad(int32 index)
	{
		let surface = FocusedSurface;
		return (surface != null) ? surface.Gamepad(index) : null;
	}

	public ITouch Touch => (Viewport != null) ? Viewport.Touch : null;

	public Span<InputEvent> Events
	{
		get
		{
			// Key and text events stream only while the viewport owns the keyboard: the same gate
			// the surface's keyboard applies to the polled reads.
			let surface = FocusedSurface;
			if ((surface == null) || !surface.Focused || (ShellInput == null))
				return .();
			return ShellInput.Events;
		}
	}

	/// The viewport's surface while the viewport is the GUI's focused node; else null.
	private InputSurface FocusedSurface => ((Viewport != null) && Viewport.IsFocused) ? Viewport.HostedSurface : null;
}
