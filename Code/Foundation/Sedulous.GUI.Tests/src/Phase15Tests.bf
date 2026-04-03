using System;
using System.Collections;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI.Tests;

/// Tests for Phase 15: Data Display Controls

// === DataGridColumn Tests ===

class DataGridColumnTests
{
	[Test]
	public static void DataGridTextColumnDefaultProperties()
	{
		let column = scope DataGridTextColumn("Name");
		Test.Assert(column.Header == "Name");
		Test.Assert(column.Width == 100);
		Test.Assert(column.MinWidth == 50);
		Test.Assert(column.MaxWidth == float.MaxValue);
		Test.Assert(column.CanResize == true);
		Test.Assert(column.CanSort == true);
		Test.Assert(column.SortDirection == null);
	}

	[Test]
	public static void DataGridTextColumnSetHeader()
	{
		let column = scope DataGridTextColumn("Initial");
		column.Header = "Changed";
		Test.Assert(column.Header == "Changed");
	}

	[Test]
	public static void DataGridTextColumnSetWidth()
	{
		let column = scope DataGridTextColumn("Test");
		column.Width = 150;
		Test.Assert(column.Width == 150);
	}

	[Test]
	public static void DataGridTextColumnWidthClampedToMin()
	{
		let column = scope DataGridTextColumn("Test");
		column.MinWidth = 100;
		column.Width = 50;
		Test.Assert(column.Width == 100);
	}

	[Test]
	public static void DataGridTextColumnWidthClampedToMax()
	{
		let column = scope DataGridTextColumn("Test");
		column.MaxWidth = 200;
		column.Width = 300;
		Test.Assert(column.Width == 200);
	}

	[Test]
	public static void DataGridTextColumnMinWidthClampedTo20()
	{
		let column = scope DataGridTextColumn("Test");
		column.MinWidth = 10;
		Test.Assert(column.MinWidth == 20);
	}

	[Test]
	public static void DataGridCheckBoxColumnDefaultProperties()
	{
		let column = scope DataGridCheckBoxColumn("Active");
		Test.Assert(column.Header == "Active");
		Test.Assert(column.Width == 60);
		Test.Assert(column.MinWidth == 40);
		Test.Assert(column.CanSort == true);
	}

	[Test]
	public static void DataGridColumnSortDirection()
	{
		let column = scope DataGridTextColumn("Test");
		Test.Assert(column.SortDirection == null);
		column.SortDirection = .Ascending;
		Test.Assert(column.SortDirection == .Ascending);
		column.SortDirection = .Descending;
		Test.Assert(column.SortDirection == .Descending);
		column.SortDirection = null;
		Test.Assert(column.SortDirection == null);
	}
}

// === DataGrid Tests ===

class DataGridTests
{
	[Test]
	public static void DataGridDefaultProperties()
	{
		let grid = scope DataGrid();
		Test.Assert(grid.Columns != null);
		Test.Assert(grid.Columns.Count == 0);
		Test.Assert(grid.Items != null);
		Test.Assert(grid.Items.Count == 0);
		Test.Assert(grid.SelectedIndex == -1);
		Test.Assert(grid.SelectedIndices.Count == 0);
		Test.Assert(grid.SelectionMode == .Extended);
		Test.Assert(grid.HeaderHeight == 24);
		Test.Assert(grid.RowHeight == 22);
		Test.Assert(grid.IsFocusable == true);
		Test.Assert(grid.IsTabStop == true);
	}

	[Test]
	public static void DataGridAddColumn()
	{
		let grid = scope DataGrid();
		let column = new DataGridTextColumn("Name");
		grid.AddColumn(column);
		Test.Assert(grid.Columns.Count == 1);
		Test.Assert(grid.Columns[0] == column);
	}

