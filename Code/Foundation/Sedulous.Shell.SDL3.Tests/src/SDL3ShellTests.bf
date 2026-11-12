using System;
using System.Collections;
using SDL3;
using Sedulous.Core;
using Sedulous.Shell;

namespace Sedulous.Shell.SDL3.Tests;

/// The SDL3 desktop backend, driven headlessly with synthetic events.
///
/// The desktop runner in Runtime.Client has its own suite.
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

	/// A window made hidden stays out of sight until Show; a software window takes an image
	/// drawn on the CPU (scaled when the sizes differ) and an icon. What the editor's splash
	/// and its hidden main window stand on.
	[Test]
	public static void AHiddenWindowShowsOnShowAndASoftwareWindowTakesPixels()
	{
		var settings = WindowSettings();
		settings.Width = 320;
		settings.Height = 200;
		settings.Hidden = true;
		let fixture = scope ShellFixture(settings);
		if (!fixture.Usable)
			return; // no display: the shell degraded, as AShellCreatesItsWindowAndReportsState says
		Test.Assert((SDL3.SDL_GetWindowFlags(fixture.Handle) & .SDL_WINDOW_HIDDEN) != 0);
		fixture.Shell.MainWindow.Show();
		Test.Assert((SDL3.SDL_GetWindowFlags(fixture.Handle) & .SDL_WINDOW_HIDDEN) == 0);

		var soft = WindowSettings();
		soft.Width = 64;
		soft.Height = 32;
		soft.SoftwareSurface = true;
		Test.Assert(fixture.Shell.WindowManager.CreateWindow(soft) case .Ok(let window));
		let pixels = scope List<uint8>();
		pixels.Count = 64 * 32 * 4;
		Test.Assert(window.PresentPixels(pixels, 64, 32));
		Test.Assert(window.PresentPixels(pixels, 32, 16), "a smaller image scales to the window");
		Test.Assert(!window.PresentPixels(pixels, 128, 64), "too few pixels for the size it names");

		uint8[16 * 16 * 4] icon = default;
		WindowIconImage[1] images = .(.(&icon[0], 16, 16));
		window.SetIcon(images);
		fixture.Shell.WindowManager.DestroyWindow(window);
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
		fixture.Shell.SetMainWindowCloseHandler(new [&asked] () =>
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

	/// A quick click or tap, down and up before the frame reads them (a slow frame, a fast
	/// finger), reads as both pressed and released: comparing the frame's two ends alone
	/// would see neither, and a host polling the edges would lose the click.
	[Test]
	public static void APressAndReleaseInOneFrameReadAsBoth()
	{
		let fixture = scope ShellFixture();
		if (!fixture.Usable)
			return;

		let mouse = fixture.Shell.Input.Mouse;
		let keyboard = fixture.Shell.Input.Keyboard;
		Test.Assert((mouse != null) && (keyboard != null));

		fixture.PushMouseButton(1, true); // SDL's left button.
		fixture.PushMouseButton(1, false);
		fixture.PushKey(.SDL_SCANCODE_A, true);
		fixture.PushKey(.SDL_SCANCODE_A, false);
		fixture.Shell.ProcessEvents();
		Test.Assert(!mouse.IsButtonDown(.Left));
		Test.Assert(mouse.IsButtonPressed(.Left), "the click was lost between the frame's ends");
		Test.Assert(mouse.IsButtonReleased(.Left));
		Test.Assert(!keyboard.IsKeyDown(.A));
		Test.Assert(keyboard.IsKeyPressed(.A), "the tap was lost between the frame's ends");
		Test.Assert(keyboard.IsKeyReleased(.A));

		// The next frame, nothing new.
		fixture.Shell.ProcessEvents();
		Test.Assert(!mouse.IsButtonPressed(.Left));
		Test.Assert(!mouse.IsButtonReleased(.Left));
		Test.Assert(!keyboard.IsKeyPressed(.A));
		Test.Assert(!keyboard.IsKeyReleased(.A));
	}

	/// The latch a pad's buttons use too (no pad to push events at here): a repeat of the
	/// state is no new edge, and a frame's start clears the edges but not the state.
	[Test]
	public static void ButtonLatchKeepsTheFramesEdges()
	{
		ButtonLatch latch = .();
		latch.Set(true);
		latch.Set(true); // a repeat
		latch.Set(false);
		latch.Set(true);
		Test.Assert(latch.Down && latch.Pressed && latch.Released);

		latch.BeginFrame();
		Test.Assert(latch.Down && !latch.Pressed && !latch.Released);
		latch.Set(true);
		Test.Assert(!latch.Pressed, "held is not pressed again");
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

	/// A window nothing covers is all safe area, in its pixels.
	[Test]
	public static void AWindowNothingCoversIsAllSafeAreaInItsPixels()
	{
		let fixture = scope ShellFixture();
		if (!fixture.Usable)
			return;
		let window = fixture.Shell.MainWindow;
		let safe = window.SafeArea;
		Test.Assert((safe.X == 0.0f) && (safe.Y == 0.0f));
		Test.Assert(safe.Width == (float)window.PixelWidth);
		Test.Assert(safe.Height == (float)window.PixelHeight);
	}

	/// A phone takes the app out of view and gives it back: the shell answers as SDL raises the
	/// events (its event watch), before the next pump, and says where the app is between them.
	[Test]
	public static void GoingToTheBackgroundAndBackIsAnsweredAsSdlRaisesIt()
	{
		let fixture = scope ShellFixture();
		if (!fixture.Usable)
			return;
		int background = 0;
		int foreground = 0;
		fixture.Shell.SetBackgroundHandlers(new [&]() => { background++; }, new [&]() => { foreground++; });
		Test.Assert(!fixture.Shell.InBackground);

		SDL_Event event = .();
		event.type = (uint32)SDL_EventType.SDL_EVENT_WILL_ENTER_BACKGROUND;
		SDL3.SDL_PushEvent(&event);
		Test.Assert(background == 1, "during the push, before any pump");
		Test.Assert(fixture.Shell.InBackground);
		event.type = (uint32)SDL_EventType.SDL_EVENT_DID_ENTER_BACKGROUND;
		SDL3.SDL_PushEvent(&event);
		fixture.Shell.ProcessEvents();
		Test.Assert(background == 1, "once for the going, whichever of SDL's events say it");
		Test.Assert(fixture.Shell.InBackground);

		event.type = (uint32)SDL_EventType.SDL_EVENT_WILL_ENTER_FOREGROUND;
		SDL3.SDL_PushEvent(&event);
		Test.Assert(foreground == 0, "the window's new surface comes with the last word, not the first");
		event.type = (uint32)SDL_EventType.SDL_EVENT_DID_ENTER_FOREGROUND;
		SDL3.SDL_PushEvent(&event);
		Test.Assert(foreground == 1);
		Test.Assert(!fixture.Shell.InBackground);
		fixture.Shell.ProcessEvents();
		Test.Assert(fixture.Shell.IsRunning);
		// The handlers capture this frame's counters: cleared before they go out of scope.
		fixture.Shell.SetBackgroundHandlers(null, null);
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

	/// On Wayland a window's new state takes effect only with the app's next frame; an app
	/// that skips idle frames hears that one is wanted.
	[Test]
	public static void AnExposedWindowAsksForAFrame()
	{
		let fixture = scope ShellFixture();
		if (!fixture.Usable)
			return;

		fixture.PushWindowEvent(.SDL_EVENT_WINDOW_EXPOSED);
		fixture.Shell.ProcessEvents();

		bool exposed = false;
		for (let e in fixture.Shell.WindowManager.Events)
		{
			if ((e.Type == .Exposed) && (e.WindowId == fixture.Shell.MainWindow.Id))
				exposed = true;
		}
		Test.Assert(exposed);
	}

	/// Floating windows need to know where windows may go, to bring one back in front and to
	/// title one for the panels it holds: the screens are read, one of them primary, a moved
	/// window is reported, a raise is safe, and a title is set.
	[Test]
	public static void TheScreensAreReadAMovedWindowIsReportedAndATitleIsSet()
	{
		let fixture = scope ShellFixture();
		if (!fixture.Usable)
			return;

		let screens = fixture.Shell.WindowManager.Screens;
		Test.Assert(screens.Length > 0, "the dummy driver has a display of its own");
		int primaries = 0;
		for (let screen in screens)
		{
			Test.Assert(screen.Id != 0);
			Test.Assert((screen.Width > 0) && (screen.Height > 0));
			Test.Assert(screen.Scale > 0.0f);
			// The usable room lies within the bounds.
			Test.Assert((screen.UsableX >= screen.X) && (screen.UsableY >= screen.Y));
			Test.Assert((screen.UsableWidth <= screen.Width) && (screen.UsableHeight <= screen.Height));
			if (screen.Primary)
				primaries++;
		}
		Test.Assert(primaries == 1);

		fixture.PushWindowEvent(.SDL_EVENT_WINDOW_MOVED, 210, 140);
		fixture.Shell.ProcessEvents();
		bool moved = false;
		for (let e in fixture.Shell.WindowManager.Events)
		{
			if ((e.Type == .Moved) && (e.WindowId == fixture.Shell.MainWindow.Id))
			{
				moved = true;
				Test.Assert((e.X == 210) && (e.Y == 140));
			}
		}
		Test.Assert(moved);

		fixture.Shell.MainWindow.Raise();

		// Any number of windows, placed by the application but on Wayland (the dummy driver here).
		let can = fixture.Shell.WindowManager.Capabilities;
		Test.Assert(can.MultipleWindows);
		Test.Assert(can.PlacesWindows == (StringView(SDL3.SDL_GetCurrentVideoDriver()) != "wayland"));

		let main = (SDL3Window)fixture.Shell.MainWindow;
		main.SetTitle("Profiler + 2");
		Test.Assert(StringView(SDL3.SDL_GetWindowTitle(main.Handle)) == "Profiler + 2");
	}

	/// A finger the platform takes back ends without a TouchUp, and a trackpad's pinch is one
	/// gesture: both reach the input events (a trackpad device cannot be made in a test).
	[Test]
	public static void ACancelledFingerAndATrackpadsPinchReachTheInputEvents()
	{
		let fixture = scope ShellFixture();
		if (!fixture.Usable)
			return;

		SDL_Event down = default;
		down.type = (uint32)SDL_EventType.SDL_EVENT_FINGER_DOWN;
		down.tfinger.windowID = fixture.WindowId;
		down.tfinger.fingerID = 7;
		down.tfinger.x = 0.5f;
		down.tfinger.y = 0.5f;
		SDL3.SDL_PushEvent(&down);
		var cancel = down;
		cancel.type = (uint32)SDL_EventType.SDL_EVENT_FINGER_CANCELED;
		SDL3.SDL_PushEvent(&cancel);
		for (let type in SDL_EventType[?](.SDL_EVENT_PINCH_BEGIN, .SDL_EVENT_PINCH_UPDATE, .SDL_EVENT_PINCH_END))
		{
			SDL_Event pinch = default;
			pinch.type = (uint32)type;
			pinch.pinch.windowID = fixture.WindowId;
			pinch.pinch.scale = 1.25f;
			SDL3.SDL_PushEvent(&pinch);
		}

		fixture.Shell.ProcessEvents();
		bool cancelled = false;
		int pinchKinds = 0;
		float scale = 0.0f;
		for (let e in fixture.Shell.Input.Events)
		{
			cancelled |= (e.Kind == .TouchCancel) && (e.TouchId == 7);
			if ((e.Kind == .PinchBegin) || (e.Kind == .PinchEnd))
				pinchKinds++;
			if (e.Kind == .PinchUpdate)
			{
				pinchKinds++;
				scale = e.Value;
			}
		}
		Test.Assert(cancelled);
		Test.Assert(pinchKinds == 3);
		Test.Assert(scale == 1.25f);
		Test.Assert(fixture.Shell.Input.Touch.TouchCount == 0, "the cancelled finger is gone");
	}

	/// SDL's mouse events carry no modifiers: the shell gives each the ones held, so a
	/// Shift+click, a Shift drag and a Ctrl+wheel reach a GUI as such.
	[Test]
	public static void AMouseEventCarriesTheModifiersHeld()
	{
		let fixture = scope ShellFixture();
		if (!fixture.Usable)
			return;

		SDL3.SDL_SetModState(.SDL_KMOD_LSHIFT | .SDL_KMOD_LCTRL);
		defer SDL3.SDL_SetModState(.SDL_KMOD_NONE);
		fixture.PushMouseButton(1, true);
		fixture.PushMouseMotion(10, 10, 1, 1);
		fixture.PushWheel(0, 1);
		fixture.Shell.ProcessEvents();

		int carried = 0;
		for (let e in fixture.Shell.Input.Events)
		{
			let mouse = (e.Kind == .MouseButtonDown) || (e.Kind == .MouseMove) || (e.Kind == .MouseWheel);
			if (mouse && e.Modifiers.HasFlag(.LeftShift) && e.Modifiers.HasFlag(.LeftCtrl))
				carried++;
		}
		Test.Assert(carried == 3);
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

	/// What windows can do by SDL's video driver: as many as wanted, placed by the application, on a
	/// desktop's X11 or Windows; none placed on Wayland, where the compositor places them; one,
	/// placed by the system, on Android, where an app has the activity's window alone.
	[Test]
	public static void WindowCapabilitiesByVideoDriver()
	{
		let x11 = SDL3WindowManager.CapabilitiesFor("x11");
		Test.Assert(x11.MultipleWindows && x11.PlacesWindows);
		let windows = SDL3WindowManager.CapabilitiesFor("windows");
		Test.Assert(windows.MultipleWindows && windows.PlacesWindows);
		let wayland = SDL3WindowManager.CapabilitiesFor("wayland");
		Test.Assert(wayland.MultipleWindows && !wayland.PlacesWindows);
		let android = SDL3WindowManager.CapabilitiesFor("android");
		Test.Assert(!android.MultipleWindows && !android.PlacesWindows);
		let none = SDL3WindowManager.CapabilitiesFor(default);
		Test.Assert(none.MultipleWindows && none.PlacesWindows);
	}
}
