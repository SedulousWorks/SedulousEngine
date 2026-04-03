using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI.Tests;

/// Phase 6 tests: commands and interactive controls.
class Phase6Tests
{
	/// Test panel for container tests.
	class TestPanel : Panel
	{
	}

	/// Simple test control that can be focused.
	class TestControl : Control
	{
		public this()
		{
			IsFocusable = true;
			IsTabStop = true;
		}
	}

	// ========== ICommand / RelayCommand Tests ==========

	[Test]
	public static void RelayCommand_ExecutesDelegate()
	{
		bool executed = false;
		let command = scope RelayCommand(new [&]() => { executed = true; });

		command.Execute();

		Test.Assert(executed, "Command should execute delegate");
	}

	[Test]
	public static void RelayCommand_CanExecuteDefaultsToTrue()
	{
		let command = scope RelayCommand(new () => { });

		Test.Assert(command.CanExecute(), "CanExecute should default to true");
	}

	[Test]
	public static void RelayCommand_CanExecuteRespectsDelegate()
	{
		bool canExecute = false;
		let command = scope RelayCommand(
			new () => { },
			new [&]() => canExecute
		);

		Test.Assert(!command.CanExecute(), "CanExecute should return false initially");

		canExecute = true;
		Test.Assert(command.CanExecute(), "CanExecute should return true when delegate returns true");
	}

	[Test]
	public static void RelayCommand_OnlyExecutesWhenCanExecute()
	{
		bool executed = false;
		bool canExecute = false;
		let command = scope RelayCommand(
			new [&]() => { executed = true; },
			new [&]() => canExecute
		);

		command.Execute();
		Test.Assert(!executed, "Should not execute when CanExecute is false");

		canExecute = true;
		command.Execute();
		Test.Assert(executed, "Should execute when CanExecute is true");
	}

	// ========== Button Tests ==========

	[Test]
	public static void Button_FiresClickOnMouseUp()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let button = new Button("Test");
		button.Width = 100;
		button.Height = 40;
		panel.AddChild(button);

		bool clicked = false;
		button.Click.Subscribe(new [&](btn) => { clicked = true; });

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Move mouse over button first to set IsHovered
		ctx.InputManager.ProcessMouseMove(50, 20);

		// Mouse down
		ctx.ProcessMouseDown(50, 20, .Left);
		Test.Assert(!clicked, "Click should not fire on mouse down");

		// Mouse up
		ctx.ProcessMouseUp(50, 20, .Left);
		Test.Assert(clicked, "Click should fire on mouse up");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void Button_ExecutesCommand()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		bool commandExecuted = false;
		let command = new RelayCommand(new [&]() => { commandExecuted = true; });

		let button = new Button("Test");
		button.Width = 100;
		button.Height = 40;
		button.Command = command;
		panel.AddChild(button);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Move mouse over button first to set IsHovered
		ctx.InputManager.ProcessMouseMove(50, 20);

		// Click button
		ctx.ProcessMouseDown(50, 20, .Left);
		ctx.ProcessMouseUp(50, 20, .Left);

		Test.Assert(commandExecuted, "Button should execute command on click");

