using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// A DataGrid column that displays boolean values as checkboxes.
public class DataGridCheckBoxColumn : DataGridColumn
{
	public delegate Object(Object rowData) ValueGetter ~ delete _;
	public delegate void(Object rowData, bool newValue) ValueSetter ~ delete _;

	/// Creates a checkbox column with the given header.
	public this(StringView header) : base(header)
	{
		Width = 60;
		MinWidth = 40;
	}

	/// Creates a checkbox column with header and value getter.
	public this(StringView header, delegate Object(Object rowData) valueGetter) : base(header)
	{
		Width = 60;
		MinWidth = 40;
		ValueGetter = valueGetter;
	}

	/// Gets the cell value from row data.
	public override Object GetCellValue(Object rowData)
	{
		if (ValueGetter != null)
			return ValueGetter(rowData);
		return null;
	}

	/// Renders the cell as a checkbox.
	public override void RenderCell(DrawContext ctx, RectangleF bounds, Object cellValue, bool isSelected, bool isHovered, DataGrid grid = null)
	{
		// Get theme colors from grid's context
		let palette = grid?.Context?.Theme?.Palette ?? Palette();
		let surfaceColor = palette.Surface.A > 0 ? palette.Surface : Color(50, 50, 50, 255);
		let accentColor = palette.Accent.A > 0 ? palette.Accent : Color(100, 150, 220, 255);
		let borderColor = palette.Border.A > 0 ? palette.Border : Color(80, 80, 80, 255);
		let successColor = palette.Success.A > 0 ? palette.Success : Color(100, 180, 100, 255);

		let isChecked = GetBoolValue(cellValue);

		// Center the checkbox in the cell
		let checkSize = 14.0f;
		let checkX = bounds.X + (bounds.Width - checkSize) / 2;
		let checkY = bounds.Y + (bounds.Height - checkSize) / 2;
		let checkBounds = RectangleF(checkX, checkY, checkSize, checkSize);

		// Checkbox background
		let bgColor = isHovered ? Palette.ComputeHover(surfaceColor) : surfaceColor;
		ctx.FillRect(checkBounds, bgColor);

		// Checkbox border
		let checkBorderColor = isSelected ? accentColor : borderColor;
		ctx.DrawRect(checkBounds, checkBorderColor, 1);

		// Checkmark if checked
		if (isChecked)
		{
			// Draw a simple checkmark
			let cx = checkBounds.X + checkBounds.Width / 2;
			let cy = checkBounds.Y + checkBounds.Height / 2;
			ctx.DrawLine(.(cx - 4, cy), .(cx - 1, cy + 3), successColor, 2);
			ctx.DrawLine(.(cx - 1, cy + 3), .(cx + 4, cy - 3), successColor, 2);
		}
	}

	/// Converts cell value to bool.
	private bool GetBoolValue(Object value)
	{
		if (value == null)
			return false;
		if (let b = value as bool?)
			return b;
		if (let i = value as int?)
			return i != 0;
		return false;
	}

	/// Compares bool values for sorting.
	public override int CompareCellValues(Object a, Object b)
	{
		let aVal = GetBoolValue(a);
		let bVal = GetBoolValue(b);
		if (aVal == bVal) return 0;
		return aVal ? 1 : -1;  // false < true
	}
}
