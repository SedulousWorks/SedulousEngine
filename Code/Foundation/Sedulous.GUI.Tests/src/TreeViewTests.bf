using System;
using Sedulous.Core;
using Sedulous.Fonts.TrueType;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// TreeModel + TreeView tests: hierarchical navigation (RowCount(parent)/Index/ParentIndex/
// HasChildren), and a TreeView that flattens visible nodes, expands/collapses (arrow click +
// keyboard), and remaps selection by node id across re-flattening.

/// A tree model's navigation, and the TreeView over it.
class TreeViewTests
{
	/// Tree:  A [A1 [A1x], A2],  B; and a tree view 260 by 300 over it (tall enough to realise
	/// every visible row) in a root 400 by 400. The model outlives the view.
	private class Bed
	{
		public TreeModel Model = new .() ~ delete _;
		public SceneRoot Root;
		public TreeView Tree;
		public int32 A;
		public int32 B;
		public int32 A1;
		public int32 A2;
		public int32 A1x;

		public this()
		{
			A = Model.AddNode(TreeModel.Root, "A");
			B = Model.AddNode(TreeModel.Root, "B");
			A1 = Model.AddNode(A, "A1");
			A2 = Model.AddNode(A, "A2");
			A1x = Model.AddNode(A1, "A1x");
			Tree = MountTree(Model, out Root);
		}

		public ~this()
		{
			Root.ReleaseRef(); // before the model the view listens to
		}

		public EventDispatcher D => Root.EventDispatcher;
	}

	/// A tree view 260 by 300 over `model` (tall enough to realise every visible row), rows 20 tall
	/// and indented 16, in a root 400 by 400 `root` takes; the root goes before the model.
	private static TreeView MountTree(IModel model, out SceneRoot root)
	{
		root = SceneFixtures.NewScene(400.0f, 400.0f);
		let tree = new TreeView();
		tree.Size = .(260.0f, 300.0f);
		tree.RowHeight = 20.0f;
		tree.IndentWidth = 16.0f;
		root.AddChild(tree);
		tree.ReleaseRef(); // the root holds it
		tree.Model = model;
		root.UpdateLayout();
		return tree;
	}

	/// A tree whose rows' classes come from the model: what each node is now.
	private class StatedTree : TreeModel
	{
		public String AClasses = new .() ~ delete _;

		public override Sedulous.GUI.Variant Data(ModelIndex index, ModelRole role = .Display)
		{
			if (role == .RowClass)
				return (index.InternalId == 0) ? Sedulous.GUI.Variant((StringView)AClasses) : Sedulous.GUI.Variant();
			return base.Data(index, role);
		}

		public void Changed()
		{
			NotifyReset();
		}
	}

	[Test]
	public static void TreeModelHierarchyNavigation()
	{
		// Tree:  A [A1 [A1x], A2],  B
		let model = scope TreeModel();
		let a = model.AddNode(TreeModel.Root, "A");
		model.AddNode(TreeModel.Root, "B");
		let a1 = model.AddNode(a, "A1");
		model.AddNode(a, "A2");
		model.AddNode(a1, "A1x");

		Test.Assert(model.RowCount() == 2); // two roots
		let ia = model.Index(0, 0, ModelIndex()); // A
		Test.Assert(model.Data(ia).AsString == "A");
		Test.Assert(model.HasChildren(ia));
		Test.Assert(model.RowCount(ia) == 2); // A1, A2

		let ia1 = model.Index(0, 0, ia); // A1
		Test.Assert(model.Data(ia1).AsString == "A1");
		Test.Assert(model.RowCount(ia1) == 1); // A1x
		Test.Assert(model.ParentIndex(ia1) == ia); // A1's parent is A

		let ib = model.Index(1, 0, ModelIndex()); // B
		Test.Assert(!model.HasChildren(ib));
		Test.Assert(!model.ParentIndex(ia).IsValid); // A is a root
	}

