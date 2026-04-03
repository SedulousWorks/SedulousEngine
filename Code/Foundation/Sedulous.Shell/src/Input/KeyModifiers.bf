namespace Sedulous.Shell.Input;

/// Keyboard modifier flags.
public enum KeyModifiers
{
	None = 0,
	LeftShift = 0x0001,
	RightShift = 0x0002,
	LeftCtrl = 0x0040,
	RightCtrl = 0x0080,
	LeftAlt = 0x0100,
	RightAlt = 0x0200,
	LeftGui = 0x0400,
	RightGui = 0x0800,
	NumLock = 0x1000,
	CapsLock = 0x2000,
	ScrollLock = 0x8000,

	Shift = LeftShift | RightShift,
	Ctrl = LeftCtrl | RightCtrl,
	Alt = LeftAlt | RightAlt,
	Gui = LeftGui | RightGui
}
