using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Tabs: a TabBar of real tab elements and a TabView pairing it with pages. Selection by the press,
/// the keys and Ctrl+Tab; closing as a request with a display policy; reordering by a drag across a
/// neighbour's midpoint; an overflowing strip that scrolls and lists every tab (or always lists
/// them), and a part that closes them all; pages kept alive, or built on first show; tabs torn out
/// of a strip of a group and dropped on another, a view's page with them.
class TabTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	/// A root `width` by 300, held by the caller.
	private static SceneRoot MakeRoot(float width = 400.0f) => SceneFixtures.NewScene(width, 300.0f);

	/// A tab of a known width (the tests have no font to size their text); the bar holds it.
	private static Tab AddSizedTab(TabBar bar, StringView text, float width = 80.0f)
	{
		let tab = bar.AddTab(text);
		tab.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(width);
				s.Height = LayoutLength.Px(24.0f);
			});
		return tab;
	}

	private static Float2 CentreOf(Node node)
	{
		let r = node.ScreenBounds;
		return .(r.X + r.Width * 0.5f, r.Y + r.Height * 0.5f);
	}

	private static void Press(EventDispatcher d, Float2 at, MouseButton button = .Left)
	{
		d.InjectMouseDown(at, button);
		d.InjectMouseUp(at, button);
	}

	/// A reorderable bar of `group`, 380 wide, placed at (10, `y`) in `root`, held by the caller.
	private static TabBar BarAt(SceneRoot root, float y, StringView group)
	{
		let bar = new TabBar();
		bar.EditLayoutStyle(scope (s) =>
			{
				s.Placement = .Absolute;
				s.Left = LayoutLength.Px(10.0f);
				s.Top = LayoutLength.Px(y);
				s.Width = LayoutLength.Px(380.0f);
			});
		bar.Reorderable = true;
		bar.Group = group;
		root.AddChild(bar);
		return bar;
	}

	/// `view` placed at (10, `y`), 380 by `height`.
	private static void PlaceView(TabView view, float y, float height)
	{
		view.EditLayoutStyle(scope (s) =>
			{
				s.Placement = .Absolute;
				s.Left = LayoutLength.Px(10.0f);
				s.Top = LayoutLength.Px(y);
				s.Width = LayoutLength.Px(380.0f);
				s.Height = LayoutLength.Px(height);
			});
	}

	/// Each of `view`'s tabs 80 by 24.
	private static void SizeTabs(TabView view)
	{
		for (int32 i = 0; i < view.PageCount; ++i)
		{
			view.Bar.GetTab(i).EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Px(80.0f);
					s.Height = LayoutLength.Px(24.0f);
				});
		}
	}

	[Test]
	public static void TheFirstTabIsSelectedAPressSelectsReportingChangeWhileCodesSelectionReportsNothing()
	{
		let root = MakeRoot();
		defer root.ReleaseRef();
		let bar = new TabBar();
		defer bar.ReleaseRef();
		root.AddChild(bar);
		let a = AddSizedTab(bar, "One");
		let b = AddSizedTab(bar, "Two");
		AddSizedTab(bar, "Three");
		root.UpdateLayout();
		Test.Assert(bar.TabCount == 3);
		Test.Assert(bar.SelectedIndex == 0);
		Test.Assert(a.IsSelected);
		Test.Assert((a.WidgetStates & WidgetStateChecked) != 0); // `tab:checked`

		int changes = 0;
		int32 selectedByUser = -1;
		int anyChange = 0;
		bar.AddEventListener(.Changed, new [&] (e) => { ++changes; });
		bar.SetOnSelected(new [&] (index) => { selectedByUser = index; });
		bar.SetOnSelectionChanged(new [&] (index) => { ++anyChange; });

		let d = root.EventDispatcher;
		d.InjectMouseDown(CentreOf(b), .Left); // a tab selects on the press
		Test.Assert(bar.SelectedIndex == 1);
		d.InjectMouseUp(CentreOf(b), .Left);
		Test.Assert(changes == 1);
		Test.Assert(selectedByUser == 1);
		Test.Assert(b.IsFocused);
		Test.Assert(!a.IsSelected);

		bar.SelectedIndex = 2;
		Test.Assert(bar.SelectedIndex == 2);
		Test.Assert(changes == 1); // code's selection: no change event
		Test.Assert(anyChange == 2); // but what shows a page follows both
	}

	[Test]
	public static void TheArrowsHomeAndEndMoveAlongTheStripCtrlTabAndCtrlShiftTabCycleRoundIt()
	{
		let root = MakeRoot();
		defer root.ReleaseRef();
		let bar = new TabBar();
		defer bar.ReleaseRef();
		root.AddChild(bar);
		String[4] names = .("A", "B", "C", "D");
		for (let t in names)
			AddSizedTab(bar, t, 60.0f);
		root.UpdateLayout();
		let d = root.EventDispatcher;
		bar.GetTab(0).RequestFocus();

		d.InjectKeyDown((uint32)KeyCode.Right);
		Test.Assert(bar.SelectedIndex == 1);
		Test.Assert(bar.GetTab(1).IsFocused);
		d.InjectKeyDown((uint32)KeyCode.End);
		Test.Assert(bar.SelectedIndex == 3);
		d.InjectKeyDown((uint32)KeyCode.Home);
		Test.Assert(bar.SelectedIndex == 0);
		d.InjectKeyDown((uint32)KeyCode.Left); // at the start the arrow is navigation's
		Test.Assert(bar.SelectedIndex == 0);

		d.InjectKeyDown((uint32)KeyCode.Tab, KeyModCtrl | KeyModShift); // back, round to the last
		Test.Assert(bar.SelectedIndex == 3);
		Test.Assert(bar.GetTab(3).IsFocused);
		d.InjectKeyDown((uint32)KeyCode.Tab, KeyModCtrl); // on, round to the first
		Test.Assert(bar.SelectedIndex == 0);
		d.InjectKeyDown((uint32)KeyCode.PageDown, KeyModCtrl);
		Test.Assert(bar.SelectedIndex == 1);
	}

	[Test]
	public static void TheCloseDisplayPolicyShowsTheClosePartOnNeverTheSelectedTheHoveredAndEveryTab()
	{
		let root = MakeRoot();
		defer root.ReleaseRef();
		let bar = new TabBar();
		defer bar.ReleaseRef();
		root.AddChild(bar);
		let a = AddSizedTab(bar, "A");
		let b = AddSizedTab(bar, "B");
		root.UpdateLayout();

		Test.Assert(!a.ClosePart.Displayed); // never, by default: no room for it either
		bar.CloseDisplay = .Selected;
		Test.Assert(a.ClosePart.Displayed);
		Test.Assert(a.ClosePart.Visible);
		Test.Assert(b.ClosePart.Displayed); // its room is kept, so showing it grows nothing
		Test.Assert(!b.ClosePart.Visible);

		bar.CloseDisplay = .Hover;
		root.UpdateLayout();
		let d = root.EventDispatcher;
		Test.Assert(!b.ClosePart.Visible);
		d.InjectMouseMove(CentreOf(b));
		Test.Assert(b.ClosePart.Visible);
		d.InjectMouseMove(.(390.0f, 290.0f));
		Test.Assert(!b.ClosePart.Visible);

		bar.CloseDisplay = .Always;
		Test.Assert(b.ClosePart.Visible);
		b.Closable = false;
		Test.Assert(!b.ClosePart.Displayed);

		bar.CloseDisplayName = "hover";
		Test.Assert(bar.CloseDisplay == .Hover);
		Test.Assert(bar.CloseDisplayName == "hover");
	}

	[Test]
	public static void ClosingIsARequestTabcloseIsReportedAndTheTabGoesUnlessAListenerTakesIt()
	{
		let root = MakeRoot();
		defer root.ReleaseRef();
		let bar = new TabBar();
		defer bar.ReleaseRef();
		root.AddChild(bar);
		bar.CloseDisplay = .Always;
		AddSizedTab(bar, "A");
		let b = AddSizedTab(bar, "B");
		AddSizedTab(bar, "C");
		bar.SelectedIndex = 1;
		root.UpdateLayout();

		bool keep = true;
		int requests = 0;
		int32 asked = -1;
		bar.AddEventListener(.TabClose, new [&] (e) =>
			{
				++requests;
				asked = ((TabEvent)e).Index;
				if (keep)
					e.Handled = true; // taken: the tab stays (an unsaved document asks first)
			});
		int removed = 0;
		bar.SetOnTabRemoved(new [&] (tab) => { ++removed; });

		let d = root.EventDispatcher;
		Press(d, CentreOf(b.ClosePart));
		Test.Assert(requests == 1);
		Test.Assert(asked == 1);
		Test.Assert(bar.TabCount == 3);
		Test.Assert(bar.SelectedIndex == 1); // the close part's press does not select either

		keep = false;
		Press(d, CentreOf(b.ClosePart));
		Test.Assert(requests == 2);
		Test.Assert(bar.TabCount == 2);
		Test.Assert(removed == 1);
		// The selected tab went: the one after it takes its place.
		Test.Assert(bar.SelectedIndex == 1);
		Test.Assert(bar.SelectedTab.Text == "C");

		// A middle click closes too; a tab not closable ignores both.
		let a = bar.GetTab(0);
		a.Closable = false;
		root.UpdateLayout();
		Press(d, CentreOf(a), .Middle);
		Test.Assert(bar.TabCount == 2);
		root.UpdateLayout();
		Press(d, CentreOf(bar.GetTab(1)), .Middle);
		Test.Assert(bar.TabCount == 1);
		Test.Assert(bar.SelectedIndex == 0);
	}

	[Test]
	public static void ReorderableATabDraggedAcrossANeighboursMidpointChangesPlacesWithIt()
	{
		let root = MakeRoot();
		defer root.ReleaseRef();
		let bar = new TabBar();
		defer bar.ReleaseRef();
		root.AddChild(bar);
		let a = AddSizedTab(bar, "A");
		AddSizedTab(bar, "B");
		AddSizedTab(bar, "C");
		int32 movedFrom = -1;
		int32 movedTo = -1;
		bar.SetOnTabMoved(new [&] (from, to) =>
			{
				movedFrom = from;
				movedTo = to;
			});
		root.UpdateLayout();
		let d = root.EventDispatcher;
		let start = CentreOf(a);

		// Not reorderable: a drag moves nothing.
		d.InjectMouseDown(start, .Left);
		d.InjectMouseMove(.(start.X + 100.0f, start.Y));
		d.InjectMouseUp(.(start.X + 100.0f, start.Y), .Left);
		Test.Assert(bar.IndexOf(a) == 0);

		bar.Reorderable = true;
		d.InjectMouseDown(start, .Left);
		d.InjectMouseMove(.(start.X + 30.0f, start.Y)); // short of B's midpoint (82 + 40 from A's left)
		Test.Assert(bar.IndexOf(a) == 0);
		d.InjectMouseMove(.(start.X + 90.0f, start.Y)); // past it
		Test.Assert(bar.IndexOf(a) == 1);
		Test.Assert(movedFrom == 0);
		Test.Assert(movedTo == 1);
		Test.Assert(a.HasClass("dragging"));
		root.UpdateLayout();
		d.InjectMouseMove(.(start.X + 180.0f, start.Y)); // past C's
		Test.Assert(bar.IndexOf(a) == 2);
		root.UpdateLayout();
		d.InjectMouseMove(.(start.X + 60.0f, start.Y)); // back past C's again (now before it)
		Test.Assert(bar.IndexOf(a) == 1);
		d.InjectMouseUp(.(start.X + 60.0f, start.Y), .Left);
		Test.Assert(!a.HasClass("dragging"));
		Test.Assert(a.IsSelected); // it stays the selected tab wherever it goes
	}

	[Test]
	public static void TabsPastTheStripsEndScrollItASelectedOneIsScrolledToAndAButtonListsThemAll()
	{
		let root = MakeRoot(300.0f);
		defer root.ReleaseRef();
		let bar = new TabBar();
		defer bar.ReleaseRef();
		root.AddChild(bar);
		AddSizedTab(bar, "A");
		AddSizedTab(bar, "B");
		root.UpdateLayout();
		Test.Assert(!bar.ListButton.Displayed); // they fit

		String[4] more = .("C", "D", "E", "F");
		for (let t in more)
			AddSizedTab(bar, t);
		root.UpdateLayout();
		Test.Assert(bar.ListButton.Displayed);
		Test.Assert(bar.Strip.ScrollRange.X > 0.0f);

		bar.SelectedIndex = 5;
		root.UpdateLayout();
		let strip = bar.Strip.ScreenBounds;
		let last = bar.GetTab(5).ScreenBounds;
		Test.Assert(last.X + last.Width <= strip.X + strip.Width + 0.5f);

		// The wheel turns the strip across (it scrolls on one axis only).
		bar.SelectedIndex = 0;
		bar.Strip.ScrollOffset = .(0.0f, 0.0f);
		root.UpdateLayout();
		let d = root.EventDispatcher;
		d.InjectMouseWheel(CentreOf(bar.GetTab(0)), .(0.0f, -1.0f));
		Test.Assert(bar.Strip.ScrollOffset.X > 0.0f);

		// The list: every tab, the selected one checked; picking one selects it.
		Press(d, CentreOf(bar.ListButton));
		let menu = bar.TabListMenu;
		Test.Assert(menu != null);
		Test.Assert(menu.ItemCount == 6);
		d.InjectKeyDown((uint32)KeyCode.Down);
		d.InjectKeyDown((uint32)KeyCode.Down);
		d.InjectKeyDown((uint32)KeyCode.Down);
		d.InjectKeyDown((uint32)KeyCode.Return);
		Test.Assert(bar.SelectedIndex == 2);
		Test.Assert(bar.TabListMenu == null);
	}

	[Test]
	public static void TheListButtonShowsAlwaysWhenAskedCloseAllAsksToCloseEveryClosableTabLastFirst()
	{
		let root = MakeRoot();
		defer root.ReleaseRef();
		let bar = new TabBar();
		defer bar.ReleaseRef();
		root.AddChild(bar);
		AddSizedTab(bar, "A");
		AddSizedTab(bar, "B");
		let pinned = AddSizedTab(bar, "C");
		pinned.Closable = false;
		root.UpdateLayout();
		Test.Assert(!bar.ListButton.Displayed); // they fit
		Test.Assert(!bar.CloseAllPart.Displayed); // not asked for
		bar.ListDisplay = .Always;
		bar.ShowsCloseAll = true;
		root.UpdateLayout();
		Test.Assert(bar.ListButton.Displayed);
		Test.Assert(bar.CloseAllPart.Displayed);
		// Past the list button, both past the strip.
		let list = bar.ListButton.ScreenBounds;
		let all = bar.CloseAllPart.ScreenBounds;
		Test.Assert(all.X >= list.X + list.Width - 0.5f);
		Test.Assert(list.X >= bar.Strip.ScreenBounds.X + bar.Strip.ScreenBounds.Width - 0.5f);

		let asked = scope List<String>();
		defer { ClearAndDeleteItems!(asked); }
		bar.AddEventListener(.TabClose, new [&] (e) =>
			{
				asked.Add(new String(bar.GetTab(((TabEvent)e).Index).Text));
			});
		let d = root.EventDispatcher;
		Press(d, CentreOf(bar.CloseAllPart));
		Test.Assert(asked.Count == 2);
		Test.Assert(asked[0] == "B");
		Test.Assert(asked[1] == "A");
		Test.Assert(bar.TabCount == 1);
		Test.Assert(bar.GetTab(0) == pinned);
		Test.Assert(!bar.CloseAllPart.Displayed); // none closable is left
		pinned.Closable = true;
		Test.Assert(bar.CloseAllPart.Displayed);

		// An owner that makes its tabs again after each close (docking does): every one still closes.
		let owned = new TabBar();
		defer owned.ReleaseRef();
		root.AddChild(owned);
		String[3] names = .("P", "Q", "R");
		for (let t in names)
			AddSizedTab(owned, t);
		owned.SetCloseHandler(new [&] (index) =>
			{
				let rest = scope List<String>();
				defer { ClearAndDeleteItems!(rest); }
				for (int32 i = 0; i < owned.TabCount; ++i)
				{
					if (i != index)
						rest.Add(new String(owned.GetTab(i).Text));
				}
				while (owned.TabCount > 0)
					owned.RemoveTab(0);
				for (let t in rest)
					owned.AddTab(t);
			});
		owned.CloseAll();
		Test.Assert(owned.TabCount == 0);
	}

	[Test]
	public static void CloseAllClosesEveryClosablePageThroughTheViewsOwnRequest()
	{
		let root = MakeRoot();
		defer root.ReleaseRef();
		let view = new TabView();
		defer view.ReleaseRef();
		root.AddChild(view);
		view.ShowsCloseAll = true;
		String[3] titles = .("A", "B", "C");
		for (let t in titles)
			view.AddPage(t);
		int requests = 0;
		view.AddEventListener(.TabClose, new [&] (e) =>
			{
				++requests;
				if (((TabEvent)e).Index == 0)
					e.Handled = true; // the first is kept (an unsaved document asks first)
			});
		view.Bar.CloseAll();
		Test.Assert(requests == 3);
		Test.Assert(view.PageCount == 1);
		Test.Assert(view.Bar.GetTab(0).Text == "A");
	}

	[Test]
	public static void APagesClassesForItsTabReachTheTabSetBeforeItHasOneOrAfterEachSetReplacingTheLast()
	{
		let root = MakeRoot();
		defer root.ReleaseRef();
		let view = new TabView();
		defer view.ReleaseRef();
		root.AddChild(view);
		let early = new TabPage();
		defer early.ReleaseRef();
		early.Title = "Early";
		early.TabClasses = "dirty  pinned";
		view.AddPage(early);
		let tab = early.Tab;
		Test.Assert(tab != null);
		Test.Assert(tab.HasClass("dirty"));
		Test.Assert(tab.HasClass("pinned"));
		Test.Assert(!early.HasClass("dirty")); // the tab's, not the page's

		early.TabClasses = "pinned";
		Test.Assert(!tab.HasClass("dirty"));
		Test.Assert(tab.HasClass("pinned"));
		early.TabClasses = "";
		Test.Assert(!tab.HasClass("pinned"));

		RegisterGuiElements();
		let loader = scope MarkupLoader(root.ElementSet);
		let tree = loader.LoadFromString("<TabView><TabPage title=\"Scene\" tab-class=\"dirty\"/></TabView>");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();
		let marked = tree as TabView;
		Test.Assert(marked != null);
		Test.Assert(marked.Bar.GetTab(0).HasClass("dirty"));
	}

	[Test]
	public static void InRightToLeftATabDraggedTowardTheLeftPassesTheNextOne()
	{
		let root = MakeRoot();
		defer root.ReleaseRef();
		root.SetLayoutDirection(.RightToLeft);
		let bar = new TabBar();
		defer bar.ReleaseRef();
		root.AddChild(bar);
		bar.Reorderable = true;
		let a = AddSizedTab(bar, "A");
		let b = AddSizedTab(bar, "B");
		AddSizedTab(bar, "C");
		root.UpdateLayout();
		Test.Assert(CentreOf(a).X > CentreOf(b).X); // the first tab at the right
		let d = root.EventDispatcher;
		let start = CentreOf(a);
		d.InjectMouseDown(start, .Left);
		d.InjectMouseMove(.(start.X - 30.0f, start.Y)); // short of B's midpoint
		Test.Assert(bar.IndexOf(a) == 0);
		d.InjectMouseMove(.(start.X - 90.0f, start.Y)); // past it, toward the inline end
		Test.Assert(bar.IndexOf(a) == 1);
		d.InjectMouseUp(.(start.X - 90.0f, start.Y), .Left);
		root.UpdateLayout();
		d.InjectMouseDown(CentreOf(a), .Left);
		d.InjectMouseMove(.(CentreOf(a).X + 90.0f, start.Y)); // back toward the inline start
		Test.Assert(bar.IndexOf(a) == 0);
		d.InjectMouseUp(.(CentreOf(a).X, start.Y), .Left);
	}

	[Test]
	public static void ACloseRequestReachesTheViewAndUnlessTakenThePageAndItsTabGoADragMovesThePageToo()
	{
		let root = MakeRoot();
		defer root.ReleaseRef();
		let view = new TabView();
		defer view.ReleaseRef();
		root.AddChild(view);
		view.Bar.CloseDisplay = .Always;
		view.Reorderable = true;
		String[3] names = .("A", "B", "C");
		for (let t in names)
			view.AddPage(t).Tab.EditLayoutStyle(scope (s) => { s.Width = LayoutLength.Px(80.0f); });
		let pageA = view.GetPage(0);
		root.UpdateLayout();

		bool keep = false;
		int32 asked = -1;
		view.AddEventListener(.TabClose, new [&] (e) =>
			{
				asked = ((TabEvent)e).Index;
				e.Handled = keep;
			});
		let d = root.EventDispatcher;
		Press(d, CentreOf(view.Bar.GetTab(1).ClosePart));
		Test.Assert(asked == 1);
		Test.Assert(view.PageCount == 2);
		Test.Assert(view.ChildHost.ChildCount == 2);
		Test.Assert((view.GetPage(1) as TabPage).Title == "C");

		keep = true;
		root.UpdateLayout();
		Press(d, CentreOf(view.Bar.GetTab(1).ClosePart));
		Test.Assert(view.PageCount == 2);

		// A drag of A past C: the pages keep the tabs' order.
		root.UpdateLayout();
		let start = CentreOf(view.Bar.GetTab(0));
		d.InjectMouseDown(start, .Left);
		d.InjectMouseMove(.(start.X + 90.0f, start.Y));
		d.InjectMouseUp(.(start.X + 90.0f, start.Y), .Left);
		Test.Assert(view.GetPage(1) == pageA);
		Test.Assert(view.ChildHost.GetChildAt(1) == pageA);
		Test.Assert(view.SelectedPage == pageA);

		// Code removing a page takes its tab.
		view.RemovePage(0);
		Test.Assert(view.PageCount == 1);
		Test.Assert(view.Bar.TabCount == 1);
		Test.Assert(view.SelectedPage == pageA);
	}

	[Test]
	public static void APageWithAContentFactoryIsBuiltTheFirstTimeItIsShown()
	{
		let root = MakeRoot();
		defer root.ReleaseRef();
		let view = new TabView();
		defer view.ReleaseRef();
		root.AddChild(view);
		view.AddPage("Light");
		let heavy = view.AddPage("Heavy");
		int built = 0;
		heavy.SetContentFactory(new [&] (page) =>
			{
				++built;
				let label = new Label();
				page.AddChild(label);
				label.ReleaseRef();
			});
		Test.Assert(built == 0);
		view.SelectedIndex = 1;
		Test.Assert(built == 1);
		Test.Assert(heavy.ChildCount == 1);
		view.SelectedIndex = 0;
		view.SelectedIndex = 1;
		Test.Assert(built == 1);
	}

	[Test]
	public static void InAGroupsStripATabMovedPastTheThresholdAnyWayIsADragThatAStripOfItsGroupTakesWhereTheMarkIs()
	{
		let root = MakeRoot();
		defer root.ReleaseRef();
		let top = BarAt(root, 10.0f, "docs");
		defer top.ReleaseRef();
		let bottom = BarAt(root, 150.0f, "docs");
		defer bottom.ReleaseRef();
		let other = BarAt(root, 250.0f, "tools");
		defer other.ReleaseRef();
		AddSizedTab(top, "A");
		let b = AddSizedTab(top, "B");
		AddSizedTab(bottom, "X");
		AddSizedTab(bottom, "Y");
		AddSizedTab(other, "T");
		root.UpdateLayout();
		let d = root.EventDispatcher;

		let start = CentreOf(b);
		d.InjectMouseDown(start, .Left);
		d.InjectMouseMove(.(start.X + 3.0f, start.Y)); // within the threshold (6)
		Test.Assert(!d.IsDragging);
		d.InjectMouseMove(.(start.X + 8.0f, start.Y)); // along the strip: a drag at once
		Test.Assert(d.IsDragging);
		Test.Assert(d.DragPayload.Type == "gui/tab");
		Test.Assert(d.DragPayload.Label == "B");

		// Over the other group's strip: nothing takes it.
		d.InjectMouseMove(CentreOf(other.GetTab(0)));
		Test.Assert(d.DropTarget == null);
		// Over the bottom strip, left of Y's middle: between X and Y.
		let y = bottom.GetTab(1).ScreenBounds;
		d.InjectMouseMove(.(y.X + 10.0f, y.Y + 10.0f));
		Test.Assert(d.DropTarget == bottom);
		Test.Assert(bottom.DropIndex == 1);
		d.InjectMouseUp(.(y.X + 10.0f, y.Y + 10.0f), .Left);
		Test.Assert(top.TabCount == 1);
		Test.Assert(bottom.TabCount == 3);
		Test.Assert(bottom.GetTab(1) == b); // the tab itself moved
		Test.Assert(bottom.SelectedTab == b);
		Test.Assert(bottom.DropIndex == -1);
	}

	[Test]
	public static void InAGroupsStripATabDroppedBackIntoItReordersItNotReorderableItsStripDoesNotTakeIt()
	{
		let root = MakeRoot();
		defer root.ReleaseRef();
		let top = BarAt(root, 10.0f, "docs");
		defer top.ReleaseRef();
		let a = AddSizedTab(top, "A");
		AddSizedTab(top, "B");
		let c = AddSizedTab(top, "C");
		root.UpdateLayout();
		let d = root.EventDispatcher;

		// A along the strip past C's middle: no slide on the way, then last at the drop.
		let start = CentreOf(a);
		d.InjectMouseDown(start, .Left);
		let cr = c.ScreenBounds;
		let end = Float2(cr.X + cr.Width - 4.0f, start.Y);
		d.InjectMouseMove(.(start.X + 10.0f, start.Y));
		Test.Assert(d.IsDragging);
		d.InjectMouseMove(end);
		Test.Assert(top.GetTab(0) == a); // nothing slid
		Test.Assert(d.DropTarget == top);
		Test.Assert(top.DropIndex == 3);
		d.InjectMouseUp(end, .Left);
		Test.Assert(top.GetTab(2) == a);
		Test.Assert(top.SelectedTab == a);

		top.Reorderable = false;
		let again = CentreOf(a);
		d.InjectMouseDown(again, .Left);
		d.InjectMouseMove(.(again.X - 10.0f, again.Y));
		Test.Assert(d.IsDragging); // its group still takes it elsewhere
		d.InjectMouseMove(CentreOf(top.GetTab(0)));
		Test.Assert(d.DropTarget != top);
		d.InjectMouseUp(CentreOf(top.GetTab(0)), .Left);
		Test.Assert(top.GetTab(2) == a);
	}

	[Test]
	public static void AnOwnerAnswersATabOfferedToAStripARefusalWithItsReasonOrPassedOnAndTakesADroppedOneOver()
	{
		let root = MakeRoot();
		defer root.ReleaseRef();
		let top = BarAt(root, 10.0f, "docs");
		defer top.ReleaseRef();
		let bottom = BarAt(root, 150.0f, "docs");
		defer bottom.ReleaseRef();
		let a = AddSizedTab(top, "A");
		AddSizedTab(top, "B");
		AddSizedTab(bottom, "X");
		AddSizedTab(bottom, "Y");
		root.UpdateLayout();
		let d = root.EventDispatcher;
		bool refuse = true;
		Tab offered = null;
		bottom.SetOnTabOffered(new [&] (query, tab, index) =>
			{
				offered = tab;
				if (refuse)
					query.Refuse("no room");
				else
				{
					query.Reason.Clear();
					query.Reason.AppendF("to {}", index);
				}
			});
		Tab taken = null;
		int32 takenAt = -1;
		bottom.SetTabTaker(new [&] (tab, index) =>
			{
				taken = tab;
				takenAt = index;
			});

		let start = CentreOf(a);
		d.InjectMouseDown(start, .Left);
		d.InjectMouseMove(.(start.X, start.Y + 60.0f));
		Test.Assert(d.IsDragging);
		let y = bottom.GetTab(1).ScreenBounds;
		let at = Float2(y.X + 10.0f, y.Y + 10.0f);
		d.InjectMouseMove(at);
		Test.Assert(offered == a);
		Test.Assert(d.DropTarget == null);
		Test.Assert(d.DropReason == "no room");
		Test.Assert(bottom.DropIndex == -1); // no mark where it may not go
		refuse = false;
		d.InjectMouseMove(.(at.X + 1.0f, at.Y));
		Test.Assert(d.DropTarget == bottom);
		Test.Assert(d.DropReason == "to 1");
		Test.Assert(bottom.DropIndex == 1);
		d.InjectMouseUp(.(at.X + 1.0f, at.Y), .Left);
		Test.Assert(taken == a);
		Test.Assert(takenAt == 1);
		Test.Assert(top.TabCount == 2); // the bar moved nothing
		Test.Assert(bottom.TabCount == 2);
		Test.Assert(bottom.DropIndex == -1);

		// Passed on (its effect set back to none): no mark, and what holds the strip is asked.
		bool askedAbove = false;
		bottom.SetOnTabOffered(new (query, tab, index) => { query.Effect = .None; });
		root.SetOnDragQuery(new [&] (query) =>
			{
				askedAbove = true;
				query.Accept(.Move);
			});
		let b = CentreOf(top.GetTab(1));
		d.InjectMouseDown(b, .Left);
		d.InjectMouseMove(.(b.X, b.Y + 60.0f));
		Test.Assert(d.IsDragging);
		d.InjectMouseMove(at);
		Test.Assert(askedAbove);
		Test.Assert(d.DropTarget == root);
		Test.Assert(bottom.DropIndex == -1);
		d.InjectKeyDown((uint32)KeyCode.Escape);
	}

	[Test]
	public static void ATornTabsGhostIsTheTabHeldWhereItWasGrabbedItsBarHearsItTornAndTheDragOverAHiddenTabIsNoPlace()
	{
		let root = MakeRoot();
		defer root.ReleaseRef();
		let top = BarAt(root, 10.0f, "docs");
		defer top.ReleaseRef();
		AddSizedTab(top, "A");
		let b = AddSizedTab(top, "B");
		let c = AddSizedTab(top, "C");
		root.UpdateLayout();
		let d = root.EventDispatcher;
		let heard = scope List<String>();
		defer { ClearAndDeleteItems!(heard); }
		top.SetOnTabTorn(new [&] (tab, torn) => { heard.Add(new String()..AppendF("{} {}", tab.Text, torn ? "torn" : "back")); });

		let from = b.ScreenBounds;
		let press = Float2(from.X + 7.0f, from.Y + 5.0f);
		d.InjectMouseDown(press, .Left);
		let outside = Float2(press.X + 3.0f, press.Y + 60.0f);
		d.InjectMouseMove(outside);
		Test.Assert(d.IsDragging);
		Test.Assert(heard.Count == 1);
		Test.Assert(heard[0] == "B torn");
		let ghost = d.DragPreview as DragPreview;
		Test.Assert(ghost != null);
		Test.Assert(ghost.HasClass("tab"));
		Test.Assert(ghost.Text == "B");
		root.UpdateLayout();
		Test.Assert(Near(ghost.Size.X, from.Width));
		Test.Assert(Near(ghost.Size.Y, from.Height));
		let held = ghost.ScreenBounds;
		Test.Assert(Near(held.X, outside.X - 7.0f)); // the press's place on it, under the pointer
		Test.Assert(Near(held.Y, outside.Y - 5.0f));

		// Hidden (as an owner may while it is torn): counted, but no place of its own. Left of C's
		// middle is before C (2), past the hidden B.
		b.Displayed = false;
		root.UpdateLayout();
		let cr = c.ScreenBounds;
		d.InjectMouseMove(.(cr.X + 3.0f, cr.Y + 5.0f));
		Test.Assert(top.DropIndex == 2);
		d.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(!d.IsDragging);
		Test.Assert(heard.Count == 2);
		Test.Assert(heard[1] == "B back");
	}

	[Test]
	public static void TheBarATabWasTornFromHearsHowItsDragEndedCancelledOrLetGoOutsideTheWindow()
	{
		let root = MakeRoot();
		defer root.ReleaseRef();
		let top = BarAt(root, 10.0f, "docs");
		defer top.ReleaseRef();
		AddSizedTab(top, "A");
		let b = AddSizedTab(top, "B");
		root.UpdateLayout();
		let d = root.EventDispatcher;
		int ends = 0;
		var last = DragResult();
		Tab whose = null;
		top.SetOnTabDragEnded(new [&] (tab, result) =>
			{
				++ends;
				last = result;
				whose = tab;
			});
		let from = b.ScreenBounds;
		let press = Float2(from.X + 7.0f, from.Y + 5.0f);
		d.InjectMouseDown(press, .Left);
		d.InjectMouseMove(.(press.X, press.Y + 60.0f));
		Test.Assert(d.IsDragging);
		d.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(ends == 1);
		Test.Assert(whose == b);
		Test.Assert(last.Cancelled);
		Test.Assert(!last.Outside);

		d.InjectMouseDown(press, .Left);
		d.InjectMouseMove(.(press.X, press.Y + 60.0f));
		d.InjectMouseMove(.(-40.0f, press.Y)); // past the root's edge
		d.InjectMouseUp(.(-40.0f, press.Y), .Left);
		Test.Assert(ends == 2);
		Test.Assert(last.Outside);
		Test.Assert(last.Target == null);
	}

	[Test]
	public static void ATabOfAGroupIsPickedUpFromTheKeyboardAndDroppedOnAStripsTabItIsMovedTo()
	{
		let root = MakeRoot();
		defer root.ReleaseRef();
		let top = BarAt(root, 10.0f, "docs");
		defer top.ReleaseRef();
		let bottom = BarAt(root, 150.0f, "docs");
		defer bottom.ReleaseRef();
		let alone = BarAt(root, 250.0f, "");
		defer alone.ReleaseRef();
		let a = AddSizedTab(top, "A");
		AddSizedTab(top, "B");
		AddSizedTab(bottom, "X");
		let y = AddSizedTab(bottom, "Y");
		let t = AddSizedTab(alone, "T");
		root.UpdateLayout();
		let d = root.EventDispatcher;
		t.RequestFocus();
		Test.Assert(!d.PickDrag()); // a strip of no group: nowhere for it to go
		a.RequestFocus();
		Test.Assert(d.PickDrag());
		Test.Assert(d.IsKeyboardDrag);
		Test.Assert(d.DragPayload.Type == "gui/tab");
		y.RequestFocus(); // the focus moves as ever; the strip asked is the focused tab's
		Test.Assert(d.DropTarget == bottom);
		d.InjectKeyDown((uint32)KeyCode.Return);
		Test.Assert(!d.IsDragging);
		Test.Assert(top.TabCount == 1);
		Test.Assert(bottom.TabCount == 3);
		Test.Assert(bottom.IndexOf(a) >= 1);
	}

	[Test]
	public static void ATabTornOutOfOneTabViewAndDroppedOnAnotherOfItsGroupBringsItsPage()
	{
		let root = MakeRoot();
		defer root.ReleaseRef();
		let left = new TabView();
		defer left.ReleaseRef();
		let right = new TabView();
		defer right.ReleaseRef();
		PlaceView(left, 10.0f, 100.0f);
		PlaceView(right, 160.0f, 100.0f);
		root.AddChild(left);
		root.AddChild(right);
		TabView[2] views = .(left, right);
		for (let v in views)
		{
			v.Reorderable = true;
			v.Group = "docs";
		}
		left.AddPage("One");
		let two = left.AddPage("Two");
		let label = new Label();
		defer label.ReleaseRef();
		two.AddChild(label);
		right.AddPage("Three");
		for (let v in views)
			SizeTabs(v);
		root.UpdateLayout();
		let d = root.EventDispatcher;

		let start = CentreOf(left.Bar.GetTab(1));
		d.InjectMouseDown(start, .Left);
		d.InjectMouseMove(.(start.X, start.Y + 80.0f));
		Test.Assert(d.IsDragging);
		let three = right.Bar.GetTab(0).ScreenBounds;
		d.InjectMouseMove(.(three.X + three.Width - 5.0f, three.Y + 10.0f)); // after Three
		Test.Assert(right.Bar.DropIndex == 1);
		d.InjectMouseUp(.(three.X + three.Width - 5.0f, three.Y + 10.0f), .Left);
		Test.Assert(left.PageCount == 1);
		Test.Assert(right.PageCount == 2);
		Test.Assert(right.GetPage(1) == two); // the page itself, what it holds with it
		Test.Assert(two.ChildCount == 1);
		Test.Assert(right.SelectedPage == two);
		Test.Assert(right.Bar.GetTab(1).Text == "Two");
	}

	[Test]
	public static void ATornOutTabDroppedOnAnotherViewsPageAreaNotItsStripGoesLastThere()
	{
		let root = MakeRoot();
		defer root.ReleaseRef();
		let left = new TabView();
		defer left.ReleaseRef();
		let right = new TabView();
		defer right.ReleaseRef();
		PlaceView(left, 10.0f, 120.0f);
		PlaceView(right, 160.0f, 120.0f);
		root.AddChild(left);
		root.AddChild(right);
		TabView[2] views = .(left, right);
		for (let v in views)
		{
			v.Reorderable = true;
			v.Group = "docs";
		}
		left.AddPage("One");
		let two = left.AddPage("Two");
		right.AddPage("Three");
		for (let v in views)
			SizeTabs(v);
		root.UpdateLayout();
		let d = root.EventDispatcher;
		let start = CentreOf(left.Bar.GetTab(1));
		d.InjectMouseDown(start, .Left);
		d.InjectMouseMove(.(start.X, start.Y + 80.0f));
		Test.Assert(d.IsDragging);
		d.InjectMouseMove(.(200.0f, 240.0f)); // the middle of the right view's page
		Test.Assert(d.DropTarget == right);
		Test.Assert(right.Bar.DropIndex == 1);
		d.InjectMouseUp(.(200.0f, 240.0f), .Left);
		Test.Assert(right.PageCount == 2);
		Test.Assert(right.GetPage(1) == two);
	}

	[Test]
	public static void APageAskedForBeforeItIsThereWaitsTheFirstIsNotShownNorBuiltOnTheWayAPageMovedIsReported()
	{
		let root = MakeRoot();
		defer root.ReleaseRef();
		let view = new TabView();
		defer view.ReleaseRef();
		root.AddChild(view);
		int built = 0;
		view.SelectedIndex = 1; // the second, which is not there yet
		let first = new TabPage();
		defer first.ReleaseRef();
		first.SetContentFactory(new [&] (page) => { ++built; });
		view.AddPage(first);
		Test.Assert(view.SelectedIndex == -1); // waiting, the first not selected meanwhile
		Test.Assert(built == 0);
		let second = new TabPage();
		defer second.ReleaseRef();
		second.SetContentFactory(new [&] (page) => { built += 10; });
		view.AddPage(second);
		Test.Assert(view.SelectedIndex == 1);
		Test.Assert(built == 10); // the second alone shown, and built

		int32 movedTo = -1;
		view.SetOnPageMoved(new [&] (to) => { movedTo = to; });
		view.Bar.MoveTab(1, 0);
		Test.Assert(movedTo == 0);
		Test.Assert(view.GetPage(0) == second);
	}

	[Test]
	public static void PagesPairWithTabsOnlyTheSelectedOneShowsHiddenOnesStayAliveCtrlTabFromInsideAPage()
	{
		let root = MakeRoot();
		defer root.ReleaseRef();
		let view = new TabView();
		defer view.ReleaseRef();
		view.EditLayoutStyle(scope (s) => { s.Height = LayoutLength.Px(200.0f); });
		root.AddChild(view);
		let first = view.AddPage("First");
		let second = view.AddPage("Second");
		let field = new TextField();
		defer field.ReleaseRef();
		second.AddChild(field);
		SizeTabs(view);
		root.UpdateLayout();

		Test.Assert(view.PageCount == 2);
		Test.Assert(view.Bar.GetTab(1).Text == "Second");
		Test.Assert(first.Tab == view.Bar.GetTab(0));
		Test.Assert(first.Displayed);
		Test.Assert(!second.Displayed);
		Test.Assert(first.Size.Y > 100.0f); // a page fills what the bar leaves

		second.Title = "Renamed"; // its tab follows it
		Test.Assert(view.Bar.GetTab(1).Text == "Renamed");

		int changes = 0;
		view.AddEventListener(.Changed, new [&] (e) => { ++changes; });
		let d = root.EventDispatcher;
		Press(d, CentreOf(view.Bar.GetTab(1)));
		Test.Assert(view.SelectedIndex == 1);
		Test.Assert(changes == 1);
		Test.Assert(!first.Displayed);
		Test.Assert(second.Displayed);
		Test.Assert(first.Parent != null); // kept alive

		// Ctrl+Tab with the focus in a page.
		field.RequestFocus();
		d.InjectKeyDown((uint32)KeyCode.Tab, KeyModCtrl);
		Test.Assert(view.SelectedIndex == 0);
		Test.Assert(changes == 2);
	}

	[Test]
	public static void MarkupsPagesAreItsChildrenWithTitleIconAndClosableItsBarsSettingsAreAttributes()
	{
		RegisterGuiElements();
		let elements = scope ElementSet();
		let loader = scope MarkupLoader(elements);
		let tree = loader.LoadFromString(
			"<TabView close-display=\"hover\" reorderable=\"true\" selected=\"1\" list-display=\"always\" close-all=\"true\">\n" +
			"    <TabPage title=\"General\"><Label text=\"one\"/></TabPage>\n" +
			"    <TabPage title=\"Advanced\" closable=\"false\" icon=\"ui/icons/gear.png\"/>\n" +
			"</TabView>");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();
		let view = tree as TabView;
		Test.Assert(view != null);
		Test.Assert(view.PageCount == 2);
		Test.Assert(view.Bar.GetTab(0).Text == "General");
		Test.Assert(!view.Bar.GetTab(1).Closable);
		Test.Assert(view.Bar.GetTab(1).Icon == "ui/icons/gear.png");
		Test.Assert(view.Bar.CloseDisplay == .Hover);
		Test.Assert(view.Reorderable);
		Test.Assert(view.SelectedIndex == 1);
		Test.Assert(view.Bar.ListDisplay == .Always);
		Test.Assert(view.ShowsCloseAll);

		// A bar alone: markup's children are its tabs.
		let barTree = loader.LoadFromString("<TabBar><Tab text=\"One\"/><Tab text=\"Two\" icon=\"a.png\"/></TabBar>");
		Test.Assert(barTree != null);
		defer barTree.ReleaseRef();
		let bar = barTree as TabBar;
		Test.Assert(bar != null);
		Test.Assert(bar.TabCount == 2);
		Test.Assert(bar.SelectedIndex == 0);
		Test.Assert(bar.GetTab(1).Icon == "a.png");
	}
}
