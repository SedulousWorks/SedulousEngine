using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI.Tests;

/// Tests for Phase 13: Menu & Toolbar
class Phase13Tests
{
	// === Menu Tests ===

	[Test]
	public static void MenuDefaultProperties()
	{
		let menu = scope Menu();
		Test.Assert(menu.ItemCount == 0);
		Test.Assert(menu.IsAltModeActive == false);
		Test.Assert(menu.IsFocusable == true);
	}

	[Test]
	public static void MenuAddItem()
	{
		let menu = scope Menu();
		let item = menu.AddItem("&File");
		Test.Assert(menu.ItemCount == 1);
		Test.Assert(item != null);
		Test.Assert(item.Text == "&File");
	}

	[Test]
	public static void MenuAddMultipleItems()
	{
		let menu = scope Menu();
		menu.AddItem("&File");
		menu.AddItem("&Edit");
		menu.AddItem("&View");
		Test.Assert(menu.ItemCount == 3);
	}

	[Test]
	public static void MenuGetItem()
	{
		let menu = scope Menu();
		let file = menu.AddItem("&File");
		let edit = menu.AddItem("&Edit");
		Test.Assert(menu.GetItem(0) == file);
		Test.Assert(menu.GetItem(1) == edit);
		Test.Assert(menu.GetItem(2) == null);
		Test.Assert(menu.GetItem(-1) == null);
	}

	[Test]
	public static void MenuAltModeActivation()
	{
		let menu = scope Menu();
		menu.AddItem("&File");
		Test.Assert(menu.IsAltModeActive == false);
		menu.ActivateAltMode();
		Test.Assert(menu.IsAltModeActive == true);
		menu.DeactivateAltMode();
		Test.Assert(menu.IsAltModeActive == false);
	}

	// === MenuBarItem Tests ===

	[Test]
	public static void MenuBarItemDefaultProperties()
	{
		let item = scope MenuBarItem();
		Test.Assert(item.Text == "");
		Test.Assert(item.AcceleratorKey == '\0');
		Test.Assert(item.IsSelected == false);
		Test.Assert(item.IsDropdownOpen == false);
		Test.Assert(item.IsFocusable == false);
	}

	[Test]
	public static void MenuBarItemWithText()
	{
		let item = scope MenuBarItem("File");
		Test.Assert(item.Text == "File");
	}

	[Test]
	public static void MenuBarItemAcceleratorKey()
	{
		let item = scope MenuBarItem("&File");
		Test.Assert(item.AcceleratorKey == 'F');
	}

	[Test]
	public static void MenuBarItemAcceleratorKeyMiddle()
	{
		let item = scope MenuBarItem("E&dit");
		Test.Assert(item.AcceleratorKey == 'D');
	}

	[Test]
	public static void MenuBarItemEscapedAmpersand()
	{
		let item = scope MenuBarItem("Tom && Jerry");
		Test.Assert(item.AcceleratorKey == '\0'); // No accelerator when escaped
	}

	[Test]
	public static void MenuBarItemAddDropdownItem()
	{
		let item = scope MenuBarItem("&File");
		let newItem = item.AddDropdownItem("&New");
		Test.Assert(newItem != null);
		Test.Assert(item.DropdownMenu.ItemCount == 1);
	}

	[Test]
	public static void MenuBarItemAddDropdownSeparator()
	{
		let item = scope MenuBarItem("&File");
		item.AddDropdownItem("&New");
		item.AddDropdownSeparator();
		item.AddDropdownItem("&Exit");
		Test.Assert(item.DropdownMenu.ItemCount == 3);
	}

	[Test]
	public static void MenuBarItemClearDropdownItems()
	{
		let item = scope MenuBarItem("&File");
		item.AddDropdownItem("&New");
		item.AddDropdownItem("&Open");
		Test.Assert(item.DropdownMenu.ItemCount == 2);
		item.ClearDropdownItems();
		Test.Assert(item.DropdownMenu.ItemCount == 0);
	}

	// === ToolBar Tests ===

