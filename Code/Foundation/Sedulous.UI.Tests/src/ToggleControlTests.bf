using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The controls that carry a checked state: CheckBox, ToggleButton, ToggleSwitch, and the
/// radio pair where the exclusion lives in the group rather than the button.
class ToggleControlTests
{
	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root, 400, 300);
	}

	// ---- CheckBox -----------------------------------------------------------------------------

	/// Setting the property notifies with the new value.
	[Test]
	public static void CheckingACheckBoxNotifiesWithTheNewValue()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let checkBox = new CheckBox("Option");
		root.AddView(checkBox);
		Test.Assert(!checkBox.IsChecked.Value);

		var fired = false;
		var newValue = false;
		checkBox.OnCheckedChanged.Add(new [&fired, &newValue](c, val) =>
			{
				fired = true;
				newValue = val;
			});

		checkBox.IsChecked.Value = true;

		Test.Assert(fired);
		Test.Assert(newValue);
		Test.Assert(checkBox.IsChecked.Value);
	}

	/// Clicking flips it, and clicking again flips it back: a checkbox is the one control in
	/// this family that can be turned off by the same gesture that turned it on.
	[Test]
	public static void ClickingACheckBoxFlipsItBothWays()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let checkBox = new CheckBox("Option");
		root.AddView(checkBox);

		let first = scope MouseEventArgs();
		first.Set(5, 5, .Left);
		checkBox.OnMouseDown(first);
		Test.Assert(checkBox.IsChecked.Value);

		let second = scope MouseEventArgs();
		second.Set(5, 5, .Left);
		checkBox.OnMouseDown(second);
		Test.Assert(!checkBox.IsChecked.Value);
	}

	/// Writing the value it already holds notifies nobody.
	[Test]
	public static void SettingACheckBoxToTheValueItAlreadyHoldsIsSilent()
	{
		let checkBox = new CheckBox("Test", true);
		defer checkBox.ReleaseRef();

		var fires = 0;
		checkBox.OnCheckedChanged.Add(new [&fires](c, val) => { fires++; });

		checkBox.IsChecked.Value = true;

		Test.Assert(fires == 0);
	}

	/// OnActivate is the gamepad and accessibility entry, and toggles like a click.
	[Test]
	public static void ActivatingACheckBoxToggles()
	{
		let checkBox = new CheckBox("Test");
		defer checkBox.ReleaseRef();

		Test.Assert(!checkBox.IsChecked.Value);
		checkBox.OnActivate();
		Test.Assert(checkBox.IsChecked.Value);
		checkBox.OnActivate();
		Test.Assert(!checkBox.IsChecked.Value);
	}

	// ---- ToggleButton -------------------------------------------------------------------------

	[Test]
	public static void SpaceTogglesAToggleButtonAndNotifies()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let toggle = new ToggleButton("Toggle");
		root.AddView(toggle);
		Test.Assert(!toggle.IsChecked.Value);

		var fired = false;
		toggle.OnCheckedChanged.Add(new [&fired](t, val) => { fired = true; });

		let space = scope KeyEventArgs();
		space.Set(.Space, .None, false);
		toggle.OnKeyDown(space);

		Test.Assert(toggle.IsChecked.Value);
		Test.Assert(fired);
	}

	/// The checked state reaches GetControlState, which is where a theme reads it: a toggle
	/// that flips without reporting Checked would draw as if it were still off.
	[Test]
	public static void ACheckedToggleButtonReportsCheckedInItsControlState()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let toggle = new ToggleButton("Toggle");
		root.AddView(toggle);

		Test.Assert(!toggle.GetControlState().HasFlag(.Checked));
		toggle.IsChecked.Value = true;
		Test.Assert(toggle.GetControlState().HasFlag(.Checked));
	}

	/// A click toggles BEFORE OnClick fires, so a click handler reading IsChecked sees the
	/// value the click produced rather than the one it replaced.
	///
	/// Driven through the input manager rather than by calling the handlers directly, because
	/// a release only counts as a click while the pointer is still over the control, and
	/// nothing sets hover except the real dispatch.
	[Test]
	public static void AToggleButtonIsAlreadyCheckedWhenItsClickFires()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let toggle = new ToggleButton("Toggle");
		root.AddView(toggle);
		toggle.Bounds = .(0, 0, 100, 40);
		UITest.LayoutPass(context, root);

		var checkedAtClick = false;
		toggle.OnClick.Add(new [&checkedAtClick, &toggle](b) =>
			{
				checkedAtClick = toggle.IsChecked.Value;
			});

		let input = context.GetInputManager();
		input.ProcessMouseMove(5, 5);
		input.ProcessMouseDown(.Left, 5, 5, 0);
		input.ProcessMouseUp(.Left, 5, 5);

		Test.Assert(toggle.IsChecked.Value);
		Test.Assert(checkedAtClick, "the click saw the new value");
	}

	// ---- RadioButton --------------------------------------------------------------------------

	/// Clicking the one already selected does nothing: a radio button never unchecks itself,
	/// which is what makes a group always have a selection once it has one.
	[Test]
	public static void ClickingACheckedRadioButtonLeavesItChecked()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let radio = new RadioButton("Option");
		radio.IsChecked.Value = true;
		root.AddView(radio);

		let click = scope MouseEventArgs();
		click.Set(5, 5, .Left);
		radio.OnMouseDown(click);

		Test.Assert(radio.IsChecked.Value);
		Test.Assert(!click.Handled, "and the click is left for someone else");
	}

	[Test]
	public static void ActivatingARadioButtonSelectsIt()
	{
		let radio = new RadioButton("Test");
		defer radio.ReleaseRef();

		Test.Assert(!radio.IsChecked.Value);
		radio.OnActivate();
		Test.Assert(radio.IsChecked.Value);
	}

	// ---- RadioGroup ---------------------------------------------------------------------------

	/// Checking one unchecks the rest, whether the check came from the group or from the
	/// button itself.
	[Test]
	public static void ARadioGroupKeepsExactlyOneChecked()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

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
		Test.Assert(group.CheckedButton == a);

		b.IsChecked.Value = true;
		Test.Assert(!a.IsChecked.Value);
		Test.Assert(b.IsChecked.Value);
		Test.Assert(!c.IsChecked.Value);
		Test.Assert(group.CheckedButton == b);
	}

	[Test]
	public static void ARadioGroupReportsWhatWasSelected()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new RadioGroup();
		let a = new RadioButton("A");
		let b = new RadioButton("B");
		group.AddRadioButton(a);
		group.AddRadioButton(b);
		root.AddView(group);

		RadioButton selected = null;
		group.OnSelectionChanged.Add(new [&selected](g, r) => { selected = r; });

		a.IsChecked.Value = true;
		Test.Assert(selected == a);

		b.IsChecked.Value = true;
		Test.Assert(selected == b);
	}

	/// Clearing leaves nothing selected, and does not report a selection on the way out: the
	/// unchecks it performs are its own, not a new choice.
	[Test]
	public static void ClearingARadioGroupSelectsNothingAndReportsNothing()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let group = new RadioGroup();
		let a = new RadioButton("A");
		let b = new RadioButton("B");
		group.AddRadioButton(a);
		group.AddRadioButton(b);
		root.AddView(group);
		group.CheckAt(0);

		var selections = 0;
		group.OnSelectionChanged.Add(new [&selections](g, r) => { selections++; });

		group.ClearCheck();

		Test.Assert(!a.IsChecked.Value);
		Test.Assert(!b.IsChecked.Value);
		Test.Assert(group.CheckedButton == null);
		Test.Assert(selections == 0);
	}

	// ---- ToggleSwitch -------------------------------------------------------------------------

	[Test]
	public static void ClickingAToggleSwitchFlipsItAndNotifies()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let toggleSwitch = new ToggleSwitch("VSync");
		root.AddView(toggleSwitch);
		Test.Assert(!toggleSwitch.IsChecked.Value);

		var toggled = false;
		toggleSwitch.OnCheckedChanged.Add(new [&toggled](s, val) => { toggled = true; });

		let click = scope MouseEventArgs();
		click.Set(10, 10, .Left);
		toggleSwitch.OnMouseDown(click);

		Test.Assert(toggleSwitch.IsChecked.Value);
		Test.Assert(toggled);
	}

	[Test]
	public static void ActivatingAToggleSwitchFlipsIt()
	{
		let toggleSwitch = new ToggleSwitch("Test");
		defer toggleSwitch.ReleaseRef();

		Test.Assert(!toggleSwitch.IsChecked.Value);
		toggleSwitch.OnActivate();
		Test.Assert(toggleSwitch.IsChecked.Value);
	}

	// ---- No text ------------------------------------------------------------------------------

	/// Built without text, these measure their box and nothing else.
	///
	/// Raptor's String property default constructs to an empty string, so its text reads are
	/// unconditionally safe. A Beef reference defaults to null instead, and every one of these
	/// measures asks the text whether it is empty, so a text-less control walked straight into
	/// a null dereference. The properties now start on an owned empty string.
	[Test]
	public static void ControlsBuiltWithoutTextMeasureTheirBoxAlone()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let checkBox = new CheckBox();
		root.AddView(checkBox);
		checkBox.Measure(BoxConstraints.Loose(400, 300));
		Test.Assert(checkBox.MeasuredSize.X == 18, "the box, with no spacing for absent text");
		Test.Assert(checkBox.MeasuredSize.Y == 18);

		let radio = new RadioButton();
		root.AddView(radio);
		radio.Measure(BoxConstraints.Loose(400, 300));
		Test.Assert(radio.MeasuredSize.X == 18);
		Test.Assert(radio.MeasuredSize.Y == 18);
	}

	/// The knob travels to the far end, the same distance from it as it sat from the near one.
	[Test]
	public static void AToggleSwitchMeasuresItsTrackPlusItsLabel()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let bare = new ToggleSwitch();
		root.AddView(bare);
		bare.Measure(BoxConstraints.Loose(400, 300));

		// No label, no spacing: the track is the whole control.
		Test.Assert(bare.MeasuredSize.X == 44);
		Test.Assert(bare.MeasuredSize.Y == 24);
	}
}
