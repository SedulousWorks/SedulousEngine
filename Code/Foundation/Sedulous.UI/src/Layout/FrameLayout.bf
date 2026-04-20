namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Stacks children on top of each other, positioned by Gravity.
/// Simplest ViewGroup - children overlap, each positioned independently.
public class FrameLayout : ViewGroup
{
	public class LayoutParams : Sedulous.UI.LayoutParams
	{
		public Gravity Gravity = .None;
	}

	public override Sedulous.UI.LayoutParams CreateDefaultLayoutParams()
	{
		return new FrameLayout.LayoutParams();
	}

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		float maxW = 0, maxH = 0;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let lp = child.LayoutParams;
			let margin = (lp != null) ? lp.Margin : Thickness();

			let childWSpec = MakeChildMeasureSpec(wSpec, Padding.TotalHorizontal + margin.TotalHorizontal, lp?.Width ?? Sedulous.UI.LayoutParams.WrapContent);
			let childHSpec = MakeChildMeasureSpec(hSpec, Padding.TotalVertical + margin.TotalVertical, lp?.Height ?? Sedulous.UI.LayoutParams.WrapContent);

			child.Measure(childWSpec, childHSpec);

			maxW = Math.Max(maxW, child.MeasuredSize.X + margin.TotalHorizontal);
			maxH = Math.Max(maxH, child.MeasuredSize.Y + margin.TotalVertical);
		}

		MeasuredSize = .(wSpec.Resolve(maxW + Padding.TotalHorizontal),
						 hSpec.Resolve(maxH + Padding.TotalVertical));
	}

	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		let contentW = (right - left) - Padding.TotalHorizontal;
		let contentH = (bottom - top) - Padding.TotalVertical;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let flp = child.LayoutParams as FrameLayout.LayoutParams;
			Gravity gravity = (flp != null) ? flp.Gravity : .None;
			let margin = child.LayoutParams?.Margin ?? Thickness();

			let childW = child.MeasuredSize.X;
			let childH = child.MeasuredSize.Y;

			var rect = GravityHelper.Apply(gravity, contentW, contentH, childW, childH, margin);
			rect.X += Padding.Left;
			rect.Y += Padding.Top;

			child.Layout(rect.X, rect.Y, rect.Width, rect.Height);
		}
	}

}
