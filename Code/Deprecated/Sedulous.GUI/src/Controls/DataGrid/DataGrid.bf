using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A control for displaying tabular data with sortable, resizable columns.
public class DataGrid : Control
{
	// Columns and data
	private List<DataGridColumn> mColumns = new .() ~ DeleteContainerAndItems!(_);
	private List<Object> mItems = new .() ~ delete _;  // Row data objects (not owned)
	private List<int> mDisplayOrder = new .() ~ delete _;  // Sorted display order

	// Layout
	private float mHeaderHeight = 24;
	private float mRowHeight = 22;
	private float mHorizontalOffset = 0;
	private float mVerticalOffset = 0;

	// Selection
	private SelectionMode mSelectionMode = .Extended;
	private List<int> mSelectedIndices = new .() ~ delete _;
	private int mFocusedIndex = -1;
	private int mAnchorIndex = -1;

	// Hover state
	private int mHoveredRowIndex = -1;
	private int mHoveredColumnIndex = -1;
	private bool mHoveringHeader = false;

	// Resize state
	private bool mIsResizing = false;
	private int mResizeColumnIndex = -1;
	private float mResizeStartX = 0;
	private float mResizeStartWidth = 0;

	// Scrollbars
	private ScrollBar mVerticalScrollBar ~ delete _;
	private ScrollBar mHorizontalScrollBar ~ delete _;
	private bool mShowVerticalScrollBar = false;
	private bool mShowHorizontalScrollBar = false;
	private float mScrollBarThickness = 12;

	// Events
	private EventAccessor<delegate void(DataGrid)> mSelectionChanged = new .() ~ delete _;
	private EventAccessor<delegate void(DataGrid, DataGridColumn)> mSortChanged = new .() ~ delete _;

	// Image support
	private ImageBrush? mGridBackgroundImage;
	private ImageBrush? mHeaderImage;
	private ImageBrush? mRowSelectionImage;
	private ImageBrush? mRowHoverImage;

	// Theme colors (computed from palette)
	private Color mBackgroundColor;
	private Color mBorderColor;
	private Color mHeaderBackgroundColor;
	private Color mHeaderBorderColor;
	private Color mRowBackgroundColor;
	private Color mRowAlternateColor;
	private Color mRowHoverColor;
	private Color mSelectionColor;
	private Color mSelectionBorderColor;
	private Color mCellBorderColor;
	private Color mRowBorderColor;

