using System;
using Sedulous.Fonts;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// The editing model: a text with a caret and an anchor, edited by named commands. Offsets are bytes
// kept on grapheme boundaries, so a caret never splits "é" written as e + U+0301 or an emoji's
// parts; words come from TextSegmentation.bf. Keys reach the model through the keymap: a field
// declares the "textinput" key context, the GUI binds the editing keys to the commands' names there
// (BindTextEditingKeys), and the field handles each name by running it here, so the keys are
// rebindable and a menu can show and run them like any other command (eepp's text input over a
// document and a command map). What each command does follows foundation.ui's editor.
//
// Vertical movement and a visual line's ends ask a view's lines (ITextLines: a wrapped text area
// knows them); with none, lines are the text's own, between line breaks. Undo keeps whole snapshots
// and folds a run of typing, or of deleting one way, into one step while it goes on within a second
// (the host advances the model's clock); moving the caret, or any other edit, ends the run.

enum TextEditCommand : uint8
{
	MoveLeft,
	MoveRight,
	MoveWordLeft,
	MoveWordRight,
	MoveLineStart,
	MoveLineEnd,
	MoveUp,
	MoveDown,
	MovePageUp,
	MovePageDown,
	MoveDocumentStart,
	MoveDocumentEnd,
	SelectLeft,
	SelectRight,
	SelectWordLeft,
	SelectWordRight,
	SelectLineStart,
	SelectLineEnd,
	SelectUp,
	SelectDown,
	SelectPageUp,
	SelectPageDown,
	SelectDocumentStart,
	SelectDocumentEnd,
	SelectAll,
	DeleteBackward,
	DeleteForward,
	DeleteWordBackward,
	DeleteWordForward,
	DeleteToLineStart,
	DeleteToLineEnd,
	InsertNewline,
	Undo,
	Redo,
	Cut,
	Copy,
	Paste,
	Count,
}

static
{
	/// The command's name, as the keymap binds it ("text.move-word-left").
	public static StringView TextEditCommandName(TextEditCommand command) => TextEditModelDetail.sTextEditCommandNames[(int)command];
}

/// The names TextEditModel.bf keeps out of the public surface, one per command (sized by Count, so
/// a command without a name does not compile).
internal static class TextEditModelDetail
{
	public static String[(int)TextEditCommand.Count] sTextEditCommandNames = .(
		"text.move-left", "text.move-right", "text.move-word-left", "text.move-word-right",
		"text.move-line-start", "text.move-line-end", "text.move-up", "text.move-down",
		"text.move-page-up", "text.move-page-down", "text.move-document-start", "text.move-document-end",
		"text.select-left", "text.select-right", "text.select-word-left", "text.select-word-right",
		"text.select-line-start", "text.select-line-end", "text.select-up", "text.select-down",
		"text.select-page-up", "text.select-page-down", "text.select-document-start",
		"text.select-document-end", "text.select-all", "text.delete-backward", "text.delete-forward",
		"text.delete-word-backward", "text.delete-word-forward", "text.delete-to-line-start",
		"text.delete-to-line-end", "text.newline", "text.undo", "text.redo", "text.cut", "text.copy",
		"text.paste");
}

/// What a view knows of the lines it shows the text in (wrapped, they are not the text's own).
interface ITextLines
{
	/// The line holding the caret at `offset` (its ends are where Home and End go).
	TextRange LineAt(int offset);
	/// The offset `lines` lines above (negative) or below `offset`, nearest `goalX` across; the
	/// text's start or end past the first or last line. `goalX` below 0: from `offset`'s own x,
	/// which it sets.
	int OffsetByLines(int offset, int32 lines, ref float goalX);
	/// How many lines a page moves.
	int32 LinesPerPage { get; }
}

/// What a view knows of where carets stand: Left and Right move across what it shows, which in
/// mixed-direction text is not the order of the bytes.
interface ITextCaretPlaces
{
	/// The caret one place left (`step` below 0) or right of (`offset`, `upstream`); false when
	/// there is none that way (it stays).
	bool OffsetVisually(int offset, bool upstream, int32 step, out int outOffset, out bool outUpstream);
	/// Whether the paragraph holding `offset` runs right to left: there a word to the left is the
	/// next one, and a selection's left end its logical end.
	bool IsRightToLeftAt(int offset);
}

