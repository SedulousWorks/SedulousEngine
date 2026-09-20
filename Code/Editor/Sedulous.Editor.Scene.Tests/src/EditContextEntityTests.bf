using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene.Tests;

/// The entity verbs of SceneEditContext: create, rename, reparent, reorder, destroy, the
/// transform and active edits, and what each does under undo and redo.
class EditContextEntityTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	[Test]
	public static void CreateEntityUndoRedoKeepsTheSameGuidAndParentsApply()
	{
		let scene = scope Scene("t");
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);

		let parent = edit.CreateEntity("Parent");
		Test.Assert(parent != Guid());
		Test.Assert(scene.EntityCount == 1);
		Test.Assert(edit.EntitySelection.Contains(parent)); // the created entity is selected

		let child = edit.CreateEntity("Child", parent);
		Test.Assert(child != Guid());
		Test.Assert(scene.GetParent(edit.Resolve(child)) == edit.Resolve(parent));

		commands.Undo(); // child gone
		Test.Assert(scene.EntityCount == 1);
		Test.Assert(!edit.Resolve(child).IsAssigned);

		commands.Redo(); // child back with the SAME guid and parent
		Test.Assert(scene.EntityCount == 2);
		Test.Assert(edit.Resolve(child).IsAssigned);
		Test.Assert(scene.GetParent(edit.Resolve(child)) == edit.Resolve(parent));
	}

	[Test]
	public static void RenameMergesAndUndoesToTheOriginal()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);

		let id = edit.CreateEntity("Original");
		edit.RenameEntity(id, "First");
		edit.RenameEntity(id, "Second"); // merges into the previous rename
		Test.Assert(scene.GetEntityName(edit.Resolve(id)) == "Second");

		commands.Undo(); // ONE undo reverts both
		Test.Assert(scene.GetEntityName(edit.Resolve(id)) == "Original");
		commands.Redo();
		Test.Assert(scene.GetEntityName(edit.Resolve(id)) == "Second");
	}

	[Test]
	public static void ReparentUndoRestoresAndCyclesAndNoOpsAreRefused()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);

		let a = edit.CreateEntity("A");
		let b = edit.CreateEntity("B", a);
		let c = edit.CreateEntity("C");

		edit.ReparentEntity(b, c); // A/B -> C/B
		Test.Assert(scene.GetParent(edit.Resolve(b)) == edit.Resolve(c));

		commands.Undo();
		Test.Assert(scene.GetParent(edit.Resolve(b)) == edit.Resolve(a));

		commands.Redo(); // back to C/B
		edit.ReparentEntity(a, b); // b is no longer under a, so this is legal
		Test.Assert(scene.GetParent(edit.Resolve(a)) == edit.Resolve(b));
		edit.ReparentEntity(c, a); // a is under b under c: a cycle, refused
		Test.Assert(scene.GetParent(edit.Resolve(c)) == EntityHandle.Invalid);

		edit.ReparentEntity(b, b); // self: refused
		Test.Assert(scene.GetParent(edit.Resolve(b)) == edit.Resolve(c));
		let before = commands.Count;
		edit.ReparentEntity(b, c); // already C's child: dropped, no undo pollution
		Test.Assert(commands.Count == before);
	}

	[Test]
	public static void DestroyUndoRestoresTheFullSubtreeWithComponents()
	{
		let scene = scope Scene();
		let health = scene.AddSystem<HealthManager>();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);

		let root = edit.CreateEntity("Root");
		let childA = edit.CreateEntity("ChildA", root);
		let grand = edit.CreateEntity("Grandchild", childA);
		let childB = edit.CreateEntity("ChildB", root);

		var t = Transform();
		t.Position = .(1, 2, 3);
		scene.SetLocalTransform(edit.Resolve(childA), t);
		scene.SetActive(edit.Resolve(childB), false);
		health.Add(edit.Resolve(grand)).Amount = 77;
		health.Add(edit.Resolve(root)).Amount = 5;

		edit.EntitySelection.Set(grand);
		edit.DestroyEntity(root);

		Test.Assert(scene.EntityCount == 0);
		Test.Assert(health.ComponentCount == 0);
		Test.Assert(edit.EntitySelection.IsEmpty); // the doomed subtree is deselected

		commands.Undo();

		Test.Assert(scene.EntityCount == 4);
		Test.Assert(edit.Resolve(root).IsAssigned);
		Test.Assert(edit.Resolve(childA).IsAssigned);
		Test.Assert(edit.Resolve(grand).IsAssigned);
		Test.Assert(edit.Resolve(childB).IsAssigned);

		Test.Assert(scene.GetParent(edit.Resolve(childA)) == edit.Resolve(root));
		Test.Assert(scene.GetParent(edit.Resolve(grand)) == edit.Resolve(childA));
		Test.Assert(scene.GetParent(edit.Resolve(childB)) == edit.Resolve(root));

		Test.Assert(scene.GetEntityName(edit.Resolve(grand)) == "Grandchild");
		Test.Assert(Near(scene.GetLocalTransform(edit.Resolve(childA)).Position.Y, 2.0f));
		Test.Assert(!scene.IsActive(edit.Resolve(childB)));

		Test.Assert(health.HasComponent(edit.Resolve(grand)));
		Test.Assert(health.Get(edit.Resolve(grand)).Amount == 77);
		Test.Assert(health.HasComponent(edit.Resolve(root)));
		Test.Assert(health.Get(edit.Resolve(root)).Amount == 5);

		commands.Redo();
		Test.Assert(scene.EntityCount == 0);
		Test.Assert(health.ComponentCount == 0);
	}

	[Test]
	public static void DestroyingAMissingEntityIsASafeNoOp()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);

		let missing = Guid(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2);
		edit.DestroyEntity(missing);
		Test.Assert(commands.Count == 0);
		edit.RenameEntity(missing, "nope"); // a failed execute is dropped
		Test.Assert(commands.Count == 0);
	}

	[Test]
	public static void SiblingReorderCommandWithUndoRedo()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);

		let a = edit.CreateEntity("A");
		let b = edit.CreateEntity("B");
		let c = edit.CreateEntity("C");

		edit.MoveEntityBefore(c, a);
		Test.Assert(scene.FirstRoot == edit.Resolve(c));

		commands.Undo();
		Test.Assert(scene.FirstRoot == edit.Resolve(a));
		Test.Assert(scene.GetNextSibling(edit.Resolve(b)) == edit.Resolve(c));
		commands.Redo();
		Test.Assert(scene.FirstRoot == edit.Resolve(c));

		edit.MoveEntityBefore(a, .()); // nil sibling: to the end
		Test.Assert(scene.GetNextSibling(edit.Resolve(b)) == edit.Resolve(a));
		commands.Undo(); // back to c, a, b
		Test.Assert(scene.GetNextSibling(edit.Resolve(c)) == edit.Resolve(a));
		Test.Assert(scene.GetNextSibling(edit.Resolve(a)) == edit.Resolve(b));

		let size = commands.Count;
		edit.MoveEntityBefore(a, b); // already before b: dropped
		Test.Assert(commands.Count == size);

		edit.ReparentEntity(b, a); // b under a
		let d = edit.CreateEntity("D", b);
		let size2 = commands.Count;
		edit.MoveEntityBefore(a, d); // the slot's parent b is inside a's subtree: refused
		Test.Assert(commands.Count == size2);
	}

	[Test]
	public static void ReparentPreservesTheWorldTransformAndUndoRestoresTheExactLocal()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);

		let parent = edit.CreateEntity("Parent");
		let child = edit.CreateEntity("Child");

		var tp = Transform();
		tp.Position = .(5, 0, 0);
		tp.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), 0.5f);
		scene.SetLocalTransform(edit.Resolve(parent), tp);
		var tc = Transform();
		tc.Position = .(1, 2, 3);
		scene.SetLocalTransform(edit.Resolve(child), tc);

		let worldBefore = scene.ComposeWorldMatrix(edit.Resolve(child));

		edit.ReparentEntity(child, parent);
		let worldAfter = scene.ComposeWorldMatrix(edit.Resolve(child));
		for (int r < 4)
			for (int c < 4)
				Test.Assert(Near(worldAfter.M[r][c], worldBefore.M[r][c]));

		commands.Undo();
		Test.Assert(scene.GetLocalTransform(edit.Resolve(child)).Position.X == 1.0f);
		Test.Assert(scene.GetLocalTransform(edit.Resolve(child)).Position.Y == 2.0f);
		Test.Assert(scene.GetParent(edit.Resolve(child)) == EntityHandle.Invalid);

		commands.Redo();
		let worldRedo = scene.ComposeWorldMatrix(edit.Resolve(child));
		for (int r < 4)
			for (int c < 4)
				Test.Assert(Near(worldRedo.M[r][c], worldBefore.M[r][c]));

		// A reorder within one parent leaves the local alone.
		let s1 = edit.CreateEntity("S1", parent);
		var ts = Transform();
		ts.Position = .(0.25f, 0.5f, 0.75f);
		scene.SetLocalTransform(edit.Resolve(s1), ts);
		edit.MoveEntityBefore(s1, child);
		Test.Assert(scene.GetLocalTransform(edit.Resolve(s1)).Position.X == 0.25f);
		Test.Assert(scene.GetLocalTransform(edit.Resolve(s1)).Position.Z == 0.75f);
	}

	[Test]
	public static void TransformAndActiveCommandsMergeAndUndo()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let id = edit.CreateEntity("E");
		let baseline = commands.Count;

		var t = Transform();
		for (int i = 1; i <= 5; i++)
		{
			t.Position = .((float)i, 0, 0);
			edit.SetLocalTransform(id, t);
		}
		Test.Assert(commands.Count == baseline + 1); // five sets, one step
		Test.Assert(Near(scene.GetLocalTransform(edit.Resolve(id)).Position.X, 5.0f));
		commands.Undo();
		Test.Assert(Near(scene.GetLocalTransform(edit.Resolve(id)).Position.X, 0.0f));

		edit.SetEntityActive(id, false);
		Test.Assert(!scene.IsActive(edit.Resolve(id)));
		commands.Undo();
		Test.Assert(scene.IsActive(edit.Resolve(id)));
		edit.SetEntityActive(id, true); // already active: dropped
		Test.Assert(commands.Count == baseline + 1);
	}
}
