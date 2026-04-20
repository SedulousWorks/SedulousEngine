namespace Sedulous.UI.Tests;

using System;
using System.Collections;
using Sedulous.UI;

/// Simple test tree: 3 roots, each with 2 children.
/// NodeIds: roots = 0,1,2. Children of 0 = 10,11. Of 1 = 20,21. Of 2 = 30,31.
class TestTreeAdapter : ITreeAdapter
{
	public int32 RootCount => 3;

	public int32 GetChildCount(int32 nodeId)
	{
		if (nodeId == -1) return 3; // root level
		if (nodeId < 3) return 2;   // each root has 2 children
		return 0;                    // leaves
	}

	public int32 GetChildId(int32 parentId, int32 childIndex)
	{
		if (parentId == -1) return (int32)childIndex;        // roots: 0,1,2
		return (int32)(parentId * 10 + 10 + childIndex);      // children: 10,11,20,21,30,31
	}

	public int32 GetDepth(int32 nodeId)
	{
		return (nodeId >= 10) ? 1 : 0;
	}

	public bool HasChildren(int32 nodeId) => nodeId < 3;

	public View CreateView(int32 viewType) => new Label();

	public void BindView(View view, int32 nodeId, int32 depth, bool isExpanded)
	{
		if (let label = view as Label)
		{
			let text = scope String();
			let prefix = scope String();
			for (int i = 0; i < depth; i++) prefix.Append("  ");
			let arrow = isExpanded ? "v " : (HasChildren(nodeId) ? "> " : "  ");
			text.AppendF("{}{}Node {}", prefix, arrow, nodeId);
			label.SetText(text);
		}
	}
}

class TreeAdapterTests
{
	[Test]
	public static void FlattenedTree_InitiallyRootsOnly()
	{
		let tree = scope TestTreeAdapter();
		let flat = scope FlattenedTreeAdapter(tree);

		// Only roots visible initially (nothing expanded).
		Test.Assert(flat.ItemCount == 3);
		Test.Assert(flat.GetNodeId(0) == 0);
		Test.Assert(flat.GetNodeId(1) == 1);
		Test.Assert(flat.GetNodeId(2) == 2);
	}

	[Test]
	public static void FlattenedTree_ExpandAddsChildren()
	{
		let tree = scope TestTreeAdapter();
		let flat = scope FlattenedTreeAdapter(tree);

		flat.Expand(0); // expand root 0

		// Roots + 2 children of root 0 = 5 items.
		Test.Assert(flat.ItemCount == 5);
		Test.Assert(flat.GetNodeId(0) == 0);   // root 0
		Test.Assert(flat.GetNodeId(1) == 10);  // child of 0
		Test.Assert(flat.GetNodeId(2) == 11);  // child of 0
		Test.Assert(flat.GetNodeId(3) == 1);   // root 1
		Test.Assert(flat.GetNodeId(4) == 2);   // root 2
	}

	[Test]
	public static void FlattenedTree_CollapseRemovesChildren()
	{
		let tree = scope TestTreeAdapter();
		let flat = scope FlattenedTreeAdapter(tree);

		flat.Expand(0);
		Test.Assert(flat.ItemCount == 5);

		flat.Collapse(0);
		Test.Assert(flat.ItemCount == 3);
		Test.Assert(flat.GetNodeId(1) == 1); // root 1 is back at position 1
	}

	[Test]
	public static void FlattenedTree_ToggleExpand()
	{
		let tree = scope TestTreeAdapter();
		let flat = scope FlattenedTreeAdapter(tree);

		flat.ToggleExpand(1); // expand
		Test.Assert(flat.IsExpanded(1));
		Test.Assert(flat.ItemCount == 5);

		flat.ToggleExpand(1); // collapse
		Test.Assert(!flat.IsExpanded(1));
		Test.Assert(flat.ItemCount == 3);
	}

	[Test]
	public static void FlattenedTree_DepthTracked()
	{
		let tree = scope TestTreeAdapter();
		let flat = scope FlattenedTreeAdapter(tree);

		flat.Expand(0);

		Test.Assert(flat.GetDepth(0) == 0); // root
		Test.Assert(flat.GetDepth(1) == 1); // child
		Test.Assert(flat.GetDepth(2) == 1); // child
		Test.Assert(flat.GetDepth(3) == 0); // root 1
	}

	[Test]
	public static void FlattenedTree_LeafExpandIsNoop()
	{
		let tree = scope TestTreeAdapter();
		let flat = scope FlattenedTreeAdapter(tree);

		flat.Expand(0);
		flat.Expand(10); // leaf - no children

		// Still 5 items (expand on leaf didn't add anything).
		Test.Assert(flat.ItemCount == 5);
		Test.Assert(!flat.IsExpanded(10));
	}
}
