namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;

class ToolkitTests
{
	// === SplitView ===

	[Test]
	public static void SplitView_RatioClamps()
	{
		let split = scope SplitView();
		split.SplitRatio = 1.5f;
		Test.Assert(split.SplitRatio == 1.0f);

		split.SplitRatio = -0.5f;
		Test.Assert(split.SplitRatio == 0.0f);
	}

	[Test]
	public static void SplitView_SetPanes()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let split = new SplitView();
		root.AddView(split);

		let left = new ColorView();
		let right = new ColorView();
		split.SetPanes(left, right);

		Test.Assert(split.FirstPane === left);
		Test.Assert(split.SecondPane === right);
	}

	[Test]
	public static void SplitView_FiresEvent()
	{
		let split = scope SplitView();
		float lastRatio = -1;
		split.OnSplitChanged.Add(new [&lastRatio](s, r) => { lastRatio = r; });

		split.SplitRatio = 0.3f;
		Test.Assert(Math.Abs(lastRatio - 0.3f) < 0.001f);
	}

	// === Toolbar ===

	[Test]
	public static void Toolbar_AddButton()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		let toolbar = new Toolbar();
		root.AddView(toolbar);

		let btn = toolbar.AddButton("Test");
		Test.Assert(btn != null);
		Test.Assert(toolbar.ChildCount == 1);
	}

	[Test]
	public static void Toolbar_AddSeparator()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		let toolbar = new Toolbar();
		root.AddView(toolbar);

		toolbar.AddButton("A");
		toolbar.AddSeparator();
		toolbar.AddButton("B");
		Test.Assert(toolbar.ChildCount == 3);
	}

	[Test]
	public static void Toolbar_Toggle()
	{
		let toggle = scope ToolbarToggle();
		Test.Assert(!toggle.IsChecked);

		bool fired = false;
		toggle.OnCheckedChanged.Add(new [&fired](t, v) => { fired = true; });

		toggle.IsChecked = true;
		Test.Assert(toggle.IsChecked);
		Test.Assert(fired);
	}

	// === StatusBar ===

	[Test]
	public static void StatusBar_SetText()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		let bar = new StatusBar();
		root.AddView(bar);

		bar.SetText("Ready");
		Test.Assert(bar.ChildCount == 1);

		// Calling again updates, doesn't add.
		bar.SetText("Updated");
		Test.Assert(bar.ChildCount == 1);
	}

	[Test]
	public static void StatusBar_AddSection()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		let bar = new StatusBar();
		root.AddView(bar);

		bar.SetText("Status");
		let section = bar.AddSection("Line 42");
		Test.Assert(section != null);
		Test.Assert(bar.ChildCount == 2);
	}

	// === MenuBar ===

	[Test]
	public static void MenuBar_AddMenu()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		let bar = new MenuBar();
		root.AddView(bar);

		let fileMenu = bar.AddMenu("File");
		Test.Assert(fileMenu != null);
		Test.Assert(bar.MenuCount == 1);

		bar.AddMenu("Edit");
		Test.Assert(bar.MenuCount == 2);
	}

	// === ColorPicker ===

	[Test]
	public static void ColorPicker_HSVToRGB_Red()
	{
		let c = ColorPicker.HSVToRGB(0, 1, 1);
		Test.Assert(c.R == 255);
		Test.Assert(c.G == 0);
		Test.Assert(c.B == 0);
	}

	[Test]
	public static void ColorPicker_HSVToRGB_Green()
	{
		let c = ColorPicker.HSVToRGB(120, 1, 1);
		Test.Assert(c.G == 255);
		Test.Assert(c.R == 0);
	}

	[Test]
	public static void ColorPicker_HSVToRGB_Blue()
	{
		let c = ColorPicker.HSVToRGB(240, 1, 1);
		Test.Assert(c.B == 255);
		Test.Assert(c.R == 0);
	}

	[Test]
	public static void ColorPicker_RGBToHSV_Roundtrip()
	{
		float h = 0, s = 0, v = 0;
		ColorPicker.RGBToHSV(1, 0, 0, ref h, ref s, ref v);
		Test.Assert(Math.Abs(h) < 1 || Math.Abs(h - 360) < 1); // 0 or 360
		Test.Assert(Math.Abs(s - 1) < 0.01f);
		Test.Assert(Math.Abs(v - 1) < 0.01f);
	}

	[Test]
	public static void ColorPicker_SetColor()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		let picker = new ColorPicker();
		root.AddView(picker);

		picker.SetColor(.(128, 64, 200, 255));
		let c = picker.CurrentColor;
		// Should roundtrip approximately.
		Test.Assert(Math.Abs((int)c.R - 128) <= 2);
		Test.Assert(Math.Abs((int)c.G - 64) <= 2);
		Test.Assert(Math.Abs((int)c.B - 200) <= 2);
	}

	// === PropertyGrid ===

	[Test]
	public static void PropertyGrid_AddRemove()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		let grid = new PropertyGrid();
		root.AddView(grid);

		grid.AddProperty(new BoolEditor("Visible", true));
		grid.AddProperty(new StringEditor("Name", "Test"));
		Test.Assert(grid.PropertyCount == 2);

		grid.RemoveProperty("Visible");
		Test.Assert(grid.PropertyCount == 1);
	}

	[Test]
	public static void PropertyGrid_Clear()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		let grid = new PropertyGrid();
		root.AddView(grid);

		grid.AddProperty(new IntEditor("X", 10));
		grid.AddProperty(new IntEditor("Y", 20));
		grid.Clear();
		Test.Assert(grid.PropertyCount == 0);
	}

	[Test]
	public static void PropertyGrid_GetProperty()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		let grid = new PropertyGrid();
		root.AddView(grid);

		grid.AddProperty(new FloatEditor("Speed", 1.5));
		let editor = grid.GetProperty("Speed");
		Test.Assert(editor != null);
		Test.Assert(editor.Name == "Speed");
	}

	[Test]
	public static void BoolEditor_Value()
	{
		let editor = scope BoolEditor("Flag", false);
		Test.Assert(!editor.Value);
		editor.Value = true;
		Test.Assert(editor.Value);
	}

	[Test]
	public static void FloatEditor_Value()
	{
		let editor = scope FloatEditor("Scale", 1.0, 0, 10, 0.1, 2);
		Test.Assert(editor.Value == 1.0);
		editor.Value = 5.5;
		Test.Assert(editor.Value == 5.5);
	}

	[Test]
	public static void IntEditor_Value()
	{
		let editor = scope IntEditor("Count", 42);
		Test.Assert(editor.Value == 42);
		editor.Value = 100;
		Test.Assert(editor.Value == 100);
	}

}