	/// Creates a new DataGrid.
	public this()
	{
		IsFocusable = true;
		IsTabStop = true;

		// Initialize default colors (will be updated by ApplyThemeDefaults)
		mBackgroundColor = Color(30, 30, 30, 255);
		mBorderColor = Color(60, 60, 60, 255);
		mHeaderBackgroundColor = Color(40, 40, 40, 255);
		mHeaderBorderColor = Color(60, 60, 60, 255);
		mRowBackgroundColor = Color(30, 30, 30, 255);
		mRowAlternateColor = Color(35, 35, 35, 255);
		mRowHoverColor = Color(45, 45, 45, 255);
		mSelectionColor = Color(50, 80, 120, 255);
		mSelectionBorderColor = Color(80, 120, 180, 200);
		mCellBorderColor = Color(50, 50, 50, 255);
		mRowBorderColor = Color(45, 45, 45, 255);

		mVerticalScrollBar = new ScrollBar(.Vertical);
		mVerticalScrollBar.Thickness = mScrollBarThickness;
		mVerticalScrollBar.SetParent(this);
		mVerticalScrollBar.Scroll.Subscribe(new (sb, value) => {
			mVerticalOffset = value;
			InvalidateLayout();
		});

		mHorizontalScrollBar = new ScrollBar(.Horizontal);
		mHorizontalScrollBar.Thickness = mScrollBarThickness;
		mHorizontalScrollBar.SetParent(this);
		mHorizontalScrollBar.Scroll.Subscribe(new (sb, value) => {
			mHorizontalOffset = value;
			InvalidateLayout();
		});
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "DataGrid";

	/// Header row height.
	public float HeaderHeight
	{
		get => mHeaderHeight;
		set { mHeaderHeight = value; InvalidateLayout(); }
	}

	/// Row height.
	public float RowHeight
	{
		get => mRowHeight;
		set { mRowHeight = value; InvalidateLayout(); }
	}

	/// Selection mode.
	public SelectionMode SelectionMode
	{
		get => mSelectionMode;
		set => mSelectionMode = value;
	}

	/// Currently selected row indices.
	public List<int> SelectedIndices => mSelectedIndices;

	/// First selected index, or -1 if none.
	public int SelectedIndex
	{
		get => mSelectedIndices.Count > 0 ? mSelectedIndices[0] : -1;
		set
		{
			mSelectedIndices.Clear();
			if (value >= 0 && value < mItems.Count)
			{
				mSelectedIndices.Add(value);
				mFocusedIndex = value;
			}
			mSelectionChanged.[Friend]Invoke(this);
		}
	}

	/// Event fired when selection changes.
	public EventAccessor<delegate void(DataGrid)> SelectionChanged => mSelectionChanged;

	/// Image for the grid background (replaces background fill + border).
	public ImageBrush? GridBackgroundImage
	{
		get => mGridBackgroundImage;
		set => mGridBackgroundImage = value;
	}

	/// Image for the header row background.
	public ImageBrush? HeaderImage
	{
		get => mHeaderImage;
		set => mHeaderImage = value;
	}

	/// Image for selected row backgrounds.
	public ImageBrush? RowSelectionImage
	{
		get => mRowSelectionImage;
		set => mRowSelectionImage = value;
	}

	/// Image for hovered row backgrounds.
	public ImageBrush? RowHoverImage
	{
		get => mRowHoverImage;
		set => mRowHoverImage = value;
	}

	/// Event fired when sort changes.
	public EventAccessor<delegate void(DataGrid, DataGridColumn)> SortChanged => mSortChanged;

	/// Columns collection.
	public List<DataGridColumn> Columns => mColumns;

	/// Items (row data) collection.
	public List<Object> Items => mItems;

	/// Adds a column to the grid.
	public void AddColumn(DataGridColumn column)
	{
		mColumns.Add(column);
		InvalidateLayout();
	}

	/// Sets the items (row data) for the grid.
	public void SetItems(List<Object> items)
	{
		mItems.Clear();
		mDisplayOrder.Clear();
		mSelectedIndices.Clear();
		mFocusedIndex = -1;

		for (let item in items)
		{
			mItems.Add(item);
			mDisplayOrder.Add(mItems.Count - 1);
		}
		InvalidateLayout();
	}

	/// Clears all items.
	public void ClearItems()
	{
		mItems.Clear();
		mDisplayOrder.Clear();
		mSelectedIndices.Clear();
		mFocusedIndex = -1;
		InvalidateLayout();
	}

	/// Returns whether an index is selected.
	public bool IsSelected(int index)
	{
		return mSelectedIndices.Contains(index);
	}

	/// Selects a single row.
	public void SelectSingle(int index)
	{
		mSelectedIndices.Clear();
		if (index >= 0 && index < mItems.Count)
		{
			mSelectedIndices.Add(index);
			mFocusedIndex = index;
			mAnchorIndex = index;
		}
		mSelectionChanged.[Friend]Invoke(this);
	}

	/// Toggles selection of a row.
	public void ToggleSelection(int index)
	{
		if (index < 0 || index >= mItems.Count)
			return;

		let existingIdx = mSelectedIndices.IndexOf(index);
		if (existingIdx >= 0)
			mSelectedIndices.RemoveAt(existingIdx);
		else
			mSelectedIndices.Add(index);

		mFocusedIndex = index;
		mSelectionChanged.[Friend]Invoke(this);
	}

	/// Selects a range of rows.
	public void SelectRange(int fromIndex, int toIndex)
	{
		mSelectedIndices.Clear();
		let start = Math.Min(fromIndex, toIndex);
		let end = Math.Max(fromIndex, toIndex);
		for (int i = start; i <= end; i++)
		{
			if (i >= 0 && i < mItems.Count)
				mSelectedIndices.Add(i);
		}
		mSelectionChanged.[Friend]Invoke(this);
	}

	/// Selects all rows.
	public void SelectAll()
	{
		mSelectedIndices.Clear();
		for (int i = 0; i < mItems.Count; i++)
			mSelectedIndices.Add(i);
		mSelectionChanged.[Friend]Invoke(this);
	}

	/// Sorts by the given column.
	public void SortByColumn(DataGridColumn column)
	{
		if (column == null || !column.CanSort)
			return;

		// Toggle sort direction
		if (column.SortDirection == null)
			column.SortDirection = .Ascending;
		else if (column.SortDirection == .Ascending)
			column.SortDirection = .Descending;
		else
			column.SortDirection = null;

		// Clear other column sorts
		for (let col in mColumns)
		{
			if (col != column)
				col.SortDirection = null;
		}

		// Apply sort
		ApplySort(column);
		mSortChanged.[Friend]Invoke(this, column);
	}

	/// Applies the current sort to display order.
	private void ApplySort(DataGridColumn column)
	{
		if (column.SortDirection == null)
		{
			// Reset to natural order
			mDisplayOrder.Clear();
			for (int i = 0; i < mItems.Count; i++)
				mDisplayOrder.Add(i);
			return;
		}

		let ascending = column.SortDirection == .Ascending;

		// Simple bubble sort for now (could optimize for large datasets)
		for (int i = 0; i < mDisplayOrder.Count - 1; i++)
		{
			for (int j = 0; j < mDisplayOrder.Count - i - 1; j++)
			{
				let idx1 = mDisplayOrder[j];
				let idx2 = mDisplayOrder[j + 1];
				let val1 = column.GetCellValue(mItems[idx1]);
				let val2 = column.GetCellValue(mItems[idx2]);
				let cmp = column.CompareCellValues(val1, val2);

				// Delete boxed values (not Strings which are owned elsewhere)
				if (val1 != null && !(val1 is String))
					delete val1;
				if (val2 != null && !(val2 is String))
					delete val2;

				bool shouldSwap = ascending ? (cmp > 0) : (cmp < 0);
				if (shouldSwap)
				{
					mDisplayOrder[j] = idx2;
					mDisplayOrder[j + 1] = idx1;
				}
			}
		}
	}

	// === Context ===

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		mVerticalScrollBar.OnAttachedToContext(context);
		mHorizontalScrollBar.OnAttachedToContext(context);
	}

