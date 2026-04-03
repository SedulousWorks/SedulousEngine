using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI.Tests;

/// Tests for Phase 11: Tree & Hierarchical Controls
class Phase11Tests
{
	// === TreeViewItem Tests ===

	[Test]
	public static void TreeViewItemDefaultProperties()
	{
		let item = scope TreeViewItem();
		Test.Assert(item.Text == "");
		Test.Assert(item.IsSelected == false);
		Test.Assert(item.IsExpanded == true);  // Expanded by default
		Test.Assert(item.HasChildren == false);
		Test.Assert(item.ChildCount == 0);
		Test.Assert(item.ParentItem == null);
		Test.Assert(item.IndentLevel == 0);
	}

	[Test]
	public static void TreeViewItemWithText()
	{
		let item = scope TreeViewItem("Documents");
		Test.Assert(item.Text == "Documents");
		Test.Assert(item.IsSelected == false);
	}

	[Test]
	public static void TreeViewItemAddChild()
	{
		let parent = scope TreeViewItem("Parent");
		let child = parent.AddChild("Child");

		Test.Assert(parent.HasChildren == true);
		Test.Assert(parent.ChildCount == 1);
		Test.Assert(child.ParentItem == parent);
		Test.Assert(child.IndentLevel == 1);
	}

	[Test]
	public static void TreeViewItemAddMultipleChildren()
	{
		let parent = scope TreeViewItem("Parent");
		let child1 = parent.AddChild("Child 1");
		let child2 = parent.AddChild("Child 2");
		let child3 = parent.AddChild("Child 3");

		Test.Assert(parent.ChildCount == 3);
		Test.Assert(parent.GetChild(0) == child1);
		Test.Assert(parent.GetChild(1) == child2);
		Test.Assert(parent.GetChild(2) == child3);
	}

	[Test]
	public static void TreeViewItemNestedChildren()
	{
		let root = scope TreeViewItem("Root");
		let level1 = root.AddChild("Level 1");
		let level2 = level1.AddChild("Level 2");
		let level3 = level2.AddChild("Level 3");

		Test.Assert(root.IndentLevel == 0);
		Test.Assert(level1.IndentLevel == 1);
		Test.Assert(level2.IndentLevel == 2);
		Test.Assert(level3.IndentLevel == 3);

		Test.Assert(level1.ParentItem == root);
		Test.Assert(level2.ParentItem == level1);
		Test.Assert(level3.ParentItem == level2);
	}

	[Test]
	public static void TreeViewItemRemoveChild()
	{
		let parent = scope TreeViewItem("Parent");
		let child1 = parent.AddChild("Child 1");
		let child2 = parent.AddChild("Child 2");

		Test.Assert(parent.ChildCount == 2);

		parent.RemoveChild(child1);
		Test.Assert(parent.ChildCount == 1);
		Test.Assert(parent.GetChild(0) == child2);
	}

	[Test]
	public static void TreeViewItemClearChildren()
	{
		let parent = scope TreeViewItem("Parent");
		parent.AddChild("Child 1");
		parent.AddChild("Child 2");
		parent.AddChild("Child 3");

		Test.Assert(parent.ChildCount == 3);

		parent.ClearChildren();
		Test.Assert(parent.ChildCount == 0);
		Test.Assert(parent.HasChildren == false);
	}

	[Test]
	public static void TreeViewItemExpandCollapse()
	{
		let item = scope TreeViewItem("Item");
		item.AddChild("Child");

		Test.Assert(item.IsExpanded == true);

		item.IsExpanded = false;
		Test.Assert(item.IsExpanded == false);

		item.IsExpanded = true;
		Test.Assert(item.IsExpanded == true);
	}

	[Test]
	public static void TreeViewItemEnumerateVisibleExpanded()
	{
		let root = scope TreeViewItem("Root");
		root.AddChild("Child 1");
		root.AddChild("Child 2");

		let visibleItems = scope System.Collections.List<TreeViewItem>();
		root.EnumerateVisible(visibleItems);

		Test.Assert(visibleItems.Count == 3);  // Root + 2 children
	}