	[Test]
	public static void CollapsedShowsOnlyRootsExpandingRevealsChildren()
	{
		let b = scope Bed();
		Test.Assert(b.Tree.VisibleRowCount == 2); // A, B (collapsed)

		b.Tree.ExpandItem(0); // expand A -> A, A1, A2, B
		Test.Assert(b.Tree.VisibleRowCount == 4);
		Test.Assert(b.Tree.IsItemExpanded(0));
		Test.Assert(b.Tree.ItemDepth(1) == 1); // A1 is a child

		b.Tree.ExpandItem(1); // expand A1 -> A, A1, A1x, A2, B
		Test.Assert(b.Tree.VisibleRowCount == 5);
		Test.Assert(b.Tree.ItemDepth(2) == 2); // A1x is a grandchild

		b.Tree.CollapseItem(0); // collapse A -> A, B
		Test.Assert(b.Tree.VisibleRowCount == 2);
	}

	[Test]
	public static void ClickingTheArrowTogglesExpansion()
	{
		let b = scope Bed();
		// Root A's arrow: row 0 (y in [0,20]), depth 0 -> arrow at x in [0,16].
		SceneFixtures.Click(b.D, .(8.0f, 10.0f));
		Test.Assert(b.Tree.VisibleRowCount == 4); // expanded
		Test.Assert(b.Tree.IsItemExpanded(0));

		SceneFixtures.Click(b.D, .(8.0f, 10.0f));
		Test.Assert(b.Tree.VisibleRowCount == 2); // collapsed again
	}

	[Test]
	public static void SelectionIsRemappedByNodeIdAcrossExpandCollapse()
	{
		let b = scope Bed();
		b.Tree.ExpandItem(0); // flat: A(0), A1(1), A2(2), B(3)
		b.Tree.SelectedItem = 3; // select B
		let selId = b.Tree.SelectedIndex.InternalId;

		b.Tree.CollapseItem(0); // flat: A(0), B(1) - B moved
		Test.Assert(b.Tree.SelectedItem == 1); // remapped to B's new row
		Test.Assert(b.Tree.SelectedIndex.InternalId == selId); // same node
	}

	[Test]
	public static void KeyboardRightExpandsAndLeftCollapsesTheSelection()
	{
		let b = scope Bed();
		b.Tree.RequestFocus();
		b.Tree.SelectedItem = 0; // select A
		b.D.InjectKeyDown((uint32)KeyCode.Right); // expand A
		Test.Assert(b.Tree.VisibleRowCount == 4);
		Test.Assert(b.Tree.IsItemExpanded(0));
		b.D.InjectKeyDown((uint32)KeyCode.Left); // collapse A
		Test.Assert(b.Tree.VisibleRowCount == 2);
		Test.Assert(!b.Tree.IsItemExpanded(0));
	}

	[Test]
	public static void InRightToLeftLeftExpandsAndRightCollapsesTowardTheWayItIsIndented()
	{
		let b = scope Bed();
		b.Root.SetLayoutDirection(.RightToLeft);
		b.Tree.RequestFocus();
		b.Tree.SelectedItem = 0;
		b.D.InjectKeyDown((uint32)KeyCode.Left); // toward the inline end: expand
		Test.Assert(b.Tree.IsItemExpanded(0));
		b.D.InjectKeyDown((uint32)KeyCode.Right); // toward the start: collapse
		Test.Assert(!b.Tree.IsItemExpanded(0));
	}

	/// A chain twenty levels deep at 32 px a level: the rows in view (about fifteen of 20 px in
	/// 300) pass the view's 260 px by their indent alone, so the rows grow that wide and the view
	/// scrolls sideways.
	[Test]
	public static void ARowDeeperThanTheViewIsWideMakesTheRowsThatWide()
	{
		let model = scope TreeModel();
		var parent = TreeModel.Root;
		for (int depth < 20)
			parent = model.AddNode(parent, "Level");
		let tree = MountTree(model, let root);
		defer root.ReleaseRef(); // before the model the view listens to
		tree.IndentWidth = 32.0f;
		root.UpdateLayout();
		Test.Assert(tree.ContentExtent.X <= 260.0f + 0.5f, "collapsed: nothing passes the edge");
		for (int32 item < 20)
			tree.ExpandItem(item);
		root.UpdateLayout();
		root.UpdateLayout(); // the widest row measured as it binds; the rows take it next
		Test.Assert(tree.ContentExtent.X > 10.0f * 32.0f, scope $"{tree.ContentExtent.X}");
		Test.Assert(tree.ScrollRange.X > 0.0f, "and it scrolls across them, not only cut at its edge");
		let row = tree.RowForItem(10);
		Test.Assert(row != null);
		Test.Assert(Math.Abs(row.Size.X - tree.ContentExtent.X) < 0.01f);
	}

