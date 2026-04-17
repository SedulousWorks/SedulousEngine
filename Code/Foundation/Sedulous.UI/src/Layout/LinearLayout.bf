namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Arranges children in a horizontal or vertical line with optional weighted distribution.
public class LinearLayout : ViewGroup
{
	public Orientation Orientation = .Vertical;
	public float Spacing;
	/// When true (default) and Orientation is Horizontal, children with
	/// baselines are vertically aligned so their text baselines match.
	public bool BaselineAligned = true;

	public class LayoutParams : Sedulous.UI.LayoutParams
	{
		/// Proportional weight for space distribution (0 = no weight, fixed size).
		public float Weight;
		/// Cross-axis alignment for this child.
		public Gravity Gravity = .None;
	}

	public override Sedulous.UI.LayoutParams CreateDefaultLayoutParams()
	{
		return new LinearLayout.LayoutParams();
	}

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		if (Orientation == .Vertical)
			MeasureVertical(wSpec, hSpec);
		else
			MeasureHorizontal(wSpec, hSpec);
	}

	private void MeasureVertical(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		float totalH = Padding.Top + Padding.Bottom;
		float maxW = 0;
		float totalWeight = 0;
		int visibleCount = 0;

		// Pass 1: measure fixed children, sum weights
		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;
			visibleCount++;

			let llp = child.LayoutParams as LinearLayout.LayoutParams;
			let margin = child.LayoutParams?.Margin ?? Thickness();
			let weight = (llp != null) ? llp.Weight : 0;

			if (weight > 0)
			{
				totalWeight += weight;
				continue; // measured in pass 2
			}

			let childWSpec = MakeChildMeasureSpec(wSpec, Padding.TotalHorizontal + margin.TotalHorizontal, child.LayoutParams?.Width ?? Sedulous.UI.LayoutParams.WrapContent);
			let childHSpec = MakeChildMeasureSpec(hSpec, totalH + margin.TotalVertical, child.LayoutParams?.Height ?? Sedulous.UI.LayoutParams.WrapContent);

			child.Measure(childWSpec, childHSpec);
			totalH += child.MeasuredSize.Y + margin.TotalVertical;
			maxW = Math.Max(maxW, child.MeasuredSize.X + margin.TotalHorizontal);
		}

		// Add spacing between visible children
		if (visibleCount > 1)
			totalH += Spacing * (visibleCount - 1);

		// Pass 2: distribute remaining space to weighted children
		if (totalWeight > 0)
		{
			let totalAvailable = hSpec.Size;
			let remaining = Math.Max(0, totalAvailable - totalH);

			for (int i = 0; i < ChildCount; i++)
			{
				let child = GetChildAt(i);
				if (child.Visibility == .Gone) continue;

				let llp = child.LayoutParams as LinearLayout.LayoutParams;
				let weight = (llp != null) ? llp.Weight : 0;
				if (weight <= 0) continue;

				let margin = child.LayoutParams?.Margin ?? Thickness();
				let childH = remaining * weight / totalWeight;

				let childWSpec = MakeChildMeasureSpec(wSpec, Padding.TotalHorizontal + margin.TotalHorizontal, child.LayoutParams?.Width ?? Sedulous.UI.LayoutParams.WrapContent);
				child.Measure(childWSpec, .Exactly(childH));
				totalH += childH + margin.TotalVertical;
				maxW = Math.Max(maxW, child.MeasuredSize.X + margin.TotalHorizontal);
			}
		}

		MeasuredSize = .(wSpec.Resolve(maxW + Padding.TotalHorizontal),
						 hSpec.Resolve(totalH));
	}

	private void MeasureHorizontal(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		float totalW = Padding.Left + Padding.Right;
		float maxH = 0;
		float totalWeight = 0;
		int visibleCount = 0;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;
			visibleCount++;

			let llp = child.LayoutParams as LinearLayout.LayoutParams;
			let margin = child.LayoutParams?.Margin ?? Thickness();
			let weight = (llp != null) ? llp.Weight : 0;

			if (weight > 0)
			{
				totalWeight += weight;
				continue;
			}

			let childWSpec = MakeChildMeasureSpec(wSpec, totalW + margin.TotalHorizontal, child.LayoutParams?.Width ?? Sedulous.UI.LayoutParams.WrapContent);
			let childHSpec = MakeChildMeasureSpec(hSpec, Padding.TotalVertical + margin.TotalVertical, child.LayoutParams?.Height ?? Sedulous.UI.LayoutParams.WrapContent);

			child.Measure(childWSpec, childHSpec);
			totalW += child.MeasuredSize.X + margin.TotalHorizontal;
			maxH = Math.Max(maxH, child.MeasuredSize.Y + margin.TotalVertical);
		}

		if (visibleCount > 1)
			totalW += Spacing * (visibleCount - 1);

		if (totalWeight > 0)
		{
			let totalAvailable = wSpec.Size;
			let remaining = Math.Max(0, totalAvailable - totalW);

			for (int i = 0; i < ChildCount; i++)
			{
				let child = GetChildAt(i);
				if (child.Visibility == .Gone) continue;

				let llp = child.LayoutParams as LinearLayout.LayoutParams;
				let weight = (llp != null) ? llp.Weight : 0;
				if (weight <= 0) continue;

				let margin = child.LayoutParams?.Margin ?? Thickness();
				let childW = remaining * weight / totalWeight;

				let childHSpec = MakeChildMeasureSpec(hSpec, Padding.TotalVertical + margin.TotalVertical, child.LayoutParams?.Height ?? Sedulous.UI.LayoutParams.WrapContent);
				child.Measure(.Exactly(childW), childHSpec);
				totalW += childW + margin.TotalHorizontal;
				maxH = Math.Max(maxH, child.MeasuredSize.Y + margin.TotalVertical);
			}
		}

		MeasuredSize = .(wSpec.Resolve(totalW),
						 hSpec.Resolve(maxH + Padding.TotalVertical));
	}

	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		if (Orientation == .Vertical)
			LayoutVertical(left, top, right, bottom);
		else
			LayoutHorizontal(left, top, right, bottom);
	}

	private void LayoutVertical(float left, float top, float right, float bottom)
	{
		let contentW = (right - left) - Padding.TotalHorizontal;
		var yPos = Padding.Top;
		bool first = true;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			if (!first) yPos += Spacing;
			first = false;

			let margin = child.LayoutParams?.Margin ?? Thickness();
			let llp = child.LayoutParams as LinearLayout.LayoutParams;
			Gravity gravity = (llp != null) ? llp.Gravity : .None;

			let childW = child.MeasuredSize.X;
			let childH = child.MeasuredSize.Y;

			// Apply cross-axis (horizontal) gravity
			var xPos = Padding.Left + margin.Left;
			if (gravity.HasFlag(.CenterH))
				xPos = Padding.Left + (contentW - childW - margin.TotalHorizontal) * 0.5f + margin.Left;
			else if (gravity.HasFlag(.Right))
				xPos = Padding.Left + contentW - childW - margin.Right;
			else if (gravity.HasFlag(.FillH))
			{
				child.Layout(Padding.Left + margin.Left, yPos + margin.Top,
					contentW - margin.TotalHorizontal, childH);
				yPos += childH + margin.TotalVertical;
				continue;
			}

			child.Layout(xPos, yPos + margin.Top, childW, childH);
			yPos += childH + margin.TotalVertical;
		}
	}

	private void LayoutHorizontal(float left, float top, float right, float bottom)
	{
		let contentH = (bottom - top) - Padding.TotalVertical;
		var xPos = Padding.Left;
		bool first = true;

		// Compute max baseline for alignment if enabled.
		float maxBaseline = -1;
		if (BaselineAligned)
		{
			for (int i = 0; i < ChildCount; i++)
			{
				let child = GetChildAt(i);
				if (child.Visibility == .Gone) continue;
				let bl = child.GetBaseline();
				if (bl >= 0) maxBaseline = Math.Max(maxBaseline, bl);
			}
		}

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			if (!first) xPos += Spacing;
			first = false;

			let margin = child.LayoutParams?.Margin ?? Thickness();
			let llp = child.LayoutParams as LinearLayout.LayoutParams;
			Gravity gravity = (llp != null) ? llp.Gravity : .None;

			let childW = child.MeasuredSize.X;
			let childH = child.MeasuredSize.Y;

			// Apply cross-axis (vertical) positioning.
			var yPos = Padding.Top + margin.Top;

			// Baseline alignment takes priority over gravity when baselines
			// are present and no explicit gravity is set.
			let childBaseline = child.GetBaseline();
			if (BaselineAligned && maxBaseline >= 0 && childBaseline >= 0 && gravity == .None)
			{
				yPos = Padding.Top + margin.Top + (maxBaseline - childBaseline);
			}
			else if (gravity.HasFlag(.CenterV))
				yPos = Padding.Top + (contentH - childH - margin.TotalVertical) * 0.5f + margin.Top;
			else if (gravity.HasFlag(.Bottom))
				yPos = Padding.Top + contentH - childH - margin.Bottom;
			else if (gravity.HasFlag(.FillV))
			{
				child.Layout(xPos + margin.Left, Padding.Top + margin.Top,
					childW, contentH - margin.TotalVertical);
				xPos += childW + margin.TotalHorizontal;
				continue;
			}

			child.Layout(xPos + margin.Left, yPos, childW, childH);
			xPos += childW + margin.TotalHorizontal;
		}
	}
}