	[Test]
	public static void ToolBarDefaultProperties()
	{
		let toolbar = scope ToolBar();
		Test.Assert(toolbar.ItemCount == 0);
		Test.Assert(toolbar.Orientation == .Horizontal);
		Test.Assert(toolbar.ShowOverflowButton == true);
		Test.Assert(toolbar.IsFocusable == false);
	}

	[Test]
	public static void ToolBarAddButton()
	{
		let toolbar = scope ToolBar();
		let btn = toolbar.AddButton("Save");
		Test.Assert(toolbar.ItemCount == 1);
		Test.Assert(btn != null);
		Test.Assert(btn.Text == "Save");
	}

	[Test]
	public static void ToolBarAddToggleButton()
	{
		let toolbar = scope ToolBar();
		let toggle = toolbar.AddToggleButton("Bold");
		Test.Assert(toolbar.ItemCount == 1);
		Test.Assert(toggle != null);
		Test.Assert(toggle.Text == "Bold");
		Test.Assert(toggle.IsChecked == false);
	}

	[Test]
	public static void ToolBarAddSeparator()
	{
		let toolbar = scope ToolBar();
		let sep = toolbar.AddSeparator();
		Test.Assert(toolbar.ItemCount == 1);
		Test.Assert(sep != null);
	}

	[Test]
	public static void ToolBarGetItem()
	{
		let toolbar = scope ToolBar();
		let btn1 = toolbar.AddButton("New");
		let btn2 = toolbar.AddButton("Open");
		Test.Assert(toolbar.GetItem(0) == btn1);
		Test.Assert(toolbar.GetItem(1) == btn2);
		Test.Assert(toolbar.GetItem(2) == null);
	}

	[Test]
	public static void ToolBarOrientationChange()
	{
		let toolbar = scope ToolBar();
		toolbar.AddSeparator();
		toolbar.Orientation = .Vertical;
		Test.Assert(toolbar.Orientation == .Vertical);
	}

	[Test]
	public static void ToolBarClearItems()
	{
		let toolbar = scope ToolBar();
		toolbar.AddButton("New");
		toolbar.AddButton("Open");
		toolbar.AddSeparator();
		Test.Assert(toolbar.ItemCount == 3);
		toolbar.ClearItems();
		Test.Assert(toolbar.ItemCount == 0);
	}

	// === ToolBarButton Tests ===

	[Test]
	public static void ToolBarButtonDefaultProperties()
	{
		let btn = scope ToolBarButton();
		Test.Assert(btn.DisplayMode == .TextOnly);
		Test.Assert(btn.Text == "");
	}

	[Test]
	public static void ToolBarButtonWithText()
	{
		let btn = scope ToolBarButton("Save");
		Test.Assert(btn.Text == "Save");
	}

	[Test]
	public static void ToolBarButtonDisplayMode()
	{
		let btn = scope ToolBarButton("Save");
		btn.DisplayMode = .IconAndText;
		Test.Assert(btn.DisplayMode == .IconAndText);
	}

	// === ToolBarToggleButton Tests ===

	[Test]
	public static void ToolBarToggleButtonDefaultProperties()
	{
		let toggle = scope ToolBarToggleButton();
		Test.Assert(toggle.IsChecked == false);
		Test.Assert(toggle.DisplayMode == .TextOnly);
		Test.Assert(toggle.Text == "");
	}

	[Test]
	public static void ToolBarToggleButtonWithText()
	{
		let toggle = scope ToolBarToggleButton("Bold");
		Test.Assert(toggle.Text == "Bold");
	}

	[Test]
	public static void ToolBarToggleButtonCheckedState()
	{
		let toggle = scope ToolBarToggleButton("Bold");
		Test.Assert(toggle.IsChecked == false);
		toggle.IsChecked = true;
		Test.Assert(toggle.IsChecked == true);
	}

	// === ToolBarSeparator Tests ===

	[Test]
	public static void ToolBarSeparatorDefaultProperties()
	{
		let sep = scope ToolBarSeparator();
		Test.Assert(sep.Orientation == .Vertical);
		Test.Assert(sep.Thickness == 1);
		Test.Assert(sep.LineMargin == 4);
		Test.Assert(sep.IsFocusable == false);
	}

