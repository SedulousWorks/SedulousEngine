namespace Sedulous.UI.Tests;

using System;
using System.Collections;

class TreeViewTests
{
	[Test]
	public static void TreeView_SetAdapter_ShowsRootItems()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root, 200, 300);

		let adapter = scope SimpleTreeAdapter();
		let tv = new TreeView();
		tv.SetAdapter(adapter);
		root.AddView(tv);
		TestSetup.Layout(ctx, root);

		Test.Assert(tv.FlatAdapter != null);
		Test.Assert(tv.FlatAdapter.ItemCount == 3); // 3 roots
	}

	[Test]
	public static void TreeView_ToggleExpand_ChangesCount()
	{
		let adapter = scope SimpleTreeAdapter();
		let tv = scope TreeView();
		tv.SetAdapter(adapter);

		Test.Assert(tv.FlatAdapter.ItemCount == 3);
		tv.ToggleExpand(0); // expand root 0
		Test.Assert(tv.FlatAdapter.ItemCount == 5); // 3 + 2 children
		tv.ToggleExpand(0); // collapse
		Test.Assert(tv.FlatAdapter.ItemCount == 3);
	}

	[Test]
	public static void TreeView_ExpandNode_AddsChildren()
	{
		let adapter = scope SimpleTreeAdapter();
		let tv = scope TreeView();
		tv.SetAdapter(adapter);

		tv.FlatAdapter.Expand(1); // root 1 has 1 child
		Test.Assert(tv.FlatAdapter.ItemCount == 4);
		Test.Assert(tv.FlatAdapter.GetNodeId(2) == 20); // child of root 1
	}

	[Test]
	public static void TreeView_CollapseNode_RemovesChildren()
	{
		let adapter = scope SimpleTreeAdapter();
		let tv = scope TreeView();
		tv.SetAdapter(adapter);

		tv.FlatAdapter.Expand(0);
		tv.FlatAdapter.Expand(1);
		Test.Assert(tv.FlatAdapter.ItemCount == 6);

		tv.FlatAdapter.Collapse(0);
		Test.Assert(tv.FlatAdapter.ItemCount == 4);
	}

	[Test]
	public static void TreeView_Selection()
	{
		let adapter = scope SimpleTreeAdapter();
		let tv = scope TreeView();
		tv.SetAdapter(adapter);

		tv.Selection.Select(0);
		Test.Assert(tv.Selection.IsSelected(0));
		Test.Assert(tv.Selection.FirstSelected == 0);
	}

	[Test]
	public static void TreeView_HierarchicalState_CaptureRestore()
	{
		let adapter = scope SimpleTreeAdapter();
		let tv = scope TreeView();
		tv.SetAdapter(adapter);

		// Set up some state.
		tv.FlatAdapter.Expand(0);
		tv.FlatAdapter.Expand(1);
		tv.Selection.Select(2);

		// Capture.
		let state = scope HierarchicalState();
		state.CaptureState(tv);

		// Clear state.
		tv.FlatAdapter.Collapse(0);
		tv.FlatAdapter.Collapse(1);
		tv.Selection.ClearSelection();
		Test.Assert(tv.FlatAdapter.ItemCount == 3);

		// Restore.
		state.ApplyState(tv);
		Test.Assert(tv.FlatAdapter.IsExpanded(0));
		Test.Assert(tv.FlatAdapter.IsExpanded(1));
		Test.Assert(tv.FlatAdapter.ItemCount == 6);
		Test.Assert(tv.Selection.IsSelected(2));
	}
}
