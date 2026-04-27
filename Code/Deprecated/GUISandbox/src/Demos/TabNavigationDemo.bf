namespace GUISandbox;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.GUI;

/// Demo 12: Tab & Navigation Controls
/// Shows TabControl, Expander, GroupBox, and Breadcrumb.
class TabNavigationDemo
{
	private StackPanel mRoot /*~ delete _*/;
	private TextBlock mTabStatusLabel /*~ delete _*/;
	private TextBlock mBreadcrumbLabel /*~ delete _*/;
	private TabControl mTabControl /*~ delete _*/;

	public UIElement CreateDemo()
	{
		mRoot = new StackPanel();
		mRoot.Orientation = .Vertical;
		mRoot.Spacing = 15;
		mRoot.Padding = .(20, 20, 20, 20);

		// Title
		let title = new TextBlock("Tab & Navigation Controls Demo");
		title.FontSize = 20;
		mRoot.AddChild(title);

		// Breadcrumb section
		CreateBreadcrumbSection();

		// TabControl section
		CreateTabControlSection();

		// Expander section
		CreateExpanderSection();

		// GroupBox section
		CreateGroupBoxSection();

		return mRoot;
	}

	private void CreateBreadcrumbSection()
	{
		let section = new StackPanel();
		section.Orientation = .Vertical;
		section.Spacing = 10;
				section.Padding = .(15, 15, 15, 15);

		let header = new TextBlock("Breadcrumb Navigation");
		header.FontSize = 16;
		section.AddChild(header);

		let breadcrumb = new Breadcrumb();
		breadcrumb.AddItem("Home", "/");
		breadcrumb.AddItem("Documents", "/documents");
		breadcrumb.AddItem("Projects", "/documents/projects");
		breadcrumb.AddItem("MyApp", "/documents/projects/myapp");

		mBreadcrumbLabel = new TextBlock("Click an item to navigate (removes subsequent items)");

		breadcrumb.ItemClicked.Subscribe(new (bc, item) => {
			// Navigate to clicked item (removes items after it)
			bc.NavigateTo(item);
			if (let str = item.Content as TextBlock)
				mBreadcrumbLabel.Text = scope $"Navigated to: {str.Text}";
		});

		section.AddChild(breadcrumb);
		section.AddChild(mBreadcrumbLabel);

		mRoot.AddChild(section);
	}

	private void CreateTabControlSection()
	{
		let section = new StackPanel();
		section.Orientation = .Vertical;
		section.Spacing = 10;
				section.Padding = .(15, 15, 15, 15);

		let header = new TextBlock("TabControl");
		header.FontSize = 16;
		section.AddChild(header);

		// Tab placement controls
		let placementRow = new StackPanel();
		placementRow.Orientation = .Horizontal;
		placementRow.Spacing = 10;

		let placementLabel = new TextBlock("Tab Position:");
		placementRow.AddChild(placementLabel);

		mTabControl = new TabControl();
		mTabControl.Width = 500;
		mTabControl.Height = 200;

		let btnTop = new Button("Top");
		btnTop.Click.Subscribe(new (b) => mTabControl.TabStripPlacement = .Top);
		placementRow.AddChild(btnTop);

		let btnBottom = new Button("Bottom");
		btnBottom.Click.Subscribe(new (b) => mTabControl.TabStripPlacement = .Bottom);
		placementRow.AddChild(btnBottom);

		let btnLeft = new Button("Left");
		btnLeft.Click.Subscribe(new (b) => mTabControl.TabStripPlacement = .Left);
		placementRow.AddChild(btnLeft);

		let btnRight = new Button("Right");
		btnRight.Click.Subscribe(new (b) => mTabControl.TabStripPlacement = .Right);
		placementRow.AddChild(btnRight);

		section.AddChild(placementRow);

		// Create tabs
		let tab1Content = new StackPanel();
		tab1Content.Orientation = .Vertical;
		tab1Content.Spacing = 5;
		tab1Content.Padding = .(10, 10, 10, 10);
		tab1Content.AddChild(new TextBlock("Welcome to the General tab!"));
		tab1Content.AddChild(new TextBlock("This is the first tab's content."));
		tab1Content.AddChild(new Button("Click Me"));

		mTabControl.AddTab("General", tab1Content);

		let tab2Content = new StackPanel();
		tab2Content.Orientation = .Vertical;
		tab2Content.Spacing = 5;
		tab2Content.Padding = .(10, 10, 10, 10);
		tab2Content.AddChild(new TextBlock("Advanced Settings"));
		tab2Content.AddChild(new CheckBox("Enable feature A"));
		tab2Content.AddChild(new CheckBox("Enable feature B"));

		let tab2 = mTabControl.AddTab("Advanced", tab2Content);
		tab2.IsCloseable = true;

		let tab3Content = new TextBlock("About this application.\n\nVersion 1.0.0");
		tab3Content.Padding = .(10, 10, 10, 10);
		let tab3 = mTabControl.AddTab("About", tab3Content);
		tab3.IsCloseable = true;

		mTabStatusLabel = new TextBlock("Selected: General");
		mTabControl.SelectionChanged.Subscribe(new (tc) => {
			if (tc.SelectedTab != null)
			{
				if (let headerText = tc.SelectedTab.Header as TextBlock)
					mTabStatusLabel.Text = scope $"Selected: {headerText.Text}";
			}
		});

		section.AddChild(mTabControl);
		section.AddChild(mTabStatusLabel);

		// Instructions
		let instructions = new TextBlock("Ctrl+Tab to cycle tabs, click X to close closeable tabs");
		section.AddChild(instructions);

		mRoot.AddChild(section);
	}

