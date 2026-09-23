using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.App;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Terrain;

/// The hole brush's floating panel: the two modes as a segmented toggle over a radius row;
/// wheel sizing feeds the radius back.
///
/// No strength row, because a sample is cut or it is solid: the disc has a hard edge and
/// there is nothing in between to scale.
class HolePanelProvider : IViewportToolPanelProvider
{
	public StringView ToolId => "terrain.hole";
	public ToolPanelPlacement Placement => .Float;

	public View CreatePanel(IViewportTool tool, in ViewportToolHostContext context)
	{
		let t = tool as TerrainHoleTool; // the id matched, so the type is known
		if (t == null)
			return null;

		let root = ToolPanelWidgets.MakePanelRoot();
		root.AddView(ToolPanelWidgets.MakeRow("Hole mode", 12.0f));

		let modes = new SegmentedToggle();
		modes.Build(2,
			new (i) =>
			{
				StringView[2] names = .("Cut", "Fill");
				return new Label(names[i]);
			},
			new [=t](i) => { t.SetMode((HoleMode)i); },
			new [=t]() => (int32)t.Mode,
			new (i, outTooltip) =>
			{
				StringView[2] tips = .(
					"Remove the surface under the brush",
					"Restore it; pick from a hole's rim, since the brush cannot pick inside one");
				outTooltip.Set(tips[i]);
			});
		root.AddView(modes);

		let grid = new PropertyGrid();
		let radius = ToolPanelWidgets.AddFloat(grid, "Radius", t.Radius,
			TerrainHoleTool.cMinRadius, TerrainHoleTool.cMaxRadius, 1.0, 1,
			new [=t](v) => { t.SetRadius((float)v); });

		delete t.OnRadiusChanged;
		t.OnRadiusChanged = new [=radius](r) => { radius.SetValue(r); };

		ToolPanelWidgets.AddGrid(root, grid);
		return root;
	}
}
