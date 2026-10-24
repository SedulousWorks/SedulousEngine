using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A view's lines for the model, recording what it was asked: every line is bytes 2 to 6, a move
/// goes ten bytes a line, and a goal not yet set becomes 5.
class FakeTextLines : ITextLines
{
	public int32 LastLines = 0;
	public float LastGoal = 0.0f;

	public TextRange LineAt(int offset) => .(2, 6);

	public int OffsetByLines(int offset, int32 lines, ref float goalX)
	{
		LastLines = lines;
		if (goalX < 0.0f)
			goalX = 5.0f;
		LastGoal = goalX;
		return offset + lines * 10;
	}

	public int32 LinesPerPage => 3;
}

/// What the text slice does that its ported tests leave unchecked: mnemonics and the case folding
/// type-ahead matches by, a font-family list's families, runs merging and collapsing across runs, a
/// mnemonic's underline and a rich text's link through Text, a font without a shaper taking no
/// ellipsis, a view's lines driving the model, and the model's version and the undo stack's floor.
class TextEditingTests
{
	private static bool Near(float a, float b) => TextFixtures.Near(a, b);

	[Test]
	public static void AMnemonicMarksItsFirstLetterAndADoubledAmpersandIsOne()
	{
		let m = scope Mnemonic();
		ParseMnemonic("&File", m);
		Test.Assert(m.Shown == "File");
		Test.Assert(m.Key == 'f');
		Test.Assert((m.Start == 0) && (m.End == 1));
		ParseMnemonic("Fish && &Chips", m);
		Test.Assert(m.Shown == "Fish & Chips");
		Test.Assert(m.Key == 'c');
		Test.Assert((m.Start == 7) && (m.End == 8));
		ParseMnemonic("&A&B", m); // only the first marks; the second ampersand is shown
		Test.Assert(m.Shown == "A&B");
		Test.Assert(m.Key == 'a');
		ParseMnemonic("x&", m); // a trailing ampersand marks nothing
		Test.Assert(m.Shown == "x&");
		Test.Assert(m.Key == (char32)0);
	}

	[Test]
	public static void TypeAheadFoldsLatinGreekAndCyrillicCase()
	{
		Test.Assert(SimpleLowerCase((char32)0xC4) == (char32)0xE4); // Ä
		Test.Assert(SimpleLowerCase((char32)0xD7) == (char32)0xD7); // × is no letter
		Test.Assert(SimpleLowerCase((char32)0x3A9) == (char32)0x3C9); // Ω
		Test.Assert(SimpleLowerCase((char32)0x416) == (char32)0x436); // Ж
		Test.Assert(SimpleLowerCase((char32)0x401) == (char32)0x451); // Ё
		Test.Assert(SimpleLowerCase((char32)0x100) == (char32)0x101); // Ā, upper even
		Test.Assert(SimpleLowerCase((char32)0x139) == (char32)0x13A); // Ĺ, upper odd
		Test.Assert(SimpleLowerCase((char32)0x130) == (char32)0x130); // İ stays
		Test.Assert(SimpleLowerCase((char32)0x178) == (char32)0xFF); // Ÿ
		Test.Assert(StartsWithIgnoringCase("\u{00C4}rger", "\u{00E4}R"));
		Test.Assert(!StartsWithIgnoringCase("ab", "abc"));
		Test.Assert(StartsWithIgnoringCase("anything", ""));
	}

	[Test]
	public static void AFontFamilyListSplitsAtCommasItsQuotesAndSpacesTakenOff()
	{
		let families = scope List<String>();
		defer { ClearAndDeleteItems!(families); }
		ForEachFamily("\"Roboto\", 'Noto Sans Arabic', sans-serif, , ", scope [&] (family) => families.Add(new String(family)));
		Test.Assert(families.Count == 3);
		Test.Assert(families[0] == "Roboto");
		Test.Assert(families[1] == "Noto Sans Arabic");
		Test.Assert(families[2] == "sans-serif");
	}

	[Test]
	public static void AlikeRunsMergeAndSpacesCollapseAcrossRuns()
	{
		let doc = scope TextDocument();
		ParseTextMarkup("[b]a[/b][b]b[/b]", doc);
		Test.Assert(doc.Runs.Count == 1); // the same style: one run
		Test.Assert(doc.Runs[0].Text == "ab");
		Test.Assert(doc.Runs[0].Bold);
		Test.Assert(!doc.Runs[0].IsPlain);
		ParseTextMarkup("plain", doc);
		Test.Assert(doc.Runs[0].IsPlain);

		let cf = scope CachedFont(new MockFont(), null);
		let t = scope Text("", cf);
		t.SetMarkup("a [b] b[/b]  ");
		Test.Assert(t.IsRich);
		Test.Assert(t.PlainText == "a b"); // the bold run's leading space joins the one before; the end's go
		Test.Assert(t.Document.Runs.Count == 2);
		Test.Assert(t.Document.Runs[1].Text == "b");
	}

