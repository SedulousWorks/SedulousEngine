using System;

namespace Sedulous.Shell;

interface IWindow
{
	/// Stable within a shell run, and never 0, which is what lets 0 mean "no window".
	uint32 Id { get; }

	uint32 Width { get; }
	uint32 Height { get; }

	/// Screen space top left, in the same frame the OS uses. Multi window code reads and
	/// writes this to place a floating window relative to another.
	int32 X { get; }
	int32 Y { get; }
	void SetPosition(int32 x, int32 y);
	void SetSize(uint32 width, uint32 height);

	/// Logical to physical scale, 1.0 at 100 percent. A view seeds its own scale from this
	/// so an interface lays out at the right size on a high density display.
	float ContentScale { get; }

	NativeWindow Native { get; }
	bool IsOpen { get; }
	/// Renderers skip a minimized window. A resize is noticed by polling the size rather
	/// than by an event, so there is one way to learn it.
	bool IsMinimized { get; }
	void Close();

	/// Text input and composition. A platform only emits text events for a window while
	/// this is on, so an interface turns it on when an editable control takes focus. Off
	/// by default. Started again with another kind while on, it switches to that kind.
	void StartTextInput(TextInputKind kind = .Text);
	void StopTextInput();
	bool IsTextInputActive { get; }
	/// The kind text input was last started with.
	TextInputKind ActiveTextInputKind { get; }
	/// Where the text being typed is, in window coordinates, and the caret's x within it: an
	/// IME places its candidate list beside it. A backend without IMEs ignores it.
	void SetTextInputArea(int32 x, int32 y, int32 width, int32 height, int32 caretX) {}

	/// The window's icon (its title bar, the taskbar, the window switcher): the first image at
	/// the normal scale, any others the same icon for larger display scales. The images are
	/// copied. A backend with no window icon ignores it.
	void SetIcon(Span<WindowIconImage> images) {}

	/// Shows a window created hidden (WindowSettings.Hidden). Nothing when shown already.
	void Show() {}

	/// Its title bar's text from now on (a floating panel's window follows the panels it holds).
	void SetTitle(StringView title);

	/// Brings the window in front of the others and asks for the keyboard: a floating panel's
	/// window gone behind the main one, come back. A system may only flag it for attention
	/// (Wayland gives the keyboard away only on the user's own action).
	void Raise();

	/// Puts an image on a software window (WindowSettings.SoftwareSurface): tightly packed 8
	/// bit RGBA rows, `width` x `height`, scaled to the window when the sizes differ. False
	/// when the backend has no software windows or the window is not one.
	bool PresentPixels(Span<uint8> rgba, uint32 width, uint32 height) => false;
}
