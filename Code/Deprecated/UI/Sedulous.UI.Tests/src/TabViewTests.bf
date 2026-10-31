using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The tabbed container: a strip of headers, one page showing, and a strip that scrolls when
/// there are more tabs than fit.
///
/// With no font service every tab takes the 80 pixel fallback width, so six tabs make 480
/// against a 400 wide view and the overflow is exact.
class TabViewTests
{
	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root, 400, 300);
	}

	private static TabView AddTabs(UIContext context, RootView root, int32 count)
	{
		let tabs = new TabView();
		for (int32 i < count)
			tabs.AddTab("Tab", new TestView(100, 100));

		root.AddView(tabs);
		UITest.LayoutPass(context, root);
		return tabs;
	}

	// ---- Tabs and pages -----------------------------------------------------------------------

	/// The first tab added becomes the selection, since a tab view showing nothing is useless.
	[Test]
	public static void TheFirstTabAddedIsSelected()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let tabs = AddTabs(context, root, 1);

		Test.Assert(tabs.SelectedIndex == 0);
		Test.Assert(tabs.TabCount == 1);
		Test.Assert(tabs.IsFocusable);
		Test.Assert(tabs.WantsArrowKeys);
	}

	/// Only the selected page is Visible; the rest are GONE, so they cost no layout either.
	[Test]
	public static void OnlyTheSelectedPageIsVisibleAndTheRestAreGone()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let tabs = new TabView();
		let first = new TestView(100, 100);
		let second = new TestView(100, 100);
		tabs.AddTab("Tab 1", first);
		tabs.AddTab("Tab 2", second);
		root.AddView(tabs);

		Test.Assert(tabs.SelectedIndex == 0);
		Test.Assert(first.Visibility == .Visible);
		Test.Assert(second.Visibility == .Gone);

		tabs.SetSelectedIndex(1);
		Test.Assert(first.Visibility == .Gone);
		Test.Assert(second.Visibility == .Visible);
	}

	[Test]
	public static void ChangingTabsReportsTheNewIndexOnceOnly()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let tabs = AddTabs(context, root, 2);

		var reports = 0;
		var lastIndex = -1;
		tabs.OnTabChanged.Add(new [&reports, &lastIndex](t, index) =>
			{
				reports++;
				lastIndex = index;
			});

		tabs.SetSelectedIndex(1);
		Test.Assert(reports == 1);
		Test.Assert(lastIndex == 1);

		// Selecting what is already selected, or an index that does not exist, reports nothing.
		tabs.SetSelectedIndex(1);
		tabs.SetSelectedIndex(99);
		tabs.SetSelectedIndex(-1);
		Test.Assert(reports == 1);
	}

	/// Removing pulls the selection back into range and makes the new one visible, WITHOUT
	/// reporting: closing a tab is not the user choosing a different one.
	[Test]
	public static void RemovingATabPullsTheSelectionBackSilently()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let tabs = AddTabs(context, root, 3);
		tabs.SetSelectedIndex(2);

		var reports = 0;
		tabs.OnTabChanged.Add(new [&reports](t, index) => { reports++; });

		tabs.RemoveTab(2);
		Test.Assert(tabs.TabCount == 2);
		Test.Assert(tabs.SelectedIndex == 1, "clamped to the new last");
		Test.Assert(tabs.GetTab(1).Content.Visibility == .Visible);
		Test.Assert(reports == 0);

		tabs.RemoveTab(1);
		Test.Assert(tabs.TabCount == 1);
		Test.Assert(tabs.SelectedIndex == 0);

		// Out of range does nothing rather than reaching past the end.
		tabs.RemoveTab(99);
		tabs.RemoveTab(-1);
		Test.Assert(tabs.TabCount == 1);
	}

	// ---- Keys ---------------------------------------------------------------------------------

	/// Left and Right walk the tab ORDER whatever the placement, and stop at the ends rather
	/// than wrapping.
	[Test]
	public static void TheArrowsWalkTheTabOrderAndStopAtTheEnds()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let tabs = AddTabs(context, root, 3);
		Test.Assert(tabs.SelectedIndex == 0);

		let right = scope KeyEventArgs();
		right.Set(.Right, .None, false);
		tabs.OnKeyDown(right);
		Test.Assert(tabs.SelectedIndex == 1);
		Test.Assert(right.Handled);

		let left = scope KeyEventArgs();
		left.Set(.Left, .None, false);
		tabs.OnKeyDown(left);
		Test.Assert(tabs.SelectedIndex == 0);

		tabs.OnKeyDown(left);
		Test.Assert(tabs.SelectedIndex == 0, "and no further");

		// A VERTICAL strip is walked with the same keys: they are the order, not a direction.
		tabs.Placement.Value = .Left;
		tabs.OnKeyDown(right);
		Test.Assert(tabs.SelectedIndex == 1);
	}

	// ---- Hover --------------------------------------------------------------------------------

	/// Hover is tracked on mouse move, which stops arriving once the pointer leaves, so leaving
	/// has to clear it or the last tab stays lit.
	[Test]
	public static void HoverClearsWhenThePointerLeaves()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let tabs = AddTabs(context, root, 2);
		let input = context.GetInputManager();

		input.ProcessMouseMove(10, 10);
		Test.Assert(tabs.HoveredTabIndex == 0);

		// Into the content area, so the tab view is no longer the hovered view.
		input.ProcessMouseMove(200, 200);
		Test.Assert(tabs.HoveredTabIndex == -1);
	}

	// ---- Overflow -----------------------------------------------------------------------------

	/// Six 80 pixel tabs overflow a 400 wide strip; three do not.
	[Test]
	public static void AStripLongerThanItsEdgeOverflows()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let few = AddTabs(context, root, 3);
		Test.Assert(!few.TabOverflow, "240 fits in 400");

		let many = AddTabs(context, root, 6);
		Test.Assert(many.TabOverflow, "480 does not");
	}

	/// Selecting a tab that is scrolled off brings it into view, so choosing by keyboard cannot
	/// land somewhere invisible.
	[Test]
	public static void SelectingAHiddenTabScrollsItIntoView()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let tabs = AddTabs(context, root, 6);
		let input = context.GetInputManager();

		// At rest the first tab holds x 0 to 80.
		input.ProcessMouseMove(10, 10);
		Test.Assert(tabs.HoveredTabIndex == 0);

		tabs.SetSelectedIndex(5);
		UITest.LayoutPass(context, root);

		// The strip slid left by the 80 of overflow, so tab 0 is off the edge and x=10 is now
		// inside tab 1.
		input.ProcessMouseMove(10, 10);
		Test.Assert(tabs.HoveredTabIndex == 1);

		input.ProcessMouseMove(390, 10);
		Test.Assert(tabs.HoveredTabIndex == 5, "and the last tab is reachable");
	}

	/// The wheel scrolls an overflowing strip. There is no room for a scroll bar in a tab
	/// strip, so this is the only way to reach a tab pushed off the end by the pointer alone.
	[Test]
	public static void TheWheelScrollsAnOverflowingStrip()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let tabs = AddTabs(context, root, 6);
		let input = context.GetInputManager();

		input.ProcessMouseMove(10, 10);
		Test.Assert(tabs.HoveredTabIndex == 0);

		let wheel = scope MouseWheelEventArgs();
		wheel.X = 10;
		wheel.Y = 10;
		wheel.DeltaY = -3;
		tabs.OnMouseWheel(wheel);
		Test.Assert(wheel.Handled);
		UITest.LayoutPass(context, root);

		input.ProcessMouseMove(10, 10);
		Test.Assert(tabs.HoveredTabIndex == 1, "tab 0 scrolled off the left edge");
	}

	/// A strip that fits ignores the wheel, so it bubbles to whatever is behind.
	[Test]
	public static void AStripThatFitsIgnoresTheWheel()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let tabs = AddTabs(context, root, 3);
		let input = context.GetInputManager();

		// Three 80s put the third at x 160 to 240.
		input.ProcessMouseMove(170, 10);
		Test.Assert(tabs.HoveredTabIndex == 2);

		let wheel = scope MouseWheelEventArgs();
		wheel.X = 170;
		wheel.Y = 10;
		wheel.DeltaY = -3;
		tabs.OnMouseWheel(wheel);
		Test.Assert(!wheel.Handled);
		UITest.LayoutPass(context, root);

		input.ProcessMouseMove(170, 10);
		Test.Assert(tabs.HoveredTabIndex == 2, "and nothing moved");
	}

	/// A wheel OUTSIDE the strip is left alone even when the strip overflows, so scrolling over
	/// a page does not shuffle the tabs above it.
	[Test]
	public static void AWheelOverThePageDoesNotMoveTheStrip()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let tabs = AddTabs(context, root, 6);
		let input = context.GetInputManager();

		let wheel = scope MouseWheelEventArgs();
		wheel.X = 200;
		wheel.Y = 200;
		wheel.DeltaY = -3;
		tabs.OnMouseWheel(wheel);

		Test.Assert(!wheel.Handled);

		UITest.LayoutPass(context, root);
		input.ProcessMouseMove(10, 10);
		Test.Assert(tabs.HoveredTabIndex == 0, "the strip did not move");
	}

	// ---- Closing ------------------------------------------------------------------------------

	/// Closing is ASKED FOR rather than done: a page may have unsaved work to ask about first,
	/// so the tab is still there when the request arrives.
	[Test]
	public static void ClickingCloseAsksRatherThanRemoving()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let tabs = new TabView();
		tabs.TabsClosable.Value = true;
		tabs.AddTab("A", new TestView(100, 100));
		tabs.AddTab("B", new TestView(100, 100));
		root.AddView(tabs);
		UITest.LayoutPass(context, root);

		var requested = -1;
		tabs.OnTabCloseRequested.Add(new [&requested](t, index) => { requested = index; });

		// A CLOSABLE tab is wider than a plain one: the button's 12 and its 4 of gap are added
		// to the 80 fallback, so each runs 96 and the second holds x 96 to 192. Its button sits
		// at the right end, x 176 to 188.
		let input = context.GetInputManager();
		input.ProcessMouseMove(182, 14);
		input.ProcessMouseDown(.Left, 182, 14, 0);

		Test.Assert(requested == 1);
		Test.Assert(tabs.TabCount == 2, "still there: removing is the consumer's decision");
		Test.Assert(tabs.SelectedIndex == 0, "and the click did not also select it");
	}

	/// A click elsewhere on a closable tab selects it as usual.
	[Test]
	public static void ClickingAClosableTabAwayFromItsButtonSelectsIt()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let tabs = new TabView();
		tabs.TabsClosable.Value = true;
		tabs.AddTab("A", new TestView(100, 100));
		tabs.AddTab("B", new TestView(100, 100));
		root.AddView(tabs);
		UITest.LayoutPass(context, root);

		var requested = -1;
		tabs.OnTabCloseRequested.Add(new [&requested](t, index) => { requested = index; });

		let input = context.GetInputManager();
		input.ProcessMouseMove(100, 14);
		input.ProcessMouseDown(.Left, 100, 14, 0);

		Test.Assert(tabs.SelectedIndex == 1);
		Test.Assert(requested == -1);
	}
}
