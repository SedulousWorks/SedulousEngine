namespace GUISandbox;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.GUI;

/// Demo data class for DataGrid.
class PersonData
{
	public String Name ~ delete _;
	public int Age;
	public bool Active;
	public String Department ~ delete _;

	public this(StringView name, int age, bool active, StringView department)
	{
		Name = new String(name);
		Age = age;
		Active = active;
		Department = new String(department);
	}
}

/// Demo 15: Data Display Controls
/// Shows DataGrid with sortable/resizable columns and PropertyGrid for object editing.
class DataDisplayDemo
{
	private StackPanel mRoot /*~ delete _*/;
	private TextBlock mSelectionLabel /*~ delete _*/;
	private TextBlock mSortLabel /*~ delete _*/;
	private List<PersonData> mPeople = new .() ~ DeleteContainerAndItems!(_);

	// PropertyGrid sample state
	private String mSampleName = new .("Sample Object") ~ delete _;
	private int mSampleCount = 42;
	private float mSampleScale = 1.5f;
	private bool mSampleEnabled = true;
	private String mSampleMode = new .("Normal") ~ delete _;

	public UIElement CreateDemo()
	{
		mRoot = new StackPanel();
		mRoot.Orientation = .Vertical;
		mRoot.Spacing = 20;
		mRoot.Padding = .(20, 20, 20, 20);

		// Title
		let title = new TextBlock("Data Display Controls Demo");
		title.FontSize = 20;
		mRoot.AddChild(title);

		// DataGrid section
		CreateDataGridSection();

		// PropertyGrid section
		CreatePropertyGridSection();

		return mRoot;
	}

	private void CreateDataGridSection()
	{
		let section = new StackPanel();
		section.Orientation = .Vertical;
		section.Spacing = 10;
		section.Padding = .(15, 15, 15, 15);

		let header = new TextBlock("DataGrid - Sortable, Resizable Columns");
		header.FontSize = 16;
		section.AddChild(header);

		// Create sample data
		CreateSampleData();

		// Create DataGrid
		let grid = new DataGrid();
		grid.Width = 600;
		grid.Height = 200;
		grid.SelectionMode = .Extended;

		// Add columns
		let nameColumn = new DataGridTextColumn("Name", new (rowData) => {
			if (let person = rowData as PersonData)
				return person.Name;
			return null;
		});
		nameColumn.Width = 150;
		grid.AddColumn(nameColumn);

		let ageColumn = new DataGridTextColumn("Age", new (rowData) => {
			if (let person = rowData as PersonData)
				return new box person.Age;
			return null;
		});
		ageColumn.Width = 80;
		grid.AddColumn(ageColumn);

		let activeColumn = new DataGridCheckBoxColumn("Active", new (rowData) => {
			if (let person = rowData as PersonData)
				return new box person.Active;
			return null;
		});
		activeColumn.Width = 80;
		grid.AddColumn(activeColumn);

		let deptColumn = new DataGridTextColumn("Department", new (rowData) => {
			if (let person = rowData as PersonData)
				return person.Department;
			return null;
		});
		deptColumn.Width = 150;
		grid.AddColumn(deptColumn);

		// Set items
		let items = new List<Object>();
		for (let person in mPeople)
			items.Add(person);
		grid.SetItems(items);
		delete items;

		// Selection label
		mSelectionLabel = new TextBlock("Selected: 0 rows");
		grid.SelectionChanged.Subscribe(new (g) => {
			mSelectionLabel.Text = scope $"Selected: {g.SelectedIndices.Count} rows";
		});

		// Sort label
		mSortLabel = new TextBlock("Sort: (none)");
		grid.SortChanged.Subscribe(new (g, col) => {
			if (col.SortDirection == null)
				mSortLabel.Text = "Sort: (none)";
			else
			{
				let dir = col.SortDirection == .Ascending ? "Asc" : "Desc";
				mSortLabel.Text = scope $"Sort: {col.Header} ({dir})";
			}
		});

		section.AddChild(grid);

		// Status row
		let statusRow = new StackPanel();
		statusRow.Orientation = .Horizontal;
		statusRow.Spacing = 20;
		statusRow.AddChild(mSelectionLabel);
		statusRow.AddChild(mSortLabel);
		section.AddChild(statusRow);

		// Instructions
		let instructions = new TextBlock("Click headers to sort | Drag header edges to resize | Ctrl+click for multi-select | Shift+click for range");
		section.AddChild(instructions);

		mRoot.AddChild(section);
	}

	private void CreateSampleData()
	{
		mPeople.Add(new PersonData("Alice Johnson", 28, true, "Engineering"));
		mPeople.Add(new PersonData("Bob Smith", 35, true, "Marketing"));
		mPeople.Add(new PersonData("Carol White", 42, false, "Finance"));
		mPeople.Add(new PersonData("David Brown", 31, true, "Engineering"));
		mPeople.Add(new PersonData("Eve Davis", 26, true, "Design"));
		mPeople.Add(new PersonData("Frank Miller", 45, false, "Sales"));
		mPeople.Add(new PersonData("Grace Lee", 33, true, "Engineering"));
		mPeople.Add(new PersonData("Henry Wilson", 29, true, "Marketing"));
		mPeople.Add(new PersonData("Ivy Chen", 38, true, "Finance"));
		mPeople.Add(new PersonData("Jack Taylor", 24, false, "Design"));
	}

	private void CreatePropertyGridSection()
	{
		let section = new StackPanel();
		section.Orientation = .Vertical;
		section.Spacing = 10;
		section.Padding = .(15, 15, 15, 15);

		let header = new TextBlock("PropertyGrid - Object Property Editor");
		header.FontSize = 16;
		section.AddChild(header);

		// Create PropertyGrid
		let propGrid = new PropertyGrid();
		propGrid.Width = 350;
		propGrid.Height = 250;
		propGrid.NameColumnWidth = 100;

		// Add properties in different categories
		propGrid.AddStringProperty("Name", "General",
			new () => new String(mSampleName),
			new (val) => {
				if (let str = val as String)
					mSampleName.Set(str);
			});

		propGrid.AddIntProperty("Count", "General",
			new () => new box mSampleCount,
			new (val) => {
				if (let i = val as int?)
					mSampleCount = i;
			});

		propGrid.AddBoolProperty("Enabled", "General",
			new () => new box mSampleEnabled,
			new (val) => {
				if (let b = val as bool?)
					mSampleEnabled = b;
			});

		propGrid.AddFloatProperty("Scale", "Transform",
			new () => new box mSampleScale,
			new (val) => {
				if (let f = val as float?)
					mSampleScale = f;
			});

		propGrid.AddEnumProperty("Mode", "Settings",
			StringView[?]("Normal", "Fast", "Quality"),
			new () => new String(mSampleMode),
			new (val) => {
				if (let str = val as String)
					mSampleMode.Set(str);
			});

		// Property changed handler
		let changeLabel = new TextBlock("Last change: (none)");
		propGrid.PropertyChanged.Subscribe(new (pg, prop) => {
			changeLabel.Text = scope $"Last change: {prop.Name} = {prop.DisplayValue}";
		});

		section.AddChild(propGrid);
		section.AddChild(changeLabel);

		// Instructions
		let instructions = new TextBlock("Click categories to expand/collapse | Click values to edit | Drag splitter to resize columns");
		section.AddChild(instructions);

		mRoot.AddChild(section);
	}
}
