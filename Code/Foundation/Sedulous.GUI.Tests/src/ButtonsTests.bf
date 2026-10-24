using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// The buttons beyond the ported tests: each element type built by its tag through its GUI table
/// and its reflected properties set by a sheet's CSS names; the reflection's flags and access names
/// and each widget's role; a click from a press and a release inside it (none released outside);
/// activation by Return, Space and the pad's South; a toggle bound to a command following the
/// command's checked state, and greyed with it; a check box's three states and `:indeterminate`; a
/// ButtonGroup's radios and the arrows; a switch's knob moving to the end of its track; an
/// expander opened and closed by its header's keys, reporting each change.
class ButtonsTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	/// A new instance of `info`'s type made by its creator, held by the caller; null when it has
	/// none.
	private static Node Make(GuiTypeInfo info) => info.Create() as Node;

	/// A root 400 by 300 whose children each keep their own size, held by the caller.
	private static SceneRoot NewRoot()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		return root;
	}

	[Test]
	public static void EachButtonTypeIsMadeByItsCreatorUnderItsTypesNameTheirPartsHaveNone()
	{
		GuiTypeInfo[5] elements = .(Button.StaticGuiType, CheckBox.StaticGuiType, RadioButton.StaticGuiType,
			ToggleSwitch.StaticGuiType, Expander.StaticGuiType);
		String[5] tags = .("Button", "CheckBox", "RadioButton", "ToggleSwitch", "Expander");
		String[5] cssTags = .("button", "checkbox", "radio", "switch", "expander");
		for (int i = 0; i < elements.Count; i++)
		{
			let info = elements[i];
			Test.Assert(info.Tag == tags[i], scope $"{tags[i]}: tagged {info.Tag}");
			Test.Assert(info.CanCreate);
			let made = Make(info);
			Test.Assert(made != null);
			Test.Assert(made.GetType() == info.Type);
			Test.Assert(made.GuiType == info); // an instance answers for its own type
			Test.Assert((made as UIWidget).Tag == cssTags[i]); // what a sheet selects it by
			made.ReleaseRef();
		}
		// Reflected, but no element: markup builds none of them by a tag.
		Test.Assert(!ButtonBase.StaticGuiType.CanCreate);
		Test.Assert(!ButtonIndicator.StaticGuiType.CanCreate);
		Test.Assert(!ExpanderHeader.StaticGuiType.CanCreate);
		// Each answers for its own type, its base's table after it.
		Test.Assert(CheckBox.StaticGuiType.Is(ButtonBase.StaticGuiType));
		Test.Assert(ExpanderHeader.StaticGuiType.Is(ButtonBase.StaticGuiType));
		Test.Assert(ButtonIndicator.StaticGuiType.Is(UIWidget.StaticGuiType));
		Test.Assert(!Expander.StaticGuiType.Is(ButtonBase.StaticGuiType));
	}

	[Test]
	public static void TheReflectedPropertiesCarryTheirFlagsAndAccessNamesAndEachButtonItsRole()
	{
		let text = Button.StaticGuiType.Find("text");
		Test.Assert(text != null);
		Test.Assert(text.IsTranslatable);
		Test.Assert(text.Access == "name");
		Test.Assert(text.Css.IsEmpty); // markup's, not a sheet's
		let checkedProperty = CheckBox.StaticGuiType.FindCss("checked"); // through its base's table
		Test.Assert(checkedProperty != null);
		Test.Assert(checkedProperty.IsTwoWay);
		Test.Assert(!Button.StaticGuiType.FindCss("toggle").IsTwoWay);
		let open = Expander.StaticGuiType.FindCss("open");
		Test.Assert(open != null);
		Test.Assert(open.IsTwoWay);
		Test.Assert(open.Access == "expanded");
		Test.Assert(Expander.StaticGuiType.FindCss("title").Access == "name");
		Test.Assert(Expander.StaticGuiType.FindCss("animate").Name == "Animated");
		Test.Assert(Button.StaticGuiType.FindCss("action-on").Name == "ActionOnName");

		let button = new Button();
		defer button.ReleaseRef();
		Test.Assert(button.AccessRoleName == "button");
		let check = new CheckBox();
		defer check.ReleaseRef();
		Test.Assert(check.AccessRoleName == "checkbox");
		let radio = new RadioButton();
		defer radio.ReleaseRef();
		Test.Assert(radio.AccessRoleName == "radio");
		let toggle = new ToggleSwitch();
		defer toggle.ReleaseRef();
		Test.Assert(toggle.AccessRoleName == "switch");
		let expander = new Expander();
		defer expander.ReleaseRef();
		Test.Assert(expander.AccessRoleName == "group");
		Test.Assert(expander.Header.AccessRoleName == "button"); // its header is a button
	}

	[Test]
	public static void ASheetSetsEachButtonsReflectedPropertiesByTheirCSSNames()
	{
		let root = NewRoot();
		defer root.ReleaseRef();
		let button = Make(Button.StaticGuiType) as Button;
		defer button.ReleaseRef();
		let check = Make(CheckBox.StaticGuiType) as CheckBox;
		defer check.ReleaseRef();
		let radio = Make(RadioButton.StaticGuiType) as RadioButton;
		defer radio.ReleaseRef();
		let toggle = Make(ToggleSwitch.StaticGuiType) as ToggleSwitch;
		defer toggle.ReleaseRef();
		let expander = Make(Expander.StaticGuiType) as Expander;
		defer expander.ReleaseRef();
		Node[5] all = .(button, check, radio, toggle, expander);
		for (let node in all)
			root.AddChild(node);
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles,
			"button { toggle: true; action-on: press; repeat: true; repeat-delay: 0.25; repeat-interval: 0.05; name: tools; icon: pic.png; } " +
			"checkbox { indeterminate: true; } " +
			"radio { name: quality; checked: true; } " +
			"switch { checked: true; } " +
			"expander { title: More; name: faq; animate: true; open: true; }");
		styles.ApplyTree(root);

		Test.Assert(button.IsToggle);
		Test.Assert(button.ActionOn == .Press);
		Test.Assert(button.ActionOnName == "press");
		Test.Assert(button.Repeat);
		Test.Assert(Near(button.RepeatDelay, 0.25f));
		Test.Assert(Near(button.RepeatInterval, 0.05f));
		Test.Assert(button.Name == "tools");
		Test.Assert(button.Icon == "pic.png");
		Test.Assert(button.IconPart != null); // the icon is a part of its own
		Test.Assert(check.Indeterminate);
		Test.Assert(radio.Name == "quality");
		Test.Assert(radio.Checked);
		Test.Assert(toggle.Checked);
		Test.Assert(expander.Title == "More");
		Test.Assert(expander.Name == "faq");
		Test.Assert(expander.Animated);
		Test.Assert(expander.Open);
	}

	[Test]
	public static void AClickIsAPressAndAReleaseInsideItNoneWhenReleasedOutside()
	{
		let root = NewRoot();
		defer root.ReleaseRef();
		let b = new Button();
		defer b.ReleaseRef();
		b.Size = .(80.0f, 30.0f);
		root.AddChild(b);
		int clicks = 0;
		b.SetOnClick(new [&] () => { clicks++; });
		let d = root.EventDispatcher;
		d.InjectMouseDown(.(10.0f, 10.0f), .Left);
		Test.Assert(clicks == 0); // a release button: not on the press
		d.InjectMouseUp(.(70.0f, 20.0f), .Left); // released elsewhere inside it
		Test.Assert(clicks == 1);
		d.InjectMouseDown(.(10.0f, 10.0f), .Left);
		d.InjectMouseUp(.(200.0f, 200.0f), .Left); // released outside
		Test.Assert(clicks == 1);
		d.InjectMouseDown(.(10.0f, 10.0f), .Right); // not the primary button
		d.InjectMouseUp(.(10.0f, 10.0f), .Right);
		Test.Assert(clicks == 1);
	}

	[Test]
	public static void ReturnSpaceAndThePadsSouthActivateTheFocusedButton()
	{
		let root = NewRoot();
		defer root.ReleaseRef();
		let b = new Button();
		defer b.ReleaseRef();
		b.Size = .(80.0f, 30.0f);
		root.AddChild(b);
		int clicks = 0;
		b.SetOnClick(new [&] () => { clicks++; });
		let d = root.EventDispatcher;
		d.FocusNode = b;
		Test.Assert(d.InjectKeyDown((uint32)KeyCode.Return));
		Test.Assert(clicks == 1);
		d.InjectKeyDown((uint32)KeyCode.Space);
		Test.Assert(clicks == 2);
		d.InjectPadButton(.South);
		Test.Assert(clicks == 3);
		b.Enabled = false; // a disabled button takes none of them
		d.InjectKeyDown((uint32)KeyCode.Return);
		d.InjectPadButton(.South);
		Test.Assert(clicks == 3);
	}

	[Test]
	public static void AToggleBoundToACommandShowsTheCommandsCheckedStateAndIsGreyedWithIt()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let music = root.Context.DefineCommand("music");
		root.OnCommand("music", new (command) => { music.Checked = !music.Checked; });
		let area = new CheckBox();
		defer area.ReleaseRef();
		area.Size = .(20.0f, 20.0f);
		root.AddChild(area);
		area.Command = "music";
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(area.Enabled);
		Test.Assert(!area.Checked);

		Test.Assert(area.HandleActivate()); // the box asks the command; the handler toggles it
		Test.Assert(!area.Checked); // not by itself: the command decides
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(music.Checked);
		Test.Assert(area.Checked);

		music.Checked = false; // the command changed elsewhere: the box follows
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(!area.Checked);
		music.Enabled = false;
		root.Context.Update(SceneFixtures.Frame);
		Test.Assert(!area.Enabled);
	}

	[Test]
	public static void ACheckBoxIsCheckedUncheckedOrMixedAndASheetReadsEach()
	{
		let root = NewRoot();
		defer root.ReleaseRef();
		let area = new CheckBox();
		defer area.ReleaseRef();
		root.AddChild(area);
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, "checkbox:indeterminate { opacity: 0.5; } checkbox:checked { opacity: 0.25; }");
		styles.ApplyTree(root);
		Test.Assert(Near(area.Alpha, 1.0f));

		area.Indeterminate = true;
		Test.Assert(!area.Checked);
		Test.Assert(area.WidgetStates == WidgetStateIndeterminate);
		styles.ApplyTree(root);
		Test.Assert(Near(area.Alpha, 0.5f));

		area.Toggle(); // from the mixed state: checked, and settled
		Test.Assert(area.Checked);
		Test.Assert(!area.Indeterminate);
		Test.Assert(area.WidgetStates == WidgetStateChecked);
		styles.ApplyTree(root);
		Test.Assert(Near(area.Alpha, 0.25f));

		area.Indeterminate = true; // mixed over checked: checked stays, the mixed state shows
		Test.Assert(area.Checked);
		Test.Assert(area.WidgetStates == (WidgetStateChecked | WidgetStateIndeterminate));
		area.Checked = false; // a choice settles it
		Test.Assert(area.WidgetStates == WidgetStateNone);
	}

	[Test]
	public static void RadiosOfAButtonGroupAreExclusiveAndTheArrowsMoveRoundIt()
	{
		let root = NewRoot();
		defer root.ReleaseRef();
		let group = new ButtonGroup();
		defer group.ReleaseRef();
		RadioButton[3] radios = default;
		defer { for (let r in radios) r.ReleaseRef(); }
		for (int i = 0; i < 3; i++)
		{
			radios[i] = new RadioButton();
			radios[i].Position = .(0.0f, 40.0f * (float)i);
			radios[i].Size = .(80.0f, 30.0f);
			root.AddChild(radios[i]);
			radios[i].Group = group;
		}
		Test.Assert(group.RefCount == 4); // the test's and each radio's
		ButtonBase changedTo = null;
		group.SetOnChanged(new [&] (button) => { changedTo = button; });
		let d = root.EventDispatcher;
		SceneFixtures.Click(d, .(10.0f, 50.0f));
		Test.Assert(radios[1].Checked);
		Test.Assert(changedTo == radios[1]);
		Test.Assert(radios[1].IsCurrentInGroup); // a checked radio is its group's current member
		Test.Assert(!radios[0].IsCurrentInGroup);

		radios[1].RequestFocus();
		d.InjectKeyDown((uint32)KeyCode.Down);
		Test.Assert(radios[2].IsFocused);
		Test.Assert(radios[2].Checked);
		Test.Assert(!radios[1].Checked);
		Test.Assert(changedTo == radios[2]);
		d.InjectKeyDown((uint32)KeyCode.Down); // round to the first
		Test.Assert(radios[0].Checked);
		d.InjectKeyDown((uint32)KeyCode.Up);
		Test.Assert(radios[2].Checked);
		Test.Assert(group.Checked == radios[2]);

		radios[0].Checked = true; // code: exclusive, but not the user's change
		Test.Assert(!radios[2].Checked);
		Test.Assert(changedTo == radios[2]);
		radios[0].Group = null; // out of the group: alone again
		Test.Assert(group.Buttons.Length == 2);
		Test.Assert(group.RefCount == 3);
	}

	/// The leftmost x the vertices of `colour` reach when `node` draws.
	private static float LeftmostOf(Node node, Color colour)
	{
		let canvas = scope VGContext();
		let dc = scope DrawContext(canvas);
		node.Draw(dc);
		float left = float.MaxValue;
		for (let v in canvas.GetBatch().Vertices)
		{
			if ((Math.Abs(v.Color.R - colour.R) < 0.01f) && (Math.Abs(v.Color.G - colour.G) < 0.01f) &&
				(Math.Abs(v.Color.B - colour.B) < 0.01f))
				left = Math.Min(left, v.Position.X);
		}
		return left;
	}

	[Test]
	public static void ASwitchsKnobGoesToTheEndOfItsTrackWhenItIsOn()
	{
		let root = NewRoot();
		defer root.ReleaseRef();
		let toggle = new ToggleSwitch();
		defer toggle.ReleaseRef();
		let knob = Color(1.0f, 0.0f, 1.0f, 1.0f);
		toggle.SetKnobColor(knob);
		root.AddChild(toggle);
		root.UpdateLayout();
		let off = LeftmostOf(toggle, knob);
		Test.Assert(off < 10.0f); // at the track's start: its radius in, less the knob's
		SceneFixtures.Click(root.EventDispatcher, .(10.0f, 10.0f));
		Test.Assert(toggle.Checked);
		let on = LeftmostOf(toggle, knob);
		// The knob's centre moves from one end's radius to the other's: 36 - 2 * 10.
		Test.Assert(Math.Abs((on - off) - 16.0f) < 0.01f, scope $"moved {on - off}");
	}

	[Test]
	public static void AnExpandersHeaderOpensAndClosesItByItsKeysReportingEachChange()
	{
		let root = NewRoot();
		defer root.ReleaseRef();
		let e = new Expander();
		defer e.ReleaseRef();
		e.Title = "&More";
		root.AddChild(e);
		root.UpdateLayout();
		Test.Assert(e.Title == "More"); // the header's text, its access key taken out
		let told = scope List<bool>();
		e.SetOnToggled(new [&] (open) => { told.Add(open); });
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, "expander:checked { opacity: 0.5; }");
		styles.ApplyTree(root);
		Test.Assert(Near(e.Alpha, 1.0f));

		let d = root.EventDispatcher;
		Test.Assert(!e.Content.IsTreeVisible); // closed: its content is out of the layout
		e.Header.RequestFocus();
		d.InjectKeyDown((uint32)KeyCode.Space);
		Test.Assert(e.Open);
		Test.Assert(e.Content.IsTreeVisible);
		styles.ApplyTree(root);
		Test.Assert(Near(e.Alpha, 0.5f)); // `expander:checked` styles an open one
		d.InjectKeyDown((uint32)KeyCode.Return);
		Test.Assert(!e.Open);
		d.InjectPadButton(.South);
		Test.Assert(e.Open);
		e.Toggle(); // code's change reports too
		Test.Assert(!e.Open);
		Test.Assert(told.Count == 4);
		Test.Assert(told[0] && !told[1] && told[2] && !told[3]);
		Test.Assert(!e.Header.Checked); // the header is no toggle: the expander holds the state
	}

	/// A click on a mixed check box checks it, whatever it held before it was made mixed.
	[Test]
	public static void AClickOnAMixedCheckBoxChecksItEvenOneCheckedBeforeItWasMixed()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let check = new CheckBox();
		defer check.ReleaseRef();
		check.Size = .(20.0f, 20.0f);
		root.AddChild(check);
		check.Checked = true;
		check.Indeterminate = true;
		Test.Assert(check.HandleActivate());
		Test.Assert(check.Checked);
		Test.Assert(!check.Indeterminate);
	}
}
