using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Shell;

namespace Sedulous.Shell.Web;

/// One canvas, one window.
///
/// The main window exists from construction and CreateWindow REFUSES: a page has a single
/// WebGPU canvas here, and multi canvas is a later concern. Refusing is better than handing
/// back a second window that nothing can draw into.
///
/// Pump re-polls the canvas size each frame and emits Resized when it moved, because the
/// browser has no OS resize queue for the runner to drain.
class WebWindowManager : IWindowManager
{
	private WebWindow mWindow ~ delete _;
	/// Borrowed, so Windows can hand back a span of the interface type.
	private List<IWindow> mLive = new .() ~ delete _;
	private List<WindowEvent> mEvents = new .() ~ delete _;
	private uint32 mMainWindowId = 1;

	public this(StringView selector, WindowSettings settings)
	{
		mWindow = new WebWindow(mMainWindowId, selector, settings);
		mLive.Add(mWindow);
	}

	public Result<IWindow, ErrorCode> CreateWindow(WindowSettings settings) =>
		.Err(.NotSupported);

	public void DestroyWindow(IWindow window)
	{
		if (window === mWindow)
			mWindow.Close();
	}

	public Span<IWindow> Windows => .(mLive.Ptr, mLive.Count);

	public IWindow MainWindow => ((mWindow != null) && mWindow.IsOpen) ? mWindow : null;

	public IWindow GetWindow(uint32 id) => (id == mMainWindowId) ? mWindow : null;

	public Span<WindowEvent> Events => .(mEvents.Ptr, mEvents.Count);

	/// Nothing is deferred: the one window lives as long as the manager.
	public void FlushDestroyed() {}

	/// Rebuilds this frame's events from a size poll. Called by the shell's ProcessEvents.
	public void Pump()
	{
		mEvents.Clear();
		if ((mWindow == null) || !mWindow.QuerySize())
			return;

		WindowEvent event = .();
		event.Type = .Resized;
		event.WindowId = mMainWindowId;
		event.Width = mWindow.Width;
		event.Height = mWindow.Height;
		mEvents.Add(event);
	}

	public WebWindow Canvas => mWindow;
}