	[Test]
	public static void AMnemonicsUnderlineIsARunOfItsOwnUnderTheLetter()
	{
		let cf = scope CachedFont(new MockFont(), null); // 6px a byte, ascent 10 at pixel height 10
		let t = scope Text("File", cf);
		t.SetUnderline(0, 1);
		Test.Assert(t.Document.Runs.Count == 2);
		Test.Assert(t.Document.Runs[0].Underline);
		Test.Assert(t.Document.Runs[0].Text == "F");
		Test.Assert(!t.Document.Runs[1].Underline);
		Test.Assert(t.PlainText == "File");
		let layout = t.LayoutFor(Rect(0.0f, 0.0f, 100.0f, 20.0f));
		Test.Assert(layout.Underlines.Count == 1);
		let line = layout.Underlines[0].Rect;
		Test.Assert(Near(line.X, 0.0f));
		Test.Assert(Near(line.Width, 6.0f));
		// The derived decoration: 0.12 of the pixel height below the baseline, a pixel thick.
		Test.Assert(Near(line.Y, 10.0f + 1.2f));
		Test.Assert(Near(line.Height, 1.0f));
		Test.Assert(Near(t.FirstBaseline(Rect(0.0f, 0.0f, 100.0f, 20.0f)), 10.0f));
	}

	[Test]
	public static void ARichTextReportsTheLinkUnderAPoint()
	{
		let cf = scope CachedFont(new MockFont(), null);
		let t = scope Text("", cf);
		t.SetMarkup("go [link=door]open[/link]");
		let bounds = Rect(10.0f, 0.0f, 400.0f, 40.0f);
		// "go " is 18px from the bounds' left, "open" the 24px after it, the line 12px tall.
		Test.Assert(t.LinkAt(bounds, .(10.0f + 20.0f, 5.0f)) == "door");
		Test.Assert(t.LinkAt(bounds, .(10.0f + 1.0f, 5.0f)).IsEmpty);
		Test.Assert(t.LinkAt(bounds, .(10.0f + 43.0f, 5.0f)).IsEmpty); // past its end
		t.SetString("go open");
		Test.Assert(t.LinkAt(bounds, .(10.0f + 20.0f, 5.0f)).IsEmpty); // plain text has none
	}

	[Test]
	public static void AFontWithoutAShaperTakesNoEllipsis()
	{
		let cf = scope CachedFont(new MockFont(), null);
		let t = scope Text("Hello", cf);
		t.Overflow = .Ellipsis;
		let layout = t.LayoutFor(Rect(0.0f, 0.0f, 12.0f, 20.0f));
		Test.Assert(layout.Lines.Count == 1);
		Test.Assert(!layout.Lines[0].Ellipsized);
		Test.Assert(Near(layout.Width, 30.0f));
		for (let run in layout.GlyphRuns)
		{
			Test.Assert(run.Unshaped);
			Test.Assert(run.Run >= 0);
		}
		// Its glyphs still place carets, a character each.
		Test.Assert(Near(layout.CaretX(2), 12.0f));
		Test.Assert(layout.OffsetAt(.(13.0f, 5.0f)) == 2);
	}

	[Test]
	public static void AViewsLinesDriveVerticalMovesAndHomeAndEnd()
	{
		let lines = scope FakeTextLines();
		let m = scope TextEditModel();
		m.Text = "0123456789012345678901234567890123456789";
		m.SetCaret(0);
		m.SetLines(lines);
		Test.Assert(!m.Run(.MoveDown)); // a single line has no vertical moves
		m.Multiline = true;
		Test.Assert(m.Run(.MovePageDown));
		Test.Assert(lines.LastLines == 3); // a page is the view's
		Test.Assert(m.Caret == 30);
		Test.Assert(Near(lines.LastGoal, 5.0f));
		Test.Assert(m.Run(.SelectUp));
		Test.Assert(lines.LastLines == -1);
		Test.Assert(Near(lines.LastGoal, 5.0f)); // the goal kept from the move before
		Test.Assert(m.Caret == 20);
		Test.Assert(m.Anchor == 30);
		Test.Assert(m.Run(.MoveLineStart));
		Test.Assert(m.Caret == 2); // the view's line, not the text's
		Test.Assert(m.Run(.SelectLineEnd));
		Test.Assert((m.Anchor == 2) && (m.Caret == 6));
		Test.Assert(m.Run(.DeleteToLineStart)); // with a selection: the selection goes
		Test.Assert(m.Text == "016789012345678901234567890123456789");
		Test.Assert(m.Caret == 2);
	}

	[Test]
	public static void TheVersionCountsChangesAndTheUndoStackKeepsOneEntryAtLeast()
	{
		let m = scope TextEditModel();
		let start = m.Version;
		m.Text = "ab";
		Test.Assert(m.Version == start + 1);
		m.Run(.MoveLeft);
		Test.Assert(m.Version == start + 1); // a move changes nothing
		m.Insert("x");
		Test.Assert(m.Version == start + 2);
		m.ReadOnly = true;
		Test.Assert(!m.Insert("y"));
		Test.Assert(!m.Run(.Undo)); // read-only: no history either
		Test.Assert(!m.Run(.Paste, scope TestClipboard()));
		Test.Assert(m.Version == start + 2);

		let stack = scope UndoStack();
		stack.MaxEntries = 0;
		Test.Assert(stack.MaxEntries == 1);
		stack.Push("one", 0, 0);
		stack.Push("two", 0, 0);
		Test.Assert(stack.UndoCount == 1);
	}
}