class TextEditModel
{
	/// How long a run of typing (or deleting) folds into one undo step.
	public const double cCoalesceSeconds = 1.0;

	private enum RunKind : uint8
	{
		None,
		Typing,
		DeletingBack,
		DeletingForward,
		Other,
	}

	private String mText = new .() ~ delete _;
	private int mCaret = 0;
	private int mAnchor = 0;
	private uint64 mVersion = 0;
	private UndoStack mUndo = new .() ~ delete _;
	private InputFilter mFilter = new .() ~ delete _;
	private ITextLines mLines = null; // borrowed
	private ITextCaretPlaces mPlaces = null; // borrowed
	private bool mUpstream = false; // the caret's affinity
	private int mMaxLength = 0;
	private float mGoalX = -1.0f; // where vertical movement aims across (-1: from the caret)
	private double mNow = 0.0;
	private double mRunTime = 0.0;
	private RunKind mRun = .None;
	private bool mMultiline = false;
	private bool mReadOnly = false;
	private bool mCopyAllowed = true;

	// === Text ===

	/// The text. Set from outside an edit, the caret goes to its end, and the history goes.
	public StringView Text
	{
		get => mText;
		set
		{
			mText.Set(value);
			mCaret = mText.Length;
			mAnchor = mCaret;
			mUpstream = false;
			mUndo.Clear();
			EndRun();
			mGoalX = -1.0f;
			Changed();
		}
	}

	/// How many times the text has changed (a view redraws and notifies on a new count).
	public uint64 Version => mVersion;

	// === Caret and selection ===

	public int Caret => mCaret;
	/// Whether the caret stands after the text before it rather than before the text after it
	/// (where the two differ, at a direction's boundary).
	public bool IsCaretUpstream => mUpstream;
	public int Anchor => mAnchor;
	public bool HasSelection => mCaret != mAnchor;
	public TextRange Selection => .(Math.Min(mCaret, mAnchor), Math.Max(mCaret, mAnchor));

	public StringView SelectedText
	{
		get
		{
			let s = Selection;
			return StringView(mText).Substring(s.Start, s.End - s.Start);
		}
	}

	/// Puts the caret at `offset` (snapped back to a grapheme boundary); `extend` keeps the anchor,
	/// so the selection grows to it.
	public void SetCaret(int offset, bool extend = false, bool upstream = false)
	{
		mCaret = Snap(offset);
		mUpstream = upstream && (mCaret == offset);
		if (!extend)
			mAnchor = mCaret;
		EndRun();
		mGoalX = -1.0f;
	}

	public void Select(TextRange range)
	{
		mAnchor = Snap(range.Start);
		mCaret = Snap(range.End);
		mUpstream = false;
		EndRun();
		mGoalX = -1.0f;
	}

	public void SelectAll() => Select(.(0, mText.Length));

	/// Selects the word, spaces or punctuation at `offset` (a double click).
	public void SelectWordAt(int offset) => Select(WordRangeAt(mText, Snap(offset)));

	// === Rules ===

	public bool Multiline
	{
		get => mMultiline;
		set => mMultiline = value;
	}

	public bool ReadOnly
	{
		get => mReadOnly;
		set => mReadOnly = value;
	}

	/// The most graphemes the text may hold (0: no limit); what does not fit is cut.
	public int MaxLength
	{
		get => mMaxLength;
		set => mMaxLength = value;
	}

	/// What it lets in. Set, the model takes and owns the filter (null: everything); got, borrowed.
	public InputFilter Filter
	{
		get => mFilter;
		set
		{
			if (value === mFilter)
				return;
			delete mFilter;
			mFilter = (value != null) ? value : new InputFilter();
		}
	}

	/// Whether the text may leave through copy and cut (a password's may not).
	public bool CopyAllowed
	{
		get => mCopyAllowed;
		set => mCopyAllowed = value;
	}

	/// The lines vertical movement and Home and End follow (null: the text's own). Borrowed.
	public void SetLines(ITextLines lines) => mLines = lines;

