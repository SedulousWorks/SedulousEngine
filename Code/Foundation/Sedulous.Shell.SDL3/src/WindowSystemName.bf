using System;
using Sedulous.Shell;

namespace Sedulous.Shell.SDL3;

/// A readable name for a window system.
///
/// For the startup log line. The graphics backend logs which windowing system it made its
/// surface against, and the shell logs which one it created the window on; when a surface
/// fails on a machine nobody can reach, those two lines side by side are what says whether
/// they disagreed.
/// A static CLASS rather than a namespace scope block: a free function here would make the
/// namespace itself nameable as a holder, and `SDL3` would then be ambiguous between this
/// namespace's last segment and the binding's.
static class WindowSystems
{
	public static StringView Name(WindowSystem system)
	{
		switch (system)
		{
		case .Win32: return "Win32";
		case .X11: return "X11";
		case .Wayland: return "Wayland";
		case .Cocoa: return "Cocoa";
		case .Web: return "Web";
		default: return "Unknown";
		}
	}
}
