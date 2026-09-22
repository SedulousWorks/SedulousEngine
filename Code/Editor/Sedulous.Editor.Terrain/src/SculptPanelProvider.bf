using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.App;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Terrain;

/// The sculpt brush's floating panel: the four mode icons as a segmented toggle over a
/// radius and strength grid; wheel sizing feeds the radius row back.
class SculptPanelProvider : IViewportToolPanelProvider
{
	public StringView ToolId => "terrain.sculpt";
	public ToolPanelPlacement Placement => .Float;

	public View CreatePanel(IViewportTool tool, in ViewportToolHostContext context)
	{
		let t = tool as TerrainSculptTool; // id matched, so the type is known
		if (t == null)
			return null;
		let root = ToolPanelWidgets.MakePanelRoot();
		root.AddView(ToolPanelWidgets.MakeRow("Sculpt mode", 12.0f));

		let modes = new SegmentedToggle();
		modes.Build(4,
			new (i) =>
			{
				SVGDrawable[4] icons = .(EditorIcons.BrushRaise, EditorIcons.BrushLower, EditorIcons.BrushSmooth, EditorIcons.BrushFlatten);
				return new IconGlyph(icons[i], 16.0f);
			},
			new [=t](i) => { t.SetMode((SculptMode)i); },
			new [=t]() => (int32)t.Mode,
			new (i, outTooltip) =>
			{
				StringView[4] names = .("Raise", "Lower", "Smooth", "Flatten");
				outTooltip.Set(names[i]);
			});
		root.AddView(modes);

		let grid = new PropertyGrid();
		let radius = ToolPanelWidgets.AddFloat(grid, "Radius", t.Radius, 0.5, 128.0, 1.0, 1, new [=t](v) => { t.SetRadius((float)v); });
		ToolPanelWidgets.AddFloat(grid, "Strength", t.Strength, 0.0, 50.0, 0.5, 1, new [=t](v) => { t.SetStrength((float)v); });
		delete t.OnRadiusChanged;
		t.OnRadiusChanged = new [=radius](r) => { radius.SetValue(r); };
		ToolPanelWidgets.AddGrid(root, grid);
		return root;
	}
}
