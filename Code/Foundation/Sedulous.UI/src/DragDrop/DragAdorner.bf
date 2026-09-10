using Sedulous.Core;

namespace Sedulous.UI;

/// The visual that follows the cursor during a drag.
///
/// Not interaction enabled and translucent, so it never hit tests over the drop target it is
/// hovering and you can see what is underneath it.
class DragAdorner : ViewGroup
{
	private float mOffsetX;
	private float mOffsetY;

	/// CONSUMES the visual's reference. A null visual gets the default ghost.
	public this(View visual, float offsetX, float offsetY)
	{
		mOffsetX = offsetX;
		mOffsetY = offsetY;
		IsInteractionEnabled = false;
		Opacity = 0.7f;

		if (visual != null)
			AddView(visual);
	}

	/// How far the adorner sits from the cursor.
	public float OffsetX => mOffsetX;
	public float OffsetY => mOffsetY;

	public override void OnDraw(UIDrawContext ctx)
	{
		if (ChildCount > 0)
		{
			base.OnDraw(ctx);
			return;
		}

		// The default ghost when the source supplied no visual. Themeable through a
		// background-color rule rather than a subclass.
		ctx.VG.FillRoundedRect(.(0, 0, Width, Height), 4.0f,
			ResolveStyleColor(.Background, Color(128 / 255.0f, 128 / 255.0f, 128 / 255.0f,
				128 / 255.0f)));
	}

	/// A size to show when there is no visual at all, so the ghost is visible rather than
	/// collapsing to nothing.
	///
	/// With a visual, the base group's own max of children measure is exactly right, so unlike
	/// Raptor this does not restate it: Raptor's ViewGroup has no such default and had to.
	protected override void OnMeasure(BoxConstraints constraints)
	{
		if (ChildCount > 0)
		{
			base.OnMeasure(constraints);
			return;
		}

		MeasuredSize = .(constraints.ConstrainWidth(32), constraints.ConstrainHeight(32));
	}

	/// The visual fills the adorner.
	protected override void OnLayout(float left, float top, float width, float height)
	{
		for (int i < ChildCount)
			GetChildAt(i).Layout(0, 0, width, height);
	}
}
