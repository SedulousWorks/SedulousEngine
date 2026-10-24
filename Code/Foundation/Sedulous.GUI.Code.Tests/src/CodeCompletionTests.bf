using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using static Sedulous.GUI.Code.Tests.CodeFixtures;

namespace Sedulous.GUI.Code.Tests;

/// The language service, with a service of the test's own over the sandbox's AngelScript: the fuzzy
/// match and its order; a name typed opens the list, more letters filter it, Up and Down go round
/// it, Return and Tab put the pick in place of the word at each caret as one undo step, Escape or
/// the caret leaving the word closes it; a trigger opens it on no word; not by typing in a comment,
/// though Ctrl+Space opens it there; a click picks a row, the focus kept in the editor; the list
/// sits below the word, its label lined up with it; the service's word under the pointer joins the
/// tooltip.
class CodeCompletionTests
{
	[Test]
	public static void TheFuzzyMatchTakesTheLettersInOrderFromAWordsStartScoringTheStartRunsAndCase()
	{
		let at = scope List<uint32>();
		Test.Assert(CodeFuzzyMatch("gpos", "GetPosition", at) >= 0);
		Test.Assert(at.Count == 4);
		Test.Assert(at[0] == 0);
		Test.Assert(at[1] == 3); // the P of Position, a word's start
		Test.Assert(at[3] == 5);
		Test.Assert(CodeFuzzyMatch("xyz", "GetPosition") < 0);
		Test.Assert(CodeFuzzyMatch("et", "GetPosition") < 0); // its first letter inside a word
		Test.Assert(CodeFuzzyMatch("pos", "get_position") >= 0); // after an underscore
		Test.Assert(CodeFuzzyMatch("pos", "position") > CodeFuzzyMatch("pos", "getPosition"));
		Test.Assert(CodeFuzzyMatch("pos", "position") > CodeFuzzyMatch("pos", "pOrderSet"));
		Test.Assert(CodeFuzzyMatch("Pos", "Position") > CodeFuzzyMatch("Pos", "position"));
		Test.Assert(CodeFuzzyMatch("", "anything") == 0);
	}

	[Test]
	public static void ANameTypedOpensTheListMoreLettersFilterItUpAndDownGoRoundReturnPutsThePickInOneUndoStep()
	{
		let bed = scope CompletionBed();
		bed.Type("p");
		Test.Assert(bed.Editor.IsCompleting);
		Test.Assert(bed.Service.Asked == 1);
		Test.Assert(bed.Service.Last.WordStart == At(0, 0));
		Test.Assert(!bed.Service.Last.Invoked);
		Test.Assert(bed.List.ShownCount == 4); // Player's P too, case aside
		bed.Type("o");
		Test.Assert(bed.Service.Asked == 1); // filtered, not asked again
		Test.Assert(bed.List.ShownCount == 2);
		Test.Assert(bed.Shown(0) == "pow"); // as good a match, and shorter
		Test.Assert(bed.Shown(1) == "position");
		Test.Assert(bed.Selected == "pow");
		bed.Key(.Down);
		Test.Assert(bed.Selected == "position");
		Test.Assert(bed.Caret == At(0, 2)); // the caret stays
		bed.Key(.Down);
		Test.Assert(bed.Selected == "pow"); // round
		bed.Key(.Up);
		Test.Assert(bed.Selected == "position");
		bed.Key(.Return);
		bed.CheckText("position");
		Test.Assert(bed.Caret == At(0, 8));
		Test.Assert(!bed.Editor.IsCompleting);
		bed.Key(.Return); // the editor's own again
		bed.CheckText("position\n");
		bed.Key(.Z, KeyModCtrl);
		bed.Key(.Z, KeyModCtrl);
		bed.CheckText("po"); // the pick, one step
	}

	[Test]
	public static void EscapeTheCaretLeavingTheWordOrNoMatchClosesItANumberNeverOpensIt()
	{
		let bed = scope CompletionBed("x = ");
		bed.Editor.SetCaret(At(0, 4));
		bed.Type("pr");
		Test.Assert(bed.Editor.IsCompleting);
		bed.Key(.Escape);
		Test.Assert(!bed.Editor.IsCompleting);
		bed.CheckText("x = pr");
		bed.Editor.SetCaret(At(0, 6));
		Test.Assert(bed.Editor.TriggerCompletion(true));
		bed.Key(.Left);
		Test.Assert(bed.Editor.IsCompleting); // still in the word: "p"
		bed.Key(.Left);
		Test.Assert(!bed.Editor.IsCompleting); // before it
		bed.Editor.SetCaret(At(0, 6));
		bed.Type("i");
		Test.Assert(bed.Editor.IsCompleting);
		bed.Type("q");
		Test.Assert(!bed.Editor.IsCompleting); // "priq" matches nothing
		bed.Editor.SetText("");
		bed.Type("1");
		Test.Assert(!bed.Editor.IsCompleting);
	}

