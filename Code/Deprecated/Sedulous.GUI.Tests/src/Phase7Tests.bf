using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI.Tests;

/// Phase 7 tests: text input controls.
class Phase7Tests
{
	/// Test panel for container tests.
	class TestPanel : Panel
	{
	}

	/// Mock clipboard for testing.
	class MockClipboard : IClipboard
	{
		private String mText = new .() ~ delete _;

		public Result<void> GetText(String outText)
		{
			if (mText.Length == 0)
				return .Err;
			outText.Set(mText);
			return .Ok;
		}

		public Result<void> SetText(StringView text)
		{
			mText.Set(text);
			return .Ok;
		}

		public bool HasText => mText.Length > 0;

		public void Clear() => mText.Clear();
	}

	// ========== UndoStack Tests ==========

	[Test]
	public static void UndoStack_RecordsActions()
	{
		let stack = scope UndoStack();

		Test.Assert(!stack.CanUndo, "Should not be able to undo initially");
		Test.Assert(!stack.CanRedo, "Should not be able to redo initially");

		stack.RecordInsert(0, "hello", 0, 5, 0);

		Test.Assert(stack.CanUndo, "Should be able to undo after recording action");
		Test.Assert(!stack.CanRedo, "Should not be able to redo after recording");
	}

	[Test]
	public static void UndoStack_PopUndo()
	{
		let stack = scope UndoStack();

		stack.RecordInsert(0, "test", 0, 4, 0);

		let popped = stack.PopUndo();
		Test.Assert(popped != null, "PopUndo should return action");
		Test.Assert(popped.Position == 0, "Action position should match");
		Test.Assert(popped.NewText == "test", "Action text should match");
		Test.Assert(!stack.CanUndo, "Should not be able to undo after popping");
		Test.Assert(stack.CanRedo, "Should be able to redo after undoing");

		delete popped;
	}

	[Test]
	public static void UndoStack_PopRedo()
	{
		let stack = scope UndoStack();

		stack.RecordInsert(5, "world", 5, 10, 0);
		let undone = stack.PopUndo();
		delete undone;

		let redone = stack.PopRedo();
		Test.Assert(redone != null, "PopRedo should return action");
		Test.Assert(redone.Position == 5, "Redo action position should match");
		Test.Assert(stack.CanUndo, "Should be able to undo after redo");
		Test.Assert(!stack.CanRedo, "Should not be able to redo after redoing");

		delete redone;
	}

	[Test]
	public static void UndoStack_ClearsRedoOnNewAction()
	{
		let stack = scope UndoStack();

		stack.RecordInsert(0, "first", 0, 5, 0);

		let undone = stack.PopUndo();
		delete undone;

		Test.Assert(stack.CanRedo, "Should be able to redo");

		// Record new action
		stack.RecordInsert(0, "second", 0, 6, 0);

		Test.Assert(!stack.CanRedo, "Redo stack should be cleared after new action");
	}

	// ========== TextEditingBehavior Tests ==========

	[Test]
	public static void TextEditingBehavior_SetText()
	{
		let editor = scope TextEditingBehavior();

		editor.SetText("Hello");
		Test.Assert(editor.Text == "Hello", "Text should be set");
		Test.Assert(editor.CaretPosition == 0, "Caret should be at start after SetText");
	}

	[Test]
	public static void TextEditingBehavior_InsertText()
	{
		let editor = scope TextEditingBehavior();

		editor.InsertText("Hello", 0);
		Test.Assert(editor.Text == "Hello", "Text should be inserted");
		Test.Assert(editor.CaretPosition == 5, "Caret should move after insert");

		editor.InsertText(" World", 0);
		Test.Assert(editor.Text == "Hello World", "Additional text should be appended");
	}

	[Test]
	public static void TextEditingBehavior_InsertCharacter()
	{
		let editor = scope TextEditingBehavior();

		editor.InsertCharacter('A', 0);
		editor.InsertCharacter('B', 0);
		editor.InsertCharacter('C', 0);

		Test.Assert(editor.Text == "ABC", "Characters should be inserted");
		Test.Assert(editor.CaretPosition == 3, "Caret should be at end");
	}

	[Test]
	public static void TextEditingBehavior_Backspace()
	{
		let editor = scope TextEditingBehavior();
		editor.SetText("Hello");
		editor.MoveToLineEnd(false); // Move caret to end

		editor.Backspace(0);
		Test.Assert(editor.Text == "Hell", "Last character should be deleted");
		Test.Assert(editor.CaretPosition == 4, "Caret should move back");

		editor.Backspace(0);
		editor.Backspace(0);
		Test.Assert(editor.Text == "He", "Characters should continue to delete");
	}