	[Test]
	public static void DataGridAddMultipleColumns()
	{
		let grid = scope DataGrid();
		grid.AddColumn(new DataGridTextColumn("Name"));
		grid.AddColumn(new DataGridTextColumn("Age"));
		grid.AddColumn(new DataGridCheckBoxColumn("Active"));
		Test.Assert(grid.Columns.Count == 3);
		Test.Assert(grid.Columns[0].Header == "Name");
		Test.Assert(grid.Columns[1].Header == "Age");
		Test.Assert(grid.Columns[2].Header == "Active");
	}

	[Test]
	public static void DataGridSetItems()
	{
		let grid = scope DataGrid();
		let items = scope List<Object>();
		items.Add(new String("Item 1"));
		items.Add(new String("Item 2"));
		items.Add(new String("Item 3"));
		defer { for (let item in items) delete item; }
		grid.SetItems(items);
		Test.Assert(grid.Items.Count == 3);
	}

	[Test]
	public static void DataGridClearItems()
	{
		let grid = scope DataGrid();
		let items = scope List<Object>();
		items.Add(new String("Item 1"));
		items.Add(new String("Item 2"));
		defer { for (let item in items) delete item; }
		grid.SetItems(items);
		Test.Assert(grid.Items.Count == 2);
		grid.ClearItems();
		Test.Assert(grid.Items.Count == 0);
	}

	[Test]
	public static void DataGridSelectionModes()
	{
		let grid = scope DataGrid();
		grid.SelectionMode = .Single;
		Test.Assert(grid.SelectionMode == .Single);
		grid.SelectionMode = .Multiple;
		Test.Assert(grid.SelectionMode == .Multiple);
		grid.SelectionMode = .Extended;
		Test.Assert(grid.SelectionMode == .Extended);
	}

	[Test]
	public static void DataGridSelectSingle()
	{
		let grid = scope DataGrid();
		let items = scope List<Object>();
		items.Add(new String("Item 1"));
		items.Add(new String("Item 2"));
		items.Add(new String("Item 3"));
		defer { for (let item in items) delete item; }
		grid.SetItems(items);
		grid.SelectSingle(1);
		Test.Assert(grid.SelectedIndex == 1);
		Test.Assert(grid.SelectedIndices.Count == 1);
		Test.Assert(grid.IsSelected(1) == true);
		Test.Assert(grid.IsSelected(0) == false);
	}

	[Test]
	public static void DataGridToggleSelection()
	{
		let grid = scope DataGrid();
		let items = scope List<Object>();
		items.Add(new String("Item 1"));
		items.Add(new String("Item 2"));
		defer { for (let item in items) delete item; }
		grid.SetItems(items);
		grid.ToggleSelection(0);
		Test.Assert(grid.IsSelected(0) == true);
		grid.ToggleSelection(0);
		Test.Assert(grid.IsSelected(0) == false);
	}

	[Test]
	public static void DataGridSelectRange()
	{
		let grid = scope DataGrid();
		let items = scope List<Object>();
		items.Add(new String("Item 1"));
		items.Add(new String("Item 2"));
		items.Add(new String("Item 3"));
		items.Add(new String("Item 4"));
		defer { for (let item in items) delete item; }
		grid.SetItems(items);
		grid.SelectRange(1, 3);
		Test.Assert(grid.SelectedIndices.Count == 3);
		Test.Assert(grid.IsSelected(0) == false);
		Test.Assert(grid.IsSelected(1) == true);
		Test.Assert(grid.IsSelected(2) == true);
		Test.Assert(grid.IsSelected(3) == true);
	}

	[Test]
	public static void DataGridSelectAll()
	{
		let grid = scope DataGrid();
		let items = scope List<Object>();
		items.Add(new String("Item 1"));
		items.Add(new String("Item 2"));
		items.Add(new String("Item 3"));
		defer { for (let item in items) delete item; }
		grid.SetItems(items);
		grid.SelectAll();
		Test.Assert(grid.SelectedIndices.Count == 3);
		Test.Assert(grid.IsSelected(0) == true);
		Test.Assert(grid.IsSelected(1) == true);
		Test.Assert(grid.IsSelected(2) == true);
	}

