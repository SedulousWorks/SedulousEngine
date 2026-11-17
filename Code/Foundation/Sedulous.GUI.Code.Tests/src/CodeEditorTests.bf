using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using static Sedulous.GUI.Code.Tests.CodeFixtures;

namespace Sedulous.GUI.Code.Tests;

/// The view: typing at every caret, one undo step that puts them back; the keymap's moves (smart
/// Home, a goal across for Up and Down), selections and deletes at each caret; Return keeping the
/// indent, Tab to a stop, tabs shown to their stops and hit by their places; the clipboard (several
/// copied, as many pasted; a line with no selection); the mouse (a click, Shift, a double and a
/// triple click, Alt adding a caret, a drag); scrolling to the caret; Escape leaving one caret;
/// markup. A mock font: 6px a byte, 12px a line; an editor 400 by 120 (ten lines of 12).
class CodeEditorTests
{
	[Test]
	public static void TypingAtEveryCaretIsOneUndoStepThatPutsThemBack()
	{
		let bed = scope CodeBed(default, "int a;\nint b;", 120.0f, true);
		bed.Editor.SetCaret(At(0, 0));
		bed.Editor.AddCaret(At(1, 0));
		Test.Assert(bed.Editor.Selections.Length == 2);
		bed.Editor.Type("/");
		bed.Editor.Type("/");
		bed.CheckText("//int a;\n//int b;");
		Test.Assert(bed.Editor.Selections[0].Head == At(0, 2));
		Test.Assert(bed.Editor.Selections[1].Head == At(1, 2));
		Test.Assert(bed.Editor.Document.UndoCount == 1); // typing merged
		Test.Assert(bed.Run(.Undo));
		bed.CheckText("int a;\nint b;");
		Test.Assert(bed.Editor.Selections.Length == 2);
		Test.Assert(bed.Editor.Selections[1].Head == At(1, 0));
		Test.Assert(bed.Run(.Redo));
		bed.CheckText("//int a;\n//int b;");

		// Typing over a selection replaces it; several carets on one line keep their places.
		CodeSelection[2] two = .(.(At(0, 2), At(0, 5)), .(At(0, 6), At(0, 6)));
		bed.Editor.SetSelections(two);
		bed.Editor.Type("X");
		Test.Assert(bed.Editor.Document.LineText(0) == "//X Xa;");
		Test.Assert(bed.Editor.Selections[1].Head == At(0, 5));
	}

	[Test]
	public static void TheKeymapsMovesAtEachCaretSmartHomeWordsAGoalAcrossForUpAndDown()
	{
		let bed = scope CodeBed(default, "    long line here\nab\nanother long line", 120.0f, true);
		bed.Editor.SetCaret(At(0, 10));
		bed.Run(.MoveLineStart);
		Test.Assert(bed.Caret == At(0, 4)); // past the indent
		bed.Run(.MoveLineStart);
		Test.Assert(bed.Caret == At(0, 0)); // then the line's start
		bed.Run(.MoveLineEnd);
		Test.Assert(bed.Caret == At(0, 18));
		bed.Run(.MoveWordLeft);
		Test.Assert(bed.Caret == At(0, 14));
		bed.Run(.MoveRight);
		Test.Assert(bed.Caret == At(0, 15));
		// Down through a short line keeps the column it set out from.
		bed.Editor.SetCaret(At(0, 12));
		bed.Run(.MoveDown);
		Test.Assert(bed.Caret == At(1, 2));
		bed.Run(.MoveDown);
		Test.Assert(bed.Caret == At(2, 12));
		bed.Run(.MoveDown); // past the last line: its end
		Test.Assert(bed.Caret == At(2, 17));
		// Selecting extends; a move without collapses to the side it goes.
		bed.Editor.SetCaret(At(1, 0));
		bed.Run(.SelectRight);
		bed.Run(.SelectRight);
		Test.Assert(bed.Editor.Primary.Range == CodeRange(At(1, 0), At(1, 2)));
		bed.Run(.MoveLeft);
		Test.Assert(bed.Caret == At(1, 0));
		bed.Run(.SelectAll);
		Test.Assert(bed.Editor.Primary.Range == CodeRange(At(0, 0), At(2, 17)));
		bed.Run(.MoveDocumentStart);
		Test.Assert(bed.Caret == At(0, 0));
	}

