namespace Sedulous.GUI;

using System;

/// Arranges children left-to-right (horizontal) or top-to-bottom (vertical),
/// wrapping to the next line/column when space runs out.
public class FlowLayout : ViewGroup
{
	public Orientation Orientation = .Horizontal;
	public float HSpacing;
	public float VSpacing;

	protected override void OnMeasure(BoxConstraints constraints)
	{
		if (Orientation == .Horizontal)
			MeasureHorizontal(constraints);
		else
			MeasureVertical(constraints);
	}

	private void MeasureHorizontal(BoxConstraints constraints)
	{
		let maxWidth = (constraints.MaxWidth < float.MaxValue)
			? constraints.MaxWidth - Padding.TotalHorizontal : 100000.0f;

		float lineW = 0, lineH = 0;
		float totalW = 0, totalH = 0;
		bool firstInLine = true;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			child.Measure(BoxConstraints.Expand());
			let cw = child.MeasuredSize.X;
			let ch = child.MeasuredSize.Y;

			if (!firstInLine && lineW + HSpacing + cw > maxWidth)
			{
				totalW = Math.Max(totalW, lineW);
				totalH += lineH + VSpacing;
				lineW = 0; lineH = 0; firstInLine = true;
			}

			if (!firstInLine) lineW += HSpacing;
			lineW += cw;
			lineH = Math.Max(lineH, ch);
			firstInLine = false;
		}

		totalW = Math.Max(totalW, lineW);
		totalH += lineH;

		MeasuredSize = .(
			constraints.ConstrainWidth(totalW + Padding.TotalHorizontal),
			constraints.ConstrainHeight(totalH + Padding.TotalVertical));
	}

	private void MeasureVertical(BoxConstraints constraints)
	{
		let maxHeight = (constraints.MaxHeight < float.MaxValue)
			? constraints.MaxHeight - Padding.TotalVertical : 100000.0f;

		float colW = 0, colH = 0;
		float totalW = 0, totalH = 0;
		bool firstInCol = true;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			child.Measure(BoxConstraints.Expand());
			let cw = child.MeasuredSize.X;
			let ch = child.MeasuredSize.Y;

			if (!firstInCol && colH + VSpacing + ch > maxHeight)
			{
				totalH = Math.Max(totalH, colH);
				totalW += colW + HSpacing;
				colW = 0; colH = 0; firstInCol = true;
			}

			if (!firstInCol) colH += VSpacing;
			colH += ch;
			colW = Math.Max(colW, cw);
			firstInCol = false;
		}

		totalH = Math.Max(totalH, colH);
		totalW += colW;

		MeasuredSize = .(
			constraints.ConstrainWidth(totalW + Padding.TotalHorizontal),
			constraints.ConstrainHeight(totalH + Padding.TotalVertical));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		if (Orientation == .Horizontal)
			LayoutHorizontal(width, height);
		else
			LayoutVertical(width, height);
	}

	private void LayoutHorizontal(float width, float height)
	{
		let maxWidth = width - Padding.TotalHorizontal;
		var xPos = Padding.Left;
		var yPos = Padding.Top;
		float lineH = 0;
		bool firstInLine = true;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let cw = child.MeasuredSize.X;
			let ch = child.MeasuredSize.Y;

			if (!firstInLine && xPos - Padding.Left + HSpacing + cw > maxWidth)
			{
				yPos += lineH + VSpacing;
				xPos = Padding.Left;
				lineH = 0; firstInLine = true;
			}

			if (!firstInLine) xPos += HSpacing;
			child.Layout(xPos, yPos, cw, ch);
			xPos += cw;
			lineH = Math.Max(lineH, ch);
			firstInLine = false;
		}
	}

	private void LayoutVertical(float width, float height)
	{
		let maxHeight = height - Padding.TotalVertical;
		var xPos = Padding.Left;
		var yPos = Padding.Top;
		float colW = 0;
		bool firstInCol = true;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let cw = child.MeasuredSize.X;
			let ch = child.MeasuredSize.Y;

			if (!firstInCol && yPos - Padding.Top + VSpacing + ch > maxHeight)
			{
				xPos += colW + HSpacing;
				yPos = Padding.Top;
				colW = 0; firstInCol = true;
			}

			if (!firstInCol) yPos += VSpacing;
			child.Layout(xPos, yPos, cw, ch);
			yPos += ch;
			colW = Math.Max(colW, cw);
			firstInCol = false;
		}
	}
}