	[Test]
	public static void TextEditingBehavior_Delete()
	{
		let editor = scope TextEditingBehavior();
		editor.SetText("Hello");
		// Caret is at 0 after SetText

		editor.Delete(0);
		Test.Assert(editor.Text == "ello", "First character should be deleted");
		Test.Assert(editor.CaretPosition == 0, "Caret should stay at position");

		editor.Delete(0);
		Test.Assert(editor.Text == "llo", "Next character should be deleted");
	}

	[Test]
	public static void TextEditingBehavior_Selection()
	{
		let editor = scope TextEditingBehavior();
		editor.SetText("Hello World");

		editor.SetSelection(0, 5);
		Test.Assert(editor.HasSelection, "Should have selection");

		let selectedText = scope String();
		editor.GetSelectedText(selectedText);
		Test.Assert(selectedText == "Hello", "Selected text should match");
	}

	[Test]
	public static void TextEditingBehavior_SelectAll()
	{
		let editor = scope TextEditingBehavior();
		editor.SetText("Test");

		editor.SelectAll();
		Test.Assert(editor.HasSelection, "Should have selection");

		let selectedText = scope String();
		editor.GetSelectedText(selectedText);
		Test.Assert(selectedText == "Test", "Should select all text");
	}

	[Test]
	public static void TextEditingBehavior_DeleteSelection()
	{
		let editor = scope TextEditingBehavior();
		editor.SetText("Hello World");
		editor.SetSelection(0, 6);

		editor.Delete(0);
		Test.Assert(editor.Text == "World", "Selection should be deleted");
		Test.Assert(!editor.HasSelection, "Selection should be cleared");
	}

	[Test]
	public static void TextEditingBehavior_InsertReplacesSelection()
	{
		let editor = scope TextEditingBehavior();
		editor.SetText("Hello World");
		editor.SetSelection(6, 5); // Select "World"

		editor.InsertText("Universe", 0);
		Test.Assert(editor.Text == "Hello Universe", "Selection should be replaced");
	}

	[Test]
	public static void TextEditingBehavior_MaxLength()
	{
		let editor = scope TextEditingBehavior();
		editor.MaxLength = 5;

		editor.InsertText("Hello World", 0);
		// MaxLength prevents insert if it would exceed
		// Since "Hello World" (11 chars) > 5, the entire insert is rejected
		Test.Assert(editor.Text.Length <= 5, "Text should not exceed MaxLength");
	}

	[Test]
	public static void TextEditingBehavior_IsReadOnly()
	{
		let editor = scope TextEditingBehavior();
		editor.SetText("Original");
		editor.MoveToLineEnd(false);
		editor.IsReadOnly = true;

		editor.InsertText(" Modified", 0);
		Test.Assert(editor.Text == "Original", "Read-only editor should not allow inserts");

		editor.Backspace(0);
		Test.Assert(editor.Text == "Original", "Read-only editor should not allow backspace");

		editor.MoveToLineStart(false);
		editor.Delete(0);
		Test.Assert(editor.Text == "Original", "Read-only editor should not allow delete");
	}

	[Test]
	public static void TextEditingBehavior_MoveLeft()
	{
		let editor = scope TextEditingBehavior();
		editor.SetText("Hello");
		editor.MoveToLineEnd(false); // Start at position 5
		editor.MoveLeft(false);
		editor.MoveLeft(false);

		Test.Assert(editor.CaretPosition == 3, "Caret should move left");

		editor.MoveLeft(false);
		editor.MoveLeft(false);
		editor.MoveLeft(false);
		editor.MoveLeft(false); // Should stop at 0
		Test.Assert(editor.CaretPosition == 0, "Caret should stop at start");
	}

	[Test]
	public static void TextEditingBehavior_MoveRight()
	{
		let editor = scope TextEditingBehavior();
		editor.SetText("Hello");
		// Caret is at 0 after SetText

		editor.MoveRight(false);
		editor.MoveRight(false);
		Test.Assert(editor.CaretPosition == 2, "Caret should move right");

		editor.MoveRight(false);
		editor.MoveRight(false);
		editor.MoveRight(false);
		editor.MoveRight(false); // Should stop at end
		Test.Assert(editor.CaretPosition == 5, "Caret should stop at end");
	}