	/// Gets current theme colors for rendering (called each frame to support theme changes).
	private void GetThemeColors()
	{
		let theme = Context?.Theme;
		let palette = theme?.Palette ?? Palette();

		// Get theme styles
		let gridStyle = theme?.GetControlStyle("DataGrid") ?? ControlStyle();
		let headerStyle = theme?.GetControlStyle("DataGridHeader") ?? ControlStyle();
		let cellStyle = theme?.GetControlStyle("DataGridCell") ?? ControlStyle();

		// Fallback colors
		let defaultBgColor = Color(30, 30, 30, 255);
		let defaultBorderColor = Color(60, 60, 60, 255);

		// Main grid colors from theme style
		mBackgroundColor = gridStyle.Background.A > 0 ? gridStyle.Background : defaultBgColor;
		mBorderColor = gridStyle.BorderColor.A > 0 ? gridStyle.BorderColor : defaultBorderColor;

		// Header colors from theme style
		mHeaderBackgroundColor = headerStyle.Background.A > 0 ? headerStyle.Background : Palette.Lighten(mBackgroundColor, 0.05f);
		mHeaderBorderColor = headerStyle.BorderColor.A > 0 ? headerStyle.BorderColor : mBorderColor;

		// Row colors from theme style
		mRowBackgroundColor = cellStyle.Background.A > 0 ? cellStyle.Background : mBackgroundColor;
		mRowAlternateColor = Palette.Lighten(mRowBackgroundColor, 0.03f);
		mRowHoverColor = cellStyle.Hover.Background ?? Palette.ComputeHover(mRowBackgroundColor);
		mCellBorderColor = cellStyle.BorderColor.A > 0 ? cellStyle.BorderColor : Palette.Lighten(mBackgroundColor, 0.08f);
		mRowBorderColor = Palette.Lighten(mBackgroundColor, 0.06f);

		// Selection colors from theme style (Pressed state) or theme
		let selColor = cellStyle.Pressed.Background ?? theme?.SelectionColor ?? palette.Accent;
		if (selColor.A > 0)
		{
			mSelectionColor = selColor;
			mSelectionBorderColor = Palette.Lighten(selColor, 0.2f);
		}
	}

