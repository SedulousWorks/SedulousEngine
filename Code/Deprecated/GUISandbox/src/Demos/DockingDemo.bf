namespace GUISandbox;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.GUI;

/// Demo 16: Docking System
/// Shows DockManager, DockablePanel, DockTabGroup, and DockSplit components.
class DockingDemo
{
	private DockPanel mRoot;
	private DockManager mDockManager;
	private GUIContext mContext;
	private int mPanelCounter = 0;
	private List<DockablePanel> mCreatedPanels = new .() ~ DeleteContainerAndItems!(_);

	public UIElement CreateDemo(GUIContext context)
	{
		mContext = context;

		mRoot = new DockPanel();
		mRoot.Padding = .(0, 70, 0, 0);  // Top padding for overlay text

		// Create button bar at top
		let buttonBar = CreateButtonBar();
		DockPanelProperties.SetDock(buttonBar, .Top);
		mRoot.AddChild(buttonBar);

		// Create the dock manager
		mDockManager = new DockManager();
		mDockManager.HorizontalAlignment = .Stretch;
		mDockManager.VerticalAlignment = .Stretch;
		mRoot.AddChild(mDockManager);

		// Add initial panels
		CreateInitialLayout();

		return mRoot;
	}

	private StackPanel CreateButtonBar()
	{
		let bar = new StackPanel();
		bar.Orientation = .Horizontal;
		bar.Spacing = 8;
		bar.Padding = .(10, 10, 10, 10);

		// Add panel buttons
		let addCenterBtn = new Button();
		addCenterBtn.Content = new TextBlock("Add Center");
		addCenterBtn.Padding = .(8, 4, 8, 4);
		addCenterBtn.Click.Subscribe(new (btn) => AddPanel(.Center));
		bar.AddChild(addCenterBtn);

		let addLeftBtn = new Button();
		addLeftBtn.Content = new TextBlock("Add Left");
		addLeftBtn.Padding = .(8, 4, 8, 4);
		addLeftBtn.Click.Subscribe(new (btn) => AddPanel(.Left));
		bar.AddChild(addLeftBtn);

		let addRightBtn = new Button();
		addRightBtn.Content = new TextBlock("Add Right");
		addRightBtn.Padding = .(8, 4, 8, 4);
		addRightBtn.Click.Subscribe(new (btn) => AddPanel(.Right));
		bar.AddChild(addRightBtn);

		let addTopBtn = new Button();
		addTopBtn.Content = new TextBlock("Add Top");
		addTopBtn.Padding = .(8, 4, 8, 4);
		addTopBtn.Click.Subscribe(new (btn) => AddPanel(.Top));
		bar.AddChild(addTopBtn);

		let addBottomBtn = new Button();
		addBottomBtn.Content = new TextBlock("Add Bottom");
		addBottomBtn.Padding = .(8, 4, 8, 4);
		addBottomBtn.Click.Subscribe(new (btn) => AddPanel(.Bottom));
		bar.AddChild(addBottomBtn);

		// Separator
		let separator = new Border();
		separator.Width = 1;
		separator.Margin = .(8, 4, 8, 4);
		bar.AddChild(separator);

		// Info label
		let info = new TextBlock("Click buttons to add panels. Close panels with X button.");
		info.VerticalAlignment = .Center;
		bar.AddChild(info);

		return bar;
	}

	private void CreateInitialLayout()
	{
		// Create initial panels with interesting content

		// Properties panel (left)
		let propertiesPanel = CreatePanel("Properties", CreatePropertiesContent());
		mDockManager.DockPanel(propertiesPanel, .Left);

		// Explorer panel (left, tabbed with Properties)
		let explorerPanel = CreatePanel("Explorer", CreateExplorerContent());
		mDockManager.DockPanel(explorerPanel, .Center);  // Adds as tab to existing

		// Main editor panel (center)
		let editorPanel = CreatePanel("Editor", CreateEditorContent());
		mDockManager.DockPanel(editorPanel, .Right);

		// Output panel (bottom)
		let outputPanel = CreatePanel("Output", CreateOutputContent());
		mDockManager.DockPanel(outputPanel, .Bottom);
	}

	private DockablePanel CreatePanel(StringView title, UIElement content)
	{
		mPanelCounter++;
		let panel = new DockablePanel(title, content);
		panel.IsCloseable = true;
		mCreatedPanels.Add(panel);
		return panel;
	}

	private void AddPanel(DockPosition position)
	{
		mPanelCounter++;
		let title = scope $"Panel {mPanelCounter}";
		let content = CreateGenericContent(title);
		let panel = CreatePanel(title, content);
		mDockManager.DockPanel(panel, position);
	}

	// === Content Creators ===

