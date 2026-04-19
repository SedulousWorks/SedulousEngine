namespace Sedulous.UI;

using Sedulous.Core.Mathematics;

/// Semi-transparent backdrop drawn behind modal popups.
/// Blocks input to underlying content.
public class ModalBackdrop : View
{
	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);
		if (!ctx.TryDrawDrawable("Modal.Backdrop", bounds, .Normal))
		{
			let color = ctx.Theme?.GetColor("Modal.Backdrop", .(0, 0, 0, 120)) ?? .(0, 0, 0, 120);
			ctx.VG.FillRect(bounds, color);
		}
	}

	// Block all mouse input.
	public override void OnMouseDown(MouseEventArgs e) { e.Handled = true; }
	public override void OnMouseUp(MouseEventArgs e) { e.Handled = true; }
	public override void OnMouseMove(MouseEventArgs e) { e.Handled = true; }
}
