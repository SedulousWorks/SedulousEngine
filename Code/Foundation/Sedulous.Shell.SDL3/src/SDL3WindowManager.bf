using System;
using System.Collections;
using SDL3;
using Sedulous.Shell;
using Sedulous.Core;

namespace Sedulous.Shell.SDL3;

/// SDL3 implementation of window management.
class SDL3WindowManager : IWindowManager
{
	private Dictionary<uint32, SDL3Window> mWindows = new .() ~ delete _;
	private EventAccessor<WindowEventDelegate> mOnWindowEvent = new .() ~ delete _;

	public int WindowCount => mWindows.Count;

	public EventAccessor<WindowEventDelegate> OnWindowEvent => mOnWindowEvent;

	public Result<IWindow> CreateWindow(WindowSettings settings)
	{
		SDL_WindowFlags flags = .SDL_WINDOW_HIGH_PIXEL_DENSITY;

		if (settings.Resizable)
			flags |= .SDL_WINDOW_RESIZABLE;
		if (!settings.Bordered)
			flags |= .SDL_WINDOW_BORDERLESS;
		if (settings.Maximized)
			flags |= .SDL_WINDOW_MAXIMIZED;
		if (settings.Minimized)
			flags |= .SDL_WINDOW_MINIMIZED;
		if (settings.Fullscreen)
			flags |= .SDL_WINDOW_FULLSCREEN;
		if (settings.Hidden)
			flags |= .SDL_WINDOW_HIDDEN;

		let title = settings.Title != null ? settings.Title.CStr() : "Sedulous";

		// Convert position constants to SDL equivalents
		int32 ConvertPosition(int32 pos)
		{
			if (pos == WindowSettings.Centered)
				return (int32)SDL_WINDOWPOS_CENTERED();
			if (pos == WindowSettings.Undefined)
				return (int32)SDL_WINDOWPOS_UNDEFINED();
			return pos;
		}

		let x = ConvertPosition(settings.X);
		let y = ConvertPosition(settings.Y);

		let sdlWindow = SDL_CreateWindow(title, settings.Width, settings.Height, flags);
		if (sdlWindow == null)
		{
			return .Err;
		}

		// Set position if explicitly specified (not Centered or Undefined)
		bool explicitX = settings.X != WindowSettings.Centered && settings.X != WindowSettings.Undefined;
		bool explicitY = settings.Y != WindowSettings.Centered && settings.Y != WindowSettings.Undefined;
		if (explicitX || explicitY)
		{
			SDL_SetWindowPosition(sdlWindow, x, y);
		}

		let window = new SDL3Window(sdlWindow, settings.Title != null ? settings.Title : "Sedulous");
		mWindows[window.ID] = window;

		return .Ok(window);
	}

	public void DestroyWindow(IWindow window)
	{
		if (let sdlWindow = window as SDL3Window)
		{
			mWindows.Remove(sdlWindow.ID);
			sdlWindow.Destroy();
			delete sdlWindow;
		}
	}

	public IWindow GetWindow(uint32 id)
	{
		if (mWindows.TryGetValue(id, let window))
			return window;
		return null;
	}

	/// Gets the SDL3Window for a window ID.
	public SDL3Window GetSDL3Window(uint32 id)
	{
		if (mWindows.TryGetValue(id, let window))
			return window;
		return null;
	}

	/// Handles an SDL window event.
	public void HandleWindowEvent(SDL_WindowEvent* e)
	{
		if (!mWindows.TryGetValue(e.windowID, let window))
			return;

		WindowEvent evt = ?;

		switch (e.type)
		{
		case .SDL_EVENT_WINDOW_SHOWN:
			evt = .(WindowEventType.Shown);
		case .SDL_EVENT_WINDOW_HIDDEN:
			evt = .(WindowEventType.Hidden);
		case .SDL_EVENT_WINDOW_EXPOSED:
			evt = .(WindowEventType.Exposed);
		case .SDL_EVENT_WINDOW_MOVED:
			evt = .(WindowEventType.Moved, e.data1, e.data2);
		case .SDL_EVENT_WINDOW_RESIZED:
			evt = .(WindowEventType.Resized, e.data1, e.data2);
		case .SDL_EVENT_WINDOW_MINIMIZED:
			evt = .(WindowEventType.Minimized);
		case .SDL_EVENT_WINDOW_MAXIMIZED:
			evt = .(WindowEventType.Maximized);
		case .SDL_EVENT_WINDOW_RESTORED:
			evt = .(WindowEventType.Restored);
		case .SDL_EVENT_WINDOW_MOUSE_ENTER:
			evt = .(WindowEventType.MouseEnter);
		case .SDL_EVENT_WINDOW_MOUSE_LEAVE:
			evt = .(WindowEventType.MouseLeave);
		case .SDL_EVENT_WINDOW_FOCUS_GAINED:
			evt = .(WindowEventType.FocusGained);
		case .SDL_EVENT_WINDOW_FOCUS_LOST:
			evt = .(WindowEventType.FocusLost);
		case .SDL_EVENT_WINDOW_CLOSE_REQUESTED:
			evt = .(WindowEventType.CloseRequested);
		case .SDL_EVENT_WINDOW_ENTER_FULLSCREEN:
			evt = .(WindowEventType.EnterFullscreen);
		case .SDL_EVENT_WINDOW_LEAVE_FULLSCREEN:
			evt = .(WindowEventType.LeaveFullscreen);
		case .SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED:
			evt = .(WindowEventType.DisplayScaleChanged);
		default:
			return;
		}

		mOnWindowEvent.[Friend]Invoke(window, evt);
	}

	/// Destroys all windows.
	public void DestroyAllWindows()
	{
		for (let window in mWindows.Values)
		{
			window.Destroy();
			delete window;
		}
		mWindows.Clear();
	}
}
