namespace GUISandbox;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.GUI;

/// Demo 14: Popup & Dialog System
/// Shows tooltips, context menus, dialogs, and message boxes.
class PopupDialogDemo
{
	private StackPanel mRoot /*~ delete _*/;
	private TextBlock mStatusLabel /*~ delete _*/;
	private GUIContext mContext;

	public UIElement CreateDemo(GUIContext context)
	{
		mContext = context;

		mRoot = new StackPanel();
		mRoot.Orientation = .Vertical;
		mRoot.Spacing = 15;
		mRoot.Padding = .(20, 70, 20, 20);

		// Title
		let title = new TextBlock("Popup & Dialog System Demo");
		title.FontSize = 20;
		mRoot.AddChild(title);

		// Tooltip section
		CreateTooltipSection();

		// Context menu section
		CreateContextMenuSection();

		// Dialog section
		CreateDialogSection();

		// Flyout section
		CreateFlyoutSection();

		// Standalone Popup section
		CreatePopupSection();

		// MessageBox section
		CreateMessageBoxSection();

		// Status label
		mStatusLabel = new TextBlock("Hover over controls for tooltips, right-click for context menu");
		mRoot.AddChild(mStatusLabel);

		// Instructions
		let instructions = new TextBlock("Tooltips: Hover 0.5s to show | Context Menu: Right-click | Dialog: Click buttons | ESC closes dialogs/menus");
		mRoot.AddChild(instructions);

		return mRoot;
	}

	private void CreateTooltipSection()
	{
		let section = new StackPanel();
		section.Orientation = .Vertical;
		section.Spacing = 10;
				section.Padding = .(15, 15, 15, 15);

		let header = new TextBlock("Tooltips - Hover over controls (placement: Mouse)");
		header.FontSize = 16;
		section.AddChild(header);

		// Placement selector row
		let placementRow = new StackPanel();
		placementRow.Orientation = .Horizontal;
		placementRow.Spacing = 10;

		let placementLabel = new TextBlock("Placement:");
		placementLabel.VerticalAlignment = .Center;
		placementRow.AddChild(placementLabel);

		let mouseBtn = new Button("Mouse");
		mouseBtn.TooltipText = "Tooltip follows mouse cursor";
		mouseBtn.Click.Subscribe(new (b) => {
			mContext.TooltipService.Placement = .Mouse;
			header.Text = "Tooltips - Hover over controls (placement: Mouse)";
		});
		placementRow.AddChild(mouseBtn);

		let topBtn = new Button("Top");
		topBtn.TooltipText = "Tooltip above element";
		topBtn.Click.Subscribe(new (b) => {
			mContext.TooltipService.Placement = .Top;
			header.Text = "Tooltips - Hover over controls (placement: Top)";
		});
		placementRow.AddChild(topBtn);

		let bottomBtn = new Button("Bottom");
		bottomBtn.TooltipText = "Tooltip below element";
		bottomBtn.Click.Subscribe(new (b) => {
			mContext.TooltipService.Placement = .Bottom;
			header.Text = "Tooltips - Hover over controls (placement: Bottom)";
		});
		placementRow.AddChild(bottomBtn);

		let leftBtn = new Button("Left");
		leftBtn.TooltipText = "Tooltip left of element";
		leftBtn.Click.Subscribe(new (b) => {
			mContext.TooltipService.Placement = .Left;
			header.Text = "Tooltips - Hover over controls (placement: Left)";
		});
		placementRow.AddChild(leftBtn);

		let rightBtn = new Button("Right");
		rightBtn.TooltipText = "Tooltip right of element";
		rightBtn.Click.Subscribe(new (b) => {
			mContext.TooltipService.Placement = .Right;
			header.Text = "Tooltips - Hover over controls (placement: Right)";
		});
		placementRow.AddChild(rightBtn);

		section.AddChild(placementRow);

		// Sample controls with tooltips
		let buttonRow = new StackPanel();
		buttonRow.Orientation = .Horizontal;
		buttonRow.Spacing = 15;

		let btn1 = new Button("Save");
		btn1.TooltipText = "Save the current document (Ctrl+S)";
		buttonRow.AddChild(btn1);

		let btn2 = new Button("Open");
		btn2.TooltipText = "Open an existing document (Ctrl+O)";
		buttonRow.AddChild(btn2);

		let btn3 = new Button("New");
		btn3.TooltipText = "Create a new document (Ctrl+N)";
		buttonRow.AddChild(btn3);

		// TextBox with tooltip
		let textBox = new TextBox();
		textBox.Width = .Fixed(150);
		textBox.TooltipText = "Enter your name here";
		textBox.Placeholder = "Name...";
		buttonRow.AddChild(textBox);

		section.AddChild(buttonRow);
		mRoot.AddChild(section);
	}

