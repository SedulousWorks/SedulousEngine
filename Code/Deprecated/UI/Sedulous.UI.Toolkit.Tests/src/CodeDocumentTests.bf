using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// The code editor's model: lines, positions, editing, undo, search, brackets and the anchors
/// that have to survive an edit.
class CodeDocumentTests
{
	private static CodeDocument MakeDoc(StringView text)
	{
		let doc = new CodeDocument();
		doc.SetText(text);
		return doc;
	}

	private static void AssertText(CodeDocument doc, StringView expected)
	{
		let text = scope String();
		doc.GetText(text);
		Test.Assert(text == expected, scope $"expected \"{expected}\", got \"{text}\"");
	}

	/// One keystroke, the way the widget drives an edit.
	private static CodePosition Type(CodeDocument doc, CodePosition at, StringView ch, double time)
		=> doc.Edit(.(at, at), ch, .Typing, .(at, at), time);

	// ---- Content --------------------------------------------------------------------------------

	[Test]
	public static void ADocumentIsNeverEmptyOfLines()
	{
		let doc = scope CodeDocument();

		Test.Assert(doc.LineCount == 1, "one empty line IS an empty document");
		Test.Assert(doc.Line(0).IsEmpty);
		AssertText(doc, "");
	}

	/// A carriage return is DROPPED, so a file saved on another platform leaves no invisible
	/// character at the end of every line.
	[Test]
	public static void SetTextSplitsOnNewlinesAndDropsCarriageReturns()
	{
		let doc = scope CodeDocument();

		doc.SetText("alpha\nbeta\r\ngamma");
		Test.Assert(doc.LineCount == 3);
		Test.Assert(doc.Line(0) == "alpha");
		Test.Assert(doc.Line(1) == "beta");
		Test.Assert(doc.Line(2) == "gamma");
		AssertText(doc, "alpha\nbeta\ngamma");

		// A trailing newline leaves a final EMPTY line, which is what a text file with one
		// actually contains.
		doc.SetText("one\n");
		Test.Assert(doc.LineCount == 2);
		Test.Assert(doc.Line(1).IsEmpty);
	}

	/// Columns count CODEPOINTS while the buffer holds bytes, so a two byte character is one
	/// column and the conversion has to know the difference.
	[Test]
	public static void ColumnsCountCodepointsNotBytes()
	{
		let doc = MakeDoc("h\u{00E9}llo");
		defer delete doc;

		Test.Assert(doc.LineLength(0) == 5, "five characters, six bytes");
		Test.Assert(doc.ColumnToByte(0, 1) == 1);
		Test.Assert(doc.ColumnToByte(0, 2) == 3, "past the two byte character");
		Test.Assert(doc.ByteToColumn(0, 3) == 2);
		Test.Assert(doc.ByteToColumn(0, 999) == 5, "and it clamps");

		Test.Assert(doc.ClampPosition(.(0, 99)).Column == 5);
		Test.Assert(doc.ClampPosition(.(99, 0)) == doc.EndPosition);
	}

	[Test]
	public static void TextInSpanReadsAcrossLinesAndNormalises()
	{
		let doc = MakeDoc("alpha\nbeta\ngamma");
		defer delete doc;

		let oneLine = scope String();
		doc.GetTextInSpan(.(.(0, 1), .(0, 4)), oneLine);
		Test.Assert(oneLine == "lph");

		let manyLines = scope String();
		doc.GetTextInSpan(.(.(0, 3), .(2, 2)), manyLines);
		Test.Assert(manyLines == "ha\nbeta\nga");

		// A selection dragged leftwards has its ends the other way round.
		let reversed = scope String();
		doc.GetTextInSpan(.(.(2, 2), .(0, 3)), reversed);
		Test.Assert(reversed == "ha\nbeta\nga");
	}

	// ---- Editing --------------------------------------------------------------------------------

