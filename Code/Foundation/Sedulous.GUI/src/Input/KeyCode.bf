namespace Sedulous.GUI;

/// Keyboard key codes. Values aligned with SDL scancodes for direct mapping.
/// Full set populated in Phase F; this is the minimal set for compilation.
public enum KeyCode : int32
{
	Unknown = 0,
	A = 4, B, C, D, E, F, G, H, I, J, K, L, M,
	N, O, P, Q, R, S, T, U, V, W, X, Y, Z,
	Num1 = 30, Num2, Num3, Num4, Num5, Num6, Num7, Num8, Num9, Num0,
	Return = 40,
	Escape,
	Backspace,
	Tab,
	Space,
	F1 = 58, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12,
	Right = 79, Left, Down, Up,
	Home = 74, End = 77,
	PageUp = 75, PageDown = 78,
	Insert = 73, Delete = 76,
}