	[Test]
	public static void ATriggerOpensItOnNoWordInTheServicesOrderTypingInACommentDoesNotCtrlSpaceDoes()
	{
		let bed = scope CompletionBed();
		bed.Type("a.");
		Test.Assert(bed.Editor.IsCompleting);
		Test.Assert(bed.Service.Last.Trigger == '.');
		Test.Assert(bed.Service.Last.WordStart == At(0, 2));
		Test.Assert(bed.List.ShownCount == 4);
		Test.Assert(bed.Shown(0) == "position");
		Test.Assert(bed.Shown(3) == "Player");
		bed.Key(.Escape);
		bed.Editor.SetText("// ");
		bed.Editor.SetCaret(At(0, 3));
		bed.Type("po");
		Test.Assert(!bed.Editor.IsCompleting);
		bed.Key(.Space, KeyModCtrl);
		Test.Assert(bed.Editor.IsCompleting);
		Test.Assert(bed.Service.Last.Invoked);
	}

	[Test]
	public static void TabAcceptsTooAtEveryCaretOnTheSameWord()
	{
		let bed = scope CompletionBed("a\nb");
		bed.Editor.SetCaret(At(0, 1));
		bed.Editor.AddCaret(At(1, 1));
		bed.Type(" pri");
		Test.Assert(bed.Editor.IsCompleting);
		Test.Assert(bed.Selected == "print");
		bed.Key(.Tab);
		bed.CheckText("a print\nb print");
		Test.Assert(!bed.Editor.IsCompleting);
	}

	[Test]
	public static void TheListSitsBelowTheWordItsLabelLinedUpAClickPicksARowAndTheEditorKeepsTheFocus()
	{
		let bed = scope CompletionBed("  ");
		bed.Editor.SetCaret(At(0, 2));
		bed.Type("p");
		Test.Assert(bed.Editor.IsCompleting);
		bed.Frame();
		let list = bed.List;
		Test.Assert(bed.D.IsPopupOpen(list));
		let word = bed.Editor.CaretRect(At(0, 2));
		let wordAt = bed.Editor.ConvertToRootSpace(.(word.X, word.Y + word.Height));
		let listAt = list.ConvertToRootSpace(.(0.0f, 0.0f));
		Test.Assert(Near(listAt.X + list.LabelInset, wordAt.X));
		Test.Assert(listAt.Y >= wordAt.Y);
		// The second row: print.
		let y = listAt.Y + list.ContentBounds.Y + list.RowHeight * 1.5f;
		bed.D.InjectMouseDown(.(listAt.X + 20.0f, y), .Left);
		bed.D.InjectMouseUp(.(listAt.X + 20.0f, y), .Left);
		bed.CheckText("  print");
		Test.Assert(!bed.Editor.IsCompleting);
		Test.Assert(bed.Editor.IsFocused);
		// A press in the code closes it, and places the caret as ever.
		bed.Type("\np");
		Test.Assert(bed.Editor.IsCompleting);
		bed.D.InjectMouseDown(bed.Editor.ConvertToRootSpace(.(bed.Editor.TextLeft + 1.0f, bed.Editor.CaretRect(At(0, 0)).Y + 2.0f)), .Left);
		Test.Assert(!bed.Editor.IsCompleting);
		Test.Assert(bed.Caret == At(0, 0));
	}

	[Test]
	public static void WhatTheServiceSaysOfTheWordUnderThePointerJoinsItsTooltipAskedOncePerWord()
	{
		let bed = scope CompletionBed("position = 1;");
		void Over(uint32 column)
		{
			let caret = bed.Editor.CaretRect(At(0, column));
			bed.D.InjectMouseMove(bed.Editor.ConvertToRootSpace(.(caret.X + 3.0f, caret.Y + 4.0f)));
		}
		Over(2);
		Test.Assert(bed.Editor.TooltipText == "Float3 position");
		Over(4);
		Test.Assert(bed.Editor.TooltipText == "Float3 position");
		Test.Assert(bed.Service.Hovered == 1); // the same word
		Over(12); // the semicolon: no word
		Test.Assert(bed.Editor.TooltipText.Length == 0);
		let end = bed.Editor.CaretRect(At(0, 13));
		bed.D.InjectMouseMove(bed.Editor.ConvertToRootSpace(.(end.X + 60.0f, end.Y + 4.0f)));
		Test.Assert(bed.Editor.TooltipText.Length == 0); // past the line's end
	}
}
