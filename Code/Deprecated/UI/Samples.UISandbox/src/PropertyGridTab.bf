using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Samples.UISandbox;

/// Every property editor the grid ships, plus a categorised group.
///
/// The three transform rows share a category, which is what makes the grid fold them under one
/// header rather than listing them flat with the rest.
static class PropertyGridTab
{
	public static void Build(TabView tabView)
	{
		let demo = SandboxViews.VFlex(8.0f);
		demo.Padding = .(8, 8);
		tabView.AddTab("PropertyGrid", demo);

		let grid = new PropertyGrid();

		grid.AddProperty(new BoolEditor("Enabled", true));
		grid.AddProperty(new BoolEditor("Visible", true));
		grid.AddProperty(new StringEditor("Name", "Player"));
		grid.AddProperty(new FloatEditor("Speed", 5.0, 0.0, 100.0, 0.5, 1));
		grid.AddProperty(new IntEditor("Health", 100, 0, 999));
		grid.AddProperty(new RangeEditor("Volume", 0.75f, 0.0f, 1.0f, 0.01f));

		StringView[3] modes = .("Easy", "Normal", "Hard");
		grid.AddProperty(new EnumEditor("Mode", 0, modes));

		grid.AddProperty(new ColorEditor("Tint", Color.Rgb(255, 200, 100)));

		AddTransform(grid, "Position", .(1.0f, 2.5f, -3.0f));
		AddTransform(grid, "Rotation", .(0, 45, 0));
		AddTransform(grid, "Scale", .(1, 1, 1));

		demo.AddView(grid, SandboxViews.Grow(1));
	}

	private static void AddTransform(PropertyGrid grid, StringView name, Float3 value) =>
		grid.AddProperty(new Float3Editor(name, value, -100000.0f, 100000.0f, 0.1f, null,
			"Transform"));
}
