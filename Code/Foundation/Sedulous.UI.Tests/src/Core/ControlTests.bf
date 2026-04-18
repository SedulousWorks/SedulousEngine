namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Tests for new controls: CheckBox, RadioButton, RadioGroup,
/// ToggleButton, ToggleSwitch, ProgressBar, Slider, TabView, ComboBox.
class ControlTests
{
	// === CheckBox ===

	[Test]
	public static void CheckBox_ToggleOnClick()
	{
		let cb = scope CheckBox();
		Test.Assert(!cb.IsChecked);

		let args = scope MouseEventArgs();
		args.Set(5, 5, .Left);
		cb.OnMouseDown(args);

		Test.Assert(cb.IsChecked);
		Test.Assert(args.Handled);
	}

	[Test]
	public static void CheckBox_FiresEvent()
	{
		let cb = scope CheckBox();
		bool fired = false;
		bool newVal = false;
		cb.OnCheckedChanged.Add(new [&](c, val) => { fired = true; newVal = val; });

		cb.IsChecked = true;
		Test.Assert(fired);
		Test.Assert(newVal);
	}

	[Test]
	public static void CheckBox_SpaceToggles()
	{
		let cb = scope CheckBox();
		let args = scope KeyEventArgs();
		args.Set(.Space, .None, false);
		cb.OnKeyDown(args);

		Test.Assert(cb.IsChecked);
		Test.Assert(args.Handled);
	}

	// === RadioButton + RadioGroup ===

	[Test]
	public static void RadioButton_CanOnlyCheck()
	{
		let rb = scope RadioButton();
		rb.IsChecked = true;
		Test.Assert(rb.IsChecked);

		// Clicking again doesn't uncheck.
		let args = scope MouseEventArgs();
		args.Set(5, 5, .Left);
		rb.OnMouseDown(args);
		Test.Assert(rb.IsChecked);
	}

	[Test]
	public static void RadioGroup_MutualExclusion()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		let group = new RadioGroup();
		root.AddView(group);

		let r1 = new RadioButton(); r1.SetText("A");
		let r2 = new RadioButton(); r2.SetText("B");
		let r3 = new RadioButton(); r3.SetText("C");
		group.AddRadioButton(r1);
		group.AddRadioButton(r2);
		group.AddRadioButton(r3);

		r1.IsChecked = true;
		Test.Assert(r1.IsChecked);
		Test.Assert(!r2.IsChecked);