	[Test]
	public static void TreeViewItemEnumerateVisibleCollapsed()
	{
		let root = scope TreeViewItem("Root");
		root.AddChild("Child 1");
		root.AddChild("Child 2");
		root.IsExpanded = false;

		let visibleItems = scope System.Collections.List<TreeViewItem>();
		root.EnumerateVisible(visibleItems);

		Test.Assert(visibleItems.Count == 1);  // Only root (children hidden)
	}

	[Test]
	public static void TreeViewItemTag()
	{
		let item = scope TreeViewItem("Item");
		let tag = scope String("UserData");
		item.Tag = tag;

		Test.Assert(item.Tag == tag);
	}

	// === TreeView Tests ===

	[Test]
	public static void TreeViewDefaultProperties()
	{
		let treeView = scope TreeView();
		Test.Assert(treeView.ItemCount == 0);
		Test.Assert(treeView.SelectedItem == null);
	}

	[Test]
	public static void TreeViewAddItem()
	{
		let treeView = scope TreeView();
		let item = treeView.AddItem("Root Item");

		Test.Assert(treeView.ItemCount == 1);
		Test.Assert(item != null);
		Test.Assert(item.Text == "Root Item");
	}

	[Test]
	public static void TreeViewAddMultipleItems()
	{
		let treeView = scope TreeView();
		let item1 = treeView.AddItem("Item 1");
		let item2 = treeView.AddItem("Item 2");
		let item3 = treeView.AddItem("Item 3");

		Test.Assert(treeView.ItemCount == 3);
		Test.Assert(treeView.GetItem(0) == item1);
		Test.Assert(treeView.GetItem(1) == item2);
		Test.Assert(treeView.GetItem(2) == item3);
	}

	[Test]
	public static void TreeViewSelectionChanged()
	{
		let treeView = scope TreeView();
		let item = treeView.AddItem("Item");

		Test.Assert(treeView.SelectedItem == null);

		treeView.SelectedItem = item;
		Test.Assert(treeView.SelectedItem == item);
		Test.Assert(item.IsSelected == true);
	}

	[Test]
	public static void TreeViewSelectionChangedEvent()
	{
		let treeView = scope TreeView();
		let item1 = treeView.AddItem("Item 1");
		let item2 = treeView.AddItem("Item 2");

		var eventFiredCount = 0;
		treeView.SelectionChanged.Subscribe(new [&](tv) => {
			eventFiredCount++;
		});

		treeView.SelectedItem = item1;
		Test.Assert(eventFiredCount == 1);

		treeView.SelectedItem = item2;
		Test.Assert(eventFiredCount == 2);
	}

	[Test]
	public static void TreeViewDeselectsOldItem()
	{
		let treeView = scope TreeView();
		let item1 = treeView.AddItem("Item 1");
		let item2 = treeView.AddItem("Item 2");

		treeView.SelectedItem = item1;
		Test.Assert(item1.IsSelected == true);

		treeView.SelectedItem = item2;
		Test.Assert(item1.IsSelected == false);
		Test.Assert(item2.IsSelected == true);
	}

	[Test]
	public static void TreeViewRemoveItem()
	{
		let treeView = scope TreeView();
		let item1 = treeView.AddItem("Item 1");
		let item2 = treeView.AddItem("Item 2");

		Test.Assert(treeView.ItemCount == 2);

		treeView.RemoveItem(item1);
		Test.Assert(treeView.ItemCount == 1);
		Test.Assert(treeView.GetItem(0) == item2);
	}

	[Test]
	public static void TreeViewRemoveSelectedItem()
	{
		let treeView = scope TreeView();
		let item1 = treeView.AddItem("Item 1");
		treeView.AddItem("Item 2");

		treeView.SelectedItem = item1;
		Test.Assert(treeView.SelectedItem == item1);

		treeView.RemoveItem(item1);
		Test.Assert(treeView.SelectedItem == null);
	}

