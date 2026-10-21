using System;

namespace Sedulous.Shell;

/// A screen (a display), in the global frame windows are placed in (IWindow.X/Y, SetPosition).
struct Screen
{
	/// The platform's, stable while it is connected. 0 is never one.
	public uint32 Id;
	/// Owned by the window manager that reported it, and valid until it reads the screens
	/// again.
	public StringView Name;
	/// Its bounds: top left and size.
	public int32 X;
	public int32 Y;
	public uint32 Width;
	public uint32 Height;
	/// The room windows get: the bounds less the taskbar and panels.
	public int32 UsableX;
	public int32 UsableY;
	public uint32 UsableWidth;
	public uint32 UsableHeight;
	/// Content scale (logical to physical, 1.0 at 100 percent).
	public float Scale = 1.0f;
	public bool Primary;

	public this()
	{
		this = default;
		Scale = 1.0f;
	}
}
