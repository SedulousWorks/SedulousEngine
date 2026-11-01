using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.GUI;
using Sedulous.Engine.Vegetation;
using Sedulous.Editor.App;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Vegetation;

// The vegetation brushes' panels (Raptor's editor-gui spec, 5.3, layer 5, part 3), made of the
// editor's tool panel kit, as the terrain's are, so the footprint brushes read the same: Paint
// Vegetation's plane (numbered from 1 as its keys are, each naming in its tooltip what grows on it;
// the chosen plane's growth said under the row, where one long "Grows:" line ran on) and its mode
// (Paint, Erase, Smooth); Paint Props' layer (by name) and its mode (Paint, Erase); each with its
// radius and the rest, and a line of help for its keys. Two rows rather than one, because erasing
// is per plane (per layer): the target stays lit whatever the mode.

/// Paint Vegetation's panel.
class VegetationPaintPanelProvider : IViewportToolPanelProvider
{
	public StringView ToolId => "vegetation.paint";

	public Node CreatePanel(IViewportTool tool, in ViewportToolHostContext context)
	{
		let t = tool as VegetationPaintTool; // the id matched, so the type is known
		if (t == null)
			return null;
		let resolved = VegetationToolPanels.PlaneCount(context.Scene);
		let count = (resolved > 0) ? resolved : 4;
		// What each plane grows; the note below the row asks them again (kept by its delegate).
		let readers = new List<String>();
		VegetationToolPanels.PlaneReaders(context.Scene, count, readers);
		let body = new ToolPanelBody();

		// The plane, from 1 as its keys are, each saying what grows on it.
		let planes = scope List<ToolPanelChoice>();
		defer { ClearAndDeleteItems!(planes); }
		for (uint32 i < count)
		{
			let choice = new ToolPanelChoice();
			choice.Label.AppendF("{}", i + 1);
			choice.Tooltip.AppendF("Plane {}: ", i + 1);
			if (!readers[i].IsEmpty)
				choice.Tooltip.AppendF("grows {}", readers[i]);
			else
				choice.Tooltip.Append("nothing reads it yet");
			if (i < 9)
				choice.Tooltip.AppendF(" ({})", i + 1);
			planes.Add(choice);
		}
		body.AddChoices("Plane", planes, new [=t] () => (int32)t.Plane, new [=t] (i) => { t.SetPlane((uint32)i); });
		// What a stroke grows: the chosen plane's layers.
		body.AddNote(new [=t, =readers] (outText) =>
			{
				let plane = t.Plane;
				if ((plane < (uint32)readers.Count) && !readers[plane].IsEmpty)
					outText.AppendF("Grows {}.", readers[plane]);
				else
					outText.Append("No procedural layer reads this plane: a layer with Mask placement names it.");
			} ~ DeleteContainerAndItems!(readers));
		ToolPanelChoice[3] modes = .(
			VegetationToolPanels.Word("Paint", "Paint the plane"),
			VegetationToolPanels.Word("Erase", "Clear the plane under the brush (0)"),
			VegetationToolPanels.Word("Smooth", "Feather its edges without repainting (-)"));
		defer { for (let choice in modes) delete choice; }
		body.AddChoices("Mode", modes, new [=t] () => t.IsSmooth ? 2 : (t.IsEraser ? 1 : 0), new [=t] (i) =>
			{
				t.SetEraser(i == 1);
				t.SetSmooth(i == 2);
			});
		body.AddSlider("Radius", 0.5, 128.0, 0.5, new [=t] () => (double)t.Radius, new [=t] (v) => { t.SetRadius((float)v); });
		body.AddSlider("Strength", 0.0, 1.0, 0.05, new [=t] () => (double)t.Strength, new [=t] (v) => { t.SetStrength((float)v); });
		body.AddSlider("Spacing", 0.05, 1.0, 0.05, new [=t] () => (double)t.Spacing, new [=t] (v) => { t.SetSpacing((float)v); });
		body.AddCheck("Airbrush", new [=t] () => t.IsAirbrush, new [=t] (on) => { t.SetAirbrush(on); });
		body.AddHelp("Drag to paint. 1 to 9 pick a plane, 0 erases, the minus key smooths, Shift+wheel sizes the brush.");
		body.Sync();
		return body;
	}
}

/// Paint Props' panel.
class VegetationScatterPanelProvider : IViewportToolPanelProvider
{
	public StringView ToolId => "vegetation.scatter";

