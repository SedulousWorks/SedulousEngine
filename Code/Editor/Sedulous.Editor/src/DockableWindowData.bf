namespace Sedulous.Editor;

using Sedulous.UI;
using Sedulous.RuntimeGraphics;

/// Per-dockable-window rendering resources.
/// Owns RootView, VGContext, VGRenderer for rendering UI in secondary OS windows.
/// Implements IRenderWindowData so it can be attached to a RenderWindow via SetData.
class DockableWindowData : IRenderWindowData
{
	public RootView RootView ~ delete _;
	public Sedulous.VG.VGContext VGContext ~ delete _;
	public Sedulous.VG.Renderer.VGRenderer VGRenderer ~ { _.Dispose(); delete _; };
	public View DockableView; // non-owning ref to the dockable window view
	public delegate void(View) OnCloseDelegate ~ delete _; // owns the callback from DockManager

	public void Dispose() { /* VGRenderer dispose handled by destructor */ }
}
