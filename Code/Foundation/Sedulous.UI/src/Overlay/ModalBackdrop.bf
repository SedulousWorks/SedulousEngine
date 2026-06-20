namespace Sedulous.UI;

using Sedulous.Core.Mathematics;

/// Semi-transparent backdrop drawn behind modal popups.
/// Blocks input to underlying content by consuming all mouse events.
public class ModalBackdrop : View
{
	/// Backdrop color (default: semi-transparent black).
	public Color Color = .(0, 0, 0, 120);

	public override void OnDraw(UIDrawContext ctx)
	{
		ctx.VG.FillRect(.(0, 0, Width, Height), Color);
	}

	// Block all mouse input so nothing reaches content behind the modal.
	public override void OnMouseDown(MouseEventArgs e) { e.Handled = true; }
	public override void OnMouseUp(MouseEventArgs e) { e.Handled = true; }
	public override void OnMouseMove(MouseEventArgs e) { e.Handled = true; }
}
