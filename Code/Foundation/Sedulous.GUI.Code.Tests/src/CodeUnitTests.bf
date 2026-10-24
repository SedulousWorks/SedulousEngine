using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using static Sedulous.GUI.Code.Tests.CodeFixtures;

namespace Sedulous.GUI.Code.Tests;

/// What the scenario tests reach only on the way: the names of tokens, kinds and severities; how an
/// edit carries a position; an anchor set past the end; a whole text replaced; numbers' shapes; a
/// definition copied; the find bar's count; the editor's reflection and its element; outdenting a
/// tab, copying a line up, deleting the last line; a page through the completion list; the sheet.
class CodeUnitTests
{
	[Test]
	public static void ATokensNameReadsBackAsItAndAnUnknownNameIsText()
	{
		for (int i < (int)CodeToken.Count)
			Test.Assert(CodeTokenNamed(CodeTokenName((CodeToken)i)) == (CodeToken)i);
		Test.Assert(CodeTokenName(.Preprocessor) == "preprocessor");
		Test.Assert(CodeTokenName(.Count) == "text");
		Test.Assert(CodeTokenNamed("nope") == .Text);
	}

	[Test]
	public static void ACompletionKindHasItsNameAndItsMarkASeverityItsName()
	{
		Test.Assert(CodeCompletionKindName(.EnumMember) == "enum-member");
		Test.Assert(CodeCompletionKindName(.Count) == "text");
		Test.Assert(CodeCompletionKindMark(.Type) == "T");
		Test.Assert(CodeCompletionKindMark(.Field) == "d");
		Test.Assert(CodeSeverityName(.Warning) == "warning");
		Test.Assert(CodeSeverityName(.Hint) == "hint");
	}

	[Test]
	public static void AnEditCarriesAPositionByItsBiasWhereTextIsPutAtIt()
	{
		let put = CodeRange(At(0, 2), At(0, 2));
		Test.Assert(CodeDocument.Moved(At(0, 2), .Left, put, At(0, 5)) == At(0, 2)); // stays before what was put
		Test.Assert(CodeDocument.Moved(At(0, 2), .Right, put, At(0, 5)) == At(0, 5)); // goes after it
		Test.Assert(CodeDocument.Moved(At(0, 4), .Left, put, At(0, 5)) == At(0, 7)); // carried along its line
		Test.Assert(CodeDocument.Moved(At(1, 3), .Left, put, At(0, 5)) == At(1, 3)); // a line below, as it was
		let replaced = CodeRange(At(0, 1), At(0, 3));
		Test.Assert(CodeDocument.Moved(At(0, 2), .Left, replaced, At(0, 2)) == At(0, 1)); // inside: to its start
		Test.Assert(CodeDocument.Moved(At(0, 2), .Right, replaced, At(0, 2)) == At(0, 2)); // inside: to the new end
	}

	[Test]
	public static void AnAnchorSetPastTheEndClampsAndANewTextTakesUndoAndAnchorsToTheStart()
	{
		let doc = scope CodeDocument();
		doc.SetText("abc");
		let id = doc.AddAnchor(At(0, 1));
		doc.SetAnchor(id, At(5, 0));
		Test.Assert(doc.GetAnchor(id) == At(0, 3));
		Test.Assert(doc.GetAnchor(99) == At(0, 0)); // no such anchor
		doc.Insert(At(0, 0), "x");
		Test.Assert(doc.CanUndo);
		doc.SetText("new text");
		Test.Assert(!doc.CanUndo);
		Test.Assert(doc.UndoCount == 0);
		Test.Assert(doc.GetAnchor(id) == At(0, 0));
	}

	[Test]
	public static void NumbersTakeAFractionAnExponentAndASuffixAnEmptyHexIsNone()
	{
		let lang = CodeLanguageTests.CLike();
		defer delete lang;
		var state = CodeLexState();
		CodeLanguageTests.CheckRuns(lang, ".5 0x x 1e+5 2ull", ref state, "number:.5 text:0x text:x number:1e+5 number:2ull");
	}

	[Test]
	public static void ADefinitionCopiedTokenizesAsTheOriginalAfterItGoes()
	{
		let original = CodeLanguageTests.CLike();
		let copy = scope CodeLanguage();
		copy.Set(original);
		delete original; // the copy holds nothing of it
		Test.Assert(copy.Id == "clike");
		Test.Assert(copy.Contexts.Count == 5);
		var state = CodeLexState();
		CodeLanguageTests.CheckRuns(copy, "int x; // c", ref state, "type:int text:x punctuation:; comment:// c");
	}

