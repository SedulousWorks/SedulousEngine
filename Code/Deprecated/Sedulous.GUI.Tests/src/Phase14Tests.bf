using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI.Tests;

/// Tests for Phase 14: Docking System
class Phase14Tests
{
	// === DockPosition Tests ===

	[Test]
	public static void DockPositionEnumValues()
	{
		Test.Assert(DockPosition.Left != DockPosition.Right);
		Test.Assert(DockPosition.Top != DockPosition.Bottom);
		Test.Assert(DockPosition.Center != DockPosition.Float);
	}

	// === DockablePanel Tests ===

	[Test]
	public static void DockablePanelDefaultProperties()
	{
		let panel = scope DockablePanel();
		Test.Assert(panel.Title == "");
		Test.Assert(panel.Content == null);
		Test.Assert(panel.IsCloseable == true);
		Test.Assert(panel.IsPinnable == false);
		Test.Assert(panel.IsPinned == false);
		Test.Assert(panel.ParentGroup == null);
		Test.Assert(panel.IsFocusable == false);
	}

	[Test]
	public static void DockablePanelWithTitle()
	{
		let panel = scope DockablePanel("Properties");
		Test.Assert(panel.Title == "Properties");
	}

	[Test]
	public static void DockablePanelWithTitleAndContent()
	{
		let content = new TextBlock("Hello");
		let panel = new DockablePanel("Test", content);
		defer delete panel;  // Panel will delete content
		Test.Assert(panel.Title == "Test");
		Test.Assert(panel.Content == content);
	}

	[Test]
	public static void DockablePanelSetTitle()
	{
		let panel = scope DockablePanel();
		panel.Title = "Explorer";
		Test.Assert(panel.Title == "Explorer");
	}

	[Test]
	public static void DockablePanelCloseableProperty()
	{
		let panel = scope DockablePanel("Test");
		Test.Assert(panel.IsCloseable == true);
		panel.IsCloseable = false;
		Test.Assert(panel.IsCloseable == false);
	}

	[Test]
	public static void DockablePanelPinnableProperty()
	{
		let panel = scope DockablePanel("Test");
		Test.Assert(panel.IsPinnable == false);
		panel.IsPinnable = true;
		Test.Assert(panel.IsPinnable == true);
	}

	[Test]
	public static void DockablePanelPinnedProperty()
	{
		let panel = scope DockablePanel("Test");
		panel.IsPinnable = true;
		Test.Assert(panel.IsPinned == false);
		panel.IsPinned = true;
		Test.Assert(panel.IsPinned == true);
	}

	[Test]
	public static void DockablePanelTitleBarHeight()
	{
		let panel = scope DockablePanel("Test");
		Test.Assert(panel.TitleBarHeight == 24);
		panel.TitleBarHeight = 32;
		Test.Assert(panel.TitleBarHeight == 32);
	}

	// === DockTabGroup Tests ===

	[Test]
	public static void DockTabGroupDefaultProperties()
	{
		let group = scope DockTabGroup();
		Test.Assert(group.PanelCount == 0);
		Test.Assert(group.SelectedIndex == -1);
		Test.Assert(group.SelectedPanel == null);
		Test.Assert(group.IsSinglePanel == false);
		Test.Assert(group.TabHeight == 24);
		Test.Assert(group.Manager == null);
		Test.Assert(group.IsFocusable == false);
	}

	[Test]
	public static void DockTabGroupAddPanel()
	{
		let group = scope DockTabGroup();
		let panel = scope DockablePanel("Test");
		group.AddPanel(panel);
		Test.Assert(group.PanelCount == 1);
		Test.Assert(group.SelectedIndex == 0);
		Test.Assert(group.SelectedPanel == panel);
		Test.Assert(group.IsSinglePanel == true);
		Test.Assert(panel.ParentGroup == group);
	}

	[Test]
	public static void DockTabGroupAddMultiplePanels()
	{
		let group = scope DockTabGroup();
		let panel1 = scope DockablePanel("Panel 1");
		let panel2 = scope DockablePanel("Panel 2");
		let panel3 = scope DockablePanel("Panel 3");
		group.AddPanel(panel1);
		group.AddPanel(panel2);
		group.AddPanel(panel3);
		Test.Assert(group.PanelCount == 3);
		Test.Assert(group.SelectedIndex == 0);
		Test.Assert(group.IsSinglePanel == false);
	}

	[Test]
	public static void DockTabGroupInsertPanel()
	{
		let group = scope DockTabGroup();
		let panel1 = scope DockablePanel("Panel 1");
		let panel2 = scope DockablePanel("Panel 2");
		let panel3 = scope DockablePanel("Panel 3");
		group.AddPanel(panel1);
		group.AddPanel(panel3);
		group.InsertPanel(1, panel2);
		Test.Assert(group.PanelCount == 3);
		Test.Assert(group.GetPanel(0) == panel1);
		Test.Assert(group.GetPanel(1) == panel2);
		Test.Assert(group.GetPanel(2) == panel3);
	}

