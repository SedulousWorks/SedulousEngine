namespace Sedulous.UI.Shell;

using Sedulous.UI;
using System;

/// Utility class for mapping Shell input types to UI input types.
/// Includes US-layout text input emulation for when SDL_StartTextInput
/// is not active.
static class InputMapping
{
	/// Maps Shell.Input.KeyCode to UI.KeyCode.
	public static Sedulous.UI.KeyCode MapKey(Sedulous.Shell.Input.KeyCode shellKey)
	{
		// Values match by design - trivial cast works for all common keys.
		return (Sedulous.UI.KeyCode)(int)shellKey;
	}

	/// Maps Shell.Input.KeyModifiers to UI.KeyModifiers.
	public static Sedulous.UI.KeyModifiers MapModifiers(Sedulous.Shell.Input.KeyModifiers shellMods)
	{
		Sedulous.UI.KeyModifiers result = .None;
		if (shellMods.HasFlag(.LeftShift) || shellMods.HasFlag(.RightShift))
			result |= .Shift;
		if (shellMods.HasFlag(.LeftCtrl) || shellMods.HasFlag(.RightCtrl))
			result |= .Ctrl;
		if (shellMods.HasFlag(.LeftAlt) || shellMods.HasFlag(.RightAlt))
			result |= .Alt;
		if (shellMods.HasFlag(.CapsLock))
			result |= .CapsLock;
		if (shellMods.HasFlag(.NumLock))
			result |= .NumLock;
		return result;
	}

	/// Maps Shell.Input.MouseButton to UI.MouseButton.
	public static Sedulous.UI.MouseButton MapMouseButton(Sedulous.Shell.Input.MouseButton shellButton)
	{
		return (.)shellButton;
	}

	/// Converts a shell key code to a printable character.
	/// Returns '\0' if the key doesn't produce a printable character.
	/// This is a fallback for when SDL_StartTextInput is not active.
	/// Uses US keyboard layout.
	public static char32 KeyToChar(Sedulous.Shell.Input.KeyCode key, bool shift)
	{
		// Letters A-Z
		if (key >= .A && key <= .Z)
		{
			let baseChar = 'a' + (int)(key - .A);
			return shift ? (char32)((int)'A' + (int)(key - .A)) : (char32)baseChar;
		}

		switch (key)
		{
		// Top row numbers
		case .Num1: return shift ? '!' : '1';
		case .Num2: return shift ? '@' : '2';
		case .Num3: return shift ? '#' : '3';
		case .Num4: return shift ? '$' : '4';
		case .Num5: return shift ? '%' : '5';
		case .Num6: return shift ? '^' : '6';
		case .Num7: return shift ? '&' : '7';
		case .Num8: return shift ? '*' : '8';
		case .Num9: return shift ? '(' : '9';
		case .Num0: return shift ? ')' : '0';

		// Keypad numbers
		case .Keypad0: return '0';
		case .Keypad1: return '1';
		case .Keypad2: return '2';
		case .Keypad3: return '3';
		case .Keypad4: return '4';
		case .Keypad5: return '5';
		case .Keypad6: return '6';
		case .Keypad7: return '7';
		case .Keypad8: return '8';
		case .Keypad9: return '9';

		// Keypad operators
		case .KeypadDivide:   return '/';
		case .KeypadMultiply: return '*';
		case .KeypadMinus:    return '-';
		case .KeypadPlus:     return '+';
		case .KeypadPeriod:   return '.';

		// Punctuation
		case .Space:        return ' ';
		case .Minus:        return shift ? '_' : '-';
		case .Equals:       return shift ? '+' : '=';
		case .LeftBracket:  return shift ? '{' : '[';
		case .RightBracket: return shift ? '}' : ']';
		case .Backslash:    return shift ? '|' : '\\';
		case .Semicolon:    return shift ? ':' : ';';
		case .Apostrophe:   return shift ? '"' : '\'';
		case .Grave:        return shift ? '~' : '`';
		case .Comma:        return shift ? '<' : ',';
		case .Period:       return shift ? '>' : '.';
		case .Slash:        return shift ? '?' : '/';

		default:            return '\0';
		}
	}
}