	private UIElement CreatePropertiesContent()
	{
		let panel = new StackPanel();
		panel.Orientation = .Vertical;
		panel.Spacing = 8;
		panel.Padding = .(8, 8, 8, 8);

		AddPropertyRow(panel, "Name", "MyObject");
		AddPropertyRow(panel, "Position", "100, 200");
		AddPropertyRow(panel, "Size", "320x240");
		AddPropertyRow(panel, "Visible", "True");
		AddPropertyRow(panel, "Enabled", "True");
		AddPropertyRow(panel, "Tag", "(none)");

		return panel;
	}

	private void AddPropertyRow(StackPanel parent, StringView label, StringView value)
	{
		let row = new StackPanel();
		row.Orientation = .Horizontal;
		row.Spacing = 8;

		let labelText = new TextBlock(label);
		labelText.Width = 80;
		row.AddChild(labelText);

		let valueText = new TextBlock(value);
		row.AddChild(valueText);

		parent.AddChild(row);
	}

	private UIElement CreateExplorerContent()
	{
		let panel = new StackPanel();
		panel.Orientation = .Vertical;
		panel.Spacing = 4;
		panel.Padding = .(8, 8, 8, 8);

		AddTreeItem(panel, "Project", 0);
		AddTreeItem(panel, "  src", 1);
		AddTreeItem(panel, "    main.bf", 2);
		AddTreeItem(panel, "    app.bf", 2);
		AddTreeItem(panel, "    utils.bf", 2);
		AddTreeItem(panel, "  assets", 1);
		AddTreeItem(panel, "    textures", 2);
		AddTreeItem(panel, "    models", 2);
		AddTreeItem(panel, "  build", 1);

		return panel;
	}

	private void AddTreeItem(StackPanel parent, StringView text, int level)
	{
		let item = new TextBlock(text);
		// Root items use accent color, children use default text color
		if (level == 0)
			item.Foreground = Color(100, 160, 220, 255);  // Keep accent color for hierarchy
		parent.AddChild(item);
	}

	private UIElement CreateEditorContent()
	{
		let panel = new StackPanel();
		panel.Orientation = .Vertical;
		panel.Spacing = 4;
		panel.Padding = .(8, 8, 8, 8);
		panel.Background = Color(30, 30, 30, 255);

		// Simulated code editor content
		AddCodeLine(panel, "using System;", Color(86, 156, 214, 255));
		AddCodeLine(panel, "using Sedulous.GUI;", Color(86, 156, 214, 255));
		AddCodeLine(panel, "", Color.White);
		AddCodeLine(panel, "class MyApp", Color(78, 201, 176, 255));
		AddCodeLine(panel, "{", Color.White);
		AddCodeLine(panel, "    public this()", Color(220, 220, 220, 255));
		AddCodeLine(panel, "    {", Color.White);
		AddCodeLine(panel, "        // Initialize", Color(87, 166, 74, 255));
		AddCodeLine(panel, "    }", Color.White);
		AddCodeLine(panel, "}", Color.White);

		return panel;
	}

	private void AddCodeLine(StackPanel parent, StringView text, Color color)
	{
		let line = new TextBlock(text);
		line.Foreground = color;
		line.FontSize = 13;
		parent.AddChild(line);
	}

	private UIElement CreateOutputContent()
	{
		let panel = new StackPanel();
		panel.Orientation = .Vertical;
		panel.Spacing = 2;
		panel.Padding = .(8, 8, 8, 8);
		panel.Background = Color(25, 25, 25, 255);

		AddOutputLine(panel, "[12:34:56] Build started...", Color(150, 150, 150, 255));
		AddOutputLine(panel, "[12:34:57] Compiling main.bf", Color(180, 180, 180, 255));
		AddOutputLine(panel, "[12:34:57] Compiling app.bf", Color(180, 180, 180, 255));
		AddOutputLine(panel, "[12:34:58] Compiling utils.bf", Color(180, 180, 180, 255));
		AddOutputLine(panel, "[12:34:58] Linking...", Color(180, 180, 180, 255));
		AddOutputLine(panel, "[12:34:59] Build succeeded", Color(100, 200, 100, 255));

		return panel;
	}

	private void AddOutputLine(StackPanel parent, StringView text, Color color)
	{
		let line = new TextBlock(text);
		line.Foreground = color;
		line.FontSize = 12;
		parent.AddChild(line);
	}

	private UIElement CreateGenericContent(StringView title)
	{
		let panel = new StackPanel();
		panel.Orientation = .Vertical;
		panel.Spacing = 10;
		panel.Padding = .(15, 15, 15, 15);
		panel.HorizontalAlignment = .Center;
		panel.VerticalAlignment = .Center;

		let label = new TextBlock(title);
		label.FontSize = 16;
		label.HorizontalAlignment = .Center;
		panel.AddChild(label);

		let desc = new TextBlock("Drag splitters to resize");
		desc.HorizontalAlignment = .Center;
		panel.AddChild(desc);

		return panel;
	}
}
