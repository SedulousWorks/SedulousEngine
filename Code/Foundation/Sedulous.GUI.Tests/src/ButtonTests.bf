using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// The button core: toggle, activation on the press, repeat on the GUI's clock, groups by a name
/// (per GUI) or a ButtonGroup, the arrows round a group, and the text, icon and indicator parts.
class ButtonTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	/// A root 400 by 300 whose children each keep their own size, held by the caller.
	private static SceneRoot NewRoot()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; }); // each at its own size
		return root;
	}

	/// A new `T` at `at`, `size`, the last child of `root`, held by the caller.
	private static T Place<T>(SceneRoot root, Float2 at, Float2 size) where T : UIWidget, new
	{
		let b = new T();
		b.Position = at;
		b.Size = size;
		root.AddChild(b);
		return b;
	}

	/// A new `T` at `at`, 80 by 30.
	private static T Place<T>(SceneRoot root, Float2 at) where T : UIWidget, new => Place<T>(root, at, .(80.0f, 30.0f));

	/// The pointer over `at`, then a press and its release there.
	private static void Click(EventDispatcher d, Float2 at)
	{
		d.InjectMouseMove(at);
		d.InjectMouseDown(at, .Left);
		d.InjectMouseUp(at, .Left);
	}

	[Test]
	public static void AToggleReportsTheUsersChangeNotCodes()
	{
		let root = NewRoot();
		defer root.ReleaseRef();
		let b = Place<Button>(root, .(0.0f, 0.0f));
		defer b.ReleaseRef();
		int32 toggled = 0;
		int32 changes = 0;
		bool last = false;
		b.SetOnToggled(new [&] (on) =>
			{
				++toggled;
				last = on;
			});
		b.AddEventListener(.Changed, new [&] (e) => { ++changes; });

		b.Checked = true; // not a toggle yet: no state to set
		Test.Assert(!b.Checked);

		b.IsToggle = true;
		Click(root.EventDispatcher, .(10.0f, 10.0f));
		Test.Assert(b.Checked);
		Test.Assert(toggled == 1);
		Test.Assert(last);
		Test.Assert(changes == 1);
		Test.Assert((b.WidgetStates & WidgetStateChecked) != 0);

		b.Checked = false; // code: reported to bindings only
		Test.Assert(!b.Checked);
		Test.Assert(toggled == 1);
		Test.Assert(changes == 1);
	}

	[Test]
	public static void ActingOnThePressActivatesOnceWithNoClickOnTheRelease()
	{
		let root = NewRoot();
		defer root.ReleaseRef();
		let b = Place<Button>(root, .(0.0f, 0.0f));
		defer b.ReleaseRef();
		b.ActionOnName = "press";
		Test.Assert(b.ActionOn == .Press);
		int32 clicks = 0;
		int32 heard = 0;
		b.SetOnClick(new [&] () => { ++clicks; });
		b.AddEventListener(.MouseClick, new [&] (e) => { ++heard; });
		let d = root.EventDispatcher;

		d.InjectMouseDown(.(10.0f, 10.0f), .Left);
		Test.Assert(clicks == 1);
		Test.Assert(heard == 1); // a listener hears the activation as a click
		d.InjectMouseUp(.(10.0f, 10.0f), .Left);
		Test.Assert(clicks == 1);
		Test.Assert(heard == 1);

		// The next ordinary press clicks as usual on another button.
		let other = Place<Button>(root, .(100.0f, 0.0f));
		defer other.ReleaseRef();
		int32 otherClicks = 0;
		other.SetOnClick(new [&] () => { ++otherClicks; });
		Click(d, .(110.0f, 10.0f));
		Test.Assert(otherClicks == 1);
	}

	[Test]
	public static void ARepeatButtonRepeatsAfterItsDelayWhileHeldAndOverIt()
	{
		let root = NewRoot();
		defer root.ReleaseRef();
		let b = Place<Button>(root, .(0.0f, 0.0f));
		defer b.ReleaseRef();
		b.Repeat = true;
		b.RepeatDelay = 0.5f;
		b.RepeatInterval = 0.1f;
		int32 clicks = 0;
		b.SetOnClick(new [&] () => { ++clicks; });
		let d = root.EventDispatcher;
		let gui = root.Context;

		d.InjectMouseMove(.(10.0f, 10.0f));
		d.InjectMouseDown(.(10.0f, 10.0f), .Left);
		Test.Assert(clicks == 1); // the press
		gui.Update(SceneFixtures.Seconds(0.4));
		Test.Assert(clicks == 1); // within the delay
		gui.Update(SceneFixtures.Seconds(0.15)); // 0.05 past the delay
		Test.Assert(clicks == 1);
		gui.Update(SceneFixtures.Seconds(0.1)); // 0.15 past: one interval
		Test.Assert(clicks == 2);

		// Off it, it pauses; back over it, it goes on.
		d.InjectMouseMove(.(300.0f, 200.0f));
		gui.Update(SceneFixtures.Seconds(0.5));
		Test.Assert(clicks == 2);
		d.InjectMouseMove(.(10.0f, 10.0f));
		gui.Update(SceneFixtures.Seconds(0.1));
		Test.Assert(clicks == 3);

		// Released: no second click from the release, and no more repeats.
		d.InjectMouseUp(.(10.0f, 10.0f), .Left);
		Test.Assert(clicks == 3);
		gui.Update(SceneFixtures.Seconds(1.0));
		Test.Assert(clicks == 3);
	}

	[Test]
	public static void RadiosOfOneNameAreAGroupWithinTheirGUIOnly()
	{
		let root = NewRoot();
		defer root.ReleaseRef();
		let low = Place<RadioButton>(root, .(0.0f, 0.0f));
		defer low.ReleaseRef();
		let mid = Place<RadioButton>(root, .(0.0f, 40.0f));
		defer mid.ReleaseRef();
		let high = Place<RadioButton>(root, .(0.0f, 80.0f));
		defer high.ReleaseRef();
		RadioButton[3] radios = .(low, mid, high);
		for (let r in radios)
			r.Name = "quality";
		// Another GUI's radio of the same name is another group.
		let otherRoot = NewRoot();
		defer otherRoot.ReleaseRef();
		let elsewhere = Place<RadioButton>(otherRoot, .(0.0f, 0.0f));
		defer elsewhere.ReleaseRef();
		elsewhere.Name = "quality";
		elsewhere.Checked = true;

		let group = scope List<ButtonBase>();
		mid.CollectGroup(group);
		Test.Assert(group.Count == 3);
		Test.Assert(group[0] == low);
		Test.Assert(group[2] == high);

		let d = root.EventDispatcher;
		Click(d, .(10.0f, 50.0f));
		Test.Assert(mid.Checked);
		Click(d, .(10.0f, 90.0f));
		Test.Assert(high.Checked);
		Test.Assert(!mid.Checked);
		Test.Assert(!low.Checked);
		Click(d, .(10.0f, 90.0f)); // a checked radio stays checked
		Test.Assert(high.Checked);
		Test.Assert(elsewhere.Checked);

		low.Checked = true; // code too keeps the group exclusive
		Test.Assert(!high.Checked);
	}

	[Test]
	public static void AButtonGroupMakesTogglesExclusiveAndMayAllowNone()
	{
		let root = NewRoot();
		defer root.ReleaseRef();
		let group = new ButtonGroup();
		defer group.ReleaseRef();
		let a = Place<Button>(root, .(0.0f, 0.0f));
		defer a.ReleaseRef();
		var b = Place<Button>(root, .(100.0f, 0.0f));
		defer { b?.ReleaseRef(); }
		ButtonBase changedTo = null;
		group.SetOnChanged(new [&] (button) => { changedTo = button; });
		Button[2] buttons = .(a, b);
		for (let x in buttons)
		{
			x.IsToggle = true;
			x.Group = group;
		}
		Test.Assert(group.Buttons.Length == 2);

		let d = root.EventDispatcher;
		Click(d, .(10.0f, 10.0f));
		Test.Assert(a.Checked);
		Test.Assert(changedTo == a);
		Click(d, .(110.0f, 10.0f));
		Test.Assert(b.Checked);
		Test.Assert(!a.Checked);
		Test.Assert(group.Checked == b);
		Click(d, .(110.0f, 10.0f)); // kept
		Test.Assert(b.Checked);

		group.AllowsNone = true;
		Click(d, .(110.0f, 10.0f));
		Test.Assert(!b.Checked);
		Test.Assert(group.Checked == null);

		// A button that goes leaves its group.
		b.RemoveFromParent();
		b.ReleaseRef();
		b = null;
		Test.Assert(group.Buttons.Length == 1);
	}

	[Test]
	public static void TheArrowsMoveRoundAnExclusiveGroupCheckingAsTheyGo()
	{
		let root = NewRoot();
		defer root.ReleaseRef();
		let r0 = Place<RadioButton>(root, .(0.0f, 0.0f));
		defer r0.ReleaseRef();
		let r1 = Place<RadioButton>(root, .(0.0f, 40.0f));
		defer r1.ReleaseRef();
		let r2 = Place<RadioButton>(root, .(0.0f, 80.0f));
		defer r2.ReleaseRef();
		RadioButton[3] radios = .(r0, r1, r2);
		for (let r in radios)
			r.Name = "g";
		int32 changes = 0;
		r1.AddEventListener(.Changed, new [&] (e) => { ++changes; });
		r1.Enabled = false;
		let d = root.EventDispatcher;

		r0.RequestFocus();
		d.InjectKeyDown((uint32)KeyCode.Down); // past the disabled one
		Test.Assert(r2.IsFocused);
		Test.Assert(r2.Checked);
		d.InjectKeyDown((uint32)KeyCode.Down); // round to the first
		Test.Assert(r0.IsFocused);
		Test.Assert(r0.Checked);
		Test.Assert(!r2.Checked);

		r1.Enabled = true;
		d.InjectKeyDown((uint32)KeyCode.Right);
		Test.Assert(r1.Checked);
		Test.Assert(changes == 1);
		d.InjectKeyDown((uint32)KeyCode.Up);
		Test.Assert(r0.Checked);

		// An ungrouped toggle leaves the arrows to navigation.
		let lone = Place<CheckBox>(root, .(200.0f, 0.0f));
		defer lone.ReleaseRef();
		lone.RequestFocus();
		d.InjectKeyDown((uint32)KeyCode.Down);
		Test.Assert(!lone.Checked);
	}

	[Test]
	public static void InRightToLeftLeftMovesOnThroughAnExclusiveGroupAndRightBack()
	{
		let root = NewRoot();
		defer root.ReleaseRef();
		root.SetLayoutDirection(.RightToLeft);
		let r0 = Place<RadioButton>(root, .(0.0f, 0.0f));
		defer r0.ReleaseRef();
		let r1 = Place<RadioButton>(root, .(0.0f, 40.0f));
		defer r1.ReleaseRef();
		r0.Name = "g";
		r1.Name = "g";
		let d = root.EventDispatcher;
		r0.RequestFocus();
		d.InjectKeyDown((uint32)KeyCode.Left);
		Test.Assert(r1.Checked);
		d.InjectKeyDown((uint32)KeyCode.Right);
		Test.Assert(r0.Checked);
	}

	[Test]
	public static void ItsTextAndIconArePartsAfterItsIndicatorInItsTextStyle()
	{
		let b = new Button();
		defer b.ReleaseRef();
		Test.Assert(b.TextPart == null);
		Test.Assert(b.ChildCount == 0);
		b.Text = "Save";
		Test.Assert(b.TextPart != null);
		Test.Assert(b.TextPart.Tag == "text");
		Test.Assert(b.Text == "Save");
		Test.Assert(!b.TextPart.HitTestVisible);

		let icon = new ImageDrawable(); // an icon: image content
		defer icon.ReleaseRef();
		b.SetIcon(icon);
		Test.Assert(b.IconPart != null);
		Test.Assert(b.GetChildAt(0) == b.IconPart);
		Test.Assert(b.GetChildAt(1) == b.TextPart);

		b.TextColor = Color.Green;
		Test.Assert(b.TextPart.TextColor == Color.Green);

		b.SetIcon(null);
		Test.Assert(b.IconPart == null);
		Test.Assert(b.ChildCount == 1);

		let check = new CheckBox();
		defer check.ReleaseRef();
		check.Text = "Music";
		Test.Assert(check.ChildCount == 2);
		Test.Assert(check.GetChildAt(0) == check.IndicatorPart);
		Test.Assert((check.IndicatorPart as UIWidget).Tag == "indicator");
		Test.Assert(check.GetChildAt(1) == check.TextPart);
	}

	[Test]
	public static void MarkupContentSitsInsideItAndItsSizeIsItsContents()
	{
		let root = NewRoot();
		defer root.ReleaseRef();
		let check = new CheckBox();
		defer check.ReleaseRef();
		root.AddChild(check);
		root.UpdateLayout();
		Test.Assert(Near(check.Size.X, 20.0f)); // the indicator alone
		Test.Assert(Near(check.Size.Y, 20.0f));

		let sw = new ToggleSwitch();
		defer sw.ReleaseRef();
		root.AddChild(sw);
		let extra = new Panel();
		defer extra.ReleaseRef();
		extra.Size = .(30.0f, 10.0f);
		sw.AddChild(extra);
		root.UpdateLayout();
		Test.Assert(Near(sw.Size.X, 36.0f + 6.0f + 30.0f)); // the track, the gap, the content
	}

	[Test]
	public static void ACommandsLabelFillsAButtonWithNoTextOfItsOwn()
	{
		let b = new Button();
		defer b.ReleaseRef();
		b.OnBoundCommandText("Play", "", "");
		Test.Assert(b.Text == "Play");
		b.OnBoundCommandText("Pause", "", "");
		Test.Assert(b.Text == "Pause");
		b.Text = "Mine";
		b.OnBoundCommandText("Stop", "", "");
		Test.Assert(b.Text == "Mine");
	}

	[Test]
	public static void ItsTextPartIsAlignedAsTheButtonIsCentredOnAButtonAtItsStartBesideAnIndicator()
	{
		let b = new Button();
		defer b.ReleaseRef();
		b.Text = "OK";
		Test.Assert(b.TextPart.TextAlignH == .Center);
		b.SetTextAlignment(.Right, .Middle);
		Test.Assert(b.TextPart.TextAlignH == .Right);

		let check = new CheckBox();
		defer check.ReleaseRef();
		check.Text = "Music";
		Test.Assert(check.TextPart.TextAlignH == .Start);
	}
}
