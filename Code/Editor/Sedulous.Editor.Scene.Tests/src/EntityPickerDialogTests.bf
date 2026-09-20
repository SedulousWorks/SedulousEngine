using System;
using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Editor.Scene.Tests;

class EntityPickerDialogTests
{
	[Test]
	public static void TheTreeListsEveryEntityAndPreselectsTheCurrentOne()
	{
		let scene = scope Scene();
		let parent = scene.CreateEntity("Parent");
		let child = scene.CreateEntity("Child");
		scene.SetParent(child, parent);
		scene.CreateEntity("Other");

		let dialog = new EntityPickerDialog(scene, scene.GetEntityId(child));
		defer dialog.ReleaseRef();
		Test.Assert(dialog.NodeCount == 3);
		Test.Assert(dialog.SelectedNode == 1); // pre-order: Parent, Child, Other

		// A pick hands back the guid; Clear hands back nil.
		var picked = Guid(9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9);
		dialog.OnPicked = new [&picked](id) => { picked = id; };
		dialog.[Friend]Confirm(scene.GetEntityId(parent));
		Test.Assert(picked == scene.GetEntityId(parent));
	}

	[Test]
	public static void TheSnapshotFiltersByNameAndKeepsAMatchingChildsPath()
	{
		let scene = scope Scene();
		let rig = scene.CreateEntity("Rig");
		let lamp = scene.CreateEntity("Lamp");
		scene.SetParent(lamp, rig);
		scene.CreateEntity("Crate");

		let snapshot = scope EntityTreeSnapshot();
		snapshot.Filter.Set("lamp");
		snapshot.Rebuild(scene);
		Test.Assert(snapshot.Count == 2); // Rig stays as Lamp's path; Crate is gone
		Test.Assert(snapshot.Roots.Count == 1);
		Test.Assert(snapshot.Nodes[1].Name == "Lamp");
		Test.Assert(snapshot.IndexOf(scene.GetEntityId(lamp)) == 1);
		Test.Assert(snapshot.IndexOf(Guid()) == -1);
	}
}
