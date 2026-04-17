namespace Sedulous.UI;

using Sedulous.Core.Mathematics;

/// Top-level ViewGroup. Owns per-window state (viewport size, DPI scale).
/// A RootView is the first child of UIContext.
public class RootView : ViewGroup
{
	public float DpiScale = 1.0f;
	public Vector2 ViewportSize;

	/// Measure fills the viewport.
	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		let w = MeasureSpec.Exactly(ViewportSize.X);
		let h = MeasureSpec.Exactly(ViewportSize.Y);
		MeasuredSize = .(ViewportSize.X, ViewportSize.Y);

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;
			child.Measure(w, h);
		}
	}

	/// Layout fills the viewport, children fill the root.
	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		let w = right - left;
		let h = bottom - top;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let lp = child.LayoutParams;
			let margin = (lp != null) ? lp.Margin : Thickness();

			let childW = child.MeasuredSize.X;
			let childH = child.MeasuredSize.Y;

			// Default gravity: fill
			let rect = GravityHelper.Apply(.Fill, w, h, childW, childH, margin);
			child.Layout(rect.X, rect.Y, rect.Width, rect.Height);
		}
	}
}
