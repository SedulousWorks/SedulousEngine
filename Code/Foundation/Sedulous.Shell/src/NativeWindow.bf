namespace Sedulous.Shell;

/// The native handles a graphics backend needs to make its own surface.
///
/// The shell does not create surfaces; it hands over the handles and the backend does the
/// rest. How to read the two pointers depends entirely on System:
///
///   Win32    Display is the HINSTANCE, Window is the HWND
///   X11      Display is a Display*, Window is an XID
///   Wayland  Display is a wl_display*, Window is a wl_surface*
///   Cocoa    Display is null, Window is an NSWindow*
///   Web      Display is null, Window is a CSS selector for the canvas
struct NativeWindow
{
	public WindowSystem System = .Unknown;
	public void* Display;
	public void* Window;

	public this() { System = .Unknown; Display = null; Window = null; }
}
