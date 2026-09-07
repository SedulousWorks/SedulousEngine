using System;
using SDL3;
using Sedulous.Shell;

namespace Sedulous.Shell.SDL3;

/// SDL's enums to the shell's.
///
/// SCANCODES, not keycodes: a scancode is the physical key, so WASD stays under the same
/// fingers on a French layout. A keycode would move with the layout, which is right for
/// typing and wrong for controls.
static class SDL3KeyMap
{
	/// The ranges are contiguous in BOTH enums, so they map by offset. Anything else is a
	/// table below. A scancode with no mapping is Unknown, which is a key the shell does
	/// not name rather than an error.
	public static KeyCode Key(SDL_Scancode scancode)
	{
		let sc = (int32)scancode;

		if ((sc >= (int32)SDL_Scancode.SDL_SCANCODE_A) && (sc <= (int32)SDL_Scancode.SDL_SCANCODE_Z))
			return (KeyCode)((int32)KeyCode.A + (sc - (int32)SDL_Scancode.SDL_SCANCODE_A));

		// SDL orders the digit row 1..9 then 0, and so does KeyCode, but zero is not
		// adjacent to nine in either, so it is handled apart.
		if ((sc >= (int32)SDL_Scancode.SDL_SCANCODE_1) && (sc <= (int32)SDL_Scancode.SDL_SCANCODE_9))
			return (KeyCode)((int32)KeyCode.Num1 + (sc - (int32)SDL_Scancode.SDL_SCANCODE_1));
		if (sc == (int32)SDL_Scancode.SDL_SCANCODE_0)
			return .Num0;

		if ((sc >= (int32)SDL_Scancode.SDL_SCANCODE_F1) && (sc <= (int32)SDL_Scancode.SDL_SCANCODE_F12))
			return (KeyCode)((int32)KeyCode.F1 + (sc - (int32)SDL_Scancode.SDL_SCANCODE_F1));
		if ((sc >= (int32)SDL_Scancode.SDL_SCANCODE_F13) && (sc <= (int32)SDL_Scancode.SDL_SCANCODE_F24))
			return (KeyCode)((int32)KeyCode.F13 + (sc - (int32)SDL_Scancode.SDL_SCANCODE_F13));

		// The keypad runs 1..9 then 0, same as the digit row.
		if ((sc >= (int32)SDL_Scancode.SDL_SCANCODE_KP_1) && (sc <= (int32)SDL_Scancode.SDL_SCANCODE_KP_9))
			return (KeyCode)((int32)KeyCode.Keypad1 + (sc - (int32)SDL_Scancode.SDL_SCANCODE_KP_1));

		switch (scancode)
		{
		case .SDL_SCANCODE_RETURN: return .Return;
		case .SDL_SCANCODE_ESCAPE: return .Escape;
		case .SDL_SCANCODE_BACKSPACE: return .Backspace;
		case .SDL_SCANCODE_TAB: return .Tab;
		case .SDL_SCANCODE_SPACE: return .Space;
		case .SDL_SCANCODE_UP: return .Up;
		case .SDL_SCANCODE_DOWN: return .Down;
		case .SDL_SCANCODE_LEFT: return .Left;
		case .SDL_SCANCODE_RIGHT: return .Right;
		case .SDL_SCANCODE_LCTRL: return .LeftCtrl;
		case .SDL_SCANCODE_LSHIFT: return .LeftShift;
		case .SDL_SCANCODE_LALT: return .LeftAlt;
		case .SDL_SCANCODE_LGUI: return .LeftGui;
		case .SDL_SCANCODE_RCTRL: return .RightCtrl;
		case .SDL_SCANCODE_RSHIFT: return .RightShift;
		case .SDL_SCANCODE_RALT: return .RightAlt;
		case .SDL_SCANCODE_RGUI: return .RightGui;
		case .SDL_SCANCODE_DELETE: return .Delete;
		case .SDL_SCANCODE_INSERT: return .Insert;
		case .SDL_SCANCODE_HOME: return .Home;
		case .SDL_SCANCODE_END: return .End;
		case .SDL_SCANCODE_PAGEUP: return .PageUp;
		case .SDL_SCANCODE_PAGEDOWN: return .PageDown;
		case .SDL_SCANCODE_KP_ENTER: return .KeypadEnter;
		case .SDL_SCANCODE_KP_0: return .Keypad0;
		case .SDL_SCANCODE_KP_DIVIDE: return .KeypadDivide;
		case .SDL_SCANCODE_KP_MULTIPLY: return .KeypadMultiply;
		case .SDL_SCANCODE_KP_MINUS: return .KeypadMinus;
		case .SDL_SCANCODE_KP_PLUS: return .KeypadPlus;
		case .SDL_SCANCODE_KP_PERIOD: return .KeypadDecimal;
		case .SDL_SCANCODE_MINUS: return .Minus;
		case .SDL_SCANCODE_EQUALS: return .Equals;
		case .SDL_SCANCODE_LEFTBRACKET: return .LeftBracket;
		case .SDL_SCANCODE_RIGHTBRACKET: return .RightBracket;
		case .SDL_SCANCODE_BACKSLASH: return .Backslash;
		case .SDL_SCANCODE_SEMICOLON: return .Semicolon;
		case .SDL_SCANCODE_APOSTROPHE: return .Apostrophe;
		case .SDL_SCANCODE_GRAVE: return .Grave;
		case .SDL_SCANCODE_COMMA: return .Comma;
		case .SDL_SCANCODE_PERIOD: return .Period;
		case .SDL_SCANCODE_SLASH: return .Slash;
		case .SDL_SCANCODE_CAPSLOCK: return .CapsLock;
		case .SDL_SCANCODE_SCROLLLOCK: return .ScrollLock;
		case .SDL_SCANCODE_NUMLOCKCLEAR: return .NumLock;
		case .SDL_SCANCODE_PRINTSCREEN: return .PrintScreen;
		case .SDL_SCANCODE_PAUSE: return .Pause;
		case .SDL_SCANCODE_APPLICATION: return .Menu;
		default: return .Unknown;
		}
	}