	[Test]
	public static void DeletesAtEachCaretCaretsThatMeetBecomingOne()
	{
		let bed = scope CodeBed(default, "abc\ndef", 120.0f, true);
		bed.Editor.SetCaret(At(0, 2));
		bed.Editor.AddCaret(At(1, 2));
		bed.Run(.DeleteBackward);
		bed.CheckText("ac\ndf");
		bed.Run(.DeleteBackward);
		bed.CheckText("c\nf");
		bed.Run(.DeleteBackward); // the second caret joins the lines
		bed.CheckText("cf");
		Test.Assert(bed.Editor.Selections.Length == 2);
		bed.Editor.SetText("one two");
		bed.Editor.SetCaret(At(0, 7));
		bed.Run(.DeleteWordBackward);
		bed.CheckText("one ");
		// Two carets on one place are one.
		bed.Editor.SetCaret(At(0, 1));
		bed.Editor.AddCaret(At(0, 1));
		Test.Assert(bed.Editor.Selections.Length == 1);
	}

	[Test]
	public static void ReturnKeepsTheIndentTabToTheNextStopTabsShownAtTheirStopsAndHitThere()
	{
		let bed = scope CodeBed(default, "    if (x)", 120.0f, true);
		bed.Editor.SetCaret(At(0, 10));
		bed.Run(.InsertNewline);
		bed.CheckText("    if (x)\n    ");
		Test.Assert(bed.Caret == At(1, 4));
		bed.Editor.SetText("ab");
		bed.Editor.SetCaret(At(0, 2));
		bed.D.InjectKeyDown((uint32)KeyCode.Tab);
		bed.CheckText("ab  "); // to column 4

		bed.Editor.SetText("\tx\ta");
		bed.Frame();
		let left = bed.Editor.TextLeft;
		Test.Assert(Near(bed.Editor.CaretRect(At(0, 1)).X, left + 4.0f * 6.0f)); // after the tab: column 4
		Test.Assert(Near(bed.Editor.CaretRect(At(0, 3)).X, left + 8.0f * 6.0f)); // x then a tab to 8
		// A point inside a tab's spaces goes to its nearer side.
		let y = bed.Editor.CaretRect(At(0, 0)).Y + 6.0f;
		Test.Assert(bed.Editor.PositionAt(.(left + 6.0f, y)) == At(0, 0));
		Test.Assert(bed.Editor.PositionAt(.(left + 20.0f, y)) == At(0, 1));
	}

	[Test]
	public static void TheClipboardSeveralCopiedAsManyPastedWithNoSelectionTheCaretsLine()
	{
		let bed = scope CodeBed(default, "alpha\nbeta\ngamma", 120.0f, true);
		CodeSelection[2] words = .(.(At(0, 0), At(0, 5)), .(At(1, 0), At(1, 4)));
		bed.Editor.SetSelections(words);
		bed.Run(.Copy);
		Test.Assert(bed.Clipboard.Text == "alpha\nbeta");
		// Two carets, two lines: one each.
		bed.Editor.SetCaret(At(2, 0));
		bed.Editor.AddCaret(At(2, 5));
		bed.Run(.Paste);
		Test.Assert(bed.Editor.Document.LineText(2) == "alphagammabeta");
		// One caret: the whole text there.
		bed.Editor.SetCaret(At(0, 0));
		bed.Run(.Paste);
		Test.Assert(bed.Editor.Document.LineText(0) == "alpha");
		Test.Assert(bed.Editor.Document.LineText(1) == "betaalpha");
		// No selection: copy and cut the caret's line.
		bed.Editor.SetText("one\ntwo\nthree");
		bed.Editor.SetCaret(At(1, 1));
		bed.Run(.Cut);
		Test.Assert(bed.Clipboard.Text == "two\n");
		bed.CheckText("one\nthree");
	}

