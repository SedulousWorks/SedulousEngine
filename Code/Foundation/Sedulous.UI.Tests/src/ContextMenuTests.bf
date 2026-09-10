using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The popup menu: its rows, and the scrolling that keeps a long one usable.
class ContextMenuTests
{
	/// A menu of `count` identical rows, measured and laid out against a 400 by 300 box.
	private static ContextMenu MakeTallMenu(int32 count)
	{
		let menu = new ContextMenu();
		for (int32 i < count)
			menu.AddItem("Item", null);

		menu.Measure(BoxConstraints.Loose(400, 300));
		menu.Layout(0, 0, menu.MeasuredSize.X, menu.MeasuredSize.Y);
		return menu;
	}

	private static void MoveTo(ContextMenu menu, float y)
	{
		let move = scope MouseEventArgs();
		move.Set(10, y, .Left);
		menu.OnMouseMove(move);
	}

	// ---- Items --------------------------------------------------------------------------------

	[Test]
	public static void AMenuItemCarriesItsLabelAndState()
	{
		let item = scope MenuItem("Test", null, true);

		Test.Assert(!item.Label.IsEmpty);
		Test.Assert(item.Label == "Test");
		Test.Assert(item.Enabled);
		Test.Assert(!item.IsSeparator);
		Test.Assert(item.Submenu == null);
	}

	[Test]
	public static void ASeparatorHasNoLabelAndNoAction()
	{
		let item = MenuItem.CreateSeparator();
		defer delete item;

		Test.Assert(item.IsSeparator);
		Test.Assert(item.Label.IsEmpty);
		Test.Assert(item.Action == null);
	}

	[Test]
	public static void ItemsAndSeparatorsBothCount()
	{
		let menu = new ContextMenu();
		defer menu.ReleaseRef();

		Test.Assert(menu.ItemCount == 0);

		menu.AddItem("Item 1", null);
		Test.Assert(menu.ItemCount == 1);

		menu.AddSeparator();
		menu.AddItem("Item 2", null);
		Test.Assert(menu.ItemCount == 3);
	}

	[Test]
	public static void ASubmenuRowCarriesAMenuOfItsOwn()
	{
		let menu = new ContextMenu();
		defer menu.ReleaseRef();

		let row = menu.AddSubmenu("More");

		Test.Assert(row != null);
		Test.Assert(row.Submenu != null);
		Test.Assert(row.Label == "More");
		Test.Assert(menu.ItemCount == 1);
	}

	[Test]
	public static void AMenuIsFocusable()
	{
		let menu = new ContextMenu();
		defer menu.ReleaseRef();

		Test.Assert(menu.IsFocusable);
	}

	// ---- Showing ------------------------------------------------------------------------------

	/// Menus are RETAINED views, a menu bar reusing its instances, so hover from the last time
	/// it was open must not survive into the next show.
	///
	/// The regression this pins: after closing and reopening a project, the File menu came back
	/// with "Close Project" still highlighted, until the pointer first moved.
	[Test]
	public static void ShowingAMenuClearsTheHoverLeftFromLastTime()
	{
		let menu = new ContextMenu();
		defer menu.ReleaseRef();
		menu.AddItem("Open", null);
		menu.AddItem("Close Project", null);

		MoveTo(menu, 10);
		Test.Assert(menu.HoveredIndex >= 0);

		// No active root, so the show cannot go ahead. The hover is cleared before that is
		// even checked, which is the point.
		let context = scope UIContext();
		menu.Show(context, 0, 0);

		Test.Assert(menu.HoveredIndex == -1);
	}

	// ---- Scrolling ----------------------------------------------------------------------------

	/// A menu taller than the room it is given CLAMPS and scrolls, rather than running off the
	/// bottom with its last rows unreachable.
	[Test]
	public static void ATallMenuClampsAndScrollsToItsLastRow()
	{
		let menu = MakeTallMenu(30);
		defer menu.ReleaseRef();

		// 30 rows of 28 plus 8 of frame is 848 of content against a 300 ceiling.
		Test.Assert(menu.MeasuredSize.Y == 300);

		MoveTo(menu, 10);
		Test.Assert(menu.HoveredIndex == 0);

		let wheel = scope MouseWheelEventArgs();
		wheel.Y = 10;
		wheel.DeltaY = -1;
		menu.OnMouseWheel(wheel);
		Test.Assert(wheel.Handled);

		// The rows moved under a stationary pointer, so the row it is over has changed.
		MoveTo(menu, 10);
		Test.Assert(menu.HoveredIndex > 0);

		// Scrolling far past the end clamps, and the LAST row is then reachable at the bottom.
		for (int32 i < 100)
		{
			let more = scope MouseWheelEventArgs();
			more.Y = 10;
			more.DeltaY = -1;
			menu.OnMouseWheel(more);
		}

		MoveTo(menu, 290);
		Test.Assert(menu.HoveredIndex == 29);
	}