	/// Left and right are kept APART, because a shortcut that means one of them (right alt
	/// as AltGr) cannot be told from the other once they are merged.
	public static KeyModifiers Modifiers(SDL_Keymod mod)
	{
		KeyModifiers result = .None;
		if ((mod & SDL_Keymod.SDL_KMOD_LSHIFT) != 0) result |= .LeftShift;
		if ((mod & SDL_Keymod.SDL_KMOD_RSHIFT) != 0) result |= .RightShift;
		if ((mod & SDL_Keymod.SDL_KMOD_LCTRL) != 0) result |= .LeftCtrl;
		if ((mod & SDL_Keymod.SDL_KMOD_RCTRL) != 0) result |= .RightCtrl;
		if ((mod & SDL_Keymod.SDL_KMOD_LALT) != 0) result |= .LeftAlt;
		if ((mod & SDL_Keymod.SDL_KMOD_RALT) != 0) result |= .RightAlt;
		if ((mod & SDL_Keymod.SDL_KMOD_LGUI) != 0) result |= .LeftGui;
		if ((mod & SDL_Keymod.SDL_KMOD_RGUI) != 0) result |= .RightGui;
		if ((mod & SDL_Keymod.SDL_KMOD_NUM) != 0) result |= .NumLock;
		if ((mod & SDL_Keymod.SDL_KMOD_CAPS) != 0) result |= .CapsLock;
		if ((mod & SDL_Keymod.SDL_KMOD_SCROLL) != 0) result |= .ScrollLock;
		return result;
	}

	/// SDL numbers its mouse buttons from ONE. Count means unmapped.
	public static MouseButton Mouse(uint32 sdlButton)
	{
		switch (sdlButton)
		{
		case 1: return .Left;
		case 2: return .Middle;
		case 3: return .Right;
		case 4: return .X1;
		case 5: return .X2;
		default: return .Count;
		}
	}

	/// Count means a button this shell does not name, which is dropped rather than
	/// misfiled onto a neighbour.
	public static GamepadButton Button(SDL_GamepadButton button)
	{
		switch (button)
		{
		case .SDL_GAMEPAD_BUTTON_SOUTH: return .South;
		case .SDL_GAMEPAD_BUTTON_EAST: return .East;
		case .SDL_GAMEPAD_BUTTON_WEST: return .West;
		case .SDL_GAMEPAD_BUTTON_NORTH: return .North;
		case .SDL_GAMEPAD_BUTTON_BACK: return .Back;
		case .SDL_GAMEPAD_BUTTON_GUIDE: return .Guide;
		case .SDL_GAMEPAD_BUTTON_START: return .Start;
		case .SDL_GAMEPAD_BUTTON_LEFT_STICK: return .LeftStick;
		case .SDL_GAMEPAD_BUTTON_RIGHT_STICK: return .RightStick;
		case .SDL_GAMEPAD_BUTTON_LEFT_SHOULDER: return .LeftShoulder;
		case .SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER: return .RightShoulder;
		case .SDL_GAMEPAD_BUTTON_DPAD_UP: return .DPadUp;
		case .SDL_GAMEPAD_BUTTON_DPAD_DOWN: return .DPadDown;
		case .SDL_GAMEPAD_BUTTON_DPAD_LEFT: return .DPadLeft;
		case .SDL_GAMEPAD_BUTTON_DPAD_RIGHT: return .DPadRight;
		case .SDL_GAMEPAD_BUTTON_MISC1: return .Misc1;
		case .SDL_GAMEPAD_BUTTON_LEFT_PADDLE1: return .LeftPaddle1;
		case .SDL_GAMEPAD_BUTTON_LEFT_PADDLE2: return .LeftPaddle2;
		case .SDL_GAMEPAD_BUTTON_RIGHT_PADDLE1: return .RightPaddle1;
		case .SDL_GAMEPAD_BUTTON_RIGHT_PADDLE2: return .RightPaddle2;
		case .SDL_GAMEPAD_BUTTON_TOUCHPAD: return .Touchpad;
		default: return .Count;
		}
	}

	public static GamepadAxis Axis(SDL_GamepadAxis axis)
	{
		switch (axis)
		{
		case .SDL_GAMEPAD_AXIS_LEFTX: return .LeftX;
		case .SDL_GAMEPAD_AXIS_LEFTY: return .LeftY;
		case .SDL_GAMEPAD_AXIS_RIGHTX: return .RightX;
		case .SDL_GAMEPAD_AXIS_RIGHTY: return .RightY;
		case .SDL_GAMEPAD_AXIS_LEFT_TRIGGER: return .LeftTrigger;
		case .SDL_GAMEPAD_AXIS_RIGHT_TRIGGER: return .RightTrigger;
		default: return .Count;
		}
	}
}