	private void CreateContextMenuSection()
	{
		let section = new StackPanel();
		section.Orientation = .Vertical;
		section.Spacing = 10;
				section.Padding = .(15, 15, 15, 15);

		let header = new TextBlock("Context Menu - Right-click the panel below");
		header.FontSize = 16;
		section.AddChild(header);

		// Panel with context menu
		let panel = new Border();
		panel.Width = .Fixed(300);
		panel.Height = .Fixed(100);

		let panelText = new TextBlock("Right-click me!");
		panelText.HorizontalAlignment = .Center;
		panelText.VerticalAlignment = .Center;
		panel.Child = panelText;

		// Create context menu
		let contextMenu = new ContextMenu();

		let cutItem = contextMenu.AddItem("Cut");
		cutItem.ShortcutText = "Ctrl+X";
		cutItem.Click.Subscribe(new (item) => {
			mStatusLabel.Text = "Cut clicked!";
		});

		let copyItem = contextMenu.AddItem("Copy");
		copyItem.ShortcutText = "Ctrl+C";
		copyItem.Click.Subscribe(new (item) => {
			mStatusLabel.Text = "Copy clicked!";
		});

		let pasteItem = contextMenu.AddItem("Paste");
		pasteItem.ShortcutText = "Ctrl+V";
		pasteItem.Click.Subscribe(new (item) => {
			mStatusLabel.Text = "Paste clicked!";
		});

		contextMenu.AddSeparator();

		// Submenu demonstration - Edit submenu with nested items
		let editSubmenu = contextMenu.AddItem("Edit");
		let undoItem = editSubmenu.AddItem("Undo");
		undoItem.ShortcutText = "Ctrl+Z";
		undoItem.Click.Subscribe(new (item) => {
			mStatusLabel.Text = "Undo clicked!";
		});
		let redoItem = editSubmenu.AddItem("Redo");
		redoItem.ShortcutText = "Ctrl+Y";
		redoItem.Click.Subscribe(new (item) => {
			mStatusLabel.Text = "Redo clicked!";
		});
		editSubmenu.AddSeparator();
		let findItem = editSubmenu.AddItem("Find");
		findItem.ShortcutText = "Ctrl+F";
		findItem.Click.Subscribe(new (item) => {
			mStatusLabel.Text = "Find clicked!";
		});
		let replaceItem = editSubmenu.AddItem("Replace");
		replaceItem.ShortcutText = "Ctrl+H";
		replaceItem.Click.Subscribe(new (item) => {
			mStatusLabel.Text = "Replace clicked!";
		});

		contextMenu.AddSeparator();

		let deleteItem = contextMenu.AddItem("Delete");
		deleteItem.Click.Subscribe(new (item) => {
			mStatusLabel.Text = "Delete clicked!";
		});

		contextMenu.AddSeparator();

		let checkableItem = contextMenu.AddItem("Show Grid");
		checkableItem.IsCheckable = true;
		checkableItem.IsChecked = true;
		checkableItem.Click.Subscribe(new (item) => {
			mStatusLabel.Text = scope $"Show Grid: {item.IsChecked}";
		});

		panel.ContextMenu = contextMenu;

		section.AddChild(panel);
		mRoot.AddChild(section);
	}

