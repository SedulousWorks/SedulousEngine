namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;

/// Stacks children on top of each other, positioned by Gravity.
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
		let pad = Padding.Value;
		float maxW = 0, maxH = 0;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility.Value == .Gone) continue;

			let margin = child.LayoutParams?.Margin ?? Thickness();
			let inner = MakeChildConstraints(constraints.Deflate(pad), child);
			child.Measure(inner);

			maxW = Math.Max(maxW, child.MeasuredSize.X + margin.TotalHorizontal);
			maxH = Math.Max(maxH, child.MeasuredSize.Y + margin.TotalVertical);
		}

		MeasuredSize = .(
			constraints.ConstrainWidth(maxW + pad.TotalHorizontal),
			constraints.ConstrainHeight(maxH + pad.TotalVertical));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		let pad = Padding.Value;
		let contentW = width - pad.TotalHorizontal;
		let contentH = height - pad.TotalVertical;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility.Value == .Gone) continue;

			let flp = child.LayoutParams as FrameLayout.LayoutParams;
			Gravity gravity = (flp != null) ? flp.Gravity : .None;
			let margin = child.LayoutParams?.Margin ?? Thickness();

			var rect = GravityHelper.Apply(gravity, contentW, contentH,
				child.MeasuredSize.X, child.MeasuredSize.Y, margin);
			rect.X += pad.Left;
			rect.Y += pad.Top;

			child.Layout(rect.X, rect.Y, rect.Width, rect.Height);
		}
	}
}
