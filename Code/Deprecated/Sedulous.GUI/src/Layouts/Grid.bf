using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI;

/// Specifies how a row or column is sized.
public enum GridUnitType
{
	/// Size is determined by the content.
	Auto,
	/// Size is a fixed number of pixels.
	Pixel,
	/// Size is a weighted proportion of available space.
	Star
}

/// Defines the length of a row or column.
public struct GridLength
{
	public GridUnitType Type;
	public float Value;

	public this(float value, GridUnitType type = .Pixel)
	{
		Value = value;
		Type = type;
	}

	public static GridLength Auto => .(0, .Auto);
	public static GridLength Star => .(1, .Star);
	public static GridLength StarN(float n) => .(n, .Star);
	public static GridLength Pixels(float pixels) => .(pixels, .Pixel);

	public bool IsAuto => Type == .Auto;
	public bool IsStar => Type == .Star;
	public bool IsAbsolute => Type == .Pixel;
}

/// Defines a row in a Grid.
public class RowDefinition
{
	public GridLength Height = .Star;
	public float MinHeight = 0;
	public float MaxHeight = SizeConstraints.Infinity;

	/// The calculated height after layout.
	public float ActualHeight;
}

/// Defines a column in a Grid.
public class ColumnDefinition
{
	public GridLength Width = .Star;
	public float MinWidth = 0;
	public float MaxWidth = SizeConstraints.Infinity;

	/// The calculated width after layout.
	public float ActualWidth;
}

/// Attached properties for Grid row/column placement.
public static class GridProperties
{
	private static Dictionary<UIElement, int> sRowValues = new .() ~ delete _;
	private static Dictionary<UIElement, int> sColumnValues = new .() ~ delete _;
	private static Dictionary<UIElement, int> sRowSpanValues = new .() ~ delete _;
	private static Dictionary<UIElement, int> sColumnSpanValues = new .() ~ delete _;

	public static int GetRow(UIElement element)
	{
		if (sRowValues.TryGetValue(element, let val))
			return val;
		return 0;
	}

	public static void SetRow(UIElement element, int value)
	{
		sRowValues[element] = Math.Max(0, value);
		element.InvalidateLayout();
	}

	public static int GetColumn(UIElement element)
	{
		if (sColumnValues.TryGetValue(element, let val))
			return val;
		return 0;
	}

	public static void SetColumn(UIElement element, int value)
	{
		sColumnValues[element] = Math.Max(0, value);
		element.InvalidateLayout();
	}

	public static int GetRowSpan(UIElement element)
	{
		if (sRowSpanValues.TryGetValue(element, let val))
			return val;
		return 1;
	}

	public static void SetRowSpan(UIElement element, int value)
	{
		sRowSpanValues[element] = Math.Max(1, value);
		element.InvalidateLayout();
	}

	public static int GetColumnSpan(UIElement element)
	{
		if (sColumnSpanValues.TryGetValue(element, let val))
			return val;
		return 1;
	}

	public static void SetColumnSpan(UIElement element, int value)
	{
		sColumnSpanValues[element] = Math.Max(1, value);
		element.InvalidateLayout();
	}

	public static void ClearAll(UIElement element)
	{
		sRowValues.Remove(element);
		sColumnValues.Remove(element);
		sRowSpanValues.Remove(element);
		sColumnSpanValues.Remove(element);
	}
}

/// A panel that arranges children in a grid of rows and columns.
public class Grid : Panel
{
	private List<RowDefinition> mRowDefinitions = new .() ~ DeleteContainerAndItems!(_);
	private List<ColumnDefinition> mColumnDefinitions = new .() ~ DeleteContainerAndItems!(_);

	// Working arrays for layout calculations
	private float[] mRowHeights ~ delete _;
	private float[] mColumnWidths ~ delete _;

	/// The row definitions for this grid.
	public List<RowDefinition> RowDefinitions => mRowDefinitions;

	/// The column definitions for this grid.
	public List<ColumnDefinition> ColumnDefinitions => mColumnDefinitions;

	/// Gets the effective row count (at least 1).
	private int RowCount => Math.Max(1, mRowDefinitions.Count);

	/// Gets the effective column count (at least 1).
	private int ColumnCount => Math.Max(1, mColumnDefinitions.Count);

	/// Gets the row definition at the given index, or a default if out of range.
	private RowDefinition GetRowDef(int index)
	{
		if (index >= 0 && index < mRowDefinitions.Count)
			return mRowDefinitions[index];
		return null;  // Caller should treat as Star(1)
	}

