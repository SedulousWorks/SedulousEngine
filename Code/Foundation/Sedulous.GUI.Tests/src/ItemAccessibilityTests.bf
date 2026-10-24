using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A stand-in for a platform's screen reader: it listens (while Listening), and keeps a copy of
/// every update and announcement it is given.
class AccessRecorder : IAccessibilityBridge
{
	public bool Listening = true;
	public List<AccessTreeUpdate> Updates = new .() ~ DeleteContainerAndItems!(_);
	public List<String> Spoken = new .() ~ DeleteContainerAndItems!(_);

	public bool IsListening => Listening;

	public void Update(AccessTreeUpdate update)
	{
		let copy = new AccessTreeUpdate();
		copy.Set(update);
		Updates.Add(copy);
	}

	public void Announce(StringView text, AnnouncePriority priority)
	{
		Spoken.Add(new String(text));
	}

	/// The node as the bridge last heard it (null: never).
	public AccessNode Last(uint64 id)
	{
		for (int u = Updates.Count - 1; u >= 0; u--)
		{
			let n = Updates[u].Find(id);
			if (n != null)
				return n;
		}
		return null;
	}
}

/// An item view's items in the accessibility tree: each item that has a node (the rows made and a
/// page each side, the current and the selected) is a node of its own, in item order, under an id
/// that follows the item, saying where it stands among them all; the focus is the current item; a
/// screen reader's actions on an item run through its view.
class ItemAccessibilityTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	private static TimeSpan Frame => TimeSpan((int64)((double)TimeSpan.TicksPerSecond / 60.0));

	/// A list of `count` items, ten rows of 20 in view, in a root 400 by 400.
	private class ItemBed
	{
		public StringListModel Model; // it outlives the view that registers with it
		public SceneRoot Root = SceneFixtures.NewScene(400.0f, 400.0f);
		public ListView List = new .();

		public this(int count)
		{
			Model = ItemViewFixtures.Numbered(count);
			List.Size = .(200.0f, 200.0f); // ten rows of 20
			List.RowHeight = 20.0f;
			Root.AddChild(List);
			List.ReleaseRef(); // the tree holds it
			List.Model = Model;
			Root.UpdateLayout();
		}

		public ~this()
		{
			Root.ReleaseRef();
			delete Model;
		}

		public GUIContext Context => Root.Context;

		/// The whole tree now. The caller owns what comes back.
		public AccessTreeUpdate Tree() => Context.BuildAccessTree(Root);

		public static AccessNode ListNode(AccessTreeUpdate tree)
		{
			for (let n in tree.Nodes)
			{
				if (n.Role == .List)
					return n;
			}
			return null;
		}

		public static AccessNode ItemNode(AccessTreeUpdate tree, int32 position)
		{
			for (let n in tree.Nodes)
			{
				if ((n.Role == .ListItem) && (n.PositionInSet == position))
					return n;
			}
			return null;
		}
	}

	[Test]
	public static void AListOfAHundredThousandItemsSendsAFewDozenNodesEachKnowingItsPlaceAmongAll()
	{
		let bed = scope ItemBed(100000);
		let tree = bed.Tree();
		defer delete tree;
		let list = ItemBed.ListNode(tree);
		Test.Assert(list != null);
		Test.Assert(list.Children.Count > 10);
		Test.Assert(list.Children.Count < 60); // the made rows and a page past them, not every item
		let first = ItemBed.ItemNode(tree, 1);
		Test.Assert(first != null);
		Test.Assert(first.Id == list.Children[0]);
		Test.Assert(first.SetSize == 100000);
		Test.Assert(first.Name == "item 0");
		Test.Assert(!first.Has(AccessOffscreen));
		Test.Assert(Near(first.Bounds.Height, 20.0f));
		// Past the rows made, within the page beyond: a node, off screen, its bounds estimated below.
		let below = ItemBed.ItemNode(tree, 15);
		Test.Assert(below != null);
		Test.Assert(below.Has(AccessOffscreen));
		Test.Assert(below.Bounds.Y > first.Bounds.Y + 200.0f);
		// The rows' own labels are no longer the list's children.
		for (let child in list.Children)
			Test.Assert(IsAccessItemId(child));
	}

	[Test]
	public static void TheFocusIsTheCurrentItemEndReachesTheLastOfAHundredThousand()
	{
		let bed = scope ItemBed(100000);
		let recorder = scope AccessRecorder();
		bed.Context.AccessibilityBridge = recorder;
		bed.List.RequestFocus();
		bed.List.SelectedItem = 0;
		bed.Context.Update(Frame);
		Test.Assert(!recorder.Updates.IsEmpty);
		var focused = recorder.Last(recorder.Updates.Back.Focus);
		Test.Assert(focused != null);
		Test.Assert(focused.Role == .ListItem);
		Test.Assert(focused.PositionInSet == 1);

		bed.Root.EventDispatcher.InjectKeyDown((uint32)KeyCode.End);
		bed.Root.UpdateLayout();
		bed.Context.Update(Frame);
		focused = recorder.Last(recorder.Updates.Back.Focus);
		Test.Assert(focused != null);
		Test.Assert(focused.PositionInSet == 100000);
		Test.Assert(focused.Name == "item 99999");
		Test.Assert(focused.Has(AccessSelected));
		Test.Assert(focused.Has(AccessFocused));
		Test.Assert(!focused.Has(AccessOffscreen));
		bed.Context.AccessibilityBridge = null;
	}

	[Test]
	public static void AnItemsIdFollowsItThroughScrollingAwayAndBackAndRowsInsertedAbove()
	{
		let bed = scope ItemBed(1000);
		// Each tree held while its nodes are read (they live in it).
		var tree = bed.Tree();
		Test.Assert(ItemBed.ItemNode(tree, 5) != null);
		let fifth = ItemBed.ItemNode(tree, 5).Id;
		bed.List.ScrollToItem(500);
		bed.Root.UpdateLayout();
		delete tree;
		tree = bed.Tree();
		Test.Assert(ItemBed.ItemNode(tree, 5) == null); // far from the rows made: no node now
		bed.List.ScrollToItem(0);
		bed.Root.UpdateLayout();
		delete tree;
		tree = bed.Tree();
		Test.Assert(ItemBed.ItemNode(tree, 5) != null);
		Test.Assert(ItemBed.ItemNode(tree, 5).Id == fifth);
		bed.Model.InsertItem(0, "new");
		bed.Root.UpdateLayout();
		delete tree;
		tree = bed.Tree();
		let moved = ItemBed.ItemNode(tree, 6);
		Test.Assert(moved != null);
		Test.Assert(moved.Id == fifth); // the same item, a place further down
		Test.Assert(moved.Name == "item 4");

		// Children in item order, whatever order the rows were made in.
		bed.List.ScrollToItem(300);
		bed.Root.UpdateLayout();
		bed.List.ScrollToItem(290);
		bed.Root.UpdateLayout();
		delete tree;
		tree = bed.Tree();
		int32 last = 0;
		for (let child in ItemBed.ListNode(tree).Children)
		{
			let item = tree.Find(child);
			Test.Assert(item != null);
			Test.Assert(item.PositionInSet > last);
			last = item.PositionInSet;
		}
		delete tree;
	}

	[Test]
	public static void AScreenReaderFocusesAnItemOffScreenScrollingToItARemovedItemRefuses()
	{
		let bed = scope ItemBed(1000);
		let tree = bed.Tree();
		defer delete tree;
		let below = ItemBed.ItemNode(tree, 16);
		Test.Assert(below != null);
		Test.Assert(below.Has(AccessOffscreen));
		let focus = scope AccessActionRequest();
		focus.Target = below.Id;
		focus.Action = .Focus;
		Test.Assert(bed.Context.RunAccessAction(focus));
		bed.Root.UpdateLayout();
		Test.Assert(bed.List.IsFocused);
		Test.Assert(bed.List.CurrentItem == 15);
		Test.Assert(bed.List.IsItemSelected(15));
		Test.Assert(bed.List.RowForItem(15) != null); // made: scrolled into view

		let before = bed.Tree();
		defer delete before;
		Test.Assert(ItemBed.ItemNode(before, 3) != null);
		let gone = ItemBed.ItemNode(before, 3).Id;
		bed.Model.RemoveItem(2);
		bed.Model.RemoveItem(2); // "item 2", then "item 3"
		bed.Root.UpdateLayout();
		let stale = scope AccessActionRequest();
		stale.Target = gone;
		stale.Action = .Focus;
		Test.Assert(!bed.Context.RunAccessAction(stale));
	}

	[Test]
	public static void ATreesItemsSayTheirLevelAndPlaceAmongTheirSiblingsAndExpand()
	{
		RegisterGuiElements();
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		let loader = scope MarkupLoader(root.ElementSet);
		let page = loader.LoadFromString(
			"<TreeView width=\"300\" height=\"300\" row-height=\"20\">\n" +
			"    <TreeItem text=\"Code\"><TreeItem text=\"GUI\"/><TreeItem text=\"VG\"/><TreeItem text=\"Fonts\"/></TreeItem>\n" +
			"    <TreeItem text=\"Data\"/>\n" +
			"</TreeView>");
		Test.Assert(page != null);
		defer page.ReleaseRef();
		let view = page as TreeView;
		Test.Assert(view != null);
		root.AddChild(view);
		root.UpdateLayout();
		let gui = root.Context;
		AccessNode Find(AccessTreeUpdate t, StringView name)
		{
			for (let n in t.Nodes)
			{
				if ((n.Role == .TreeItem) && (n.Name == name))
					return n;
			}
			return null;
		}
		var t = gui.BuildAccessTree(root);
		let code = Find(t, "Code");
		Test.Assert(code != null);
		Test.Assert(code.Level == 1);
		Test.Assert(code.PositionInSet == 1);
		Test.Assert(code.SetSize == 2);
		Test.Assert(code.Has(AccessCollapsed));
		Test.Assert(code.Takes(.Expand));
		Test.Assert(Find(t, "VG") == null); // closed: its children are not items

		let expand = scope AccessActionRequest();
		expand.Target = code.Id;
		expand.Action = .Expand;
		Test.Assert(gui.RunAccessAction(expand));
		root.UpdateLayout();
		delete t;
		t = gui.BuildAccessTree(root);
		defer delete t;
		let vg = Find(t, "VG");
		Test.Assert(vg != null);
		Test.Assert(vg.Level == 2);
		Test.Assert(vg.PositionInSet == 2);
		Test.Assert(vg.SetSize == 3);
		Test.Assert(Find(t, "Code").Has(AccessExpanded));
	}

	[Test]
	public static void ATablesRowsSayTheirIndexTheTableItsRowsAndColumns()
	{
		let model = scope TableModel(); // first: it outlives the view that registers with it
		let root = SceneFixtures.NewScene(400.0f, 400.0f);
		defer root.ReleaseRef();
		StringView[3] columns = .("Name", "Age", "City");
		model.SetColumns(columns);
		for (int i = 0; i < 40; ++i)
		{
			Sedulous.GUI.Variant[3] row = .(.((StringView)"Person"), .((int64)(20 + i)), .((StringView)"Town"));
			model.AddRow(row);
		}
		let table = new TableView();
		table.Size = .(300.0f, 200.0f);
		table.RowHeight = 24.0f;
		root.AddChild(table);
		table.ReleaseRef();
		table.Model = model;
		root.UpdateLayout();
		let t = root.Context.BuildAccessTree(root);
		defer delete t;
		AccessNode tableNode = null;
		AccessNode third = null;
		for (let n in t.Nodes)
		{
			if (n.Role == .Table)
				tableNode = n;
			if ((n.Role == .Row) && (n.RowIndex == 3))
				third = n;
		}
		Test.Assert(tableNode != null);
		Test.Assert(tableNode.RowCount == 40);
		Test.Assert(tableNode.ColumnCount == 3);
		Test.Assert(third != null);
		Test.Assert(third.SetSize == 40);
	}
}
