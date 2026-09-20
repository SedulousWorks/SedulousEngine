using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Physics;

namespace Sedulous.Editor.Scene;

/// A child collider's shape, gated by Show Colliders.
class ChildColliderGizmoRenderer : IGizmoRenderer
{
	public Type ComponentType => typeof(ColliderComponent);
	public bool DrawWhenUnselected => true;

	public void Draw(void* component, EntityHandle owner, GizmoContext ctx)
	{
		if (!ctx.ShowColliders)
			return;
		let collider = (ColliderComponent*)component;
		let color = ctx.EntityEffectivelyActive
			? Color(0.25f, 0.85f, 0.8f, 1.0f) : Color(0.45f, 0.45f, 0.45f, 1.0f);
		var s = ColliderShapeDraw();
		s.Shape = collider.Shape;
		s.HalfExtents = collider.HalfExtents;
		s.Radius = collider.Radius;
		s.HalfHeight = collider.HalfHeight;
		s.PlaneHalfExtent = collider.PlaneHalfExtent;
		s.Cooked = collider.CollisionShape.Get;
		s.Heightfield = collider.Heightfield.Get;
		ColliderShapeGizmo.DrawColliderShape(s, ctx.Scene.GetWorldMatrix(owner), color, ctx.Debug);
	}
}