	/// Where carets stand in the view (null: Left and Right move by graphemes, as the bytes go).
	/// Borrowed.
	public void SetCaretPlaces(ITextCaretPlaces places) => mPlaces = places;

	public UndoStack UndoStack => mUndo;

	/// The model's clock, in seconds, which undo folding reads.
	public double Time
	{
		get => mNow;
		set => mNow = value;
	}

	// === Editing ===

	/// Types `text` at the caret, over the selection: what the filter lets in, line breaks only in a
	/// multiline text, as much as the length limit leaves room for. True when it changed.
	public bool Insert(StringView text) => InsertText(text, .Typing);

	/// Runs `command`; `clipboard` (borrowed) serves cut, copy and paste (null: they do nothing).
	/// True when it applies to this text (a read-only text takes moves and copies, not edits).
	public bool Run(TextEditCommand command, IClipboard clipboard = null)
	{
		StringView text = mText;
		switch (command)
		{
		// Across what the view shows; a selection collapses to its end on that side (in a
		// right-to-left paragraph, Left goes to its logical end).
		case .MoveLeft:
			return HasSelection ? MoveCaret(RightToLeftHere() ? Selection.End : Selection.Start, false) : MoveAcross(-1, false);
		case .MoveRight:
			return HasSelection ? MoveCaret(RightToLeftHere() ? Selection.Start : Selection.End, false) : MoveAcross(1, false);
		case .SelectLeft:
			return MoveAcross(-1, true);
		case .SelectRight:
			return MoveAcross(1, true);
		// A word on that side, by the text's order in the caret's paragraph: to the left of a
		// right-to-left one is the next word.
		case .MoveWordLeft, .SelectWordLeft:
			return MoveCaret(RightToLeftHere() ? NextWordBoundary(text, mCaret) : PrevWordBoundary(text, mCaret), command == .SelectWordLeft);
		case .MoveWordRight, .SelectWordRight:
			return MoveCaret(RightToLeftHere() ? PrevWordBoundary(text, mCaret) : NextWordBoundary(text, mCaret), command == .SelectWordRight);
		case .MoveLineStart, .SelectLineStart:
			return MoveCaret(LineAt(mCaret).Start, command == .SelectLineStart);
		case .MoveLineEnd, .SelectLineEnd:
			return MoveCaret(LineAt(mCaret).End, command == .SelectLineEnd);
		case .MoveDocumentStart, .SelectDocumentStart:
			return MoveCaret(0, command == .SelectDocumentStart);
		case .MoveDocumentEnd, .SelectDocumentEnd:
			return MoveCaret(text.Length, command == .SelectDocumentEnd);
		case .MoveUp, .SelectUp:
			return MoveLines(-1, command == .SelectUp);
		case .MoveDown, .SelectDown:
			return MoveLines(1, command == .SelectDown);
		case .MovePageUp, .SelectPageUp:
			return MoveLines(-PageLines(), command == .SelectPageUp);
		case .MovePageDown, .SelectPageDown:
			return MoveLines(PageLines(), command == .SelectPageDown);
		case .SelectAll:
			SelectAll();
			return true;
		case .DeleteBackward:
			return DeleteTo(HasSelection ? mCaret : PrevGrapheme(text, mCaret), .DeletingBack);
		case .DeleteForward:
			return DeleteTo(HasSelection ? mCaret : NextGrapheme(text, mCaret), .DeletingForward);
		case .DeleteWordBackward:
			return DeleteTo(HasSelection ? mCaret : PrevWordBoundary(text, mCaret), .Other);
		case .DeleteWordForward:
			return DeleteTo(HasSelection ? mCaret : NextWordBoundary(text, mCaret), .Other);
		case .DeleteToLineStart:
			return DeleteTo(HasSelection ? mCaret : LineAt(mCaret).Start, .Other);
		case .DeleteToLineEnd:
			return DeleteTo(HasSelection ? mCaret : LineAt(mCaret).End, .Other);
		case .InsertNewline:
			if (!mMultiline)
				return false;
			return InsertText("\n", .Other);
		case .Undo:
			return StepHistory(true);
		case .Redo:
			return StepHistory(false);
		case .Copy:
			if ((clipboard != null) && HasSelection && mCopyAllowed)
				clipboard.SetText(SelectedText);
			return true;
		case .Cut:
			if (!mCopyAllowed)
				return true; // nothing leaves a password, and nothing goes
			if ((clipboard != null) && HasSelection)
				clipboard.SetText(SelectedText);
			if (mReadOnly)
				return true; // a read-only cut is a copy
			return DeleteTo(mCaret, .Other);
		case .Paste:
			if (mReadOnly)
				return false;
			if ((clipboard != null) && clipboard.HasText)
			{
				let pasted = scope String();
				clipboard.GetText(pasted);
				InsertText(pasted, .Other);
			}
			return true;
		case .Count:
			return false;
		}
	}

