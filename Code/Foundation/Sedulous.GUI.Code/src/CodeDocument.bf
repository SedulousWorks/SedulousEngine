using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.GUI;

// A code editor's document: an array of lines, as every editor surveyed keeps (none but zed, whose
// rope serves collaboration, a gap buffer or a rope), each line its text and a hash (what a
// tokenizer caches its tokens by, eepp's key). Positions are (line, byte column), a column on a
// character's boundary. Anchors are positions the document moves through each edit, biased left or
// right (zed's, without its collaboration): selections, diagnostics, markers and search hits keep
// their places while text changes round them. Undo is transactions of edits (the range replaced,
// the text it held, the text put there) with the selections before and after (zed's
// SelectionHistory, Godot's and Lumix's carets kept with each step), so multi-cursor undo puts every
// cursor back; transactions of typing (or of deleting) within 300 ms of each other merge into one
// step on the document's clock, which its host advances.

/// A place in a document: a line, and a byte column in it on a character's boundary.
struct CodePosition : IEquatable<CodePosition>
{
	public uint32 Line = 0;
	public uint32 Column = 0;

	public this() { }

	public this(uint32 line, uint32 column)
	{
		Line = line;
		Column = column;
	}

	public bool Equals(CodePosition other) => this == other;

	[Commutable]
	public static bool operator==(CodePosition a, CodePosition o) => (a.Line == o.Line) && (a.Column == o.Column);

	public static bool operator<(CodePosition a, CodePosition o) => (a.Line < o.Line) || ((a.Line == o.Line) && (a.Column < o.Column));

	public static bool operator<=(CodePosition a, CodePosition o) => !(o < a);
}

/// A run of a document, start to end (end not included); empty where they meet.
struct CodeRange : IEquatable<CodeRange>
{
	public CodePosition Start = .();
	public CodePosition End = .();

	public this() { }

	public this(CodePosition start, CodePosition end)
	{
		Start = start;
		End = end;
	}

	public bool IsEmpty => Start == End;

	public bool Equals(CodeRange other) => this == other;

	[Commutable]
	public static bool operator==(CodeRange a, CodeRange o) => (a.Start == o.Start) && (a.End == o.End);

	/// Start before end, whichever way it was given.
	public static CodeRange Ordered(CodePosition a, CodePosition b) => (b < a) ? CodeRange(b, a) : CodeRange(a, b);
}

/// A selection: where it was begun (its anchor) and where its caret is (its head).
struct CodeSelection : IEquatable<CodeSelection>
{
	public CodePosition Anchor = .();
	public CodePosition Head = .();

	public this() { }

	public this(CodePosition anchor, CodePosition head)
	{
		Anchor = anchor;
		Head = head;
	}

	public bool IsEmpty => Anchor == Head;
	public CodeRange Range => CodeRange.Ordered(Anchor, Head);

	public bool Equals(CodeSelection other) => this == other;

	[Commutable]
	public static bool operator==(CodeSelection a, CodeSelection o) => (a.Anchor == o.Anchor) && (a.Head == o.Head);
}

/// Which way an anchor goes when text is put where it stands: before it (it stays) or after.
enum CodeBias : uint8
{
	/// Text put at it goes after it (a selection's start, a diagnostic's start).
	Left,
	/// Text put at it goes before it, it moving on (a caret after typing).
	Right,
}

/// What an edit is, for merging undo steps: typing merges with typing, deleting with deleting.
enum CodeEditKind : uint8
{
	Other,
	Typing,
	Deleting,
}

/// An edit: from `FirstLine`, `RemovedLines` lines gave way to `InsertedLines`; exactly, the range
/// `Replaced` (as it was) by text now ending at `End` (what another view sharing the document moves
/// its own positions through).
struct CodeChange
{
	public uint32 FirstLine = 0;
	public uint32 RemovedLines = 0;
	public uint32 InsertedLines = 0;
	public CodeRange Replaced = .();
	public CodePosition End = .();

