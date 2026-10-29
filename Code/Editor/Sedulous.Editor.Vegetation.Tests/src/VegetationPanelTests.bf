using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.ViewportTools;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Vegetation.Tests;

/// The brush's panel, of the kit: it registers, it builds, and its rows drive the tool. The planes
/// from 1, the chosen one checked; the mode a row of its own, so the erase target stays lit; a
/// wheel resize shows after a Sync.
class VegetationPanelTests
{
	[Test]
	public static void TheProviderRegistersAndBuildsAPanelOfTheKitForTheBrush()
	{
		VegetationEditor.RegisterToolPanels();
		VegetationEditor.RegisterToolPanels(); // idempotent, first wins per tool id
		let provider = ViewportToolPanelRegistry.Global.FindByToolId("vegetation.paint");
		Test.Assert(provider != null);

		let fx = scope VegetationFixture();
		let commands = scope EditorCommandStack();
		let tool = scope VegetationPaintTool(fx.Scene, commands, null);
		tool.SetPlane(1);
		var context = ViewportToolHostContext();
		context.Scene = fx.Scene;
		context.Commands = commands;
		let node = provider.CreatePanel(tool, context);
		Test.Assert(node != null);
		defer node.ReleaseRef();
		let panel = node as ToolPanelBody;
		Test.Assert(panel != null);

		// The planes from 1, the chosen one checked; a wheel resize shows after a Sync.
		Test.Assert(panel.ChoiceCount(0) >= 2);
		Test.Assert(panel.ChoiceAt(0, 0).Text == "1");
		Test.Assert(panel.ChoiceAt(0, 1).Checked);
		Test.Assert(!panel.ChoiceAt(0, 1).Tooltip.IsEmpty, "what grows on it");
		tool.SetRadius(12.0f);
		panel.Sync();
		Test.Assert(panel.NumberAt(0).Value == 12.0);
		// The mode: Erase, then Smooth, each one at a time.
		Test.Assert(panel.ChoiceCount(1) == 3);
		panel.ChoiceAt(1, 1).HandleActivate();
		Test.Assert(tool.IsEraser);
		panel.ChoiceAt(1, 2).HandleActivate();
		Test.Assert(tool.IsSmooth);
		Test.Assert(!tool.IsEraser);
		Test.Assert(tool.Plane == 1, "the plane kept through the modes");
		panel.ChoiceAt(0, 0).HandleActivate();
		Test.Assert(tool.Plane == 0);
		panel.CheckAt(0).HandleActivate(); // Airbrush
		Test.Assert(tool.IsAirbrush);
		tool.OnDeactivate();
	}
}
