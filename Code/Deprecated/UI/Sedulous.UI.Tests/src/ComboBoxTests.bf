using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The drop-down selector and the list it opens.
class ComboBoxTests
{
	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root, 400, 300);
	}

	private static ComboBox MakeBox(StringView a, StringView b, StringView c = default)
	{
		let combo = new ComboBox();
		combo.AddItem(a);
		combo.AddItem(b);
		if (!c.IsEmpty)
			combo.AddItem(c);

		return combo;
	}

	// ---- Items --------------------------------------------------------------------------------

	[Test]
	public static void AddingItemsAnswersTheirIndices()
	{
		let combo = new ComboBox();
		defer combo.ReleaseRef();

		Test.Assert(combo.AddItem("A") == 0);
		Test.Assert(combo.AddItem("B") == 1);
		Test.Assert(combo.AddItem("C") == 2);
		Test.Assert(combo.ItemCount == 3);
		Test.Assert(combo.ItemAt(1) == "B");
	}

	[Test]
	public static void RemovingAnItemShortensTheList()
	{
		let combo = MakeBox("A", "B", "C");
		defer combo.ReleaseRef();

		combo.RemoveItem(1);
		Test.Assert(combo.ItemCount == 2);
		Test.Assert(combo.ItemAt(1) == "C", "the rest closed up");

		// Out of range does nothing rather than reaching past the end.
		combo.RemoveItem(99);
		combo.RemoveItem(-1);
		Test.Assert(combo.ItemCount == 2);
	}

	[Test]
	public static void ClearingEmptiesTheListAndTheSelection()
	{
		let combo = MakeBox("A", "B");
		defer combo.ReleaseRef();
		combo.SetSelectedIndex(1);

		combo.ClearItems();

		Test.Assert(combo.ItemCount == 0);
		Test.Assert(combo.SelectedIndex == -1);
	}

	/// Removing an item that leaves the selection past the end pulls it back WITHOUT reporting:
	/// the list shrinking is not the user choosing something else.
	[Test]
	public static void RemovingPastTheSelectionPullsItBackSilently()
	{
		let combo = MakeBox("A", "B", "C");
		defer combo.ReleaseRef();
		combo.SetSelectedIndex(2);

		var reports = 0;
		combo.OnSelectionChanged.Add(new [&reports](b, index) => { reports++; });

		combo.RemoveItem(2);

		Test.Assert(combo.SelectedIndex == 1);
		Test.Assert(reports == 0);
	}

	// ---- Selection ----------------------------------------------------------------------------

	/// Minus one is the empty state, and the clamp runs to it rather than to zero.
	[Test]
	public static void TheSelectionClampsToTheListAndToNothing()
	{
		let combo = MakeBox("A", "B");
		defer combo.ReleaseRef();

		combo.SetSelectedIndex(5);
		Test.Assert(combo.SelectedIndex == 1);

		combo.SetSelectedIndex(-5);
		Test.Assert(combo.SelectedIndex == -1);
	}

	[Test]
	public static void TheSelectedTextIsEmptyUntilSomethingIsChosen()
	{
		let combo = MakeBox("Alpha", "Beta");
		defer combo.ReleaseRef();

		Test.Assert(combo.SelectedText == "");

		combo.SetSelectedIndex(1);
		Test.Assert(combo.SelectedText == "Beta");
	}

	[Test]
	public static void ChoosingReportsTheNewIndexOnceOnly()
	{
		let combo = MakeBox("A", "B");
		defer combo.ReleaseRef();

		var fired = 0;
		var firedIndex = -1;
		combo.OnSelectionChanged.Add(new [&fired, &firedIndex](b, index) =>
			{
				fired++;
				firedIndex = index;
			});

		combo.SetSelectedIndex(1);
		Test.Assert(fired == 1);
		Test.Assert(firedIndex == 1);

		// Setting what it already holds reports nothing.
		combo.SetSelectedIndex(1);
		Test.Assert(fired == 1);
	}

	[Test]
	public static void TheDefaultStateIsEmptyAndClosed()
	{
		let combo = new ComboBox();
		defer combo.ReleaseRef();

		Test.Assert(combo.SelectedIndex == -1);
		Test.Assert(combo.SelectedText == "");
		Test.Assert(!combo.IsOpen);
		Test.Assert(combo.ItemCount == 0);
		Test.Assert(combo.IsFocusable);
		Test.Assert(combo.IsTabStop);
		Test.Assert(combo.WantsArrowKeys);
	}

	// ---- Opening ------------------------------------------------------------------------------

	/// Clicking opens, clicking again closes.
	[Test]
	public static void ClickingOpensAndClosesTheList()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let combo = MakeBox("A", "B");
		root.AddView(combo);
		UITest.LayoutPass(context, root);

		let click = scope MouseEventArgs();
		click.Set(5, 5, .Left);
		combo.OnMouseDown(click);
		Test.Assert(combo.IsOpen);
		Test.Assert(click.Handled);

		let again = scope MouseEventArgs();
		again.Set(5, 5, .Left);
		combo.OnMouseDown(again);
		Test.Assert(!combo.IsOpen);
	}

	/// An EMPTY combo does not open: there would be nothing in the list.
	[Test]
	public static void AnEmptyBoxDoesNotOpen()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let combo = new ComboBox();
		root.AddView(combo);
		UITest.LayoutPass(context, root);

		combo.OpenDropdown();

		Test.Assert(!combo.IsOpen);
	}

	/// The list closing for ANY reason puts the combo back, a click outside included. The combo is
	/// the popup's owner, so the layer tells it.
	[Test]
	public static void TheListClosingFromOutsidePutsTheBoxBack()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let combo = MakeBox("A", "B");
		root.AddView(combo);
		UITest.LayoutPass(context, root);

		combo.OpenDropdown();
		Test.Assert(combo.IsOpen);

		let layer = root.GetPopupLayer();
		Test.Assert(layer.PopupCount == 1);

		// Whatever the layer is closing, the owner is told and stops drawing itself open.
		layer.CloseAllPopups();
		Test.Assert(!combo.IsOpen);
	}

	// ---- Keys ---------------------------------------------------------------------------------

	/// The arrows step the selection WITHOUT opening, so a closed combo can be cycled in place.
	[Test]
	public static void TheArrowsStepTheSelectionWithoutOpening()
	{
		let combo = MakeBox("A", "B", "C");
		defer combo.ReleaseRef();
		combo.SetSelectedIndex(0);

		let down = scope KeyEventArgs();
		down.Set(.Down, .None, false);
		combo.OnKeyDown(down);
		Test.Assert(combo.SelectedIndex == 1);
		Test.Assert(!combo.IsOpen);
		Test.Assert(down.Handled);

		let up = scope KeyEventArgs();
		up.Set(.Up, .None, false);
		combo.OnKeyDown(up);
		Test.Assert(combo.SelectedIndex == 0);

		// And they stop at the ends rather than wrapping.
		let upAgain = scope KeyEventArgs();
		upAgain.Set(.Up, .None, false);
		combo.OnKeyDown(upAgain);
		Test.Assert(combo.SelectedIndex == 0);
	}

	[Test]
	public static void SpaceAndReturnOpenTheList()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let combo = MakeBox("A", "B");
		root.AddView(combo);
		UITest.LayoutPass(context, root);

		let space = scope KeyEventArgs();
		space.Set(.Space, .None, false);
		combo.OnKeyDown(space);
		Test.Assert(combo.IsOpen);
		Test.Assert(space.Handled);

		let escape = scope KeyEventArgs();
		escape.Set(.Escape, .None, false);
		combo.OnKeyDown(escape);
		Test.Assert(!combo.IsOpen);
	}

	// ---- The dropdown -------------------------------------------------------------------------

	/// The list is as wide as the combo it hangs from, so the two read as one control.
	[Test]
	public static void TheListMatchesTheBoxsWidth()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let combo = MakeBox("A", "B", "C");
		root.AddView(combo);
		combo.Bounds = .(0, 0, 240, 30);

		let dropdown = new ComboBoxDropdown(combo);
		defer dropdown.ReleaseRef();
		dropdown.Measure(BoxConstraints.Loose(400, 300));

		Test.Assert(dropdown.MeasuredSize.X == 240);
		// Three items of 28, plus 4 of frame at each end.
		Test.Assert(dropdown.MeasuredSize.Y == 3 * 28 + 8);
	}

	/// Choosing from the list sets the combo and closes it.
	[Test]
	public static void ChoosingFromTheListSetsTheBoxAndCloses()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let combo = MakeBox("A", "B", "C");
		root.AddView(combo);
		UITest.LayoutPass(context, root);
		combo.OpenDropdown();
		Test.Assert(combo.IsOpen);

		let dropdown = new ComboBoxDropdown(combo);
		defer dropdown.ReleaseRef();

		// The second row starts 4 in and runs 28: click the middle of it.
		let click = scope MouseEventArgs();
		click.Set(10, 4 + 28 + 14, .Left);
		dropdown.OnMouseDown(click);

		Test.Assert(combo.SelectedIndex == 1);
		Test.Assert(!combo.IsOpen);
		Test.Assert(click.Handled);
	}

	/// Arriving by keyboard from below lands on the LAST item, so Up into a fresh list is
	/// useful rather than doing nothing.
	[Test]
	public static void TheKeyboardEntersTheListFromEitherEnd()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let combo = MakeBox("A", "B", "C");
		root.AddView(combo);

		let fromBelow = new ComboBoxDropdown(combo);
		defer fromBelow.ReleaseRef();
		let up = scope KeyEventArgs();
		up.Set(.Up, .None, false);
		fromBelow.OnKeyDown(up);
		Test.Assert(fromBelow.HoveredIndex == 2);

		let fromAbove = new ComboBoxDropdown(combo);
		defer fromAbove.ReleaseRef();
		let down = scope KeyEventArgs();
		down.Set(.Down, .None, false);
		fromAbove.OnKeyDown(down);
		Test.Assert(fromAbove.HoveredIndex == 0);
	}

	/// Escape closes WITHOUT choosing, so the combo keeps what it had.
	[Test]
	public static void EscapeLeavesTheListWithoutChoosing()
	{
		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let combo = MakeBox("A", "B", "C");
		root.AddView(combo);
		UITest.LayoutPass(context, root);
		combo.SetSelectedIndex(0);
		combo.OpenDropdown();

		let dropdown = new ComboBoxDropdown(combo);
		defer dropdown.ReleaseRef();

		let down = scope KeyEventArgs();
		down.Set(.Down, .None, false);
		dropdown.OnKeyDown(down);

		let escape = scope KeyEventArgs();
		escape.Set(.Escape, .None, false);
		dropdown.OnKeyDown(escape);

		Test.Assert(combo.SelectedIndex == 0, "still the original");
		Test.Assert(!combo.IsOpen);
	}
}
