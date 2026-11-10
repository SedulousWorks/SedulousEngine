using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// What the item view tests share.
static class ItemViewFixtures
{
	/// A model of `count` rows, "item 0" on. The caller owns what comes back.
	public static StringListModel Numbered(int count)
	{
		let model = new StringListModel();
		let text = scope String();
		for (int i = 0; i < count; ++i)
		{
			text.Clear();
			text.AppendF("item {}", i);
			model.AddItem(text);
		}
		return model;
	}

	/// A model of `count` rows that all read "item". The caller owns what comes back.
	public static StringListModel Same(int count)
	{
		let model = new StringListModel();
		for (int i = 0; i < count; ++i)
			model.AddItem("item");
		return model;
	}

	/// A model's rows run together ("ABC"), into `outText`.
	public static void Items(StringListModel model, String outText)
	{
		for (int i = 0; i < model.RowCount(); ++i)
			outText.Append(model.ItemAt(i));
	}
}

/// A list view 200 wide in a root 300 by 300, over a model it borrows (which outlives the bed).
class ListBed
{
	public SceneRoot Root;
	public ListView List;

	public this(IModel model, float rowHeight = 20.0f, float height = 100.0f)
	{
		Root = SceneFixtures.NewScene(300.0f, 300.0f);
		List = new ListView();
		List.Size = .(200.0f, height);
		List.RowHeight = rowHeight;
		Root.AddChild(List);
		List.ReleaseRef(); // the tree holds it
		List.Model = model;
		Layout();
	}

	public ~this()
	{
		Root.ReleaseRef(); // the tree, the list with it
	}

	public EventDispatcher D => Root.EventDispatcher;
	public void Layout() => Root.UpdateLayout();
}

