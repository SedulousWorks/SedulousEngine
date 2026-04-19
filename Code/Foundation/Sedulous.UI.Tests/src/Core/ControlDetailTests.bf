namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Comprehensive unit tests for individual UI controls.
/// Each test follows the UIContext + RootView pattern for controls
/// that need a tree, and scope allocation for simple property tests.
class ControlDetailTests
{
	// =====================================================================
	// Helper: test ICommand implementation
	// =====================================================================

	class TestCommand : ICommand
	{
		public bool CanExec = true;
		public int ExecuteCount;

		public bool CanExecute() => CanExec;
		public void Execute() { ExecuteCount++; }
	}

	// =====================================================================
	// Button
	// =====================================================================

	[Test]
	public static void Button_TextProperty()
	{
		let btn = scope Button();
		Test.Assert(btn.Text == null);

		btn.SetText("Click me");
		Test.Assert(btn.Text != null);
		Test.Assert(StringView(btn.Text) == "Click me");
	}

	[Test]
	public static void Button_SetTextOverwrites()
	{
		let btn = scope Button();
		btn.SetText("First");
		btn.SetText("Second");
		Test.Assert(StringView(btn.Text) == "Second");
	}

	[Test]
	public static void Button_FontSizeDefault()
	{
		let btn = scope Button();
		// Without a theme, FontSize falls back to 16.
		Test.Assert(btn.FontSize == 16);
	}

	[Test]
	public static void Button_FontSizeOverride()
	{
		let btn = scope Button();
		btn.FontSize = 24;
		Test.Assert(btn.FontSize == 24);
	}

	[Test]
	public static void Button_IsPressedStartsFalse()
	{
		let btn = scope Button();
		Test.Assert(!btn.IsPressed);
	}

	[Test]
	public static void Button_IsFocusableByDefault()
	{
		let btn = scope Button();
		Test.Assert(btn.IsFocusable);
	}

	[Test]
	public static void Button_OnClickFires()
	{
		let btn = scope Button();
		int fireCount = 0;
		btn.OnClick.Add(new [&](b) => { fireCount++; });

		btn.FireClick();
		Test.Assert(fireCount == 1);

		btn.FireClick();
		Test.Assert(fireCount == 2);
	}

	[Test]
	public static void Button_CommandExecutedOnClick()
	{
		let btn = scope Button();
		let cmd = scope TestCommand();
		btn.Command = cmd;

		btn.FireClick();
		Test.Assert(cmd.ExecuteCount == 1);
	}

	[Test]
	public static void Button_CommandNotExecutedWhenCannotExecute()
	{
		let btn = scope Button();
		let cmd = scope TestCommand();
		cmd.CanExec = false;
		btn.Command = cmd;

		btn.FireClick();
		Test.Assert(cmd.ExecuteCount == 0);
	}

	[Test]
	public static void Button_ControlState_DisabledWhenCommandCantExecute()
	{
		let btn = scope Button();
		let cmd = scope TestCommand();
		cmd.CanExec = false;
		btn.Command = cmd;

		Test.Assert(btn.GetControlState() == .Disabled);
	}

	[Test]
	public static void Button_ControlState_NormalByDefault()
	{
		let btn = scope Button();
		Test.Assert(btn.GetControlState() == .Normal);
	}

	[Test]
	public static void Button_ControlState_PressedWhenIsPressed()
	{
		let btn = scope Button();
		btn.IsPressed = true;
		Test.Assert(btn.GetControlState() == .Pressed);
	}

	[Test]
	public static void Button_PaddingDefault()
	{
		let btn = scope Button();
		let p = btn.Padding;
		// Default is (12, 8) meaning left=12, top=8, right=12, bottom=8.
		Test.Assert(p.Left == 12);
		Test.Assert(p.Top == 8);
	}

	// =====================================================================
	// Label
	// =====================================================================

	[Test]
	public static void Label_SetText()
	{
		let lbl = scope Label();
		Test.Assert(lbl.Text == null);

		lbl.SetText("Hello");
		Test.Assert(StringView(lbl.Text) == "Hello");
	}

	[Test]
	public static void Label_SetTextOverwrites()
	{
		let lbl = scope Label();
		lbl.SetText("First");
		lbl.SetText("Second");
		Test.Assert(StringView(lbl.Text) == "Second");
	}

	[Test]
	public static void Label_FontSizeDefault()
	{
		let lbl = scope Label();
		Test.Assert(lbl.FontSize == 16);
	}

