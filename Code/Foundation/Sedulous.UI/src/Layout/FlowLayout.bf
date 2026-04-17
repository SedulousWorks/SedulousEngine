namespace Sedulous.UI;

using System;

/// Arranges children left-to-right (horizontal) or top-to-bottom (vertical),
/// wrapping to the next line/column when space runs out.
public class FlowLayout : ViewGroup
{
	public Orientation Orientation = .Horizontal;
	public float HSpacing;
	public float VSpacing;

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		if (Orientation == .Horizontal)
			MeasureHorizontal(wSpec, hSpec);
		else
			MeasureVertical(wSpec, hSpec);
	}

	private void MeasureHorizontal(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		let maxWidth = (wSpec.Mode != .Unspecified) ? wSpec.Size - Padding.TotalHorizontal : 100000.0f;

		float lineW = 0, lineH = 0;
		float totalW = 0, totalH = 0;
		bool firstInLine = true;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			child.Measure(.Unspecified(), .Unspecified());
			let cw = child.MeasuredSize.X;
			let ch = child.MeasuredSize.Y;

			if (!firstInLine && lineW + HSpacing + cw > maxWidth)
			{
				// Wrap to next line.
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

		MeasuredSize = .(wSpec.Resolve(totalW + Padding.TotalHorizontal),
						 hSpec.Resolve(totalH + Padding.TotalVertical));
	}

	private void MeasureVertical(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		let maxHeight = (hSpec.Mode != .Unspecified) ? hSpec.Size - Padding.TotalVertical : 100000.0f;

		float colW = 0, colH = 0;
		float totalW = 0, totalH = 0;
		bool firstInCol = true;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			child.Measure(.Unspecified(), .Unspecified());
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

		MeasuredSize = .(wSpec.Resolve(totalW + Padding.TotalHorizontal),
						 hSpec.Resolve(totalH + Padding.TotalVertical));
	}

	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		if (Orientation == .Horizontal)
			LayoutHorizontal(left, top, right, bottom);
		else
			LayoutVertical(left, top, right, bottom);
	}

	private void LayoutHorizontal(float left, float top, float right, float bottom)
	{
		let maxWidth = (right - left) - Padding.TotalHorizontal;
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

	private void LayoutVertical(float left, float top, float right, float bottom)
	{
		let maxHeight = (bottom - top) - Padding.TotalVertical;
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
