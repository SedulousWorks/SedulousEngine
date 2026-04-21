namespace Sedulous.Editor.Core;

using System;
using System.Collections;

/// Undo/redo stack for editor commands. Each editor page owns one.
class EditorCommandStack
{
	private List<IEditorCommand> mUndoStack = new .() ~ DeleteContainerAndItems!(_);
	private List<IEditorCommand> mRedoStack = new .() ~ DeleteContainerAndItems!(_);
	private int32 mGroupDepth;
	private CommandGroup mActiveGroup;
	private int32 mMaxEntries = 100;

	/// Whether there are commands to undo.
	public bool CanUndo => mUndoStack.Count > 0;

	/// Whether there are commands to redo.
	public bool CanRedo => mRedoStack.Count > 0;

	/// Description of the next undo command.
	public StringView UndoDescription =>
		mUndoStack.Count > 0 ? mUndoStack.Back.Description : "";

	/// Description of the next redo command.
	public StringView RedoDescription =>
		mRedoStack.Count > 0 ? mRedoStack.Back.Description : "";

	/// Execute a command and push it onto the undo stack.
	/// Clears the redo stack (new action invalidates redo history).
	public void Execute(IEditorCommand command)
	{
		command.Execute();

		if (mActiveGroup != null)
		{
			mActiveGroup.Add(command);
			return;
		}

		// Try to merge with the top of the undo stack.
		if (mUndoStack.Count > 0)
		{
			let top = mUndoStack.Back;
			if (top.CanMergeWith(command))
			{
				top.MergeWith(command);
				command.Dispose();
				delete command;
				ClearRedoStack();
				return;
			}
		}

		PushUndo(command);
		ClearRedoStack();
	}

	/// Undo the last command.
	public void Undo()
	{
		if (mUndoStack.Count == 0) return;

		let command = mUndoStack.PopBack();
		command.Undo();
		mRedoStack.Add(command);
	}

	/// Redo the last undone command.
	public void Redo()
	{
		if (mRedoStack.Count == 0) return;

		let command = mRedoStack.PopBack();
		command.Execute();
		mUndoStack.Add(command);
	}

	/// Begin a command group. All commands until EndGroup are atomic.
	public void BeginGroup(StringView description)
	{
		if (mGroupDepth == 0)
			mActiveGroup = new CommandGroup(description);
		mGroupDepth++;
	}

	/// End a command group. Pushes the group as a single undo entry.
	public void EndGroup()
	{
		if (mGroupDepth <= 0) return;
		mGroupDepth--;

		if (mGroupDepth == 0 && mActiveGroup != null)
		{
			if (mActiveGroup.IsEmpty)
			{
				delete mActiveGroup;
			}
			else
			{
				PushUndo(mActiveGroup);
				ClearRedoStack();
			}
			mActiveGroup = null;
		}
	}

	/// Clear all undo/redo history.
	public void Clear()
	{
		ClearUndoStack();
		ClearRedoStack();
	}

	private void PushUndo(IEditorCommand command)
	{
		mUndoStack.Add(command);

		// Trim oldest entries if over limit.
		while (mUndoStack.Count > mMaxEntries)
		{
			let oldest = mUndoStack.PopFront();
			oldest.Dispose();
			delete oldest;
		}
	}

	private void ClearRedoStack()
	{
		for (let cmd in mRedoStack)
		{
			cmd.Dispose();
			delete cmd;
		}
		mRedoStack.Clear();
	}

	private void ClearUndoStack()
	{
		for (let cmd in mUndoStack)
		{
			cmd.Dispose();
			delete cmd;
		}
		mUndoStack.Clear();
	}
}