		r2.IsChecked = true;
		Test.Assert(!r1.IsChecked);
		Test.Assert(r2.IsChecked);
		Test.Assert(group.CheckedButton === r2);
	}

	[Test]
	public static void RadioGroup_ClearCheck()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		let group = new RadioGroup();
		root.AddView(group);

		let r1 = new RadioButton();
		group.AddRadioButton(r1);
		r1.IsChecked = true;

		group.ClearCheck();
		Test.Assert(!r1.IsChecked);
		Test.Assert(group.CheckedButton == null);
	}

	// === ToggleButton ===

	[Test]
	public static void ToggleButton_ClickToggles()
	{
		let tb = scope ToggleButton();
		Test.Assert(!tb.IsChecked);

		let args = scope MouseEventArgs();
		args.Set(5, 5, .Left);
		tb.OnMouseDown(args);
		Test.Assert(tb.IsChecked);

		args.Set(5, 5, .Left);
		tb.OnMouseDown(args);
		Test.Assert(!tb.IsChecked);
	}

	// === ToggleSwitch ===

	[Test]
	public static void ToggleSwitch_ClickToggles()
	{
		let sw = scope ToggleSwitch();
		Test.Assert(!sw.IsChecked);

		let args = scope MouseEventArgs();
		args.Set(5, 5, .Left);
		sw.OnMouseDown(args);
		Test.Assert(sw.IsChecked);
	}

	// === ProgressBar ===

	[Test]
	public static void ProgressBar_ClampedRange()
	{
		let bar = scope ProgressBar();
		bar.Progress = 0.5f;
		Test.Assert(bar.Progress == 0.5f);

		bar.Progress = 1.5f;
		Test.Assert(bar.Progress == 1.0f);

		bar.Progress = -0.5f;
		Test.Assert(bar.Progress == 0.0f);
	}

	// === Slider ===

	[Test]
	public static void Slider_ValueClamped()
	{
		let slider = scope Slider();
		slider.Min = 0;
		slider.Max = 100;

		slider.Value = 50;
		Test.Assert(slider.Value == 50);

		slider.Value = 200;
		Test.Assert(slider.Value == 100);

		slider.Value = -10;
		Test.Assert(slider.Value == 0);
	}

	[Test]
	public static void Slider_StepSnap()
	{
		let slider = scope Slider();
		slider.Min = 0;
		slider.Max = 100;
		slider.Step = 10;

		slider.Value = 47;
		Test.Assert(slider.Value == 50);

		slider.Value = 3;
		Test.Assert(slider.Value == 0);
	}

	[Test]
	public static void Slider_FiresEvent()
	{
		let slider = scope Slider();
		slider.Max = 100;
		float lastVal = -1;
		slider.OnValueChanged.Add(new [&](s, val) => { lastVal = val; });

		slider.Value = 42;
		Test.Assert(lastVal == 42);
	}

	[Test]
	public static void Slider_KeyboardNav()
	{
		let slider = scope Slider();
		slider.Min = 0;
		slider.Max = 100;
		slider.Step = 10;
		slider.Value = 50;

		let args = scope KeyEventArgs();
		args.Set(.Right, .None, false);
		slider.OnKeyDown(args);
		Test.Assert(slider.Value == 60);

		args.Set(.Left, .None, false);
		slider.OnKeyDown(args);
		Test.Assert(slider.Value == 50);

		args.Set(.Home, .None, false);
		slider.OnKeyDown(args);
		Test.Assert(slider.Value == 0);

		args.Set(.End, .None, false);
		slider.OnKeyDown(args);
		Test.Assert(slider.Value == 100);
	}

	// === TabView ===

	[Test]
	public static void TabView_AddAndSelect()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		let tabs = new TabView();
		root.AddView(tabs);

		let c1 = new Label(); c1.SetText("Tab 1");
		let c2 = new Label(); c2.SetText("Tab 2");
		tabs.AddTab("First", c1);
		tabs.AddTab("Second", c2);

		// First tab auto-selected.
		Test.Assert(tabs.SelectedIndex == 0);
		Test.Assert(c1.Visibility == .Visible);
		Test.Assert(c2.Visibility == .Gone);

		// Switch to second tab.
		tabs.SelectedIndex = 1;
		Test.Assert(c1.Visibility == .Gone);
		Test.Assert(c2.Visibility == .Visible);
	}

	[Test]
	public static void TabView_RemoveTab()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		let tabs = new TabView();
		root.AddView(tabs);

		let c1 = new Label(); c1.SetText("1");
		let c2 = new Label(); c2.SetText("2");
		tabs.AddTab("A", c1);
		tabs.AddTab("B", c2);

		tabs.RemoveTab(0);
		Test.Assert(tabs.TabCount == 1);
		Test.Assert(tabs.SelectedIndex == 0);
	}

	[Test]
	public static void TabView_FiresEvent()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		let tabs = new TabView();
		root.AddView(tabs);

		int lastIdx = -1;
		tabs.OnTabChanged.Add(new [&](t, idx) => { lastIdx = idx; });

		tabs.AddTab("A", new Label());
		tabs.AddTab("B", new Label());
		tabs.SelectedIndex = 1;
		Test.Assert(lastIdx == 1);
	}

	// === ComboBox ===

	[Test]
	public static void ComboBox_AddAndSelect()
	{
		let combo = scope ComboBox();
		combo.AddItem("Apple");
		combo.AddItem("Banana");
		combo.AddItem("Cherry");

		Test.Assert(combo.ItemCount == 3);
		Test.Assert(combo.SelectedIndex == -1);

		combo.SelectedIndex = 1;
		Test.Assert(combo.SelectedText == "Banana");
	}

	[Test]
	public static void ComboBox_RemoveItem()
	{
		let combo = scope ComboBox();
		combo.AddItem("A");
		combo.AddItem("B");
		combo.AddItem("C");
		combo.SelectedIndex = 2;

		combo.RemoveItem(2);
		Test.Assert(combo.ItemCount == 2);
		Test.Assert(combo.SelectedIndex == 1); // clamped
	}

	[Test]
	public static void ComboBox_ClearItems()
	{
		let combo = scope ComboBox();
		combo.AddItem("X");
		combo.AddItem("Y");
		combo.SelectedIndex = 0;

		combo.ClearItems();
		Test.Assert(combo.ItemCount == 0);
		Test.Assert(combo.SelectedIndex == -1);
	}

	[Test]
	public static void ComboBox_KeyboardNav()
	{
		let combo = scope ComboBox();
		combo.AddItem("A");
		combo.AddItem("B");
		combo.AddItem("C");
		combo.SelectedIndex = 0;

		let args = scope KeyEventArgs();
		args.Set(.Down, .None, false);
		combo.OnKeyDown(args);
		Test.Assert(combo.SelectedIndex == 1);

		args.Set(.Down, .None, false);
		combo.OnKeyDown(args);
		Test.Assert(combo.SelectedIndex == 2);

		args.Set(.Up, .None, false);
		combo.OnKeyDown(args);
		Test.Assert(combo.SelectedIndex == 1);
	}

	// === View.IsHovered ===

	[Test]
	public static void View_IsHovered_ComputedFromInputManager()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let layout = new FrameLayout();
		root.AddView(layout);

		let view = new ColorView();
		view.PreferredWidth = 100;
		view.PreferredHeight = 100;
		layout.AddView(view, new FrameLayout.LayoutParams() { Width = 100, Height = 100 });

		ctx.UpdateRootView(root);

		Test.Assert(!view.IsHovered);

		ctx.InputManager.ProcessMouseMove(50, 50);
		Test.Assert(view.IsHovered);

		ctx.InputManager.ProcessMouseMove(200, 200);
		Test.Assert(!view.IsHovered);
	}
}
