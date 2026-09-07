using System;
using SDL3;
using Sedulous.Shell;

namespace Sedulous.Shell.SDL3.Tests;

/// A headless shell, and the SDL handles a test needs to push synthetic events at it.
///
/// The shell DEGRADES when there is no display rather than failing, so every case has to
/// tolerate a null main window: that is the same path a machine with no display takes, and
/// asserting against it would make the suite depend on the host having a screen.
class ShellFixture
{
	public SDL3Shell Shell ~ delete _;

	public this(WindowSettings settings = .())
	{
		HeadlessDriver.Apply();
		Shell = new SDL3Shell(settings);
	}

	/// True when there is a window to test against. A case that gets false has nothing to
	/// assert and returns.
	public bool Usable => Shell.MainWindow != null;

	public SDL_Window* Handle => ((SDL3Window)Shell.MainWindow).Handle;
	public SDL_WindowID WindowId => SDL3.SDL_GetWindowID(Handle);

	/// Pushes a key event as though SDL had reported it.
	public void PushKey(SDL_Scancode scancode, bool down, SDL_Keymod modifiers = .SDL_KMOD_NONE)
	{
		SDL_Event e = default;
		e.type = (uint32)(down ? SDL_EventType.SDL_EVENT_KEY_DOWN : SDL_EventType.SDL_EVENT_KEY_UP);
		e.key.windowID = WindowId;
		e.key.scancode = scancode;
		e.key.down = down;
		e.key.mod = modifiers;
		SDL3.SDL_PushEvent(&e);
	}

	public void PushMouseMotion(float x, float y, float relativeX, float relativeY)
	{
		SDL_Event e = default;
		e.type = (uint32)SDL_EventType.SDL_EVENT_MOUSE_MOTION;
		e.motion.windowID = WindowId;
		e.motion.x = x;
		e.motion.y = y;
		e.motion.xrel = relativeX;
		e.motion.yrel = relativeY;
		SDL3.SDL_PushEvent(&e);
	}

	/// SDL numbers its buttons from one.
	public void PushMouseButton(uint8 sdlButton, bool down)
	{
		SDL_Event e = default;
		e.type = (uint32)(down ? SDL_EventType.SDL_EVENT_MOUSE_BUTTON_DOWN
			: SDL_EventType.SDL_EVENT_MOUSE_BUTTON_UP);
		e.button.windowID = WindowId;
		e.button.button = sdlButton;
		e.button.down = down;
		SDL3.SDL_PushEvent(&e);
	}

	public void PushWheel(float x, float y)
	{
		SDL_Event e = default;
		e.type = (uint32)SDL_EventType.SDL_EVENT_MOUSE_WHEEL;
		e.wheel.windowID = WindowId;
		e.wheel.x = x;
		e.wheel.y = y;
		SDL3.SDL_PushEvent(&e);
	}

	public void PushWindowClose()
	{
		SDL_Event e = default;
		e.type = (uint32)SDL_EventType.SDL_EVENT_WINDOW_CLOSE_REQUESTED;
		e.window.windowID = WindowId;
		SDL3.SDL_PushEvent(&e);
	}

	public void PushWindowEvent(SDL_EventType type, int32 data1 = 0, int32 data2 = 0)
	{
		SDL_Event e = default;
		e.type = (uint32)type;
		e.window.windowID = WindowId;
		e.window.data1 = data1;
		e.window.data2 = data2;
		SDL3.SDL_PushEvent(&e);
	}
}
