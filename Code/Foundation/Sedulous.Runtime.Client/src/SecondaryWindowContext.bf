using Sedulous.RHI;
using Sedulous.Shell;
using System;

namespace Sedulous.Runtime.Client;

/// Per-window rendering context for secondary OS windows.
/// Manages a surface and swapchain bound to a secondary window.
/// The Device is shared with the main window (owned by Application).
class SecondaryWindowContext
{
	public IWindow Window;
	public ISurface Surface;
	public ISwapChain SwapChain;

	/// Callback invoked when the OS window close button is clicked.
	public delegate void(SecondaryWindowContext) OnCloseRequested ~ delete _;

	/// Application-layer data attached to this context.
	/// Application subclasses can store per-window rendering resources here.
	/// Ownership is up to the application (Application does NOT delete this).
	public Object UserData;
}