	[Test]
	public static void DataGridSortByColumn()
	{
		let grid = scope DataGrid();
		let column = new DataGridTextColumn("Name");
		grid.AddColumn(column);
		Test.Assert(column.SortDirection == null);
		grid.SortByColumn(column);
		Test.Assert(column.SortDirection == .Ascending);
		grid.SortByColumn(column);
		Test.Assert(column.SortDirection == .Descending);
		grid.SortByColumn(column);
		Test.Assert(column.SortDirection == null);
	}

	[Test]
	public static void DataGridSortClearsOtherColumns()
	{
		let grid = scope DataGrid();
		let column1 = new DataGridTextColumn("Name");
		let column2 = new DataGridTextColumn("Age");
		grid.AddColumn(column1);
		grid.AddColumn(column2);
		grid.SortByColumn(column1);
		Test.Assert(column1.SortDirection == .Ascending);
		grid.SortByColumn(column2);
		Test.Assert(column1.SortDirection == null);
		Test.Assert(column2.SortDirection == .Ascending);
	}

	[Test]
	public static void DataGridHeaderHeight()
	{
		let grid = scope DataGrid();
		Test.Assert(grid.HeaderHeight == 24);
		grid.HeaderHeight = 32;
		Test.Assert(grid.HeaderHeight == 32);
	}

	[Test]
	public static void DataGridRowHeight()
	{
		let grid = scope DataGrid();
		Test.Assert(grid.RowHeight == 22);
		grid.RowHeight = 28;
		Test.Assert(grid.RowHeight == 28);
	}
}

// === PropertyGrid Tests ===

class PropertyGridTests
{
	[Test]
	public static void PropertyGridDefaultProperties()
	{
		let grid = scope PropertyGrid();
		Test.Assert(grid.RowHeight == 22);
		Test.Assert(grid.NameColumnWidth == 120);
		Test.Assert(grid.IsFocusable == true);
		Test.Assert(grid.IsTabStop == true);
	}

	[Test]
	public static void PropertyGridAddProperty()
	{
		let grid = scope PropertyGrid();
		let prop = grid.AddProperty("Name", .String);
		Test.Assert(prop != null);
		Test.Assert(prop.Name == "Name");
		Test.Assert(prop.Type == .String);
		Test.Assert(prop.Category == "General");
	}

	[Test]
	public static void PropertyGridAddPropertyWithCategory()
	{
		let grid = scope PropertyGrid();
		let prop = grid.AddProperty("Scale", .Float, "Transform");
		Test.Assert(prop.Category == "Transform");
	}

	[Test]
	public static void PropertyGridAddStringProperty()
	{
		let grid = scope PropertyGrid();
		String value = scope .("Test");
		let prop = grid.AddStringProperty("Text", "General",
			new () => new String(value),
			new (val) => { });
		Test.Assert(prop.Type == .String);
		Test.Assert(prop.Getter != null);
		Test.Assert(prop.Setter != null);
	}

	[Test]
	public static void PropertyGridAddIntProperty()
	{
		let grid = scope PropertyGrid();
		let prop = grid.AddProperty("Count", .Int, "General");
		Test.Assert(prop != null);
		Test.Assert(prop.Type == .Int);
		Test.Assert(prop.Name == "Count");
	}

	[Test]
	public static void PropertyGridAddFloatProperty()
	{
		let grid = scope PropertyGrid();
		let prop = grid.AddProperty("Scale", .Float, "Transform");
		Test.Assert(prop != null);
		Test.Assert(prop.Type == .Float);
		Test.Assert(prop.Category == "Transform");
	}

	[Test]
	public static void PropertyGridAddBoolProperty()
	{
		let grid = scope PropertyGrid();
		let prop = grid.AddProperty("Enabled", .Bool, "General");
		Test.Assert(prop != null);
		Test.Assert(prop.Type == .Bool);
	}

