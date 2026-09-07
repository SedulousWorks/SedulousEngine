namespace Sedulous.Shell;

/// Which windowing system a native handle belongs to, which is what says how to read it.
enum WindowSystem : uint8
{
	case Unknown;
	case Win32;
	case X11;
	case Wayland;
	case Cocoa;
	case Web;
}