	public this() { }

	public this(uint32 firstLine, uint32 removedLines, uint32 insertedLines, CodeRange replaced, CodePosition end)
	{
		FirstLine = firstLine;
		RemovedLines = removedLines;
		InsertedLines = insertedLines;
		Replaced = replaced;
		End = end;
	}
}

typealias CodeAnchorId = uint32;

class CodeDocument
{
	/// Seconds within which a transaction of typing (or of deleting) merges with the last.
	public const float cMergeSeconds = 0.3f;

	private class Line
	{
		public String Text = new .() ~ delete _;
		public uint64 Hash = 0;
	}

	private struct Anchor
	{
		public CodePosition Position = .();
		public CodeBias Bias = .Left;
		public bool Live = false;

		public this() { }

		public this(CodePosition position, CodeBias bias, bool live)
		{
			Position = position;
			Bias = bias;
			Live = live;
		}
	}

	private class Edit
	{
		/// What was replaced.
		public CodeRange Before = .();
		/// The text it held.
		public String Removed = new .() ~ delete _;
		/// The text put there.
		public String Inserted = new .() ~ delete _;
		/// Where that text lies.
		public CodeRange After = .();
	}

	private class Transaction
	{
		public List<Edit> Edits = new .() ~ DeleteContainerAndItems!(_);
		public List<CodeSelection> Before = new .() ~ delete _;
		public List<CodeSelection> After = new .() ~ delete _;
		public CodeEditKind Kind = .Other;
		/// The clock when it last closed.
		public float At = 0.0f;
	}

	private class Listener
	{
		public uint32 Token = 0;
		public delegate void(CodeChange change) Callback ~ delete _;
	}

	// Never empty: an empty document is one empty line.
	private List<Line> mLines = new .() ~ DeleteContainerAndItems!(_);
	private List<Anchor> mAnchors = new .() ~ delete _;
	private List<Transaction> mUndo = new .() ~ DeleteContainerAndItems!(_);
	private List<Transaction> mRedo = new .() ~ DeleteContainerAndItems!(_);
	private bool mOpen = false;
	// Begin calls inside the open transaction.
	private uint32 mDepth = 0;
	private bool mBreakNext = false;
	private float mClock = 0.0f;
	private int mUndoLimit = 1000;
	private uint64 mVersion = 0;
	private List<Listener> mListeners = new .() ~ DeleteContainerAndItems!(_);
	private uint32 mLastListener = 0;

	public this()
	{
		let line = new Line();
		line.Hash = Hash(default);
		mLines.Add(line);
	}

	// === The text ===

	/// Replaces the whole text (lines split at line feeds, a carriage return before one dropped);
	/// undo starts again, anchors go to the start.
	public void SetText(StringView text)
	{
		let removed = (uint32)mLines.Count;
		ClearAndDeleteItems!(mLines);
		SplitInto(text, mLines);
		for (int i < mAnchors.Count)
			mAnchors[i].Position = .();
		ClearAndDeleteItems!(mUndo);
		ClearAndDeleteItems!(mRedo);
		mOpen = false;
		++mVersion;
		Changed(.(0, removed, (uint32)mLines.Count, .(), End()));
	}

	/// The whole text, its lines joined by line feeds, appended to `outText`.
	public void GetText(String outText)
	{
		for (int i < mLines.Count)
		{
			if (i > 0)
				outText.Append("\n");
			outText.Append(mLines[i].Text);
		}
	}

	public uint32 LineCount => (uint32)mLines.Count;
	public StringView LineText(uint32 line) => mLines[(int)line].Text;
	/// A line's text's hash: what a tokenizer keeps its tokens by.
	public uint64 LineHash(uint32 line) => mLines[(int)line].Hash;
	/// Raised by every change: what a view compares against what it drew.
	public uint64 Version => mVersion;

