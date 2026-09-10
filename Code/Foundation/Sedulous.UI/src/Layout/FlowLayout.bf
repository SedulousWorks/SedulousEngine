using Sedulous.Core;

namespace Sedulous.UI;

/// Wraps children onto new lines when they run out of room, like text.
///
/// Horizontal fills a row and wraps downward; vertical fills a column and wraps sideways. The
/// line breaks are decided during MEASURE and again during arrange, both from margin boxes, so
/// the two passes agree on where the breaks fall.
class FlowLayout : ViewGroup
{
	public Orientation Orientation = .Horizontal;
	public float HSpacing = 0.0f;
	public float VSpacing = 0.0f;

	public this() {}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		if (Orientation == .Horizontal)
			MeasureHorizontal(constraints);
		else
			MeasureVertical(constraints);
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		if (Orientation == .Horizontal)
			LayoutHorizontal(width, height);
		else
			LayoutVertical(width, height);
	}

	private void MeasureHorizontal(BoxConstraints constraints)
	{
		let maxWidth = (constraints.MaxWidth < FloatMax)
			? (constraints.MaxWidth - Padding.TotalHorizontal) : FloatMax;
		// Children are measured LOOSE but BOUNDED: an unbounded fill style leaf handed
		// FloatMax would measure to it and blow the flow apart on the first line.
		let crossMax = (constraints.MaxHeight < FloatMax)
			? Max(0.0f, constraints.MaxHeight - Padding.TotalVertical) : FloatMax;

		var lineWidth = 0.0f;
		var lineHeight = 0.0f;
		var totalWidth = 0.0f;
		var totalHeight = 0.0f;
		var firstInLine = true;

		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (!IsInFlow(child))
				continue;

			child.Measure(.(0, maxWidth, 0, crossMax));
			let marginBox = child.MarginBoxSize;

			// A child that will not fit starts a new line, unless it is the only thing on this
			// one: a single oversized child overflows rather than wrapping onto an empty line.
			if (!firstInLine && ((lineWidth + HSpacing + marginBox.X) > maxWidth))
			{
				totalWidth = Max(totalWidth, lineWidth);
				totalHeight += lineHeight + VSpacing;
				lineWidth = 0;
				lineHeight = 0;
				firstInLine = true;
			}
			if (!firstInLine)
				lineWidth += HSpacing;

			lineWidth += marginBox.X;
			lineHeight = Max(lineHeight, marginBox.Y);
			firstInLine = false;
		}

		// The last line was never closed by a wrap, so it is folded in here.
		totalWidth = Max(totalWidth, lineWidth);
		totalHeight += lineHeight;

		MeasuredSize = .(constraints.ConstrainWidth(totalWidth + Padding.TotalHorizontal),
			constraints.ConstrainHeight(totalHeight + Padding.TotalVertical));
	}

	private void MeasureVertical(BoxConstraints constraints)
	{
		let maxHeight = (constraints.MaxHeight < FloatMax)
			? (constraints.MaxHeight - Padding.TotalVertical) : FloatMax;
		let crossMax = (constraints.MaxWidth < FloatMax)
			? Max(0.0f, constraints.MaxWidth - Padding.TotalHorizontal) : FloatMax;

		var columnWidth = 0.0f;
		var columnHeight = 0.0f;
		var totalWidth = 0.0f;
		var totalHeight = 0.0f;
		var firstInColumn = true;

		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (!IsInFlow(child))
				continue;

			child.Measure(.(0, crossMax, 0, maxHeight));
			let marginBox = child.MarginBoxSize;

			if (!firstInColumn && ((columnHeight + VSpacing + marginBox.Y) > maxHeight))
			{
				totalHeight = Max(totalHeight, columnHeight);
				totalWidth += columnWidth + HSpacing;
				columnWidth = 0;
				columnHeight = 0;
				firstInColumn = true;
			}
			if (!firstInColumn)
				columnHeight += VSpacing;

			columnHeight += marginBox.Y;
			columnWidth = Max(columnWidth, marginBox.X);
			firstInColumn = false;
		}

		totalHeight = Max(totalHeight, columnHeight);
		totalWidth += columnWidth;

		MeasuredSize = .(constraints.ConstrainWidth(totalWidth + Padding.TotalHorizontal),
			constraints.ConstrainHeight(totalHeight + Padding.TotalVertical));
	}

	private void LayoutHorizontal(float width, float height)
	{
		let maxWidth = width - Padding.TotalHorizontal;
		var x = Padding.Left;
		var y = Padding.Top;
		var lineHeight = 0.0f;
		var firstInLine = true;

		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (!IsInFlow(child))
				continue;

			// Placed as MARGIN boxes: the base Layout insets by the margin itself.
			let marginBox = child.MarginBoxSize;

			if (!firstInLine && ((x - Padding.Left + HSpacing + marginBox.X) > maxWidth))
			{
				y += lineHeight + VSpacing;
				x = Padding.Left;
				lineHeight = 0;
				firstInLine = true;
			}
			if (!firstInLine)
				x += HSpacing;

			child.Layout(x, y, marginBox.X, marginBox.Y);
			x += marginBox.X;
			lineHeight = Max(lineHeight, marginBox.Y);
			firstInLine = false;
		}
	}

	private void LayoutVertical(float width, float height)
	{
		let maxHeight = height - Padding.TotalVertical;
		var x = Padding.Left;
		var y = Padding.Top;
		var columnWidth = 0.0f;
		var firstInColumn = true;

		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (!IsInFlow(child))
				continue;

			let marginBox = child.MarginBoxSize;

			if (!firstInColumn && ((y - Padding.Top + VSpacing + marginBox.Y) > maxHeight))
			{
				x += columnWidth + HSpacing;
				y = Padding.Top;
				columnWidth = 0;
				firstInColumn = true;
			}
			if (!firstInColumn)
				y += VSpacing;

			child.Layout(x, y, marginBox.X, marginBox.Y);
			y += marginBox.Y;
			columnWidth = Max(columnWidth, marginBox.X);
			firstInColumn = false;
		}
	}
}
