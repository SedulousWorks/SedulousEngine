using System;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Scene;
using Sedulous.Engine.Render;
using Sedulous.Editor.Core;
using static Sedulous.Editor.Scene.Tests.GizmoFixture;

namespace Sedulous.Editor.Scene.Tests;

/// Vertex snap: a move drag puts the pivot on the vertex under the cursor, never onto the
/// dragged entity itself, plain over no surface, one undo entry, and the toolbar's mode
/// without V.
class GizmoVertexSnapTests
{
	private static GizmoFrameInput Snapping(GizmoFrameInput frame)
	{
		var snapping = frame;
		snapping.VertexSnap = true;
		return snapping;
	}

	[Test]
	public static void VertexSnapPutsThePivotOnTheVertexUnderTheCursor()
	{
		let scene = scope Scene();
		let meshes = scene.AddSystem<MeshComponentManager>();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let ctl = scope GizmoController(edit);
		let cube = Primitives.Cube(2.0f);
		defer delete cube;

		// A cube to snap onto at (3, 0, 0): its face toward the camera at z = 1, corners
		// (2..4, -1..1).
		let targetId = edit.CreateEntity("Wall");
		let target = edit.Resolve(targetId);
		scene.SetLocalPosition(target, .(3, 0, 0));
		meshes.Add(target).Mesh.SetDirect(cube);
		// The dragged box has a mesh of its own: once moved in front of the wall it must not
		// snap onto itself.
		let id = edit.CreateEntity("Box");
		meshes.Add(edit.Resolve(id)).Mesh.SetDirect(cube);
		edit.EntitySelection.Set(id);
		scene.UpdateTransforms();
		commands.Clear(); // the drags' entries only

		let size = TransformGizmo.ScreenScale(CamPos, CamFwd, 1.0472f, .Zero);
		let grab = Float3(size * 0.6f, 0.0f, 0.0f); // the X shaft

		Test.Assert(ctl.Update(Frame(grab, true, true, false)));
		// Over the wall's face near its (4, 1, 1) corner: the pivot exactly there, though the
		// drag holds the X shaft.
		Test.Assert(ctl.Update(Snapping(Frame(.(3.8f, 0.8f, 1.0f), false, true, false))));
		Test.Assert(ctl.SnapTarget.HasValue);
		var at = scene.GetLocalTransform(edit.Resolve(id)).Position;
		Test.Assert(Near(at.X, 4.0f) && Near(at.Y, 1.0f) && Near(at.Z, 1.0f));
		// Again with the box now in front of the wall: it never snaps onto itself.
		scene.UpdateTransforms();
		Test.Assert(ctl.Update(Snapping(Frame(.(3.8f, 0.8f, 1.0f), false, true, false))));
		at = scene.GetLocalTransform(edit.Resolve(id)).Position;
		Test.Assert(Near(at.X, 4.0f) && Near(at.Y, 1.0f));

		// Over no surface: the drag as it is (along X, y back to 0), and nothing marked.
		Test.Assert(ctl.Update(Snapping(Frame(grab + Float3(0, 40.0f, 0), false, true, false))));
		Test.Assert(!ctl.SnapTarget.HasValue);
		Test.Assert(Near(scene.GetLocalTransform(edit.Resolve(id)).Position.Y, 0.0f));

		// Without vertex snap, over the wall: the plain axis drag.
		Test.Assert(ctl.Update(Frame(grab + Float3(1.0f, 0.5f, 0), false, true, false)));
		Test.Assert(!ctl.SnapTarget.HasValue);
		at = scene.GetLocalTransform(edit.Resolve(id)).Position;
		Test.Assert(Near(at.X, 1.0f, 0.05f) && Near(at.Y, 0.0f));

		// One drag, one undo entry, back to the start.
		Test.Assert(ctl.Update(Frame(grab + Float3(1.0f, 0.5f, 0), false, false, true)));
		Test.Assert(!ctl.SnapTarget.HasValue);
		commands.Undo();
		Test.Assert(Near(scene.GetLocalTransform(edit.Resolve(id)).Position.X, 0.0f));
		Test.Assert(!commands.CanUndo, "the drag was one entry");

		// The toolbar's mode snaps every drag, V or not.
		scene.UpdateTransforms();
		ctl.VertexSnapMode = true;
		Test.Assert(ctl.Update(Frame(grab, true, true, false)));
		Test.Assert(ctl.Update(Frame(.(3.8f, 0.8f, 1.0f), false, true, false)));
		Test.Assert(Near(scene.GetLocalTransform(edit.Resolve(id)).Position.Y, 1.0f));
		Test.Assert(ctl.Update(Frame(.(3.8f, 0.8f, 1.0f), false, false, true)));
	}
}
