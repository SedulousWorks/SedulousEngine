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
	private TextInputKind mTextInputKind = .Text;

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
	/// the input method on. Started again with another kind, it stops and starts as that kind.
	public void StartTextInput(TextInputKind kind = .Text)
	{
		if ((mWindow == null) || (mTextInputActive && (kind == mTextInputKind)))
			return;
		if (mTextInputActive)
			SDL3.SDL_StopTextInput(mWindow); // another kind: started again as that
		// A secret field tells the platform it is a hidden password: its IME composes nothing there.
		let properties = SDL3.SDL_CreateProperties();
		SDL3.SDL_SetNumberProperty(properties, SDL3.SDL_PROP_TEXTINPUT_TYPE_NUMBER,
			(int64)((kind == .Secret) ? SDL3.SDL_TextInputType.SDL_TEXTINPUT_TYPE_TEXT_PASSWORD_HIDDEN : SDL3.SDL_TextInputType.SDL_TEXTINPUT_TYPE_TEXT));
		SDL3.SDL_StartTextInputWithProperties(mWindow, properties);
		SDL3.SDL_DestroyProperties(properties);
		mTextInputActive = true;
		mTextInputKind = kind;
	}

	public TextInputKind ActiveTextInputKind => mTextInputKind;

	public void SetTextInputArea(int32 x, int32 y, int32 width, int32 height, int32 caretX)
	{
		if (mWindow == null)
			return;
		var area = SDL_Rect() { x = x, y = y, w = width, h = height };
		SDL3.SDL_SetTextInputArea(mWindow, &area, caretX);
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

	public void Show()
	{
		if (mWindow != null)
			SDL3.SDL_ShowWindow(mWindow);
	}

	public void Raise()
	{
		if (mWindow != null)
			SDL3.SDL_RaiseWindow(mWindow);
	}

	public bool PresentPixels(Span<uint8> rgba, uint32 width, uint32 height)
	{
		if ((mWindow == null) || (rgba.Length < (int)width * (int)height * 4))
			return false;
		let target = SDL3.SDL_GetWindowSurface(mWindow);
		if (target == null)
			return false;
		let image = SDL3.SDL_CreateSurfaceFrom((int32)width, (int32)height, .SDL_PIXELFORMAT_RGBA32, rgba.Ptr, (int32)width * 4);
		if (image == null)
			return false;
		// The window's surface may be larger than the image on a scaled display: scale to fit.
		let drawn = ((target.w == (int32)width) && (target.h == (int32)height))
			? SDL3.SDL_BlitSurface(image, null, target, null)
			: SDL3.SDL_BlitSurfaceScaled(image, null, target, null, .SDL_SCALEMODE_LINEAR);
		SDL3.SDL_DestroySurface(image);
		return drawn && SDL3.SDL_UpdateWindowSurface(mWindow);
	}

	public void SetIcon(Span<WindowIconImage> images)
	{
		if ((mWindow == null) || images.IsEmpty || (images[0].Rgba == null))
			return;
		// The surfaces borrow the pixels; SDL copies them when it sets the icon.
		let icon = SurfaceOf(images[0]);
		if (icon == null)
			return;
		for (int i = 1; i < images.Length; i++)
		{
			if (images[i].Rgba == null)
				continue;
			if (let larger = SurfaceOf(images[i]))
			{
				SDL3.SDL_AddSurfaceAlternateImage(icon, larger); // the icon holds its own reference
				SDL3.SDL_DestroySurface(larger);
			}
		}
		SDL3.SDL_SetWindowIcon(mWindow, icon);
		SDL3.SDL_DestroySurface(icon);
	}

	private static SDL_Surface* SurfaceOf(WindowIconImage image) =>
		SDL3.SDL_CreateSurfaceFrom((int32)image.Width, (int32)image.Height, .SDL_PIXELFORMAT_RGBA32, image.Rgba, (int32)image.Width * 4);

	/// Called by the pump when SDL reports a resize.
	public void OnResized(uint32 width, uint32 height)
	{
		mWidth = width;
		mHeight = height;
	}
}
