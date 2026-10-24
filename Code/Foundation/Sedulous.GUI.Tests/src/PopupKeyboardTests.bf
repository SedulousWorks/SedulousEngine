using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A 600 by 400 GUI driven by keys and the pad. The root goes with it.
class PopupKeyBed
{
	public SceneRoot Root = SceneFixtures.NewScene(600.0f, 400.0f) ~ _.ReleaseRef();

	public EventDispatcher D => Root.EventDispatcher;

	public void Key(KeyCode k, uint32 mods = 0)
	{
		D.InjectKeyDown((uint32)k, mods);
	}

	/// A key that types: its key, then its text (what type-ahead reads).
	public void Type(KeyCode k, StringView text)
	{
		Key(k);
		D.InjectText(text);
	}

	/// The text of the focused menu item, or empty.
	public StringView FocusedItem
	{
		get
		{
			let item = D.FocusNode as MenuItem;
			return (item != null) ? item.Text : default;
		}
	}
}

/// The keyboard and the pad in composite widgets: a walk through a menu bar and a submenu, a combo
/// box closed and open, and a message box, by keys and by the pad.
class PopupKeyboardTests
{
	/// A message box asking with `buttons`, open modal in `bed`'s GUI, kept in `boxes` (whose
	/// owner releases them). OWNERSHIP of `onResult` transfers.
	private static MessageBox ShowBox(PopupKeyBed bed, List<MessageBox> boxes, MessageBox.Buttons buttons, delegate void(MessageBox.Result result) onResult)
	{
		let dialog = new MessageBox();
		boxes.Add(dialog);
		dialog.Configure("Leave", "Leave the ball?", buttons);
		dialog.SetOnResult(onResult);
		dialog.OpenModal(bed.Root);
		return dialog;
	}

	[Test]
	public static void AWalkThroughAMenuBarItsMenusAndASubmenu()
	{
		let bed = scope PopupKeyBed();
		let bar = new MenuBar();
		defer bar.ReleaseRef();
		bed.Root.AddChild(bar);
		int opened = 0;
		int saved = 0;
		int deep = 0;
		let file = bar.AddMenu("File");
		file.AddItem("Open", new [&] () => { ++opened; });
		file.AddItem("Save", new [&] () => { ++saved; }).Enabled = false; // skipped
		let recent = file.AddSubMenu("Recent");
		recent.AddItem("First", new [&] () => { ++deep; });
		recent.AddItem("Second", new () => { });
		let edit = bar.AddMenu("Edit");
		edit.AddItem("Undo", new () => { });
		bed.Root.UpdateLayout();

		bed.Key(.F10); // into the bar
		Test.Assert(bed.D.FocusNode == bar.ButtonAt(0));
		bed.Key(.Down); // opens File, its first item lit
		Test.Assert(file.IsOpen);
		Test.Assert(bed.FocusedItem == "Open");
		bed.Key(.Down); // Save is disabled: skipped
		Test.Assert(bed.FocusedItem == "Recent");
		bed.Key(.Right); // into the submenu
		Test.Assert(recent.IsOpen);
		Test.Assert(bed.FocusedItem == "First");
		bed.Key(.Left); // out again, back on its item
		Test.Assert(!recent.IsOpen);
		Test.Assert(bed.FocusedItem == "Recent");
		bed.Key(.Right); // the next menu on the bar: Right on a submenu item goes in, so first move off it
		bed.Key(.Left);
		bed.Key(.Up); // Open
		Test.Assert(bed.FocusedItem == "Open");
		bed.Key(.Right); // File's Open has no submenu: the next menu
		Test.Assert(edit.IsOpen);
		Test.Assert(!file.IsOpen);
		Test.Assert(bed.FocusedItem == "Undo");
		bed.Key(.Left);
		Test.Assert(file.IsOpen);
		Test.Assert(bed.FocusedItem == "Open");
		bed.Key(.Return); // runs it and closes the menu
		Test.Assert(opened == 1);
		Test.Assert(!file.IsOpen);

		// Escape closes, focus going back to the bar's button.
		bar.ButtonAt(0).RequestFocus();
		bed.Key(.Down);
		Test.Assert(file.IsOpen);
		bed.Key(.Escape);
		Test.Assert(!file.IsOpen);
		Test.Assert(bed.D.FocusNode == bar.ButtonAt(0));
		Test.Assert(saved == 0);
		Test.Assert(deep == 0);
	}

