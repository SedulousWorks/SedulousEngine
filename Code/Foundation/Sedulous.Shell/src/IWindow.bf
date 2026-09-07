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
	/// by default.
	void StartTextInput();
	void StopTextInput();
	bool IsTextInputActive { get; }
}
