namespace Sedulous.Shell.Input;

/// Keyboard key codes (based on physical key positions/scancodes).
public enum KeyCode
{
	Unknown = 0,

	// Letters
	A = 4,
	B = 5,
	C = 6,
	D = 7,
	E = 8,
	F = 9,
	G = 10,
	H = 11,
	I = 12,
	J = 13,
	K = 14,
	L = 15,
	M = 16,
	N = 17,
	O = 18,
	P = 19,
	Q = 20,
	R = 21,
	S = 22,
	T = 23,
	U = 24,
	V = 25,
	W = 26,
	X = 27,
	Y = 28,
	Z = 29,

	// Numbers (top row)
	Num1 = 30,
	Num2 = 31,
	Num3 = 32,
	Num4 = 33,
	Num5 = 34,
	Num6 = 35,
	Num7 = 36,
	Num8 = 37,
	Num9 = 38,
	Num0 = 39,

	// Special keys
	Return = 40,
	Escape = 41,
	Backspace = 42,
	Tab = 43,
	Space = 44,

	// Symbols
	Minus = 45,
	Equals = 46,
	LeftBracket = 47,
	RightBracket = 48,
	Backslash = 49,
	Semicolon = 51,
	Apostrophe = 52,
	Grave = 53,
	Comma = 54,
	Period = 55,
	Slash = 56,

	CapsLock = 57,

	// Function keys
	F1 = 58,
	F2 = 59,
	F3 = 60,
	F4 = 61,
	F5 = 62,
	F6 = 63,
	F7 = 64,
	F8 = 65,
	F9 = 66,
	F10 = 67,
	F11 = 68,
	F12 = 69,

	PrintScreen = 70,
	ScrollLock = 71,
	Pause = 72,
	Insert = 73,
	Home = 74,
	PageUp = 75,
	Delete = 76,
	End = 77,
	PageDown = 78,

	// Arrow keys
	Right = 79,
	Left = 80,
	Down = 81,
	Up = 82,

	NumLock = 83,

	// Keypad
	KeypadDivide = 84,
	KeypadMultiply = 85,
	KeypadMinus = 86,
	KeypadPlus = 87,
	KeypadEnter = 88,
	Keypad1 = 89,
	Keypad2 = 90,
	Keypad3 = 91,
	Keypad4 = 92,
	Keypad5 = 93,
	Keypad6 = 94,
	Keypad7 = 95,
	Keypad8 = 96,
	Keypad9 = 97,
	Keypad0 = 98,
	KeypadPeriod = 99,

	// Additional keys
	Application = 101,
	KeypadEquals = 103,

	F13 = 104,
	F14 = 105,
	F15 = 106,
	F16 = 107,
	F17 = 108,
	F18 = 109,
	F19 = 110,
	F20 = 111,
	F21 = 112,
	F22 = 113,
	F23 = 114,
	F24 = 115,

	// Modifiers
	LeftCtrl = 224,
	LeftShift = 225,
	LeftAlt = 226,
	LeftGui = 227,
	RightCtrl = 228,
	RightShift = 229,
	RightAlt = 230,
	RightGui = 231,

	Count = 512
}
