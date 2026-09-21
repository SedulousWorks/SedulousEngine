using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Render;
using Sedulous.Spline;
using Sedulous.Engine.Spline;
using Sedulous.Editor.Core;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Spline.Tests;

/// The spline tool over a headless scene: availability, picking, a point drag as one undo
/// step, a Ctrl-click insert, and the provider.
class SplineEditToolTests
{
	private static Float3 CamPos => .(0.0f, 0.0f, 10.0f);
	private static bool Near(float a, float b) => Math.Abs(a - b) < 0.01f;

	private static ViewportToolInput Frame(Float3 through, bool pressed, bool down, bool released, bool ctrl = false)
	{
		var input = ViewportToolInput();
		input.Ray.Origin = CamPos;
		input.Ray.Direction = Normalized(through - CamPos);
		input.CameraPosition = CamPos;
		input.CameraForward = .(0.0f, 0.0f, -1.0f);
		input.LeftPressed = pressed;
		input.LeftDown = down;
		input.LeftReleased = released;
		input.Ctrl = ctrl;
		return input;
	}

	/// A three point spline along X on one entity, selected.
	private static SplineComponent* Rig(Scene scene, Selection<Guid> selection, out Guid id)
	{
		scene.AddSystem<SplineComponentManager>();
		let entity = scene.CreateEntity("Path");
		id = scene.GetEntityId(entity);
		let component = scene.GetSystem<SplineComponentManager>().Add(entity);
		component.Curve.Points.Add(.(.(-2.0f, 0.0f, 0.0f)));
		component.Curve.Points.Add(.(.(0.0f, 0.0f, 0.0f)));
		component.Curve.Points.Add(.(.(2.0f, 0.0f, 0.0f)));
		component.Curve.UpdateAutoHandles();
		component.Curve.RebuildArcLength();
		selection.Set(id);
		return component;
	}

	private static ViewportToolHostContext Host(Scene scene, EditorCommandStack commands, Selection<Guid> selection)
	{
		var host = ViewportToolHostContext();
		host.Scene = scene;
		host.Commands = commands;
		host.EntitySelection = selection;
		return host;
	}

