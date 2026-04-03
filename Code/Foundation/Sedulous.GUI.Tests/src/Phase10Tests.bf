using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI.Tests;

/// Tests for Phase 10: Tab & Navigation Controls
class Phase10Tests
{
	// === TabControl Tests ===

	[Test]
	public static void TabControlDefaultProperties()
	{
		let tabControl = scope TabControl();
		Test.Assert(tabControl.TabCount == 0);
		Test.Assert(tabControl.SelectedIndex == -1);
		Test.Assert(tabControl.SelectedTab == null);
		Test.Assert(tabControl.TabStripPlacement == .Top);
	}

	[Test]
	public static void TabControlAddTab()
	{
		let tabControl = scope TabControl();
		let tab = tabControl.AddTab("Tab 1");

		Test.Assert(tabControl.TabCount == 1);
		Test.Assert(tab != null);
		Test.Assert(tabControl.SelectedIndex == 0);  // First tab auto-selected
		Test.Assert(tabControl.SelectedTab == tab);
	}

	[Test]
	public static void TabControlAddMultipleTabs()
	{
		let tabControl = scope TabControl();
		let tab1 = tabControl.AddTab("Tab 1");
		let tab2 = tabControl.AddTab("Tab 2");
		let tab3 = tabControl.AddTab("Tab 3");

		Test.Assert(tabControl.TabCount == 3);
		Test.Assert(tabControl.GetTab(0) == tab1);
		Test.Assert(tabControl.GetTab(1) == tab2);
		Test.Assert(tabControl.GetTab(2) == tab3);
		Test.Assert(tabControl.SelectedIndex == 0);  // First tab still selected
	}

	[Test]
	public static void TabControlSelectionChanges()
	{
		let tabControl = scope TabControl();
		tabControl.AddTab("Tab 1");
		tabControl.AddTab("Tab 2");
		tabControl.AddTab("Tab 3");

		Test.Assert(tabControl.SelectedIndex == 0);

		tabControl.SelectedIndex = 1;
		Test.Assert(tabControl.SelectedIndex == 1);

		tabControl.SelectedIndex = 2;
		Test.Assert(tabControl.SelectedIndex == 2);
	}

	[Test]
	public static void TabControlSelectionChangedEvent()
	{
		let tabControl = scope TabControl();
		tabControl.AddTab("Tab 1");
		tabControl.AddTab("Tab 2");

		var eventFiredCount = 0;
		tabControl.SelectionChanged.Subscribe(new [&](tc) => {
			eventFiredCount++;
		});

		// Event should fire on selection change (first tab auto-selected during AddTab)
		tabControl.SelectedIndex = 1;
		Test.Assert(eventFiredCount == 1);

		tabControl.SelectedIndex = 0;
		Test.Assert(eventFiredCount == 2);
	}

	[Test]
	public static void TabControlRemoveTab()
	{
		let tabControl = scope TabControl();
		let tab1 = tabControl.AddTab("Tab 1");
		let tab2 = tabControl.AddTab("Tab 2");
		let tab3 = tabControl.AddTab("Tab 3");

		Test.Assert(tabControl.TabCount == 3);

		tabControl.RemoveTab(tab2);
		Test.Assert(tabControl.TabCount == 2);
		Test.Assert(tabControl.GetTab(0) == tab1);
		Test.Assert(tabControl.GetTab(1) == tab3);
	}

	[Test]
	public static void TabControlRemoveSelectedTab()
	{
		let tabControl = scope TabControl();
		tabControl.AddTab("Tab 1");
		let tab2 = tabControl.AddTab("Tab 2");
		tabControl.AddTab("Tab 3");

		tabControl.SelectedIndex = 1;  // Select Tab 2
		Test.Assert(tabControl.SelectedTab == tab2);

		tabControl.RemoveTabAt(1);  // Remove selected tab
		Test.Assert(tabControl.TabCount == 2);
		// Selection should adjust
		Test.Assert(tabControl.SelectedIndex >= 0 && tabControl.SelectedIndex < 2);
	}

	[Test]
	public static void TabControlClearTabs()
	{
		let tabControl = scope TabControl();
		tabControl.AddTab("Tab 1");
		tabControl.AddTab("Tab 2");
		tabControl.AddTab("Tab 3");

		Test.Assert(tabControl.TabCount == 3);

		tabControl.ClearTabs();
		Test.Assert(tabControl.TabCount == 0);
		Test.Assert(tabControl.SelectedIndex == -1);
		Test.Assert(tabControl.SelectedTab == null);
	}

	[Test]
	public static void TabControlNavigateNext()
	{
		let tabControl = scope TabControl();
		tabControl.AddTab("Tab 1");
		tabControl.AddTab("Tab 2");
		tabControl.AddTab("Tab 3");

		tabControl.SelectedIndex = 0;

		tabControl.SelectNextTab();
		Test.Assert(tabControl.SelectedIndex == 1);

		tabControl.SelectNextTab();
		Test.Assert(tabControl.SelectedIndex == 2);

		// Wraps around
		tabControl.SelectNextTab();
		Test.Assert(tabControl.SelectedIndex == 0);
	}