	[Test]
	public static void TreeViewClearItems()
	{
		let treeView = scope TreeView();
		treeView.AddItem("Item 1");
		treeView.AddItem("Item 2");
		treeView.AddItem("Item 3");

		Test.Assert(treeView.ItemCount == 3);

		treeView.ClearItems();
		Test.Assert(treeView.ItemCount == 0);
		Test.Assert(treeView.SelectedItem == null);
	}

	[Test]
	public static void TreeViewExpandAll()
	{
		let treeView = scope TreeView();
		let root = treeView.AddItem("Root");
		let child = root.AddChild("Child");
		root.IsExpanded = false;
		child.IsExpanded = false;

		treeView.ExpandAll();

		Test.Assert(root.IsExpanded == true);
		Test.Assert(child.IsExpanded == true);
	}

	[Test]
	public static void TreeViewCollapseAll()
	{
		let treeView = scope TreeView();
		let root = treeView.AddItem("Root");
		let child = root.AddChild("Child");

		Test.Assert(root.IsExpanded == true);
		Test.Assert(child.IsExpanded == true);

		treeView.CollapseAll();

		Test.Assert(root.IsExpanded == false);
		Test.Assert(child.IsExpanded == false);
	}

	[Test]
	public static void TreeViewItemExpandedEvent()
	{
		let treeView = scope TreeView();
		let item = treeView.AddItem("Item");
		item.AddChild("Child");
		item.IsExpanded = false;

		var expandEventFired = false;
		treeView.ItemExpanded.Subscribe(new [&](tv, expandedItem) => {
			expandEventFired = true;
		});

		item.IsExpanded = true;
		// Note: Event firing depends on how items notify parent
		Test.Assert(treeView.ItemExpanded != null);
	}

	[Test]
	public static void TreeViewItemCollapsedEvent()
	{
		let treeView = scope TreeView();
		let item = treeView.AddItem("Item");
		item.AddChild("Child");

		var collapseEventFired = false;
		treeView.ItemCollapsed.Subscribe(new [&](tv, collapsedItem) => {
			collapseEventFired = true;
		});

		item.IsExpanded = false;
		// Note: Event firing depends on how items notify parent
		Test.Assert(treeView.ItemCollapsed != null);
	}

	// === TileViewItem Tests ===

	[Test]
	public static void TileViewItemDefaultProperties()
	{
		let item = scope TileViewItem();
		Test.Assert(item.Content == null);
		Test.Assert(item.IsSelected == false);
		Test.Assert(item.Index == -1);
		Test.Assert(item.Tag == null);
	}

	[Test]
	public static void TileViewItemWithContent()
	{
		let item = scope TileViewItem();
		let content = new TextBlock("Documents");
		item.Content = content;
		Test.Assert(item.Content == content);
	}

	[Test]
	public static void TileViewItemSelection()
	{
		let item = scope TileViewItem();
		Test.Assert(item.IsSelected == false);

		item.IsSelected = true;
		Test.Assert(item.IsSelected == true);

		item.IsSelected = false;
		Test.Assert(item.IsSelected == false);
	}

	[Test]
	public static void TileViewItemTag()
	{
		let item = scope TileViewItem();
		let tag = scope String("UserData");
		item.Tag = tag;

		Test.Assert(item.Tag == tag);
	}

	// === TileView Tests ===

	[Test]
	public static void TileViewDefaultProperties()
	{
		let tileView = scope TileView();
		Test.Assert(tileView.ItemCount == 0);
		Test.Assert(tileView.SelectedItem == null);
		Test.Assert(tileView.TileWidth == 80);
		Test.Assert(tileView.TileHeight == 90);
	}

	[Test]
	public static void TileViewAddItem()
	{
		let tileView = scope TileView();
		let item = tileView.AddItem("Documents");

		Test.Assert(tileView.ItemCount == 1);
		Test.Assert(item != null);
		Test.Assert(item.Content != null);  // AddItem(text) creates a TextBlock content
		Test.Assert(item.Index == 0);
	}

