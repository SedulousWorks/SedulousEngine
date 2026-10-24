using System;
using System.Collections;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A GUI of buttons, each with an id, 40 by 20. The root and the buttons go with it.
class KeyBed
{
	public SceneRoot Root = SceneFixtures.NewScene() ~ _.ReleaseRef();
	public List<Button> Buttons = new .() ~ { for (let b in _) b.ReleaseRef(); delete _; };

	public EventDispatcher D => Root.EventDispatcher;

	/// A new button `id`, the last child of `parent` (the root when null); the bed holds it.
	public Button Add(StringView id, Node parent = null)
	{
		let b = new Button();
		b.Id = id;
		b.Size = .(40.0f, 20.0f);
		((parent != null) ? parent : Root).AddChild(b);
		Buttons.Add(b);
		return b;
	}

	public static StringView IdOf(Node n)
	{
		let w = n as UIWidget;
		return (w != null) ? w.Id : default;
	}

	/// The focused widget's id (empty: none, or not a widget).
	public StringView Focused => IdOf(D.FocusNode);

	public void Tab(bool back = false)
	{
		D.InjectKeyDown((uint32)KeyCode.Tab, back ? KeyModShift : 0);
	}
}

/// The keyboard: tab-index, focus groups (a tab strip's one stop), Tab captured by a widget, the
/// next key captured, access keys (a menu bar's) and type-ahead from text input (a combo box's); a
/// menu's moves rebound; a focused widget hidden gives the focus up.
class KeyboardTests
{
	[Test]
	public static void TabIndexOrdersTabPositiveFirstLowestFirstThenTreeOrderNegativeIsSkipped()
	{
		let bed = scope KeyBed();
		bed.Add("a").TabIndex = 2;
		bed.Add("b");
		bed.Add("c").TabIndex = 1;
		bed.Add("d").TabIndex = -1;
		bed.Add("e");
		let stops = scope List<Node>();
		bed.D.TabStops(stops);
		Test.Assert(stops.Count == 4);
		Test.Assert(KeyBed.IdOf(stops[0]) == "c");
		Test.Assert(KeyBed.IdOf(stops[1]) == "a");
		Test.Assert(KeyBed.IdOf(stops[2]) == "b");
		Test.Assert(KeyBed.IdOf(stops[3]) == "e");
		bed.Tab();
		Test.Assert(bed.Focused == "c");
		bed.Tab();
		Test.Assert(bed.Focused == "a");
		bed.Tab(true);
		Test.Assert(bed.Focused == "c");
		// Skipped by Tab, but still focusable another way; Tab from there goes on in the order.
		bed.D.FocusNode = bed.Buttons[3];
		Test.Assert(bed.Focused == "d");
		bed.Tab();
		Test.Assert(bed.Focused == "c"); // not among the stops: Tab starts over
	}

	[Test]
	public static void AFocusGroupIsOneTabStopItsCheckedMemberFirstThenTheOneFocusedLastArrowsWrapInside()
	{
		let bed = scope KeyBed();
		bed.Add("x").Position = .(0.0f, 0.0f);
		let group = new Panel();
		defer group.ReleaseRef();
		group.FocusGroup = true;
		group.Position = .(0.0f, 40.0f);
		group.Size = .(200.0f, 20.0f);
		bed.Root.AddChild(group);
		String[3] ids = .("r0", "r1", "r2");
		RadioButton[3] radios = default;
		defer { for (let r in radios) r.ReleaseRef(); }
		for (int i = 0; i < 3; ++i)
		{
			radios[i] = new RadioButton();
			radios[i].Id = ids[i];
			radios[i].Position = .(60.0f * (float)i, 0.0f);
			radios[i].Size = .(50.0f, 20.0f);
			group.AddChild(radios[i]);
		}
		radios[1].Checked = true;
		bed.Add("y").Position = .(0.0f, 80.0f);

		let stops = scope List<Node>();
		bed.D.TabStops(stops);
		Test.Assert(stops.Count == 3);
		bed.Tab();
		Test.Assert(bed.Focused == "x");
		bed.Tab();
		Test.Assert(bed.Focused == "r1"); // the checked one
		bed.D.InjectKeyDown((uint32)KeyCode.Right, 0);
		Test.Assert(bed.Focused == "r2");
		bed.D.InjectKeyDown((uint32)KeyCode.Right, 0);
		Test.Assert(bed.Focused == "r0"); // wrapped inside the group
		bed.Tab();
		Test.Assert(bed.Focused == "y"); // out of the group in one step
		bed.Tab(true);
		Test.Assert(bed.Focused == "r0"); // back to the one focused there last
	}