/// ItemView: the engine behind the list, tree and table views. Row heights in a sum tree,
/// measured on demand; scrolling anchored to an item; rows from a native factory, pooled by type
/// and recycled; selection as a set of ids that survives inserts and sorting; `activate`,
/// type-ahead and editing in place; and the view as a Node scroll container.
class ItemViewTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);
	private static bool Near(float a, float b, float epsilon) => Math.Abs(a - b) < epsilon * (1.0f + Math.Max(Math.Abs(a), Math.Abs(b)));

	// A factory whose rows are as tall as their row says (`item 3` is 40 high: 10 times one more
	// than the row's place in fours), counting the rows it makes in `created`.
	private static RowFactory TallRows(int* created)
	{
		let f = new RowFactory();
		f.Create = new (type) =>
			{
				++*created;
				return new Panel();
			};
		f.Bind = new (content, index) =>
			{
				let h = 10.0f * (float)(index.Row % 4 + 1);
				content.EditLayoutStyle(scope (s) => { s.Height = LayoutLength.Px(h); });
			};
		return f;
	}

	[Test]
	public static void RowHeightsInASumTreeFindARowByOffsetAndAnOffsetByRow()
	{
		let h = scope RowHeights();
		h.Reset(5, 10.0f);
		Test.Assert(Near(h.Total, 50.0f));
		Test.Assert(Near(h.Top(3), 30.0f));
		Test.Assert(h.Find(0.0f) == 0);
		Test.Assert(h.Find(29.9f) == 2);
		Test.Assert(h.Find(30.0f) == 3);
		Test.Assert(h.Find(500.0f) == 4); // past the end: the last
		Test.Assert(h.Set(1, 25.0f));
		Test.Assert(h.IsMeasured(1));
		Test.Assert(Near(h.Top(2), 35.0f));
		Test.Assert(h.Find(34.0f) == 1);
		h.Insert(0, 2, 5.0f);
		Test.Assert(h.Count == 7);
		Test.Assert(Near(h.Top(3), 20.0f)); // 5, 5, 10, then the 25
		Test.Assert(Near(h.Top(4), 45.0f));
		h.Remove(0, 2);
		Test.Assert(Near(h.Top(2), 35.0f));
		h.Move(1, 1, 4); // the 25 row goes last
		Test.Assert(Near(h.At(4), 25.0f));
		Test.Assert(Near(h.Total, 65.0f));
	}

	/// Fitting its rows, it measures as tall as they are, and follows their count.
	[Test]
	public static void FittingItsRowsItMeasuresAsTallAsTheyAreAndFollowsTheirCount()
	{
		let model = ItemViewFixtures.Numbered(5);
		defer delete model;
		// A list with no height of its own, as one placed among other content.
		let root = SceneFixtures.NewScene(300.0f, 600.0f);
		defer root.ReleaseRef(); // the tree, the list with it
		let list = new ListView();
		list.RowHeight = 20.0f;
		root.AddChild(list);
		list.ReleaseRef(); // the tree holds it
		list.Model = model;
		let open = LayoutConstraints(.(0.0f, 0.0f), .(300.0f, 10000.0f), .(300.0f, -1.0f), false, false);
		list.FitsRows = true;
		root.UpdateLayout();
		Test.Assert(Near(list.Measure(open).Y, 100.0f), "five rows of 20");
		model.RemoveItem(4);
		model.RemoveItem(3);
		root.UpdateLayout();
		Test.Assert(Near(list.Measure(open).Y, 60.0f));
	}

	[Test]
	public static void MeasuredRowsTakeTheirOwnHeightsOnceRealisedEstimatedUntilThen()
	{
		let model = ItemViewFixtures.Numbered(100);
		defer delete model;
		let m = scope ListBed(model, 20.0f);
		int created = 0;
		m.List.SetRowFactory(TallRows(&created));
		m.List.RowHeight = 0.0f; // measured
		m.List.EstimatedRowHeight = 25.0f;
		m.Layout();
		// Rows 0..: 10, 20, 30, 40, 10, ... The first rows are measured; the rest still estimated.
		let r2 = m.List.ItemBounds(2);
		Test.Assert(Near(r2.Y, 30.0f));
		Test.Assert(Near(r2.Height, 30.0f));
		Test.Assert(Near(m.List.ItemBounds(99).Height, 25.0f));
		Test.Assert(m.List.ContentExtent.Y > 100.0f * 10.0f);
		// A row's content fills it.
		let row = m.List.RowForItem(3);
		Test.Assert(row != null);
		Test.Assert(Near(row.Size.Y, 40.0f));
	}

	[Test]
	public static void RowsComeFromAFactoryOnePoolPerTypeRecycledAsTheyScroll()
	{
		let model = ItemViewFixtures.Numbered(200);
		defer delete model;
		let m = scope ListBed(model);
		int created = 0;
		uint32[2] boundTypes = .(0, 0);
		let f = new RowFactory();
		f.TypeOf = new (index) => (uint32)(index.Row % 2);
		f.Create = new [&] (type) =>
			{
				++created;
				let label = new Label();
				label.AddClass((type == 0) ? "even" : "odd");
				return label;
			};
		f.Bind = new [&] (content, index) =>
			{
				let label = (Label)content;
				Test.Assert(label.HasClass((index.Row % 2 == 0) ? "even" : "odd")); // a row of its type
				++boundTypes[index.Row % 2];
				label.Text = model.ItemAt(index.Row);
			};
		m.List.SetRowFactory(f);
		m.Layout();
		let firstMade = created;
		Test.Assert(firstMade == 6);

		// Scrolling a long way makes no more rows: the ones that leave are taken again.
		for (int i = 0; i < 20; ++i)
		{
			m.D.InjectMouseWheel(.(50.0f, 50.0f), .(0.0f, -3.0f));
			m.Layout();
		}
		Test.Assert(Near(m.List.ScrollOffset.Y, 1200.0f));
		Test.Assert(created <= firstMade + 2);
		Test.Assert(m.List.VisibleRowCount <= 7);
		let row = m.List.RowForItem(61);
		Test.Assert(row != null);
		Test.Assert(((Label)row.Content).Text == "item 61");
		Test.Assert(boundTypes[0] > 6);
		Test.Assert(boundTypes[1] > 6);
	}

	[Test]
	public static void RowsInsertedAboveLeaveWhatIsInViewWhereItIs()
	{
		let model = ItemViewFixtures.Numbered(100);
		defer delete model;
		let m = scope ListBed(model);
		m.List.ScrollToItem(50, .Start);
		m.Layout();
		Test.Assert(Near(m.List.ScrollOffset.Y, 1000.0f));
		for (int i = 0; i < 3; ++i)
			model.InsertItem(0, "new");
		m.Layout();
		// Item 50 is now item 53, still at the top of the view.
		Test.Assert(Near(m.List.ScrollOffset.Y, 53.0f * 20.0f));
		let top = m.List.RowForItem(53);
		Test.Assert(top != null);
		Test.Assert(((Label)top.Content).Text == "item 50");
	}

	/// Twenty rows, then three: they fit the view, so it cannot scroll. Scrolled to the third with
	/// the layout still pending (the offset unclamped until it runs), the layout's range clamps the
	/// offset back to the top; the rows are taken there, not left where the scroll aimed (the first
	/// two missing, a gap over the rest).
	[Test]
	public static void ScrolledToAnItemBeforeALayoutThatClampsTheOffsetTheRowsFollowTheClamp()
	{
		let model = ItemViewFixtures.Numbered(20);
		defer delete model;
		let m = scope ListBed(model);
		for (int i = 0; i < 17; ++i)
			model.RemoveItem(3);
		m.List.ScrollToItem(2, .Start);
		m.Layout();
		Test.Assert(Near(m.List.ScrollOffset.Y, 0.0f));
		let first = m.List.RowForItem(0);
		Test.Assert(first != null);
		Test.Assert(((Label)first.Content).Text == "item 0");
		Test.Assert(Near(first.ScreenBounds.Y, m.List.ScreenBounds.Y));
		Test.Assert(m.List.RowForItem(1) != null);
	}

	[Test]
	public static void ARowAboveMeasuringTallerThanItsEstimateLeavesTheViewWhereItIs()
	{
		let model = ItemViewFixtures.Numbered(100);
		defer delete model;
		let m = scope ListBed(model);
		int created = 0;
		m.List.SetRowFactory(TallRows(&created));
		m.List.RowHeight = 0.0f;
		m.List.EstimatedRowHeight = 10.0f;
		m.Layout();
		// Jump to item 40: realised with the row above it (39), whose measuring is put back at once.
		m.List.ScrollToItem(40, .Start);
		m.Layout();
		let before = m.List.ItemBounds(40).Y;
		Test.Assert(Near(m.List.ScrollOffset.Y, before));
		// Five pixels up realises row 38 (30 high, estimated 10): everything below it moves down 20,
		// and the offset with it, so the view shows what it did, five pixels higher.
		m.List.ScrollBy(.(0.0f, -5.0f));
		m.Layout();
		Test.Assert(Near(m.List.ItemBounds(40).Y - before, 20.0f));
		Test.Assert(Near(m.List.ItemBounds(40).Y - m.List.ScrollOffset.Y, 5.0f));
	}

	[Test]
	public static void TheSelectionIsASetOfIdsItFollowsRowsInsertedAboveAndLeavesWithARemovedRow()
	{
		let model = ItemViewFixtures.Numbered(10);
		defer delete model;
		let m = scope ListBed(model);
		m.List.SelectedItem = 4;
		model.InsertItem(0, "new");
		Test.Assert(m.List.SelectedItem == 5);
		Test.Assert(m.List.SelectedIndex.Row == 5);
		model.MoveItem(5, 0);
		Test.Assert(m.List.SelectedItem == 0);
		model.RemoveItem(0);
		Test.Assert(m.List.SelectedItem == -1);
		Test.Assert(m.List.SelectionCount == 0);
	}

	[Test]
	public static void ATablesSelectionFollowsItsRowWhenAHeaderClickSortsIt()
	{
		let model = scope TableModel();
		StringView[2] columns = .("Name", "Score");
		model.SetColumns(columns);
		StringView[3] names = .("b", "a", "c");
		int64[3] scores = .(2, 10, 1);
		for (int i = 0; i < 3; ++i)
		{
			Sedulous.GUI.Variant[2] row = .(.(names[i]), .(scores[i]));
			model.AddRow(row);
		}
		let proxy = scope SortingProxyModel(model);
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let table = new TableView();
		table.Size = .(300.0f, 200.0f);
		table.RowHeight = 24.0f;
		root.AddChild(table);
		table.ReleaseRef();
		table.Model = proxy;
		root.UpdateLayout();
		table.SelectedItem = 0; // "b"

		// Nothing listening to the header: a click sorts through the model's capability.
		SceneFixtures.Click(root.EventDispatcher, .(200.0f, 13.0f));
		Test.Assert(proxy.SortColumn == 1);
		Test.Assert(proxy.Data(MakeModelIndex(0, 0)).AsString == "c"); // 1, 2, 10
		Test.Assert(table.SelectedItem == 1); // "b" is second now
		Test.Assert(proxy.Data(MakeModelIndex(table.SelectedItem, 0)).AsString == "b");
	}

	[Test]
	public static void ASelectedRowShowsSelectedAContextMenuAskedForOverARowSelectsIt()
	{
		RegisterGuiElements();
		let model = ItemViewFixtures.Numbered(10);
		defer delete model;
		let m = scope ListBed(model);
		m.List.SelectedItem = 1;
		m.Layout();
		let row = m.List.RowForItem(1);
		Test.Assert(row != null);
		Test.Assert((row.WidgetStates & WidgetStateSelected) != 0);
		Test.Assert(row.IsSelected);
		Test.Assert(!m.List.RowForItem(2).IsSelected);

		bool asked = false;
		m.List.AddEventListener(.ContextMenu, new [&] (e) => { asked = true; });
		m.D.InjectMouseDown(.(50.0f, 70.0f), .Right); // row 3
		m.D.InjectMouseUp(.(50.0f, 70.0f), .Right);
		Test.Assert(asked);
		Test.Assert(m.List.SelectedItem == 3);
	}

	[Test]
	public static void ADoubleClickReturnAndThePadsSouthReportActivate()
	{
		let model = ItemViewFixtures.Numbered(10);
		defer delete model;
		let m = scope ListBed(model);
		int activations = 0;
		int32 lastItem = -1;
		ModelIndex lastIndex = .();
		m.List.AddEventListener(.ItemActivate, new [&] (e) =>
			{
				++activations;
				lastItem = ((ItemEvent)e).Item;
			});
		m.List.SetOnActivated(new [&] (index) => { lastIndex = index; });

		SceneFixtures.Click(m.D, .(50.0f, 30.0f));
		Test.Assert(activations == 0);
		SceneFixtures.Click(m.D, .(50.0f, 30.0f)); // the second press
		Test.Assert(activations == 1);
		Test.Assert(lastItem == 1);
		Test.Assert(lastIndex.Row == 1);

		m.D.InjectKeyDown((uint32)KeyCode.Down);
		m.D.InjectKeyDown((uint32)KeyCode.Return);
		Test.Assert(activations == 2);
		Test.Assert(lastItem == 2);
	}

	[Test]
	public static void TypingLettersJumpsToTheNextRowStartingWithThem()
	{
		let model = scope StringListModel();
		StringView[6] names = .("Apple", "Banana", "blueberry", "Cherry", "Bilberry", "Date");
		for (let n in names)
			model.AddItem(n);
		let m = scope ListBed(model, 20.0f, 200.0f);
		m.List.RequestFocus();
		int changes = 0;
		m.List.AddEventListener(.Changed, new [&] (e) => { ++changes; });
		m.D.InjectKeyDown((uint32)KeyCode.B);
		m.D.InjectText("b"); // the text it types: what type-ahead reads
		Test.Assert(m.List.SelectedItem == 1);
		m.D.InjectKeyDown((uint32)KeyCode.L);
		m.D.InjectText("l"); // "bl"
		Test.Assert(m.List.SelectedItem == 2);
		Test.Assert(changes == 2);
		// After a pause, "b" again cycles through the b's.
		m.Root.Context.Update(SceneFixtures.Seconds(1.5));
		m.D.InjectKeyDown((uint32)KeyCode.B);
		m.D.InjectText("b");
		Test.Assert(m.List.SelectedItem == 4);
		m.D.InjectKeyDown((uint32)KeyCode.B);
		m.D.InjectText("b"); // "bb": one letter again, the next b
		Test.Assert(m.List.SelectedItem == 1);
	}

	[Test]
	public static void F2EditsARowInPlaceTheHooksMayRefuseEscapeCancelsReturnCommits()
	{
		let model = ItemViewFixtures.Numbered(5);
		defer delete model;
		let m = scope ListBed(model);
		m.List.RequestFocus();
		m.List.SelectedItem = 1;

		// Not editable: F2 does nothing.
		m.D.InjectKeyDown((uint32)KeyCode.F2);
		Test.Assert(!m.List.IsEditing);

		model.Editable = true;
		bool allowBegin = false;
		m.List.SetOnEditBegin(new [&] (index) => allowBegin);
		m.D.InjectKeyDown((uint32)KeyCode.F2);
		Test.Assert(!m.List.IsEditing);
		allowBegin = true;
		m.D.InjectKeyDown((uint32)KeyCode.F2);
		Test.Assert(m.List.IsEditing);
		let editor = m.List.Editor;
		Test.Assert(editor.IsFocused);
		Test.Assert(editor.Text == "item 1");
		Test.Assert(editor.Parent == m.List.RowForItem(1));

		// Escape cancels: the model keeps its text, the view the focus.
		int cancels = 0;
		m.List.SetOnEditCancel(new [&] (index) => { ++cancels; });
		m.D.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(!m.List.IsEditing);
		Test.Assert(cancels == 1);
		Test.Assert(model.ItemAt(1) == "item 1");
		Test.Assert(m.List.IsFocused);

		// The commit hook refuses an empty name: it stays editing, marked invalid.
		m.List.SetOnEditCommit(new (index, text) => text.Length != 0);
		Test.Assert(m.List.BeginEdit(1));
		editor.Text = "";
		m.D.InjectKeyDown((uint32)KeyCode.Return);
		Test.Assert(m.List.IsEditing);
		Test.Assert(editor.HasClass("invalid"));
		editor.Text = "renamed";
		m.D.InjectKeyDown((uint32)KeyCode.Return);
		Test.Assert(!m.List.IsEditing);
		Test.Assert(model.ItemAt(1) == "renamed");
		m.Layout();
		Test.Assert(((Label)m.List.RowForItem(1).Content).Text == "renamed");
	}

	[Test]
	public static void TheViewIsANodeScrollContainerScrolledFromCodeLikeAnyOther()
	{
		let model = ItemViewFixtures.Numbered(50);
		defer delete model;
		let m = scope ListBed(model);
		Test.Assert(m.List.IsScrollContainer);
		Test.Assert(Near(m.List.ScrollRange.Y, 50.0f * 20.0f - 100.0f));
		// Scrolled from code like any scroller: the rows follow.
		m.List.ScrollTo(.(0.0f, 400.0f), .Instant);
		Test.Assert(m.List.RowForItem(20) != null);
		Test.Assert(m.List.RowForItem(0) == null);
		Test.Assert(m.List.ItemAt(.(50.0f, 5.0f)) == 20);
	}

	[Test]
	public static void MarkupsTemplateIsMadeIntoEachRowItsItemAndIndexFilled()
	{
		RegisterGuiElements();
		let root = SceneFixtures.NewScene(300.0f, 300.0f);
		defer root.ReleaseRef();
		let loader = scope MarkupLoader(root.ElementSet);
		let tree = loader.LoadFromString(
			"<ListView width=\"200\" height=\"100\" row-height=\"20\" items=\"Ada|Bo|Cara\" selection-mode=\"multi\">\n" +
			"    <template><Panel flex-direction=\"row\"><Label class=\"name\" text=\"{{item}}\"/><Label class=\"nth\" text=\"#{{index}}\"/></Panel></template>\n" +
			"</ListView>");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();
		let list = tree as ListView;
		Test.Assert(list != null);
		root.AddChild(list);
		root.UpdateLayout();
		Test.Assert(list.Model.RowCount() == 3);
		Test.Assert(list.SelectionMode == .Multi);
		Test.Assert(list.ItemsText == "Ada|Bo|Cara");
		var row = list.RowForItem(1);
		Test.Assert(row != null);
		let content = row.Content as TemplateRowContent;
		Test.Assert(content != null);
		Test.Assert(content.ChildCount == 1);
		let panel = content.GetChildAt(0);
		Test.Assert(panel.ChildCount == 2);
		Test.Assert((panel.GetChildAt(0) as Label).Text == "Bo");
		Test.Assert((panel.GetChildAt(1) as Label).Text == "#1");
		Test.Assert((panel.GetChildAt(0) as Label).HasClass("name"));

		// A changed row is filled again; selecting is bindable.
		list.ItemsText = "Ada|Bea|Cara";
		root.UpdateLayout();
		row = list.RowForItem(1);
		Test.Assert((row.Content.GetChildAt(0).GetChildAt(0) as Label).Text == "Bea");
	}

	[Test]
	public static void TemplatesOfATypeArePickedByTheRowTypeColumnsTextEachTypeItsOwnPool()
	{
		RegisterGuiElements();
		let model = scope TableModel();
		StringView[2] columns = .("Kind", "Title");
		model.SetColumns(columns);
		StringView[4] kinds = .("header", "entry", "entry", "header");
		StringView[4] titles = .("Fruit", "Apple", "Pear", "Nuts");
		for (int i = 0; i < 4; ++i)
		{
			Sedulous.GUI.Variant[2] row = .(.(kinds[i]), .(titles[i]));
			model.AddRow(row);
		}
		let root = SceneFixtures.NewScene(300.0f, 300.0f);
		defer root.ReleaseRef();
		let loader = scope MarkupLoader(root.ElementSet);
		let tree = loader.LoadFromString(
			"<ListView width=\"200\" height=\"200\" row-height=\"0\" row-type-column=\"Kind\">\n" +
			"    <template><Label class=\"entry\" text=\"{{item.Title}}\" height=\"20\"/></template>\n" +
			"    <template type=\"header\"><Label class=\"header\" text=\"== {{item.Title}} ==\" height=\"30\"/></template>\n" +
			"</ListView>");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();
		let list = tree as ListView;
		Test.Assert(list != null);
		root.AddChild(list);
		list.Model = model;
		root.UpdateLayout();
		root.UpdateLayout();
		Label LabelOf(int32 item) => list.RowForItem(item).Content.GetChildAt(0) as Label;
		Test.Assert(LabelOf(0).HasClass("header"));
		Test.Assert(LabelOf(0).Text == "== Fruit ==");
		Test.Assert(LabelOf(1).HasClass("entry"));
		Test.Assert(LabelOf(1).Text == "Apple");
		Test.Assert(LabelOf(3).HasClass("header"));
		Test.Assert(list.RowForItem(0).RowType != list.RowForItem(1).RowType);
	}

	[Test]
	public static void AGridLaysCellsAcrossThenDownStretchedToFillTheArrowsMoveAcrossAndDown()
	{
		let model = ItemViewFixtures.Numbered(50);
		defer delete model;
		let m = scope ListBed(model, 20.0f, 100.0f);
		m.List.LayoutMode = .Grid;
		m.List.CellWidth = 60.0f;
		m.List.CellHeight = 40.0f;
		m.Layout();
		// 200 wide: 3 cells of 66.7 across; 17 lines of 40.
		Test.Assert(m.List.ColumnsAcross == 3);
		Test.Assert(Near(m.List.ScrollRange.Y, 17.0f * 40.0f - 100.0f));
		let cell = m.List.RowForItem(4);
		Test.Assert(cell != null);
		Test.Assert(Near(cell.Position.X, 200.0f / 3.0f, 0.02f));
		Test.Assert(Near(cell.Position.Y, 40.0f));
		Test.Assert(Near(cell.Size.X, 200.0f / 3.0f, 0.02f));
		// Lines 0 to 2 in view and one past: 12 cells, not 50.
		Test.Assert(m.List.VisibleRowCount == 12);
		Test.Assert(m.List.ItemAt(.(150.0f, 50.0f)) == 5);

		m.List.RequestFocus();
		m.List.SelectedItem = 4;
		m.D.InjectKeyDown((uint32)KeyCode.Right);
		Test.Assert(m.List.SelectedItem == 5);
		m.D.InjectKeyDown((uint32)KeyCode.Down);
		Test.Assert(m.List.SelectedItem == 8);
		m.D.InjectKeyDown((uint32)KeyCode.Up);
		m.D.InjectKeyDown((uint32)KeyCode.Up);
		Test.Assert(m.List.SelectedItem == 2);
		m.D.InjectKeyDown((uint32)KeyCode.End);
		m.Layout();
		Test.Assert(m.List.SelectedItem == 49);
		Test.Assert(Near(m.List.ScrollOffset.Y, m.List.ScrollRange.Y));
		Test.Assert(m.List.RowForItem(49) != null);

		// Narrower: fewer across, more lines.
		m.List.Size = .(130.0f, 100.0f);
		m.Layout();
		Test.Assert(m.List.ColumnsAcross == 2);
		Test.Assert(m.List.LayoutModeName == "grid");
	}

	// The rows a view shows now (its children displayed).
	private static int ShownRows(ItemView view)
	{
		int count = 0;
		for (int i = 0; i < view.ChildCount; ++i)
		{
			if (let row = view.GetChildAt(i) as ItemRow)
			{
				if (row.Displayed)
					++count;
			}
		}
		return count;
	}

	[Test]
	public static void AGridWhoseItemsTakeAnotherRowTypeShowsOnlyTheNewRowsATilesAndListSwitch()
	{
		let model = ItemViewFixtures.Numbered(6);
		defer delete model;
		let m = scope ListBed(model, 20.0f, 200.0f);
		uint32 kind = 0;
		let rows = new RowFactory();
		rows.TypeOf = new [&] (index) => kind;
		rows.Create = new (type) => (Node)new Panel();
		rows.Bind = new (content, index) => { };
		m.List.SetRowFactory(rows);
		m.List.LayoutMode = .Grid;
		m.List.CellWidth = 60.0f;
		m.List.CellHeight = 40.0f;
		m.Layout();
		Test.Assert(ShownRows(m.List) == 6);
		kind = 1; // the other kind of row, for every item
		// The same items, told to bind again (that gives them new ids, and rows of items no
		// longer there go back on their own): each live row is kept for its
		// item and then not taken, its item wanting the other kind.
		m.List.OnModelReset();
		m.Layout();
		Test.Assert(ShownRows(m.List) == 6, "not twelve: the old rows went back to their pool");
		// Here a row not taken is hidden either way; whether it went back is its pool's to say.
		Test.Assert(m.List.[Friend]PoolOf(0).Rows.Count == 6, "the old rows are in their pool, to be used again");
		for (int i = 0; i < m.List.ChildCount; ++i)
		{
			if (let row = m.List.GetChildAt(i) as ItemRow)
			{
				if (row.Displayed)
					Test.Assert(row.RowType == 1);
			}
		}
	}

	[Test]
	public static void InRightToLeftAGridLaysItsCellsFromTheRight()
	{
		let model = ItemViewFixtures.Numbered(50);
		defer delete model;
		let m = scope ListBed(model, 20.0f, 100.0f);
		m.Root.SetLayoutDirection(.RightToLeft);
		m.List.LayoutMode = .Grid;
		m.List.CellWidth = 60.0f;
		m.List.CellHeight = 40.0f;
		m.Layout();
		Test.Assert(m.List.ColumnsAcross == 3);
		let first = m.List.RowForItem(0);
		let second = m.List.RowForItem(1);
		Test.Assert(first != null);
		Test.Assert(second != null);
		let @box = m.List.ContentBounds;
		Test.Assert(Near(first.Position.X + first.Size.X, @box.X + @box.Width, 0.01f));
		Test.Assert(second.Position.X < first.Position.X);
		Test.Assert(Near(m.List.ItemBounds(1).X, second.Position.X, 0.01f));
	}

	[Test]
	public static void InRightToLeftAGridsLeftGoesOnToTheNextCellAndRightBack()
	{
		let model = ItemViewFixtures.Numbered(50);
		defer delete model;
		let m = scope ListBed(model, 20.0f, 100.0f);
		m.Root.SetLayoutDirection(.RightToLeft);
		m.List.LayoutMode = .Grid;
		m.List.CellWidth = 60.0f;
		m.List.CellHeight = 40.0f;
		m.Layout();
		m.List.RequestFocus();
		m.List.SelectedItem = 4;
		m.D.InjectKeyDown((uint32)KeyCode.Left);
		Test.Assert(m.List.SelectedItem == 5);
		m.D.InjectKeyDown((uint32)KeyCode.Right);
		m.D.InjectKeyDown((uint32)KeyCode.Right);
		Test.Assert(m.List.SelectedItem == 3);
	}

	[Test]
	public static void ATemplatesRootFillsItsRowOrAGridsCellInsideItsMargin()
	{
		RegisterGuiElements();
		let root = SceneFixtures.NewScene(300.0f, 300.0f);
		defer root.ReleaseRef();
		let loader = scope MarkupLoader(root.ElementSet);
		let tree = loader.LoadFromString(
			"<ListView width=\"200\" height=\"100\" layout=\"grid\" cell-width=\"100\" cell-height=\"50\" items=\"a|b|c\">\n" +
			"    <template><Panel margin=\"4\"><Label text=\"{{item}}\"/></Panel></template>\n" +
			"</ListView>");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();
		let list = tree as ListView;
		Test.Assert(list != null);
		root.AddChild(list);
		root.UpdateLayout();
		let tile = list.RowForItem(1).Content.GetChildAt(0);
		Test.Assert(Near(tile.Size.X, 92.0f));
		Test.Assert(Near(tile.Size.Y, 42.0f));
		Test.Assert(Near(tile.Position.X, 4.0f));
	}

	[Test]
	public static void RowsMadeBeforeTheyAreStyledKeepTheirEstimateAndTheViewStillStartsAtTheFirst()
	{
		// As a page shown after the GUI started: its list makes its rows before a sheet has styled
		// them, so they measure nothing; that must not stand as their height.
		RegisterGuiElements();
		let root = SceneFixtures.NewScene(600.0f, 600.0f);
		defer root.ReleaseRef();
		let loader = scope MarkupLoader(root.ElementSet);
		let tree = loader.LoadFromString(
			"<ListView width=\"420\" height=\"200\" row-height=\"0\" estimated-row-height=\"40\" items=\"a|b|c|d|e|f\">\n" +
			"    <template><Panel class=\"tall-row\"/></template>\n" +
			"</ListView>");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();
		let list = tree as ListView;
		Test.Assert(list != null);
		root.AddChild(list);
		root.UpdateLayout(); // the rows made, unstyled
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, ".tall-row { height: 30px; }");
		for (int frame = 0; frame < 3; ++frame)
		{
			styles.ApplyTree(root);
			root.UpdateLayout();
		}
		let first = list.RowForItem(0);
		Test.Assert(first != null);
		Test.Assert(Near(first.Position.Y, 0.0f));
		Test.Assert(Near(first.Size.Y, 30.0f));
		let fourth = list.RowForItem(3);
		Test.Assert(fourth != null);
		Test.Assert(Near(fourth.Position.Y, 90.0f));
	}
}