	/// The text in `range`, lines joined by line feeds, appended to `outText`.
	public void TextIn(CodeRange range, String outText)
	{
		var range;
		range = .(Clamp(range.Start), Clamp(range.End));
		if (range.End < range.Start)
			range = .(range.End, range.Start);
		for (uint32 line = range.Start.Line; line <= range.End.Line; ++line)
		{
			let text = LineText(line);
			let from = (line == range.Start.Line) ? range.Start.Column : 0u;
			let to = (line == range.End.Line) ? range.End.Column : (uint32)text.Length;
			if (line > range.Start.Line)
				outText.Append("\n");
			outText.Append(text.Substring((int)from, (int)to - (int)from));
		}
	}

	/// The end of the text.
	public CodePosition End() => .((uint32)(LineCount - 1), (uint32)mLines.Back.Text.Length);

	// === Search ===

	/// The first match of `needle` (line feeds in it span lines) at or after `from`, going on from
	/// the start to `from` when `wrap`; case folded for ASCII letters unless `matchCase`, only where
	/// no name runs on either side when `wholeWord`. False when there is none.
	public bool Find(StringView needle, CodePosition from, bool matchCase, bool wholeWord, bool wrap, out CodeRange @out)
	{
		@out = .();
		if (needle.Length == 0)
			return false;
		var from;
		from = Clamp(from);
		for (uint32 line = from.Line; line < LineCount; ++line)
		{
			if (FindOnLine(needle, line, (line == from.Line) ? (int)from.Column : 0, (int)uint32.MaxValue, matchCase, wholeWord, out @out))
				return true;
		}
		if (!wrap)
			return false;
		for (uint32 line = 0; (line <= from.Line) && (line < LineCount); ++line)
		{
			if (FindOnLine(needle, line, 0, (line == from.Line) ? (int)from.Column : (int)uint32.MaxValue, matchCase, wholeWord, out @out))
				return true;
		}
		return false;
	}

	// === Positions ===

	/// `position` within the text, its column back on a character's boundary.
	public CodePosition Clamp(CodePosition position)
	{
		if (position.Line >= LineCount)
			return End();
		let text = LineText(position.Line);
		var column = Math.Min(position.Column, (uint32)text.Length);
		while ((column > 0) && (column < (uint32)text.Length) && (((uint8)text[(int)column] & 0xC0) == 0x80))
			--column; // inside a character's bytes: back to its start
		return .(position.Line, column);
	}

	/// The next character's place (a grapheme: "é" as e and its accent, an emoji's parts, one), the
	/// next line's start from a line's end; the end stays.
	public CodePosition NextCharacter(CodePosition position)
	{
		let at = Clamp(position);
		let text = LineText(at.Line);
		if (at.Column < (uint32)text.Length)
			return .(at.Line, (uint32)NextGrapheme(text, (int)at.Column));
		return (at.Line + 1 < LineCount) ? CodePosition((uint32)(at.Line + 1), 0) : at;
	}

	/// The character before's place, the last line's end from a line's start; the start stays.
	public CodePosition PreviousCharacter(CodePosition position)
	{
		let at = Clamp(position);
		if (at.Column > 0)
			return .(at.Line, (uint32)PrevGrapheme(LineText(at.Line), (int)at.Column));
		return (at.Line > 0) ? CodePosition((uint32)(at.Line - 1), (uint32)LineText((uint32)(at.Line - 1)).Length) : at;
	}

	// === Edits ===

	/// Puts `text` in place of `range` (line feeds in it make lines), as one edit of the open
	/// transaction (or a transaction of its own); the range `text` now takes.
	public CodeRange Replace(CodeRange range, StringView text, CodeEditKind kind = .Other)
	{
		var range;
		range = CodeRange.Ordered(Clamp(range.Start), Clamp(range.End));
		let own = !mOpen;
		if (own)
			Begin(default, kind);
		let edit = new Edit();
		edit.Before = range;
		TextIn(range, edit.Removed);
		Normalized(text, edit.Inserted);
		edit.After = Apply(range, edit.Inserted);
		mUndo.Back.Edits.Add(edit);
		ClearAndDeleteItems!(mRedo);
		if (own)
			End(default);
		return edit.After;
	}

