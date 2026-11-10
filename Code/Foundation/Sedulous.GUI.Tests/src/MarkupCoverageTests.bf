using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Markup coverage: every control is a markup element. The data views take their data from markup
/// (a tree's nested items, a table's columns and rows), a scroll bar is a range like the slider,
/// and a message box waits in its page until code shows it.
class MarkupCoverageTests
{
	private static bool Near(double a, double b) => Math.Abs(a - b) < 1e-5;

	[Test]
	public static void EveryControlIsAnElement()
	{
		String[?] controls = .(
			"<Label/>", "<Button/>", "<CheckBox/>", "<RadioButton/>", "<ToggleSwitch/>", "<Slider/>",
			"<ScrollBar/>", "<ProgressBar/>", "<NumberField/>", "<TextField/>", "<TextArea/>",
			"<EditableLabel/>", "<RichText/>", "<Image/>", "<Separator/>", "<Spacer/>", "<Panel/>",
			"<ScrollView/>", "<Expander/>", "<ComboBox/>", "<ListBox/>",
			"<TabBar/>", "<TabView/>", "<Menu/>", "<MenuBar/>", "<Window/>",
			"<MessageBox/>", "<ListView/>", "<TreeView/>", "<TableView/>");
		for (let markup in controls)
		{
			let made = MarkupFixtures.Load(markup);
			Test.Assert(made != null, markup);
			made?.ReleaseRef();
		}
	}

	[Test]
	public static void AScrollBarIsARangeWithAnOrientationAndAPage()
	{
		let tree = MarkupFixtures.Load("<ScrollBar orientation=\"vertical\" min=\"0\" max=\"100\" page=\"25\" value=\"40\"/>");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();
		let bar = tree as ScrollBar;
		Test.Assert(bar != null);
		Test.Assert(bar.Orientation == .Vertical);
		Test.Assert(Near(bar.Page, 25.0));
		Test.Assert(Near(bar.Value, 40.0));
	}

	[Test]
	public static void AMessageBoxWaitsUnseenInItsPageIsShownModalAndGoesBackAnswered()
	{
		let root = SceneFixtures.NewScene(800.0f, 600.0f);
		defer root.ReleaseRef();
		let page = MarkupFixtures.Load(
			"<Panel><Label text=\"before\"/><MessageBox id=\"ask\" title=\"Delete?\" text=\"It cannot be undone.\" buttons=\"ok-cancel\"/><Label text=\"after\"/></Panel>");
		Test.Assert(page != null);
		defer page.ReleaseRef();
		root.AddChild(page);
		root.UpdateLayout();
		let @box = page.GetChildAt(1) as MessageBox;
		Test.Assert(@box != null);
		Test.Assert(!@box.Displayed);
		Test.Assert(@box.Message == "It cannot be undone.");
		Test.Assert(@box.ButtonCount == 2);

		int changes = 0;
		@box.AddEventListener(.Changed, new [&] (e) => { ++changes; });
		@box.Show();
		Test.Assert(@box.IsOpen);
		Test.Assert(@box.IsModal);
		Test.Assert(@box.Displayed);
		Test.Assert(@box.Parent != page);

		// Escape answers with the leftmost button (Cancel).
		root.EventDispatcher.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(!@box.IsOpen);
		Test.Assert(@box.ResultName == "cancel");
		Test.Assert(changes == 1);
		// Back in its place, unseen, ready to be shown again.
		Test.Assert(@box.Parent == page);
		Test.Assert(page.GetChildIndex(@box) == 1);
		Test.Assert(!@box.Displayed);
		@box.Show();
		Test.Assert(@box.IsOpen);
	}

	[Test]
	public static void ATreeViewsNestedItemsBecomeItsModelOpenWhereTheySay()
	{
		let tree = MarkupFixtures.Load(
			"<TreeView>\n" +
			"    <TreeItem text=\"Code\" expanded=\"true\">\n" +
			"        <TreeItem text=\"GUI\"/>\n" +
			"        <TreeItem text=\"Foundation\"><TreeItem text=\"VG\"/></TreeItem>\n" +
			"    </TreeItem>\n" +
			"    <TreeItem text=\"Data\"/>\n" +
			"</TreeView>");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();
		let view = tree as TreeView;
		Test.Assert(view != null);
		Test.Assert(view.Model != null);
		Test.Assert(view.Model.RowCount() == 2); // Code, Data
		Test.Assert(view.IsItemExpanded(0));
		Test.Assert(view.ItemDepth(1) == 1); // GUI, under the open Code
		Test.Assert(!view.IsItemExpanded(2)); // Foundation, closed
		Test.Assert(view.Model.Data(view.Model.Index(1)).ToString(.. scope String()) == "Data");
	}

	[Test]
	public static void ATableViewsColumnsAndRowsBecomeAModelBehindASortingProxy()
	{
		let root = SceneFixtures.NewScene(400.0f, 300.0f);
		defer root.ReleaseRef();
		let tree = MarkupFixtures.Load(
			"<TableView width=\"300\" height=\"200\" columns=\"Name|Score|Rate\" column-widths=\"50% auto\" editable=\"true\">\n" +
			"    <TableItem cells=\"Ada|42|0.5\"/>\n" +
			"    <TableItem cells=\"Bo|7|1.25\"/>\n" +
			"    <TableItem cells=\"Cara|100|-2\"/>\n" +
			"</TableView>");
		Test.Assert(tree != null);
		defer tree.ReleaseRef();
		let table = tree as TableView;
		Test.Assert(table != null);
		root.AddChild(table);
		root.UpdateLayout();
		let model = table.Model;
		Test.Assert(model != null);
		Test.Assert(model.ColumnCount() == 3);
		Test.Assert(model.RowCount() == 3);
		Test.Assert(table.ColumnsText == "Name|Score|Rate");
		Test.Assert(model.Data(MakeModelIndex(0, 1)).Kind == .Int);
		Test.Assert(model.Data(MakeModelIndex(1, 2)).Kind == .Float);
		Test.Assert(model.Data(MakeModelIndex(2, 2)).Kind == .Int);
		Test.Assert(NodeFixtures.Near(table.GetColumnWidth(0), 150.0f));
		Test.Assert(table.Editable);
		Test.Assert(model.IsEditable(MakeModelIndex(0, 0)));

		// Its header sorts by value (100 after 42, not before).
		SceneFixtures.Click(root.EventDispatcher, .(180.0f, 13.0f));
		Test.Assert(table.SortColumn == 1);
		Test.Assert(model.Data(MakeModelIndex(2, 1)).AsInt == 100);
	}
}
