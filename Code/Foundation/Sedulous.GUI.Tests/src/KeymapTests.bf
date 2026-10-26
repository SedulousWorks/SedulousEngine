using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using internal Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A screen in the key context "menu mode=main" holding a focused button, and the commands that
/// ran, by id. The root and the tree go with it.
class KeymapBed
{
	public SceneRoot Root = SceneFixtures.NewScene() ~ _.ReleaseRef();
	public UIWidget Screen = new .() ~ _.ReleaseRef();
	public Button Item = new .() ~ _.ReleaseRef();
	public List<String> Ran = new .() ~ DeleteContainerAndItems!(_);

	public this()
	{
		Root.AddChild(Screen);
		Screen.AddChild(Item);
		Screen.KeyContext = "menu mode=main";
		Item.TabFocusable = true;
		Item.Size = .(40.0f, 20.0f);
		Root.EventDispatcher.FocusNode = Item;
	}

	/// The root handles `id`, noting each run.
	public void Handle(String id)
	{
		Root.OnCommand(id, new (command) => { Ran.Add(new String(id)); });
	}

	public void Key(KeyCode key, uint32 mods = 0)
	{
		Root.EventDispatcher.InjectKeyDown((uint32)key, mods);
	}
}

/// Bindings: keystrokes and gamepad buttons bound to commands, scoped by context predicates over
/// the focus path (the deepest match winning, then the later binding), unbinding, chords, and the
/// order keys take (the widget, then bindings, then navigation; a text field keeping its own);
/// `>` for a context inside another; keystrokes and gamepad buttons parsed and named, and a
/// command's keys as a menu shows them (a text field's context menu among them).
class KeymapTests
{
	private static bool ShortcutIs(Keymap keymap, StringView command, StringView expected)
	{
		let text = scope String();
		keymap.ShortcutText(command, text);
		return text == expected;
	}

	private static bool StrokeTextIs(StringView keys, StringView expected)
	{
		let text = scope String();
		KeystrokeText(ParseKeystroke(keys).Value, text);
		return text == expected;
	}

	[Test]
	public static void KeystrokesChordsAndPredicatesParse()
	{
		let s = ParseKeystroke("ctrl-shift-a");
		Test.Assert(s.HasValue);
		Test.Assert(s.Value.Code == (uint32)KeyCode.A);
		Test.Assert(s.Value.Modifiers == (KeyModCtrl | KeyModShift));
		Test.Assert(ParseKeystroke("pad-east").Value.Pad);
		Test.Assert(!ParseKeystroke("hyper-a").HasValue);
		Test.Assert(!ParseKeystroke("pad-turbo").HasValue);

		let p = scope ContextPredicate();
		Test.Assert(p.Parse("menu && (mode == main || !modal)"));
		let layer = scope KeyContextLayer();
		layer.Declare("menu mode=main");
		Test.Assert(p.Eval(layer));
		layer.Declare("mode=settings modal");
		Test.Assert(!p.Eval(layer));
		Test.Assert(!p.Parse("menu &&"));
		Test.Assert(!p.Eval(layer)); // malformed matches nothing
		let keymap = scope Keymap();
		Test.Assert(!keymap.Bind("ctrl-nonesuch", "x"));
		Test.Assert(!keymap.Bind("escape", "x", "(menu"));
	}

	[Test]
	public static void ACommandsKeysAsTextTheLatestBindingsFollowingARebinding()
	{
		let keymap = scope Keymap();
		Test.Assert(ShortcutIs(keymap, "save", ""));
		Test.Assert(keymap.Bind("ctrl-s", "save"));
		Test.Assert(ShortcutIs(keymap, "save", "Ctrl+S"));
		Test.Assert(keymap.Bind("ctrl-k ctrl-shift-s", "save"));
		Test.Assert(ShortcutIs(keymap, "save", "Ctrl+K Ctrl+Shift+S"));
		Test.Assert(keymap.Bind("f12", "shot"));
		Test.Assert(ShortcutIs(keymap, "shot", "F12"));
		Test.Assert(keymap.Bind("pad-east", "back"));
		Test.Assert(ShortcutIs(keymap, "back", "Pad East"));
		Test.Assert(StrokeTextIs("alt-enter", "Alt+Enter"));
	}

