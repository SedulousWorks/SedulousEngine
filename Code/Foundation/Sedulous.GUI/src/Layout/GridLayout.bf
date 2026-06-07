namespace Sedulous.GUI;

using System;
using System.Collections;

/// Grid track sizing mode.
public enum TrackSizeMode { Auto, Fixed, Flex }

/// Defines the size of a grid track (row or column).
public struct TrackSize
{
	public TrackSizeMode Mode;
	public float Value;

	/// Size to content.
	public static TrackSize Auto() => .() { Mode = .Auto };

	/// Explicit pixel size.
	public static TrackSize Fixed(float px) => .() { Mode = .Fixed, Value = px };

	/// Proportional (weighted) sizing.
	public static TrackSize Flex(float weight = 1) => .() { Mode = .Flex, Value = weight };
}

/// Row/column grid with Auto/Fixed/Flex sizing per track.
/// Supports auto-flow: children without explicit Row/Column are placed
/// left-to-right, top-to-bottom.
public class GridLayout : ViewGroup
{
	public List<TrackSize> Columns = new .() ~ delete _;
	public List<TrackSize> Rows = new .() ~ delete _;
	public float ColumnSpacing;
	public float RowSpacing;

	/// When true (default), children without explicit Row/Column are placed
	/// in the next available cell left-to-right, top-to-bottom.
	public bool AutoFlow = true;

	public class LayoutParams : Sedulous.GUI.LayoutParams
	{
		/// Row index (-1 = auto-flow).
		public int32 Row = -1;
		/// Column index (-1 = auto-flow).
		public int32 Column = -1;
		/// Number of rows this child spans.
		public int32 RowSpan = 1;
		/// Number of columns this child spans.
		public int32 ColumnSpan = 1;
	}

	protected override Sedulous.GUI.LayoutParams CreateDefaultLayoutParams()
		=> new GridLayout.LayoutParams();

	private int32 ColCount => (int32)Math.Max(1, Columns.Count);
	private int32 RowCount => (int32)Math.Max(1, Rows.Count);

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let cols = ColCount;
		let rows = RowCount;

		// Assign auto-flow positions.
		if (AutoFlow) AssignAutoFlow(cols, rows);

		float[] colWidths = scope float[cols];
		float[] rowHeights = scope float[rows];

		// Initialize Fixed tracks (may have no children in them).
		InitFixedTracks(Columns, colWidths, cols);
		InitFixedTracks(Rows, rowHeights, rows);

		// Pass 1: measure children, compute Auto sizes.
		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let glp = child.LayoutParams as GridLayout.LayoutParams;
			let col = Math.Clamp((glp != null) ? glp.Column : 0, 0, cols - 1);
			let row = Math.Clamp((glp != null) ? glp.Row : 0, 0, rows - 1);

			child.Measure(BoxConstraints.Expand());

			let colDef = (col < Columns.Count) ? Columns[col] : TrackSize.Auto();
			let rowDef = (row < Rows.Count) ? Rows[row] : TrackSize.Auto();

			if (colDef.Mode == .Auto)
				colWidths[col] = Math.Max(colWidths[col], child.MeasuredSize.X);

