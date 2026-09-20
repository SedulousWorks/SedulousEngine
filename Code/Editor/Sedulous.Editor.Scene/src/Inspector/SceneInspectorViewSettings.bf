using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Script;

namespace Sedulous.Editor.Scene;

/// The Scene tab: a section per system with a registered settings type, plus the physics
/// collision matrix and the level script's property rows.
extension SceneInspectorView
{
	private void BuildSceneSettingsSections()
	{
		for (let system in mEdit.Scene.Systems)
		{
			let type = system.SettingsType;
			let entry = InspectorRegistry.Find(type);
			if (entry == null)
				continue;
			let category = scope String(entry.DisplayName);
			// A type named "...Settings" with no label of its own reads as the thing it sets.
			let suffix = "Settings";
			if ((category.Length > suffix.Length) && category.EndsWith(suffix))
			{
				category.RemoveFromEnd(suffix.Length);
				category.TrimEnd();
			}

			let section = scope InspectorSection(this, new SettingsTarget(mEdit, type), category);
			Keep(section.Target);
			entry.Build(section);

			if (type == typeof(PhysicsSceneSettings))
				BuildCollisionMatrixRow(type, category);
			if (type == typeof(SceneScriptSettings))
				BuildSceneScriptPropertyRows(type, category); // the Level's property rows
		}
	}

	/// The collision group matrix: names down the side, a symmetric grid of collide flags,
	/// add and remove. Every change commits the whole block as one undo step.
	private void BuildCollisionMatrixRow(Type type, StringView category)
	{
		let edit = mEdit;
		let system = edit.FindSystemBySettingsType(type);
		if (system == null)
			return;
		let live = (PhysicsSceneSettings)Internal.UnsafeCastToObject(system.SettingsInstance);

		let matrix = new CollisionMatrixEditor("Collision Groups", category);
		for (let name in live.GroupNames)
			matrix.Names.Add(new String(name));
		if (matrix.Names.IsEmpty)
			matrix.Names.Add(new String("Default"));
		matrix.Matrix.AddRange(live.GroupCollides);
		while (matrix.Matrix.Count < matrix.Names.Count)
			matrix.Matrix.Add(0xFFFFFFFF);

		// The edited names and flags written over the live block, committed as bytes.
		delegate void() commit = new [=edit, =type, =live, =matrix]() =>
		{
			let target = scope SettingsTarget(edit, type);
			target.Mutate(scope [=live, =matrix](p) =>
			{
				ClearAndDeleteItems(live.GroupNames);
				for (let name in matrix.Names)
					live.GroupNames.Add(new String(name));
				live.GroupCollides.Clear();
				live.GroupCollides.AddRange(matrix.Matrix);
			});
		};
		Keep(commit);

		matrix.OnRename = new [=commit, =matrix](i, name) =>
		{
			if (i >= matrix.Names.Count)
				return;
			matrix.Names[i].Set(name);
			commit();
			matrix.RequestRebuild(); // the cell tooltips name the groups
		};
		matrix.OnToggle = new [=commit, =matrix](i, j) =>
		{
			if ((i >= matrix.Matrix.Count) || (j >= matrix.Matrix.Count))
				return;
			let collides = (matrix.Matrix[i] & (1u << j)) != 0;
			if (collides)
			{
				matrix.Matrix[i] &= ~(1u << j);
				matrix.Matrix[j] &= ~(1u << i); // symmetric
			}
			else
			{
				matrix.Matrix[i] |= (1u << j);
				matrix.Matrix[j] |= (1u << i);
			}
			commit();
			matrix.RequestRebuild();
		};
		matrix.OnAddGroup = new [=commit, =matrix]() =>
		{
			matrix.Names.Add(new String()..AppendF("Group {}", matrix.Names.Count));
			matrix.Matrix.Add(0xFFFFFFFF);
			commit();
			matrix.RequestRebuild(); // the new row and column appear
		};
		matrix.OnRemoveGroup = new [=commit, =matrix](index) =>
		{
			if ((index + 1 != matrix.Names.Count) || (matrix.Names.Count <= 1))
				return;
			delete matrix.Names[index];
			matrix.Names.RemoveAt(index);
			matrix.Matrix.RemoveAt(index);
			let clear = (uint32)~(1u << index);
			for (int k < matrix.Matrix.Count)
				matrix.Matrix[k] &= clear; // drop the removed group's column from every row
			commit();
			matrix.RequestRebuild();
		};
		AddEditor(matrix, new () => {});
	}
}
