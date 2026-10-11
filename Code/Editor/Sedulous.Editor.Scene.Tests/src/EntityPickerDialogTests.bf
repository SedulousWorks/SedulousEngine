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

	/// The picker's filter finds an entity by its guid too, by its first digits or whole, and a
	/// whole one is the choice.
	[Test]
	public static void TheFilterFindsAnEntityByItsGuidAndAWholeOneIsTheChoice()
	{
		let scene = scope Scene();
		let crate = scene.CreateEntity("Crate");
		let lamp = scene.CreateEntity("Lamp");
		scene.SetParent(lamp, crate);
		scene.CreateEntity("Barrel");

		let dialog = new EntityPickerDialog(scene, scene.GetEntityId(crate));
		defer dialog.ReleaseRef();
		Test.Assert(dialog.NodeCount == 3);
		Test.Assert(dialog.SelectedEntity == scene.GetEntityId(crate), "the current target, pre-selected");

		void Type(StringView text)
		{
			dialog.FilterField.SetText(text);
			dialog.FilterField.OnTextChanged(dialog.FilterField);
		}
		let bare = scope String();
		for (let c in scene.GetEntityId(lamp).ToString(.. scope .()).RawChars)
		{
			if (c != '-')
				bare.Append(c);
		}
		Type(StringView(bare, 0, 6));
		Test.Assert(dialog.NodeCount == 2, "Lamp and the Crate holding it");
		Type(bare);
		Test.Assert(dialog.SelectedEntity == scene.GetEntityId(lamp), "a whole guid is the choice");
		Type("barr");
		Test.Assert(dialog.NodeCount == 1);
	}
}
