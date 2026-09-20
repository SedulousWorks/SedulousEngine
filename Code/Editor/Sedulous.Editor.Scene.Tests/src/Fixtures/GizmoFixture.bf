using Sedulous.Core;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Scene.Tests;

/// A camera ten units up the Z axis looking down it, and rays cast from it.
static class GizmoFixture
{
	public static Float3 CamPos => .(0.0f, 0.0f, 10.0f);
	public static Float3 CamFwd => .(0.0f, 0.0f, -1.0f);

	public static GizmoRay RayThrough(Float3 point) => .(CamPos, Normalized(point - CamPos));

	public static TransformGizmo MakeGizmo()
	{
		let g = new TransformGizmo();
		g.Position = .Zero;
		g.Size = 1.0f;
		g.SetCamera(CamPos, CamFwd);
		return g;
	}

	public static GizmoFrameInput Frame(Float3 through, bool pressed, bool down, bool released,
		bool snap = false)
	{
		var input = GizmoFrameInput();
		input.Ray = RayThrough(through);
		input.CameraPosition = CamPos;
		input.CameraForward = CamFwd;
		input.LeftPressed = pressed;
		input.LeftDown = down;
		input.LeftReleased = released;
		input.Snap = snap;
		return input;
	}

	public static ViewportToolInput ToolFrame(Float3 through, bool pressed, bool down,
		bool released, bool ctrl = false)
	{
		var input = ViewportToolInput();
		input.Ray.Origin = CamPos;
		input.Ray.Direction = Normalized(through - CamPos);
		input.CameraPosition = CamPos;
		input.CameraForward = CamFwd;
		input.LeftPressed = pressed;
		input.LeftDown = down;
		input.LeftReleased = released;
		input.Ctrl = ctrl;
		return input;
	}

	public static bool Near(float a, float b, float eps = 0.01f) => Abs(a - b) <= eps;
}