	[Test]
	public static void TheMouseAClickShiftADoubleAndATripleClickAltAddingACaretADrag()
	{
		let bed = scope CodeBed(default, "int value = 42;\nreturn value;", 120.0f, true);
		bed.Click(bed.Over(At(0, 6)));
		Test.Assert(bed.Caret == At(0, 6));
		Test.Assert(bed.Editor.IsFocused);
		bed.Pause();
		bed.Click(bed.Over(At(1, 3)), KeyModShift);
		Test.Assert(bed.Editor.Primary.Range == CodeRange(At(0, 6), At(1, 3)));
		bed.Pause();
		bed.Click(bed.Over(At(0, 6)));
		bed.Click(bed.Over(At(0, 6))); // the second of a double
		Test.Assert(bed.Editor.Primary.Range == CodeRange(At(0, 4), At(0, 9))); // "value"
		bed.Click(bed.Over(At(0, 6))); // the third
		Test.Assert(bed.Editor.Primary.Range == CodeRange(At(0, 0), At(1, 0)));
		bed.Pause();
		bed.Click(bed.Over(At(0, 2)));
		bed.Pause();
		bed.Click(bed.Over(At(1, 2)), KeyModAlt);
		Test.Assert(bed.Editor.Selections.Length == 2);
		Test.Assert(bed.Editor.Primary.Head == At(1, 2));
		// Escape leaves the primary caret alone.
		bed.D.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(bed.Editor.Selections.Length == 1);
		Test.Assert(bed.Caret == At(1, 2));
		// A drag selects from the press to the pointer.
		bed.Pause();
		let from = bed.Over(At(0, 1));
		let to = bed.Over(At(0, 8));
		bed.D.InjectMouseMove(from);
		bed.D.InjectMouseDown(from, .Left);
		bed.D.InjectMouseMove(to);
		bed.D.InjectMouseUp(to, .Left);
		Test.Assert(bed.Editor.Primary.Range == CodeRange(At(0, 1), At(0, 8)));
	}

	[Test]
	public static void ItScrollsToTheCaretDrawingTheLinesInView()
	{
		let text = scope String();
		for (int i = 0; i < 100; ++i)
			text.AppendF("line {}\n", i);
		let bed = scope CodeBed(default, text, 120.0f, true);
		bed.Editor.VisibleLines(var first, var last);
		Test.Assert(first == 0);
		Test.Assert(last <= 10);
		bed.Run(.MoveDocumentEnd);
		bed.Frame();
		Test.Assert(bed.Caret == At(100, 0));
		bed.Editor.VisibleLines(out first, out last);
		Test.Assert(last == 100);
		Test.Assert(first >= 90);
		let caret = bed.Editor.CaretRect(bed.Caret);
		Test.Assert(caret.Y + caret.Height <= bed.Editor.ContentBounds.Bottom + 0.5f);
		Test.Assert(bed.Editor.ScrollOffset.Y > 0.0f);
		// Typing there lays it out again: it stays where it was scrolled.
		let scrolled = bed.Editor.ScrollOffset.Y;
		bed.Editor.Type("x");
		bed.Frame();
		Test.Assert(Near(bed.Editor.ScrollOffset.Y, scrolled));
	}

	[Test]
	public static void ItsKeysComeThroughTheKeymapTypedTextGoesInReadOnlyNothingChanges()
	{
		let bed = scope CodeBed(default, "abc", 120.0f, true);
		bed.Editor.SetCaret(At(0, 0));
		bed.D.InjectKeyDown((uint32)KeyCode.End);
		Test.Assert(bed.Caret == At(0, 3));
		bed.D.InjectText("d");
		bed.CheckText("abcd");
		bed.D.InjectKeyDown((uint32)KeyCode.Backspace);
		bed.CheckText("abc");
		bed.Editor.IsReadOnly = true;
		bed.D.InjectText("x");
		bed.D.InjectKeyDown((uint32)KeyCode.Backspace);
		bed.CheckText("abc");
	}

	/// A caret another caret's edit swallowed ends where that edit left it: from 5 a word deleted
	/// backward takes "abcde", carrying the caret at 3 to 0, where its own delete has nothing to
	/// take; it kept its place from before the edit, a caret at 3 in "fgh".
	[Test]
	public static void ACaretAnotherCaretsEditSwallowedEndsWhereThatEditLeftIt()
	{
		let bed = scope CodeBed(default, "abcdefgh", 120.0f, true);
		CodeSelection[2] two = .(.(At(0, 3), At(0, 3)), .(At(0, 5), At(0, 5)));
		bed.Editor.SetSelections(two);
		Test.Assert(bed.Run(.DeleteWordBackward));
		bed.CheckText("fgh");
		Test.Assert(bed.Editor.Selections.Length == 1);
		Test.Assert(bed.Caret == At(0, 0));
		// Carets that do not overlap still each make their edit.
		let apart = scope CodeBed(default, "ab cd ef", 120.0f, true);
		CodeSelection[3] three = .(.(At(0, 2), At(0, 2)), .(At(0, 5), At(0, 5)), .(At(0, 8), At(0, 8)));
		apart.Editor.SetSelections(three);
		Test.Assert(apart.Run(.DeleteBackward));
		apart.CheckText("a c e");
	}

