using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI.Tests;

/// Phase 9 tests: list controls (ItemsControl, ListBox, ComboBox).
class Phase9Tests
{
	/// Test panel for container tests.
	class TestPanel : Panel
	{
	}

	// ========== SelectionMode Enum Tests ==========

	[Test]
	public static void SelectionMode_AllValuesExist()
	{
		SelectionMode mode;

		mode = .Single;
		Test.Assert(mode == .Single, "Single should exist");

		mode = .Multiple;
		Test.Assert(mode == .Multiple, "Multiple should exist");

		mode = .Extended;
		Test.Assert(mode == .Extended, "Extended should exist");
	}

	// ========== ItemsControl Tests ==========

	[Test]
	public static void ItemsControl_DefaultProperties()
	{
		let itemsControl = scope ItemsControl();

		Test.Assert(itemsControl.ItemCount == 0, "Default ItemCount should be 0");
		Test.Assert(itemsControl.ItemTemplate == null, "Default ItemTemplate should be null");
	}

	[Test]
	public static void ItemsControl_AddItem()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let itemsControl = new ItemsControl();
		panel.AddChild(itemsControl);

		let item1 = new String("Item 1");
		let item2 = new String("Item 2");
		defer { delete item1; delete item2; }

		itemsControl.AddItem(item1);
		Test.Assert(itemsControl.ItemCount == 1, "ItemCount should be 1 after adding item");
		Test.Assert(itemsControl.GetItem(0) == item1, "GetItem(0) should return the added item");

		itemsControl.AddItem(item2);
		Test.Assert(itemsControl.ItemCount == 2, "ItemCount should be 2 after adding second item");
		Test.Assert(itemsControl.GetItem(1) == item2, "GetItem(1) should return the second item");

		itemsControl.ClearItems();
		ctx.Update(0, 0);
		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ItemsControl_InsertItem()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let itemsControl = new ItemsControl();
		panel.AddChild(itemsControl);

		let item1 = new String("First");
		let item2 = new String("Second");
		let item3 = new String("Middle");
		defer { delete item1; delete item2; delete item3; }

		itemsControl.AddItem(item1);
		itemsControl.AddItem(item2);
		itemsControl.InsertItem(1, item3);

		Test.Assert(itemsControl.ItemCount == 3, "ItemCount should be 3");
		Test.Assert(itemsControl.GetItem(0) == item1, "First item unchanged");
		Test.Assert(itemsControl.GetItem(1) == item3, "Inserted item at index 1");
		Test.Assert(itemsControl.GetItem(2) == item2, "Second item shifted to index 2");

		itemsControl.ClearItems();
		ctx.Update(0, 0);
		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ItemsControl_RemoveItem()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let itemsControl = new ItemsControl();
		panel.AddChild(itemsControl);

		let item1 = new String("Item 1");
		let item2 = new String("Item 2");
		defer { delete item1; delete item2; }

		itemsControl.AddItem(item1);
		itemsControl.AddItem(item2);

		let removed = itemsControl.RemoveItem(item1);
		ctx.Update(0, 0);  // Process mutation queue

		Test.Assert(removed, "RemoveItem should return true for existing item");
		Test.Assert(itemsControl.ItemCount == 1, "ItemCount should be 1 after removal");
		Test.Assert(itemsControl.GetItem(0) == item2, "Remaining item should be item2");

		itemsControl.ClearItems();
		ctx.Update(0, 0);
		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ItemsControl_RemoveItemAt()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let itemsControl = new ItemsControl();
		panel.AddChild(itemsControl);

		let item1 = new String("Item 1");
		let item2 = new String("Item 2");
		let item3 = new String("Item 3");
		defer { delete item1; delete item2; delete item3; }

		itemsControl.AddItem(item1);
		itemsControl.AddItem(item2);
		itemsControl.AddItem(item3);

		itemsControl.RemoveItemAt(1);
		ctx.Update(0, 0);  // Process mutation queue

