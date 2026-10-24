using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;
using static Sedulous.GUI.Code.Tests.CodeFixtures;

namespace Sedulous.GUI.Code.Tests;

/// Folding and soft wrap, with the sandbox's definitions: ranges from brackets past strings, by
/// indentation where the language folds so, from regions, or the host's; a folded range's lines
/// hide, one row in the map the carets and the scroll share; folding moves carets out, and a caret
/// going in unfolds; folds go with their lines through edits and go when their bracket does; the
/// gutter's chevron and the placeholder; VS Code's keys. Wrapping, a long line's rows join the same
/// map, so Down, the pointer and folds go by them. Whitespace drawn by VS Code's choices.
class CodeFoldingTests
{
	private const String cScript = "void f()\n{\n    if (x)\n    {\n        y();\n    }\n    string s = \"{\";\n}\nint z;";

	private static bool HasRange(CodeEditor editor, uint32 first, uint32 last)
	{
		for (let r in editor.FoldRanges)
		{
			if ((r.First == first) && (r.Last == last))
				return true;
		}
		return false;
	}

	// A press and its release at `local` (the editor's space).
	private static void ClickAt(CodeBed bed, Float2 local)
	{
		Click(bed.D, bed.Editor.ConvertToRootSpace(local));
	}

	[Test]
	public static void RangesFromBracketsACloseFirstOnItsLineLeftOutPastStrings()
	{
		let bed = scope CodeBed("angelscript", cScript);
		Test.Assert(bed.Editor.FoldRanges.Length == 2);
		Test.Assert(HasRange(bed.Editor, 1, 6)); // the body, its close's line shown
		Test.Assert(HasRange(bed.Editor, 3, 4));
	}

	[Test]
	public static void ByIndentationWhereTheLanguageSaysTrailingBlankLinesLeftOutAndRegions()
	{
		let bed = scope CodeBed("luau", "function f()\n  if x then\n    y()\n  end\n\nend\n--#region setup\nlocal z = 1\n--#endregion");
		Test.Assert(HasRange(bed.Editor, 0, 3));
		Test.Assert(HasRange(bed.Editor, 1, 2));
		Test.Assert(HasRange(bed.Editor, 6, 8)); // through its end's line
		Test.Assert(bed.Editor.FoldRanges.Length == 3);
		let hlsl = scope CodeBed("hlsl", "#pragma region lights\nfloat3 a;\n#pragma endregion");
		Test.Assert(HasRange(hlsl.Editor, 0, 2));
	}

	[Test]
	public static void AFoldedRangesLinesHideTheRowsCloseUpUnderItDownStepsOverIt()
	{
		let bed = scope CodeBed("angelscript", cScript);
		Test.Assert(bed.Editor.RowCount == 9);
		Test.Assert(bed.Editor.Fold(1));
		Test.Assert(bed.Editor.IsFolded(1));
		Test.Assert(bed.Editor.RowCount == 4); // 2 to 6 hidden
		Test.Assert(bed.Editor.IsLineHidden(2));
		Test.Assert(bed.Editor.IsLineHidden(6));
		Test.Assert(!bed.Editor.IsLineHidden(7));
		let lh = bed.Editor.LineHeight;
		Test.Assert(Near(bed.Editor.CaretRect(At(7, 0)).Y - bed.Editor.CaretRect(At(0, 0)).Y, lh * 2.0f));
		bed.Editor.SetCaret(At(1, 1));
		bed.Key(.Down);
		Test.Assert(bed.Caret.Line == 7);
		bed.Key(.Up);
		Test.Assert(bed.Caret.Line == 1);
		// The line under a point below the fold is the one after it.
		bed.Frame();
		let row = bed.Editor.CaretRect(At(7, 0));
		Test.Assert(bed.Editor.PositionAt(.(bed.Editor.TextLeft + 1.0f, row.Y + lh * 0.5f)).Line == 7);
	}

	[Test]
	public static void CtrlShiftBracketFoldsTheInnermostRangeOpenAtTheCaretMovingItOutUnfoldsACaretGoingInUnfolds()
	{
		let bed = scope CodeBed("angelscript", cScript);
		bed.Editor.SetCaret(At(4, 3));
		bed.Key(.LeftBracket, KeyModCtrl | KeyModShift);
		Test.Assert(bed.Editor.IsFolded(3));
		Test.Assert(bed.Caret == At(3, 5)); // the end of the line it folds onto
		bed.Key(.LeftBracket, KeyModCtrl | KeyModShift);
		Test.Assert(bed.Editor.IsFolded(1)); // the next one out
		Test.Assert(bed.Caret == At(1, 1));
		bed.Key(.RightBracket, KeyModCtrl | KeyModShift);
		Test.Assert(!bed.Editor.IsFolded(1));
		Test.Assert(bed.Editor.IsFolded(3)); // only what held the caret
		bed.Editor.SetCaret(At(4, 0)); // a match found, a line gone to
		Test.Assert(!bed.Editor.IsFolded(3));
		Test.Assert(bed.Caret == At(4, 0));
	}