	/// The command a name names (as the keymap binds it); false for a name not the model's.
	public static bool FindCommand(StringView name, out TextEditCommand outCommand)
	{
		outCommand = default;
		for (int i = 0; i < (int)TextEditCommand.Count; i++)
		{
			if (name == TextEditModelDetail.sTextEditCommandNames[i])
			{
				outCommand = (TextEditCommand)i;
				return true;
			}
		}
		return false;
	}

	private int Snap(int offset)
	{
		StringView text = mText;
		var offset;
		offset = Math.Min(offset, text.Length);
		// Back off a UTF-8 continuation byte, then off a mark that belongs to the grapheme before.
		while ((offset > 0) && (offset < text.Length) && ((((uint8)text[offset] & 0xC0) == 0x80) || !IsGraphemeBoundary(text, offset)))
			offset--;
		return offset;
	}

	// Whether the caret's paragraph runs right to left (the view says; none: left to right).
	private bool RightToLeftHere() => (mPlaces != null) && mPlaces.IsRightToLeftAt(mCaret);

	// One place left or right: across the view where it says where carets stand, else by a grapheme
	// as the bytes go.
	private bool MoveAcross(int32 step, bool extend)
	{
		StringView text = mText;
		if (mPlaces == null)
			return MoveCaret((step < 0) ? PrevGrapheme(text, mCaret) : NextGrapheme(text, mCaret), extend);
		int to = mCaret;
		bool upstream = mUpstream;
		if (!mPlaces.OffsetVisually(mCaret, mUpstream, step, out to, out upstream))
			return MoveCaret(mCaret, extend, mUpstream);
		let snapped = Snap(Math.Min(to, text.Length));
		return MoveCaret(snapped, extend, upstream && (snapped == to));
	}

	private bool MoveCaret(int to, bool extend, bool upstream = false)
	{
		mUpstream = upstream;
		mCaret = to;
		if (!extend)
			mAnchor = to;
		EndRun();
		mGoalX = -1.0f;
		return true;
	}

	private TextRange LineAt(int offset) => (mLines != null) ? mLines.LineAt(offset) : LineRangeAt(mText, offset);

	private int32 PageLines() => (mLines != null) ? Math.Max(1, mLines.LinesPerPage) : 1;

	private bool MoveLines(int32 lines, bool extend)
	{
		if (!mMultiline)
			return false;
		int to;
		if (mLines != null)
		{
			float x = mGoalX;
			to = mLines.OffsetByLines(mCaret, lines, ref x);
			mGoalX = x;
		}
		else
		{
			to = OffsetByTextLines(lines);
		}
		mCaret = to; // the goal stays for the next vertical move
		mUpstream = false;
		if (!extend)
			mAnchor = to;
		EndRun();
		return true;
	}

	// The text's own lines, the column counted in graphemes (the goal kept in mGoalX).
	private int OffsetByTextLines(int32 lines)
	{
		var lines;
		StringView text = mText;
		var line = LineRangeAt(text, mCaret);
		if (mGoalX < 0.0f)
			mGoalX = (float)GraphemeCount(text.Substring(line.Start, mCaret - line.Start));
		for (; lines < 0; lines++)
		{
			if (line.Start == 0)
				return 0;
			line = LineRangeAt(text, line.Start - 1);
		}
		for (; lines > 0; lines--)
		{
			int next = line.End;
			while ((next < text.Length) && (text[next] != '\n'))
				next++;
			if (next >= text.Length)
				return text.Length;
			line = LineRangeAt(text, next + 1);
		}
		int at = line.Start;
		for (int32 column = 0; (column < (int32)mGoalX) && (at < line.End); column++)
			at = NextGrapheme(text, at);
		return Math.Min(at, line.End);
	}

