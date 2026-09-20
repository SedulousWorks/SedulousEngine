using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Render;
using static Sedulous.Editor.Scene.GizmoDrawHelpers;

namespace Sedulous.Editor.Scene;

/// A directional light's arrow, a point light's range sphere, a spot light's cone.
class LightGizmoRenderer : IGizmoRenderer
{
	public Type ComponentType => typeof(LightComponent);

	public void Draw(void* component, EntityHandle owner, GizmoContext ctx)
	{
		let light = (LightComponent*)component;
		let world = ctx.Scene.GetWorldMatrix(owner);
		let position = WorldPosition(world);
		let forward = WorldForward(world);
		let dd = ctx.Debug;
		let color = Color(Clamp(light.Color.R, 0.0f, 1.0f), Clamp(light.Color.G, 0.0f, 1.0f),
			Clamp(light.Color.B, 0.0f, 1.0f), 1.0f);

		switch (light.Type)
		{
		case .Directional:
			DrawCenterCross(dd, position, 0.3f, color);
			let tip = position + forward * 1.5f;
			dd.DrawArrow(position, tip, color, 0.2f);
		case .Point:
			dd.DrawWireSphere(position, light.Range, color, 24);
			DrawCenterCross(dd, position, 0.15f, color);
		case .Spot:
			let tipDist = Max(light.Range, 0.1f);
			let tipCenter = position + forward * tipDist;
			let tipRadius = tipDist * Tan(light.OuterAngle);

			let up = (Abs(forward.Y) < 0.99f) ? Float3(0, 1, 0) : Float3(0, 0, 1);
			let right = Normalized(Cross(forward, up));
			let trueUp = Cross(right, forward);

			dd.DrawCircle(tipCenter, right, trueUp, tipRadius, color, 24);
			dd.DrawLine(position, tipCenter + right * tipRadius, color);
			dd.DrawLine(position, tipCenter - right * tipRadius, color);
			dd.DrawLine(position, tipCenter + trueUp * tipRadius, color);
			dd.DrawLine(position, tipCenter - trueUp * tipRadius, color);
		}
	}
}
