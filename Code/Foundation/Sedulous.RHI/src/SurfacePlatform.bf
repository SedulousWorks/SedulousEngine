namespace Sedulous.RHI;

/// The windowing system that produced a native window's handles.
///
/// Passed to CreateSurface so the backend builds exactly the matching platform surface: a
/// raw pointer does not say which system made it, and handing an X11 Display to the
/// Wayland WSI segfaults rather than failing. Unknown asks the backend for its best guess,
/// which is right on the platforms with only one windowing system.
///
/// The neutral counterpart of the shell's WindowSystem. It is duplicated rather than
/// shared because the RHI must not depend on the shell; the layer that owns both maps one
/// to the other.
enum SurfacePlatform : uint32
{
	Unknown,
	Win32,
	X11,
	Wayland,
	Cocoa,
	/// A browser canvas. The window handle is a CSS SELECTOR rather than a handle, which is
	/// the one case where the pointer is not opaque: see NativeWindow's Web row.
	Web
}
