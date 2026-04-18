namespace Sedulous.UI;

using Sedulous.Core.Mathematics;

/// Visual overlay shown during a drag operation.
/// Wraps a user-provided visual or shows a default indicator.
/// Shown via PopupLayer with IsHitTestVisible = false.
public class DragAdorner : FrameLayout
{
	private float mOffsetX;
	private float mOffsetY;

	public float OffsetX => mOffsetX;
	public float OffsetY => mOffsetY;

	public this(View visual, float offsetX, float offsetY)
	{
		mOffsetX = offsetX;
		mOffsetY = offsetY;
		IsHitTestVisible = false;
		Alpha = 0.7f;

		if (visual != null)
			AddView(visual);
	}

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		if (ChildCount > 0)
		{
			base.OnMeasure(wSpec, hSpec);
		}
		else
		{
			// Default size when no visual provided.
			MeasuredSize = .(wSpec.Resolve(32), hSpec.Resolve(32));
		}
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		if (ChildCount > 0)
		{
			DrawChildren(ctx);
		}
		else
		{
			// Default: semi-transparent rounded rect.
			ctx.VG.FillRoundedRect(.(0, 0, Width, Height), 4, .(128, 128, 128, 128));
		}
	}
}