		ctx.RootElement = null;
		delete panel;
		delete command;
	}

	[Test]
	public static void Button_DisabledWhenCanExecuteFalse()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		bool canExecute = false;
		let command = new RelayCommand(
			new () => { },
			new [&]() => canExecute
		);

		let button = new Button("Test");
		button.Width = 100;
		button.Height = 40;
		button.Command = command;
		panel.AddChild(button);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		Test.Assert(!button.IsEnabled, "Button should be disabled when CanExecute is false");

		canExecute = true;
		command.RaiseCanExecuteChanged();

		Test.Assert(button.IsEnabled, "Button should be enabled when CanExecute is true");

		ctx.RootElement = null;
		delete panel;
		delete command;
	}

	[Test]
	public static void Button_KeyboardActivation()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let button = new Button("Test");
		button.Width = 100;
		button.Height = 40;
		panel.AddChild(button);

		bool clicked = false;
		button.Click.Subscribe(new [&](btn) => { clicked = true; });

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Focus button
		ctx.FocusManager.SetFocus(button);

		// Press Space
		ctx.InputManager.ProcessKeyDown(.Space, .None);
		ctx.InputManager.ProcessKeyUp(.Space, .None);

		Test.Assert(clicked, "Button should activate on Space key");

		ctx.RootElement = null;
		delete panel;
	}

	// ========== ToggleButton Tests ==========

	[Test]
	public static void ToggleButton_TogglesOnClick()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let toggle = new ToggleButton("Toggle");
		toggle.Width = 100;
		toggle.Height = 40;
		panel.AddChild(toggle);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		Test.Assert(!toggle.IsChecked, "ToggleButton should be unchecked initially");

		// Move mouse over button first to set IsHovered
		ctx.InputManager.ProcessMouseMove(50, 20);

		// Click to check
		ctx.ProcessMouseDown(50, 20, .Left);
		ctx.ProcessMouseUp(50, 20, .Left);

		Test.Assert(toggle.IsChecked, "ToggleButton should be checked after first click");

		// Click to uncheck
		ctx.ProcessMouseDown(50, 20, .Left);
		ctx.ProcessMouseUp(50, 20, .Left);

		Test.Assert(!toggle.IsChecked, "ToggleButton should be unchecked after second click");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ToggleButton_FiresCheckedEvent()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let toggle = new ToggleButton("Toggle");
		toggle.Width = 100;
		toggle.Height = 40;
		panel.AddChild(toggle);

		bool checkedFired = false;
		bool uncheckedFired = false;
		toggle.Checked.Subscribe(new [&](tb, isChecked) => { checkedFired = true; });
		toggle.Unchecked.Subscribe(new [&](tb) => { uncheckedFired = true; });

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Move mouse over button first to set IsHovered
		ctx.InputManager.ProcessMouseMove(50, 20);

		// Click to check
		ctx.ProcessMouseDown(50, 20, .Left);
		ctx.ProcessMouseUp(50, 20, .Left);

		Test.Assert(checkedFired, "Checked event should fire");

		// Click to uncheck
		ctx.ProcessMouseDown(50, 20, .Left);
		ctx.ProcessMouseUp(50, 20, .Left);

		Test.Assert(uncheckedFired, "Unchecked event should fire");

		ctx.RootElement = null;
		delete panel;
	}

	// ========== CheckBox Tests ==========

	[Test]
	public static void CheckBox_MeasuresWithIndicator()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let checkbox = new CheckBox("Test Label");
		panel.AddChild(checkbox);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// CheckBox should have width for indicator + spacing + text
		Test.Assert(checkbox.DesiredSize.Width >= checkbox.BoxSize, "CheckBox should measure indicator size");
		Test.Assert(checkbox.DesiredSize.Height >= checkbox.BoxSize, "CheckBox height should be at least indicator size");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void CheckBox_TogglesOnClick()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let checkbox = new CheckBox("Test");
		checkbox.Width = 150;
		checkbox.Height = 30;
		panel.AddChild(checkbox);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		Test.Assert(!checkbox.IsChecked, "CheckBox should be unchecked initially");

		// Move mouse over checkbox first to set IsHovered
		ctx.InputManager.ProcessMouseMove(10, 15);

		// Click to check
		ctx.ProcessMouseDown(10, 15, .Left);  // Click on indicator
		ctx.ProcessMouseUp(10, 15, .Left);

		Test.Assert(checkbox.IsChecked, "CheckBox should be checked after click");

		ctx.RootElement = null;
		delete panel;
	}

	// ========== RadioButton Tests ==========

	[Test]
	public static void RadioButton_MutualExclusion()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		// Add all radio buttons to same group
		let radio1 = new RadioButton("Option 1", "testGroup");
		radio1.Width = 150;
		radio1.Height = 30;
		radio1.IsChecked = true;
		panel.AddChild(radio1);

		let radio2 = new RadioButton("Option 2", "testGroup");
		radio2.Width = 150;
		radio2.Height = 30;
		radio2.Margin = .(0, 30, 0, 0);
		panel.AddChild(radio2);

		let radio3 = new RadioButton("Option 3", "testGroup");
		radio3.Width = 150;
		radio3.Height = 30;
		radio3.Margin = .(0, 60, 0, 0);
		panel.AddChild(radio3);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		Test.Assert(radio1.IsChecked, "Radio1 should be checked initially");
		Test.Assert(!radio2.IsChecked, "Radio2 should be unchecked initially");
		Test.Assert(!radio3.IsChecked, "Radio3 should be unchecked initially");

		// Move mouse over radio2 and click
		ctx.InputManager.ProcessMouseMove(10, 45);
		ctx.ProcessMouseDown(10, 45, .Left);
		ctx.ProcessMouseUp(10, 45, .Left);

		Test.Assert(!radio1.IsChecked, "Radio1 should be unchecked after clicking radio2");
		Test.Assert(radio2.IsChecked, "Radio2 should be checked");
		Test.Assert(!radio3.IsChecked, "Radio3 should remain unchecked");

		// Move mouse over radio3 and click
		ctx.InputManager.ProcessMouseMove(10, 75);
		ctx.ProcessMouseDown(10, 75, .Left);
		ctx.ProcessMouseUp(10, 75, .Left);

		Test.Assert(!radio1.IsChecked, "Radio1 should remain unchecked");
		Test.Assert(!radio2.IsChecked, "Radio2 should be unchecked after clicking radio3");
		Test.Assert(radio3.IsChecked, "Radio3 should be checked");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void RadioButton_DoesNotUncheckSelf()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let radio = new RadioButton("Only Option", "soloGroup");
		radio.Width = 150;
		radio.Height = 30;
		radio.IsChecked = true;
		panel.AddChild(radio);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		Test.Assert(radio.IsChecked, "RadioButton should be checked");

		// Move mouse over and click again - should stay checked
		ctx.InputManager.ProcessMouseMove(10, 15);
		ctx.ProcessMouseDown(10, 15, .Left);
		ctx.ProcessMouseUp(10, 15, .Left);

		Test.Assert(radio.IsChecked, "RadioButton should remain checked when clicked again");

		ctx.RootElement = null;
		delete panel;
	}

	// ========== ToggleSwitch Tests ==========

	[Test]
	public static void ToggleSwitch_TogglesOnClick()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let toggle = new ToggleSwitch("Wi-Fi");
		toggle.Width = 100;
		toggle.Height = 30;
		panel.AddChild(toggle);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		Test.Assert(!toggle.IsChecked, "ToggleSwitch should be off initially");

		// Move mouse over toggle and click to turn on
		ctx.InputManager.ProcessMouseMove(20, 15);
		ctx.ProcessMouseDown(20, 15, .Left);
		ctx.ProcessMouseUp(20, 15, .Left);

		Test.Assert(toggle.IsChecked, "ToggleSwitch should be on after click");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ToggleSwitch_MeasuresCorrectly()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let toggle = new ToggleSwitch();
		panel.AddChild(toggle);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		Test.Assert(toggle.DesiredSize.Width >= toggle.TrackWidth, "ToggleSwitch width should include track");
		Test.Assert(toggle.DesiredSize.Height >= toggle.TrackHeight, "ToggleSwitch height should include track");

		ctx.RootElement = null;
		delete panel;
	}

	// ========== Hyperlink Tests ==========

	[Test]
	public static void Hyperlink_FiresRequestNavigate()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let hyperlink = new Hyperlink("Click me", "https://example.com");
		hyperlink.Width = 100;
		hyperlink.Height = 30;
		panel.AddChild(hyperlink);

		String navigatedUri = scope .();
		hyperlink.RequestNavigate.Subscribe(new [&](hl, uri) => {
			navigatedUri.Set(uri);
		});

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Move mouse over hyperlink and click
		ctx.InputManager.ProcessMouseMove(50, 15);
		ctx.ProcessMouseDown(50, 15, .Left);
		ctx.ProcessMouseUp(50, 15, .Left);

		Test.Assert(navigatedUri == "https://example.com", "Hyperlink should fire RequestNavigate with URI");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void Hyperlink_AlsoFiresClick()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let hyperlink = new Hyperlink("Click me", "https://example.com");
		hyperlink.Width = 100;
		hyperlink.Height = 30;
		panel.AddChild(hyperlink);

		bool clicked = false;
		hyperlink.Click.Subscribe(new [&](btn) => { clicked = true; });

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Move mouse over hyperlink and click
		ctx.InputManager.ProcessMouseMove(50, 15);
		ctx.ProcessMouseDown(50, 15, .Left);
		ctx.ProcessMouseUp(50, 15, .Left);

		Test.Assert(clicked, "Hyperlink should also fire Click event");

		ctx.RootElement = null;
		delete panel;
	}

	// ========== RepeatButton Tests ==========

	[Test]
	public static void RepeatButton_FiresImmediatelyOnPress()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let repeatButton = new RepeatButton("+");
		repeatButton.Width = 50;
		repeatButton.Height = 30;
		panel.AddChild(repeatButton);

		int clickCount = 0;
		repeatButton.Click.Subscribe(new [&](btn) => { clickCount++; });

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Move mouse over button first to set IsHovered (for repeat timing check)
		ctx.InputManager.ProcessMouseMove(25, 15);

		// Mouse down should fire first click immediately
		ctx.ProcessMouseDown(25, 15, .Left);

		Test.Assert(clickCount == 1, "RepeatButton should fire click immediately on mouse down");

		ctx.ProcessMouseUp(25, 15, .Left);

		ctx.RootElement = null;
		delete panel;
	}

	// ========== Visual State Tests ==========

	[Test]
	public static void Button_VisualStates()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let button = new Button("Test");
		button.Width = 100;
		button.Height = 40;
		panel.AddChild(button);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Normal state
		Test.Assert(button.CurrentState == .Normal, "Initial state should be Normal");

		// Hover state
		ctx.InputManager.ProcessMouseMove(50, 20);
		Test.Assert(button.CurrentState == .Hover, "State should be Hover when mouse is over");

		// Pressed state
		ctx.ProcessMouseDown(50, 20, .Left);
		Test.Assert(button.CurrentState == .Pressed, "State should be Pressed when mouse is down");

		// Back to focused after release (button was focused during mouse down, Focused takes priority over Hover)
		ctx.ProcessMouseUp(50, 20, .Left);
		Test.Assert(button.CurrentState == .Focused, "State should be Focused after release (button got focus when clicked)");
		Test.Assert(button.IsHovered, "Button should still be hovered");

		// Back to hover when mouse leaves but still focused
		ctx.InputManager.ProcessMouseMove(500, 500);
		Test.Assert(button.CurrentState == .Focused, "State should remain Focused when mouse leaves (still has focus)");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void Button_DisabledState()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let button = new Button("Test");
		button.Width = 100;
		button.Height = 40;
		button.IsEnabled = false;
		panel.AddChild(button);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		Test.Assert(button.CurrentState == .Disabled, "Disabled button should have Disabled state");

		// Hovering shouldn't change state
		ctx.InputManager.ProcessMouseMove(50, 20);
		Test.Assert(button.CurrentState == .Disabled, "Disabled button should stay Disabled on hover");

		ctx.RootElement = null;
		delete panel;
	}
}