	[Test]
	public static void DockTabGroupGetPanel()
	{
		let group = scope DockTabGroup();
		let panel1 = scope DockablePanel("Panel 1");
		let panel2 = scope DockablePanel("Panel 2");
		group.AddPanel(panel1);
		group.AddPanel(panel2);
		Test.Assert(group.GetPanel(0) == panel1);
		Test.Assert(group.GetPanel(1) == panel2);
		Test.Assert(group.GetPanel(2) == null);
		Test.Assert(group.GetPanel(-1) == null);
	}

	[Test]
	public static void DockTabGroupSelectedIndex()
	{
		let group = scope DockTabGroup();
		let panel1 = scope DockablePanel("Panel 1");
		let panel2 = scope DockablePanel("Panel 2");
		group.AddPanel(panel1);
		group.AddPanel(panel2);
		Test.Assert(group.SelectedIndex == 0);
		group.SelectedIndex = 1;
		Test.Assert(group.SelectedIndex == 1);
		Test.Assert(group.SelectedPanel == panel2);
	}

	[Test]
	public static void DockTabGroupSelectedIndexClamped()
	{
		let group = scope DockTabGroup();
		let panel = scope DockablePanel("Panel");
		group.AddPanel(panel);
		group.SelectedIndex = 100;
		Test.Assert(group.SelectedIndex == 0);
		group.SelectedIndex = -100;
		Test.Assert(group.SelectedIndex == 0);
	}

	[Test]
	public static void DockTabGroupRemovePanel()
	{
		let group = scope DockTabGroup();
		let panel1 = scope DockablePanel("Panel 1");
		let panel2 = scope DockablePanel("Panel 2");
		group.AddPanel(panel1);
		group.AddPanel(panel2);
		Test.Assert(group.PanelCount == 2);
		let removed = group.RemovePanel(panel1);
		Test.Assert(removed == true);
		Test.Assert(group.PanelCount == 1);
		Test.Assert(group.GetPanel(0) == panel2);
		Test.Assert(panel1.ParentGroup == null);
	}

	[Test]
	public static void DockTabGroupRemovePanelNotFound()
	{
		let group = scope DockTabGroup();
		let panel1 = scope DockablePanel("Panel 1");
		let panel2 = scope DockablePanel("Panel 2");
		group.AddPanel(panel1);
		let removed = group.RemovePanel(panel2);
		Test.Assert(removed == false);
		Test.Assert(group.PanelCount == 1);
	}

	[Test]
	public static void DockTabGroupRemovePanelAt()
	{
		let group = scope DockTabGroup();
		let panel1 = scope DockablePanel("Panel 1");
		let panel2 = scope DockablePanel("Panel 2");
		group.AddPanel(panel1);
		group.AddPanel(panel2);
		group.RemovePanelAt(0);
		Test.Assert(group.PanelCount == 1);
		Test.Assert(group.GetPanel(0) == panel2);
	}

	[Test]
	public static void DockTabGroupTabHeight()
	{
		let group = scope DockTabGroup();
		Test.Assert(group.TabHeight == 24);
		group.TabHeight = 32;
		Test.Assert(group.TabHeight == 32);
	}

	// === DockSplit Tests ===

	[Test]
	public static void DockSplitDefaultProperties()
	{
		let split = new DockSplit();
		defer delete split;
		Test.Assert(split.Orientation == .Horizontal);
		Test.Assert(split.SplitRatio == 0.5f);
		Test.Assert(split.First == null);
		Test.Assert(split.Second == null);
		Test.Assert(split.MinFirstSize == 100);
		Test.Assert(split.MinSecondSize == 100);
		Test.Assert(split.Splitter != null);
		Test.Assert(split.Manager == null);
		Test.Assert(split.ParentSplit == null);
		Test.Assert(split.IsFocusable == false);
	}

	[Test]
	public static void DockSplitWithOrientation()
	{
		let split = new DockSplit(.Vertical);
		defer delete split;
		Test.Assert(split.Orientation == .Vertical);
	}

	[Test]
	public static void DockSplitOrientationChange()
	{
		let split = new DockSplit();
		defer delete split;
		Test.Assert(split.Orientation == .Horizontal);
		split.Orientation = .Vertical;
		Test.Assert(split.Orientation == .Vertical);
	}

	[Test]
	public static void DockSplitRatio()
	{
		let split = new DockSplit();
		defer delete split;
		Test.Assert(split.SplitRatio == 0.5f);
		split.SplitRatio = 0.25f;
		Test.Assert(split.SplitRatio == 0.25f);
	}

	[Test]
	public static void DockSplitRatioClamped()
	{
		let split = new DockSplit();
		defer delete split;
		split.SplitRatio = 1.5f;
		Test.Assert(split.SplitRatio == 1.0f);
		split.SplitRatio = -0.5f;
		Test.Assert(split.SplitRatio == 0.0f);
	}

	[Test]
	public static void DockSplitMinSizes()
	{
		let split = new DockSplit();
		defer delete split;
		split.MinFirstSize = 150;
		split.MinSecondSize = 200;
		Test.Assert(split.MinFirstSize == 150);
		Test.Assert(split.MinSecondSize == 200);
	}