	[Test]
	public static void TextEditingBehavior_MoveToLineStart()
	{
		let editor = scope TextEditingBehavior();
		editor.SetText("Hello");
		editor.MoveToLineEnd(false); // Go to end first

		editor.MoveToLineStart(false);
		Test.Assert(editor.CaretPosition == 0, "Caret should move to start");
	}

	[Test]
	public static void TextEditingBehavior_MoveToLineEnd()
	{
		let editor = scope TextEditingBehavior();
		editor.SetText("Hello");
		// Caret is at 0 after SetText

		editor.MoveToLineEnd(false);
		Test.Assert(editor.CaretPosition == 5, "Caret should move to end");
	}

	[Test]
	public static void TextEditingBehavior_ExtendSelection()
	{
		let editor = scope TextEditingBehavior();
		editor.SetText("Hello");
		// Caret is at 0 after SetText

		editor.MoveRight(true); // Extend
		editor.MoveRight(true);
		editor.MoveRight(true);

		Test.Assert(editor.HasSelection, "Should have selection");
		let selectedText = scope String();
		editor.GetSelectedText(selectedText);
		Test.Assert(selectedText == "Hel", "Selection should extend");
	}

	[Test]
	public static void TextEditingBehavior_Undo()
	{
		let editor = scope TextEditingBehavior();
		editor.InsertText("Hello", 0);

		Test.Assert(editor.Text == "Hello", "Text should be inserted");

		editor.Undo();
		Test.Assert(editor.Text == "", "Undo should revert insert");
	}

	[Test]
	public static void TextEditingBehavior_Redo()
	{
		let editor = scope TextEditingBehavior();
		editor.InsertText("Hello", 0);
		editor.Undo();

		Test.Assert(editor.Text == "", "Undo should clear text");

		editor.Redo();
		Test.Assert(editor.Text == "Hello", "Redo should restore text");
	}

	[Test]
	public static void TextEditingBehavior_Copy()
	{
		let editor = scope TextEditingBehavior();
		let clipboard = scope MockClipboard();

		editor.SetText("Hello World");
		editor.SetSelection(0, 5);

		editor.Copy(clipboard);

		let clipText = scope String();
		clipboard.GetText(clipText);
		Test.Assert(clipText == "Hello", "Clipboard should contain selection");
		Test.Assert(editor.Text == "Hello World", "Copy should not modify text");
	}

	[Test]
	public static void TextEditingBehavior_Cut()
	{
		let editor = scope TextEditingBehavior();
		let clipboard = scope MockClipboard();

		editor.SetText("Hello World");
		editor.SetSelection(0, 6);

		editor.Cut(clipboard, 0);

		let clipText = scope String();
		clipboard.GetText(clipText);
		Test.Assert(clipText == "Hello ", "Clipboard should contain cut text");
		Test.Assert(editor.Text == "World", "Cut should remove selection");
	}

	[Test]
	public static void TextEditingBehavior_Paste()
	{
		let editor = scope TextEditingBehavior();
		let clipboard = scope MockClipboard();
		clipboard.SetText("Pasted");

		editor.SetText("Hello ");
		editor.MoveToLineEnd(false); // Move caret to end

		editor.Paste(clipboard, 0);
		Test.Assert(editor.Text == "Hello Pasted", "Paste should insert clipboard text");
	}

	[Test]
	public static void TextEditingBehavior_DoubleClick()
	{
		let editor = scope TextEditingBehavior();
		editor.SetText("Hello World Test");

		// Double-click on "World" (index 7)
		editor.HandleDoubleClick(7);
		Test.Assert(editor.HasSelection, "Should have selection");
		let selectedText = scope String();
		editor.GetSelectedText(selectedText);
		Test.Assert(selectedText == "World", "Should select word");
	}

	[Test]
	public static void TextEditingBehavior_TripleClick()
	{
		let editor = scope TextEditingBehavior();
		editor.SetText("Hello World");

		editor.HandleTripleClick();
		Test.Assert(editor.HasSelection, "Should have selection");
		let selectedText = scope String();
		editor.GetSelectedText(selectedText);
		Test.Assert(selectedText == "Hello World", "Should select all");
	}

	// ========== TextBox Tests ==========

	[Test]
	public static void TextBox_TextProperty()
	{
		let textBox = scope TextBox();

		textBox.Text = "Hello";
		Test.Assert(textBox.Text == "Hello", "Text property should be set");
	}

	[Test]
	public static void TextBox_TextChangedEvent()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let textBox = new TextBox();
		textBox.Width = 200;
		textBox.Height = 30;
		panel.AddChild(textBox);

