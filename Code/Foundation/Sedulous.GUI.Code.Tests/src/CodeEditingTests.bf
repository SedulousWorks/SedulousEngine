using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using static Sedulous.GUI.Code.Tests.CodeFixtures;

namespace Sedulous.GUI.Code.Tests;

/// Editing, with the sandbox's AngelScript, Luau and XML definitions: brackets and quotes closed as
/// typed and typed over, a selection surrounded, an empty pair or an indent's spaces deleted back;
/// Return indenting after what opens a block and a closing word outdenting; comments toggled by line
/// or by block; lines indented, moved, copied and deleted; the next occurrence added and all of
/// them; a caret added below; a column by Alt+drag; brackets matched past strings and comments; the
/// document's search; the find bar. The keys are VS Code's. An editor 400 by 240.
class CodeEditingTests
{
	[Test]
	public static void BracketsAndQuotesCloseAsTypedTheCloseTypedOverNotInAStringNotAQuoteAfterAName()
	{
		let bed = scope CodeBed("angelscript", default);
		bed.Type("f(");
		bed.CheckText("f()");
		Test.Assert(bed.Caret == At(0, 2));
		bed.Type("x)");
		bed.CheckText("f(x)"); // the close typed over the one put
		Test.Assert(bed.Caret == At(0, 4));
		bed.Type(" = \"");
		bed.CheckText("f(x) = \"\"");
		bed.Type("a(b");
		bed.CheckText("f(x) = \"a(b\""); // in a string: no pair
		bed.Editor.SetText("it");
		bed.Editor.SetCaret(At(0, 2));
		bed.Type("'");
		bed.CheckText("it'"); // a quote after a name
		// A selection and an open: surrounded.
		bed.Editor.SetText("value");
		var word = CodeSelection(At(0, 0), At(0, 5));
		bed.Editor.SetSelections(.(&word, 1));
		bed.Type("[");
		bed.CheckText("[value]");
	}

	[Test]
	public static void BackspaceTakesAnEmptyPairAndAnIndentsSpacesBackToTheStopBefore()
	{
		let bed = scope CodeBed("angelscript", default);
		bed.Type("(");
		bed.Key(.Backspace);
		bed.CheckText("");
		bed.Editor.SetText("      x");
		bed.Editor.SetCaret(At(0, 6));
		bed.Key(.Backspace);
		bed.CheckText("    x");
		bed.Key(.Backspace);
		bed.CheckText("x");
	}

	[Test]
	public static void ReturnIndentsAfterWhatOpensABlockTheCloseBelowAClosingWordOrMarkOutdentsItsLine()
	{
		let bed = scope CodeBed("angelscript", "void f()");
		bed.Editor.SetCaret(At(0, 8));
		bed.Type(" {");
		bed.CheckText("void f() {}");
		bed.Key(.Return);
		bed.CheckText("void f() {\n    \n}");
		Test.Assert(bed.Caret == At(1, 4));
		bed.Type("x;");
		bed.Key(.Return);
		bed.CheckText("void f() {\n    x;\n    \n}");
		bed.Editor.SetText("if (a) {\n    b;\n    ");
		bed.Editor.SetCaret(At(2, 4));
		bed.Type("}");
		bed.CheckText("if (a) {\n    b;\n}");

		let luau = scope CodeBed("luau", "if x then");
		luau.Editor.SetCaret(At(0, 9));
		luau.Key(.Return);
		luau.CheckText("if x then\n    ");
		luau.Type("y()");
		luau.Key(.Return);
		luau.Type("end");
		luau.CheckText("if x then\n    y()\nend");
	}

