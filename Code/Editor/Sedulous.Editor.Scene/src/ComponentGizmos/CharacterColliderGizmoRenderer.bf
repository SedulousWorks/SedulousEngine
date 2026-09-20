using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Physics;
using static Sedulous.Editor.Scene.GizmoDrawHelpers;

namespace Sedulous.Editor.Scene;

/// A character's upright capsule, gated by Show Colliders.
class CharacterColliderGizmoRenderer : IGizmoRenderer
{
	public Type ComponentType => typeof(CharacterComponent);
	public bool DrawWhenUnselected => true;

	public void Draw(void* component, EntityHandle owner, GizmoContext ctx)
	{
		if (!ctx.ShowColliders)
			return;
		let ch = (CharacterComponent*)component;
		let position = WorldPosition(ctx.Scene.GetWorldMatrix(owner));
		let color = ctx.EntityEffectivelyActive
			? Color(0.2f, 0.9f, 0.9f, 1.0f) : Color(0.45f, 0.45f, 0.45f, 1.0f);
		let frame = Transform(position, .Identity, .One).ToMatrix();
		ColliderShapeGizmo.DrawWireCapsule(ctx.Debug, frame, ch.Radius, ch.HalfHeight, color);
	}
}
