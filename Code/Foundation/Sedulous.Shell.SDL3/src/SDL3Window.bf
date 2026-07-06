using System;
using SDL3;
using Sedulous.Shell;
using Sedulous.Surface;

namespace Sedulous.Shell.SDL3;

/// SDL3 implementation of a window.
class SDL3Window : IWindow
{
	private SDL_Window* mWindow;
	private uint32 mID;
	private String mTitle = new .() ~ delete _;

	public uint32 ID => mID;

	public SDL_Window* Handle => mWindow;

	public StringView Title
	{
		get => mTitle;
		set
		{
			mTitle.Set(value);
			SDL_SetWindowTitle(mWindow, mTitle.CStr());
		}
	}

	public int32 X
	{
		get
		{
			int32 x = 0, y = 0;
			SDL_GetWindowPosition(mWindow, &x, &y);
			return x;
		}
		set
		{
			SDL_SetWindowPosition(mWindow, value, Y);
		}
	}

	public int32 Y
	{
		get
		{
			int32 x = 0, y = 0;
			SDL_GetWindowPosition(mWindow, &x, &y);
			return y;
		}
		set
		{
			SDL_SetWindowPosition(mWindow, X, value);
		}
	}

	public int32 Width
	{
		get
		{
			int32 w = 0, h = 0;
			SDL_GetWindowSize(mWindow, &w, &h);
			return w;
		}
		set
		{
			SDL_SetWindowSize(mWindow, value, Height);
		}
	}

	public int32 Height
	{
		get
		{
			int32 w = 0, h = 0;
			SDL_GetWindowSize(mWindow, &w, &h);
			return h;
		}
		set
		{
			SDL_SetWindowSize(mWindow, Width, value);
		}
	}

	public WindowState State
	{
		get
		{
			let flags = SDL_GetWindowFlags(mWindow);
			if (flags.HasFlag(.SDL_WINDOW_FULLSCREEN))
				return .Fullscreen;
			if (flags.HasFlag(.SDL_WINDOW_MINIMIZED))
				return .Minimized;
			if (flags.HasFlag(.SDL_WINDOW_MAXIMIZED))
				return .Maximized;
			return .Normal;
		}
	}

	public bool Visible
	{
		get => !SDL_GetWindowFlags(mWindow).HasFlag(.SDL_WINDOW_HIDDEN);
		set
		{
			if (value)
				SDL_ShowWindow(mWindow);
			else
				SDL_HideWindow(mWindow);
		}
	}

	public bool Focused => SDL_GetWindowFlags(mWindow).HasFlag(.SDL_WINDOW_INPUT_FOCUS);

	public float ContentScale => SDL_GetWindowDisplayScale(mWindow);

#if !BF_PLATFORM_WINDOWS
	// SDL3 can pick either Wayland or X11 at runtime (e.g. on Arch it may choose
	// Wayland even when DISPLAY is set), so detect the active driver by name.
	private static bool IsWayland()
	{
		let driver = SDL_GetCurrentVideoDriver();
		return driver != null && StringView(driver) == "wayland";
	}
#endif

	public SurfaceInfo SurfaceInfo
	{
		get
		{
			let props = SDL_GetWindowProperties(mWindow);
#if BF_PLATFORM_WINDOWS
			return .FromWin32(SDL_GetPointerProperty(props, SDL_PROP_WINDOW_WIN32_HWND_POINTER, null));
#else
			if (IsWayland())
			{
				return .FromWayland(
					SDL_GetPointerProperty(props, SDL_PROP_WINDOW_WAYLAND_DISPLAY_POINTER, null),
					SDL_GetPointerProperty(props, SDL_PROP_WINDOW_WAYLAND_SURFACE_POINTER, null));
			}
			// X11 Window is an XID (integer), not a pointer.
			return .FromX11(
				SDL_GetPointerProperty(props, SDL_PROP_WINDOW_X11_DISPLAY_POINTER, null),
				(uint64)SDL_GetNumberProperty(props, SDL_PROP_WINDOW_X11_WINDOW_NUMBER, 0));
#endif
		}
	}

	public this(SDL_Window* window, StringView title)
	{
		mWindow = window;
		mID = SDL_GetWindowID(window);
		mTitle.Set(title);
	}

	public void Show()
	{
		SDL_ShowWindow(mWindow);
	}

	public void Hide()
	{
		SDL_HideWindow(mWindow);
	}

	public void Minimize()
	{
		SDL_MinimizeWindow(mWindow);
	}

	public void Maximize()
	{
		SDL_MaximizeWindow(mWindow);
	}

	public void Restore()
	{
		SDL_RestoreWindow(mWindow);
	}

	public void Close()
	{
		// Send a close request event
		SDL_Event e = .();
		e.type = (uint32)SDL_EventType.SDL_EVENT_WINDOW_CLOSE_REQUESTED;
		e.window.windowID = mID;
		SDL_PushEvent(&e);
	}

	public void SetFullscreen(bool fullscreen)
	{
		SDL_SetWindowFullscreen(mWindow, fullscreen);
	}

	/// Destroys the SDL window.
	public void Destroy()
	{
		if (mWindow != null)
		{
			SDL_DestroyWindow(mWindow);
			mWindow = null;
		}
	}
}
