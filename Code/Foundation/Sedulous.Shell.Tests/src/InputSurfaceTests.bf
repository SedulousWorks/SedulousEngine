using System;
using Sedulous.Core;
using Sedulous.Shell;

namespace Sedulous.Shell.Tests;

/// The surface's device facades. They implement the same interfaces as the shell's, so
/// anything written against IMouse works unchanged when handed one of these; what changes
/// is that they are transformed and gated.
class InputSurfaceTests
{
	private static bool Near(float a, float b, float tolerance = 0.001f) => Abs(a - b) <= tolerance;

	private static InputSurface Surface(IInputManager raw, uint32 window = 1)
	{
		let fit = ContentFit(.(0, 0, 200, 100), .(400, 200), .Stretch);
		return new InputSurface(raw, window, fit);
	}

	/// The mouse is gated on hover OR capture, so a drag off the rectangle keeps reporting.
	[Test]
	public static void TheMouseIsGatedOnHoverOrCapture()
	{
		let raw = scope FakeInputManager();
		let surface = Surface(raw);
		defer delete surface;

		raw.MouseDevice.WheelY = 3.0f;
		raw.MouseDevice.Press(.Left);

		// Nothing applied yet, so no gate: everything reads as inactive.
		Test.Assert(!surface.MouseActive);
		Test.Assert(!surface.Mouse.IsButtonDown(.Left));
		Test.Assert(Near(surface.Mouse.ScrollY, 0.0f), "the wheel does not leak through");

		surface.ApplyGate(true, false, false, .(10, 20), .(1, 2));
		Test.Assert(surface.Mouse.IsButtonDown(.Left));
		Test.Assert(surface.Mouse.IsButtonPressed(.Left));
		Test.Assert(Near(surface.Mouse.ScrollY, 3.0f));

		// Captured but not hovered is still active: that is a drag in progress.
		surface.ApplyGate(false, false, true, .(10, 20), .(1, 2));
		Test.Assert(surface.MouseActive);
		Test.Assert(surface.Mouse.IsButtonDown(.Left));
	}

	/// Position and delta come from the gate, already in content space.
	[Test]
	public static void TheMouseReportsContentSpace()
	{
		let raw = scope FakeInputManager();
		let surface = Surface(raw);
		defer delete surface;

		raw.MouseDevice.PosX = 50; raw.MouseDevice.PosY = 25;
		surface.ApplyGate(true, false, false, .(100, 50), .(4, 8));

		Test.Assert(Near(surface.Mouse.X, 100.0f), "content, not the raw window position");
		Test.Assert(Near(surface.Mouse.Y, 50.0f));
		Test.Assert(Near(surface.Mouse.DeltaX, 4.0f));
		Test.Assert(Near(surface.Mouse.DeltaY, 8.0f));
	}

	/// The global position is desktop space and surface independent, so it passes through
	/// untransformed and UNGATED: multi window drag maths depends on it staying valid even
	/// while the surface is not hovered.
	[Test]
	public static void TheGlobalPositionPassesStraightThrough()
	{
		let raw = scope FakeInputManager();
		let surface = Surface(raw);
		defer delete surface;

		raw.MouseDevice.GlobalPosX = 1234; raw.MouseDevice.GlobalPosY = 567;

		Test.Assert(!surface.MouseActive);
		Test.Assert(Near(surface.Mouse.GlobalX, 1234.0f), "still readable while inactive");
		Test.Assert(Near(surface.Mouse.GlobalY, 567.0f));
	}

