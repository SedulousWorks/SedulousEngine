using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// The editing model: graphemes and words over UTF-8, each command on multi-byte and combining
/// text, undo folding, the filter and the length limit, read-only and password rules, and the
/// editing keys bound in the text contexts.
class TextEditModelTests
{
	private static TextEditModel Model(StringView text, TextEditModel outModel)
	{
		outModel.Text = text;
		return outModel;
	}

	private static KeymapMatch Match(Keymap keymap, StringView keys, KeyContextLayer layer, String command)
	{
		Keystroke[1] stroke = .(ParseKeystroke(keys).Value);
		KeyContextLayer[1] stack = .(layer);
		return keymap.Match(stroke, stack, command);
	}

	[Test]
	public static void ACombiningMarkAnEmojisJoinedPartsAndAFlagAreOneGraphemeEach()
	{
		StringView accent = "e\u{0301}x"; // e + combining acute, then x
		Test.Assert(NextGrapheme(accent, 0) == 3);
		Test.Assert(PrevGrapheme(accent, 3) == 0);
		Test.Assert(!IsGraphemeBoundary(accent, 1));
		Test.Assert(GraphemeCount(accent) == 2);

		StringView family = "\u{1F469}\u{200D}\u{1F467}!"; // woman ZWJ girl, then !
		Test.Assert(NextGrapheme(family, 0) == family.Length - 1);
		StringView flags = "\u{1F1EF}\u{1F1F5}\u{1F1EB}\u{1F1F7}"; // two flags
		Test.Assert(NextGrapheme(flags, 0) == 8);
		Test.Assert(GraphemeCount(flags) == 2);
		StringView crlf = "a\r\nb";
		Test.Assert(NextGrapheme(crlf, 1) == 3);
		StringView thumbs = "\u{1F44D}\u{1F3FD}."; // thumbs up, medium skin tone
		Test.Assert(NextGrapheme(thumbs, 0) == 8);
	}

	[Test]
	public static void WordsMoveOverAWordAndTheGapAfterItNeverAcrossALineBreak()
	{
		StringView text = "one two,  three\nfour";
		Test.Assert(NextWordBoundary(text, 0) == 4); // "one " -> before "two"
		Test.Assert(NextWordBoundary(text, 4) == 10); // "two,  " -> before "three"
		Test.Assert(NextWordBoundary(text, 10) == 15); // stops at the break
		Test.Assert(NextWordBoundary(text, 15) == 16); // over the break
		Test.Assert(PrevWordBoundary(text, 20) == 16);
		Test.Assert(PrevWordBoundary(text, 16) == 15);
		Test.Assert(PrevWordBoundary(text, 15) == 10);
		Test.Assert(PrevWordBoundary(text, 10) == 4);
		Test.Assert(WordRangeAt(text, 5) == TextRange(4, 7));
		Test.Assert(WordRangeAt(text, 8) == TextRange(8, 10)); // the spaces
		StringView accented = "café crème";
		Test.Assert(WordRangeAt(accented, 1) == TextRange(0, 5)); // é counts as a letter
		Test.Assert(LineRangeAt(text, 17) == TextRange(16, 20));
	}

	[Test]
	public static void CaretMovesStepByGraphemeCollapseASelectionAndExtendOne()
	{
		let m = Model("ae\u{0301}z", scope .());
		Test.Assert(m.Caret == 5);
		m.Run(.MoveLeft);
		Test.Assert(m.Caret == 4); // before z
		m.Run(.MoveLeft);
		Test.Assert(m.Caret == 1); // over e + acute at once
		m.Run(.SelectRight);
		Test.Assert(m.SelectedText == "e\u{0301}");
		m.Run(.MoveLeft);
		Test.Assert(m.Caret == 1); // collapsed to the selection's start
		Test.Assert(!m.HasSelection);
		m.Run(.SelectDocumentEnd);
		Test.Assert(m.SelectedText == "e\u{0301}z");
		m.Run(.MoveRight);
		Test.Assert(m.Caret == 5);
		m.SetCaret(2); // inside the grapheme: snapped back to its start
		Test.Assert(m.Caret == 1);
	}

