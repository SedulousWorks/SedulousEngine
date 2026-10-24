using System;
using Sedulous.GUI;
using internal Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Bindings: keystrokes and gamepad buttons parsed and named, context predicates over a key
/// context layer, and a command's keys as a menu shows them.
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
}