	[Test]
	public static void TheFindBarCountsNothingWithoutAQueryElseNoResultsOrWhichOfHowMany()
	{
		let bar = new CodeFindBar();
		defer bar.ReleaseRef();
		bar.SetCount(1, 2);
		Test.Assert(bar.CountLabel.Text.Length == 0);
		bar.QueryField.Text = "a";
		bar.SetCount(0, 0);
		Test.Assert(bar.CountLabel.Text == "No results");
		bar.SetCount(2, 5);
		Test.Assert(bar.CountLabel.Text == "2 of 5");
		Test.Assert(!bar.Displayed); // made closed
	}

	[Test]
	public static void TheEditorReflectsItsSettingsAndTheCurrentLineAndIsAnElement()
	{
		let type = CodeEditor.StaticGuiType;
		let tabSize = type.FindCss("tab-size");
		Test.Assert((tabSize != null) && tabSize.CanWrite);
		Test.Assert(type.FindCss("read-only") != null);
		Test.Assert(type.FindCss("soft-wrap") != null);
		let access = type.Find("accessValue");
		Test.Assert((access != null) && (access.Access == "value") && !access.CanWrite);
		RegisterCodeElements();
		RegisterCodeElements(); // again: nothing
		Test.Assert(ElementTypes.Find("CodeEditor") == type);

		let bed = scope CodeBed(default, "one\ntwo");
		bed.Editor.SetCaret(At(1, 1));
		Test.Assert(bed.Editor.AccessValue == "two");
	}

	[Test]
	public static void OutdentingTakesATabAsAStopsWorthAndAnUnindentedLineKeepsIt()
	{
		let bed = scope CodeBed(default, "\t\tx");
		bed.Editor.SetCaret(At(0, 2));
		bed.Editor.IndentLines(true);
		bed.CheckText("\tx");
		bed.Editor.IndentLines(true);
		bed.CheckText("x");
		let steps = bed.Editor.Document.UndoCount;
		bed.Editor.IndentLines(true);
		bed.CheckText("x");
		Test.Assert(bed.Editor.Document.UndoCount == steps); // nothing to take: no step
	}

	[Test]
	public static void CopyingALineUpKeepsTheCaretOnTheFirstDeletingTheLastLineTakesItsLineFeed()
	{
		let bed = scope CodeBed(default, "a\nb");
		bed.Editor.SetCaret(At(0, 0));
		bed.Editor.DuplicateLines(true);
		bed.CheckText("a\na\nb");
		Test.Assert(bed.Caret == At(0, 0));
		bed.Editor.SetText("a\nb");
		bed.Editor.SetCaret(At(1, 0));
		bed.Editor.DeleteLines();
		bed.CheckText("a");
		Test.Assert(bed.Caret == At(0, 1));
	}

	[Test]
	public static void PageDownInTheListStopsAtTheLastPageUpAtTheFirst()
	{
		let bed = scope CompletionBed();
		bed.Type("p");
		Test.Assert(bed.Editor.IsCompleting);
		Test.Assert(bed.List.ShownCount == 4);
		Test.Assert(bed.Selected == "pow"); // the case matched and shortest first
		bed.Key(.PageDown);
		Test.Assert(bed.Selected == "Player"); // the last: its P not the pattern's case
		bed.Key(.PageUp);
		Test.Assert(bed.Selected == "pow");
	}

	[Test]
	public static void ALabelTooLongToWeighMatchesAsAPrefixCaseAside()
	{
		let label = scope String("ABC");
		for (int i < 127)
			label.Append("x");
		let at = scope List<uint32>();
		Test.Assert(CodeFuzzyMatch("abc", label, at) == 3);
		Test.Assert((at.Count == 3) && (at[2] == 2));
		label[0] = 'X';
		Test.Assert(CodeFuzzyMatch("abc", label) < 0);
	}

	[Test]
	public static void TheSheetColoursTokensThroughTheThemesTokens()
	{
		let css = CodeSheetCSS();
		Test.Assert(css.Contains("codeeditor::keyword { color: var(--code-keyword); }"));
		Test.Assert(css.Contains("@media (prefers-color-scheme: light)"));
	}
}
