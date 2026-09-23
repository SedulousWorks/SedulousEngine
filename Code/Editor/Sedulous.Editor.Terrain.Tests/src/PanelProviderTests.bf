using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Heightfield;
using Sedulous.Terrain.Resource;
using Sedulous.Engine.Terrain;
using Sedulous.UI;
using Sedulous.Editor.Core;
using Sedulous.Editor.ViewportTools;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Terrain.Tests;

/// The brush panels: both providers register, each builds a panel for its tool, and the
/// splat panel's slots follow the scene's palette rather than a fixed cap.
class PanelProviderTests
{
	private static void CountTooltips(View view, ref int32 count)
	{
		if (!view.TooltipText.IsEmpty)
			count++;
		if (let group = view as ViewGroup)
		{
			for (int k < group.ChildCount)
				CountTooltips(group.GetChildAt(k), ref count);
		}
	}

	[Test]
	public static void ProvidersRegisterAndBuildAPanelForEachBrush()
	{
		TerrainEditor.RegisterToolPanels();
		TerrainEditor.RegisterToolPanels(); // idempotent, first wins per tool id
		let registry = ViewportToolPanelRegistry.Global;
		let sculptProvider = registry.FindByToolId("terrain.sculpt");
		let splatProvider = registry.FindByToolId("terrain.splat");
		let holeProvider = registry.FindByToolId("terrain.hole");
		Test.Assert(sculptProvider != null);
		Test.Assert(splatProvider != null);
		Test.Assert(holeProvider != null);
		Test.Assert(sculptProvider.Placement == .Float);
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
		splat.SetPaletteIndex(5); // a slot past the retired four layer cap
		Test.Assert(splat.PaletteIndex == 5);

		var context = ViewportToolHostContext();
		context.Scene = scene;
		context.Commands = commands;
		let hole = scope TerrainHoleTool(scene, commands, null);
		let sculptPanel = sculptProvider.CreatePanel(sculpt, context);
		let splatPanel = splatProvider.CreatePanel(splat, context);
		let holePanel = holeProvider.CreatePanel(hole, context);
		defer { sculptPanel.ReleaseRef(); splatPanel.ReleaseRef(); holePanel.ReleaseRef(); }
		Test.Assert(holePanel != null);
		Test.Assert(sculptPanel != null);
		Test.Assert(splatPanel != null); // the six palette slots plus the eraser and smooth

		int32 tooltipped = 0;
		CountTooltips(splatPanel, ref tooltipped);
		Test.Assert(tooltipped >= 7); // six palette slots plus the eraser, at least

		// The panel wired the radius readout: wheel sizing reaches it through the tool.
		Test.Assert(sculpt.OnRadiusChanged != null);
		Test.Assert(splat.OnRadiusChanged != null);
		sculpt.SetRadius(20.0f);
		splat.SetRadius(12.0f);

		splat.SetEraser(true);
		Test.Assert(splat.IsEraser);
		splat.SetSmooth(true);
		Test.Assert(splat.IsSmooth);
		Test.Assert(!splat.IsEraser);
		splat.SetSmooth(false);
		Test.Assert(splat.PaletteIndex == 5); // the selection survives leaving eraser and smooth

		// A tool of the wrong type for a matched id builds nothing.
		Test.Assert(sculptProvider.CreatePanel(splat, context) == null);
		sculpt.OnDeactivate();
		splat.OnDeactivate();
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
