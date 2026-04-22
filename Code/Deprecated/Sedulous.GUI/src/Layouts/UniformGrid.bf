using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI;

/// A grid where all cells have equal size.
/// Children are placed in order, filling rows first.
public class UniformGrid : Panel
{
	private int mRows = 0;  // 0 = auto-calculate
	private int mColumns = 0;  // 0 = auto-calculate
	private int mFirstColumn = 0;  // Starting column offset for first row

	/// Number of rows. 0 means auto-calculate based on children and columns.
	public int Rows
	{
		get => mRows;
		set
		{
			if (mRows != value)
			{
				mRows = Math.Max(0, value);
				InvalidateLayout();
			}
		}
	}

	/// Number of columns. 0 means auto-calculate based on children and rows.
	public int Columns
	{
		get => mColumns;
		set
		{
			if (mColumns != value)
			{
				mColumns = Math.Max(0, value);
				InvalidateLayout();
			}
		}
	}

	/// Starting column offset for the first row.
	public int FirstColumn
	{
		get => mFirstColumn;
		set
		{
			if (mFirstColumn != value)
			{
				mFirstColumn = Math.Max(0, value);
				InvalidateLayout();
			}
		}
	}

	/// Calculates the actual rows and columns based on children count.
	private void CalculateGridSize(out int rows, out int columns)
	{
		int childCount = 0;
		for (let child in Children)
		{
			if (child.Visibility != .Collapsed)
				childCount++;
		}

		if (mRows == 0 && mColumns == 0)
		{
			// Auto-calculate: try to make it square-ish
			columns = (int)Math.Ceiling(Math.Sqrt((float)childCount));
			rows = (int)Math.Ceiling((float)childCount / columns);
		}
		else if (mRows == 0)
		{
			columns = mColumns;
			rows = (int)Math.Ceiling((float)(childCount + mFirstColumn) / columns);
		}
		else if (mColumns == 0)
		{
			rows = mRows;
			columns = (int)Math.Ceiling((float)(childCount + mFirstColumn) / rows);
		}
		else
		{
			rows = mRows;
			columns = mColumns;
		}

		rows = Math.Max(1, rows);
		columns = Math.Max(1, columns);
	}

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		int rows, columns;
		CalculateGridSize(out rows, out columns);

		float cellWidth = constraints.MaxWidth / columns;
		float cellHeight = constraints.MaxHeight / rows;
		let cellConstraints = SizeConstraints.FromMaximum(cellWidth, cellHeight);

		float maxCellWidth = 0;
		float maxCellHeight = 0;

		for (let child in Children)
		{
			if (child.Visibility == .Collapsed)
				continue;

			let childSize = child.Measure(cellConstraints);
			maxCellWidth = Math.Max(maxCellWidth, childSize.Width);
			maxCellHeight = Math.Max(maxCellHeight, childSize.Height);
		}

		return .(maxCellWidth * columns, maxCellHeight * rows);
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		int rows, columns;
		CalculateGridSize(out rows, out columns);

		float cellWidth = contentBounds.Width / columns;
		float cellHeight = contentBounds.Height / rows;

		int index = 0;
		for (let child in Children)
		{
			if (child.Visibility == .Collapsed)
				continue;

			// Calculate row and column for this child
			int adjustedIndex = index + mFirstColumn;
			int col = adjustedIndex % columns;
			int row = adjustedIndex / columns;

			if (row >= rows)
				break;  // No more space

			let cellRect = RectangleF(
				contentBounds.X + col * cellWidth,
				contentBounds.Y + row * cellHeight,
				cellWidth,
				cellHeight
			);

			child.Arrange(cellRect);
			index++;
		}
	}
}
