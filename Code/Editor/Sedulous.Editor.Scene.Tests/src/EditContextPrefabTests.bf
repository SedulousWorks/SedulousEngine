using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene.Tests;

/// Prefab instances through the edit context: spawn, replace, and revert to baseline.
class EditContextPrefabTests
{
	[Test]
	public static void SpawnPrefabInstanceIsUndoableAndRedoRecreatesTheSameGuids()
	{
		let scene = scope Scene("level");
		let health = scene.AddSystem<HealthManager>();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);

		let prefabId = Guid(0xAB, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xCD);
		let rootId = edit.SpawnPrefabInstance(prefabId, PrefabPayloads.Capture("Barrel", 12));
		Test.Assert(!rootId.IsNil);
		let live = edit.Resolve(rootId);
		Test.Assert(live.IsAssigned);
		Test.Assert(health.Has(live));
		Test.Assert(health.Get(live).Amount == 12);
		Test.Assert(scene.PrefabInstanceCount == 1);
		Test.Assert(edit.EntitySelection.Contains(rootId));

		commands.Undo();
		Test.Assert(!edit.Resolve(rootId).IsAssigned);
		Test.Assert(scene.PrefabInstanceCount == 0);

		commands.Redo();
		let back = edit.Resolve(rootId); // the SAME guid
		Test.Assert(back.IsAssigned);
		Test.Assert(health.Has(back));
		Test.Assert(scene.PrefabInstanceCount == 1);
	}

	[Test]
	public static void ReplaceEntityWithPrefabInstanceIsOneUndoStep()
	{
		let scene = scope Scene("level");
		scene.AddSystem<HealthManager>();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);

		let parent = edit.CreateEntity("Props");
		let before = edit.CreateEntity("Before", parent);
		let original = edit.CreateEntity("OldCrate", parent);
		let after = edit.CreateEntity("After", parent);
		{
			let h = edit.Resolve(original);
			var t = scene.GetLocalTransform(h);
			t.Position = .(4, 5, 6);
			scene.SetLocalTransform(h, t);
		}

		let prefabId = Guid(0x99, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x11);
		let instanceRoot = edit.ReplaceWithPrefabInstance(original, prefabId,
			PrefabPayloads.Capture("Crate", null));
		Test.Assert(!instanceRoot.IsNil);
		Test.Assert(!edit.Resolve(original).IsAssigned); // the original is replaced
		let inst = edit.Resolve(instanceRoot);
		Test.Assert(inst.IsAssigned);
		Test.Assert(scene.GetParent(inst) == edit.Resolve(parent)); // same parent
		Test.Assert(Math.Abs(scene.GetLocalTransform(inst).Position.X - 4.0f) < 1e-4f); // same placement
		let first = scene.GetFirstChild(edit.Resolve(parent));
		Test.Assert(first == edit.Resolve(before)); // same slot
		Test.Assert(scene.GetNextSibling(first) == inst);
		Test.Assert(scene.GetNextSibling(inst) == edit.Resolve(after));

		commands.Undo(); // ONE step: the instance is gone, the original is back
		Test.Assert(!edit.Resolve(instanceRoot).IsAssigned);
		Test.Assert(edit.Resolve(original).IsAssigned);
		Test.Assert(scene.PrefabInstanceCount == 0);
	}

	[Test]
	public static void RevertComponentToPrefabBaselineIsUndoable()
	{
		let scene = scope Scene("level");
		let health = scene.AddSystem<HealthManager>();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let rootId = edit.SpawnPrefabInstance(Guid(5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6),
			PrefabPayloads.Capture("Guard", 30));
		Test.Assert(!rootId.IsNil);
		let live = edit.Resolve(rootId);

		health.Get(live).Amount = 31;
		let type = scene.FindManagerBySerializationId("test.health").ComponentType;
		Test.Assert(edit.RevertComponentToBaseline(rootId, type));
		Test.Assert(health.Get(live).Amount == 30); // back to the baseline
		commands.Undo();
		Test.Assert(health.Get(live).Amount == 31); // the override is restored

		let plain = scene.CreateEntity("NotAMember");
		Test.Assert(!edit.RevertComponentToBaseline(scene.GetEntityId(plain), type)); // a non member
	}
}
