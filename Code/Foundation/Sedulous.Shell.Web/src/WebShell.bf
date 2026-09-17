using System;
using System.Collections;
using Sedulous.Shell;

namespace Sedulous.Shell.Web;

/// An IShell backed by a single HTML canvas, the browser counterpart of the SDL3 backend.
///
/// The FRAME CADENCE is not here. A browser cannot be blocked, so the loop lives in
/// Sedulous.Runtime.Web, which hands it to requestAnimationFrame; this only pumps when asked,
/// exactly as the desktop shell does.
class WebShell : IShell
{
	private WebWindowManager mWindows ~ delete _;
	private WebInputManager mInput = new .() ~ delete _;
	private WebDialogService mDialogs = new .() ~ delete _;
	private bool mRunning = true;
	private String mClipboard = new .() ~ delete _;
	private delegate bool() mCloseHandler ~ delete _;

	/// The selector defaults to Emscripten's canonical canvas. An app that puts its canvas
	/// somewhere else constructs with its own.
	public this(StringView selector = "#canvas", WindowSettings settings = .())
	{
		mWindows = new WebWindowManager(selector, settings);

		if (mWindows.MainWindow != null)
			mInput.RegisterCallbacks(selector, mWindows.MainWindow.Id);
	}

	public IWindowManager WindowManager => mWindows;
	public IWindow MainWindow => mWindows.MainWindow;
	public IInputManager Input => mInput;
	public IDialogService Dialogs => mDialogs;

	/// Rolls the input frame and drains the browser's queue, then polls the canvas size. The
	/// order matters: input first, so a frame's edges are computed before anything reads them.
	public void ProcessEvents()
	{
		mInput.Update();
		mWindows.Pump();
	}

	public bool IsRunning
	{
		get
		{
			let main = mWindows.MainWindow;
			return mRunning && (main != null) && main.IsOpen;
		}
	}

	public void RequestExit() => mRunning = false;

	/// TAKES OWNERSHIP of the handler, replacing any previous one.
	public void SetMainWindowCloseHandler(delegate bool() handler)
	{
		delete mCloseHandler;
		mCloseHandler = handler;
	}

	/// Asked before the main window closes. Nothing in a browser requests that close today,
	/// since a tab closing gives no chance to refuse, but the handler is kept so an app can
	/// drive its own exit through RequestExit on the same path the desktop uses.
	public bool RequestMainWindowClose()
	{
		if (mCloseHandler == null)
			return true;
		return mCloseHandler();
	}

	/// Drag and drop onto a canvas is a DOM listener this shell does not register yet.
	public void DrainDroppedFiles(List<DroppedFile> outFiles) {}

	/// An in memory clipboard.
	///
	/// The real one is navigator.clipboard, which is asynchronous and permission gated, so it
	/// cannot answer a synchronous Get at all. This round trips within the page, which is what
	/// a cut, copy and paste inside the app needs; crossing into another tab does not work.
	public void SetClipboardText(StringView text) => mClipboard.Set(text);
	public void GetClipboardText(String outText) => outText.Set(mClipboard);
	public bool HasClipboardText => !mClipboard.IsEmpty;
}
