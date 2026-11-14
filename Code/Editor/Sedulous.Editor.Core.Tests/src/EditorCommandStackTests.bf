using System;
using Sedulous.Core;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Core.Tests;

/// The undo spine's semantics: execute, undo, redo; a failed execute dropped; the redo tail
/// truncated; same typed merge; groups atomic, coalescing and lockable; the change hook; and
/// the Simulate lock.
static class EditorCommandStackTests
{
	/// Adds a delta to a shared counter; merges by adopting the newer delta.
	private class AddCommand : EditorCommand
	{
		private int32* mTarget;
		private int32 mDelta;
		private int32 mApplied = 0;
		private bool mMergeable;

		public this(int32* target, int32 delta, bool mergeable = false)
		{
			mTarget = target;
			mDelta = delta;
			mMergeable = mergeable;
		}

		public override bool Execute()
		{
			// A merged re-execution first reverts what it applied before.
			if (mApplied != 0)
				*mTarget -= mApplied;
			*mTarget += mDelta;
			mApplied = mDelta;
			return true;
		}

		public override void Undo()
		{
			*mTarget -= mApplied;
			mApplied = 0;
		}

		public override StringView TypeId => "add";

		public override bool MergeInto(EditorCommand previous)
		{
			if (!mMergeable)
				return false;
			let prev = (AddCommand)previous;
			if (!prev.mMergeable || (prev.mTarget != mTarget))
				return false;
			// Absorbed: the previous command now applies the NEW value.
			prev.mDelta = mDelta;
			return true;
		}
	}

	private class FailCommand : EditorCommand
	{
		public override bool Execute() => false;
		public override void Undo() {}
		public override StringView TypeId => "fail";
	}

	private class SetCommand : EditorCommand
	{
		private int32* mSlot;
		private int32 mTo;
		private int32 mFrom = 0;
		public this(int32* slot, int32 to) { mSlot = slot; mTo = to; }
		public override bool Execute() { mFrom = *mSlot; *mSlot = mTo; return true; }
		public override void Undo() { *mSlot = mFrom; }
		public override StringView TypeId => "test.set";
	}

	[Test]
	public static void ExecuteUndoRedo()
	{
		let stack = scope EditorCommandStack();
		int32 value = 0;
		Test.Assert(!stack.CanUndo && !stack.CanRedo);
		Test.Assert(stack.Execute(new AddCommand(&value, 5)));
		Test.Assert(stack.Execute(new AddCommand(&value, 3)));
		Test.Assert(value == 8);
		Test.Assert(stack.CanUndo);
		stack.Undo();
		Test.Assert(value == 5);
		Test.Assert(stack.CanRedo);
		stack.Undo();
		Test.Assert(value == 0);
		Test.Assert(!stack.CanUndo);
		stack.Redo();
		Test.Assert(value == 5);
		stack.Redo();
		Test.Assert(value == 8);
		Test.Assert(!stack.CanRedo);
	}

	[Test]
	public static void AFailedExecuteIsDroppedNotPushed()
	{
		let stack = scope EditorCommandStack();
		int32 value = 0;
		Test.Assert(stack.Execute(new AddCommand(&value, 1)));
		Test.Assert(!stack.Execute(new FailCommand()));
		Test.Assert(stack.Count == 1, "only the add");
		stack.Undo();
		Test.Assert(value == 0);
	}

	[Test]
	public static void ANewCommandTruncatesTheRedoTail()
	{
		let stack = scope EditorCommandStack();
		int32 value = 0;
		Test.Assert(stack.Execute(new AddCommand(&value, 1)));
		Test.Assert(stack.Execute(new AddCommand(&value, 2)));
		stack.Undo();
		Test.Assert(stack.CanRedo);
		Test.Assert(stack.Execute(new AddCommand(&value, 10)), "truncates the +2 redo entry");
		Test.Assert(value == 11);
		Test.Assert(!stack.CanRedo);
		stack.Undo();
		stack.Undo();
		Test.Assert(value == 0);
		Test.Assert(!stack.CanUndo);
	}

