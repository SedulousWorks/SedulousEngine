using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Editor.Core;
using Sedulous.Editor.ViewportTools;
using static Sedulous.Editor.Scene.Tests.GizmoFixture;

namespace Sedulous.Editor.Scene.Tests;

/// The select tool: picking, the gizmo taking the pointer first, and the locked page.
class SelectToolTests
{
	[Test]
	public static void IdentityAndDefaultAvailability()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let tool = scope SelectTransformTool(edit);
		Test.Assert(tool.Id == "select");
		Test.Assert(tool.IsAvailable); // the default tool must never report unavailable
	}

	[Test]
	public static void ClickPicksTheNearestEntityCtrlTogglesEmptySpaceClears()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let tool = scope SelectTransformTool(edit);

		let nearId = edit.CreateEntity("Near");
		let farId = edit.CreateEntity("Far");
		{
			var t = Transform();
			t.Position = .(0.0f, 0.0f, -5.0f); // behind Near along the same click ray
			scene.SetLocalTransform(edit.Resolve(farId), t);
		}
		let selection = edit.EntitySelection;
		selection.Clear();

		Test.Assert(!tool.Update(ToolFrame(.Zero, true, true, false)));
		Test.Assert(selection.Contains(nearId));
		Test.Assert(!selection.Contains(farId));
		tool.Update(ToolFrame(.Zero, false, false, true));

		// Ctrl-click on nothing keeps the selection.
		Test.Assert(!tool.Update(ToolFrame(.(50.0f, 0.0f, 0.0f), true, true, false, true)));
		Test.Assert(selection.Contains(nearId));
		tool.Update(ToolFrame(.(50.0f, 0.0f, 0.0f), false, false, true));

		// A plain click on nothing clears.
		Test.Assert(!tool.Update(ToolFrame(.(50.0f, 0.0f, 0.0f), true, true, false)));
		Test.Assert(!selection.Contains(nearId));

		// A press while the pointer is off the viewport picks nothing.
		tool.Update(ToolFrame(.(50.0f, 0.0f, 0.0f), false, false, true));
		var away = ToolFrame(.Zero, true, true, false);
		away.PointerOver = false;
		Test.Assert(!tool.Update(away));
		Test.Assert(!selection.Contains(nearId));
	}

	[Test]
	public static void AGizmoDragConsumesThePointerIsOneUndoEntryAndSuppressesPicking()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let tool = scope SelectTransformTool(edit);

		let boxId = edit.CreateEntity("Box");
		let otherId = edit.CreateEntity("Other");
		{
			var t = Transform();
			t.Position = .(20.0f, 0.0f, 0.0f); // out of the way; must stay unselected
			scene.SetLocalTransform(edit.Resolve(otherId), t);
		}
		edit.EntitySelection.Set(boxId);
		commands.Clear(); // forget the creates, so the counts below are the drag only

		let size = TransformGizmo.ScreenScale(CamPos, CamFwd, 1.0472f, .Zero);
		let grab = Float3(size * 0.6f, 0.0f, 0.0f);

		Test.Assert(tool.Update(ToolFrame(grab, false, false, false)));
		Test.Assert(!commands.CanUndo);

		Test.Assert(tool.Update(ToolFrame(grab, true, true, false)));
		Test.Assert(tool.Update(ToolFrame(grab + Float3(1.0f, 0, 0), false, true, false)));
		Test.Assert(tool.Update(ToolFrame(grab + Float3(2.0f, 0, 0), false, true, false)));
		Test.Assert(tool.Update(ToolFrame(grab + Float3(2.0f, 0, 0), false, false, true)));

		Test.Assert(Near(scene.GetLocalTransform(edit.Resolve(boxId)).Position.X, 2.0f, 0.05f));
		Test.Assert(edit.EntitySelection.Contains(boxId)); // the consumed press never picked
		Test.Assert(!edit.EntitySelection.Contains(otherId));
		Test.Assert(commands.CanUndo);
		commands.Undo();
		Test.Assert(Near(scene.GetLocalTransform(edit.Resolve(boxId)).Position.X, 0.0f, 0.0001f));
		Test.Assert(!commands.CanUndo);
	}

	[Test]
	public static void EditingLockedBlocksDragsButSelectionPickingStillWorks()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let tool = scope SelectTransformTool(edit);

		let boxId = edit.CreateEntity("Box");
		edit.EntitySelection.Set(boxId);
		commands.Clear();

		let size = TransformGizmo.ScreenScale(CamPos, CamFwd, 1.0472f, .Zero);
		let grab = Float3(size * 0.6f, 0.0f, 0.0f);

		// A press on a handle while locked is a pick of empty space, not a drag.
		var locked = ToolFrame(grab, true, true, false);
		locked.EditingLocked = true;
		Test.Assert(!tool.Update(locked));
		Test.Assert(!commands.CanUndo);
		Test.Assert(!edit.EntitySelection.Contains(boxId));

		var pick = ToolFrame(.Zero, true, true, false);
		pick.EditingLocked = true;
		Test.Assert(!tool.Update(pick));
		Test.Assert(edit.EntitySelection.Contains(boxId));
		Test.Assert(Near(scene.GetLocalTransform(edit.Resolve(boxId)).Position.X, 0.0f, 0.0001f));
	}

	[Test]
	public static void OnDeactivateEndsAnInFlightDragWithNoHalfAppliedGroup()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let tool = scope SelectTransformTool(edit);

		let boxId = edit.CreateEntity("Box");
		edit.EntitySelection.Set(boxId);
		commands.Clear();

		let size = TransformGizmo.ScreenScale(CamPos, CamFwd, 1.0472f, .Zero);
		let grab = Float3(size * 0.6f, 0.0f, 0.0f);

		Test.Assert(tool.Update(ToolFrame(grab, false, false, false)));
		Test.Assert(tool.Update(ToolFrame(grab, true, true, false)));
		Test.Assert(tool.Update(ToolFrame(grab + Float3(1.0f, 0, 0), false, true, false)));

		tool.OnDeactivate(); // a tool switch mid drag

		if (commands.CanUndo)
			commands.Undo();
		Test.Assert(Near(scene.GetLocalTransform(edit.Resolve(boxId)).Position.X, 0.0f, 0.0001f));
		Test.Assert(!commands.CanUndo);
	}
}
