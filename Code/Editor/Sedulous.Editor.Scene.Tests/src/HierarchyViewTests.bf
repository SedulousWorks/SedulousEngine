using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene.Tests;

/// The hierarchy view's snapshot: collapse state and selection across rebuilds, and the
/// selection model driving the scene selection.
class HierarchyViewTests
{
	[Test]
	public static void CollapseStateSurvivesSnapshotRebuilds()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let hierarchy = new SceneHierarchyView(edit);
		defer hierarchy.ReleaseRef();

		let parent = edit.CreateEntity("Parent");
		edit.CreateEntity("Child", parent);
		edit.CreateEntity("Sibling");
		hierarchy.Refresh();

		var flat = hierarchy.Tree.InternalTreeView.FlatAdapter;
		Test.Assert(flat != null);
		Test.Assert(flat.ItemCount == 3); // Parent (expanded), Child, Sibling

		// Collapse Parent (pre-order node 0), then force a rebuild by editing the scene.
		flat.Collapse(0);
		Test.Assert(flat.ItemCount == 2);
		edit.CreateEntity("Another");
		hierarchy.Refresh();

		// SetAdapter recreated the flat view; Parent STAYS collapsed, the new root shows.
		flat = hierarchy.Tree.InternalTreeView.FlatAdapter;
		Test.Assert(flat.ItemCount == 3); // Parent (collapsed), Sibling, Another
		Test.Assert(!flat.IsExpanded(0));

		// Re-expanding sticks across the next rebuild too.
		flat.Expand(0);
		edit.CreateEntity("YetAnother");
		hierarchy.Refresh();
		flat = hierarchy.Tree.InternalTreeView.FlatAdapter;
		Test.Assert(flat.ItemCount == 5);
		Test.Assert(flat.IsExpanded(0));
		Test.Assert(hierarchy.NodeCount == 5);
	}

	[Test]
	public static void SelectionSurvivesSnapshotRebuilds()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let hierarchy = new SceneHierarchyView(edit);
		defer hierarchy.ReleaseRef();

		let a = edit.CreateEntity("A");
		let b = edit.CreateEntity("B");
		let c = edit.CreateEntity("C");
		hierarchy.Refresh();

		let list = hierarchy.Tree.InternalTreeView.InternalListView;

		edit.EntitySelection.Set(b);
		Test.Assert(list.Selection.FirstSelected() == 1); // rows: A=0, B=1, C=2

		// A rename of another entity bumps the revision.
		edit.RenameEntity(a, "A2");
		hierarchy.Refresh();
		Test.Assert(edit.EntitySelection.Contains(b));
		Test.Assert(list.Selection.FirstSelected() == 1);

		edit.SetEntityActive(c, false);
		hierarchy.Refresh();
		Test.Assert(list.Selection.FirstSelected() == 1);

		// Destroying ANOTHER entity: B stays selected at its shifted position.
		edit.DestroyEntity(a);
		hierarchy.Refresh();
		Test.Assert(edit.EntitySelection.Contains(b));
		Test.Assert(list.Selection.FirstSelected() == 0); // rows: B=0, C=1

		// Reparent B under C: B stays selected at its new position.
		edit.ReparentEntity(b, c);
		hierarchy.Refresh();
		Test.Assert(edit.EntitySelection.Contains(b));
		Test.Assert(list.Selection.FirstSelected() == 1); // rows: C=0, B (child)=1

		// Undo puts B back in its exact old slot, before C, rather than at the end.
		commands.Undo();
		hierarchy.Refresh();
		Test.Assert(edit.EntitySelection.Contains(b));
		Test.Assert(list.Selection.FirstSelected() == 0);
	}

	[Test]
	public static void ASelectionModelChangeSyncsTheSceneSelection()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let hierarchy = new SceneHierarchyView(edit);
		defer hierarchy.ReleaseRef();

		let a = edit.CreateEntity("A");
		let b = edit.CreateEntity("B");
		edit.CreateEntity("C");
		hierarchy.Refresh();

		// Arrow key navigation moves the selection model via Select, not OnItemClick, and the
		// scene selection, which drives the inspector, must follow. Rows: A=0, B=1, C=2.
		let listSel = hierarchy.Tree.InternalTreeView.InternalListView.Selection;
		listSel.Select(1);
		Test.Assert(edit.EntitySelection.Contains(b));
		listSel.Select(0);
		Test.Assert(edit.EntitySelection.Contains(a));
	}

	[Test]
	public static void TheFilterMatchesCaseInsensitivelyAndKeepsAMatchingChildsPath()
	{
		Test.Assert(SceneHierarchyView.MatchesFilter("Sun Light", "light"));
		Test.Assert(SceneHierarchyView.MatchesFilter("Sun Light", ""));
		Test.Assert(!SceneHierarchyView.MatchesFilter("Sun", "light"));
		Test.Assert(!SceneHierarchyView.MatchesFilter("Su", "sun"));
	}
}
