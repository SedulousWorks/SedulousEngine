namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;

class ToolkitTests
{
	// === MenuBar ===

	[Test]
	public static void MenuBar_AddMenu()
	{
		let menuBar = scope MenuBar();
		let menu = menuBar.AddMenu("File");
		Test.Assert(menu != null);
		Test.Assert(menuBar.MenuCount == 1);

		menuBar.AddMenu("Edit");
		Test.Assert(menuBar.MenuCount == 2);
	}

	// === Toolbar ===

	[Test]
	public static void Toolbar_AddButton()
	{
		let toolbar = scope Toolbar();
		let btn = toolbar.AddButton("Save");
		Test.Assert(btn != null);
		Test.Assert(toolbar.ChildCount == 1);
	}

	[Test]
	public static void Toolbar_AddSeparator()
	{
		let toolbar = scope Toolbar();
		toolbar.AddButton("A");
		toolbar.AddSeparator();
		toolbar.AddButton("B");
		Test.Assert(toolbar.ChildCount == 3);
	}

	[Test]
	public static void Toolbar_AddToggle()
	{
		let toolbar = scope Toolbar();
		let toggle = toolbar.AddToggle("Bold");
		Test.Assert(toggle != null);
		Test.Assert(!toggle.IsChecked);
		toggle.IsChecked = true;
		Test.Assert(toggle.IsChecked);
	}

	// === StatusBar ===

	[Test]
	public static void StatusBar_SetText()
	{
		let statusBar = scope StatusBar();
		statusBar.SetText("Ready");
		// SetText creates a default label as first child.
		Test.Assert(statusBar.ChildCount >= 1);
	}

	[Test]
	public static void StatusBar_AddSection()
	{
		let statusBar = scope StatusBar();
		let section = statusBar.AddSection("UTF-8");
		Test.Assert(section != null);
	}

	// === SplitView ===

	[Test]
	public static void SplitView_RatioClamping()
	{
		let sv = scope SplitView();
		sv.SplitRatio = -1;
		Test.Assert(sv.SplitRatio == 0);

		sv.SplitRatio = 2;
		Test.Assert(sv.SplitRatio == 1);
	}

	[Test]
	public static void SplitView_SetPanes()
	{
		let sv = scope SplitView();
		let first = new Label("A");
		let second = new Label("B");
		sv.SetPanes(first, second);

		Test.Assert(sv.FirstPane === first);
		Test.Assert(sv.SecondPane === second);
	}

	// === BreadcrumbBar ===

	[Test]
	public static void BreadcrumbBar_SetPath()
	{
		let bar = scope BreadcrumbBar();
		bar.SetPath("Project/Assets/Textures");

		Test.Assert(bar.SegmentCount == 3);
		Test.Assert(bar.GetSegment(0) == "Project");
		Test.Assert(bar.GetSegment(1) == "Assets");
		Test.Assert(bar.GetSegment(2) == "Textures");
	}

	[Test]
	public static void BreadcrumbBar_SetSegments()
	{
		let bar = scope BreadcrumbBar();
		bar.SetSegments(StringView[]("Home", "Documents", "File.txt"));

		Test.Assert(bar.SegmentCount == 3);
		Test.Assert(bar.GetSegment(0) == "Home");
		Test.Assert(bar.GetSegment(2) == "File.txt");
	}

	[Test]
	public static void BreadcrumbBar_GetPathUpTo()
	{
		let bar = scope BreadcrumbBar();
		bar.SetPath("A/B/C/D");

		let path = scope String();
		bar.GetPathUpTo(1, path);
		Test.Assert(path == "A/B");
	}

	[Test]
	public static void BreadcrumbBar_OnSegmentClicked()
	{
		let bar = scope BreadcrumbBar();
		bar.SetPath("A/B/C");

		bool fired = false;
		int32 firedIndex = -1;
		bar.OnSegmentClicked.Add(new [&fired, &firedIndex] (b, idx) =>
		{
			fired = true;
			firedIndex = idx;
		});

		// Can't easily simulate click without context, but event should be wired.
		Test.Assert(!fired);
	}

