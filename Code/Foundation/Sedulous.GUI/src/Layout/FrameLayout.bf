namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;

/// Stacks children on top of each other, positioned by Gravity.
/// Simplest ViewGroup - children overlap, each positioned independently.
public class FrameLayout : ViewGroup
{
	public class LayoutParams : Sedulous.GUI.LayoutParams
	{
		public Gravity Gravity = .None;
	}

	protected override Sedulous.GUI.LayoutParams CreateDefaultLayoutParams()
		=> new FrameLayout.LayoutParams();

	protected override void OnMeasure(BoxConstraints constraints)
	{
		float maxW = 0, maxH = 0;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let margin = child.LayoutParams?.Margin ?? Thickness();

			// Use SizeSpec-aware constraints.
			let inner = MakeChildConstraints(
				constraints.Deflate(Padding), child);
			child.Measure(inner);

			maxW = Math.Max(maxW, child.MeasuredSize.X + margin.TotalHorizontal);
			maxH = Math.Max(maxH, child.MeasuredSize.Y + margin.TotalVertical);
		}

		MeasuredSize = .(
			constraints.ConstrainWidth(maxW + Padding.TotalHorizontal),
			constraints.ConstrainHeight(maxH + Padding.TotalVertical));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		let contentW = width - Padding.TotalHorizontal;
		let contentH = height - Padding.TotalVertical;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let flp = child.LayoutParams as FrameLayout.LayoutParams;
			Gravity gravity = (flp != null) ? flp.Gravity : .None;
			let margin = child.LayoutParams?.Margin ?? Thickness();

			var rect = GravityHelper.Apply(gravity, contentW, contentH,
				child.MeasuredSize.X, child.MeasuredSize.Y, margin);
			rect.X += Padding.Left;
			rect.Y += Padding.Top;

			child.Layout(rect.X, rect.Y, rect.Width, rect.Height);
		}
	}
}
