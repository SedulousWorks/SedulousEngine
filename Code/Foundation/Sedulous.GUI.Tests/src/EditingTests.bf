using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// The input filter and the undo stack, copied from foundation.ui with their tests; the undo
/// stack's offsets are bytes here.
class EditingTests
{
	[Test]
	public static void NoneAcceptsAll()
	{
		let filter = scope InputFilter();
		Test.Assert(filter.Accept('a'));
		Test.Assert(filter.Accept('Z'));
		Test.Assert(filter.Accept('5'));
		Test.Assert(filter.Accept(' '));
		Test.Assert(filter.Accept('!'));
	}

	[Test]
	public static void DigitsAcceptsOnlyDigits()
	{
		let filter = InputFilter.Digits();
		defer delete filter;
		Test.Assert(filter.Accept('0'));
		Test.Assert(filter.Accept('5'));
		Test.Assert(filter.Accept('9'));
		Test.Assert(!filter.Accept('a'));
		Test.Assert(!filter.Accept(' '));
		Test.Assert(!filter.Accept('.'));
	}

	[Test]
	public static void HexDigitsAcceptsHexChars()
	{
		let filter = InputFilter.HexDigits();
		defer delete filter;
		Test.Assert(filter.Accept('0'));
		Test.Assert(filter.Accept('9'));
		Test.Assert(filter.Accept('a'));
		Test.Assert(filter.Accept('f'));
		Test.Assert(filter.Accept('A'));
		Test.Assert(filter.Accept('F'));
		Test.Assert(!filter.Accept('g'));
		Test.Assert(!filter.Accept('G'));
		Test.Assert(!filter.Accept(' '));
	}

	[Test]
	public static void CustomUsesDelegate()
	{
		let filter = scope InputFilter();
		filter.SetCustomFilter(new (c) => (c == 'x') || (c == 'y'));
		Test.Assert(filter.Accept('x'));
		Test.Assert(filter.Accept('y'));
		Test.Assert(!filter.Accept('z'));
		Test.Assert(!filter.Accept('a'));
	}

	// === UndoStack ===

	[Test]
	public static void PushThenUndoRestoresThePushedSnapshot()
	{
		let stack = scope UndoStack();
		Test.Assert(!stack.CanUndo);
		Test.Assert(!stack.CanRedo);

		stack.Push("a", 1, 1);
		Test.Assert(stack.CanUndo);
		Test.Assert(stack.UndoCount == 1);

		let entry = scope UndoEntry();
		Test.Assert(stack.Undo(scope UndoEntry("ab", 2, 2), entry));
		Test.Assert(entry.Text == "a");
		Test.Assert(entry.Caret == 1);
		Test.Assert(entry.Anchor == 1);
		Test.Assert(!stack.CanUndo);
		Test.Assert(stack.CanRedo); // the "ab" state went onto redo
	}

	[Test]
	public static void RedoRestoresTheStateUndoneAway()
	{
		let stack = scope UndoStack();
		stack.Push("a", 1, 1);
		let undone = scope UndoEntry();
		stack.Undo(scope UndoEntry("ab", 2, 2), undone);

		let redone = scope UndoEntry();
		Test.Assert(stack.Redo(undone, redone));
		Test.Assert(redone.Text == "ab");
		Test.Assert(redone.Caret == 2);
		Test.Assert(redone.Anchor == 2);
		Test.Assert(stack.CanUndo);
		Test.Assert(!stack.CanRedo);
	}

	[Test]
	public static void PushClearsTheRedoStack()
	{
		let stack = scope UndoStack();
		stack.Push("a", 1, 1);
		let entry = scope UndoEntry();
		stack.Undo(scope UndoEntry("ab", 2, 2), entry);
		Test.Assert(stack.CanRedo);

		stack.Push("new", 3, 3);
		Test.Assert(!stack.CanRedo); // redo cleared by the new push
	}

	[Test]
	public static void CapacityDropsTheOldestEntry()
	{
		let stack = scope UndoStack();
		stack.MaxEntries = 2;
		Test.Assert(stack.MaxEntries == 2);

		stack.Push("one", 0, 0);
		stack.Push("two", 0, 0);
		stack.Push("three", 0, 0); // drops "one"
		Test.Assert(stack.UndoCount == 2);

		let entry = scope UndoEntry();
		stack.Undo(scope UndoEntry("cur", 0, 0), entry);
		Test.Assert(entry.Text == "three");
		let again = scope UndoEntry();
		stack.Undo(entry, again);
		Test.Assert(again.Text == "two"); // "one" is gone
		Test.Assert(!stack.CanUndo);
	}

	[Test]
	public static void UndoAndRedoOnEmptyStacksReturnFalse()
	{
		let stack = scope UndoStack();
		let entry = scope UndoEntry();
		Test.Assert(!stack.Undo(scope UndoEntry("x", 0, 0), entry));
		Test.Assert(!stack.Redo(scope UndoEntry("x", 0, 0), entry));

		stack.Push("a", 0, 0);
		stack.Clear();
		Test.Assert(!stack.CanUndo);
		Test.Assert(!stack.CanRedo);
	}
}
