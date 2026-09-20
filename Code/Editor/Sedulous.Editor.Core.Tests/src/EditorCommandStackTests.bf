using System;
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
}
