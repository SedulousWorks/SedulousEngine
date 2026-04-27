namespace GUISandbox;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.GUI;

/// Phase 6: Interactive Controls Demo
/// This is a class (not static) because it has state for event handling.
class InteractiveControlsDemo
{
	private TextBlock mStatusTextBlock;
	private int mClickCount = 0;
	private RelayCommand mSaveCommand ~ delete _;

	public Panel Create()
	{
		// Main container with vertical stack
		let container = new StackPanel();
		container.Orientation = .Vertical;
		container.Spacing = 20;
		container.Margin = .(50, 80, 50, 50);
		container.HorizontalAlignment = .Left;
		container.VerticalAlignment = .Top;

		// --- Button Section ---
		let buttonSection = new StackPanel();
		buttonSection.Orientation = .Vertical;
		buttonSection.Spacing = 10;

		let buttonHeader = new TextBlock("Button Controls:");
		buttonHeader.FontSize = 18;
		buttonSection.AddChild(buttonHeader);

		let buttonRow = new StackPanel();
		buttonRow.Orientation = .Horizontal;
		buttonRow.Spacing = 15;

		// Simple button
		let simpleButton = new Button("Click Me");
		simpleButton.Click.Subscribe(new (btn) => {
			mClickCount++;
			UpdateStatus(scope $"Button clicked! Count: {mClickCount}");
			mSaveCommand?.RaiseCanExecuteChanged();
		});
		buttonRow.AddChild(simpleButton);

		// Disabled button
		let disabledButton = new Button("Disabled");
		disabledButton.IsEnabled = false;
		buttonRow.AddChild(disabledButton);

		// Button with command (stored as field for proper cleanup)
		delete mSaveCommand;
		mSaveCommand = new RelayCommand(
			new () => { UpdateStatus("Save command executed!"); },
			new () => mClickCount > 0
		);
		let commandButton = new Button("Save (needs click)");
		commandButton.Command = mSaveCommand;
		buttonRow.AddChild(commandButton);

		buttonSection.AddChild(buttonRow);
		container.AddChild(buttonSection);

		// --- Separator ---
		let sep1 = new Separator(.Horizontal);
		sep1.Width = 700;
		container.AddChild(sep1);

		// --- RepeatButton Section ---
		let repeatSection = new StackPanel();
		repeatSection.Orientation = .Vertical;
		repeatSection.Spacing = 10;

		let repeatHeader = new TextBlock("RepeatButton (hold to repeat):");
		repeatHeader.FontSize = 18;
		repeatSection.AddChild(repeatHeader);

		let repeatRow = new StackPanel();
		repeatRow.Orientation = .Horizontal;
		repeatRow.Spacing = 15;

		let repeatButton = new RepeatButton("+1");
		repeatButton.Width = 60;
		repeatButton.Click.Subscribe(new (btn) => {
			mClickCount++;
			UpdateStatus(scope $"Repeat count: {mClickCount}");
			mSaveCommand?.RaiseCanExecuteChanged();
		});
		repeatRow.AddChild(repeatButton);

		let repeatMinusButton = new RepeatButton("-1");
		repeatMinusButton.Width = 60;
		repeatMinusButton.Click.Subscribe(new (btn) => {
			mClickCount--;
			UpdateStatus(scope $"Repeat count: {mClickCount}");
			mSaveCommand?.RaiseCanExecuteChanged();
		});
		repeatRow.AddChild(repeatMinusButton);

		repeatSection.AddChild(repeatRow);
		container.AddChild(repeatSection);

		// --- Separator ---
		let sep2 = new Separator(.Horizontal);
		sep2.Width = 700;
		container.AddChild(sep2);

		// --- CheckBox Section ---
		let checkSection = new StackPanel();
		checkSection.Orientation = .Vertical;
		checkSection.Spacing = 10;

		let checkHeader = new TextBlock("CheckBox Controls:");
		checkHeader.FontSize = 18;
		checkSection.AddChild(checkHeader);

		let checkRow = new StackPanel();
		checkRow.Orientation = .Vertical;
		checkRow.Spacing = 8;

		let check1 = new CheckBox("Enable notifications");
		check1.Checked.Subscribe(new (cb, isChecked) => {
			UpdateStatus(scope $"Notifications: {isChecked ? "ON" : "OFF"}");
		});
		checkRow.AddChild(check1);

		let check2 = new CheckBox("Dark mode");
		check2.IsChecked = true;
		check2.Checked.Subscribe(new (cb, isChecked) => {
			UpdateStatus(scope $"Dark mode: {isChecked ? "ON" : "OFF"}");
		});
		checkRow.AddChild(check2);

		let check3 = new CheckBox("Disabled option");
		check3.IsEnabled = false;
		checkRow.AddChild(check3);

		checkSection.AddChild(checkRow);
		container.AddChild(checkSection);

		// --- Separator ---
		let sep3 = new Separator(.Horizontal);
		sep3.Width = 700;
		container.AddChild(sep3);

		// --- RadioButton Section ---
		let radioSection = new StackPanel();
		radioSection.Orientation = .Vertical;
		radioSection.Spacing = 10;

		let radioHeader = new TextBlock("RadioButton Controls (mutually exclusive):");
		radioHeader.FontSize = 18;
		radioSection.AddChild(radioHeader);

		let radioRow = new StackPanel();
		radioRow.Orientation = .Vertical;
		radioRow.Spacing = 8;

		let radio1 = new RadioButton("Option A", "options");
		radio1.IsChecked = true;
		radio1.Checked.Subscribe(new (rb, isChecked) => {
			if (isChecked) UpdateStatus("Selected: Option A");
		});
		radioRow.AddChild(radio1);

		let radio2 = new RadioButton("Option B", "options");
		radio2.Checked.Subscribe(new (rb, isChecked) => {
			if (isChecked) UpdateStatus("Selected: Option B");
		});
		radioRow.AddChild(radio2);

		let radio3 = new RadioButton("Option C", "options");
		radio3.Checked.Subscribe(new (rb, isChecked) => {
			if (isChecked) UpdateStatus("Selected: Option C");
		});
		radioRow.AddChild(radio3);

		radioSection.AddChild(radioRow);
		container.AddChild(radioSection);

		// --- Separator ---
		let sep4 = new Separator(.Horizontal);
		sep4.Width = 700;
		container.AddChild(sep4);

		// --- ToggleSwitch Section ---
		let toggleSection = new StackPanel();
		toggleSection.Orientation = .Vertical;
		toggleSection.Spacing = 10;

		let toggleHeader = new TextBlock("ToggleSwitch Controls:");
		toggleHeader.FontSize = 18;
		toggleSection.AddChild(toggleHeader);

		let toggleRow = new StackPanel();
		toggleRow.Orientation = .Horizontal;
		toggleRow.Spacing = 30;

		let toggle1 = new ToggleSwitch("Wi-Fi");
		toggle1.Checked.Subscribe(new (ts, isChecked) => {
			UpdateStatus(scope $"Wi-Fi: {isChecked ? "ON" : "OFF"}");
		});
		toggleRow.AddChild(toggle1);

		let toggle2 = new ToggleSwitch("Bluetooth");
		toggle2.IsChecked = true;
		toggle2.Checked.Subscribe(new (ts, isChecked) => {
			UpdateStatus(scope $"Bluetooth: {isChecked ? "ON" : "OFF"}");
		});
		toggleRow.AddChild(toggle2);

		toggleSection.AddChild(toggleRow);
		container.AddChild(toggleSection);

		// --- Separator ---
		let sep5 = new Separator(.Horizontal);
		sep5.Width = 700;
		container.AddChild(sep5);

		// --- Hyperlink Section ---
		let linkSection = new StackPanel();
		linkSection.Orientation = .Vertical;
		linkSection.Spacing = 10;

		let linkHeader = new TextBlock("Hyperlink Controls:");
		linkHeader.FontSize = 18;
		linkSection.AddChild(linkHeader);

		let linkRow = new StackPanel();
		linkRow.Orientation = .Horizontal;
		linkRow.Spacing = 20;

		let link1 = new Hyperlink("Visit Documentation", "https://example.com/docs");
		link1.RequestNavigate.Subscribe(new (hl, uri) => {
			UpdateStatus(scope $"Navigate to: {uri}");
		});
		linkRow.AddChild(link1);

		let link2 = new Hyperlink("GitHub Repo", "https://github.com/example");
		link2.RequestNavigate.Subscribe(new (hl, uri) => {
			UpdateStatus(scope $"Navigate to: {uri}");
		});
		linkRow.AddChild(link2);

		linkSection.AddChild(linkRow);
		container.AddChild(linkSection);

		// --- Status Section ---
		let sep6 = new Separator(.Horizontal);
		sep6.Width = 700;
		container.AddChild(sep6);

		let statusSection = new StackPanel();
		statusSection.Orientation = .Horizontal;
		statusSection.Spacing = 10;

		let statusLabel = new TextBlock("Last Action: ");
		statusSection.AddChild(statusLabel);

		mStatusTextBlock = new TextBlock("(none)");
		mStatusTextBlock.Foreground = Color(100, 200, 100, 255);
		statusSection.AddChild(mStatusTextBlock);

		container.AddChild(statusSection);

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