	public CodeRange Insert(CodePosition at, StringView text, CodeEditKind kind = .Other)
	{
		return Replace(.(at, at), text, kind);
	}

	public void Erase(CodeRange range, CodeEditKind kind = .Deleting)
	{
		Replace(range, default, kind);
	}

	// === Undo ===

	/// Opens a transaction: the edits until End are one undo step, which puts `before` back. Of a
	/// kind (typing, deleting) and within cMergeSeconds of the last of that kind, it continues that
	/// step.
	public void Begin(Span<CodeSelection> before, CodeEditKind kind = .Other)
	{
		if (mOpen)
		{
			++mDepth;
			return;
		}
		mOpen = true;
		mDepth = 0;
		let merges = (kind != .Other) && !mUndo.IsEmpty && (mUndo.Back.Kind == kind) && !mBreakNext &&
			(mClock - mUndo.Back.At <= cMergeSeconds) && mRedo.IsEmpty;
		mBreakNext = false;
		if (!merges)
		{
			let transaction = new Transaction();
			transaction.Kind = kind;
			for (let selection in before)
				transaction.Before.Add(selection);
			mUndo.Add(transaction);
			if (mUndo.Count > mUndoLimit)
			{
				delete mUndo[0];
				mUndo.RemoveAt(0);
			}
		}
	}

	/// Closes it: undoing it, then redoing it, puts `after` back.
	public void End(Span<CodeSelection> after)
	{
		if (!mOpen)
			return;
		if (mDepth > 0)
		{
			--mDepth;
			return;
		}
		mOpen = false;
		let transaction = mUndo.Back;
		transaction.At = mClock;
		transaction.After.Clear();
		for (let selection in after)
			transaction.After.Add(selection);
		if (transaction.Edits.IsEmpty)
		{
			// Nothing changed: no step.
			mUndo.RemoveAt(mUndo.Count - 1);
			delete transaction;
		}
	}

	/// The next transaction starts a step of its own (a caret moved between two runs of typing).
	public void BreakMerge()
	{
		mBreakNext = true;
	}

	/// Advances the clock merging counts on (the host's frame).
	public void AdvanceClock(float seconds)
	{
		mClock += seconds;
	}

	public bool CanUndo => !mUndo.IsEmpty && !mOpen;
	public bool CanRedo => !mRedo.IsEmpty && !mOpen;

	/// Steps back; the selections as they were before the step (empty when it kept none) in
	/// `selections`. False when there is nothing to undo.
	public bool Undo(List<CodeSelection> selections)
	{
		if (!CanUndo)
			return false;
		let transaction = mUndo.PopBack();
		for (int i = transaction.Edits.Count - 1; i >= 0; i--)
		{
			let edit = transaction.Edits[i];
			Apply(edit.After, edit.Removed);
		}
		selections.Clear();
		selections.AddRange(transaction.Before);
		mRedo.Add(transaction);
		mBreakNext = true;
		return true;
	}

	/// Steps forward again; the selections as they were after the step.
	public bool Redo(List<CodeSelection> selections)
	{
		if (!CanRedo)
			return false;
		let transaction = mRedo.PopBack();
		for (let edit in transaction.Edits)
			Apply(edit.Before, edit.Inserted);
		selections.Clear();
		selections.AddRange(transaction.After);
		mUndo.Add(transaction);
		mBreakNext = true;
		return true;
	}

	/// How many steps undo keeps (1000).
	public void SetUndoLimit(int steps)
	{
		mUndoLimit = Math.Max(1, steps);
	}

	public int UndoCount => mUndo.Count;

	// === Anchors ===

