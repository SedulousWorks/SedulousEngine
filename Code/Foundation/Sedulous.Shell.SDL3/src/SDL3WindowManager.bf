using System;
using System.Collections;
using SDL3;
using Sedulous.Core;
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

	private static SDL_WindowFlags WindowFlags(WindowSettings settings)
	{
		SDL_WindowFlags flags = 0;
		if (settings.Resizable)
			flags |= .SDL_WINDOW_RESIZABLE;
		if (settings.Borderless)
			flags |= .SDL_WINDOW_BORDERLESS;

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
