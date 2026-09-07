using System;

namespace Sedulous.Shell;

/// What to create a window as.
struct WindowSettings
{
	public StringView Title = "Shell";
	public uint32 Width = 1280;
	public uint32 Height = 720;

	/// When false the backend places the window itself, centred, which is what a single
	/// window application wants. A floating or dockable window sets a position.
	public bool Positioned;
	public int32 X;
	public int32 Y;

	public bool Resizable = true;
	public bool Borderless;

	public this()
	{
		Title = "Shell"; Width = 1280; Height = 720;
		Positioned = false; X = 0; Y = 0;
		Resizable = true; Borderless = false;
	}
}
