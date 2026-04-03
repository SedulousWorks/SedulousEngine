using System;
using System.Collections;

namespace Sedulous.GUI;

/// The type of text editing action for undo/redo.
public enum TextEditActionType
{
	/// Text was inserted.
	Insert,
	/// Text was deleted.
	Delete,
	/// Text was replaced (selection replaced with new text).
	Replace
}

/// Represents a text editing action that can be undone/redone.
public class TextEditAction
{
	/// The type of action.
	public TextEditActionType Type;
	/// The position where the action occurred.
	public int32 Position;
	/// The text that was removed (for Delete/Replace actions).
	public String OldText ~ delete _;
	/// The text that was inserted (for Insert/Replace actions).
	public String NewText ~ delete _;
	/// Caret position before the action.
	public int32 OldCaretPos;
	/// Caret position after the action.
	public int32 NewCaretPos;
	/// Selection anchor before the action (-1 if none).
	public int32 OldSelectionAnchor = -1;
	/// Timestamp when the action was created (for merge decisions).
	public double Timestamp;

	public this()
	{
		OldText = new String();
		NewText = new String();
	}

	/// Creates a copy of this action.
	public TextEditAction Clone()
	{
		let copy = new TextEditAction();
		copy.Type = Type;
		copy.Position = Position;
		copy.OldText.Set(OldText);
		copy.NewText.Set(NewText);
		copy.OldCaretPos = OldCaretPos;
		copy.NewCaretPos = NewCaretPos;
		copy.OldSelectionAnchor = OldSelectionAnchor;
		copy.Timestamp = Timestamp;
		return copy;
	}

	/// Checks if this action can be merged with another insert action.
	/// Merge conditions: same position continuation, within time limit, no word boundary.
	public bool CanMergeWith(TextEditAction other, double currentTime)
	{
		// Only merge Insert actions
		if (Type != .Insert || other.Type != .Insert)
			return false;

		// Must be within 1 second
		if (currentTime - Timestamp > 1.0)
			return false;

		// Must be consecutive (new insert at end of previous)
		if (other.Position != Position + NewText.Length)
			return false;

		// Don't merge if previous text ends with word boundary
		if (NewText.Length > 0)
		{
			let lastChar = NewText[NewText.Length - 1];
			if (lastChar == ' ' || lastChar == '\t' || lastChar == '\n' ||
				lastChar == '.' || lastChar == ',' || lastChar == ';' ||
				lastChar == ':' || lastChar == '!' || lastChar == '?')
				return false;
		}

		return true;
	}

	/// Merges another insert action into this one.
	public void MergeWith(TextEditAction other)
	{
		NewText.Append(other.NewText);
		NewCaretPos = other.NewCaretPos;
		Timestamp = other.Timestamp;
	}
}

/// Manages undo/redo history for text editing.
public class UndoStack
{
	private List<TextEditAction> mUndoStack = new .() ~ DeleteContainerAndItems!(_);
	private List<TextEditAction> mRedoStack = new .() ~ DeleteContainerAndItems!(_);
	private int32 mMaxStackSize = 100;

	/// Maximum number of actions to keep in the undo stack.
	public int32 MaxStackSize
	{
		get => mMaxStackSize;
		set => mMaxStackSize = Math.Max(1, value);
	}

	/// Whether an undo operation is available.
	public bool CanUndo => mUndoStack.Count > 0;

	/// Whether a redo operation is available.
	public bool CanRedo => mRedoStack.Count > 0;

	/// Records an action for undo support.
	/// Clears the redo stack.
	public void RecordAction(TextEditAction action)
	{
		// Clear redo stack when new action is recorded
		ClearRedo();

		// Try to merge with previous action
		if (mUndoStack.Count > 0)
		{
			let lastAction = mUndoStack[mUndoStack.Count - 1];
			if (lastAction.CanMergeWith(action, action.Timestamp))
			{
				lastAction.MergeWith(action);
				delete action;
				return;
			}
		}

		// Add to undo stack
		mUndoStack.Add(action);

		// Trim if exceeds max size
		while (mUndoStack.Count > mMaxStackSize)
		{
			let removed = mUndoStack.PopFront();
			delete removed;
		}
	}

	/// Records an insert action with automatic merging for consecutive typing.
	public void RecordInsert(int32 position, StringView text, int32 oldCaret, int32 newCaret, double timestamp)
	{
		let action = new TextEditAction();
		action.Type = .Insert;
		action.Position = position;
		action.NewText.Set(text);
		action.OldCaretPos = oldCaret;
		action.NewCaretPos = newCaret;
		action.Timestamp = timestamp;
		RecordAction(action);
	}

	/// Records a delete action.
	public void RecordDelete(int32 position, StringView deletedText, int32 oldCaret, int32 newCaret, double timestamp)
	{
		let action = new TextEditAction();
		action.Type = .Delete;
		action.Position = position;
		action.OldText.Set(deletedText);
		action.OldCaretPos = oldCaret;
		action.NewCaretPos = newCaret;
		action.Timestamp = timestamp;
		RecordAction(action);
	}

	/// Records a replace action (selection replaced with new text).
	public void RecordReplace(int32 position, StringView oldText, StringView newText, int32 oldCaret, int32 newCaret, int32 oldAnchor, double timestamp)
	{
		let action = new TextEditAction();
		action.Type = .Replace;
		action.Position = position;
		action.OldText.Set(oldText);
		action.NewText.Set(newText);
		action.OldCaretPos = oldCaret;
		action.NewCaretPos = newCaret;
		action.OldSelectionAnchor = oldAnchor;
		action.Timestamp = timestamp;
		RecordAction(action);
	}

	/// Pops the most recent undo action.
	/// The caller takes ownership of the returned action.
	public TextEditAction PopUndo()
	{
		if (mUndoStack.Count == 0)
			return null;

		let action = mUndoStack.PopBack();
		mRedoStack.Add(action.Clone());
		return action;
	}

	/// Pops the most recent redo action.
	/// The caller takes ownership of the returned action.
	public TextEditAction PopRedo()
	{
		if (mRedoStack.Count == 0)
			return null;

		let action = mRedoStack.PopBack();
		// Re-add to undo stack without merging
		mUndoStack.Add(action.Clone());
		return action;
	}

	/// Clears all undo history.
	public void Clear()
	{
		ClearAndDeleteItems!(mUndoStack);
		ClearAndDeleteItems!(mRedoStack);
	}

	/// Clears the redo stack.
	private void ClearRedo()
	{
		ClearAndDeleteItems!(mRedoStack);
	}

	/// Breaks the merge chain - next insert won't merge with previous.
	public void BreakMergeChain()
	{
		// Set timestamp to past so next action won't merge
		if (mUndoStack.Count > 0)
			mUndoStack[mUndoStack.Count - 1].Timestamp = 0;
	}
}
