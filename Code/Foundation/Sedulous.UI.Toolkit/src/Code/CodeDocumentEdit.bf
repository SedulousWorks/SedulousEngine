using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// [[CodeDocument]]: the one mutation, and the undo history built on it.
extension CodeDocument
{
	/// One replacement: where it happened, what came out, what went in.
	private class EditOp
	{
		/// Where the removed and the inserted text both start.
		public CodePosition Pos = .();
		/// The end of the inserted text once applied, which is the span an undo takes back out.
		public CodePosition InsertedEnd = .();
		public String Removed = new .() ~ delete _;
		public String Inserted = new .() ~ delete _;
	}

	/// One step of undo, which may hold SEVERAL operations: coalesced typing, or everything
	/// inside a compound bracket.
	private class UndoEntry
	{
		public List<EditOp> Ops = new .() ~ DeleteContainerAndItems!(_);
		public CodeCursorState Before = .();
		public CodeCursorState After = .();
		public CodeEditKind Kind = .None;
	}

	private static List<UndoEntry> sUndoUnused;

	/// OWNED.
	private List<UndoEntry> mUndo = new .() ~ DeleteContainerAndItems!(_);
	private List<UndoEntry> mRedo = new .() ~ DeleteContainerAndItems!(_);

	private bool mCompoundOpen = false;
	private bool mCompoundEntryStarted = false;
	private CodeEditKind mLastEditKind = .None;
	private double mLastEditTime = 0.0;
	private CodePosition mLastEditBegin = .();
	private CodePosition mLastEditEnd = .();

	/// The single undoable mutation: replaces a span with text and returns where the cursor
	/// should now be, which is just past what was inserted.
	///
	/// The TIME is passed in rather than read from a clock, so coalescing is deterministic and a
	/// test can drive it with synthetic times.
	public CodePosition Edit(CodeSpan span, StringView text, CodeEditKind kind,
		CodeCursorState before, double time)
	{
		let target = ClampSpan(span.Normalized);

		let op = new EditOp();
		op.Pos = target.Begin;
		op.Inserted.Set(text);
		Replace(target, text, op.Removed, out op.InsertedEnd);

		// Any new edit INVALIDATES the redo stack: the future it described no longer follows
		// from the present.
		ClearAndDeleteItems!(mRedo);

		if (mCompoundOpen)
			return AppendToCompound(op, before);

		if (CanCoalesce(kind, target, time))
		{
			let last = mUndo[mUndo.Count - 1];
			last.After = .(op.InsertedEnd, op.InsertedEnd);
			last.Ops.Add(op);
		}
		else
		{
			let entry = new UndoEntry();
			entry.Before = before;
			entry.After = .(op.InsertedEnd, op.InsertedEnd);
			entry.Kind = kind;
			entry.Ops.Add(op);
			mUndo.Add(entry);

			if (mUndo.Count > MaxUndoEntries)
			{
				delete mUndo[0];
				mUndo.RemoveAt(0);
			}
		}

		mLastEditKind = kind;
		mLastEditTime = time;
		mLastEditEnd = op.InsertedEnd;
		mLastEditBegin = target.Begin;
		return mLastEditEnd;
	}

	/// Inside a compound bracket every edit lands in ONE entry, and the coalescing state is left
	/// alone: a replace-all is one undo step whatever it did.
	private CodePosition AppendToCompound(EditOp op, CodeCursorState before)
	{
		if (!mCompoundEntryStarted)
		{
			let entry = new UndoEntry();
			entry.Before = before;
			entry.Kind = .Other;
			mUndo.Add(entry);
			mCompoundEntryStarted = true;
		}

		let last = mUndo[mUndo.Count - 1];
		last.After = .(op.InsertedEnd, op.InsertedEnd);
		last.Ops.Add(op);
		mLastEditKind = .None;
		return op.InsertedEnd;
	}

	public bool CanUndo => !mUndo.IsEmpty;

	public bool CanRedo => !mRedo.IsEmpty;

	/// Reverts the newest entry, handing back the cursor state to restore.
	public bool Undo(out CodeCursorState outCursor)
	{
		outCursor = .();
		if (mUndo.IsEmpty)
			return false;

		let entry = mUndo[mUndo.Count - 1];
		mUndo.RemoveAt(mUndo.Count - 1);

		// BACKWARDS through the operations, because each one's recorded position is only valid
		// once everything after it has been taken back out.
		for (int i = entry.Ops.Count - 1; i >= 0; i--)
		{
			let op = entry.Ops[i];
			Replace(.(op.Pos, op.InsertedEnd), op.Removed, scope String(), var ignored);
		}

		outCursor = entry.Before;
		mRedo.Add(entry);
		// A new edit after an undo must NOT merge with whatever came before it.
		mLastEditKind = .None;
		return true;
	}

