namespace Sedulous.Editor.App;

using Sedulous.UI;

/// Per-floating-window rendering resources.
/// Owns RootView, VGContext, VGRenderer for rendering UI in secondary OS windows.
class FloatingWindowData
{
	public RootView RootView ~ delete _;
	public Sedulous.VG.VGContext VGContext ~ delete _;
	public Sedulous.VG.Renderer.VGRenderer VGRenderer ~ { _.Dispose(); delete _; };
	public View FloatingView; // non-owning ref to the floating window view
	public delegate void(View) OnCloseDelegate ~ delete _; // owns the callback from DockManager
}