	[Test]
	public static void FoldsGoWithTheirLinesThroughEditsAndGoWhenTheirBracketDoes()
	{
		let bed = scope CodeBed("angelscript", cScript);
		Test.Assert(bed.Editor.Fold(3));
		bed.Editor.SetCaret(At(0, 0));
		bed.Type("\n");
		Test.Assert(bed.Editor.IsFolded(4));
		Test.Assert(!bed.Editor.IsFolded(3));
		// The open bracket deleted: no range, no fold.
		var brace = CodeSelection(At(4, 4), At(4, 5));
		bed.Editor.SetSelections(.(&brace, 1));
		bed.Key(.Delete);
		Test.Assert(!bed.Editor.IsFolded(4));
		Test.Assert(!bed.Editor.IsLineHidden(5));
	}

	[Test]
	public static void TheGuttersChevronFoldsAndUnfoldsThePlaceholderUnfolds()
	{
		let bed = scope CodeBed("angelscript", cScript);
		let lh = bed.Editor.LineHeight;
		let chevron = bed.Editor.TextLeft - 15.0f; // the fold column, before the text's gap
		ClickAt(bed, .(chevron, bed.Editor.CaretRect(At(1, 0)).Y + lh * 0.5f));
		Test.Assert(bed.Editor.IsFolded(1));
		ClickAt(bed, .(chevron, bed.Editor.CaretRect(At(1, 0)).Y + lh * 0.5f));
		Test.Assert(!bed.Editor.IsFolded(1));
		ClickAt(bed, .(chevron, bed.Editor.CaretRect(At(0, 0)).Y + lh * 0.5f)); // no range there
		Test.Assert(bed.Editor.FoldRanges.Length == 2);
		Test.Assert(bed.Editor.Fold(1));
		let end = bed.Editor.CaretRect(At(1, 1));
		ClickAt(bed, .(end.X + 12.0f, end.Y + lh * 0.5f)); // on the dots after the brace
		Test.Assert(!bed.Editor.IsFolded(1));
	}

	[Test]
	public static void CtrlKCtrl0FoldsEverythingCtrlKCtrlJUnfoldsEverything()
	{
		let bed = scope CodeBed("angelscript", cScript);
		bed.Editor.SetCaret(At(4, 0));
		bed.Key(.K, KeyModCtrl);
		bed.Key(.Num0, KeyModCtrl);
		Test.Assert(bed.Editor.IsFolded(1));
		Test.Assert(bed.Editor.IsFolded(3));
		Test.Assert(bed.Caret == At(1, 1)); // out of them all
		Test.Assert(bed.Editor.RowCount == 4);
		bed.Key(.K, KeyModCtrl);
		bed.Key(.J, KeyModCtrl);
		Test.Assert(!bed.Editor.IsFolded(1));
		Test.Assert(!bed.Editor.IsFolded(3));
		Test.Assert(bed.Editor.RowCount == 9);
	}

	[Test]
	public static void TheHostsRangesInPlaceOfTheLanguagesCarriedThroughEdits()
	{
		let bed = scope CodeBed("angelscript", cScript);
		var mine = CodeFoldRange(0, 2);
		bed.Editor.FoldRanges = .(&mine, 1);
		Test.Assert(bed.Editor.FoldRanges.Length == 1);
		Test.Assert(HasRange(bed.Editor, 0, 2));
		bed.Editor.SetCaret(At(0, 0));
		bed.Type("\n");
		Test.Assert(HasRange(bed.Editor, 1, 3));
		bed.Editor.UseLanguageFolds();
		Test.Assert(HasRange(bed.Editor, 2, 7));
	}

	[Test]
	public static void ALongLinesRowsAreRowsOfTheMapDownGoesByThemNothingScrollsAcross()
	{
		let words = scope String();
		for (int i = 0; i < 30; ++i)
			words.Append("abcd ");
		words.Append("\nend");
		let bed = scope CodeBed("angelscript", default);
		bed.Editor.SetText(words);
		bed.Frame();
		Test.Assert(bed.Editor.RowCount == 2);
		bed.Key(.Z, KeyModAlt);
		Test.Assert(bed.Editor.SoftWrap);
		bed.Frame();
		let rows = bed.Editor.RowCount - 1; // the long line's
		Test.Assert(rows >= 3);
		let lh = bed.Editor.LineHeight;
		let top = bed.Editor.CaretRect(At(0, 0));
		Test.Assert(Near(bed.Editor.CaretRect(At(1, 0)).Y - top.Y, lh * (float)rows));
		// Down from near the start: the line's second row, as far across.
		bed.Editor.SetCaret(At(0, 2));
		bed.Key(.Down);
		Test.Assert(bed.Caret.Line == 0);
		let second = bed.Editor.CaretRect(bed.Caret);
		Test.Assert(Near(second.Y - top.Y, lh));
		Test.Assert(Near(second.X, bed.Editor.CaretRect(At(0, 2)).X, 0.03f));
		// The pointer on the second row finds the line's place there.
		let hit = bed.Editor.PositionAt(.(bed.Editor.TextLeft + 1.0f, top.Y + lh * 1.5f));
		Test.Assert(hit.Line == 0);
		Test.Assert(hit.Column > 0);
		Test.Assert(Near(bed.Editor.CaretRect(hit).Y - top.Y, lh));
		bed.Key(.End);
		bed.Frame();
		Test.Assert(Near(bed.Editor.ScrollOffset.X, 0.0f)); // never across
		// Narrower: more rows.
		bed.Editor.EditLayoutStyle(scope (s) => { s.Width = LayoutLength.Px(200.0f); });
		bed.Frame();
		Test.Assert(bed.Editor.RowCount - 1 > rows);
	}

