namespace Sedulous.GUI.Tests;

using System;

class EditableLabelTests
{
	[Test]
	public static void EditableLabel_StartsInLabelMode()
	{
		let el = scope EditableLabel();
		Test.Assert(!el.IsEditing);
		Test.Assert(el.IsReadOnly == true);
		Test.Assert(el.IsFocusable == false);
		Test.Assert(el.Cursor == .Arrow);
	}

	[Test]
	public static void EditableLabel_BeginEditTransitions()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let el = new EditableLabel();
		el.SetText("Hello");
		root.AddView(el);
		TestSetup.Layout(ctx, root);

		el.BeginEdit();

		Test.Assert(el.IsEditing);
		Test.Assert(el.IsReadOnly == false);
		Test.Assert(el.IsFocusable == true);
		Test.Assert(el.Cursor == .IBeam);
	}

	[Test]
	public static void EditableLabel_CommitEditFiresEvent()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let el = new EditableLabel();
		el.SetText("Hello");
		root.AddView(el);
		TestSetup.Layout(ctx, root);

		bool committed = false;
		String committedText = scope .();
		el.OnRenameCommitted.Add(new [&committed, =committedText] (label, text) =>
		{
			committed = true;
			committedText.Set(text);
		});

		el.BeginEdit();

		// Modify text: select all, type new text.
		el.[Friend]mBehavior.HandleKeyDown(.A, .Ctrl);
		el.[Friend]mBehavior.HandleTextInput('W');
		el.[Friend]mBehavior.HandleTextInput('o');
		el.[Friend]mBehavior.HandleTextInput('r');
		el.[Friend]mBehavior.HandleTextInput('l');
		el.[Friend]mBehavior.HandleTextInput('d');

		el.CommitEdit();

		Test.Assert(committed);
		Test.Assert(committedText == "World");
		Test.Assert(!el.IsEditing);
	}

	[Test]
	public static void EditableLabel_CancelEditRestoresText()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let el = new EditableLabel();
		el.SetText("Original");
		root.AddView(el);
		TestSetup.Layout(ctx, root);

		bool cancelled = false;
		el.OnRenameCancelled.Add(new [&cancelled] (label) => { cancelled = true; });

		el.BeginEdit();

		// Type some text.
		el.[Friend]mBehavior.HandleKeyDown(.A, .Ctrl);
		el.[Friend]mBehavior.HandleTextInput('X');

		el.CancelEdit();

		Test.Assert(cancelled);
		Test.Assert(el.Text == "Original");
		Test.Assert(!el.IsEditing);
	}

	[Test]
	public static void EditableLabel_EmptyTextRejected()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let el = new EditableLabel();
		el.SetText("Test");
		root.AddView(el);
		TestSetup.Layout(ctx, root);

		bool committed = false;
		bool cancelled = false;
		el.OnRenameCommitted.Add(new [&committed] (label, text) => { committed = true; });
		el.OnRenameCancelled.Add(new [&cancelled] (label) => { cancelled = true; });

		el.BeginEdit();

		// Delete all text.
		el.[Friend]mBehavior.HandleKeyDown(.A, .Ctrl);
		el.[Friend]mBehavior.HandleKeyDown(.Delete, .None);

		el.CommitEdit();

		// Empty text should trigger cancel, not commit.
		Test.Assert(!committed);
		Test.Assert(cancelled);
		Test.Assert(el.Text == "Test"); // restored
	}

	[Test]
	public static void EditableLabel_ValidateRenameCalled()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let el = new EditableLabel();
		el.SetText("Hello");
		root.AddView(el);
		TestSetup.Layout(ctx, root);

		// Reject anything containing "bad".
		el.ValidateRename = new (text) => !text.Contains("bad");

		bool committed = false;
		bool cancelled = false;
		el.OnRenameCommitted.Add(new [&committed] (label, text) => { committed = true; });
		el.OnRenameCancelled.Add(new [&cancelled] (label) => { cancelled = true; });

		el.BeginEdit();
		el.[Friend]mBehavior.HandleKeyDown(.A, .Ctrl);
		for (let c in "bad".DecodedChars)
			el.[Friend]mBehavior.HandleTextInput(c);

		el.CommitEdit();

		Test.Assert(!committed);
		Test.Assert(cancelled); // validator rejected
	}

	[Test]
	public static void EditableLabel_DoubleClickToEditDefault()
	{
		let el = scope EditableLabel();
		Test.Assert(el.DoubleClickToEdit == true);
		Test.Assert(el.SlowClickToEdit == true);
	}

	[Test]
	public static void EditableLabel_UnchangedTextRejected()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let el = new EditableLabel();
		el.SetText("Same");
		root.AddView(el);
		TestSetup.Layout(ctx, root);

		bool committed = false;
		bool cancelled = false;
		el.OnRenameCommitted.Add(new [&committed] (label, text) => { committed = true; });
		el.OnRenameCancelled.Add(new [&cancelled] (label) => { cancelled = true; });

		el.BeginEdit();
		// Don't change anything.
		el.CommitEdit();

		Test.Assert(!committed); // unchanged = cancel
		Test.Assert(cancelled);
	}
}
