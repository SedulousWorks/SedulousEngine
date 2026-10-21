using System;
using System.Collections;
using SDL3;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Shell;

namespace Sedulous.Shell.SDL3;

/// Owns every window for the run.
///
/// Destruction is DEFERRED to FlushDestroyed rather than done on request, because a window
/// closed mid frame may still have a swapchain the GPU is reading. The host flushes at a
/// point it knows is safe.
class SDL3WindowManager : IWindowManager
{
	private List<SDL3Window> mOwned = new .() ~ DeleteContainerAndItems!(_);
	private List<IWindow> mLive = new .() ~ delete _;
	private List<uint32> mPendingDestroy = new .() ~ delete _;
	private List<WindowEvent> mEvents = new .() ~ delete _;
	private List<Screen> mScreens = new .() ~ delete _;
	/// The screens' names, which the screens borrow.
	private List<String> mScreenNames = new .() ~ DeleteContainerAndItems!(_);
	/// The first window created. Zero means none.
	private uint32 mMainWindowId;

	public Result<IWindow, ErrorCode> CreateWindow(WindowSettings settings)
	{
		let title = scope String(settings.Title);
		let handle = SDL3.SDL_CreateWindow(title, (int32)settings.Width, (int32)settings.Height,
			WindowFlags(settings));
		if (handle == null)
			return .Err(.Internal);

		if (settings.Positioned)
			SDL3.SDL_SetWindowPosition(handle, settings.X, settings.Y);
		ApplyFullscreen(handle, settings);

		let window = new SDL3Window(handle);
		mOwned.Add(window);
		mLive.Add(window);
		if (mMainWindowId == 0)
			mMainWindowId = window.Id;
		return .Ok(window);
	}

	/// Queued, not freed. By POINTER identity, not id: a window from another manager can
	/// share an id, and acting on that would corrupt this one's bookkeeping.
	public void DestroyWindow(IWindow window)
	{
		if (!Owns(window))
			return;
		let id = window.Id;
		if (!mPendingDestroy.Contains(id))
			mPendingDestroy.Add(id);
	}

	public Span<IWindow> Windows => .(mLive.Ptr, mLive.Count);

	public IWindow MainWindow => (mMainWindowId != 0) ? GetWindow(mMainWindowId) : null;

	public IWindow GetWindow(uint32 id)
	{
		for (let window in mLive)
		{
			if (window.Id == id)
				return window;
		}
		return null;
	}

	public Span<WindowEvent> Events => .(mEvents.Ptr, mEvents.Count);

	public Span<Screen> Screens => .(mScreens.Ptr, mScreens.Count);

	/// Any number of windows; placed by the application, and the global pointer read, except
	/// on Wayland, where a client does neither (the compositor places windows).
	public WindowCapabilities Capabilities
	{
		get
		{
			let driver = StringView(SDL3.SDL_GetCurrentVideoDriver());
			let wayland = (driver.Ptr != null) && (driver == "wayland");
			return .(true, !wayland);
		}
	}

	/// Reads the screens again: at start, and when the pump sees a display event.
	public void ReadScreens()
	{
		mScreens.Clear();
		ClearAndDeleteItems!(mScreenNames);
		int32 count = 0;
		let displays = SDL3.SDL_GetDisplays(&count);
		if (displays == null)
			return;
		defer SDL3.SDL_free(displays);
		let primary = SDL3.SDL_GetPrimaryDisplay();
		for (int i < count)
		{
			SDL_Rect bounds = default;
			if (!SDL3.SDL_GetDisplayBounds(displays[i], &bounds))
				continue;
			var usable = bounds;
			SDL3.SDL_GetDisplayUsableBounds(displays[i], &usable);

			var screen = Screen();
			screen.Id = (uint32)displays[i];
			let name = new String();
			if (let text = SDL3.SDL_GetDisplayName(displays[i]))
				name.Append(text);
			mScreenNames.Add(name);
			screen.Name = name;
			screen.X = bounds.x;
			screen.Y = bounds.y;
			screen.Width = (uint32)bounds.w;
			screen.Height = (uint32)bounds.h;
			screen.UsableX = usable.x;
			screen.UsableY = usable.y;
			screen.UsableWidth = (uint32)usable.w;
			screen.UsableHeight = (uint32)usable.h;
			let scale = SDL3.SDL_GetDisplayContentScale(displays[i]);
			screen.Scale = (scale > 0.0f) ? scale : 1.0f; // 0 when the system does not say
			screen.Primary = displays[i] == primary;
			mScreens.Add(screen);
		}
	}