	[Test]
	public static void AWordLongerThanARowBreaksAFoldHidesEveryRowOfWhatItHolds()
	{
		let text = scope String("{\n");
		for (int i = 0; i < 100; ++i)
			text.Append("x");
		text.Append("\n}");
		let bed = scope CodeBed("angelscript", default);
		bed.Editor.SetText(text);
		bed.Editor.SoftWrap = true;
		bed.Frame();
		Test.Assert(bed.Editor.RowCount == 4); // the hundred in two rows
		Test.Assert(bed.Editor.Fold(0));
		Test.Assert(bed.Editor.RowCount == 2);
		bed.Editor.SoftWrap = false;
		bed.Frame();
		Test.Assert(bed.Editor.RowCount == 2);
		bed.Editor.UnfoldAll();
		Test.Assert(bed.Editor.RowCount == 3);
	}

	[Test]
	public static void WhitespaceDrawnByTheChoiceAllALinesEndAllButASingleSpaceBetweenWordsTheSelections()
	{
		let bed = scope CodeBed("angelscript", "  a b  c\t\nx y  ");
		bool Shows(uint32 line, uint32 column) => bed.Editor.ShowsWhitespaceAt(At(line, column));
		Test.Assert(!Shows(0, 0)); // none by default
		bed.Editor.ShowWhitespace = .All;
		Test.Assert(Shows(0, 0));
		Test.Assert(Shows(0, 3));
		Test.Assert(Shows(0, 8)); // the tab
		Test.Assert(!Shows(0, 2)); // a letter
		bed.Editor.ShowWhitespace = .Trailing;
		Test.Assert(Shows(1, 3));
		Test.Assert(Shows(1, 4));
		Test.Assert(!Shows(1, 1));
		Test.Assert(Shows(0, 8));
		Test.Assert(!Shows(0, 5));
		bed.Editor.ShowWhitespace = .Boundary;
		Test.Assert(Shows(0, 0)); // the indent
		Test.Assert(Shows(0, 1));
		Test.Assert(!Shows(0, 3)); // one between words
		Test.Assert(Shows(0, 5)); // a run
		Test.Assert(Shows(0, 6));
		Test.Assert(Shows(0, 8));
		bed.Editor.ShowWhitespace = .Selection;
		var some = CodeSelection(At(0, 0), At(0, 4));
		bed.Editor.SetSelections(.(&some, 1));
		Test.Assert(Shows(0, 1));
		Test.Assert(Shows(0, 3));
		Test.Assert(!Shows(0, 5));
	}

	[Test]
	public static void ItDrawsWrappedFoldedWithItsWhitespaceASelectionAcrossRowsAndTheChevrons()
	{
		let text = scope String("void f()\n{\n\tint a = 1;   \n");
		for (int i = 0; i < 40; ++i)
			text.Append("word ");
		text.Append("\n}\n");
		let bed = scope CodeBed("angelscript", default);
		bed.Editor.SetText(text);
		bed.Editor.SoftWrap = true;
		bed.Editor.ShowWhitespace = .All;
		bed.Frame();
		var across = CodeSelection(At(2, 2), At(3, 120));
		bed.Editor.SetSelections(.(&across, 1));
		bed.D.InjectMouseMove(bed.Editor.ConvertToRootSpace(.(2.0f, 20.0f))); // the gutter: chevrons
		bed.Frame();
		let canvas = scope VGContext();
		{
			let ctx = scope DrawContext(canvas);
			bed.Root.Draw(ctx);
		}
		Test.Assert(bed.Editor.Fold(1));
		bed.Editor.SetCaret(At(0, 4));
		bed.Frame();
		{
			let ctx = scope DrawContext(canvas);
			bed.Root.Draw(ctx);
		}
		Test.Assert(bed.Editor.RowCount == 4); // the function's line, the brace's, the close's, the end
	}
}