	/// Gets the column definition at the given index, or a default if out of range.
	private ColumnDefinition GetColDef(int index)
	{
		if (index >= 0 && index < mColumnDefinitions.Count)
			return mColumnDefinitions[index];
		return null;  // Caller should treat as Star(1)
	}

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		int rowCount = RowCount;
		int colCount = ColumnCount;

		// Allocate working arrays
		if (mRowHeights == null || mRowHeights.Count != rowCount)
		{
			delete mRowHeights;
			mRowHeights = new float[rowCount];
		}
		if (mColumnWidths == null || mColumnWidths.Count != colCount)
		{
			delete mColumnWidths;
			mColumnWidths = new float[colCount];
		}

		// Initialize with fixed sizes, zeros for auto/star
		for (int r = 0; r < rowCount; r++)
		{
			let def = GetRowDef(r);
			if (def != null && def.Height.IsAbsolute)
				mRowHeights[r] = Math.Clamp(def.Height.Value, def.MinHeight, def.MaxHeight);
			else
				mRowHeights[r] = 0;
		}
		for (int c = 0; c < colCount; c++)
		{
			let def = GetColDef(c);
			if (def != null && def.Width.IsAbsolute)
				mColumnWidths[c] = Math.Clamp(def.Width.Value, def.MinWidth, def.MaxWidth);
			else
				mColumnWidths[c] = 0;
		}

		// Measure children and update auto sizes
		for (let child in Children)
		{
			if (child.Visibility == .Collapsed)
				continue;

			int row = Math.Min(GridProperties.GetRow(child), rowCount - 1);
			int col = Math.Min(GridProperties.GetColumn(child), colCount - 1);
			int rowSpan = Math.Min(GridProperties.GetRowSpan(child), rowCount - row);
			int colSpan = Math.Min(GridProperties.GetColumnSpan(child), colCount - col);

			// For non-spanning cells in auto rows/columns, measure with unconstrained size
			let childSize = child.Measure(SizeConstraints.Unconstrained);

			// Update auto row heights (only for non-spanning)
			if (rowSpan == 1)
			{
				let def = GetRowDef(row);
				if (def == null || def.Height.IsAuto)
				{
					float minH = def?.MinHeight ?? 0;
					float maxH = def?.MaxHeight ?? SizeConstraints.Infinity;
					mRowHeights[row] = Math.Max(mRowHeights[row], Math.Clamp(childSize.Height, minH, maxH));
				}
			}

			// Update auto column widths (only for non-spanning)
			if (colSpan == 1)
			{
				let def = GetColDef(col);
				if (def == null || def.Width.IsAuto)
				{
					float minW = def?.MinWidth ?? 0;
					float maxW = def?.MaxWidth ?? SizeConstraints.Infinity;
					mColumnWidths[col] = Math.Max(mColumnWidths[col], Math.Clamp(childSize.Width, minW, maxW));
				}
			}
		}

		// Calculate star sizes
		float totalFixedHeight = 0;
		float totalStarHeight = 0;
		for (int r = 0; r < rowCount; r++)
		{
			let def = GetRowDef(r);
			if (def != null && def.Height.IsStar)
				totalStarHeight += def.Height.Value;
			else
				totalFixedHeight += mRowHeights[r];
		}

		float totalFixedWidth = 0;
		float totalStarWidth = 0;
		for (int c = 0; c < colCount; c++)
		{
			let def = GetColDef(c);
			if (def != null && def.Width.IsStar)
				totalStarWidth += def.Width.Value;
			else
				totalFixedWidth += mColumnWidths[c];
		}

		// Distribute remaining space to star rows/columns
		float availableHeight = constraints.MaxHeight - totalFixedHeight;
		float availableWidth = constraints.MaxWidth - totalFixedWidth;

		if (totalStarHeight > 0 && availableHeight > 0)
		{
			float starUnit = availableHeight / totalStarHeight;
			for (int r = 0; r < rowCount; r++)
			{
				let def = GetRowDef(r);
				if (def != null && def.Height.IsStar)
					mRowHeights[r] = Math.Clamp(starUnit * def.Height.Value, def.MinHeight, def.MaxHeight);
			}
		}

		if (totalStarWidth > 0 && availableWidth > 0)
		{
			float starUnit = availableWidth / totalStarWidth;
			for (int c = 0; c < colCount; c++)
			{
				let def = GetColDef(c);
				if (def != null && def.Width.IsStar)
					mColumnWidths[c] = Math.Clamp(starUnit * def.Width.Value, def.MinWidth, def.MaxWidth);
			}
		}