	[Test]
	public static void SameTypedMergeCoalescesADragIntoOneEntry()
	{
		let stack = scope EditorCommandStack();
		int32 value = 0;
		Test.Assert(stack.Execute(new AddCommand(&value, 1, true)));
		Test.Assert(stack.Execute(new AddCommand(&value, 2, true)));
		Test.Assert(stack.Execute(new AddCommand(&value, 3, true)));
		Test.Assert(value == 3, "the merged command re-applies the newest value");
		Test.Assert(stack.Count == 1);
		stack.Undo();
		Test.Assert(value == 0);
		Test.Assert(!stack.CanUndo);
		stack.Redo();
		Test.Assert(value == 3);
	}

	[Test]
	public static void NonMergeableCommandsDoNotMerge()
	{
		let stack = scope EditorCommandStack();
		int32 value = 0;
		Test.Assert(stack.Execute(new AddCommand(&value, 1)));
		Test.Assert(stack.Execute(new AddCommand(&value, 2)));
		Test.Assert(stack.Count == 2);
	}

	[Test]
	public static void GroupsUndoAndRedoAtomically()
	{
		let stack = scope EditorCommandStack();
		int32 value = 0;
		stack.BeginGroup("spawn");
		Test.Assert(stack.Execute(new AddCommand(&value, 1)));
		Test.Assert(stack.Execute(new AddCommand(&value, 2)));
		Test.Assert(!stack.CanUndo, "unavailable inside an open group");
		stack.EndGroup();
		Test.Assert(value == 3);
		stack.Undo();
		Test.Assert(value == 0);
		Test.Assert(!stack.CanUndo);
		stack.Redo();
		Test.Assert(value == 3);
		Test.Assert(!stack.CanRedo);
	}

	[Test]
	public static void ConsecutiveSameTypedGroupsCoalesce()
	{
		let stack = scope EditorCommandStack();
		int32 value = 0;
		stack.BeginGroup("move");
		Test.Assert(stack.Execute(new AddCommand(&value, 1)));
		stack.EndGroup();
		stack.BeginGroup("move");
		Test.Assert(stack.Execute(new AddCommand(&value, 2)));
		stack.EndGroup();
		Test.Assert(value == 3);
		stack.Undo();
		Test.Assert(value == 0, "ONE undo reverts both");
		Test.Assert(!stack.CanUndo);
	}

	[Test]
	public static void AnEmptyGroupLeavesNoUndoStep()
	{
		let stack = scope EditorCommandStack();
		int32 value = 0;
		int changes = 0;
		stack.OnChanged = new [&changes]() => { changes++; };

		stack.BeginGroup("mcp");
		stack.EndGroup(); // nothing inside
		Test.Assert(stack.Count == 0);
		Test.Assert(!stack.CanUndo);
		Test.Assert(changes == 0, "nobody told: nothing changed");

		// A group whose only command was refused is empty too; the step before it stands alone.
		Test.Assert(stack.Execute(new AddCommand(&value, 5)));
		let countBefore = stack.Count;
		stack.BeginGroup("mcp");
		Test.Assert(!stack.Execute(new FailCommand()));
		stack.EndGroup();
		Test.Assert(stack.Count == countBefore);
		Test.Assert(stack.UndoIndex == 0);
		stack.Undo();
		Test.Assert(value == 0);
		Test.Assert(!stack.CanUndo);
	}

	[Test]
	public static void LockGroupPreventsCoalescing()
	{
		let stack = scope EditorCommandStack();
		int32 value = 0;
		stack.BeginGroup("move");
		Test.Assert(stack.Execute(new AddCommand(&value, 1)));
		stack.EndGroup();
		stack.LockGroup();
		stack.BeginGroup("move");
		Test.Assert(stack.Execute(new AddCommand(&value, 2)));
		stack.EndGroup();
		Test.Assert(value == 3);
		stack.Undo();
		Test.Assert(value == 1, "only the second group reverted");
		stack.Undo();
		Test.Assert(value == 0);
	}

