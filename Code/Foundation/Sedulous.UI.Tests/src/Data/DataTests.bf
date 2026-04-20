namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Simple test adapter producing Labels with text "Item N".
class TestAdapter : IListAdapter
{
	public int32 Count;

	public this(int32 count) { Count = count; }

	public int32 ItemCount => Count;

	public void SetObserver(IListAdapterObserver observer) { }

	public View CreateView(int32 viewType)
	{
		return new Label();
	}

	public void BindView(View view, int32 position)
	{
		if (let label = view as Label)
		{
			let text = scope String();
			text.AppendF("Item {}", position);
			label.SetText(text);
		}
	}
}

class DataTests
{
	[Test]
	public static void ViewRecycler_ReusesViews()
	{
		let recycler = scope ViewRecycler();
		let adapter = scope TestAdapter(10);

		// Create a view.
		let view = recycler.GetOrCreate(adapter, 0);
		Test.Assert(recycler.CreatedCount == 1);
		Test.Assert(recycler.ReusedCount == 0);

		// Recycle it.
		recycler.Recycle(view, 0);
		Test.Assert(recycler.RecycledCount == 1);

		// Get another - should reuse.
		let view2 = recycler.GetOrCreate(adapter, 1);
		Test.Assert(recycler.CreatedCount == 1); // didn't create new
		Test.Assert(recycler.ReusedCount == 1);
		Test.Assert(view2 === view); // same instance

		delete view2;
	}

	[Test]
	public static void ViewRecycler_MultiViewType()
	{
		let recycler = scope ViewRecycler();

		let viewA = new ColorView();
		let viewB = new Label();

		recycler.Recycle(viewA, 0);
		recycler.Recycle(viewB, 1);

		// Acquire type 1 -> gets the Label, not the ColorView.
		let got = recycler.Acquire(1);
		Test.Assert(got === viewB);

		// Acquire type 0 -> gets the ColorView.
		let got2 = recycler.Acquire(0);
		Test.Assert(got2 === viewA);

		delete viewA;
		delete viewB;
	}

	[Test]
	public static void SelectionModel_SingleMode()
	{
		let sel = scope SelectionModel();
		sel.Mode = .Single;

		sel.Select(3);
		Test.Assert(sel.IsSelected(3));
		Test.Assert(sel.SelectedCount == 1);

		// Selecting another clears previous in Single mode.
		sel.Select(5);
		Test.Assert(!sel.IsSelected(3));
		Test.Assert(sel.IsSelected(5));
		Test.Assert(sel.SelectedCount == 1);
	}

	[Test]
	public static void SelectionModel_MultipleMode()
	{
		let sel = scope SelectionModel();
		sel.Mode = .Multiple;

		sel.Select(1);
		sel.Select(3);
		sel.Select(5);
		Test.Assert(sel.SelectedCount == 3);
		Test.Assert(sel.IsSelected(1));
		Test.Assert(sel.IsSelected(3));
		Test.Assert(sel.IsSelected(5));
	}

	[Test]
	public static void SelectionModel_ShiftIndices()
	{
		let sel = scope SelectionModel();
		sel.Mode = .Multiple;
		sel.Select(2);
		sel.Select(5);

		// Insert 3 items at position 3 -> indices >= 3 shift by +3.
		sel.ShiftIndices(3, 3);
		Test.Assert(sel.IsSelected(2));  // below start, unchanged
		Test.Assert(!sel.IsSelected(5)); // was 5, shifted to 8
		Test.Assert(sel.IsSelected(8));
	}

	[Test]
	public static void SelectionModel_Toggle()
	{
		let sel = scope SelectionModel();
		sel.Mode = .Multiple;

		sel.Toggle(2);
		Test.Assert(sel.IsSelected(2));

		sel.Toggle(2);
		Test.Assert(!sel.IsSelected(2));
	}

	[Test]
	public static void ListView_FixedHeight_VisibleRange()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(300, 100);

		let list = new ListView();
		list.ItemHeight = 25;
		list.Adapter = new TestAdapter(100);
		defer delete list.Adapter;
		root.AddView(list);

		ctx.UpdateRootView(root);

