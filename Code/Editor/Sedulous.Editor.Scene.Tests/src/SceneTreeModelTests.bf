using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.GUI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene.Tests;

/// The scene's tree as the hierarchy and the entity picker share it (Sedulous adds these: Raptor's
/// move of it out of the hierarchy has none of its own): the scene's row on top, the roots in list
/// order and each one's children under it; an inactive entity marked, an unnamed one so called, a
/// plain one by the generic icon; ids from the guids, found back; and a search keeping a match with
/// what holds it.
class SceneTreeModelTests
{
	[Test]
	public static void TheScenesRowOnTopItsEntitiesUnderItEachFoundBack()
	{
		let scene = scope Sedulous.Scene.Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let town = edit.CreateEntity("Town");
		let barrel = edit.CreateEntity("Barrel", town);
		let bell = edit.CreateEntity("Bell", town);
		let crate = edit.CreateEntity("Crate");
		let nameless = edit.CreateEntity("");
		scene.SetActive(edit.Resolve(bell), false);
		let icons = scope EditorIcons(new (path) => false);

		let model = scope SceneTreeModel();
		model.Build(scene, "Level", "Editor/Icons/scene.svg", icons, "");
		Test.Assert(model.Rows.Count == 6);
		Test.Assert(model.RowCount(.()) == 1, "one top row: the scene's");
		let top = model.Index(0, 0, .());
		Test.Assert(model.Data(top).AsString == "Level");
		Test.Assert(model.Data(top, .Icon).AsString == "Editor/Icons/scene.svg");
		Test.Assert(model.IdOf(top) == SceneTreeModel.cSceneRowId);
		Test.Assert(model.EntityOfNode(top.InternalId).IsNil);
		Test.Assert(model.RowCount(top) == 3, "the roots: Town, Crate and the unnamed one");
		let townAt = model.Index(0, 0, top);
		Test.Assert(model.Data(townAt).AsString == "Town");
		Test.Assert(model.Data(townAt, .Icon).AsString == "Editor/Icons/cube.svg", "a plain entity: the generic icon");
		Test.Assert(model.Data(model.Index(1, 0, top)).AsString == "Crate");
		Test.Assert(model.Data(model.Index(2, 0, top)).AsString == "(unnamed)");
		Test.Assert(model.RowCount(townAt) == 2);
		let bellAt = model.Index(1, 0, townAt);
		Test.Assert(model.Data(bellAt).AsString == "Bell");
		Test.Assert(model.Data(bellAt, .RowClass).AsString == "inactive");
		Test.Assert(model.Data(model.Index(0, 0, townAt), .RowClass).IsEmpty, "active, no member: no class");
		Test.Assert(model.ParentIndex(bellAt).InternalId == townAt.InternalId);
		Test.Assert(!model.ParentIndex(top).IsValid);

		// An id from the guid, the entity found back by it and by its node; its index by its guid.
		let id = model.IdOf(bellAt);
		Test.Assert(id == SceneTreeModel.IdOfEntity(bell));
		Test.Assert(id != SceneTreeModel.cSceneRowId);
		Test.Assert(model.EntityOfId(id) == bell);
		Test.Assert(model.EntityOfNode(bellAt.InternalId) == bell);
		Test.Assert(model.IndexOf(bell).InternalId == bellAt.InternalId);
		Test.Assert(model.IndexOf(crate).Row == 1);
		Test.Assert(!model.IndexOf(Guid(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11)).IsValid, "not shown");
		Test.Assert(model.EntityOfId(12345).IsNil);
		Test.Assert(nameless != .Empty);

		// No icons: none asked.
		model.Build(scene, "Level", "", null, "");
		Test.Assert(model.Data(model.IndexOf(barrel), .Icon).IsEmpty);
	}

	[Test]
	public static void ASearchKeepsAMatchWithWhatHoldsIt()
	{
		let scene = scope Sedulous.Scene.Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let town = edit.CreateEntity("Town");
		let barrel = edit.CreateEntity("Barrel", town);
		edit.CreateEntity("Bell", town);
		edit.CreateEntity("Crate");

		let model = scope SceneTreeModel();
		model.Build(scene, "Level", "", null, "bar");
		Test.Assert(model.Rows.Count == 3, "the scene, Town for what it holds, Barrel");
		Test.Assert(model.Rows[1].Entity == town);
		Test.Assert(model.Rows[2].Entity == barrel);
		Test.Assert(model.Rows[2].Parent == 1);
		model.Build(scene, "Level", "", null, "");
		Test.Assert(model.Rows.Count == 5, "the search cleared: every entity again");
	}
}
