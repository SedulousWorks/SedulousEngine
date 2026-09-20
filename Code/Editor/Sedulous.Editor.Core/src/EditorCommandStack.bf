using System;
using System.Collections;

namespace Sedulous.Editor.Core;

/// The editor's undo and redo spine, with the semantics Lumix's WorldEditor settled:
///
/// - a failed Execute is DROPPED, never pushed;
/// - a command merges into a same typed stack top, so a drag coalesces into one entry;
/// - BeginGroup/EndGroup transactions undo and redo atomically, and consecutive same typed
///   groups coalesce unless the earlier one was locked, so "create entity + add component"
///   stays apart from the next identical action.
///
/// Each editor page owns its own stack; the context routes Edit > Undo and Redo to the
/// active page's. Not thread safe: the editor's main thread only.
class EditorCommandStack
{
	private const String cBeginGroup = "__begin_group";
	private const String cEndGroup = "__end_group";

	/// Group brackets: inert markers on the stack that Undo and Redo unwind between.
	private class BeginGroupCommand : EditorCommand
	{
		public String GroupType = new .() ~ delete _;
		public this(StringView groupType) { GroupType.Set(groupType); }
		public override bool Execute() => true;
		public override void Undo() {}
		public override StringView TypeId => cBeginGroup;
	}

	private class EndGroupCommand : EditorCommand
	{
		public String GroupType = new .() ~ delete _;
		/// A locked group never coalesces with the next same typed one.
		public bool Locked = false;
		public this(StringView groupType) { GroupType.Set(groupType); }
		public override bool Execute() => true;
		public override void Undo() {}
		public override StringView TypeId => cEndGroup;
	}

	private List<EditorCommand> mStack = new .() ~ DeleteContainerAndItems!(_);
	/// The index of the last executed, undoable, entry.
	private int mUndoIndex = -1;
	private bool mInGroup = false;
	private String mGroupType = new .() ~ delete _;
	private bool mLocked = false;

	/// Fired after any change (execute, undo, redo, clear): the dirty tracking and refresh hook.
	public delegate void() OnChanged ~ delete _;

	/// While locked, the editor's Simulate mode, Execute, Undo and Redo refuse: runtime
	/// mutations do not belong on the edit history, and undoing into entities the simulation
	/// replaced, or the stop restore recreated, is a guid minefield.
	public bool IsLocked
	{
		get => mLocked;
		set => mLocked = value;
	}

	/// Entry count including the group markers, for diagnostics and tests.
	public int Count => mStack.Count;
	public int UndoIndex => mUndoIndex;

	public bool CanUndo => !mInGroup && (mUndoIndex >= 0);
	public bool CanRedo => !mInGroup && (mUndoIndex + 1 < mStack.Count);

	/// Executes and pushes `command`, TAKING OWNERSHIP. False, the command deleted and the
	/// stack untouched, when Execute failed. May merge into the current top instead of pushing.
	public bool Execute(EditorCommand command)
	{
		if ((command == null) || mLocked)
		{
			delete command;
			return false;
		}
		// A same typed merge against the undo top; the markers never match a real TypeId.
		if (mUndoIndex >= 0)
		{
			let top = mStack[mUndoIndex];
			if ((top.TypeId == command.TypeId) && command.MergeInto(top))
			{
				let ok = top.Execute();
				Runtime.Assert(ok, "re-executing a merged command must not fail");
				delete command;
				Notify();
				return true;
			}
		}
		if (!command.Execute())
		{
			delete command;
			return false;
		}
		TruncateRedo();
		mStack.Add(command);
		mUndoIndex++;
		Notify();
		return true;
	}

	public void Undo()
	{
		if (mLocked || !CanUndo)
			return;
		var i = mUndoIndex;
		if (mStack[i].TypeId == cEndGroup)
		{
			// The whole group: every real command back to the begin marker.
			i--;
			while ((i >= 0) && (mStack[i].TypeId != cBeginGroup))
			{
				mStack[i].Undo();
				i--;
			}
			Runtime.Assert(i >= 0, "unbalanced group markers");
			mUndoIndex = i - 1;
		}
		else
		{
			mStack[i].Undo();
			mUndoIndex = i - 1;
		}
		Notify();
	}

	public void Redo()
	{
		if (mLocked || !CanRedo)
			return;
		var i = mUndoIndex + 1;
		if (mStack[i].TypeId == cBeginGroup)
		{
			// The whole group forward to the end marker.
			i++;
			while ((i < mStack.Count) && (mStack[i].TypeId != cEndGroup))
			{
				let ok = mStack[i].Execute();
				Runtime.Assert(ok, "replaying a previously successful command must not fail");
				i++;
			}
			Runtime.Assert(i < mStack.Count, "unbalanced group markers");
			mUndoIndex = i;
		}
		else
		{
			let ok = mStack[i].Execute();
			Runtime.Assert(ok, "replaying a previously successful command must not fail");
			mUndoIndex = i;
		}
		Notify();
	}

	/// Opens a transaction: commands executed until EndGroup undo and redo as one unit.
	/// Consecutive groups of the same type coalesce, the previous group reopened, unless the
	/// previous one was locked. No nesting.
	public void BeginGroup(StringView groupType)
	{
		Runtime.Assert(!mInGroup, "no nested groups");
		TruncateRedo();
		// Coalesce: an unlocked end marker of the same group type on top is popped, so the
		// new commands append inside that group; its begin marker stays.
		if (mUndoIndex >= 0)
		{
			if (let end = mStack[mUndoIndex] as EndGroupCommand)
			{
				if (!end.Locked && (end.GroupType == groupType))
				{
					mStack.PopBack();
					delete end;
					mUndoIndex--;
					mInGroup = true;
					mGroupType.Set(groupType);
					return;
				}
			}
		}
		mStack.Add(new BeginGroupCommand(groupType));
		mUndoIndex++;
		mInGroup = true;
		mGroupType.Set(groupType);
	}

	public void EndGroup()
	{
		Runtime.Assert(mInGroup, "EndGroup without BeginGroup");
		mStack.Add(new EndGroupCommand(mGroupType));
		mUndoIndex++;
		mInGroup = false;
		Notify();
	}

	/// Keeps the most recent group from coalescing with the next same typed one.
	public void LockGroup()
	{
		for (int i = mUndoIndex; i >= 0; i--)
		{
			if (let end = mStack[i] as EndGroupCommand)
			{
				end.Locked = true;
				return;
			}
		}
	}

	public void Clear()
	{
		Runtime.Assert(!mInGroup, "Clear inside a group");
		ClearAndDeleteItems(mStack);
		mUndoIndex = -1;
		Notify();
	}

	private void TruncateRedo()
	{
		while (mStack.Count > mUndoIndex + 1)
		{
			let dropped = mStack.PopBack();
			delete dropped;
		}
	}

	private void Notify()
	{
		if (OnChanged != null)
			OnChanged();
	}
}