	[Test]
	public static void DeleteByGraphemeAndByWordAndToTheLinesEnds()
	{
		let m = Model("hello wo\u{0308}rld", scope .());
		m.Run(.DeleteWordBackward);
		Test.Assert(m.Text == "hello ");
		m.Text = "x\u{1F469}\u{200D}\u{1F467}";
		m.Run(.DeleteBackward);
		Test.Assert(m.Text == "x"); // the whole family at once
		m.Text = "one two three";
		m.SetCaret(4);
		m.Run(.DeleteWordForward);
		Test.Assert(m.Text == "one three");
		m.Run(.DeleteToLineEnd);
		Test.Assert(m.Text == "one ");
		m.Run(.DeleteToLineStart);
		Test.Assert(m.Text == "");
		m.Text = "ab";
		m.SetCaret(0);
		m.Run(.DeleteForward);
		Test.Assert(m.Text == "b");
	}

	[Test]
	public static void TypingReplacesTheSelectionTheFilterAndTheLimitCutWhatComesIn()
	{
		let m = Model("hello", scope .());
		m.Select(.(1, 4));
		Test.Assert(m.Insert("ipp"));
		Test.Assert(m.Text == "hippo");
		Test.Assert(m.Caret == 4);

		let digits = scope TextEditModel();
		digits.Filter = InputFilter.Digits();
		digits.Insert("a1b2c3");
		Test.Assert(digits.Text == "123");

		let limited = scope TextEditModel();
		limited.MaxLength = 3;
		limited.Insert("e\u{0301}e\u{0301}e\u{0301}e\u{0301}"); // four graphemes, eight codepoints
		Test.Assert(GraphemeCount(limited.Text) == 3);
		Test.Assert(!limited.Insert("x")); // full
		limited.SelectAll();
		Test.Assert(limited.Insert("ok")); // a selection's room counts
		Test.Assert(limited.Text == "ok");
	}

	[Test]
	public static void ASingleLineTakesAPastedLineBreakAsASpaceMultilineKeepsIt()
	{
		let clipboard = scope TestClipboard();
		clipboard.SetText("a\r\nb\nc");
		let line = scope TextEditModel();
		line.Run(.Paste, clipboard);
		Test.Assert(line.Text == "a b c");
		Test.Assert(!line.Run(.InsertNewline));

		let area = scope TextEditModel();
		area.Multiline = true;
		area.Run(.Paste, clipboard);
		Test.Assert(area.Text == "a\nb\nc");
		area.Run(.InsertNewline);
		Test.Assert(area.Text == "a\nb\nc\n");
	}

	[Test]
	public static void CutCopyAndPasteThroughAClipboard()
	{
		let clipboard = scope TestClipboard();
		let m = Model("copy me", scope .());
		m.Select(.(5, 7));
		m.Run(.Copy, clipboard);
		Test.Assert(clipboard.Text == "me");
		m.Run(.Cut, clipboard);
		Test.Assert(m.Text == "copy ");
		m.SetCaret(0);
		m.Run(.Paste, clipboard);
		Test.Assert(m.Text == "mecopy ");
	}

	[Test]
	public static void ReadOnlyTakesMovesAndCopiesNotEditsAPasswordLetsNothingOut()
	{
		let clipboard = scope TestClipboard();
		let m = Model("fixed", scope .());
		m.ReadOnly = true;
		m.SelectAll();
		Test.Assert(!m.Insert("x"));
		Test.Assert(!m.Run(.DeleteBackward));
		Test.Assert(m.Run(.Cut, clipboard)); // a copy
		Test.Assert(clipboard.Text == "fixed");
		Test.Assert(m.Text == "fixed");
		Test.Assert(m.Run(.MoveLeft));

		let other = scope TestClipboard();
		let secret = Model("hunter2", scope .());
		secret.CopyAllowed = false;
		secret.SelectAll();
		secret.Run(.Copy, other);
		secret.Run(.Cut, other);
		Test.Assert(!other.HasText);
		Test.Assert(secret.Text == "hunter2");
	}

