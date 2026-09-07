using System;
using SDL3;
using Sedulous.Shell;

namespace Sedulous.Shell.SDL3;

/// One SDL window.
///
/// Width and height are CACHED rather than asked of SDL on every read: they are read every
/// frame by layout and by the swapchain, and the cache is what the resize event updates. A
/// position is not cached, because nothing reads it per frame and the window manager can
/// move a window without telling anyone.
class SDL3Window : IWindow
{
	private SDL_Window* mWindow;
	private uint32 mId;
	private uint32 mWidth;
	private uint32 mHeight;
	private bool mOpen = true;
	private bool mTextInputActive;

	public this(SDL_Window* window)
	{
		mWindow = window;
		mId = (uint32)SDL3.SDL_GetWindowID(window);

		int32 width = 0, height = 0;
		SDL3.SDL_GetWindowSize(window, &width, &height);
		mWidth = (uint32)width;
		mHeight = (uint32)height;
	}

	public ~this()
	{
		if (mWindow != null)
			SDL3.SDL_DestroyWindow(mWindow);
	}

	public SDL_Window* Handle => mWindow;

	public uint32 Id => mId;
	public uint32 Width => mWidth;
	public uint32 Height => mHeight;

	public int32 X
	{
		get
		{
			int32 x = 0, y = 0;
			if (mWindow != null)
				SDL3.SDL_GetWindowPosition(mWindow, &x, &y);
			return x;
		}
	}

	public int32 Y
	{
		get
		{
			int32 x = 0, y = 0;
			if (mWindow != null)
				SDL3.SDL_GetWindowPosition(mWindow, &x, &y);
			return y;
		}
	}

	public void SetPosition(int32 x, int32 y)
	{
		if (mWindow != null)
			SDL3.SDL_SetWindowPosition(mWindow, x, y);
	}

	/// Updates the cached size as well as asking SDL, so a caller that resizes and then
	/// reads back sees what it asked for without waiting for the event to come round.
	public void SetSize(uint32 width, uint32 height)
	{
		if (mWindow == null)
			return;
		SDL3.SDL_SetWindowSize(mWindow, (int32)width, (int32)height);
		mWidth = width;
		mHeight = height;
	}

	/// Floored at one.
	///
	/// SDL reports zero before a window has been shown, and a scale of zero collapses every
	/// measurement taken from it to nothing.
	public float ContentScale
	{
		get
		{
			if (mWindow == null)
				return 1.0f;
			let scale = SDL3.SDL_GetWindowDisplayScale(mWindow);
			return (scale > 0.0f) ? scale : 1.0f;
		}
	}

	/// The handles a graphics backend needs, pulled out of SDL's window properties.
	///
	/// Read from the properties rather than through SDL's own surface helpers, because the
	/// backend creates its surface itself and needs the raw handles to do it.
	public NativeWindow Native
	{
		get
		{
			var native = NativeWindow();
			if (mWindow == null)
				return native;

			let props = SDL3.SDL_GetWindowProperties(mWindow);
#if BF_PLATFORM_WINDOWS
			native.System = .Win32;
			native.Display = SDL3.SDL_GetPointerProperty(props, SDL3.SDL_PROP_WINDOW_WIN32_INSTANCE_POINTER, null);
			native.Window = SDL3.SDL_GetPointerProperty(props, SDL3.SDL_PROP_WINDOW_WIN32_HWND_POINTER, null);
#elif BF_PLATFORM_MACOS
			native.System = .Cocoa;
			native.Window = SDL3.SDL_GetPointerProperty(props, SDL3.SDL_PROP_WINDOW_COCOA_WINDOW_POINTER, null);
#else
			// Which of the two it is cannot be decided at compile time: one binary serves
			// both, and the driver is chosen at run time.
			let driver = StringView(SDL3.SDL_GetCurrentVideoDriver());
			if (driver == "wayland")
			{
				native.System = .Wayland;
				native.Display = SDL3.SDL_GetPointerProperty(props, SDL3.SDL_PROP_WINDOW_WAYLAND_DISPLAY_POINTER, null);
				native.Window = SDL3.SDL_GetPointerProperty(props, SDL3.SDL_PROP_WINDOW_WAYLAND_SURFACE_POINTER, null);
			}
			else if (driver == "x11")
			{
				native.System = .X11;
				native.Display = SDL3.SDL_GetPointerProperty(props, SDL3.SDL_PROP_WINDOW_X11_DISPLAY_POINTER, null);
				// X11 hands back a numeric XID, not a pointer.
				native.Window = (void*)(int)SDL3.SDL_GetNumberProperty(props, SDL3.SDL_PROP_WINDOW_X11_WINDOW_NUMBER, 0);
			}
#endif
			return native;
		}
	}

	public bool IsOpen => mOpen;

	public bool IsMinimized
	{
		get
		{
			if (mWindow == null)
				return false;
			return (SDL3.SDL_GetWindowFlags(mWindow) & .SDL_WINDOW_MINIMIZED) != 0;
		}
	}

	/// Marks it closed WITHOUT destroying it. The manager destroys it later, because a
	/// swapchain recorded against it may still be in flight.
	public void Close() => mOpen = false;

	/// Guarded on the current state, because SDL counts these and an unbalanced stop leaves
	/// the input method on.
	public void StartTextInput()
	{
		if ((mWindow != null) && !mTextInputActive)
		{
			SDL3.SDL_StartTextInput(mWindow);
			mTextInputActive = true;
		}
	}

	public void StopTextInput()
	{
		if ((mWindow != null) && mTextInputActive)
		{
			SDL3.SDL_StopTextInput(mWindow);
			mTextInputActive = false;
		}
	}

	public bool IsTextInputActive => mTextInputActive;

	/// Called by the pump when SDL reports a resize.
	public void OnResized(uint32 width, uint32 height)
	{
		mWidth = width;
		mHeight = height;
	}
}
