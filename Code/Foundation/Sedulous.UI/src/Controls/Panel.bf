namespace Sedulous.UI;

using Sedulous.Core.Mathematics;

/// ViewGroup with an optional background drawable. Use as a general-purpose
/// container that needs a visible background (unlike bare LinearLayout/FrameLayout
/// which are theme-transparent).
public class Panel : ViewGroup
{
	public Drawable Background ~ delete _;

	public override void OnDraw(UIDrawContext ctx)
	{
		if (Background != null)
			Background.Draw(ctx, .(0, 0, Width, Height));
		DrawChildren(ctx);
	}

	/// Default layout: children fill the panel (like FrameLayout with Fill gravity).
	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		let contentW = (right - left) - Padding.TotalHorizontal;
		let contentH = (bottom - top) - Padding.TotalVertical;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;
			let margin = child.LayoutParams?.Margin ?? Thickness();
			child.Layout(
				Padding.Left + margin.Left,
				Padding.Top + margin.Top,
				contentW - margin.TotalHorizontal,
				contentH - margin.TotalVertical);
		}
	}
}