	public Node CreatePanel(IViewportTool tool, in ViewportToolHostContext context)
	{
		let t = tool as VegetationScatterTool; // the id matched, so the type is known
		if (t == null)
			return null;
		let body = new ToolPanelBody();
		let choices = scope List<ToolPanelChoice>();
		defer { ClearAndDeleteItems!(choices); }
		VegetationToolPanels.LayerChoices(context.Scene, choices);
		if (!choices.IsEmpty)
			body.AddChoices("Layer", choices, new [=t] () => (int32)t.Layer, new [=t] (i) => { t.SetLayer((uint32)i); });
		else
			body.AddHelp("No prop layers here: add one to the Terrain Vegetation component.");
		ToolPanelChoice[2] modes = .(
			VegetationToolPanels.Word("Paint", "Place props"),
			VegetationToolPanels.Word("Erase", "Remove the layer's props under the brush (0)"));
		defer { for (let choice in modes) delete choice; }
		body.AddChoices("Mode", modes, new [=t] () => t.IsEraser ? 1 : 0, new [=t] (i) => { t.SetEraser(i == 1); });
		body.AddSlider("Radius", 0.5, 128.0, 0.5, new [=t] () => (double)t.Radius, new [=t] (v) => { t.SetRadius((float)v); });
		body.AddSlider("Density", 0.0, 64.0, 0.05, new [=t] () => (double)t.Density, new [=t] (v) => { t.SetDensity((float)v); });
		body.AddSlider("Strength", 0.0, 1.0, 0.05, new [=t] () => (double)t.Strength, new [=t] (v) => { t.SetStrength((float)v); });
		body.AddSlider("Prop Spacing", 0.0, 8.0, 0.1, new [=t] () => (double)t.Spacing, new [=t] (v) => { t.SetSpacing((float)v); });
		body.AddHelp("Drag to place. Density is props per square metre; prop spacing keeps props apart, in their mesh's radii. 1 to 9 pick a layer, 0 erases, Shift+wheel sizes the brush.");
		body.Sync();
		return body;
	}
}

/// The vegetation brush panels' registration, and what they read of the scene.
static class VegetationToolPanels
{
	private static VegetationPaintPanelProvider sPaint = null ~ delete _;
	private static VegetationScatterPanelProvider sScatter = null ~ delete _;

	/// Idempotent, first wins per tool id.
	public static void Register()
	{
		if (sPaint == null)
			sPaint = new VegetationPaintPanelProvider();
		ViewportToolPanelRegistry.Global.Register(sPaint);
		if (sScatter == null)
			sScatter = new VegetationScatterPanelProvider();
		ViewportToolPanelRegistry.Global.Register(sScatter);
	}

	/// A choice by its word. The caller deletes it.
	public static ToolPanelChoice Word(StringView label, StringView tooltip)
	{
		let choice = new ToolPanelChoice();
		choice.Label.Set(label);
		choice.Tooltip.Set(tooltip);
		return choice;
	}

	/// The plane count of the scene's first resolved vegetation mask (0: none resolved).
	public static uint32 PlaneCount(Scene scene)
	{
		let manager = (scene != null) ? scene.GetSystem<TerrainVegetationComponentManager>() : null;
		if (manager == null)
			return 0;
		uint32 planes = 0;
		manager.ForEach(scope [&] (component, owner) =>
			{
				let mask = component.Mask.Get;
				if ((planes == 0) && (mask != null) && !mask.IsEmpty)
					planes = mask.PlaneCount;
			});
		return planes;
	}

	/// The procedural layers that read each of `planeCount` mask planes ("Grass, Flowers"; empty
	/// for none), one string each, appended (the caller deletes them): the brush paints a plane,
	/// and a layer is what gives the plane meaning.
	public static void PlaneReaders(Scene scene, uint32 planeCount, List<String> outReaders)
	{
		let start = outReaders.Count;
		for (uint32 i < planeCount)
			outReaders.Add(new String());
		let manager = (scene != null) ? scene.GetSystem<TerrainVegetationComponentManager>() : null;
		if (manager == null)
			return;
		manager.ForEach(scope [&] (component, owner) =>
			{
				if (component.ProceduralLayers == null)
					return;
				for (int i < component.ProceduralLayers.Count)
				{
					let layer = component.ProceduralLayers[i];
					if (((layer.Placement != .Mask) && (layer.Placement != .SplatTimesMask)) || (layer.MaskPlane >= planeCount))
						continue;
					let line = outReaders[start + (int)layer.MaskPlane];
					if (!line.IsEmpty)
						line.Append(", ");
					if (layer.Name.IsEmpty)
						line.AppendF("Procedural layer {}", i + 1);
					else
						line.Append(layer.Name);
				}
			});
	}

	/// The prop layers of the scene's first vegetation component that has any, as choices by
	/// name, appended (the caller deletes them): one whose mesh does not resolve says so (props of
	/// it place, but nothing draws).
	public static void LayerChoices(Scene scene, List<ToolPanelChoice> outChoices)
	{
		let manager = (scene != null) ? scene.GetSystem<TerrainVegetationComponentManager>() : null;
		if (manager == null)
			return;
		var taken = false;
		manager.ForEach(scope [&] (component, owner) =>
			{
				if (taken || (component.PropLayers == null) || component.PropLayers.IsEmpty)
					return;
				taken = true;
				for (int i < component.PropLayers.Count)
				{
					let layer = component.PropLayers[i];
					let choice = new ToolPanelChoice();
					if (layer.Name.IsEmpty)
						choice.Label.AppendF("Prop layer {}", i + 1);
					else
						choice.Label.Set(layer.Name);
					if (layer.Mesh.Get == null)
						choice.Tooltip.Set("Its mesh does not resolve: props place, but nothing draws");
					else
					{
						choice.Tooltip.AppendF("Layer {}", i + 1);
						if (i < 9)
							choice.Tooltip.AppendF(" ({})", i + 1);
					}
					outChoices.Add(choice);
				}
			});
	}
}