	private void CreateDialogSection()
	{
		let section = new StackPanel();
		section.Orientation = .Vertical;
		section.Spacing = 10;
				section.Padding = .(15, 15, 15, 15);

		let header = new TextBlock("Dialogs - Click buttons to open");
		header.FontSize = 16;
		section.AddChild(header);

		let buttonRow = new StackPanel();
		buttonRow.Orientation = .Horizontal;
		buttonRow.Spacing = 15;

		// Simple dialog
		let simpleDialogBtn = new Button("Simple Dialog");
		simpleDialogBtn.Click.Subscribe(new (b) => {
			let dialog = new Dialog("Simple Dialog");
			dialog.Padding = .(12, 8, 12, 8);
			dialog.DialogMinWidth = 350;

			let content = new TextBlock("This is a simple dialog with OK and Cancel buttons.");
			content.TextWrapping = .Wrap;
			dialog.Content = content;

			dialog.AddButton("OK", .OK);
			dialog.AddButton("Cancel", .Cancel);

			dialog.OnAttachedToContext(mContext);
			dialog.Show();

			dialog.Closed.Subscribe(new (d, result) => {
				mStatusLabel.Text = scope $"Dialog closed with: {result}";
				mContext.QueueDelete(d);
			});
		});
		buttonRow.AddChild(simpleDialogBtn);

		// Input dialog
		let inputDialogBtn = new Button("Input Dialog");
		inputDialogBtn.Click.Subscribe(new (b) => {
			let dialog = new Dialog("Enter Name");
			dialog.Padding = .(12, 8, 12, 8);
			dialog.DialogMinWidth = 400;

			let content = new StackPanel();
			content.Orientation = .Vertical;
			content.Spacing = 8;

			let label = new TextBlock("Please enter your name:");
			content.AddChild(label);

			let inputTextBox = new TextBox();
			inputTextBox.Placeholder = "Name...";
			inputTextBox.HorizontalAlignment = .Stretch;
			content.AddChild(inputTextBox);

			dialog.Content = content;

			dialog.AddButton("OK", .OK);
			dialog.AddButton("Cancel", .Cancel);

			dialog.OnAttachedToContext(mContext);
			dialog.Show();

			dialog.Closed.Subscribe(new (d, result) => {
				if (result == .OK)
					mStatusLabel.Text = scope $"Hello, {inputTextBox.Text}!";
				else
					mStatusLabel.Text = "Input cancelled";
				mContext.QueueDelete(d);
			});
		});
		buttonRow.AddChild(inputDialogBtn);

		section.AddChild(buttonRow);
		mRoot.AddChild(section);
	}

	private void CreateFlyoutSection()
	{
		let section = new StackPanel();
		section.Orientation = .Vertical;
		section.Spacing = 10;
				section.Padding = .(15, 15, 15, 15);

		let header = new TextBlock("Flyouts - Lightweight popups (click outside to close)");
		header.FontSize = 16;
		section.AddChild(header);

		let buttonRow = new StackPanel();
		buttonRow.Orientation = .Horizontal;
		buttonRow.Spacing = 15;

		// Simple flyout
		let flyoutBtn = new Button("Show Flyout");
		flyoutBtn.Click.Subscribe(new (b) => {
			let flyout = new Flyout();
			flyout.Placement = .Bottom;

			let content = new StackPanel();
			content.Orientation = .Vertical;
			content.Spacing = 8;

			let label = new TextBlock("This is a flyout!");
			content.AddChild(label);

			let closeBtn = new Button("Close");
			closeBtn.Click.Subscribe(new (cb) => {
				flyout.Hide();
			});
			content.AddChild(closeBtn);

			flyout.Content = content;
			flyout.ShowAt(b);

			flyout.Closed.Subscribe(new (f) => {
				mContext.QueueDelete(f);
			});
		});
		buttonRow.AddChild(flyoutBtn);

		// Right flyout
		let rightFlyoutBtn = new Button("Flyout Right");
		rightFlyoutBtn.Click.Subscribe(new (b) => {
			let flyout = new Flyout();
			flyout.Placement = .Right;

			let content = new TextBlock("Flyout to the right!");
			flyout.Content = content;
			flyout.ShowAt(b);

			flyout.Closed.Subscribe(new (f) => {
				mContext.QueueDelete(f);
			});
		});
		buttonRow.AddChild(rightFlyoutBtn);

		// Top flyout
		let topFlyoutBtn = new Button("Flyout Top");
		topFlyoutBtn.Click.Subscribe(new (b) => {
			let flyout = new Flyout();
			flyout.Placement = .Top;

			let content = new TextBlock("Flyout above!");
			flyout.Content = content;
			flyout.ShowAt(b);

			flyout.Closed.Subscribe(new (f) => {
				mContext.QueueDelete(f);
			});
		});
		buttonRow.AddChild(topFlyoutBtn);

		section.AddChild(buttonRow);
		mRoot.AddChild(section);
	}

