namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Container with optional background drawable.
/// Children are laid out filling the panel minus padding.
///
/// Background is set via the inline-style API:
/// `panel.SetStyle(.Background, new ColorDrawable(...))`. Theme rules
/// on the context StyleSheet contribute when no inline override is
/// set. Both paths flow through `ResolveStyleDrawable(.Background)`.
public class Panel : ViewGroup
{
	protected override void OnMeasure(BoxConstraints constraints)
	{
		let effectivePad = EffectivePadding;
		let inner = constraints.Deflate(effectivePad).Loosen();

		float maxW = 0, maxH = 0;
		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let margin = child.LayoutParams?.Margin ?? Thickness();
			child.Measure(inner.Deflate(margin));
			maxW = Math.Max(maxW, child.MeasuredSize.X + margin.TotalHorizontal);
			maxH = Math.Max(maxH, child.MeasuredSize.Y + margin.TotalVertical);
		}

		MeasuredSize = .(
			constraints.ConstrainWidth(maxW + effectivePad.TotalHorizontal),
			constraints.ConstrainHeight(maxH + effectivePad.TotalVertical));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		let pad = EffectivePadding;
		let contentW = width - pad.TotalHorizontal;
		let contentH = height - pad.TotalVertical;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let margin = child.LayoutParams?.Margin ?? Thickness();
			child.Layout(
				pad.Left + margin.Left,
				pad.Top + margin.Top,
				Math.Max(0, contentW - margin.TotalHorizontal),
				Math.Max(0, contentH - margin.TotalVertical));
		}
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);
		let bg = ResolveStyleDrawable(.Background);
		if (bg != null)
			bg.Draw(ctx, bounds, GetControlState());

		DrawChildren(ctx);
	}

	/// Effective padding: max of explicit padding and the resolved
	/// background drawable's padding.
	private Thickness EffectivePadding
	{
		get
		{
			let bg = ResolveStyleDrawable(.Background);
			let dp = bg?.DrawablePadding ?? Thickness();
			return .(
				Math.Max(Padding.Left, dp.Left),
				Math.Max(Padding.Top, dp.Top),
				Math.Max(Padding.Right, dp.Right),
				Math.Max(Padding.Bottom, dp.Bottom));
		}
	}
}