	/// A position the document keeps through edits.
	public CodeAnchorId AddAnchor(CodePosition position, CodeBias bias = .Left)
	{
		let anchor = Anchor(Clamp(position), bias, true);
		for (int i < mAnchors.Count)
		{
			if (!mAnchors[i].Live)
			{
				mAnchors[i] = anchor;
				return (CodeAnchorId)i;
			}
		}
		mAnchors.Add(anchor);
		return (CodeAnchorId)(mAnchors.Count - 1);
	}

	public void RemoveAnchor(CodeAnchorId id)
	{
		if ((int)id < mAnchors.Count)
			mAnchors[(int)id].Live = false;
	}

	public CodePosition GetAnchor(CodeAnchorId id)
	{
		return ((int)id < mAnchors.Count) ? mAnchors[(int)id].Position : CodePosition();
	}

	public void SetAnchor(CodeAnchorId id, CodePosition position)
	{
		if ((int)id < mAnchors.Count)
			mAnchors[(int)id].Position = Clamp(position);
	}

	/// Where `position` goes through an edit that put a range ending at `after` in place of
	/// `before` (what anchors do; a view moves what it keeps outside the document the same).
	public static CodePosition Moved(CodePosition position, CodeBias bias, CodeRange before, CodePosition after)
	{
		if (position < before.Start)
			return position; // before the edit
		if ((position == before.Start) && (bias == .Left))
			return position; // at its start keeping left: text put there goes after it
		if ((position < before.End) || ((position == before.Start) && before.IsEmpty))
			return (bias == .Left) ? before.Start : after; // inside what was replaced, or text put at it
		// At or after its end: carried along with the text after it.
		if (position.Line == before.End.Line)
			return .(after.Line, (uint32)(after.Column + (position.Column - before.End.Column)));
		return .((uint32)(position.Line - before.End.Line + after.Line), position.Column);
	}

	/// Tells `callback` each change's lines (a tokenizer's cache, a view's layouts; each editor
	/// sharing the document its own); a token for RemoveChangeListener. OWNERSHIP of `callback`
	/// transfers.
	public uint32 AddChangeListener(delegate void(CodeChange change) callback)
	{
		let listener = new Listener();
		listener.Token = ++mLastListener;
		listener.Callback = callback;
		mListeners.Add(listener);
		return mLastListener;
	}

	public void RemoveChangeListener(uint32 token)
	{
		for (int i < mListeners.Count)
		{
			if (mListeners[i].Token == token)
			{
				delete mListeners[i];
				mListeners.RemoveAt(i);
				return;
			}
		}
	}

	private static char8 Folded(char8 c, bool matchCase)
	{
		return (!matchCase && (c >= 'A') && (c <= 'Z')) ? (char8)((uint8)c - (uint8)'A' + (uint8)'a') : c;
	}

