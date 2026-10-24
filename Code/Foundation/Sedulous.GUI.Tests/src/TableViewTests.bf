using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// TableModel + TableView tests: multi-column data, virtualized rows with a header, single
// selection (mouse + keyboard), and header-click reporting (for sorting).

/// A table model's columns, rows and typed cells, and the TableView over it: its rows virtualised
/// under its header, selected by the mouse and the keys, its header clicked, sorting and resized.
class TableViewTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);
	private static bool Near(float a, float b, float epsilon) => Math.Abs(a - b) < epsilon * (1.0f + Math.Max(Math.Abs(a), Math.Abs(b)));

	/// A table 300 by 200 (24-high rows under a 26-high header) in a root 400 by 400, over a model
	/// it borrows (which outlives the bed).
	private class Bed
	{
		public SceneRoot Root = SceneFixtures.NewScene(400.0f, 400.0f) ~ _.ReleaseRef();
		public TableView Table;

		public this(IModel model)
		{
			Table = new TableView();
			Table.Size = .(300.0f, 200.0f);
			Table.RowHeight = 24.0f;
			Table.HeaderHeight = 26.0f;
			Root.AddChild(Table);
			Table.ReleaseRef(); // the tree holds it
			Table.Model = model;
			Root.UpdateLayout();
		}

		public EventDispatcher D => Root.EventDispatcher;
	}

	// A 2-column model (Name, Age) with `count` rows.
	private static void FillPeople(TableModel model, int count)
	{
		StringView[2] columns = .("Name", "Age");
		model.SetColumns(columns);
		for (int i = 0; i < count; i++)
		{
			Sedulous.GUI.Variant[2] row = .(.((StringView)"Person"), .((int64)(20 + i)));
			model.AddRow(row);
		}
	}

	[Test]
	public static void TableModelColumnsRowsAndTypedCells()
	{
		let model = scope TableModel();
		FillPeople(model, 3);

		Test.Assert(model.ColumnCount() == 2);
		Test.Assert(model.RowCount() == 3);
		let name = scope String();
		model.ColumnName(0, name);
		Test.Assert(name == "Name");
		name.Clear();
		model.ColumnName(1, name);
		Test.Assert(name == "Age");
		Test.Assert(model.Data(MakeModelIndex(0, 0)).AsString == "Person");
		Test.Assert(model.Data(MakeModelIndex(1, 1)).AsInt == 21);
		Test.Assert(model.Data(MakeModelIndex(1, 1)).ToString(.. scope String()) == "21");
		Test.Assert(model.Data(MakeModelIndex(9, 0)).IsEmpty); // out of range
	}

	[Test]
	public static void VirtualizesRowsOverTheBodyViewport()
	{
		let model = scope TableModel();
		FillPeople(model, 1000);
		let b = scope Bed(model);
		// body = 200 - 26 header = 174: rows 0 to 7 in view and row 8 past the edge, not 1000.
		Test.Assert(b.Table.VisibleRowCount == 9);
		Test.Assert(b.Table.Model == model);
	}

	[Test]
	public static void ClickingARowSelectsIt()
	{
		let model = scope TableModel();
		FillPeople(model, 5); // fits (no scrollbar), body width = 300, 2 cols of 150
		let b = scope Bed(model);
		int selected = -1;
		b.Table.SetOnSelectionChanged(new [&] (i) => { selected = i.Row; });
		// Row 1 spans y in [26 + 24, 26 + 48) = [50, 74); cells are hit-transparent -> row gets it.
		SceneFixtures.Click(b.D, .(60.0f, 60.0f));
		Test.Assert(b.Table.SelectedItem == 1);
		Test.Assert(selected == 1);
	}

	[Test]
	public static void KeyboardNavigationMovesTheSelection()
	{
		let model = scope TableModel();
		FillPeople(model, 8);
		let b = scope Bed(model);
		b.Table.RequestFocus();
		b.D.InjectKeyDown((uint32)KeyCode.Down); // -> row 0
		b.D.InjectKeyDown((uint32)KeyCode.Down); // -> row 1
		Test.Assert(b.Table.SelectedItem == 1);
		b.D.InjectKeyDown((uint32)KeyCode.End);
		Test.Assert(b.Table.SelectedItem == 7);
	}

	[Test]
	public static void ClickingAColumnHeaderReportsItsIndex()
	{
		let model = scope TableModel();
		FillPeople(model, 3);
		let b = scope Bed(model);
		int clickedColumn = -1;
		b.Table.SetOnColumnHeaderClicked(new [&] (column) => { clickedColumn = column; });
		// Header spans y in [0, 26). Two columns of 150 -> column 1 header at x in [150, 300).
		SceneFixtures.Click(b.D, .(200.0f, 13.0f));
		Test.Assert(clickedColumn == 1);
	}

	[Test]
	public static void ReactsToModelUpdatesAndRebuildsTheHeader()
	{
		let model = scope TableModel();
		FillPeople(model, 4);
		let b = scope Bed(model);
		b.Table.SelectedItem = 3;
		Test.Assert(b.Table.SelectedItem == 3);
		model.Clear(); // notifies -> selection cleared, no rows
		b.Root.UpdateLayout();
		Test.Assert(b.Table.SelectedItem == -1);
		Test.Assert(b.Table.VisibleRowCount == 0);
	}

	[Test]
	public static void SortingFromAHeaderClickSurvivesTheHeaderItRebuilds()
	{
		// A header click sorts through a proxy, the proxy's update rebuilds the header, and neither
		// the click nor the next mouse move may reach the freed header cell.
		let model = scope TableModel();
		FillPeople(model, 5);
		let proxy = scope SortingProxyModel(model);
		let b = scope Bed(proxy);
		b.Table.SetOnColumnHeaderClicked(new [&] (column) => { proxy.ToggleSort(column); });
		for (int i = 0; i < 3; ++i) // ascending, descending, ascending
		{
			b.D.InjectMouseMove(.(200.0f, 13.0f));
			SceneFixtures.Click(b.D, .(200.0f, 13.0f));
			b.Root.Context.Update(SceneFixtures.Frame);
			// The rebuild freed the hovered header cell: the dispatcher let go of it (what it still
			// holds is in the tree), so moving on leaves nothing freed.
			Test.Assert(b.D.OverNode != null);
			Test.Assert(b.D.OverNode.RootNode == b.Root);
		}
		b.D.InjectMouseMove(.(200.0f, 60.0f));
		Test.Assert(b.D.OverNode != null);
		Test.Assert(proxy.SortColumn == 1);
		Test.Assert(proxy.SortOrder == .Ascending);
	}

	[Test]
	public static void ColumnsArePixelsPercentagesOrAutoSharesNoneUnderTheMinimum()
	{
		let model = scope TableModel();
		StringView[4] names = .("A", "B", "C", "D");
		model.SetColumns(names);
		let b = scope Bed(model);
		b.Table.ColumnWidthsText = "60px 20% auto";
		b.Root.UpdateLayout();
		// 300 wide: A 60, B 60 (20%), C and D share the 180 left.
		Test.Assert(Near(b.Table.GetColumnWidth(0), 60.0f));
		Test.Assert(Near(b.Table.GetColumnWidth(1), 60.0f));
		Test.Assert(Near(b.Table.GetColumnWidth(2), 90.0f));
		Test.Assert(Near(b.Table.GetColumnWidth(3), 90.0f));
		Test.Assert(b.Table.ColumnWidthsText == "60px 20% auto");
		Test.Assert(Near(b.Table.ScrollRange.X, 0.0f));

		// Too many pixels: the autos keep the minimum, and the table scrolls across.
		b.Table.SetColumnWidth(0, LayoutLength.Px(250.0f));
		b.Root.UpdateLayout();
		Test.Assert(Near(b.Table.GetColumnWidth(2), b.Table.MinColumnWidth));
		Test.Assert(Near(b.Table.ColumnsWidth, 250.0f + 60.0f + 80.0f));
		Test.Assert(Near(b.Table.ScrollRange.X, 90.0f));
		// The header scrolls across with the rows (and stays at the top as they scroll down).
		b.Table.ScrollTo(.(90.0f, 0.0f), .Instant);
		b.Root.UpdateLayout();
		Test.Assert(Near(b.Table.Header.Size.X, 390.0f));
	}

	[Test]
	public static void DraggingAHeaderCellsRightEdgeResizesItsColumnWithoutSorting()
	{
		let model = scope TableModel();
		FillPeople(model, 3);
		let proxy = scope SortingProxyModel(model);
		let b = scope Bed(proxy);
		Test.Assert(Near(b.Table.GetColumnWidth(0), 150.0f));

		// Column 0's edge is at x 150: press just inside it and drag 40 right.
		b.D.InjectMouseMove(.(148.0f, 13.0f));
		Test.Assert(b.D.Cursor == .EwResize);
		b.D.InjectMouseDown(.(148.0f, 13.0f), .Left);
		b.D.InjectMouseMove(.(188.0f, 13.0f));
		b.Root.UpdateLayout();
		b.D.InjectMouseUp(.(188.0f, 13.0f), .Left);
		b.Root.UpdateLayout();
		Test.Assert(Near(b.Table.GetColumnWidth(0), 190.0f));
		Test.Assert(Near(b.Table.GetColumnWidth(1), 110.0f)); // the auto one takes what is left
		Test.Assert(proxy.SortColumn == -1); // a resize is no click
		// Dragged past the minimum, it stops there.
		b.D.InjectMouseDown(.(188.0f, 13.0f), .Left);
		b.D.InjectMouseMove(.(0.0f, 13.0f));
		b.D.InjectMouseUp(.(0.0f, 13.0f), .Left);
		b.Root.UpdateLayout();
		Test.Assert(Near(b.Table.GetColumnWidth(0), b.Table.MinColumnWidth));
	}

	[Test]
	public static void AHeaderClickSortsWhereTheModelCanAndTheCellShowsWhichWay()
	{
		let model = scope TableModel();
		FillPeople(model, 3);
		let proxy = scope SortingProxyModel(model);
		let b = scope Bed(proxy);
		Test.Assert(b.Table.SortColumn == -1);
		SceneFixtures.Click(b.D, .(200.0f, 13.0f));
		Test.Assert(b.Table.SortColumn == 1);
		Test.Assert(b.Table.SortOrder == .Ascending);
		SceneFixtures.Click(b.D, .(200.0f, 13.0f));
		Test.Assert(b.Table.SortOrder == .Descending);
		Test.Assert(proxy.SortOrder == .Descending);
		Test.Assert(proxy.Data(MakeModelIndex(0, 1)).AsInt == 22);

		// A table alone cannot sort: no indicator.
		let plain = scope TableModel();
		FillPeople(plain, 2);
		let b2 = scope Bed(plain);
		SceneFixtures.Click(b2.D, .(200.0f, 13.0f));
		Test.Assert(b2.Table.SortColumn == -1);
	}

	[Test]
	public static void AResizedColumnResizesItsCellsInEveryRowNotOnlyItsHeaderCell()
	{
		let model = scope TableModel();
		FillPeople(model, 3);
		let b = scope Bed(model);
		b.D.InjectMouseDown(.(148.0f, 13.0f), .Left);
		for (float x = 140.0f; x >= 60.0f; x -= 20.0f)
		{
			b.D.InjectMouseMove(.(x, 13.0f));
			b.Root.UpdateLayout();
		}
		b.D.InjectMouseUp(.(60.0f, 13.0f), .Left);
		b.Root.UpdateLayout();
		let column = b.Table.GetColumnWidth(0);
		Test.Assert(Near(column, 62.0f)); // pressed 2 in from its edge, released at 60
		// Each row's first cell is as wide as the column, and its second starts where the column ends.
		for (int32 item = 0; item < 3; ++item)
		{
			let row = b.Table.RowForItem(item);
			Test.Assert(row != null);
			let content = row.Content as TableRowContent;
			Test.Assert(content != null);
			Test.Assert(Near(content.CellAt(0).Size.X, column));
			Test.Assert(Near(content.CellAt(1).Position.X, column));
		}
	}

	[Test]
	public static void ARowAddedBeforeItsCellsAreSetShowsThemAndItsItemLivesOn()
	{
		let table = new TableView();
		defer table.ReleaseRef();
		table.ColumnsText = "Name|Score";
		let item = new TableItem();
		table.ChildHost.AddChild(item); // taken in at once, with no cells yet
		item.ReleaseRef(); // the caller keeps only a weak handle, as a script does
		item.Cells = "Ada|9";
		let model = table.Model;
		Test.Assert(model != null);
		Test.Assert(model.RowCount() == 1);
		Test.Assert(model.Data(model.Index(0, 0)).ToString(.. scope String()) == "Ada");
		Test.Assert(model.Data(model.Index(0, 1)).ToString(.. scope String()) == "9");
	}

	[Test]
	public static void InRightToLeftItsColumnsRunFromTheRightWiderOnesOverflowingToTheLeft()
	{
		let model = scope TableModel();
		FillPeople(model, 5);
		let b = scope Bed(model);
		b.Root.SetLayoutDirection(.RightToLeft);
		b.Table.SetColumnWidth(0, LayoutLength.Px(250.0f));
		b.Table.SetColumnWidth(1, LayoutLength.Px(200.0f));
		b.Root.UpdateLayout();
		let @box = b.Table.ContentBounds;
		let right = b.Table.ConvertToRootSpace(.(@box.X + @box.Width, 0.0f)).X;

		// At its start: offset 0, the first column against the right edge, the rest past the left.
		Test.Assert(Near(b.Table.ScrollOffset.X, 0.0f));
		Test.Assert(b.Table.ScrollMin.X < -100.0f);
		let row = b.Table.RowForItem(0);
		Test.Assert(row != null);
		let content = row.Content as TableRowContent;
		Test.Assert(content != null);
		let name = content.CellAt(0).ScreenBounds;
		let age = content.CellAt(1).ScreenBounds;
		Test.Assert(Near(name.X + name.Width, right, 0.01f));
		Test.Assert(Near(age.X + age.Width, name.X, 0.01f));
		// The header's cells over their columns.
		let heading = b.Table.Header.GetChildAt(0).ScreenBounds;
		Test.Assert(Near(heading.X, name.X, 0.01f));

		// Scrolled to its end, the left: the last column shows.
		b.Table.ScrollOffset = .(-1000.0f, 0.0f);
		b.Root.UpdateLayout();
		Test.Assert(Near(b.Table.ScrollOffset.X, b.Table.ScrollMin.X));
		let ageThen = content.CellAt(1).ScreenBounds;
		Test.Assert(Near(ageThen.X, b.Table.ConvertToRootSpace(.(@box.X, 0.0f)).X, 0.01f));

		// A column's grip is at its inline end, the left: pulled further left, it widens.
		b.Table.ScrollOffset = .(0.0f, 0.0f);
		b.Root.UpdateLayout();
		let cell = b.Table.Header.GetChildAt(0).ScreenBounds;
		let grip = Float2(cell.X + 2.0f, cell.Y + cell.Height * 0.5f);
		b.D.InjectMouseDown(grip, .Left);
		b.D.InjectMouseMove(.(grip.X - 30.0f, grip.Y));
		b.D.InjectMouseUp(.(grip.X - 30.0f, grip.Y), .Left);
		Test.Assert(Near(b.Table.GetColumnWidth(0), 280.0f));
	}
}
