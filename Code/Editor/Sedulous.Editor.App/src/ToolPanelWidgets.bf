using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.Editor.App;

/// The building blocks a viewport tool's settings panel is made of: the panel root, a
/// caption row, the property rows and the grid mount.
///
/// It lives here rather than in a domain editor because every brush panel wants the same
/// shapes, and Editor.App stays ignorant of what any of them edit.
static class ToolPanelWidgets
{
	/// A caption row, which is a label at a size.
	public static View MakeRow(StringView title, float fontSize)
	{
		let label = new Label(title);
		label.FontSize.Value = fontSize;
		return label;
	}

	/// The vertical panel root the rows stack into.
	public static FlexLayout MakePanelRoot()
	{
		let root = new FlexLayout();
		root.Direction = .Vertical;
		root.Spacing = 4.0f;
		return root;
	}

	/// Adds a float row; the grid takes the editor, the caller keeps a borrowed handle to
	/// push values back. CONSUMES the setter.
	public static FloatEditor AddFloat(PropertyGrid grid, StringView label, double value,
		double min, double max, double step, int32 decimals, delegate void(double) onChange)
	{
		let editor = new FloatEditor(label, value, min, max, step, decimals, onChange);
		grid.AddProperty(editor);
		return editor;
	}

	/// Adds a bool row. CONSUMES the setter.
	public static BoolEditor AddBool(PropertyGrid grid, StringView label, bool value,
		delegate void(bool) onChange)
	{
		let editor = new BoolEditor(label, value, onChange);
		grid.AddProperty(editor);
		return editor;
	}

	public static void AddGrid(FlexLayout root, PropertyGrid grid)
	{
		var style = LayoutStyle();
		style.Width = SizeSpec.Match();
		style.FlexGrow = 1.0f;
		root.AddView(grid, style);
	}
}