	[Test]
	public static void CtrlSlashCommentsLinesAtTheirLeastIndentAndBackMarkupByABlock()
	{
		let bed = scope CodeBed("angelscript", "    a;\n        b;\n\n    c;");
		var all = CodeSelection(At(0, 0), At(3, 6));
		bed.Editor.SetSelections(.(&all, 1));
		bed.Key(.Slash, KeyModCtrl);
		bed.CheckText("    // a;\n    //     b;\n\n    // c;");
		bed.Key(.Slash, KeyModCtrl);
		bed.CheckText("    a;\n        b;\n\n    c;");

		let markup = scope CodeBed("xml", "  <Panel/>");
		markup.Editor.SetCaret(At(0, 3));
		markup.Key(.Slash, KeyModCtrl);
		markup.CheckText("  <!-- <Panel/> -->");
		markup.Key(.Slash, KeyModCtrl);
		markup.CheckText("  <Panel/>");
	}

	[Test]
	public static void TabAndShiftTabIndentASelectionsLinesAltUpAndDownMoveThemShiftAltDownCopiesCtrlShiftKDeletes()
	{
		let bed = scope CodeBed("angelscript", "a\nb\nc\nd");
		var two = CodeSelection(At(1, 0), At(2, 1));
		bed.Editor.SetSelections(.(&two, 1));
		bed.Key(.Tab);
		bed.CheckText("a\n    b\n    c\nd");
		bed.Key(.Tab, KeyModShift);
		bed.CheckText("a\nb\nc\nd");
		bed.Key(.Up, KeyModAlt);
		bed.CheckText("b\nc\na\nd");
		Test.Assert(bed.Editor.Primary.Range == CodeRange(At(0, 0), At(1, 1)));
		bed.Key(.Down, KeyModAlt);
		bed.Key(.Down, KeyModAlt);
		bed.CheckText("a\nd\nb\nc");
		bed.Key(.Up, KeyModAlt); // back: a b c d with b, c selected
		bed.Editor.SetCaret(At(0, 0));
		bed.Key(.Down, KeyModShift | KeyModAlt);
		bed.CheckText("a\na\nb\nc\nd");
		Test.Assert(bed.Caret == At(1, 0)); // with the copy
		bed.Key(.K, KeyModCtrl | KeyModShift);
		bed.CheckText("a\nb\nc\nd");
	}

	[Test]
	public static void CtrlDSelectsTheWordThenAddsTheNextMatchRoundToTheStartCtrlShiftLAllCtrlAltDownACaretBelow()
	{
		let bed = scope CodeBed("angelscript", "int x = x + 1;\nx++;");
		bed.Editor.SetCaret(At(0, 4));
		bed.Key(.D, KeyModCtrl);
		Test.Assert(bed.Editor.Primary.Range == CodeRange(At(0, 4), At(0, 5)));
		bed.Key(.D, KeyModCtrl);
		Test.Assert(bed.Editor.Selections.Length == 2);
		Test.Assert(bed.Editor.Selections[1].Range == CodeRange(At(0, 8), At(0, 9)));
		bed.Key(.D, KeyModCtrl);
		bed.Key(.D, KeyModCtrl); // none further
		Test.Assert(bed.Editor.Selections.Length == 3);
		bed.Type("y");
		bed.CheckText("int y = y + 1;\ny++;");
		bed.Editor.SetCaret(At(1, 0));
		bed.Key(.L, KeyModCtrl | KeyModShift);
		Test.Assert(bed.Editor.Selections.Length == 3);
		bed.Editor.SetCaret(At(0, 3));
		bed.Key(.Down, KeyModCtrl | KeyModAlt);
		Test.Assert(bed.Editor.Selections.Length == 2);
		Test.Assert(bed.Editor.Selections[1].Head == At(1, 3));
	}

	[Test]
	public static void AltDragAcrossLinesSelectsAColumn()
	{
		let bed = scope CodeBed("angelscript", "alpha\nbeta\ngamma\ndelta");
		let from = bed.Over(At(0, 1));
		let to = bed.Over(At(2, 3));
		bed.D.InjectMouseMove(from, KeyModAlt);
		bed.D.InjectMouseDown(from, .Left, KeyModAlt);
		bed.D.InjectMouseMove(to, KeyModAlt);
		bed.D.InjectMouseUp(to, .Left, KeyModAlt);
		Test.Assert(bed.Editor.Selections.Length == 3);
		Test.Assert(bed.Editor.Selections[0].Range == CodeRange(At(0, 1), At(0, 3)));
		Test.Assert(bed.Editor.Selections[1].Range == CodeRange(At(1, 1), At(1, 3)));
		Test.Assert(bed.Editor.Selections[2].Range == CodeRange(At(2, 1), At(2, 3)));
	}

