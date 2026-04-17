namespace Sedulous.UI;

using System;

/// Positions children at explicit X/Y coordinates.
public class AbsoluteLayout : ViewGroup
{
	public class LayoutParams : Sedulous.UI.LayoutParams
	{
		public float X;
		public float Y;
	}

	public override Sedulous.UI.LayoutParams CreateDefaultLayoutParams()
		=> new AbsoluteLayout.LayoutParams();

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		float maxR = 0, maxB = 0;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			child.Measure(.Unspecified(), .Unspecified());

			let alp = child.LayoutParams as AbsoluteLayout.LayoutParams;
			let x = (alp != null) ? alp.X : 0;
			let y = (alp != null) ? alp.Y : 0;

			maxR = Math.Max(maxR, x + child.MeasuredSize.X);
			maxB = Math.Max(maxB, y + child.MeasuredSize.Y);
		}

		MeasuredSize = .(wSpec.Resolve(maxR + Padding.TotalHorizontal),
						 hSpec.Resolve(maxB + Padding.TotalVertical));
	}

	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let alp = child.LayoutParams as AbsoluteLayout.LayoutParams;
			let x = Padding.Left + ((alp != null) ? alp.X : 0);
			let y = Padding.Top + ((alp != null) ? alp.Y : 0);

			child.Layout(x, y, child.MeasuredSize.X, child.MeasuredSize.Y);
		}
	}
}