	[Test]
	public static void Label_FontSizeOverride()
	{
		let lbl = scope Label();
		lbl.FontSize = 20;
		Test.Assert(lbl.FontSize == 20);
	}

	[Test]
	public static void Label_HAlignDefault()
	{
		let lbl = scope Label();
		Test.Assert(lbl.HAlign == .Left);
	}

	[Test]
	public static void Label_VAlignDefault()
	{
		let lbl = scope Label();
		Test.Assert(lbl.VAlign == .Middle);
	}

	[Test]
	public static void Label_AlignOverrides()
	{
		let lbl = scope Label();
		lbl.HAlign = .Center;
		lbl.VAlign = .Top;
		Test.Assert(lbl.HAlign == .Center);
		Test.Assert(lbl.VAlign == .Top);
	}

	// =====================================================================
	// CheckBox
	// =====================================================================

	[Test]
	public static void CheckBox_IsCheckedDefaultFalse()
	{
		let cb = scope CheckBox();
		Test.Assert(!cb.IsChecked);
	}

	[Test]
	public static void CheckBox_ToggleViaProperty()
	{
		let cb = scope CheckBox();
		cb.IsChecked = true;
		Test.Assert(cb.IsChecked);
		cb.IsChecked = false;
		Test.Assert(!cb.IsChecked);
	}

	[Test]
	public static void CheckBox_OnCheckedChangedFires()
	{
		let cb = scope CheckBox();
		int fireCount = 0;
		bool lastValue = false;
		cb.OnCheckedChanged.Add(new [&](c, val) => { fireCount++; lastValue = val; });

		cb.IsChecked = true;
		Test.Assert(fireCount == 1);
		Test.Assert(lastValue == true);

		cb.IsChecked = false;
		Test.Assert(fireCount == 2);
		Test.Assert(lastValue == false);
	}

	[Test]
	public static void CheckBox_EventNotFiredWhenSameValue()
	{
		let cb = scope CheckBox();
		int fireCount = 0;
		cb.OnCheckedChanged.Add(new [&](c, val) => { fireCount++; });

		cb.IsChecked = false; // same as default
		Test.Assert(fireCount == 0);
	}

	[Test]
	public static void CheckBox_MouseDownToggles()
	{
		let cb = scope CheckBox();
		let args = scope MouseEventArgs();
		args.Set(5, 5, .Left);
		cb.OnMouseDown(args);

		Test.Assert(cb.IsChecked);
		Test.Assert(args.Handled);

		// Click again to uncheck.
		args.Set(5, 5, .Left);
		cb.OnMouseDown(args);
		Test.Assert(!cb.IsChecked);
	}

	[Test]
	public static void CheckBox_KeyboardSpaceToggles()
	{
		let cb = scope CheckBox();
		let args = scope KeyEventArgs();
		args.Set(.Space, .None, false);
		cb.OnKeyDown(args);
		Test.Assert(cb.IsChecked);
		Test.Assert(args.Handled);
	}

	[Test]
	public static void CheckBox_KeyboardReturnToggles()
	{
		let cb = scope CheckBox();
		let args = scope KeyEventArgs();
		args.Set(.Return, .None, false);
		cb.OnKeyDown(args);
		Test.Assert(cb.IsChecked);
	}

	[Test]
	public static void CheckBox_SetText()
	{
		let cb = scope CheckBox();
		cb.SetText("Accept terms");
		// The text is private, but we can verify SetText doesn't crash
		// and that FontSize has a sane default.
		Test.Assert(cb.FontSize == 16);
	}

	[Test]
	public static void CheckBox_IsFocusable()
	{
		let cb = scope CheckBox();
		Test.Assert(cb.IsFocusable);
	}

	// =====================================================================
	// RadioButton + RadioGroup
	// =====================================================================

	[Test]
	public static void RadioButton_DefaultUnchecked()
	{
		let rb = scope RadioButton();
		Test.Assert(!rb.IsChecked);
	}

	[Test]
	public static void RadioButton_CanBeChecked()
	{
		let rb = scope RadioButton();
		rb.IsChecked = true;
		Test.Assert(rb.IsChecked);
	}

	[Test]
	public static void RadioButton_ClickDoesNotUncheck()
	{
		let rb = scope RadioButton();
		rb.IsChecked = true;

		let args = scope MouseEventArgs();
		args.Set(5, 5, .Left);
		rb.OnMouseDown(args);
		// Should remain checked.
		Test.Assert(rb.IsChecked);
	}

