using System;
using Sedulous.Shell;

namespace Sedulous.Shell.Web;

/// Turns a DOM KeyboardEvent.code into a KeyCode.
///
/// `code` is the PHYSICAL key and is layout independent: "KeyW" is the same key whatever the
/// keyboard prints on it, which is what a binding wants. The layout dependent `key` produces
/// characters and belongs to text input instead.
static class WebKeyMap
{
	public static KeyCode FromDom(StringView code)
	{
		if (code.IsEmpty)
			return .Unknown;

		// The runs first, since they are the bulk of the keyboard and cost one compare each.
		if ((code.Length == 4) && code.StartsWith("Key"))
		{
			let letter = code[3];
			if ((letter >= 'A') && (letter <= 'Z'))
				return (KeyCode)((uint32)KeyCode.A + (uint32)(letter - 'A'));
		}

		if ((code.Length == 6) && code.StartsWith("Digit"))
		{
			let digit = code[5];
			if ((digit >= '0') && (digit <= '9'))
				return (KeyCode)((uint32)KeyCode.Num0 + (uint32)(digit - '0'));
		}

		if ((code.Length == 7) && code.StartsWith("Numpad"))
		{
			let digit = code[6];
			if ((digit >= '0') && (digit <= '9'))
				return (KeyCode)((uint32)KeyCode.Keypad0 + (uint32)(digit - '0'));
		}

		// Function keys, one or two digits, F1 through F24.
		if ((code.Length >= 2) && (code[0] == 'F') && (code[1] >= '1') && (code[1] <= '9'))
		{
			var number = (int32)(code[1] - '0');
			if ((code.Length == 3) && (code[2] >= '0') && (code[2] <= '9'))
				number = number * 10 + (int32)(code[2] - '0');
			else if (code.Length != 2)
				number = 0;

			if ((number >= 1) && (number <= 24))
				return (KeyCode)((uint32)KeyCode.F1 + (uint32)(number - 1));
		}

		switch (code)
		{
		case "Space": return .Space;
		case "Enter": return .Return;
		case "Escape": return .Escape;
		case "Backspace": return .Backspace;
		case "Tab": return .Tab;
		case "Minus": return .Minus;
		case "Equal": return .Equals;
		case "BracketLeft": return .LeftBracket;
		case "BracketRight": return .RightBracket;
		case "Backslash": return .Backslash;
		case "Semicolon": return .Semicolon;
		case "Quote": return .Apostrophe;
		case "Backquote": return .Grave;
		case "Comma": return .Comma;
		case "Period": return .Period;
		case "Slash": return .Slash;
		case "CapsLock": return .CapsLock;
		case "ArrowRight": return .Right;
		case "ArrowLeft": return .Left;
		case "ArrowDown": return .Down;
		case "ArrowUp": return .Up;
		case "Insert": return .Insert;
		case "Home": return .Home;
		case "PageUp": return .PageUp;
		case "Delete": return .Delete;
		case "End": return .End;
		case "PageDown": return .PageDown;
		case "ControlLeft": return .LeftCtrl;
		case "ShiftLeft": return .LeftShift;
		case "AltLeft": return .LeftAlt;
		case "MetaLeft": return .LeftGui;
		case "ControlRight": return .RightCtrl;
		case "ShiftRight": return .RightShift;
		case "AltRight": return .RightAlt;
		case "MetaRight": return .RightGui;
		case "ContextMenu": return .Menu;
		case "NumpadEnter": return .KeypadEnter;
		case "NumpadAdd": return .KeypadPlus;
		case "NumpadSubtract": return .KeypadMinus;
		case "NumpadMultiply": return .KeypadMultiply;
		case "NumpadDivide": return .KeypadDivide;
		case "NumpadDecimal": return .KeypadDecimal;
		case "PrintScreen": return .PrintScreen;
		case "ScrollLock": return .ScrollLock;
		case "Pause": return .Pause;
		case "NumLock": return .NumLock;
		default: return .Unknown;
		}
	}

	/// The modifier set a browser event carries. The DOM reports Ctrl, Shift, Alt and Meta
	/// WITHOUT SIDES, so both bits of each pair are set: a binding asking for either side
	/// still answers correctly, and one asking for a specific side cannot be served at all.
	public static KeyModifiers Modifiers(bool ctrl, bool shift, bool alt, bool meta)
	{
		var modifiers = KeyModifiers.None;
		if (ctrl)
			modifiers = modifiers | .Ctrl;
		if (shift)
			modifiers = modifiers | .Shift;
		if (alt)
			modifiers = modifiers | .Alt;
		if (meta)
			modifiers = modifiers | .Gui;
		return modifiers;
	}
}
