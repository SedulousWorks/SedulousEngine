using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Terrain;

/// The brush panels' shared building blocks and their registration.
static class TerrainToolPanels
{
	private static SculptPanelProvider sSculpt = null ~ delete _;
	private static SplatPanelProvider sSplat = null ~ delete _;

	/// Registers both brush panels with the global registry; idempotent, first wins per
	/// tool id.
	public static void Register()
	{
		if (sSculpt == null)
			sSculpt = new SculptPanelProvider();
		if (sSplat == null)
			sSplat = new SplatPanelProvider();
		ViewportToolPanelRegistry.Global.Register(sSculpt);
		ViewportToolPanelRegistry.Global.Register(sSplat);
	}

	public static View MakeRow(StringView title, float fontSize)
	{
		let label = new Label(title);
		label.FontSize.Value = fontSize;
		return label;
	}

	public static FlexLayout MakePanelRoot()
	{
		let root = new FlexLayout();
		root.Direction = .Vertical;
		root.Spacing = 4.0f;
		return root;
	}

	/// Adds a float row; the grid takes the editor, the caller keeps a borrowed handle to
	/// push values back. CONSUMES the setter.
	public static FloatEditor AddFloat(PropertyGrid grid, StringView label, double value, double min, double max,
		double step, int32 decimals, delegate void(double) onChange)
	{
		let editor = new FloatEditor(label, value, min, max, step, decimals, onChange);
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
