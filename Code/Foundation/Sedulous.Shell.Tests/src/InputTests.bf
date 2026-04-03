using System;
using Sedulous.Shell.Input;

namespace Sedulous.Shell.Tests;

class InputTests
{
	[Test]
	public static void TestMouseButtonEnum()
	{
		Test.Assert((int)MouseButton.Left == 0);
		Test.Assert((int)MouseButton.Middle == 1);
		Test.Assert((int)MouseButton.Right == 2);
		Test.Assert((int)MouseButton.X1 == 3);
		Test.Assert((int)MouseButton.X2 == 4);
	}

	[Test]
	public static void TestGamepadButtonEnum()
	{
		Test.Assert((int)GamepadButton.South == 0);
		Test.Assert((int)GamepadButton.East == 1);
		Test.Assert((int)GamepadButton.West == 2);
		Test.Assert((int)GamepadButton.North == 3);
		Test.Assert((int)GamepadButton.Count > 0);
	}

	[Test]
	public static void TestGamepadAxisEnum()
	{
		Test.Assert((int)GamepadAxis.LeftX == 0);
		Test.Assert((int)GamepadAxis.LeftY == 1);
		Test.Assert((int)GamepadAxis.RightX == 2);
		Test.Assert((int)GamepadAxis.RightY == 3);
		Test.Assert((int)GamepadAxis.LeftTrigger == 4);
		Test.Assert((int)GamepadAxis.RightTrigger == 5);
		Test.Assert((int)GamepadAxis.Count == 6);
	}

	[Test]
	public static void TestKeyModifiers()
	{
		var mods = KeyModifiers.None;
		Test.Assert(mods == .None);

		mods = .LeftShift | .LeftCtrl;
		Test.Assert(mods.HasFlag(.LeftShift));
		Test.Assert(mods.HasFlag(.LeftCtrl));
		Test.Assert(!mods.HasFlag(.LeftAlt));

		// Test Shift property
		Test.Assert(KeyModifiers.LeftShift.HasFlag(.LeftShift));
		Test.Assert(KeyModifiers.RightShift.HasFlag(.RightShift));
	}

	[Test]
	public static void TestTouchPoint()
	{
		let point = TouchPoint(123, 100.5f, 200.5f, 0.75f);

		Test.Assert(point.ID == 123);
		Test.Assert(point.X == 100.5f);
		Test.Assert(point.Y == 200.5f);
		Test.Assert(point.Pressure == 0.75f);
	}

	[Test]
	public static void TestTouchPointDefaultPressure()
	{
		let point = TouchPoint(456, 50.0f, 75.0f);

		Test.Assert(point.ID == 456);
		Test.Assert(point.X == 50.0f);
		Test.Assert(point.Y == 75.0f);
		Test.Assert(point.Pressure == 1.0f);
	}

	[Test]
	public static void TestKeyCodeRange()
	{
		// Test that KeyCode.Count is valid
		Test.Assert((int)KeyCode.Count > 0);
		Test.Assert((int)KeyCode.Count <= 512);

		// Test some specific key codes
		Test.Assert((int)KeyCode.A > 0);
		Test.Assert((int)KeyCode.Escape > 0);
		Test.Assert((int)KeyCode.Space > 0);
	}
}