	[Test]
	public static void TabControlNavigatePrevious()
	{
		let tabControl = scope TabControl();
		tabControl.AddTab("Tab 1");
		tabControl.AddTab("Tab 2");
		tabControl.AddTab("Tab 3");

		tabControl.SelectedIndex = 2;

		tabControl.SelectPreviousTab();
		Test.Assert(tabControl.SelectedIndex == 1);

		tabControl.SelectPreviousTab();
		Test.Assert(tabControl.SelectedIndex == 0);

		// Wraps around
		tabControl.SelectPreviousTab();
		Test.Assert(tabControl.SelectedIndex == 2);
	}

	[Test]
	public static void TabControlStripPlacement()
	{
		let tabControl = scope TabControl();
		tabControl.AddTab("Tab 1");

		Test.Assert(tabControl.TabStripPlacement == .Top);

		tabControl.TabStripPlacement = .Bottom;
		Test.Assert(tabControl.TabStripPlacement == .Bottom);

		tabControl.TabStripPlacement = .Left;
		Test.Assert(tabControl.TabStripPlacement == .Left);

		tabControl.TabStripPlacement = .Right;
		Test.Assert(tabControl.TabStripPlacement == .Right);
	}

	// === TabItem Tests ===

	[Test]
	public static void TabItemDefaultProperties()
	{
		let tabItem = scope TabItem();
		Test.Assert(tabItem.Header == null);
		Test.Assert(tabItem.Content == null);
		Test.Assert(tabItem.IsSelected == false);
		Test.Assert(tabItem.IsCloseable == false);
		Test.Assert(tabItem.Index == -1);
	}

	[Test]
	public static void TabItemWithHeader()
	{
		let tabItem = scope TabItem("My Tab");
		Test.Assert(tabItem.Header != null);
		Test.Assert(tabItem.IsSelected == false);
	}

	[Test]
	public static void TabItemWithHeaderAndContent()
	{
		let content = new TextBlock("Content");
		let tabItem = scope TabItem("My Tab", content);
		Test.Assert(tabItem.Header != null);
		Test.Assert(tabItem.Content == content);
	}

	[Test]
	public static void TabItemIsCloseable()
	{
		let tabItem = scope TabItem("Closeable Tab");
		Test.Assert(tabItem.IsCloseable == false);

		tabItem.IsCloseable = true;
		Test.Assert(tabItem.IsCloseable == true);
	}

	// === Expander Tests ===

	[Test]
	public static void ExpanderDefaultProperties()
	{
		let expander = scope Expander();
		Test.Assert(expander.IsExpanded == true);  // Expanded by default
		Test.Assert(expander.Header == null);
		Test.Assert(expander.Content == null);
	}

	[Test]
	public static void ExpanderWithHeader()
	{
		let expander = scope Expander("Click to expand");
		Test.Assert(expander.Header != null);
		Test.Assert(expander.IsExpanded == true);
	}

	[Test]
	public static void ExpanderExpandCollapse()
	{
		let expander = scope Expander("Test");
		let content = new TextBlock("Content");
		expander.Content = content;

		Test.Assert(expander.IsExpanded == true);

		expander.Collapse();
		Test.Assert(expander.IsExpanded == false);

		expander.Expand();
		Test.Assert(expander.IsExpanded == true);
	}

	[Test]
	public static void ExpanderToggle()
	{
		let expander = scope Expander();

		let initialState = expander.IsExpanded;
		expander.Toggle();
		Test.Assert(expander.IsExpanded != initialState);

		expander.Toggle();
		Test.Assert(expander.IsExpanded == initialState);
	}

	[Test]
	public static void ExpanderExpandedChangedEvent()
	{
		let expander = scope Expander();
		let content = new TextBlock("Content");
		expander.Content = content;

		var eventFired = false;
		var newState = true;
		expander.ExpandedChanged.Subscribe(new [&](e, expanded) => {
			eventFired = true;
			newState = expanded;
		});

		expander.Collapse();
		Test.Assert(eventFired);
		Test.Assert(newState == false);

		eventFired = false;
		expander.Expand();
		Test.Assert(eventFired);
		Test.Assert(newState == true);
	}

	// === GroupBox Tests ===

	[Test]
	public static void GroupBoxDefaultProperties()
	{
		let groupBox = scope GroupBox();
		Test.Assert(groupBox.Header == null);
		Test.Assert(groupBox.Content == null);
	}

	[Test]
	public static void GroupBoxWithHeader()
	{
		let groupBox = scope GroupBox("Settings");
		Test.Assert(groupBox.Header != null);
	}

	[Test]
	public static void GroupBoxWithContent()
	{
		let groupBox = scope GroupBox("Settings");
		let content = new TextBlock("Content here");
		groupBox.Content = content;

		Test.Assert(groupBox.Header != null);
		Test.Assert(groupBox.Content == content);
	}

	[Test]
	public static void GroupBoxMeasure()
	{
		let groupBox = scope GroupBox("Title");
		let content = new TextBlock("Content");
		groupBox.Content = content;

		groupBox.Measure(SizeConstraints.FromMaximum(200, 200));

		Test.Assert(groupBox.DesiredSize.Width > 0);
		Test.Assert(groupBox.DesiredSize.Height > 0);
	}

