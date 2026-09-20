using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Physics;
using static Sedulous.Editor.Scene.GizmoDrawHelpers;

namespace Sedulous.Editor.Scene;

/// A joint's anchor, the link to its target, and the axis a hinge or slider works along.
/// Gated by Show Colliders.
class JointGizmoRenderer : IGizmoRenderer
{
	public Type ComponentType => typeof(JointComponent);
	public bool DrawWhenUnselected => true;

	public void Draw(void* component, EntityHandle owner, GizmoContext ctx)
	{
		if (!ctx.ShowColliders)
			return;
		let joint = (JointComponent*)component;
		let world = ctx.Scene.GetWorldMatrix(owner);
		let anchor = TransformPoint(joint.LocalAnchor, world);
		let color = ctx.EntityEffectivelyActive
			? Color(1.0f, 0.5f, 0.1f, 1.0f) : Color(0.45f, 0.45f, 0.45f, 1.0f);
		let dd = ctx.Debug;
		dd.DrawCross(anchor, 0.25f, color);
		if (!joint.TargetEntity.IsNil)
		{
			let target = ctx.Scene.FindEntity(joint.TargetEntity.Id);
			if (target.IsAssigned)
				dd.DrawLine(anchor, WorldPosition(ctx.Scene.GetWorldMatrix(target)), color);
		}
		if ((joint.Kind == .Hinge) || (joint.Kind == .Slider))
		{
			let axisEnd = TransformPoint(joint.LocalAnchor + joint.LocalAxis, world);
			var dir = axisEnd - anchor;
			let len = Length(dir);
			if (len > 1e-4f)
			{
				dir = dir * (1.0f / len);
				dd.DrawArrow(anchor - dir * 0.5f, anchor + dir * 0.5f, color, 0.1f);
			}
		}
	}
}