	[Test]
	public static void TheWholeKeyboardHasNamesTheKeypadApartFromTheDigitsEachShownAsAMenuWritesIt()
	{
		Test.Assert(ParseKeystroke("numpad5").Value.Code == (uint32)KeyCode.Keypad5);
		Test.Assert(ParseKeystroke("5").Value.Code == (uint32)KeyCode.Num5);
		Test.Assert(ParseKeystroke("f24").Value.Code == (uint32)KeyCode.F24);
		Test.Assert(ParseKeystroke("f13").Value.Code == (uint32)KeyCode.F13);
		Test.Assert(!ParseKeystroke("f25").HasValue);
		Test.Assert(ParseKeystroke("ctrl-slash").Value.Code == (uint32)KeyCode.Slash);
		Test.Assert(StrokeTextIs("ctrl-minus", "Ctrl+-"));
		Test.Assert(StrokeTextIs("numpadenter", "Numpad Enter"));
		Test.Assert(StrokeTextIs("f17", "F17"));
		Test.Assert(StrokeTextIs("backslash", "\\"));
		// Every named key reads back from its own name.
		for (int i = 0; i < KeymapDetail.sKeyNames.Count; i++)
		{
			let key = KeymapDetail.sKeyNames[i];
			let stroke = ParseKeystroke(key.Name);
			Test.Assert(stroke.HasValue, scope $"{key.Name} does not parse");
			Test.Assert(stroke.Value.Code == (uint32)key.Code, scope $"{key.Name} reads as {stroke.Value.Code}");
		}
	}

	[Test]
	public static void AKeystrokesNameReadsBackAsTheSameKeystroke()
	{
		StringView[11] names = .("ctrl-shift-s", "numpad5", "pad-north", "f24", "alt-f4", "leftshift",
			"ctrl-minus", "enter", "super-space", "7", "grave");
		for (int i = 0; i < names.Count; i++)
		{
			let name = names[i];
			let stroke = ParseKeystroke(name);
			Test.Assert(stroke.HasValue, scope $"{name} does not parse");
			let written = scope String();
			KeystrokeName(stroke.Value, written);
			Test.Assert(written == name, scope $"{name} is written {written}");
			Test.Assert(ParseKeystroke(written).Value == stroke.Value);
		}
		let unknown = scope String();
		KeystrokeName(Keystroke((uint32)KeyCode.Unknown, 0, false), unknown);
		Test.Assert(unknown.IsEmpty);
	}

	[Test]
	public static void TheDeepestMatchingContextWinsThenTheLaterBinding()
	{
		let bed = scope KeymapBed();
		bed.Handle("quit");
		bed.Handle("back");
		bed.Handle("close");
		let keys = bed.Root.Context.Keymap;
		Test.Assert(keys.Bind("escape", "quit")); // everywhere
		Test.Assert(keys.Bind("escape", "back", "menu")); // in the menu: deeper
		bed.Key(.Escape);
		Test.Assert(bed.Ran.Count == 1);
		Test.Assert(bed.Ran[0] == "back");

		Test.Assert(keys.Bind("escape", "close", "mode == main")); // as deep, later: wins
		bed.Key(.Escape);
		Test.Assert(bed.Ran[1] == "close");

		// Focus outside the menu: only the context-free binding holds.
		let outside = new Button();
		defer outside.ReleaseRef();
		outside.TabFocusable = true;
		bed.Root.AddChild(outside);
		bed.Root.EventDispatcher.FocusNode = outside;
		bed.Key(.Escape);
		Test.Assert(bed.Ran[2] == "quit");
	}

	[Test]
	public static void AnOuterNodesContextDoesNotOutrankTheFocusedOnes()
	{
		// The game screen declares "game"; the menu inside it declares "menu". Escape pauses in the
		// game and closes in the menu, whichever was bound later.
		let bed = scope KeymapBed();
		bed.Handle("pause");
		bed.Handle("close");
		let game = new UIWidget();
		defer game.ReleaseRef();
		bed.Root.RemoveChild(bed.Screen);
		bed.Root.AddChild(game);
		game.AddChild(bed.Screen);
		game.KeyContext = "game";
		bed.Root.EventDispatcher.FocusNode = bed.Item;
		let keys = bed.Root.Context.Keymap;
		Test.Assert(keys.Bind("escape", "close", "menu"));
		Test.Assert(keys.Bind("escape", "pause", "game")); // later, but outer
		bed.Key(.Escape);
		Test.Assert(bed.Ran.Count == 1);
		Test.Assert(bed.Ran[0] == "close");

		// "not in a menu" holds only outside it.
		Test.Assert(keys.Bind("f1", "pause", "game && !menu"));
		bed.Key(.F1);
		Test.Assert(bed.Ran.Count == 1);
		let hud = new Button();
		defer hud.ReleaseRef();
		hud.TabFocusable = true;
		game.AddChild(hud);
		bed.Root.EventDispatcher.FocusNode = hud;
		bed.Key(.F1);
		Test.Assert(bed.Ran.Count == 2);
		Test.Assert(bed.Ran[1] == "pause");
		bed.Key(.Escape); // outside the menu: the game's binding
		Test.Assert(bed.Ran.Count == 3);
		Test.Assert(bed.Ran[2] == "pause");
	}

