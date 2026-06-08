namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class ControlTests
{
	// === Button ===

	[Test]
	public static void Button_FiresClickOnMouseUpAfterDown()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let btn = new Button("Test");
		root.AddView(btn);
		TestSetup.Layout(ctx, root);

		bool clicked = false;
		btn.OnClick.Add(new [&clicked] (b) => { clicked = true; });

		let downArgs = scope MouseEventArgs();
		downArgs.Set(10, 10, .Left);
		btn.OnMouseDown(downArgs);
		Test.Assert(btn.IsPressed);

		let upArgs = scope MouseEventArgs();
		upArgs.Set(10, 10, .Left);
		btn.OnMouseUp(upArgs);
		Test.Assert(!btn.IsPressed);
	}

	[Test]
	public static void Button_DisabledDoesNotClick()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let btn = new Button("Test");
		btn.IsEnabled = false;
		root.AddView(btn);

		bool clicked = false;
		btn.OnClick.Add(new [&clicked] (b) => { clicked = true; });

		btn.FireClick();
		Test.Assert(!clicked);
	}

	[Test]
	public static void Button_KeyboardActivation()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let btn = new Button("Test");
		root.AddView(btn);

		bool clicked = false;
		btn.OnClick.Add(new [&clicked] (b) => { clicked = true; });

		let args = scope KeyEventArgs();
		args.Set(.Return, .None, false);
		btn.OnKeyDown(args);
		Test.Assert(clicked);
	}

	[Test]
	public static void Button_IsFocusable()
	{
		let btn = scope Button("Test");
		Test.Assert(btn.IsFocusable);
		Test.Assert(btn.IsTabStop);
	}

	[Test]
	public static void Button_ControlState_Pressed()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let btn = new Button("Test");
		root.AddView(btn);

		let args = scope MouseEventArgs();
		args.Set(10, 10, .Left);
		btn.OnMouseDown(args);
		Test.Assert(btn.GetControlState().HasFlag(.Pressed));
	}

	// === Label ===

	[Test]
	public static void Label_SetText()
	{
		let label = scope Label("Hello");
		Test.Assert(label.Text.Value != null);
		Test.Assert(String.Equals(label.Text.Value, "Hello", .OrdinalIgnoreCase));
	}

	[Test]
	public static void Label_SetTextChaining()
	{
		let label = scope Label();
		label.SetText("World");
		Test.Assert(String.Equals(label.Text.Value, "World", .OrdinalIgnoreCase));
	}

	[Test]
	public static void Label_MeasuresNonZero()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let label = new Label("Hello");
		root.AddView(label);
		TestSetup.Layout(ctx, root);

		// Without font service, still measures to font size height
		Test.Assert(label.MeasuredSize.Y > 0);
	}

	// === CheckBox ===

	[Test]
	public static void CheckBox_Toggle()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let cb = new CheckBox("Option");
		root.AddView(cb);

		Test.Assert(!cb.IsChecked.Value);

		bool fired = false;
		bool newVal = false;
		cb.OnCheckedChanged.Add(new [&] (c, val) => { fired = true; newVal = val; });

		cb.IsChecked.Value = true;
		Test.Assert(fired);
		Test.Assert(newVal == true);
		Test.Assert(cb.IsChecked.Value);
	}

	[Test]
	public static void CheckBox_MouseToggle()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let cb = new CheckBox("Option");
		root.AddView(cb);

		let args = scope MouseEventArgs();
		args.Set(5, 5, .Left);
		cb.OnMouseDown(args);
		Test.Assert(cb.IsChecked.Value);

		let args2 = scope MouseEventArgs();
		args2.Set(5, 5, .Left);
		cb.OnMouseDown(args2);
		Test.Assert(!cb.IsChecked.Value);
	}

	[Test]
	public static void CheckBox_NoChangeNotifyOnSameValue()
	{
		let cb = scope CheckBox("Test", true);
		int fireCount = 0;
		cb.OnCheckedChanged.Add(new [&fireCount] (c, v) => { fireCount++; });

		cb.IsChecked.Value = true; // same value
		Test.Assert(fireCount == 0);
	}

	// === RadioButton + RadioGroup ===

	[Test]
	public static void RadioButton_CannotUncheckByClick()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let radio = new RadioButton("Option");
		radio.IsChecked.Value = true;
		root.AddView(radio);

		let args = scope MouseEventArgs();
		args.Set(5, 5, .Left);
		radio.OnMouseDown(args);
		Test.Assert(radio.IsChecked.Value); // still checked
	}

	[Test]
	public static void RadioGroup_MutualExclusion()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let group = new RadioGroup();
		let a = new RadioButton("A");
		let b = new RadioButton("B");
		let c = new RadioButton("C");
		group.AddRadioButton(a);
		group.AddRadioButton(b);
		group.AddRadioButton(c);
		root.AddView(group);

		group.CheckAt(0);
		Test.Assert(a.IsChecked.Value);
		Test.Assert(!b.IsChecked.Value);

		b.IsChecked.Value = true;
		Test.Assert(!a.IsChecked.Value);
		Test.Assert(b.IsChecked.Value);
		Test.Assert(!c.IsChecked.Value);
	}

	[Test]
	public static void RadioGroup_SelectionChangedEvent()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let group = new RadioGroup();
		let a = new RadioButton("A");
		let b = new RadioButton("B");
		group.AddRadioButton(a);
		group.AddRadioButton(b);
		root.AddView(group);

		RadioButton selected = null;
		group.OnSelectionChanged.Add(new [&selected] (g, r) => { selected = r; });

		a.IsChecked.Value = true;
		Test.Assert(selected === a);

		b.IsChecked.Value = true;
		Test.Assert(selected === b);
	}

	// === ToggleButton ===

	[Test]
	public static void ToggleButton_Toggle()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let toggle = new ToggleButton("Toggle");
		root.AddView(toggle);

		Test.Assert(!toggle.IsChecked.Value);

		bool fired = false;
		toggle.OnCheckedChanged.Add(new [&fired] (t, v) => { fired = true; });

		let args = scope KeyEventArgs();
		args.Set(.Space, .None, false);
		toggle.OnKeyDown(args);
		Test.Assert(toggle.IsChecked.Value);
		Test.Assert(fired);
	}

	// === ToggleSwitch ===

	[Test]
	public static void ToggleSwitch_Toggle()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let sw = new ToggleSwitch("VSync");
		root.AddView(sw);

		Test.Assert(!sw.IsChecked.Value);

		bool toggled = false;
		sw.OnCheckedChanged.Add(new [&toggled] (s, v) => { toggled = true; });

		let args = scope MouseEventArgs();
		args.Set(10, 10, .Left);
		sw.OnMouseDown(args);
		Test.Assert(sw.IsChecked.Value);
		Test.Assert(toggled);
	}

	// === Slider ===

	[Test]
	public static void Slider_ValueClamped()
	{
		let slider = scope Slider(0, 100, 50);
		Test.Assert(slider.Value.Value == 50);

		slider.Value.Value = -10;
		Test.Assert(slider.Value.Value == 0);

		slider.Value.Value = 200;
		Test.Assert(slider.Value.Value == 100);
	}

	[Test]
	public static void Slider_Step()
	{
		let slider = scope Slider(0, 100);
		slider.Step.Value = 10;
		slider.Value.Value = 33;
		Test.Assert(Math.Abs(slider.Value.Value - 30) < 0.01f); // snapped to nearest 10
	}

	[Test]
	public static void Slider_ValueChangedEvent()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let slider = new Slider(0, 100);
		root.AddView(slider);

		float lastVal = -1;
		slider.OnValueChanged.Add(new [&lastVal] (s, v) => { lastVal = v; });

		slider.Value.Value = 42;
		Test.Assert(lastVal == 42);
	}

	[Test]
	public static void Slider_KeyboardControl()
	{
		let slider = scope Slider(0, 100, 50);
		slider.Step.Value = 5;

		let args = scope KeyEventArgs();
		args.Set(.Right, .None, false);
		slider.OnKeyDown(args);
		Test.Assert(slider.Value.Value == 55);

		let args2 = scope KeyEventArgs();
		args2.Set(.Left, .None, false);
		slider.OnKeyDown(args2);
		Test.Assert(slider.Value.Value == 50);

		let args3 = scope KeyEventArgs();
		args3.Set(.Home, .None, false);
		slider.OnKeyDown(args3);
		Test.Assert(slider.Value.Value == 0);

		let args4 = scope KeyEventArgs();
		args4.Set(.End, .None, false);
		slider.OnKeyDown(args4);
		Test.Assert(slider.Value.Value == 100);
	}

	// === ProgressBar ===

	[Test]
	public static void ProgressBar_ValueClamped()
	{
		let bar = scope ProgressBar();
		bar.Value.Value = 0.5f;
		Test.Assert(bar.Value.Value == 0.5f);

		bar.Value.Value = -1;
		Test.Assert(bar.Value.Value == 0);

		bar.Value.Value = 2;
		Test.Assert(bar.Value.Value == 1);
	}

	// === Spacer ===

	[Test]
	public static void Spacer_MeasuresToDesiredSize()
	{
		let spacer = scope Spacer(20, 10);
		spacer.Measure(BoxConstraints.Expand());
		Test.Assert(spacer.MeasuredSize.X == 20);
		Test.Assert(spacer.MeasuredSize.Y == 10);
	}

	// === ColorView ===

	[Test]
	public static void ColorView_StoresColor()
	{
		let cv = scope ColorView(.(255, 0, 0, 255));
		Test.Assert(cv.Color.Value.R == 255 && cv.Color.Value.G == 0);
	}

	// === Separator ===

	[Test]
	public static void Separator_HorizontalMeasure()
	{
		let sep = scope Separator(.Horizontal);
		sep.Measure(BoxConstraints.Loose(400, 300));
		Test.Assert(sep.MeasuredSize.Y == 1); // thickness
		Test.Assert(sep.MeasuredSize.X == 400); // fills width
	}

	[Test]
	public static void Separator_VerticalMeasure()
	{
		let sep = scope Separator(.Vertical);
		sep.Measure(BoxConstraints.Loose(400, 300));
		Test.Assert(sep.MeasuredSize.X == 1);
		Test.Assert(sep.MeasuredSize.Y == 300);
	}

	// === Panel ===

	[Test]
	public static void Panel_ChildFillsContent()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let panel = new Panel();
		panel.Padding = .(10);
		let child = new TestView(50, 30);
		panel.AddView(child);
		root.AddView(panel);
		TestSetup.Layout(ctx, root);

		// Child should be positioned within padding
		Test.Assert(Math.Abs(child.Bounds.X - 10) < 0.01f);
		Test.Assert(Math.Abs(child.Bounds.Y - 10) < 0.01f);
	}

	// === Expander ===

	[Test]
	public static void Expander_DefaultExpanded()
	{
		let expander = scope Expander("Header");
		Test.Assert(expander.IsExpanded);
	}

	[Test]
	public static void Expander_Toggle()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let expander = new Expander("Settings");
		let content = new TestView(100, 50);
		expander.SetContent(content);
		root.AddView(expander);

		bool fired = false;
		expander.OnExpandedChanged.Add(new [&fired] (e, v) => { fired = true; });

		expander.IsExpanded = false;
		Test.Assert(!expander.IsExpanded);
		Test.Assert(fired);
		Test.Assert(content.Visibility == .Gone);

		expander.IsExpanded = true;
		Test.Assert(content.Visibility == .Visible);
	}

	[Test]
	public static void Expander_CollapsedMeasure()
	{
		let expander = scope Expander("Header");
		let content = new TestView(100, 50);
		expander.SetContent(content);

		// Measure with loose constraints so expander sizes to content
		expander.Measure(BoxConstraints.Loose(400, 300));
		let expandedH = expander.MeasuredSize.Y;

		expander.IsExpanded = false;
		expander.Measure(BoxConstraints.Loose(400, 300));
		let collapsedH = expander.MeasuredSize.Y;

		// Expanded: header + content, Collapsed: just header
		Test.Assert(collapsedH < expandedH);
		Test.Assert(Math.Abs(collapsedH - expander.HeaderHeight.Value) < 1.0f);
	}

	// === ImageView ===

	[Test]
	public static void ImageView_NullImage_ZeroSize()
	{
		let iv = scope ImageView();
		iv.Measure(BoxConstraints.Expand());
		Test.Assert(iv.MeasuredSize.X == 0);
		Test.Assert(iv.MeasuredSize.Y == 0);
	}

	// === RepeatButton ===

	[Test]
	public static void RepeatButton_ClicksOnce()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let btn = new RepeatButton("Hold");
		root.AddView(btn);

		int clickCount = 0;
		btn.OnClick.Add(new [&clickCount] (b) => { clickCount++; });

		let args = scope KeyEventArgs();
		args.Set(.Return, .None, false);
		btn.OnKeyDown(args);
		Test.Assert(clickCount == 1);
	}

	[Test]
	public static void RepeatButton_RepeatsOnHold()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let btn = new RepeatButton("Hold");
		btn.RepeatDelay = 0.1f;
		btn.RepeatInterval = 0.05f;
		root.AddView(btn);

		int clickCount = 0;
		btn.OnClick.Add(new [&clickCount] (b) => { clickCount++; });

		// Simulate mouse down
		let downArgs = scope MouseEventArgs();
		downArgs.Set(10, 10, .Left);
		btn.OnMouseDown(downArgs);

		// Before delay - no repeats
		btn.UpdateRepeat(0.05f);
		Test.Assert(clickCount == 0);

		// After delay - first repeat
		btn.UpdateRepeat(0.06f); // total 0.11 > 0.1
		Test.Assert(clickCount >= 1);

		// More time - more repeats
		let countBefore = clickCount;
		btn.UpdateRepeat(0.1f);
		Test.Assert(clickCount > countBefore);
	}

	[Test]
	public static void RepeatButton_StopsOnRelease()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let btn = new RepeatButton("Hold");
		btn.RepeatDelay = 0.05f;
		btn.RepeatInterval = 0.02f;
		root.AddView(btn);

		int clickCount = 0;
		btn.OnClick.Add(new [&clickCount] (b) => { clickCount++; });

		let downArgs = scope MouseEventArgs();
		downArgs.Set(10, 10, .Left);
		btn.OnMouseDown(downArgs);

		let upArgs = scope MouseEventArgs();
		upArgs.Set(10, 10, .Left);
		btn.OnMouseUp(upArgs);

		// After release, UpdateRepeat should not fire
		let countAfterRelease = clickCount;
		btn.UpdateRepeat(0.2f);
		Test.Assert(clickCount == countAfterRelease);
	}
}
