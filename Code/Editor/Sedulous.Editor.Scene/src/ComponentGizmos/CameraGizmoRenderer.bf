using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Render;
using static Sedulous.Editor.Scene.GizmoDrawHelpers;

namespace Sedulous.Editor.Scene;

/// A camera's frustum, capped at a few metres so a distant far plane does not swamp the
/// viewport.
class CameraGizmoRenderer : IGizmoRenderer
{
	public Type ComponentType => typeof(CameraComponent);

	public void Draw(void* component, EntityHandle owner, GizmoContext ctx)
	{
		let camera = (CameraComponent*)component;
		let world = ctx.Scene.GetWorldMatrix(owner);
		let position = WorldPosition(world);
		let forward = WorldForward(world);
		let up = (Abs(forward.Y) < 0.99f) ? Float3(0, 1, 0) : Float3(0, 0, 1);

		// A short frustum (clamped far) keeps scene cameras readable; an orthographic camera
		// draws as the box it sees.
		var preview = *camera;
		preview.NearZ = Max(camera.NearZ, 0.01f);
		preview.FarZ = Min(camera.FarZ, 8.0f);
		let view = Float4x4.LookAtRH(position, position + forward, up);
		let proj = preview.MakeProjection(camera.Aspect);
		ctx.Debug.DrawFrustum(Inverse(view * proj), .(0.9f, 0.9f, 0.9f, 1.0f));
	}
}