		// Second pass: re-measure all children with actual cell constraints.
		// The first pass used unconstrained sizes (needed for Auto sizing), but children
		// in Pixel/Star cells need to know their actual width/height constraints so they
		// can make correct internal layout decisions (e.g. text wrapping, scroll constraining).
		for (let child in Children)
		{
			if (child.Visibility == .Collapsed)
				continue;

			int row = Math.Min(GridProperties.GetRow(child), rowCount - 1);
			int col = Math.Min(GridProperties.GetColumn(child), colCount - 1);
			int rowSpan = Math.Min(GridProperties.GetRowSpan(child), rowCount - row);
			int colSpan = Math.Min(GridProperties.GetColumnSpan(child), colCount - col);

			float cellWidth = 0;
			for (int c = col; c < col + colSpan; c++)
				cellWidth += mColumnWidths[c];

			float cellHeight = 0;
			for (int r = row; r < row + rowSpan; r++)
				cellHeight += mRowHeights[r];

			child.Measure(SizeConstraints.FromMaximum(cellWidth, cellHeight));
		}

		// Calculate total size
		float totalHeight = 0;
		for (int r = 0; r < rowCount; r++)
			totalHeight += mRowHeights[r];

		float totalWidth = 0;
		for (int c = 0; c < colCount; c++)
			totalWidth += mColumnWidths[c];

		return .(totalWidth, totalHeight);
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		int rowCount = RowCount;
		int colCount = ColumnCount;

		// Recalculate sizes for arrange (may differ from measure if content bounds changed)
		// Calculate fixed/auto sizes first
		float totalFixedHeight = 0;
		float totalStarHeight = 0;
		for (int r = 0; r < rowCount; r++)
		{
			let def = GetRowDef(r);
			if (def != null && def.Height.IsStar)
				totalStarHeight += def.Height.Value;
			else
				totalFixedHeight += mRowHeights[r];
		}

		float totalFixedWidth = 0;
		float totalStarWidth = 0;
		for (int c = 0; c < colCount; c++)
		{
			let def = GetColDef(c);
			if (def != null && def.Width.IsStar)
				totalStarWidth += def.Width.Value;
			else
				totalFixedWidth += mColumnWidths[c];
		}

		// Distribute remaining space to star rows/columns
		float availableHeight = contentBounds.Height - totalFixedHeight;
		float availableWidth = contentBounds.Width - totalFixedWidth;

		if (totalStarHeight > 0)
		{
			float starUnit = Math.Max(0, availableHeight) / totalStarHeight;
			for (int r = 0; r < rowCount; r++)
			{
				let def = GetRowDef(r);
				if (def != null && def.Height.IsStar)
					mRowHeights[r] = Math.Clamp(starUnit * def.Height.Value, def.MinHeight, def.MaxHeight);
			}
		}

		if (totalStarWidth > 0)
		{
			float starUnit = Math.Max(0, availableWidth) / totalStarWidth;
			for (int c = 0; c < colCount; c++)
			{
				let def = GetColDef(c);
				if (def != null && def.Width.IsStar)
					mColumnWidths[c] = Math.Clamp(starUnit * def.Width.Value, def.MinWidth, def.MaxWidth);
			}
		}

		// Store actual sizes in definitions
		for (int r = 0; r < mRowDefinitions.Count; r++)
			mRowDefinitions[r].ActualHeight = mRowHeights[r];
		for (int c = 0; c < mColumnDefinitions.Count; c++)
			mColumnDefinitions[c].ActualWidth = mColumnWidths[c];

		// Arrange children
		for (let child in Children)
		{
			if (child.Visibility == .Collapsed)
				continue;

			int row = Math.Min(GridProperties.GetRow(child), rowCount - 1);
			int col = Math.Min(GridProperties.GetColumn(child), colCount - 1);
			int rowSpan = Math.Min(GridProperties.GetRowSpan(child), rowCount - row);
			int colSpan = Math.Min(GridProperties.GetColumnSpan(child), colCount - col);

			// Calculate cell position
			float x = contentBounds.X;
			for (int c = 0; c < col; c++)
				x += mColumnWidths[c];

			float y = contentBounds.Y;
			for (int r = 0; r < row; r++)
				y += mRowHeights[r];

			// Calculate cell size (including spans)
			float width = 0;
			for (int c = col; c < col + colSpan; c++)
				width += mColumnWidths[c];

			float height = 0;
			for (int r = row; r < row + rowSpan; r++)
				height += mRowHeights[r];

			child.Arrange(.(x, y, width, height));
		}
	}
}