	public override void OnDetachedFromContext()
	{
		mHorizontalScrollBar.OnDetachedFromContext();
		mVerticalScrollBar.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}

	// === Layout ===

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		mVerticalScrollBar.Measure(constraints);
		mHorizontalScrollBar.Measure(constraints);

		// Desired size based on content
		float totalWidth = 0;
		for (let col in mColumns)
			totalWidth += col.Width;

		float totalHeight = mHeaderHeight + mItems.Count * mRowHeight;
		return .(totalWidth, totalHeight);
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		// Calculate content size
		float totalWidth = 0;
		for (let col in mColumns)
			totalWidth += col.Width;
		float totalHeight = mItems.Count * mRowHeight;

		// Determine scrollbar visibility
		float viewportWidth = contentBounds.Width;
		float viewportHeight = contentBounds.Height - mHeaderHeight;

		mShowVerticalScrollBar = totalHeight > viewportHeight;
		mShowHorizontalScrollBar = totalWidth > viewportWidth;

		// Adjust for scrollbar presence
		if (mShowVerticalScrollBar)
			viewportWidth -= mScrollBarThickness;
		if (mShowHorizontalScrollBar)
			viewportHeight -= mScrollBarThickness;

		// Recheck after adjustment
		mShowVerticalScrollBar = totalHeight > viewportHeight;
		mShowHorizontalScrollBar = totalWidth > viewportWidth;

		// Arrange scrollbars
		if (mShowVerticalScrollBar)
		{
			let sbBounds = RectangleF(
				contentBounds.Right - mScrollBarThickness,
				contentBounds.Y + mHeaderHeight,
				mScrollBarThickness,
				viewportHeight
			);
			mVerticalScrollBar.Arrange(sbBounds);
			// Maximum should be total content size, not scrollable range
			mVerticalScrollBar.Maximum = totalHeight;
			mVerticalScrollBar.ViewportSize = viewportHeight;
			mVerticalScrollBar.Value = mVerticalOffset;
		}

		if (mShowHorizontalScrollBar)
		{
			mHorizontalScrollBar.Arrange(.(
				contentBounds.X,
				contentBounds.Bottom - mScrollBarThickness,
				viewportWidth,
				mScrollBarThickness
			));
			// Maximum should be total content size, not scrollable range
			mHorizontalScrollBar.Maximum = totalWidth;
			mHorizontalScrollBar.ViewportSize = viewportWidth;
			mHorizontalScrollBar.Value = mHorizontalOffset;
		}

		// Clamp scroll offsets
		mVerticalOffset = Math.Clamp(mVerticalOffset, 0, Math.Max(0, totalHeight - viewportHeight));
		mHorizontalOffset = Math.Clamp(mHorizontalOffset, 0, Math.Max(0, totalWidth - viewportWidth));
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		// Get current theme colors
		GetThemeColors();

		let bounds = ArrangedBounds;

		// Background
		if (mGridBackgroundImage.HasValue && mGridBackgroundImage.Value.IsValid)
			ctx.DrawImageBrush(mGridBackgroundImage.Value, bounds);
		else
			ctx.FillRect(bounds, mBackgroundColor);