	private static bool IsNameChar(char8 c)
	{
		return ((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z')) || ((c >= '0') && (c <= '9')) || (c == '_') ||
			((uint8)c >= 0x80);
	}

	private static bool SameText(StringView a, StringView b, bool matchCase)
	{
		if (a.Length != b.Length)
			return false;
		for (int i < a.Length)
		{
			if (Folded(a[i], matchCase) != Folded(b[i], matchCase))
				return false;
		}
		return true;
	}

	// A match beginning on `line` at a column in [first, last).
	private bool FindOnLine(StringView needle, uint32 line, int first, int last, bool matchCase, bool wholeWord, out CodeRange @out)
	{
		@out = .();
		int split = 0;
		while ((split < needle.Length) && (needle[split] != '\n'))
			++split;
		let head = needle.Substring(0, split);
		let text = LineText(line);
		let spans = split < needle.Length;
		for (int column = first; (column + head.Length <= text.Length) && (column < last); ++column)
		{
			if (((uint8)text[column] & 0xC0) == 0x80)
				continue; // inside a character
			if (spans ? (column + head.Length != text.Length) : false)
				continue; // a match across lines begins with a line's end
			if (!SameText(text.Substring(column, head.Length), head, matchCase))
				continue;
			var end = CodePosition(line, (uint32)(column + head.Length));
			if (spans)
			{
				// Each whole line between, then the next line's start.
				int at = split + 1;
				uint32 next = (uint32)(line + 1);
				bool fits = true;
				while (fits)
				{
					int stop = at;
					while ((stop < needle.Length) && (needle[stop] != '\n'))
						++stop;
					let part = needle.Substring(at, stop - at);
					if (next >= LineCount)
					{
						fits = false;
						break;
					}
					let there = LineText(next);
					if (stop < needle.Length)
					{
						fits = SameText(there, part, matchCase);
						at = stop + 1;
						++next;
						continue;
					}
					fits = (part.Length <= there.Length) && SameText(there.Substring(0, part.Length), part, matchCase);
					end = .(next, (uint32)part.Length);
					break;
				}
				if (!fits)
					continue;
			}
			if (wholeWord)
			{
				let endLine = LineText(end.Line);
				if (((column > 0) && IsNameChar(text[column - 1])) || ((end.Column < (uint32)endLine.Length) && IsNameChar(endLine[(int)end.Column])))
					continue;
			}
			@out = .(.(line, (uint32)column), end);
			return true;
		}
		return false;
	}

	private static uint64 Hash(StringView text) => HashBytes(text.Ptr, text.Length);

	// Its lines' feeds as line feeds alone, appended to `outText`.
	private static void Normalized(StringView text, String outText)
	{
		for (int i < text.Length)
		{
			if (!((text[i] == '\r') && (i + 1 < text.Length) && (text[i + 1] == '\n')))
				outText.Append(text[i]);
		}
	}

	private static void SplitInto(StringView text, List<Line> @out)
	{
		int start = 0;
		for (int i = 0; i <= text.Length; ++i)
		{
			if ((i == text.Length) || (text[i] == '\n'))
			{
				var end = i;
				if ((end > start) && (text[end - 1] == '\r'))
					--end;
				let line = text.Substring(start, end - start);
				let made = new Line();
				made.Text.Set(line);
				made.Hash = Hash(line);
				@out.Add(made);
				start = i + 1;
			}
		}
	}

	// The edit itself: lines replaced, anchors moved, listeners told; where the text now lies.
	private CodeRange Apply(CodeRange range, StringView text)
	{
		let prefix = scope String(LineText(range.Start.Line).Substring(0, (int)range.Start.Column));
		let endLine = LineText(range.End.Line);
		let suffix = scope String(endLine.Substring((int)range.End.Column, endLine.Length - (int)range.End.Column));
		let made = scope List<Line>();
		SplitInto(text, made);
		let after = CodePosition((uint32)(range.Start.Line + (uint32)made.Count - 1),
			(uint32)(((made.Count == 1) ? prefix.Length : 0) + made.Back.Text.Length));
		made[0].Text.Insert(0, prefix);
		made.Back.Text.Append(suffix);
		for (let line in made)
			line.Hash = Hash(line.Text);
		let removed = (uint32)(range.End.Line - range.Start.Line + 1);
		for (uint32 i < removed)
		{
			delete mLines[(int)range.Start.Line];
			mLines.RemoveAt((int)range.Start.Line);
		}
		for (int i < made.Count)
			mLines.Insert((int)range.Start.Line + i, made[i]); // the document's now
		for (int i < mAnchors.Count)
		{
			if (mAnchors[i].Live)
				mAnchors[i].Position = Moved(mAnchors[i].Position, mAnchors[i].Bias, range, after);
		}
		++mVersion;
		Changed(.(range.Start.Line, removed, (uint32)made.Count, range, after));
		return .(range.Start, after);
	}

	private void Changed(CodeChange change)
	{
		for (int i = 0; i < mListeners.Count; i++)
		{
			if (mListeners[i].Callback != null)
				mListeners[i].Callback(change);
		}
	}
}