	[Test]
	public static void ARunOfTypingUndoesAsOneStepAPauseAMoveOrAnotherEditEndsIt()
	{
		let m = scope TextEditModel();
		m.Time = 0.0;
		m.Insert("a");
		m.Time = 0.2;
		m.Insert("b");
		m.Time = 0.4;
		m.Insert("c");
		m.Time = 3.0; // a pause
		m.Insert("d");
		Test.Assert(m.Text == "abcd");
		m.Run(.Undo);
		Test.Assert(m.Text == "abc");
		m.Run(.Undo);
		Test.Assert(m.Text == "");
		m.Run(.Redo);
		Test.Assert(m.Text == "abc");
		Test.Assert(m.Caret == 3);

		m.Run(.MoveLeft); // a move ends the run
		m.Insert("x");
		m.Insert("y");
		m.Run(.DeleteBackward); // another kind of edit
		m.Run(.DeleteBackward); // deleting folds with itself
		Test.Assert(m.Text == "abc");
		m.Run(.Undo);
		Test.Assert(m.Text == "abxyc");
		m.Run(.Undo);
		Test.Assert(m.Text == "abc");
	}

	[Test]
	public static void UpAndDownKeepTheirColumnAcrossTheTextsLines()
	{
		let m = Model("long line\nab\nanother", scope .());
		m.Multiline = true;
		m.SetCaret(7); // "long li|ne"
		m.Run(.MoveDown);
		Test.Assert(m.Caret == 12); // the end of "ab"
		m.Run(.MoveDown);
		Test.Assert(m.Caret == 20); // column 7 of "another"
		m.Run(.MoveUp);
		m.Run(.MoveUp);
		Test.Assert(m.Caret == 7);
		m.Run(.MoveUp);
		Test.Assert(m.Caret == 0); // past the first line
		m.Run(.SelectDown); // the column kept from before
		Test.Assert(m.SelectedText == "long line\nab");
		m.SetCaret(14);
		m.Run(.MoveLineStart);
		Test.Assert(m.Caret == 13);
		m.Run(.MoveLineEnd);
		Test.Assert(m.Caret == 20);
	}

	[Test]
	public static void EveryCommandHasANameTheKeymapBindsFoundAgainFromIt()
	{
		for (int i = 0; i < (int)TextEditCommand.Count; i++)
		{
			Test.Assert(TextEditModel.FindCommand(TextEditCommandName((TextEditCommand)i), let found));
			Test.Assert((int)found == i);
		}
		Test.Assert(!TextEditModel.FindCommand("text.nonesuch", ?));
	}

	[Test]
	public static void TextEditingKeysAreBoundInTheTextContextsMultilineKeysOnlyInATextArea()
	{
		let keymap = scope Keymap();
		BindTextEditingKeys(keymap);
		let field = scope KeyContextLayer();
		field.Declare("textinput");
		let area = scope KeyContextLayer();
		area.Declare("textinput multiline");
		let command = scope String();
		Test.Assert(Match(keymap, "ctrl-shift-left", field, command) == .Matched);
		Test.Assert(command == TextEditCommandName(.SelectWordLeft));
		Test.Assert(Match(keymap, "enter", field, command) == .Matched);
		Test.Assert(command == cTextSubmitCommand);
		Test.Assert(Match(keymap, "enter", area, command) == .Matched);
		Test.Assert(command == TextEditCommandName(.InsertNewline));
		Test.Assert(Match(keymap, "up", field, command) == .None); // a field's up is navigation's
		Test.Assert(Match(keymap, "up", area, command) == .Matched);
		let elsewhere = scope KeyContextLayer();
		elsewhere.Declare("menu");
		Test.Assert(Match(keymap, "left", elsewhere, command) == .None);
	}

	[Test]
	public static void TypingTheFilterRefusesWholeLeavesTheSelectionAsItWas()
	{
		let digits = scope TextEditModel();
		digits.Filter = InputFilter.Digits();
		digits.Text = "12345";
		digits.Select(.(1, 3));
		Test.Assert(!digits.Insert("ab")); // letters: none let in
		Test.Assert(digits.Text == "12345");
		Test.Assert(digits.Selection.Start == 1);
		Test.Assert(digits.Selection.End == 3);
		Test.Assert(digits.Insert("a9")); // some let in: they replace it
		Test.Assert(digits.Text == "1945");
	}
}
