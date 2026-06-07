namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;

class UndoStackTests
{
	[Test]
	public static void Empty_CannotUndo()
	{
		let stack = scope UndoStack();
		Test.Assert(!stack.CanUndo);
		Test.Assert(!stack.CanRedo);
	}

	[Test]
	public static void PushState_CanUndo()
	{
		let stack = scope UndoStack();
		stack.PushState("hello", 5, 5);
		Test.Assert(stack.CanUndo);
		Test.Assert(stack.UndoCount == 1);
	}

	[Test]
	public static void Undo_RestoresState()
	{
		let stack = scope UndoStack();
		stack.PushState("hello", 3, 3);

		let restored = scope String();
		int32 cursor = 0, anchor = 0;
		let result = stack.Undo("hello world", 11, 11, restored, out cursor, out anchor);

		Test.Assert(result);
		Test.Assert(restored == "hello");
		Test.Assert(cursor == 3);
		Test.Assert(anchor == 3);
	}

	[Test]
	public static void Undo_PushesToRedo()
	{
		let stack = scope UndoStack();
		stack.PushState("a", 1, 1);

		let restored = scope String();
		int32 c = 0, a = 0;
		stack.Undo("b", 1, 1, restored, out c, out a);

		Test.Assert(stack.CanRedo);
		Test.Assert(stack.RedoCount == 1);
	}

	[Test]
	public static void Redo_RestoresState()
	{
		let stack = scope UndoStack();
		stack.PushState("original", 3, 3);

		let text1 = scope String();
		int32 c1 = 0, a1 = 0;
		stack.Undo("modified", 8, 8, text1, out c1, out a1);

		let text2 = scope String();
		int32 c2 = 0, a2 = 0;
		let result = stack.Redo(text1, c1, a1, text2, out c2, out a2);

		Test.Assert(result);
		Test.Assert(text2 == "modified");
		Test.Assert(c2 == 8);
	}

	[Test]
	public static void PushState_ClearsRedo()
	{
		let stack = scope UndoStack();
		stack.PushState("a", 1, 1);

		let text = scope String();
		int32 c = 0, a = 0;
		stack.Undo("b", 1, 1, text, out c, out a);
		Test.Assert(stack.CanRedo);

		stack.PushState("c", 1, 1);
		Test.Assert(!stack.CanRedo);
	}

	[Test]
	public static void MaxEntries_DropsOldest()
	{
		let stack = scope UndoStack();
		stack.MaxEntries = 3;

		stack.PushState("a", 0, 0);
		stack.PushState("b", 0, 0);
		stack.PushState("c", 0, 0);
		Test.Assert(stack.UndoCount == 3);

		stack.PushState("d", 0, 0); // should drop "a"
		Test.Assert(stack.UndoCount == 3);

		// Undo pops most recent: d, then c, then b (not a - it was dropped)
		let text = scope String();
		int32 cursor = 0, anchor = 0;
		stack.Undo("current", 0, 0, text, out cursor, out anchor);
		Test.Assert(text == "d");

		text.Clear();
		stack.Undo(text, 0, 0, text, out cursor, out anchor);
		Test.Assert(text == "c");

		text.Clear();
		stack.Undo(text, 0, 0, text, out cursor, out anchor);
		Test.Assert(text == "b");

		// No more - "a" was dropped
		text.Clear();
		Test.Assert(!stack.Undo(text, 0, 0, text, out cursor, out anchor));
	}

	[Test]
	public static void Clear_EmptiesAll()
	{
		let stack = scope UndoStack();
		stack.PushState("a", 0, 0);
		stack.PushState("b", 0, 0);

		let text = scope String();
		int32 c = 0, a = 0;
		stack.Undo("c", 0, 0, text, out c, out a);

		stack.Clear();
		Test.Assert(!stack.CanUndo);
		Test.Assert(!stack.CanRedo);
		Test.Assert(stack.UndoCount == 0);
		Test.Assert(stack.RedoCount == 0);
	}
}
