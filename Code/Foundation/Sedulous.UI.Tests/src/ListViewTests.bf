namespace Sedulous.UI.Tests;

using System;

class ListViewTests
{
	[Test]
	public static void ListView_NoAdapter_NoViews()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 200, 300);

		let lv = new ListView();
		root.AddView(lv);
		TestSetup.Layout(ctx, root);

		// VisualChildCount = active views (0) + scrollbar (1)
		Test.Assert(lv.VisualChildCount == 1);
	}

	[Test]
	public static void ListView_IsFocusable()
	{
		let lv = scope ListView();
		Test.Assert(lv.IsFocusable);
		Test.Assert(lv.IsTabStop);
	}

	[Test]
	public static void ListView_SetAdapter_CreatesVisibleViews()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 200, 300);

		let adapter = new SimpleListAdapter(100);
		defer delete adapter;

		let lv = new ListView();
		lv.ItemHeight.Value = 30;
		lv.Adapter = adapter;
		root.AddView(lv);
		TestSetup.Layout(ctx, root);

		// Should have some active views (300 / 30 = ~10 visible)
		Test.Assert(lv.VisualChildCount > 1); // at least 1 item + scrollbar
	}

	[Test]
	public static void ListView_ScrollBy_ClampsBounds()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 200, 300);

		let adapter = new SimpleListAdapter(100);
		defer delete adapter;

		let lv = new ListView();
		lv.ItemHeight.Value = 30;
		lv.Adapter = adapter;
		root.AddView(lv);
		TestSetup.Layout(ctx, root);

		lv.ScrollBy(-1000);
		Test.Assert(lv.ScrollY == 0);

		lv.ScrollBy(999999);
		Test.Assert(lv.ScrollY == lv.MaxScrollY);
	}

	[Test]
	public static void ListView_GetItemAtY()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 200, 300);

		let adapter = new SimpleListAdapter(100);
		defer delete adapter;

		let lv = new ListView();
		lv.ItemHeight.Value = 30;
		lv.Adapter = adapter;
		root.AddView(lv);
		TestSetup.Layout(ctx, root);

		Test.Assert(lv.GetItemAtY(0) == 0);
		Test.Assert(lv.GetItemAtY(31) == 1);
		Test.Assert(lv.GetItemAtY(60) == 2);
	}

	[Test]
	public static void ListView_Selection_SingleMode()
	{
		let lv = scope ListView();
		let adapter = scope SimpleListAdapter(10);
		lv.Adapter = adapter;

		lv.Selection.Select(3);
		Test.Assert(lv.Selection.IsSelected(3));
		Test.Assert(lv.Selection.SelectedCount == 1);

		lv.Selection.Select(5);
		Test.Assert(!lv.Selection.IsSelected(3));
		Test.Assert(lv.Selection.IsSelected(5));
	}

	[Test]
	public static void ListView_AdapterObserver_OnDataSetChanged()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 200, 300);

		let adapter = new SimpleListAdapter(10);
		defer delete adapter;

		let lv = new ListView();
		lv.Adapter = adapter;
		root.AddView(lv);
		TestSetup.Layout(ctx, root);

		// Change adapter count and notify.
		adapter.Count = 20;
		adapter.NotifyDataSetChanged();

		// ListView should have rebuilt.
		Test.Assert(lv.Adapter.ItemCount == 20);
	}
}
