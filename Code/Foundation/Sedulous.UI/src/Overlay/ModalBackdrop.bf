namespace Sedulous.UI;

using Sedulous.Core.Mathematics;

/// Semi-transparent backdrop drawn behind modal popups.
/// Blocks input to underlying content.
public class ModalBackdrop : View
{
	public Color BackdropColor = .(0, 0, 0, 120);

	public override void OnDraw(UIDrawContext ctx)
	{
		ctx.VG.FillRect(.(0, 0, Width, Height), BackdropColor);
	}

	// Block all mouse input.
	public override void OnMouseDown(MouseEventArgs e) { e.Handled = true; }
	public override void OnMouseUp(MouseEventArgs e) { e.Handled = true; }
	public override void OnMouseMove(MouseEventArgs e) { e.Handled = true; }
}
