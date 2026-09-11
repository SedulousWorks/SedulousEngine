using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Gamekit;

/// A vertical stack of selectable menu rows.
///
/// Thin over the UI proper: a flex layout of focusable buttons whose Up and Down directional
/// focus neighbours are wired with WRAP AROUND, so the focus manager already drives arrow and
/// pad navigation between rows, wrapping at the ends, and this class handles no keys at all.
///
/// Selection IS the focused row rather than a second piece of state beside it, so a menu cannot
/// show one row highlighted while a different one takes the Enter key. Activation, by click,
/// Enter or the pad's accept button, fires OnItemActivated.
///
/// Rows carry the "menu-item" class and the list itself "menu", which is what a game theme
/// targets to style them.
class MenuList : FlexLayout
{
	/// BORROWED: the rows are owned by the child list, and these are the same views.
	private List<Button> mItems = new .() ~ delete _;
	/// OWNED: the per row callbacks handed to AddItem.
	private List<delegate void()> mCallbacks = new .() ~ DeleteContainerAndItems!(_);

	/// Fired when a row is activated, with its index.
	public Event<delegate void(MenuList, int32)> OnItemActivated ~ _.Dispose();

	public this()
	{
		Direction = .Vertical;
		AlignItems = .Stretch; // rows fill the menu's width
		Spacing = 4.0f;
		AddClass("menu");
	}

	public int ItemCount => mItems.Count;

	public Button ItemAt(int index) => ((index >= 0) && (index < mItems.Count)) ? mItems[index] : null;

	/// Appends a selectable row. The row comes back so a caller can style it or wire OnClick
	/// directly; it stays OWNED by the menu.
	public Button AddItem(StringView label)
	{
		let row = new Button(label);
		row.AddClass("menu-item");
		mItems.Add(row);
		AddView(row); // the child list takes the reference
		RewireFocusChain();
		return row;
	}

	/// Appends a row and wires onSelect to it. CONSUMES the delegate.
	public Button AddItem(StringView label, delegate void() onSelect)
	{
		let row = AddItem(label);
		let index = (int32)(mItems.Count - 1);

		if (onSelect != null)
			mCallbacks.Add(onSelect);

		row.OnClick.Add(new [=](button) =>
			{
				if (onSelect != null)
					onSelect();

				OnItemActivated(this, index);
			});

		return row;
	}

	/// Removes every row.
	public void ClearItems()
	{
		RemoveAllViews();
		mItems.Clear();
		ClearAndDeleteItems!(mCallbacks);
	}

	/// The highlighted row: the focused one. Minus one when nothing is focused, or when the
	/// menu is not attached to a context and so has no focus manager to ask.
	public int32 SelectedIndex
	{
		get
		{
			if (Context == null)
				return -1;

			let focus = Context.GetFocusManager();
			if (focus == null)
				return -1;

			let focused = focus.FocusedView;
			for (int i < mItems.Count)
			{
				if (mItems[i] == focused)
					return (int32)i;
			}
			return -1;
		}
	}

	/// Moves focus, and so the highlight, to a row. Out of range is a no op.
	public void SetSelectedIndex(int32 index)
	{
		if ((index < 0) || (index >= mItems.Count) || (Context == null))
			return;

		if (let focus = Context.GetFocusManager())
			focus.SetFocus(mItems[index], .Programmatic);
	}

	/// Focuses the first row, so a pad or keyboard user lands on something. What a screen calls
	/// when it becomes active.
	public void FocusFirst() => SetSelectedIndex(mItems.IsEmpty ? -1 : 0);

	/// Rewires every row's Up and Down neighbours with wrap around, so the first row's Up lands
	/// on the last and the last row's Down lands on the first. Redone on every insertion rather
	/// than patched at the ends, which is what keeps the chain correct however rows arrive.
	private void RewireFocusChain()
	{
		let count = mItems.Count;
		for (int i < count)
		{
			mItems[i].NextFocusUp = mItems[(i + count - 1) % count].Id;
			mItems[i].NextFocusDown = mItems[(i + 1) % count].Id;
		}
	}
}
