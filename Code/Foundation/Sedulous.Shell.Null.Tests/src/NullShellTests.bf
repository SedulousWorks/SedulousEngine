using System;
using System.Collections;
using Sedulous.Shell;
using Sedulous.Shell.Null;

namespace Sedulous.Shell.Null.Tests;

/// The headless shell. It is not only a test double: it is the reference for what a real
/// backend must provide, so the behaviour worth pinning is the behaviour every backend
/// owes.
class NullShellTests
{
	[Test]
	public static void AShellStartsWithOneMainWindow()
	{
		let shell = scope NullShell();

		Test.Assert(shell.WindowManager != null);
		Test.Assert(shell.MainWindow != null);
		Test.Assert(shell.MainWindow === shell.WindowManager.MainWindow, "the same window either way");
		Test.Assert(shell.WindowManager.Windows.Length == 1);
		Test.Assert(shell.IsRunning);

		// Every service is present, so a headless caller needs no null checks.
		Test.Assert(shell.Input != null);
		Test.Assert(shell.Input.Keyboard != null);
		Test.Assert(shell.Input.Mouse != null);
		Test.Assert(shell.Input.Touch != null);
		Test.Assert(shell.Dialogs != null);
	}

	[Test]
	public static void WindowSettingsAreHonoured()
	{
		var settings = WindowSettings();
		settings.Width = 800;
		settings.Height = 600;
		settings.Positioned = true;
		settings.X = 40;
		settings.Y = 50;

		let shell = scope NullShell(settings);
		let window = shell.MainWindow;

		Test.Assert(window.Width == 800);
		Test.Assert(window.Height == 600);
		Test.Assert(window.X == 40);
		Test.Assert(window.Y == 50);
		Test.Assert(window.Id != 0, "zero is reserved for no window");
		Test.Assert(window.IsOpen);
		Test.Assert(!window.IsMinimized);
	}

	/// An unpositioned window is placed by the backend, which headless means the origin.
	[Test]
	public static void AnUnpositionedWindowSitsAtTheOrigin()
	{
		var settings = WindowSettings();
		settings.X = 500;
		settings.Y = 500;
		settings.Positioned = false;

		let shell = scope NullShell(settings);
		Test.Assert(shell.MainWindow.X == 0, "the position is ignored when not positioned");
		Test.Assert(shell.MainWindow.Y == 0);
	}

	[Test]
	public static void WindowsCanBeCreatedAndAreGivenDistinctIds()
	{
		let shell = scope NullShell();
		let manager = shell.WindowManager;

		let second = manager.CreateWindow(.()).Value;
		let third = manager.CreateWindow(.()).Value;

		Test.Assert(manager.Windows.Length == 3);
		Test.Assert(second.Id != third.Id);
		Test.Assert(second.Id != shell.MainWindow.Id);
		Test.Assert(manager.GetWindow(second.Id) === second);
		Test.Assert(manager.GetWindow(9999) == null);
	}

	/// Destruction is DEFERRED: marking closes the window, and only the flush frees it. A
	/// window torn down mid frame is a window the GPU may still be drawing.
	[Test]
	public static void DestructionIsDeferredUntilTheFlush()
	{
		let shell = scope NullShell();
		let manager = shell.WindowManager;
		let extra = manager.CreateWindow(.()).Value;
		let id = extra.Id;

		manager.DestroyWindow(extra);

		Test.Assert(!extra.IsOpen, "marked closed at once");
		Test.Assert(manager.Windows.Length == 2, "but still listed until the flush");
		Test.Assert(manager.GetWindow(id) != null);

		manager.FlushDestroyed();

		Test.Assert(manager.Windows.Length == 1, "and gone after it");
		Test.Assert(manager.GetWindow(id) == null);

		// Flushing again is harmless.
		manager.FlushDestroyed();
		Test.Assert(manager.Windows.Length == 1);
	}

	/// Destroying is by IDENTITY, not id: a window from another manager can share an id,
	/// and acting on it would corrupt both managers' bookkeeping.
	[Test]
	public static void DestroyingAForeignWindowDoesNothing()
	{
		let first = scope NullShell();
		let second = scope NullShell();

		// Both managers issue ids from one, so these two share an id.
		Test.Assert(first.MainWindow.Id == second.MainWindow.Id);

		first.WindowManager.DestroyWindow(second.MainWindow);
		first.WindowManager.FlushDestroyed();

		Test.Assert(first.WindowManager.Windows.Length == 1, "its own window is untouched");
		Test.Assert(second.MainWindow.IsOpen, "and the other shell's was not closed");

		// Null is harmless too.
		first.WindowManager.DestroyWindow(null);
		Test.Assert(first.WindowManager.Windows.Length == 1);
	}

	/// The main window is tracked by id, so destroying it never promotes another window
	/// into its place: closing the main window is not masked by others still being open.
	[Test]
	public static void TheMainWindowIsNeverReassigned()
	{
		let shell = scope NullShell();
		let manager = shell.WindowManager;
		let main = manager.MainWindow;
		manager.CreateWindow(.()).IgnoreError();

		Test.Assert(manager.MainWindow === main);

		manager.DestroyWindow(main);
		manager.FlushDestroyed();

		Test.Assert(manager.MainWindow == null, "gone, not replaced by the other window");
		Test.Assert(manager.Windows.Length == 1, "though that window is still open");
	}

	/// The run ends when the main window closes, even with no OS to say so, because that is
	/// what a real backend does.
	[Test]
	public static void ClosingTheMainWindowEndsTheRun()
	{
		let shell = scope NullShell();
		Test.Assert(shell.IsRunning);

		shell.ProcessEvents();
		Test.Assert(shell.IsRunning, "pumping nothing changes nothing");

		shell.MainWindow.Close();
		Test.Assert(!shell.IsRunning);
	}