	[Test]
	public static void DockSplitMinSizesClamped()
	{
		let split = new DockSplit();
		defer delete split;
		split.MinFirstSize = 10;  // Should clamp to 50
		Test.Assert(split.MinFirstSize == 50);
	}

	[Test]
	public static void DockSplitSetChildren()
	{
		let split = new DockSplit();
		defer delete split;
		let group1 = new DockTabGroup();
		let group2 = new DockTabGroup();
		split.First = group1;
		split.Second = group2;
		Test.Assert(split.First == group1);
		Test.Assert(split.Second == group2);
		// Clear children before deletion to avoid double-free
		split.First = null;
		split.Second = null;
		delete group1;
		delete group2;
	}

	[Test]
	public static void DockSplitSplitterExists()
	{
		let split = new DockSplit();
		defer delete split;
		Test.Assert(split.Splitter != null);
		Test.Assert(split.Splitter.Thickness == 4);
	}

	// === DockManager Tests ===

	[Test]
	public static void DockManagerDefaultProperties()
	{
		let manager = new DockManager();
		defer delete manager;
		// RootNode starts null until first panel is docked
		Test.Assert(manager.RootNode == null);
		Test.Assert(manager.IsFocusable == false);
	}

	[Test]
	public static void DockManagerCreatesRootOnFirstDock()
	{
		let manager = new DockManager();
		defer delete manager;
		Test.Assert(manager.RootNode == null);
		let panel = scope DockablePanel("Test");
		manager.AddPanel(panel);
		// After adding a panel, root should be a DockTabGroup
		Test.Assert(manager.RootNode is DockTabGroup);
	}

	[Test]
	public static void DockManagerAddPanel()
	{
		let manager = new DockManager();
		defer delete manager;
		let panel = scope DockablePanel("Test");
		manager.AddPanel(panel);
		let rootGroup = manager.RootNode as DockTabGroup;
		Test.Assert(rootGroup != null);
		Test.Assert(rootGroup.PanelCount == 1);
		Test.Assert(rootGroup.GetPanel(0) == panel);
		// Manager will delete panel when destroyed
	}

	[Test]
	public static void DockManagerDockPanelCenter()
	{
		let manager = new DockManager();
		defer delete manager;
		let panel1 = scope DockablePanel("Panel 1");
		let panel2 = scope DockablePanel("Panel 2");
		manager.DockPanel(panel1, .Center);
		manager.DockPanel(panel2, .Center);
		let rootGroup = manager.RootNode as DockTabGroup;
		Test.Assert(rootGroup != null);
		Test.Assert(rootGroup.PanelCount == 2);
	}

	[Test]
	public static void DockManagerDockPanelLeft()
	{
		let manager = new DockManager();
		defer delete manager;
		let panel1 = scope DockablePanel("Center");
		let panel2 = scope DockablePanel("Left");
		manager.DockPanel(panel1, .Center);
		manager.DockPanel(panel2, .Left);
		// Root should now be a split
		Test.Assert(manager.RootNode is DockSplit);
		let split = manager.RootNode as DockSplit;
		Test.Assert(split.Orientation == .Horizontal);
		Test.Assert(split.First is DockTabGroup);
		Test.Assert(split.Second is DockTabGroup);
	}

	[Test]
	public static void DockManagerDockPanelRight()
	{
		let manager = new DockManager();
		defer delete manager;
		let panel1 = scope DockablePanel("Center");
		let panel2 = scope DockablePanel("Right");
		manager.DockPanel(panel1, .Center);
		manager.DockPanel(panel2, .Right);
		Test.Assert(manager.RootNode is DockSplit);
		let split = manager.RootNode as DockSplit;
		Test.Assert(split.Orientation == .Horizontal);
	}

	[Test]
	public static void DockManagerDockPanelTop()
	{
		let manager = new DockManager();
		defer delete manager;
		let panel1 = scope DockablePanel("Center");
		let panel2 = scope DockablePanel("Top");
		manager.DockPanel(panel1, .Center);
		manager.DockPanel(panel2, .Top);
		Test.Assert(manager.RootNode is DockSplit);
		let split = manager.RootNode as DockSplit;
		Test.Assert(split.Orientation == .Vertical);
	}

	[Test]
	public static void DockManagerDockPanelBottom()
	{
		let manager = new DockManager();
		defer delete manager;
		let panel1 = scope DockablePanel("Center");
		let panel2 = scope DockablePanel("Bottom");
		manager.DockPanel(panel1, .Center);
		manager.DockPanel(panel2, .Bottom);
		Test.Assert(manager.RootNode is DockSplit);
		let split = manager.RootNode as DockSplit;
		Test.Assert(split.Orientation == .Vertical);
	}

	[Test]
	public static void DockManagerRemovePanel()
	{
		let manager = new DockManager();
		defer delete manager;
		let panel = scope DockablePanel("Test");
		manager.AddPanel(panel);
		let rootGroup = manager.RootNode as DockTabGroup;
		Test.Assert(rootGroup.PanelCount == 1);
		manager.RemovePanel(panel);
		Test.Assert(rootGroup.PanelCount == 0);
		//delete panel;  // Panel was removed, need to delete manually
	}
}