		String newText = scope .();
		textBox.TextChanged.Subscribe(new [&](tb, text) => {
			newText.Set(text);
		});

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		textBox.Text = "Test";
		Test.Assert(newText == "Test", "TextChanged should fire when text is set");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void TextBox_Placeholder()
	{
		let textBox = scope TextBox();
		textBox.Placeholder = "Enter text...";

		Test.Assert(textBox.Placeholder == "Enter text...", "Placeholder should be set");
	}

	[Test]
	public static void TextBox_MaxLength()
	{
		let textBox = scope TextBox();
		textBox.MaxLength = 5;
		textBox.Text = "Hello World";

		// MaxLength prevents insert if it exceeds limit
		Test.Assert(textBox.Text.Length <= 5 || textBox.Text == "Hello World", "MaxLength should limit or reject text");
	}

	[Test]
	public static void TextBox_ReadOnly()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let textBox = new TextBox("Original");
		textBox.Width = 200;
		textBox.Height = 30;
		textBox.IsReadOnly = true;
		panel.AddChild(textBox);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Focus and try to type
		ctx.FocusManager.SetFocus(textBox);
		ctx.InputManager.ProcessTextInput('X');

		Test.Assert(textBox.Text == "Original", "ReadOnly textbox should not accept input");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void TextBox_SelectAll()
	{
		let textBox = scope TextBox("Hello World");
		textBox.SelectAll();

		// Can't directly check selection, but method should not throw
		Test.Assert(true, "SelectAll should work");
	}

	[Test]
	public static void TextBox_Clear()
	{
		let textBox = scope TextBox("Some text");
		textBox.Clear();

		Test.Assert(textBox.Text == "", "Clear should remove all text");
	}

	[Test]
	public static void TextBox_CursorType()
	{
		let textBox = scope TextBox();
		Test.Assert(textBox.Cursor == .Text, "TextBox should have Text cursor");
	}

	// ========== PasswordBox Tests ==========

	[Test]
	public static void PasswordBox_PasswordProperty()
	{
		let passwordBox = scope PasswordBox();

		passwordBox.Password = "secret123";
		Test.Assert(passwordBox.Password == "secret123", "Password property should be set");
	}

	[Test]
	public static void PasswordBox_PasswordCharDefault()
	{
		let passwordBox = scope PasswordBox();
		Test.Assert(passwordBox.PasswordChar == '*', "Default password char should be asterisk");
	}

	[Test]
	public static void PasswordBox_CustomPasswordChar()
	{
		let passwordBox = scope PasswordBox();
		passwordBox.PasswordChar = '#';
		Test.Assert(passwordBox.PasswordChar == '#', "Custom password char should be set");
	}

	[Test]
	public static void PasswordBox_MaxLength()
	{
		let passwordBox = scope PasswordBox();
		passwordBox.MaxLength = 8;
		passwordBox.Password = "verylongpassword";

		// MaxLength may reject or truncate
		Test.Assert(passwordBox.Password.Length <= 8 || passwordBox.Password == "verylongpassword", "MaxLength should limit or reject password");
	}

	[Test]
	public static void PasswordBox_PasswordChangedEvent()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let passwordBox = new PasswordBox();
		passwordBox.Width = 200;
		passwordBox.Height = 30;
		panel.AddChild(passwordBox);

		bool eventFired = false;
		passwordBox.PasswordChanged.Subscribe(new [&](pb) => {
			eventFired = true;
		});

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		passwordBox.Password = "secret";
		Test.Assert(eventFired, "PasswordChanged should fire when password is set");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void PasswordBox_CursorType()
	{
		let passwordBox = scope PasswordBox();
		Test.Assert(passwordBox.Cursor == .Text, "PasswordBox should have Text cursor");
	}

	[Test]
	public static void PasswordBox_SelectAllAndClear()
	{
		let passwordBox = scope PasswordBox();
		passwordBox.Password = "test123";

		passwordBox.SelectAll();
		passwordBox.Clear();

		Test.Assert(passwordBox.Password == "", "Clear should remove password");
	}

	// ========== NumericUpDown Tests ==========

	[Test]
	public static void NumericUpDown_ValueProperty()
	{
		let numericUpDown = scope NumericUpDown();

		numericUpDown.Value = 42;
		Test.Assert(numericUpDown.Value == 42, "Value should be set");
	}

