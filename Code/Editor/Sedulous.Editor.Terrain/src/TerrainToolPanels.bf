using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Terrain;

// The terrain brushes' panels (Raptor's editor-gui spec, 5.3, layer 5, part 3), made of the
// editor's tool panel kit so they read as one: Sculpt's mode (Raise, Lower, Smooth, Flatten), Paint
// Layers' layer (each its albedo's picture, numbered from 1 as the keys are) and its mode (Paint,
// Erase, Smooth; they were letters on the layer row), Cut Holes' mode (Cut, Fill), each with its
// radius and what else it has, and a line of help for its keys. Each provider downcasts the active
// tool to its concrete one (the id matched, the seam's contract) to read and write what the UI-free
// tool cannot expose; the kit asks them again each frame, so the tool's keys show in it.

/// Sculpt's panel.
class SculptPanelProvider : IViewportToolPanelProvider
{
	public StringView ToolId => "terrain.sculpt";

	public Node CreatePanel(IViewportTool tool, in ViewportToolHostContext context)
	{
		let t = tool as TerrainSculptTool;
		if (t == null)
			return null;
		let body = new ToolPanelBody();
		ToolPanelChoice[4] modes = .(
			TerrainToolPanels.Word("Raise", "Push the surface up (1)"),
			TerrainToolPanels.Word("Lower", "Push it down (2)"),
			TerrainToolPanels.Word("Smooth", "Even out bumps toward their neighbours (3)"),
			TerrainToolPanels.Word("Flatten", "Pull toward the height Ctrl+click picked (4)"));
		defer { for (let choice in modes) delete choice; }
		body.AddChoices(default, modes, new [=t] () => (int32)t.Mode, new [=t] (i) => { t.SetMode((SculptMode)i); });
		body.AddSlider("Radius", 0.5, 128.0, 0.5, new [=t] () => (double)t.Radius, new [=t] (v) => { t.SetRadius((float)v); });
		body.AddSlider("Strength", 0.0, 50.0, 0.5, new [=t] () => (double)t.Strength, new [=t] (v) => { t.SetStrength((float)v); });
		body.AddHelp("Drag to sculpt. 1 to 4 pick the mode, Shift+wheel sizes the brush, Ctrl+click picks Flatten's height.");
		body.Sync();
		return body;
	}
}

/// Paint Layers' panel.
class SplatPanelProvider : IViewportToolPanelProvider
{
	public StringView ToolId => "terrain.splat";

	public Node CreatePanel(IViewportTool tool, in ViewportToolHostContext context)
	{
		let t = tool as TerrainSplatTool;
		if (t == null)
			return null;
		let thumbs = (context.EditorContext != null) ? context.EditorContext.Thumbnails : null;
		let layers = scope LayerSet();
		LayerSet.Resolve(context.Scene, layers);
		let body = new ToolPanelBody();

		// The base, shown and never chosen: it is never painted, erasing reveals it.
		if (layers.Count > 0)
		{
			let @base = scope ToolPanelChoice();
			@base.Tooltip.Append("The base layer: ");
			TerrainToolPanels.AlbedoName(context.EditorContext, layers.BaseId, @base.Tooltip);
			@base.Tooltip.Append(". It is never painted; Erase reveals it.");
			@base.Icon.Set("Editor/Icons/texture.svg");
			let baseId = layers.BaseId;
			if ((thumbs != null) && !baseId.IsNil)
				@base.Picture = new [=thumbs, =baseId] () => thumbs.Get(baseId);
			body.AddPicture("Base (erase to reveal)", @base);
		}

		// The layers, numbered from 1 as their keys are (and the Terrain page names them), each its
		// albedo's picture once there is one. With no terrain resolved, four.
		let count = (layers.Count > 0) ? layers.Count : 4;
		let choices = scope List<ToolPanelChoice>();
		defer { ClearAndDeleteItems!(choices); }
		for (uint32 i < count)
		{
			let choice = new ToolPanelChoice();
			choice.Label.AppendF("{}", i + 1);
			let albedo = (i < (uint32)layers.Ids.Count) ? layers.Ids[i] : Guid.Empty;
			if (layers.Count > 0)
			{
				choice.Tooltip.AppendF("Layer {}: ", i + 1);
				TerrainToolPanels.AlbedoName(context.EditorContext, albedo, choice.Tooltip);
				if (i < 9)
					choice.Tooltip.AppendF(" ({})", i + 1);
			}
			else
				choice.Tooltip.AppendF("Layer {}", i + 1);
			if ((thumbs != null) && !albedo.IsNil)
			{
				choice.Icon.Set("Editor/Icons/texture.svg");
				choice.Picture = new [=thumbs, =albedo] () => thumbs.Get(albedo);
			}
			choices.Add(choice);
		}
		body.AddChoices("Layer", choices, new [=t] () => (int32)t.PaletteIndex, new [=t] (i) => { t.SetPaletteIndex((uint32)i); });
		ToolPanelChoice[3] modes = .(
			TerrainToolPanels.Word("Paint", "Paint the layer"),
			TerrainToolPanels.Word("Erase", "Fade what was painted, revealing the base layer (0)"),
			TerrainToolPanels.Word("Smooth", "Feather painted seams without repainting either side (-)"));
		defer { for (let choice in modes) delete choice; }
		body.AddChoices("Mode", modes, new [=t] () => t.IsEraser ? 1 : (t.IsSmooth ? 2 : 0), new [=t] (i) =>
			{
				if (i == 0)
					t.SetPaletteIndex(t.PaletteIndex); // back to painting it
				else if (i == 1)
					t.SetEraser(true);
				else
					t.SetSmooth(true);
			});
		body.AddSlider("Radius", 0.5, 128.0, 0.5, new [=t] () => (double)t.Radius, new [=t] (v) => { t.SetRadius((float)v); });
		body.AddSlider("Strength", 0.0, 1.0, 0.05, new [=t] () => (double)t.Strength, new [=t] (v) => { t.SetStrength((float)v); });
		// Spacing: how close the stamps fall along a stroke, a share of the radius (low and soft
		// blends smoothly; high leaves dabs).
		body.AddSlider("Spacing", 0.05, 1.0, 0.05, new [=t] () => (double)t.Spacing, new [=t] (v) => { t.SetSpacing((float)v); });
		// Airbrush: stamps on a clock while held, building up where the brush rests.
		body.AddCheck("Airbrush", new [=t] () => t.IsAirbrush, new [=t] (on) => { t.SetAirbrush(on); });
		body.AddHelp("Drag to paint. 1 to 9 pick a layer, 0 erases, - smooths, Shift+wheel sizes the brush.");
		body.Sync();
		return body;
	}
}

