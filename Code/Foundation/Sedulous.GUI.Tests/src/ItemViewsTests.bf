using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// The item views beyond what their own tests show: a range and every item picked from the keys,
/// a tree walked by its arrows, a table's cell edited in place into its model's column, rows
/// following removals and moves, an item activated by a screen reader, which widgets a screen
/// reader may press, a node described alone, and each view built by its tag with its properties
/// set by their CSS names.
class ItemViewsTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	[Test]
	public static void TheKeysSelectARangeWithShiftEveryItemWithCtrlAAndPickOneWithCtrlSpace()
	{
		let model = ItemViewFixtures.Numbered(10);
		defer delete model;
		let m = scope ListBed(model, 20.0f, 120.0f);
		m.List.SelectionMode = .Multi;
		m.List.RequestFocus();
		m.D.InjectKeyDown((uint32)KeyCode.Down); // nothing selected -> row 0, the anchor
		Test.Assert(m.List.SelectedItem == 0);
		m.D.InjectKeyDown((uint32)KeyCode.Down, KeyModShift);
		m.D.InjectKeyDown((uint32)KeyCode.Down, KeyModShift); // 0 to 2
		Test.Assert(m.List.SelectionCount == 3);
		Test.Assert(m.List.SelectedItem == 2);
		Test.Assert(m.List.IsItemSelected(1));
		// Ctrl moves the keyboard alone: row 3 is current, not selected.
		m.D.InjectKeyDown((uint32)KeyCode.Down, KeyModCtrl);
		Test.Assert(m.List.CurrentItem == 3);
		Test.Assert(m.List.SelectionCount == 3);
		Test.Assert(m.List.SelectedItem == -1);
		// Ctrl+Space picks it, beside the range.
		m.D.InjectKeyDown((uint32)KeyCode.Space, KeyModCtrl);
		Test.Assert(m.List.SelectionCount == 4);
		Test.Assert(m.List.SelectedItem == 3);
		// Ctrl+A: every item.
		m.D.InjectKeyDown((uint32)KeyCode.A, KeyModCtrl);
		Test.Assert(m.List.SelectionCount == 10);
		let ids = scope List<ItemId>();
		m.List.GetSelectedIds(ids);
		Test.Assert(ids.Count == 10);
	}

	[Test]
	public static void ATreesArrowsGoIntoAnOpenNodeAndBackToItsParentClosingANodeSelectsIt()
	{
		// A [A1 [A1x], A2], B
		let model = scope TreeModel();
		let a = model.AddNode(TreeModel.Root, "A");
		model.AddNode(TreeModel.Root, "B");
		let a1 = model.AddNode(a, "A1");
		model.AddNode(a, "A2");
		model.AddNode(a1, "A1x");
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let tree = new TreeView();
		tree.Size = .(260.0f, 300.0f);
		tree.RowHeight = 20.0f;
		root.AddChild(tree);
		tree.ReleaseRef();
		tree.Model = model;
		root.UpdateLayout();
		let d = root.EventDispatcher;
		tree.RequestFocus();
		tree.SelectedItem = 0; // A
		d.InjectKeyDown((uint32)KeyCode.Right); // opens A: A, A1, A2, B
		Test.Assert(tree.IsItemExpanded(0));
		Test.Assert(tree.SelectedItem == 0);
		d.InjectKeyDown((uint32)KeyCode.Right); // open already: into its first child, A1
		Test.Assert(tree.SelectedItem == 1);
		d.InjectKeyDown((uint32)KeyCode.Left); // A1 closed: back to its parent, A
		Test.Assert(tree.SelectedItem == 0);
		d.InjectKeyDown((uint32)KeyCode.Right);
		d.InjectKeyDown((uint32)KeyCode.Right); // A1 opened: A, A1, A1x, A2, B
		Test.Assert(tree.IsItemExpanded(1));
		Test.Assert(tree.VisibleRowCount == 5);
		d.InjectKeyDown((uint32)KeyCode.Right); // into A1x
		Test.Assert(tree.SelectedItem == 2);
		Test.Assert(tree.ItemDepth(2) == 2);
		// Closing A while the keyboard is on A1x, under it: A is selected.
		tree.CollapseItem(0);
		Test.Assert(tree.SelectedItem == 0);
		Test.Assert(tree.VisibleRowCount == 2);
		// Expansion by id survives the closing of what holds it.
		Test.Assert(tree.IsIdExpanded((ItemId)a1));
	}

	[Test]
	public static void ATablesCellEditedInPlaceCommitsToItsColumnInTheModel()
	{
		let model = scope TableModel();
		StringView[2] columns = .("Name", "Age");
		model.SetColumns(columns);
		for (int i = 0; i < 3; ++i)
		{
			Sedulous.GUI.Variant[2] row = .(.((StringView)"Person"), .((int64)(20 + i)));
			model.AddRow(row);
		}
		model.Editable = true;
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let table = new TableView();
		table.Size = .(300.0f, 200.0f);
		table.RowHeight = 24.0f;
		root.AddChild(table);
		table.ReleaseRef();
		table.Model = model;
		root.UpdateLayout();

		Test.Assert(table.BeginEdit(1, 1)); // row 1's age
		let editor = table.Editor;
		Test.Assert(editor.Parent == table.RowForItem(1));
		Test.Assert(editor.Text == "21");
		// Over its column: the second of two 150 wide.
		Test.Assert(Near(editor.Position.X, 150.0f));
		Test.Assert(Near(editor.Size.X, 150.0f));
		editor.Text = "33";
		root.EventDispatcher.InjectKeyDown((uint32)KeyCode.Return);
		Test.Assert(!table.IsEditing);
		Test.Assert(model.Cell(1, 1).Kind == .Int); // a number column keeps numbers
		Test.Assert(model.Cell(1, 1).AsInt == 33);
		Test.Assert(model.Cell(1, 0).AsString == "Person");
		root.UpdateLayout();
		let content = table.RowForItem(1).Content as TableRowContent;
		Test.Assert(content.CellAt(1).Text == "33");

		// A value the model refuses (a word for a number) keeps it editing, marked invalid.
		Test.Assert(table.BeginEdit(2, 1));
		editor.Text = "old";
		root.EventDispatcher.InjectKeyDown((uint32)KeyCode.Return);
		Test.Assert(table.IsEditing);
		Test.Assert(editor.HasClass("invalid"));
		Test.Assert(model.Cell(2, 1).AsInt == 22);
		Test.Assert(table.EndEdit(false));
		Test.Assert(!table.IsEditing);
	}

	[Test]
	public static void RowsFollowRemovalsAndMovesTheirTextAndTheSelectionWithThem()
	{
		let model = ItemViewFixtures.Numbered(10);
		defer delete model;
		let m = scope ListBed(model);
		m.List.SelectedItem = 5; // "item 5"
		model.RemoveItem(0);
		m.Layout();
		Test.Assert(m.List.SelectedItem == 4);
		Test.Assert(((Label)m.List.RowForItem(0).Content).Text == "item 1");
		Test.Assert(m.List.RowForItem(4).IsSelected);
		model.MoveItem(8, 0); // "item 9" first
		m.Layout();
		Test.Assert(((Label)m.List.RowForItem(0).Content).Text == "item 9");
		Test.Assert(((Label)m.List.RowForItem(1).Content).Text == "item 1");
		Test.Assert(m.List.SelectedItem == 5);
		Test.Assert(m.List.RowForItem(5).IsSelected);
		Test.Assert(!m.List.RowForItem(4).IsSelected);
		// A changed row is filled again where it is.
		model.SetItem(2, "changed");
		m.Layout();
		Test.Assert(((Label)m.List.RowForItem(2).Content).Text == "changed");
	}

	[Test]
	public static void AScreenReaderActivatesAnItemThroughItsViewNotOneOfADisabledView()
	{
		let model = ItemViewFixtures.Numbered(10);
		defer delete model;
		let m = scope ListBed(model);
		int32 activated = -1;
		m.List.AddEventListener(.ItemActivate, new [&] (e) => { activated = ((ItemEvent)e).Item; });
		let tree = m.Root.Context.BuildAccessTree(m.Root);
		defer delete tree;
		AccessNode third = null;
		for (let n in tree.Nodes)
		{
			if ((n.Role == .ListItem) && (n.PositionInSet == 3))
				third = n;
		}
		Test.Assert(third != null);
		Test.Assert(third.Name == "item 2");
		Test.Assert(third.Takes(.Activate));
		Test.Assert(!third.Has(AccessSelected));
		let request = scope AccessActionRequest();
		request.Target = third.Id;
		request.Action = .Activate;
		Test.Assert(m.Root.Context.RunAccessAction(request));
		Test.Assert(activated == 2);
		// A list item takes no expanding.
		request.Action = .Expand;
		Test.Assert(!m.Root.Context.RunAccessAction(request));

		activated = -1;
		m.List.Enabled = false;
		request.Action = .Activate;
		Test.Assert(!m.Root.Context.RunAccessAction(request));
		Test.Assert(activated == -1);
		let again = scope AccessNode();
		Test.Assert(m.Root.Context.DescribeAccess(m.List, again));
		Test.Assert(again.Role == .List);
		Test.Assert(again.Has(AccessDisabled));
	}

	[Test]
	public static void AButtonsKindOfWidgetAScreenReaderMayPressALabelsItMayNot()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let button = new Button();
		let check = new CheckBox();
		let swatch = new ColorSwatch();
		let combo = new ComboBox();
		let item = new MenuItem();
		let label = new Label();
		let slider = new Slider();
		UIWidget[7] widgets = .(button, check, swatch, combo, item, label, slider);
		for (let w in widgets)
		{
			root.AddChild(w);
			w.ReleaseRef(); // the tree holds it
		}
		Test.Assert(button.AccessActivates);
		Test.Assert(check.AccessActivates);
		Test.Assert(swatch.AccessActivates);
		Test.Assert(combo.AccessActivates);
		Test.Assert(item.AccessActivates);
		Test.Assert(!label.AccessActivates);
		Test.Assert(!slider.AccessActivates);
		let gui = root.Context;
		for (let w in widgets)
		{
			let described = scope AccessNode();
			Test.Assert(gui.DescribeAccess(w, described));
			Test.Assert(described.Takes(.Activate) == w.AccessActivates);
		}
		// Disabled, a button takes it no more.
		button.Enabled = false;
		let disabled = scope AccessNode();
		Test.Assert(gui.DescribeAccess(button, disabled));
		Test.Assert(!disabled.Takes(.Activate));
	}

	[Test]
	public static void ANodeIsDescribedAloneItsOwnNodeAndNoneForALeafsPartOrAHiddenOne()
	{
		let bed = MarkupFixtures.Load("<Panel><Button id=\"ok\" text=\"OK\"/><Label id=\"gone\" text=\"x\" aria-hidden=\"true\"/></Panel>");
		Test.Assert(bed != null);
		defer bed.ReleaseRef();
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		root.AddChild(bed);
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, "");
		styles.ApplyTree(root);
		root.UpdateLayout();
		let gui = root.Context;
		let ok = MarkupFixtures.Find(root, "ok");
		let described = scope AccessNode();
		Test.Assert(gui.DescribeAccess(ok, described));
		Test.Assert(described.Role == .Button);
		Test.Assert(described.Name == "OK");
		Test.Assert(gui.ResolveAccessId(described.Id) == ok);
		// The button's label is its part: no node of its own.
		Node part = null;
		for (int i = 0; i < ok.ChildCount; ++i)
		{
			if (ok.GetChildAt(i) is Label)
				part = ok.GetChildAt(i);
		}
		Test.Assert(part != null);
		Test.Assert(!gui.DescribeAccess(part, scope AccessNode()));
		// Hidden from screen readers: none; the panel, with no role: none.
		Test.Assert(!gui.DescribeAccess(MarkupFixtures.Find(root, "gone"), scope AccessNode()));
		Test.Assert(!gui.DescribeAccess(bed, scope AccessNode()));
		// Out of every GUI: none.
		let loose = new Label();
		defer loose.ReleaseRef();
		Test.Assert(!gui.DescribeAccess(loose, scope AccessNode()));
	}

	[Test]
	public static void EachViewIsBuiltByItsTagItsPropertiesSetByTheirCssNames()
	{
		RegisterGuiElements();
		StringView[5] tags = .("ListView", "TreeView", "TreeItem", "TableView", "TableItem");
		for (let tag in tags)
		{
			let type = ElementTypes.Find(tag);
			Test.Assert(type != null, scope String(tag));
			Test.Assert(type.CanCreate, scope String(tag));
		}
		let made = MarkupFixtures.Load(
			"<ListView selection-mode=\"multi\" layout=\"grid\" cell-width=\"50\" cell-height=\"40\" row-height=\"0\" estimated-row-height=\"30\" row-type-column=\"Kind\" items=\"a|b|c\"/>");
		Test.Assert(made != null);
		defer made.ReleaseRef();
		let list = made as ListView;
		Test.Assert(list != null);
		Test.Assert(list.SelectionMode == .Multi);
		Test.Assert(list.LayoutMode == .Grid);
		Test.Assert(Near(list.CellWidth, 50.0f));
		Test.Assert(Near(list.CellHeight, 40.0f));
		Test.Assert(Near(list.RowHeight, 0.0f));
		Test.Assert(Near(list.EstimatedRowHeight, 30.0f));
		Test.Assert(list.RowTypeColumn == "Kind");
		Test.Assert(list.ItemsText == "a|b|c");
		Test.Assert(list.SelectedItem == -1);
		Test.Assert(list.AccessRoleName == "list");
		// A binding to `selected` writes back: the user picks.
		let selected = ListView.StaticGuiType.FindCss("selected");
		Test.Assert(selected != null);
		Test.Assert(selected.IsTwoWay);
		Test.Assert(selected.Set(list, System.Variant.Create((int32)2)));
		Test.Assert(list.SelectedItem == 2);

		let tableMade = MarkupFixtures.Load("<TableView columns=\"A|B\" column-widths=\"40px 25%\" editable=\"true\"/>");
		Test.Assert(tableMade != null);
		defer tableMade.ReleaseRef();
		let table = tableMade as TableView;
		Test.Assert(table != null);
		Test.Assert(table.ColumnsText == "A|B");
		Test.Assert(table.ColumnWidthsText == "40px 25%");
		Test.Assert(table.Editable);
		Test.Assert(table.ColumnCount == 2);
		Test.Assert(table.AccessRoleName == "table");

		let treeMade = MarkupFixtures.Load("<TreeView><TreeItem text=\"Only\" expanded=\"true\"><TreeItem text=\"Child\"/></TreeItem></TreeView>");
		Test.Assert(treeMade != null);
		defer treeMade.ReleaseRef();
		let tree = treeMade as TreeView;
		Test.Assert(tree != null);
		Test.Assert(tree.AccessRoleName == "tree");
		Test.Assert(tree.IsItemExpanded(0));
		Test.Assert(tree.GetItemCount() == 2);
		let text = scope String();
		tree.GetItemText(1, text);
		Test.Assert(text == "Child");
		Test.Assert(TreeItem.StaticGuiType.FindCss("expanded") != null);
		Test.Assert(TableItem.StaticGuiType.Find("cells") != null);
	}
}
