namespace Sedulous.GUI.Shell;

using Sedulous.GUI;

/// Utility class for mapping Shell input types to GUI input types.
static class InputMapping
{
	/// Maps Shell.Input.KeyCode to GUI.KeyCode.
	public static Sedulous.GUI.KeyCode MapKey(Sedulous.Shell.Input.KeyCode shellKey)
	{
		switch (shellKey)
		{
		case .A: return .A;
		case .B: return .B;
		case .C: return .C;
		case .D: return .D;
		case .E: return .E;
		case .F: return .F;
		case .G: return .G;
		case .H: return .H;
		case .I: return .I;
		case .J: return .J;
		case .K: return .K;
		case .L: return .L;
		case .M: return .M;
		case .N: return .N;
		case .O: return .O;
		case .P: return .P;
		case .Q: return .Q;
		case .R: return .R;
		case .S: return .S;
		case .T: return .T;
		case .U: return .U;
		case .V: return .V;
		case .W: return .W;
		case .X: return .X;
		case .Y: return .Y;
		case .Z: return .Z;
		case .Num0: return .Num0;
		case .Num1: return .Num1;
		case .Num2: return .Num2;
		case .Num3: return .Num3;
		case .Num4: return .Num4;
		case .Num5: return .Num5;
		case .Num6: return .Num6;
		case .Num7: return .Num7;
		case .Num8: return .Num8;
		case .Num9: return .Num9;
		case .Return: return .Return;
		case .Escape: return .Escape;
		case .Backspace: return .Backspace;
		case .Tab: return .Tab;
		case .Space: return .Space;
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
		case .CapsLock: return .CapsLock;
		case .F1: return .F1;
		case .F2: return .F2;
		case .F3: return .F3;
		case .F4: return .F4;
		case .F5: return .F5;
		case .F6: return .F6;
		case .F7: return .F7;
		case .F8: return .F8;
		case .F9: return .F9;
		case .F10: return .F10;
		case .F11: return .F11;
		case .F12: return .F12;
		case .PrintScreen: return .PrintScreen;
		case .ScrollLock: return .ScrollLock;
		case .Pause: return .Pause;
		case .Insert: return .Insert;
		case .Home: return .Home;
		case .PageUp: return .PageUp;
		case .Delete: return .Delete;
		case .End: return .End;
		case .PageDown: return .PageDown;
		case .Right: return .Right;
		case .Left: return .Left;
		case .Down: return .Down;
		case .Up: return .Up;
		case .NumLock: return .NumLock;
		case .KeypadDivide: return .KeypadDivide;
		case .KeypadMultiply: return .KeypadMultiply;
		case .KeypadMinus: return .KeypadMinus;
		case .KeypadPlus: return .KeypadPlus;
		case .KeypadEnter: return .KeypadEnter;
		case .Keypad1: return .Keypad1;
		case .Keypad2: return .Keypad2;
		case .Keypad3: return .Keypad3;
		case .Keypad4: return .Keypad4;
		case .Keypad5: return .Keypad5;
		case .Keypad6: return .Keypad6;
		case .Keypad7: return .Keypad7;
		case .Keypad8: return .Keypad8;
		case .Keypad9: return .Keypad9;
		case .Keypad0: return .Keypad0;
		case .KeypadPeriod: return .KeypadPeriod;
		case .Application: return .Application;
		case .LeftCtrl: return .LeftCtrl;
		case .LeftShift: return .LeftShift;
		case .LeftAlt: return .LeftAlt;
		case .LeftGui: return .LeftSuper;
		case .RightCtrl: return .RightCtrl;
		case .RightShift: return .RightShift;
		case .RightAlt: return .RightAlt;
		case .RightGui: return .RightSuper;
		default: return .Unknown;
		}
	}

	/// Maps Shell.Input.KeyModifiers to GUI.KeyModifiers.
	public static Sedulous.GUI.KeyModifiers MapModifiers(Sedulous.Shell.Input.KeyModifiers shellMods)
	{
		Sedulous.GUI.KeyModifiers result = .None;
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

	/// Maps Shell.Input.MouseButton to GUI.MouseButton.
	public static Sedulous.GUI.MouseButton MapMouseButton(Sedulous.Shell.Input.MouseButton shellButton)
	{
		return (.)shellButton;
	}

	/// Maps GUI.CursorType to Shell.Input.CursorType.
	public static Sedulous.Shell.Input.CursorType MapCursor(Sedulous.GUI.CursorType guiCursor)
	{
		switch (guiCursor)
		{
		case .Default:    return .Default;
		case .Text:       return .Text;
		case .Wait:       return .Wait;
		case .Crosshair:  return .Crosshair;
		case .Progress:   return .Progress;
		case .Move:       return .Move;
		case .NotAllowed: return .NotAllowed;
		case .Pointer:    return .Pointer;
		case .ResizeEW:   return .ResizeEW;
		case .ResizeNS:   return .ResizeNS;
		case .ResizeNWSE: return .ResizeNWSE;
		case .ResizeNESW: return .ResizeNESW;
		case .ResizeNW:   return .ResizeNW;
		case .ResizeN:    return .ResizeN;
		case .ResizeNE:   return .ResizeNE;
		case .ResizeE:    return .ResizeE;
		case .ResizeSE:   return .ResizeSE;
		case .ResizeS:    return .ResizeS;
		case .ResizeSW:   return .ResizeSW;
		case .ResizeW:    return .ResizeW;
		}
	}

	/// Converts a key-down event to text input if the key is printable.
	/// Call this alongside ProcessKeyDown to provide text input from key events
	/// when OS text input events are unavailable.
	public static void ForwardKeyAsTextInput(Sedulous.Shell.Input.KeyCode shellKey, Sedulous.GUI.KeyModifiers mods, GUIContext context)
	{
		if (mods.HasFlag(.Ctrl) || mods.HasFlag(.Alt))
			return;

		let c = KeyToChar(shellKey, mods.HasFlag(.Shift));
		if (c != '\0')
			context.ProcessTextInput(c);
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

		// Common punctuation and numbers (US keyboard layout)
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
		case .Tab:          return '\t';
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
