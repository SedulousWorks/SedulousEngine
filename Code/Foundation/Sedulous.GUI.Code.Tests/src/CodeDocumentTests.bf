using System;
using System.Collections;
using Sedulous.GUI;
using static Sedulous.GUI.Code.Tests.CodeFixtures;

namespace Sedulous.GUI.Code.Tests;

/// The document: lines from a text and back, positions on characters' boundaries, edits across
/// lines told as the lines they replaced, anchors carried through edits by their bias, and undo as
/// transactions that put the selections back, typing within 300 ms merged into one step.
class CodeDocumentTests
{
	[Test]
	public static void LinesFromATextAndBackAnEmptyTextOneEmptyLine()
	{
		let doc = scope CodeDocument();
		Test.Assert(doc.LineCount == 1);
		Test.Assert(doc.LineText(0).Length == 0);
		doc.SetText("int a;\r\nint b;\n\nend");
		Test.Assert(doc.LineCount == 4);
		Test.Assert(doc.LineText(0) == "int a;"); // the carriage return dropped
		Test.Assert(doc.LineText(2).Length == 0);
		Test.Assert(doc.GetText(.. scope String()) == "int a;\nint b;\n\nend");
		Test.Assert(doc.End() == At(3, 3));
		Test.Assert(doc.TextIn(.(At(0, 4), At(1, 3)), .. scope String()) == "a;\nint");
		Test.Assert(doc.LineHash(0) != doc.LineHash(1)); // a hash per line
		doc.SetText("x\n");
		Test.Assert(doc.LineCount == 2); // a text ending in a line feed ends in an empty line
	}

	[Test]
	public static void PositionsStayOnCharactersAStepIsAGraphemeAcrossLinesAtTheirEnds()
	{
		let doc = scope CodeDocument();
		doc.SetText("a\u{00E9} b\ncd"); // é is two bytes
		Test.Assert(doc.Clamp(At(0, 2)) == At(0, 1)); // inside é: back to its start
		Test.Assert(doc.Clamp(At(0, 99)) == At(0, 5)); // past the line's end
		Test.Assert(doc.Clamp(At(7, 0)) == doc.End()); // past the last line
		Test.Assert(doc.NextCharacter(At(0, 1)) == At(0, 3)); // over é
		Test.Assert(doc.PreviousCharacter(At(0, 3)) == At(0, 1));
		Test.Assert(doc.NextCharacter(At(0, 5)) == At(1, 0)); // a line's end to the next's start
		Test.Assert(doc.PreviousCharacter(At(1, 0)) == At(0, 5));
		Test.Assert(doc.NextCharacter(doc.End()) == doc.End());
		Test.Assert(doc.PreviousCharacter(At(0, 0)) == At(0, 0));
	}

	[Test]
	public static void AnEditAcrossLinesReplacesThemToldAsTheLinesItReplaced()
	{
		let doc = scope CodeDocument();
		doc.SetText("one\ntwo\nthree");
		let changes = scope List<CodeChange>();
		let token = doc.AddChangeListener(new (change) => { changes.Add(change); });
		let others = scope List<CodeChange>();
		let second = doc.AddChangeListener(new (change) => { others.Add(change); });
		let version = doc.Version;
		let hash = doc.LineHash(1);
		let put = doc.Replace(.(At(0, 2), At(2, 2)), "X\r\nYY");
		Test.Assert(doc.GetText(.. scope String()) == "onX\nYYree");
		Test.Assert(put == CodeRange(At(0, 2), At(1, 2)));
		Test.Assert(changes.Count == 1);
		Test.Assert(changes[0].FirstLine == 0);
		Test.Assert(changes[0].RemovedLines == 3);
		Test.Assert(changes[0].InsertedLines == 2);
		Test.Assert(doc.Version > version);
		Test.Assert(doc.LineHash(1) != hash);
		Test.Assert(others.Count == 1); // every listener told
		doc.RemoveChangeListener(second);
		doc.RemoveChangeListener(token);

		// Given backwards, the same; removed listeners hear no more.
		doc.Erase(.(At(1, 2), At(0, 2)));
		Test.Assert(changes.Count == 1);
		Test.Assert(others.Count == 1);
		Test.Assert(doc.GetText(.. scope String()) == "onree");
		doc.Insert(At(0, 5), "\n");
		Test.Assert(doc.LineCount == 2);
		Test.Assert(doc.LineText(1).Length == 0);
	}