	[Test]
	public static void ABindingToNothingUnbindsAKeyThere()
	{
		let bed = scope KeymapBed();
		bed.Handle("quit");
		let keys = bed.Root.Context.Keymap;
		Test.Assert(keys.Bind("escape", "quit"));
		Test.Assert(keys.Bind("escape", "", "menu")); // not in the menu
		bed.Key(.Escape);
		Test.Assert(bed.Ran.IsEmpty);
	}

	[Test]
	public static void AChordWaitsForItsNextKeystrokeAndLapses()
	{
		let bed = scope KeymapBed();
		bed.Handle("comment");
		bed.Handle("select-all");
		let keys = bed.Root.Context.Keymap;
		Test.Assert(keys.Bind("ctrl-x ctrl-c", "comment"));
		Test.Assert(keys.Bind("ctrl-a", "select-all"));
		bed.Key(.X, KeyModCtrl); // waits
		Test.Assert(bed.Ran.IsEmpty);
		bed.Key(.C, KeyModCtrl);
		Test.Assert(bed.Ran.Count == 1);
		Test.Assert(bed.Ran[0] == "comment");

		bed.Key(.X, KeyModCtrl);
		bed.Root.Context.Update(SceneFixtures.Seconds(1.5)); // too slow: dropped
		bed.Key(.C, KeyModCtrl);
		Test.Assert(bed.Ran.Count == 1);

		bed.Key(.X, KeyModCtrl);
		bed.Key(.A, KeyModCtrl); // broken off: the keystroke alone
		Test.Assert(bed.Ran.Count == 2);
		Test.Assert(bed.Ran[1] == "select-all");
	}

	[Test]
	public static void AGamepadsButtonsBindTooSouthActivatesWhenUnbound()
	{
		let bed = scope KeymapBed();
		bed.Handle("back");
		Test.Assert(bed.Root.Context.Keymap.Bind("pad-east", "back"));
		int clicks = 0;
		bed.Item.AddEventListener(.MouseClick, new [&] (e) => { clicks++; });
		let d = bed.Root.EventDispatcher;
		d.InjectPadButton(.East);
		Test.Assert(bed.Ran.Count == 1);
		d.InjectPadButton(.South);
		Test.Assert(clicks == 1);
	}

	[Test]
	public static void AChordCutShortRunsWhatItsFirstKeyBindsAloneTimedOutOrBrokenOff()
	{
		let bed = scope KeymapBed();
		bed.Handle("kill");
		bed.Handle("kill-all");
		bed.Handle("select-all");
		let keys = bed.Root.Context.Keymap;
		Test.Assert(keys.Bind("ctrl-k", "kill"));
		Test.Assert(keys.Bind("ctrl-k ctrl-a", "kill-all"));
		Test.Assert(keys.Bind("ctrl-a", "select-all"));
		bed.Key(.K, KeyModCtrl); // waits: a chord may follow
		Test.Assert(bed.Ran.IsEmpty);
		bed.Root.Context.Update(SceneFixtures.Seconds(1.5)); // none did
		Test.Assert(bed.Ran.Count == 1);
		Test.Assert(bed.Ran[0] == "kill");

		bed.Key(.K, KeyModCtrl);
		bed.Key(.Z, KeyModCtrl); // continues no binding: ctrl-k alone, then ctrl-z (unbound)
		Test.Assert(bed.Ran.Count == 2);
		Test.Assert(bed.Ran[1] == "kill");
	}

