namespace Sedulous.UI;

using System;
using System.Collections;

/// Row/column grid with Auto/Star/Pixel sizing per track.
public class GridLayout : ViewGroup
{
	public enum SizeMode { Auto, Pixel, Star }

	public struct TrackDef
	{
		public SizeMode Mode;
		public float Value;    // pixel size or star weight

		public static TrackDef Auto() => .() { Mode = .Auto };
		public static TrackDef Pixel(float px) => .() { Mode = .Pixel, Value = px };
		public static TrackDef Star(float weight = 1) => .() { Mode = .Star, Value = weight };
	}

	public class LayoutParams : Sedulous.UI.LayoutParams
	{
		public int32 Row;
		public int32 Column;
	}

	public List<TrackDef> ColumnDefs = new .() ~ delete _;
	public List<TrackDef> RowDefs = new .() ~ delete _;
	public float HSpacing;
	public float VSpacing;

	public override Sedulous.UI.LayoutParams CreateDefaultLayoutParams()
		=> new GridLayout.LayoutParams();

	private int32 ColCount => (int32)Math.Max(1, ColumnDefs.Count);
	private int32 RowCount => (int32)Math.Max(1, RowDefs.Count);

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		let cols = ColCount;
		let rows = RowCount;

		float[] colWidths = scope float[cols];
		float[] rowHeights = scope float[rows];

		// Pass 1: measure children, compute Auto sizes.
		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let glp = child.LayoutParams as GridLayout.LayoutParams;
			let col = Math.Min((glp != null) ? glp.Column : 0, cols - 1);
			let row = Math.Min((glp != null) ? glp.Row : 0, rows - 1);

			child.Measure(.Unspecified(), .Unspecified());

			let colDef = (col < ColumnDefs.Count) ? ColumnDefs[col] : TrackDef.Auto();
			let rowDef = (row < RowDefs.Count) ? RowDefs[row] : TrackDef.Auto();

			if (colDef.Mode == .Auto)
				colWidths[col] = Math.Max(colWidths[col], child.MeasuredSize.X);
			else if (colDef.Mode == .Pixel)
				colWidths[col] = colDef.Value;

			if (rowDef.Mode == .Auto)
				rowHeights[row] = Math.Max(rowHeights[row], child.MeasuredSize.Y);
			else if (rowDef.Mode == .Pixel)
				rowHeights[row] = rowDef.Value;
		}

		// Distribute remaining space to Star tracks.
		let totalAvailW = (wSpec.Mode != .Unspecified) ? wSpec.Size - Padding.TotalHorizontal - HSpacing * (cols - 1) : 0;
		let totalAvailH = (hSpec.Mode != .Unspecified) ? hSpec.Size - Padding.TotalVertical - VSpacing * (rows - 1) : 0;

		DistributeStars(ColumnDefs, colWidths, cols, totalAvailW);
		DistributeStars(RowDefs, rowHeights, rows, totalAvailH);

		float totalW = Padding.TotalHorizontal + HSpacing * Math.Max(0, cols - 1);
		float totalH = Padding.TotalVertical + VSpacing * Math.Max(0, rows - 1);
		for (let w in colWidths) totalW += w;
		for (let h in rowHeights) totalH += h;

		MeasuredSize = .(wSpec.Resolve(totalW), hSpec.Resolve(totalH));
	}

	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		let cols = ColCount;
		let rows = RowCount;

		float[] colWidths = scope float[cols];
		float[] rowHeights = scope float[rows];

		// Recompute sizes (same as measure but with final constraints).
		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let glp = child.LayoutParams as GridLayout.LayoutParams;
			let col = Math.Min((glp != null) ? glp.Column : 0, cols - 1);
			let row = Math.Min((glp != null) ? glp.Row : 0, rows - 1);

			let colDef = (col < ColumnDefs.Count) ? ColumnDefs[col] : TrackDef.Auto();
			let rowDef = (row < RowDefs.Count) ? RowDefs[row] : TrackDef.Auto();

			if (colDef.Mode == .Auto)
				colWidths[col] = Math.Max(colWidths[col], child.MeasuredSize.X);
			else if (colDef.Mode == .Pixel)
				colWidths[col] = colDef.Value;

			if (rowDef.Mode == .Auto)
				rowHeights[row] = Math.Max(rowHeights[row], child.MeasuredSize.Y);
			else if (rowDef.Mode == .Pixel)
				rowHeights[row] = rowDef.Value;
		}

		let contentW = (right - left) - Padding.TotalHorizontal - HSpacing * Math.Max(0, cols - 1);
		let contentH = (bottom - top) - Padding.TotalVertical - VSpacing * Math.Max(0, rows - 1);
		DistributeStars(ColumnDefs, colWidths, cols, contentW);
		DistributeStars(RowDefs, rowHeights, rows, contentH);

		// Compute cumulative offsets.
		float[] colX = scope float[cols];
		float[] rowY = scope float[rows];
		colX[0] = Padding.Left;
		for (int c = 1; c < cols; c++)
			colX[c] = colX[c - 1] + colWidths[c - 1] + HSpacing;
		rowY[0] = Padding.Top;
		for (int r = 1; r < rows; r++)
			rowY[r] = rowY[r - 1] + rowHeights[r - 1] + VSpacing;

		// Position children.
		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let glp = child.LayoutParams as GridLayout.LayoutParams;
			let col = Math.Min((glp != null) ? glp.Column : 0, cols - 1);
			let row = Math.Min((glp != null) ? glp.Row : 0, rows - 1);

			child.Layout(colX[col], rowY[row], colWidths[col], rowHeights[row]);
		}
	}

	private static void DistributeStars(List<TrackDef> defs, float[] sizes, int32 count, float totalAvail)
	{
		float usedByFixed = 0;
		float totalStarWeight = 0;

		for (int i = 0; i < count; i++)
		{
			let def = (i < defs.Count) ? defs[i] : TrackDef.Auto();
			if (def.Mode == .Star)
				totalStarWeight += def.Value;
			else
				usedByFixed += sizes[i];
		}

		if (totalStarWeight > 0)
		{
			let remaining = Math.Max(0, totalAvail - usedByFixed);
			for (int i = 0; i < count; i++)
			{
				let def = (i < defs.Count) ? defs[i] : TrackDef.Auto();
				if (def.Mode == .Star)
					sizes[i] = remaining * def.Value / totalStarWeight;
			}
		}
	}
}