		// Viewport = 100px, item height = 25px -> ~4-5 visible items.
		// With 100 items, most are off-screen and not created.
		Test.Assert(list.Recycler.CreatedCount <= 6); // at most ceil(100/25)+1
		Test.Assert(list.Recycler.CreatedCount >= 4);
	}

	[Test]
	public static void ListView_ScrollRecyclesViews()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(300, 100);

		let list = new ListView();
		list.ItemHeight = 25;
		list.Adapter = new TestAdapter(100);
		defer delete list.Adapter;
		root.AddView(list);

		ctx.UpdateRootView(root);
		let initialCreated = list.Recycler.CreatedCount;

		// Scroll down by one item.
		list.ScrollBy(25);
		ctx.UpdateRootView(root);

		// Should have recycled 1 view and reused it (or created 1 more).
		// CreatedCount should not have grown much.
		Test.Assert(list.Recycler.CreatedCount <= initialCreated + 1);
	}

	// === Variable-height adapter ===

	class VariableHeightAdapter : IListAdapter
	{
		public int32 ItemCount => 20;
		public void SetObserver(IListAdapterObserver observer) { }

		public View CreateView(int32 viewType) => new Label();

		public void BindView(View view, int32 position)
		{
			if (let label = view as Label)
				label.SetText(scope $"Item {position}");
		}

		/// Items 0-9 are 20px, items 10-19 are 40px.
		public float GetItemHeight(int32 position)
		{
			return (position < 10) ? 20 : 40;
		}
	}

	[Test]
	public static void ListView_VariableHeight_CorrectRange()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(300, 100);

		let list = new ListView();
		list.Adapter = new VariableHeightAdapter();
		defer delete list.Adapter;
		root.AddView(list);

		ctx.UpdateRootView(root);

		// First 10 items = 20px each = 200px. In 100px viewport,
		// 5 items visible (0-4) + 1 buffer.
		Test.Assert(list.Recycler.CreatedCount >= 5);
		Test.Assert(list.Recycler.CreatedCount <= 7);
	}

	[Test]
	public static void ListView_VariableHeight_ScrollToLargeItems()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(300, 100);

		let list = new ListView();
		list.Adapter = new VariableHeightAdapter();
		defer delete list.Adapter;
		root.AddView(list);

		ctx.UpdateRootView(root);

		// Scroll to the large items region (items 10+, each 40px).
		// Total offset of item 10 = 10 * 20 = 200.
		list.ScrollBy(200);
		ctx.UpdateRootView(root);

		// In 100px viewport with 40px items: 2-3 items visible.
		// Verify we didn't crash and created reasonable count.
		Test.Assert(list.Recycler.CreatedCount > 0);
	}

	// === Observer tests ===

	class ObservedAdapter : ListAdapterBase
	{
		public int32 Count = 10;

		public override int32 ItemCount => Count;
		public override View CreateView(int32 viewType) => new Label();
		public override void BindView(View view, int32 position)
		{
			if (let label = view as Label)
				label.SetText(scope $"Item {position}");
		}
	}

	[Test]
	public static void Observer_DataSetChanged_Rebuilds()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(300, 200);

		let adapter = new ObservedAdapter();
		defer delete adapter;

		let list = new ListView();
		list.ItemHeight = 20;
		list.Adapter = adapter;
		root.AddView(list);

		ctx.UpdateRootView(root);

		// Change data and notify.
		adapter.Count = 5;
		adapter.NotifyDataSetChanged();
		ctx.UpdateRootView(root);

		// ListView should have rebuilt - MaxScrollY should reflect new count.
		// 5 * 20 = 100 < 200 viewport -> no scroll needed.
		Test.Assert(list.MaxScrollY == 0);
	}

	[Test]
	public static void Observer_RangeChanged_Rebinds()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(300, 200);

		let adapter = new ObservedAdapter();
		defer delete adapter;

		let list = new ListView();
		list.ItemHeight = 20;
		list.Adapter = adapter;
		root.AddView(list);

		ctx.UpdateRootView(root);

		// Notify range changed - shouldn't crash, should rebind.
		adapter.NotifyRangeChanged(0, 3);
		ctx.UpdateRootView(root);

		// Just verify no crash and views still exist.
		Test.Assert(list.Recycler.CreatedCount > 0);
	}
}
