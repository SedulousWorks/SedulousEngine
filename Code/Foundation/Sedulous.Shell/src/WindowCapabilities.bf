namespace Sedulous.Shell;

/// What a window manager's windows can do, as its backend knows it: asked, never inferred
/// from the window system's name.
struct WindowCapabilities
{
	/// CreateWindow opens windows beside the main one.
	public bool MultipleWindows;
	/// SetPosition and X/Y hold, and the global pointer is real.
	public bool PlacesWindows;

	public this(bool multipleWindows, bool placesWindows)
	{
		MultipleWindows = multipleWindows;
		PlacesWindows = placesWindows;
	}
}
