using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Editor.Core;
using static Sedulous.Editor.Scene.Tests.GizmoFixture;

namespace Sedulous.Editor.Scene.Tests;

/// The controller over the edit context: one undo entry per drag, parent space conversion,
/// mode keys, and pose tracking while the pointer is away.
class GizmoControllerTests
{
	[Test]
	public static void ADragSessionIsExactlyOneUndoEntryRestoringTheStart()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let ctl = scope GizmoController(edit);

		let id = edit.CreateEntity("Box");
		edit.EntitySelection.Set(id);
		commands.Clear(); // forget the create, so the counts below are the drags only

		let size = TransformGizmo.ScreenScale(CamPos, CamFwd, 1.0472f, .Zero);
		let grab = Float3(size * 0.6f, 0.0f, 0.0f);

		Test.Assert(ctl.Update(Frame(grab, false, false, false)));
		Test.Assert(ctl.Gizmo.Hovered == .X);
		Test.Assert(!commands.CanUndo);

		Test.Assert(ctl.Update(Frame(grab, true, true, false)));
		Test.Assert(ctl.Gizmo.IsDragging);
		Test.Assert(ctl.Update(Frame(grab + Float3(1.0f, 0, 0), false, true, false)));
		Test.Assert(ctl.Update(Frame(grab + Float3(2.0f, 0, 0), false, true, false)));
		Test.Assert(ctl.Update(Frame(grab + Float3(2.0f, 0, 0), false, false, true)));
		Test.Assert(!ctl.Gizmo.IsDragging);

		Test.Assert(Near(scene.GetLocalTransform(edit.Resolve(id)).Position.X, 2.0f, 0.05f));

		Test.Assert(commands.CanUndo);
		commands.Undo();
		Test.Assert(Near(scene.GetLocalTransform(edit.Resolve(id)).Position.X, 0.0f, 0.0001f));
		Test.Assert(!commands.CanUndo);
		commands.Redo();
		Test.Assert(Near(scene.GetLocalTransform(edit.Resolve(id)).Position.X, 2.0f, 0.05f));

