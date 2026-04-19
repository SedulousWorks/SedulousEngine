namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// ViewGroup with an optional background drawable. Use as a general-purpose
/// container that needs a visible background (unlike bare LinearLayout/FrameLayout
/// which are theme-transparent).
public class Panel : ViewGroup
{
	public Drawable Background ~ delete _;

	/// Effective padding = max(explicit Padding, Background.DrawablePadding)
	/// per component. Theme drawables can enforce minimum padding.
	public Thickness EffectivePadding
	{
		get
		{
			if (Background == null) return Padding;
			let dp = Background.DrawablePadding;
			return .(
				Math.Max(Padding.Left, dp.Left),
				Math.Max(Padding.Top, dp.Top),
				Math.Max(Padding.Right, dp.Right),
				Math.Max(Padding.Bottom, dp.Bottom));
		}
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);
		if (Background != null)
			Background.Draw(ctx, bounds);
		else if (!ctx.TryDrawDrawable("Panel.Background", bounds, GetControlState()))
			ctx.FillThemedBox(bounds, "Panel");
		DrawChildren(ctx);
	}

	/// Default layout: children fill the panel (like FrameLayout with Fill gravity).
	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		let pad = EffectivePadding;
		let contentW = (right - left) - pad.TotalHorizontal;
		let contentH = (bottom - top) - pad.TotalVertical;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;
			let margin = child.LayoutParams?.Margin ?? Thickness();
			child.Layout(
				pad.Left + margin.Left,
				pad.Top + margin.Top,
				contentW - margin.TotalHorizontal,
				contentH - margin.TotalVertical);
		}
	}

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		let pad = EffectivePadding;
		float maxW = 0, maxH = 0;
		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;
			child.Measure(wSpec, hSpec);
			maxW = Math.Max(maxW, child.MeasuredSize.X);
			maxH = Math.Max(maxH, child.MeasuredSize.Y);
		}
		MeasuredSize = .(wSpec.Resolve(maxW + pad.TotalHorizontal),
						 hSpec.Resolve(maxH + pad.TotalVertical));
	}
}