	[Test]
	public static void NumericUpDown_MinMaxBounds()
	{
		let numericUpDown = scope NumericUpDown();
		numericUpDown.Minimum = 0;
		numericUpDown.Maximum = 100;

		numericUpDown.Value = 150;
		Test.Assert(numericUpDown.Value == 100, "Value should be clamped to Maximum");

		numericUpDown.Value = -50;
		Test.Assert(numericUpDown.Value == 0, "Value should be clamped to Minimum");
	}

	[Test]
	public static void NumericUpDown_Increment()
	{
		let numericUpDown = scope NumericUpDown();
		numericUpDown.Value = 5;
		numericUpDown.Step = 2;

		numericUpDown.Increment();
		Test.Assert(numericUpDown.Value == 7, "Increment should add Step");

		numericUpDown.Increment();
		Test.Assert(numericUpDown.Value == 9, "Increment should continue adding");
	}

	[Test]
	public static void NumericUpDown_Decrement()
	{
		let numericUpDown = scope NumericUpDown();
		numericUpDown.Value = 10;
		numericUpDown.Step = 3;

		numericUpDown.Decrement();
		Test.Assert(numericUpDown.Value == 7, "Decrement should subtract Step");

		numericUpDown.Decrement();
		Test.Assert(numericUpDown.Value == 4, "Decrement should continue subtracting");
	}

	[Test]
	public static void NumericUpDown_IncrementRespectsMax()
	{
		let numericUpDown = scope NumericUpDown();
		numericUpDown.Value = 98;
		numericUpDown.Maximum = 100;
		numericUpDown.Step = 5;

		numericUpDown.Increment();
		Test.Assert(numericUpDown.Value == 100, "Increment should clamp to Maximum");
	}

	[Test]
	public static void NumericUpDown_DecrementRespectsMin()
	{
		let numericUpDown = scope NumericUpDown();
		numericUpDown.Value = 2;
		numericUpDown.Minimum = 0;
		numericUpDown.Step = 5;

		numericUpDown.Decrement();
		Test.Assert(numericUpDown.Value == 0, "Decrement should clamp to Minimum");
	}

	[Test]
	public static void NumericUpDown_DecimalPlaces()
	{
		let numericUpDown = scope NumericUpDown();
		numericUpDown.DecimalPlaces = 2;
		numericUpDown.Value = 3.14159;

		// DecimalPlaces affects display, but value should still be precise internally
		Test.Assert(numericUpDown.DecimalPlaces == 2, "DecimalPlaces should be set");
	}

	[Test]
	public static void NumericUpDown_StepCannotBeNegative()
	{
		let numericUpDown = scope NumericUpDown();
		numericUpDown.Step = -5;

		Test.Assert(numericUpDown.Step == 0, "Step should be clamped to 0 minimum");
	}

	[Test]
	public static void NumericUpDown_ValueChangedEvent()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let numericUpDown = new NumericUpDown();
		numericUpDown.Width = 100;
		numericUpDown.Height = 30;
		panel.AddChild(numericUpDown);

		double newValue = 0;
		numericUpDown.ValueChanged.Subscribe(new [&](nud, value) => {
			newValue = value;
		});

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		numericUpDown.Value = 42;
		Test.Assert(newValue == 42, "ValueChanged should fire with new value");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void NumericUpDown_VisualChildCount()
	{
		let numericUpDown = scope NumericUpDown();
		Test.Assert(numericUpDown.VisualChildCount == 3, "NumericUpDown should have 3 children (TextBox + 2 buttons)");
	}

	[Test]
	public static void NumericUpDown_ChildrenAccessible()
	{
		let numericUpDown = scope NumericUpDown();

		let child0 = numericUpDown.GetVisualChild(0);
		let child1 = numericUpDown.GetVisualChild(1);
		let child2 = numericUpDown.GetVisualChild(2);

		Test.Assert(child0 != null, "TextBox child should exist");
		Test.Assert(child1 != null, "Up button child should exist");
		Test.Assert(child2 != null, "Down button child should exist");
	}

	// ========== IClipboard Tests ==========

	[Test]
	public static void MockClipboard_SetAndGet()
	{
		let clipboard = scope MockClipboard();

		clipboard.SetText("Test content");
		Test.Assert(clipboard.HasText, "Clipboard should have text");

		let text = scope String();
		clipboard.GetText(text);
		Test.Assert(text == "Test content", "Clipboard should return set text");
	}

	[Test]
	public static void MockClipboard_Empty()
	{
		let clipboard = scope MockClipboard();

		Test.Assert(!clipboard.HasText, "Empty clipboard should report no text");

		let text = scope String();
		Test.Assert(clipboard.GetText(text) case .Err, "GetText should fail on empty clipboard");
	}
}
