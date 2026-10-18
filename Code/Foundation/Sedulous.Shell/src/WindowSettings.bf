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
	/// Windowed, exclusive or desktop fullscreen. A backend without fullscreen ignores it.
	public WindowFullscreen Fullscreen;
	/// Created hidden, shown by IWindow.Show: an application that is not ready to draw (the
	/// editor while it starts, a splash on screen) keeps its window out of sight until it is.
	public bool Hidden;
	/// A window drawn on the CPU (IWindow.PresentPixels) rather than by the GPU: a splash
	/// shown before there is a graphics device. Not for a window a swapchain presents to.
	public bool SoftwareSurface;
	/// The application draws an IME's composition text itself (TextEditing events), in place
	/// in its text field, rather than the platform's own box. Read when the shell starts, from
	/// the first window's settings; a backend without IMEs ignores it.
	public bool DrawsTextComposition;

	public this()
	{
		Title = "Shell"; Width = 1280; Height = 720;
		Positioned = false; X = 0; Y = 0;
		Resizable = true; Borderless = false; Fullscreen = .None;
		Hidden = false; SoftwareSurface = false; DrawsTextComposition = false;
	}
}

/// One image of a window's icon: tightly packed 8 bit RGBA rows, `Width` x `Height`. The
/// pixels are borrowed for the call that takes it.
struct WindowIconImage
{
	public uint8* Rgba;
	public uint32 Width;
	public uint32 Height;

	public this(uint8* rgba, uint32 width, uint32 height)
	{
		Rgba = rgba;
		Width = width;
		Height = height;
	}
}
