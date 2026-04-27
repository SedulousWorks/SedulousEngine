namespace GUISandbox;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.GUI;

/// Demo 15: Menu & Toolbar System
/// Shows menu bar, toolbar, and status bar components.
class MenuToolbarDemo
{
	private DockPanel mRoot /*~ delete _*/;
	private TextBlock mStatusLabel /*~ delete _*/;
	private GUIContext mContext;

	// Track document state for demo
	private bool mIsBold = false;
	private bool mIsItalic = false;
	private String mCurrentFile = new .("Untitled") ~ delete _;

	public UIElement CreateDemo(GUIContext context)
	{
		mContext = context;

		mRoot = new DockPanel();
		mRoot.Padding = .(0, 70, 0, 0);  // Top padding for overlay text

		// Create menu bar at top
		let menuBar = CreateMenuBar();
		DockPanelProperties.SetDock(menuBar, .Top);
		mRoot.AddChild(menuBar);

		// Create toolbar below menu bar
		let toolbar = CreateToolBar();
		DockPanelProperties.SetDock(toolbar, .Top);
		mRoot.AddChild(toolbar);

		// Create status bar at bottom
		let statusBar = CreateStatusBar();
		DockPanelProperties.SetDock(statusBar, .Bottom);
		mRoot.AddChild(statusBar);

		// Create content area
		let content = CreateContentArea();
		mRoot.AddChild(content);

		return mRoot;
	}

	private Menu CreateMenuBar()
	{
		let menuBar = new Menu();
		menuBar.Padding = .(4, 2, 4, 2);

		// File menu
		let fileMenu = menuBar.AddItem("&File");
		let newItem = fileMenu.AddDropdownItem("&New");
		newItem.ShortcutText = "Ctrl+N";
		newItem.Click.Subscribe(new (mi) => UpdateStatus("New file created"));

		let openItem = fileMenu.AddDropdownItem("&Open...");
		openItem.ShortcutText = "Ctrl+O";
		openItem.Click.Subscribe(new (mi) => UpdateStatus("Open dialog (simulated)"));

		let saveItem = fileMenu.AddDropdownItem("&Save");
		saveItem.ShortcutText = "Ctrl+S";
		saveItem.Click.Subscribe(new (mi) => UpdateStatus("File saved"));

		let saveAsItem = fileMenu.AddDropdownItem("Save &As...");
		saveAsItem.ShortcutText = "Ctrl+Shift+S";
		saveAsItem.Click.Subscribe(new (mi) => UpdateStatus("Save As dialog (simulated)"));

		fileMenu.AddDropdownSeparator();

		let exitItem = fileMenu.AddDropdownItem("E&xit");
		exitItem.ShortcutText = "Alt+F4";
		exitItem.Click.Subscribe(new (mi) => UpdateStatus("Exit requested"));

		// Edit menu
		let editMenu = menuBar.AddItem("&Edit");
		let undoItem = editMenu.AddDropdownItem("&Undo");
		undoItem.ShortcutText = "Ctrl+Z";
		undoItem.Click.Subscribe(new (mi) => UpdateStatus("Undo"));

		let redoItem = editMenu.AddDropdownItem("&Redo");
		redoItem.ShortcutText = "Ctrl+Y";
		redoItem.Click.Subscribe(new (mi) => UpdateStatus("Redo"));

		editMenu.AddDropdownSeparator();

		let cutItem = editMenu.AddDropdownItem("Cu&t");
		cutItem.ShortcutText = "Ctrl+X";
		cutItem.Click.Subscribe(new (mi) => UpdateStatus("Cut to clipboard"));

		let copyItem = editMenu.AddDropdownItem("&Copy");
		copyItem.ShortcutText = "Ctrl+C";
		copyItem.Click.Subscribe(new (mi) => UpdateStatus("Copied to clipboard"));

		let pasteItem = editMenu.AddDropdownItem("&Paste");
		pasteItem.ShortcutText = "Ctrl+V";
		pasteItem.Click.Subscribe(new (mi) => UpdateStatus("Pasted from clipboard"));

		editMenu.AddDropdownSeparator();

		let selectAllItem = editMenu.AddDropdownItem("Select &All");
		selectAllItem.ShortcutText = "Ctrl+A";
		selectAllItem.Click.Subscribe(new (mi) => UpdateStatus("Select All"));

		// View menu
		let viewMenu = menuBar.AddItem("&View");

		let showToolbar = viewMenu.AddDropdownItem("&Toolbar");
		showToolbar.IsCheckable = true;
		showToolbar.IsChecked = true;
		showToolbar.Click.Subscribe(new (mi) => {
			UpdateStatus(scope $"Toolbar: {(mi.IsChecked ? "Visible" : "Hidden")}");
		});

		let showStatusBar = viewMenu.AddDropdownItem("&Status Bar");
		showStatusBar.IsCheckable = true;
		showStatusBar.IsChecked = true;
		showStatusBar.Click.Subscribe(new (mi) => {
			UpdateStatus(scope $"Status Bar: {(mi.IsChecked ? "Visible" : "Hidden")}");
		});

		viewMenu.AddDropdownSeparator();

		let zoomInItem = viewMenu.AddDropdownItem("Zoom &In");
		zoomInItem.ShortcutText = "Ctrl++";
		zoomInItem.Click.Subscribe(new (mi) => UpdateStatus("Zoom In"));

		let zoomOutItem = viewMenu.AddDropdownItem("Zoom &Out");
		zoomOutItem.ShortcutText = "Ctrl+-";
		zoomOutItem.Click.Subscribe(new (mi) => UpdateStatus("Zoom Out"));

		// Help menu
		let helpMenu = menuBar.AddItem("&Help");
		let aboutItem = helpMenu.AddDropdownItem("&About");
		aboutItem.Click.Subscribe(new (mi) => UpdateStatus("About: Sedulous.GUI Menu Demo"));

		return menuBar;
	}

