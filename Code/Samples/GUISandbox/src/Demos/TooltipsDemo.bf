namespace GUISandbox;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.GUI;

/// Demonstrates tooltip functionality.
class TooltipsDemo
{
	public UIElement CreateDemo()
	{
		let root = new StackPanel();
		root.Orientation = .Vertical;
		root.Margin = .(20, 20, 20, 20);

		// Title
		let title = new TextBlock("Tooltips Demo");
		title.FontSize = 20;
		title.Margin = .(0, 0, 0, 20);
		root.AddChild(title);

		let description = new TextBlock("Hover over the controls below to see their tooltips.");
		description.Foreground = Color(180, 180, 180, 255);
		description.Margin = .(0, 0, 0, 20);
		root.AddChild(description);

		// Basic tooltip section
		let basicSection = new StackPanel();
		basicSection.Orientation = .Horizontal;
		basicSection.Margin = .(0, 0, 0, 20);
		root.AddChild(basicSection);

		let basicLabel = new TextBlock("Basic Tooltips:");
		basicLabel.Width = 140;
		basicLabel.VerticalAlignment = .Center;
		basicSection.AddChild(basicLabel);

		let btn1 = new Button("Hover Me");
		btn1.Margin = .(0, 0, 10, 0);
		btn1.TooltipText = "This is a simple tooltip";
		basicSection.AddChild(btn1);

		let btn2 = new Button("Information");
		btn2.Margin = .(0, 0, 10, 0);
		btn2.TooltipText = "Click this button to perform an action.\nTooltips can have multiple lines.";
		basicSection.AddChild(btn2);

		let btn3 = new Button("Disabled");
		btn3.IsEnabled = false;
		btn3.TooltipText = "This button is disabled";
		basicSection.AddChild(btn3);

		// Various controls with tooltips
		let controlsSection = new StackPanel();
		controlsSection.Orientation = .Horizontal;
		controlsSection.Margin = .(0, 0, 0, 20);
		root.AddChild(controlsSection);

		let controlsLabel = new TextBlock("Control Tooltips:");
		controlsLabel.Width = 140;
		controlsLabel.VerticalAlignment = .Center;
		controlsSection.AddChild(controlsLabel);

		let checkbox = new CheckBox("Enable Feature");
		checkbox.Margin = .(0, 0, 20, 0);
		checkbox.TooltipText = "Toggle this option to enable the feature";
		controlsSection.AddChild(checkbox);

		let radioA = new RadioButton("Option A");
		radioA.GroupName = "tooltipDemo";
		radioA.Margin = .(0, 0, 10, 0);
		radioA.TooltipText = "Select option A";
		controlsSection.AddChild(radioA);

		let radioB = new RadioButton("Option B");
		radioB.GroupName = "tooltipDemo";
		radioB.Margin = .(0, 0, 10, 0);
		radioB.TooltipText = "Select option B";
		controlsSection.AddChild(radioB);

		// Slider with tooltip
		let sliderSection = new StackPanel();
		sliderSection.Orientation = .Horizontal;
		sliderSection.Margin = .(0, 0, 0, 20);
		root.AddChild(sliderSection);

		let sliderLabel = new TextBlock("Slider:");
		sliderLabel.Width = 140;
		sliderLabel.VerticalAlignment = .Center;
		sliderSection.AddChild(sliderLabel);

		let slider = new Slider();
		slider.Width = 200;
		slider.Minimum = 0;
		slider.Maximum = 100;
		slider.Value = 50;
		slider.TooltipText = "Drag to adjust the value (0-100)";
		sliderSection.AddChild(slider);

		// Text input with tooltip
		let textSection = new StackPanel();
		textSection.Orientation = .Horizontal;
		textSection.Margin = .(0, 0, 0, 20);
		root.AddChild(textSection);

		let textLabel = new TextBlock("Text Input:");
		textLabel.Width = 140;
		textLabel.VerticalAlignment = .Center;
		textSection.AddChild(textLabel);

		let textBox = new TextBox();
		textBox.Width = 200;
		textBox.Placeholder = "Enter text...";
		textBox.TooltipText = "Enter your text here.\nPress Enter to confirm.";
		textSection.AddChild(textBox);

		// ComboBox with tooltip
		let comboSection = new StackPanel();
		comboSection.Orientation = .Horizontal;
		comboSection.Margin = .(0, 0, 0, 20);
		root.AddChild(comboSection);

		let comboLabel = new TextBlock("ComboBox:");
		comboLabel.Width = 140;
		comboLabel.VerticalAlignment = .Center;
		comboSection.AddChild(comboLabel);

		let combo = new ComboBox();
		combo.Width = 150;
		combo.AddItem("Option 1");
		combo.AddItem("Option 2");
		combo.AddItem("Option 3");
		combo.SelectedIndex = 0;
		combo.TooltipText = "Select an option from the dropdown";
		comboSection.AddChild(combo);

		// Image/icon area with tooltip
		let iconSection = new StackPanel();
		iconSection.Orientation = .Horizontal;
		iconSection.Margin = .(0, 0, 0, 20);
		root.AddChild(iconSection);

		let iconLabel = new TextBlock("Icon Tooltips:");
		iconLabel.Width = 140;
		iconLabel.VerticalAlignment = .Center;
		iconSection.AddChild(iconLabel);

		// Create colored boxes as icon placeholders
		let iconSave = CreateIconBox(Color(80, 160, 80, 255), "Save");
		iconSave.TooltipText = "Save the current document (Ctrl+S)";
		iconSection.AddChild(iconSave);

		let iconOpen = CreateIconBox(Color(80, 120, 200, 255), "Open");
		iconOpen.TooltipText = "Open an existing file (Ctrl+O)";
		iconSection.AddChild(iconOpen);

		let iconNew = CreateIconBox(Color(200, 160, 80, 255), "New");
		iconNew.TooltipText = "Create a new document (Ctrl+N)";
		iconSection.AddChild(iconNew);

		let iconDelete = CreateIconBox(Color(200, 80, 80, 255), "Del");
		iconDelete.TooltipText = "Delete the selected item\n(This action cannot be undone)";
		iconSection.AddChild(iconDelete);

		// Help text
		let helpText = new TextBlock("Tooltips appear after hovering for a short delay.\nThey automatically hide when you move away or click.");
		helpText.Foreground = Color(140, 140, 140, 255);
		helpText.Margin = .(0, 20, 0, 0);
		root.AddChild(helpText);

		return root;
	}

	private ContentControl CreateIconBox(Color color, StringView text)
	{
		let iconBox = new ContentControl();
		iconBox.Width = 40;
		iconBox.Height = 40;
		iconBox.Background = color;
		iconBox.Margin = .(0, 0, 10, 0);

		let label = new TextBlock(text);
		label.Foreground = Color.White;
		label.HorizontalAlignment = .Center;
		label.VerticalAlignment = .Center;
		label.FontSize = 10;
		iconBox.Content = label;

		return iconBox;
	}
}
