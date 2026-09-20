using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Physics;

namespace Sedulous.Editor.Scene;

/// A rigid body's collider, gated by Show Colliders: green for dynamic, blue for the rest,
/// yellow for a trigger, grey when the entity is inactive.
class PhysicsColliderGizmoRenderer : IGizmoRenderer
{
	public Type ComponentType => typeof(RigidBodyComponent);
	public bool DrawWhenUnselected => true;

	public void Draw(void* component, EntityHandle owner, GizmoContext ctx)
	{
		if (!ctx.ShowColliders)
			return;
		let body = (RigidBodyComponent*)component;

		Color color;
		if (!ctx.EntityEffectivelyActive)
			color = .(0.45f, 0.45f, 0.45f, 1.0f); // dimmed: the simulation will skip it
		else if (body.IsTrigger)
			color = .(1.0f, 0.8f, 0.2f, 1.0f);
		else if (body.Motion == .Dynamic)
			color = .(0.3f, 1.0f, 0.4f, 1.0f);
		else
			color = .(0.4f, 0.6f, 1.0f, 1.0f);

		var s = ColliderShapeDraw();
		s.Shape = body.Shape;
		s.HalfExtents = body.HalfExtents;
		s.Radius = body.Radius;
		s.HalfHeight = body.HalfHeight;
		s.PlaneHalfExtent = body.PlaneHalfExtent;
		s.Cooked = body.CollisionShape.Get;
		s.Heightfield = body.Heightfield.Get;
		ColliderShapeGizmo.DrawColliderShape(s, ctx.Scene.GetWorldMatrix(owner), color, ctx.Debug);
	}
}
