using System;
using Sedulous.Platform;
using Sedulous.Platform.Input;
using Sedulous.Platform.SDL3;

namespace Sedulous.Platform.Tests;

class SDL3PlatformTests
{
	[Test]
	public static void TestPlatformCreation()
	{
		let platform = scope SDL3Platform();

		// Managers are created in constructor, but platform is not running until initialized
		Test.Assert(platform.WindowManager != null);
		Test.Assert(platform.InputManager != null);
		Test.Assert(!platform.IsRunning);
	}

	[Test]
	public static void TestPlatformInitializeAndShutdown()
	{
		let platform = scope SDL3Platform();

		let initResult = platform.Initialize();
		Test.Assert(initResult case .Ok);

		Test.Assert(platform.WindowManager != null);
		Test.Assert(platform.InputManager != null);
		Test.Assert(platform.IsRunning);

		platform.Shutdown();
		Test.Assert(!platform.IsRunning);
	}

	[Test]
	public static void TestWindowCreation()
	{
		let platform = scope SDL3Platform();
		Test.Assert(platform.Initialize() case .Ok);
		defer platform.Shutdown();

		let settings = WindowSettings()
		{
			Title = "Test Window",
			Width = 320,
			Height = 240,
			Hidden = true  // Don't show the window during tests
		};

		let windowResult = platform.WindowManager.CreateWindow(settings);
		Test.Assert(windowResult case .Ok);

		let window = windowResult.Value;
		Test.Assert(window != null);
		Test.Assert(window.ID != 0);
		Test.Assert(window.Width == 320);
		Test.Assert(window.Height == 240);

		platform.WindowManager.DestroyWindow(window);
		Test.Assert(platform.WindowManager.WindowCount == 0);
	}

	[Test]
	public static void TestMultipleWindows()
	{
		let platform = scope SDL3Platform();
		Test.Assert(platform.Initialize() case .Ok);
		defer platform.Shutdown();

		let settings1 = WindowSettings() { Title = "Window 1", Width = 200, Height = 150, Hidden = true };
		let settings2 = WindowSettings() { Title = "Window 2", Width = 300, Height = 200, Hidden = true };

		let window1Result = platform.WindowManager.CreateWindow(settings1);
		let window2Result = platform.WindowManager.CreateWindow(settings2);

		Test.Assert(window1Result case .Ok);
		Test.Assert(window2Result case .Ok);
		Test.Assert(platform.WindowManager.WindowCount == 2);

		let window1 = window1Result.Value;
		let window2 = window2Result.Value;

		Test.Assert(window1.ID != window2.ID);

		// Test GetWindow
		Test.Assert(platform.WindowManager.GetWindow(window1.ID) == window1);
		Test.Assert(platform.WindowManager.GetWindow(window2.ID) == window2);

		platform.WindowManager.DestroyWindow(window1);
		Test.Assert(platform.WindowManager.WindowCount == 1);

		platform.WindowManager.DestroyWindow(window2);
		Test.Assert(platform.WindowManager.WindowCount == 0);
	}

	[Test]
	public static void TestInputManagerAccess()
	{
		let platform = scope SDL3Platform();
		Test.Assert(platform.Initialize() case .Ok);
		defer platform.Shutdown();

		let input = platform.InputManager;
		Test.Assert(input != null);
		Test.Assert(input.Keyboard != null);
		Test.Assert(input.Mouse != null);
		Test.Assert(input.Touch != null);
		Test.Assert(input.GamepadCount == 8); // Max gamepads pre-allocated
	}

	[Test]
	public static void TestKeyboardState()
	{
		let platform = scope SDL3Platform();
		Test.Assert(platform.Initialize() case .Ok);
		defer platform.Shutdown();

		let keyboard = platform.InputManager.Keyboard;

		// Initially no keys should be pressed
		Test.Assert(!keyboard.IsKeyDown(.A));
		Test.Assert(!keyboard.IsKeyDown(.Escape));
		Test.Assert(!keyboard.IsKeyPressed(.Space));
		Test.Assert(!keyboard.IsKeyReleased(.Return));
		Test.Assert(keyboard.Modifiers == .None);
	}

	[Test]
	public static void TestMouseState()
	{
		let platform = scope SDL3Platform();
		Test.Assert(platform.Initialize() case .Ok);
		defer platform.Shutdown();

		let mouse = platform.InputManager.Mouse;

		// Initial state
		Test.Assert(!mouse.IsButtonDown(.Left));
		Test.Assert(!mouse.IsButtonDown(.Right));
		Test.Assert(!mouse.IsButtonPressed(.Middle));
		Test.Assert(!mouse.IsButtonReleased(.X1));

		// Delta should be zero initially
		Test.Assert(mouse.DeltaX == 0);
		Test.Assert(mouse.DeltaY == 0);
		Test.Assert(mouse.ScrollX == 0);
		Test.Assert(mouse.ScrollY == 0);
	}

	[Test]
	public static void TestGamepadAccess()
	{
		let platform = scope SDL3Platform();
		Test.Assert(platform.Initialize() case .Ok);
		defer platform.Shutdown();

		// Test gamepad slots exist
		for (int i = 0; i < 8; i++)
		{
			let gamepad = platform.InputManager.GetGamepad(i);
			Test.Assert(gamepad != null);
			Test.Assert(gamepad.Index == i);
		}

		// Invalid indices should return null
		Test.Assert(platform.InputManager.GetGamepad(-1) == null);
		Test.Assert(platform.InputManager.GetGamepad(100) == null);
	}

	[Test]
	public static void TestRequestExit()
	{
		let platform = scope SDL3Platform();
		Test.Assert(platform.Initialize() case .Ok);

		Test.Assert(platform.IsRunning);
		platform.RequestExit();
		Test.Assert(!platform.IsRunning);

		platform.Shutdown();
	}

	[Test]
	public static void TestProcessEvents()
	{
		let platform = scope SDL3Platform();
		Test.Assert(platform.Initialize() case .Ok);
		defer platform.Shutdown();

		// Create a hidden window
		let settings = WindowSettings() { Title = "Event Test", Width = 100, Height = 100, Hidden = true };
		let windowResult = platform.WindowManager.CreateWindow(settings);
		Test.Assert(windowResult case .Ok);

		// Process events should not crash
		platform.ProcessEvents();

		platform.WindowManager.DestroyWindow(windowResult.Value);
	}
}