	[Test]
	public static void AComboBoxStepsItsSelectionClosedTypesAheadAndOpensOnItsCurrentItem()
	{
		let bed = scope PopupKeyBed();
		let combo = new ComboBox();
		defer combo.ReleaseRef();
		combo.Size = .(140.0f, 26.0f);
		combo.ItemsText = "Apple|Banana|Blueberry|Cherry";
		combo.SelectedIndex = 0;
		bed.Root.AddChild(combo);
		combo.RequestFocus();

		bed.Key(.Down);
		Test.Assert(combo.SelectedIndex == 1);
		bed.Type(.B, "b"); // the next starting with b
		Test.Assert(combo.SelectedText == "Blueberry");
		bed.Type(.B, "b"); // round to the first b
		Test.Assert(combo.SelectedText == "Banana");
		bed.Type(.C, "c");
		Test.Assert(combo.SelectedIndex == 3);
		bed.Key(.Down); // at the end: given back, the selection stays
		Test.Assert(combo.SelectedIndex == 3);
		combo.RequestFocus();

		bed.Key(.Return); // opens, the list focused on the current item
		Test.Assert(combo.IsOpen);
		let list = combo.Dropdown;
		Test.Assert(bed.D.FocusNode == list);
		Test.Assert(list.SelectedIndex == 3);
		bed.Key(.Up);
		Test.Assert(combo.SelectedIndex == 3); // moving in the list picks nothing yet
		bed.Key(.Return);
		Test.Assert(!combo.IsOpen);
		Test.Assert(combo.SelectedText == "Blueberry");
		Test.Assert(combo.IsFocused); // focus back

		bed.Key(.Down, KeyModAlt);
		Test.Assert(combo.IsOpen);
		bed.Key(.Escape);
		Test.Assert(!combo.IsOpen);
		Test.Assert(combo.SelectedText == "Blueberry");
		Test.Assert(combo.IsFocused);
	}

	[Test]
	public static void ThePadOpensAComboBoxWithSouthAndBacksOutWithEast()
	{
		let bed = scope PopupKeyBed();
		let combo = new ComboBox();
		defer combo.ReleaseRef();
		combo.Size = .(140.0f, 26.0f);
		combo.ItemsText = "One|Two";
		combo.SelectedIndex = 0;
		bed.Root.AddChild(combo);
		combo.RequestFocus();
		bed.D.InjectPadButton(.South);
		Test.Assert(combo.IsOpen);
		bed.D.PressDirection(.Down);
		bed.D.ReleaseDirection(.Down);
		bed.D.InjectPadButton(.South);
		Test.Assert(combo.SelectedText == "Two");
		Test.Assert(!combo.IsOpen);
		bed.D.InjectPadButton(.South);
		Test.Assert(combo.IsOpen);
		bed.D.InjectPadButton(.East);
		Test.Assert(!combo.IsOpen);
		Test.Assert(combo.IsFocused);
	}

	[Test]
	public static void AMessageBoxOpensOnItsDefaultButtonEscapeAndThePadsEastCancel()
	{
		let bed = scope PopupKeyBed();
		let behind = new Button();
		defer behind.ReleaseRef();
		behind.Size = .(40.0f, 20.0f);
		bed.Root.AddChild(behind);
		behind.RequestFocus();
		var got = MessageBox.Result.Ok;
		int results = 0;
		let boxes = scope List<MessageBox>();
		defer { for (let b in boxes) b.ReleaseRef(); }
		var dialog = ShowBox(bed, boxes, .YesNo, new [&] (result) =>
			{
				got = result;
				++results;
			});
		Test.Assert(bed.D.FocusNode == dialog.ButtonAt(1)); // Yes, the default
		bed.Key(.Return);
		Test.Assert(results == 1);
		Test.Assert(got == .Yes);
		Test.Assert(behind.IsFocused); // focus back

		dialog = ShowBox(bed, boxes, .OkCancel, new [&] (result) =>
			{
				got = result;
				++results;
			});
		bed.Key(.Escape);
		Test.Assert(results == 2);
		Test.Assert(got == .Cancel);

		dialog = ShowBox(bed, boxes, .YesNo, new [&] (result) =>
			{
				got = result;
				++results;
			});
		bed.D.InjectPadButton(.East);
		Test.Assert(results == 3);
		Test.Assert(got == .No);
		Test.Assert(!dialog.IsOpen);
	}
}
