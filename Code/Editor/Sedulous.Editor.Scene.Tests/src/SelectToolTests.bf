using System;
using System.Collections;
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

	// ---- GPU picking and the marquee -------------------------------------------------------

	/// A scripted picker: counts requests, records the last rect, hands back an answer for one
	/// request when told to, and can refuse.
	private class FakePicker : IViewportPicker
	{
		public uint32 Requests = 0;
		public int32 LastX = -1;
		public int32 LastY = -1;
		public uint32 LastW = 0;
		public uint32 LastH = 0;
		public uint32 NextId = 1;
		public bool Refuse = false;

		private uint32 mAnswerFor = 0;
		private bool mAnswerReady = false;
		private List<EntityHandle> mAnswer = new .() ~ delete _;

		public uint32 RequestPick(int32 x, int32 y, uint32 width, uint32 height)
		{
			Requests++;
			LastX = x;
			LastY = y;
			LastW = width;
			LastH = height;
			return Refuse ? 0 : NextId++;
		}

		public bool TryTakePick(uint32 request, List<EntityHandle> hits)
		{
			if (!mAnswerReady || (request != mAnswerFor))
				return false;
			hits.Clear();
			hits.AddRange(mAnswer);
			mAnswerReady = false;
			return true;
		}

		public void Answer(uint32 request, params Span<EntityHandle> hits)
		{
			mAnswerFor = request;
			mAnswer.Clear();
			mAnswer.AddRange(hits);
			mAnswerReady = true;
		}
	}

	/// A press or release frame with the pointer at a pixel of a 640 by 360 view.
	private static ViewportToolInput PixelFrame(Float3 through, bool pressed, int32 px, int32 py,
		bool ctrl = false)
	{
		var input = ToolFrame(through, pressed, pressed, !pressed, ctrl);
		input.PointerX = px;
		input.PointerY = py;
		input.ViewportWidth = 640;
		input.ViewportHeight = 360;
		return input;
	}

	/// A frame mid drag: button held, pointer at the pixel.
	private static ViewportToolInput DragFrame(Float3 through, int32 px, int32 py, bool ctrl = false)
	{
		var input = ToolFrame(through, false, true, false, ctrl);
		input.PointerX = px;
		input.PointerY = py;
		input.ViewportWidth = 640;
		input.ViewportHeight = 360;
		return input;
	}

	private static ViewportToolInput ReleaseFrame(Float3 through, int32 px, int32 py, bool ctrl = false)
	{
		var input = ToolFrame(through, false, false, true, ctrl);
		input.PointerX = px;
		input.PointerY = py;
		input.ViewportWidth = 640;
		input.ViewportHeight = 360;
		return input;
	}

	/// Where a world point lands in the 640 by 360 fixture view: the tool's CPU projection.
	private static void FixturePixel(Float3 world, out int32 px, out int32 py)
	{
		let d = world - CamPos;
		let z = Dot(d, CamFwd);
		let tanY = Tan(1.0472f * 0.5f);
		let tanX = tanY * (640.0f / 360.0f);
		px = (int32)((Dot(d, Float3(1, 0, 0)) / (z * tanX) * 0.5f + 0.5f) * 640.0f);
		py = (int32)((0.5f - Dot(d, Float3(0, 1, 0)) / (z * tanY) * 0.5f) * 360.0f);
	}

	private static void PlaceAt(SceneEditContext edit, Scene scene, Guid id, Float3 position)
	{
		var t = Transform();
		t.Position = position;
		scene.SetLocalTransform(edit.Resolve(id), t);
	}

	[Test]
	public static void WithAPickerAClickAsksTheGpuAndAppliesTheAnswer()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let tool = scope SelectTransformTool(edit);
		let picker = scope FakePicker();
		tool.SetPicker(picker);
		let nearId = edit.CreateEntity("Near");
		let farId = edit.CreateEntity("Far");
		PlaceAt(edit, scene, farId, .(0.0f, 0.0f, -5.0f));
		let selection = edit.EntitySelection;
		selection.Clear();

		// Press: a 1x1 request at the pointer pixel; nothing selected until the answer lands.
		Test.Assert(!tool.Update(PixelFrame(.Zero, true, 123, 45)));
		Test.Assert(picker.Requests == 1);
		Test.Assert((picker.LastX == 123) && (picker.LastY == 45));
		Test.Assert((picker.LastW == 1) && (picker.LastH == 1));
		Test.Assert(tool.HasPendingPick);
		Test.Assert(selection.IsEmpty);

		// The GPU saw the FAR entity's surface, it being what is drawn under the pointer
		// whatever the CPU origin pick would say: the answer wins.
		picker.Answer(1, edit.Resolve(farId));
		tool.Update(PixelFrame(.Zero, false, 123, 45));
		Test.Assert(!tool.HasPendingPick);
		Test.Assert(selection.Contains(farId));
		Test.Assert(!selection.Contains(nearId));
	}

	[Test]
	public static void AGpuMissFallsBackToTheCpuPickCtrlRidesAlongNewestClickWins()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let tool = scope SelectTransformTool(edit);
		let picker = scope FakePicker();
		tool.SetPicker(picker);
		let nearId = edit.CreateEntity("Near");
		let farId = edit.CreateEntity("Far");
		PlaceAt(edit, scene, farId, .(0.0f, 0.0f, -5.0f));
		let selection = edit.EntitySelection;
		selection.Clear();

		// Click through both origins: the GPU answers nothing drawn there, an empty or a
		// light, so the CPU origin pick's nearest entity is selected.
		Test.Assert(!tool.Update(PixelFrame(.Zero, true, 10, 10)));
		picker.Answer(1);
		tool.Update(PixelFrame(.Zero, false, 10, 10));
		Test.Assert(selection.Contains(nearId));
		Test.Assert(!selection.Contains(farId));

		// Ctrl-click answered with the far entity: toggled INTO the selection, Ctrl having been
		// captured with the click, not read at answer time. The current selection is an entity
		// OFF the click ray, so its gizmo does not consume the press.
		tool.Update(PixelFrame(.Zero, false, 10, 10));
		let asideId = edit.CreateEntity("Aside");
		PlaceAt(edit, scene, asideId, .(20.0f, 0.0f, 0.0f));
		selection.Set(asideId);
		Test.Assert(!tool.Update(PixelFrame(.Zero, true, 10, 10, true)));
		picker.Answer(2, edit.Resolve(farId));
		tool.Update(PixelFrame(.Zero, false, 10, 10)); // no Ctrl now
		Test.Assert(selection.Contains(asideId));
		Test.Assert(selection.Contains(farId));
		Test.Assert(!selection.Contains(nearId));

		// Two clicks before any answer: the FIRST request's answer is ignored, the second
		// applies.
		selection.Clear();
		Test.Assert(!tool.Update(PixelFrame(.Zero, true, 10, 10)));
		tool.Update(PixelFrame(.Zero, false, 10, 10));
		Test.Assert(!tool.Update(PixelFrame(.Zero, true, 11, 11)));
		Test.Assert(picker.Requests == 4);
		picker.Answer(3, edit.Resolve(farId)); // the stale one
		tool.Update(PixelFrame(.Zero, false, 11, 11));
		Test.Assert(selection.IsEmpty);
		Test.Assert(tool.HasPendingPick);
		picker.Answer(4, edit.Resolve(nearId));
		tool.Update(PixelFrame(.Zero, false, 11, 11));
		Test.Assert(selection.Contains(nearId));
		Test.Assert(!selection.Contains(farId));

		// A dead handle in the answer, the entity destroyed while the pick was in flight, is
		// skipped: the CPU answer stands.
		selection.Clear();
		let farHandle = edit.Resolve(farId);
		Test.Assert(!tool.Update(PixelFrame(.Zero, true, 10, 10)));
		scene.DestroyEntity(farHandle);
		picker.Answer(5, farHandle);
		tool.Update(PixelFrame(.Zero, false, 10, 10));
		Test.Assert(selection.Contains(nearId));
	}

	[Test]
	public static void NoPixelOrARefusingPickerPicksOnTheCpuAtOnce()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let tool = scope SelectTransformTool(edit);
		let picker = scope FakePicker();
		tool.SetPicker(picker);
		let nearId = edit.CreateEntity("Near");
		let selection = edit.EntitySelection;
		selection.Clear();

		// No viewport size on the input, a host without pixels: an immediate CPU pick, no
		// request.
		Test.Assert(!tool.Update(ToolFrame(.Zero, true, true, false)));
		Test.Assert(picker.Requests == 0);
		Test.Assert(selection.Contains(nearId));
		tool.Update(ToolFrame(.Zero, false, false, true));

		// The picker refuses, the renderer not ready: an immediate CPU pick.
		selection.Clear();
		picker.Refuse = true;
		Test.Assert(!tool.Update(PixelFrame(.Zero, true, 5, 5)));
		Test.Assert(picker.Requests == 1);
		Test.Assert(!tool.HasPendingPick);
		Test.Assert(selection.Contains(nearId));

		// A pointer outside the view never asks the GPU; the selection is cleared first, a
		// selected entity under the ray handing the press to its gizmo.
		picker.Refuse = false;
		tool.Update(PixelFrame(.Zero, false, 5, 5));
		selection.Clear();
		Test.Assert(!tool.Update(PixelFrame(.Zero, true, 640, 5)));
		Test.Assert(picker.Requests == 1);
		Test.Assert(selection.Contains(nearId)); // the CPU pick answered instead
	}

	[Test]
	public static void ADragPastTheThresholdBecomesAMarqueeAndTheClickIsUndone()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let tool = scope SelectTransformTool(edit);
		let picker = scope FakePicker();
		tool.SetPicker(picker);
		let nearId = edit.CreateEntity("Near");
		let farId = edit.CreateEntity("Far");
		PlaceAt(edit, scene, farId, .(0.0f, 0.0f, -5.0f));
		let selection = edit.EntitySelection;
		selection.Clear();

		// Press on empty space far to the side: the click asks the GPU, request one.
		let empty = Float3(50.0f, 0.0f, 0.0f);
		Test.Assert(!tool.Update(PixelFrame(empty, true, 100, 80)));
		Test.Assert(tool.HasPendingPick);
		Test.Assert(!tool.IsMarqueeActive);
		// A two pixel wobble stays a click.
		Test.Assert(!tool.Update(DragFrame(empty, 102, 81)));
		Test.Assert(!tool.IsMarqueeActive);
		Test.Assert(tool.HasPendingPick);
		// Past the threshold it is a marquee: the click's pick is dropped, the pointer
		// consumed.
		Test.Assert(tool.Update(DragFrame(empty, 160, 140)));
		Test.Assert(tool.IsMarqueeActive);
		Test.Assert(!tool.HasPendingPick);
		Test.Assert(picker.Requests == 1);

		// Release: ONE rect request over the dragged pixels, inclusive, any corner order.
		tool.Update(ReleaseFrame(empty, 40, 140));
		Test.Assert(!tool.IsMarqueeActive);
		Test.Assert(tool.HasPendingMarquee);
		Test.Assert(picker.Requests == 2);
		Test.Assert((picker.LastX == 40) && (picker.LastY == 80));
		Test.Assert((picker.LastW == 61) && (picker.LastH == 61));
		Test.Assert(selection.IsEmpty); // nothing until the answer lands

		// The answer: both entities drawn in the rect, so both selected; a dead handle is
		// skipped.
		picker.Answer(2, edit.Resolve(nearId), edit.Resolve(farId), EntityHandle(999, 7));
		tool.Update(ReleaseFrame(empty, 40, 140));
		Test.Assert(!tool.HasPendingMarquee);
		Test.Assert(selection.Contains(nearId));
		Test.Assert(selection.Contains(farId));
		Test.Assert(selection.Count == 2);

		// A marquee that answers nothing clears, plain; the stale click's answer never
		// applies.
		Test.Assert(!tool.Update(PixelFrame(empty, true, 300, 300)));
		tool.Update(DragFrame(empty, 340, 340));
		tool.Update(ReleaseFrame(empty, 340, 340));
		picker.Answer(3); // the click's id: ignored
		tool.Update(ReleaseFrame(empty, 340, 340));
		Test.Assert(selection.Count == 2);
		picker.Answer(4); // the rect's id
		tool.Update(ReleaseFrame(empty, 340, 340));
		Test.Assert(selection.IsEmpty);
	}

	[Test]
	public static void CtrlMarqueeAddsAndThePressClickIsRestored()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let tool = scope SelectTransformTool(edit);
		let picker = scope FakePicker();
		tool.SetPicker(picker);
		let nearId = edit.CreateEntity("Near");
		let farId = edit.CreateEntity("Far");
		let asideId = edit.CreateEntity("Aside");
		PlaceAt(edit, scene, farId, .(0.0f, 0.0f, -5.0f));
		PlaceAt(edit, scene, asideId, .(20.0f, 0.0f, 0.0f));
		let selection = edit.EntitySelection;
		selection.Set(asideId);

		let empty = Float3(50.0f, 0.0f, 0.0f);
		Test.Assert(!tool.Update(PixelFrame(empty, true, 10, 10, true)));
		tool.Update(DragFrame(empty, 90, 90, true));
		tool.Update(ReleaseFrame(empty, 90, 90)); // Ctrl captured at press, not here
		picker.Answer(2, edit.Resolve(nearId), edit.Resolve(farId));
		tool.Update(ReleaseFrame(empty, 90, 90));
		Test.Assert(selection.Contains(asideId));
		Test.Assert(selection.Contains(nearId));
		Test.Assert(selection.Contains(farId));
		Test.Assert(selection.Count == 3);

		// A plain press on empty space with a synchronous CPU click, the picker refusing: the
		// click CLEARS the selection; dragging into a marquee puts it back first, then the
		// rect's answer replaces it.
		picker.Refuse = true;
		Test.Assert(!tool.Update(PixelFrame(empty, true, 200, 200)));
		Test.Assert(selection.IsEmpty); // the click's CPU answer: nothing there
		tool.Update(DragFrame(empty, 260, 260));
		Test.Assert(selection.Count == 3); // restored while the marquee is dragged
		picker.Refuse = false;
		tool.Update(ReleaseFrame(empty, 260, 260));
		picker.Answer(picker.NextId - 1, edit.Resolve(farId));
		tool.Update(ReleaseFrame(empty, 260, 260));
		Test.Assert(selection.Count == 1);
		Test.Assert(selection.Contains(farId));
	}

	[Test]
	public static void WithoutAPickerTheMarqueeSelectsTheOriginsProjectingInsideIt()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);
		let tool = scope SelectTransformTool(edit); // no picker
		let nearId = edit.CreateEntity("Near");
		let farId = edit.CreateEntity("Far");
		let asideId = edit.CreateEntity("Aside");
		let behindId = edit.CreateEntity("Behind");
		PlaceAt(edit, scene, farId, .(0.0f, 0.0f, -5.0f));
		PlaceAt(edit, scene, asideId, .(3.0f, 1.0f, 0.0f));
		PlaceAt(edit, scene, behindId, .(0.0f, 0.0f, 20.0f)); // behind the camera
		scene.UpdateTransforms(); // the CPU marquee reads world matrices
		let selection = edit.EntitySelection;
		selection.Clear();
		let empty = Float3(50.0f, 0.0f, 0.0f);

		// The whole view: everything in front of the camera.
		Test.Assert(!tool.Update(PixelFrame(empty, true, 0, 0)));
		tool.Update(DragFrame(empty, 639, 359));
		tool.Update(ReleaseFrame(empty, 639, 359));
		Test.Assert(selection.Contains(nearId));
		Test.Assert(selection.Contains(farId));
		Test.Assert(selection.Contains(asideId));
		Test.Assert(!selection.Contains(behindId));
		Test.Assert(selection.Count == 3);

		// A tight rect around the aside entity's pixel: only it.
		FixturePixel(.(3.0f, 1.0f, 0.0f), let ax, let ay);
		Test.Assert(!tool.Update(PixelFrame(empty, true, ax - 6, ay - 6)));
		tool.Update(DragFrame(empty, ax + 6, ay + 6));
		tool.Update(ReleaseFrame(empty, ax + 6, ay + 6));
		Test.Assert(selection.Count == 1);
		Test.Assert(selection.Contains(asideId));

		// OnDeactivate mid drag drops the marquee: nothing applied, the selection untouched.
		Test.Assert(!tool.Update(PixelFrame(empty, true, 0, 0)));
		tool.Update(DragFrame(empty, 639, 359));
		Test.Assert(tool.IsMarqueeActive);
		tool.OnDeactivate();
		Test.Assert(!tool.IsMarqueeActive);
		tool.Update(ReleaseFrame(empty, 639, 359));
		Test.Assert(selection.Count == 1);
		Test.Assert(selection.Contains(asideId));
	}
}
