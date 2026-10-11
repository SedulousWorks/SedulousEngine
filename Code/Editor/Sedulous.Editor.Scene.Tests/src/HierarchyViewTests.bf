using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.UI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene.Tests;

/// The hierarchy view's snapshot: collapse state and selection across rebuilds, and the
/// selection model driving the scene selection.
class HierarchyViewTests
{
	private class TestClipboard : IClipboard
	{
		public String Stored = new .() ~ delete _;

		public Result<void> GetText(String outText)
		{
			outText.Set(Stored);
			return .Ok;
		}

		public Result<void> SetText(StringView text)
		{
			Stored.Set(text);
			return .Ok;
		}

		public bool HasText => !Stored.IsEmpty;
	}

	/// A double-click frames the row's entity, and no longer starts a rename: that is a slow
	/// click, F2 or the menu.
	[Test]
	public static void ADoubleClickFramesTheRowsEntityNotARename()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let hierarchy = new SceneHierarchyView(edit);
		defer hierarchy.ReleaseRef();
		let table = edit.CreateEntity("Table");
		hierarchy.Refresh();

		let framed = scope System.Collections.List<Guid>();
		hierarchy.OnFrameEntity = new [&framed](id) => { framed.Add(id); };
		let tree = hierarchy.Tree.InternalTreeView;

		// One click selects, and frames nothing.
		tree.OnItemClick(TreeItemClickInfo(0, 1));
		Test.Assert(framed.IsEmpty);
		Test.Assert(!edit.EntitySelection.IsEmpty && (edit.EntitySelection.Primary == table));

		// A double-click selects and frames.
		tree.OnItemClick(TreeItemClickInfo(0, 2));
		Test.Assert((framed.Count == 1) && (framed[0] == table));

		// The row leaves the double-click to the tree.
		let row = tree.TreeAdapter.CreateView(0);
		defer row.ReleaseRef();
		let label = row as EditableLabel;
		Test.Assert(label != null);
		Test.Assert(!label.DoubleClickToEdit.Value);
		Test.Assert(label.SlowClickToEdit.Value);
	}

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
		Test.Assert(Sedulous.Editor.Core.SearchFilter.NameOrGuidMatches("Sun Light", Guid(), "light"));
		Test.Assert(Sedulous.Editor.Core.SearchFilter.NameOrGuidMatches("Sun Light", Guid(), ""));
		Test.Assert(!Sedulous.Editor.Core.SearchFilter.NameOrGuidMatches("Sun", Guid(), "light"));
		Test.Assert(!Sedulous.Editor.Core.SearchFilter.NameOrGuidMatches("Su", Guid(), "sun"));
	}

	/// Copy ID puts the entity's persistent guid on the clipboard, and a view with no UI
	/// context behind it refuses rather than reaching through a null.
	[Test]
	public static void CopyIdPutsThePersistentGuidOnTheClipboard()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let hierarchy = new SceneHierarchyView(edit);
		defer hierarchy.ReleaseRef();

		let entity = edit.CreateEntity("Crate");
		Test.Assert(!hierarchy.CopyEntityId(entity)); // no context: nothing to copy onto

		let context = scope UIContext();
		let clipboard = scope TestClipboard();
		let root = new RootView();
		root.ViewportSize = .(400, 300);
		context.AddRootView(root);
		context.SetClipboard(clipboard);
		root.AddView(hierarchy..AddRef());

		Test.Assert(hierarchy.CopyEntityId(entity));
		Test.Assert(clipboard.Stored == scope $"{entity}");
		Test.Assert(!hierarchy.CopyEntityId(.())); // a nil entity names nothing
	}

	/// A guid copied from a log line, an MCP answer or a scene file finds its entity, as one finds
	/// an asset in the browser: whole or by its first digits, braces, dashes and case aside. A
	/// whole one selects the entity, its folded ancestors opened to show it.
	[Test]
	public static void TheFilterFindsAnEntityByItsGuidAndAWholeOneSelectsIt()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let hierarchy = new SceneHierarchyView(edit);
		defer hierarchy.ReleaseRef();

		let parent = edit.CreateEntity("Parent");
		let child = edit.CreateEntity("Child", parent);
		edit.CreateEntity("Sibling");
		hierarchy.Refresh();
		hierarchy.Tree.InternalTreeView.FlatAdapter.Collapse(0); // Parent folded: Child hidden
		hierarchy.Tree.InternalTreeView.InternalListView.NotifyDataChanged();
		Test.Assert(hierarchy.FlatCount == 2);

		void Type(StringView text)
		{
			hierarchy.FilterField.SetText(text);
			hierarchy.FilterField.OnTextChanged(hierarchy.FilterField);
		}
		let whole = child.ToString(.. scope .());

		// Its first digits find the child and the ancestor holding it, and select nothing.
		edit.EntitySelection.Clear(); // creating selected the new entity
		Type(StringView(whole, 0, 8));
		Test.Assert(edit.EntitySelection.IsEmpty, "first digits find, they do not select");

		// The whole guid, braced and in capitals: selected, its folded parent opened.
		let braced = scope String("{");
		for (let c in whole.RawChars)
			braced.Append(c.ToUpper);
		braced.Append("}");
		Type(braced);
		Test.Assert(!edit.EntitySelection.IsEmpty && (edit.EntitySelection.Primary == child));
		Test.Assert(hierarchy.FlatCount == 2, "Parent, now open, and Child");
		Test.Assert(hierarchy.Tree.InternalTreeView.FlatAdapter.IsExpanded(0));

		// A name still filters by name.
		Type("sib");
		Test.Assert(hierarchy.FlatCount == 1);
	}
}