	/// A long name bound before its row had a font (a row just made has none until the sheet
	/// reaches it: the editor's hierarchy) measured nothing as it bound; placed with its font, it
	/// is measured again.
	[Test]
	public static void ALongNameBoundBeforeTheRowHadAFontWidensTheRowsOnceItHasOne()
	{
		let service = scope TrueTypeFontService();
		let model = scope TreeModel();
		model.AddNode(TreeModel.Root, "An entity whose name runs far past the edge of a view two hundred and sixty wide");
		let tree = MountTree(model, let root);
		defer root.ReleaseRef(); // before the model the view listens to, and the font it draws in
		Test.Assert(tree.ContentExtent.X <= 260.0f + 0.5f, "no font: no width to its name");
		TextFixtures.Load(service, "DejaVu", TextFixtures.cDejaVuMono);
		tree.Font = service.GetFont("DejaVu", 13.0f); // as the sheet gives it, after the bind
		root.UpdateLayout();
		root.UpdateLayout(); // measured as placed; the rows take it next
		Test.Assert(tree.ContentExtent.X > 400.0f, scope $"{tree.ContentExtent.X}");
		Test.Assert(tree.ScrollRange.X > 140.0f, "scrolled across to see the rest of the name");
	}

	[Test]
	public static void ASheetSetsItsArrowsColumnAndItsIndent()
	{
		let b = scope Bed();
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, "treeview { arrow-size: calc(5px * 2); indent-width: 8px; }");
		styles.ApplyTree(b.Root);
		b.Root.UpdateLayout();
		Test.Assert(Math.Abs(b.Tree.ArrowSize - 10.0f) < 0.01f);
		Test.Assert(Math.Abs(b.Tree.IndentWidth - 8.0f) < 0.01f);
		// Past the 10 px arrow (inside the default 16): the row, not its arrow.
		SceneFixtures.Click(b.D, .(13.0f, 10.0f));
		Test.Assert(!b.Tree.IsItemExpanded(0));
		SceneFixtures.Click(b.D, .(5.0f, 10.0f));
		Test.Assert(b.Tree.IsItemExpanded(0));
	}

	[Test]
	public static void ARowShowsTheModelsIconWithItsClassBetweenTheArrowAndTheText()
	{
		let b = scope Bed();
		b.Model.SetIcon(b.A, "Icons/folder.svg", "cat-rendering");
		b.Tree.IconSize = 14.0f;
		b.Root.UpdateLayout();

		let withIcon = b.Tree.RowForItem(0).Content as TreeRowContent; // A
		let without = b.Tree.RowForItem(1).Content as TreeRowContent; // B
		Test.Assert(withIcon != null);
		Test.Assert(without != null);
		Test.Assert(withIcon.Icon != null);
		Test.Assert(withIcon.Icon.Source == "Icons/folder.svg");
		Test.Assert(withIcon.Icon.HasClass("cat-rendering"));
		Test.Assert(Math.Abs(withIcon.Icon.Size.X - 14.0f) < 0.01f);
		// The icon after the arrow's column, the text after the icon; a row with none starts its
		// text earlier.
		Test.Assert(withIcon.Icon.Position.X >= withIcon.Arrow.Position.X + withIcon.Arrow.Size.X);
		Test.Assert(withIcon.Label.Position.X >= withIcon.Icon.Position.X + 14.0f);
		Test.Assert(without.Label.Position.X < withIcon.Label.Position.X);

		// The icon goes when the model takes it away, and the text moves back.
		b.Model.SetIcon(b.A, "");
		b.Root.UpdateLayout();
		let cleared = b.Tree.RowForItem(0).Content as TreeRowContent;
		Test.Assert((cleared.Icon == null) || !cleared.Icon.Displayed);
		Test.Assert(Math.Abs(cleared.Label.Position.X - without.Label.Position.X) < 0.01f);
	}

	[Test]
	public static void ARowTakesTheClassesTheModelGivesItInPlaceOfThoseItGaveBefore()
	{
		let model = scope StatedTree();
		model.AddNode(TreeModel.Root, "A"); // node 0
		model.AddNode(TreeModel.Root, "B");
		model.AClasses.Set("member  inactive"); // spaced as written
		let tree = MountTree(model, let root);
		defer root.ReleaseRef(); // before the model the view listens to
		var a = tree.RowForItem(0).Content as TreeRowContent;
		let b = tree.RowForItem(1).Content as TreeRowContent;
		Test.Assert(a != null);
		Test.Assert(b != null);
		Test.Assert(a.HasClass("member"));
		Test.Assert(a.HasClass("inactive"));
		Test.Assert(!b.HasClass("member"));

		model.AClasses.Set("inactive");
		model.Changed();
		root.UpdateLayout();
		a = tree.RowForItem(0).Content as TreeRowContent;
		Test.Assert(!a.HasClass("member"));
		Test.Assert(a.HasClass("inactive"));
	}

	[Test]
	public static void SeveralIdsSelectedFromCodeTheFirstCurrentWithoutMultiSelectionOnlyTheFirst()
	{
		let b = scope Bed();
		b.Tree.ExpandItem(0); // A, A1, A2, B
		b.Tree.SelectionMode = .Multi;
		Sedulous.GUI.ItemId[3] ids = .((.)b.A2, (.)b.B, (.)b.A1x); // A1x under closed A1
		b.Tree.SetSelectedIds(ids);
		Test.Assert(b.Tree.SelectionCount == 3);
		Test.Assert(b.Tree.IsItemSelected(2)); // A2
		Test.Assert(b.Tree.IsItemSelected(3)); // B
		Test.Assert(b.Tree.CurrentItem == 2);
		b.Tree.ExpandItem(1); // A1 opens: A1x shows selected
		Test.Assert(b.Tree.IsItemSelected(2));

		b.Tree.SelectionMode = .Single;
		b.Tree.SetSelectedIds(ids);
		Test.Assert(b.Tree.SelectionCount == 1);
		b.Tree.SetSelectedIds(default);
		Test.Assert(b.Tree.SelectionCount == 0);
	}

	[Test]
	public static void MarkupsItemsTakeAnIconAndItsClass()
	{
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let loaded = MarkupFixtures.Load(
			"<TreeView width=\"300\" height=\"300\" row-height=\"20\">\n" +
			"    <TreeItem text=\"Sun\" icon=\"Icons/light.svg\" icon-class=\"cat-rendering\"/>\n" +
			"    <TreeItem text=\"Group\"/>\n" +
			"</TreeView>");
		let tree = loaded as TreeView;
		Test.Assert(tree != null);
		root.AddChild(tree);
		loaded.ReleaseRef(); // the root holds it
		root.UpdateLayout();
		let sun = tree.RowForItem(0).Content as TreeRowContent;
		Test.Assert(sun != null);
		Test.Assert(sun.Icon != null);
		Test.Assert(sun.Icon.Source == "Icons/light.svg");
		Test.Assert(sun.Icon.HasClass("cat-rendering"));
		Test.Assert((tree.RowForItem(1).Content as TreeRowContent).Icon == null);
	}

	[Test]
	public static void ItsModelTakenAwayScrolledOrNotItShowsNothingAndBindsNothingStale()
	{
		let b = scope Bed();
		b.Tree.ExpandItem(0);
		b.Tree.ExpandItem(1);
		b.Tree.Size = .(260.0f, 40.0f); // two rows of five: it scrolls
		b.Root.UpdateLayout();
		b.Tree.ScrollOffset = .(0.0f, 40.0f);
		b.Root.UpdateLayout();
		b.Tree.Model = null;
		b.Root.UpdateLayout();
		Test.Assert(b.Tree.GetItemCount() == 0);
		Test.Assert(b.Tree.VisibleRowCount == 0);
	}
}
