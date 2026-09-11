using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Gamekit;

namespace Sedulous.UI.Gamekit.Tests;

/// A menu list is a vertical flex layout of focusable button rows. These cover row creation,
/// the wrap around Up and Down chain, activation, and selection following focus.
class MenuListTests
{
	private static MenuList Attach(WidgetBed bed)
	{
		let menu = new MenuList();
		bed.Root.AddView(menu); // attaches the menu, and its rows, to the context
		return menu;
	}

	[Test]
	public static void AddItemAppendsFocusableRows()
	{
		let bed = scope WidgetBed();
		let menu = Attach(bed);

		Test.Assert(menu.ItemCount == 0);
		let a = menu.AddItem("Start");
		let b = menu.AddItem("Options");
		let c = menu.AddItem("Quit");

		Test.Assert(menu.ItemCount == 3);
		Test.Assert(menu.ItemAt(0) == a);
		Test.Assert(menu.ItemAt(2) == c);
		Test.Assert(menu.ItemAt(3) == null, "out of range");
		Test.Assert(menu.ChildCount == 3, "the rows are the menu's children");
		Test.Assert(a.IsFocusable);
		Test.Assert(b.IsFocusable);
		Test.Assert(c.IsFocusable);
	}

	[Test]
	public static void TheUpAndDownFocusChainWrapsAround()
	{
		let bed = scope WidgetBed();
		let menu = Attach(bed);

		let a = menu.AddItem("A");
		let b = menu.AddItem("B");
		let c = menu.AddItem("C");

		Test.Assert(a.NextFocusDown.HasValue);
		Test.Assert(a.NextFocusDown.Value == b.Id);
		Test.Assert(b.NextFocusDown.Value == c.Id);
		Test.Assert(c.NextFocusDown.Value == a.Id, "the last row wraps to the first");
		Test.Assert(a.NextFocusUp.Value == c.Id, "the first row wraps to the last");
		Test.Assert(b.NextFocusUp.Value == a.Id);
		Test.Assert(c.NextFocusUp.Value == b.Id);
	}

	[Test]
	public static void ActivatingARowFiresItsCallbackAndOnItemActivated()
	{
		let bed = scope WidgetBed();
		let menu = Attach(bed);

		var picked = -1;
		var activatedIndex = -1;
		menu.OnItemActivated.Add(new [&activatedIndex](list, index) => { activatedIndex = index; });
		menu.AddItem("First", new [&picked]() => { picked = 0; });
		let second = menu.AddItem("Second", new [&picked]() => { picked = 1; });

		second.FireClick();
		Test.Assert(picked == 1);
		Test.Assert(activatedIndex == 1);
	}

	[Test]
	public static void SelectionFollowsFocus()
	{
		let bed = scope WidgetBed();
		let menu = Attach(bed);

		menu.AddItem("A");
		menu.AddItem("B");
		menu.AddItem("C");

		Test.Assert(menu.SelectedIndex == -1, "nothing is focused yet");
		menu.SetSelectedIndex(1);
		Test.Assert(menu.SelectedIndex == 1);
		menu.FocusFirst();
		Test.Assert(menu.SelectedIndex == 0);
		menu.SetSelectedIndex(99); // out of range leaves the selection alone
		Test.Assert(menu.SelectedIndex == 0);
	}

	[Test]
	public static void ClearItemsEmptiesTheList()
	{
		let bed = scope WidgetBed();
		let menu = Attach(bed);

		menu.AddItem("A");
		menu.AddItem("B");
		Test.Assert(menu.ItemCount == 2);

		menu.ClearItems();
		Test.Assert(menu.ItemCount == 0);
		Test.Assert(menu.ChildCount == 0);
	}
}
