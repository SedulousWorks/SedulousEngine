namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.GUI.Toolkit;

class DockingTests
{
	[Test]
	public static void DockablePanel_Title()
	{
		let panel = scope DockablePanel("My Panel");
		Test.Assert(panel.Title == "My Panel");

		panel.SetTitle("Renamed");
		Test.Assert(panel.Title == "Renamed");
	}

	[Test]
	public static void DockablePanel_SetContent()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		let panel = new DockablePanel("Test");
		root.AddView(panel);

		let content = new Label();
		panel.SetContent(content);
		Test.Assert(panel.ContentView === content);
	}

	[Test]
	public static void DockSplit_RatioClamping()
	{
		let split = scope DockSplit();
		split.SplitRatio = -1;
		Test.Assert(split.SplitRatio >= 0.05f);

		split.SplitRatio = 2;
		Test.Assert(split.SplitRatio <= 0.95f);
	}

	[Test]
	public static void DockZoneIndicator_AddTargets()
	{
		let indicator = scope DockZoneIndicator();
		Test.Assert(indicator.TargetCount == 0);

		indicator.AddTarget(.Left, .(0, 0, 100, 400), null);
		indicator.AddTarget(.Right, .(300, 0, 100, 400), null);
		Test.Assert(indicator.TargetCount == 2);

		indicator.ClearTargets();
		Test.Assert(indicator.TargetCount == 0);
	}

	[Test]
	public static void DockZoneIndicator_UpdateHover()
	{
		let indicator = scope DockZoneIndicator();
		indicator.AddTarget(.Left, .(0, 0, 100, 400), null);
		indicator.AddTarget(.Right, .(300, 0, 100, 400), null);

		indicator.UpdateHover(50, 200);
		Test.Assert(indicator.HoveredTarget.HasValue);
		Test.Assert(indicator.HoveredTarget.Value.Position == .Left);

		indicator.UpdateHover(350, 200);
		Test.Assert(indicator.HoveredTarget.Value.Position == .Right);

		indicator.UpdateHover(200, 200);
		Test.Assert(!indicator.HoveredTarget.HasValue);
	}

	// === DockTabGroup (standalone, no DockManager) ===

	[Test]
	public static void DockTabGroup_AddRemovePanel()
	{
		let group = scope DockTabGroup();
		let p1 = new DockablePanel("Panel 1");
		let p2 = new DockablePanel("Panel 2");

		group.AddPanel(p1);
		Test.Assert(group.PanelCount == 1);
		Test.Assert(group.SelectedIndex == 0);

		group.AddPanel(p2);
		Test.Assert(group.PanelCount == 2);

		group.RemovePanel(p1);
		Test.Assert(group.PanelCount == 1);

		delete p1; // removed from group, we own it now
	}

	[Test]
	public static void DockTabGroup_SelectedIndex()
	{
		let group = scope DockTabGroup();
		let p1 = new DockablePanel("A");
		let p2 = new DockablePanel("B");

		group.AddPanel(p1);
		group.AddPanel(p2);

		Test.Assert(group.SelectedIndex == 0);
		Test.Assert(group.SelectedPanel === p1);

		group.SelectedIndex = 1;
		Test.Assert(group.SelectedPanel === p2);
	}

	// === DockSplit (standalone) ===

	[Test]
	public static void DockSplit_SetChildren()
	{
		let split = scope DockSplit();
		let child1 = new DockTabGroup();
		let child2 = new DockTabGroup();

		split.SetChildren(child1, child2);
		Test.Assert(split.First === child1);
		Test.Assert(split.Second === child2);
	}

	// === DockableWindow (standalone) ===

	[Test]
	public static void DockableWindow_DetachPanel()
	{
		let panel = new DockablePanel("Test");
		let dw = scope DockableWindow(panel);

		Test.Assert(dw.Panel === panel);

		let detached = dw.DetachPanel();
		Test.Assert(detached === panel);
		Test.Assert(dw.Panel == null);

		delete panel;
	}

	// === DockManager (with context) ===

	[Test]
	public static void DockManager_AddPanel()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		root.ViewportSize = .(800, 600);
		ctx.AddRootView(root);

		let dm = new DockManager();
		root.AddView(dm);
		ctx.BeginFrame(0.016f);
		root.Measure(BoxConstraints.Tight(800, 600));
		root.Layout(0, 0, 800, 600);

		let panel = dm.AddPanel("Test", new Label("Content"));
		Test.Assert(panel != null);
		Test.Assert(panel.Title == "Test");
		Test.Assert(panel.DockHost === dm);

		// Dock the panel so it's in the view tree and gets cleaned up.
		dm.DockPanel(panel, .Center);
	}

	[Test]
	public static void DockManager_DockPanel_Center()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		root.ViewportSize = .(800, 600);
		ctx.AddRootView(root);

		let dm = new DockManager();
		root.AddView(dm);
		ctx.BeginFrame(0.016f);
		root.Measure(BoxConstraints.Tight(800, 600));
		root.Layout(0, 0, 800, 600);

		let panel = dm.AddPanel("P1", new Label("Content 1"));
		dm.DockPanel(panel, .Center);

		Test.Assert(dm.[Friend]mRootNode != null);
	}

	[Test]
	public static void DockManager_DockPanel_Split()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		root.ViewportSize = .(800, 600);
		ctx.AddRootView(root);

		let dm = new DockManager();
		root.AddView(dm);
		ctx.BeginFrame(0.016f);
		root.Measure(BoxConstraints.Tight(800, 600));
		root.Layout(0, 0, 800, 600);

		let p1 = dm.AddPanel("P1", new Label("Content 1"));
		let p2 = dm.AddPanel("P2", new Label("Content 2"));

		dm.DockPanel(p1, .Center);
		dm.DockPanel(p2, .Right);

		Test.Assert(dm.[Friend]mRootNode is DockSplit);
	}
}
