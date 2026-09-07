using System;
using System.Collections;
using Sedulous.Shell;

namespace Sedulous.Shell.Null;

/// A shell with no operating system behind it, for tests, tools and headless servers.
///
/// Also the reference for what a real backend must provide: everything here behaves, it
/// simply has nothing underneath. Where a backend would pump the OS, this does nothing and
/// leaves the run state to RequestExit and to the main window closing.
class NullShell : IShell
{
	private NullWindowManager mWindows ~ delete _;
	private NullInputManager mInput = new .() ~ delete _;
	private NullDialogService mDialogs = new .() ~ delete _;
	private bool mRunning = true;
	private String mClipboard = new .() ~ delete _;
	private delegate bool() mCloseHandler ~ delete _;

	public this(WindowSettings settings = .())
	{
		mWindows = new NullWindowManager(settings);
	}

	public IWindowManager WindowManager => mWindows;
	public IWindow MainWindow => mWindows.MainWindow;
	public IInputManager Input => mInput;
	public IDialogService Dialogs => mDialogs;

	/// Nothing to pump.
	public void ProcessEvents() {}

	/// Running until an exit is requested or the main window goes.
	///
	/// The main window closing ends the run even though no OS said so, because that is what
	/// a real backend does and a headless test of the shutdown path has to see the same
	/// thing.
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

	/// Asks the installed handler whether the main window may close. No handler means yes,
	/// which is the behaviour of a host with nothing to ask about.
	public bool RequestMainWindowClose()
	{
		if (mCloseHandler == null)
			return true;
		return mCloseHandler();
	}

	/// Nothing is ever dropped on a window that does not exist.
	public void DrainDroppedFiles(List<DroppedFile> outFiles) {}

	/// An in memory clipboard with no OS behind it.
	///
	/// It still round trips, so a headless test of a cut, copy and paste path works. A
	/// clipboard that silently dropped everything would make those tests pass while
	/// testing nothing.
	public void SetClipboardText(StringView text) => mClipboard.Set(text);
	public void GetClipboardText(String outText) => outText.Set(mClipboard);
	public bool HasClipboardText => !mClipboard.IsEmpty;
}
