using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// TreeModel + TreeView tests: hierarchical navigation (RowCount(parent)/Index/ParentIndex/
// HasChildren), and a TreeView that flattens visible nodes, expands/collapses (arrow click +
// keyboard), and remaps selection by node id across re-flattening.

/// A tree model's navigation (the view's tests wait for TreeView).
class TreeViewTests
{
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
}