	[Test]
	public static void AnEditSplitsAndJoinsLines()
	{
		let doc = MakeDoc("alpha\ngamma");
		defer delete doc;

		let end = doc.Edit(.(.(0, 5), .(0, 5)), "\nbeta", .Paste, .(), 0.0);
		Test.Assert(doc.LineCount == 3);
		AssertText(doc, "alpha\nbeta\ngamma");
		Test.Assert(end == CodePosition(1, 4), "the cursor lands past what was inserted");

		// A delete spanning lines JOINS them.
		doc.Edit(.(.(0, 3), .(2, 2)), "", .Delete, .(), 1.0);
		Test.Assert(doc.LineCount == 1);
		AssertText(doc, "alpmma");
	}

	// ---- Undo -----------------------------------------------------------------------------------

	/// A run of typing is ONE undo step, which is what makes undo useful rather than a letter
	/// at a time.
	[Test]
	public static void TypingCoalescesIntoOneUndoEntry()
	{
		let doc = scope CodeDocument();

		var cursor = CodePosition(0, 0);
		cursor = Type(doc, cursor, "a", 0.0);
		cursor = Type(doc, cursor, "b", 0.2);
		cursor = Type(doc, cursor, "c", 0.4);
		AssertText(doc, "abc");

		Test.Assert(doc.Undo(let state));
		AssertText(doc, "");
		Test.Assert(state.Cursor == CodePosition(0, 0));
		Test.Assert(!doc.CanUndo, "all three keystrokes, one entry");

		Test.Assert(doc.Redo(let redone));
		AssertText(doc, "abc");
		Test.Assert(redone.Cursor == CodePosition(0, 3));
	}

	/// Four different reasons a run stops merging, each of which a user experiences as a
	/// boundary they expect to undo back to.
	[Test]
	public static void FourThingsBreakTheUndoChain()
	{
		// A gap in TIME.
		let byTime = scope CodeDocument();
		var cursor = Type(byTime, .(0, 0), "a", 0.0);
		Type(byTime, cursor, "b", 5.0);
		Test.Assert(byTime.Undo(let ignored1));
		AssertText(byTime, "a");

		// A change of KIND.
		let byKind = scope CodeDocument();
		cursor = Type(byKind, .(0, 0), "a", 0.0);
		byKind.Edit(.(cursor, cursor), "\n", .Newline, .(cursor, cursor), 0.1);
		Test.Assert(byKind.Undo(let ignored2));
		AssertText(byKind, "a");

		// An EXPLICIT break, which the view raises on navigation, focus loss and save.
		let byBreak = scope CodeDocument();
		cursor = Type(byBreak, .(0, 0), "a", 0.0);
		byBreak.BreakUndoChain();
		Type(byBreak, cursor, "b", 0.1);
		Test.Assert(byBreak.Undo(let ignored3));
		AssertText(byBreak, "a");

		// Typing somewhere ELSE.
		let byPlace = scope CodeDocument();
		Type(byPlace, .(0, 0), "a", 0.0);
		Type(byPlace, .(0, 0), "x", 0.1);
		Test.Assert(byPlace.Undo(let ignored4));
		AssertText(byPlace, "a");
	}

	/// Backspace runs RIGHT TO LEFT, so contiguity is the new end meeting the old beginning
	/// rather than the other way round.
	[Test]
	public static void BackspaceCoalescesBackwards()
	{
		let doc = MakeDoc("abc");
		defer delete doc;

		doc.Edit(.(.(0, 2), .(0, 3)), "", .Backspace, .(.(0, 3), .(0, 3)), 0.0);
		doc.Edit(.(.(0, 1), .(0, 2)), "", .Backspace, .(.(0, 2), .(0, 2)), 0.2);
		AssertText(doc, "a");

		Test.Assert(doc.Undo(let state));
		AssertText(doc, "abc");
		Test.Assert(state.Cursor == CodePosition(0, 3));
		Test.Assert(!doc.CanUndo);
	}