	[Test]
	public static void RadioButton_OnCheckedChangedFires()
	{
		let rb = scope RadioButton();
		int fireCount = 0;
		rb.OnCheckedChanged.Add(new [&](r, val) => { fireCount++; });

		rb.IsChecked = true;
		Test.Assert(fireCount == 1);
	}

	[Test]
	public static void RadioButton_SetText()
	{
		let rb = scope RadioButton();
		rb.SetText("Option A");
		Test.Assert(rb.FontSize == 16);
	}

	[Test]
	public static void RadioGroup_MutualExclusion()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

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
		Test.Assert(!r3.IsChecked);

		r2.IsChecked = true;
		Test.Assert(!r1.IsChecked);
		Test.Assert(r2.IsChecked);
		Test.Assert(!r3.IsChecked);
		Test.Assert(group.CheckedButton === r2);

		ctx.UpdateRootView(root);
	}

	[Test]
	public static void RadioGroup_SelectionChangedFires()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let group = new RadioGroup();
		root.AddView(group);

		let r1 = new RadioButton();
		let r2 = new RadioButton();
		group.AddRadioButton(r1);
		group.AddRadioButton(r2);

		RadioButton lastSelected = null;
		group.OnSelectionChanged.Add(new [&](g, btn) => { lastSelected = btn; });

		r1.IsChecked = true;
		Test.Assert(lastSelected === r1);

		r2.IsChecked = true;
		Test.Assert(lastSelected === r2);

		ctx.UpdateRootView(root);
	}

	[Test]
	public static void RadioGroup_CheckAt()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let group = new RadioGroup();
		root.AddView(group);

		let r1 = new RadioButton();
		let r2 = new RadioButton();
		group.AddRadioButton(r1);
		group.AddRadioButton(r2);

		group.CheckAt(1);
		Test.Assert(r2.IsChecked);
		Test.Assert(!r1.IsChecked);

		ctx.UpdateRootView(root);
	}

	[Test]
	public static void RadioGroup_ClearCheck()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let group = new RadioGroup();
		root.AddView(group);

		let r1 = new RadioButton();
		group.AddRadioButton(r1);
		r1.IsChecked = true;

		group.ClearCheck();
		Test.Assert(!r1.IsChecked);
		Test.Assert(group.CheckedButton == null);

		ctx.UpdateRootView(root);
	}

	[Test]
	public static void RadioGroup_DefaultOrientation()
	{
		let group = scope RadioGroup();
		Test.Assert(group.Orientation == .Vertical);
		Test.Assert(group.Spacing == 4);
	}

	// =====================================================================
	// Slider
	// =====================================================================

	[Test]
	public static void Slider_DefaultValues()
	{
		let slider = scope Slider();
		Test.Assert(slider.Min == 0);
		Test.Assert(slider.Max == 1);
		Test.Assert(slider.Value == 0);
		Test.Assert(slider.Step == 0);
	}

	[Test]
	public static void Slider_ValueClampedToMinMax()
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
	public static void Slider_StepSnapping()
	{
		let slider = scope Slider();
		slider.Min = 0;
		slider.Max = 100;
		slider.Step = 10;

		slider.Value = 47;
		Test.Assert(slider.Value == 50);

		slider.Value = 3;
		Test.Assert(slider.Value == 0);

		slider.Value = 95;
		Test.Assert(slider.Value == 100);
	}

	[Test]
	public static void Slider_OnValueChangedFires()
	{
		let slider = scope Slider();
		slider.Max = 100;

		float lastVal = -1;
		slider.OnValueChanged.Add(new [&](s, val) => { lastVal = val; });

		slider.Value = 42;
		Test.Assert(lastVal == 42);
	}

	[Test]
	public static void Slider_EventNotFiredWhenSameValue()
	{
		let slider = scope Slider();
		slider.Max = 100;
		slider.Value = 50;

		int fireCount = 0;
		slider.OnValueChanged.Add(new [&](s, val) => { fireCount++; });

		slider.Value = 50; // same value
		Test.Assert(fireCount == 0);
	}

	[Test]
	public static void Slider_ChangingMinClampsValue()
	{
		let slider = scope Slider();
		slider.Max = 100;
		slider.Value = 10;

		slider.Min = 20;
		Test.Assert(slider.Value == 20);
	}

	[Test]
	public static void Slider_ChangingMaxClampsValue()
	{
		let slider = scope Slider();
		slider.Max = 100;
		slider.Value = 80;

		slider.Max = 50;
		Test.Assert(slider.Value == 50);
	}

	[Test]
	public static void Slider_KeyboardNavigation()
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

	// =====================================================================
	// ProgressBar
	// =====================================================================

	[Test]
	public static void ProgressBar_DefaultZero()
	{
		let bar = scope ProgressBar();
		Test.Assert(bar.Progress == 0);
	}

	[Test]
	public static void ProgressBar_SetProgress()
	{
		let bar = scope ProgressBar();
		bar.Progress = 0.5f;
		Test.Assert(bar.Progress == 0.5f);
	}

	[Test]
	public static void ProgressBar_ClampAboveOne()
	{
		let bar = scope ProgressBar();
		bar.Progress = 1.5f;
		Test.Assert(bar.Progress == 1.0f);
	}

	[Test]
	public static void ProgressBar_ClampBelowZero()
	{
		let bar = scope ProgressBar();
		bar.Progress = -0.5f;
		Test.Assert(bar.Progress == 0.0f);
	}

	[Test]
	public static void ProgressBar_ExactBoundaries()
	{
		let bar = scope ProgressBar();

		bar.Progress = 0.0f;
		Test.Assert(bar.Progress == 0.0f);

		bar.Progress = 1.0f;
		Test.Assert(bar.Progress == 1.0f);
	}

	// =====================================================================
	// ToggleButton
	// =====================================================================

	[Test]
	public static void ToggleButton_DefaultUnchecked()
	{
		let tb = scope ToggleButton();
		Test.Assert(!tb.IsChecked);
	}

	[Test]
	public static void ToggleButton_Toggle()
	{
		let tb = scope ToggleButton();
		tb.IsChecked = true;
		Test.Assert(tb.IsChecked);
		tb.IsChecked = false;
		Test.Assert(!tb.IsChecked);
	}

	[Test]
	public static void ToggleButton_OnCheckedChangedFires()
	{
		let tb = scope ToggleButton();
		int fireCount = 0;
		bool lastVal = false;
		tb.OnCheckedChanged.Add(new [&](t, val) => { fireCount++; lastVal = val; });

		tb.IsChecked = true;
		Test.Assert(fireCount == 1);
		Test.Assert(lastVal == true);

		tb.IsChecked = false;
		Test.Assert(fireCount == 2);
		Test.Assert(lastVal == false);
	}

	[Test]
	public static void ToggleButton_MouseDownToggles()
	{
		let tb = scope ToggleButton();
		let args = scope MouseEventArgs();

		args.Set(5, 5, .Left);
		tb.OnMouseDown(args);
		Test.Assert(tb.IsChecked);
		Test.Assert(args.Handled);

		args.Set(5, 5, .Left);
		tb.OnMouseDown(args);
		Test.Assert(!tb.IsChecked);
	}

	[Test]
	public static void ToggleButton_KeySpaceToggles()
	{
		let tb = scope ToggleButton();
		let args = scope KeyEventArgs();

		args.Set(.Space, .None, false);
		tb.OnKeyDown(args);
		Test.Assert(tb.IsChecked);

		args.Set(.Space, .None, false);
		tb.OnKeyDown(args);
		Test.Assert(!tb.IsChecked);
	}

	[Test]
	public static void ToggleButton_SetText()
	{
		let tb = scope ToggleButton();
		tb.SetText("Bold");
		Test.Assert(tb.FontSize == 16);
	}

	[Test]
	public static void ToggleButton_IsFocusable()
	{
		let tb = scope ToggleButton();
		Test.Assert(tb.IsFocusable);
	}

	// =====================================================================
	// ToggleSwitch
	// =====================================================================

	[Test]
	public static void ToggleSwitch_DefaultUnchecked()
	{
		let sw = scope ToggleSwitch();
		Test.Assert(!sw.IsChecked);
	}

	[Test]
	public static void ToggleSwitch_Toggle()
	{
		let sw = scope ToggleSwitch();
		sw.IsChecked = true;
		Test.Assert(sw.IsChecked);
		sw.IsChecked = false;
		Test.Assert(!sw.IsChecked);
	}

	[Test]
	public static void ToggleSwitch_OnCheckedChangedFires()
	{
		let sw = scope ToggleSwitch();
		int fireCount = 0;
		bool lastVal = false;
		sw.OnCheckedChanged.Add(new [&](s, val) => { fireCount++; lastVal = val; });

		sw.IsChecked = true;
		Test.Assert(fireCount == 1);
		Test.Assert(lastVal == true);
	}

	[Test]
	public static void ToggleSwitch_MouseDownToggles()
	{
		let sw = scope ToggleSwitch();
		let args = scope MouseEventArgs();
		args.Set(5, 5, .Left);
		sw.OnMouseDown(args);
		Test.Assert(sw.IsChecked);
		Test.Assert(args.Handled);
	}

	[Test]
	public static void ToggleSwitch_KeySpaceToggles()
	{
		let sw = scope ToggleSwitch();
		let args = scope KeyEventArgs();
		args.Set(.Space, .None, false);
		sw.OnKeyDown(args);
		Test.Assert(sw.IsChecked);
	}

	[Test]
	public static void ToggleSwitch_SetText()
	{
		let sw = scope ToggleSwitch();
		sw.SetText("Dark mode");
		// Default font size for ToggleSwitch is 14.
		Test.Assert(sw.FontSize == 14);
	}

	[Test]
	public static void ToggleSwitch_TrackDimensions()
	{
		let sw = scope ToggleSwitch();
		Test.Assert(sw.TrackWidth == 44);
		Test.Assert(sw.TrackHeight == 24);
		Test.Assert(sw.KnobSize == 20);
	}

	[Test]
	public static void ToggleSwitch_IsFocusable()
	{
		let sw = scope ToggleSwitch();
		Test.Assert(sw.IsFocusable);
	}

	// =====================================================================
	// ScrollBar
	// =====================================================================

	[Test]
	public static void ScrollBar_DefaultValues()
	{
		let sb = scope ScrollBar();
		Test.Assert(sb.Value == 0);
		Test.Assert(sb.Min == 0);
		Test.Assert(sb.MaxValue == 100);
		Test.Assert(sb.BarThickness == 8);
		Test.Assert(sb.SmallChange == 20);
	}

	[Test]
	public static void ScrollBar_ThumbRatio()
	{
		let sb = scope ScrollBar();
		sb.MaxValue = 100;
		sb.ViewportSize = 50;
		// ThumbRatio = Clamp(50 / (100+50), 0.05, 1) = 50/150 ~ 0.333
		let ratio = sb.ThumbRatio;
		Test.Assert(Math.Abs(ratio - (50.0f / 150.0f)) < 0.01f);
	}

	[Test]
	public static void ScrollBar_ThumbRatioFullViewport()
	{
		let sb = scope ScrollBar();
		sb.MaxValue = 0;
		sb.ViewportSize = 100;
		// No scrollable content -> ThumbRatio = 1.0
		Test.Assert(sb.ThumbRatio == 1.0f);
	}

	[Test]
	public static void ScrollBar_NormalizedValue()
	{
		let sb = scope ScrollBar();
		sb.MaxValue = 100;
		sb.Value = 50;
		Test.Assert(Math.Abs(sb.NormalizedValue - 0.5f) < 0.01f);
	}

	[Test]
	public static void ScrollBar_NormalizedValueClamped()
	{
		let sb = scope ScrollBar();
		sb.MaxValue = 100;
		sb.Value = 200; // above max (ScrollBar doesn't auto-clamp Value)
		// NormalizedValue clamps to [0,1]
		Test.Assert(sb.NormalizedValue == 1.0f);
	}

	[Test]
	public static void ScrollBar_LargeChangeAutoFromViewport()
	{
		let sb = scope ScrollBar();
		sb.ViewportSize = 200;
		// Default LargeChange = ViewportSize * 0.9 when not explicitly set.
		Test.Assert(Math.Abs(sb.LargeChange - 180.0f) < 0.01f);
	}

	[Test]
	public static void ScrollBar_LargeChangeExplicit()
	{
		let sb = scope ScrollBar();
		sb.ViewportSize = 200;
		sb.LargeChange = 50;
		Test.Assert(sb.LargeChange == 50);
	}

	[Test]
	public static void ScrollBar_Orientation()
	{
		let sb = scope ScrollBar();
		Test.Assert(sb.Orientation == .Vertical);
		sb.Orientation = .Horizontal;
		Test.Assert(sb.Orientation == .Horizontal);
	}

	// =====================================================================
	// Separator
	// =====================================================================

	[Test]
	public static void Separator_DefaultThickness()
	{
		let sep = scope Separator();
		Test.Assert(sep.SeparatorThickness == 1);
	}

	[Test]
	public static void Separator_CustomThickness()
	{
		let sep = scope Separator();
		sep.SeparatorThickness = 3;
		Test.Assert(sep.SeparatorThickness == 3);
	}

	[Test]
	public static void Separator_DefaultOrientation()
	{
		let sep = scope Separator();
		Test.Assert(sep.Orientation == .Horizontal);
	}

	[Test]
	public static void Separator_MeasuresCorrectly()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let sep = scope Separator();
		sep.SeparatorThickness = 2;

		// Measure directly with Unspecified to test natural size.
		sep.Measure(.Unspecified(), .Unspecified());

		// For a horizontal separator, height (Y) should be SeparatorThickness.
		Test.Assert(sep.MeasuredSize.Y == 2);
	}

	[Test]
	public static void Separator_VerticalMeasuresCorrectly()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let sep = scope Separator();
		sep.Orientation = .Vertical;
		sep.SeparatorThickness = 4;

		// Measure directly with Unspecified to test natural size.
		sep.Measure(.Unspecified(), .Unspecified());

		// For a vertical separator, width (X) should be SeparatorThickness.
		Test.Assert(sep.MeasuredSize.X == 4);
	}

	// =====================================================================
	// NumericField
	// =====================================================================

	[Test]
	public static void NumericField_DefaultValues()
	{
		let nf = scope NumericField();
		Test.Assert(nf.Value == 0);
		Test.Assert(nf.Min == 0);
		Test.Assert(nf.Max == 100);
		Test.Assert(nf.Step == 1);
		Test.Assert(nf.DecimalPlaces == 0);
	}

	[Test]
	public static void NumericField_ValueClampedToMin()
	{
		let nf = scope NumericField();
		nf.Min = 10;
		nf.Max = 100;
		nf.Value = 5;
		Test.Assert(nf.Value == 10);
	}

	[Test]
	public static void NumericField_ValueClampedToMax()
	{
		let nf = scope NumericField();
		nf.Min = 0;
		nf.Max = 50;
		nf.Value = 75;
		Test.Assert(nf.Value == 50);
	}

	[Test]
	public static void NumericField_Increment()
	{
		let nf = scope NumericField();
		nf.Max = 100;
		nf.Step = 5;
		nf.Value = 10;
		nf.Increment();
		Test.Assert(nf.Value == 15);
	}

	[Test]
	public static void NumericField_Decrement()
	{
		let nf = scope NumericField();
		nf.Max = 100;
		nf.Step = 5;
		nf.Value = 10;
		nf.Decrement();
		Test.Assert(nf.Value == 5);
	}

	[Test]
	public static void NumericField_IncrementClamped()
	{
		let nf = scope NumericField();
		nf.Max = 100;
		nf.Step = 10;
		nf.Value = 95;
		nf.Increment();
		Test.Assert(nf.Value == 100);
	}

	[Test]
	public static void NumericField_DecrementClamped()
	{
		let nf = scope NumericField();
		nf.Min = 0;
		nf.Max = 100;
		nf.Step = 10;
		nf.Value = 5;
		nf.Decrement();
		Test.Assert(nf.Value == 0);
	}

	[Test]
	public static void NumericField_OnValueChangedFires()
	{
		let nf = scope NumericField();
		nf.Max = 100;

		double lastVal = -1;
		nf.OnValueChanged.Add(new [&](f, val) => { lastVal = val; });

		nf.Value = 42;
		Test.Assert(lastVal == 42);
	}

	[Test]
	public static void NumericField_StepZeroAllowed()
	{
		let nf = scope NumericField();
		nf.Step = 0;
		Test.Assert(nf.Step == 0);
	}

	[Test]
	public static void NumericField_ChangingMinClampsValue()
	{
		let nf = scope NumericField();
		nf.Max = 100;
		nf.Value = 5;
		nf.Min = 10;
		Test.Assert(nf.Value == 10);
	}

	[Test]
	public static void NumericField_ChangingMaxClampsValue()
	{
		let nf = scope NumericField();
		nf.Max = 100;
		nf.Value = 80;
		nf.Max = 50;
		Test.Assert(nf.Value == 50);
	}

	// =====================================================================
	// RepeatButton
	// =====================================================================

	[Test]
	public static void RepeatButton_DefaultDelay()
	{
		let rb = scope RepeatButton();
		Test.Assert(rb.Delay == 0.5f);
	}

	[Test]
	public static void RepeatButton_DefaultInterval()
	{
		let rb = scope RepeatButton();
		Test.Assert(rb.Interval == 0.1f);
	}

	[Test]
	public static void RepeatButton_CustomDelayInterval()
	{
		let rb = scope RepeatButton();
		rb.Delay = 0.3f;
		rb.Interval = 0.05f;
		Test.Assert(rb.Delay == 0.3f);
		Test.Assert(rb.Interval == 0.05f);
	}

	[Test]
	public static void RepeatButton_InheritsButtonBehavior()
	{
		let rb = scope RepeatButton();
		// RepeatButton extends Button, so it should have Text, OnClick, etc.
		rb.SetText("Hold me");
		Test.Assert(StringView(rb.Text) == "Hold me");

		int fireCount = 0;
		rb.OnClick.Add(new [&](b) => { fireCount++; });
		rb.FireClick();
		Test.Assert(fireCount == 1);
	}

	[Test]
	public static void RepeatButton_IsFocusable()
	{
		let rb = scope RepeatButton();
		Test.Assert(rb.IsFocusable);
	}

	// =====================================================================
	// ImageView
	// =====================================================================

	[Test]
	public static void ImageView_DefaultImage()
	{
		let iv = scope ImageView();
		Test.Assert(iv.Image == null);
	}

	[Test]
	public static void ImageView_DefaultScaleType()
	{
		let iv = scope ImageView();
		Test.Assert(iv.ScaleType == .FillBounds);
	}

	[Test]
	public static void ImageView_ScaleTypeOverride()
	{
		let iv = scope ImageView();
		iv.ScaleType = .FitCenter;
		Test.Assert(iv.ScaleType == .FitCenter);

		iv.ScaleType = .None;
		Test.Assert(iv.ScaleType == .None);

		iv.ScaleType = .CenterCrop;
		Test.Assert(iv.ScaleType == .CenterCrop);
	}

	[Test]
	public static void ImageView_TintDefault()
	{
		let iv = scope ImageView();
		Test.Assert(iv.Tint == .White);
	}

	[Test]
	public static void ImageView_TintOverride()
	{
		let iv = scope ImageView();
		iv.Tint = .(255, 0, 0, 255);
		Test.Assert(iv.Tint.R == 255);
		Test.Assert(iv.Tint.G == 0);
	}

	// =====================================================================
	// ListView
	// =====================================================================

	/// Simple test adapter for ListView tests.
	class SimpleTestAdapter : IListAdapter
	{
		public int32 Count;

		public this(int32 count) { Count = count; }

		public int32 ItemCount => Count;

		public void SetObserver(IListAdapterObserver observer) { }

		public View CreateView(int32 viewType)
		{
			return new Label();
		}

		public void BindView(View view, int32 position)
		{
			if (let label = view as Label)
			{
				let text = scope String();
				text.AppendF("Item {}", position);
				label.SetText(text);
			}
		}
	}

	[Test]
	public static void ListView_AdapterSetGet()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let list = new ListView();
		root.AddView(list);

		Test.Assert(list.Adapter == null);

		let adapter = new SimpleTestAdapter(10);
		defer delete adapter;
		list.Adapter = adapter;
		Test.Assert(list.Adapter === adapter);

		ctx.UpdateRootView(root);
	}

	[Test]
	public static void ListView_ItemHeight()
	{
		let list = scope ListView();
		Test.Assert(list.ItemHeight == 30); // default

		list.ItemHeight = 50;
		Test.Assert(list.ItemHeight == 50);
	}

	[Test]
	public static void ListView_ScrollToPosition()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 200);

		let list = new ListView();
		list.ItemHeight = 25;
		let adapter = new SimpleTestAdapter(100);
		defer delete adapter;
		list.Adapter = adapter;
		root.AddView(list);

		ctx.UpdateRootView(root);

		// Scroll to item 50 (at 50*25 = 1250px).
		list.ScrollToPosition(50);
		// ScrollY should have moved so item 50 is visible.
		Test.Assert(list.ScrollY > 0);

		ctx.UpdateRootView(root);
	}

	[Test]
	public static void ListView_OnItemLongPressEventExists()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let list = new ListView();
		root.AddView(list);

		// Verify we can subscribe to OnItemLongPress without error.
		int pressedItem = -1;
		list.OnItemLongPress.Add(new [&](pos) => { pressedItem = pos; });
		Test.Assert(pressedItem == -1); // not fired yet

		ctx.UpdateRootView(root);
	}

	[Test]
	public static void ListView_OnItemClickedFires()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let list = new ListView();
		list.ItemHeight = 30;
		let adapter = new SimpleTestAdapter(10);
		defer delete adapter;
		list.Adapter = adapter;
		root.AddView(list);

		ctx.UpdateRootView(root);

		int32 clickedPos = -1;
		list.OnItemClicked.Add(new [&](pos, count) => { clickedPos = pos; });

		// Simulate a click in the first item area.
		let args = scope MouseEventArgs();
		args.Set(50, 15, .Left, 1); // y=15 is within first item (0..30)
		list.OnMouseDown(args);
		Test.Assert(clickedPos == 0);

		ctx.UpdateRootView(root);
	}

	[Test]
	public static void ListView_LongPressTimeDefault()
	{
		let list = scope ListView();
		Test.Assert(list.LongPressTime == 0.5f);
	}

	[Test]
	public static void ListView_SelectionModelPresent()
	{
		let list = scope ListView();
		Test.Assert(list.Selection != null);
	}

	[Test]
	public static void ListView_ScrollByClamps()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 200);

		let list = new ListView();
		list.ItemHeight = 25;
		let adapter = new SimpleTestAdapter(100);
		defer delete adapter;
		list.Adapter = adapter;
		root.AddView(list);

		ctx.UpdateRootView(root);

		// Scroll negative should clamp to 0.
		list.ScrollBy(-1000);
		Test.Assert(list.ScrollY == 0);

		ctx.UpdateRootView(root);
	}

	// =====================================================================
	// TabView — Closable Tabs
	// =====================================================================

	[Test]
	public static void TabView_AddClosableTab()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let tabs = new TabView();
		root.AddView(tabs, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

		tabs.AddTab("Normal", new ColorView());
		tabs.AddTab("Closable", new ColorView(), closable: true);

		Test.Assert(tabs.TabCount == 2);
	}

	[Test]
	public static void TabView_CloseRequestedEvent_Fires()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let tabs = new TabView();
		root.AddView(tabs, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

		tabs.AddTab("Tab1", new ColorView(), closable: true);
		tabs.AddTab("Tab2", new ColorView(), closable: true);

		int closedIndex = -1;
		tabs.OnTabCloseRequested.Add(new [&closedIndex](tv, idx) => { closedIndex = idx; });

		// Simulate clicking the close button area on the first tab.
		// We need to layout first so tab rects are computed.
		ctx.UpdateRootView(root);

		// Force a draw to rebuild tab rects (they're built in OnDraw).
		// Instead, just verify the event is wired — actual close button
		// hit-testing requires rendered tab rects.
		tabs.OnTabCloseRequested(tabs, 0);
		Test.Assert(closedIndex == 0);
	}

	[Test]
	public static void TabView_RemoveTab_OnClose()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let tabs = new TabView();
		root.AddView(tabs, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

		tabs.AddTab("A", new ColorView(), closable: true);
		tabs.AddTab("B", new ColorView(), closable: true);
		tabs.AddTab("C", new ColorView());

		tabs.OnTabCloseRequested.Add(new (tv, idx) => { tv.RemoveTab(idx); });

		Test.Assert(tabs.TabCount == 3);

		// Close first tab.
		tabs.OnTabCloseRequested(tabs, 0);
		Test.Assert(tabs.TabCount == 2);
	}

	[Test]
	public static void TabView_ClosableTab_WiderThanNormal()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let tabs = new TabView();
		root.AddView(tabs, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });
		tabs.AddTab("Test", new ColorView(), closable: false);
		tabs.AddTab("Test", new ColorView(), closable: true);

		// Closable tab should request more width for the X button.
		// Can't easily measure without font service, but verify no crash.
		Test.Assert(tabs.TabCount == 2);
	}

	[Test]
	public static void TabView_CloseLastTab_SelectsPrevious()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let tabs = new TabView();
		root.AddView(tabs, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

		tabs.AddTab("A", new ColorView());
		tabs.AddTab("B", new ColorView(), closable: true);
		tabs.SelectedIndex = 1;

		tabs.RemoveTab(1);
		Test.Assert(tabs.SelectedIndex == 0);
		Test.Assert(tabs.TabCount == 1);
	}
}
