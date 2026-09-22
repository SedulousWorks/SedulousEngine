using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.App;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Vegetation;

/// The vegetation brush's floating panel: the three modes as a segmented toggle over a
/// radius, strength, spacing and airbrush grid; wheel sizing feeds the radius row back.
///
/// The mode row shows what is being painted, so the ERASE target is never ambiguous: the
/// lit segment names it.
class VegetationPaintPanelProvider : IViewportToolPanelProvider
{
	public StringView ToolId => "vegetation.paint";
	public ToolPanelPlacement Placement => .Float;

	public View CreatePanel(IViewportTool tool, in ViewportToolHostContext context)
	{
		let t = tool as VegetationPaintTool; // the id matched, so the type is known
		if (t == null)
			return null;

		let root = ToolPanelWidgets.MakePanelRoot();
		root.AddView(ToolPanelWidgets.MakeRow("Vegetation mode", 12.0f));

		let modes = new SegmentedToggle();
		modes.Build(3,
			new (i) =>
			{
				StringView[3] names = .("Paint", "Erase", "Smooth");
				return new Label(names[i]);
			},
			new [=t](i) =>
			{
				switch (i)
				{
				case 1: t.SetEraser(true);
				case 2: t.SetSmooth(true);
				default: t.SetPlane(t.Plane); // paint: leaves both modes
				}
			},
			new [=t]() => t.IsSmooth ? 2 : (t.IsEraser ? 1 : 0),
			new (i, outTooltip) =>
			{
				StringView[3] tips = .("Grow the layer's mask", "Clear it back",
					"Feather a painted edge");
				outTooltip.Set(tips[i]);
			});
		root.AddView(modes);

		root.AddView(ToolPanelWidgets.MakeRow("Plane", 12.0f));
		let planes = new SegmentedToggle();
		planes.Build(4,
			new (i) => new Label(scope $"{i}"),
			new [=t](i) => { t.SetPlane((uint32)i); },
			new [=t]() => (int32)t.Plane,
			new (i, outTooltip) => { outTooltip.Set(scope $"Paint mask plane {i}"); });
		root.AddView(planes);

		let grid = new PropertyGrid();
		let radius = ToolPanelWidgets.AddFloat(grid, "Radius", t.Radius,
			VegetationPaintTool.cMinRadius, VegetationPaintTool.cMaxRadius, 1.0, 1,
			new [=t](v) => { t.SetRadius((float)v); });
		ToolPanelWidgets.AddFloat(grid, "Strength", t.Strength, 0.0, 1.0, 0.05, 2,
			new [=t](v) => { t.SetStrength((float)v); });
		ToolPanelWidgets.AddFloat(grid, "Spacing", t.Spacing, 0.05, 1.0, 0.05, 2,
			new [=t](v) => { t.SetSpacing((float)v); });
		ToolPanelWidgets.AddBool(grid, "Airbrush", t.IsAirbrush,
			new [=t](v) => { t.SetAirbrush(v); });

		// Wheel sizing pushes the radius back into its row.
		delete t.OnRadiusChanged;
		t.OnRadiusChanged = new [=radius](r) => { radius.SetValue(r); };

		ToolPanelWidgets.AddGrid(root, grid);
		return root;
	}
}