	/// A new edit INVALIDATES the redo stack: the future it described no longer follows from
	/// the present.
	[Test]
	public static void ANewEditClearsTheRedoStack()
	{
		let doc = scope CodeDocument();

		Type(doc, .(0, 0), "a", 0.0);
		Test.Assert(doc.Undo(let ignored));
		Test.Assert(doc.CanRedo);

		Type(doc, .(0, 0), "z", 9.0);
		Test.Assert(!doc.CanRedo);
	}

	/// A compound bracket makes any number of edits one undo step, which is what a replace-all
	/// needs.
	[Test]
	public static void ACompoundEditIsOneUndoEntry()
	{
		let doc = MakeDoc("aa bb aa");
		defer delete doc;

		doc.BeginCompoundEdit();
		doc.Edit(.(.(0, 6), .(0, 8)), "XX", .Other, .(), 0.0);
		doc.Edit(.(.(0, 0), .(0, 2)), "XX", .Other, .(), 0.0);
		doc.EndCompoundEdit();
		AssertText(doc, "XX bb XX");

		Test.Assert(doc.Undo(let state));
		AssertText(doc, "aa bb aa");
		Test.Assert(!doc.CanUndo, "both reverted together");

		Test.Assert(doc.Redo(let redone));
		AssertText(doc, "XX bb XX");
	}

	// ---- Anchors --------------------------------------------------------------------------------

	/// A breakpoint has to follow its line through an edit, or it points at something else.
	[Test]
	public static void MarkersFollowTheirLineThroughEdits()
	{
		// Inserting ABOVE pushes it down.
		let above = MakeDoc("a\nb\nc\nd");
		defer delete above;
		above.SetMarker(2, .Breakpoint);
		above.Edit(.(.(0, 1), .(0, 1)), "\nnew", .Paste, .(), 0.0);
		Test.Assert((above.MarkersOn(3) & .Breakpoint) != .None);
		Test.Assert(above.MarkersOn(2) == .None);

		// Deleting above pulls it up.
		let deleted = MakeDoc("a\nb\nc\nd");
		defer delete deleted;
		deleted.SetMarker(2, .Breakpoint);
		deleted.Edit(.(.(0, 0), .(1, 0)), "", .Delete, .(), 0.0);
		Test.Assert((deleted.MarkersOn(1) & .Breakpoint) != .None);

		// Deleting the marker's OWN line takes it with it.
		let swallowed = MakeDoc("a\nb\nc\nd");
		defer delete swallowed;
		swallowed.SetMarker(2, .Breakpoint);
		swallowed.Edit(.(.(1, 0), .(2, 1)), "", .Delete, .(), 0.0);
		let lines = scope List<int32>();
		swallowed.CollectMarkerLines(.Breakpoint, lines);
		Test.Assert(lines.IsEmpty);

		// An edit BELOW leaves it alone.
		let below = MakeDoc("a\nb\nc\nd");
		defer delete below;
		below.SetMarker(2, .Breakpoint);
		below.Edit(.(.(3, 0), .(3, 1)), "x", .Typing, .(), 0.0);
		Test.Assert((below.MarkersOn(2) & .Breakpoint) != .None);
	}

	[Test]
	public static void MarkersToggleAndCollectInOrder()
	{
		let doc = MakeDoc("a\nb\nc");
		defer delete doc;

		Test.Assert(doc.ToggleMarker(2, .Breakpoint));
		Test.Assert(doc.ToggleMarker(0, .Breakpoint));
		Test.Assert(!doc.ToggleMarker(2, .Breakpoint), "and back off again");

		let lines = scope List<int32>();
		doc.CollectMarkerLines(.Breakpoint, lines);
		Test.Assert(lines.Count == 1);
		Test.Assert(lines[0] == 0);

		// A line that does not exist cannot carry one.
		doc.SetMarker(99, .Breakpoint);
		doc.CollectMarkerLines(.Breakpoint, lines);
		Test.Assert(lines.Count == 1);
	}