	/// Cursor and capture control act on the REAL device: a surface asking for a resize
	/// cursor means it, gate or no gate.
	[Test]
	public static void CursorControlReachesTheRealDevice()
	{
		let raw = scope FakeInputManager();
		let surface = Surface(raw);
		defer delete surface;

		surface.Mouse.SetCursor(.ResizeEW);
		Test.Assert(raw.MouseDevice.LastCursor == .ResizeEW);

		surface.Mouse.SetCursorVisible(false);
		Test.Assert(!raw.MouseDevice.Visible);
		Test.Assert(!surface.Mouse.CursorVisible);

		surface.Mouse.SetRelativeMode(true);
		Test.Assert(raw.MouseDevice.Relative);
		Test.Assert(surface.Mouse.RelativeMode);

		surface.Mouse.SetGlobalCapture(true);
		Test.Assert(raw.MouseDevice.GlobalCapture);
	}

	/// The keyboard is gated on FOCUS, not hover, so two viewports cannot both act on one
	/// keystroke.
	[Test]
	public static void TheKeyboardIsGatedOnFocus()
	{
		let raw = scope FakeInputManager();
		let surface = Surface(raw);
		defer delete surface;

		raw.KeyboardDevice.DownKeys.Add(.W);
		raw.KeyboardDevice.PressedKeys.Add(.W);
		raw.KeyboardDevice.Mods = .LeftShift;

		// Hovered but NOT focused: the keyboard stays shut.
		surface.ApplyGate(true, false, false, .Zero, .Zero);
		Test.Assert(!surface.Keyboard.IsKeyDown(.W));
		Test.Assert(!surface.Keyboard.IsKeyPressed(.W));
		Test.Assert(surface.Keyboard.Modifiers == .None, "and no modifiers leak either");

		surface.ApplyGate(true, true, false, .Zero, .Zero);
		Test.Assert(surface.Keyboard.IsKeyDown(.W));
		Test.Assert(surface.Keyboard.IsKeyPressed(.W));
		Test.Assert(surface.Keyboard.Modifiers == .LeftShift);
	}

	/// The gamepad is gated on focus too, but rumble is not: asking an unfocused pad to
	/// stop has to work.
	[Test]
	public static void TheGamepadIsGatedButRumbleIsNot()
	{
		let raw = scope FakeInputManager();
		let pad = new FakeGamepad();
		pad.DeviceIndex = 0;
		pad.DownButtons.Add(.South);
		pad.Axes[(int)GamepadAxis.LeftX] = 0.75f;
		raw.Gamepads.Add(pad);

		let surface = Surface(raw);
		defer delete surface;

		surface.ApplyGate(true, false, false, .Zero, .Zero);
		let gamepad = surface.Gamepad(0);
		Test.Assert(gamepad != null);
		Test.Assert(!gamepad.IsButtonDown(.South), "unfocused, so the pad is quiet");
		Test.Assert(Near(gamepad.Axis(.LeftX), 0.0f));
		// Identity still reads through, so a UI can list pads without focusing them.
		Test.Assert(gamepad.Connected);
		Test.Assert(gamepad.Name == "Fake Pad");
		Test.Assert(gamepad.Index == 0);

		// Rumble is not gated.
		gamepad.SetRumble(0.5f, 0.25f, 100);
		Test.Assert(Near(pad.LastRumbleLow, 0.5f), "rumble reached the device while unfocused");
		Test.Assert(pad.LastRumbleMs == 100);

		surface.ApplyGate(true, true, false, .Zero, .Zero);
		Test.Assert(gamepad.IsButtonDown(.South));
		Test.Assert(Near(gamepad.Axis(.LeftX), 0.75f));
	}

	/// An index with no device behind it answers safely rather than trapping.
	[Test]
	public static void AnAbsentGamepadIsHarmless()
	{
		let raw = scope FakeInputManager();
		let surface = Surface(raw);
		defer delete surface;
		surface.ApplyGate(true, true, false, .Zero, .Zero);

		let gamepad = surface.Gamepad(0);
		Test.Assert(gamepad != null, "the slot exists even with no device in it");
		Test.Assert(!gamepad.Connected);
		Test.Assert(!gamepad.IsButtonDown(.South));
		Test.Assert(Near(gamepad.Axis(.LeftX), 0.0f));
		gamepad.SetRumble(1.0f, 1.0f, 10); // must not trap

		Test.Assert(surface.Gamepad(-1) == null, "out of range is null");
		Test.Assert(surface.Gamepad(InputSurface.MaxGamepads) == null);
	}