	[Test]
	public static void DifferentTypedGroupsDoNotCoalesce()
	{
		let stack = scope EditorCommandStack();
		int32 value = 0;
		stack.BeginGroup("move");
		Test.Assert(stack.Execute(new AddCommand(&value, 1)));
		stack.EndGroup();
		stack.BeginGroup("rotate");
		Test.Assert(stack.Execute(new AddCommand(&value, 2)));
		stack.EndGroup();
		stack.Undo();
		Test.Assert(value == 1);
		stack.Undo();
		Test.Assert(value == 0);
	}

	[Test]
	public static void AnEmptyGroupRoundTripsUndoAndRedo()
	{
		let stack = scope EditorCommandStack();
		int32 value = 0;
		// The play mode fence pattern: an empty group as a stack marker.
		stack.BeginGroup("fence");
		stack.EndGroup();
		Test.Assert(stack.Execute(new AddCommand(&value, 1)));
		stack.Undo();
		Test.Assert(value == 0);
		stack.Undo();
		Test.Assert(!stack.CanUndo);
		stack.Redo();
		stack.Redo();
		Test.Assert(value == 1);
	}

	[Test]
	public static void OnChangedFiresOnMutations()
	{
		let stack = scope EditorCommandStack();
		int32 value = 0;
		int32 changes = 0;
		stack.OnChanged = new [&changes]() => { changes++; };
		Test.Assert(stack.Execute(new AddCommand(&value, 1)));
		Test.Assert(changes == 1);
		stack.Undo();
		Test.Assert(changes == 2);
		stack.Redo();
		Test.Assert(changes == 3);
		stack.Clear();
		Test.Assert(changes == 4);
		Test.Assert((stack.Count == 0) && !stack.CanUndo);
	}

	[Test]
	public static void ALockedStackRefusesExecuteUndoAndRedo()
	{
		let stack = scope EditorCommandStack();
		int32 value = 0;
		Test.Assert(stack.Execute(new SetCommand(&value, 1)));
		Test.Assert(value == 1);
		stack.IsLocked = true;
		Test.Assert(!stack.Execute(new SetCommand(&value, 2)), "refused while locked");
		Test.Assert(value == 1);
		stack.Undo();
		Test.Assert(value == 1, "undo refused while locked");
		stack.IsLocked = false;
		stack.Undo();
		Test.Assert(value == 0);
		stack.Redo();
		Test.Assert(value == 1);
		stack.IsLocked = true;
		stack.Redo();
		stack.Undo();
		Test.Assert(value == 1, "neither moves while locked");
	}

	[Test]
	public static void TheSavedPointFollowsUndoAndRedo()
	{
		let stack = scope EditorCommandStack();
		int32 value = 0;
		Test.Assert(stack.IsAtSaved, "an empty history is what was loaded");

		Test.Assert(stack.Execute(new AddCommand(&value, 1)));
		Test.Assert(stack.Execute(new AddCommand(&value, 2)));
		Test.Assert(!stack.IsAtSaved);
		stack.MarkSaved();
		Test.Assert(stack.IsAtSaved);

		Test.Assert(stack.Execute(new AddCommand(&value, 4)));
		Test.Assert(!stack.IsAtSaved);
		stack.Undo();
		Test.Assert(stack.IsAtSaved, "undone back to what the file holds");
		stack.Undo();
		Test.Assert(!stack.IsAtSaved);
		Test.Assert(value == 1);

		// Past the save: going back to it redoes.
		Test.Assert(stack.ReturnToSaved());
		Test.Assert((value == 3) && stack.IsAtSaved);

		// After the save: going back to it undoes.
		stack.Redo();
		Test.Assert(value == 7);
		Test.Assert(stack.ReturnToSaved());
		Test.Assert(value == 3);

		// Dropping the history keeps the point saved when it was.
		stack.Clear();
		Test.Assert(stack.IsAtSaved);
		Test.Assert(stack.Execute(new AddCommand(&value, 1)));
		stack.Clear();
		Test.Assert(!stack.IsAtSaved, "the history is gone, and the change it made is not saved");
	}

