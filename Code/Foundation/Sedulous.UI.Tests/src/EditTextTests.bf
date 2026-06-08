namespace Sedulous.UI.Tests;

using System;

class EditTextTests
{
	// === EditText ===

	[Test]
	public static void EditText_TextGetSet()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let edit = new EditText();
		root.AddView(edit);

		edit.SetText("Hello");
		Test.Assert(edit.Text == "Hello");

		edit.SetText("World");
		Test.Assert(edit.Text == "World");
	}

	[Test]
	public static void EditText_OnTextChangedFires()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let edit = new EditText();
		root.AddView(edit);
		TestSetup.Layout(ctx, root);

		bool fired = false;
		edit.OnTextChanged.Add(new [&fired] (e) => { fired = true; });

		// Simulate typing a character via the behavior.
		((ITextEditHost)edit).ReplaceText(0, 0, "A");
		((ITextEditHost)edit).OnTextModified();

		Test.Assert(fired);
	}

	[Test]
	public static void EditText_MaxLengthEnforced()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let edit = new EditText();
		edit.MaxLength.Value = 5;
		root.AddView(edit);
		TestSetup.Layout(ctx, root);

		// Type 10 characters.
		for (int i = 0; i < 10; i++)
			edit.[Friend]mBehavior.HandleTextInput('a');

		// Should only have 5.
		int32 charCount = 0;
		for (let c in edit.Text.DecodedChars)
			charCount++;
		Test.Assert(charCount == 5);
	}

	[Test]
	public static void EditText_InputFilterBlocksInvalid()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let edit = new EditText();
		edit.Filter = InputFilter.Digits();
		root.AddView(edit);
		TestSetup.Layout(ctx, root);

		edit.[Friend]mBehavior.HandleTextInput('5');
		edit.[Friend]mBehavior.HandleTextInput('a');
		edit.[Friend]mBehavior.HandleTextInput('3');

		Test.Assert(edit.Text == "53");
	}

	[Test]
	public static void EditText_IsReadOnlyPreventsModification()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let edit = new EditText();
		edit.SetText("Original");
		edit.IsReadOnly.Value = true;
		root.AddView(edit);
		TestSetup.Layout(ctx, root);

		edit.[Friend]mBehavior.HandleTextInput('X');

		Test.Assert(edit.Text == "Original");
	}

	[Test]
	public static void EditText_PlaceholderProperty()
	{
		let edit = scope EditText();
		edit.SetPlaceholder("Enter text...");
		Test.Assert(edit.Placeholder.Value == "Enter text...");
	}

	[Test]
	public static void EditText_IsFocusableAndCursor()
	{
		let edit = scope EditText();
		Test.Assert(edit.IsFocusable == true);
		Test.Assert(edit.IsTabStop == true);
		Test.Assert(edit.Cursor == .IBeam);
	}

	[Test]
	public static void EditText_MultilineProperty()
	{
		let edit = scope EditText();
		Test.Assert(edit.Multiline.Value == false);
		edit.Multiline.Value = true;
		Test.Assert(edit.Multiline.Value == true);
	}

	[Test]
	public static void EditText_CursorMovement()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let edit = new EditText();
		edit.SetText("Hello");
		root.AddView(edit);
		TestSetup.Layout(ctx, root);

		// Cursor starts at 0 after SetText (reset).
		Test.Assert(edit.CursorPosition == 0);

		// Move right.
		edit.[Friend]mBehavior.HandleKeyDown(.Right, .None);
		Test.Assert(edit.CursorPosition == 1);

		// Move to end.
		edit.[Friend]mBehavior.HandleKeyDown(.End, .None);
		Test.Assert(edit.CursorPosition == 5);

		// Move to home.
		edit.[Friend]mBehavior.HandleKeyDown(.Home, .None);
		Test.Assert(edit.CursorPosition == 0);
	}

	[Test]
	public static void EditText_SelectAll()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let edit = new EditText();
		edit.SetText("Hello");
		root.AddView(edit);
		TestSetup.Layout(ctx, root);

		edit.[Friend]mBehavior.HandleKeyDown(.A, .Ctrl);

		Test.Assert(edit.SelectionStart == 0);
		Test.Assert(edit.SelectionEnd == 5);
	}

	[Test]
	public static void EditText_DeleteBackspace()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let edit = new EditText();
		edit.SetText("Hello");
		root.AddView(edit);
		TestSetup.Layout(ctx, root);

		// Move to end and backspace.
		edit.[Friend]mBehavior.HandleKeyDown(.End, .None);
		edit.[Friend]mBehavior.HandleKeyDown(.Backspace, .None);

		Test.Assert(edit.Text == "Hell");
	}

	[Test]
	public static void EditText_DeleteForward()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let edit = new EditText();
		edit.SetText("Hello");
		root.AddView(edit);
		TestSetup.Layout(ctx, root);

		// Cursor at 0, delete forward.
		edit.[Friend]mBehavior.HandleKeyDown(.Delete, .None);

		Test.Assert(edit.Text == "ello");
	}

	// === PasswordBox ===

	[Test]
	public static void PasswordBox_DisplayTextIsMasked()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let pw = new PasswordBox();
		pw.SetText("secret");
		root.AddView(pw);
		TestSetup.Layout(ctx, root);

		let display = scope String();
		pw.[Friend]GetDisplayText(display);

		Test.Assert(display == "******");
		Test.Assert(pw.Text == "secret");
	}

	[Test]
	public static void PasswordBox_CustomPasswordChar()
	{
		let pw = scope PasswordBox();
		pw.SetText("abc");
		pw.PasswordChar.Value = '#';

		let display = scope String();
		pw.[Friend]GetDisplayText(display);

		Test.Assert(display == "###");
	}

	[Test]
	public static void PasswordBox_CopyDisabled()
	{
		let pw = scope PasswordBox();
		Test.Assert(pw.[Friend]mBehavior.AllowClipboardCopy == false);
	}
}
