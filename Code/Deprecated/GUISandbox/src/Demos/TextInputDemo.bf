namespace GUISandbox;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.GUI;

/// Phase 7: Text Input Controls Demo
class TextInputDemo
{
	private TextBlock mStatusTextBlock;

	public Panel Create()
	{
		// Main container with vertical stack
		let container = new StackPanel();
		container.Orientation = .Vertical;
		container.Spacing = 20;
		container.Margin = .(50, 80, 50, 50);
		container.HorizontalAlignment = .Left;
		container.VerticalAlignment = .Top;

		// --- TextBox Section ---
		let textBoxSection = new StackPanel();
		textBoxSection.Orientation = .Vertical;
		textBoxSection.Spacing = 10;

		let textBoxHeader = new TextBlock("TextBox Controls:");
		textBoxHeader.FontSize = 18;
		textBoxSection.AddChild(textBoxHeader);

		// Basic TextBox with placeholder
		let textBox1 = new TextBox();
		textBox1.Width = 300;
		textBox1.Placeholder = "Enter your name...";
		textBox1.TextChanged.Subscribe(new (tb, text) => {
			UpdateStatus(scope $"Text changed: {text}");
		});
		textBoxSection.AddChild(textBox1);

		// TextBox with initial text
		let textBox2 = new TextBox("Hello, World!");
		textBox2.Width = 300;
		textBoxSection.AddChild(textBox2);

		// Read-only TextBox
		let readOnlyRow = new StackPanel();
		readOnlyRow.Orientation = .Horizontal;
		readOnlyRow.Spacing = 10;

		let readOnlyLabel = new TextBlock("Read-only:");
		readOnlyRow.AddChild(readOnlyLabel);

		let textBox3 = new TextBox("This text cannot be edited");
		textBox3.Width = 250;
		textBox3.IsReadOnly = true;
		readOnlyRow.AddChild(textBox3);

		textBoxSection.AddChild(readOnlyRow);

		// TextBox with max length
		let maxLengthRow = new StackPanel();
		maxLengthRow.Orientation = .Horizontal;
		maxLengthRow.Spacing = 10;

		let maxLengthLabel = new TextBlock("Max 10 chars:");
		maxLengthRow.AddChild(maxLengthLabel);

		let textBox4 = new TextBox();
		textBox4.Width = 150;
		textBox4.MaxLength = 10;
		textBox4.Placeholder = "Max 10";
		maxLengthRow.AddChild(textBox4);

		textBoxSection.AddChild(maxLengthRow);

		container.AddChild(textBoxSection);

		// --- Separator ---
		let sep1 = new Separator(.Horizontal);
		sep1.Width = 600;
		container.AddChild(sep1);

		// --- PasswordBox Section ---
		let passwordSection = new StackPanel();
		passwordSection.Orientation = .Vertical;
		passwordSection.Spacing = 10;

		let passwordHeader = new TextBlock("PasswordBox Control:");
		passwordHeader.FontSize = 18;
		passwordSection.AddChild(passwordHeader);

		let passwordRow = new StackPanel();
		passwordRow.Orientation = .Horizontal;
		passwordRow.Spacing = 10;

		let passwordLabel = new TextBlock("Password:");
		passwordRow.AddChild(passwordLabel);

		let passwordBox = new PasswordBox();
		passwordBox.Width = 200;
		passwordBox.PasswordChanged.Subscribe(new (pb) => {
			UpdateStatus(scope $"Password length: {pb.Password.Length}");
		});
		passwordRow.AddChild(passwordBox);

		passwordSection.AddChild(passwordRow);

		let passwordNote = new TextBlock("(Copy/Cut disabled for security)");
		passwordNote.FontSize = 12;
		passwordSection.AddChild(passwordNote);

		container.AddChild(passwordSection);

		// --- Separator ---
		let sep2 = new Separator(.Horizontal);
		sep2.Width = 600;
		container.AddChild(sep2);

		// --- NumericUpDown Section ---
		let numericSection = new StackPanel();
		numericSection.Orientation = .Vertical;
		numericSection.Spacing = 10;

		let numericHeader = new TextBlock("NumericUpDown Controls:");
		numericHeader.FontSize = 18;
		numericSection.AddChild(numericHeader);

		// Integer NumericUpDown
		let integerRow = new StackPanel();
		integerRow.Orientation = .Horizontal;
		integerRow.Spacing = 10;

		let integerLabel = new TextBlock("Integer (0-100):");
		integerRow.AddChild(integerLabel);

		let numericInt = new NumericUpDown();
		numericInt.Width = 100;
		numericInt.Minimum = 0;
		numericInt.Maximum = 100;
		numericInt.Value = 50;
		numericInt.Step = 1;
		numericInt.ValueChanged.Subscribe(new (nud, value) => {
			UpdateStatus(scope $"Integer value: {(int)value}");
		});
		integerRow.AddChild(numericInt);

		numericSection.AddChild(integerRow);

		// Decimal NumericUpDown
		let decimalRow = new StackPanel();
		decimalRow.Orientation = .Horizontal;
		decimalRow.Spacing = 10;

		let decimalLabel = new TextBlock("Decimal (0.0-10.0):");
		decimalRow.AddChild(decimalLabel);

		let numericDecimal = new NumericUpDown();
		numericDecimal.Width = 120;
		numericDecimal.Minimum = 0;
		numericDecimal.Maximum = 10;
		numericDecimal.Value = 5.5;
		numericDecimal.Step = 0.1;
		numericDecimal.DecimalPlaces = 1;
		numericDecimal.ValueChanged.Subscribe(new (nud, value) => {
			UpdateStatus(scope $"Decimal value: {value:F1}");
		});
		decimalRow.AddChild(numericDecimal);

		numericSection.AddChild(decimalRow);

		// Large step NumericUpDown
		let largeStepRow = new StackPanel();
		largeStepRow.Orientation = .Horizontal;
		largeStepRow.Spacing = 10;

		let largeStepLabel = new TextBlock("Step=10:");
		largeStepRow.AddChild(largeStepLabel);

		let numericLarge = new NumericUpDown();
		numericLarge.Width = 100;
		numericLarge.Minimum = 0;
		numericLarge.Maximum = 1000;
		numericLarge.Value = 100;
		numericLarge.Step = 10;
		largeStepRow.AddChild(numericLarge);

		numericSection.AddChild(largeStepRow);

		container.AddChild(numericSection);

		// --- Separator ---
		let sep3 = new Separator(.Horizontal);
		sep3.Width = 600;
		container.AddChild(sep3);

		// --- Copy/Paste Demo Section ---
		let copyPasteSection = new StackPanel();
		copyPasteSection.Orientation = .Vertical;
		copyPasteSection.Spacing = 10;

		let copyPasteHeader = new TextBlock("Copy/Paste Demo:");
		copyPasteHeader.FontSize = 18;
		copyPasteSection.AddChild(copyPasteHeader);

		let copyPasteRow = new StackPanel();
		copyPasteRow.Orientation = .Horizontal;
		copyPasteRow.Spacing = 10;

		let sourceBox = new TextBox("Select and copy me!");
		sourceBox.Width = 200;
		copyPasteRow.AddChild(sourceBox);

		let arrow = new TextBlock("->");
		copyPasteRow.AddChild(arrow);

		let destBox = new TextBox();
		destBox.Width = 200;
		destBox.Placeholder = "Paste here (Ctrl+V)";
		copyPasteRow.AddChild(destBox);

		copyPasteSection.AddChild(copyPasteRow);

		let copyPasteInstructions = new TextBlock("Try: Select text with mouse or Shift+arrows, Ctrl+C to copy, Ctrl+V to paste");
		copyPasteInstructions.FontSize = 12;
		copyPasteSection.AddChild(copyPasteInstructions);

		container.AddChild(copyPasteSection);

		// --- Status Section ---
		let sep4 = new Separator(.Horizontal);
		sep4.Width = 600;
		container.AddChild(sep4);

		let statusSection = new StackPanel();
		statusSection.Orientation = .Horizontal;
		statusSection.Spacing = 10;

		let statusLabel = new TextBlock("Last Action: ");
		statusSection.AddChild(statusLabel);

		mStatusTextBlock = new TextBlock("(none)");
		mStatusTextBlock.Foreground = Color(100, 200, 100, 255);
		statusSection.AddChild(mStatusTextBlock);

		container.AddChild(statusSection);

		// --- Keyboard Shortcuts Info ---
		let shortcutsInfo = new TextBlock("Shortcuts: Ctrl+A (select all), Ctrl+Z (undo), Ctrl+Y (redo), Ctrl+Arrows (word jump)");
		shortcutsInfo.FontSize = 12;
		container.AddChild(shortcutsInfo);

		return container;
	}

	private void UpdateStatus(StringView text)
	{
		if (mStatusTextBlock != null)
		{
			mStatusTextBlock.Text = text;
		}
	}
}
