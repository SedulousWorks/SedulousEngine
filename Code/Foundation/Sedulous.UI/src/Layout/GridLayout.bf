using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI;

/// Places children in a grid of rows and columns.
///
/// A track is Auto, Fixed or Flex. Fixed takes its size outright, Auto grows to its largest
/// child, and Flex shares out whatever is left in proportion to its weight, which is how a
/// column can be told to take "the rest".
class GridLayout : ViewGroup
{
	/// Empty means a single Auto track, so a grid with nothing declared still works.
	public List<TrackSize> Columns = new .() ~ delete _;
	public List<TrackSize> Rows = new .() ~ delete _;
	public float ColumnSpacing = 0.0f;
	public float RowSpacing = 0.0f;
	/// Places a child that named no cell at the next free one, filling row by row.
	public bool AutoFlow = true;

	/// A child's resolved cell for THIS pass.
	///
	/// Held separately from the child's LayoutStyle on purpose: an auto flowed child keeps its
	/// -1 intent there, so reordering or reparenting re-flows it rather than pinning it to
	/// wherever it first landed.
	private struct Cell
	{
		public int32 Row = 0;
		public int32 Column = 0;
		public int32 RowSpan = 1;
		public int32 ColumnSpan = 1;

		public this() {}
	}

	/// Index aligned with the children, rebuilt each measure.
	private List<Cell> mCells = new .() ~ delete _;

	public this() {}

	private static int32 Clamp(int32 value, int32 low, int32 high) =>
		(value < low) ? low : ((value > high) ? high : value);

	private int32 ColumnCount => (int32)Max(1, Columns.Count);
	private int32 RowCount => (int32)Max(1, Rows.Count);

	private static TrackSize TrackAt(List<TrackSize> defs, int index) =>
		(index < defs.Count) ? defs[index] : TrackSize.Auto();

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let columns = ColumnCount;
		let rows = RowCount;
		ResolvePlacements(columns, rows);

		let columnWidths = scope float[columns];
		let rowHeights = scope float[rows];
		InitFixedTracks(Columns, columnWidths, columns);
		InitFixedTracks(Rows, rowHeights, rows);

		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (!IsInFlow(child))
				continue;

			// LOOSE but BOUNDED: an unbounded fill style leaf measured against FloatMax would
			// blow an auto track out to it. Tracks aggregate MARGIN boxes, so the cell
			// placement and the base margin inset compose.
			child.Measure(.(0, Max(0.0f, constraints.MaxWidth - Padding.TotalHorizontal),
				0, Max(0.0f, constraints.MaxHeight - Padding.TotalVertical)));