	private void CreatePopupSection()
	{
		let section = new StackPanel();
		section.Orientation = .Vertical;
		section.Spacing = 10;
				section.Padding = .(15, 15, 15, 15);

		let header = new TextBlock("Standalone Popup - Various placements and behaviors");
		header.FontSize = 16;
		section.AddChild(header);

		let buttonRow = new StackPanel();
		buttonRow.Orientation = .Horizontal;
		buttonRow.Spacing = 10;

		// Bottom placement popup (context from anchor)
		let bottomPopupBtn = new Button("Popup Bottom");
		bottomPopupBtn.Click.Subscribe(new (b) => {
			let popup = new Popup();

			let content = new StackPanel();
			content.Orientation = .Vertical;
			content.Spacing = 8;
			content.Padding = .(10, 10, 10, 10);

			let label = new TextBlock("Bottom Popup");
			content.AddChild(label);

			let closeBtn = new Button("Close");
			closeBtn.Click.Subscribe(new (cb) => popup.Close());
			content.AddChild(closeBtn);

			popup.Content = content;
			popup.OpenAt(b, .Bottom);  // Gets context from anchor

			popup.Closed.Subscribe(new (p) => {
				mStatusLabel.Text = "Bottom popup closed";
				p.Content = null;
				mContext.QueueDelete(p);
			});
		});
		buttonRow.AddChild(bottomPopupBtn);

		// Top placement popup (context from anchor)
		let topPopupBtn = new Button("Popup Top");
		topPopupBtn.Click.Subscribe(new (b) => {
			let popup = new Popup();

			let content = new TextBlock("Top Popup!");
			content.Padding = .(10, 10, 10, 10);
			popup.Content = content;
			popup.OpenAt(b, .Top);  // Gets context from anchor

			popup.Closed.Subscribe(new (p) => {
				mStatusLabel.Text = "Top popup closed";
				p.Content = null;
				mContext.QueueDelete(p);
			});
		});
		buttonRow.AddChild(topPopupBtn);

		// Absolute position popup (pass context explicitly)
		let absolutePopupBtn = new Button("Popup at (100, 200)");
		absolutePopupBtn.Click.Subscribe(new (b) => {
			let popup = new Popup();

			let content = new StackPanel();
			content.Orientation = .Vertical;
			content.Spacing = 5;
			content.Padding = .(10, 10, 10, 10);

			let label = new TextBlock("Popup at absolute position");
			content.AddChild(label);

			let posLabel = new TextBlock("Position: (100, 200)");
			content.AddChild(posLabel);

			popup.Content = content;
			popup.OpenAt(mContext, 100, 200);  // Pass context for absolute position

			popup.Closed.Subscribe(new (p) => {
				mStatusLabel.Text = "Absolute popup closed";
				p.Content = null;
				mContext.QueueDelete(p);
			});
		});
		buttonRow.AddChild(absolutePopupBtn);

		// Mouse position popup (pass context explicitly)
		let mousePopupBtn = new Button("Popup at Mouse");
		mousePopupBtn.Click.Subscribe(new (b) => {
			let popup = new Popup();

			let content = new TextBlock("Popup at mouse position!");
			content.Padding = .(10, 10, 10, 10);
			popup.Content = content;
			popup.OpenAtMouse(mContext);  // Pass context for mouse position

			popup.Closed.Subscribe(new (p) => {
				mStatusLabel.Text = "Mouse popup closed";
				p.Content = null;
				mContext.QueueDelete(p);
			});
		});
		buttonRow.AddChild(mousePopupBtn);

		section.AddChild(buttonRow);

		// Second row for behavior options
		let behaviorRow = new StackPanel();
		behaviorRow.Orientation = .Horizontal;
		behaviorRow.Spacing = 10;

		// Popup that doesn't close on click outside (context from anchor)
		let stickyPopupBtn = new Button("Sticky Popup");
		stickyPopupBtn.TooltipText = "This popup only closes via the button";
		stickyPopupBtn.Click.Subscribe(new (b) => {
			let popup = new Popup();
			popup.Behavior = .CloseOnEscape;  // Only ESC closes, not click outside

			let content = new StackPanel();
			content.Orientation = .Vertical;
			content.Spacing = 8;
			content.Padding = .(10, 10, 10, 10);

			let label = new TextBlock("Sticky Popup");
			content.AddChild(label);

			let info = new TextBlock("Click outside won't close this.\nUse button or ESC key.");
			content.AddChild(info);

			let closeBtn = new Button("Close Me");
			closeBtn.Click.Subscribe(new (cb) => popup.Close());
			content.AddChild(closeBtn);

			popup.Content = content;
			popup.OpenAt(b, .Bottom);  // Gets context from anchor

			popup.Closed.Subscribe(new (p) => {
				mStatusLabel.Text = "Sticky popup closed";
				p.Content = null;
				mContext.QueueDelete(p);
			});
		});
		behaviorRow.AddChild(stickyPopupBtn);

		section.AddChild(behaviorRow);
		mRoot.AddChild(section);
	}