	[Test]
	public static void AnchorsGoWithTheTextByTheirBiasWhereTextIsPutAtThem()
	{
		let doc = scope CodeDocument();
		doc.SetText("alpha beta\ngamma");
		let before = doc.AddAnchor(At(0, 2));
		let left = doc.AddAnchor(At(0, 6), .Left);
		let right = doc.AddAnchor(At(0, 6), .Right);
		let later = doc.AddAnchor(At(0, 8));
		let below = doc.AddAnchor(At(1, 3));
		doc.Insert(At(0, 6), "new\nline ");
		Test.Assert(doc.GetAnchor(before) == At(0, 2));
		Test.Assert(doc.GetAnchor(left) == At(0, 6)); // stays before what was put
		Test.Assert(doc.GetAnchor(right) == At(1, 5)); // goes after it
		Test.Assert(doc.GetAnchor(later) == At(1, 7)); // carried with "beta"
		Test.Assert(doc.GetAnchor(below) == At(2, 3)); // a line down
		// Inside what is erased: to its start.
		doc.Erase(.(At(0, 1), At(1, 7)));
		Test.Assert(doc.GetAnchor(right) == At(0, 1));
		Test.Assert(doc.GetAnchor(later) == At(0, 1));
		Test.Assert(doc.GetText(.. scope String()) == "ata\ngamma");
		Test.Assert(doc.GetAnchor(below) == At(1, 3));
		doc.RemoveAnchor(before);
		Test.Assert(doc.AddAnchor(At(1, 0)) == before); // its slot reused
	}

	[Test]
	public static void UndoAndRedoStepByTransactionsTheSelectionsPutBack()
	{
		let doc = scope CodeDocument();
		doc.SetText("int x;");
		CodeSelection[2] beforeTwo = .(.(At(0, 0), At(0, 0)), .(At(0, 4), At(0, 5)));
		CodeSelection[2] afterTwo = .(.(At(0, 2), At(0, 2)), .(At(0, 7), At(0, 7)));
		doc.Begin(beforeTwo);
		doc.Insert(At(0, 4), "yy");
		doc.Insert(At(0, 0), "//");
		doc.End(afterTwo);
		Test.Assert(doc.GetText(.. scope String()) == "//int yyx;");
		Test.Assert(doc.UndoCount == 1);

		let selections = scope List<CodeSelection>();
		Test.Assert(doc.Undo(selections));
		Test.Assert(doc.GetText(.. scope String()) == "int x;");
		Test.Assert(selections.Count == 2);
		Test.Assert(selections[1] == beforeTwo[1]);
		Test.Assert(doc.CanRedo);
		Test.Assert(doc.Redo(selections));
		Test.Assert(doc.GetText(.. scope String()) == "//int yyx;");
		Test.Assert(selections.Count == 2);
		Test.Assert(selections[0] == afterTwo[0]);

		// An edit after an undo drops what redo had.
		Test.Assert(doc.Undo(selections));
		doc.Insert(At(0, 0), "z");
		Test.Assert(!doc.CanRedo);

		// Nested transactions are one; one with no edits is no step.
		let steps = doc.UndoCount;
		doc.Begin(default);
		doc.Begin(default);
		doc.Insert(At(0, 0), "a");
		doc.End(default);
		doc.Insert(At(0, 0), "b");
		doc.End(default);
		Test.Assert(doc.UndoCount == steps + 1);
		doc.Begin(default);
		doc.End(default);
		Test.Assert(doc.UndoCount == steps + 1);
	}

	[Test]
	public static void TypingWithin300MsMergesIntoOneStepAPauseACaretMovedOrAnotherKindBreaksIt()
	{
		let doc = scope CodeDocument();
		void TypeText(StringView text)
		{
			doc.Insert(doc.End(), text, .Typing);
			doc.AdvanceClock(0.1f);
		}
		TypeText("a");
		TypeText("b");
		TypeText("c");
		Test.Assert(doc.UndoCount == 1);
		doc.AdvanceClock(0.5f); // a pause
		TypeText("d");
		Test.Assert(doc.UndoCount == 2);
		doc.BreakMerge(); // the caret moved
		TypeText("e");
		Test.Assert(doc.UndoCount == 3);
		doc.Erase(.(At(0, 4), At(0, 5))); // deleting: a step of its own
		Test.Assert(doc.UndoCount == 4);
		let selections = scope List<CodeSelection>();
		doc.Undo(selections);
		doc.Undo(selections);
		doc.Undo(selections);
		Test.Assert(doc.GetText(.. scope String()) == "abc");
		doc.Undo(selections);
		Test.Assert(doc.GetText(.. scope String()).IsEmpty);

		doc.SetUndoLimit(2);
		for (int i = 0; i < 5; ++i)
		{
			doc.BreakMerge();
			TypeText("x");
		}
		Test.Assert(doc.UndoCount == 2);
	}
}
