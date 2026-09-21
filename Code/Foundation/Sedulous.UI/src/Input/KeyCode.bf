namespace Sedulous.UI;

/// Keyboard key codes.
///
/// SDL scancode values. They deliberately do NOT match Sedulous.Shell.KeyCode, which
/// numbers its keys sequentially, so a shell to UI bridge must MAP rather than cast. Note
/// the digits: SDL runs Num1 through Num9 and then Num0, where the shell's run Num0 first,
/// which is one more reason a cast would not survive contact.
enum KeyCode : uint32
{
	case Unknown = 0;

	case A = 4;
	case B = 5;
	case C = 6;
	case D = 7;
	case E = 8;
	case F = 9;
	case G = 10;
	case H = 11;
	case I = 12;
	case J = 13;
	case K = 14;
	case L = 15;
	case M = 16;
	case N = 17;
	case O = 18;
	case P = 19;
	case Q = 20;
	case R = 21;
	case S = 22;
	case T = 23;
	case U = 24;
	case V = 25;
	case W = 26;
	case X = 27;
	case Y = 28;
	case Z = 29;

	case Num1 = 30;
	case Num2 = 31;
	case Num3 = 32;
	case Num4 = 33;
	case Num5 = 34;
	case Num6 = 35;
	case Num7 = 36;
	case Num8 = 37;
	case Num9 = 38;
	case Num0 = 39;

	case Return = 40;
	case Escape = 41;
	case Backspace = 42;
	case Tab = 43;
	case Space = 44;

	case Minus = 45;
	case Equals = 46;
	case LeftBracket = 47;
	case RightBracket = 48;
	case Backslash = 49;
	case Semicolon = 51;
	case Apostrophe = 52;
	case Grave = 53;
	case Comma = 54;
	case Period = 55;
	case Slash = 56;

	case CapsLock = 57;

	case F1 = 58;
	case F2 = 59;
	case F3 = 60;
	case F4 = 61;
	case F5 = 62;
	case F6 = 63;
	case F7 = 64;
	case F8 = 65;
	case F9 = 66;
	case F10 = 67;
	case F11 = 68;
	case F12 = 69;

	case PrintScreen = 70;
	case ScrollLock = 71;
	case Pause = 72;
	case Insert = 73;
	case Home = 74;
	case PageUp = 75;
	case Delete = 76;
	case End = 77;
	case PageDown = 78;

	case Right = 79;
	case Left = 80;
	case Down = 81;
	case Up = 82;

	case NumLock = 83;

	case KeypadDivide = 84;
	case KeypadMultiply = 85;
	case KeypadMinus = 86;
	case KeypadPlus = 87;
	case KeypadEnter = 88;
	case Keypad1 = 89;
	case Keypad2 = 90;
	case Keypad3 = 91;
	case Keypad4 = 92;
	case Keypad5 = 93;
	case Keypad6 = 94;
	case Keypad7 = 95;
	case Keypad8 = 96;
	case Keypad9 = 97;
	case Keypad0 = 98;
	case KeypadPeriod = 99;

	case Application = 101;
	case KeypadEquals = 103;

	case F13 = 104;
	case F14 = 105;
	case F15 = 106;
	case F16 = 107;
	case F17 = 108;
	case F18 = 109;
	case F19 = 110;
	case F20 = 111;
	case F21 = 112;
	case F22 = 113;
	case F23 = 114;
	case F24 = 115;

	case LeftCtrl = 224;
	case LeftShift = 225;
	case LeftAlt = 226;
	case LeftGui = 227;
	case RightCtrl = 228;
	case RightShift = 229;
	case RightAlt = 230;
	case RightGui = 231;

	/// Sizes a key state array; not a key.
	case Count = 512;
}