	[Test]
	public static void ABracketsMatchAcrossLinesPastBracketsInStringsAndComments()
	{
		let bed = scope CodeBed("angelscript", "void f() {\n    s = \"}\"; // }\n    if (a) { b(); }\n}");
		CodeRange bracket;
		CodeRange match;
		Test.Assert(bed.Editor.FindMatchingBracket(At(0, 9), out bracket, out match));
		Test.Assert(bracket == CodeRange(At(0, 9), At(0, 10)));
		Test.Assert(match == CodeRange(At(3, 0), At(3, 1)));
		Test.Assert(bed.Editor.FindMatchingBracket(At(3, 1), out bracket, out match)); // the one before the caret
		Test.Assert(match.Start == At(0, 9));
		Test.Assert(bed.Editor.FindMatchingBracket(At(2, 7), out bracket, out match));
		Test.Assert(match == CodeRange(At(2, 9), At(2, 10)));
		Test.Assert(!bed.Editor.FindMatchingBracket(At(1, 6), out bracket, out match)); // the string's
	}

	[Test]
	public static void SearchByCaseAndWholeWordAcrossLinesRoundToTheStart()
	{
		let doc = scope CodeDocument();
		doc.SetText("Value value\nvalues end\nx");
		CodeRange found;
		Test.Assert(doc.Find("value", At(0, 0), false, false, false, out found));
		Test.Assert(found == CodeRange(At(0, 0), At(0, 5)));
		Test.Assert(doc.Find("value", At(0, 0), true, false, false, out found));
		Test.Assert(found == CodeRange(At(0, 6), At(0, 11)));
		Test.Assert(doc.Find("value", At(0, 7), true, true, false, out found) == false);
		Test.Assert(doc.Find("value", At(0, 7), true, false, false, out found));
		Test.Assert(found.Start == At(1, 0)); // in "values"
		Test.Assert(doc.Find("end\nx", At(0, 0), true, false, false, out found));
		Test.Assert(found == CodeRange(At(1, 7), At(2, 1)));
		Test.Assert(doc.Find("Value", At(1, 0), true, false, true, out found));
		Test.Assert(found.Start == At(0, 0)); // round to the start
		Test.Assert(!doc.Find("Value", At(1, 0), true, false, false, out found));
	}

	[Test]
	public static void CtrlFOpensTheBarWithTheSelectionsTextF3AndShiftF3GoRoundTheMatchesCounted()
	{
		let bed = scope CodeBed("angelscript", "int count = 0;\ncount += 1; // Count\nreturn count;");
		var word = CodeSelection(At(0, 4), At(0, 9));
		bed.Editor.SetSelections(.(&word, 1));
		bed.Key(.F, KeyModCtrl);
		let bar = bed.Editor.FindBar;
		Test.Assert(bar.Displayed);
		Test.Assert(bar.Query == "count");
		Test.Assert(bar.QueryField.IsFocused);
		bed.Frame();
		Test.Assert(bed.Editor.Matches.Length == 4); // "Count" too, case folded
		Test.Assert(bed.Editor.CurrentMatch() == 1);
		Test.Assert(bar.CountLabel.Text == "1 of 4");
		bed.Key(.F3);
		Test.Assert(bed.Editor.Primary.Range == CodeRange(At(1, 0), At(1, 5)));
		Test.Assert(bar.CountLabel.Text == "2 of 4");
		bed.Key(.F3, KeyModShift);
		bed.Key(.F3, KeyModShift); // round to the last
		Test.Assert(bed.Editor.Primary.Range == CodeRange(At(2, 7), At(2, 12)));
		// Matching case: "Count" goes; whole words.
		bar.CaseToggle.HandleActivate();
		Test.Assert(bed.Editor.Matches.Length == 3);
		bar.QueryField.Text = "coun";
		Test.Assert(bed.Editor.Matches.Length == 3);
		bar.WordToggle.HandleActivate();
		Test.Assert(bed.Editor.Matches.Length == 0);
		Test.Assert(bar.CountLabel.Text == "No results");
		// Return in the field finds the next; Escape closes, the focus back in the editor.
		bar.WordToggle.HandleActivate();
		bed.Key(.Return);
		Test.Assert(bed.Editor.CurrentMatch() > 0);
		bed.Key(.Escape);
		Test.Assert(!bar.Displayed);
		Test.Assert(bed.Editor.IsFocused);
	}