	/// Read only holds for undo, redo and the line commands, which edit the document without the
	/// planned edits' check.
	[Test]
	public static void ReadOnlyUndoRedoAndTheLineCommandsChangeNothing()
	{
		let bed = scope CodeBed(default, "one\ntwo\nthree", 120.0f, true);
		bed.Editor.SetCaret(At(0, 3));
		bed.Editor.Type("!");
		bed.CheckText("one!\ntwo\nthree");
		bed.Editor.IsReadOnly = true;
		bed.Editor.SetCaret(At(1, 0));
		Test.Assert(!bed.Run(.Undo));
		bed.CheckText("one!\ntwo\nthree");
		bed.Editor.MoveLines(true);
		bed.Editor.MoveLines(false);
		bed.Editor.DuplicateLines(true);
		bed.Editor.DuplicateLines(false);
		bed.Editor.DeleteLines();
		bed.Editor.IndentLines(false);
		bed.Editor.IndentLines(true);
		bed.CheckText("one!\ntwo\nthree");
		bed.Editor.IsReadOnly = false;
		Test.Assert(bed.Run(.Undo), "writable again, the edit undoes");
		bed.CheckText("one\ntwo\nthree");
	}

	[Test]
	public static void TwoEditorsOverOneDocumentSeeEachOthersEdits()
	{
		let bed = scope CodeBed(default, "shared", 120.0f, true);
		let other = new CodeEditor();
		defer other.ReleaseRef();
		let doc = scope CodeDocument();
		doc.SetText("one");
		bed.Editor.Document = doc;
		other.Document = doc;
		bed.Editor.SetCaret(At(0, 3));
		bed.Editor.Type("!");
		Test.Assert(other.GetText(.. scope String()) == "one!");
		// Both hear it: the other's caret, after where the text went, moved along with it.
		other.SetCaret(At(0, 3));
		bed.Editor.SetCaret(At(0, 0));
		bed.Editor.Type(">");
		Test.Assert(other.GetText(.. scope String()) == ">one!");
		Test.Assert(other.Primary.Head == At(0, 4));
		bed.Editor.Document = null; // back to its own
		other.Document = null;
		bed.CheckText("shared"); // its own, as it was
	}

	[Test]
	public static void TheGuttersMarksStayWithTheirLinesAClickInTheirColumnIsTheHosts()
	{
		let bed = scope CodeBed(default, "zero\none\ntwo\nthree", 120.0f, true);
		let breakpoint = bed.Editor.AddMarker(2, "breakpoint");
		let bookmark = bed.Editor.AddMarker(3, "bookmark");
		Test.Assert(bed.Editor.HasMarker(2, "breakpoint"));
		bed.Editor.Document.Insert(At(0, 0), "new\n");
		Test.Assert(bed.Editor.MarkerLine(breakpoint) == 3);
		// Return at its line's start: the mark goes down with the text.
		bed.Editor.SetCaret(At(3, 0));
		bed.Run(.InsertNewline);
		Test.Assert(bed.Editor.MarkerLine(breakpoint) == 4);
		bed.Editor.RemoveMarker(breakpoint);
		Test.Assert(!bed.Editor.HasMarker(4, "breakpoint"));
		Test.Assert(bed.Editor.MarkerLine(bookmark) == 5);
		bed.Editor.ClearMarkers("bookmark");
		Test.Assert(bed.Editor.MarkerLine(bookmark) == uint32.MaxValue);

		// A click in the marker column: told its line, the caret staying.
		let clicked = scope List<uint32>();
		bed.Editor.SetOnGutterClick(new (line) => { clicked.Add(line); });
		bed.Editor.SetCaret(At(0, 1));
		let row = bed.Editor.CaretRect(At(2, 0));
		bed.Click(.(bed.Editor.ContentBounds.X + 4.0f, row.Y + row.Height * 0.5f));
		Test.Assert(clicked.Count == 1);
		Test.Assert(clicked[0] == 2);
		Test.Assert(bed.Caret == At(0, 1));
	}

