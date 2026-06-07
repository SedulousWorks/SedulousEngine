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

	public static TrackSize Auto() => .() { Mode = .Auto };
	public static TrackSize Fixed(float px) => .() { Mode = .Fixed, Value = px };
	public static TrackSize Flex(float weight = 1) => .() { Mode = .Flex, Value = weight };
}

/// Row/column grid with Auto/Fixed/Flex sizing per track.
/// Supports auto-flow: children without explicit Row/Column are placed
/// left-to-right, top-to-bottom.
public class GridLayout : ViewGroup
{
	public List<TrackSize> Columns = new .() ~ delete _;
	public List<TrackSize> Rows = new .() ~ delete _;
	public Property<float> ColumnSpacing = new .(0) ~ delete _;
	public Property<float> RowSpacing = new .(0) ~ delete _;
	public Property<bool> AutoFlow = new .(true) ~ delete _;

	protected override void InitializePropertyOwners()
	{
		base.InitializePropertyOwners();
		ColumnSpacing.SetOwner(this);
		RowSpacing.SetOwner(this);
		AutoFlow.SetOwner(this);
	}

	public class LayoutParams : Sedulous.GUI.LayoutParams
	{
		public int32 Row = -1;
		public int32 Column = -1;
		public int32 RowSpan = 1;
		public int32 ColumnSpan = 1;
	}

	protected override Sedulous.GUI.LayoutParams CreateDefaultLayoutParams()
		=> new GridLayout.LayoutParams();

	private int32 ColCount => (int32)Math.Max(1, Columns.Count);
	private int32 RowCount => (int32)Math.Max(1, Rows.Count);

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let pad = Padding.Value;
		let cols = ColCount;
		let rows = RowCount;
		let colSpacing = ColumnSpacing.Value;
		let rowSpacing = RowSpacing.Value;

		if (AutoFlow.Value) AssignAutoFlow(cols, rows);

		float[] colWidths = scope float[cols];
		float[] rowHeights = scope float[rows];

		InitFixedTracks(Columns, colWidths, cols);
		InitFixedTracks(Rows, rowHeights, rows);

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility.Value == .Gone) continue;

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

		let totalAvailW = constraints.MaxWidth - pad.TotalHorizontal - colSpacing * Math.Max(0, cols - 1);
		let totalAvailH = constraints.MaxHeight - pad.TotalVertical - rowSpacing * Math.Max(0, rows - 1);

		DistributeFlex(Columns, colWidths, cols, totalAvailW);
		DistributeFlex(Rows, rowHeights, rows, totalAvailH);

		float totalW = pad.TotalHorizontal + colSpacing * Math.Max(0, cols - 1);
		float totalH = pad.TotalVertical + rowSpacing * Math.Max(0, rows - 1);
		for (let w in colWidths) totalW += w;
		for (let h in rowHeights) totalH += h;

		MeasuredSize = .(constraints.ConstrainWidth(totalW), constraints.ConstrainHeight(totalH));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		let pad = Padding.Value;
		let cols = ColCount;
		let rows = RowCount;
		let colSpacing = ColumnSpacing.Value;
		let rowSpacing = RowSpacing.Value;

		float[] colWidths = scope float[cols];
		float[] rowHeights = scope float[rows];

		InitFixedTracks(Columns, colWidths, cols);
		InitFixedTracks(Rows, rowHeights, rows);

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility.Value == .Gone) continue;

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

		let contentW = width - pad.TotalHorizontal - colSpacing * Math.Max(0, cols - 1);
		let contentH = height - pad.TotalVertical - rowSpacing * Math.Max(0, rows - 1);
		DistributeFlex(Columns, colWidths, cols, contentW);
		DistributeFlex(Rows, rowHeights, rows, contentH);

		float[] colX = scope float[cols];
		float[] rowY = scope float[rows];
		colX[0] = pad.Left;
		for (int c = 1; c < cols; c++)
			colX[c] = colX[c - 1] + colWidths[c - 1] + colSpacing;
		rowY[0] = pad.Top;
		for (int r = 1; r < rows; r++)
			rowY[r] = rowY[r - 1] + rowHeights[r - 1] + rowSpacing;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility.Value == .Gone) continue;

			let glp = child.LayoutParams as GridLayout.LayoutParams;
			let col = Math.Clamp((glp != null) ? glp.Column : 0, 0, cols - 1);
			let row = Math.Clamp((glp != null) ? glp.Row : 0, 0, rows - 1);
			let colSpan = Math.Clamp((glp != null) ? glp.ColumnSpan : 1, 1, cols - col);
			let rowSpan = Math.Clamp((glp != null) ? glp.RowSpan : 1, 1, rows - row);

			float cellW = 0;
			for (int c = col; c < col + colSpan; c++)
			{
				cellW += colWidths[c];
				if (c > col) cellW += colSpacing;
			}
			float cellH = 0;
			for (int r = row; r < row + rowSpan; r++)
			{
				cellH += rowHeights[r];
				if (r > row) cellH += rowSpacing;
			}

			child.Layout(colX[col], rowY[row], cellW, cellH);
		}
	}

	private void AssignAutoFlow(int32 cols, int32 rows)
	{
		int32 nextRow = 0, nextCol = 0;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility.Value == .Gone) continue;

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

	private static void InitFixedTracks(List<TrackSize> defs, float[] sizes, int32 count)
	{
		for (int i = 0; i < count; i++)
		{
			let def = (i < defs.Count) ? defs[i] : TrackSize.Auto();
			if (def.Mode == .Fixed)
				sizes[i] = def.Value;
		}
	}

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