		// Calculate viewport
		float viewportWidth = bounds.Width;
		float viewportHeight = bounds.Height - mHeaderHeight;
		if (mShowVerticalScrollBar) viewportWidth -= mScrollBarThickness;
		if (mShowHorizontalScrollBar) viewportHeight -= mScrollBarThickness;

		// Render header
		RenderHeader(ctx, .(bounds.X, bounds.Y, viewportWidth, mHeaderHeight));

		// Render rows (clipped)
		let rowsRect = RectangleF(bounds.X, bounds.Y + mHeaderHeight, viewportWidth, viewportHeight);
		ctx.PushClipRect(rowsRect);
		RenderRows(ctx, rowsRect);
		ctx.PopClip();

		// Render scrollbars
		if (mShowVerticalScrollBar)
		{
			mVerticalScrollBar.Render(ctx);
		}
		if (mShowHorizontalScrollBar)
			mHorizontalScrollBar.Render(ctx);

		// Border (skip when using grid background image)
		if (!mGridBackgroundImage.HasValue || !mGridBackgroundImage.Value.IsValid)
			ctx.DrawRect(bounds, mBorderColor, 1);
	}

	private void RenderHeader(DrawContext ctx, RectangleF headerBounds)
	{
		// Header background
		if (mHeaderImage.HasValue && mHeaderImage.Value.IsValid)
			ctx.DrawImageBrush(mHeaderImage.Value, headerBounds);
		else
			ctx.FillRect(headerBounds, mHeaderBackgroundColor);

		// Clip to header bounds
		ctx.PushClipRect(headerBounds);

		float x = headerBounds.X - mHorizontalOffset;
		for (int i = 0; i < mColumns.Count; i++)
		{
			let col = mColumns[i];
			let colBounds = RectangleF(x, headerBounds.Y, col.Width, mHeaderHeight);

			let isHovered = mHoveringHeader && mHoveredColumnIndex == i;
			col.RenderHeader(ctx, colBounds, isHovered, this);

			x += col.Width;
		}

		ctx.PopClip();

		// Header bottom border (skip when using header image)
		if (!mHeaderImage.HasValue || !mHeaderImage.Value.IsValid)
			ctx.DrawLine(.(headerBounds.X, headerBounds.Bottom - 1), .(headerBounds.Right, headerBounds.Bottom - 1), mHeaderBorderColor, 1);
	}

	private void RenderRows(DrawContext ctx, RectangleF rowsBounds)
	{
		if (mDisplayOrder.Count == 0)
			return;

		// Calculate visible row range
		int firstVisible = (int)(mVerticalOffset / mRowHeight);
		int lastVisible = (int)((mVerticalOffset + rowsBounds.Height) / mRowHeight) + 1;
		firstVisible = Math.Max(0, firstVisible);
		lastVisible = Math.Min(mDisplayOrder.Count - 1, lastVisible);

		float startY = rowsBounds.Y - (mVerticalOffset % mRowHeight);

		for (int displayIdx = firstVisible; displayIdx <= lastVisible; displayIdx++)
		{
			let dataIdx = mDisplayOrder[displayIdx];
			let rowY = startY + (displayIdx - firstVisible) * mRowHeight;
			let rowBounds = RectangleF(rowsBounds.X, rowY, rowsBounds.Width, mRowHeight);

			// Skip rows completely outside visible area
			if (rowY + mRowHeight <= rowsBounds.Y || rowY >= rowsBounds.Bottom)
				continue;

			RenderRow(ctx, rowBounds, dataIdx, displayIdx);
		}
	}

	private void RenderRow(DrawContext ctx, RectangleF rowBounds, int dataIndex, int displayIndex)
	{
		let rowData = mItems[dataIndex];
		let isSelected = IsSelected(dataIndex);
		let isHovered = !mHoveringHeader && mHoveredRowIndex == displayIndex;
		let isFocused = mFocusedIndex == dataIndex && IsFocused;

		// Row background
		bool drewImage = false;
		if (isSelected && mRowSelectionImage.HasValue && mRowSelectionImage.Value.IsValid)
		{
			ctx.DrawImageBrush(mRowSelectionImage.Value, rowBounds);
			drewImage = true;
		}
		else if (isHovered && mRowHoverImage.HasValue && mRowHoverImage.Value.IsValid)
		{
			ctx.DrawImageBrush(mRowHoverImage.Value, rowBounds);
			drewImage = true;
		}

		if (!drewImage)
		{
			Color bgColor;
			if (isSelected)
				bgColor = mSelectionColor;
			else if (isHovered)
				bgColor = mRowHoverColor;
			else if (displayIndex % 2 == 1)
				bgColor = mRowAlternateColor;
			else
				bgColor = mRowBackgroundColor;

			ctx.FillRect(rowBounds, bgColor);
		}

		// Focus indicator
		if (isFocused)
			ctx.DrawRect(rowBounds, mSelectionBorderColor, 1);

		// Render cells
		float x = rowBounds.X - mHorizontalOffset;
		for (let col in mColumns)
		{
			let cellBounds = RectangleF(x, rowBounds.Y, col.Width, mRowHeight);
			let cellValue = col.GetCellValue(rowData);

			// Only render if visible
			if (cellBounds.Right > rowBounds.X && cellBounds.X < rowBounds.Right)
			{
				col.RenderCell(ctx, cellBounds, cellValue, isSelected, isHovered, this);

				// Cell border
				ctx.DrawLine(.(cellBounds.Right - 1, cellBounds.Y), .(cellBounds.Right - 1, cellBounds.Bottom), mCellBorderColor, 1);
			}

			// Delete boxed values (not Strings which are owned elsewhere)
			if (cellValue != null && !(cellValue is String))
				delete cellValue;

			x += col.Width;
		}

		// Row bottom border
		ctx.DrawLine(.(rowBounds.X, rowBounds.Bottom - 1), .(rowBounds.Right, rowBounds.Bottom - 1), mRowBorderColor, 1);
	}

	// === Input ===

	protected override void OnMouseMove(MouseEventArgs e)
	{
		base.OnMouseMove(e);

		let point = Vector2(e.ScreenX, e.ScreenY);
		let bounds = ArrangedBounds;

		if (mIsResizing)
		{
			// Handle column resize
			let delta = point.X - mResizeStartX;
			let newWidth = mResizeStartWidth + delta;
			mColumns[mResizeColumnIndex].Width = newWidth;
			InvalidateLayout();
			return;
		}

		// Check if in header area
		let headerBounds = RectangleF(bounds.X, bounds.Y, bounds.Width, mHeaderHeight);
		mHoveringHeader = headerBounds.Contains(point.X, point.Y);

		if (mHoveringHeader)
		{
			// Find hovered column
			float x = bounds.X - mHorizontalOffset;
			mHoveredColumnIndex = -1;
			for (int i = 0; i < mColumns.Count; i++)
			{
				let col = mColumns[i];
				if (point.X >= x && point.X < x + col.Width)
				{
					mHoveredColumnIndex = i;

					// Check if near resize edge
					if (col.CanResize && point.X > x + col.Width - 5)
					{
						// TODO: Change cursor to resize cursor
					}
					break;
				}
				x += col.Width;
			}
			mHoveredRowIndex = -1;
		}
		else
		{
			// Find hovered row
			mHoveredColumnIndex = -1;
			float viewportTop = bounds.Y + mHeaderHeight;
			if (point.Y >= viewportTop)
			{
				let relativeY = point.Y - viewportTop + mVerticalOffset;
				mHoveredRowIndex = (int)(relativeY / mRowHeight);
				if (mHoveredRowIndex >= mDisplayOrder.Count)
					mHoveredRowIndex = -1;
			}
			else
			{
				mHoveredRowIndex = -1;
			}
		}
	}

	protected override void OnMouseLeave(MouseEventArgs e)
	{
		base.OnMouseLeave(e);
		mHoveredRowIndex = -1;
		mHoveredColumnIndex = -1;
		mHoveringHeader = false;
	}

	protected override void OnMouseDown(MouseButtonEventArgs e)
	{
		base.OnMouseDown(e);

		if (e.Button != .Left)
			return;

		let point = Vector2(e.ScreenX, e.ScreenY);
		let bounds = ArrangedBounds;

		// Check header click
		let headerBounds = RectangleF(bounds.X, bounds.Y, bounds.Width, mHeaderHeight);
		if (headerBounds.Contains(point.X, point.Y))
		{
			float x = bounds.X - mHorizontalOffset;
			for (int i = 0; i < mColumns.Count; i++)
			{
				let col = mColumns[i];
				let colRight = x + col.Width;

				// Check resize edge
				if (col.CanResize && point.X > colRight - 5 && point.X <= colRight)
				{
					mIsResizing = true;
					mResizeColumnIndex = i;
					mResizeStartX = point.X;
					mResizeStartWidth = col.Width;
					if (Context != null)
						Context.FocusManager?.SetCapture(this);
					e.Handled = true;
					return;
				}

				// Check column click for sort
				if (point.X >= x && point.X < colRight)
				{
					if (col.CanSort)
						SortByColumn(col);
					e.Handled = true;
					return;
				}

				x += col.Width;
			}
			return;
		}

		// Check row click
		if (mHoveredRowIndex >= 0 && mHoveredRowIndex < mDisplayOrder.Count)
		{
			let dataIdx = mDisplayOrder[mHoveredRowIndex];
			let hasCtrl = e.HasModifier(.Ctrl);
			let hasShift = e.HasModifier(.Shift);

			Context?.FocusManager?.SetFocus(this);

			switch (mSelectionMode)
			{
			case .Single:
				SelectSingle(dataIdx);
			case .Multiple:
				ToggleSelection(dataIdx);
			case .Extended:
				if (hasShift && mAnchorIndex >= 0)
					SelectRange(mAnchorIndex, dataIdx);
				else if (hasCtrl)
					ToggleSelection(dataIdx);
				else
				{
					SelectSingle(dataIdx);
					mAnchorIndex = dataIdx;
				}
			}

			e.Handled = true;
		}
	}

	protected override void OnMouseUp(MouseButtonEventArgs e)
	{
		base.OnMouseUp(e);

		if (mIsResizing)
		{
			mIsResizing = false;
			if (Context != null)
				Context.FocusManager?.ReleaseCapture();
		}
	}

	protected override void OnMouseWheel(MouseWheelEventArgs e)
	{
		base.OnMouseWheel(e);

		let scrollAmount = mRowHeight * 3;
		mVerticalOffset -= e.DeltaY * scrollAmount;

		// Clamp
		float totalHeight = mItems.Count * mRowHeight;
		float viewportHeight = ArrangedBounds.Height - mHeaderHeight;
		if (mShowHorizontalScrollBar) viewportHeight -= mScrollBarThickness;
		mVerticalOffset = Math.Clamp(mVerticalOffset, 0, Math.Max(0, totalHeight - viewportHeight));

		InvalidateLayout();
		e.Handled = true;
	}

	protected override void OnKeyDown(KeyEventArgs e)
	{
		base.OnKeyDown(e);

		let hasCtrl = e.HasModifier(.Ctrl);
		let hasShift = e.HasModifier(.Shift);

		switch (e.Key)
		{
		case .Up:
			NavigateUp(hasShift, hasCtrl);
			e.Handled = true;
		case .Down:
			NavigateDown(hasShift, hasCtrl);
			e.Handled = true;
		case .Home:
			if (hasCtrl)
				NavigateToStart(hasShift);
			e.Handled = true;
		case .End:
			if (hasCtrl)
				NavigateToEnd(hasShift);
			e.Handled = true;
		case .A:
			if (hasCtrl && mSelectionMode != .Single)
			{
				SelectAll();
				e.Handled = true;
			}
		default:
		}
	}

	private void NavigateUp(bool extend, bool preserveSelection)
	{
		if (mDisplayOrder.Count == 0) return;

		int newFocus = mFocusedIndex >= 0 ? mFocusedIndex - 1 : 0;
		if (newFocus < 0) newFocus = 0;

		// Find display index for this data index
		for (int i = 0; i < mDisplayOrder.Count; i++)
		{
			if (mDisplayOrder[i] == mFocusedIndex && i > 0)
			{
				newFocus = mDisplayOrder[i - 1];
				break;
			}
		}

		if (extend && mSelectionMode == .Extended)
			SelectRange(mAnchorIndex, newFocus);
		else if (!preserveSelection)
		{
			SelectSingle(newFocus);
			mAnchorIndex = newFocus;
		}

		mFocusedIndex = newFocus;
		ScrollIntoView(newFocus);
	}

	private void NavigateDown(bool extend, bool preserveSelection)
	{
		if (mDisplayOrder.Count == 0) return;

		int newFocus = mFocusedIndex >= 0 ? mFocusedIndex + 1 : 0;
		if (newFocus >= mItems.Count) newFocus = mItems.Count - 1;

		// Find display index for this data index
		for (int i = 0; i < mDisplayOrder.Count; i++)
		{
			if (mDisplayOrder[i] == mFocusedIndex && i < mDisplayOrder.Count - 1)
			{
				newFocus = mDisplayOrder[i + 1];
				break;
			}
		}

		if (extend && mSelectionMode == .Extended)
			SelectRange(mAnchorIndex, newFocus);
		else if (!preserveSelection)
		{
			SelectSingle(newFocus);
			mAnchorIndex = newFocus;
		}

		mFocusedIndex = newFocus;
		ScrollIntoView(newFocus);
	}

	private void NavigateToStart(bool extend)
	{
		if (mDisplayOrder.Count == 0) return;

		let newFocus = mDisplayOrder[0];

		if (extend && mSelectionMode == .Extended)
			SelectRange(mAnchorIndex, newFocus);
		else
		{
			SelectSingle(newFocus);
			mAnchorIndex = newFocus;
		}

		mFocusedIndex = newFocus;
		ScrollIntoView(newFocus);
	}

	private void NavigateToEnd(bool extend)
	{
		if (mDisplayOrder.Count == 0) return;

		let newFocus = mDisplayOrder[mDisplayOrder.Count - 1];

		if (extend && mSelectionMode == .Extended)
			SelectRange(mAnchorIndex, newFocus);
		else
		{
			SelectSingle(newFocus);
			mAnchorIndex = newFocus;
		}

		mFocusedIndex = newFocus;
		ScrollIntoView(newFocus);
	}

	private void ScrollIntoView(int dataIndex)
	{
		// Find display index
		int displayIdx = -1;
		for (int i = 0; i < mDisplayOrder.Count; i++)
		{
			if (mDisplayOrder[i] == dataIndex)
			{
				displayIdx = i;
				break;
			}
		}

		if (displayIdx < 0) return;

		let rowTop = displayIdx * mRowHeight;
		let rowBottom = rowTop + mRowHeight;
		let viewportHeight = ArrangedBounds.Height - mHeaderHeight;

		if (rowTop < mVerticalOffset)
			mVerticalOffset = rowTop;
		else if (rowBottom > mVerticalOffset + viewportHeight)
			mVerticalOffset = rowBottom - viewportHeight;

		InvalidateLayout();
	}

	// === Hit Testing ===

	public override UIElement HitTest(Vector2 point)
	{
		if (Visibility != .Visible)
			return null;
		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		// Check scrollbars
		if (mShowVerticalScrollBar)
		{
			let hit = mVerticalScrollBar.HitTest(point);
			if (hit != null) return hit;
		}
		if (mShowHorizontalScrollBar)
		{
			let hit = mHorizontalScrollBar.HitTest(point);
			if (hit != null) return hit;
		}

		return this;
	}

	// === Visual Children ===

	public override int VisualChildCount => 2;

	public override UIElement GetVisualChild(int index)
	{
		if (index == 0) return mVerticalScrollBar;
		if (index == 1) return mHorizontalScrollBar;
		return null;
	}
}