	[Test]
	public static void AStepBelowTheSaveRemovesTheSaveFromTheHistory()
	{
		let stack = scope EditorCommandStack();
		int32 value = 0;
		Test.Assert(stack.Execute(new AddCommand(&value, 1)));
		Test.Assert(stack.Execute(new AddCommand(&value, 2)));
		stack.MarkSaved(); // value 3, two steps
		stack.Undo();
		stack.Undo();
		Test.Assert(stack.Execute(new AddCommand(&value, 10))); // the saved step is dropped
		Test.Assert(stack.Execute(new AddCommand(&value, 20))); // two steps long again
		Test.Assert(value == 30);
		Test.Assert(!stack.IsAtSaved, "at the saved position, not the saved state");
		Test.Assert(!stack.ReturnToSaved());
		Test.Assert(value == 30, "nothing changed");
	}

	[Test]
	public static void AStepMergedIntoTheSavedOneRemovesTheSaveAndDropsTheRedoTail()
	{
		let stack = scope EditorCommandStack();
		int32 value = 0;
		Test.Assert(stack.Execute(new AddCommand(&value, 1, true)));
		stack.MarkSaved();
		Test.Assert(stack.Execute(new AddCommand(&value, 5, true))); // a drag continuing into the saved step
		Test.Assert(stack.Count == 1);
		Test.Assert(!stack.IsAtSaved);
		Test.Assert(!stack.ReturnToSaved());

		// A merge is a new step: what was undone before it no longer follows.
		let other = scope EditorCommandStack();
		int32 n = 0;
		Test.Assert(other.Execute(new AddCommand(&n, 1, true)));
		Test.Assert(other.Execute(new AddCommand(&n, 100)));
		other.Undo();
		Test.Assert(other.Execute(new AddCommand(&n, 2, true)));
		Test.Assert(!other.CanRedo);
		Test.Assert(n == 2);
	}

	[Test]
	public static void AGroupReopenedOverTheSaveOrASaveInsideAGroupIsNoSavedPoint()
	{
		let stack = scope EditorCommandStack();
		int32 value = 0;
		stack.BeginGroup("drag");
		Test.Assert(stack.Execute(new AddCommand(&value, 1)));
		stack.EndGroup();
		stack.MarkSaved();
		stack.BeginGroup("drag"); // coalesces: the saved end marker is reopened
		Test.Assert(stack.Execute(new AddCommand(&value, 1)));
		stack.EndGroup();
		Test.Assert(!stack.IsAtSaved);
		Test.Assert(!stack.ReturnToSaved());

		let inside = scope EditorCommandStack();
		inside.BeginGroup("drag");
		Test.Assert(inside.Execute(new AddCommand(&value, 1)));
		inside.MarkSaved(); // no undo or redo lands mid-group
		Test.Assert(!inside.IsAtSaved);
		inside.EndGroup();
		Test.Assert(!inside.ReturnToSaved());
	}

	[Test]
	public static void ALockedStackDoesNotGoBackToTheSave()
	{
		let stack = scope EditorCommandStack();
		int32 value = 0;
		stack.MarkSaved();
		Test.Assert(stack.Execute(new AddCommand(&value, 1)));
		stack.IsLocked = true;
		Test.Assert(!stack.CanUndo && !stack.CanRedo);
		Test.Assert(!stack.ReturnToSaved());
		Test.Assert(value == 1);
	}

