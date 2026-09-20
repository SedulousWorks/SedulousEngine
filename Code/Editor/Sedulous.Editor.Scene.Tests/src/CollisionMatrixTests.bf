using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.UI;
using Sedulous.Editor.Core;
using Sedulous.Engine.Physics;

namespace Sedulous.Editor.Scene.Tests;

/// The collision groups matrix: its grid rebuilds with the groups, and removing the last
/// group clears its bit from every surviving mask while other removals are refused.
class CollisionMatrixTests
{
	[Test]
	public static void TheMatrixRebuildsItsGridWhenAGroupIsAdded()
	{
		let editor = scope CollisionMatrixEditor("Collision Groups", "Physics");
		editor.Names.Add(new String("Default"));
		editor.Matrix.Add(0xFFFFFFFF);

		let grid = editor.EditorView as ViewGroup; // a FlexLayout column
		Test.Assert(grid != null);
		let before = grid.ChildCount; // the header, one group row and the add button

		editor.Names.Add(new String("Group 1"));
		editor.Matrix.Add(0xFFFFFFFF);
		editor.RequestRebuild(); // no context: rebuilt in place
		Test.Assert(grid.ChildCount == before + 1); // the new row appeared

		delete editor.Names[1];
		editor.Names.RemoveAt(1);
		editor.Matrix.RemoveAt(1);
		editor.RequestRebuild();
		Test.Assert(grid.ChildCount == before);
	}

	private static CollisionMatrixEditor BuildSceneTabMatrix(SceneInspectorView inspector)
	{
		inspector.[Friend]mTabView.SetSelectedIndex(1); // the Scene tab
		inspector.Refresh();
		let grid = inspector.Grid;
		for (int i < grid.PropertyCount)
		{
			if (let matrix = grid.PropertyAt(i) as CollisionMatrixEditor)
				return matrix;
		}
		return null;
	}

	private static void SeedGroups(PhysicsSceneSettings settings, uint32 a, uint32 b, uint32 c)
	{
		settings.GroupNames.Add(new String("Default"));
		settings.GroupNames.Add(new String("Player"));
		settings.GroupNames.Add(new String("Debris"));
		settings.GroupCollides.Add(a);
		settings.GroupCollides.Add(b);
		settings.GroupCollides.Add(c);
	}

	[Test]
	public static void RemovingTheLastGroupClearsItsBitFromEverySurvivingMask()
	{
		SceneInspectors.RegisterBuiltin();
		let scene = scope Scene("t");
		let physics = scene.AddSystem<PhysicsSceneSystem>();
		let settings = physics.Settings;
		SeedGroups(settings, 0b101, 0b110, 0b111); // Default vs Default and Debris; Player vs Player and Debris; Debris vs all

		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let editorContext = scope EditorContext();
		let inspector = new SceneInspectorView(editorContext, edit);
		defer inspector.ReleaseRef();

		let matrix = BuildSceneTabMatrix(inspector);
		Test.Assert(matrix != null);
		Test.Assert(matrix.Names.Count == 3);
		Test.Assert(matrix.OnRemoveGroup != null); // the production handler is wired

		matrix.OnRemoveGroup(2); // the LAST group, Debris

		Test.Assert(matrix.Names.Count == 2);
		Test.Assert(matrix.Matrix.Count == 2);
		for (let mask in matrix.Matrix)
			Test.Assert((mask & (1u << 2)) == 0);
		Test.Assert(matrix.Matrix[0] == 0b001); // Default kept only its non Debris bits
		Test.Assert(matrix.Matrix[1] == 0b010); // Player likewise

		// The live block followed, through the undoable settings command.
		Test.Assert(settings.GroupCollides.Count == 2);
		Test.Assert(settings.GroupNames.Count == 2);
		Test.Assert(settings.GroupCollides[0] == 0b001);
		Test.Assert(settings.GroupCollides[1] == 0b010);
		commands.Undo();
		Test.Assert(settings.GroupCollides.Count == 3);
		Test.Assert(settings.GroupCollides[2] == 0b111);
	}

	[Test]
	public static void GroupRemovalRefusesNonLastIndicesAndTheFinalGroup()
	{
		SceneInspectors.RegisterBuiltin();
		let scene = scope Scene("t");
		let physics = scene.AddSystem<PhysicsSceneSystem>();
		let settings = physics.Settings;
		SeedGroups(settings, 0b111, 0b111, 0b111);

		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let editorContext = scope EditorContext();
		let inspector = new SceneInspectorView(editorContext, edit);
		defer inspector.ReleaseRef();

		let matrix = BuildSceneTabMatrix(inspector);
		Test.Assert(matrix != null);
		Test.Assert(matrix.Names.Count == 3);

		matrix.OnRemoveGroup(0); // not the last: refused
		Test.Assert(matrix.Names.Count == 3);
		Test.Assert(matrix.Matrix.Count == 3);
		Test.Assert(matrix.Matrix[0] == 0b111); // untouched

		matrix.OnRemoveGroup(7); // out of range: refused
		Test.Assert(matrix.Names.Count == 3);

		matrix.OnRemoveGroup(2);
		Test.Assert(matrix.Names.Count == 2);
		matrix.OnRemoveGroup(1);
		Test.Assert(matrix.Names.Count == 1);

		matrix.OnRemoveGroup(0); // the final group stays
		Test.Assert(matrix.Names.Count == 1);
		Test.Assert(matrix.Matrix.Count == 1);
	}
}