	// === Breadcrumb Tests ===

	[Test]
	public static void BreadcrumbDefaultProperties()
	{
		let breadcrumb = scope Breadcrumb();
		Test.Assert(breadcrumb.ItemCount == 0);
		Test.Assert(breadcrumb.Separator == " > ");
	}

	[Test]
	public static void BreadcrumbAddItems()
	{
		let breadcrumb = scope Breadcrumb();
		breadcrumb.AddItem("Home");
		breadcrumb.AddItem("Documents");
		breadcrumb.AddItem("Projects");

		Test.Assert(breadcrumb.ItemCount == 3);
	}

	[Test]
	public static void BreadcrumbGetItem()
	{
		let breadcrumb = scope Breadcrumb();
		let item1 = breadcrumb.AddItem("Home");
		let item2 = breadcrumb.AddItem("Documents");

		Test.Assert(breadcrumb.GetItem(0) == item1);
		Test.Assert(breadcrumb.GetItem(1) == item2);
		Test.Assert(breadcrumb.GetItem(2) == null);  // Out of range
	}

	[Test]
	public static void BreadcrumbIsLastFlag()
	{
		let breadcrumb = scope Breadcrumb();
		let item1 = breadcrumb.AddItem("Home");
		Test.Assert(item1.IsLast == true);

		let item2 = breadcrumb.AddItem("Documents");
		Test.Assert(item1.IsLast == false);
		Test.Assert(item2.IsLast == true);

		let item3 = breadcrumb.AddItem("Projects");
		Test.Assert(item1.IsLast == false);
		Test.Assert(item2.IsLast == false);
		Test.Assert(item3.IsLast == true);
	}

	[Test]
	public static void BreadcrumbNavigateTo()
	{
		let breadcrumb = scope Breadcrumb();
		breadcrumb.AddItem("Home");
		breadcrumb.AddItem("Documents");
		breadcrumb.AddItem("Projects");
		breadcrumb.AddItem("MyProject");

		Test.Assert(breadcrumb.ItemCount == 4);

		breadcrumb.NavigateTo(1);  // Navigate to "Documents"

		Test.Assert(breadcrumb.ItemCount == 2);  // Only Home and Documents remain
		Test.Assert(breadcrumb.GetItem(1).IsLast == true);
	}

	[Test]
	public static void BreadcrumbRemoveItem()
	{
		let breadcrumb = scope Breadcrumb();
		breadcrumb.AddItem("Home");
		breadcrumb.AddItem("Documents");
		breadcrumb.AddItem("Projects");

		Test.Assert(breadcrumb.ItemCount == 3);

		breadcrumb.RemoveItemAt(1);

		Test.Assert(breadcrumb.ItemCount == 2);
	}

	[Test]
	public static void BreadcrumbClearItems()
	{
		let breadcrumb = scope Breadcrumb();
		breadcrumb.AddItem("Home");
		breadcrumb.AddItem("Documents");
		breadcrumb.AddItem("Projects");

		Test.Assert(breadcrumb.ItemCount == 3);

		breadcrumb.ClearItems();

		Test.Assert(breadcrumb.ItemCount == 0);
	}

	[Test]
	public static void BreadcrumbCustomSeparator()
	{
		let breadcrumb = scope Breadcrumb();
		breadcrumb.Separator = " / ";
		breadcrumb.AddItem("Home");
		breadcrumb.AddItem("Documents");

		Test.Assert(breadcrumb.Separator == " / ");
	}

	[Test]
	public static void BreadcrumbItemWithValue()
	{
		let breadcrumb = scope Breadcrumb();
		let pathValue = scope String("/home/documents");
		let item = breadcrumb.AddItem("Documents", pathValue);

		Test.Assert(item.Value == pathValue);
	}

	[Test]
	public static void BreadcrumbItemClickedEvent()
	{
		let breadcrumb = scope Breadcrumb();
		breadcrumb.AddItem("Home");
		breadcrumb.AddItem("Documents");

		var clickedItem = (BreadcrumbItem)null;
		breadcrumb.ItemClicked.Subscribe(new [&](bc, item) => {
			clickedItem = item;
		});

		// Note: In a real scenario, the click would be triggered by mouse input
		// This test just verifies the event accessor is properly set up
		Test.Assert(breadcrumb.ItemClicked != null);
	}

	// === BreadcrumbItem Tests ===

	[Test]
	public static void BreadcrumbItemDefaultProperties()
	{
		let item = scope BreadcrumbItem();
		Test.Assert(item.Value == null);
		Test.Assert(item.Index == -1);
		Test.Assert(item.IsLast == false);
	}

	[Test]
	public static void BreadcrumbItemWithText()
	{
		let item = scope BreadcrumbItem("Documents");
		Test.Assert(item.Content != null);
	}

	[Test]
	public static void BreadcrumbItemWithTextAndValue()
	{
		let value = scope String("/path/to/docs");
		let item = scope BreadcrumbItem("Documents", value);
		Test.Assert(item.Content != null);
		Test.Assert(item.Value == value);
	}
}
