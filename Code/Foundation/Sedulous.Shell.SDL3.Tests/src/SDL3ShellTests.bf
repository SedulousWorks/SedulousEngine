using System;
using System.Collections;
using SDL3;
using Sedulous.Core;
using Sedulous.Shell;

namespace Sedulous.Shell.SDL3.Tests;

/// The SDL3 desktop backend, driven headlessly with synthetic events.
///
/// Covers Raptor's Shell.Desktop suite. Its RunApplication case has no counterpart yet:
/// that is the desktop runner in Runtime.Client, which is not ported.
class SDL3ShellTests
{
	[Test]
	public static void AShellCreatesItsWindowAndReportsState()
	{
		var settings = WindowSettings();
		settings.Title = "Shell Test";
		settings.Width = 640;
		settings.Height = 480;

		let fixture = scope ShellFixture(settings);
		if (!fixture.Usable)
		{
			// No display: the shell degraded, which is the contract rather than a failure.
			Test.Assert(!fixture.Shell.IsRunning);
			return;
		}

		Test.Assert(fixture.Shell.MainWindow.Width == 640);
		Test.Assert(fixture.Shell.MainWindow.Height == 480);
		Test.Assert(fixture.Shell.IsRunning);

		// The native handles must be readable and self consistent. WHICH system it reports
		// is host dependent: under the headless driver Linux has no display to name, while
		// Windows still reports Win32.
		let native = fixture.Shell.MainWindow.Native;
#if BF_PLATFORM_WINDOWS
		Test.Assert(native.System == .Win32);
#else
		Test.Assert(native.System == .Unknown);
#endif

		// Pumping with nothing queued must not change anything.
		fixture.Shell.ProcessEvents();
		Test.Assert(fixture.Shell.IsRunning);
	}

	[Test]
	public static void ClosingTheMainWindowStopsTheShell()
	{
		let fixture = scope ShellFixture();
		if (!fixture.Usable)
			return;

		fixture.PushWindowClose();
		fixture.Shell.ProcessEvents();

		Test.Assert(!fixture.Shell.IsRunning);
		Test.Assert(!fixture.Shell.MainWindow.IsOpen);
	}

	/// A host with unsaved work gets to refuse. A vetoed close does NOTHING: the window
	/// stays open, the shell keeps running, and no event is delivered.
	[Test]
	public static void AVetoedCloseLeavesEverythingAlone()
	{
		let fixture = scope ShellFixture();
		if (!fixture.Usable)
			return;

		bool asked = false;
		fixture.Shell.SetMainWindowCloseHandler(new [&] () =>
		{
			asked = true;
			return false;
		});

		fixture.PushWindowClose();
		fixture.Shell.ProcessEvents();

		Test.Assert(asked, "the handler was consulted");
		Test.Assert(fixture.Shell.IsRunning);
		Test.Assert(fixture.Shell.MainWindow.IsOpen);

		// No CLOSE event: the queue may carry others the driver raised on its own, but a
		// close that was refused must not be reported as having happened.
		for (let e in fixture.Shell.WindowManager.Events)
			Test.Assert(e.Type != .CloseRequested, "a refused close was reported anyway");
	}

	/// The edges are what a control fires on, so a key held across frames must report
	/// pressed exactly once.
	[Test]
	public static void KeyStateIsDoubleBuffered()
	{
		let fixture = scope ShellFixture();
		if (!fixture.Usable)
			return;

		let keyboard = fixture.Shell.Input.Keyboard;
		Test.Assert(keyboard != null);

		fixture.PushKey(.SDL_SCANCODE_A, true, .SDL_KMOD_LSHIFT);
		fixture.Shell.ProcessEvents();
		Test.Assert(keyboard.IsKeyDown(.A));
		Test.Assert(keyboard.IsKeyPressed(.A));
		Test.Assert(keyboard.Modifiers.HasFlag(.LeftShift));

		// Still held, no longer newly pressed.
		fixture.Shell.ProcessEvents();
		Test.Assert(keyboard.IsKeyDown(.A));
		Test.Assert(!keyboard.IsKeyPressed(.A));

		fixture.PushKey(.SDL_SCANCODE_A, false);
		fixture.Shell.ProcessEvents();
		Test.Assert(!keyboard.IsKeyDown(.A));
		Test.Assert(keyboard.IsKeyReleased(.A));
	}

