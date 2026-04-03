using System;
using Sedulous.Shell;
using Sedulous.Shell.Input;
using Sedulous.Shell.SDL3;

namespace Sedulous.Shell.Tests;

class SDL3ShellTests
{
	[Test]
	public static void TestShellCreation()
	{
		let shell = scope SDL3Shell();

		// Managers are created in constructor, but shell is not running until initialized
		Test.Assert(shell.WindowManager != null);
		Test.Assert(shell.InputManager != null);
		Test.Assert(!shell.IsRunning);
	}

	[Test]
	public static void TestShellInitializeAndShutdown()
	{
		let shell = scope SDL3Shell();

		let initResult = shell.Initialize();
		Test.Assert(initResult case .Ok);

		Test.Assert(shell.WindowManager != null);
		Test.Assert(shell.InputManager != null);
		Test.Assert(shell.IsRunning);

		shell.Shutdown();
		Test.Assert(!shell.IsRunning);
	}

	[Test]
	public static void TestWindowCreation()
	{
		let shell = scope SDL3Shell();
		Test.Assert(shell.Initialize() case .Ok);
		defer shell.Shutdown();

		let settings = WindowSettings()
		{
			Title = "Test Window",
			Width = 320,
			Height = 240,
			Hidden = true  // Don't show the window during tests
		};

		let windowResult = shell.WindowManager.CreateWindow(settings);
		Test.Assert(windowResult case .Ok);

		let window = windowResult.Value;
		Test.Assert(window != null);
		Test.Assert(window.ID != 0);
		Test.Assert(window.Width == 320);
		Test.Assert(window.Height == 240);

		shell.WindowManager.DestroyWindow(window);
		Test.Assert(shell.WindowManager.WindowCount == 0);
	}

	[Test]
	public static void TestMultipleWindows()
	{
		let shell = scope SDL3Shell();
		Test.Assert(shell.Initialize() case .Ok);
		defer shell.Shutdown();

		let settings1 = WindowSettings() { Title = "Window 1", Width = 200, Height = 150, Hidden = true };
		let settings2 = WindowSettings() { Title = "Window 2", Width = 300, Height = 200, Hidden = true };

		let window1Result = shell.WindowManager.CreateWindow(settings1);
		let window2Result = shell.WindowManager.CreateWindow(settings2);

		Test.Assert(window1Result case .Ok);
		Test.Assert(window2Result case .Ok);
		Test.Assert(shell.WindowManager.WindowCount == 2);

		let window1 = window1Result.Value;
		let window2 = window2Result.Value;

		Test.Assert(window1.ID != window2.ID);

		// Test GetWindow
		Test.Assert(shell.WindowManager.GetWindow(window1.ID) == window1);
		Test.Assert(shell.WindowManager.GetWindow(window2.ID) == window2);

		shell.WindowManager.DestroyWindow(window1);
		Test.Assert(shell.WindowManager.WindowCount == 1);

		shell.WindowManager.DestroyWindow(window2);
		Test.Assert(shell.WindowManager.WindowCount == 0);
	}

	[Test]
	public static void TestInputManagerAccess()
	{
		let shell = scope SDL3Shell();
		Test.Assert(shell.Initialize() case .Ok);
		defer shell.Shutdown();

		let input = shell.InputManager;
		Test.Assert(input != null);
		Test.Assert(input.Keyboard != null);
		Test.Assert(input.Mouse != null);
		Test.Assert(input.Touch != null);
		Test.Assert(input.GamepadCount == 8); // Max gamepads pre-allocated
	}

	[Test]
	public static void TestKeyboardState()
	{
		let shell = scope SDL3Shell();
		Test.Assert(shell.Initialize() case .Ok);
		defer shell.Shutdown();

		let keyboard = shell.InputManager.Keyboard;

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
		let shell = scope SDL3Shell();
		Test.Assert(shell.Initialize() case .Ok);
		defer shell.Shutdown();

		let mouse = shell.InputManager.Mouse;

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
		let shell = scope SDL3Shell();
		Test.Assert(shell.Initialize() case .Ok);
		defer shell.Shutdown();

		// Test gamepad slots exist
		for (int i = 0; i < 8; i++)
		{
			let gamepad = shell.InputManager.GetGamepad(i);
			Test.Assert(gamepad != null);
			Test.Assert(gamepad.Index == i);
		}

		// Invalid indices should return null
		Test.Assert(shell.InputManager.GetGamepad(-1) == null);
		Test.Assert(shell.InputManager.GetGamepad(100) == null);
	}

	[Test]
	public static void TestRequestExit()
	{
		let shell = scope SDL3Shell();
		Test.Assert(shell.Initialize() case .Ok);

		Test.Assert(shell.IsRunning);
		shell.RequestExit();
		Test.Assert(!shell.IsRunning);

		shell.Shutdown();
	}

	[Test]
	public static void TestProcessEvents()
	{
		let shell = scope SDL3Shell();
		Test.Assert(shell.Initialize() case .Ok);
		defer shell.Shutdown();

		// Create a hidden window
		let settings = WindowSettings() { Title = "Event Test", Width = 100, Height = 100, Hidden = true };
		let windowResult = shell.WindowManager.CreateWindow(settings);
		Test.Assert(windowResult case .Ok);

		// Process events should not crash
		shell.ProcessEvents();

		shell.WindowManager.DestroyWindow(windowResult.Value);
	}
}