	[Test]
	public static void DiagnosticsKeepTheirPlacesThroughEditsTheWorstOnALineTheirMessagesOnHover()
	{
		let bed = scope CodeBed(default, "int a = b;\nfloat c;", 120.0f, true);
		let set = scope List<CodeDiagnostic>();
		defer { ClearAndDeleteItems!(set); }
		set.Add(new CodeDiagnostic(.(At(0, 8), At(0, 9)), .Error, "'b' is not declared"));
		set.Add(new CodeDiagnostic(.(At(1, 6), At(1, 6)), .Warning, "'c' is never used"));
		bed.Editor.SetDiagnostics(set);
		CodeSeverity worst;
		Test.Assert(bed.Editor.WorstOn(0, out worst));
		Test.Assert(worst == .Error);
		Test.Assert(bed.Editor.WorstOn(1, out worst));
		Test.Assert(worst == .Warning);
		Test.Assert(!bed.Editor.WorstOn(2, out worst));
		// An edit before them moves them.
		bed.Editor.Document.Insert(At(0, 0), "// x\n");
		let moved = scope List<CodeDiagnostic>();
		defer { ClearAndDeleteItems!(moved); }
		bed.Editor.GetDiagnostics(moved);
		Test.Assert(moved.Count == 2);
		Test.Assert(moved[0].Range == CodeRange(At(1, 8), At(1, 9)));
		Test.Assert(moved[1].Range.Start == At(2, 6));
		// An empty one marks its word.
		Test.Assert(bed.Editor.DiagnosticsAt(At(2, 7), .. scope String()) == "'c' is never used");
		Test.Assert(bed.Editor.DiagnosticsAt(At(1, 8), .. scope String()) == "'b' is not declared");
		Test.Assert(bed.Editor.DiagnosticsAt(At(1, 2), .. scope String()).IsEmpty);
		// The pointer over one: its message for the tooltip; in the gutter, its line's.
		bed.Frame();
		let at = bed.Editor.CaretRect(At(1, 8));
		bed.D.InjectMouseMove(.(at.X + 3.0f, at.Y + at.Height * 0.5f));
		Test.Assert(bed.Editor.TooltipText == "'b' is not declared");
		bed.D.InjectMouseMove(.(bed.Editor.ContentBounds.X + 4.0f, bed.Editor.CaretRect(At(2, 0)).Y + 6.0f));
		Test.Assert(bed.Editor.TooltipText == "'c' is never used");
		// A new set replaces them.
		bed.Editor.SetDiagnostics(default);
		let none = scope List<CodeDiagnostic>();
		defer { ClearAndDeleteItems!(none); }
		bed.Editor.GetDiagnostics(none);
		Test.Assert(none.IsEmpty);
	}

	[Test]
	public static void AnElementMarkupPlaces()
	{
		RegisterGuiElements();
		RegisterCodeElements();
		let elements = ElementSet.All();
		defer delete elements;
		let loader = scope MarkupLoader(elements);
		let made = loader.LoadFromString("<Panel><CodeEditor tab-size=\"2\" read-only=\"true\"/></Panel>");
		Test.Assert(made != null);
		defer made.ReleaseRef();
		let editor = made.GetChildAt(0) as CodeEditor;
		Test.Assert(editor != null);
		Test.Assert(editor.TabSize == 2);
		Test.Assert(editor.IsReadOnly);
	}

	private static MenuItem ItemNamed(Menu menu, StringView text)
	{
		for (int i = 0; i < menu.ChildCount; i++)
		{
			if ((menu.GetChildAt(i) is MenuItem) && ((MenuItem)menu.GetChildAt(i)).Text == text)
				return (MenuItem)menu.GetChildAt(i);
		}
		return null;
	}

	private static void RightClick(CodeBed bed, Float2 at)
	{
		bed.D.InjectMouseMove(at);
		bed.D.InjectMouseDown(at, .Right);
		bed.D.InjectMouseUp(at, .Right);
	}

