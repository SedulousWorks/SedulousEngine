using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
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
			// A block whose values can come from a profile: its verbs between the block's own
			// fields (the source, the profile) and its values.
			if (system.SettingsProfileType != null)
				section.OnValuesBegin = scope:: [&]() => BuildSettingsProfileRows(type, category);
			entry.Build(section);

			if (type == typeof(PhysicsSceneSettings))
				BuildCollisionMatrixRow(type, category);
			if (type == typeof(SceneScriptSettings))
				BuildSceneScriptPropertyRows(type, category); // the Level's property rows
		}
	}

	/// Open Profile, Make Profile and Copy Into Scene for a block whose values can come from a
	/// profile. The first row names whose values the rows below are.
	private void BuildSettingsProfileRows(Type type, StringView category)
	{
		let edit = mEdit;
		let editor = mEditor;
		delegate Guid() usesProfile = new [=edit, =type]() =>
		{
			let system = edit.FindSystemBySettingsType(type);
			return (system != null) ? system.SettingsProfile : .();
		};
		Keep(usesProfile);

		// The profile in use, named: its values are the rows below, shared by every scene using it.
		let open = new ButtonEditor("Open Profile", new [=editor, =usesProfile]() =>
			{
				let id = usesProfile();
				if ((id != Guid.Empty) && (editor.OpenAsset != null))
					editor.OpenAsset(id);
			}, category);
		open.SetTooltip("The values below are this profile's: an edit changes every scene using it (written to the profile on save).");
		AddStatefulEditor(open, new [=editor, =usesProfile, =open]() =>
			{
				let id = usesProfile();
				open.SetButtonEnabled(id != Guid.Empty);
				let label = scope String();
				if (id == Guid.Empty)
					label.Set("Values: this scene's");
				else
					label.AppendF("Values: profile '{}'", editor.AssetNameFor(id, .. scope .()));
				open.SetDisplayName(label);
			});

		let profileName = new $"{edit.Scene.Name} {category}";
		Keep(profileName);
		let make = new ButtonEditor("Make Profile", new [=editor, =edit, =type, =profileName]() =>
			{
				let made = SettingsProfiles.Make(editor, edit, type, profileName);
				if (made != null)
					editor.Notify(.Success, scope $"Made profile '{made.Name}'; this scene uses it.");
			}, category);
		make.SetTooltip("Saves these values as a new profile asset, and this scene uses it.");
		AddStatefulEditor(make, new [=usesProfile, =make]() => { make.SetButtonEnabled(usesProfile() == Guid.Empty); });

		let copy = new ButtonEditor("Copy Into Scene", new [=edit, =type]() =>
			{
				edit.MutateSceneSettings(type, scope (s) => { s.CopySettingsProfileIntoScene(); });
			}, category);
		copy.SetTooltip("Copies the profile's values into this scene, which then uses its own (the profile is unchanged).");
		AddStatefulEditor(copy, new [=usesProfile, =copy]() => { copy.SetButtonEnabled(usesProfile() != Guid.Empty); });
	}

	/// AddEditor for a row whose state its refresher sets: run once now, so the row is right
	/// from the frame it is built rather than the one after. CONSUMES the refresher.
	private void AddStatefulEditor(PropertyEditor editor, delegate void() refresher)
	{
		refresher();
		AddEditor(editor, refresher);
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
