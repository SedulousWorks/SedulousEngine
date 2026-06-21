namespace Sedulous.UI;

using Sedulous.Core.Mathematics;
using System;

/// Visual overlay shown during a drag operation.
/// Wraps a user-provided visual or shows a default indicator.
/// Shown via PopupLayer. Entire subtree is invisible to hit testing
/// so the underlying drop target can be found.
public class DragAdorner : ViewGroup
{
	private float mOffsetX;
	private float mOffsetY;

	/// Offset from cursor position.
	public float OffsetX => mOffsetX;
	public float OffsetY => mOffsetY;

	public this(View visual, float offsetX, float offsetY)
	{
		mOffsetX = offsetX;
		mOffsetY = offsetY;
		IsInteractionEnabled = false;
		Opacity = 0.7f;

		if (visual != null)
			AddView(visual);
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		if (ChildCount > 0)
		{
			base.OnMeasure(constraints);
		}
		else
		{
			// Default size when no visual provided.
			MeasuredSize = .(constraints.ConstrainWidth(32), constraints.ConstrainHeight(32));
		}
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		// Layout children to fill the adorner bounds.
		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child != null)
				child.Layout(0, 0, width, height);
		}
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		if (ChildCount > 0)
		{
			base.OnDraw(ctx);
		}
		else
		{
			// Default: semi-transparent rounded rect.
			ctx.VG.FillRoundedRect(.(0, 0, Width, Height), 4, .(128, 128, 128, 128));
		}
	}
}