	private void CreateMessageBoxSection()
	{
		let section = new StackPanel();
		section.Orientation = .Vertical;
		section.Spacing = 10;
				section.Padding = .(15, 15, 15, 15);

		let header = new TextBlock("Message Boxes - Pre-built dialogs");
		header.FontSize = 16;
		section.AddChild(header);

		let buttonRow = new StackPanel();
		buttonRow.Orientation = .Horizontal;
		buttonRow.Spacing = 10;

		let infoBtn = new Button("Info");
		infoBtn.Click.Subscribe(new (b) => {
			MessageBox.Show(mContext, "This is an information message.", "Information");
		});
		buttonRow.AddChild(infoBtn);

		let warningBtn = new Button("Warning");
		warningBtn.Click.Subscribe(new (b) => {
			MessageBox.ShowWarning(mContext, "This is a warning message. Something might need attention.", "Warning");
		});
		buttonRow.AddChild(warningBtn);

		let errorBtn = new Button("Error");
		errorBtn.Click.Subscribe(new (b) => {
			MessageBox.ShowError(mContext, "An error has occurred. Please try again.", "Error");
		});
		buttonRow.AddChild(errorBtn);

		let questionBtn = new Button("Question");
		questionBtn.Click.Subscribe(new (b) => {
			let dialog = MessageBox.ShowQuestion(mContext, "Do you want to save changes before closing?", "Confirm Save");
			dialog.Closed.Subscribe(new (d, result) => {
				mStatusLabel.Text = scope $"Question result: {result}";
				mContext.QueueDelete(d);
			});
		});
		buttonRow.AddChild(questionBtn);

		let confirmBtn = new Button("Confirm");
		confirmBtn.Click.Subscribe(new (b) => {
			let dialog = MessageBox.ShowConfirm(mContext, "Are you sure you want to proceed?", "Confirm Action");
			dialog.Closed.Subscribe(new (d, result) => {
				mStatusLabel.Text = scope $"Confirm result: {result}";
				mContext.QueueDelete(d);
			});
		});
		buttonRow.AddChild(confirmBtn);

		section.AddChild(buttonRow);
		mRoot.AddChild(section);
	}
}