	[Test]
	public static void ABindingWhoseCommandNothingOnTheFocusPathHandlesLetsTheKeyGoOn()
	{
		let bed = scope KeyBed();
		bed.Add("a").Position = .(0.0f, 0.0f);
		bed.Add("b").Position = .(0.0f, 40.0f);
		Test.Assert(bed.Root.Context.Keymap.Bind("down", "nobody.handles"));
		bed.D.FocusNode = bed.Buttons[0];
		bed.D.InjectKeyDown((uint32)KeyCode.Down, 0);
		Test.Assert(bed.Focused == "b"); // navigation had it
	}

	[Test]
	public static void AFocusedWidgetHiddenGivesUpTheFocusReturnDoesNotPressItTheScopesCommandsRun()
	{
		let bed = scope KeyBed();
		let screen = new Panel();
		defer screen.ReleaseRef();
		bed.Root.AddChild(screen);
		let back = bed.Add("back", screen);
		int pressed = 0;
		back.SetOnClick(new [&] () => { pressed++; });
		int ran = 0;
		bed.Root.Context.DefineCommand("test.back");
		Test.Assert(bed.Root.Context.Keymap.Bind("escape", "test.back"));
		bed.Root.OnCommand("test.back", new [&] (command) => { ran++; });
		back.RequestFocus();
		Test.Assert(bed.Focused == "back");

		screen.Displayed = false; // the screen hides with its button focused
		bed.D.InjectKeyDown((uint32)KeyCode.Return);
		Test.Assert(pressed == 0);
		Test.Assert(bed.D.FocusNode == null);
		bed.D.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(ran == 1);

		// Hidden by `visibility` too, and found out by the tick as well as by a key.
		screen.Displayed = true;
		back.RequestFocus();
		Test.Assert(bed.Focused == "back");
		back.Visible = false;
		bed.D.Tick(0.016f);
		Test.Assert(bed.D.FocusNode == null);
	}

	[Test]
	public static void AltAndAButtonsAccessKeyFocusAndPressItItsLetterIsUnderlinedWhileAltIsHeld()
	{
		let bed = scope KeyBed();
		let other = bed.Add("other");
		let apply = bed.Add("apply");
		apply.Text = "&Apply";
		other.Text = "Other";
		int clicks = 0;
		apply.SetOnClick(new [&] () => { clicks++; });
		Test.Assert(apply.Text == "Apply");
		Test.Assert(apply.Mnemonic == 'a');
		bed.D.FocusNode = other;
		bed.D.InjectKeyDown((uint32)KeyCode.A, KeyModAlt);
		Test.Assert(clicks == 1);
		Test.Assert(bed.Focused == "apply");
		bed.D.InjectKeyDown((uint32)KeyCode.Q, KeyModAlt); // nothing marked Q
		Test.Assert(clicks == 1);

		Test.Assert(apply.TextPart != null);
		Test.Assert(!bed.D.AreMnemonicsShown);
		bed.D.InjectKeyDown((uint32)KeyCode.LeftAlt, KeyModAlt);
		Test.Assert(bed.D.AreMnemonicsShown);
		bed.D.InjectKeyUp((uint32)KeyCode.LeftAlt, 0);
		Test.Assert(!bed.D.AreMnemonicsShown);
		bed.D.MnemonicsAlwaysShown = true;
		Test.Assert(bed.D.AreMnemonicsShown);
	}

