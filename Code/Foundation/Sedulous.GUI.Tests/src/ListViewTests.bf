using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// ListView: virtualization (only visible rows realized), single selection via mouse and keyboard,
/// wheel and scroll-into-view, reacting to model updates; and the item view's multi-selection.
class ListViewTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	[Test]
	public static void VirtualizesOnlyVisibleRowsAreRealized()
	{
		let model = ItemViewFixtures.Same(1000);
		defer delete model;
		let m = scope ListBed(model);
		// A 100px view of 20px rows: rows 0 to 4, and row 5 past its bottom edge.
		Test.Assert(m.List.VisibleRowCount == 6); // 5 in view and one past the edge, not 1000
		Test.Assert(m.List.Model == model);
	}

	[Test]
	public static void ClickingARowSelectsItAndFiresTheCallback()
	{
		let model = ItemViewFixtures.Same(10);
		defer delete model;
		let m = scope ListBed(model);
		int selectedRow = -1;
		int calls = 0;
		m.List.SetOnSelectionChanged(new [&] (i) =>
			{
				selectedRow = i.Row;
				++calls;
			});

		// Row 2 spans y in [40, 60); click it.
		SceneFixtures.Click(m.D, .(50.0f, 50.0f));
		Test.Assert(m.List.SelectedItem == 2);
		Test.Assert(selectedRow == 2);
		Test.Assert(calls == 1);
		Test.Assert(m.List.SelectedIndex == MakeModelIndex(2));
	}

	[Test]
	public static void KeyboardNavigationMovesTheSelection()
	{
		let model = ItemViewFixtures.Same(10);
		defer delete model;
		let m = scope ListBed(model);
		m.List.RequestFocus();
		m.D.InjectKeyDown((uint32)KeyCode.Down); // nothing selected -> row 0
		Test.Assert(m.List.SelectedItem == 0);
		m.D.InjectKeyDown((uint32)KeyCode.Down);
		m.D.InjectKeyDown((uint32)KeyCode.Down);
		Test.Assert(m.List.SelectedItem == 2);
		m.D.InjectKeyDown((uint32)KeyCode.Up);
		Test.Assert(m.List.SelectedItem == 1);
		m.D.InjectKeyDown((uint32)KeyCode.End);
		Test.Assert(m.List.SelectedItem == 9);
		m.D.InjectKeyDown((uint32)KeyCode.Home);
		Test.Assert(m.List.SelectedItem == 0);
	}

	[Test]
	public static void SelectingAFarRowScrollsItIntoView()
	{
		let model = ItemViewFixtures.Same(20); // content 400, viewport 100 -> maxScroll 300
		defer delete model;
		let m = scope ListBed(model);
		Test.Assert(Near(m.List.ScrollOffset.Y, 0.0f));
		m.List.SelectedItem = 19; // last row -> bottom (400) - viewport (100) = 300
		Test.Assert(Near(m.List.ScrollOffset.Y, 300.0f));
		Test.Assert(m.List.SelectedItem == 19);
	}

	[Test]
	public static void WheelScrollsAndClamps()
	{
		let model = ItemViewFixtures.Same(20);
		defer delete model;
		let m = scope ListBed(model);
		m.D.InjectMouseWheel(.(50.0f, 50.0f), .(0.0f, -3.0f)); // down 3 rows
		Test.Assert(Near(m.List.ScrollOffset.Y, 60.0f));
		m.D.InjectMouseWheel(.(50.0f, 50.0f), .(0.0f, -100.0f)); // clamps to maxScroll
		Test.Assert(Near(m.List.ScrollOffset.Y, 300.0f));
	}

	[Test]
	public static void ReactsToModelUpdatesAndClampsAStaleSelection()
	{
		let model = ItemViewFixtures.Same(5);
		defer delete model;
		let m = scope ListBed(model);
		m.List.SelectedItem = 4;
		Test.Assert(m.List.SelectedItem == 4);

		StringView[2] two = .("item", "item");
		model.SetItems(two); // notifies the view -> selection 4 is now out of range
		Test.Assert(m.List.SelectedItem == -1);

		model.AddItem("more");
		Test.Assert(m.List.Model.RowCount() == 3);
	}

	[Test]
	public static void CtrlClickTogglesItemsInMultiSelectionMode()
	{
		let model = ItemViewFixtures.Same(10);
		defer delete model;
		let m = scope ListBed(model, 20.0f, 120.0f);
		m.List.SelectionMode = .Multi;
		m.D.InjectMouseDown(.(10.0f, 10.0f), .Left); // row 0 (plain)
		m.D.InjectMouseUp(.(10.0f, 10.0f), .Left);
		m.D.InjectMouseDown(.(10.0f, 50.0f), .Left, KeyModCtrl); // row 2 (ctrl)
		m.D.InjectMouseUp(.(10.0f, 50.0f), .Left, KeyModCtrl);

		Test.Assert(m.List.SelectionCount == 2);
		Test.Assert(m.List.IsItemSelected(0));
		Test.Assert(m.List.IsItemSelected(2));

		// Ctrl-click an already-selected item removes it.
		m.D.InjectMouseDown(.(10.0f, 10.0f), .Left, KeyModCtrl);
		m.D.InjectMouseUp(.(10.0f, 10.0f), .Left, KeyModCtrl);
		Test.Assert(!m.List.IsItemSelected(0));
		Test.Assert(m.List.SelectionCount == 1);
	}

	[Test]
	public static void ShiftClickSelectsARangeFromTheAnchor()
	{
		let model = ItemViewFixtures.Same(10);
		defer delete model;
		let m = scope ListBed(model, 20.0f, 120.0f);
		m.List.SelectionMode = .Multi;
		m.D.InjectMouseDown(.(10.0f, 10.0f), .Left); // row 0 anchors
		m.D.InjectMouseUp(.(10.0f, 10.0f), .Left);
		m.D.InjectMouseDown(.(10.0f, 70.0f), .Left, KeyModShift); // row 3
		m.D.InjectMouseUp(.(10.0f, 70.0f), .Left, KeyModShift);

		Test.Assert(m.List.SelectionCount == 4); // rows 0,1,2,3
		Test.Assert(m.List.IsItemSelected(1));
		Test.Assert(m.List.IsItemSelected(3));
	}

	[Test]
	public static void SingleSelectionModeIgnoresCtrlStaysSingle()
	{
		let model = ItemViewFixtures.Same(10);
		defer delete model;
		let m = scope ListBed(model, 20.0f, 120.0f); // default SelectionMode.Single
		SceneFixtures.Click(m.D, .(10.0f, 10.0f));
		m.D.InjectMouseDown(.(10.0f, 50.0f), .Left, KeyModCtrl); // ctrl ignored
		m.D.InjectMouseUp(.(10.0f, 50.0f), .Left, KeyModCtrl);
		Test.Assert(m.List.SelectionCount == 1);
		Test.Assert(m.List.SelectedItem == 2);
	}

	/// Rows 0 and 5 are headers.
	private class Sections : StringListModel
	{
		public override bool IsSelectable(ModelIndex index) => (index.Row != 0) && (index.Row != 5);
	}

	[Test]
	public static void AnItemItsModelSaysMayNotBeSelectedASectionHeaderIsPassedOverByClicksKeysAndSelectAll()
	{
		let model = scope Sections();
		for (int i = 0; i < 10; ++i)
			model.AddItem("item");
		let m = scope ListBed(model, 20.0f, 220.0f);
		int activated = 0;
		m.List.SetOnActivated(new [&] (index) => { ++activated; });

		// A click on a header selects nothing, and a second activates nothing.
		SceneFixtures.Click(m.D, .(50.0f, 10.0f));
		SceneFixtures.Click(m.D, .(50.0f, 10.0f));
		Test.Assert(m.List.SelectedItem == -1);
		Test.Assert(activated == 0);

		m.List.RequestFocus();
		m.D.InjectKeyDown((uint32)KeyCode.Down); // nothing selected: the first that may be, past the header
		Test.Assert(m.List.SelectedItem == 1);
		m.List.SelectedItem = 4;
		m.D.InjectKeyDown((uint32)KeyCode.Down); // over the header at 5
		Test.Assert(m.List.SelectedItem == 6);
		m.D.InjectKeyDown((uint32)KeyCode.Up);
		Test.Assert(m.List.SelectedItem == 4);
		m.D.InjectKeyDown((uint32)KeyCode.Home); // the first that may be
		Test.Assert(m.List.SelectedItem == 1);
		m.D.InjectKeyDown((uint32)KeyCode.Up); // nothing before it: it stays
		Test.Assert(m.List.SelectedItem == 1);

		m.List.SelectionModeName = "multi";
		m.List.SelectAll();
		Test.Assert(!m.List.IsItemSelected(0));
		Test.Assert(!m.List.IsItemSelected(5));
		Test.Assert(m.List.IsItemSelected(9));
	}
}
