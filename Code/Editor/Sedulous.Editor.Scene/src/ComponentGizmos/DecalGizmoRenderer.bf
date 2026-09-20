using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Render;
using static Sedulous.Editor.Scene.GizmoDrawHelpers;

namespace Sedulous.Editor.Scene;

/// A decal's projection box and the direction it projects along.
class DecalGizmoRenderer : IGizmoRenderer
{
	public Type ComponentType => typeof(DecalComponent);

	public void Draw(void* component, EntityHandle owner, GizmoContext ctx)
	{
		let decal = (DecalComponent*)component;
		let world = ctx.Scene.GetWorldMatrix(owner);
		let position = WorldPosition(world);
		let color = Color(1.0f, 0.75f, 0.2f, 1.0f);

		let he = decal.Size * 0.5f;
		ctx.Debug.DrawTransformedBox(Float3.Zero - he, he, world, color);
		let projDir = Float3.Zero - WorldForward(world);
		ctx.Debug.DrawArrow(position, position + projDir * (he.Z + 0.35f), color, 0.12f);
	}
}