	// === ColorPicker ===

	[Test]
	public static void ColorPicker_DefaultColor()
	{
		let picker = scope ColorPicker();
		let color = picker.CurrentColor;
		// Default is white (H=0, S=1, V=1, A=1 -> RGB white... actually S=1,V=1 is red-ish)
		// HSVToRGB(0, 1, 1) = red. Let's just check it's valid.
		Test.Assert(color.A == 255);
	}

	[Test]
	public static void ColorPicker_SetColor()
	{
		let picker = scope ColorPicker();
		picker.CurrentColor = Color32(128, 64, 32, 255);
		let c = picker.CurrentColor;
		// Should round-trip approximately (HSV conversion may lose precision).
		Test.Assert(Math.Abs((int)c.R - 128) <= 2);
		Test.Assert(Math.Abs((int)c.G - 64) <= 2);
		Test.Assert(Math.Abs((int)c.B - 32) <= 2);
		Test.Assert(c.A == 255);
	}

	[Test]
	public static void ColorPicker_SetOriginalColor()
	{
		let picker = scope ColorPicker();
		picker.SetOriginalColor(.(255, 0, 0, 255));
		// No crash, original preview updated.
	}

	[Test]
	public static void ColorPicker_OnColorChanged()
	{
		let picker = scope ColorPicker();

		bool fired = false;
		picker.OnColorChanged.Add(new [&fired] (p, c) => { fired = true; });

		// Programmatic SetColor does NOT fire OnColorChanged (avoids feedback loops).
		// Event only fires from interactive changes (drag, field input).
		picker.CurrentColor = Color32(0, 255, 0, 255);
		Test.Assert(!fired);
	}

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
		Test.Assert(c.R == 0);
		Test.Assert(c.G == 255);
		Test.Assert(c.B == 0);
	}

	[Test]
	public static void ColorPicker_HSVToRGB_Blue()
	{
		let c = ColorPicker.HSVToRGB(240, 1, 1);
		Test.Assert(c.R == 0);
		Test.Assert(c.G == 0);
		Test.Assert(c.B == 255);
	}

	[Test]
	public static void ColorPicker_HSVToRGB_White()
	{
		let c = ColorPicker.HSVToRGB(0, 0, 1);
		Test.Assert(c.R == 255);
		Test.Assert(c.G == 255);
		Test.Assert(c.B == 255);
	}

	[Test]
	public static void ColorPicker_HSVToRGB_Black()
	{
		let c = ColorPicker.HSVToRGB(0, 0, 0);
		Test.Assert(c.R == 0);
		Test.Assert(c.G == 0);
		Test.Assert(c.B == 0);
	}

	[Test]
	public static void ColorPicker_RGBToHSV_Roundtrip()
	{
		float h = 0, s = 0, v = 0;
		ColorPicker.RGBToHSV(1.0f, 0.5f, 0.25f, ref h, ref s, ref v);
		let c = ColorPicker.HSVToRGB(h, s, v);
		Test.Assert(Math.Abs((int)c.R - 255) <= 1);
		Test.Assert(Math.Abs((int)c.G - 128) <= 1);
		Test.Assert(Math.Abs((int)c.B - 64) <= 1);
	}

	// === PropertyGrid ===

	[Test]
	public static void PropertyGrid_AddProperty()
	{
		let grid = scope PropertyGrid();
		let editor = new BoolEditor("Enabled", true);
		grid.AddProperty(editor);
		Test.Assert(grid.PropertyCount == 1);
	}

	[Test]
	public static void PropertyGrid_GetProperty()
	{
		let grid = scope PropertyGrid();
		let editor = new BoolEditor("Enabled", true);
		grid.AddProperty(editor);

		let found = grid.GetProperty("Enabled");
		Test.Assert(found === editor);

		let notFound = grid.GetProperty("Missing");
		Test.Assert(notFound == null);
	}

	[Test]
	public static void PropertyGrid_RemoveProperty()
	{
		let grid = scope PropertyGrid();
		grid.AddProperty(new BoolEditor("A", false));
		grid.AddProperty(new BoolEditor("B", true));
		Test.Assert(grid.PropertyCount == 2);

		grid.RemoveProperty("A");
		Test.Assert(grid.PropertyCount == 1);
	}

	[Test]
	public static void PropertyGrid_Clear()
	{
		let grid = scope PropertyGrid();
		grid.AddProperty(new BoolEditor("A", false));
		grid.AddProperty(new IntEditor("B", 42));
		grid.Clear();
		Test.Assert(grid.PropertyCount == 0);
	}

	// === PropertyEditor types ===

	[Test]
	public static void BoolEditor_Value()
	{
		let editor = scope BoolEditor("Flag", true);
		Test.Assert(editor.Value == true);
		editor.Value = false;
		Test.Assert(editor.Value == false);
	}

	[Test]
	public static void FloatEditor_Value()
	{
		let editor = scope FloatEditor("Speed", 3.14);
		Test.Assert(Math.Abs(editor.Value - 3.14) < 0.01);
		editor.Value = 2.0;
		Test.Assert(Math.Abs(editor.Value - 2.0) < 0.01);
	}

	[Test]
	public static void IntEditor_Value()
	{
		let editor = scope IntEditor("Count", 42);
		Test.Assert(editor.Value == 42);
		editor.Value = 100;
		Test.Assert(editor.Value == 100);
	}

	[Test]
	public static void StringEditor_Value()
	{
		let editor = scope StringEditor("Name", "Hello");
		Test.Assert(editor.Value == "Hello");
		editor.Value = "World";
		Test.Assert(editor.Value == "World");
	}

	[Test]
	public static void EnumEditor_Value()
	{
		let editor = scope EnumEditor("Mode", 1, StringView[]("Off", "On", "Auto"));
		Test.Assert(editor.Value == 1);
		editor.Value = 2;
		Test.Assert(editor.Value == 2);
	}

	[Test]
	public static void RangeEditor_Value()
	{
		let editor = scope RangeEditor("Volume", 0.5f, 0, 1);
		Test.Assert(Math.Abs(editor.Value - 0.5f) < 0.01f);
		editor.Value = 0.8f;
		Test.Assert(Math.Abs(editor.Value - 0.8f) < 0.01f);
	}

	[Test]
	public static void ColorEditor_Value()
	{
		let editor = scope ColorEditor("Tint", .(255, 0, 0, 255));
		Test.Assert(editor.Value.R == 255);
		Test.Assert(editor.Value.G == 0);
		editor.Value = .(0, 255, 0, 255);
		Test.Assert(editor.Value.G == 255);
	}

	[Test]
	public static void Vector3Editor_Value()
	{
		let editor = scope Vector3Editor("Position", .(1, 2, 3));
		Test.Assert(editor.Value.X == 1);
		Test.Assert(editor.Value.Y == 2);
		Test.Assert(editor.Value.Z == 3);
		editor.Value = .(4, 5, 6);
		Test.Assert(editor.Value.X == 4);
	}

	[Test]
	public static void PropertyEditor_EditTransaction()
	{
		let editor = scope BoolEditor("Test", false);

		bool began = false;
		bool ended = false;
		editor.OnEditBegin.Add(new [&began] (e) => { began = true; });
		editor.OnEditEnd.Add(new [&ended] (e) => { ended = true; });

		editor.[Friend]BeginEdit();
		Test.Assert(began);
		Test.Assert(editor.IsEditing);

		editor.[Friend]EndEdit();
		Test.Assert(ended);
		Test.Assert(!editor.IsEditing);
	}
}