	/// A menu that fits leaves the wheel alone, so it bubbles to whatever is behind.
	[Test]
	public static void AMenuThatFitsIgnoresTheWheel()
	{
		let menu = MakeTallMenu(2);
		defer menu.ReleaseRef();

		let wheel = scope MouseWheelEventArgs();
		wheel.Y = 10;
		wheel.DeltaY = -1;
		menu.OnMouseWheel(wheel);

		Test.Assert(!wheel.Handled);

		MoveTo(menu, 10);
		Test.Assert(menu.HoveredIndex == 0, "the rows did not move");
	}

	/// Walking down with the keyboard keeps the highlighted row inside the frame, so by the
	/// last one the menu has scrolled to its end.
	[Test]
	public static void KeyboardNavigationScrollsTheHighlightedRowIntoView()
	{
		let menu = MakeTallMenu(30);
		defer menu.ReleaseRef();

		for (int32 i < 30)
		{
			let down = scope KeyEventArgs();
			down.Set(.Down, .None, false);
			menu.OnKeyDown(down);
		}

		Test.Assert(menu.HoveredIndex == 29);

		// The row under the pointer at the bottom IS the one navigated to.
		MoveTo(menu, 290);
		Test.Assert(menu.HoveredIndex == 29);
	}

	/// Navigation WRAPS and steps over separators, so a menu whose rows are grouped never
	/// lands the highlight on a divider.
	[Test]
	public static void KeyboardNavigationWrapsAndSkipsSeparators()
	{
		let menu = new ContextMenu();
		defer menu.ReleaseRef();
		menu.AddItem("A", null);
		menu.AddSeparator();
		menu.AddItem("B", null);
		menu.Measure(BoxConstraints.Loose(400, 300));
		menu.Layout(0, 0, menu.MeasuredSize.X, menu.MeasuredSize.Y);

		let down = scope KeyEventArgs();
		down.Set(.Down, .None, false);

		menu.OnKeyDown(down);
		Test.Assert(menu.HoveredIndex == 0);

		menu.OnKeyDown(down);
		Test.Assert(menu.HoveredIndex == 2, "stepped over the separator");

		menu.OnKeyDown(down);
		Test.Assert(menu.HoveredIndex == 0, "and wrapped");

		let up = scope KeyEventArgs();
		up.Set(.Up, .None, false);
		menu.OnKeyDown(up);
		Test.Assert(menu.HoveredIndex == 2, "wrapping the other way too");
	}

	/// A separator is not selectable: the pointer over one highlights nothing.
	[Test]
	public static void ASeparatorIsNotSelectable()
	{
		let menu = new ContextMenu();
		defer menu.ReleaseRef();
		menu.AddItem("A", null);
		menu.AddSeparator();
		menu.AddItem("B", null);
		menu.Measure(BoxConstraints.Loose(400, 300));
		menu.Layout(0, 0, menu.MeasuredSize.X, menu.MeasuredSize.Y);

		// The frame's 4 of padding, then a 28 row, puts the separator band at 32 to 40.
		MoveTo(menu, 36);
		Test.Assert(menu.HoveredIndex == -1);
	}

	/// Choosing a row runs its action. A disabled row does not, and neither does a submenu
	/// row, which is entered rather than chosen.
	[Test]
	public static void ChoosingARowRunsItsActionUnlessItCannotBeChosen()
	{
		let menu = new ContextMenu();
		defer menu.ReleaseRef();

		var ran = 0;
		menu.AddItem("Live", new [&ran]() => { ran++; });
		menu.AddItem("Dead", new [&ran]() => { ran++; }, false);
		menu.AddSubmenu("More");
		menu.Measure(BoxConstraints.Loose(400, 300));
		menu.Layout(0, 0, menu.MeasuredSize.X, menu.MeasuredSize.Y);

		let click = scope MouseEventArgs();
		click.Set(10, 10, .Left);
		menu.OnMouseDown(click);
		Test.Assert(ran == 1);
		Test.Assert(click.Handled);

		let onDisabled = scope MouseEventArgs();
		onDisabled.Set(10, 38, .Left);
		menu.OnMouseDown(onDisabled);
		Test.Assert(ran == 1, "a disabled row does nothing");
		Test.Assert(!onDisabled.Handled, "and lets the press past");

		let onSubmenu = scope MouseEventArgs();
		onSubmenu.Set(10, 66, .Left);
		menu.OnMouseDown(onSubmenu);
		Test.Assert(ran == 1, "a submenu row is entered, not chosen");
	}
}