	/// A page over one number: its "file" holds `Stored`, and reading it again can be refused.
	private class NumberPage : EditorPage
	{
		public int32 Value = 0;
		public int32 Stored = 0;
		public int Reloads = 0;
		public bool Readable = true;

		public override StringView Title => "number";

		public override Result<void, ErrorCode> Save()
		{
			Stored = Value;
			ClearDirty();
			return .Ok;
		}

		public override bool ReloadFromSource()
		{
			Reloads++;
			if (!Readable)
				return false;
			Value = Stored;
			Commands.Clear();
			ClearDirty();
			return true;
		}
	}

	[Test]
	public static void DiscardGoesBackToTheLastSaveNotPastIt()
	{
		let page = scope NumberPage();
		Test.Assert(page.Commands.Execute(new AddCommand(&page.Value, 1)));
		Test.Assert(page.Save() case .Ok);
		Test.Assert(page.Commands.Execute(new AddCommand(&page.Value, 2)));
		Test.Assert(page.IsDirty);

		Test.Assert(page.DiscardChanges());
		Test.Assert(page.Value == 1, "the saved step stays applied");
		Test.Assert(!page.IsDirty);
		Test.Assert(page.Reloads == 0, "the history reached the save");

		// Undone past the save, Discard redoes back to it.
		Test.Assert(page.Commands.Execute(new AddCommand(&page.Value, 4)));
		Test.Assert(page.Save() case .Ok);
		page.Commands.Undo();
		Test.Assert(page.Value == 1);
		Test.Assert(page.IsDirty);
		Test.Assert(page.DiscardChanges());
		Test.Assert(page.Value == 5);
		Test.Assert(!page.IsDirty);
	}

	[Test]
	public static void UndoingBackToTheSaveMakesThePageClean()
	{
		let page = scope NumberPage();
		Test.Assert(page.Commands.Execute(new AddCommand(&page.Value, 1)));
		Test.Assert(page.IsDirty);
		page.Commands.Undo();
		Test.Assert(!page.IsDirty);
		page.MarkDirty(); // a change outside the history keeps it unsaved
		Test.Assert(page.IsDirty);
	}

	[Test]
	public static void DiscardReadsTheFileAgainWhenTheHistoryDoesNotReachTheSave()
	{
		let page = scope NumberPage();
		Test.Assert(page.Commands.Execute(new AddCommand(&page.Value, 1)));
		Test.Assert(page.Save() case .Ok);
		page.Commands.Undo();
		Test.Assert(page.Commands.Execute(new AddCommand(&page.Value, 7))); // drops the saved step
		Test.Assert(page.DiscardChanges());
		Test.Assert(page.Reloads == 1);
		Test.Assert(page.Value == 1);
		Test.Assert(!page.IsDirty);

		// A change made outside the history is undone only by reading the file.
		page.Value = 9;
		page.MarkDirty();
		Test.Assert(page.DiscardChanges());
		Test.Assert(page.Reloads == 2);
		Test.Assert(page.Value == 1);

		// A file that does not read keeps the edits, and says so.
		page.Readable = false;
		page.Value = 9;
		page.MarkDirty();
		Test.Assert(!page.DiscardChanges());
		Test.Assert(page.Value == 9);
		Test.Assert(page.IsDirty);
	}

	/// Discard on a locked history (Simulate) returns at once and keeps the edits; it looped on
	/// CanUndo while Undo refused.
	[Test]
	public static void DiscardOnALockedHistoryReturnsAtOnceAndKeepsTheEdits()
	{
		let page = scope NumberPage();
		Test.Assert(page.Commands.Execute(new AddCommand(&page.Value, 1)));
		page.Commands.IsLocked = true;
		Test.Assert(!page.DiscardChanges());
		Test.Assert(page.Value == 1);
		Test.Assert(page.IsDirty);
		Test.Assert(page.Reloads == 0);
	}
}
