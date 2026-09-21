using System;
using Sedulous.Shell;
using Sedulous.UI;

namespace Sedulous.UI.Shell;

/// Translation between the shell's input vocabulary and the UI's.
///
/// The two sets share most of their NAMES and almost none of their values, because each was
/// numbered for its own purposes. Keeping the translation in one place is what lets both stay
/// that way.
static class ShellInputMapping
{
	/// A UI cursor to the shell's. The UI names a cursor by what it MEANS and the shell by
	/// what the platform calls it, so Hand becomes Pointer and IBeam becomes Text.
	public static Sedulous.Shell.CursorType ToShellCursor(Sedulous.UI.CursorType cursor)
	{
		switch (cursor)
		{
		case .Hand: return .Pointer;
		case .IBeam: return .Text;
		case .Crosshair: return .Crosshair;
		case .SizeNS: return .ResizeNS;
		case .SizeWE: return .ResizeEW;
		case .SizeNWSE: return .ResizeNWSE;
		case .SizeNESW: return .ResizeNESW;
		case .Move: return .Move;
		case .NotAllowed: return .NotAllowed;
		case .Wait: return .Wait;
		// Default and Arrow are the same thing to the platform.
		default: return .Default;
		}
	}

	public static Sedulous.UI.MouseButton ToUIButton(Sedulous.Shell.MouseButton button)
	{
		switch (button)
		{
		case .Left: return .Left;
		case .Middle: return .Middle;
		case .Right: return .Right;
		case .X1: return .X1;
		case .X2: return .X2;
		default: return .Left;
		}
	}

	/// A shell key to the UI's.
	///
	/// The contiguous RANGES are mapped arithmetically rather than case by case: the letters,
	/// the function keys and the digits run in order on both sides, so the offsets carry. What
	/// is left is the navigation, editing and punctuation the UI actually interprets.
	public static Sedulous.UI.KeyCode ToUIKey(Sedulous.Shell.KeyCode key)
	{
		if (MapRange(key, .A, .Z, Sedulous.UI.KeyCode.A) case .Ok(let letter))
			return letter;

		if (MapRange(key, .F1, .F12, Sedulous.UI.KeyCode.F1) case .Ok(let functionKey))
			return functionKey;

		if (MapRange(key, .F13, .F24, Sedulous.UI.KeyCode.F13) case .Ok(let highFunctionKey))
			return highFunctionKey;

		// The digit row runs 1 to 9 then 0 on both sides, which is the physical keyboard's
		// order rather than the numeric one, so zero is mapped on its own.
		if (MapRange(key, .Num1, .Num9, Sedulous.UI.KeyCode.Num1) case .Ok(let digit))
			return digit;

		if (key == .Num0)
			return .Num0;

		return ToUINamedKey(key);
	}

	/// A key within a range that runs in the same order on both sides.
	private static Result<Sedulous.UI.KeyCode> MapRange(Sedulous.Shell.KeyCode key,
		Sedulous.Shell.KeyCode first, Sedulous.Shell.KeyCode last, Sedulous.UI.KeyCode target)
	{
		let value = (uint32)key;
		if ((value < (uint32)first) || (value > (uint32)last))
			return .Err;

		return .Ok((Sedulous.UI.KeyCode)((uint32)target + (value - (uint32)first)));
	}

	private static Sedulous.UI.KeyCode ToUINamedKey(Sedulous.Shell.KeyCode key)
	{
		switch (key)
		{
		// Both mean CONFIRM to a control, so the keypad's enter is not distinguished.
		case .Return, .KeypadEnter: return .Return;
		case .Escape: return .Escape;
		case .Backspace: return .Backspace;
		case .Tab: return .Tab;
		case .Space: return .Space;
		case .Delete: return .Delete;
		case .Insert: return .Insert;
		case .Home: return .Home;
		case .End: return .End;
		case .PageUp: return .PageUp;
		case .PageDown: return .PageDown;
		case .Left: return .Left;
		case .Right: return .Right;
		case .Up: return .Up;
		case .Down: return .Down;

		// The punctuation row, because editors bind chords on it: Ctrl and slash toggles a
		// comment, and a UI that dropped these could not offer that at all.
		case .Minus: return .Minus;
		case .Equals: return .Equals;
		case .LeftBracket: return .LeftBracket;
		case .RightBracket: return .RightBracket;
		case .Backslash: return .Backslash;
		case .Semicolon: return .Semicolon;
		case .Apostrophe: return .Apostrophe;
		case .Grave: return .Grave;
		case .Comma: return .Comma;
		case .Period: return .Period;
		case .Slash: return .Slash;

		default: return .Unknown;
		}
	}

	public static Sedulous.UI.KeyModifiers ToUIModifiers(Sedulous.Shell.KeyModifiers modifiers)
	{
		var result = Sedulous.UI.KeyModifiers.None;

		// HasANY, not HasFlag. Shift is both shift bits and HasFlag demands every bit of its
		// argument, so it answers false for the one shift a person actually holds. Both enums
		// carry HasAny for exactly this.
		//
		// The composite goes out rather than the side that came in, which is what lets the
		// whole UI ask HasFlag(.Shift) downstream and be right.
		if (modifiers.HasAny(.Shift))
			result |= .Shift;
		if (modifiers.HasAny(.Ctrl))
			result |= .Ctrl;
		if (modifiers.HasAny(.Alt))
			result |= .Alt;
		if (modifiers.HasAny(.Gui))
			result |= .Gui;

		return result;
	}
}