	[Test]
	public static void MouseMotionAndButtonsAreTracked()
	{
		let fixture = scope ShellFixture();
		if (!fixture.Usable)
			return;

		let mouse = fixture.Shell.Input.Mouse;
		Test.Assert(mouse != null);

		fixture.PushMouseMotion(12.0f, 34.0f, 12.0f, 34.0f);
		fixture.PushMouseButton(1, true); // SDL's left button.
		fixture.Shell.ProcessEvents();

		Test.Assert(mouse.X == 12.0f);
		Test.Assert(mouse.Y == 34.0f);
		Test.Assert(mouse.DeltaX == 12.0f);
		Test.Assert(mouse.IsButtonDown(.Left));
		Test.Assert(mouse.IsButtonPressed(.Left));

		// A frame with no events: the position stays, the DELTA does not.
		fixture.Shell.ProcessEvents();
		Test.Assert(mouse.X == 12.0f, "position is a state");
		Test.Assert(mouse.DeltaX == 0.0f, "movement is per frame");
		Test.Assert(mouse.IsButtonDown(.Left));
		Test.Assert(!mouse.IsButtonPressed(.Left));
	}

	/// Several motions between pumps are the frame's total movement, not the last one.
	[Test]
	public static void MotionWithinAFrameAccumulates()
	{
		let fixture = scope ShellFixture();
		if (!fixture.Usable)
			return;

		fixture.PushMouseMotion(10.0f, 10.0f, 5.0f, 5.0f);
		fixture.PushMouseMotion(14.0f, 13.0f, 4.0f, 3.0f);
		fixture.Shell.ProcessEvents();

		let mouse = fixture.Shell.Input.Mouse;
		Test.Assert(mouse.DeltaX == 9.0f, scope $"got {mouse.DeltaX}");
		Test.Assert(mouse.DeltaY == 8.0f);
		Test.Assert(mouse.X == 14.0f, "and the position is the latest, not the sum");
	}

	[Test]
	public static void WheelScrollIsPerFrame()
	{
		let fixture = scope ShellFixture();
		if (!fixture.Usable)
			return;

		fixture.PushWheel(1.0f, 2.0f);
		fixture.PushWheel(0.5f, 1.0f);
		fixture.Shell.ProcessEvents();

		let mouse = fixture.Shell.Input.Mouse;
		Test.Assert(mouse.ScrollY == 3.0f, scope $"got {mouse.ScrollY}");

		fixture.Shell.ProcessEvents();
		Test.Assert(mouse.ScrollY == 0.0f, "and it does not carry into the next frame");
	}

	/// The snapshot is a fold over the event stream, so anything the devices report must
	/// also be in the stream a consumer reads.
	[Test]
	public static void EveryInputAlsoReachesTheEventStream()
	{
		let fixture = scope ShellFixture();
		if (!fixture.Usable)
			return;

		fixture.PushKey(.SDL_SCANCODE_B, true);
		fixture.PushMouseMotion(5.0f, 6.0f, 5.0f, 6.0f);
		fixture.Shell.ProcessEvents();

		bool sawKey = false, sawMove = false;
		for (let e in fixture.Shell.Input.Events)
		{
			if ((e.Kind == .KeyDown) && (e.Key == .B))
				sawKey = true;
			if (e.Kind == .MouseMove)
				sawMove = true;
		}
		Test.Assert(sawKey && sawMove);

		// Emptied at the start of the next frame, so a consumer never sees a stale event.
		fixture.Shell.ProcessEvents();
		Test.Assert(fixture.Shell.Input.Events.Length == 0);
	}

	/// Cursor calls have to be safe whether or not the driver can make one.
	[Test]
	public static void CursorStateIsSettable()
	{
		let fixture = scope ShellFixture();
		if (!fixture.Usable)
			return;

		let mouse = fixture.Shell.Input.Mouse;
		Test.Assert(mouse.CursorVisible);
		mouse.SetCursorVisible(false);
		Test.Assert(!mouse.CursorVisible);
		mouse.SetCursorVisible(true);
		Test.Assert(mouse.CursorVisible);

		mouse.SetCursor(.Pointer);
		mouse.SetCursor(.Text);
		mouse.SetCursor(.ResizeNWSE);
		mouse.SetCursor(.Pointer); // The cached path, on the second use.
		mouse.SetCursor(.Default);
	}

	[Test]
	public static void ThereAreNoGamepadsUnderTheHeadlessDriver()
	{
		let fixture = scope ShellFixture();
		if (!fixture.Usable)
			return;

		let input = fixture.Shell.Input;
		Test.Assert(input.GamepadCount == 0);
		Test.Assert(input.GetGamepad(0) == null);
		Test.Assert(input.GetGamepad(-1) == null, "and an out of range index is null, not a trap");
	}

