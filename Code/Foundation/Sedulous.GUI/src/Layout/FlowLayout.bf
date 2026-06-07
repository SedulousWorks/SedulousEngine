namespace Sedulous.GUI;

using System;

/// Arranges children left-to-right (horizontal) or top-to-bottom (vertical),
/// wrapping to the next line/column when space runs out.
public class FlowLayout : ViewGroup
{
	public Property<Orientation> Orientation = new .(.Horizontal) ~ delete _;
	public Property<float> HSpacing = new .(0) ~ delete _;
	public Property<float> VSpacing = new .(0) ~ delete _;

	protected override void InitializePropertyOwners()
	{
		base.InitializePropertyOwners();
		Orientation.SetOwner(this);
		HSpacing.SetOwner(this);
		VSpacing.SetOwner(this);
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		if (Orientation.Value == .Horizontal)
			MeasureHorizontal(constraints);
		else
			MeasureVertical(constraints);
	}

	private void MeasureHorizontal(BoxConstraints constraints)
	{
		let pad = Padding.Value;
		let hSpace = HSpacing.Value;
		let vSpace = VSpacing.Value;
		let maxWidth = (constraints.MaxWidth < float.MaxValue)
			? constraints.MaxWidth - pad.TotalHorizontal : 100000.0f;

		float lineW = 0, lineH = 0;
		float totalW = 0, totalH = 0;
		bool firstInLine = true;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility.Value == .Gone) continue;

			child.Measure(BoxConstraints.Expand());
			let cw = child.MeasuredSize.X;
			let ch = child.MeasuredSize.Y;

			if (!firstInLine && lineW + hSpace + cw > maxWidth)
			{
				totalW = Math.Max(totalW, lineW);
				totalH += lineH + vSpace;
				lineW = 0; lineH = 0; firstInLine = true;
			}

			if (!firstInLine) lineW += hSpace;
			lineW += cw;
			lineH = Math.Max(lineH, ch);
			firstInLine = false;
		}

		totalW = Math.Max(totalW, lineW);
		totalH += lineH;

		MeasuredSize = .(
			constraints.ConstrainWidth(totalW + pad.TotalHorizontal),
			constraints.ConstrainHeight(totalH + pad.TotalVertical));
	}

	private void MeasureVertical(BoxConstraints constraints)
	{
		let pad = Padding.Value;
		let hSpace = HSpacing.Value;
		let vSpace = VSpacing.Value;
		let maxHeight = (constraints.MaxHeight < float.MaxValue)
			? constraints.MaxHeight - pad.TotalVertical : 100000.0f;

		float colW = 0, colH = 0;
		float totalW = 0, totalH = 0;
		bool firstInCol = true;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility.Value == .Gone) continue;

			child.Measure(BoxConstraints.Expand());
			let cw = child.MeasuredSize.X;
			let ch = child.MeasuredSize.Y;

			if (!firstInCol && colH + vSpace + ch > maxHeight)
			{
				totalH = Math.Max(totalH, colH);
				totalW += colW + hSpace;
				colW = 0; colH = 0; firstInCol = true;
			}

			if (!firstInCol) colH += vSpace;
			colH += ch;
			colW = Math.Max(colW, cw);
			firstInCol = false;
		}

		totalH = Math.Max(totalH, colH);
		totalW += colW;

		MeasuredSize = .(
			constraints.ConstrainWidth(totalW + pad.TotalHorizontal),
			constraints.ConstrainHeight(totalH + pad.TotalVertical));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		if (Orientation.Value == .Horizontal)
			LayoutHorizontal(width, height);
		else
			LayoutVertical(width, height);
	}

	private void LayoutHorizontal(float width, float height)
	{
		let pad = Padding.Value;
		let hSpace = HSpacing.Value;
		let vSpace = VSpacing.Value;
		let maxWidth = width - pad.TotalHorizontal;
		var xPos = pad.Left;
		var yPos = pad.Top;
		float lineH = 0;
		bool firstInLine = true;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility.Value == .Gone) continue;

			let cw = child.MeasuredSize.X;
			let ch = child.MeasuredSize.Y;

			if (!firstInLine && xPos - pad.Left + hSpace + cw > maxWidth)
			{
				yPos += lineH + vSpace;
				xPos = pad.Left;
				lineH = 0; firstInLine = true;
			}

			if (!firstInLine) xPos += hSpace;
			child.Layout(xPos, yPos, cw, ch);
			xPos += cw;
			lineH = Math.Max(lineH, ch);
			firstInLine = false;
		}
	}

	private void LayoutVertical(float width, float height)
	{
		let pad = Padding.Value;
		let hSpace = HSpacing.Value;
		let vSpace = VSpacing.Value;
		let maxHeight = height - pad.TotalVertical;
		var xPos = pad.Left;
		var yPos = pad.Top;
		float colW = 0;
		bool firstInCol = true;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility.Value == .Gone) continue;

			let cw = child.MeasuredSize.X;
			let ch = child.MeasuredSize.Y;

			if (!firstInCol && yPos - pad.Top + vSpace + ch > maxHeight)
			{
				xPos += colW + hSpace;
				yPos = pad.Top;
				colW = 0; firstInCol = true;
			}

			if (!firstInCol) yPos += vSpace;
			child.Layout(xPos, yPos, cw, ch);
			yPos += ch;
			colW = Math.Max(colW, cw);
			firstInCol = false;
		}
	}
}
