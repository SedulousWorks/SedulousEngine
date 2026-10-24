using System;
using System.Collections;

namespace Sedulous.GUI;

// A bounded undo and redo stack for text editing: each entry is the whole text with its caret and
// anchor (byte offsets), a snapshot rather than a delta, which keeps undo exact for any edit.
//
// Copied from foundation.ui's undo stack, and the GUI's own from then on: offsets are bytes, as the
// GUI's text keeps them. An entry owns its text and is copied onto the other stack, so it is a
// class with a deep Set.

/// The text, caret and anchor at one point of an edit's history.
class UndoEntry
{
	public String Text = new .() ~ delete _;
	public int Caret = 0;
	public int Anchor = 0;

	public this() { }

	public this(StringView text, int caret, int anchor)
	{
		Text.Set(text);
		Caret = caret;
		Anchor = anchor;
	}

	/// Makes this a copy of `other`.
	public void Set(UndoEntry other)
	{
		if (other === this)
			return;
		Text.Set(other.Text);
		Caret = other.Caret;
		Anchor = other.Anchor;
	}
}

class UndoStack
{
	private List<UndoEntry> mUndo = new .() ~ DeleteContainerAndItems!(_);
	private List<UndoEntry> mRedo = new .() ~ DeleteContainerAndItems!(_);
	private int mMaxEntries = 100;

	public bool CanUndo => mUndo.Count != 0;
	public bool CanRedo => mRedo.Count != 0;
	public int UndoCount => mUndo.Count;
	public int RedoCount => mRedo.Count;

	/// The most entries each stack keeps (1 at least): past it, the oldest goes.
	public int MaxEntries
	{
		get => mMaxEntries;
		set => mMaxEntries = Math.Max(1, value);
	}

	/// Remembers the state before an edit; what was undone can no longer be redone.
	public void Push(StringView text, int caret, int anchor)
	{
		ClearAndDeleteItems!(mRedo);
		PushBounded(mUndo, new UndoEntry(text, caret, anchor));
	}

	/// Steps back: `current` (copied) goes onto the redo stack and the state before it comes out in
	/// `outEntry`.
	public bool Undo(UndoEntry current, UndoEntry outEntry) => Step(mUndo, mRedo, current, outEntry);

	/// Steps forward again: `current` (copied) goes back onto the undo stack.
	public bool Redo(UndoEntry current, UndoEntry outEntry) => Step(mRedo, mUndo, current, outEntry);

	public void Clear()
	{
		ClearAndDeleteItems!(mUndo);
		ClearAndDeleteItems!(mRedo);
	}

	// Takes ownership of `entry`.
	private void PushBounded(List<UndoEntry> stack, UndoEntry entry)
	{
		if (stack.Count >= mMaxEntries)
		{
			delete stack[0]; // the oldest goes
			stack.RemoveAt(0);
		}
		stack.Add(entry);
	}

	private bool Step(List<UndoEntry> from, List<UndoEntry> to, UndoEntry current, UndoEntry outEntry)
	{
		if (from.Count == 0)
			return false;
		let saved = new UndoEntry();
		saved.Set(current);
		PushBounded(to, saved);
		let restored = from.PopBack();
		outEntry.Set(restored);
		delete restored;
		return true;
	}
}