	/// Touch points are transformed into normalised content space and FILTERED to those
	/// that land on the surface, so the index a caller iterates is an index among this
	/// surface's touches.
	[Test]
	public static void TouchesAreTransformedAndFiltered()
	{
		let raw = scope FakeInputManager();
		let surface = Surface(raw);
		defer delete surface;
		surface.SetWindowSize(.(400, 200));

		// Normalised to the window: 0.25 of 400 is x=100, inside the 200 wide region.
		raw.TouchDevice.Points.Add(.(1, 0.25f, 0.25f, 0.8f));
		// 0.75 of 400 is x=300, outside it.
		raw.TouchDevice.Points.Add(.(2, 0.75f, 0.25f, 1.0f));

		Test.Assert(surface.Touch.TouchCount == 1, "only the one on the surface");
		Test.Assert(surface.Touch.HasTouch);

		Test.Assert(surface.Touch.GetTouchPoint(0, let point));
		Test.Assert(point.Id == 1, "and it is the one that was inside");
		// x=100 of a 200 region showing 400 content is content x=200, normalised 0.5.
		Test.Assert(Near(point.X, 0.5f), scope $"got {point.X}");
		Test.Assert(Near(point.Pressure, 0.8f), "pressure passes through");

		Test.Assert(!surface.Touch.GetTouchPoint(1, let beyond), "there is no second one here");
		Test.Assert(!surface.Touch.GetTouchPoint(-1, let negative));
	}

	/// A surface that has not been told its window size cannot transform a touch, and says
	/// so rather than dividing by zero.
	[Test]
	public static void TouchWithoutAWindowSizeReportsNothing()
	{
		let raw = scope FakeInputManager();
		let surface = Surface(raw);
		defer delete surface;

		raw.TouchDevice.Points.Add(.(1, 0.25f, 0.25f, 1.0f));

		Test.Assert(surface.Touch.TouchCount == 0);
		Test.Assert(!surface.Touch.HasTouch);
		Test.Assert(!surface.Touch.GetTouchPoint(0, let untransformable));
	}

	/// A surface can be re-targeted at another window, which is what follows a panel
	/// undocked into a floating one.
	[Test]
	public static void ASurfaceCanBeMovedToAnotherWindow()
	{
		let raw = scope FakeInputManager();
		let surface = Surface(raw, 1);
		defer delete surface;

		let router = scope InputRouter(raw);
		router.AddSurface(surface);

		raw.Hover = 2;
		raw.MouseDevice.PosX = 50; raw.MouseDevice.PosY = 50;
		router.Update();
		Test.Assert(!surface.Hovered, "it is in window one, the pointer is in window two");

		surface.SetWindow(2);
		router.Update();
		Test.Assert(surface.Hovered, "and now it follows");
		Test.Assert(surface.Window == 2);
	}

	/// Re-fitting changes where the surface is and what it shows, which is what a resized
	/// or scrolled viewport does every frame it changes.
	[Test]
	public static void TheFitCanBeChanged()
	{
		let raw = scope FakeInputManager();
		let surface = Surface(raw);
		defer delete surface;

		surface.SetRegion(.(10, 20, 100, 50));
		Test.Assert(Near(surface.Fit.Region.X, 10.0f));
		Test.Assert(Near(surface.Fit.Region.Width, 100.0f));

		surface.SetContentSize(.(50, 25));
		Test.Assert(Near(surface.Fit.ContentSize.X, 50.0f));

		surface.SetFitMode(.Letterbox);
		Test.Assert(surface.Fit.Mode == .Letterbox);

		surface.SetWindowSize(.(800, 600));
		Test.Assert(Near(surface.WindowSize.X, 800.0f));
	}
}
