using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Shell;

namespace Sedulous.Shell.Null;

/// A fully working window manager with no operating system behind it.
///
/// Headless does not mean inert: creation, destruction, the deferred flush and main window
/// tracking all behave exactly as a real backend must, which is what lets multi window
/// logic be tested without a display.
class NullWindowManager : IWindowManager
{
	private List<NullWindow> mOwned = new .() ~ DeleteContainerAndItems!(_);
	/// Borrowed, parallel to the owned list, so Windows can hand back a span of the
	/// interface type.
	private List<IWindow> mLive = new .() ~ delete _;
	private List<uint32> mPendingDestroy = new .() ~ delete _;
	/// Always empty: there is no OS to raise events.
	private List<WindowEvent> mEvents = new .() ~ delete _;

	private uint32 mNextId = 1;
	private uint32 mMainWindowId;

	public this(WindowSettings main)
	{
		CreateWindow(main).IgnoreError();
	}

	public Result<IWindow, ErrorCode> CreateWindow(WindowSettings settings)
	{
		let id = mNextId++;
		let window = new NullWindow(id, settings);
		mOwned.Add(window);
		mLive.Add(window);

		if (mMainWindowId == 0)
			mMainWindowId = id;

		return .Ok(window);
	}

	public void DestroyWindow(IWindow window)
	{
		// Only what this manager owns, and matched by IDENTITY rather than id: a window
		// from another manager can carry the same id, and acting on it would corrupt the
		// bookkeeping of both.
		if (!Owns(window))
			return;

		window.Close();
		mPendingDestroy.Add(window.Id);
	}

	public Span<IWindow> Windows => .(mLive.Ptr, mLive.Count);

	/// Tracked by id, so destroying the main window never promotes another into its place.
	public IWindow MainWindow => GetWindow(mMainWindowId);

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

	public void FlushDestroyed()
	{
		for (let id in mPendingDestroy)
		{
			for (int i < mLive.Count)
			{
				if (mLive[i].Id == id)
				{
					mLive.RemoveAt(i);
					break;
				}
			}
			for (int i < mOwned.Count)
			{
				if (mOwned[i].Id == id)
				{
					delete mOwned[i];
					mOwned.RemoveAt(i);
					break;
				}
			}
		}
		mPendingDestroy.Clear();
	}

	private bool Owns(IWindow window)
	{
		if (window == null)
			return false;
		for (let live in mLive)
		{
			if (live === window)
				return true;
		}
		return false;
	}
}
