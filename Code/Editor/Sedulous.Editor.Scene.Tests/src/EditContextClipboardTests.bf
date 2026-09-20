using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene.Tests;

/// Duplicate, copy and paste of entities and components: fresh identities, exact values,
/// one undo step each.
class EditContextClipboardTests
{
	[Test]
	public static void DuplicateEntityGivesFreshGuidsSubtreeAndComponentsInOneUndo()
	{
		let scene = scope Scene();
		let health = scene.AddSystem<HealthManager>();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);

		let parent = edit.CreateEntity("Rig");
		let child = edit.CreateEntity("Lamp", parent);
		scene.SetLocalPosition(edit.Resolve(parent), .(3, 0, 0));
		health.Add(edit.Resolve(child)).Amount = 7;

		let copy = edit.DuplicateEntity(parent);
		Test.Assert(copy != Guid());
		Test.Assert(copy != parent); // a fresh identity
		let copyRoot = edit.Resolve(copy);
		Test.Assert(copyRoot.IsAssigned);
		Test.Assert(scene.GetEntityName(copyRoot) == "Rig (2)"); // copies are distinguishable
		Test.Assert(Math.Abs(scene.GetLocalTransform(copyRoot).Position.X - 3.0f) < 1e-4f);
		Test.Assert(!scene.GetParent(copyRoot).IsAssigned); // a sibling of the original
		Test.Assert(edit.EntitySelection.Count == 1);
		Test.Assert(edit.EntitySelection.Primary == copy); // the copy is the selection

		Test.Assert(scene.GetChildCount(copyRoot) == 1);
		let copyChild = scene.GetFirstChild(copyRoot);
		Test.Assert(scene.GetEntityName(copyChild) == "Lamp");
		Test.Assert(scene.GetEntityId(copyChild) != child);
		Test.Assert(health.Get(copyChild) != null);
		Test.Assert(health.Get(copyChild).Amount == 7);

		// A copy of a copy counts on, rather than stacking suffixes.
		let third = edit.DuplicateEntity(copy);
		Test.Assert(scene.GetEntityName(edit.Resolve(third)) == "Rig (3)");
		commands.Undo();

		commands.Undo();
		Test.Assert(!edit.Resolve(copy).IsAssigned);
		Test.Assert(edit.Resolve(parent).IsAssigned); // the original is untouched
		commands.Redo();
		Test.Assert(edit.Resolve(copy).IsAssigned);
		Test.Assert(health.Get(scene.GetFirstChild(edit.Resolve(copy))) != null);
	}

	[Test]
	public static void CopyPasteEntitiesAcrossScenesWithFreshGuids()
	{
		let sceneA = scope Scene();
		let healthA = sceneA.AddSystem<HealthManager>();
		let commandsA = scope EditorCommandStack();
		let editA = scope SceneEditContext(sceneA, commandsA);

		let src = editA.CreateEntity("Prop");
		let srcChild = editA.CreateEntity("Bulb", src);
		healthA.Add(editA.Resolve(srcChild)).Amount = 12;
		let blob = scope List<uint8>();
		editA.CopyEntity(src, blob);
		Test.Assert(!blob.IsEmpty);

		let sceneB = scope Scene();
		let healthB = sceneB.AddSystem<HealthManager>();
		let commandsB = scope EditorCommandStack();
		let editB = scope SceneEditContext(sceneB, commandsB);
		let target = editB.CreateEntity("Holder");

		let pasted = editB.PasteEntities(blob, target);
		Test.Assert(pasted != Guid());
		let root = editB.Resolve(pasted);
		Test.Assert(root.IsAssigned);
		Test.Assert(sceneB.GetEntityName(root) == "Prop");
		Test.Assert(sceneB.GetEntityId(sceneB.GetParent(root)) == target);
		Test.Assert(sceneB.GetChildCount(root) == 1);
		Test.Assert(healthB.Get(sceneB.GetFirstChild(root)) != null);
		Test.Assert(healthB.Get(sceneB.GetFirstChild(root)).Amount == 12);

		// The same blob pastes again as another fresh subtree, and the source is untouched.
		let pasted2 = editB.PasteEntities(blob);
		Test.Assert(pasted2 != Guid());
		Test.Assert(pasted2 != pasted);
		Test.Assert(editA.Resolve(src).IsAssigned);

		commandsB.Undo();
		Test.Assert(!editB.Resolve(pasted2).IsAssigned);
		Test.Assert(editB.Resolve(pasted).IsAssigned);

		// Garbage is refused rather than half pasted.
		let junk = scope List<uint8>();
		junk.Add(0xFF);
		Test.Assert(editB.PasteEntities(junk) == Guid());
	}

	[Test]
	public static void CopyPasteComponentAddsOverwritesAndUndoesExactly()
	{
		let scene = scope Scene();
		let health = scene.AddSystem<HealthManager>();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);

		let a = edit.CreateEntity("A");
		let b = edit.CreateEntity("B");
		health.Add(edit.Resolve(a)).Amount = 9;

		let blob = scope List<uint8>();
		edit.CopyComponent(a, typeof(Health), blob);
		Test.Assert(!blob.IsEmpty);
		let typeId = scope String();
		SceneEditContext.PeekComponentTypeId(blob, typeId);
		Test.Assert(typeId == "test.health");

		// Add.
		Test.Assert(edit.PasteComponent(b, blob));
		Test.Assert(health.Get(edit.Resolve(b)) != null);
		Test.Assert(health.Get(edit.Resolve(b)).Amount == 9);
		commands.Undo();
		Test.Assert(health.Get(edit.Resolve(b)) == null);
		commands.Redo();
		Test.Assert(health.Get(edit.Resolve(b)) != null);

		// Overwrite, undone to the prior bytes.
		health.Get(edit.Resolve(b)).Amount = 1;
		Test.Assert(edit.PasteComponent(b, blob));
		Test.Assert(health.Get(edit.Resolve(b)).Amount == 9);
		commands.Undo();
		Test.Assert(health.Get(edit.Resolve(b)) != null);
		Test.Assert(health.Get(edit.Resolve(b)).Amount == 1);

		// A component the scene has no manager for is refused.
		let none = scope List<uint8>();
		edit.CopyComponent(a, typeof(Widget), none);
		Test.Assert(none.IsEmpty);
	}
}