	[Test]
	public static void AvailableOnlyWhileASelectedEntityCarriesASpline()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let selection = scope Selection<Guid>();
		let tool = scope SplineEditTool(Host(scene, commands, selection));
		Test.Assert(tool.Id == "spline.edit");
		Test.Assert(!tool.IsAvailable);
		Guid id = .();
		Rig(scene, selection, out id);
		Test.Assert(tool.IsAvailable);
		selection.Clear();
		Test.Assert(!tool.IsAvailable);
		Test.Assert(!tool.Update(Frame(.Zero, false, false, false)));
	}

	[Test]
	public static void DraggingAPointMovesItAsOneUndoStep()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let selection = scope Selection<Guid>();
		Guid id = .();
		let component = Rig(scene, selection, out id);
		let tool = scope SplineEditTool(Host(scene, commands, selection));

		// Hover the middle point, press, drag it up two units, release.
		Test.Assert(tool.Update(Frame(.Zero, false, false, false)));
		Test.Assert(tool.HoverPoint == 1);
		Test.Assert(tool.Update(Frame(.Zero, true, true, false)));
		Test.Assert(tool.IsDragging && (tool.SelectedPoint == 1));
		Test.Assert(tool.Update(Frame(.(0.0f, 2.0f, 0.0f), false, true, false)));
		Test.Assert(Math.Abs(component.Curve.Points[1].Position.Y - 2.0f) < 0.01f);
		Test.Assert(tool.Update(Frame(.(0.0f, 2.0f, 0.0f), false, false, true)));
		Test.Assert(!tool.IsDragging);
		Test.Assert(commands.CanUndo);

		// Undo restores the whole table; redo brings the move back.
		commands.Undo();
		Test.Assert(Math.Abs(component.Curve.Points[1].Position.Y) < 0.01f);
		commands.Redo();
		Test.Assert(Math.Abs(component.Curve.Points[1].Position.Y - 2.0f) < 0.01f);

		// A drag cut by a lock reverts without a command.
		let before = commands.Count;
		tool.Update(Frame(.Zero, false, false, false));
		Test.Assert(tool.Update(Frame(.(-2.0f, 0.0f, 0.0f), true, true, false)));
		Test.Assert(tool.Update(Frame(.(-2.0f, 1.0f, 0.0f), false, true, false)));
		var locked = Frame(.(-2.0f, 1.0f, 0.0f), false, true, false);
		locked.EditingLocked = true;
		tool.Update(locked);
		Test.Assert(!tool.IsDragging);
		Test.Assert(Math.Abs(component.Curve.Points[0].Position.Y) < 0.01f);
		Test.Assert(commands.Count == before);
	}

	[Test]
	public static void CtrlClickOnASegmentInsertsAPoint()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let selection = scope Selection<Guid>();
		Guid id = .();
		let component = Rig(scene, selection, out id);
		let tool = scope SplineEditTool(Host(scene, commands, selection));

		// Between the first two points, off any point: the preview appears with Ctrl held.
		Test.Assert(!tool.Update(Frame(.(-1.0f, 0.0f, 0.0f), false, false, false)));
		Test.Assert(!tool.HasInsertPreview);
		tool.Update(Frame(.(-1.0f, 0.0f, 0.0f), false, false, false, true));
		Test.Assert(tool.HasInsertPreview);
		Test.Assert(tool.Update(Frame(.(-1.0f, 0.0f, 0.0f), true, true, false, true)));
		Test.Assert(component.Curve.Points.Count == 4);
		Test.Assert(Math.Abs(component.Curve.Points[1].Position.X + 1.0f) < 0.15f);
		Test.Assert(commands.CanUndo);
		commands.Undo();
		Test.Assert(component.Curve.Points.Count == 3);
	}

	/// A component added bare, before its Initialize phase seeded it: no points at all. The
	/// tool builds the curve from Ctrl-clicks, one undo step each.
	[Test]
	public static void AnEmptySplineTakesItsFirstPointsFromCtrlClicksUndoably()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let selection = scope Selection<Guid>();
		let splines = scene.AddSystem<SplineComponentManager>();
		let entity = scene.CreateEntity("Path");
		let component = splines.Add(entity);
		selection.Set(scene.GetEntityId(entity));
		let tool = scope SplineEditTool(Host(scene, commands, selection));
		Test.Assert(tool.IsAvailable, "the component is there, even with nothing to draw");

		// Without Ctrl nothing happens; with Ctrl the place preview appears where the ray
		// meets the camera-facing plane through the entity.
		Test.Assert(!tool.Update(Frame(.(-1.0f, 0.0f, 0.0f), false, false, false)));
		Test.Assert(!tool.HasPlacePreview);
		tool.Update(Frame(.(-1.0f, 0.0f, 0.0f), false, false, false, true));
		Test.Assert(tool.HasPlacePreview);
		Test.Assert(!tool.HasInsertPreview);

		// Two Ctrl-clicks: a two-point curve, each click one undo step, the last point selected.
		Test.Assert(tool.Update(Frame(.(-1.0f, 0.0f, 0.0f), true, true, false, true)));
		Test.Assert(component.Curve.Points.Count == 1);
		Test.Assert(Near(component.Curve.Points[0].Position.X, -1.0f));
		Test.Assert(tool.SelectedPoint == 0);
		tool.Update(Frame(.(1.0f, 0.0f, 0.0f), false, false, true, true)); // release
		Test.Assert(tool.Update(Frame(.(1.0f, 0.0f, 0.0f), true, true, false, true)));
		Test.Assert(component.Curve.Points.Count == 2);
		Test.Assert(Near(component.Curve.Points[1].Position.X, 1.0f));
		Test.Assert(component.Curve.SegmentCount == 1);
		tool.Update(Frame(.(1.0f, 0.0f, 0.0f), false, false, true, true));

		// From here Ctrl-click is the insert-on-segment gesture, not placement.
		tool.Update(Frame(.(0.0f, 0.0f, 0.0f), false, false, false, true));
		Test.Assert(tool.HasInsertPreview);
		Test.Assert(!tool.HasPlacePreview);

		commands.Undo();
		Test.Assert(component.Curve.Points.Count == 1);
		commands.Undo();
		Test.Assert(component.Curve.Points.IsEmpty);
		commands.Redo();
		Test.Assert(component.Curve.Points.Count == 1);
	}

	[Test]
	public static void TheProviderAddsTheToolOnce()
	{
		let scene = scope Scene();
		let commands = scope EditorCommandStack();
		let selection = scope Selection<Guid>();
		let before = ViewportToolProviderRegistry.Count;
		SplineEditor.RegisterViewportTools();
		SplineEditor.RegisterViewportTools();
		Test.Assert(ViewportToolProviderRegistry.Count == before + 1);
		let manager = scope ViewportToolManager();
		ViewportToolProviderRegistry.CreateAll(manager, Host(scene, commands, selection));
		bool found = false;
		for (int i < manager.Count)
		{
			if (manager.ToolAt(i).Id == "spline.edit")
				found = true;
		}
		Test.Assert(found);
	}
}
