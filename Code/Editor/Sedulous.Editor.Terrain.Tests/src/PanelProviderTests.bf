using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Heightfield;
using Sedulous.Terrain.Resource;
using Sedulous.Engine.Terrain;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.ViewportTools;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Terrain.Tests;

/// The brush panels: each provider registers, each builds its panel of the kit for its concrete
/// tool, which shows what the tool has and sets it, the keys' changes too (a Sync after them); the
/// Paint Layers panel's layers follow the scene's palette rather than a fixed cap, numbered from 1.
class PanelProviderTests
{
	[Test]
	public static void APanelOfTheKitForEachBrushItShowsTheToolAndSetsItTheKeysChangesToo()
	{
		TerrainEditor.RegisterToolPanels();
		TerrainEditor.RegisterToolPanels(); // idempotent, first wins per tool id
		let registry = ViewportToolPanelRegistry.Global;
		let sculptProvider = registry.FindByToolId("terrain.sculpt");
		let splatProvider = registry.FindByToolId("terrain.splat");
		let holeProvider = registry.FindByToolId("terrain.hole");
		Test.Assert((sculptProvider != null) && (splatProvider != null) && (holeProvider != null));
		Test.Assert(registry.FindByToolId("select") == null); // the default tool has no panel

		let scene = scope Scene();
		TerrainScene.AddTerrainSceneManagers(scene);
		let grid = scope Heightfield(65, .(64.0f, 64.0f), 0.0f, 10.0f);
		let weights = scope SplatWeights(16, 16);
		let res = scope TerrainResource();
		res.Heightfield.SetDirect(grid);
		res.Weights.SetDirect(weights);
		for (int i < 6)
			res.Palette.Add(TerrainLayer());
		scene.GetSystem<TerrainComponentManager>().Add(scene.CreateEntity("terrain")).Terrain.SetDirect(res);
		scene.Start();

		let commands = scope EditorCommandStack();
		let sculpt = scope TerrainSculptTool(scene, commands, null);
		let splat = scope TerrainSplatTool(scene, commands, null);
		let hole = scope TerrainHoleTool(scene, commands, null);
		splat.SetPaletteIndex(5); // a slot past the retired four layer cap
		var context = ViewportToolHostContext();
		context.Scene = scene;
		context.Commands = commands;
		let sculptNode = sculptProvider.CreatePanel(sculpt, context);
		let splatNode = splatProvider.CreatePanel(splat, context);
		let holeNode = holeProvider.CreatePanel(hole, context);
		defer { sculptNode.ReleaseRef(); splatNode.ReleaseRef(); holeNode.ReleaseRef(); }
		let sculptPanel = sculptNode as ToolPanelBody;
		let splatPanel = splatNode as ToolPanelBody;
		let holePanel = holeNode as ToolPanelBody;
		Test.Assert((sculptPanel != null) && (splatPanel != null) && (holePanel != null));

		// Sculpt: its four modes by word, the chosen one checked; a key's change shows after a Sync.
		Test.Assert(sculptPanel.ChoiceCount(0) == 4);
		Test.Assert(sculptPanel.ChoiceAt(0, 0).Text == "Raise");
		Test.Assert(sculptPanel.ChoiceAt(0, 0).Checked);
		sculpt.SetMode(.Flatten); // as the 4 key does
		sculpt.SetRadius(20.0f); // as Shift + wheel does
		sculptPanel.Sync();
		Test.Assert(sculptPanel.ChoiceAt(0, 3).Checked);
		Test.Assert(!sculptPanel.ChoiceAt(0, 0).Checked);
		Test.Assert(sculptPanel.NumberAt(0).Value == 20.0);
		sculptPanel.ChoiceAt(0, 1).HandleActivate(); // Lower, as a click
		Test.Assert(sculpt.Mode == .Lower);
		sculpt.SetStrength(12.0f);
		sculptPanel.Sync();
		Test.Assert(sculptPanel.SliderAt(1).Value == 12.0); // Strength's slider follows the tool

		// Paint Layers: the six layers numbered from 1 (as their keys), each named in its tooltip,
		// the sixth checked; its mode a row of words (they were letters on the layer row).
		Test.Assert(splatPanel.ChoiceCount(0) == 6);
		Test.Assert(splatPanel.ChoiceAt(0, 0).Text == "1");
		Test.Assert(splatPanel.ChoiceAt(0, 5).Checked);
		for (int i < 6)
			Test.Assert(!splatPanel.ChoiceAt(0, i).Tooltip.IsEmpty);
		Test.Assert(splatPanel.ChoiceCount(1) == 3);
		Test.Assert(splatPanel.ChoiceAt(1, 0).Checked); // painting
		splatPanel.ChoiceAt(1, 1).HandleActivate(); // Erase
		Test.Assert(splat.IsEraser);
		splatPanel.ChoiceAt(1, 2).HandleActivate(); // Smooth
		Test.Assert(splat.IsSmooth && !splat.IsEraser);
		splatPanel.ChoiceAt(1, 0).HandleActivate(); // back to painting, the layer kept
		Test.Assert(!splat.IsSmooth);
		Test.Assert(splat.PaletteIndex == 5);
		splatPanel.ChoiceAt(0, 2).HandleActivate(); // layer 3
		Test.Assert(splat.PaletteIndex == 2);
		splatPanel.CheckAt(0).HandleActivate(); // Airbrush
		Test.Assert(splat.IsAirbrush);

		// Cut Holes: Cut or Fill.
		Test.Assert(holePanel.ChoiceCount(0) == 2);
		holePanel.ChoiceAt(0, 1).HandleActivate();
		Test.Assert(hole.Mode == .Fill);

		// A tool of the wrong type for a matched id builds nothing.
		Test.Assert(sculptProvider.CreatePanel(splat, context) == null);
		sculpt.OnDeactivate();
		splat.OnDeactivate();
		hole.OnDeactivate();
	}

	[Test]
	public static void TheProviderAddsBothBrushesToAToolSetWithASceneAndCommands()
	{
		let fx = scope TerrainFixture();
		let commands = scope EditorCommandStack();
		var context = ViewportToolHostContext();
		context.Scene = fx.Scene;
		context.Commands = commands;
		let provider = scope TerrainViewportToolProvider();
		let manager = scope ViewportToolManager();
		provider.CreateTools(manager, context);
		Test.Assert(manager.FindById("terrain.sculpt") != null);
		Test.Assert(manager.FindById("terrain.splat") != null);
		Test.Assert(manager.FindById("terrain.hole") != null);

		let bare = scope ViewportToolManager();
		provider.CreateTools(bare, ViewportToolHostContext()); // no scene: nothing to brush
		Test.Assert(bare.FindById("terrain.sculpt") == null);
	}
}
