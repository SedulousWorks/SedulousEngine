using System;
using System.Collections;
using Sedulous.Scene;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.App;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Vegetation;

/// The vegetation brush's floating panel: the plane the brush works on and the mode it
/// works in, as two segmented rows over a radius, strength, spacing and airbrush grid;
/// wheel sizing feeds the radius row back.
///
/// TWO rows rather than one, because erasing is per PLANE: with the eraser as a slot beside
/// the planes, choosing it unlit the plane and the erase target vanished.
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
		// The plane the brush works on, always lit whatever the mode, then the mode itself.
		root.AddView(ToolPanelWidgets.MakeRow("Mask plane", 12.0f));
		let planes = new SegmentedToggle();
		planes.Build(4,
			new (i) => new Label(scope $"{i}"),
			new [=t](i) => { t.SetPlane((uint32)i); },
			new [=t]() => (int32)t.Plane,
			new (i, outTooltip) =>
			{
				outTooltip.Set("The plane the brush works on; a procedural layer with Mask placement names it");
			});
		root.AddView(planes);

		// What each plane GROWS, which is what a stroke on it actually means.
		let line = scope String();
		AppendPlaneReaders(context.Scene, 4, line);
		root.AddView(ToolPanelWidgets.MakeRow(line, 11.0f));

		root.AddView(ToolPanelWidgets.MakeRow("Mode", 12.0f));
		let modes = new SegmentedToggle();
		modes.Build(3,
			new (i) =>
			{
				StringView[3] names = .("Paint", "Erase", "Smooth");
				return new Label(names[i]);
			},
			new [=t](i) =>
			{
				t.SetEraser(i == 1);
				t.SetSmooth(i == 2);
			},
			new [=t]() => t.IsSmooth ? 2 : (t.IsEraser ? 1 : 0),
			new (i, outTooltip) =>
			{
				StringView[3] tips = .("Paint the plane, density up",
					"Erase the plane under the brush, so nothing grows",
					"Smooth, which feathers a painted edge");
				outTooltip.Set(tips[i]);
			});
		root.AddView(modes);

		let grid = new PropertyGrid();
		let radius = ToolPanelWidgets.AddFloat(grid, "Radius", t.Radius,
			VegetationPaintTool.cMinRadius, VegetationPaintTool.cMaxRadius, 1.0, 1,
			new [=t](v) => { t.SetRadius((float)v); });
		ToolPanelWidgets.AddFloat(grid, "Strength", t.Strength, 0.0, 1.0, 0.05, 2,
			new [=t](v) => { t.SetStrength((float)v); });
		ToolPanelWidgets.AddFloat(grid, "Stamp spacing", t.Spacing, 0.05, 1.0, 0.05, 2,
			new [=t](v) => { t.SetSpacing((float)v); });
		ToolPanelWidgets.AddBool(grid, "Airbrush", t.IsAirbrush,
			new [=t](v) => { t.SetAirbrush(v); });

		// Wheel sizing pushes the radius back into its row.
		delete t.OnRadiusChanged;
		t.OnRadiusChanged = new [=radius](r) => { radius.SetValue(r); };

		ToolPanelWidgets.AddGrid(root, grid);
		return root;
	}

	/// "Grows:  0: Grass, 1: Flowers" — the procedural layers that read each plane, so the
	/// panel says what painting a plane will grow rather than leaving it to be discovered.
	private static void AppendPlaneReaders(Scene scene, int planeCount, String outLine)
	{
		let manager = (scene != null)
			? scene.GetSystem<Sedulous.Engine.Vegetation.TerrainVegetationComponentManager>()
			: null;

		let readers = scope List<String>();
		defer { ClearAndDeleteItems!(readers); }
		for (int i < planeCount)
			readers.Add(new String());

		if (manager != null)
		{
			var taken = false;
			manager.ForEach(scope [&] (component, owner) =>
				{
					if (taken || (component.ProceduralLayers == null))
						return;
					taken = true;
					for (int i < component.ProceduralLayers.Count)
					{
						let layer = component.ProceduralLayers[i];
						if ((layer.Placement != .Mask) && (layer.Placement != .SplatTimesMask))
							continue;
						if (layer.MaskPlane >= (uint32)planeCount)
							continue;

						let into = readers[(int)layer.MaskPlane];
						if (!into.IsEmpty)
							into.Append(", ");
						if (layer.Name.IsEmpty)
							into.AppendF("Procedural layer {}", i + 1);
						else
							into.Append(layer.Name);
					}
				});
		}

		outLine.Set("Grows:");
		var any = false;
		for (int i < readers.Count)
		{
			if (readers[i].IsEmpty)
				continue;
			any = true;
			outLine.AppendF("  {}: {}", i, readers[i]);
		}
		if (!any)
			outLine.Set("Grows: no procedural layer reads a plane yet");
	}
}
