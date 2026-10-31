using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI;

/// A fixed capacity undo and redo stack for text editing.
class UndoStack
{
	private List<UndoEntry> mUndoList = new .() ~ DeleteContainerAndItems!(_);
	private List<UndoEntry> mRedoList = new .() ~ DeleteContainerAndItems!(_);
	private int32 mMaxEntries = 100;

	public bool CanUndo => !mUndoList.IsEmpty;
	public bool CanRedo => !mRedoList.IsEmpty;
	public int32 UndoCount => (int32)mUndoList.Count;
	public int32 RedoCount => (int32)mRedoList.Count;

	public int32 MaxEntries
	{
		get => mMaxEntries;
		set => mMaxEntries = Max(1, value);
	}

	/// Pushes the current state onto the undo stack, and CLEARS the redo stack: editing after
	/// undoing abandons the branch that was undone.
	public void PushState(StringView text, int32 cursorPos, int32 anchorPos)
	{
		ClearRedo();

		// At capacity the OLDEST goes, so a long session keeps its recent history.
		if ((int32)mUndoList.Count >= mMaxEntries)
		{
			delete mUndoList[0];
			mUndoList.RemoveAt(0);
		}

		mUndoList.Add(new UndoEntry(text, cursorPos, anchorPos));
	}

	/// Pops the previous state, pushing the current one onto the redo stack.
	public bool Undo(StringView currentText, int32 currentCursor, int32 currentAnchor,
		String outText, ref int32 outCursor, ref int32 outAnchor)
	{
		outCursor = 0;
		outAnchor = 0;

		if (mUndoList.IsEmpty)
			return false;

		mRedoList.Add(new UndoEntry(currentText, currentCursor, currentAnchor));

		let entry = mUndoList.PopBack();
		defer delete entry;
		outText.Set(entry.Text);
		outCursor = entry.CursorPos;
		outAnchor = entry.AnchorPos;
		return true;
	}

	/// Pops the next state, pushing the current one back onto the undo stack.
	public bool Redo(StringView currentText, int32 currentCursor, int32 currentAnchor,
		String outText, ref int32 outCursor, ref int32 outAnchor)
	{
		outCursor = 0;
		outAnchor = 0;

		if (mRedoList.IsEmpty)
			return false;

		// Pushed WITHOUT clearing redo, which is what lets redo walk forward repeatedly.
		if ((int32)mUndoList.Count >= mMaxEntries)
		{
			delete mUndoList[0];
			mUndoList.RemoveAt(0);
		}
		mUndoList.Add(new UndoEntry(currentText, currentCursor, currentAnchor));

		let entry = mRedoList.PopBack();
		defer delete entry;
		outText.Set(entry.Text);
		outCursor = entry.CursorPos;
		outAnchor = entry.AnchorPos;
		return true;
	}

	public void Clear()
	{
		ClearAndDeleteItems!(mUndoList);
		ClearRedo();
	}

	private void ClearRedo()
	{
		ClearAndDeleteItems!(mRedoList);
	}
}
