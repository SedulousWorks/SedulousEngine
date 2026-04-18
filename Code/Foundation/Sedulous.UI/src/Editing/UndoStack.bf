namespace Sedulous.UI;

using System;
using System.Collections;

/// A single undo entry capturing text state.
public class UndoEntry
{
	public String Text ~ delete _;
	public int32 CursorPos;
	public int32 AnchorPos;

	public this(StringView text, int32 cursorPos, int32 anchorPos)
	{
		Text = new String(text);
		CursorPos = cursorPos;
		AnchorPos = anchorPos;
	}
}

/// Fixed-capacity undo/redo stack for text editing.
public class UndoStack
{
	private List<UndoEntry> mUndoList = new .() ~ DeleteContainerAndItems!(_);
	private List<UndoEntry> mRedoList = new .() ~ DeleteContainerAndItems!(_);
	private int32 mMaxEntries = 100;

	public bool CanUndo => mUndoList.Count > 0;
	public bool CanRedo => mRedoList.Count > 0;
	public int32 UndoCount => (int32)mUndoList.Count;
	public int32 RedoCount => (int32)mRedoList.Count;

	public int32 MaxEntries
	{
		get => mMaxEntries;
		set => mMaxEntries = Math.Max(1, value);
	}

	/// Push current state onto undo stack. Clears redo stack.
	public void PushState(StringView text, int32 cursorPos, int32 anchorPos)
	{
		ClearRedo();

		// Drop oldest if at capacity.
		if (mUndoList.Count >= mMaxEntries)
		{
			let oldest = mUndoList[0];
			delete oldest;
			mUndoList.RemoveAt(0);
		}

		mUndoList.Add(new UndoEntry(text, cursorPos, anchorPos));
	}

	/// Undo: pops previous state. Pushes current state onto redo stack.
	public bool Undo(StringView currentText, int32 currentCursor, int32 currentAnchor,
		String outText, out int32 outCursor, out int32 outAnchor)
	{
		outCursor = 0;
		outAnchor = 0;

		if (mUndoList.Count == 0)
			return false;

		// Push current state to redo.
		mRedoList.Add(new UndoEntry(currentText, currentCursor, currentAnchor));

		// Pop from undo.
		let entry = mUndoList.PopBack();
		outText.Set(entry.Text);
		outCursor = entry.CursorPos;
		outAnchor = entry.AnchorPos;
		delete entry;

		return true;
	}

	/// Redo: pops next state. Pushes current state onto undo stack.
	public bool Redo(StringView currentText, int32 currentCursor, int32 currentAnchor,
		String outText, out int32 outCursor, out int32 outAnchor)
	{
		outCursor = 0;
		outAnchor = 0;

		if (mRedoList.Count == 0)
			return false;

		// Push current state to undo (without clearing redo).
		if (mUndoList.Count >= mMaxEntries)
		{
			let oldest = mUndoList[0];
			delete oldest;
			mUndoList.RemoveAt(0);
		}
		mUndoList.Add(new UndoEntry(currentText, currentCursor, currentAnchor));

		// Pop from redo.
		let entry = mRedoList.PopBack();
		outText.Set(entry.Text);
		outCursor = entry.CursorPos;
		outAnchor = entry.AnchorPos;
		delete entry;

		return true;
	}

	/// Clear all undo and redo entries.
	public void Clear()
	{
		ClearList(mUndoList);
		ClearList(mRedoList);
	}

	private void ClearRedo()
	{
		ClearList(mRedoList);
	}

	private static void ClearList(List<UndoEntry> list)
	{
		for (let entry in list)
			delete entry;
		list.Clear();
	}
}
