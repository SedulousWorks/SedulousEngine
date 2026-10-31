using Sedulous.Core;

namespace Sedulous.UI;

/// The scrim behind a modal popup: it dims what is underneath and swallows every mouse event
/// so nothing behind it can be clicked.
class ModalBackdrop : View
{
	/// Semi transparent black. A `background-color` rule overrides it, so a theme can tint the
	/// scrim without a subclass.
	public Color Color = .(0.0f, 0.0f, 0.0f, 120.0f / 255.0f);

	public this() {}

	public override void OnDraw(UIDrawContext ctx)
	{
		ctx.VG.FillRect(.(0, 0, Width, Height), ResolveStyleColor(.Background, Color));
	}

	// Every mouse event stops here: the whole point of a modal is that the content behind it
	// cannot be reached.
	public override void OnMouseDown(MouseEventArgs e) => e.Handled = true;
	public override void OnMouseUp(MouseEventArgs e) => e.Handled = true;
	public override void OnMouseMove(MouseEventArgs e) => e.Handled = true;
}