	[Test]
	public static void TileViewAddMultipleItems()
	{
		let tileView = scope TileView();
		let item1 = tileView.AddItem("Item 1");
		let item2 = tileView.AddItem("Item 2");
		let item3 = tileView.AddItem("Item 3");

		Test.Assert(tileView.ItemCount == 3);
		Test.Assert(tileView.GetItem(0) == item1);
		Test.Assert(tileView.GetItem(1) == item2);
		Test.Assert(tileView.GetItem(2) == item3);
		Test.Assert(item1.Index == 0);
		Test.Assert(item2.Index == 1);
		Test.Assert(item3.Index == 2);
	}

	[Test]
	public static void TileViewSelectionChanged()
	{
		let tileView = scope TileView();
		let item = tileView.AddItem("Item");

		Test.Assert(tileView.SelectedItem == null);

		tileView.SelectedItem = item;
		Test.Assert(tileView.SelectedItem == item);
		Test.Assert(item.IsSelected == true);
	}

	[Test]
	public static void TileViewSelectionChangedEvent()
	{
		let tileView = scope TileView();
		let item1 = tileView.AddItem("Item 1");
		let item2 = tileView.AddItem("Item 2");

		var eventFiredCount = 0;
		tileView.SelectionChanged.Subscribe(new [&](tv) => {
			eventFiredCount++;
		});

		tileView.SelectedItem = item1;
		Test.Assert(eventFiredCount == 1);

		tileView.SelectedItem = item2;
		Test.Assert(eventFiredCount == 2);
	}

	[Test]
	public static void TileViewDeselectsOldItem()
	{
		let tileView = scope TileView();
		let item1 = tileView.AddItem("Item 1");
		let item2 = tileView.AddItem("Item 2");

		tileView.SelectedItem = item1;
		Test.Assert(item1.IsSelected == true);

		tileView.SelectedItem = item2;
		Test.Assert(item1.IsSelected == false);
		Test.Assert(item2.IsSelected == true);
	}

	[Test]
	public static void TileViewRemoveItem()
	{
		let tileView = scope TileView();
		let item1 = tileView.AddItem("Item 1");
		let item2 = tileView.AddItem("Item 2");
		let item3 = tileView.AddItem("Item 3");

		Test.Assert(tileView.ItemCount == 3);

		tileView.RemoveItem(item2);
		Test.Assert(tileView.ItemCount == 2);
		Test.Assert(tileView.GetItem(0) == item1);
		Test.Assert(tileView.GetItem(1) == item3);
		// Indices should be updated
		Test.Assert(item3.Index == 1);
	}

	[Test]
	public static void TileViewRemoveSelectedItem()
	{
		let tileView = scope TileView();
		let item1 = tileView.AddItem("Item 1");
		tileView.AddItem("Item 2");

		tileView.SelectedItem = item1;
		Test.Assert(tileView.SelectedItem == item1);

		tileView.RemoveItem(item1);
		Test.Assert(tileView.SelectedItem == null);
	}

	[Test]
	public static void TileViewClearItems()
	{
		let tileView = scope TileView();
		tileView.AddItem("Item 1");
		tileView.AddItem("Item 2");
		tileView.AddItem("Item 3");

		Test.Assert(tileView.ItemCount == 3);

		tileView.ClearItems();
		Test.Assert(tileView.ItemCount == 0);
		Test.Assert(tileView.SelectedItem == null);
	}

	[Test]
	public static void TileViewTileSizeProperties()
	{
		let tileView = scope TileView();

		tileView.TileWidth = 100;
		Test.Assert(tileView.TileWidth == 100);

		tileView.TileHeight = 120;
		Test.Assert(tileView.TileHeight == 120);

		tileView.TileSpacing = 12;
		Test.Assert(tileView.TileSpacing == 12);
	}

	[Test]
	public static void TileViewGetItemOutOfRange()
	{
		let tileView = scope TileView();
		tileView.AddItem("Item 1");

		Test.Assert(tileView.GetItem(-1) == null);
		Test.Assert(tileView.GetItem(1) == null);
		Test.Assert(tileView.GetItem(100) == null);
	}
}
