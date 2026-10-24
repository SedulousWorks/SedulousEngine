using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// The combo box: its items, opening and closing the dropdown popup, picking an item through the
/// dropdown, and dismissal (outside click / Escape) through the dispatcher's popups.
class ComboBoxTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	/// A combo box of Red, Green and Blue, 120 by 26, the last child of `root`, held by the caller.
	private static ComboBox MakeCombo(SceneRoot root)
	{
		let cb = new ComboBox();
		cb.Size = .(120.0f, 26.0f);
		cb.SetItemHeight(24.0f);
		cb.AddItem("Red");
		cb.AddItem("Green");
		cb.AddItem("Blue");
		root.AddChild(cb);
		return cb;
	}

	[Test]
	public static void ItemManagementAndSelection()
	{
		let cb = new ComboBox();
		defer cb.ReleaseRef();
		cb.AddItem("One");
		cb.AddItem("Two");
		Test.Assert(cb.ItemCount == 2);
		Test.Assert(cb.SelectedIndex == -1);

		int changes = 0;
		cb.SetOnSelectionChanged(new [&] (index) => { ++changes; });
		cb.SelectedIndex = 1;
		Test.Assert(cb.SelectedIndex == 1);
		Test.Assert(cb.SelectedText == "Two");
		Test.Assert(changes == 1);
		cb.SelectedIndex = 1; // no change
		Test.Assert(changes == 1);
	}

	[Test]
	public static void MinusOneSelectsNoneAndItsPlaceholderShows()
	{
		let cb = new ComboBox();
		defer cb.ReleaseRef();
		cb.AddItem("One");
		cb.AddItem("Two");
		cb.Placeholder = "Mixed";
		cb.SelectedIndex = 1;
		int changes = 0;
		int last = 0;
		cb.SetOnSelectionChanged(new [&] (index) =>
			{
				++changes;
				last = index;
			});
		cb.SelectedIndex = -1;
		Test.Assert(cb.SelectedIndex == -1);
		Test.Assert(cb.SelectedText.Length == 0);
		Test.Assert(changes == 1);
		Test.Assert(last == -1);
		cb.SelectedIndex = -2; // not an index: nothing
		Test.Assert(changes == 1);
	}

	[Test]
	public static void ClickOpensTheDropdownItRegistersAsTheDispatcherPopup()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let cb = MakeCombo(root);
		defer cb.ReleaseRef();
		let d = root.EventDispatcher;

		Test.Assert(!cb.IsOpen);
		Test.Assert(d.PopupCount == 0);

		// Click the combo (a press+release on it).
		d.InjectMouseDown(.(20.0f, 13.0f), .Left);
		d.InjectMouseUp(.(20.0f, 13.0f), .Left);
		Test.Assert(cb.IsOpen);
		Test.Assert(d.TopPopup == cb.Dropdown); // the dropdown is the open popup
		Test.Assert(cb.Dropdown.Parent == cb); // the combo box's child while open
	}

	[Test]
	public static void ClickingADropdownRowSelectsItAndCloses()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let cb = MakeCombo(root);
		defer cb.ReleaseRef();
		let d = root.EventDispatcher;

		d.InjectMouseDown(.(20.0f, 13.0f), .Left);
		d.InjectMouseUp(.(20.0f, 13.0f), .Left); // open
		Test.Assert(cb.IsOpen);

		// The dropdown sits just below the combo (combo is 26 tall at y=0). Row 1 (Green) spans
		// y in [26 + 24, 26 + 48) = [50, 74).
		d.InjectMouseDown(.(20.0f, 60.0f), .Left);
		d.InjectMouseUp(.(20.0f, 60.0f), .Left);
		Test.Assert(cb.SelectedIndex == 1);
		Test.Assert(cb.SelectedText == "Green");
		Test.Assert(!cb.IsOpen);
		Test.Assert(root.EventDispatcher.PopupCount == 0);
	}

	[Test]
	public static void ClickingOutsideDismissesTheDropdown()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let cb = MakeCombo(root);
		defer cb.ReleaseRef();
		let d = root.EventDispatcher;

		d.InjectMouseDown(.(20.0f, 13.0f), .Left);
		d.InjectMouseUp(.(20.0f, 13.0f), .Left); // open
		Test.Assert(cb.IsOpen);

		// Press far away from the combo and its dropdown -> dismissed.
		d.InjectMouseDown(.(350.0f, 350.0f), .Left);
		Test.Assert(!cb.IsOpen);
		Test.Assert(d.PopupCount == 0);
	}

	[Test]
	public static void EscapeDismissesTheDropdown()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let cb = MakeCombo(root);
		defer cb.ReleaseRef();
		let d = root.EventDispatcher;

		d.InjectMouseDown(.(20.0f, 13.0f), .Left);
		d.InjectMouseUp(.(20.0f, 13.0f), .Left); // open
		Test.Assert(cb.IsOpen);

		d.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(!cb.IsOpen);
		Test.Assert(d.PopupCount == 0);
	}

	[Test]
	public static void TheDropdownOpensBelowTheBoxAtADisplayScale()
	{
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		root.DisplayScale = 2.0f; // device pixels are twice the root's units
		root.Size = .(300.0f, 300.0f);
		let cb = MakeCombo(root);
		defer cb.ReleaseRef();
		cb.Position = .(10.0f, 20.0f);
		let d = root.EventDispatcher;
		d.InjectMouseDown(.(60.0f, 60.0f), .Left); // device pixels, inside the box
		d.InjectMouseUp(.(60.0f, 60.0f), .Left);
		Test.Assert(cb.IsOpen);
		Test.Assert(d.TopPopup != null);
		Test.Assert(Near(d.TopPopup.Position.X, 10.0f));
		Test.Assert(Near(d.TopPopup.Position.Y, 46.0f)); // the box's bottom, in root units
	}

	[Test]
	public static void NewItemsDropTheOldSelectionsTextTheSelectionBindsAndAPickReportsAChange()
	{
		let cb = new ComboBox();
		defer cb.ReleaseRef();
		cb.ItemsText = "Low|High";
		cb.SelectedIndex = 1;
		Test.Assert(cb.SelectedText == "High");
		cb.ItemsText = "A|B|C";
		Test.Assert(cb.SelectedIndex == -1);
		Test.Assert(cb.SelectedText.Length == 0);

		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let combo = MakeCombo(root);
		defer combo.ReleaseRef();
		let data = root.Context.Data;
		data.Set("pick", System.Variant.Create((int32)1));
		Test.Assert(combo.BindData("selected", root.Context.Data, "pick"));
		root.Context.Update(SceneFixtures.Seconds(1.0 / 60.0));
		Test.Assert(combo.SelectedIndex == 1); // the data's
		int changes = 0;
		combo.AddEventListener(.Changed, new [&] (e) => { ++changes; });
		combo.SelectByUser(2);
		root.Context.Update(SceneFixtures.Seconds(1.0 / 60.0));
		Test.Assert(changes == 1);
		let back = data.Get("pick");
		Test.Assert(back.VariantType == typeof(int32));
		Test.Assert(back.Get<int32>() == 2); // written back
		combo.SelectedIndex = 0;
		Test.Assert(changes == 1); // code's change is no user's
	}
}
