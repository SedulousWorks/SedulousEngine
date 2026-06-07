namespace Sedulous.GUI;

using System;

/// Positions children at explicit X/Y coordinates.
public class AbsoluteLayout : ViewGroup
{
	public class LayoutParams : Sedulous.GUI.LayoutParams
	{
		public float X;
		public float Y;
	}

	protected override Sedulous.GUI.LayoutParams CreateDefaultLayoutParams()
		=> new AbsoluteLayout.LayoutParams();

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let pad = Padding.Value;
		float maxR = 0, maxB = 0;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility.Value == .Gone) continue;

			let childConstraints = MakeAbsoluteChildConstraints(constraints, child);
			child.Measure(childConstraints);

			let alp = child.LayoutParams as AbsoluteLayout.LayoutParams;
			let x = (alp != null) ? alp.X : 0;
			let y = (alp != null) ? alp.Y : 0;

			maxR = Math.Max(maxR, x + child.MeasuredSize.X);
			maxB = Math.Max(maxB, y + child.MeasuredSize.Y);
		}

		MeasuredSize = .(
			constraints.ConstrainWidth(maxR + pad.TotalHorizontal),
			constraints.ConstrainHeight(maxB + pad.TotalVertical));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		let pad = Padding.Value;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility.Value == .Gone) continue;

			let lp = child.LayoutParams;
			let alp = lp as AbsoluteLayout.LayoutParams;
			let x = pad.Left + ((alp != null) ? alp.X : 0);
			let y = pad.Top + ((alp != null) ? alp.Y : 0);

			float w = child.MeasuredSize.X;
			float h = child.MeasuredSize.Y;

			if (lp != null)
			{
				if (lp.Width case .Match)
					w = Math.Max(0, width - pad.TotalHorizontal - ((alp != null) ? alp.X : 0));
				if (lp.Height case .Match)
					h = Math.Max(0, height - pad.TotalVertical - ((alp != null) ? alp.Y : 0));
			}

			child.Layout(x, y, w, h);
		}
	}

	private BoxConstraints MakeAbsoluteChildConstraints(BoxConstraints parentConstraints, View child)
	{
		let pad = Padding.Value;
		let lp = child.LayoutParams;
		float minW = 0, maxW = float.MaxValue;
		float minH = 0, maxH = float.MaxValue;

		if (lp != null)
		{
			switch (lp.Width)
			{
			case .Fixed(let u):
				let v = u.Resolve(1.0f);
				minW = v; maxW = v;
			case .Match:
				let avail = Math.Max(0, parentConstraints.MaxWidth - pad.TotalHorizontal);
				minW = avail; maxW = avail;
			case .Wrap:
			}

			switch (lp.Height)
			{
			case .Fixed(let u):
				let v = u.Resolve(1.0f);
				minH = v; maxH = v;
			case .Match:
				let avail = Math.Max(0, parentConstraints.MaxHeight - pad.TotalVertical);
				minH = avail; maxH = avail;
			case .Wrap:
			}
		}

		return BoxConstraints(minW, maxW, minH, maxH);
	}
}
