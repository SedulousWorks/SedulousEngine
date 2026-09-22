using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.ViewportTools;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Vegetation.Tests;

/// The brush's settings panel: it registers, it builds, and its rows drive the tool. The
/// mode row is what keeps the erase target visible rather than implied.
class VegetationPanelTests
{
	/// The panel's property grid, wherever it sits in the tree.
	private static PropertyGrid FindGrid(View view)
	{
		if (let grid = view as PropertyGrid)
			return grid;
		if (let group = view as ViewGroup)
		{
			for (int k < group.ChildCount)
			{
				if (let found = FindGrid(group.GetChildAt(k)))
					return found;
			}
		}
		return null;
	}

	private static PropertyEditor Find(View view, StringView name)
	{
		let grid = FindGrid(view);
		if (grid == null)
			return null;
		for (int i < grid.PropertyCount)
		{
			if (grid.PropertyAt(i).Name == name)
				return grid.PropertyAt(i);
		}
		return null;
	}

	private static int32 CountToggles(View view)
	{
		var n = (int32)0;
		if (view is ToggleButton)
			n++;
		if (let group = view as ViewGroup)
		{
			for (int k < group.ChildCount)
				n += CountToggles(group.GetChildAt(k));
		}
		return n;
	}

	[Test]
	public static void TheProviderRegistersAndBuildsAPanelForTheBrush()
	{
		VegetationEditor.RegisterToolPanels();
		VegetationEditor.RegisterToolPanels(); // idempotent, first wins per tool id

		let registry = ViewportToolPanelRegistry.Global;
		let provider = registry.FindByToolId("vegetation.paint");
		Test.Assert(provider != null);
		Test.Assert(provider.Placement == .Float);

		let fx = scope VegetationFixture();
		let commands = scope EditorCommandStack();
		let tool = scope VegetationPaintTool(fx.Scene, commands, null);
		var context = ViewportToolHostContext();
		context.Scene = fx.Scene;
		context.Commands = commands;

		let panel = provider.CreatePanel(tool, context);
		Test.Assert(panel != null);
		defer panel.ReleaseRef();

		// A mode row of three and a plane row of four: the erase target stays visible.
		Test.Assert(CountToggles(panel) == 7);
	}

	[Test]
	public static void ThePanelRowsDriveTheToolAndTheWheelFeedsTheRadiusBack()
	{
		VegetationEditor.RegisterToolPanels();
		let provider = ViewportToolPanelRegistry.Global.FindByToolId("vegetation.paint");
		Test.Assert(provider != null);

		let fx = scope VegetationFixture();
		let commands = scope EditorCommandStack();
		let tool = scope VegetationPaintTool(fx.Scene, commands, null);
		var context = ViewportToolHostContext();
		context.Scene = fx.Scene;
		context.Commands = commands;

		let panel = provider.CreatePanel(tool, context);
		Test.Assert(panel != null);
		defer panel.ReleaseRef();

		let radius = Find(panel, "Radius") as FloatEditor;
		let strength = Find(panel, "Strength") as FloatEditor;
		let spacing = Find(panel, "Spacing") as FloatEditor;
		let airbrush = Find(panel, "Airbrush") as BoolEditor;
		Test.Assert((radius != null) && (strength != null) && (spacing != null)
			&& (airbrush != null));

		radius.Setter(24.0);
		Test.Assert(tool.Radius == 24.0f);
		strength.Setter(0.4);
		Test.Assert(Math.Abs(tool.Strength - 0.4f) < 0.001f);
		spacing.Setter(0.8);
		Test.Assert(Math.Abs(tool.Spacing - 0.8f) < 0.001f);
		airbrush.Setter(true);
		Test.Assert(tool.IsAirbrush);

		// Wheel sizing pushes the new radius back into the row.
		tool.SetRadius(11.0f);
		Test.Assert(Math.Abs((float)radius.Value - 11.0f) < 0.001f);
	}
}