/// Cut Holes' panel.
class HolePanelProvider : IViewportToolPanelProvider
{
	public StringView ToolId => "terrain.hole";

	public Node CreatePanel(IViewportTool tool, in ViewportToolHostContext context)
	{
		let t = tool as TerrainHoleTool;
		if (t == null)
			return null;
		let body = new ToolPanelBody();
		ToolPanelChoice[2] modes = .(
			TerrainToolPanels.Word("Cut", "Cut the surface under the brush: nothing draws, collides, walks or grows there (1)"),
			TerrainToolPanels.Word("Fill", "Fill a cut back in (2)"));
		defer { for (let choice in modes) delete choice; }
		body.AddChoices(default, modes, new [=t] () => (t.Mode == .Cut) ? 0 : 1, new [=t] (i) => { t.SetMode((i == 0) ? .Cut : .Fill); });
		body.AddSlider("Radius", 0.5, 128.0, 0.5, new [=t] () => (double)t.Radius, new [=t] (v) => { t.SetRadius((float)v); });
		body.AddHelp("Drag to cut or fill. 1 cuts, 2 fills, Shift+wheel sizes the brush.");
		body.Sync();
		return body;
	}
}

/// The terrain brush panels' registration.
static class TerrainToolPanels
{
	private static SculptPanelProvider sSculpt = null ~ delete _;
	private static SplatPanelProvider sSplat = null ~ delete _;
	private static HolePanelProvider sHole = null ~ delete _;

	/// Registers every brush panel with the global registry; idempotent, first wins per tool id.
	public static void Register()
	{
		if (sSculpt == null)
			sSculpt = new SculptPanelProvider();
		if (sSplat == null)
			sSplat = new SplatPanelProvider();
		if (sHole == null)
			sHole = new HolePanelProvider();
		ViewportToolPanelRegistry.Global.Register(sSculpt);
		ViewportToolPanelRegistry.Global.Register(sSplat);
		ViewportToolPanelRegistry.Global.Register(sHole);
	}

	/// A choice by its word. The caller deletes it.
	public static ToolPanelChoice Word(StringView label, StringView tooltip)
	{
		let choice = new ToolPanelChoice();
		choice.Label.Set(label);
		choice.Tooltip.Set(tooltip);
		return choice;
	}

	/// A layer's albedo by its asset's name, appended: at a swatch's size a displacement map picked
	/// in place of its diffuse looks the same, the name tells them apart.
	public static void AlbedoName(EditorContext context, Guid id, String outName)
	{
		if (id.IsNil)
		{
			outName.Append("no albedo");
			return;
		}
		if ((context != null) && (context.Project != null))
		{
			if (let instance = context.Project.SourceDb.GetInstance(id))
			{
				outName.Append(instance.Name);
				return;
			}
		}
		outName.Append("its albedo is missing");
	}
}
