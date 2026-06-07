namespace Sedulous.GUI.Tests;

using System;
using System.Collections;

/// Test adapter for data tests.
class SimpleListAdapter : ListAdapterBase
{
	public int32 Count;
	public this(int32 count) { Count = count; }
	public override int32 ItemCount => Count;
	public override View CreateView(int32 viewType) => new TestView(100, 30);
	public override void BindView(View view, int32 position) { }
}

/// Test tree adapter: 3 roots, root 0 has 2 children, root 1 has 1 child, root 2 has 0.
/// Node IDs: roots = 0,1,2; children of 0 = 10,11; children of 1 = 20.
class SimpleTreeAdapter : ITreeAdapter
{
	public int32 RootCount => 3;

	public int32 GetChildCount(int32 nodeId)
	{
		if (nodeId == -1) return 3;
		if (nodeId == 0) return 2;
		if (nodeId == 1) return 1;
		return 0;
	}

	public int32 GetChildId(int32 parentId, int32 childIndex)
	{
		if (parentId == -1) return childIndex; // roots: 0, 1, 2
		if (parentId == 0) return 10 + childIndex; // 10, 11
		if (parentId == 1) return 20 + childIndex; // 20
		return -1;
	}

	public int32 GetDepth(int32 nodeId)
	{
		if (nodeId >= 10) return 1;
		return 0;
	}

	public bool HasChildren(int32 nodeId)
	{
		return nodeId == 0 || nodeId == 1;
	}

	public View CreateView(int32 viewType) => new TestView(100, 30);
	public void BindView(View view, int32 nodeId, int32 depth, bool isExpanded) { }
}

class DataTests
{
	// === ViewRecycler ===

	[Test]
	public static void ViewRecycler_AcquireReturnsNull_WhenEmpty()
	{
		let recycler = scope ViewRecycler();
		Test.Assert(recycler.Acquire(0) == null);
	}

	[Test]
	public static void ViewRecycler_RecycleAndAcquire_ReusesView()
	{
		let recycler = scope ViewRecycler();
		let view = new TestView();
		recycler.Recycle(view, 0);
		let reused = recycler.Acquire(0);
		Test.Assert(reused === view);
		Test.Assert(recycler.ReusedCount == 1);
		Test.Assert(recycler.RecycledCount == 1);
		delete view;
	}

	[Test]
	public static void ViewRecycler_GetOrCreate_CreatesWhenEmpty()
	{
		let recycler = scope ViewRecycler();
		let adapter = scope SimpleListAdapter(5);
		let view = recycler.GetOrCreate(adapter, 0);
		Test.Assert(view != null);
		Test.Assert(recycler.CreatedCount == 1);
		delete view;
	}

	[Test]
	public static void ViewRecycler_DiagnosticCounters()
	{
		let recycler = scope ViewRecycler();
		let adapter = scope SimpleListAdapter(5);
		let v1 = recycler.GetOrCreate(adapter, 0);
		Test.Assert(recycler.CreatedCount == 1);
		recycler.Recycle(v1, 0);
		Test.Assert(recycler.RecycledCount == 1);
		let v2 = recycler.GetOrCreate(adapter, 1);
		Test.Assert(recycler.ReusedCount == 1);
		Test.Assert(v2 === v1);
		delete v2;
	}

	// === SelectionModel ===

	[Test]
	public static void SelectionModel_SingleMode_ReplacesSelection()
	{
		let sel = scope SelectionModel();
		sel.Mode = .Single;
		sel.Select(0);
		sel.Select(1);
		Test.Assert(!sel.IsSelected(0));
		Test.Assert(sel.IsSelected(1));
		Test.Assert(sel.SelectedCount == 1);
	}

	[Test]
	public static void SelectionModel_MultipleMode_Accumulates()
	{
		let sel = scope SelectionModel();
		sel.Mode = .Multiple;
		sel.Select(0);
		sel.Select(1);
		sel.Select(2);
		Test.Assert(sel.IsSelected(0));
		Test.Assert(sel.IsSelected(1));
		Test.Assert(sel.IsSelected(2));
		Test.Assert(sel.SelectedCount == 3);
	}

	[Test]
	public static void SelectionModel_Toggle()
	{
		let sel = scope SelectionModel();
		sel.Mode = .Multiple;
		sel.Select(0);
		sel.Toggle(0);
		Test.Assert(!sel.IsSelected(0));
		sel.Toggle(0);
		Test.Assert(sel.IsSelected(0));
	}