	[Test]
	public static void RequestExitStopsTheShell()
	{
		let fixture = scope ShellFixture();
		if (!fixture.Usable)
			return;

		Test.Assert(fixture.Shell.IsRunning);
		fixture.Shell.RequestExit();
		Test.Assert(!fixture.Shell.IsRunning);
	}

	[Test]
	public static void WindowGeometryIsReadableAndSettable()
	{
		var settings = WindowSettings();
		settings.Width = 500;
		settings.Height = 400;
		settings.Positioned = true;
		settings.X = 64;
		settings.Y = 48;
		settings.Borderless = true; // The borderless creation path.

		let fixture = scope ShellFixture(settings);
		if (!fixture.Usable)
			return;

		let window = fixture.Shell.MainWindow;

		// The headless driver does not honour an exact position, so only that the
		// accessors are safe and that the scale is usable.
		let x = window.X;
		let y = window.Y;
		Test.Assert((x == x) && (y == y));
		Test.Assert(window.ContentScale > 0.0f, "a zero scale collapses every measurement");

		window.SetPosition(100, 120);
		window.SetSize(320, 240);
		Test.Assert(window.Width == 320, "the cached size follows what was asked for");
		Test.Assert(window.Height == 240);

		let mouse = fixture.Shell.Input.Mouse;
		let globalX = mouse.GlobalX;
		let globalY = mouse.GlobalY;
		Test.Assert((globalX == globalX) && (globalY == globalY), "callable, value is host dependent");
	}

	/// A resize event updates the cached size and is reported to whoever drains the queue.
	[Test]
	public static void AResizeUpdatesTheWindowAndIsReported()
	{
		let fixture = scope ShellFixture();
		if (!fixture.Usable)
			return;

		fixture.PushWindowEvent(.SDL_EVENT_WINDOW_RESIZED, 800, 600);
		fixture.Shell.ProcessEvents();

		Test.Assert(fixture.Shell.MainWindow.Width == 800);
		Test.Assert(fixture.Shell.MainWindow.Height == 600);

		bool reported = false;
		for (let e in fixture.Shell.WindowManager.Events)
		{
			if ((e.Type == .Resized) && (e.Width == 800) && (e.Height == 600))
				reported = true;
		}
		Test.Assert(reported);
	}

	/// Focus decides where the keyboard and the pads go, so it has to be tracked and it has
	/// to be given up.
	[Test]
	public static void FocusIsTrackedAndReleased()
	{
		let fixture = scope ShellFixture();
		if (!fixture.Usable)
			return;

		fixture.PushWindowEvent(.SDL_EVENT_WINDOW_FOCUS_GAINED);
		fixture.Shell.ProcessEvents();
		Test.Assert(fixture.Shell.Input.FocusedWindow == fixture.Shell.MainWindow.Id);

		fixture.PushWindowEvent(.SDL_EVENT_WINDOW_FOCUS_LOST);
		fixture.Shell.ProcessEvents();
		Test.Assert(fixture.Shell.Input.FocusedWindow == 0);
	}

	[Test]
	public static void HoverIsTrackedAndReleased()
	{
		let fixture = scope ShellFixture();
		if (!fixture.Usable)
			return;

		fixture.PushWindowEvent(.SDL_EVENT_WINDOW_MOUSE_ENTER);
		fixture.Shell.ProcessEvents();
		Test.Assert(fixture.Shell.Input.HoverWindow == fixture.Shell.MainWindow.Id);

		fixture.PushWindowEvent(.SDL_EVENT_WINDOW_MOUSE_LEAVE);
		fixture.Shell.ProcessEvents();
		Test.Assert(fixture.Shell.Input.HoverWindow == 0);
	}

	/// Every window system has a name for the log, and none of them share one: the whole
	/// point is to compare this line against the graphics backend's.
	[Test]
	public static void EveryWindowSystemHasItsOwnName()
	{
		let systems = scope WindowSystem[](.Unknown, .Win32, .X11, .Wayland, .Cocoa, .Web);
		let seen = scope List<String>();
		for (let system in systems)
		{
			let name = WindowSystems.Name(system);
			Test.Assert(!name.IsEmpty);
			for (let previous in seen)
				Test.Assert(previous != name, scope $"two systems both named {name}");
			seen.Add(scope:: String(name));
		}
	}
}