			let cell = mCells[i];
			let marginBox = child.MarginBoxSize;
			// Only an AUTO track grows to its content: a fixed one was already told its size,
			// and a flex one takes its share below.
			if (TrackAt(Columns, cell.Column).Mode == .Auto)
				columnWidths[cell.Column] = Max(columnWidths[cell.Column], marginBox.X);
			if (TrackAt(Rows, cell.Row).Mode == .Auto)
				rowHeights[cell.Row] = Max(rowHeights[cell.Row], marginBox.Y);
		}

		let availableWidth = constraints.MaxWidth - Padding.TotalHorizontal
			- ColumnSpacing * (float)Max(0, columns - 1);
		let availableHeight = constraints.MaxHeight - Padding.TotalVertical
			- RowSpacing * (float)Max(0, rows - 1);
		DistributeFlex(Columns, columnWidths, columns, availableWidth);
		DistributeFlex(Rows, rowHeights, rows, availableHeight);

		var totalWidth = Padding.TotalHorizontal + ColumnSpacing * (float)Max(0, columns - 1);
		var totalHeight = Padding.TotalVertical + RowSpacing * (float)Max(0, rows - 1);
		for (let width in columnWidths)
			totalWidth += width;
		for (let height in rowHeights)
			totalHeight += height;

		MeasuredSize = .(constraints.ConstrainWidth(totalWidth),
			constraints.ConstrainHeight(totalHeight));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		let columns = ColumnCount;
		let rows = RowCount;
		// A layout with no measure before it, which a test or a forced arrange can produce.
		if (mCells.Count != ChildCount)
			ResolvePlacements(columns, rows);

		let columnWidths = scope float[columns];
		let rowHeights = scope float[rows];
		InitFixedTracks(Columns, columnWidths, columns);
		InitFixedTracks(Rows, rowHeights, rows);

		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (!IsInFlow(child))
				continue;

			let cell = mCells[i];
			let marginBox = child.MarginBoxSize;
			if (TrackAt(Columns, cell.Column).Mode == .Auto)
				columnWidths[cell.Column] = Max(columnWidths[cell.Column], marginBox.X);
			if (TrackAt(Rows, cell.Row).Mode == .Auto)
				rowHeights[cell.Row] = Max(rowHeights[cell.Row], marginBox.Y);
		}

		let contentWidth = width - Padding.TotalHorizontal
			- ColumnSpacing * (float)Max(0, columns - 1);
		let contentHeight = height - Padding.TotalVertical
			- RowSpacing * (float)Max(0, rows - 1);
		DistributeFlex(Columns, columnWidths, columns, contentWidth);
		DistributeFlex(Rows, rowHeights, rows, contentHeight);

		// The running origin of each track, which is every earlier track plus the gaps.
		let columnX = scope float[columns];
		let rowY = scope float[rows];
		columnX[0] = Padding.Left;
		for (int c = 1; c < columns; c++)
			columnX[c] = columnX[c - 1] + columnWidths[c - 1] + ColumnSpacing;
		rowY[0] = Padding.Top;
		for (int r = 1; r < rows; r++)
			rowY[r] = rowY[r - 1] + rowHeights[r - 1] + RowSpacing;

		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (!IsInFlow(child))
				continue;

			let cell = mCells[i];
			// A spanning cell swallows the gaps BETWEEN the tracks it covers as well as the
			// tracks themselves.
			var cellWidth = 0.0f;
			for (int32 c = cell.Column; c < cell.Column + cell.ColumnSpan; c++)
			{
				cellWidth += columnWidths[c];
				if (c > cell.Column)
					cellWidth += ColumnSpacing;
			}
			var cellHeight = 0.0f;
			for (int32 r = cell.Row; r < cell.Row + cell.RowSpan; r++)
			{
				cellHeight += rowHeights[r];
				if (r > cell.Row)
					cellHeight += RowSpacing;
			}

			child.Layout(columnX[cell.Column], rowY[cell.Row], cellWidth, cellHeight);
		}
	}

	private void ResolvePlacements(int32 columns, int32 rows)
	{
		mCells.Clear();
		mCells.Resize(ChildCount);

		var nextRow = 0;
		var nextColumn = 0;
		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (!IsInFlow(child))
				continue;

			let layout = child.Layout;
			var cell = Cell();
			if (AutoFlow && ((layout.GridRow < 0) || (layout.GridColumn < 0)))
			{
				cell.Row = (int32)nextRow;
				cell.Column = (int32)nextColumn;
				nextColumn++;
				if (nextColumn >= columns)
				{
					nextColumn = 0;
					nextRow++;
				}
			}
			else
			{
				cell.Row = layout.GridRow;
				cell.Column = layout.GridColumn;
			}

			// Clamped rather than rejected: a cell outside the grid lands on the nearest real
			// one, so a mis-declared child is visible and wrong instead of invisible.
			cell.Column = Clamp(cell.Column, 0, columns - 1);
			cell.Row = Clamp(cell.Row, 0, rows - 1);
			cell.ColumnSpan = Clamp(layout.GridColumnSpan, 1, columns - cell.Column);
			cell.RowSpan = Clamp(layout.GridRowSpan, 1, rows - cell.Row);
			mCells[i] = cell;
		}
	}

	private static void InitFixedTracks(List<TrackSize> defs, Span<float> sizes, int32 count)
	{
		for (int i < count)
		{
			let def = TrackAt(defs, i);
			if (def.Mode == .Fixed)
				sizes[i] = def.Value;
		}
	}

	/// Shares what is left among the flex tracks, in proportion to their weights.
	private static void DistributeFlex(List<TrackSize> defs, Span<float> sizes, int32 count,
		float totalAvailable)
	{
		var usedByOthers = 0.0f;
		var totalWeight = 0.0f;
		for (int i < count)
		{
			let def = TrackAt(defs, i);
			if (def.Mode == .Flex)
				totalWeight += def.Value;
			else
				usedByOthers += sizes[i];
		}

		if (totalWeight <= 0)
			return;

		let remaining = Max(0.0f, totalAvailable - usedByOthers);
		for (int i < count)
		{
			let def = TrackAt(defs, i);
			if (def.Mode == .Flex)
				sizes[i] = remaining * def.Value / totalWeight;
		}
	}
}
