namespace GUISandbox;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.GUI;

/// Demo 11: List Controls
/// Shows ListBox with selection modes and ComboBox dropdown.
class ListControlsDemo
{
	private StackPanel mRoot /*~ delete _*/;
	private TextBlock mSingleSelLabel /*~ delete _*/;
	private TextBlock mMultiSelLabel /*~ delete _*/;
	private TextBlock mComboSelLabel /*~ delete _*/;

	public UIElement CreateDemo()
	{
		mRoot = new StackPanel();
		mRoot.Orientation = .Vertical;
		mRoot.Spacing = 15;
		mRoot.Padding = .(20, 20, 20, 20);

		// Title
		let title = new TextBlock("List Controls Demo");
		title.FontSize = 20;
		mRoot.AddChild(title);

		// ListBox section
		CreateListBoxSection();

		// ComboBox section
		CreateComboBoxSection();

		return mRoot;
	}

	private void CreateListBoxSection()
	{
		let section = new StackPanel();
		section.Orientation = .Vertical;
		section.Spacing = 10;
		section.Padding = .(15, 15, 15, 15);

		let header = new TextBlock("ListBox - Selection Modes");
		header.FontSize = 16;
		section.AddChild(header);

		// Horizontal layout for two listboxes
		let row = new StackPanel();
		row.Orientation = .Horizontal;
		row.Spacing = 30;

		// === Single Selection ListBox ===
		let singleCol = new StackPanel();
		singleCol.Orientation = .Vertical;
		singleCol.Spacing = 5;

		let singleLabel = new TextBlock("Single Selection:");
		singleCol.AddChild(singleLabel);

		let singleList = new ListBox();
		singleList.SelectionMode = .Single;
		singleList.Width = 200;
		singleList.Height = 150;

		// Add items (control owns the strings internally)
		singleList.AddText("Apple");
		singleList.AddText("Banana");
		singleList.AddText("Cherry");
		singleList.AddText("Date");
		singleList.AddText("Elderberry");
		singleList.AddText("Fig");
		singleList.AddText("Grape");
		singleList.AddText("Honeydew");

		mSingleSelLabel = new TextBlock("Selected: (none)");
		singleList.SelectionChanged.Subscribe(new (list) => {
			if (list.SelectedItem != null)
			{
				if (let str = list.SelectedItem as String)
					mSingleSelLabel.Text = scope $"Selected: {str}";
			}
			else
			{
				mSingleSelLabel.Text = "Selected: (none)";
			}
		});

		singleCol.AddChild(singleList);
		singleCol.AddChild(mSingleSelLabel);
		row.AddChild(singleCol);

		// === Extended Selection ListBox ===
		let multiCol = new StackPanel();
		multiCol.Orientation = .Vertical;
		multiCol.Spacing = 5;

		let multiLabel = new TextBlock("Extended Selection (Ctrl/Shift+click):");
		multiCol.AddChild(multiLabel);

		let multiList = new ListBox();
		multiList.SelectionMode = .Extended;
		multiList.Width = 200;
		multiList.Height = 150;

		// Add items
		multiList.AddText("Red");
		multiList.AddText("Orange");
		multiList.AddText("Yellow");
		multiList.AddText("Green");
		multiList.AddText("Blue");
		multiList.AddText("Indigo");
		multiList.AddText("Violet");

		mMultiSelLabel = new TextBlock("Selected: 0 items");
		multiList.SelectionChanged.Subscribe(new (list) => {
			mMultiSelLabel.Text = scope $"Selected: {list.SelectedCount} items";
		});

		multiCol.AddChild(multiList);
		multiCol.AddChild(mMultiSelLabel);

		// Selection buttons
		let btnRow = new StackPanel();
		btnRow.Orientation = .Horizontal;
		btnRow.Spacing = 5;

		let selectAllBtn = new Button("Select All");
		selectAllBtn.Click.Subscribe(new (b) => multiList.SelectAll());
		btnRow.AddChild(selectAllBtn);

		let clearBtn = new Button("Clear");
		clearBtn.Click.Subscribe(new (b) => multiList.ClearSelection());
		btnRow.AddChild(clearBtn);

		multiCol.AddChild(btnRow);
		row.AddChild(multiCol);

		section.AddChild(row);

		// Instructions
		let instructions = new TextBlock("Keyboard: Up/Down to navigate, Home/End, Ctrl+A to select all");
		section.AddChild(instructions);

		mRoot.AddChild(section);
	}

	private void CreateComboBoxSection()
	{
		let section = new StackPanel();
		section.Orientation = .Vertical;
		section.Spacing = 10;
		section.Padding = .(15, 15, 15, 15);

		let header = new TextBlock("ComboBox");
		header.FontSize = 16;
		section.AddChild(header);

		let row = new StackPanel();
		row.Orientation = .Horizontal;
		row.Spacing = 15;

		let comboLabel = new TextBlock("Select a country:");
		row.AddChild(comboLabel);

		let combo = new ComboBox();
		combo.Width = 200;
		combo.AddText("United States");
		combo.AddText("Canada");
		combo.AddText("United Kingdom");
		combo.AddText("France");
		combo.AddText("Germany");
		combo.AddText("Japan");
		combo.AddText("Australia");
		combo.AddText("Brazil");

		combo.SelectedIndex = 0;  // Default selection

		mComboSelLabel = new TextBlock("Selected: United States");
		combo.SelectionChanged.Subscribe(new (cb) => {
			if (let str = cb.SelectedItem as String)
				mComboSelLabel.Text = scope $"Selected: {str}";
		});

		row.AddChild(combo);
		row.AddChild(mComboSelLabel);

		section.AddChild(row);

		// Instructions
		let instructions = new TextBlock("Click to open dropdown, arrow keys when open to navigate");
		section.AddChild(instructions);

		mRoot.AddChild(section);
	}
}