		Test.Assert(itemsControl.ItemCount == 2, "ItemCount should be 2 after removal");
		Test.Assert(itemsControl.GetItem(0) == item1, "First item unchanged");
		Test.Assert(itemsControl.GetItem(1) == item3, "Third item shifted to index 1");

		itemsControl.ClearItems();
		ctx.Update(0, 0);
		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ItemsControl_ClearItems()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let itemsControl = new ItemsControl();
		panel.AddChild(itemsControl);

		let item1 = new String("Item 1");
		let item2 = new String("Item 2");
		defer { delete item1; delete item2; }

		itemsControl.AddItem(item1);
		itemsControl.AddItem(item2);
		itemsControl.ClearItems();
		ctx.Update(0, 0);  // Process mutation queue

		Test.Assert(itemsControl.ItemCount == 0, "ItemCount should be 0 after clear");
		Test.Assert(itemsControl.GetItem(0) == null, "GetItem should return null after clear");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ItemsControl_IndexOf()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let itemsControl = new ItemsControl();
		panel.AddChild(itemsControl);

		let item1 = new String("Item 1");
		let item2 = new String("Item 2");
		let notAdded = new String("Not Added");
		defer { delete item1; delete item2; delete notAdded; }

		itemsControl.AddItem(item1);
		itemsControl.AddItem(item2);

		Test.Assert(itemsControl.IndexOf(item1) == 0, "IndexOf item1 should be 0");
		Test.Assert(itemsControl.IndexOf(item2) == 1, "IndexOf item2 should be 1");
		Test.Assert(itemsControl.IndexOf(notAdded) == -1, "IndexOf non-existing should be -1");

		itemsControl.ClearItems();
		ctx.Update(0, 0);
		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ItemsControl_GetContainer()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let itemsControl = new ItemsControl();
		panel.AddChild(itemsControl);

		let item1 = new String("Item 1");
		defer delete item1;
		itemsControl.AddItem(item1);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		let container = itemsControl.GetContainer(0);
		Test.Assert(container != null, "Container should be created for item");
		Test.Assert(container is ListBoxItem, "Default container should be ListBoxItem");