	private ToolBar CreateToolBar()
	{
		let toolbar = new ToolBar();
		toolbar.Padding = .(4, 4, 4, 4);

		// File operations
		let newBtn = toolbar.AddButton("New");
		newBtn.TooltipText = "Create new file (Ctrl+N)";
		newBtn.Click.Subscribe(new (btn) => UpdateStatus("New file created"));

		let openBtn = toolbar.AddButton("Open");
		openBtn.TooltipText = "Open file (Ctrl+O)";
		openBtn.Click.Subscribe(new (btn) => UpdateStatus("Open dialog (simulated)"));

		let saveBtn = toolbar.AddButton("Save");
		saveBtn.TooltipText = "Save file (Ctrl+S)";
		saveBtn.Click.Subscribe(new (btn) => UpdateStatus("File saved"));

		toolbar.AddSeparator();

		// Edit operations
		let cutBtn = toolbar.AddButton("Cut");
		cutBtn.TooltipText = "Cut (Ctrl+X)";
		cutBtn.Click.Subscribe(new (btn) => UpdateStatus("Cut to clipboard"));

		let copyBtn = toolbar.AddButton("Copy");
		copyBtn.TooltipText = "Copy (Ctrl+C)";
		copyBtn.Click.Subscribe(new (btn) => UpdateStatus("Copied to clipboard"));

		let pasteBtn = toolbar.AddButton("Paste");
		pasteBtn.TooltipText = "Paste (Ctrl+V)";
		pasteBtn.Click.Subscribe(new (btn) => UpdateStatus("Pasted from clipboard"));

		toolbar.AddSeparator();

		// Formatting toggles
		let boldBtn = toolbar.AddToggleButton("B");
		boldBtn.TooltipText = "Bold (Ctrl+B)";
		boldBtn.Click.Subscribe(new (btn) => {
			mIsBold = !mIsBold;
			UpdateStatus(scope $"Bold: {(mIsBold ? "ON" : "OFF")}");
		});

		let italicBtn = toolbar.AddToggleButton("I");
		italicBtn.TooltipText = "Italic (Ctrl+I)";
		italicBtn.Click.Subscribe(new (btn) => {
			mIsItalic = !mIsItalic;
			UpdateStatus(scope $"Italic: {(mIsItalic ? "ON" : "OFF")}");
		});

		let underlineBtn = toolbar.AddToggleButton("U");
		underlineBtn.TooltipText = "Underline (Ctrl+U)";
		underlineBtn.Click.Subscribe(new (btn) => UpdateStatus("Underline toggled"));

		toolbar.AddSeparator();

		// Alignment buttons
		let alignLeftBtn = toolbar.AddButton("Left");
		alignLeftBtn.TooltipText = "Align Left";
		alignLeftBtn.Click.Subscribe(new (btn) => UpdateStatus("Aligned left"));

		let alignCenterBtn = toolbar.AddButton("Center");
		alignCenterBtn.TooltipText = "Align Center";
		alignCenterBtn.Click.Subscribe(new (btn) => UpdateStatus("Aligned center"));

		let alignRightBtn = toolbar.AddButton("Right");
		alignRightBtn.TooltipText = "Align Right";
		alignRightBtn.Click.Subscribe(new (btn) => UpdateStatus("Aligned right"));

		return toolbar;
	}

