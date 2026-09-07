namespace Sedulous.Shell;

interface IMouse
{
	/// Window space position.
	float X { get; }
	float Y { get; }

	/// Desktop global position, in logical screen coordinates.
	///
	/// Multi window dragging uses this: a window that follows the cursor keeps changing
	/// what its own local coordinates mean mid drag, while global ones stay comparable.
	float GlobalX { get; }
	float GlobalY { get; }

	float DeltaX { get; }
	float DeltaY { get; }
	float ScrollX { get; }
	float ScrollY { get; }

	bool IsButtonDown(MouseButton button);
	bool IsButtonPressed(MouseButton button);
	bool IsButtonReleased(MouseButton button);

	bool RelativeMode { get; }
	void SetRelativeMode(bool enabled);
	bool CursorVisible { get; }
	void SetCursorVisible(bool visible);
	void SetCursor(CursorType cursor);

	/// Keeps events flowing while the cursor is outside the window.
	///
	/// Required for a drag or resize that leaves the window: without it the OS stops
	/// delivering events at the window edge, so the operation stalls there and the release
	/// outside is never seen, which leaves the drag stuck on.
	void SetGlobalCapture(bool enabled);
}