	[Test]
	public static void CtrlHReplacesThisMatchAndGoesOnAllReplacesEveryOneAsOneUndoStep()
	{
		let bed = scope CodeBed("angelscript", "a = old; b = old; c = old;");
		bed.Editor.SetCaret(At(0, 0));
		bed.Key(.H, KeyModCtrl);
		let bar = bed.Editor.FindBar;
		Test.Assert(bar.GetMode() == .Replace);
		bar.QueryField.Text = "old";
		bar.ReplacementField.Text = "new";
		bed.Editor.ReplaceCurrent(); // on no match yet: finds the first
		Test.Assert(bed.Editor.CurrentMatch() == 1);
		bed.Editor.ReplaceCurrent();
		bed.CheckText("a = new; b = old; c = old;");
		Test.Assert(bed.Editor.CurrentMatch() == 1); // the next, now the first left
		let steps = bed.Editor.Document.UndoCount;
		bed.Editor.ReplaceAll();
		bed.CheckText("a = new; b = new; c = new;");
		Test.Assert(bed.Editor.Document.UndoCount == steps + 1);
		Test.Assert(bar.CountLabel.Text == "No results");
	}

	[Test]
	public static void CtrlGGoesToALineOrALineAndColumnTheBarKeepsItsPlaceAsTheCodeScrolls()
	{
		let text = scope String();
		for (int i = 0; i < 80; ++i)
			text.AppendF("line {}\n", i);
		let bed = scope CodeBed("angelscript", text);
		bed.Key(.G, KeyModCtrl);
		let bar = bed.Editor.FindBar;
		Test.Assert(bar.GetMode() == .GoToLine);
		Test.Assert(bar.LineField.Text == "1");
		bar.LineField.Model.SelectAll();
		bed.D.InjectText("60:3");
		bed.Key(.Return);
		Test.Assert(bed.Caret == At(59, 2));
		Test.Assert(!bar.Displayed);
		Test.Assert(bed.Editor.IsFocused);
		bed.Frame();
		Test.Assert(bed.Editor.ScrollOffset.Y > 0.0f);
		// Open again, scrolled: still at the top of the editor's box.
		bed.Key(.F, KeyModCtrl);
		bed.Frame();
		Test.Assert(Near(bar.ScreenBounds.Y, bed.Editor.ScreenBounds.Y + bed.Editor.ContentBounds.Y + 2.0f, 0.01f));
	}

	[Test]
	public static void GoToLineReadsEveryDigitOfTheLineAndTheColumn()
	{
		let text = scope String();
		for (int i = 0; i < 20; ++i)
			text.Append("abcdefghijklmnopqrstuvwxyz\n");
		let bed = scope CodeBed("angelscript", text);
		bed.Editor.GoToLine("12:15");
		Test.Assert(bed.Caret == At(11, 14));
		bed.Editor.GoToLine("3");
		Test.Assert(bed.Caret == At(2, 0));
		bed.Editor.GoToLine("0:4"); // no line 0: the caret stays
		Test.Assert(bed.Caret == At(2, 0));
	}
}
