using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// The drag plumbing the colour surfaces share: press captures and samples, movement keeps
/// sampling, release lets go.
///
/// CAPTURED on press, because dragging out past the edge is the ordinary way to reach a limit
/// and the drag must not stop when the pointer leaves.
abstract class HSVDragSurface : View
{
	protected IHSVSource mSource;
	private bool mDragging = false;

	public this(IHSVSource source)
	{
		mSource = source;
	}

	protected abstract void UpdateFromMouse(float x, float y);

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button != .Left)
			return;

		mDragging = true;
		if (Context != null)
			Context.GetFocusManager().SetCapture(this);

		UpdateFromMouse(e.X, e.Y);
		e.Handled = true;
	}

	public override void OnMouseMove(MouseEventArgs e)
	{
		if (mDragging)
			UpdateFromMouse(e.X, e.Y);
	}

	public override void OnMouseUp(MouseEventArgs e)
	{
		if (!mDragging || (e.Button != .Left))
			return;

		mDragging = false;
		if (Context != null)
			Context.GetFocusManager().ReleaseCapture();
		e.Handled = true;
	}

	protected void DrawBorder(UIDrawContext ctx)
	{
		ctx.VG.StrokeRect(Rectangle(0, 0, Width, Height),
			ResolveStyleColor(.BorderColor, Color.Rgb(80, 85, 100)), 1);
	}

	/// The marker across a strip: a light bar with a dark outline, so it stays readable over
	/// both ends of whatever the strip shows.
	protected void DrawStripMarker(UIDrawContext ctx, float y)
	{
		let marker = Rectangle(0, y - 1, Width, 3);
		ctx.VG.FillRect(marker, .(1.0f, 1.0f, 1.0f, 230 / 255.0f));
		ctx.VG.StrokeRect(marker, .(0.0f, 0.0f, 0.0f, 128 / 255.0f), 1);
	}
}