	[Test]
	public static void ToolBarSeparatorOrientation()
	{
		let sep = scope ToolBarSeparator();
		sep.Orientation = .Horizontal;
		Test.Assert(sep.Orientation == .Horizontal);
	}

	[Test]
	public static void ToolBarSeparatorThickness()
	{
		let sep = scope ToolBarSeparator();
		sep.Thickness = 2;
		Test.Assert(sep.Thickness == 2);
	}

	// === StatusBar Tests ===

	[Test]
	public static void StatusBarDefaultProperties()
	{
		let statusBar = scope StatusBar();
		Test.Assert(statusBar.ItemCount == 0);
		Test.Assert(statusBar.ShowSeparators == true);
		Test.Assert(statusBar.IsFocusable == false);
	}

	[Test]
	public static void StatusBarAddItem()
	{
		let statusBar = scope StatusBar();
		let item = statusBar.AddItem("Ready");
		Test.Assert(statusBar.ItemCount == 1);
		Test.Assert(item != null);
		Test.Assert(item.Text == "Ready");
	}

	[Test]
	public static void StatusBarAddFlexibleItem()
	{
		let statusBar = scope StatusBar();
		let item = statusBar.AddFlexibleItem("Status Message");
		Test.Assert(statusBar.ItemCount == 1);
		Test.Assert(item.IsFlexible == true);
	}

	[Test]
	public static void StatusBarAddFixedItem()
	{
		let statusBar = scope StatusBar();
		let item = statusBar.AddFixedItem("Line 1", 100);
		Test.Assert(statusBar.ItemCount == 1);
		Test.Assert(item.MinWidth == 100);
		Test.Assert(item.MaxWidth == 100);
	}

	[Test]
	public static void StatusBarGetItem()
	{
		let statusBar = scope StatusBar();
		let item1 = statusBar.AddItem("Item 1");
		let item2 = statusBar.AddItem("Item 2");
		Test.Assert(statusBar.GetItem(0) == item1);
		Test.Assert(statusBar.GetItem(1) == item2);
		Test.Assert(statusBar.GetItem(2) == null);
	}

	[Test]
	public static void StatusBarClearItems()
	{
		let statusBar = scope StatusBar();
		statusBar.AddItem("Item 1");
		statusBar.AddItem("Item 2");
		Test.Assert(statusBar.ItemCount == 2);
		statusBar.ClearItems();
		Test.Assert(statusBar.ItemCount == 0);
	}

	[Test]
	public static void StatusBarSeparatorToggle()
	{
		let statusBar = scope StatusBar();
		Test.Assert(statusBar.ShowSeparators == true);
		statusBar.ShowSeparators = false;
		Test.Assert(statusBar.ShowSeparators == false);
	}

	// === StatusBarItem Tests ===

	[Test]
	public static void StatusBarItemDefaultProperties()
	{
		let item = scope StatusBarItem();
		Test.Assert(item.Text == "");
		Test.Assert(item.IsClickable == false);
		Test.Assert(item.IsFlexible == false);
		Test.Assert(item.IsFocusable == false);
	}

	[Test]
	public static void StatusBarItemWithText()
	{
		let item = scope StatusBarItem("Ready");
		Test.Assert(item.Text == "Ready");
	}

	[Test]
	public static void StatusBarItemSetText()
	{
		let item = scope StatusBarItem();
		item.Text = "Processing...";
		Test.Assert(item.Text == "Processing...");
	}

	[Test]
	public static void StatusBarItemClickable()
	{
		let item = scope StatusBarItem("Click Me");
		item.IsClickable = true;
		Test.Assert(item.IsClickable == true);
	}

	[Test]
	public static void StatusBarItemFlexible()
	{
		let item = scope StatusBarItem("Flexible");
		item.IsFlexible = true;
		Test.Assert(item.IsFlexible == true);
	}

	[Test]
	public static void StatusBarItemMinMaxWidth()
	{
		let item = scope StatusBarItem("Fixed");
		item.MinWidth = 50;
		item.MaxWidth = 150;
		Test.Assert(item.MinWidth == 50);
		Test.Assert(item.MaxWidth == 150);
	}
}