	[Test]
	public static void ACommandsKeysAsTextAreThoseBoundWhereTheControlIs()
	{
		let bed = scope KeymapBed();
		let keys = bed.Root.Context.Keymap;
		Test.Assert(keys.Bind("ctrl-s", "save", "menu"));
		Test.Assert(keys.Bind("ctrl-shift-s", "save", "editor")); // later, but elsewhere
		let here = scope List<KeyContextLayer>();
		defer { ClearAndDeleteItems!(here); }
		bed.Root.KeyContextsAt(bed.Item, here);
		let text = scope String();
		keys.ShortcutText("save", (Span<KeyContextLayer>)here, text);
		Test.Assert(text == "Ctrl+S");
	}

	[Test]
	public static void AModifierKeyBindsAloneThoughPressingItSetsItsOwnModifier()
	{
		let bed = scope KeymapBed();
		bed.Handle("sprint");
		bed.Handle("zoom");
		let keys = bed.Root.Context.Keymap;
		Test.Assert(keys.Bind("leftshift", "sprint"));
		Test.Assert(keys.Bind("ctrl-rightshift", "zoom"));
		bed.Key(.LeftShift, KeyModShift); // the platform reports Shift held as the key goes down
		Test.Assert(bed.Ran.Count == 1);
		Test.Assert(bed.Ran[0] == "sprint");
		bed.Key(.RightShift, KeyModShift | KeyModCtrl);
		Test.Assert(bed.Ran.Count == 2);
		Test.Assert(bed.Ran[1] == "zoom");
		bed.Key(.Keypad5);
		Test.Assert(bed.Ran.Count == 2); // unbound: Numpad 5 is not 5
	}

	[Test]
	public static void AControlBoundToACommandShowsItsLabelAndKeysAndFollowsThem()
	{
		let bed = scope KeymapBed();
		let save = bed.Root.Context.DefineCommand("save");
		save.Label = "Save";
		bed.Handle("save");
		let button = new Button();
		defer button.ReleaseRef();
		bed.Screen.AddChild(button);
		button.Command = "save";
		let menu = new Menu();
		defer menu.ReleaseRef();
		let item = menu.AddItem("", new () => { });
		bed.Screen.AddChild(menu); // in the tree, so its binding runs
		item.Command = "save";
		Test.Assert(bed.Root.Context.Keymap.Bind("ctrl-s", "save"));
		bed.Root.Context.Update(SceneFixtures.Frame); // bindings run once a frame
		Test.Assert(button.Text == "Save");
		Test.Assert(item.Text == "Save");
		Test.Assert(item.Shortcut == "Ctrl+S");

		save.Label = "Save all";
		Test.Assert(bed.Root.Context.Keymap.Bind("ctrl-shift-s", "save"));
		bed.Root.Context.Update(SceneFixtures.Frame);
		Test.Assert(button.Text == "Save all");
		Test.Assert(item.Shortcut == "Ctrl+Shift+S");

		// A control with its own text keeps it.
		let own = new Button();
		defer own.ReleaseRef();
		own.Text = "Keep";
		bed.Screen.AddChild(own);
		own.Command = "save";
		bed.Root.Context.Update(SceneFixtures.Frame);
		Test.Assert(own.Text == "Keep");
	}

	[Test]
	public static void ATextFieldKeepsItsKeysAndLeavesAShortcutToTheBindings()
	{
		let bed = scope KeymapBed();
		bed.Handle("save");
		Test.Assert(bed.Root.Context.Keymap.Bind("ctrl-s", "save"));
		Test.Assert(bed.Root.Context.Keymap.Bind("ctrl-a", "save")); // the field's own: it keeps it
		let field = new TextField();
		defer field.ReleaseRef();
		bed.Screen.AddChild(field);
		bed.Root.EventDispatcher.FocusNode = field;
		field.Text = "hello";
		bed.Key(.A, KeyModCtrl);
		Test.Assert(bed.Ran.IsEmpty); // select-all in the field
		bed.Root.EventDispatcher.InjectKeyDown((uint32)KeyCode.Unknown, KeyModCtrl);
		Test.Assert(bed.Ran.IsEmpty);
	}