	public bool Redo(out CodeCursorState outCursor)
	{
		outCursor = .();
		if (mRedo.IsEmpty)
			return false;

		let entry = mRedo[mRedo.Count - 1];
		mRedo.RemoveAt(mRedo.Count - 1);

		for (let op in entry.Ops)
		{
			let removedEnd = AdvancePosition(op.Pos, op.Removed);
			Replace(.(op.Pos, removedEnd), op.Inserted, scope String(), out op.InsertedEnd);
		}

		outCursor = entry.After;
		mUndo.Add(entry);
		mLastEditKind = .None;
		return true;
	}

	/// Splits the coalescing chain. Called when the cursor moves, focus is lost, or the file is
	/// saved: all three are moments a user thinks of as a boundary.
	public void BreakUndoChain() => mLastEditKind = .None;

	/// Groups every edit until the matching end into ONE undo entry. No entry is pushed if
	/// nothing happens between them.
	public void BeginCompoundEdit()
	{
		mCompoundOpen = true;
		mCompoundEntryStarted = false;
	}

	public void EndCompoundEdit()
	{
		mCompoundOpen = false;
		mCompoundEntryStarted = false;
	}

	protected void ClearUndoHistory()
	{
		ClearAndDeleteItems!(mUndo);
		ClearAndDeleteItems!(mRedo);
		mLastEditKind = .None;
	}

	/// Whether this edit MERGES with the one before it: the same kind, one that merges at all,
	/// close enough in time, and picking up exactly where the last one left off.
	private bool CanCoalesce(CodeEditKind kind, CodeSpan target, double time)
	{
		if (mUndo.IsEmpty || (kind != mLastEditKind))
			return false;

		// A newline or a paste is a LANDMARK: a user expects to undo back to one, not through
		// it.
		if ((kind != .Typing) && (kind != .Backspace) && (kind != .Delete))
			return false;

		if ((time - mLastEditTime) > UndoCoalesceSeconds)
			return false;

		switch (kind)
		{
		// Typing continues where the last insertion ended, and only when it inserts rather
		// than replaces a selection.
		case .Typing: return (target.Begin == mLastEditEnd) && target.IsEmpty;
		// Backspace eats backwards into where the last one began.
		case .Backspace: return target.End == mLastEditBegin;
		// Delete keeps eating forwards from the same place.
		case .Delete: return target.Begin == mLastEditBegin;
		default: return false;
		}
	}

	/// Where a position ends up after text is inserted at it.
	private static CodePosition AdvancePosition(CodePosition pos, StringView text)
	{
		var addedLines = 0;
		var lastLineStart = 0;

		for (int i = 0; i < text.Length; i++)
		{
			if (text[i] != '\n')
				continue;

			addedLines++;
			lastLineStart = i + 1;
		}

		let tail = text.Substring(lastLineStart);
		let tailLength = Utf8Text.CharCount(tail);

		// With no newline the column ADVANCES; with one it restarts, because the position is
		// now on a different line.
		return (addedLines == 0) ? CodePosition(pos.Line, pos.Column + tailLength)
			: CodePosition(pos.Line + (int32)addedLines, tailLength);
	}

	/// The raw mutation, with NO recording: undo replay comes through here too, and recording
	/// an undo would make undoing an undo impossible.
	///
	/// The whole affected range is rebuilt rather than patched: the first line's prefix, the new
	/// text, then the last line's suffix, split into lines and spliced in. Patching in place
	/// would need a different case for every shape of edit.
	private void Replace(CodeSpan span, StringView text, String outRemoved,
		out CodePosition outInsertedEnd)
	{
		GetTextInSpan(span, outRemoved);

		let prefixBytes = ColumnToByte(span.Begin.Line, span.Begin.Column);
		let suffixByte = ColumnToByte(span.End.Line, span.End.Column);
		let lastLine = Line(span.End.Line);
		let prefix = scope String(Line(span.Begin.Line).Substring(0, prefixBytes));
		let suffix = scope String(lastLine.Substring(suffixByte));

		let oldCount = span.End.Line - span.Begin.Line + 1;

		let newLines = scope List<String>();
		var current = new String(prefix);
		for (int i = 0; i < text.Length; i++)
		{
			if (text[i] == '\n')
			{
				newLines.Add(current);
				current = new String();
			}
			else if (text[i] != '\r')
			{
				current.Append(text[i]);
			}
		}

		// Measured BEFORE the suffix is stitched on, because the insertion ends where the new
		// text does, not where the line does.
		outInsertedEnd = .(span.Begin.Line + (int32)newLines.Count, Utf8Text.CharCount(current));
		current.Append(suffix);
		newLines.Add(current);

		let newCount = (int32)newLines.Count;

		for (int32 i = 0; i < oldCount; i++)
		{
			delete mLines[span.Begin.Line];
			mLines.RemoveAt(span.Begin.Line);
		}

		for (int i = newCount - 1; i >= 0; i--)
			mLines.Insert(span.Begin.Line, newLines[i]);

		ShiftLineAnchors(span, newCount - oldCount);
		BumpVersion();

		if (OnLinesChanged != null)
			OnLinesChanged(span.Begin.Line, oldCount, newCount);
	}
}
