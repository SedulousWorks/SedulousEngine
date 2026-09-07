using System;
using SDL3;
using Sedulous.Shell;

namespace Sedulous.Shell.SDL3.Tests;

/// The scancode table.
///
/// Raptor carries a case for exactly this because KP_ENTER was silently Unknown: a key that
/// maps to nothing produces no error, it just never does anything, and that is only ever
/// found by someone pressing it. Checked through the real pump, so the mapping and the fold
/// into the snapshot are both covered.
class ScancodeMapTests
{
	private static void RoundTrip(ShellFixture fixture, SDL_Scancode scancode, KeyCode expected)
	{
		fixture.PushKey(scancode, true);
		fixture.Shell.ProcessEvents();
		Test.Assert(fixture.Shell.Input.Keyboard.IsKeyDown(expected),
			scope $"{scancode} did not reach {expected}");

		fixture.PushKey(scancode, false);
		fixture.Shell.ProcessEvents();
		Test.Assert(!fixture.Shell.Input.Keyboard.IsKeyDown(expected));
	}

	/// The keypad and the high function keys, which are the ones a table written by hand
	/// tends to miss.
	[Test]
	public static void TheAwkwardScancodesMap()
	{
		let fixture = scope ShellFixture();
		if (!fixture.Usable)
			return;

		RoundTrip(fixture, .SDL_SCANCODE_KP_ENTER, .KeypadEnter);
		RoundTrip(fixture, .SDL_SCANCODE_KP_0, .Keypad0);
		RoundTrip(fixture, .SDL_SCANCODE_KP_5, .Keypad5);
		RoundTrip(fixture, .SDL_SCANCODE_KP_PLUS, .KeypadPlus);
		RoundTrip(fixture, .SDL_SCANCODE_F13, .F13);
		RoundTrip(fixture, .SDL_SCANCODE_GRAVE, .Grave);
		RoundTrip(fixture, .SDL_SCANCODE_PRINTSCREEN, .PrintScreen);
	}

	/// The contiguous ranges, at both ends: an off by one shows at an edge and nowhere else.
	[Test]
	public static void TheRangesMapAtBothEnds()
	{
		let fixture = scope ShellFixture();
		if (!fixture.Usable)
			return;

		RoundTrip(fixture, .SDL_SCANCODE_A, .A);
		RoundTrip(fixture, .SDL_SCANCODE_Z, .Z);

		// SDL runs the digit row 1..9 then 0, and so does KeyCode, so zero is the one that
		// is not simply an offset.
		RoundTrip(fixture, .SDL_SCANCODE_1, .Num1);
		RoundTrip(fixture, .SDL_SCANCODE_9, .Num9);
		RoundTrip(fixture, .SDL_SCANCODE_0, .Num0);

		RoundTrip(fixture, .SDL_SCANCODE_F1, .F1);
		RoundTrip(fixture, .SDL_SCANCODE_F12, .F12);
		RoundTrip(fixture, .SDL_SCANCODE_KP_1, .Keypad1);
		RoundTrip(fixture, .SDL_SCANCODE_KP_9, .Keypad9);
	}

	/// Left and right stay APART: a shortcut that means right alt cannot be told from one
	/// that means left once they are merged.
	[Test]
	public static void ModifierKeysKeepTheirSide()
	{
		let fixture = scope ShellFixture();
		if (!fixture.Usable)
			return;

		RoundTrip(fixture, .SDL_SCANCODE_LSHIFT, .LeftShift);
		RoundTrip(fixture, .SDL_SCANCODE_RSHIFT, .RightShift);
		RoundTrip(fixture, .SDL_SCANCODE_LCTRL, .LeftCtrl);
		RoundTrip(fixture, .SDL_SCANCODE_RALT, .RightAlt);
		RoundTrip(fixture, .SDL_SCANCODE_LGUI, .LeftGui);
	}

	/// A scancode the shell does not name folds to Unknown rather than onto a real key,
	/// which would fire the wrong action.
	[Test]
	public static void AnUnnamedScancodeIsUnknownAndNotSomeoneElse()
	{
		let fixture = scope ShellFixture();
		if (!fixture.Usable)
			return;

		fixture.PushKey(.SDL_SCANCODE_LANG5, true);
		fixture.Shell.ProcessEvents();

		// It reaches the STREAM, so a consumer working in scancodes is not cut off.
		bool inStream = false;
		for (let e in fixture.Shell.Input.Events)
		{
			if ((e.Kind == .KeyDown) && (e.Key == .Unknown))
				inStream = true;
		}
		Test.Assert(inStream);

		// But nothing in the snapshot went down with it.
		for (int i = 1; i < (int)KeyCode.Count; i++)
			Test.Assert(!fixture.Shell.Input.Keyboard.IsKeyDown((KeyCode)i),
				scope $"an unnamed scancode pressed {(KeyCode)i}");
	}
}