	/// A right click in the code did nothing.
	[Test]
	public static void ARightClickOpensItsEditMenuWithEachCommandsKeysAtTheClick()
	{
		let bed = scope CodeBed(default, "int a;\nint b;", 240.0f, true);
		bed.Editor.SetCaret(At(0, 0));
		RightClick(bed, bed.Over(At(1, 2)));
		let menu = bed.Editor.ContextMenu;
		Test.Assert(menu != null);
		Test.Assert(menu.IsOpen);
		Test.Assert(bed.Caret == At(1, 2)); // outside any selection: the caret moves to the click

		let undo = ItemNamed(menu, "Undo");
		let copy = ItemNamed(menu, "Copy");
		let paste = ItemNamed(menu, "Paste");
		let comment = ItemNamed(menu, "Toggle comment");
		Test.Assert((undo != null) && (copy != null) && (paste != null) && (comment != null));
		Test.Assert(ItemNamed(menu, "Redo") != null);
		Test.Assert(ItemNamed(menu, "Cut") != null);
		Test.Assert(ItemNamed(menu, "Select all") != null);
		Test.Assert(!undo.Enabled); // nothing edited yet
		Test.Assert(copy.Enabled); // with no selection, the caret's line
		Test.Assert(!paste.Enabled); // the clipboard is empty
		Test.Assert(!comment.Enabled); // no language, so no comment syntax
		Test.Assert(copy.Shortcut.Length != 0);

		copy.HandleActivate();
		Test.Assert(bed.Clipboard.Text == "int b;\n");
	}

	[Test]
	public static void ARightClickInsideTheSelectionKeepsIt()
	{
		let bed = scope CodeBed(default, "int alpha;", 240.0f, true);
		CodeSelection[1] word = .(.(At(0, 4), At(0, 9)));
		bed.Editor.SetSelections(word);
		RightClick(bed, bed.Over(At(0, 6)));
		Test.Assert(bed.Editor.ContextMenu != null);
		Test.Assert(bed.Editor.Primary == word[0]);
		let cut = ItemNamed(bed.Editor.ContextMenu, "Cut");
		Test.Assert(cut != null);
		cut.HandleActivate();
		bed.CheckText("int ;");
		Test.Assert(bed.Clipboard.Text == "alpha");
	}

	[Test]
	public static void TheHostAddsItsItemsToTheContextMenuForTheClickedLine()
	{
		let bed = scope CodeBed(default, "a\nb\nc", 240.0f, true);
		uint32 toggled = 99;
		bed.Editor.SetOnContextMenu(new [&toggled] (menu, line) =>
			{
				menu.AddItem("Toggle breakpoint", new [&toggled, =line] () => { toggled = line; });
			});
		RightClick(bed, bed.Over(At(2, 0)));
		Test.Assert(bed.Editor.ContextMenu != null);
		let item = ItemNamed(bed.Editor.ContextMenu, "Toggle breakpoint");
		Test.Assert(item != null);
		item.HandleActivate();
		Test.Assert(toggled == 2);
		// Opened again, the host's item is there once.
		RightClick(bed, bed.Over(At(1, 0)));
		let menu = bed.Editor.ContextMenu;
		int count = 0;
		for (int i = 0; i < menu.ChildCount; i++)
		{
			if ((menu.GetChildAt(i) is MenuItem) && ((MenuItem)menu.GetChildAt(i)).Text == "Toggle breakpoint")
				count++;
		}
		Test.Assert(count == 1);
	}

	/// The clipboard's lines were split at the line feed alone, so text copied on Windows put a CR at
	/// the end of each line pasted into a caret.
	[Test]
	public static void LinesPastedOneToACaretFromACrLfClipboardCarryNoCr()
	{
		let bed = scope CodeBed(default, "x\ny", 120.0f, true);
		bed.Clipboard.SetText("one\r\ntwo");
		bed.Editor.SetCaret(At(0, 1));
		bed.Editor.AddCaret(At(1, 1));
		bed.Run(.Paste);
		Test.Assert(bed.Editor.Document.LineText(0) == "xone");
		Test.Assert(bed.Editor.Document.LineText(1) == "ytwo");
	}

	/// With no selection each caret cut its whole line, and two carets on one line both did: the
	/// second cut removed the line, the first caret moved to the next line, and that went too.
	[Test]
	public static void TwoCaretsOnOneLineCutThatLineOnceAndNoOther()
	{
		let bed = scope CodeBed(default, "one\ntwo\nthree", 120.0f, true);
		bed.Editor.SetCaret(At(0, 1));
		bed.Editor.AddCaret(At(0, 2));
		bed.Run(.Cut);
		Test.Assert(bed.Text(.. scope .()) == "two\nthree", bed.Text(.. scope .()));
		Test.Assert(bed.Clipboard.Text == "one\n", bed.Clipboard.Text);
	}
}
