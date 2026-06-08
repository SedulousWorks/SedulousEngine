namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.GUI.Toolkit;

class DockPersistenceTests
{
	// === PersistenceId ===

	[Test]
	public static void PersistenceId_DefaultEmpty()
	{
		let panel = scope DockablePanel("Test");
		Test.Assert(panel.PersistenceId.Length == 0);
	}

	[Test]
	public static void PersistenceId_SetAndGet()
	{
		let panel = scope DockablePanel("Test");
		panel.SetPersistenceId("my_panel");
		Test.Assert(panel.PersistenceId == "my_panel");
	}

	[Test]
	public static void FindPanelById_Found()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		root.ViewportSize = .(800, 600);
		ctx.AddRootView(root);

		let dm = new DockManager();
		root.AddView(dm);

		let panel = dm.AddPanel("Assets", new Label("Content"));
		panel.SetPersistenceId("assets");
		dm.DockPanel(panel, .Center);

		let found = dm.FindPanelById("assets");
		Test.Assert(found === panel);
	}

	[Test]
	public static void FindPanelById_NotFound()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		root.ViewportSize = .(800, 600);
		ctx.AddRootView(root);

		let dm = new DockManager();
		root.AddView(dm);

		let panel = dm.AddPanel("Assets", new Label("Content"));
		panel.SetPersistenceId("assets");
		dm.DockPanel(panel, .Center);

		Test.Assert(dm.FindPanelById("nonexistent") == null);
	}

	// === ExportLayout ===

	[Test]
	public static void ExportLayout_EmptyTree_ReturnsNull()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		root.ViewportSize = .(800, 600);
		ctx.AddRootView(root);

		let dm = new DockManager();
		root.AddView(dm);

		let layout = dm.ExportLayout();
		Test.Assert(layout == null);
	}

	[Test]
	public static void ExportLayout_SinglePanel()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		root.ViewportSize = .(800, 600);
		ctx.AddRootView(root);

		let dm = new DockManager();
		root.AddView(dm);

		let panel = dm.AddPanel("Assets", new Label("Content"));
		panel.SetPersistenceId("assets");
		dm.DockPanel(panel, .Center);

		let layout = dm.ExportLayout();
		defer delete layout;

		Test.Assert(layout != null);
		Test.Assert(layout.Type == .TabGroup);
		Test.Assert(layout.PanelIds.Count == 1);
		Test.Assert(layout.PanelIds[0] == "assets");
		Test.Assert(layout.ActiveTabIndex == 0);
	}

	[Test]
	public static void ExportLayout_TwoTabs()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		root.ViewportSize = .(800, 600);
		ctx.AddRootView(root);

		let dm = new DockManager();
		root.AddView(dm);

		let p1 = dm.AddPanel("Assets", new Label("C1"));
		p1.SetPersistenceId("assets");
		let p2 = dm.AddPanel("Console", new Label("C2"));
		p2.SetPersistenceId("console");

		dm.DockPanel(p1, .Center);
		dm.DockPanelRelativeTo(p2, .Center, p1.Parent);

		let layout = dm.ExportLayout();
		defer delete layout;

		Test.Assert(layout != null);
		Test.Assert(layout.Type == .TabGroup);
		Test.Assert(layout.PanelIds.Count == 2);
		Test.Assert(layout.PanelIds[0] == "assets");
		Test.Assert(layout.PanelIds[1] == "console");
	}

	[Test]
	public static void ExportLayout_HorizontalSplit()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		root.ViewportSize = .(800, 600);
		ctx.AddRootView(root);

		let dm = new DockManager();
		root.AddView(dm);

		let p1 = dm.AddPanel("Left", new Label("L"));
		p1.SetPersistenceId("left");
		let p2 = dm.AddPanel("Right", new Label("R"));
		p2.SetPersistenceId("right");

		dm.DockPanel(p1, .Center);
		dm.DockPanel(p2, .Right);

		let layout = dm.ExportLayout();
		defer delete layout;

		Test.Assert(layout != null);
		Test.Assert(layout.Type == .Split);
		Test.Assert(layout.Direction == .Horizontal);
		Test.Assert(layout.First != null);
		Test.Assert(layout.Second != null);
		Test.Assert(layout.First.Type == .TabGroup);
		Test.Assert(layout.Second.Type == .TabGroup);
		Test.Assert(layout.First.PanelIds[0] == "left");
		Test.Assert(layout.Second.PanelIds[0] == "right");
	}

	[Test]
	public static void ExportLayout_PreservesSplitRatio()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		root.ViewportSize = .(800, 600);
		ctx.AddRootView(root);

		let dm = new DockManager();
		root.AddView(dm);

		let p1 = dm.AddPanel("Left", new Label("L"));
		p1.SetPersistenceId("left");
		let p2 = dm.AddPanel("Right", new Label("R"));
		p2.SetPersistenceId("right");

		dm.DockPanel(p1, .Center);
		dm.DockPanel(p2, .Right);

		// Adjust split ratio
		if (let split = dm.[Friend]mRootNode as DockSplit)
			split.SplitRatio = 0.3f;

		let layout = dm.ExportLayout();
		defer delete layout;

		Test.Assert(Math.Abs(layout.SplitRatio - 0.3f) < 0.01f);
	}

	[Test]
	public static void ExportLayout_NestedSplit()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		root.ViewportSize = .(800, 600);
		ctx.AddRootView(root);

		let dm = new DockManager();
		root.AddView(dm);

		let p1 = dm.AddPanel("Editor", new Label("E"));
		p1.SetPersistenceId("editor");
		let p2 = dm.AddPanel("Assets", new Label("A"));
		p2.SetPersistenceId("assets");
		let p3 = dm.AddPanel("Inspector", new Label("I"));
		p3.SetPersistenceId("inspector");

		dm.DockPanel(p1, .Center);
		dm.DockPanel(p2, .Bottom);
		dm.DockPanel(p3, .Right);

		let layout = dm.ExportLayout();
		defer delete layout;

		Test.Assert(layout != null);
		Test.Assert(layout.Type == .Split);

		// Should be a nested split tree with all 3 panels
		int panelCount = CountPanels(layout);
		Test.Assert(panelCount == 3);
	}

	// === ApplyLayout ===

	[Test]
	public static void ApplyLayout_SinglePanel()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		root.ViewportSize = .(800, 600);
		ctx.AddRootView(root);

		let dm = new DockManager();
		root.AddView(dm);

		let panel = dm.AddPanel("Assets", new Label("Content"));
		panel.SetPersistenceId("assets");

		// Build layout manually
		let layout = new DockLayoutNode();
		layout.Type = .TabGroup;
		layout.PanelIds.Add(new String("assets"));
		layout.ActiveTabIndex = 0;
		defer delete layout;

		dm.ApplyLayout(layout);

		// Panel should be docked
		Test.Assert(panel.Parent != null);
		Test.Assert(dm.[Friend]mRootNode != null);
	}

	[Test]
	public static void ApplyLayout_TwoTabs()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		root.ViewportSize = .(800, 600);
		ctx.AddRootView(root);

		let dm = new DockManager();
		root.AddView(dm);

		let p1 = dm.AddPanel("Assets", new Label("C1"));
		p1.SetPersistenceId("assets");
		let p2 = dm.AddPanel("Console", new Label("C2"));
		p2.SetPersistenceId("console");

		let layout = new DockLayoutNode();
		layout.Type = .TabGroup;
		layout.PanelIds.Add(new String("assets"));
		layout.PanelIds.Add(new String("console"));
		layout.ActiveTabIndex = 1;
		defer delete layout;

		dm.ApplyLayout(layout);

		Test.Assert(dm.[Friend]mRootNode is DockTabGroup);
		let group = dm.[Friend]mRootNode as DockTabGroup;
		Test.Assert(group.PanelCount == 2);
		Test.Assert(group.SelectedIndex == 1);
	}

	[Test]
	public static void ApplyLayout_Split()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		root.ViewportSize = .(800, 600);
		ctx.AddRootView(root);

		let dm = new DockManager();
		root.AddView(dm);

		let p1 = dm.AddPanel("Left", new Label("L"));
		p1.SetPersistenceId("left");
		let p2 = dm.AddPanel("Right", new Label("R"));
		p2.SetPersistenceId("right");

		let layout = new DockLayoutNode();
		layout.Type = .Split;
		layout.Direction = .Horizontal;
		layout.SplitRatio = 0.7f;

		let firstNode = new DockLayoutNode();
		firstNode.Type = .TabGroup;
		firstNode.PanelIds.Add(new String("left"));
		layout.First = firstNode;

		let secondNode = new DockLayoutNode();
		secondNode.Type = .TabGroup;
		secondNode.PanelIds.Add(new String("right"));
		layout.Second = secondNode;
		defer delete layout;

		dm.ApplyLayout(layout);

		Test.Assert(dm.[Friend]mRootNode is DockSplit);
		let split = dm.[Friend]mRootNode as DockSplit;
		Test.Assert(split.Orientation == .Horizontal);
		Test.Assert(Math.Abs(split.SplitRatio - 0.7f) < 0.01f);
		Test.Assert(split.First is DockTabGroup);
		Test.Assert(split.Second is DockTabGroup);
	}

	[Test]
	public static void ApplyLayout_UnknownPanelId_Skipped()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		root.ViewportSize = .(800, 600);
		ctx.AddRootView(root);

		let dm = new DockManager();
		root.AddView(dm);

		let panel = dm.AddPanel("Assets", new Label("Content"));
		panel.SetPersistenceId("assets");

		let layout = new DockLayoutNode();
		layout.Type = .TabGroup;
		layout.PanelIds.Add(new String("nonexistent"));
		layout.PanelIds.Add(new String("assets"));
		defer delete layout;

		dm.ApplyLayout(layout);

		// Only the known panel should be docked
		Test.Assert(dm.[Friend]mRootNode is DockTabGroup);
		let group = dm.[Friend]mRootNode as DockTabGroup;
		Test.Assert(group.PanelCount == 1);
	}

	[Test]
	public static void ApplyLayout_EmptySplitBranch_Collapsed()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		root.ViewportSize = .(800, 600);
		ctx.AddRootView(root);

		let dm = new DockManager();
		root.AddView(dm);

		let panel = dm.AddPanel("Only", new Label("O"));
		panel.SetPersistenceId("only");

		// Layout has a split but one side references unknown panels
		let layout = new DockLayoutNode();
		layout.Type = .Split;
		layout.Direction = .Horizontal;
		layout.SplitRatio = 0.5f;

		let firstNode = new DockLayoutNode();
		firstNode.Type = .TabGroup;
		firstNode.PanelIds.Add(new String("only"));
		layout.First = firstNode;

		let secondNode = new DockLayoutNode();
		secondNode.Type = .TabGroup;
		secondNode.PanelIds.Add(new String("gone"));
		layout.Second = secondNode;
		defer delete layout;

		dm.ApplyLayout(layout);

		// Split should collapse since second is empty
		Test.Assert(dm.[Friend]mRootNode is DockTabGroup);
	}

	// === Roundtrip (Export -> Apply) ===

	[Test]
	public static void Roundtrip_SinglePanel()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		root.ViewportSize = .(800, 600);
		ctx.AddRootView(root);

		let dm = new DockManager();
		root.AddView(dm);

		let panel = dm.AddPanel("Assets", new Label("Content"));
		panel.SetPersistenceId("assets");
		dm.DockPanel(panel, .Center);

		let layout = dm.ExportLayout();
		defer delete layout;

		dm.ApplyLayout(layout);

		Test.Assert(panel.Parent != null);
		Test.Assert(dm.[Friend]mRootNode != null);
	}

	[Test]
	public static void Roundtrip_ComplexLayout()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		root.ViewportSize = .(800, 600);
		ctx.AddRootView(root);

		let dm = new DockManager();
		root.AddView(dm);

		let p1 = dm.AddPanel("Editor", new Label("E"));
		p1.SetPersistenceId("editor");
		let p2 = dm.AddPanel("Assets", new Label("A"));
		p2.SetPersistenceId("assets");
		let p3 = dm.AddPanel("Console", new Label("C"));
		p3.SetPersistenceId("console");
		let p4 = dm.AddPanel("Inspector", new Label("I"));
		p4.SetPersistenceId("inspector");

		dm.DockPanel(p1, .Center);
		dm.DockPanel(p2, .Bottom);
		dm.DockPanelRelativeTo(p3, .Center, p2.Parent); // Tab with Assets
		dm.DockPanel(p4, .Right);

		// Export
		let layout = dm.ExportLayout();
		defer delete layout;

		let originalPanelCount = CountPanels(layout);

		// Apply (rebuilds tree)
		dm.ApplyLayout(layout);

		// Export again and verify structure matches
		let layout2 = dm.ExportLayout();
		defer delete layout2;

		Test.Assert(layout2 != null);
		Test.Assert(CountPanels(layout2) == originalPanelCount);
	}

	[Test]
	public static void Roundtrip_PreservesSplitRatio()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		root.ViewportSize = .(800, 600);
		ctx.AddRootView(root);

		let dm = new DockManager();
		root.AddView(dm);

		let p1 = dm.AddPanel("Left", new Label("L"));
		p1.SetPersistenceId("left");
		let p2 = dm.AddPanel("Right", new Label("R"));
		p2.SetPersistenceId("right");

		dm.DockPanel(p1, .Center);
		dm.DockPanel(p2, .Right);

		if (let split = dm.[Friend]mRootNode as DockSplit)
			split.SplitRatio = 0.35f;

		let layout = dm.ExportLayout();
		defer delete layout;

		dm.ApplyLayout(layout);

		let layout2 = dm.ExportLayout();
		defer delete layout2;

		Test.Assert(layout2.Type == .Split);
		Test.Assert(Math.Abs(layout2.SplitRatio - 0.35f) < 0.01f);
	}

	[Test]
	public static void Roundtrip_PreservesActiveTab()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		root.ViewportSize = .(800, 600);
		ctx.AddRootView(root);

		let dm = new DockManager();
		root.AddView(dm);

		let p1 = dm.AddPanel("Assets", new Label("A"));
		p1.SetPersistenceId("assets");
		let p2 = dm.AddPanel("Console", new Label("C"));
		p2.SetPersistenceId("console");

		dm.DockPanel(p1, .Center);
		dm.DockPanelRelativeTo(p2, .Center, p1.Parent);

		// Select second tab
		if (let group = dm.[Friend]mRootNode as DockTabGroup)
			group.SelectedIndex = 1;

		let layout = dm.ExportLayout();
		defer delete layout;

		dm.ApplyLayout(layout);

		if (let group = dm.[Friend]mRootNode as DockTabGroup)
			Test.Assert(group.SelectedIndex == 1);
	}

	// === Helpers ===

	private static int CountPanels(DockLayoutNode node)
	{
		if (node == null) return 0;

		if (node.Type == .TabGroup)
			return node.PanelIds.Count;

		return CountPanels(node.First) + CountPanels(node.Second);
	}
}
