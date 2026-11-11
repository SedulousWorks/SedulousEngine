using System;
using System.Collections;

namespace Sedulous.Shell;

/// The raw operating system service: windows, the event pump, run state and input
/// devices.
///
/// PASSIVE. It is not a subsystem and does not own the loop: the runner pumps it once a
/// frame and an application borrows it to wire up whatever needs it. Interfaces only, so a
/// native backend implements it and a null backend serves headless and test runs.
interface IShell
{
	IWindowManager WindowManager { get; }

	/// The same as WindowManager.MainWindow, kept so a single window host does not have to
	/// reach through the manager.
	IWindow MainWindow { get; }

	/// Always present: a null backend returns a no-op manager, so a caller never checks.
	IInputManager Input { get; }

	/// Always present: a null backend returns a service that cancels immediately.
	IDialogService Dialogs { get; }

	/// Pumps pending OS events, once a frame. The backend rolls input state before
	/// pumping, so a frame's edges are computed against the previous frame and not against
	/// a half updated one.
	void ProcessEvents();

	/// False once the shell should quit, such as when the main window closed. Distinct
	/// from an application's own running state: the OS asking to close and the application
	/// deciding to exit are different questions.
	bool IsRunning { get; }

	/// Flips IsRunning.
	void RequestExit();

	/// Whether the app is in the background, where a platform that takes it out of view (a
	/// phone's home button, another app in front) puts it: there it draws nothing (its window's
	/// surface may be gone), its sound stops, and it may be ended without being asked. A desktop
	/// never puts an app there.
	bool InBackground { get; }

	/// TAKES OWNERSHIP of both, replacing any previous ones; null leaves that one unset.
	/// `onEnterBackground` is called as the app goes, before the shell gives control back to the
	/// platform, so what must stop or be saved is done in it; `onEnterForeground` as it comes
	/// back.
	void SetBackgroundHandlers(delegate void() onEnterBackground, delegate void() onEnterForeground);

	/// Hands the back button the app did not use to the platform, which does with it what it does
	/// for an app that takes no back (a phone puts the app in the background). Nothing on a
	/// platform without a back of its own.
	void PassBackToPlatform() {}

	/// Consulted when the MAIN window's close is requested, by its button or by the OS.
	///
	/// Returning false KEEPS THE SHELL RUNNING, so an application can run its own confirm
	/// flow for unsaved work and exit later on its own terms. Unset means the close
	/// proceeds, which is the behaviour of a host that has nothing to ask about.
	void SetMainWindowCloseHandler(delegate bool() handler);

	/// Files dropped during the last pump, drained once a frame in order. A backend
	/// without drop support leaves it empty.
	void DrainDroppedFiles(List<DroppedFile> outFiles);

	/// The system clipboard, which is process global on every desktop backend rather than
	/// per window, so it sits here rather than on IWindow.
	void SetClipboardText(StringView text);
	void GetClipboardText(String outText);
	bool HasClipboardText { get; }
}