	[Test]
	public static void PropertyGridAddEnumProperty()
	{
		let grid = scope PropertyGrid();
		String value = scope .("Normal");
		let prop = grid.AddEnumProperty("Mode", "Settings",
			StringView[?]("Normal", "Fast", "Quality"),
			new () => new String(value),
			new (val) => { });
		Test.Assert(prop.Type == .Enum);
		Test.Assert(prop.EnumValues != null);
		Test.Assert(prop.EnumValues.Count == 3);
	}

	[Test]
	public static void PropertyGridClear()
	{
		let grid = scope PropertyGrid();
		grid.AddProperty("Name", .String);
		grid.AddProperty("Age", .Int);
		grid.Clear();
		// Clear should remove all properties
		// (We can't directly test internal state, but Clear() should work without error)
	}

	[Test]
	public static void PropertyGridNameColumnWidth()
	{
		let grid = scope PropertyGrid();
		Test.Assert(grid.NameColumnWidth == 120);
		grid.NameColumnWidth = 150;
		Test.Assert(grid.NameColumnWidth == 150);
	}

	[Test]
	public static void PropertyGridNameColumnWidthMinimum()
	{
		let grid = scope PropertyGrid();
		grid.NameColumnWidth = 30;
		Test.Assert(grid.NameColumnWidth == 50);  // Should clamp to minimum
	}

	[Test]
	public static void PropertyGridRowHeight()
	{
		let grid = scope PropertyGrid();
		Test.Assert(grid.RowHeight == 22);
		grid.RowHeight = 28;
		Test.Assert(grid.RowHeight == 28);
	}
}

// === PropertyItem Tests ===

class PropertyItemTests
{
	[Test]
	public static void PropertyItemDefaultProperties()
	{
		let item = scope PropertyItem("Test", .String);
		Test.Assert(item.Name == "Test");
		Test.Assert(item.Type == .String);
		Test.Assert(item.Category == "General");
		Test.Assert(item.DisplayValue != null);
		Test.Assert(item.GetValue() == null);
		Test.Assert(item.Getter == null);
		Test.Assert(item.Setter == null);
	}

	[Test]
	public static void PropertyItemSetCategory()
	{
		let item = scope PropertyItem("Test", .Float);
		item.SetCategory("Transform");
		Test.Assert(item.Category == "Transform");
	}

	[Test]
	public static void PropertyItemTypes()
	{
		let stringItem = scope PropertyItem("A", .String);
		let intItem = scope PropertyItem("B", .Int);
		let floatItem = scope PropertyItem("C", .Float);
		let boolItem = scope PropertyItem("D", .Bool);
		let enumItem = scope PropertyItem("E", .Enum);
		let colorItem = scope PropertyItem("F", .Color);
		Test.Assert(stringItem.Type == .String);
		Test.Assert(intItem.Type == .Int);
		Test.Assert(floatItem.Type == .Float);
		Test.Assert(boolItem.Type == .Bool);
		Test.Assert(enumItem.Type == .Enum);
		Test.Assert(colorItem.Type == .Color);
	}
}

// === PropertyCategory Tests ===

class PropertyCategoryTests
{
	[Test]
	public static void PropertyCategoryDefaultProperties()
	{
		let category = scope PropertyCategory("General");
		Test.Assert(category.Name == "General");
		Test.Assert(category.IsExpanded == true);
		Test.Assert(category.Properties != null);
		Test.Assert(category.Properties.Count == 0);
	}

	[Test]
	public static void PropertyCategoryExpandCollapse()
	{
		let category = scope PropertyCategory("Test");
		Test.Assert(category.IsExpanded == true);
		category.IsExpanded = false;
		Test.Assert(category.IsExpanded == false);
		category.IsExpanded = true;
		Test.Assert(category.IsExpanded == true);
	}
}
