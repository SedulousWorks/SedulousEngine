namespace Sedulous.Shell;

/// Types of window events.
public enum WindowEventType
{
	/// Window was shown.
	Shown,
	/// Window was hidden.
	Hidden,
	/// Window was exposed and needs redrawing.
	Exposed,
	/// Window was moved.
	Moved,
	/// Window was resized.
	Resized,
	/// Window was minimized.
	Minimized,
	/// Window was maximized.
	Maximized,
	/// Window was restored from minimized/maximized state.
	Restored,
	/// Mouse entered the window.
	MouseEnter,
	/// Mouse left the window.
	MouseLeave,
	/// Window gained keyboard focus.
	FocusGained,
	/// Window lost keyboard focus.
	FocusLost,
	/// Window close was requested.
	CloseRequested,
	/// Window entered fullscreen mode.
	EnterFullscreen,
	/// Window left fullscreen mode.
	LeaveFullscreen,
	/// Display content scale (DPI) changed.
	/// This occurs when the window is moved to a display with different scaling.
	/// Query IWindow.ContentScale to get the new scale value.
	DisplayScaleChanged
}

/// Represents a window event.
public struct WindowEvent
{
	/// The type of window event.
	public WindowEventType Type;
	/// Event data (interpretation depends on Type).
	public int32 Data1;
	/// Event data (interpretation depends on Type).
	public int32 Data2;

	public this(WindowEventType type, int32 data1 = 0, int32 data2 = 0)
	{
		Type = type;
		Data1 = data1;
		Data2 = data2;
	}
}
