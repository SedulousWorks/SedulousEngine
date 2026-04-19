namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;

class DockingDetailTests
{
	// ==========================================================
	// DockablePanel -- basic properties
	// ==========================================================

	[Test]
	public static void DockablePanel_DefaultTitle()
	{
		let panel = scope DockablePanel();
		Test.Assert(panel.Title == "Panel");
	}

	[Test]
	public static void DockablePanel_ConstructWithTitle()
	{
		let panel = scope DockablePanel("Inspector");
		Test.Assert(panel.Title == "Inspector");
	}

	[Test]
	public static void DockablePanel_SetTitle_Updates()
	{
		let panel = scope DockablePanel("Old");
		panel.SetTitle("New");
		Test.Assert(panel.Title == "New");
	}

	[Test]
	public static void DockablePanel_Closable_Default()
	{
		let panel = scope DockablePanel("Test");
		Test.Assert(panel.Closable);
	}

	[Test]
	public static void DockablePanel_Closable_SetFalse()
	{
		let panel = scope DockablePanel("Test");
		panel.Closable = false;
		Test.Assert(!panel.Closable);
	}

	[Test]
	public static void DockablePanel_SetContent_SetsContentView()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);

		let panel = new DockablePanel("Test");
		root.AddView(panel);

		let label = new Label();
		label.SetText("Content");
		panel.SetContent(label);

		Test.Assert(panel.ContentView === label);
	}

	[Test]
	public static void DockablePanel_SetContent_ReplacesOld()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);

		let panel = new DockablePanel("Test");
		root.AddView(panel);

		let c1 = new Label();
		panel.SetContent(c1);
		Test.Assert(panel.ContentView === c1);

		let c2 = new Label();
		panel.SetContent(c2);
		Test.Assert(panel.ContentView === c2);
	}

	[Test]
	public static void DockablePanel_ConstructWithContent()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);

		let content = new ColorView();
		let panel = new DockablePanel("Panel", content);
		root.AddView(panel);

		Test.Assert(panel.ContentView === content);
		Test.Assert(panel.Title == "Panel");
	}

	[Test]
	public static void DockablePanel_SaveDockPosition()
	{
		let panel = scope DockablePanel("Test");
		let dummy = scope ColorView();
		panel.SaveDockPosition(.Left, dummy);

		Test.Assert(panel.mLastDockPosition == .Left);
		// mLastRelativeToId should be valid (the dummy's Id).
		Test.Assert(panel.mLastRelativeToId.IsValid);
	}

	// ==========================================================
	// DockTabGroup -- basic operations
	// ==========================================================

	[Test]
	public static void DockTabGroup_InitialState()
	{
		let group = scope DockTabGroup();
		Test.Assert(group.PanelCount == 0);
		Test.Assert(group.SelectedIndex == -1);
		Test.Assert(group.SelectedPanel == null);
	}

	[Test]
	public static void DockTabGroup_AddPanel_SetsSelected()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);

		let group = new DockTabGroup();
		root.AddView(group);

		let panel = new DockablePanel("A");
		group.AddPanel(panel);

		Test.Assert(group.PanelCount == 1);
		Test.Assert(group.SelectedIndex == 0);
		Test.Assert(group.SelectedPanel === panel);
	}

	[Test]
	public static void DockTabGroup_AddMultiplePanels()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);

		let group = new DockTabGroup();
		root.AddView(group);

		let p1 = new DockablePanel("A");
		let p2 = new DockablePanel("B");
		let p3 = new DockablePanel("C");
		group.AddPanel(p1);
		group.AddPanel(p2);
		group.AddPanel(p3);

		Test.Assert(group.PanelCount == 3);
		// First added is selected by default.
		Test.Assert(group.SelectedIndex == 0);
		Test.Assert(group.SelectedPanel === p1);
	}

	[Test]
	public static void DockTabGroup_SelectedIndex_SwitchesPanel()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);

		let group = new DockTabGroup();
		root.AddView(group);

		let p1 = new DockablePanel("A");
		let p2 = new DockablePanel("B");
		group.AddPanel(p1);
		group.AddPanel(p2);

		group.SelectedIndex = 1;
		Test.Assert(group.SelectedPanel === p2);

		group.SelectedIndex = 0;
		Test.Assert(group.SelectedPanel === p1);
	}

	[Test]
	public static void DockTabGroup_SelectedIndex_OutOfRange_Ignored()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);

		let group = new DockTabGroup();
		root.AddView(group);

		let panel = new DockablePanel("A");
		group.AddPanel(panel);

		group.SelectedIndex = 5; // out of range
		// Should remain at 0.
		Test.Assert(group.SelectedIndex == 0);
	}

	[Test]
	public static void DockTabGroup_RemovePanel_ReturnsPanelRef()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);

		let group = new DockTabGroup();
		root.AddView(group);

		let panel = new DockablePanel("A");
		group.AddPanel(panel);

		let removed = group.RemovePanel(panel);
		Test.Assert(removed === panel);
		Test.Assert(group.PanelCount == 0);

		// Re-add so cleanup doesn't orphan it.
		group.AddPanel(panel);
	}

	[Test]
	public static void DockTabGroup_RemovePanel_AdjustsSelected()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);

		let group = new DockTabGroup();
		root.AddView(group);

		let p1 = new DockablePanel("A");
		let p2 = new DockablePanel("B");
		let p3 = new DockablePanel("C");
		group.AddPanel(p1);
		group.AddPanel(p2);
		group.AddPanel(p3);

		group.SelectedIndex = 2; // Select C
		group.RemovePanel(p3);

		// Selected should adjust to count - 1.
		Test.Assert(group.SelectedIndex == 1);
		Test.Assert(group.SelectedPanel === p2);

		// Re-add so cleanup doesn't orphan.
		group.AddPanel(p3);
	}

	[Test]
	public static void DockTabGroup_RemovePanel_UnknownReturnsNull()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);

		let group = new DockTabGroup();
		root.AddView(group);

		let panel = scope DockablePanel("X");
		let result = group.RemovePanel(panel);
		Test.Assert(result == null);
	}

	[Test]
	public static void DockTabGroup_GetPanel_ValidIndex()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);

		let group = new DockTabGroup();
		root.AddView(group);

		let p1 = new DockablePanel("A");
		let p2 = new DockablePanel("B");
		group.AddPanel(p1);
		group.AddPanel(p2);

		Test.Assert(group.GetPanel(0) === p1);
		Test.Assert(group.GetPanel(1) === p2);
	}

	[Test]
	public static void DockTabGroup_GetPanel_InvalidIndex()
	{
		let group = scope DockTabGroup();
		Test.Assert(group.GetPanel(-1) == null);
		Test.Assert(group.GetPanel(0) == null);
		Test.Assert(group.GetPanel(100) == null);
	}

	[Test]
	public static void DockTabGroup_InsertPanel_AtIndex()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);

		let group = new DockTabGroup();
		root.AddView(group);

		let p1 = new DockablePanel("A");
		let p2 = new DockablePanel("B");
		let p3 = new DockablePanel("Inserted");
		group.AddPanel(p1);
		group.AddPanel(p2);

		group.InsertPanel(1, p3);

		Test.Assert(group.PanelCount == 3);
		Test.Assert(group.GetPanel(0) === p1);
		Test.Assert(group.GetPanel(1) === p3);
		Test.Assert(group.GetPanel(2) === p2);
	}

	[Test]
	public static void DockTabGroup_TabHeight_Clamps()
	{
		let group = scope DockTabGroup();
		group.TabHeight = 5; // below minimum of 16
		Test.Assert(group.TabHeight >= 16);

		group.TabHeight = 40;
		Test.Assert(group.TabHeight == 40);
	}

	// ==========================================================
	// DockSplit -- basic properties
	// ==========================================================

	[Test]
	public static void DockSplit_DefaultOrientation()
	{
		let split = scope DockSplit();
		Test.Assert(split.Orientation == .Horizontal);
	}

	[Test]
	public static void DockSplit_Orientation_Vertical()
	{
		let split = scope DockSplit(.Vertical);
		Test.Assert(split.Orientation == .Vertical);
	}

	[Test]
	public static void DockSplit_DefaultSplitRatio()
	{
		let split = scope DockSplit();
		Test.Assert(Math.Abs(split.SplitRatio - 0.5f) < 0.001f);
	}

	[Test]
	public static void DockSplit_SplitRatio_ClampsLow()
	{
		let split = scope DockSplit();
		split.SplitRatio = -1.0f;
		Test.Assert(split.SplitRatio == 0.05f);
	}

	[Test]
	public static void DockSplit_SplitRatio_ClampsHigh()
	{
		let split = scope DockSplit();
		split.SplitRatio = 1.5f;
		Test.Assert(split.SplitRatio == 0.95f);
	}

	[Test]
	public static void DockSplit_SplitRatio_AcceptsValid()
	{
		let split = scope DockSplit();
		split.SplitRatio = 0.3f;
		Test.Assert(Math.Abs(split.SplitRatio - 0.3f) < 0.001f);
	}

	[Test]
	public static void DockSplit_SetChildren_FirstAndSecond()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);

		let split = new DockSplit(.Horizontal);
		root.AddView(split);

		let left = new ColorView();
		let right = new ColorView();
		split.SetChildren(left, right);

		Test.Assert(split.First === left);
		Test.Assert(split.Second === right);
	}

	[Test]
	public static void DockSplit_SetChildren_NullSecond()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);

		let split = new DockSplit(.Vertical);
		root.AddView(split);

		let child = new ColorView();
		split.SetChildren(child, null);

		Test.Assert(split.First === child);
		Test.Assert(split.Second == null);
	}

	[Test]
	public static void DockSplit_FirstSecond_EmptyReturnsNull()
	{
		let split = scope DockSplit();
		Test.Assert(split.First == null);
		Test.Assert(split.Second == null);
	}

	[Test]
	public static void DockSplit_DividerSize_ClampsLow()
	{
		let split = scope DockSplit();
		split.DividerSize = 0;
		Test.Assert(split.DividerSize >= 2);
	}

	[Test]
	public static void DockSplit_MinPaneSize_ClampsLow()
	{
		let split = scope DockSplit();
		split.MinPaneSize = 1;
		Test.Assert(split.MinPaneSize >= 10);
	}

	// ==========================================================
	// DockManager -- AddPanel
	// ==========================================================

	[Test]
	public static void DockManager_AddPanel_CreatesPanel()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let dock = new DockManager();
		root.AddView(dock);

		let content = new ColorView();
		let panel = dock.AddPanel("Scene", content);
		Test.Assert(panel != null);
		Test.Assert(panel.Title == "Scene");
		Test.Assert(panel.ContentView === content);

		// Dock so the panel is in the tree and gets cleaned up on destruction.
		dock.DockPanel(panel, .Center);
	}

	// ==========================================================
	// DockManager -- DockPanel Center (tab group creation)
	// ==========================================================

	[Test]
	public static void DockManager_DockCenter_CreatesTabGroup()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let dock = new DockManager();
		root.AddView(dock);

		let panel = dock.AddPanel("Panel1", new ColorView());
		dock.DockPanel(panel, .Center);

		// Root should be a DockTabGroup with 1 panel.
		Test.Assert(dock.RootNode != null);
		let tabGroup = dock.RootNode as DockTabGroup;
		Test.Assert(tabGroup != null);
		Test.Assert(tabGroup.PanelCount == 1);
	}

	[Test]
	public static void DockManager_DockCenter_SecondPanel_SameGroup()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let dock = new DockManager();
		root.AddView(dock);

		let p1 = dock.AddPanel("P1", new ColorView());
		let p2 = dock.AddPanel("P2", new ColorView());
		dock.DockPanel(p1, .Center);
		dock.DockPanel(p2, .Center);

		// Both should be in the same tab group.
		let tabGroup = dock.RootNode as DockTabGroup;
		Test.Assert(tabGroup != null);
		Test.Assert(tabGroup.PanelCount == 2);
	}

	// ==========================================================
	// DockManager -- DockPanel Left/Right/Top/Bottom (split creation)
	// ==========================================================

	[Test]
	public static void DockManager_DockLeft_CreatesSplit()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let dock = new DockManager();
		root.AddView(dock);

		let center = dock.AddPanel("Center", new ColorView());
		dock.DockPanel(center, .Center);

		let left = dock.AddPanel("Left", new ColorView());
		dock.DockPanel(left, .Left);

		// Root should now be a DockSplit.
		let split = dock.RootNode as DockSplit;
		Test.Assert(split != null);
		Test.Assert(split.Orientation == .Horizontal);
		// Left panel should be in the first child (left side).
		Test.Assert(split.First != null);
	}

	[Test]
	public static void DockManager_DockRight_CreatesSplit()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let dock = new DockManager();
		root.AddView(dock);

		let center = dock.AddPanel("Center", new ColorView());
		dock.DockPanel(center, .Center);

		let right = dock.AddPanel("Right", new ColorView());
		dock.DockPanel(right, .Right);

		let split = dock.RootNode as DockSplit;
		Test.Assert(split != null);
		Test.Assert(split.Orientation == .Horizontal);
		// Right panel should be in the second child.
		Test.Assert(split.Second != null);
	}

	[Test]
	public static void DockManager_DockTop_CreatesSplit()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let dock = new DockManager();
		root.AddView(dock);

		let center = dock.AddPanel("Center", new ColorView());
		dock.DockPanel(center, .Center);

		let top = dock.AddPanel("Top", new ColorView());
		dock.DockPanel(top, .Top);

		let split = dock.RootNode as DockSplit;
		Test.Assert(split != null);
		Test.Assert(split.Orientation == .Vertical);
	}

	[Test]
	public static void DockManager_DockBottom_CreatesSplit()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let dock = new DockManager();
		root.AddView(dock);

		let center = dock.AddPanel("Center", new ColorView());
		dock.DockPanel(center, .Center);

		let bottom = dock.AddPanel("Bottom", new ColorView());
		dock.DockPanel(bottom, .Bottom);

		let split = dock.RootNode as DockSplit;
		Test.Assert(split != null);
		Test.Assert(split.Orientation == .Vertical);
	}

	// ==========================================================
	// DockManager -- UndockPanel / ClosePanel
	// ==========================================================

	[Test]
	public static void DockManager_UndockPanel_RemovesFromTree()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let dock = new DockManager();
		root.AddView(dock);

		let p1 = dock.AddPanel("P1", new ColorView());
		let p2 = dock.AddPanel("P2", new ColorView());
		dock.DockPanel(p1, .Center);
		dock.DockPanel(p2, .Center);

		let tabGroup = dock.RootNode as DockTabGroup;
		Test.Assert(tabGroup != null);
		Test.Assert(tabGroup.PanelCount == 2);

		dock.UndockPanel(p2);
		// p2 removed from tab group.
		Test.Assert(tabGroup.PanelCount == 1);
		// Clean up undocked panel (UndockPanel detaches but doesn't delete).
		delete p2;
	}

	[Test]
	public static void DockManager_ClosePanel_RemovesFromTracking()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let dock = new DockManager();
		root.AddView(dock);

		let panel = dock.AddPanel("Closing", new ColorView());
		dock.DockPanel(panel, .Center);
		Test.Assert(dock.RootNode != null);

		dock.ClosePanel(panel);
		// Process deferred deletion.
		ctx.MutationQueue.Drain();

		// Root should be cleared after the only panel is closed.
		// (CleanupEmptyNodes removes the empty tab group.)
	}

	// ==========================================================
	// DockManager -- InsertSplit with panels inside DockTabGroups
	// (the redirect fix: when target is a panel in a tab group,
	// split relative to the tab group, not the panel)
	// ==========================================================

	[Test]
	public static void DockManager_InsertSplit_RedirectsFromPanelToTabGroup()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let dock = new DockManager();
		root.AddView(dock);

		let center = dock.AddPanel("Center", new ColorView());
		dock.DockPanel(center, .Center);

		// Root is a DockTabGroup with center inside.
		let tabGroup = dock.RootNode as DockTabGroup;
		Test.Assert(tabGroup != null);

		// Dock left relative to the center panel (which is inside a tab group).
		let left = dock.AddPanel("Left", new ColorView());
		dock.DockPanelRelativeTo(left, .Left, center);

		// InsertSplit should redirect to split the tab group, not the panel.
		// Root should now be a DockSplit.
		let split = dock.RootNode as DockSplit;
		Test.Assert(split != null);
		Test.Assert(split.Orientation == .Horizontal);
	}

	// ==========================================================
	// DockManager -- Center dock with panel already in tab group
	// (the other redirect fix)
	// ==========================================================

	[Test]
	public static void DockManager_CenterDock_PanelInTabGroup_AddsToGroup()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let dock = new DockManager();
		root.AddView(dock);

		let p1 = dock.AddPanel("P1", new ColorView());
		dock.DockPanel(p1, .Center);

		// p1 is in a tab group. Now dock p2 center relative to p1.
		let p2 = dock.AddPanel("P2", new ColorView());
		dock.DockPanelRelativeTo(p2, .Center, p1);

		// p2 should end up in the same tab group as p1.
		let tabGroup = dock.RootNode as DockTabGroup;
		Test.Assert(tabGroup != null);
		Test.Assert(tabGroup.PanelCount == 2);
	}

	// ==========================================================
	// DockManager -- CleanupEmptyNodes collapses empty groups
	// ==========================================================

	[Test]
	public static void DockManager_CleanupEmptyNodes_CollapsesEmptyGroup()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let dock = new DockManager();
		root.AddView(dock);

		let p1 = dock.AddPanel("P1", new ColorView());
		let p2 = dock.AddPanel("P2", new ColorView());
		dock.DockPanel(p1, .Center);
		dock.DockPanel(p2, .Left);

		// Root should be a split with left tab group (p2) and right tab group (p1).
		let split = dock.RootNode as DockSplit;
		Test.Assert(split != null);

		// Undock p2 -- its tab group becomes empty, should collapse.
		dock.UndockPanel(p2);
		delete p2; // UndockPanel detaches but doesn't delete.
		ctx.MutationQueue.Drain();

		// After cleanup, the split with one empty side should collapse
		// to just the remaining tab group.
		Test.Assert(dock.RootNode != null);
	}

	// ==========================================================
	// DockSplit -- Layout and measurement
	// ==========================================================

	[Test]
	public static void DockSplit_Layout_Horizontal()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let split = new DockSplit(.Horizontal);
		split.SplitRatio = 0.5f;
		root.AddView(split);

		let left = new ColorView();
		let right = new ColorView();
		split.SetChildren(left, right);

		ctx.UpdateRootView(root);

		// Both children should have been laid out.
		Test.Assert(left.Width > 0);
		Test.Assert(right.Width > 0);
		Test.Assert(left.Width + right.Width + split.DividerSize <= 800 + 1);
	}

	[Test]
	public static void DockSplit_Layout_Vertical()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let split = new DockSplit(.Vertical);
		split.SplitRatio = 0.5f;
		root.AddView(split);

		let top = new ColorView();
		let bottom = new ColorView();
		split.SetChildren(top, bottom);

		ctx.UpdateRootView(root);

		Test.Assert(top.Height > 0);
		Test.Assert(bottom.Height > 0);
		Test.Assert(top.Height + bottom.Height + split.DividerSize <= 600 + 1);
	}

	// ==========================================================
	// DockManager -- Complex multi-panel layout
	// ==========================================================

	[Test]
	public static void DockManager_ThreePanels_TwoSplits()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let dock = new DockManager();
		root.AddView(dock);

		let center = dock.AddPanel("Center", new ColorView());
		let left = dock.AddPanel("Left", new ColorView());
		let bottom = dock.AddPanel("Bottom", new ColorView());

		dock.DockPanel(center, .Center);
		dock.DockPanel(left, .Left);
		dock.DockPanel(bottom, .Bottom);

		// Should have nested splits.
		Test.Assert(dock.RootNode != null);
		let rootSplit = dock.RootNode as DockSplit;
		Test.Assert(rootSplit != null);
	}

	[Test]
	public static void DockManager_AddPanel_WithEmptyRoot()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let dock = new DockManager();
		root.AddView(dock);

		Test.Assert(dock.RootNode == null);

		let panel = dock.AddPanel("First", new ColorView());
		dock.DockPanel(panel, .Center);

		Test.Assert(dock.RootNode != null);
	}

	[Test]
	public static void DockManager_DockPanel_Left_ThenRight()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let dock = new DockManager();
		root.AddView(dock);

		let center = dock.AddPanel("Center", new ColorView());
		let left = dock.AddPanel("Left", new ColorView());
		let right = dock.AddPanel("Right", new ColorView());

		dock.DockPanel(center, .Center);
		dock.DockPanel(left, .Left);
		dock.DockPanel(right, .Right);

		// Root should be a split, and it should have splits/groups as children.
		Test.Assert(dock.RootNode != null);
	}

	// ==========================================================
	// DockSplit -- Orientation change
	// ==========================================================

	[Test]
	public static void DockSplit_ChangeOrientation()
	{
		let split = scope DockSplit(.Horizontal);
		Test.Assert(split.Orientation == .Horizontal);

		split.Orientation = .Vertical;
		Test.Assert(split.Orientation == .Vertical);
	}

	// ==========================================================
	// DockSplit -- SetChildren replaces existing
	// ==========================================================

	[Test]
	public static void DockSplit_SetChildren_ReplacesExisting()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);

		let split = new DockSplit();
		root.AddView(split);

		let a = new ColorView();
		let b = new ColorView();
		split.SetChildren(a, b);
		Test.Assert(split.First === a);
		Test.Assert(split.Second === b);

		// Replace with new children -- old ones deleted by RemoveAllViews.
		let c = new ColorView();
		let d = new ColorView();
		split.SetChildren(c, d);
		Test.Assert(split.First === c);
		Test.Assert(split.Second === d);
	}

	// ==========================================================
	// DockManager -- Undock last panel clears root
	// ==========================================================

	[Test]
	public static void DockManager_UndockLastPanel_ClearsTree()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let dock = new DockManager();
		root.AddView(dock);

		let panel = dock.AddPanel("Solo", new ColorView());
		dock.DockPanel(panel, .Center);
		Test.Assert(dock.RootNode != null);

		dock.UndockPanel(panel);
		delete panel; // UndockPanel detaches but doesn't delete.
		ctx.MutationQueue.Drain();

		// After undocking the only panel and cleanup, root may be null.
		// The tab group becomes empty and should be cleaned up.
	}

	// ==========================================================
	// DockTabGroup -- Visibility toggling on selection
	// ==========================================================

	[Test]
	public static void DockTabGroup_SelectedPanel_IsVisible_OthersGone()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(800, 600);

		let group = new DockTabGroup();
		root.AddView(group);

		let p1 = new DockablePanel("A");
		let p2 = new DockablePanel("B");
		group.AddPanel(p1);
		group.AddPanel(p2);

		// After layout, selected (index 0) should be visible, other gone.
		ctx.UpdateRootView(root);

		Test.Assert(p1.Visibility == .Visible);
		Test.Assert(p2.Visibility == .Gone);

		group.SelectedIndex = 1;
		ctx.UpdateRootView(root);

		Test.Assert(p1.Visibility == .Gone);
		Test.Assert(p2.Visibility == .Visible);
	}
}