		itemsControl.ClearItems();
		ctx.Update(0, 0);
		ctx.RootElement = null;
		delete panel;
	}

	// ========== ListBox Tests ==========

	[Test]
	public static void ListBox_DefaultProperties()
	{
		let listBox = scope ListBox();

		Test.Assert(listBox.SelectionMode == .Single, "Default SelectionMode should be Single");
		Test.Assert(listBox.SelectedIndex == -1, "Default SelectedIndex should be -1");
		Test.Assert(listBox.SelectedItem == null, "Default SelectedItem should be null");
		Test.Assert(listBox.SelectedCount == 0, "Default SelectedCount should be 0");
	}

	[Test]
	public static void ListBox_SingleSelection_SelectedIndex()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let listBox = new ListBox();
		panel.AddChild(listBox);

		let item1 = new String("Apple");
		let item2 = new String("Banana");
		let item3 = new String("Cherry");
		defer { delete item1; delete item2; delete item3; }

		listBox.AddItem(item1);
		listBox.AddItem(item2);
		listBox.AddItem(item3);

		listBox.SelectedIndex = 1;
		Test.Assert(listBox.SelectedIndex == 1, "SelectedIndex should be 1");
		Test.Assert(listBox.SelectedItem == item2, "SelectedItem should be item2");
		Test.Assert(listBox.SelectedCount == 1, "SelectedCount should be 1");

		listBox.ClearItems();
		ctx.Update(0, 0);
		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ListBox_SingleSelection_ReplaceSelection()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let listBox = new ListBox();
		panel.AddChild(listBox);

		let item1 = new String("First");
		let item2 = new String("Second");
		defer { delete item1; delete item2; }

		listBox.AddItem(item1);
		listBox.AddItem(item2);

		listBox.SelectedIndex = 0;
		Test.Assert(listBox.SelectedIndex == 0, "Initial selection should be 0");

		listBox.SelectedIndex = 1;
		Test.Assert(listBox.SelectedIndex == 1, "Selection should change to 1");
		Test.Assert(listBox.SelectedCount == 1, "Only one item should be selected");

		listBox.ClearItems();
		ctx.Update(0, 0);
		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ListBox_SingleSelection_InvalidIndex()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let listBox = new ListBox();
		panel.AddChild(listBox);

		let item1 = new String("Item");
		defer delete item1;

		listBox.AddItem(item1);
		listBox.SelectedIndex = 0;

		listBox.SelectedIndex = 10;  // Invalid
		Test.Assert(listBox.SelectedIndex == -1, "Invalid index should clear selection");

		listBox.SelectedIndex = -5;  // Invalid
		Test.Assert(listBox.SelectedIndex == -1, "Negative index should clear selection");

		listBox.ClearItems();
		ctx.Update(0, 0);
		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ListBox_SelectAll_SingleMode()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let listBox = new ListBox();
		listBox.SelectionMode = .Single;
		panel.AddChild(listBox);

		let item1 = new String("Item 1");
		let item2 = new String("Item 2");
		defer { delete item1; delete item2; }

		listBox.AddItem(item1);
		listBox.AddItem(item2);

		listBox.SelectAll();  // Should be ignored in Single mode
		Test.Assert(listBox.SelectedCount == 0, "SelectAll should do nothing in Single mode");

		listBox.ClearItems();
		ctx.Update(0, 0);
		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ListBox_ExtendedSelection_SelectAll()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let listBox = new ListBox();
		listBox.SelectionMode = .Extended;
		panel.AddChild(listBox);

		let item1 = new String("Item 1");
		let item2 = new String("Item 2");
		let item3 = new String("Item 3");
		defer { delete item1; delete item2; delete item3; }

		listBox.AddItem(item1);
		listBox.AddItem(item2);
		listBox.AddItem(item3);

		listBox.SelectAll();
		Test.Assert(listBox.SelectedCount == 3, "SelectAll should select all items in Extended mode");
		Test.Assert(listBox.IsItemSelected(0), "Item 0 should be selected");
		Test.Assert(listBox.IsItemSelected(1), "Item 1 should be selected");
		Test.Assert(listBox.IsItemSelected(2), "Item 2 should be selected");

		listBox.ClearItems();
		ctx.Update(0, 0);
		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ListBox_ExtendedSelection_SelectRange()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let listBox = new ListBox();
		listBox.SelectionMode = .Extended;
		panel.AddChild(listBox);

		let item1 = new String("A");
		let item2 = new String("B");
		let item3 = new String("C");
		let item4 = new String("D");
		defer { delete item1; delete item2; delete item3; delete item4; }

		listBox.AddItem(item1);
		listBox.AddItem(item2);
		listBox.AddItem(item3);
		listBox.AddItem(item4);

		listBox.SelectRange(1, 3);
		Test.Assert(listBox.SelectedCount == 3, "SelectRange should select 3 items");
		Test.Assert(!listBox.IsItemSelected(0), "Item 0 should not be selected");
		Test.Assert(listBox.IsItemSelected(1), "Item 1 should be selected");
		Test.Assert(listBox.IsItemSelected(2), "Item 2 should be selected");
		Test.Assert(listBox.IsItemSelected(3), "Item 3 should be selected");

		listBox.ClearItems();
		ctx.Update(0, 0);
		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ListBox_ToggleSelection()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let listBox = new ListBox();
		listBox.SelectionMode = .Multiple;
		panel.AddChild(listBox);

		let item1 = new String("Item");
		defer delete item1;

		listBox.AddItem(item1);

		listBox.ToggleSelection(0);
		Test.Assert(listBox.IsItemSelected(0), "Item should be selected after toggle");

		listBox.ToggleSelection(0);
		Test.Assert(!listBox.IsItemSelected(0), "Item should be deselected after second toggle");

		listBox.ClearItems();
		ctx.Update(0, 0);
		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ListBox_ClearSelection()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let listBox = new ListBox();
		listBox.SelectionMode = .Extended;
		panel.AddChild(listBox);

		let item1 = new String("A");
		let item2 = new String("B");
		defer { delete item1; delete item2; }

		listBox.AddItem(item1);
		listBox.AddItem(item2);
		listBox.SelectAll();

		Test.Assert(listBox.SelectedCount == 2, "Both items should be selected");

		listBox.ClearSelection();
		Test.Assert(listBox.SelectedCount == 0, "Selection should be cleared");
		Test.Assert(!listBox.IsItemSelected(0), "Item 0 should not be selected");
		Test.Assert(!listBox.IsItemSelected(1), "Item 1 should not be selected");

		listBox.ClearItems();
		ctx.Update(0, 0);
		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ListBox_SelectionChangedEvent()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let listBox = new ListBox();
		panel.AddChild(listBox);

		let item1 = new String("Item 1");
		defer delete item1;
		listBox.AddItem(item1);

		bool eventFired = false;
		listBox.SelectionChanged.Subscribe(new [&](lb) => { eventFired = true; });

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		listBox.SelectedIndex = 0;
		Test.Assert(eventFired, "SelectionChanged event should fire");

		listBox.ClearItems();
		ctx.Update(0, 0);
		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ListBox_SelectionModeChange_ClearsSelection()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let listBox = new ListBox();
		listBox.SelectionMode = .Extended;
		panel.AddChild(listBox);

		let item1 = new String("A");
		let item2 = new String("B");
		defer { delete item1; delete item2; }

		listBox.AddItem(item1);
		listBox.AddItem(item2);
		listBox.SelectAll();

		Test.Assert(listBox.SelectedCount == 2, "Items should be selected");

		listBox.SelectionMode = .Single;
		Test.Assert(listBox.SelectedCount == 0, "Changing mode should clear selection");

		listBox.ClearItems();
		ctx.Update(0, 0);
		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ListBox_KeyboardNavigation_UpDown()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let listBox = new ListBox();
		listBox.Width = 200;
		listBox.Height = 200;
		panel.AddChild(listBox);

		let item1 = new String("First");
		let item2 = new String("Second");
		let item3 = new String("Third");
		defer { delete item1; delete item2; delete item3; }

		listBox.AddItem(item1);
		listBox.AddItem(item2);
		listBox.AddItem(item3);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Focus the list
		ctx.FocusManager.SetFocus(listBox);

		// Navigate down
		ctx.InputManager.ProcessKeyDown(.Down, .None);
		Test.Assert(listBox.SelectedIndex == 0 || listBox.SelectedIndex == 1, "Down should move selection");

		// Navigate down again
		ctx.InputManager.ProcessKeyDown(.Down, .None);

		// Navigate up
		let prevIndex = listBox.SelectedIndex;
		ctx.InputManager.ProcessKeyDown(.Up, .None);
		Test.Assert(listBox.SelectedIndex < prevIndex || prevIndex == 0, "Up should move selection up");

		listBox.ClearItems();
		ctx.Update(0, 0);
		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ListBox_KeyboardNavigation_HomeEnd()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let listBox = new ListBox();
		listBox.Width = 200;
		listBox.Height = 200;
		panel.AddChild(listBox);

		let item1 = new String("First");
		let item2 = new String("Middle");
		let item3 = new String("Last");
		defer { delete item1; delete item2; delete item3; }

		listBox.AddItem(item1);
		listBox.AddItem(item2);
		listBox.AddItem(item3);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);
		ctx.FocusManager.SetFocus(listBox);

		// Press End
		ctx.InputManager.ProcessKeyDown(.End, .None);
		Test.Assert(listBox.SelectedIndex == 2, "End should select last item");

		// Press Home
		ctx.InputManager.ProcessKeyDown(.Home, .None);
		Test.Assert(listBox.SelectedIndex == 0, "Home should select first item");

		listBox.ClearItems();
		ctx.Update(0, 0);
		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ListBox_RemoveSelectedItem_UpdatesSelection()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let listBox = new ListBox();
		panel.AddChild(listBox);

		let item1 = new String("A");
		let item2 = new String("B");
		let item3 = new String("C");
		defer { delete item1; delete item2; delete item3; }

		listBox.AddItem(item1);
		listBox.AddItem(item2);
		listBox.AddItem(item3);

		listBox.SelectedIndex = 2;  // Select "C"
		Test.Assert(listBox.SelectedItem == item3, "Should have item3 selected");

		listBox.RemoveItemAt(1);  // Remove "B"
		ctx.Update(0, 0);  // Process mutation queue
		Test.Assert(listBox.SelectedIndex == 1, "Selection index should adjust after removal");
		Test.Assert(listBox.SelectedItem == item3, "Selected item should still be item3");

		listBox.ClearItems();
		ctx.Update(0, 0);
		ctx.RootElement = null;
		delete panel;
	}

	// ========== ListBoxItem Tests ==========

	[Test]
	public static void ListBoxItem_DefaultProperties()
	{
		let item = scope ListBoxItem();

		Test.Assert(!item.IsSelected, "Default IsSelected should be false");
		Test.Assert(item.Index == -1, "Default Index should be -1");
	}

	[Test]
	public static void ListBoxItem_Selection()
	{
		let item = scope ListBoxItem();

		item.IsSelected = true;
		Test.Assert(item.IsSelected, "IsSelected should be true");

		item.IsSelected = false;
		Test.Assert(!item.IsSelected, "IsSelected should be false");
	}

	// ========== ComboBox Tests ==========

	[Test]
	public static void ComboBox_DefaultProperties()
	{
		let comboBox = scope ComboBox();

		Test.Assert(comboBox.ItemCount == 0, "Default ItemCount should be 0");
		Test.Assert(comboBox.SelectedIndex == -1, "Default SelectedIndex should be -1");
		Test.Assert(comboBox.SelectedItem == null, "Default SelectedItem should be null");
		Test.Assert(!comboBox.IsDropDownOpen, "Default IsDropDownOpen should be false");
		Test.Assert(comboBox.DropDownMaxHeight == 200, "Default DropDownMaxHeight should be 200");
	}

	[Test]
	public static void ComboBox_AddItem()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let comboBox = new ComboBox();
		panel.AddChild(comboBox);

		let item1 = new String("Item 1");
		let item2 = new String("Item 2");
		defer { delete item1; delete item2; }

		comboBox.AddItem(item1);
		Test.Assert(comboBox.ItemCount == 1, "ItemCount should be 1");

		comboBox.AddItem(item2);
		Test.Assert(comboBox.ItemCount == 2, "ItemCount should be 2");
		Test.Assert(comboBox.GetItem(0) == item1, "GetItem(0) should return item1");
		Test.Assert(comboBox.GetItem(1) == item2, "GetItem(1) should return item2");

		comboBox.ClearItems();
		ctx.Update(0, 0);
		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ComboBox_SelectedIndex()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let comboBox = new ComboBox();
		panel.AddChild(comboBox);

		let item1 = new String("First");
		let item2 = new String("Second");
		defer { delete item1; delete item2; }

		comboBox.AddItem(item1);
		comboBox.AddItem(item2);

		comboBox.SelectedIndex = 0;
		Test.Assert(comboBox.SelectedIndex == 0, "SelectedIndex should be 0");
		Test.Assert(comboBox.SelectedItem == item1, "SelectedItem should be item1");

		comboBox.SelectedIndex = 1;
		Test.Assert(comboBox.SelectedIndex == 1, "SelectedIndex should change to 1");
		Test.Assert(comboBox.SelectedItem == item2, "SelectedItem should be item2");

		comboBox.ClearItems();
		ctx.Update(0, 0);
		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ComboBox_InvalidSelectedIndex()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let comboBox = new ComboBox();
		panel.AddChild(comboBox);

		let item = new String("Item");
		defer delete item;

		comboBox.AddItem(item);
		comboBox.SelectedIndex = 0;

		comboBox.SelectedIndex = 100;  // Invalid
		Test.Assert(comboBox.SelectedIndex == -1, "Invalid index should set to -1");
		Test.Assert(comboBox.SelectedItem == null, "SelectedItem should be null");

		comboBox.ClearItems();
		ctx.Update(0, 0);
		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ComboBox_ClearItems()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let comboBox = new ComboBox();
		panel.AddChild(comboBox);

		let item = new String("Item");
		defer delete item;

		comboBox.AddItem(item);
		comboBox.SelectedIndex = 0;

		comboBox.ClearItems();
		ctx.Update(0, 0);
		Test.Assert(comboBox.ItemCount == 0, "ItemCount should be 0 after clear");
		Test.Assert(comboBox.SelectedIndex == -1, "SelectedIndex should be -1 after clear");

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ComboBox_RemoveSelectedItem()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let comboBox = new ComboBox();
		panel.AddChild(comboBox);

		let item1 = new String("A");
		let item2 = new String("B");
		defer { delete item1; delete item2; }

		comboBox.AddItem(item1);
		comboBox.AddItem(item2);
		comboBox.SelectedIndex = 0;

		comboBox.RemoveItemAt(0);
		ctx.Update(0, 0);
		Test.Assert(comboBox.SelectedIndex == -1, "Selection should be cleared when selected item removed");

		comboBox.ClearItems();
		ctx.Update(0, 0);
		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ComboBox_SelectionChangedEvent()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let comboBox = new ComboBox();
		panel.AddChild(comboBox);

		let item1 = new String("A");
		let item2 = new String("B");
		defer { delete item1; delete item2; }

		comboBox.AddItem(item1);
		comboBox.AddItem(item2);

		bool eventFired = false;
		comboBox.SelectionChanged.Subscribe(new [&](cb) => { eventFired = true; });

		comboBox.SelectedIndex = 1;
		Test.Assert(eventFired, "SelectionChanged event should fire");

		comboBox.ClearItems();
		ctx.Update(0, 0);
		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void ComboBox_DropDownMaxHeight()
	{
		let comboBox = scope ComboBox();

		comboBox.DropDownMaxHeight = 300;
		Test.Assert(comboBox.DropDownMaxHeight == 300, "DropDownMaxHeight should be settable");

		comboBox.DropDownMaxHeight = 10;  // Below minimum
		Test.Assert(comboBox.DropDownMaxHeight == 50, "DropDownMaxHeight should clamp to minimum");
	}

	[Test]
	public static void ComboBox_InsertItem()
	{
		let ctx = scope GUIContext();
		let panel = new TestPanel();
		ctx.RootElement = panel;

		let comboBox = new ComboBox();
		panel.AddChild(comboBox);

		let item1 = new String("First");
		let item2 = new String("Last");
		let item3 = new String("Middle");
		defer { delete item1; delete item2; delete item3; }

		comboBox.AddItem(item1);
		comboBox.AddItem(item2);
		comboBox.SelectedIndex = 1;  // Select "Last"

		comboBox.InsertItem(1, item3);

		Test.Assert(comboBox.ItemCount == 3, "ItemCount should be 3");
		Test.Assert(comboBox.GetItem(1) == item3, "Inserted item should be at index 1");
		Test.Assert(comboBox.SelectedIndex == 2, "Selection should adjust after insert");
		Test.Assert(comboBox.SelectedItem == item2, "Selected item should still be item2");

		comboBox.ClearItems();
		ctx.Update(0, 0);
		ctx.RootElement = null;
		delete panel;
	}

	// ========== PopupLayer Tests ==========

	[Test]
	public static void PopupLayer_DefaultProperties()
	{
		let popupLayer = scope PopupLayer();

		Test.Assert(!popupLayer.HasPopups, "Default should have no popups");
	}

	// ========== ISelectable Interface Tests ==========

	[Test]
	public static void ISelectable_ListBoxItem_Implements()
	{
		let item = scope ListBoxItem();
		ISelectable selectable = item;

		Test.Assert(selectable != null, "ListBoxItem should implement ISelectable");

		selectable.IsSelected = true;
		Test.Assert(selectable.IsSelected, "IsSelected should be settable via interface");
	}
}