			if (rowDef.Mode == .Auto)
				rowHeights[row] = Math.Max(rowHeights[row], child.MeasuredSize.Y);
		}

		// Distribute remaining space to Flex tracks.
		let totalAvailW = constraints.MaxWidth - Padding.TotalHorizontal - ColumnSpacing * Math.Max(0, cols - 1);
		let totalAvailH = constraints.MaxHeight - Padding.TotalVertical - RowSpacing * Math.Max(0, rows - 1);

		DistributeFlex(Columns, colWidths, cols, totalAvailW);
		DistributeFlex(Rows, rowHeights, rows, totalAvailH);

		float totalW = Padding.TotalHorizontal + ColumnSpacing * Math.Max(0, cols - 1);
		float totalH = Padding.TotalVertical + RowSpacing * Math.Max(0, rows - 1);
		for (let w in colWidths) totalW += w;
		for (let h in rowHeights) totalH += h;

		MeasuredSize = .(constraints.ConstrainWidth(totalW), constraints.ConstrainHeight(totalH));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		let cols = ColCount;
		let rows = RowCount;

		float[] colWidths = scope float[cols];
		float[] rowHeights = scope float[rows];

		// Initialize Fixed tracks.
		InitFixedTracks(Columns, colWidths, cols);
		InitFixedTracks(Rows, rowHeights, rows);

		// Recompute Auto sizes with final constraints.
		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let glp = child.LayoutParams as GridLayout.LayoutParams;
			let col = Math.Clamp((glp != null) ? glp.Column : 0, 0, cols - 1);
			let row = Math.Clamp((glp != null) ? glp.Row : 0, 0, rows - 1);

			let colDef = (col < Columns.Count) ? Columns[col] : TrackSize.Auto();
			let rowDef = (row < Rows.Count) ? Rows[row] : TrackSize.Auto();

			if (colDef.Mode == .Auto)
				colWidths[col] = Math.Max(colWidths[col], child.MeasuredSize.X);

			if (rowDef.Mode == .Auto)
				rowHeights[row] = Math.Max(rowHeights[row], child.MeasuredSize.Y);
		}

		let contentW = width - Padding.TotalHorizontal - ColumnSpacing * Math.Max(0, cols - 1);
		let contentH = height - Padding.TotalVertical - RowSpacing * Math.Max(0, rows - 1);
		DistributeFlex(Columns, colWidths, cols, contentW);
		DistributeFlex(Rows, rowHeights, rows, contentH);

		// Compute cumulative offsets.
		float[] colX = scope float[cols];
		float[] rowY = scope float[rows];
		colX[0] = Padding.Left;
		for (int c = 1; c < cols; c++)
			colX[c] = colX[c - 1] + colWidths[c - 1] + ColumnSpacing;
		rowY[0] = Padding.Top;
		for (int r = 1; r < rows; r++)
			rowY[r] = rowY[r - 1] + rowHeights[r - 1] + RowSpacing;

		// Position children.
		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let glp = child.LayoutParams as GridLayout.LayoutParams;
			let col = Math.Clamp((glp != null) ? glp.Column : 0, 0, cols - 1);
			let row = Math.Clamp((glp != null) ? glp.Row : 0, 0, rows - 1);
			let colSpan = Math.Clamp((glp != null) ? glp.ColumnSpan : 1, 1, cols - col);
			let rowSpan = Math.Clamp((glp != null) ? glp.RowSpan : 1, 1, rows - row);

			// Compute spanned width/height.
			float cellW = 0;
			for (int c = col; c < col + colSpan; c++)
			{
				cellW += colWidths[c];
				if (c > col) cellW += ColumnSpacing;
			}
			float cellH = 0;
			for (int r = row; r < row + rowSpan; r++)
			{
				cellH += rowHeights[r];
				if (r > row) cellH += RowSpacing;
			}

			child.Layout(colX[col], rowY[row], cellW, cellH);
		}
	}

	/// Assign auto-flow positions to children that don't have explicit Row/Column.
	private void AssignAutoFlow(int32 cols, int32 rows)
	{
		int32 nextRow = 0, nextCol = 0;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let glp = child.LayoutParams as GridLayout.LayoutParams;
			if (glp == null) continue;

			if (glp.Row < 0 || glp.Column < 0)
			{
				glp.Row = nextRow;
				glp.Column = nextCol;

				nextCol++;
				if (nextCol >= cols)
				{
					nextCol = 0;
					nextRow++;
				}
			}
		}
	}

	/// Set Fixed track sizes upfront (they don't depend on children).
	private static void InitFixedTracks(List<TrackSize> defs, float[] sizes, int32 count)
	{
		for (int i = 0; i < count; i++)
		{
			let def = (i < defs.Count) ? defs[i] : TrackSize.Auto();
			if (def.Mode == .Fixed)
				sizes[i] = def.Value;
		}
	}

	/// Distribute remaining space to Flex tracks by weight.
	private static void DistributeFlex(List<TrackSize> defs, float[] sizes, int32 count, float totalAvail)
	{
		float usedByFixed = 0;
		float totalFlexWeight = 0;

		for (int i = 0; i < count; i++)
		{
			let def = (i < defs.Count) ? defs[i] : TrackSize.Auto();
			if (def.Mode == .Flex)
				totalFlexWeight += def.Value;
			else
				usedByFixed += sizes[i];
		}

		if (totalFlexWeight > 0)
		{
			let remaining = Math.Max(0, totalAvail - usedByFixed);
			for (int i = 0; i < count; i++)
			{
				let def = (i < defs.Count) ? defs[i] : TrackSize.Auto();
				if (def.Mode == .Flex)
					sizes[i] = remaining * def.Value / totalFlexWeight;
			}
		}
	}
}