	[Test]
	public static void AGreaterThanHoldsForAContextInsideAnother()
	{
		let outer = scope KeyContextLayer();
		outer.Declare("menu");
		let inner = scope KeyContextLayer();
		inner.Set(outer);
		inner.Declare("textinput");
		let elsewhere = scope KeyContextLayer();
		elsewhere.Declare("textinput");
		KeyContextLayer[2] nested = .(outer, inner);
		KeyContextLayer[1] alone = .(elsewhere);
		let p = scope ContextPredicate();
		Test.Assert(p.Parse("menu > textinput"));
		Test.Assert(p.Eval(Span<KeyContextLayer>(&nested[0], 2), 1));
		Test.Assert(!p.Eval(Span<KeyContextLayer>(&nested[0], 2), 0)); // the menu itself
		Test.Assert(!p.Eval(Span<KeyContextLayer>(&alone[0], 1), 0)); // a field in no menu
		Test.Assert(p.Parse("menu > textinput && !multiline || game")); // `>` binds loosest
		Test.Assert(p.Eval(Span<KeyContextLayer>(&nested[0], 2), 1));
		Test.Assert(!p.Parse("menu >"));

		// A binding for fields inside a menu beats the fields' own.
		let bed = scope KeymapBed();
		bed.Handle("menu.field-escape");
		let field = new TextField();
		defer field.ReleaseRef();
		field.Size = .(100.0f, 20.0f);
		bed.Screen.AddChild(field);
		Test.Assert(bed.Root.Context.Keymap.Bind("ctrl-a", "menu.field-escape", "menu > textinput"));
		field.RequestFocus();
		bed.Key(.A, KeyModCtrl);
		Test.Assert(bed.Ran.Count == 1);
		Test.Assert(bed.Ran[0] == "menu.field-escape");
	}

	[Test]
	public static void ATextFieldsContextMenuShowsTheKeysBoundToItsCommands()
	{
		let bed = scope KeymapBed();
		let field = new TextField();
		defer field.ReleaseRef();
		field.Size = .(100.0f, 20.0f);
		bed.Screen.AddChild(field);
		field.RequestFocus();
		bed.Root.EventDispatcher.InjectContextMenu();
		let menu = field.ContextMenu;
		Test.Assert(menu != null);
		let cut = menu.GetChildAt(0) as MenuItem;
		Test.Assert(cut != null);
		Test.Assert(cut.Shortcut == "Ctrl+X");
	}

	// The command `keys` run with no context held, into `outCommand` (empty: none).
	private static void Runs(Keymap keymap, StringView keys, String outCommand)
	{
		outCommand.Clear();
		var stroke = ParseKeystroke(keys).Value;
		let command = scope String();
		if (keymap.Match(Span<Keystroke>(&stroke, 1), Span<KeyContextLayer>(), command) == .Matched)
			outCommand.Set(command);
	}

	[Test]
	public static void ARebindingReplacesTheCommandsKeysWhereItWasBoundABindAdds()
	{
		let keymap = scope Keymap();
		let ran = scope String();
		Test.Assert(keymap.Bind("ctrl-s", "save"));
		Test.Assert(keymap.Bind("ctrl-shift-s", "save-all"));
		Test.Assert(keymap.Bind("ctrl-s", "menu.save", "menu")); // another context's

		// Rebound, the old key is free: it no longer saves, and the new one does.
		Test.Assert(keymap.Rebind("f2", "save"));
		Runs(keymap, "f2", ran);
		Test.Assert(ran == "save");
		Runs(keymap, "ctrl-s", ran);
		Test.Assert(ran.IsEmpty);
		Test.Assert(ShortcutIs(keymap, "save", "F2"));
		Runs(keymap, "ctrl-shift-s", ran);
		Test.Assert(ran == "save-all"); // another command keeps its keys
		Test.Assert(ShortcutIs(keymap, "menu.save", "Ctrl+S")); // and another context its own

		// A bind adds: both keys work. Keys that do not parse change nothing.
		Test.Assert(keymap.Bind("ctrl-s", "save"));
		Runs(keymap, "f2", ran);
		Test.Assert(ran == "save");
		Runs(keymap, "ctrl-s", ran);
		Test.Assert(ran == "save");
		Test.Assert(!keymap.Rebind("ctrl-nokey", "save"));
		Runs(keymap, "ctrl-s", ran);
		Test.Assert(ran == "save");

		// Unbound, it has no keys there.
		Test.Assert(keymap.UnbindCommand("save") == 2);
		Runs(keymap, "f2", ran);
		Test.Assert(ran.IsEmpty);
		Test.Assert(ShortcutIs(keymap, "save", ""));
	}
}
