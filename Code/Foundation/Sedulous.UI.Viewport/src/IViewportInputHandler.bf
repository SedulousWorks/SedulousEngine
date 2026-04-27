namespace Sedulous.UI.Viewport;

using Sedulous.UI;

/// Input handler for viewport views. Multiple handlers can be registered
/// on a ViewportView, processed in priority order. First handler to set
/// e.Handled = true stops propagation to lower-priority handlers.
public interface IViewportInputHandler
{
	void OnMouseDown(MouseEventArgs e, ViewportView viewport);
	void OnMouseUp(MouseEventArgs e, ViewportView viewport);
	void OnMouseMove(MouseEventArgs e, ViewportView viewport);
	void OnMouseWheel(MouseWheelEventArgs e, ViewportView viewport);
}