		// A second drag is its own entry, never merged into the first.
		Test.Assert(ctl.Update(Frame(grab + Float3(2.0f, 0, 0), true, true, false)));
		Test.Assert(ctl.Update(Frame(grab + Float3(3.0f, 0, 0), false, true, false)));
		Test.Assert(ctl.Update(Frame(grab + Float3(3.0f, 0, 0), false, false, true)));
		Test.Assert(Near(scene.GetLocalTransform(edit.Resolve(id)).Position.X, 3.0f, 0.05f));
		commands.Undo();
		Test.Assert(Near(scene.GetLocalTransform(edit.Resolve(id)).Position.X, 2.0f, 0.05f));
		commands.Undo();
		Test.Assert(Near(scene.GetLocalTransform(edit.Resolve(id)).Position.X, 0.0f, 0.0001f));
	}

	[Test]
	public static void WorldDragsConvertIntoARotatedParentsSpace()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let ctl = scope GizmoController(edit);

		let parentId = edit.CreateEntity("Parent");
		let childId = edit.CreateEntity("Child", parentId);
		{
			var t = Transform();
			t.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), Pi * 0.5f);
			scene.SetLocalTransform(edit.Resolve(parentId), t);
		}
		edit.EntitySelection.Set(childId);

		let size = TransformGizmo.ScreenScale(CamPos, CamFwd, 1.0472f, .Zero);
		let grab = Float3(size * 0.6f, 0.0f, 0.0f);

		Test.Assert(ctl.Update(Frame(grab, false, false, false)));
		Test.Assert(ctl.Gizmo.Hovered == .X);
		Test.Assert(ctl.Update(Frame(grab, true, true, false)));
		Test.Assert(ctl.Update(Frame(grab + Float3(1.0f, 0, 0), false, true, false)));
		Test.Assert(ctl.Update(Frame(grab + Float3(1.0f, 0, 0), false, false, true)));

		// Moved one unit along world X...
		let world = scene.ComposeWorldMatrix(edit.Resolve(childId));
		Test.Assert(Near(world.M[3][0], 1.0f, 0.05f));
		Test.Assert(Near(world.M[3][1], 0.0f));
		Test.Assert(Near(world.M[3][2], 0.0f, 0.05f));

		// ...which is the parent's local Z.
		let local = scene.GetLocalTransform(edit.Resolve(childId));
		Test.Assert(Abs(local.Position.X) < 0.05f);
		Test.Assert(Near(Abs(local.Position.Z), 1.0f, 0.05f));
	}

	[Test]
	public static void ModeKeysSpaceToggleAndScaleForcingLocal()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let ctl = scope GizmoController(edit);

		let id = edit.CreateEntity("Thing");
		{
			var t = Transform();
			t.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), 0.7f);
			scene.SetLocalTransform(edit.Resolve(id), t);
		}
		edit.EntitySelection.Set(id);

		Test.Assert(ctl.Mode == .Translate);
		Test.Assert(ctl.Space == .World);

		var input = Frame(.(5, 5, 0), false, false, false);
		input.KeyRotate = true;
		ctl.Update(input);
		Test.Assert(ctl.Mode == .Rotate);

		input = Frame(.(5, 5, 0), false, false, false);
		input.KeyScale = true;
		ctl.Update(input);
		Test.Assert(ctl.Mode == .Scale);

		// Scale is always local: the handles take the entity's orientation.
		let q = ctl.Gizmo.Orientation;
		Test.Assert(Abs(q.Y) > 0.1f);

		input = Frame(.(5, 5, 0), false, false, false);
		input.KeyTranslate = true;
		ctl.Update(input);
		Test.Assert(ctl.Mode == .Translate);
		Test.Assert(Near(ctl.Gizmo.Orientation.Y, 0.0f, 0.001f)); // world again

		input = Frame(.(5, 5, 0), false, false, false);
		input.KeyToggleSpace = true;
		ctl.Update(input);
		Test.Assert(ctl.Space == .Local);
		Test.Assert(Abs(ctl.Gizmo.Orientation.Y) > 0.1f); // local: the entity's orientation

		edit.EntitySelection.Clear();
		Test.Assert(!ctl.Update(Frame(.Zero, false, false, false)));
		Test.Assert(!ctl.IsActive);
	}

	[Test]
	public static void PoseTracksSelectionEvenWhileThePointerIsOffTheViewport()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let ctl = scope GizmoController(edit);

		let a = edit.CreateEntity("A");
		let b = edit.CreateEntity("B");
		{
			var t = Transform();
			t.Position = .(5.0f, 0.0f, 0.0f);
			scene.SetLocalTransform(edit.Resolve(b), t);
		}

		var away = Frame(.Zero, false, false, false);
		away.PointerValid = false;

		edit.EntitySelection.Set(a);
		Test.Assert(!ctl.Update(away)); // a pose sync only, never consuming the mouse
		Test.Assert(ctl.IsActive);
		Test.Assert(Near(ctl.Gizmo.Position.X, 0.0f, 0.0001f));

		edit.EntitySelection.Set(b);
		ctl.Update(away);
		Test.Assert(ctl.IsActive);
		Test.Assert(Near(ctl.Gizmo.Position.X, 5.0f, 0.0001f));

		// Hover clears when the pointer leaves.
		let size = TransformGizmo.ScreenScale(CamPos, CamFwd, 1.0472f, .(5, 0, 0));
		ctl.Update(Frame(.(5.0f + size * 0.6f, 0, 0), false, false, false));
		Test.Assert(ctl.Gizmo.Hovered == .X);
		ctl.Update(away);
		Test.Assert(ctl.Gizmo.Hovered == .None);

		// A drag in flight when the pointer leaves is closed out, as one entry.
		commands.Clear();
		Test.Assert(ctl.Update(Frame(.(5.0f + size * 0.6f, 0, 0), true, true, false)));
		Test.Assert(ctl.Update(Frame(.(6.0f + size * 0.6f, 0, 0), false, true, false)));
		Test.Assert(ctl.Gizmo.IsDragging);
		Test.Assert(ctl.Update(away)); // consumed: the drag is being closed out
		Test.Assert(!ctl.Gizmo.IsDragging);
		Test.Assert(Near(scene.GetLocalTransform(edit.Resolve(b)).Position.X, 6.0f, 0.05f));
		Test.Assert(commands.CanUndo);
		commands.Undo();
		Test.Assert(Near(scene.GetLocalTransform(edit.Resolve(b)).Position.X, 5.0f));
		Test.Assert(!commands.CanUndo);
	}

	[Test]
	public static void APointerlessUpdateFollowsAnEntityTheSimulationMoves()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let ctl = scope GizmoController(edit);

		let crate = edit.CreateEntity("box");
		edit.EntitySelection.Set(crate);

		var away = Frame(.Zero, false, false, false);
		away.PointerValid = false;
		ctl.Update(away);
		Test.Assert(Near(ctl.Gizmo.Position.Y, 0.0f, 0.0001f));

		var t = Transform();
		t.Position = .(0.0f, -3.0f, 2.0f);
		scene.SetLocalTransform(edit.Resolve(crate), t);

		ctl.Update(away);
		Test.Assert(ctl.IsActive);
		Test.Assert(Near(ctl.Gizmo.Position.Y, -3.0f, 0.0001f));
		Test.Assert(Near(ctl.Gizmo.Position.Z, 2.0f, 0.0001f));
	}
}
