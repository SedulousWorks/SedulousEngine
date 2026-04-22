using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// A DataGrid column that displays text values.
/// Uses a delegate to extract the text value from row data.
public class DataGridTextColumn : DataGridColumn
{
	public delegate Object(Object rowData) ValueGetter ~ delete _;

	/// Creates a text column with the given header.
	public this(StringView header) : base(header)
	{
	}

	/// Creates a text column with header and value getter.
	public this(StringView header, delegate Object(Object rowData) valueGetter) : base(header)
	{
		ValueGetter = valueGetter;
	}

	/// Gets the cell value from row data.
	public override Object GetCellValue(Object rowData)
	{
		if (ValueGetter != null)
			return ValueGetter(rowData);
		return null;
	}

	/// Renders the cell as text.
	public override void RenderCell(DrawContext ctx, RectangleF bounds, Object cellValue, bool isSelected, bool isHovered, DataGrid grid = null)
	{
		// Get theme colors from grid's context
		let palette = grid?.Context?.Theme?.Palette ?? Palette();
		let textColor = isSelected
			? (palette.Text.A > 0 ? palette.Text : Color(255, 255, 255, 255))
			: (palette.Text.A > 0 ? palette.Text : Color(220, 220, 220, 255));

		let text = cellValue?.ToString(.. scope String()) ?? "";
		let fontSize = 12.0f;
		let textX = bounds.X + 4;
		let textY = bounds.Y + (bounds.Height - fontSize) / 2;

		// Clip text to cell bounds
		ctx.PushClipRect(bounds);
		ctx.DrawText(text, fontSize, .(textX, textY), textColor);
		ctx.PopClip();
	}
}