	[Test]
	public static void EscapeCancelsACaptureUnlessTheCallerTakesIt()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let d = root.EventDispatcher;
		let taken = scope List<Keystroke>();
		int cancels = 0;
		d.CaptureNextKey(new [&] (stroke) => { taken.Add(stroke); }, new [&] () => { cancels++; });
		d.InjectKeyDown((uint32)KeyCode.Escape, 0);
		Test.Assert(cancels == 1);
		Test.Assert(taken.IsEmpty);
		Test.Assert(!d.IsCapturingKey);
		d.CaptureNextKey(new [&] (stroke) => { taken.Add(stroke); }, new [&] () => { cancels++; }, true);
		d.InjectKeyDown((uint32)KeyCode.Escape, 0);
		Test.Assert(taken.Count == 1);
		Test.Assert(taken[0].Code == (uint32)KeyCode.Escape);
		Test.Assert(cancels == 1);
		// A second capture replaces a waiting one, which is cancelled.
		d.CaptureNextKey(new [&] (stroke) => { taken.Add(stroke); }, new [&] () => { cancels++; });
		d.CaptureNextKey(new [&] (stroke) => { taken.Add(stroke); });
		Test.Assert(cancels == 2);
	}

	[Test]
	public static void AnAmpersandMarksAnAccessKeyAndADoubledOneIsAnAmpersand()
	{
		let m = scope Mnemonic();
		ParseMnemonic("&File", m);
		Test.Assert(m.Shown == "File");
		Test.Assert(m.Key == 'f');
		Test.Assert(m.Start == 0);
		Test.Assert(m.End == 1);
		ParseMnemonic("E&xit", m);
		Test.Assert(m.Shown == "Exit");
		Test.Assert(m.Key == 'x');
		Test.Assert(m.Start == 1);
		ParseMnemonic("Save && Quit", m);
		Test.Assert(m.Shown == "Save & Quit");
		Test.Assert(m.Key == (char32)0);
	}

	[Test]
	public static void TypeAheadMatchesLettersInEitherCaseInLatinGreekAndCyrillic()
	{
		Test.Assert(StartsWithIgnoringCase("Banana", "ba"));
		Test.Assert(StartsWithIgnoringCase("Éclair", "é")); // É, é
		Test.Assert(StartsWithIgnoringCase("Łódź", "ł")); // Ł, ł
		Test.Assert(StartsWithIgnoringCase("Δέλτα", "δ")); // Δ, δ
		Test.Assert(StartsWithIgnoringCase("Груша", "гр")); // Гр, гр
		Test.Assert(StartsWithIgnoringCase("Ёлка", "ё")); // Ё, ё
		Test.Assert(!StartsWithIgnoringCase("Apple", "b"));
		Test.Assert(!StartsWithIgnoringCase("A", "ab"));
	}

	[Test]
	public static void ATabStripIsAFocusGroupOneStopTheSelectedTab()
	{
		let bed = scope KeyBed();
		bed.Add("before");
		let bar = new TabBar();
		defer bar.ReleaseRef();
		bed.Root.AddChild(bar);
		bar.InsertTab(0, "One");
		bar.InsertTab(1, "Two");
		bar.InsertTab(2, "Three");
		bar.SelectedIndex = 2;
		let stops = scope List<Node>();
		bed.D.TabStops(stops);
		Test.Assert(stops.Count == 2);
		Test.Assert(stops[1].IsCurrentInGroup); // the selected tab
	}

	[Test]
	public static void AMenusMovesAreBindingsInTheMenuKeyContextReboundLikeAnyKey()
	{
		let bed = scope KeyBed();
		bed.Root.Size = .(600.0f, 400.0f);
		let bar = new MenuBar();
		defer bar.ReleaseRef();
		bed.Root.AddChild(bar);
		let file = bar.AddMenu("File");
		file.AddItem("Open", new () => { });
		file.AddItem("Save", new () => { });
		let edit = bar.AddMenu("Edit");
		edit.AddItem("Undo", new () => { });
		bed.Root.UpdateLayout();
		let keys = bed.Root.Context.Keymap;
		String[4] wasd = .("w", "s", "a", "d");
		String[4] moves = .("menu.up", "menu.down", "menu.left", "menu.right");
		for (int i = 0; i < 4; ++i)
			Test.Assert(keys.Bind(wasd[i], moves[i], cMenuKeyContext));

		StringView Item()
		{
			let it = bed.D.FocusNode as MenuItem;
			return (it != null) ? it.Text : default;
		}
		bar.ButtonAt(0).RequestFocus();
		bed.D.InjectKeyDown((uint32)KeyCode.S, 0); // opens File
		Test.Assert(file.IsOpen);
		Test.Assert(Item() == "Open");
		bed.D.InjectKeyDown((uint32)KeyCode.S, 0);
		Test.Assert(Item() == "Save");
		bed.D.InjectKeyDown((uint32)KeyCode.D, 0); // along the bar
		Test.Assert(edit.IsOpen);
		Test.Assert(Item() == "Undo");
		bed.D.InjectKeyDown((uint32)KeyCode.A, 0);
		Test.Assert(file.IsOpen);
	}

	[Test]
	public static void AltAndAKeyOpenAMenuBarsMenuAndRunAnItemOfTheOpenMenu()
	{
		let bed = scope KeyBed();
		bed.Root.Size = .(600.0f, 400.0f);
		let bar = new MenuBar();
		defer bar.ReleaseRef();
		bed.Root.AddChild(bar);
		int opened = 0;
		let file = bar.AddMenu("&File");
		file.AddItem("&Open", new [&] () => { ++opened; });
		file.AddItem("E&xit", new () => { });
		bar.AddMenu("&Edit");
		bed.Root.UpdateLayout();
		bed.D.InjectKeyDown((uint32)KeyCode.F, KeyModAlt);
		Test.Assert(file.IsOpen);
		bed.D.InjectKeyDown((uint32)KeyCode.O, KeyModAlt);
		Test.Assert(opened == 1);
		Test.Assert(!file.IsOpen);
	}

	[Test]
	public static void TypeAheadReadsTypedTextSoItFollowsTheLayoutAndAnIMEACyrillicListTypesAhead()
	{
		let bed = scope KeyBed();
		let combo = new ComboBox();
		defer combo.ReleaseRef();
		combo.Size = .(140.0f, 26.0f);
		combo.ItemsText = "Яблоко|Груша|Арбуз";
		combo.SelectedIndex = 0;
		bed.Root.AddChild(combo);
		combo.RequestFocus();
		Test.Assert(bed.D.WantsTextInput); // it asks for typed text
		// A Russian layout's key types a Cyrillic letter; its key code is a Latin letter's.
		bed.D.InjectKeyDown((uint32)KeyCode.U, 0);
		bed.D.InjectText("г");
		Test.Assert(combo.SelectedIndex == 1);
		// A binding of a bare letter does not take it from under the type-ahead.
		int ran = 0;
		bed.Root.OnCommand("jump", new [&] (command) => { ++ran; });
		Test.Assert(bed.Root.Context.Keymap.Bind("f", "jump"));
		bed.D.InjectKeyDown((uint32)KeyCode.F, 0);
		bed.D.InjectText("а");
		Test.Assert(ran == 0);
		Test.Assert(combo.SelectedIndex == 2);
	}

	[Test]
	public static void AWidgetThatCapturesTabTakesTabAndShiftTabAsKeysCtrlTabMovesFocusFromIt()
	{
		let bed = scope KeyBed();
		bed.Add("a");
		let editor = new TextArea();
		defer editor.ReleaseRef();
		editor.Id = "editor";
		editor.Size = .(200.0f, 80.0f);
		editor.TabCaptures = true;
		bed.Root.AddChild(editor);
		bed.Add("b");
		bed.D.FocusNode = editor;
		bed.Tab();
		Test.Assert(bed.Focused == "editor");
		Test.Assert(editor.Text == "\t"); // it typed a tab
		bed.Tab(true);
		Test.Assert(bed.Focused == "editor"); // its key, though it does nothing with it
		bed.D.InjectKeyDown((uint32)KeyCode.Tab, KeyModCtrl);
		Test.Assert(bed.Focused == "b");
		bed.D.FocusNode = editor;
		bed.D.InjectKeyDown((uint32)KeyCode.Tab, KeyModCtrl | KeyModShift);
		Test.Assert(bed.Focused == "a");
		// Without it, Tab moves on as ever.
		editor.TabCaptures = false;
		bed.D.FocusNode = editor;
		bed.Tab();
		Test.Assert(bed.Focused == "b");
		Test.Assert(editor.Text == "\t");
	}

	[Test]
	public static void CaptureNextKeyTakesTheNextKeyBeforeBindingsAndWidgetsWithItsModifiersAndDropsItsText()
	{
		let bed = scope KeyBed();
		let field = new TextField();
		defer field.ReleaseRef();
		field.Size = .(200.0f, 24.0f);
		bed.Root.AddChild(field);
		bed.D.FocusNode = field;
		int quits = 0;
		bed.Root.OnCommand("quit", new [&] (command) => { ++quits; });
		Test.Assert(bed.Root.Context.Keymap.Bind("ctrl-q", "quit"));

		let taken = scope List<Keystroke>();
		int cancels = 0;
		bed.D.CaptureNextKey(new [&] (stroke) => { taken.Add(stroke); }, new [&] () => { ++cancels; });
		Test.Assert(bed.D.IsCapturingKey);
		bed.D.InjectKeyDown((uint32)KeyCode.LeftCtrl, KeyModCtrl); // waits: maybe Ctrl and something
		Test.Assert(taken.IsEmpty);
		bed.D.InjectKeyDown((uint32)KeyCode.Q, KeyModCtrl);
		Test.Assert(taken.Count == 1);
		Test.Assert(taken[0] == ParseKeystroke("ctrl-q").Value);
		Test.Assert(quits == 0); // the binding never saw it
		Test.Assert(!bed.D.IsCapturingKey);

		// A plain key's text is dropped; the field gets nothing.
		bed.D.CaptureNextKey(new [&] (stroke) => { taken.Add(stroke); });
		bed.D.InjectKeyDown((uint32)KeyCode.W, 0);
		bed.D.InjectText("w");
		Test.Assert(taken.Count == 2);
		Test.Assert(field.Text.IsEmpty);
		bed.D.InjectKeyDown((uint32)KeyCode.E, 0); // the capture over: as ever
		bed.D.InjectText("e");
		Test.Assert(field.Text == "e");

		// A modifier alone, taken as it is released.
		bed.D.CaptureNextKey(new [&] (stroke) => { taken.Add(stroke); });
		bed.D.InjectKeyDown((uint32)KeyCode.LeftShift, KeyModShift);
		bed.D.InjectKeyUp((uint32)KeyCode.LeftShift, 0);
		Test.Assert(taken.Count == 3);
		Test.Assert(taken[2] == ParseKeystroke("leftshift").Value);

		// A pad button.
		bed.D.CaptureNextKey(new [&] (stroke) => { taken.Add(stroke); });
		bed.D.InjectPadButton(.North);
		Test.Assert(taken.Count == 4);
		Test.Assert(taken[3] == ParseKeystroke("pad-north").Value);
		Test.Assert(cancels == 0);
	}

	[Test]
	public static void TabIndexComesFromASheetAndFromMarkup()
	{
		let bed = scope KeyBed();
		let a = bed.Add("a");
		let b = bed.Add("b");
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, "#a { tab-index: -1; } #b { tab-index: 3; }");
		styles.ApplyTree(bed.Root);
		Test.Assert(a.TabIndex == -1);
		Test.Assert(b.TabIndex == 3);

		let tree = MarkupFixtures.Load("<Panel><Button id=\"x\" tab-index=\"5\"/></Panel>");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();
		Test.Assert(tree.ChildCount == 1);
		Test.Assert(tree.GetChildAt(0).TabIndex == 5);
	}
}
