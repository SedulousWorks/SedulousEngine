using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The virtualised list: only the rows that can be seen exist as views, and they are recycled
/// as they scroll past.
class ListViewTests
{
	/// Counts binds per position and remembers which view each one landed in, so a range
	/// change can be pinned as an IN-PLACE rebind rather than a teardown.
	private class BindCountingAdapter : ListAdapterBase
	{
		public int32 Count = 0;
		public List<int32> Binds = new .() ~ delete _;
		public List<View> BoundViews = new .() ~ delete _;

		public this(int32 count)
		{
			Count = count;
			for (int32 i < count)
			{
				Binds.Add(0);
				BoundViews.Add(null);
			}
		}

		public override int32 ItemCount => Count;
		public override View CreateView(int32 viewType) => new TestView(100.0f, 30.0f);

		public override void BindView(View view, int32 position)
		{
			Binds[position]++;
			BoundViews[position] = view;
		}
	}

	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root, 200, 300);
	}

	/// The adapter is BORROWED, so it must outlive the list. Every caller here declares it
	/// before the teardown defer: Beef destroys scope locals in reverse declaration order, so
	/// an adapter declared after the defer would be freed while the list's destructor is still
	/// asking it for view types.
	private static ListView AddList(UIContext context, RootView root, IListAdapter adapter)
	{
		let list = new ListView();
		list.ItemHeight.Value = 30;
		list.SetAdapter(adapter);
		root.AddView(list);
		UITest.LayoutPass(context, root);
		return list;
	}

	// ---- Virtualisation -----------------------------------------------------------------------

	/// With no adapter there are no rows, and the scroll bar is the only visual child.
	[Test]
	public static void AListWithNoAdapterHasOnlyItsScrollBar()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let list = new ListView();
		root.AddView(list);
		UITest.LayoutPass(context, root);

		Test.Assert(list.VisualChildCount == 1);
		Test.Assert(list.IsFocusable);
		Test.Assert(list.IsTabStop);
		// The arrows move the selection, so focus must not spend them on moving away.
		Test.Assert(list.WantsArrowKeys);
	}

	/// A hundred rows in a three hundred pixel viewport creates a SCREENFUL, not a hundred.
	/// That is the whole point of the control.
	[Test]
	public static void OnlyTheVisibleRowsExist()
	{
		let adapter = scope SimpleListAdapter(100);
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let list = AddList(context, root, adapter);

		// Ten rows of thirty fill three hundred, plus the partial one at the bottom edge,
		// plus the scroll bar.
		Test.Assert(list.VisualChildCount > 1);
		Test.Assert(list.VisualChildCount <= 13, "a screenful, not a hundred");
		Test.Assert(list.Recycler.CreatedCount <= 12);
	}

	/// Scrolling REUSES the rows that left rather than creating more.
	[Test]
	public static void ScrollingRecyclesRowsRatherThanCreatingThem()
	{
		let adapter = scope SimpleListAdapter(1000);
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let list = AddList(context, root, adapter);
		let createdAtFirstLayout = list.Recycler.CreatedCount;

		for (int32 i < 20)
		{
			list.ScrollBy(30);
			UITest.LayoutPass(context, root);
		}

		Test.Assert(list.Recycler.ReusedCount > 0, "rows came back from the pool");
		Test.Assert(list.Recycler.CreatedCount == createdAtFirstLayout,
			"and no new ones were needed");
	}

	[Test]
	public static void ScrollingClampsToTheExtent()
	{
		let adapter = scope SimpleListAdapter(100);
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let list = AddList(context, root, adapter);

		list.ScrollBy(-1000);
		Test.Assert(list.ScrollY == 0);

		list.ScrollBy(999999);
		Test.Assert(list.ScrollY == list.MaxScrollY);
	}

	[Test]
	public static void TheRowAtAHeightIsFoundByDivision()
	{
		let adapter = scope SimpleListAdapter(100);
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let list = AddList(context, root, adapter);

		Test.Assert(list.GetItemAtY(0) == 0);
		Test.Assert(list.GetItemAtY(31) == 1);
		Test.Assert(list.GetItemAtY(60) == 2);
	}

	/// Scrolling to a row moves the LEAST that brings it into view, and not at all when it is
	/// already there.
	[Test]
	public static void ScrollingToARowMovesTheLeastThatShowsIt()
	{
		let adapter = scope SimpleListAdapter(100);
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let list = AddList(context, root, adapter);

		list.ScrollToPosition(2);
		Test.Assert(list.ScrollY == 0, "already visible");

		// Row 20 sits at 600; bringing its bottom edge to the viewport's puts the top at 330.
		list.ScrollToPosition(20);
		Test.Assert(list.ScrollY == 630 - 300);

		list.ScrollToPosition(0);
		Test.Assert(list.ScrollY == 0);
	}

	// ---- Selection ----------------------------------------------------------------------------

	[Test]
	public static void SelectingOneRowDeselectsTheLast()
	{
		let adapter = scope SimpleListAdapter(10);
		let list = new ListView();
		defer list.ReleaseRef();
		list.SetAdapter(adapter);

		list.Selection.Select(3);
		Test.Assert(list.Selection.IsSelected(3));
		Test.Assert(list.Selection.SelectedCount == 1);

		list.Selection.Select(5);
		Test.Assert(!list.Selection.IsSelected(3));
		Test.Assert(list.Selection.IsSelected(5));
	}

	/// The selection is POSITIONAL, so a shrinking data set drops the indices that no longer
	/// exist. Left alone, a later grow would silently highlight whichever row inherited one.
	[Test]
	public static void ShrinkingTheDataDropsSelectionPastTheEnd()
	{
		let big = scope SimpleListAdapter(10);
		let small = scope SimpleListAdapter(4);
		let list = new ListView();
		defer list.ReleaseRef();

		list.SetAdapter(big);
		list.Selection.Select(2);
		list.Selection.Toggle(8);
		Test.Assert(list.Selection.IsSelected(8));

		list.SetAdapter(small);
		list.NotifyDataChanged();

		Test.Assert(!list.Selection.IsSelected(8));
		Test.Assert(list.Selection.SelectedCount == 0);
	}

	/// The arrows move the selection and drag the view along with it; Shift extends instead of
	/// moving.
	[Test]
	public static void TheKeyboardMovesTheSelectionAndFollowsIt()
	{
		let adapter = scope SimpleListAdapter(100);
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let list = AddList(context, root, adapter);
		list.Selection.Select(0);

		let down = scope KeyEventArgs();
		down.Set(.Down, .None, false);
		list.OnKeyDown(down);
		Test.Assert(list.Selection.IsSelected(1));
		Test.Assert(down.Handled);

		let end = scope KeyEventArgs();
		end.Set(.End, .None, false);
		list.OnKeyDown(end);
		Test.Assert(list.Selection.IsSelected(99));
		Test.Assert(list.ScrollY == list.MaxScrollY, "and scrolled to show it");

		let home = scope KeyEventArgs();
		home.Set(.Home, .None, false);
		list.OnKeyDown(home);
		Test.Assert(list.Selection.IsSelected(0));
		Test.Assert(list.ScrollY == 0);

		// Shift EXTENDS from where the selection was rather than moving it.
		list.Selection.Mode = .Multiple;
		let shiftDown = scope KeyEventArgs();
		shiftDown.Set(.Down, .Shift, false);
		list.OnKeyDown(shiftDown);
		Test.Assert(list.Selection.IsSelected(0));
		Test.Assert(list.Selection.IsSelected(1));
	}

	/// A row gets FIRST refusal on a key, so a consumer can bind F2 or Delete without the list
	/// having to know about them.
	[Test]
	public static void ARowSeesAKeyBeforeTheListDoes()
	{
		let adapter = scope SimpleListAdapter(100);
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let list = AddList(context, root, adapter);
		list.Selection.Select(5);

		var sawPosition = -1;
		list.OnItemKeyDown.Add(new [&sawPosition](position, args) =>
			{
				sawPosition = position;
				args.Handled = true;
			});

		let down = scope KeyEventArgs();
		down.Set(.Down, .None, false);
		list.OnKeyDown(down);

		Test.Assert(sawPosition == 5);
		Test.Assert(list.Selection.IsSelected(5), "the list's own handling was suppressed");
	}

	// ---- Adapter notifications ----------------------------------------------------------------

	[Test]
	public static void AWholeDataSetChangeIsPickedUp()
	{
		let adapter = scope SimpleListAdapter(10);
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let list = AddList(context, root, adapter);

		adapter.Count = 20;
		adapter.NotifyDataSetChanged();

		Test.Assert(list.Adapter.ItemCount == 20);
	}

	/// A range change rebinds the named rows IN PLACE: the same view object, no recycling, and
	/// the neighbours untouched. Rebuilding the lot would be correct but would throw away
	/// every visible row to update one.
	[Test]
	public static void ARangeChangeRebindsOnlyWhatItNamesAndKeepsTheView()
	{
		let adapter = scope BindCountingAdapter(100);
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let list = AddList(context, root, adapter);

		let visualChildrenBefore = list.VisualChildCount;
		Test.Assert(adapter.Binds[2] == 1, "visible, and bound once by the layout");
		let boundView = adapter.BoundViews[2];
		Test.Assert(boundView != null);

		adapter.NotifyRangeChanged(2, 1);

		Test.Assert(adapter.Binds[2] == 2, "rebound");
		Test.Assert(adapter.BoundViews[2] == boundView, "into the same view, so nothing recycled");
		Test.Assert(adapter.Binds[3] == 1, "the neighbours were left alone");
		Test.Assert(list.VisualChildCount == visualChildrenBefore);

		// A position that is not on screen has nothing to rebind.
		adapter.NotifyRangeChanged(90, 1);
		Test.Assert(adapter.Binds[90] == 0);
	}

	/// A row already on screen is NOT rebound by an ordinary layout pass. Binding on acquire
	/// plus the change notifications covers it; rebinding per layout meant every visible row
	/// rebound every frame.
	[Test]
	public static void AnOrdinaryLayoutPassRebindsNothing()
	{
		let adapter = scope BindCountingAdapter(100);
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		AddList(context, root, adapter);
		Test.Assert(adapter.Binds[0] == 1);

		UITest.LayoutPass(context, root);
		UITest.LayoutPass(context, root);

		Test.Assert(adapter.Binds[0] == 1, "still once");
	}
}
