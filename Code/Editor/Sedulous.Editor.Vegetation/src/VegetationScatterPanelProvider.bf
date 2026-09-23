using System;
using System.Collections;
using Sedulous.Scene;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Vegetation;
using Sedulous.Engine.Vegetation;
using Sedulous.Editor.App;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Vegetation;

/// The prop brush's floating panel: the scene's vegetation layers and the mode, as two
/// segmented rows over a radius, density, strength and spacing grid.
///
/// TWO rows rather than one, because erasing is per LAYER: with the eraser as a slot beside
/// the layers, choosing it unlit the layer and the erase target vanished. A slot that is not
/// a Scattered layer, or whose mesh does not resolve, says so rather than silently doing
/// nothing.
class VegetationScatterPanelProvider : IViewportToolPanelProvider
{
	public StringView ToolId => "vegetation.scatter";
	public ToolPanelPlacement Placement => .Float;

	/// The first vegetation component's layer labels, each already saying whether the brush
	/// can paint it. THE CALLER OWNS the strings it appends.
	private static void ResolveLayerLabels(Scene scene, List<String> outLabels)
	{
		let manager = (scene != null) ? scene.GetSystem<TerrainVegetationComponentManager>() : null;
		if (manager == null)
			return;

		var taken = false;
		manager.ForEach(scope [&] (component, owner) =>
			{
				if (taken || (component.Layers == null) || component.Layers.IsEmpty)
					return;
				taken = true;
				for (int i < component.Layers.Count)
				{
					let layer = component.Layers[i];
					let label = new String();
					if (layer.Name.IsEmpty)
						label.AppendF("Layer {}", i + 1);
					else
						label.Set(layer.Name);
					if (layer.Placement != .Scattered)
						label.Append(" (not scattered)");
					else if (layer.Mesh.Get == null)
						label.Append(" (no mesh)"); // nothing would draw
					outLabels.Add(label);
				}
			});
	}

	public View CreatePanel(IViewportTool tool, in ViewportToolHostContext context)
	{
		let t = tool as VegetationScatterTool; // the id matched, so the type is known
		if (t == null)
			return null;

		// The labels live only for the build: the toggle copies each into its own label view.
		let labels = scope List<String>();
		defer { ClearAndDeleteItems!(labels); }
		ResolveLayerLabels(context.Scene, labels);
		let count = (int32)labels.Count;

		let root = ToolPanelWidgets.MakePanelRoot();
		root.AddView(ToolPanelWidgets.MakeRow("Prop layer (Scattered)", 12.0f));
		if (count == 0)
		{
			root.AddView(ToolPanelWidgets.MakeRow(
				"No vegetation layers here, add a Scattered layer", 11.0f));
		}

		// The layer the brush works on, always lit whatever the mode, then the mode itself.
		let choices = new SegmentedToggle();
		choices.Build(count,
			new [=labels](i) => new Label(labels[i]),
			new [=t](i) => { t.SetLayer((uint32)i); },
			new [=t]() => (int32)t.Layer,
			new (i, outTooltip) => { outTooltip.Set("The layer the brush works on"); });
		root.AddView(choices);

		root.AddView(ToolPanelWidgets.MakeRow("Mode", 12.0f));
		let modes = new SegmentedToggle();
		modes.Build(2,
			new (i) =>
			{
				StringView[2] names = .("Paint", "Erase");
				return new Label(names[i]);
			},
			new [=t](i) => { t.SetEraser(i == 1); },
			new [=t]() => t.IsEraser ? 1 : 0,
			new (i, outTooltip) =>
			{
				StringView[2] tips = .("Place props into the layer",
					"Remove the layer's props under the brush");
				outTooltip.Set(tips[i]);
			});
		root.AddView(modes);

		let grid = new PropertyGrid();
		let radius = ToolPanelWidgets.AddFloat(grid, "Radius", t.Radius,
			VegetationScatterTool.cMinRadius, VegetationScatterTool.cMaxRadius, 1.0, 1,
			new [=t](v) => { t.SetRadius((float)v); });
		ToolPanelWidgets.AddFloat(grid, "Density /m2", t.Density, 0.0, 64.0, 0.05, 2,
			new [=t](v) => { t.SetDensity((float)v); });
		ToolPanelWidgets.AddFloat(grid, "Strength", t.Strength, 0.0, 1.0, 0.05, 2,
			new [=t](v) => { t.SetStrength((float)v); });
		ToolPanelWidgets.AddFloat(grid, "Spacing (x radius)", t.Spacing, 0.0, 8.0, 0.1, 1,
			new [=t](v) => { t.SetSpacing((float)v); });

		// Wheel sizing pushes the radius back into its row.
		delete t.OnRadiusChanged;
		t.OnRadiusChanged = new [=radius](r) => { radius.SetValue(r); };

		ToolPanelWidgets.AddGrid(root, grid);
		return root;
	}
}