	private void CreateExpanderSection()
	{
		let section = new StackPanel();
		section.Orientation = .Vertical;
		section.Spacing = 10;
				section.Padding = .(15, 15, 15, 15);

		let header = new TextBlock("Expander");
		header.FontSize = 16;
		section.AddChild(header);

		// First expander
		let expander1 = new Expander("Click to Expand/Collapse");
		let expanderContent1 = new StackPanel();
		expanderContent1.Orientation = .Vertical;
		expanderContent1.Spacing = 5;
		expanderContent1.Padding = .(10, 10, 10, 10);
		expanderContent1.AddChild(new TextBlock("This content is collapsible."));
		expanderContent1.AddChild(new TextBlock("Click the header or arrow to toggle."));
		expanderContent1.AddChild(new Button("Button Inside Expander"));
		expander1.Content = expanderContent1;
		expander1.Width = 400;

		section.AddChild(expander1);

		// Second expander (starts collapsed)
		let expander2 = new Expander("Another Expander (starts collapsed)");
		let expanderContent2 = new StackPanel();
		expanderContent2.Orientation = .Vertical;
		expanderContent2.Spacing = 5;
		expanderContent2.Padding = .(10, 10, 10, 10);
		expanderContent2.AddChild(new TextBlock("Hidden content revealed!"));
		expanderContent2.AddChild(new TextBlock("You expanded this section."));
		expander2.Content = expanderContent2;
		expander2.IsExpanded = false;
		expander2.Width = 400;

		section.AddChild(expander2);

		// Instructions
		let instructions = new TextBlock("Click header to toggle, or use keyboard: Space/Enter, Left/Right arrows");
		section.AddChild(instructions);

		mRoot.AddChild(section);
	}

	private void CreateGroupBoxSection()
	{
		let section = new StackPanel();
		section.Orientation = .Vertical;
		section.Spacing = 10;
				section.Padding = .(15, 15, 15, 15);

		let header = new TextBlock("GroupBox");
		header.FontSize = 16;
		section.AddChild(header);

		// Horizontal row of groupboxes
		let row = new StackPanel();
		row.Orientation = .Horizontal;
		row.Spacing = 20;

		// First GroupBox
		let groupBox1 = new GroupBox("User Information");
		let content1 = new StackPanel();
		content1.Orientation = .Vertical;
		content1.Spacing = 5;
		content1.AddChild(new TextBlock("Name: John Doe"));
		content1.AddChild(new TextBlock("Email: john@example.com"));
		content1.AddChild(new TextBlock("Role: Administrator"));
		groupBox1.Content = content1;
		groupBox1.Width = 200;
		groupBox1.Height = 120;

		row.AddChild(groupBox1);

		// Second GroupBox
		let groupBox2 = new GroupBox("Settings");
		let content2 = new StackPanel();
		content2.Orientation = .Vertical;
		content2.Spacing = 5;
		content2.AddChild(new CheckBox("Enable notifications"));
		content2.AddChild(new CheckBox("Auto-save"));
		content2.AddChild(new CheckBox("Dark mode"));
		groupBox2.Content = content2;
		groupBox2.Width = 200;
		groupBox2.Height = 120;

		row.AddChild(groupBox2);

		section.AddChild(row);

		mRoot.AddChild(section);
	}
}