	/// Frees what was queued. Called by the host at a point it knows no frame is still
	/// referencing the window.
	public void FlushDestroyed()
	{
		for (let id in mPendingDestroy)
		{
			for (int i = mLive.Count - 1; i >= 0; i--)
			{
				if (mLive[i].Id == id)
					mLive.RemoveAt(i);
			}
			for (int i = mOwned.Count - 1; i >= 0; i--)
			{
				if (mOwned[i].Id == id)
				{
					delete mOwned[i];
					mOwned.RemoveAt(i);
				}
			}
			if (mMainWindowId == id)
				mMainWindowId = 0;
		}
		mPendingDestroy.Clear();
	}

	/// The backing window for an id, for the pump.
	public SDL3Window Find(uint32 id)
	{
		for (let window in mOwned)
		{
			if (window.Id == id)
				return window;
		}
		return null;
	}

	public void ClearEvents() => mEvents.Clear();
	public void PushEvent(WindowEvent e) => mEvents.Add(e);

	/// Destroys everything NOW, which the shell does before shutting SDL down: a window
	/// destroyed after SDL_Quit calls into a torn down subsystem.
	public void DestroyAllNow()
	{
		mLive.Clear();
		ClearAndDeleteItems!(mOwned);
		mPendingDestroy.Clear();
		mMainWindowId = 0;
	}

	private bool Owns(IWindow window)
	{
		if (window == null)
			return false;
		for (let owned in mOwned)
		{
			if (owned === window)
				return true;
		}
		return false;
	}

	/// Exclusive takes the display mode closest to the window's size; desktop fullscreen is
	/// SDL's fullscreen with no mode, the display left as it is. Loud and windowed when the
	/// display refuses.
	private static void ApplyFullscreen(SDL_Window* handle, WindowSettings settings)
	{
		if (settings.Fullscreen == .None)
			return;
		if (settings.Fullscreen == .Exclusive)
		{
			SDL_DisplayMode mode = default;
			if (SDL3.SDL_GetClosestFullscreenDisplayMode(SDL3.SDL_GetPrimaryDisplay(), (int32)settings.Width,
				(int32)settings.Height, 0.0f, true, &mode))
				SDL3.SDL_SetWindowFullscreenMode(handle, &mode);
			else
				GlobalLog(.Warning, "Shell: no fullscreen mode near {}x{}; the desktop's is used", settings.Width, settings.Height);
		}
		else
		{
			SDL3.SDL_SetWindowFullscreenMode(handle, null);
		}
		if (!SDL3.SDL_SetWindowFullscreen(handle, true))
			GlobalLog(.Warning, "Shell: fullscreen refused; the window stays windowed");
	}

	private static SDL_WindowFlags WindowFlags(WindowSettings settings)
	{
		SDL_WindowFlags flags = 0;
		if (settings.Resizable)
			flags |= .SDL_WINDOW_RESIZABLE;
		if (settings.Borderless)
			flags |= .SDL_WINDOW_BORDERLESS;
		if (settings.Hidden)
			flags |= .SDL_WINDOW_HIDDEN;
		if (settings.SoftwareSurface)
			return flags; // drawn through SDL's window surface: no Vulkan surface on it

#if !BF_PLATFORM_WINDOWS && !BF_PLATFORM_MACOS
		// SDL only attaches client side decorations to a window backed by a GPU surface, so
		// a plain window comes up with no title bar at all under GNOME. Flagging every
		// window as Vulkan is what puts the decorations back. Skipped under the headless
		// driver, which has no Vulkan to ask for.
		let driver = StringView(SDL3.SDL_GetCurrentVideoDriver());
		if ((driver.Ptr != null) && (driver != "dummy"))
			flags |= .SDL_WINDOW_VULKAN;
#endif
		return flags;
	}
}