	/// Errors, warnings and the execution line are DERIVED, and reach the gutter through the
	/// same mask as the markers set by hand.
	[Test]
	public static void DiagnosticsAndTheExecutionLineReachTheGutter()
	{
		let doc = MakeDoc("a\nb\nc\nd");
		defer delete doc;

		let diagnostics = new List<CodeDiagnostic>();
		diagnostics.Add(new CodeDiagnostic(true, 1, "boom"));
		diagnostics.Add(new CodeDiagnostic(false, 3, "meh"));
		doc.SetDiagnostics(diagnostics);
		doc.SetExecutionLine(2);

		Test.Assert((doc.MarkersOn(1) & .Error) != .None);
		Test.Assert((doc.MarkersOn(3) & .Warning) != .None);
		Test.Assert((doc.MarkersOn(2) & .ExecutionLine) != .None);
		Test.Assert(doc.DiagnosticOn(1) != null);
		Test.Assert(doc.DiagnosticOn(1).Message == "boom");
		Test.Assert(doc.DiagnosticOn(0) == null);

		// They shift with an edit above, like markers do.
		doc.Edit(.(.(0, 0), .(0, 0)), "top\n", .Paste, .(), 0.0);
		Test.Assert((doc.MarkersOn(2) & .Error) != .None);
		Test.Assert(doc.ExecutionLine == 3);

		// And deleting the executing line CLEARS it rather than moving it somewhere arbitrary.
		doc.Edit(.(.(2, 0), .(3, 1)), "", .Delete, .(), 1.0);
		Test.Assert(doc.ExecutionLine == -1);
	}

	/// A reload is a NEW document as far as anchors go: a breakpoint from the old contents
	/// would point at something unrelated.
	[Test]
	public static void AReloadDropsEveryAnchor()
	{
		let doc = MakeDoc("a\nb\nc");
		defer delete doc;

		doc.SetMarker(1, .Breakpoint);
		doc.SetExecutionLine(2);
		Type(doc, .(0, 0), "x", 0.0);
		Test.Assert(doc.CanUndo);

		doc.SetText("completely\ndifferent");
		Test.Assert(doc.MarkersOn(1) == .None);
		Test.Assert(doc.ExecutionLine == -1);
		Test.Assert(!doc.CanUndo);
	}

	// ---- Words ----------------------------------------------------------------------------------

	[Test]
	public static void WordBoundariesStopBetweenClasses()
	{
		let doc = MakeDoc("foo bar_baz(qux)");
		defer delete doc;

		Test.Assert(doc.NextWordBoundary(.(0, 0)) == CodePosition(0, 4), "past foo and its space");
		Test.Assert(doc.NextWordBoundary(.(0, 4)) == CodePosition(0, 11), "past bar_baz");
		Test.Assert(doc.PrevWordBoundary(.(0, 11)) == CodePosition(0, 4));
		Test.Assert(doc.PrevWordBoundary(.(0, 4)) == CodePosition(0, 0));

		let word = doc.WordAt(.(0, 6));
		Test.Assert(word.Begin == CodePosition(0, 4));
		Test.Assert(word.End == CodePosition(0, 11));

		// At the END of a word it still finds it, which is where a double click and a
		// completion prefix both land.
		Test.Assert(doc.WordAt(.(0, 3)).Begin == CodePosition(0, 0));
		Test.Assert(doc.WordAt(.(0, 16)).IsEmpty, "a bracket to the left is not a word");
	}

	[Test]
	public static void WordBoundariesCrossLines()
	{
		let doc = MakeDoc("foo\nbar");
		defer delete doc;

		Test.Assert(doc.NextWordBoundary(.(0, 3)) == CodePosition(1, 0));
		Test.Assert(doc.PrevWordBoundary(.(1, 0)) == CodePosition(0, 3));
	}

