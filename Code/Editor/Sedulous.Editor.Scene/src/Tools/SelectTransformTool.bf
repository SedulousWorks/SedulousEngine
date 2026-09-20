using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Shell;
using Sedulous.Render;
using Sedulous.Editor.Core;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Scene;

/// The default viewport tool: click picks an entity, Ctrl-click toggles it, empty space
/// clears, and the transform gizmo over the selection takes the pointer first.
///
/// The edit context is borrowed: the page owns it and the tool dies with the page.
class SelectTransformTool : IViewportTool
{
	private SceneEditContext mEdit;
	private GizmoController mGizmos ~ delete _;

	public this(SceneEditContext edit)
	{
		mEdit = edit;
		mGizmos = new GizmoController(edit);
	}

	public StringView Id => "select";
	public StringView DisplayName => "Select";
	/// The default tool never reports unavailable.
	public bool IsAvailable => true;
	public GizmoController Gizmos => mGizmos;

	public void OnActivate() {}

	/// A tool switch mid drag closes the drag out, so no command group is left half applied.
	public void OnDeactivate()
	{
		var gizmoInput = GizmoFrameInput();
		gizmoInput.PointerValid = false;
		mGizmos.Update(gizmoInput);
	}

	public bool Update(in ViewportToolInput input)
	{
		var gizmoInput = GizmoFrameInput();
		gizmoInput.Ray = .(input.Ray.Origin, input.Ray.Direction);
		gizmoInput.CameraPosition = input.CameraPosition;
		gizmoInput.CameraForward = input.CameraForward;
		gizmoInput.FovY = input.FovY;
		// A locked page still picks, but never drags.
		gizmoInput.PointerValid = input.PointerValid && !input.EditingLocked;
		gizmoInput.LeftPressed = input.LeftPressed;
		gizmoInput.LeftDown = input.LeftDown;
		gizmoInput.LeftReleased = input.LeftReleased;
		gizmoInput.Snap = input.Ctrl;
		if ((input.Keyboard != null) && gizmoInput.PointerValid)
		{
			gizmoInput.KeyTranslate = input.Keyboard.IsKeyPressed(.W);
			gizmoInput.KeyRotate = input.Keyboard.IsKeyPressed(.E);
			gizmoInput.KeyScale = input.Keyboard.IsKeyPressed(.R);
			gizmoInput.KeyToggleSpace = input.Keyboard.IsKeyPressed(.X);
		}
		let consumed = mGizmos.Update(gizmoInput);

		if (!consumed && input.PointerOver && input.LeftPressed)
			PickOnClick(input);
		return consumed;
	}

	public void Draw(DebugDraw drawList) => mGizmos.Draw(drawList);

	public StringView StatusText => mGizmos.IsActive ? mGizmos.StatusText : default;

	/// The nearest entity whose origin lies within a small, distance scaled radius of the
	/// click ray.
	private void PickOnClick(in ViewportToolInput input)
	{
		let scene = mEdit.Scene;
		let origin = input.Ray.Origin;
		let dir = input.Ray.Direction;

		var best = Guid();
		var bestT = FloatMax;
		scene.ForEachEntity(scope [&](e) =>
		{
			let world = scene.GetWorldMatrix(e);
			let p = Float3(world.M[3][0], world.M[3][1], world.M[3][2]);
			let toCenter = p - origin;
			let t = Dot(toCenter, dir);
			if ((t <= 0.0f) || (t >= bestT))
				return;
			let closest = origin + dir * t;
			let d = p - closest;
			let radius = Max(0.15f, t * 0.02f);
			if (Dot(d, d) <= radius * radius)
			{
				bestT = t;
				best = scene.GetEntityId(e);
			}
		});

		let selection = mEdit.EntitySelection;
		if (best != Guid())
		{
			if (input.Ctrl)
				selection.Toggle(best);
			else
				selection.Set(best);
		}
		else if (!input.Ctrl)
		{
			selection.Clear();
		}
	}
}
