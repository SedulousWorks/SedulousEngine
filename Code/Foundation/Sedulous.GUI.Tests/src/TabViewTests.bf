namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

class TabViewTests
{
	[Test]
	public static void TabView_AddTab_SelectsFirst()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let tabs = new TabView();
		tabs.AddTab("Tab 1", new TestView(100, 100));
		root.AddView(tabs);

		Test.Assert(tabs.SelectedIndex == 0);
		Test.Assert(tabs.TabCount == 1);
	}

	[Test]
	public static void TabView_SwitchTab()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let tabs = new TabView();
		let content1 = new TestView(100, 100);
		let content2 = new TestView(100, 100);
		tabs.AddTab("Tab 1", content1);
		tabs.AddTab("Tab 2", content2);
		root.AddView(tabs);

		Test.Assert(tabs.SelectedIndex == 0);
		Test.Assert(content1.Visibility == .Visible);
		Test.Assert(content2.Visibility == .Gone);

		tabs.SelectedIndex = 1;
		Test.Assert(content1.Visibility == .Gone);
		Test.Assert(content2.Visibility == .Visible);
	}

	[Test]
	public static void TabView_TabChangedEvent()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let tabs = new TabView();
		tabs.AddTab("A", new TestView());
		tabs.AddTab("B", new TestView());
		root.AddView(tabs);

		int32 lastIdx = -1;
		tabs.OnTabChanged.Add(new [&lastIdx] (t, idx) => { lastIdx = idx; });

		tabs.SelectedIndex = 1;
		Test.Assert(lastIdx == 1);
	}

	[Test]
	public static void TabView_RemoveTab()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let tabs = new TabView();
		tabs.AddTab("A", new TestView());
		tabs.AddTab("B", new TestView());
		tabs.AddTab("C", new TestView());
		root.AddView(tabs);

		tabs.SelectedIndex = 2;
		tabs.RemoveTab(2);

		Test.Assert(tabs.TabCount == 2);
		Test.Assert(tabs.SelectedIndex == 1); // clamps to last
	}

	[Test]
	public static void TabView_RemoveTab_AdjustsSelection()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let tabs = new TabView();
		tabs.AddTab("A", new TestView());
		tabs.AddTab("B", new TestView());
		root.AddView(tabs);

		tabs.SelectedIndex = 1;
		tabs.RemoveTab(1);

		Test.Assert(tabs.TabCount == 1);
		Test.Assert(tabs.SelectedIndex == 0);
	}

	[Test]
	public static void TabView_KeyboardNavigation()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let tabs = new TabView();
		tabs.AddTab("A", new TestView());
		tabs.AddTab("B", new TestView());
		tabs.AddTab("C", new TestView());
		root.AddView(tabs);

		Test.Assert(tabs.SelectedIndex == 0);

		let right = scope KeyEventArgs();
		right.Set(.Right, .None, false);
		tabs.OnKeyDown(right);
		Test.Assert(tabs.SelectedIndex == 1);

		let left = scope KeyEventArgs();
		left.Set(.Left, .None, false);
		tabs.OnKeyDown(left);
		Test.Assert(tabs.SelectedIndex == 0);

		// Can't go below 0
		tabs.OnKeyDown(left);
		Test.Assert(tabs.SelectedIndex == 0);
	}

	[Test]
	public static void TabView_InvalidIndex_Ignored()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 400, 300);

		let tabs = new TabView();
		tabs.AddTab("A", new TestView());
		root.AddView(tabs);

		tabs.SelectedIndex = 5; // out of range
		Test.Assert(tabs.SelectedIndex == 0); // unchanged
	}
}