	/// The completion provider that offers what is already in the file.
	[Test]
	public static void TheWordHarvestIsDistinctAndSkipsNumbers()
	{
		let doc = MakeDoc("var count = 10\nfn update(count, delta_time)\n");
		defer delete doc;

		let words = scope List<StringView>();
		doc.GetWords(words);

		Test.Assert(words.Contains("var"));
		Test.Assert(words.Contains("count"));
		Test.Assert(words.Contains("update"));
		Test.Assert(words.Contains("delta_time"));
		Test.Assert(!words.Contains("10"), "a number is not an identifier");

		var countHits = 0;
		for (let word in words)
		{
			if (word == "count")
				countHits++;
		}
		Test.Assert(countHits == 1, "the same word twice is harvested once");

		// The cache follows the VERSION, so an edit is picked up.
		doc.Edit(.(.(2, 0), .(2, 0)), "newWord", .Typing, .(), 0.0);
		let after = scope List<StringView>();
		doc.GetWords(after);
		Test.Assert(after.Contains("newWord"));
	}

	// ---- Search ---------------------------------------------------------------------------------

	[Test]
	public static void FindAllHonoursCaseAndWordBounds()
	{
		let doc = MakeDoc("Count count\ncounter\nno match here");
		defer delete doc;

		let matches = scope List<CodeSpan>();

		doc.FindAll("count", false, false, matches);
		Test.Assert(matches.Count == 3, "Count, count, and counter's prefix");
		Test.Assert(matches[0].Begin == CodePosition(0, 0));
		Test.Assert(matches[1].Begin == CodePosition(0, 6));
		Test.Assert(matches[2].Begin == CodePosition(1, 0));

		doc.FindAll("count", true, false, matches);
		Test.Assert(matches.Count == 2, "case sensitivity drops Count");

		doc.FindAll("count", false, true, matches);
		Test.Assert(matches.Count == 2, "whole word drops counter");
	}

	/// Matches do not OVERLAP, which is what makes a replace-all well defined.
	[Test]
	public static void MatchesDoNotOverlap()
	{
		let doc = MakeDoc("aaaa");
		defer delete doc;

		let matches = scope List<CodeSpan>();
		doc.FindAll("aaa", true, false, matches);
		Test.Assert(matches.Count == 1);

		doc.FindAll("", true, false, matches);
		Test.Assert(matches.IsEmpty, "an empty query matches nothing, not everything");
	}

	// ---- Brackets -------------------------------------------------------------------------------

	[Test]
	public static void BracketsMatchAcrossLinesAndNesting()
	{
		let doc = MakeDoc("fn(a, [b {\nnested}\n])");
		defer delete doc;

		Test.Assert(doc.FindMatchingBracket(.(0, 2), let closing));
		Test.Assert(closing == CodePosition(2, 1), "past the nested pairs between them");

		Test.Assert(doc.FindMatchingBracket(.(2, 1), let opening));
		Test.Assert(opening == CodePosition(0, 2), "and the same backwards");

		Test.Assert(doc.FindMatchingBracket(.(0, 9), let brace));
		Test.Assert(brace == CodePosition(1, 6), "across the line break");
	}

	[Test]
	public static void ANonBracketAndAnUnmatchedOneBothFail()
	{
		let doc = MakeDoc("fn(a)");
		defer delete doc;
		Test.Assert(!doc.FindMatchingBracket(.(0, 0), let ignored1));

		let unmatched = MakeDoc("(((");
		defer delete unmatched;
		Test.Assert(!unmatched.FindMatchingBracket(.(0, 0), let ignored2));
	}

	// ---- Notification ---------------------------------------------------------------------------

	[Test]
	public static void LineChangesAreReportedWithTheirShape()
	{
		let doc = MakeDoc("a\nb\nc");
		defer delete doc;

		var first = -99;
		var removed = -99;
		var added = -99;
		doc.OnLinesChanged = new [&added, &first, &removed](f, r, a) =>
			{
				first = f;
				removed = r;
				added = a;
			};

		doc.Edit(.(.(1, 0), .(1, 0)), "x\ny", .Paste, .(), 0.0);
		Test.Assert(first == 1);
		Test.Assert(removed == 1);
		Test.Assert(added == 2);

		// A reload reports minus one removed, which is the signal for "everything".
		doc.SetText("z");
		Test.Assert(first == 0);
		Test.Assert(removed == -1);
		Test.Assert(added == 1);
	}
}
