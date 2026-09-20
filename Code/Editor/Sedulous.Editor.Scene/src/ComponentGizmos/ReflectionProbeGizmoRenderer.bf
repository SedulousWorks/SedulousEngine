using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Render;
using static Sedulous.Editor.Scene.GizmoDrawHelpers;

namespace Sedulous.Editor.Scene;

/// A probe's influence box and centre.
class ReflectionProbeGizmoRenderer : IGizmoRenderer
{
	public Type ComponentType => typeof(ReflectionProbeComponent);

	public void Draw(void* component, EntityHandle owner, GizmoContext ctx)
	{
		let probe = (ReflectionProbeComponent*)component;
		let world = ctx.Scene.GetWorldMatrix(owner);
		let position = WorldPosition(world);
		let color = Color(0.4f, 0.8f, 1.0f, 1.0f);
		ctx.Debug.DrawTransformedBox(Float3.Zero - probe.HalfExtents, probe.HalfExtents, world, color);
		DrawCenterCross(ctx.Debug, position, 0.2f, color);
	}
}
