using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Navigation;

namespace Sedulous.Editor.Scene;

/// A zone's bake extents.
class NavMeshZoneGizmoRenderer : IGizmoRenderer
{
	public Type ComponentType => typeof(NavMeshZoneComponent);

	public void Draw(void* component, EntityHandle owner, GizmoContext ctx)
	{
		let zone = (NavMeshZoneComponent*)component;
		let world = ctx.Scene.GetWorldMatrix(owner);
		ctx.Debug.DrawTransformedBox(Float3.Zero - zone.Extents, zone.Extents, world,
			.(0.20f, 0.85f, 1.0f, 1.0f));
	}
}