	[Test]
	public static void RequestingExitEndsTheRun()
	{
		let shell = scope NullShell();
		Test.Assert(shell.IsRunning);

		shell.RequestExit();
		Test.Assert(!shell.IsRunning);
		Test.Assert(shell.MainWindow.IsOpen, "the window is still open; the shell just stopped");
	}

	/// A close handler can VETO the main window closing, which is how an application runs
	/// its own confirm flow for unsaved work.
	[Test]
	public static void ACloseHandlerCanVetoTheClose()
	{
		let shell = scope NullShell();
		Test.Assert(shell.RequestMainWindowClose(), "no handler means the close proceeds");

		var asked = 0;
		shell.SetMainWindowCloseHandler(new [&asked] () => { asked++; return false; });
		Test.Assert(!shell.RequestMainWindowClose(), "the handler said no");
		Test.Assert(asked == 1);

		shell.SetMainWindowCloseHandler(new () => true);
		Test.Assert(shell.RequestMainWindowClose(), "and the replacement said yes");
	}

	[Test]
	public static void AWindowRecordsWhatItIsToldWithoutAnOs()
	{
		let shell = scope NullShell();
		let window = shell.MainWindow;

		window.SetPosition(11, 22);
		Test.Assert(window.X == 11 && window.Y == 22);

		window.SetSize(320, 240);
		Test.Assert(window.Width == 320 && window.Height == 240);

		Test.Assert(window.ContentScale == 1.0f);
		Test.Assert(window.Native.System == .Unknown, "nothing for a graphics backend to use");
		Test.Assert(window.Native.Window == null);

		Test.Assert(!window.IsTextInputActive, "off by default");
		window.StartTextInput();
		Test.Assert(window.IsTextInputActive);
		window.StopTextInput();
		Test.Assert(!window.IsTextInputActive);
	}

	/// The clipboard round trips in memory, so a headless test of cut, copy and paste
	/// works. One that silently dropped everything would make those tests pass while
	/// testing nothing.
	[Test]
	public static void TheClipboardRoundTripsInMemory()
	{
		let shell = scope NullShell();
		Test.Assert(!shell.HasClipboardText);

		let read = scope String();
		shell.GetClipboardText(read);
		Test.Assert(read.IsEmpty);

		shell.SetClipboardText("copied text");
		Test.Assert(shell.HasClipboardText);
		read.Clear();
		shell.GetClipboardText(read);
		Test.Assert(read == "copied text");

		shell.SetClipboardText("");
		Test.Assert(!shell.HasClipboardText, "cleared");
	}

	/// Devices report nothing, but they REPORT: every accessor answers rather than
	/// trapping, which is what lets a consumer poll uniformly.
	[Test]
	public static void TheDevicesAnswerWithoutAnOs()
	{
		let shell = scope NullShell();
		let input = shell.Input;

		Test.Assert(!input.Keyboard.IsKeyDown(.A));
		Test.Assert(!input.Keyboard.IsKeyPressed(.Escape));
		Test.Assert(input.Keyboard.Modifiers == .None);

		Test.Assert(input.Mouse.X == 0.0f);
		Test.Assert(!input.Mouse.IsButtonDown(.Left));
		Test.Assert(input.Mouse.CursorVisible);
		// Setters do nothing but must not trap.
		input.Mouse.SetCursor(.Wait);
		input.Mouse.SetRelativeMode(true);
		input.Mouse.SetGlobalCapture(true);
		Test.Assert(!input.Mouse.RelativeMode, "nothing was actually changed");

		Test.Assert(input.Touch.TouchCount == 0);
		Test.Assert(!input.Touch.HasTouch);
		Test.Assert(!input.Touch.GetTouchPoint(0, let point));

		Test.Assert(input.GamepadCount == 0);
		Test.Assert(input.GetGamepad(0) == null);
		Test.Assert(input.Events.Length == 0);
		Test.Assert(input.HoverWindow == 0);
		input.Update();
	}

	/// A dialog still CALLS BACK, with nothing. Not calling back at all would leave a
	/// caller waiting for a result that never comes, which is a worse headless failure than
	/// a cancel.
	[Test]
	public static void DialogsCancelImmediatelyRatherThanNeverAnswering()
	{
		let shell = scope NullShell();
		var calls = 0;
		var results = -1;

		// Typed explicitly: the parameter type cannot be inferred from a bare lambda here.
		delegate void(Span<String>) observe = scope [&] (paths) => { calls++; results = paths.Length; };

		shell.Dialogs.ShowOpenFile(observe, .(), "", false, 0);
		Test.Assert(calls == 1, "it answered");
		Test.Assert(results == 0, "with nothing, which reads as a cancel");

		shell.Dialogs.ShowSaveFile(observe, .(), "", 0);
		Test.Assert(calls == 2);

		shell.Dialogs.ShowOpenFolder(observe, "", false, 0);
		Test.Assert(calls == 3);

		// And a null callback is not an error.
		shell.Dialogs.ShowOpenFile(null, .(), "", false, 0);
		shell.Dialogs.OpenPath("/tmp");
	}

	/// The event queue exists and is empty, rather than being absent, so a consumer drains
	/// it unconditionally each frame.
	[Test]
	public static void TheEventQueueIsEmptyButPresent()
	{
		let shell = scope NullShell();
		Test.Assert(shell.WindowManager.Events.Length == 0);

		shell.ProcessEvents();
		Test.Assert(shell.WindowManager.Events.Length == 0);

		let dropped = scope List<DroppedFile>();
		shell.DrainDroppedFiles(dropped);
		Test.Assert(dropped.IsEmpty);
	}
}