	[Test]
	public static void SelectionModel_SelectRange()
	{
		let sel = scope SelectionModel();
		sel.Mode = .Multiple;
		sel.SelectRange(2, 5);
		Test.Assert(sel.SelectedCount == 4);
		Test.Assert(sel.IsSelected(2));
		Test.Assert(sel.IsSelected(3));
		Test.Assert(sel.IsSelected(4));
		Test.Assert(sel.IsSelected(5));
	}

	[Test]
	public static void SelectionModel_ClearSelection()
	{
		let sel = scope SelectionModel();
		sel.Mode = .Multiple;
		sel.Select(0);
		sel.Select(1);
		sel.ClearSelection();
		Test.Assert(sel.SelectedCount == 0);
	}

	[Test]
	public static void SelectionModel_ShiftIndices_Insert()
	{
		let sel = scope SelectionModel();
		sel.Mode = .Multiple;
		sel.Select(2);
		sel.Select(4);
		sel.ShiftIndices(3, 1); // insert at 3
		Test.Assert(sel.IsSelected(2)); // unchanged
		Test.Assert(sel.IsSelected(5)); // shifted from 4
	}

	[Test]
	public static void SelectionModel_NoneMode_Ignores()
	{
		let sel = scope SelectionModel();
		sel.Mode = .None;
		sel.Select(0);
		Test.Assert(sel.SelectedCount == 0);
	}

	// === FlattenedTreeAdapter ===

	[Test]
	public static void FlattenedTreeAdapter_InitialCount_IsRootCount()
	{
		let tree = scope SimpleTreeAdapter();
		let flat = scope FlattenedTreeAdapter(tree);
		Test.Assert(flat.ItemCount == 3); // 3 roots, none expanded
	}

	[Test]
	public static void FlattenedTreeAdapter_ExpandRoot_IncludesChildren()
	{
		let tree = scope SimpleTreeAdapter();
		let flat = scope FlattenedTreeAdapter(tree);
		flat.Expand(0); // root 0 has 2 children
		Test.Assert(flat.ItemCount == 5); // 3 roots + 2 children
	}

	[Test]
	public static void FlattenedTreeAdapter_CollapseRoot_RemovesChildren()
	{
		let tree = scope SimpleTreeAdapter();
		let flat = scope FlattenedTreeAdapter(tree);
		flat.Expand(0);
		Test.Assert(flat.ItemCount == 5);
		flat.Collapse(0);
		Test.Assert(flat.ItemCount == 3);
	}

	[Test]
	public static void FlattenedTreeAdapter_ToggleExpand()
	{
		let tree = scope SimpleTreeAdapter();
		let flat = scope FlattenedTreeAdapter(tree);
		flat.ToggleExpand(0);
		Test.Assert(flat.IsExpanded(0));
		Test.Assert(flat.ItemCount == 5);
		flat.ToggleExpand(0);
		Test.Assert(!flat.IsExpanded(0));
		Test.Assert(flat.ItemCount == 3);
	}

	[Test]
	public static void FlattenedTreeAdapter_GetNodeId_GetDepth()
	{
		let tree = scope SimpleTreeAdapter();
		let flat = scope FlattenedTreeAdapter(tree);
		flat.Expand(0);
		// Visible: 0, 10, 11, 1, 2
		Test.Assert(flat.GetNodeId(0) == 0);
		Test.Assert(flat.GetNodeId(1) == 10);
		Test.Assert(flat.GetNodeId(2) == 11);
		Test.Assert(flat.GetNodeId(3) == 1);
		Test.Assert(flat.GetDepth(0) == 0);
		Test.Assert(flat.GetDepth(1) == 1);
		Test.Assert(flat.GetDepth(2) == 1);
		Test.Assert(flat.GetDepth(3) == 0);
	}

	[Test]
	public static void FlattenedTreeAdapter_GetSetExpandedNodes()
	{
		let tree = scope SimpleTreeAdapter();
		let flat = scope FlattenedTreeAdapter(tree);
		flat.Expand(0);
		flat.Expand(1);

		let saved = scope HashSet<int32>();
		flat.GetExpandedNodes(saved);
		Test.Assert(saved.Contains(0));
		Test.Assert(saved.Contains(1));

		flat.Collapse(0);
		flat.Collapse(1);
		Test.Assert(flat.ItemCount == 3);

		flat.SetExpandedNodes(saved);
		Test.Assert(flat.IsExpanded(0));
		Test.Assert(flat.IsExpanded(1));
		Test.Assert(flat.ItemCount == 6); // 3 roots + 2 children of 0 + 1 child of 1
	}
}