	private StatusBar CreateStatusBar()
	{
		let statusBar = new StatusBar();
		statusBar.Padding = .(8, 4, 8, 4);

		// Main status message (flexible)
		let statusItem = statusBar.AddFlexibleItem("Ready");
		mStatusLabel = statusItem.[Friend]mTextBlock;

		// Line/column indicator (fixed width)
		let lineColItem = statusBar.AddFixedItem("Line 1, Col 1", 120);
		lineColItem.IsClickable = true;
		lineColItem.Click.Subscribe(new (item) => UpdateStatus("Go to line dialog (simulated)"));

		// Encoding indicator
		let encodingItem = statusBar.AddFixedItem("UTF-8", 60);
		encodingItem.IsClickable = true;
		encodingItem.Click.Subscribe(new (item) => UpdateStatus("Select encoding (simulated)"));

		return statusBar;
	}

	private UIElement CreateContentArea()
	{
		let panel = new StackPanel();
		panel.Orientation = .Vertical;
		panel.Spacing = 20;
		panel.Padding = .(30, 30, 30, 30);
		panel.HorizontalAlignment = .Stretch;
		panel.VerticalAlignment = .Stretch;

		// Title
		let title = new TextBlock("Menu & Toolbar Demo");
		title.FontSize = 24;
		panel.AddChild(title);

		// Description
		let desc = new TextBlock("This demo showcases the Menu, ToolBar, and StatusBar controls.");
		panel.AddChild(desc);

		// Instructions panel
		let instructions = new StackPanel();
		instructions.Orientation = .Vertical;
		instructions.Spacing = 8;
		instructions.Padding = .(15, 15, 15, 15);

		let instructionsTitle = new TextBlock("Instructions:");
		instructionsTitle.FontSize = 16;
		instructions.AddChild(instructionsTitle);

		AddInstruction(instructions, "- Click menu items (File, Edit, View, Help) to open dropdown menus");
		AddInstruction(instructions, "- Use Alt+F, Alt+E, Alt+V, Alt+H to access menus via keyboard");
		AddInstruction(instructions, "- Arrow keys navigate within menus when open");
		AddInstruction(instructions, "- Toolbar buttons show tooltips on hover");
		AddInstruction(instructions, "- Toggle buttons (B, I, U) maintain checked state");
		AddInstruction(instructions, "- Resize window to see toolbar overflow handling");
		AddInstruction(instructions, "- Click status bar items (Line/Col, Encoding) for actions");
		AddInstruction(instructions, "- ESC closes open menus");

		panel.AddChild(instructions);

		// Feature list
		let features = new StackPanel();
		features.Orientation = .Vertical;
		features.Spacing = 6;
		features.Padding = .(10, 10, 10, 10);

		let featuresTitle = new TextBlock("Controls demonstrated:");
		featuresTitle.FontSize = 14;
		featuresTitle.Foreground = Color(100, 160, 220, 255);  // Keep accent color for title
		features.AddChild(featuresTitle);

		AddFeature(features, "Menu - Horizontal menu bar with Alt-key accelerators");
		AddFeature(features, "MenuBarItem - Top-level menu items with dropdown");
		AddFeature(features, "ToolBar - Toolbar with buttons and overflow");
		AddFeature(features, "ToolBarButton - Flat-styled toolbar button");
		AddFeature(features, "ToolBarToggleButton - Toggle button with checked state");
		AddFeature(features, "ToolBarSeparator - Visual separator");
		AddFeature(features, "StatusBar - Status bar with segments");
		AddFeature(features, "StatusBarItem - Fixed and flexible segments");

		panel.AddChild(features);

		return panel;
	}

	private void AddInstruction(StackPanel parent, StringView text)
	{
		let label = new TextBlock(text);
		parent.AddChild(label);
	}

	private void AddFeature(StackPanel parent, StringView text)
	{
		let label = new TextBlock(text);
		label.FontSize = 12;
		parent.AddChild(label);
	}

	private void UpdateStatus(StringView message)
	{
		if (mStatusLabel != null)
		{
			// Get the StatusBarItem that contains the TextBlock
			if (let statusItem = mStatusLabel.Parent as StatusBarItem)
				statusItem.Text = message;
		}
	}
}