	// Deletes from the caret to `to` (or the selection, when there is one).
	private bool DeleteTo(int to, RunKind kind)
	{
		if (mReadOnly)
			return false;
		let range = HasSelection ? Selection : TextRange(Math.Min(mCaret, to), Math.Max(mCaret, to));
		if (range.IsEmpty)
		{
			EndRun();
			return true;
		}
		Remember(HasSelection ? RunKind.Other : kind);
		mText.Remove(range.Start, range.End - range.Start);
		mCaret = range.Start;
		mAnchor = range.Start;
		mUpstream = false;
		mGoalX = -1.0f;
		Changed();
		return true;
	}

	private bool InsertText(StringView text, RunKind kind)
	{
		if (mReadOnly)
			return false;
		// What the filter lets in; a single-line text takes a line break as a space.
		let accepted = scope String();
		for (int i = 0; i < text.Length;)
		{
			var c = DecodeCodepoint(text, ref i);
			if (c == (uint32)'\r')
			{
				if ((i < text.Length) && (text[i] == '\n'))
					continue; // CR LF: the LF follows
				c = (uint32)'\n';
			}
			if ((c == (uint32)'\n') && !mMultiline)
				c = (uint32)' ';
			if ((c != (uint32)'\n') && (c != (uint32)'\t') && (c < 0x20))
				continue; // other controls are not text
			if ((c != (uint32)'\n') && !mFilter.Accept((char32)c))
				continue;
			accepted.Append((char32)c);
		}
		// As many graphemes as the limit leaves room for.
		let selection = Selection;
		if (mMaxLength > 0)
		{
			StringView whole = mText;
			let kept = GraphemeCount(whole) - GraphemeCount(whole.Substring(selection.Start, selection.End - selection.Start));
			let room = (kept >= mMaxLength) ? 0 : mMaxLength - kept;
			int end = 0;
			for (int n = 0; (n < room) && (end < accepted.Length); n++)
				end = NextGrapheme(accepted, end);
			accepted.RemoveToEnd(end);
		}
		// Nothing of what was typed is let in: nothing changes (the selection it would have replaced
		// stays, rather than being deleted for nothing).
		if ((accepted.Length == 0) && (selection.IsEmpty || (text.Length != 0)))
			return false;
		Remember(selection.IsEmpty ? kind : RunKind.Other);
		mText.Remove(selection.Start, selection.End - selection.Start);
		mText.Insert(selection.Start, accepted);
		mCaret = selection.Start + accepted.Length;
		mAnchor = mCaret;
		mUpstream = false;
		mGoalX = -1.0f;
		Changed();
		return true;
	}

	// Before an edit: a new undo step, unless it goes on the run before it.
	private void Remember(RunKind kind)
	{
		let folds = (kind != .Other) && (kind == mRun) && (mNow - mRunTime <= cCoalesceSeconds);
		if (!folds)
			mUndo.Push(mText, mCaret, mAnchor);
		mRun = kind;
		mRunTime = mNow;
	}

	private void EndRun() => mRun = .None;

	private bool StepHistory(bool back)
	{
		if (mReadOnly)
			return false;
		let current = scope UndoEntry(mText, mCaret, mAnchor);
		let restored = scope UndoEntry();
		if (!(back ? mUndo.Undo(current, restored) : mUndo.Redo(current, restored)))
			return true;
		mText.Set(restored.Text);
		mCaret = Math.Min(restored.Caret, mText.Length);
		mUpstream = false;
		mAnchor = Math.Min(restored.Anchor, mText.Length);
		EndRun();
		mGoalX = -1.0f;
		Changed();
		return true;
	}

	private void Changed() => mVersion++;
}
